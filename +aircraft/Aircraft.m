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
        W_f             % Design Fuel Weight [kg]

        % Geometric Parameters
        D_fus           % Fuselag Diameter [m]
        d_TE            % Fixed Inboard Trailing Edge Length [m]
        d_rib           % Rib Pitch [m]
        S               % Reference Wing-Planform area [m^2]
        FS              % Front Spar Chordwise Position [-]
        RS              % Rear Spar Chordwise Position [-]
        FS_fus          % F.Spar Chordwise Pos. at fuselage [-]
        RS_fus          % R.Spar chordwise Pos. at fuselage [-]
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
        engine_spec = [0.25, 3000]; % [Span Position, Weight [kg]]
        
        % Miscelaneious Properties
        eta_max         % Maximum Load Factor [-]
        rho_f           % Fuel Density (Kerosene) [kg/m^3]
        C_T             % Thrust Specific Fuel Consumption
        M_mo            % Maximum Operating Mach Number [-]
        fuel_limits     % Span-wise Fuel Tank Limits (Root, Tip)
        g               % Acceleration due to gravity [m/s^2]
        v               % Air viscosity at altitude [m^2/s]
        % Planform Object of the Current Aircraft
        planform
        
        % Aircraft Airfoils
        airfoils
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
            exclude = {'planform'; 'airfoils'}; % Exclude list
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
        end
        
        function getAirfoils(obj)
            import_airfoil = geometry.AirfoilReader([obj.base_airfoil...
                                                   '.dat']);
%             root_fit = geometry.FittedAirfoil(import_airfoil)...
%                 .scale(obj.c_r, 0.15); % TODO thickness should be thickness specified by planform
% 
%             % TODO fix scaling of tip airfoil
%             tip_airfoil = root_fit.scale(c_t, 0.1); % TODO change this to thickness specified by planform
            % problem WITH SCALING
            root_fit = geometry.FittedAirfoil(import_airfoil);
            tip_airfoil=root_fit.scale(1.0, 0.1);
            
            obj.airfoils.root = root_fit;
            obj.airfoils.tip = tip_airfoil;
        end
    end
end

