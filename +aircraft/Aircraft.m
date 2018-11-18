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

classdef Aircraft < handle
    %AIRCRAFT Base-Class of a generic Aircraft.
    % Defines the inputs and methods necessary set-up an initial design 
    % condition for the optimizer.
    
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
        
        % Airfoil Properties
        A_root          % Root-Bernstein Coefficients
        A_tip           % Root-Bernstein Coefficients
        A_kink          % Weighted-Average of Current A_root and A_tip
        CST             % Struct of Constructed CSTAirfoil objects
        
        % Loading coefficients
        A_L             % Lift Distribution Bernstein Coefficients
        A_M             % Moment Distribution Bernstein Coefficients
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
            exclude = {'planform'; 'A_root'; 'A_tip'; 'A_kink'; 'CST'};
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
            obj.interp_airfoil();
            obj.build_CSTAirfoil();            
        end
        
        function getAirfoils(obj)
            % Reads the base-airfoil of the aircraft from .dat file and
            % transforms it into a root and tip airfoil. At the moment
            % the scaling factor is hardcoded to A320 values.
            import_airfoil = geometry.AirfoilReader([obj.base_airfoil...
                                                   '.dat']);
            root_fit = geometry.FittedAirfoil(import_airfoil);
            tip_airfoil=root_fit.scale(1.0, 0.11);

            root_cst = root_fit.CSTAirfoil;
            tip_cst = tip_airfoil.CSTAirfoil;
            obj.A_root = [root_cst.A_upper; root_cst.A_lower];
            obj.A_tip = [tip_cst.A_upper; tip_cst.A_lower];
        end
        
        function interp_airfoil(obj)
            % Obtains the Bernstein coef. of the airfoil at the kink
            % taking a weighted average based on trunk lengt
            obj.A_kink = (obj.A_root*obj.d_TE + obj.A_tip*((obj.b/2.0) ...
                        - obj.d_TE)) / (obj.b/2.0);
        end

        function build_CSTAirfoil(obj)
            % Creating cosine spaced points for maximum accuracy of airfoil
            u_control = linspace(0, pi, 50);
            x = 0.5*(1 - cos(u_control))';
            
            % Fetching Root CST Coefs
            root.upper = obj.A_root(1:length(obj.A_root)/2);
            root.lower = obj.A_root(length(obj.A_root)/2+1:end);
            
            % Fetching Tip CST Coefs
            tip.upper = obj.A_tip(1:length(obj.A_tip)/2);
            tip.lower = obj.A_tip(length(obj.A_tip)/2+1:end);
            
            % Fetching Mid CST Coefs
            kink.upper = obj.A_kink(1:length(obj.A_kink)/2);
            kink.lower = obj.A_kink(length(obj.A_kink)/2+1:end);
            
            % Creating CST Airfoils
            CSTAirfoil = @geometry.CSTAirfoil;
            obj.CST.root = CSTAirfoil(x, 'A_upper', root.upper,...
                'A_lower', root.lower);
            obj.CST.kink = CSTAirfoil(x, 'A_upper', kink.upper,...
                'A_lower', kink.lower);
            obj.CST.tip = CSTAirfoil(x, 'A_upper', tip.upper,...
                'A_lower', tip.lower);
        end
            
        function modify(obj, x)
            % Modifies the current Aircraft instance with the updated
            % values of the design vector
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
            obj.interp_airfoil();
            obj.build_CSTAirfoil();
        end
    end
end

