classdef AirfoilReader < geometry.Airfoil
    %AIRFOIL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
       filename     % Filename of the airfoil.dat file
       name         % Derived airfoil name from filename
       x_upper      % x coordinate of upper-surface points
       x_lower      % x coordinate of lower-surface points
       y_upper      % y coordinate of upper-surface points
       y_lower      % y coordinate of lower-surface points
       x_max        % x location of maximum thickness
       t_max        % Normalized maximum thickness (t/c)
    end

    properties (SetAccess = private, GetAccess = private)
       data         % Read airfoil data, dependent
%        plot = ''
%        le_index     % Defines the index of the LE point in `data`
       figure_handle    % Retrieves the generated figure handle
    end
    
    methods
        %% Class Constructor
        function obj = AirfoilReader(varargin)
            %AIRFOIL Construct an instance of this class
            %   Detailed explanation goes here
            %CLASS CONSTRUCTOR!
            filename = 'naca23015.dat';
            % Ability to add validator functions for
            p = inputParser; % Analyzes passed arguments
            addOptional(p, 'filename', filename,...
                        @geometry.Validators.validAirfoilData)
            parse(p, varargin{:});
            
            obj.filename = p.Results.filename;
%             obj.update_data()
%             obj.update_points()
        end
        
        %% Callable Methods
        function handle = plot(obj)            
            figure('Name', obj.name);
            hold on; grid on; grid minor;
            plot(obj.x_upper, obj.y_upper)
            plot(obj.x_lower, obj.y_lower)
            chord = max([obj.x_upper; obj.x_lower]);
            axis([0, chord, -0.5 * chord, 0.5 * chord])
            hold off;
            xlabel('Normalized Chord Location (x/c)','Color','k');
            ylabel('Normalized Chord-Normal Location (y/c)','Color','k');
            legend('Upper Surface', 'Lower Surface')
            title(sprintf('%s Geometry', obj.name))
            handle = gcf();
        end
        
        function scale(obj, chord, thickness)
            upper_spline = spline(obj.x_upper, obj.y_upper);
            lower_spline = spline(obj.x_lower, obj.y_lower);
            
            % Objective Function used to find the current thickness
            f = @(x) -(ppval(upper_spline, x) - ppval(lower_spline, x));
            
            % Normalized maximum thickness value and location
            [obj.x_max, obj.t_max] = fminbnd(f, 0.0, 1.0);
            
            %  Extablishing thikcness scaling ratio
            current_thickness = -obj.t_max;
            ratio = thickness / current_thickness;
            
            obj.x_upper = obj.x_upper * chord;
            obj.x_lower = obj.x_lower * chord;
            obj.y_upper = obj.y_upper * ratio;
            obj.y_lower = obj.y_lower * ratio;
        end
        
%         function CSTAirfoil = makeCST(obj)
%             CSTstruct.A_upper = +geometry.CSTAirfoil()
%         end

        %% Dependent Property Getters
%         function value = get.name(obj)
%             %GETTER of public property `name`
%             % Retrieves and formats name from airfoil filename
%             split_filename = strsplit(obj.filename, '.dat');
%             value = upper(char(split_filename{1, 1}));
%         end
%         
%         function value = get.data(obj)
%             %GETTER of private attribute `data`
%             % Matrix of Airfoil coordinates (1st row = x, 2nd row = y)
%             fid = fopen([pwd '\data\airfoil\' obj.filename], 'r');
%             fgetl(fid); % Removing header from the opened airfoil
%             value = fscanf(fid, '\t%g\t%g', [2 Inf]);            
%             fclose(fid);
%         end
%         
%         function value = get.le_index(obj)
%             %GETTER of private attribute `le_index`
%               %Obtains the index of the leading edge point (where x = 0)
%             idx = find(obj.data(1,:) == 0);
%             if length(idx) ~= 1
%                 error(['Airfoil file is corrupted, contains multiple'...
%                        'LE points'])
%             else
%                 value = idx;
%             end
%         end
%         
%         function value = get.x_upper(obj)
%             %GETTER of attribute x_upper
%             %   Extracts x coordinates of the upper_surface and reverses it
%             value = flip(obj.data(1, 1:obj.le_index))';
%         end
%         
%         function value = get.x_lower(obj)
%             %GETTER of attribute x_lower
%             %   Extracts x coordinates of the upper_surface
%             value = obj.data(1, obj.le_index:end)';
%         end
%         
%         function value = get.y_upper(obj)
%             %GETTER of attribute y_upper
%             %   Extracts y coordinates of the upper_surface and reverses it
%             value = flip(obj.data(2, 1:obj.le_index))';
%         end
%         
%         function value = get.y_lower(obj)
%             %GETTER of attribute y_lower
%             %   Extracts y coordinates of the upper_surface
%             value = obj.data(2, obj.le_index:end)';
%         end
%         
        %% Dependent Property Setters
%         function obj = set.y_upper(obj, value)
%             obj.y_upper = value;
%         end
%         
%         function obj = set.y_lower(obj, value)
%             obj.y_lower = value;
%         end

        function update_points(obj)
            %GETTER of private attribute `le_index`
              %Obtains the index of the leading edge point (where x = 0)
            idx = find(obj.data(1,:) == 0);
            if length(idx) ~= 1
                error(['Airfoil file is corrupted, contains multiple'...
                       'LE points'])
            else
                le_index = idx;
                obj.x_upper = flip(obj.data(1, 1:le_index))';
                obj.x_lower = obj.data(1, le_index:end)';
                obj.y_upper = flip(obj.data(2, 1:le_index))';
                obj.y_lower = obj.data(2, le_index:end)'; 
            end
        end
        
        function update_data(obj)
            %GETTER of private attribute `data`
            % Matrix of Airfoil coordinates (1st row = x, 2nd row = y)
            fid = fopen([pwd '\data\airfoil\' obj.filename], 'r');
            fgetl(fid); % Removing header from the opened airfoil
            obj.data = fscanf(fid, '\t%g\t%g', [2 Inf]);            
            fclose(fid);
        end

        function update_name(obj)
            split_filename = strsplit(obj.filename, '.dat');
            obj.name = upper(char(split_filename{1, 1}));
        end
        
        function set.filename(obj, value)
            obj.filename = value;
            obj.update_name();
            obj.update_data();
            obj.update_points()
            disp('I updated')
        end
    end
end

