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
        h = 11248;          %Cruise altitude[m]
        
        M_c = 0.787;          %Cruise Mach number
        rho = 0.589;        %Cruise altitude air density[kg m^-3]
 %       W_pl = 17670;       %Design payload weight[kg]
        g = 9.81;           %Acceleration due to gravity[ms^-2]
        v = 8*10^(-6);       %Viscosity of air at 215 K[m^2s^-1]
        W_aw = 38400;       %Aircraft less wing weight[kg]
    end
 %% Set parameters   
    properties(SetAccess = 'private')

      
    end
    

    
    methods
%% Setting the fuel weight, wing weight and geometry        
   function obj = Aerodynamics(aircraft_in)
            
            obj.W_f = aircraft_in.W_f_hat;    %Extracting fuel weight from design vector
            obj.W_w = aircraft_in.W_w_hat;    %Extracting wing weight from design vector
            obj.A_r = aircraft_in.A_root.';   %Extracting root coeffcients
            obj.A_t = aircraft_in.A_tip.';    %Extracting tip coefficients
            obj.Chords = aircraft_in.Planform.Chords;  %Chords based on Planform class
            obj.Coords = aircraft_in.Planform.Coords;  
            obj.Twists = aircraft_in.Planform.Twists;
            obj.S = aircraft_in.Planform.S;
            obj.MAC = aircraft_in.Planform.MAC;
            obj.p = aircraft_in.Planform;
            
            obj.h = aircraft_in.h_c;
            obj.M_c = aircraft_in.M_c;
            obj.rho = aircraft_in.rho_c;
            obj.g = aircraft_in.g;
            obj.W_aw = aircraft_in.W_aw;
            obj.v = aircraft_in.v;
            
            obj.Res = obj.fetch_Res();
            
            
   end 
        
        function AC = get.AC(obj)
            
            MTOW = obj.W_aw + obj.W_f + obj.W_w;
            W_des = sqrt(MTOW*(MTOW - obj.W_f));
            T_c = 288.15 - 0.0065*obj.h;
            
            V_c = obj.M_c*sqrt(1.4*287*T_c/(1+0.2*obj.M_c^2));
            
            C_L = obj.g*W_des/(0.5*obj.rho*obj.S*V_c^2);
            AC.Wing.Geom = [obj.Coords, obj.Chords.', obj.Twists.'];
            AC.Wing.inc = 0;
            AC.Wing.eta = [0;1];
            AC.Visc = 1;
            AC.Wing.Airfoils = [obj.A_r;obj.A_t];
            AC.Aero.rho = obj.rho;
            AC.Aero.alt = obj.h;
            AC.Aero.M = obj.M_c;
            AC.Aero.Re = V_c*obj.MAC/obj.v;
            
            AC.Aero.V = obj.M_c*sqrt(1.4*287*T_c/(1+0.2*obj.M_c^2));
            AC.Aero.CL = C_L;
            
            
        end
        
        function res = fetch_Res(obj)
           
           res = aerodynamics.Q3D_solver(obj.AC);
           
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
    
    



    
    
