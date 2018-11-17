

classdef Aerodynamics
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

    

    
    methods
%% Setting the fuel weight, wing weight and geometry        
   function obj = Aerodynamics(aircraft_in)
            % Extracting input variables
            obj.Vars.W_f = aircraft_in.W_f;    % Guess value fuel weight[kg]
            obj.Vars.W_w = aircraft_in.W_w;    % Guess value wing weight [kg]
            obj.Vars.A_r = aircraft_in.A_root.';   % Root chord coefficients
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
            
            % Running Q3D
            obj.Structs.Res = obj.fetch_Res();
            
            % Extracting the wing drag coefficient
            obj.C_d_w = obj.fetch_C_dw();
            
            
            
   end 
%% Building the Q3D input struct        
        function AC = fetch_AC(obj)
            
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
            AC.Wing.Airfoils = [obj.Vars.A_r; 0.5*obj.Vars.A_r + 0.5*obj.Vars.A_t;...
                obj.Vars.A_t];
            AC.Aero.rho = obj.Params.rho;
            AC.Aero.alt = obj.Params.h;
            AC.Aero.M = obj.Params.M_c;
            AC.Aero.Re = V_c*obj.Vars.MAC/obj.Params.v;
            
            AC.Aero.V = V_c;
            AC.Aero.CL = C_L;
            
            
        end
 %% Running Q3D       
        function res = fetch_Res(obj)
            working_dir = cd;
            cd([pwd '\bin'])
            res = Q3D(obj.Structs.AC);
            cd(working_dir);
        end
        
%% Extracting the drag coefficient        
        function Cd = fetch_C_dw(obj)
           Cd = obj.Structs.Res.CDwing;

        end
        end

         
end
    
    



    
    
