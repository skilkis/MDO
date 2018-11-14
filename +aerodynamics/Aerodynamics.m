% clear all
% close all
% clc



classdef Aerodynamics
%% Properties allowed to be changed by the optimizer or class itself    
    properties
        %Root chord Bernstein coefficients
        A_r;% = [0.2081    0.2645   0.1419     0.2872  0.1349  0.2845...
       %-0.1230   -0.1419     -0.1727     -0.1080     -0.1503     -0.1197];
        %Tip chord Bernstein coefficients
        A_t;% = 0.66666*[0.2081    0.2645   0.1419     0.2872  0.1349  0.2845...
      %-0.1230   -0.1419     -0.1727     -0.1080     -0.1503     -0.1197];
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
        p;
    end
 %% Set parameters   
    properties(SetAccess = 'private')
        h = 11248;          %Cruise altitude[m]
        
        M_c = 0.6;          %Cruise Mach number
        rho = 0.589;        %Cruise altitude air density[kg m^-3]
 %       W_pl = 17670;       %Design payload weight[kg]
        g = 9.81;           %Acceleration due to gravity[ms^-2]
        v = 8*10^(-6);       %Viscosity of air at 215 K[m^2s^-1]
        W_aw = 38400;       %Aircraft less wing weight[kg]
      
    end
    

    
    methods
%% Setting the fuel weight, wing weight        
   function obj = Aerodynamics(x,P)
            obj.W_f = x.W_f_hat;
            obj.W_w = x.W_w_hat;
            obj.A_r = [0.2257, 0.1039, 0.2244, 0.1359, 0.2463, 0.3951, -0.2233,...
                -0.1597, -0.0684, -0.454, 0.0619, 0.3303];%x.A_root.';
            obj.A_t = [0.2257, 0.1039, 0.2244, 0.1359, 0.2463, 0.3951, -0.2233,...
                -0.1597, -0.0684, -0.454, 0.0619, 0.3303];%x.A_tip.';
            obj.Chords = P.Chords;
            obj.Coords = P.Coords;
            obj.Twists = [0 0 0];%P.Twists;
            obj.S = P.S;
            obj.MAC = P.MAC;
            obj.p = P;
            
            obj.Res = obj.fetch_Res();
            
            
   end 
        
        function AC = get.AC(obj)
            P = obj.p;
            MTOW = obj.W_aw + obj.W_f + obj.W_w;
            W_des = sqrt(MTOW*(MTOW - obj.W_f));
            T_c = 288.15 - 0.0065*obj.h;
            
            V_c = obj.M_c*sqrt(1.4*287*T_c/(1+0.2*obj.M_c^2));
            
            C_L = obj.g*W_des/(0.5*obj.rho*obj.S*V_c^2);
            AC.Wing.Geom = [obj.Coords, obj.Chords.', obj.Twists.'];
            AC.Wing.inc = 0;
            AC.Wing.eta = [0;2*P.gamma/P.b;1];
            AC.Visc = 1;
            AC.Wing.Airfoils = [obj.A_r;obj.A_r - (obj.A_r-obj.A_t)*2*P.gamma/P.b;obj.A_t];
            AC.Aero.rho = obj.rho;
            AC.Aero.alt = obj.h;
            AC.Aero.M = obj.M_c;%obj.V_c/sqrt(1.4*287*215.038);
            AC.Aero.Re = V_c*obj.MAC/obj.v;
            
            AC.Aero.V = obj.M_c*sqrt(1.4*287*T_c/(1+0.2*obj.M_c^2));
            AC.Aero.CL = C_L;
            
            
        end
        
        function res = fetch_Res(obj)
           tic; 
           res = aerodynamics.Q3D_solver(obj.AC);
           t=toc; disp(['Simulation time: ', num2str(t),' s']);
        end
        function Cd = get.C_dw(obj)
           Cd = obj.Res.CDwing;
%            if isnan(cd) == 1
%                Cd = 1000;
%            else
%                Cd = cd;
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
    
    



    
    
