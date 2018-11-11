classdef Aircraft
    %AIRCRAFT Base-Class of a generic Aircraft.
    % Defines the inputs and methods necessary set-up an initial design 
    % condition for the optimizer.
    
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
            try
                for field=fieldnames(obj)'
                    obj.(field{:}) = data.(field{:});
                end
            catch
                error(['Input .dat file is corrupted, %s '...
                       'could not be updated'], field{:})
            end
        end
    end
end

