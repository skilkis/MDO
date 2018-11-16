classdef Loads
%% Loads
% This class is responsible for the wing loading analysis. It calculates
% the section lift and moment distribution over the wing during the
% critical load case of flying at maximum load factor at dive speed while
% at maximum take-off weight. For this, an inviscid Q3D analysis is
% performed using the variables and parameters provided by the input
% struct. The output of this class is used in order to compare the load
% distribution resulting from the guess values of the load distribution
% coefficients, which are used in structural analysis. 

%% Class variables, parameters, structs and outputs
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
    
 %% Class Methods   
   methods
   function obj = Loads(aircraft_in)
       % Extracting the variables from the input struct
            obj.Vars.W_f = aircraft_in.W_f;    % Guess value fuel weight [kg]     
            obj.Vars.W_w = aircraft_in.W_w;    % Guess value wing weight [kg]
            obj.Vars.A_r = aircraft_in.airfoils.A_root.';   % Root chord coefficients
            obj.Vars.A_t = aircraft_in.airfoils.A_tip.';    % Tip chord coefficients
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
            
      % Building all output structs and fetching the analysis outputs      
            obj.Structs.AC = obj.fetch_AC();
            obj.Structs.Res = obj.fetch_Res();
            obj.Y_coord = obj.fetch_Y_coord();
            obj.L_distr = obj.fetch_L_distr();
            obj.M_distr = obj.fetch_M_distr();
   end 
   %% Creating the Q3D input struct
   function AC = fetch_AC(obj)
        
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
        AC.Wing.eta = [0;1];
        AC.Visc = 0;
        AC.Wing.Airfoils = [obj.Vars.A_r;obj.Vars.A_t];
        AC.Aero.rho = obj.Params.rho;
        AC.Aero.alt = obj.Params.h;
        AC.Aero.M = obj.Params.M_mo;
        AC.Aero.Re = V_c*obj.Vars.MAC/obj.Params.v;
        AC.Aero.V = V_c;
        AC.Aero.CL = C_L;
   end
    %% Initializing Q3D
   function res = fetch_Res(obj)
        res = aerodynamics.Q3D_solver(obj.Structs.AC);
   end
    %% Extracting the spanwise coordinates
   function Y = fetch_Y_coord(obj)
       
      Y = [0, obj.Structs.Res.Wing.Yst.', 0.5*obj.Vars.b]; 
       
   end
   
   %% Extracting the section lift distribution
    function L = fetch_L_distr(obj)
        
        Y = obj.Structs.Res.Wing.Yst;
        
        % Calculating dynamic pressure
        V_c = obj.Params.M_mo*obj.Params.a_c;
        q = 0.5*obj.Params.rho*obj.Vars.S*V_c^2;
        Ccl = obj.Structs.Res.Wing.ccl;
        
        % Extrapolating the lift at the root and tip using spline
        % extrapolation
        ends = interp1(Y,Ccl, [0;0.5*obj.Vars.b],'pchip','extrap');
        Ccl0 = ends(1);
        Ccl1 = ends(2);
        L = [Ccl0,Ccl.',Ccl1]*q;
    end
    
    %% Extracting section moment distribution
    function M = fetch_M_distr(obj)
        V_c = obj.Params.M_mo*obj.Params.a_c;
        
        % Calculating dynamic pressure
        q = 0.5*obj.Params.rho*obj.Vars.S*V_c^2;
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
   
end
