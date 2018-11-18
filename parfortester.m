

% x.c_r = 7.3834;
% x.lambda_1 = 31.87*pi/180;
% x.lambda_2 = 27.285*pi/180;
% x.tau = 0.2002;
% x.b = 33.92;
% x.beta_root = 4.82;
% x.beta_kink = 0.62;
% x.beta_tip = -0.56;


params.gamma = 6.013;
params.D_fus = 3.95;
params.fs = 0.2;
params.rs = 0.7255;
stuff = [];
P = geometry.Planform(x, params);
% f = @(x, P) aerodynamics.Aerodynamics(x, P);
% g = @(x, P) loads.Loads(x, P);
parfor i = 1:4
    if i == 1
        
        stuff(i) = A(x,P);
    end
    if i == 2
        stuff(i) = L(x,P);
    end
    if i == 3
        
        stuff(i) = 2*2*i^2;
    end
    if i == 4
        
        stuff(i) = i;
    end    
end

function cd = A(x,P)
solv = aerodynamics.Aerodynamics(x,P);
cd = solv.C_dw;

end

function sum = L(x,P)
solv = loads.Loads(x,P);
sum = sum(solv.L_distr - 60000) + sum(solv.M_distr - 30000);
end
