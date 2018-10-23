classdef FittedAirfoil
    %FITTEDAIRFOIL Takes input airfoil coordinates and returns a CSTAirfoil
    %   Inputs: Airfoil, Optional: n_variables, optimize_class
    
%     properties (GetAccess = private)
    properties
        x_upper         % Input x ordinates of upper surface
        x_lower         % Input x ordinates of lower surface
        y_upper         % Input y ordinates of upper surface
        y_lower         % Input y ordinates of lower surface
        n_variables     % Number of Bernstein Coef. per surface
        optimize_class  % Toggles if class function should be optimized
        x0              % Initial design vector
        ub              % Design vector upper bound
        lb              % Design vector lpper bound
    end
    
    properties (Dependent, SetAccess = 'private')
        CSTAirfoil
    end
    
    methods
        %% Class Constructor
        function obj = FittedAirfoil(ordStruct, varargin)
            %FITTEDAIRFOIL Construct an instance of this class
            %   Detailed explanation goes here
            %CLASS CONSTRUCTOR!
            
            % Default Values
            n_variables = 6; % Number of Bernstein Coef. per surface
            optimize_class = false; % Toggles if class function should be optimized

            % Ability to add validator functions for
            p = inputParser; % Analyzes passed arguments
            addRequired(p, 'ordStruct', @geometry.Validators.validAirfoil)
            addOptional(p, 'n_variables', n_variables, ...
                        @geometry.Validators.isInteger);
            addOptional(p, 'optimize_class', optimize_class, ...
                        @islogical) % TODO make sure this is a new validator for boolean

            parse(p, ordStruct, varargin{:});
            
            % Setting Properties from Input
            obj.x_upper = p.Results.ordStruct.x_upper;
            obj.x_lower = p.Results.ordStruct.x_lower;
            obj.y_upper = p.Results.ordStruct.y_upper;
            obj.y_lower = p.Results.ordStruct.y_lower;
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
            ub(end-1) = 1.0; ub(end) = 1.0;
            
            lb = ones(1, length(obj.x0)) * -Inf;
            lb(end-1) = 0.0; lb(end) = 0.0;
            
            obj.ub = ub; obj.lb = lb; % Assigning to property
        end

        %% Dependent Property Getter
        function value = get.CSTAirfoil(obj)
        % Runs fmincon with the design vector/bounds from the class
        % constructor. Settings for fmincon can be changed below:
            options = optimset('Display', 'iter', 'Algorithm', 'sqp');
            
            disp('Performing CST Airfoil Fitting');
            [x_final, ~, ~, ~] = fmincon(@obj.cst_objective, ...
                                         obj.x0, [],[],[],[], ...
                                         obj.lb, obj.ub, [], ...
                                         options);
            value = obj.parseDesignVector(x_final);

        end
        
        %% Minimization Helper and Objective Functions
        function my_CSTAirfoil = parseDesignVector(obj, x)
        % Parses the design vector into a CSTObjective

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
