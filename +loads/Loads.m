classdef Loads
    properties
        

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
        A_r;
        A_t;
        b;
        p;

        h;          % Cruise altitude[m]
        a_c;
        M_mo;
        
        rho;        % Cruise altitude air density[kg m^-3]

        g;           % Acceleration due to gravity[ms^-2]
        n;        % Maximum load factor
        v;      % Viscosity of air at 215 K[m^2s^-1]
        W_aw;       % Aircraft less wing weight[kg]
        W_pl_des;    % Design payload weight [kg]
        n_max;
        
    end
   methods
   function obj = Loads(aircraft_in)
            obj.W_f = aircraft_in.W_f;
            obj.W_w = aircraft_in.W_w;
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
            obj.a_c = aircraft_in.a_c;
            obj.M_mo = aircraft_in.M_mo;
            obj.rho = aircraft_in.rho_c;
            obj.g = aircraft_in.g;
            obj.n_max = aircraft_in.eta_max;
            obj.v = aircraft_in.v;
            obj.W_aw = aircraft_in.W_aw;
            
            obj.Res = obj.fetch_Res();
   end 
   
   function AC = get.AC(obj)
        
        MTOW = obj.W_aw + obj.W_pl_des + obj.W_f + obj.W_w;
        
        V_c = obj.M_mo*obj.a_c;
        
        C_L = obj.n_max*obj.g*MTOW/(0.5*obj.rho*obj.S*V_c^2);
        AC.Wing.Geom = [obj.Coords, obj.Chords.', obj.Twists.'];
        AC.Wing.inc = 0;
        
        AC.Wing.eta = [0;1];
        AC.Visc = 0;
        AC.Wing.Airfoils = [obj.A_r;obj.A_t];
        AC.Aero.rho = obj.rho;
        AC.Aero.alt = obj.h;
        AC.Aero.M = obj.M_mo;
        AC.Aero.Re = V_c*obj.MAC/obj.v;

        AC.Aero.V = obj.M_mo*obj.a_c;
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

        V_c = obj.M_mo*obj.a_c;
        q = 0.5*obj.rho*obj.S*V_c^2;
        Ccl = obj.Res.Wing.ccl;
        
        ends = interp1(Y,Ccl, [0;0.5*obj.b],'pchip','extrap');
        Ccl0 = ends(1);
        Ccl1 = ends(2);
        L = [Ccl0,Ccl.',Ccl1]*q;
    end
    function M = get.M_distr(obj)
        V_c = obj.M_mo*obj.a_c;
        
        q = 0.5*obj.rho*obj.S*V_c^2;
        Y = obj.Res.Wing.Yst;
        Cm = obj.Res.Wing.cm_c4;
        ends = interp1(Y,Cm, [0; 0.5*obj.b],'pchip','extrap');
        Cm0 = ends(1);
        Cm1 = ends(2);
        M = [Cm0,Cm.',Cm1].*q.*[obj.Chords(1), obj.Res.Wing.chord.',...
            obj.Chords(3)].*obj.MAC;
    end
   end
   
end
