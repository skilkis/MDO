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
        W_zf            % Zero-Fuel Weight [kg]
%         W_e             % Empty Weight [kg]
        
        % Geometric Parameters
%         D_fus           % Fuselag Diameter [m]
%         d_TE            % Fixed Inboard Trailing Edge Length [m]
%         d_rib           % Rib Pitch [m]
%         S               % Reference Wing-Planform area [m^2]
%         N1              % LE Class Function Coefficient [-]
%         N2              % TE Class Function Coefficient [-]
%         FS              % Front Spar Chordwise Position [-]
%         RS              % Rear Spar Chordwise Position [-]
%         FS_fus          % Front Spar Chordwise Pos. at Fuselage-Line [-]
        
        % Aluminum Material Properties
        E_al            % Young's Modulus of Aluminum [Pa]
        sigma_c         % Compresible Yield Stress [Pa]
        sigma_t         % Tensile Yield Stress [Pa]
        rho_al          % Density of Aluminum Alloy [kg/m^3]
        
        % Miscelaneious Properties
        eta_max         % Maximum Load Factor [-]
        rho_f           % Fuel Density (Kerosene) [kg/m^3]
        C_T             % Thrust Specific Fuel Consumption
        M_mo            % Maximum Operating Mach Number [-]
        fuel_limits     % Span-wise Fuel Tank Limits (Root, Tip)

        % Planform Object of the Current Aircraft
        planform = geometry.Planform()
        
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

            obj.planform = geometry.Planform();
            obj.getAirfoils();
        end
        
        function getAirfoils(obj)
            root_airfoil = geometry.AirfoilReader([obj.base_airfoil...
                                                   '.dat']);
            root_fit = geometry.FittedAirfoil(root_airfoil);
%             root_cst = root_fit.CSTAirfoil;

            tip_airfoil = root_fit.scale(1.0, 0.1);
%             tip_cst = tip_airfoil.CSTAirfoil;
            
            obj.airfoils.root = root_fit;
            obj.airfoils.tip = tip_airfoil;
        end
    end
end

