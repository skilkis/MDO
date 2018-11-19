fsize = 20;

L = loads.Loads(run_case.aircraft);
rho = L.Structs.AC.Aero.rho;
V = L.Structs.AC.Aero.V;


Y = L.Y_coord;
C_cl = L.L_distr./(0.5*rho*V^2);

plot(Y, C_cl,'DisplayName','Ccl','LineWidth',2);
set(gca,'FontSize',fsize);
xlabel('Spanwise position[m]','FontSize',fsize)
ylabel('$C_{cl}$','Interpreter','latex','FontSize',fsize);
grid('on')
lgd = legend();
title('$C_{cl}$ at Critical Conditions','Interpreter','latex','FontSize',fsize)
