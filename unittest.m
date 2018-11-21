clc
clear all
close all

%% Test Aircraft Initialization
ac = aircraft.Aircraft('A320');
ac.planform.plot();

%% Testing Airfoil Fitting
root_airfoil = geometry.AirfoilReader('naca23015.dat');
root_fit = geometry.FittedAirfoil(root_airfoil);
% root_cst = root_fit.CSTAirfoil;
% 
% % Visual Verification of Fitting Process
% root_fit.plot()
% 
% tip_airfoil = root_fit.scale(2.0, 0.1);
% tip_cst = tip_airfoil.CSTAirfoil;
% tip_airfoil.plot()
% 
% t_ratio = sum(tip_airfoil.CSTAirfoil.A_upper./root_cst.A_upper)/6;
% assert(round(t_ratio, 1) == round(0.1/0.15, 1),...
%     'Applied scaling error exceeded tol')
% 
% clear t_ratio

%% Testing 1-D Linear Interpolation of Arrays
% A_root = root_cst.A_upper;
% A_tip = tip_cst.A_upper;
% 
% A_mid = util.interparray(0.5, 0, 1, A_root, A_tip);
% assert(all(A_mid == (A_root + A_tip) / 2), 'Array Interpolation Failed')

%% Testing Design Vector
x = optimize.DesignVector({'lambda_1', ac.lambda_1, 0, 1.25;...
                           'lambda_2', ac.lambda_2, 0.94, 1.25;...
                           'b', ac.b, 0.71, 1.06;...
                           'c_r', ac.c_r, 0.68, 1.15;...
                           'tau', ac.tau, 0.16, 2.5;...
                           'A_root', ac.A_root', -2.0, 2.0;...
                           'A_tip', ac.A_tip', -2.0, 2.0;...
                           'beta_root', ac.beta_root, 0, 1.7;...
                           'beta_kink', ac.beta_kink, -0.8, 3.2;...
                           'beta_tip', ac.beta_tip, -3.6, 3.6;...
                           % Get these values from first initial run
                           'A_L', ac.A_L, -1.5, 1.5;...
                           'A_M', ac.A_M, -1.5, 1.5;...
                           'W_w', ac.W_w, 0.8, 1.0;...
                           'W_f', ac.W_f, 0.8, 1.0;...
                           'C_d_w', ac.C_d_w, 0.8, 1.0});
%%
assert(all((x.init .* x.vector) == x.init), 'Design Vector Corrupted');

% Testing if current vector created by the initial design is a new vector
assert(x.isnew(x.vector * 1)==false)
assert(x.isnew(x.vector * 1.2)==true)
% x.vector = ones(length(x.vector), 1) * 2; % Updating w/ a new design vector [2, 2, 2, ...]'
x.vector = x.vector * 1.5;
x.fetch_history('normalized', true);

%% Testing Aircraft Modification
new_vector = ones(length(x.vector), 1); new_vector(3) = 1.25;
x.vector = new_vector;

ac.modify(x);
assert(ac.b == (x.b_0 * 1.25))

%% Creating a EMWET Worker and Running
tic;
s = structures.Structures(ac);
toc;
assert(~isempty(fieldnames(s.EMWET_output)), 'EMWET Output Not Recieved')

%% Creating a Q3D Viscid Worker and Running
a = aerodynamics.Aerodynamics(ac);

%% Creating a Q3D Inviscid Worker and Running
l = loads.Loads(ac);