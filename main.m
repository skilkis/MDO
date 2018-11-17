%% Demonstrates simple yet powerful directory management w/ packages
clc
clear all
close all

% A_r = [0.2081    0.2645   0.1419     0.2872  0.1349  0.2845...
% -0.1230   -0.1419     -0.1727     -0.1080     -0.1503     -0.1197];

% Options for the optimization
options.Display         = 'iter-detailed';
options.Algorithm       = 'sqp';
options.FunValCheck     = 'off';
options.DiffMinChange   = 1e-2;         % Minimum change while gradient searching
options.DiffMaxChange   = 5e-2;         % Maximum change while gradient searching
options.TolCon          = 1e-6;         % Maximum difference between two subsequent constraint vectors [c and ceq]
options.TolFun          = 1e-6;         % Maximum difference between two subsequent objective value
options.TolX            = 0.07;         % Maximum difference between two subsequent design vectors

options.MaxIter         = 1e5;          % Maximum iterations
options.PlotFcns        = {@optimplotx,...
                           @optimplotfval,...
                           @optimplotfirstorderopt};

run_case = optimize.RunCase('A320', options);
run_case.optimize();
% To see the power of classes try accessing the plot method by
% typing obj.plot() after running. These are dynamic calls to the object
% and can proove indispensible when asking for data or storing history
% of optimizations

% Test Text from Visual Studio Code

% Notes on Object Arrays:
% https://nl.mathworks.com/matlabcentral/answers/312332-how-can-i-create-an-array-of-class-handles

% Notes on Dependent Values: (Calculated on the Fly, can be very costly!)
% https://nl.mathworks.com/matlabcentral/answers/128905-how-to-efficiently-use-dependent-properties-if-dependence-is-computational-costly
