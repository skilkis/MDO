classdef Aircraft < handle
    %AIRCRAFT Base-Class of a generic Aircraft.
    % Defines the inputs and methods necessary set-up an initial design 
    % condition for the optimizer.
    
    % TODO consider removing
    
    properties (SetAccess = private)
        % List of all design parameters, these are not subject to change
        % throughout the optimization process
        name            % Aircraft Name w/o File-Extension [-]
        base_airfoil    % Airfoil Name that Best Describes the Geom. [-]
        
        % Drag coefficient
        C_d_w
        C_d_aw
        
        % Cruise Parameters
        h_c             % Cruise Altitude [m]
        M_c             % Cruise Mach Number [-]
        a_c             % Speed of Sound [m/s]
        V_c             % Cruise Velocity [m/s]
        rho_c           % Cruise Air Density [kg/m^3]
        mu_c            % Cruise Dynamic Viscosity [kg/m s]
        R_c             % Design Cruise Range [km]
        
        % Aircraft Weights
        W_aw            % Aircraft Less Wing Weight [kg]
        W_mp            % Max Payload Weight [kg]
        W_p             % Design Payload Weight [kg]
        W_f             % Design Fuel Weight [kg]
        W_w             % Wing Weight [kg]
        
        % Geometric Parameters
        D_fus           % Fuselag Diameter [m]
        d_TE            % Fixed Inboard Trailing Edge Length [m]
        d_rib           % Rib Pitch [m]
        S               % Reference Wing-Planform area [m^2]
        FS              % Front Spar Chordwise Position [-]
        RS              % Rear Spar Chordwise Position [-]
        c_r             % Root chord [m]
        lambda_1        % Inboard Quarter chord sweep angle [rad]
        lambda_2        % Outboard Quarter chord sweep angle [rad]
        tau             % Taper ratio(Ct/Cr) [-]
        b               % Wing span(total) [m]
        beta_root       % Twist angle value for root [deg]
        beta_kink       % Twist angle at kink [deg]
        beta_tip        % Twist angle at tip [deg]
        
        % Aluminum Material Properties
        E_al            % Young's Modulus of Aluminum [Pa]
        sigma_c         % Compresible Yield Stress [Pa]
        sigma_t         % Tensile Yield Stress [Pa]
        rho_al          % Density of Aluminum Alloy [kg/m^3]
        
        % Engine Specifications
        engine_spec     % Span Position, Weight [kg]
        
        % Miscelaneious Properties
        eta_max         % Maximum Load Factor [-]
        rho_f           % Fuel Density (Kerosene) [kg/m^3]
        C_T             % Thrust Specific Fuel Consumption
        M_mo            % Maximum Operating Mach Number [-]
        fuel_limit      % Span-wise Normalized Fuel Tank Limit (Tip)
        g               % Acceleration due to gravity [m/s^2]
        v               % Air viscosity at altitude [m^2/s]
        
        % Planform Object of the Current Aircraft
        planform
        
        % Airfoil Bernstein Coefficients
        A_root
        A_tip
        
        % Loading coefficients
        A_L
        A_M
        
%         % Design Vector
%         x
    end
    
    methods
        function obj = Aircraft(name)
            %AIRCRAFT Construct an instance of this class
            %   Detailed explanation goes here
            % Creates optional arguments for all state variables
            args = inputParser; % Analyzes passed arguments
            
            addRequired(args, 'name', @aircraft.Validators.validAircraft)
            parse(args, name);
            obj.name = args.Results.name;
            data = load([pwd '\data\aircraft\' obj.name '.mat']);
            
            % Reading properties from data
            exclude = {'planform'; 'A_root'; 'A_tip'}; % Exclude list
            try
                for field=fieldnames(obj)'
                    if ~any(strcmp(exclude, field{:}))
                        obj.(field{:}) = data.(field{:});
                    end
                end
            catch
                error(['Input .dat file is corrupted, %s '...
                       'could not be updated'], field{:})
            end

            obj.planform = geometry.Planform(obj);
            obj.getAirfoils();
%            obj.x = optimize.DesignVector();
            
        end
        
        function getAirfoils(obj)
            import_airfoil = geometry.AirfoilReader([obj.base_airfoil...
                                                   '.dat']);
            root_fit = geometry.FittedAirfoil(import_airfoil);
            tip_airfoil=root_fit.scale(1.0, 0.1);
            
            % Returning 
            root_cst = root_fit.CSTAirfoil;
            tip_cst = tip_airfoil.CSTAirfoil;
            obj.A_root = [root_cst.A_upper; root_cst.A_lower];
            obj.A_tip = [tip_cst.A_upper; tip_cst.A_lower];
        end

        function modify(obj, x)
            try
                exclude = {'init'; 'vector'; 'lb'; 'ub'; 'history'};
                for field=fieldnames(x)'
                    if isempty(strfind(field{:}, '_0')) && ...
                         ~any(strcmp(exclude, field{:}))
                        obj.(field{:}) = x.(field{:});
                    end
                end
            catch
                error(['Input .dat file is corrupted, %s '...
                       'could not be updated'], field{:})
            end

            obj.planform = geometry.Planform(obj);
        end
    end
end

