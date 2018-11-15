clc
clear all
close all

A1 = [1.0, 1.5, 2.0]';
A2 = [0.5, 0.75, 1.0]';

y1 = 0; y2 = 2;
y = 3.0;

tic;
Ay = util.interparray([0.0 1.0 2.0], y1, y2, A1, A2);
toc;

M1 = ones(2, 2);
M2 = 2*ones(2, 2);

tic;
A_i = util.interparray([0.0, 0.5, 1.0], 0, 1, M1, M2);
toc;