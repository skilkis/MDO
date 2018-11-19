%A = aerodynamics.Aerodynamics(run_case.aircraft);

rho = A.Structs.AC.Aero.rho;
V = A.Structs.AC.Aero.V;

C_cl = A.Structs.Res.Wing.ccl;
Cdi = A.Structs.Res.Wing.cdi;
Cd_sec = A.Structs.Res.Section.Cd;
Y_sec = A.Structs.Res.Section.Y;

Y = A.Structs.Res.Wing.Yst;

Cd_tot = interp1(Y_sec, Cd_sec, Y, 'pchip');
Cd_rest = Cd_tot - Cdi;

    

plot(Y, Cd_tot,'DisplayName','Total','LineWidth',2)
hold on
plot(Y, Cdi,'DisplayName','Induced','LineWidth',2)
hold on
plot(Y, Cd_rest,'DisplayName','Wave and Profile','LineWidth',2)
grid('on')

legend()