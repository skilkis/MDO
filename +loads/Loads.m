classdef Loads
    %% Class Variable Properties
    properties
        %Root chord Bernstein coefficients

        W_f;         %Design fuel weight[kg]
        W_w;         %Wing weight[kg]
        Chords;      %Wing chords[m]
        Coords;      %Wing LE coordinates[m]
        Twists;      %Wing twist angles at root, kink and tip[deg]
        S;           %Wing surface area[m^2]
        MAC;         %Mean aerodynamic chord[m]
        AC;          %Q3D input struct containing all geometric and aerodynamic inputs
        Res;         %Q3D output struct
        Y_coord;     %Y coordinates along which the loads are evaluated
        L_distr;     %Lift distribution array[N]
        M_distr;     %Moment distribution array[Nm]
        A_r;         %Root chord Bernstein coefficient array
        A_t;         %Tip chord Bernstein coefficient array
        b;           %Wing span[m]
    end
 %% Class Parameters and initial values       
    properties(SetAccess = 'private')
    h = 11248;          %Cruise altitude[m]
    V_c = 231.5;        %Cruise speed[m/s]
    rho = 0.589;        %Cruise altitude air density[kg m^-3]
    g = 9.81;           %Acceleration due to gravity[ms^-2]
    v = 8*10^(-6);       %Viscosity of air at 215 K[m^2s^-1]
    W_aw = 38400;       %Aircraft less wing weight[kg]
    W_f0 = 23330;       %A320-200 design fuel weight[kg]
    W_w0 = 9600;        %A320-200 wing weight[kg]
    %Root chord initial Bernstein coefficients
    A_r0 = [0.2081    0.2645   0.1419     0.2872  0.1349  0.2845...
    -0.1230   -0.1419     -0.1727     -0.1080     -0.1503     -0.1197];
    %Tip chord initial Bernstein coefficients
    A_t0 = 0.66666*[0.2081    0.2645   0.1419     0.2872  0.1349  0.2845...
    -0.1230   -0.1419     -0.1727     -0.1080     -0.1503     -0.1197];
        
        
    end
    %% Class initialization
   methods
   function obj = Loads(x_wf, x_ww, x_ar, x_at, P)
       %This method initializes the Loads anaysis block, where the
       %normalized guess values for wing weight and fuel weight, as well as
       %the normalized values for all bernstein coefficients have to be
       %inserted. P is the Planform class that calculates all geometric
       %wing parameters.
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
   %% Q3D input struct maker
   function AC = get.AC(obj)
       %This method constructs the Q3D input struct.

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
    AC.Aero.M = obj.V_c/sqrt(1.4*287*215.038);
    AC.Aero.Re = obj.V_c*obj.MAC/obj.v;
    AC.Aero.V = obj.V_c;
    AC.Aero.CL = C_L;

   end
 %% Result struct maker
   function res = get.Res(obj)
       %This one initializes Q3D to obtain the result struct from which
       %wing lift and moment distributions will be obtained.
   res = aerodynamics.Q3D_solver(obj.AC);
   end
 %% Lift, Y and moment distributions   
   function Y = get.Y_coord(obj)
       %Here, the y coordinate array is made. The array from the Q3D
       %results is augmented with root and tip coordinates.
      Y = [0, obj.Res.Wing.Yst.', 0.5*obj.b]; 
       
   end
    function L = get.L_distr(obj)
        %Here, the lift distribution of the wing is calculated and the root
        %and tip values are extrapolated using spline extrapolation.
        q = 0.5*obj.rho*obj.S*obj.V_c^2;
        Y = obj.Res.Wing.Yst;
        
        Ccl = obj.Res.Wing.ccl;
        ends = interp1(Y,Ccl, [0;0.5*obj.b],'pchip','extrap');
        Ccl0 = ends(1);
        Ccl1 = ends(2);
        L = [Ccl0,Ccl.',Ccl1]*q;
    end
    function M = get.M_distr(obj)
        %Here, the moment distribution is calculated using the result
        %struct from Q3D. The moment values at the root and tip are
        %obtained using spline extrapolation.
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
