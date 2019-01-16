
%% Loading Results of Simulation
load('data\runs\run_21-Dec-2018_17-52-12.mat')
set(0,'defaulttextinterpreter','latex') % Setting panel thickness

%% Running Simulations at Start/End (These are not cached to save memory)

n_cores = feature('numcores');
try
    if n_cores >= 4
        parallel = true; run_case.run_parallel = true;
        parpool(4)
    else
        parallel = false; run_case.run_parallel = false;
    end
catch
    warning(['Parallel Processing Disabled ' ...
             'or not Installed on Machine. Optimization '...
             'will execute as a serial process!'])
end

for field = {'start', 'end'}
    f = field{:};
    switch f
        case 'start'
            data.(f).aircraft = aircraft.Aircraft(run_case.aircraft.name);
            results = run_case.cache.results(1);
        case 'end'
            data.(f).aircraft = run_case.aircraft; % Final iter aircraft
            results = run_case.cache.results(end);
    end
    
    ac = data.(f).aircraft;
    
    if parallel
        spmd
            if labindex == 1
                temp = aerodynamics.Aerodynamics(ac);
            elseif labindex == 2
                temp = loads.Loads(ac);
            elseif labindex == 3
                temp = structures.Structures(ac);
            elseif labindex == 4
                temp = performance.Performance(ac);
            end
        end

        data.(f).aero = temp{1};
        data.(f).load = temp{2};
        data.(f).struc = temp{3};
        data.(f).perf = temp{4};
        data.(f).const = optimize.Constraints(ac, results, run_case.x);
    else
        data.(f).aero = aerodynamics.Aerodynamics(ac);
        data.(f).load = loads.Loads(ac);
        data.(f).struc = structures.Structures(ac);
        data.(f).perf = performance.Performance(ac);
        data.(f).const = optimize.Constraints(ac, results, run_case.x);
    end
end

% Parallel Pool Clean-up
if parallel
    poolobj = gcp('nocreate');
    delete(poolobj);
end

%%
const = optimize.Constraints(data.start.aircraft, run_case.cache.results(end), run_case.x);
const.plot_moment();
const.plot_lift();

%% Convergence Plots
x_history = run_case.x.fetch_history('normalized', false);

% Objective Convergence History
figure('Name', 'ObjectiveConvergence')
hold on; grid minor
plot([run_case.cache.results.W_f], 'DisplayName', 'Calc. Value $W_f$')
plot(x_history(44, :), 'DisplayName', 'Guess Value $\hat{W}_f$')
l = legend('Location', 'Best'); set(l, 'Interpreter', 'latex');
xlabel('Function Calls [-]','Color','k');
ylabel('Fuel Weight [kg]','Color','k');
title('Convergence History of Fuel Weight')

% Inequality Convergence History
figure('Name', 'IneqConstConvergence')
hold on; grid minor
plot(run_case.cache.const.c(:, 1), 'DisplayName', '$g_\mathrm{wing}$')
plot(run_case.cache.const.c(:, 2), 'DisplayName', '$g_\mathrm{spar}$')
plot(run_case.cache.const.c(:, 3), 'DisplayName', '$g_\mathrm{fuel}$')
axis()
l = legend('Location', 'Best'); set(l, 'Interpreter', 'latex');
xlabel('Function Calls [-]','Color','k');
ylabel('Normalized Constraint [-]','Color','k');
title('Convergence History of Inequality Constraints')

% Inequality Convergence History
figure('Name', 'EqConstConvergence')
hold on; grid minor
plot(run_case.cache.const.ceq(:, 1), 'DisplayName', '$\hat{C}_{D_w}$')
plot(run_case.cache.const.ceq(:, 2), 'DisplayName', '$\hat{A}_L$')
plot(run_case.cache.const.ceq(:, 3), 'DisplayName', '$\hat{A}_M$')
plot(run_case.cache.const.ceq(:, 4), 'DisplayName', '$\hat{W}_w$')
plot(run_case.cache.const.ceq(:, 5), 'DisplayName', '$\hat{W}_f$')
x_lim = xlim;
axis([x_lim(1), x_lim(2), -1, 1])
l = legend('Location', 'Best'); set(l, 'Interpreter', 'latex');
xlabel('Function Calls [-]','Color','k');
ylabel('Normalized Constraint [-]','Color','k');
title('Convergence History of Consistency Constraints')

%% Plotting Planform
figure('Name', 'Planform');
hold on; grid on; grid minor;

