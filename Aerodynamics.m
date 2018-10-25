clear all
close all
clc


%% Aerodynamic solver setting
P = Planform;       %Planform class transforms geometry variables in 
                    %functional variables.
MTOW = 78000;       %Maximum take-off weight[kg]. For now obtained from literature
W_f = 18837.72;     %Maximum fuel weight[kg]
W_des = sqrt(MTOW*(MTOW-W_f));      %Design weight, as specified in assignment


AC.Wing.Geom = [P.Coords,P.Chords.',P.Twists.'];    %Filling in the planform geometry

AC.Wing.inc  = 0;       %Wing incidence angle, not sure what to do with this just yet
  
            
            
% Airfoil coefficients input matrix
%                    | ->     upper curve coeff.                <-|   | ->       lower curve coeff.       <-| 
AC.Wing.Airfoils   = [0.2081    0.2645   0.1419     0.2872  0.1349  0.2845...
                      -0.1230   -0.1419     -0.1727     -0.1080     -0.1503     -0.1197;
                      0.66666*[0.2081    0.2645   0.1419     0.2872  0.1349  0.2845...
                      -0.1230   -0.1419     -0.1727     -0.1080     -0.1503     -0.1197]];
AC.Wing.eta = [0;1];  % Spanwise location of the airfoil sections

AC.Visc = 1;% Viscous vs inviscid
              % 0 for inviscid and 1 for viscous analysis
a_h = 303.25;              % Speed of sound at altitude of 30000 ft
v_h = 13.19*10^-6;         % Air viscosity at T = 280 K
mac = P.MAC;               % Mean Aerodynamic Chord, as calculated in P
rho = 0.46;                % Air density at 30000 ft, maybe replace this with a function
h = 9120;                  % Flight altitude[m]
M = 0.79;                  % Flight Mach number
V = M*a_h;                 % Airspeed, as calcualted with Mach number and speed of sound
Re = mac*V/v_h;            % Reynolds number calculated with MAC

q = 0.5*rho*V^2;           % Dynamic pressure at flight conditions

AC.Aero.rho   = rho;         % air density  (kg/m3)
AC.Aero.alt   = h;             % flight altitude (m)
AC.Aero.M     = M;           % flight Mach number 
AC.Aero.V     = V;            % flight speed (m/s)
AC.Aero.Re    = Re;        % reynolds number (bqased on mean aerodynamic chord)

AC.Aero.CL    = 2.5*9.81*W_des/(q*P.S);          % lift coefficient, based on design weight

tic;             
Res = Q3D_solver(AC);
toc

Y = Res.Wing.Yst;
Ccl = Res.Wing.ccl;
Cm = Res.Wing.cm_c4;

% Interpolating the lift and moment at locations y = 0 and y = b/2
Ccl0 = (Ccl(2)*Y(1) - Ccl(1)*Y(2))/(Y(1)-Y(2));  % Ccl at y = 0
Cm0 = (Cm(2)*Y(1) - Cm(1)*Y(2))/(Y(1)-Y(2));     % Cm at y = 0

L = length(Ccl);
% Ccl at y = b/2
Ccl1 = ((Ccl(L-1)-Ccl(L))*0.5*P.b +Ccl(L)*Y(L-1)-Ccl(L-1)*Y(L))/(Y(L-1)-Y(L));
% Cm at y = b/2
Cm1 = ((Cm(L-1)-Cm(L))*0.5*P.b +Cm(L)*Y(L-1)-Cm(L-1)*Y(L))/(Y(L-1)-Y(L));

L_out = [Ccl0,Ccl.',Ccl1]*q;    % Section lift output array
M_out = [Cm0,Cm.',Cm1]*q*mac .* [P.Cr, Res.Wing.chord.', P.Chords(3)]; % Moment output array
Y_out = [0,Y.',0.5*P.b]/(0.5*P.b);  % Y coordinate output array

%Plotting the lift and moment distribution, for validation purpose
figure
plot(Y_out,L_out);
figure
plot(Y_out,M_out);

%Creating the load file and filling in the section lift and moment
%distribution
fid = fopen('A320.load','wt');
for i = 1:length(Y_out)
    fprintf(fid,'%g %g %g\n',Y_out(i), L_out(i), M_out(i));
end

