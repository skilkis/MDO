% Copyright 2018 Evert Bunschoten
% 
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
% 
%    http://www.apache.org/licenses/LICENSE-2.0
% 
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.

classdef Performance < handle
    %Class capable of calculating the fuel weight required for the aircraft
    %to fly its mission
    %% Performance Properties
   properties
       
       % Required fuel weight [kg]
       W_fuel
       
   end
   %% Fuel Weight Calculations
   methods
       function obj = Performance(aircraft_in)
          
           
          M_c = aircraft_in.M_c;        % Cruise Mach number [-]
          V_c = M_c*aircraft_in.a_c;    % Cruise velocity [m/s]
          W_f = aircraft_in.W_f;        % Guess value fuel weight [kg]
          W_p = aircraft_in.W_p;        % Design payload weight [kg]
          S = aircraft_in.planform.S;   % Wing planform area [m^2]
          R_c = aircraft_in.R_c*1000;   % Cruise range [m]
          C_T = aircraft_in.C_T;        % Specific fuel consumption [kg/Ns]
          
          % Calculating the design lift coeffcient
          MTOW = aircraft_in.W_aw + aircraft_in.W_w + W_f + W_p;
          W_des = sqrt(MTOW*(MTOW-W_f));
          
          C_L = W_des*aircraft_in.g/(0.5*aircraft_in.rho_c*...
              S*V_c^2);
          
          % Calculating the drag coefficient with aircraft-less wing drag
          % corrected with current planform area
          C_D = aircraft_in.C_d_w + aircraft_in.C_d_aw*aircraft_in.S/S;
          
          % Calculating the fuel required for the mission
          obj.W_fuel = (1 - 0.938*exp(-aircraft_in.g*R_c*C_T*C_D/(V_c*C_L)))*MTOW;
          
          
       end
       
   end
   
    
end
    