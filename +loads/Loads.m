classdef Loads
    properties
        %Root chord Bernstein coefficients

        W_f;         %Design fuel weight[kg]
        W_w;         %Wing weight[kg]
        Chords;
        Coords;
        Twists;
        C_dwing;
        S;
        MAC;
        AC;
        Res;
        C_dw;
        Y_coord;
        L_distr;
        M_distr;
        A_r;% = ones(1,12);
        A_t;% = ones(1,12);
        b;
        p;

    h = 11248;          % Cruise altitude[m]
    
    M_c;
    rho;        % Cruise altitude air density[kg m^-3]

    g;           % Acceleration due to gravity[ms^-2]
    n;        % Maximum load factor
    v;      % Viscosity of air at 215 K[m^2s^-1]
    W_aw;       % Aircraft less wing weight[kg]
    
        
    end
   methods
   function obj = Loads(aircraft_in)
            obj.W_f = aircraft_in.W_f_hat;
            obj.W_w = aircraft_in.W_w_hat;
            obj.A_r = aircraft_in.A_root.';
            obj.A_t = aircraft_in.A_tip.';
            obj.Chords = aircraft_in.Chords;
            obj.Coords = aircraft_in.Coords;
            obj.Twists = aircraft_in.Twists;
            obj.S = aircraft_in.planform.S;
            obj.MAC = aircraft_in.planform.MAC;
            obj.b = aircraft_in.planform.b;
            obj.p = aircraft_in.planform;
            
            obj.h = aircraft_in.h_c;
            obj.M_c = aircraft_in.M_c;
            obj.rho = aircraft_in.rho_c;
            obj.g = aircraft_in.g;
            obj.n_max = aircraft_in.n_max;
            obj.v = aircraft_in.v;
            obj.W_aw = aircraft_in.W_aw;
            
            obj.Res = obj.fetch_Res();
   end 
   
   function AC = get.AC(obj)
        P = obj.p;
        MTOW = obj.W_aw + obj.W_f + obj.W_w;
        W_des = sqrt(MTOW*(MTOW - obj.W_f));
        T_c = 288.15 - 0.0065*obj.h;

        V_c = obj.M_c*sqrt(1.4*287*T_c/(1+0.2*obj.M_c^2));

        C_L = obj.n_max*obj.g*W_des/(0.5*obj.rho*obj.S*V_c^2);
        AC.Wing.Geom = [obj.Coords, obj.Chords.', obj.Twists.'];
        AC.Wing.inc = 0;
        %AC.Wing.eta = [0;2*P.gamma/P.b;1];
        AC.Wing.eta = [0;1];
        AC.Visc = 0;
        %AC.Wing.Airfoils = [obj.A_r;obj.A_r - (obj.A_r-obj.A_t)*2*P.gamma/P.b;obj.A_t];
        AC.Wing.Airfoils = [obj.A_r;obj.A_t];
        AC.Aero.rho = obj.rho;
        AC.Aero.alt = obj.h;
        AC.Aero.M = obj.M_c;%obj.V_c/sqrt(1.4*287*215.038);
        AC.Aero.Re = V_c*obj.MAC/obj.v;

        AC.Aero.V = obj.M_c*sqrt(1.4*287*T_c/(1+0.2*obj.M_c^2));
        AC.Aero.CL = C_L;
   end
    
   function res = fetch_Res(obj)
   res = aerodynamics.Q3D_solver(obj.AC);
   end
    
   function Y = get.Y_coord(obj)
       
      Y = [0, obj.Res.Wing.Yst.', 0.5*obj.b]; 
       
   end
    function L = get.L_distr(obj)
        
        Y = obj.Res.Wing.Yst;
        T_c = 288.15 - 0.0065*obj.h;

        V_c = obj.M_c*sqrt(1.4*287*T_c/(1+0.2*obj.M_c^2));
        q = 0.5*obj.rho*obj.S*V_c^2;
        Ccl = obj.Res.Wing.ccl;
        
        ends = interp1(Y,Ccl, [0;0.5*obj.b],'pchip','extrap');
        Ccl0 = ends(1);
        Ccl1 = ends(2);
        L = [Ccl0,Ccl.',Ccl1]*q;
    end
    function M = get.M_distr(obj)
        T_c = 288.15 - 0.0065*obj.h;

        V_c = obj.M_c*sqrt(1.4*287*T_c/(1+0.2*obj.M_c^2));
        q = 0.5*obj.rho*obj.S*V_c^2;
        Y = obj.Res.Wing.Yst;
        Cm = obj.Res.Wing.cm_c4;
        ends = interp1(Y,Cm, [0; 0.5*obj.b],'pchip','extrap');
        Cm0 = ends(1);
        Cm1 = ends(2);
        M = [Cm0,Cm.',Cm1].*q.*[obj.Chords(1), obj.Res.Wing.chord.',obj.Chords(3)].*obj.MAC;
    end
   end
   
end
