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
    end
        
    properties(SetAccess = 'private')
    h = 11248;          % Cruise altitude[m]
    V_c = 231.5;        % Cruise speed[m/s]
    rho = 0.589;        % Cruise altitude air density[kg m^-3]
%       W_pl = 17670;   % Design payload weight[kg]
    g = 9.81;           % Acceleration due to gravity[ms^-2]
    v = 8*10^(-6);      % Viscosity of air at 215 K[m^2s^-1]
    W_aw = 38400;       % Aircraft less wing weight[kg]
    W_f0 = 23330;       % A320-200 design fuel weight[kg]
    W_w0 = 9600;        % A320-200 wing weight[kg]
    A_r0 = [0.2081    0.2645   0.1419     0.2872  0.1349  0.2845...
    -0.1230   -0.1419     -0.1727     -0.1080     -0.1503     -0.1197];
    %Tip chord Bernstein coefficients
    A_t0 = 0.66666*[0.2081    0.2645   0.1419     0.2872  0.1349  0.2845...
    -0.1230   -0.1419     -0.1727     -0.1080     -0.1503     -0.1197];
        
        
    end
   methods
   function obj = Loads(x_wf, x_ww, x_ar, x_at, P)
            obj.W_f = x_wf*obj.W_f0;
            obj.W_w = x_ww*obj.W_w0;
            obj.A_r = x_ar.*obj.A_r0;
            obj.A_t = x_at.*obj.A_t0;
            obj.Chords = P.Chords;
            obj.Coords = P.Coords;
            obj.Twists = P.Twists;
            obj.S = P.S;
            obj.MAC = P.MAC;
            obj.b = P.b;
   end 
   
   function AC = get.AC(obj)

    MTOW = obj.W_aw + obj.W_f + obj.W_w;
    W_des = sqrt(MTOW*(MTOW - obj.W_f));

    C_L = obj.g*W_des/(0.5*obj.rho*obj.S*obj.V_c^2);
    AC.Wing.Geom = [obj.Coords, obj.Chords.', obj.Twists.'];
    AC.Wing.inc = 0;
    AC.Wing.eta = [0;1];
    AC.Visc = 0;
    AC.Wing.Airfoils = [obj.A_r;obj.A_t];
    AC.Aero.rho = obj.rho;
    AC.Aero.alt = obj.h;
    AC.Aero.M = obj.V_c/sqrt(1.4*287.05*215.038);
    AC.Aero.Re = obj.V_c*obj.MAC/obj.v;
    AC.Aero.V = obj.V_c;
    AC.Aero.CL = C_L;

   end
    
   function res = get.Res(obj)
   res = aerodynamics.Q3D_solver(obj.AC);
   end
    
   function Y = get.Y_coord(obj)
      Y = [0, obj.Res.Wing.Yst.', 0.5*obj.b]; 
       
   end
    function L = get.L_distr(obj)
        q = 0.5*obj.rho*obj.S*obj.V_c^2;
        Y = obj.Res.Wing.Yst;
        
        Ccl = obj.Res.Wing.ccl;
        ends = interp1(Y,Ccl, [0;0.5*obj.b],'pchip','extrap');
        Ccl0 = ends(1);
        Ccl1 = ends(2);
        L = [Ccl0,Ccl.',Ccl1]*q;
    end
    function M = get.M_distr(obj)
        q = 0.5*obj.rho*obj.S*obj.V_c^2;
        Y = obj.Res.Wing.Yst;
        Cm = obj.Res.Wing.cm_c4;
        ends = interp1(Y,Cm, [0; 0.5*obj.b],'pchip','extrap');
        Cm0 = ends(1);
        Cm1 = ends(2);
        M = [Cm0,Cm.',Cm1].*q.*[obj.Chords(1), obj.Res.Wing.chord.',obj.Chords(3)].*obj.MAC;
    end
   end
    
end
