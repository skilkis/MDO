%% Demonstrates simple yet powerful directory management w/ packages
clc
clear all
close all

obj = geometry.CSTAirfoil(linspace(0, 1, 100)');

% To see the power of classes try accessing the plot method by
% typing obj.plot() after running. These are dynamic calls to the object
% and can proove indispensible when asking for data or storing history
% of optimizations

% Test Text from Visual Studio Code

% Notes on Object Arrays:
% https://nl.mathworks.com/matlabcentral/answers/312332-how-can-i-create-an-array-of-class-handles

% Notes on Dependent Values: (Calculated on the Fly, can be very costly!)
% https://nl.mathworks.com/matlabcentral/answers/128905-how-to-efficiently-use-dependent-properties-if-dependence-is-computational-costly
