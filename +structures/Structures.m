% Copyright 2018 San Kilkis
% 
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
% 
%    http://www.apache.org/licenses/LICENSE-2.0
% 
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.

classdef Structures < handle
    %STRUCTURES 
    %   Detailed explanation goes here
    % TODO Comment HERE
    
    properties
        aircraft_in                 % Input Aircraft Object
        W_w                         % Wing Weight
        V_t                         % Computed Fuel-Tank Volume
        EMWET_input = struct();     % Struct Containing Inputs for EMWET 
        EMWET_output = struct();    % Struct Containing Outputs of EMWET
        fuel_tank                   % Constructed Fuel-Tank
    end
    
    properties (SetAccess = private, GetAccess = private)
        temp_dir                    % Temporary Directory for EMWET Runs
    end
    
    methods
        
        function obj = Structures(aircraft_in)
            %STRUCTURES Construct an instance of this class
            %   Detailed explanation goes here
            obj.aircraft_in = aircraft_in;

            % Construction Sequence:
            obj.fetch_inputs()      % Fetching Inputs
            obj.make_temp_dir()     % Making Temporary Directory
            obj.write_init()        % Writing EMWET .init file
            obj.write_airfoils()    % Writes .dat file of current airfoils
            obj.write_loads()       % Writes loads to file
            obj.run_EMWET();        % Runs EMWET
            obj.fetch_output()      % Parses data from .weight file
            obj.build_fuel_tank     % Builds the fuel-tank
            obj.cleanup()           % Removes Temporary Directory
        end

        function MTOW = calc_mtow(obj)
            % Calculates the MTOW of the current Iteraiton
            
            % TODO move into aircraft class
            ac = obj.aircraft_in;
            MTOW = ac.W_aw + ac.W_f + ac.W_w + ac.W_p;
        end

        function fetch_inputs(obj)
            % Defining Input Struct
            ac = obj.aircraft_in; i.name = ac.name;
            i.MTOW = obj.calc_mtow();
            % TODO check if zero fuel weight can be constant
            i.ZFW = ac.W_aw + ac.W_mp + ac.W_w; % Zero Fuel Weight is assumed constant
            i.n_max = ac.eta_max; % Load Factor
            i.b = ac.b;  % Wing Span
            i.N_sections = 4; % Number of Planform Sections
           
            % Fetching Planform Geometry
            planform = obj.aircraft_in.planform;
            coords = planform.Coords;
            chords = planform.Chords;
            eta_fus = ac.D_fus / ac.b;

            i.sections.root.chord = chords(1);
            i.sections.root.x = coords(1, 1);
            i.sections.root.y = coords(1, 2);
            i.sections.root.z = coords(1, 3);
            i.sections.root.fs = planform.FS_root;
            i.sections.root.rs = planform.RS_root;
            
            i.sections.fus.chord = planform.chord_at_span(eta_fus);
            i.sections.fus.x = planform.LE_at_span(eta_fus);
            i.sections.fus.y = eta_fus * ac.b * 0.5;
            i.sections.fus.z = 0;
            i.sections.fus.fs = planform.FS_fus;
            i.sections.fus.rs = planform.RS_fus;

            i.sections.kink.chord = chords(2);
            i.sections.kink.x = coords(2, 1);
            i.sections.kink.y = coords(2, 2);
            i.sections.kink.z = coords(2, 3);
            i.sections.kink.fs = planform.FS;
            i.sections.kink.rs = planform.RS;

            i.sections.tip.chord = chords(end);
            i.sections.tip.x = coords(end, 1);
            i.sections.tip.y = coords(end, 2);
            i.sections.tip.z = coords(end, 3);
            i.sections.tip.fs = planform.FS;
            i.sections.tip.rs = planform.RS;

            i.N_airfoils = 3; % Number of Airfoil Sections
            i.airfoils.root.loc = 0;
            i.airfoils.root.name = [i.name '_r'];
            
            i.airfoils.kink.loc = planform.eta(2);
            i.airfoils.kink.name = [i.name '_k'];
            
            i.airfoils.tip.loc = 1;
            i.airfoils.tip.name = [i.name '_t'];
            
            i.S = planform.S;
            i.fuel_start = ac.D_fus / planform.b;
            i.fuel_end = ac.fuel_limit;
            i.engine_spec = ac.engine_spec; % Engine
            i.N_engines = 1; % Number of engines on each wing, HARDCODED

            % Material Properties
            young = ac.E_al;
            rho = ac.rho_al;
            tens = ac.sigma_c;
            comp = ac.sigma_t;

            % Assigning Material Properties per Panel
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
                fprintf(fid, '%g %g %g %g %g %g \n',...
                    sec.chord,...
                    sec.x,...
                    sec.y,...
                    sec.z,...
                    sec.fs,...
                    sec.rs);
            end

            % Creating Engine Specifications
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
            % TODO verify that planform is same as input planform

            CST = obj.aircraft_in.CST;
            CST.root.write([obj.temp_dir '\' ...
                obj.EMWET_input.airfoils.root.name '.dat'])
            CST.kink.write([obj.temp_dir ...
                '\' obj.EMWET_input.airfoils.kink.name '.dat'])
            CST.tip.write([obj.temp_dir ...
                '\' obj.EMWET_input.airfoils.tip.name '.dat'])
        end
        
        function CST = build_CSTAirfoil(obj) % TODO put this into design vector
            % Creating cosine spaced points for maximum accuracy of airfoil
            u_control = linspace(0, pi, 100);
            x = 0.5*(1 - cos(u_control))';
            
            % Fetching Root CST Coefs
            ac = obj.aircraft_in; A_root = ac.A_root;
            root.upper = A_root(1:length(A_root)/2);
            root.lower = A_root(length(A_root)/2+1:end);

            % Fetching Kink CST Coefs
            A_kink = ac.A_kink;
            kink.upper = A_kink(1:length(A_kink)/2);
            kink.lower = A_kink(length(A_kink)/2+1:end);
            
            % Fetching Tip CST Coefs
            A_tip = ac.A_tip;
            tip.upper = A_tip(1:length(A_tip)/2);
            tip.lower = A_tip(length(A_tip)/2+1:end);
            
            % Creating CST Airfoils
            CSTAirfoil = @geometry.CSTAirfoil;
            CST.root = CSTAirfoil(x, 'A_upper', root.upper,...
                'A_lower', root.lower);
            CST.kink = CSTAirfoil(x, 'A_upper', kink.upper,...
                'A_lower', kink.lower);
            CST.tip = CSTAirfoil(x, 'A_upper', tip.upper,...
                'A_lower', tip.lower);
        end
        
        function write_loads(obj)
            % Transforming Bernstein Coefs. into Actual Load Data
            ac = obj.aircraft_in;
            A_L = ac.A_L'; A_M = ac.A_M';
            Y_range = linspace(0, 1, 30)';
            L = geometry.CSTAirfoil.shapeFunction(Y_range, A_L);
            M = geometry.CSTAirfoil.shapeFunction(Y_range, A_M);
            
            plot(Y_range, L); drawnow;
            
            % Writing to .load file
            filename = [obj.temp_dir '\' obj.aircraft_in.name '.load'];
            fid = fopen(filename, 'w');
            for i = 1:length(Y_range)
                fprintf(fid, '%.4f %.4e %.4e\n', Y_range(i), L(i), M(i));
            end
            fclose(fid);
            % copyfile([pwd '\data\aircraft\A320.load'], obj.temp_dir);
        end
        
        function fetch_output(obj)
            filename = [obj.temp_dir '\' obj.aircraft_in.name '.weight'];
            fid = fopen(filename, 'r');
            idx = 1;

            n_lines = util.linecount(filename);
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
                tic;
                working_dir = cd;
                cd(obj.temp_dir)
                eval(sprintf('EMWET %s', obj.aircraft_in.name))
                cd(working_dir);
                exit_code = 1;
                t = toc;
                fprintf('EMWET took: %.5f [s]\n', t)
            catch e
                error(e.message);
                exit_code = 0;
            end
        end
        
        function build_fuel_tank(obj)
            obj.fuel_tank = structures.FuelTank(obj);
            obj.V_t = obj.fuel_tank.V_t;
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

