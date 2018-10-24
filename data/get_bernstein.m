%% Demonstrates simple yet powerful directory management w/ packages
clc
clear all
close all

airfoil = 'naca23015.dat';

root = geometry.AirfoilReader(airfoil); root.scale(1.0, 0.15)
kink = geometry.AirfoilReader(airfoil); kink.scale(1.0, 0.115)
tip = geometry.AirfoilReader(airfoil); tip.scale(1.0, 0.11)

cst_root = geometry.FittedAirfoil(root, 'optimize_class', false);
cst_kink = geometry.FittedAirfoil(kink, 'optimize_class', false);
cst_tip = geometry.FittedAirfoil(tip, 'optimize_class', false);

cst_root.CSTAirfoil.plot()
cst_kink.CSTAirfoil.plot()
cst_tip.CSTAirfoil.plot()

BernsteinCoefs.root.upper = cst_root.CSTAirfoil.A_upper;
BernsteinCoefs.root.lower = cst_root.CSTAirfoil.A_lower;

BernsteinCoefs.kink.upper = cst_kink.CSTAirfoil.A_upper;
BernsteinCoefs.kink.lower = cst_kink.CSTAirfoil.A_lower;

BernsteinCoefs.tip.upper = cst_tip.CSTAirfoil.A_upper;
BernsteinCoefs.tip.lower = cst_tip.CSTAirfoil.A_lower;