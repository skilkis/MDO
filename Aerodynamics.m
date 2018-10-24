clear all
close all
clc


%% Aerodynamic solver setting
P = Planform;       %Planform class transforms geometry variables in 
                    %functional variables.
% Wing planform geometry 
%                x    y     z   chord(m)    twist angle (deg) 

MTOW = 78000;
W_f = 29141.8;

AC.Wing.Geom = [P.Coords,P.Chords.',P.Twists.'];
% Wing incidence angle (degree)
AC.Wing.inc  = 0; 
  
            
            
% Airfoil coefficients input matrix
%                    | ->     upper curve coeff.                <-|   | ->       lower curve coeff.       <-| 
AC.Wing.Airfoils   = [0.2081    0.2645   0.1419     0.2872  0.1349  0.2845...
                      -0.1230   -0.1419     -0.1727     -0.1080     -0.1503     -0.1197;
                      0.66666*[0.2081    0.2645   0.1419     0.2872  0.1349  0.2845...
                      -0.1230   -0.1419     -0.1727     -0.1080     -0.1503     -0.1197]];
AC.Wing.eta = [0;1];%P.eta.';  % Spanwise location of the airfoil sections

AC.Visc = 1;% Viscous vs inviscid
              % 0 for inviscid and 1 for viscous analysis
a_h = 303.25;              % Speed of sound at altitude of 30000 ft
v_h = 13.19*10^-6;         % Air viscosity at T = 280 K
mac = P.MAC;
rho = 0.46;
h = 9120;
M = 0.79;
V = M*a_h;
Re = mac*V/v_h;

q = 0.5*rho*V^2;
% Flight Condition

AC.Aero.rho   = rho;         % air density  (kg/m3)
AC.Aero.alt   = h;             % flight altitude (m)
AC.Aero.M     = M;           % flight Mach number 
AC.Aero.V     = V;            % flight speed (m/s)
AC.Aero.Re    = Re;        % reynolds number (bqased on mean aerodynamic chord)

AC.Aero.CL    = 2.5*9.81*(0.98*0.97*MTOW - 0.5*W_f)/(q*P.S);          % lift coefficient - comment this line to run the code for given alpha%
             % angle of attack -  comment this line to run the code for given cl 

tic;             
Res = Q3D_solver(AC);
toc

Y = Res.Wing.Yst;
Ccl = Res.Wing.ccl;
Cm = Res.Wing.cm_c4;

Ccl0 = (Ccl(2)*Y(1) - Ccl(1)*Y(2))/(Y(1)-Y(2));
Cm0 = (Cm(2)*Y(1) - Cm(1)*Y(2))/(Y(1)-Y(2));

L = length(Ccl);
Ccl1 = ((Ccl(L-1)-Ccl(L))*0.5*P.b +Ccl(L)*Y(L-1)-Ccl(L-1)*Y(L))/(Y(L-1)-Y(L));
Cm1 = ((Cm(L-1)-Cm(L))*0.5*P.b +Cm(L)*Y(L-1)-Cm(L-1)*Y(L))/(Y(L-1)-Y(L));

L_out = [Ccl0,Ccl.',Ccl1]*q;
M_out = [Cm0,Cm.',Cm1]*q*mac .* [P.Cr, Res.Wing.chord.', P.Chords(3)];

Y_out = [0,Y.',0.5*P.b]/(0.5*P.b);
figure
plot(Y_out,L_out);
figure
plot(Y_out,M_out);

fid = fopen('A320.load','wt');
%fprintf(fid, '%s %s %s\n','Spanwise Position','Lift','Pitching Moment');
for i = 1:length(Y_out)
    fprintf(fid,'%g %g %g\n',Y_out(i), L_out(i), M_out(i));
end

