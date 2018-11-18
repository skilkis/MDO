% Copyright 2018 San Kilkis, Evert Bunschoten
% 
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
% 
%    http://www.apache.org/licenses/LICENSE-2.0
% 
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.

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
options.DiffMinChange   = 1e-4;         % Minimum change while gradient searching
options.DiffMaxChange   = 1e-2;         % Maximum change while gradient searching
options.TolCon          = 1e-3;         % Maximum difference between two subsequent constraint vectors [c and ceq]
options.TolFun          = 1e-3;         % Maximum difference between two subsequent objective value
options.TolX            = 1e-3;         % Maximum difference between two subsequent design vectors

options.MaxIter         = 1e5;          % Maximum iterations
options.PlotFcns        = {@optimplotx,...
                           @optimplotfval,...
                           @optimplotfirstorderopt};

run_case = optimize.RunCase('A320', options);
% run_case = optimize.RunCase.load_run('run_1'); % Allows to use saved runs
run_case.optimize();

run_case.aircraft.planform.plot();
run_case.aircraft.CST.root.plot();
run_case.aircraft.CST.tip.plot();
