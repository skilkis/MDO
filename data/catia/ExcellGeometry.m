Y = [linspace(1, 0, 30), linspace(0,1,30)];
C_r = 7.3834;

C_t = 1.4782;
t_r = 4.6*pi/180;
t_k = 1.2*pi/180;
t_t = -0.56*pi/180;
S1 = 36*pi/180;%31.87*pi/180;
S2 = 28.7*pi/180;
b = 33.91;
d_TE = 6.0134;
d_f = 3.95;

C_m = C_r - d_TE*tan(S1);
C_f = C_r - 0.5*d_f*tan(S1);
t_f = t_r - (t_r - t_k)*(0.5*d_f/d_TE);

FS_r = 0.3739;
RS_r = 0.6926;
FS_f = 0.2493;
RS_f = 0.6320;
FS = 0.25;
RS = 0.75;

X_fs_r = (FS_r-0.5)*C_r;
X_rs_r = (RS_r-0.5)*C_r;
X_fs_f = (FS_f-0.5)*C_f;
X_rs_f = (RS_f-0.5)*C_f;
X_fs_k = (FS-0.5)*C_m;
X_rs_k = (RS-0.5)*C_m;
X_fs_t = (FS-0.5)*C_t;
X_rs_t = (RS - 0.5)*C_t;

Spars_root = Twister([X_fs_r;X_fs_r;X_rs_r;X_rs_r],[-C_r; C_r; -C_r; C_r], t_r);
Spars_root(3,:) = zeros(1,length(Spars_root));
Spars_fus = Twister([X_fs_f;X_fs_f;X_rs_f;X_rs_f],[-C_f; C_f; -C_f; C_f], t_f);
Spars_fus(3,:) = 0.5*d_f*ones(1,length(Spars_fus));
Spars_kink = Twister([X_fs_k;X_fs_k;X_rs_k;X_rs_k],[-C_m; C_m; -C_m; C_m], t_k);
Spars_kink(3,:) = d_TE*ones(1,length(Spars_kink));
Spars_tip = Twister([X_fs_t;X_fs_t;X_rs_t;X_rs_t],[-C_t; C_t; -C_t; C_t], t_t);
Spars_tip(3,:) = 0.5*b*ones(1,length(Spars_tip));

stuff1 = Spars_root(1,:)'+ 0.5*C_r;
stuff2 = Spars_kink(1,:)'+0.5*C_m+d_TE*tan(S1);
stuff3 = Spars_tip(1,:)'...
    +0.5*C_t + d_TE*tan(S1) + (0.5*b-d_TE)*tan(S2) ;
stuff4 = Spars_fus(1,:)'+0.5*d_f*tan(S1) + 0.5*C_f;

X_s = [stuff1;stuff2;stuff3;stuff4];
Y_s = [Spars_root(2,:)';Spars_kink(2,:)';Spars_tip(2,:)';Spars_fus(2,:)'];
Z_s = [Spars_root(3,:)';Spars_kink(3,:)';Spars_tip(3,:)';Spars_fus(3,:)'];

thetarange = linspace(0, pi, 30);

