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

classdef FittedAirfoil < geometry.Airfoil
    %FITTEDAIRFOIL Takes input airfoil coordinates and returns a CSTAirfoil
    %   Inputs: Airfoil, Optional: n_variables, optimize_class
    
%     properties (GetAccess = private)
    properties (SetAccess = private)
        x_upper         % Input x ordinates of upper surface
        x_lower         % Input x ordinates of lower surface
        y_upper         % Input y ordinates of upper surface
        y_lower         % Input y ordinates of lower surface
        n_variables     % Number of Bernstein Coef. per surface
        optimize_class  % Toggles if class function should be optimized
        x0              % Initial design vector
        ub              % Design vector upper bound
        lb              % Design vector lpper bound
        airfoil_in      % Input Airfoil
        CSTAirfoil      % Fitted CSTAirfoil
    end
    
    
    methods
        %% Class Constructor
        function obj = FittedAirfoil(airfoil_in, varargin)
            %FITTEDAIRFOIL Construct an instance of this class
            %   Detailed explanation goes here
            %CLASS CONSTRUCTOR!
            
            % Default Values
            n_variables = 6; % Number of Bernstein Coef. per surface
            optimize_class = false; % Optimize Class Function?

            % Ability to add validator functions for
            p = inputParser; % Analyzes passed arguments
            addRequired(p, 'airfoil_in', @geometry.Validators.validAirfoil)
            addOptional(p, 'n_variables', n_variables, ...
                        @geometry.Validators.isInteger);
            addOptional(p, 'optimize_class', optimize_class, ...
                        @islogical)

            parse(p, airfoil_in, varargin{:});
            
            % Setting Properties from Input
            obj.airfoil_in = p.Results.airfoil_in;
            obj.x_upper = p.Results.airfoil_in.x_upper;
            obj.x_lower = p.Results.airfoil_in.x_lower;
            obj.y_upper = p.Results.airfoil_in.y_upper;
            obj.y_lower = p.Results.airfoil_in.y_lower;
            obj.n_variables = p.Results.n_variables;
            obj.optimize_class = p.Results.optimize_class;

            % Creating design vector
            Au0 = ones(n_variables, 1); Al0 = ones(n_variables, 1);
            if obj.optimize_class
                N1 = 0.5; N2 = 1.0; % Default class values
                obj.x0 = cat(1, Au0, Al0, N1, N2);
            else
                obj.x0 = cat(1, Au0, Al0);
            end

            % Setting Bounds on design Vector
            ub = ones(1, length(obj.x0)) * Inf;            
            lb = ones(1, length(obj.x0)) * -Inf;
            
            % Limiting class function values
            if obj.optimize_class
                ub(end-1) = 1.0; ub(end) = 1.0;
                lb(end-1) = 0.0; lb(end) = 0.0;
            end
            
            obj.ub = ub; obj.lb = lb; % Assigning to property

            % Running Fitting Operation on Load
            obj.fitCSTAirfoil();
        end

        function fitCSTAirfoil(obj)
        % Runs fmincon with the design vector/bounds from the class
        % constructor. Settings for fmincon can be changed below:
            tic;
            options = optimset('Display', 'off', 'Algorithm', 'sqp');
            [x_final, error, ~, ~] = fmincon(@obj.cst_objective, ...
                                             obj.x0, [],[],[],[], ...
                                             obj.lb, obj.ub, [], ...
                                             options);
            t=toc;
            fprintf('CST Airfoil Fitting took: %.5f [s], Error: %e\n',...
                    t, error)
            obj.CSTAirfoil = obj.parseDesignVector(x_final);
        end
        
        function handle = plot(obj)            
            figure('Name', inputname(1))
            hold on; grid on; grid minor;
            % Plotting Original Airfoil Ordinates
            plot(obj.x_upper, obj.y_upper,'o',...
                'DisplayName', 'Upper Surface')
            plot(obj.x_lower, obj.y_lower, 'o',...
                'DisplayName', 'Lower Surface')
            % Plotting CSTAirfoil Values
            chord = max([obj.x_upper; obj.x_lower]) - ...
                    min([obj.x_upper; obj.x_lower]);
            plot(obj.x_upper, obj.CSTAirfoil.y_upper * chord,...
                'DisplayName', 'CST Upper')
            plot(obj.x_lower, obj.CSTAirfoil.y_lower * chord,...
                'DisplayName', 'CST Lower')
            axis([0, chord, -0.5 * chord, 0.5 * chord])
            hold off;
            xlabel('Normalized Chord Location (x/c)','Color','k');
            ylabel('Normalized Chord-Normal Location (y/c)','Color','k');
            legend()
            title(sprintf('%s Object Geometry', inputname(1)),...
                  'Interpreter', 'none')
            handle = gcf();
        end
        
        function scaled = scale(obj, chord, thickness)
            % Avoids having to re-fit to new points by scaling geometry
            scaled = obj.copy();
            scaled.CSTAirfoil = obj.CSTAirfoil.scale(thickness);
            scaled.airfoil_in = obj.airfoil_in.scale(chord, thickness);
            
            % Obtaining Thickness Ratio
            ratio = thickness / obj.airfoil_in.t_max;
            
            scaled.x_upper = obj.x_upper * chord;
            scaled.x_lower = obj.x_lower * chord;
            scaled.y_upper = obj.y_upper * chord * ratio;
            scaled.y_lower = obj.y_lower * chord * ratio;
        end
        
        %% Minimization Helper and Objective Functions
        function my_CSTAirfoil = parseDesignVector(obj, x)
        % Parses the design vector and instantiates a CSTAirfoil

            n = obj.n_variables;
            if obj.optimize_class
                Au = x(1:n); Al = x(n+1:length(x)-2);
                N1 = x(length(x)-1); N2 = x(length(x));
                my_CSTAirfoil = geometry.CSTAirfoil(obj.x_upper,...
                                                    obj.x_lower,...
                                                    Au, Al, N1, N2);
            else
                Au = x(1:n); Al = x(n+1:length(x));
                my_CSTAirfoil = geometry.CSTAirfoil(obj.x_upper,...
                                                    obj.x_lower,...
                                                    Au, Al);
            end
        end
        
        function error = cst_objective(obj, x)
        % Fitting objective function

            my_CSTAirfoil = obj.parseDesignVector(x);

            % Upper Surface Error
            y_cst_upper = my_CSTAirfoil.y_upper;
            y_error_upper = sum((obj.y_upper - y_cst_upper).^2);

            % Lower Surface Error
            y_cst_lower = my_CSTAirfoil.y_lower;
            y_error_lower = sum((obj.y_lower - y_cst_lower).^2);

            % Total Error
            error = y_error_upper + y_error_lower;
        end
    end
end
