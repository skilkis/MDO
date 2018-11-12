classdef Structures < handle
    %STRUCTURES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        design_vector           % Design Vector Object
        aircraft_in = aircraft.Aircraft('A320');
        W_w                     % Wing Weight
        
        EMWET_input = struct();
        EMWET_output = struct();
    end
    
    properties (SetAccess = private, GetAccess = private)
        temp_dir            % Temporary Directory for EMWET Runs
    end
    
    methods
        
        function obj = Structures(design_vector, aircraft_in)
            %STRUCTURES Construct an instance of this class
            %   Detailed explanation goes here
            % TODO enable input for aircraft_in
            obj.design_vector = design_vector;
            obj.aircraft_in = aircraft_in;

            % Construction Sequence:
            obj.fetch_inputs()      % Fetching Inputs
            obj.make_temp_dir()     % Making Temporary Directory
            obj.write_init()        % Writing EMWET .init file
            obj.write_airfoils()    % Writes .dat file of current airfoils
            obj.write_loads()       % Writes loads to file
            obj.run_EMWET();        % Runs EMWET
            obj.fetch_output()      % Parses data from .weight file
            obj.cleanup()           % Removes Temporary Directory
        end

        function MTOW = calc_mtow(obj)
            % Calculates the MTOW of the current Iteraiton
            
            % TODO move into aircraft class
            ac = obj.aircraft_in; x = obj.design_vector;
            MTOW = ac.W_aw + x.W_f_hat + x.W_w_hat;
        end

        function fetch_inputs(obj)
            % Defining Input Struct
            ac = obj.aircraft_in; x = obj.design_vector; i.name = ac.name;
            i.MTOW = obj.calc_mtow();
            i.ZFW = ac.W_zf; % Zero Fuel Weight
            i.n_max = ac.eta_max; % Load Factor
            i.b = x.b;  % Wing Span
            i.N_sections = 2; % Number of Planform Sections
            i.N_airfoils = 2; % Number of Airfoil Sections
            i.airfoils.root.loc = 0; i.airfoils.root.name = [i.name '_r'];
            i.airfoils.tip.loc = 1; i.airfoils.tip.name = [i.name '_t'];
            
            % Fetching Planform Geometry
            planform = obj.aircraft_in.planform;
            coords = planform.Coords;
            chords = planform.Chords;

            i.sections.root.chord = chords(1);
            i.sections.root.x = coords(1, 1);
            i.sections.root.y = coords(1, 2);
            i.sections.root.z = coords(1, 3);
            i.sections.root.fs = planform.fs_r;
            i.sections.root.rs = planform.rs_r;


            i.sections.tip.chord = chords(end);
            i.sections.tip.x = coords(end, 1);
            i.sections.tip.y = coords(end, 2);
            i.sections.tip.z = coords(end, 3);
            i.sections.tip.fs = planform.fs;
            i.sections.tip.rs = planform.rs;

            i.S = planform.S;
            i.fuel_start = ac.fuel_limits(1); 
            i.fuel_end = ac.fuel_limits(2);
            i.engine_spec = [0.25, 3000]; % TODO Add this into Aircraft
            i.N_engines = 1; % Number of engines on each wing

            % Material Properties
            young = ac.E_al;
            rho = ac.rho_al;
            tens = ac.sigma_c;
            comp = ac.sigma_t;

            fields = {'top', 'bot', 'front', 'rear'};
            for field = fields
                i.box.(field{:}).young = young;
                i.box.(field{:}).rho  = rho;
                i.box.(field{:}).tens = tens;
                i.box.(field{:}).comp = comp;
            end
            i.eta_panel = 1.02; % Integral Zed Stiffener
            i.rib_pitch  = 0.5;
            i.display_option = 0;

            obj.EMWET_input = i;
        end

        function write_init(obj)
            filepath = [obj.temp_dir '\' obj.aircraft_in.name '.init'];
            i = obj.EMWET_input;
            fid = fopen(filepath, 'w');
            fprintf(fid, '%g %g\n', i.MTOW, i.ZFW);
            fprintf(fid, '%g \n', i.n_max);
            fprintf(fid, '%g %g %g %g \n', i.S, i.b, i.N_sections,...
                    i.N_airfoils);

            % Creating Airfoil Location Fields
            for field = fieldnames(i.airfoils)'
                air = i.airfoils.(field{:});
                fprintf(fid, '%g %s \n', air.loc, air.name);
            end

            % Creating Planform Sections
            for field = fieldnames(i.sections)'
                sec = i.sections.(field{:});
                disp(sec);
                fprintf(fid, '%g %g %g %g %g %g \n',...
                    sec.chord,...
                    sec.x,...
                    sec.y,...
                    sec.z,...
                    sec.fs,...
                    sec.rs);
            end

            % Creating 
            fprintf(fid, '%g %g \n', i.fuel_start, i.fuel_end);
            fprintf(fid, '%d \n', i.N_engines);
            fprintf(fid, '%g %g \n', i.engine_spec); % Another problem area

            % Always 4 entries (Upper, Lower, Front, Rear)
            for field = fieldnames(i.box)'
                box = i.box.(field{:});
                fprintf(fid, '%g %g %g %g \n',...
                    box.young,...
                    box.rho,...
                    box.tens,...
                    box.comp);
            end

            fprintf(fid, '%g %g \n', i.eta_panel, i.rib_pitch);
            fprintf(fid, '%d', i.display_option);
            fclose(fid);
        end
        
        function write_airfoils(obj)
            ac = obj.aircraft_in;
            ac.airfoils.root.write([obj.temp_dir '\' ...
                obj.EMWET_input.airfoils.root.name '.dat'])
            ac.airfoils.tip.write([obj.temp_dir ...
                '\' obj.EMWET_input.airfoils.tip.name '.dat'])
        end
        
        function write_loads(obj)
            copyfile([pwd '\data\aircraft\A320.load'], obj.temp_dir);
        end
        
        function fetch_output(obj)
            filename = [obj.temp_dir '\' obj.aircraft_in.name '.weight'];
            fid = fopen(filename, 'r');
            idx = 1;

            n_lines = utilities.linecount(filename);
            data_idx = 5; % Line index where EMWET output data starts
            data = zeros(n_lines - data_idx, 6);
            while ~feof(fid)
                line = fgetl(fid);
                if idx == 1
                    split_header = strsplit(line, '(kg) ');
                    obj.W_w = str2double(split_header{:, 2}); % Wing Weight
                elseif idx >= data_idx && ischar(line)
                    cell_line = strsplit(line,' ');
                    data_line = cellfun(@(x) str2double(x),...
                        cell_line(1, 2:end));
                    data(idx - (data_idx - 1), :) = data_line;
                end
                idx = idx + 1;
            end
            fclose(fid);
            
            % Assining Data to Struct and updating EMWET_output
            o.half_span = data(:, 1); o.chord = data(:, 2);
            o.t_u = data(:, 3); o.t_l = data(:, 4); o.t_fs = data(:, 5);
            o.t_rs = data(:, 6);
            obj.EMWET_output = o;
        end
        
        function exit_code = run_EMWET(obj)
            try
                working_dir = cd;
                cd(obj.temp_dir)
                eval(sprintf('EMWET %s', obj.aircraft_in.name))
                cd(working_dir);
                exit_code = 1;
            catch e
                error(e.message);
                exit_code = 0;
            end
        end
    end
    
    methods (Access = private)
        function make_temp_dir(obj)
            % Creates a temporary directory pertaining to the current
            % worker_ID for EMWET if parallel processing is enabled.
            % Otherwise a 'serial_exec' folder is created. The EMWET.p
            % file is also copied to this directory
            try
                w = getCurrentWorker;
                worker_ID = w.ProcessId;
            catch
                warning(['Parallel Processing Disabled ' ...
                         'or not Installed on Machine'])
                worker_ID = 'serial_exec';
            end

            obj.temp_dir = [pwd '\temp\EMWET\'...
                            num2str(worker_ID)];
            mkdir(obj.temp_dir)

            % Copying EMWET to New Worker Directory
            copyfile([pwd '\bin\EMWET.p'], obj.temp_dir);
        end
        
        function cleanup(obj)
            rmdir(obj.temp_dir, 's');
        end
    end
end

