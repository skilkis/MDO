
P = geometry.Planform(x);

x0 = 0;
x1 = P.gamma;
x2 = P.b/2;
x3 = x2;
x4 = x1;
x5 = x0;

y0 = 0;
y1 = P.gamma*tan(P.S1);
y2 = y1 + (P.b/2 - P.gamma)*tan(P.S2);
y3 = y2 + P.Chords(3);
y4 = y1 + P.Chords(2);
y5 = y0 + P.Chords(1);

C_f = P.Chords(1) - (P.Chords(1) - P.Chords(2))*0.5*P.D_fus/P.gamma;
X0 = 0.5*P.D_fus;
X1 = P.gamma;
X2 = P.b/2;

Y0 = P.fs_f*C_f + 0.5*P.D_fus*tan(P.S1);
Y1 = P.fs*P.Chords(2) + P.gamma*tan(P.S1);
Y2 = P.fs*P.Chords(3)+ P.gamma*tan(P.S1) + (P.b/2 - P.gamma)*tan(P.S2);

figure
plot([x0, x1, x2, x3, x4, x5],[y0, y1, y2, y3, y4, y5]);
hold on
plot([X0, X1, X2],[Y0, Y1, Y2])
hold on
plot([X0, X1, X2],[P.rs_f*C_f+0.5*P.D_fus*tan(P.S1), P.rs*P.Chords(2)+P.gamma*tan(P.S1)...
    ,P.rs*P.Chords(3) + P.gamma*tan(P.S1) + (P.b/2 - P.gamma)*tan(P.S2)])


