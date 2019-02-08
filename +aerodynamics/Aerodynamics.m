% Copyright 2018 Evert Bunschoten
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

classdef Aerodynamics < handle
%% AERODYNAMICS

% This is the aerodynamics analysis code. It's responsible for calculating
% the drag coefficient of the wing defined in the current iteration. This
% value is compared to the guessed value of the drag coefficient in the
% constraints. First, the variables and parameters are extracted from the
% input struct. After that, the Q3D input struct is made according to these
% variables and parameters, which allows Q3D to calculate the wing drag
% coefficient.

%% Properties allowed to be changed by the optimizer or class itself    
    properties
        Vars;       % Input variables
        Params;     % Input parameters
        Structs;    % Input structs
        C_d_w;      % Aerodynamics output
    end

    properties (SetAccess = private, GetAccess = private)
        temp_dir            % Temporary Directory for Q3D Runs
    end
    
    methods     
        function obj = Aerodynamics(aircraft_in)
        %Setting the fuel weight, wing weight and geometry

            % Extracting input variables
            obj.Vars.W_f = aircraft_in.W_f;    % Guess value fuel weight[kg]
            obj.Vars.W_w = aircraft_in.W_w;    % Guess value wing weight [kg]
            obj.Vars.A_r = aircraft_in.A_root.';   % Root chord coefficients
            obj.Vars.A_k = aircraft_in.A_kink.';   % Kink airfoil coeffs.
            obj.Vars.A_t = aircraft_in.A_tip.';    % Tip chord coefficients
            obj.Vars.Chords = aircraft_in.planform.Chords;  % Wing section chord lengths [m]
            obj.Vars.Coords = aircraft_in.planform.Coords;  % Leading edge coordinates [m]
            obj.Vars.Twists = aircraft_in.planform.Twists;  % Wing section twist angles [deg]
            obj.Vars.S = aircraft_in.planform.S;            % Wing planform area [m^2]
            obj.Vars.MAC = aircraft_in.planform.MAC;        % Wing mean aerodynamic chord [m]
            obj.Vars.b = aircraft_in.planform.b;            % Wing span [m]

            % Extracting input parameters
            obj.Params.h = aircraft_in.h_c;         % Cruise altitude [m]
            obj.Params.M_c = aircraft_in.M_c;       % Cruise Mach number [-]
            obj.Params.a_c = aircraft_in.a_c;       % Speed of sound at cruise [m/s]
            obj.Params.rho = aircraft_in.rho_c;     % Air density at cruise [kg/m^3]
            obj.Params.g = aircraft_in.g;           % Acceleration due to gravity [m/s^2]
            obj.Params.W_aw = aircraft_in.W_aw;     % Empty aircraft-less weight [kg]
            obj.Params.W_p = aircraft_in.W_p;       % Design payload weight [kg]
            obj.Params.v = aircraft_in.v;           % Kinematic viscosity at cruise [m^2/s]
            obj.Params.d_TE = aircraft_in.d_TE;     % Straight trailing edge length [m]


            obj.Structs.p = aircraft_in.planform;

            % Creating the Q3D input struct
            obj.Structs.AC = obj.fetch_AC();
            
            % Creating Temporary Directory
            obj.make_temp_dir();

            % Running Q3D
            obj.Structs.Res = obj.run_Q3D();

            % Extracting the wing drag coefficient
            obj.C_d_w = obj.fetch_C_dw();
            
            % Cleaning-up Temporary Directory
            obj.cleanup();
        end
    
        function AC = fetch_AC(obj)
        % Building the Q3D input struct 

            % Maximum take-off weight calculation [kg]
            MTOW = obj.Params.W_aw + obj.Vars.W_f + obj.Vars.W_w;

            % Aircraft weight at design point [kg]
            W_des = sqrt(MTOW*(MTOW - obj.Vars.W_f));

            % Cruise speed [m/s]
            V_c = obj.Params.M_c*obj.Params.a_c;

            % Calculation of design lift coefficient
            C_L = obj.Params.g*W_des/(0.5*obj.Params.rho*obj.Vars.S*V_c^2);

            % Building the struct based on input geometry, parameters and
            % design lift coefficient.
            AC.Wing.Geom = [obj.Vars.Coords, obj.Vars.Chords.', obj.Vars.Twists.'];
            AC.Wing.inc = 0;
            AC.Wing.eta = [0;2*obj.Params.d_TE/obj.Vars.b;1];
            AC.Visc = 1;
            AC.Wing.Airfoils = [obj.Vars.A_r; obj.Vars.A_k; obj.Vars.A_t];
            AC.Aero.rho = obj.Params.rho;
            AC.Aero.alt = obj.Params.h;
            AC.Aero.M = obj.Params.M_c;
            AC.Aero.Re = V_c*obj.Vars.MAC/obj.Params.v;

            AC.Aero.V = V_c;
            AC.Aero.CL = C_L;
        end

        function res = run_Q3D(obj)
        % Running Q3D
            try
                tic;
                working_dir = cd;
                cd(obj.temp_dir)
                res = Q3D(obj.Structs.AC);
                cd(working_dir);
                t = toc;
                fprintf('Q3D Viscous took: %.5f [s]\n', t)
            catch e
                error(e.message);
            end
        end
    
        function Cd = fetch_C_dw(obj)
        % Extracting Drag Coefficient
           Cd = obj.Structs.Res.CDwing;
        end
    end

    methods (Access = private)
        function make_temp_dir(obj)
            % Creates a temporary directory pertaining to the current
            % worker_ID for EMWET if parallel processing is enabled.
            % Otherwise a 'serial_exec' folder is created. The EMWET.p
            % file is also copied to this directory
            try
                w = getCurrentWorker;
                worker_ID = w.ProcessId;
            catch
                warning(['Parallel Processing Disabled ' ...
                         'or not Installed on Machine'])
                worker_ID = 'serial_exec';
            end

            obj.temp_dir = [pwd '\temp\Q3D\Aero\'...
                            num2str(worker_ID)];
                        
            mkdir(obj.temp_dir)

            % Copying EMWET to New Worker Directory
            copyfile([pwd '\bin\Q3D.p'], obj.temp_dir);
            copyfile([pwd '\bin\Storage'], [obj.temp_dir '\Storage']);
        end
        
        function cleanup(obj)
            rmdir(obj.temp_dir, 's');
        end
    end 
end
    
    



    
    