% Plotting Original Planform
obj = data.start.aircraft.planform;
x = [obj.Coords(:, 1); flipud(obj.Coords(:, 1) + obj.Chords');...
    obj.Coords(1,1)];
y = [obj.Coords(:, 2); flipud(obj.Coords(:, 2));...
    obj.Coords(1,2)];
eta_spar = [0, obj.D_fus/(obj.b), obj.eta(2:end)];
x_le = [obj.Coords(1, 1); obj.LE_at_span(eta_spar(2)); ...
        obj.Coords(2:end, 1)];
chords = [obj.Chords(1), obj.chord_at_span(eta_spar(2)), ...
        obj.Chords(2:end)]';
FS_frac = [obj.FS_root, obj.FS_fus, obj.FS, obj.FS]';
RS_frac = [obj.RS_root, obj.RS_fus, obj.RS, obj.RS]';
x_FS = chords .* FS_frac + x_le;
x_RS = chords .* RS_frac + x_le;
plot(y, x, 'DisplayName', 'A320-200 Planform', 'Color', [0.1, 0.1, 0.1])
plot((eta_spar * 0.5 * obj.b), x_FS, ':k', 'HandleVisibility','off')
plot((eta_spar * 0.5 * obj.b), x_RS, ':k', 'HandleVisibility','off')

% Plotting Optimized Planform
obj = data.end.aircraft.planform;
x = [obj.Coords(:, 1); flipud(obj.Coords(:, 1) + obj.Chords');...
    obj.Coords(1,1)];
y = [obj.Coords(:, 2); flipud(obj.Coords(:, 2));...
    obj.Coords(1,2)];
eta_spar = [0, obj.D_fus/(obj.b), obj.eta(2:end)];
x_le = [obj.Coords(1, 1); obj.LE_at_span(eta_spar(2)); ...
        obj.Coords(2:end, 1)];
chords = [obj.Chords(1), obj.chord_at_span(eta_spar(2)), ...
        obj.Chords(2:end)]';
FS_frac = [obj.FS_root, obj.FS_fus, obj.FS, obj.FS]';
RS_frac = [obj.RS_root, obj.RS_fus, obj.RS, obj.RS]';
x_FS = chords .* FS_frac + x_le;
x_RS = chords .* RS_frac + x_le;
plot(y, x, 'DisplayName', 'Opt. Planform')
line(0.5*[obj.D_fus obj.D_fus],get(gca,'YLim'),...
    'LineStyle', '-.', 'Color', 'k', 'DisplayName',...
    'Fuselage-Line')
plot((eta_spar * 0.5 * obj.b), x_FS, 'DisplayName',...
    'Front Spar')
plot((eta_spar * 0.5 * obj.b), x_RS, 'DisplayName',...
    'Rear Spar')
plot(0, obj.FS_proj * chords(1), 'o', 'DisplayName',...
    'Projected FS')
plot(0, obj.RS_proj * chords(1), 'o', 'DisplayName',...
    'Projected RS')

axis image
set(gca,'Ydir','reverse')
hold off;
xlabel('Half-Span (y) [m]','Color','k');
ylabel('Chord-Wise Length (x)','Color','k');
l = legend('Location', 'Best'); set(l, 'Interpreter', 'latex');
title('A320-G Planform Geometry')

%% Plotting Root Airfoil

figure('Name', 'RootAirfoil')
hold on; grid minor

%Plotting Original Airfoil
obj = data.start.aircraft.CST.root;
plot(obj.x_upper, obj.y_upper, ':k', 'DisplayName', 'Base-Airfoil')
plot(obj.x_lower, obj.y_lower, ':k', 'HandleVisibility','off')

%Plotting Modified Airfoil
obj = data.end.aircraft.CST.root;
plot(obj.x_upper, obj.y_upper, 'DisplayName', 'Upper-Surface')
plot(obj.x_lower, obj.y_lower, 'DisplayName', 'Lower-Surface')

axis([min(obj.x_upper), max(obj.x_upper),...
    -max(obj.x_upper) * 0.5, max(obj.x_upper)*0.5])
l = legend('Location', 'Best'); set(l, 'Interpreter', 'latex');
xlabel('Normalized Chord Location (x/c)','Color','k');
ylabel('Normalized Chord-Normal Location (y/c)','Color','k');
title('A320-G Modified Root Airfoil')

%% Plotting Tip Airfoil

figure('Name', 'TipAirfoil')
hold on; grid minor

%Plotting Original Airfoil
obj = data.start.aircraft.CST.tip;
plot(obj.x_upper, obj.y_upper, ':k', 'DisplayName', 'Base-Airfoil')
plot(obj.x_lower, obj.y_lower, ':k', 'HandleVisibility','off')

%Plotting Modified Airfoil
obj = data.end.aircraft.CST.tip;
plot(obj.x_upper, obj.y_upper, 'DisplayName', 'Upper-Surface')
plot(obj.x_lower, obj.y_lower, 'DisplayName', 'Lower-Surface')

axis([min(obj.x_upper), max(obj.x_upper),...
    -max(obj.x_upper) * 0.5, max(obj.x_upper)*0.5])
l = legend('Location', 'Best'); set(l, 'Interpreter', 'latex');
xlabel('Normalized Chord Location (x/c)','Color','k');
ylabel('Normalized Chord-Normal Location (y/c)','Color','k');
title('A320-G Modified Tip Airfoil')

%% Plotting Lift/Moment/Drag

figure('Name', 'LiftDist')
hold on; grid minor
wing = data.start.aero.Structs.Res.Wing;
plot(wing.Yst, wing.ccl, ':k', 'DisplayName', 'A320-200')
wing = data.end.aero.Structs.Res.Wing;
plot(wing.Yst, wing.ccl, 'DisplayName', 'A320-G')
l = legend('Location', 'Best'); set(l, 'Interpreter', 'latex');
xlabel('Half-Span Position [m]','Color','k');
ylabel('Lift Coefficient ($C_l\cdot c$) [-]','Color','k');
title('A320-G Modified Lift Distribution at $M_c$')

figure('Name', 'LiftDistMMO')
hold on; grid minor
wing = data.start.load.Structs.Res.Wing;
plot(wing.Yst, wing.ccl, ':k', 'DisplayName', 'A320-200')
wing = data.end.load.Structs.Res.Wing;
plot(wing.Yst, wing.ccl, 'DisplayName', 'A320-G')
l = legend('Location', 'Best'); set(l, 'Interpreter', 'latex');
xlabel('Half-Span Position [m]','Color','k');
ylabel('Lift Coefficient ($C_l\cdot c$) [-]','Color','k');
title('A320-G Modified Lift Distribution at $M_{MO}$')

figure('Name', 'MomentDist')
hold on; grid minor
wing = data.start.aero.Structs.Res.Wing;
plot(wing.Yst, wing.cm_c4, ':k', 'DisplayName', 'A320-200')
wing = data.end.aero.Structs.Res.Wing;
plot(wing.Yst, wing.cm_c4, 'DisplayName', 'A320-G')
l = legend('Location', 'Best'); set(l, 'Interpreter', 'latex');
xlabel('Half-Span Position [m]','Color','k');
ylabel('Quarter-Chord Moment Coefficient ($C_{m_{0.25c}}$) [-]','Color','k');
title('A320-G Modified Moment Distribution at $M_c$')

figure('Name', 'MomentDistMMO')
hold on; grid minor
wing = data.start.load.Structs.Res.Wing;
plot(wing.Yst, wing.cm_c4, ':k', 'DisplayName', 'A320-200')
wing = data.end.load.Structs.Res.Wing;
plot(wing.Yst, wing.cm_c4, 'DisplayName', 'A320-G')
l = legend('Location', 'Best'); set(l, 'Interpreter', 'latex');
xlabel('Half-Span Position [m]','Color','k');
ylabel('Quarter-Chord Moment Coefficient ($C_{m_{0.25c}}$) [-]','Color','k');
title('A320-G Modified Moment Distribution at $M_{MO}$')

figure('Name', 'Drag')
hold on; grid minor

Res = data.start.aero.Structs.Res;
Cdi = Res.Wing.cdi;
Cd_sec = Res.Section.Cd;
Y_sec = Res.Section.Y;
Y = Res.Wing.Yst;
Cd_tot = interp1(Y_sec, Cd_sec, Y, 'pchip');
Cd_rest = Cd_tot - Cdi;
plot(Y, Cd_tot,':k', 'DisplayName', 'A320-200 Drag')
plot(Y, Cdi,':k', 'HandleVisibility','off')
plot(Y, Cd_rest,':k', 'HandleVisibility','off')

Res = data.end.aero.Structs.Res;
Cdi = Res.Wing.cdi;
Cd_sec = Res.Section.Cd;
Y_sec = Res.Section.Y;
Y = Res.Wing.Yst;
Cd_tot = interp1(Y_sec, Cd_sec, Y, 'pchip');
Cd_rest = Cd_tot - Cdi;
plot(Y, Cd_tot,'DisplayName','A320-G Total')
plot(Y, Cdi,'DisplayName','A320-G Induced')
plot(Y, Cd_rest,'DisplayName','A320-G Wave & Profile')

l = legend('Location', 'Best'); set(l, 'Interpreter', 'latex');
xlabel('Half-Span Position [m]','Color','k');
ylabel('Drag Coefficient ($C_d$) [-]','Color','k');
title('A320-G Modified Drag Distribution at $M_{c}$')


%% Convex Hull Plots
figure('Name', 'FuelTankA320-200')
hold on; grid;
obj = data.start.struc.fuel_tank;
c = obj.convex_hull.center; i = obj.convex_hull.inner;
o = obj.convex_hull.outer;

trisurf(c.K,c.x,c.y,c.z, 'FaceColor', 'red', 'DisplayName',...
                         'Center Tank')
trisurf(i.K,i.x,i.y,i.z, 'FaceColor', 'blue', 'DisplayName',...
                         'Inboard Tank')
trisurf(o.K,o.x,o.y,o.z, 'FaceColor', 'green', 'DisplayName',...
                         'Outboard Tank')
axis image
xlabel('Chord [m]')
ylabel('Half Span [m]')
zlabel('Thickness [m]')
az = 45;
el = 30;
view(az, el);
legend('Location', 'Best', 'Orientation', 'horizontal')
l = legend('Location', 'Best');
set(l, 'Orientation', 'horizontal','Interpreter', 'latex');

figure('Name', 'FuelTankA320-G')
hold on; grid;
obj = data.start.struc.fuel_tank;
c = obj.convex_hull.center; i = obj.convex_hull.inner;
o = obj.convex_hull.outer;

trisurf(c.K,c.x,c.y,c.z, 'FaceColor', 'red', 'DisplayName',...
                         'Center Tank')
trisurf(i.K,i.x,i.y,i.z, 'FaceColor', 'blue', 'DisplayName',...
                         'Inboard Tank')
trisurf(o.K,o.x,o.y,o.z, 'FaceColor', 'green', 'DisplayName',...
                         'Outboard Tank')
axis image
xlabel('Chord [m]')
ylabel('Half Span [m]')
zlabel('Thickness [m]')
az = 45;
el = 30;
view(az, el);
l = legend('Location', 'Best');
set(l, 'Orientation', 'horizontal','Interpreter', 'latex');

%% Saving/Overwriting Figures in the Images Folder as a .pdf

choice=questdlg(['Would you like to close and save all figures to ',...
                 '\data\figures?'],'Figure Save Dialog', ...
                 'Yes','Just Save','Specify Directory',...
                 'Specify Directory');
default_dir = 'data\figures\';

switch choice
    case 'Yes'
        if exist(default_dir,'dir')==0
        mkdir(default_dir)
        end
        b1=waitbar(0,'1','Name','Please Wait');
        handles = findobj('Type', 'figure');
        N = length(handles);
        i = 0;
        for handle = handles'
            i = i + 1;
            waitbar(i/N,b1,sprintf('Saving Figure (%d/%d)',i,N))
            util.save2pdf(sprintf('%s%s.pdf', default_dir, handle.Name),...
                          handle)
        end
        close all
        delete(b1)
        b2=msgbox('Operation Completed','Success');
    case 'Just Save'
        if exist(default_dir,'dir')==0
        mkdir(default_dir)
        end
        b1=waitbar(0,'1','Name','Please Wait');
        handles = findobj('Type', 'figure');
        N = length(handles);
        i = 0;
        for handle = handles'
            i = i + 1;
            waitbar(i/N,b1,sprintf('Saving Figure (%d/%d)',i,N))
            util.save2pdf(sprintf('%s%s.pdf', default_dir, handle.Name),...
                          handle)
        end
        delete(b1)
        b2=msgbox('Operation Completed','Success');
    case 'Specify Directory'
        new_dir=uigetdir('','Select Figure Saving Directory');
        b1=waitbar(0,'1','Name','Please Wait');
        handles = findobj('Type', 'figure');
        N = length(handles);
        i = 0;
        for handle = handles'
            i = i + 1;
            waitbar(i/N,b1,sprintf('Saving Figure (%d/%d)',i,N))
            util.save2pdf(sprintf('%s%s.pdf', new_dir, handle.Name),...
                          handle)
        end
        close all
        delete(b1)
        b2=msgbox('Operation Completed','Success');
end

