clc
clear all
close all

%% Test Aircraft Initialization
ac = aircraft.Aircraft('A320');

%% Testing Airfoil Fitting
root_airfoil = geometry.AirfoilReader([ac.base_airfoil '.dat']);
root_fit = geometry.FittedAirfoil(root_airfoil);
root_cst = root_fit.CSTAirfoil;

tip_airfoil = root_fit.scale(1.0, 0.1);
tip_cst = tip_airfoil.CSTAirfoil;

%% Testing Design Vector
A_root = [root_cst.A_upper', root_cst.A_lower'];
A_tip = [tip_cst.A_upper', tip_cst.A_lower'];

x = optimize.DesignVector({'lambda_1', 31.87, 0, 1.25;...
                           'lambda_2', 27.285, 0.94, 1.25;...
                           'b', 33.91, 0.71, 1.06;...
                           'c_r', 7.3834, 0.68, 1.15;...
                           'tau', 0.2002, 0.16, 2.5;...
                           'A_root', A_root, -2.0, -2.0;...
                           'A_tip', A_tip, -2.0, -2.0;...
                           'beta_root', 4.82, 0, 1.7;...
                           'beta_kink', 0.62, -0.8, 3.2;...
                           'beta_tip', -0.56, -3.6, 3.6;...
                           'A_L', 1702, -1.5, 1.5;...
                           'N_L', 1702, -1.5, 1.5;...
                           'A_M', 1702, -1.5, 1.5;...
                           'N_M', 1702, -1.5, 1.5;...
                           'W_w_hat', 9600, 0.8, 1.2;...
                           'W_f_hat', 23330, 0.8, 1.2;...
                           'C_dw_hat', 1702, 0.1, 2.2});
                       
x.update(x.vector * 1.25);
x.update(x.vector * 0.8);

assert(all((x.init .* x.vector) == x.init), 'Design Vector Corrupted');

%% Creating a EMWET Worker and Running
s = structures.Structures(x, ac);

% root_fit.write([current_path '\' s.EMWET_input.airfoils.root.name '.dat'])
% tip_airfoil.write([current_path '\' s.EMWET_input.airfoils.tip.name '.dat'])

% s.write_init();


%% Testing EMWET

working_dir = cd;
cd(current_path)
eval(sprintf('EMWET %s', ac.name))
cd(working_dir);

%% Testing EMWET Parsing
filename = [current_path '\A320.weight'];
fid = fopen(filename, 'r');
idx = 1;

n_lines = utilities.linecount(filename);
data_idx = 5; % Line index where EMWET output data starts
data = zeros(n_lines - data_idx, 6);
while ~feof(fid)
    line = fgetl(fid);
    if idx == 1
        split_header = strsplit(line, '(kg) ');
        W_w = str2double(split_header{:, 2}); % Obtaining Wing Weight
    elseif idx >= data_idx && ischar(line)
        cell_line = strsplit(line,' ');
        data_line = cellfun(@(x) str2double(x), cell_line(1, 2:end));
        data(idx - (data_idx - 1), :) = data_line;
    end
    idx = idx + 1;
end
fclose(fid);

half_span = data(:, 1); chord = data(:, 2); t_u = data(:, 3);
t_l = data(:, 4); t_fs = data(:, 5); t_rs = data(:, 6);
