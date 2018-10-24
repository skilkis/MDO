classdef AirfoilReader < geometry.Airfoil
    %AIRFOIL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        filename
        name
    end
    
    properties (Dependent, SetAccess = private)
       x_upper      % x coordinate of upper-surface points
       x_lower      % x coordinate of lower-surface points
       y_upper      % y coordinate of upper-surface points
       y_lower      % y coordinate of lower-surface points
    end
    
    properties (Dependent, SetAccess = private, GetAccess = private)
       data         % Read airfoil data, dependent
       le_index     % Defines the index of the LE point in `data`
       fig_handle   % Retrieves the generated figure handle
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
        end
        
        %% Callable Methods
        function handle = plot(obj)            
            figure('Name', obj.name);
            hold on; grid on; grid minor;
            plot(obj.x_upper, obj.y_upper)
            plot(obj.x_lower, obj.y_lower)
            axis([0, 1, -0.5, 0.5])
            hold off;
            xlabel('Normalized Chord Location (x/c)','Color','k');
            ylabel('Normalized Chord-Normal Location (y/c)','Color','k');
            legend('Upper Surface', 'Lower Surface')
            title(sprintf('%s Geometry', obj.name))
            handle = gcf();
        end
        
%         function CSTAirfoil = makeCST(obj)
%             CSTstruct.A_upper = +geometry.CSTAirfoil()
%         end

        %% Dependent Property Getters
        function value = get.name(obj)
            %GETTER of public property `name`
            % Retrieves and formats name from airfoil filename
            split_filename = strsplit(obj.filename, '.dat');
            value = upper(char(split_filename{1, 1}));
        end
        
        function value = get.data(obj)
            %GETTER of private attribute `data`
            % Matrix of Airfoil coordinates (1st row = x, 2nd row = y)
            fid = fopen([pwd '\data\airfoil\' obj.filename], 'r');
            fgetl(fid); % Removing header from the opened airfoil
            value = fscanf(fid, '\t%g\t%g', [2 Inf]);            
            fclose(fid);
        end
        
        function value = get.le_index(obj)
            %GETTER of private attribute `le_index`
              %Obtains the index of the leading edge point (where x = 0)
            idx = find(obj.data(1,:) == 0);
            if length(idx) ~= 1
                error(['Airfoil file is corrupted, contains multiple'...
                       'LE points'])
            else
                value = idx;
            end
        end
        
        function value = get.x_upper(obj)
            %GETTER of attribute x_upper
            %   Extracts x coordinates of the upper_surface and reverses it
            value = flip(obj.data(1, 1:obj.le_index))';
        end
        
        function value = get.x_lower(obj)
            %GETTER of attribute x_lower
            %   Extracts x coordinates of the upper_surface
            value = obj.data(1, obj.le_index:end)';
        end
        
        function value = get.y_upper(obj)
            %GETTER of attribute y_upper
            %   Extracts y coordinates of the upper_surface and reverses it
            value = flip(obj.data(2, 1:obj.le_index))';
        end
        
        function value = get.y_lower(obj)
            %GETTER of attribute y_lower
            %   Extracts y coordinates of the upper_surface
            value = obj.data(2, obj.le_index:end)';
        end
        
    end
end

