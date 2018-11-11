clc
clear all
close all

%% Allows one to quickly configure an Aircraft .mat file for the optimizer

name = 'A320';                  % Aircraft Name w/o File-Extension [-]
base_airfoil = 'naca_23015';    % Base Airfoil Name [-]

% Cruise Parameters
h_c = 11248;                    % Cruise Altitude [m]
M_c = 0.787;                    % Cruise Mach Number [-]
a_c = 294.01;                   % Speed of Sound [m/s]
V_c = 231.5;                    % Cruise Velocity [m/s]
rho_c = 0.589;                  % Cruise Air Density [kg/m^3]
mu_c = 8.0e-06;                 % Cruise Dynamic Viscosity [kg/m s]
R_c = 5000.4;                   % Design Cruise Range [km]

% Aircraft Weights
W_aw = 38400;                   % Aircraft Less Wing Weight [kg]
% W_e = [];                     % Empty Weight [kg]

% Geometric Parameters
% D_fus = [];                     % Fuselag Diameter [m]
% d_TE = 6.01;                    % Fixed Inboard Trailing Edge Length [m]
% d_rib = 0.5;                    % Rib Pitch [m]
% S = [];                         % Reference Wing-Planform area [m^2]
% N1 = 0.5;                       % LE Class Function Coefficient [-]
% N2 = 1.0;                       % TE Class Function Coefficient [-]
% FS = [];                        % Front Spar Chordwise Position [-]
% RS = [];                        % Rear Spar Chordwise Position [-]
% FS_fus = [];                    % F.Spar Chordwise Pos. at Fus.-Line [-]

% Aluminum Material Properties
E_al = 70.1e9;                  % Young's Modulus of Aluminum [Pa]
sigma_c = 295e6;                % Compresible Yield Stress [Pa]
sigma_t = 295e6;                % Tensile Yield Stress [Pa]
rho_al = 2800;                  % Density of Aluminum Alloy [kg/m^3]

% Miscelaneious Properties
eta_max = 2.5;                  % Maximum Load Factor [-]
rho_f = 840;                    % Fuel Density (Kerosene) [kg/m^3]
C_T = [];                       % Thrust Specific Fuel Consumption
M_mo = 0.82;                    % Maximum Operating Mach Number [-]

%% Saving
save(name)