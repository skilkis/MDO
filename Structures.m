MTOW = 78000;
MZF = 60500;
nmax = 2.5;
P = Planform;

S = P.S;
b = P.b;

XR = P.Coords(1,:);
XM = P.Coords(2,:);
Xt = P.Coords(3,:);

Cr = P.Chords(1);
Cm = P.Chords(2);
Ct = P.Chords(3);

FS_r = P.fs_r;
RS_r = P.rs_r;
FS_m = P.fs;
RS_m = P.rs;
FS_t = P.fs;
RS_t = P.rs;

D_f = 3.95;
W_e = 2359;

E = 7.10185e+010;
rho = 2795.68;
Y_t = 4.8265e+008;
Y_c = 4.6886e+008;
RP = 0.5;

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

fid = fopen('NACA23010.dat','wt');
fid2 = fopen('NACA23012.dat','wt');
data = importdata('NACA23015.dat');
for i = 1:length(data(:,1))
    fprintf(fid,'%g %g\n',data(i,1),(2/3)*data(i,2));
    fprintf(fid2,'%g %g\n',data(i,1),(0.12/0.15)*data(i,2));
end
tic;
diary EMWET_stuff.txt

EMWET A320
diary off
toc


