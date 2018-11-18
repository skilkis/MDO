
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

classdef Loads < handle
% LOADS This class is responsible for the wing loading analysis. It calculates
% the section lift and moment distribution over the wing during the
% critical load case of flying at maximum load factor at dive speed while
% at maximum take-off weight. For this, an inviscid Q3D analysis is
% performed using the variables and parameters provided by the input
% struct. The output of this class is used in order to compare the load
% distribution resulting from the guess values of the load distribution
% coefficients, which are used in structural analysis.
%%

% Class variables, parameters, structs and outputs
    properties
    % Extracted variables    
        Vars;
    % Extracted parameters
        Params;
    % Input and output structs
        Structs;
        
    % Loads analysis outputs
        Y_coord;
        L_distr;
        M_distr;
    end

    properties (SetAccess = private, GetAccess = private)
        temp_dir            % Temporary Directory for Q3D Runs
    end
    
    methods
        function obj = Loads(aircraft_in)
            % Extracting the variables from the input struct
            obj.Vars.W_f = aircraft_in.W_f;    % Guess value fuel weight [kg]     
            obj.Vars.W_w = aircraft_in.W_w;    % Guess value wing weight [kg]
            obj.Vars.A_r = aircraft_in.A_root.';   % Root chord coefficients
            obj.Vars.A_k = aircraft_in.A_kink.';   % Kink airfoil coeffs.
            obj.Vars.A_t = aircraft_in.A_tip.';    % Tip chord coefficients
            obj.Vars.Chords = aircraft_in.planform.Chords;  % Wing section chords [m]
            obj.Vars.Coords = aircraft_in.planform.Coords;  % Leading edge coordinates [m]
            obj.Vars.Twists = aircraft_in.planform.Twists;  % Wing section twist angles [deg]
            obj.Vars.S = aircraft_in.planform.S;            % Wing planform area [m^2]
            obj.Vars.MAC = aircraft_in.planform.MAC;        % Wing mean aerodynamic chord [m]
            obj.Vars.b = aircraft_in.planform.b;            % Wing span [m]
            obj.Structs.p = aircraft_in.planform;           % Planform struct

            % Extracting the parameters from the input struct
            obj.Params.h = aircraft_in.h_c;             % Cruise altitude [m]
            obj.Params.a_c = aircraft_in.a_c;           % Speed of sound at cruise [m/s]
            obj.Params.M_mo = aircraft_in.M_mo;         % Dive Mach number [-]
            obj.Params.rho = aircraft_in.rho_c;         % Air density at [kg/m^3]
            obj.Params.g = aircraft_in.g;               % Acceleration due to gravity [m/s^2]
            obj.Params.n_max = aircraft_in.eta_max;     % Maximum load factor [-]
            obj.Params.v = aircraft_in.v;               % Kinematic viscosity [m^2/s]
            obj.Params.W_aw = aircraft_in.W_aw;         % Empty-less wing weight [kg]
            obj.Params.W_p = aircraft_in.W_p;           % Design payload weight [kg]
            obj.Params.d_TE = aircraft_in.d_TE;         % Straight trailing edge length [m]

            % Building all output structs and fetching the analysis outputs      
            obj.Structs.AC = obj.fetch_AC();
            obj.make_temp_dir();
            obj.Structs.Res = obj.run_Q3D();
            obj.Y_coord = obj.fetch_Y_coord();
            obj.L_distr = obj.fetch_L_distr();
            obj.M_distr = obj.fetch_M_distr();
            obj.cleanup();
        end 

        function AC = fetch_AC(obj)
        % Creating the Q3D input struct
            % Calculating maximum take-off weight
            MTOW = obj.Params.W_aw + obj.Params.W_p + obj.Vars.W_f + obj.Vars.W_w;

            % Calculating maximum dive speed
            V_c = obj.Params.M_mo*obj.Params.a_c;
            

            % Calculating lift coefficient based on maximum load factor
            C_L = obj.Params.n_max*obj.Params.g*MTOW/(0.5*obj.Params.rho*...
                obj.Vars.S*V_c^2);

            % Constructing the Q3D input struct with the variables and
            % calculated parameters
            AC.Wing.Geom = [obj.Vars.Coords, obj.Vars.Chords.', obj.Vars.Twists.'];
            AC.Wing.inc = 0;
            AC.Wing.eta = [0;2*obj.Params.d_TE/obj.Vars.b;1];
            AC.Visc = 0;
            AC.Wing.Airfoils = [obj.Vars.A_r; obj.Vars.A_k; obj.Vars.A_t];
            AC.Aero.rho = obj.Params.rho;
            AC.Aero.alt = obj.Params.h;
            AC.Aero.M = obj.Params.M_mo;
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
                    fprintf('Q3D Inviscid took: %.5f [s]\n', t)
                catch e
                    error(e.message);
                end
            end

        
            function Cd = fetch_C_dw(obj)
            % Extracting Drag Coefficient
               Cd = obj.Structs.Res.CDwing;
            end

        function Y = fetch_Y_coord(obj)
            % Extracting the spanwise coordinates
            Y = [0, obj.Structs.Res.Wing.Yst.', 0.5*obj.Vars.b]; 
        end

        function L = fetch_L_distr(obj)
        % Extracting the section lift distribution
            Y = obj.Structs.Res.Wing.Yst;

            % Calculating dynamic pressure
            V_c = obj.Params.M_mo*obj.Params.a_c;
            q = 0.5*obj.Params.rho*V_c^2;
            Ccl = obj.Structs.Res.Wing.ccl;

            % Extrapolating the lift at the root and tip using spline
            % extrapolation
            ends = interp1(Y,Ccl, [0;0.5*obj.Vars.b],'pchip','extrap');
            Ccl0 = ends(1);
            Ccl1 = ends(2);
            L = [Ccl0,Ccl.',Ccl1]*q;
        end
    
        function M = fetch_M_distr(obj)
        % Extracting section moment distribution
            V_c = obj.Params.M_mo*obj.Params.a_c;

            % Calculating dynamic pressure
            q = 0.5*obj.Params.rho*V_c^2;
            Y = obj.Structs.Res.Wing.Yst;
            Cm = obj.Structs.Res.Wing.cm_c4;

            % Extrapolating the moment at the root and tip using spline
            % extrapolation
            ends = interp1(Y,Cm, [0; 0.5*obj.Vars.b],'pchip','extrap');
            Cm0 = ends(1);
            Cm1 = ends(2);
            M = [Cm0,Cm.',Cm1].*q.*[obj.Vars.Chords(1), obj.Structs.Res.Wing.chord.',...
                obj.Vars.Chords(3)].*obj.Vars.MAC;
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

            obj.temp_dir = [pwd '\temp\Q3D\Loads\'...
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
