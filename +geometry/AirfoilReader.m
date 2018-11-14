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

            p = inputParser; % Analyzes passed arguments
            addOptional(p, 'filename', filename,...
                        @geometry.Validators.validAirfoilData)
            parse(p, varargin{:});
            
            obj.filename = p.Results.filename;
        end
        
        %% Callable Methods
        function scaled = scale(obj, chord, thickness)            
            upper_spline = spline(obj.x_upper, obj.y_upper);
            lower_spline = spline(obj.x_lower, obj.y_lower);
            
            % Objective Function used to find the current thickness
            f = @(x) -(ppval(upper_spline, x) - ppval(lower_spline, x));
            
            % Normalized maximum thickness value and location
            [obj.x_max, obj.t_max] = fminbnd(f, 0.0, 1.0);
            
            %  Extablishing thikcness scaling ratio
            current_thickness = -obj.t_max;
            ratio = thickness / current_thickness;
            
            scaled = obj.copy(); scaled.t_max = thickness;            
            scaled.x_upper = obj.x_upper * chord;
            scaled.x_lower = obj.x_lower * chord;
            scaled.y_upper = obj.y_upper * chord * ratio;
            scaled.y_lower = obj.y_lower * chord * ratio;
        end
        
        %% Private Methods
        % TODO make this private
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
            obj.update_points();
        end
    end
end

