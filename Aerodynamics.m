clear all
close all
clc


%% Aerodynamic solver setting
P = Planform;       %Planform class transforms geometry variables in 
                    %functional variables.
% Wing planform geometry 
%                x    y     z   chord(m)    twist angle (deg) 


AC.Wing.Geom = [P.Coords,P.Chords.',P.Twists.'];

% Wing incidence angle (degree)
AC.Wing.inc  = 0;   
            
            
% Airfoil coefficients input matrix
%                    | ->     upper curve coeff.                <-|   | ->       lower curve coeff.       <-| 
AC.Wing.Airfoils   = [0.2171    0.3450    0.2975    0.2685    0.2893  -0.1299   -0.2388   -0.1635   -0.0476    0.0797;
                      0.2171    0.3450    0.2975    0.2685    0.2893  -0.1299   -0.2388   -0.1635   -0.0476    0.0797];
AC.Wing.eta = [0;1];%P.eta.';  % Spanwise location of the airfoil sections

% Viscous vs inviscid
              % 0 for inviscid and 1 for viscous analysis
a_h = 303.25;              % Speed of sound at altitude of 30000 ft
v_h = 13.19*10^-6;         % Air viscosity at T = 280 K
mac = P.MAC;
% Flight Condition

AC.Aero.rho   = 0.46;         % air density  (kg/m3)
AC.Aero.alt   = 9120;             % flight altitude (m)
AC.Aero.M     = 0.79;           % flight Mach number 
AC.Aero.V     = AC.Aero.M*a_h;            % flight speed (m/s)
AC.Aero.Re    = mac*AC.Aero.V/v_h;        % reynolds number (bqased on mean aerodynamic chord)

AC.Aero.CL    = 0.5;          % lift coefficient - comment this line to run the code for given alpha%
             % angle of attack -  comment this line to run the code for given cl 

% 
alpharange = linspace(0,5,20);
for i = 1:length(alpharange)
    AC.Aero.Alpha = alpharange(i);
    disp(alpharange(i))
    AC.Visc  = 1;
    Res_vis = Q3D_solver(AC);
    AC.Visc = 0;
    Res_invis = Q3D_solver(AC);
    Cd0(i) = Res_vis.CDwing - Res_invis.CDiwing;
    CL(i) = Res_invis.CLwing;
    CD_v(i) = Res_vis.CDwing;
    CD_inv(i) = Res_invis.CDiwing;
    
end

