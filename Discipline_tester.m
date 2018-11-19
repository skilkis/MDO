a_r = ones(1,12);
a_t = ones(1,12);
x_wf = 1.0;
x_ww = 1.0;
P = Planform;


tic;
A = aerodynamics.Aerodynamics(x_wf,x_ww,a_r,a_t,P);
C_d = A.C_dw;
L = loads.Loads(x_wf,x_ww,a_r,a_t,P);

Y = L.Y_coord;
l = L.L_distr;
M = L.M_distr;
toc
% subplot(211)
% plot(Y,l);
% 
% subplot(212)
% plot(Y,M);
