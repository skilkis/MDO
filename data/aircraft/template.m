clc
clear all
close all

%% Allows one to quickly configure an Aircraft .mat file for the optimizer

name = 'A320';                  % Aircraft Name w/o File-Extension [-]
base_airfoil = 'naca23015';     % Base Airfoil Name [-]

% Drag coefficients
C_d_w = 0.0117;                 % Initial wing drag coefficient [-]
C_d_aw = 0.00587;               % Aircraft-less wing drag coefficient [-]

% Cruise Parameters
h_c = 11248;                    % Cruise Altitude [m]
M_c = 0.787;                    % Cruise Mach Number [-]
a_c = 294.01;                   % Speed of Sound [m/s]
V_c = 231.5;                    % Cruise Velocity [m/s]
rho_c = 0.589;                  % Cruise Air Density [kg/m^3]
mu_c = 8.0e-06;                 % Cruise Dynamic Viscosity [kg/m s]
R_c = 5000.4;                   % Design Cruise Range [km]

% Aircraft Weights
W_aw = 31367.5;                 % Aircraft Less Wing Weight [kg]
W_mp = 19190;                   % Maximum Zero-Fuel Weight [kg]
W_f = 17940;                    % Design Fuel Weight [kg]
W_p = 14250;                    % Design Payload Weight [kg]
W_w = 9942.5;                   % Wing weight[kg]

% Geometric Parameters
D_fus = 3.95;                   % Fuselag Diameter [m]
d_TE = 6.0134;                  % Fixed Inboard Trailing Edge Length [m]
d_rib = 0.5;                    % Rib Pitch [m]
S = 122.3696;                   % Reference Wing-Planform area [m^2]
FS = 0.25;                      % Front Spar Chordwise Position [-]
RS = 0.75;                      % Rear Spar Chordwise Position [-]
c_r = 7.3834;                   % Root chord [m]
lambda_1 = 31.87;               % Inboard Quarter chord sweep angle [rad]
lambda_2 = 27.285;              % Outboard Quarter chord sweep angle [rad]
tau = 0.2002;                   % Taper ratio(Ct/Cr) [-]
b = 33.91;                      % Wing span(total) [m]
beta_root = 4.82;               % Twist angle value for root [deg]
beta_kink = 0.62;               % Twist angle at kink [deg]
beta_tip = -0.56;               % Twist angle at tip [deg]

% Aluminum Material Properties
E_al = 70.1e9;                  % Young's Modulus of Aluminum [Pa]
sigma_c = 295e6;                % Compresible Yield Stress [Pa]
sigma_t = 295e6;                % Tensile Yield Stress [Pa]
rho_al = 2800;                  % Density of Aluminum Alloy [kg/m^3]

% Engine Specifications
engine_spec = [0.1696, 2327];   % [Span Position, Weight [kg]

% Loading Coefficients
A_L = [8.5945,...               % Lift distribution Bernstein coefficients
    8.3803,...
    3.2083,...
    5.2971,...
    1.4767]*1e4;

A_M = [-2.4352,...              % Moment distribution Bernstein coefficients
    -0.2221,...
    0.0262,...
    -0.6234,...
    0.3645]*1e4;

% Miscelaneious Properties
eta_max = 2.5;                  % Maximum Load Factor [-]
rho_f = 817;                    % Fuel Density (Kerosene) [kg/m^3]
C_T = 16.5e-6;                  % Thrust Specific Fuel Consumption
M_mo = 0.82;                    % Maximum Operating Mach Number [-]
fuel_limit = 0.85;              % Allowable Fuel-Tank Normalized Span (Tip)
g = 9.81;                       % Acceleration due to gravity [m/s^2]
v = 8e-6;                       % Kinematic viscosity at altitude [m^2/s]
%% Saving
save(name)