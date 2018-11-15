classdef Performance < handle
    %Class capable of calculating the fuel weight required for the aircraft
    %to fly its mission
    %% Performance Properties
   properties
       W_fuel
       
   end
   %% Fuel Weight Calculations
   methods
       function obj = Performanc(aircraft_in)
          
          M_c = aircraft_in.M_c;
          V_c = M_c*aircraft_in.a_c;
          W_f = aircraft_in.W_f;
          MTOW = aircraft_in.W_aw + aircraft_in.W_w + W_f;
          W_des = sqrt(MTOW(MTOW-W_f));
          C_L = W_des*aircraft_in.g/(0.5*aircraft_in.rho_c*...
              aircraft_in.planform.S);
          C_D = aircraft_in.C_dw;
          R_c = aircraft_in.R_c*1000;
          C_T = aircraft_in.C_T;
          
          obj.W_fuel = (1 - 0.938*exp(R_c*C_T*C_D/(V_c*C_L)))*MTOW;
          
          
       end
       
   end
   
    
end
    