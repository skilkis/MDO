%Script capable of calculating the wing weight using EMWET, as well as
%calculating the available fuel volume in the wing tanks and center tank.

MTOW = 78000;   %Maximum take-off weight[kg]. For now obtained from literature
MZF = 60500;    %Maximum zero fuel weight[kg]
nmax = 2.5;     %Maximum load factor, as specified in assignment
P = Planform(); %Using the Planform class to obtain wing geometry

S = P.S;        %Wing planform area[m^2]
b = P.b;        %Wing span[m]

XR = P.Coords(1,:);  %Coordinates of the root chord leading edge [x, y, z]
XM = P.Coords(2,:);  %Coordinates of the kink chord leading edge [x, y, z]
Xt = P.Coords(3,:);  %Coordinates of the tip chord leading edge [x, y, z]

Cr = P.Chords(1);   %Root chord length[m]
Cm = P.Chords(2);   %Kink chord length[m]
Ct = P.Chords(3);   %Tip chord length[m]

FS_r = P.fs_r;      %Root chord front spar chordwise location
RS_r = P.rs_r;      %Root chord rear spar chordwise location
FS_m = P.fs;        %Mid chord front spar chordwise location
RS_m = P.rs;        %Mid chord rear spar chordwise location
FS_t = P.fs;        %Tip chord front spar chordwise location
RS_t = P.rs;        %Tip chord rear spar chordwise location

D_f = P.D_f;        %Fuselage diameter[m]
W_e = 2327;         %Engine weight[kg]

% Material characteristics were obtained from the tutorial example
E = 7.10185e+010;   %E-modulus aluminium[Pa]
rho = 2795.68;      %Density[kg/m^3]
Y_t = 4.8265e+008;  %Tensile yield stress[Pa]
Y_c = 4.6886e+008;  %Compressive yield stress[Pa]
RP = 0.5;           %Rib pitch[m]

%Constructing the the init file using the planform parameters and weights
fid = fopen('A320.init','wt');
fprintf(fid, '%g %g\n', MTOW, MZF);
fprintf(fid, '%g\n', nmax);
fprintf(fid, '%g %g %d %d\n',S, b, 3, 3);
fprintf(fid, '%d %s\n',0, 'NACA23015');
fprintf(fid, '%g %s\n',P.gamma/P.b, 'NACA23012');
fprintf(fid, '%g %s\n',1, 'NACA23010');
fprintf(fid, '%g %g %g %g %g %g\n',Cr, XR(1), XR(2), XR(3),FS_r, RS_r);
fprintf(fid, '%g %g %g %g %g %g\n',Cm, XM(1), XM(2), XM(3),FS_m, RS_m);
fprintf(fid, '%g %g %g %g %g %g\n',Ct, Xt(1), Xt(2), Xt(3),FS_t, RS_t);
fprintf(fid, '%g %g\n',P.D_f/P.b, 0.85);
fprintf(fid, '%d\n',1);
fprintf(fid, '%g %g\n',2*5.75/P.b, W_e);
fprintf(fid, '%g %g %g %g\n',E, rho, Y_t, Y_c);
fprintf(fid, '%g %g %g %g\n',E, rho, Y_t, Y_c);
fprintf(fid, '%g %g %g %g\n',E, rho, Y_t, Y_c);
fprintf(fid, '%g %g %g %g\n',E, rho, Y_t, Y_c);
fprintf(fid, '%g %g\n',0.96, 0.7);
fprintf(fid, '%d', 1);

%Writing the aifoil files, based on the NACA23015, but in the future they
%should be constructed using the Bernstein coefficients.
fid = fopen('NACA23010.dat','wt');
fid2 = fopen('NACA23012.dat','wt');
data = importdata('NACA23015.dat');
for i = 1:length(data(:,1))
    fprintf(fid,'%g %g\n',data(i,1),(2/3)*data(i,2));
    fprintf(fid2,'%g %g\n',data(i,1),(0.12/0.15)*data(i,2));
end

%Initiating EMWET and writing a diary file
tic;
diary EMWET_stuff.txt

EMWET A320
diary off
toc