xup = 0.5+0.5*cos(thetarange');%linspace(1,0,80)';
xdown = 0.5+0.5*cos(thetarange' + pi);%linspace(1,0,80)';


A_root = [0.2965; 
    0.2266; 
    0.2292; 
    0.2136; 
    0.1832; 
    0.2353; 
    -0.1423; 
    -0.1382; ...
    -0.1949; 
    -0.1258; 
    -0.1534; 
    -0.1837];%0.4*[rand(6,1);-rand(6,1)];
A_tip = [0.1975;
    0.1509;
    0.1527;
    0.1423;
    0.1220;
    0.1567;
   -0.0948;
   -0.0920;
   -0.1298;
   -0.0838;
   -0.1022;
   -0.1224];%0.4*[rand(6,1);-rand(6,1)];
A_kink = (A_root + A_tip)/2;
A_fus = A_root - (A_root - A_kink)*0.5*d_f/d_TE;

N = [0.5;1];

n = length(A_root)/2 -1;
i = 0:n;


yrange = xup/max(xup);
yrange2 = xdown/max(xdown);

B = (((factorial(n)./(factorial(i).*factorial(n-i))).*(yrange.^i).*(1-yrange)...
    .^(n-i))).*(yrange.^N(1)).*(1-yrange).^N(2);
B2 = (((factorial(n)./(factorial(i).*factorial(n-i))).*(yrange2.^i).*(1-yrange2)...
    .^(n-i))).*(yrange2.^N(1)).*(1-yrange2).^N(2);


Y_r_up = C_r*B*A_root(1:n+1);
Y_r_down = C_r*B2*A_root(n+2:end);
X_r_up = C_r*(xup-0.5);
X_r_down = C_r*(xdown-0.5);
X_r = [X_r_up;X_r_down];
Y_r = [Y_r_up;Y_r_down];
Coords_r = [cos(t_r), sin(t_r);
              -sin(t_r), cos(t_r)]*[X_r, Y_r]';
          
Y_f_up = C_f*B*A_fus(1:n+1);
Y_f_down = C_f*B2*A_fus(n+2:end);
X_f_up = C_f*(xup-0.5);
X_f_down = C_f*(xdown-0.5);
X_f = [X_f_up;X_f_down];
Y_f = [Y_f_up;Y_f_down];
Coords_f = [cos(t_f), sin(t_f);
              -sin(t_f), cos(t_f)]*[X_f, Y_f]';
          
Y_k_up = C_m*B*A_kink(1:n+1);
Y_k_down = C_m*B2*A_kink(n+2:end);
X_k_up = C_m*(xup-0.5);
X_k_down = C_m*(xdown-0.5);
X_k = [X_k_up;X_k_down];
Y_k = [Y_k_up;Y_k_down];
Coords_k = [cos(t_k), sin(t_k);
              -sin(t_k), cos(t_k)]*[X_k, Y_k]';


Y_t_up = C_t*B*A_tip(1:n+1);
Y_t_down = C_t*B2*A_tip(n+2:end);
X_t_up = C_t*(xup-0.5);
X_t_down = C_t*(xdown-0.5);
X_t = [X_t_up;X_t_down];
Y_t = [Y_t_up;Y_t_down];
Coords_t = [cos(t_t), sin(t_t);
              -sin(t_t), cos(t_t)]*[X_t, Y_t]';


plot(Coords_r(1,:)'+0.5*C_r, Coords_r(2,:)')
hold on
plot(Spars_root(1,:) + 0.5*C_r, Spars_root(2,:),'o')

hold on
plot(Coords_f(1,:)'+0.5*d_f*tan(S1)+0.5*C_f,Coords_f(2,:)')
hold on
plot(Spars_fus(1,:) + 0.5*C_f + 0.5*d_f*tan(S1), Spars_fus(2,:),'o')

hold on
plot(d_TE*tan(S1)+0.5*C_m + Coords_k(1,:)',Coords_k(2,:)')
hold on
plot(Spars_kink(1,:) + 0.5*C_m + d_TE*tan(S1), Spars_kink(2,:),'o')

hold on
plot(d_TE*tan(S1) + (0.5*b-d_TE)*tan(S2) + 0.5*C_t + Coords_t(1,:)',Coords_t(2,:)')
hold on
plot(Spars_tip(1,:) + 0.5*C_t + d_TE*tan(S1)+(0.5*b-d_TE)*tan(S2), Spars_tip(2,:),'o')

A = [Coords_r(1,:)'+0.5*C_r, Coords_r(2,:)', zeros(length(Coords_r),1);
    Coords_k(1,:)'+d_TE*tan(S1)+0.5*C_m, Coords_k(2,:)', d_TE*ones(length(Coords_k),1);
    Coords_t(1,:)'+d_TE*tan(S1)+0.5*C_t + (0.5*b-d_TE)*tan(S2), Coords_t(2,:)', 0.5*b*ones(length(Coords_t),1);
    Coords_f(1,:)'+0.5*d_f*tan(S1)+0.5*C_f, Coords_f(2,:)', 0.5*d_f*ones(length(Coords_f),1)];

X = A(:,1);
Y = A(:,2);
Z = A(:,3);

M = [];
fid = fopen('Chordpoints.txt','wt');
chords = {'Root Chord','Kink Chord','Tip Chord','Fuselage Chord'};
for i = 0:3
    if i == 0
        chord = 'Root Chord';
    end
    if i == 1
        chord = 'Kink Chord';
    end
    if i == 2
        chord = 'Tip Chord';
        
    end
    if i == 3
        chord = 'Fuselage Chord';
    end
for j = 1:length(Coords_r(1,:))
    str1 = [chord,'\GeometryFromExcel\Point.',num2str(j+i*60),'\X (mm), '];
    str2 = [chord,'\GeometryFromExcel\Point.',num2str(j+i*60),'\Y (mm), '];
    str3 = [chord,'\GeometryFromExcel\Point.',num2str(j+i*60),'\Z (mm), '];
    
    fprintf(fid, '%s %g\n', str1, 1000*X(j+i*60));
    fprintf(fid, '%s %g\n', str2, 1000*Y(j+i*60));
    fprintf(fid, '%s %g\n', str3, 1000*Z(j+i*60));
    

end
for j = 1:length(Spars_root)
    str1 = [chord,'\GeometryFromExcel\GeometryFromExcel\Point.',num2str(j+i*4+240),'\X (mm), '];
    str2 = [chord,'\GeometryFromExcel\GeometryFromExcel\Point.',num2str(j+i*4+240),'\Y (mm), '];
    str3 = [chord,'\GeometryFromExcel\GeometryFromExcel\Point.',num2str(j+i*4+240),'\Z (mm), '];
    fprintf(fid, '%s %g\n', str1, 1000*X_s(j+i*4));
    fprintf(fid, '%s %g\n', str2, 1000*Y_s(j+i*4));
    fprintf(fid, '%s %g\n', str3, 1000*Z_s(j+i*4));
end
end

fprintf(fid, '%s %g\n', 'Offset1 (mm), ', 1000*0.5*d_f);
fprintf(fid, '%s %g\n', 'D_te (mm), ', 1000*d_TE);
fprintf(fid, '%s %g\n', 'semispan (mm), ',500*b);
fprintf(fid, '%s %g\n', 'Cr (mm), ',1000*C_r);

function B = Twister(x, y, alpha)
    A = [cos(alpha), sin(alpha);
    -sin(alpha), cos(alpha)];
    B = A*[x,y]';
    X = B(:,1);
    Y = B(:,2);
    
end
