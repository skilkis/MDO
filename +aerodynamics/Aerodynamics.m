% clear all
% close all
% clc



classdef Aerodynamics
%% Properties allowed to be changed by the optimizer or class itself    
    properties
        %Root chord Bernstein coefficients
        A_r = [0.2081    0.2645   0.1419     0.2872  0.1349  0.2845...
       -0.1230   -0.1419     -0.1727     -0.1080     -0.1503     -0.1197];
        %Tip chord Bernstein coefficients
        A_t = 0.66666*[0.2081    0.2645   0.1419     0.2872  0.1349  0.2845...
      -0.1230   -0.1419     -0.1727     -0.1080     -0.1503     -0.1197];
        W_f;         %Design fuel weight[kg]
        W_w;         %Wing weight[kg]
        Chords;
        Coords;
        Twists;
        S;
        MAC;
        AC;
        Res;
        C_dw;
        
    end
 %% Set parameters   
    properties(SetAccess = 'private')
        h = 11248;          %Cruise altitude[m]
        V_c = 231.5;        %Cruise speed[m/s]
        rho = 0.589;        %Cruise altitude air density[kg m^-3]
 %       W_pl = 17670;       %Design payload weight[kg]
        g = 9.81;           %Acceleration due to gravity[ms^-2]
        v = 8*10^(-6);       %Viscosity of air at 215 K[m^2s^-1]
        W_aw = 38400;       %Aircraft less wing weight[kg]
        W_f0 = 23330;       %A320-200 design fuel weight[kg]
        W_w0 = 9600;        %A320-200 wing weight[kg]
         A_r0 = [0.2081    0.2645   0.1419     0.2872  0.1349  0.2845...
        -0.1230   -0.1419     -0.1727     -0.1080     -0.1503     -0.1197];
        %Tip chord Bernstein coefficients
        A_t0 = 0.66666*[0.2081    0.2645   0.1419     0.2872  0.1349  0.2845...
        -0.1230   -0.1419     -0.1727     -0.1080     -0.1503     -0.1197];

        
    end
    

    
    methods
%% Setting the fuel weight, wing weight        
   function obj = Aerodynamics(x_wf, x_ww, x_ar, x_at, P)
            obj.W_f = x_wf*obj.W_f0;
            obj.W_w = x_ww*obj.W_w0;
            obj.A_r = x_ar.*obj.A_r0;
            obj.A_t = x_at.*obj.A_t0;
            obj.Chords = P.Chords;
            obj.Coords = P.Coords;
            obj.Twists = P.Twists;
            obj.S = P.S;
            obj.MAC = P.MAC;
            
   end 
        
        function AC = get.AC(obj)
           
            MTOW = obj.W_aw + obj.W_f + obj.W_w;
            W_des = sqrt(MTOW*(MTOW - obj.W_f));
            
            C_L = obj.g*W_des/(0.5*obj.rho*obj.S*obj.V_c^2);
            AC.Wing.Geom = [obj.Coords, obj.Chords.', obj.Twists.'];
            AC.Wing.inc = 0;
            AC.Wing.eta = [0;1];
            AC.Visc = 1;
            AC.Wing.Airfoils = [obj.A_r;obj.A_t];
            AC.Aero.rho = obj.rho;
            AC.Aero.alt = obj.h;
            AC.Aero.M = obj.V_c/sqrt(1.4*287*215.038);
            AC.Aero.Re = obj.V_c*obj.MAC/obj.v;
            AC.Aero.V = obj.V_c;
            AC.Aero.CL = C_L;
            
        end
        
        function res = get.Res(obj)
           res = aerodynamics.Q3D_solver(obj.AC);
        end
        
        function Cd = get.C_dw(obj)
           cd = obj.Res.CDwing;
           if isnan(cd) == 1
               Cd = 1000;
           else
               Cd = cd;
           end
        end
        
%         function L = get.L_distr(obj)
%             q = 0.5*obj.rho*obj.S*obj.V_c^2;
%             Y = obj.Res.Wing.Yst;
%             Ccl = obj.Res.Wing.ccl;
%             Ccl0 = (Ccl(2)*Y(1) - Ccl(1)*Y(2))/(Y(1)-Y(2));
%             Ccl1 = ((Ccl(L-1)-Ccl(L))*0.5*P.b +Ccl(L)*Y(L-1)-Ccl(L-1)*Y(L))/(Y(L-1)-Y(L));
%             L = [Ccl0,Ccl.',Ccl1]*q;
%         end
         
        
    end
    
    
end


    
    
