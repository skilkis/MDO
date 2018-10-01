x = [34.10, 6.07, 25*pi/180, -25*pi/180, 0.247, 4.47];

b = x(1);
Cr = x(2);
S1 = x(3);
S2 = x(4);
tau = x(5);
g = x(6);

Cm = Cr-(4*g/3)*tan(S1);
Ct = tau*Cr;

A = g*tan(S1) - 0.25*Cm;
B = g*tan(S1) + (0.5*b - g)*tan(S2) - 0.25*Ct;
C = 3*Cr/4;
D = g*tan(S1) + (0.5*b-g)*tan(S2) +(3*Ct/4);


Le_1 = @(y) (((Cr - Cm)/(4*g)) + tan(S1)).*y - 0.25*Cr;
Le_2 = @(y) ((A-B).*y + g*B -0.5*b*A)./(g - 0.5*b);
Te_1 = @(y) (3*Cr/4)*ones(1,length(y));
Te_2 = @(y) ((C-D).*y + g*D - 0.5*b*C)./(g - 0.5*b);

y1 = linspace(0, g, 20);
y2 = linspace(g, 0.5*b, 20);

wline = 2;
figure
plot([0, 0], [-Cr/4, 3*Cr/4],'LineWidth',wline)
hold on
plot([g, g], [A, C],'LineWidth',wline)
hold on
plot([0.5*b 0.5*b],[B,D],'LineWidth',wline)
hold on
plot([0, g], [0, g*tan(S1)],'LineWidth',wline)
hold on
plot([g, 0.5*b], [g*tan(S1), g*tan(S1) + (0.5*b-g)*tan(S2)],'LineWidth',wline)
hold on
plot(y1, Le_1(y1),'LineWidth',wline)
hold on
plot(y1, Te_1(y1),'LineWidth',wline)
hold on
plot(y2, Le_2(y2),'LineWidth',wline)
hold on
plot(y2, Te_2(y2),'LineWidth',wline)

legend('Root chord', 'Mid chord', 'Tip chord', 'First quarter chord'...
    ,'Second quarter chord', 'First leading edge','First trailing edge'...
    ,'Second leading edge','Second trailing edge','Location','southeast')



