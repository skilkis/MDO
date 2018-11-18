%% Loading Results of Simulation
load('data\runs\run_18-Nov-2018_20-05-19.mat')

%% Running Simulations at Start/End (These are not cached to save memory)

n_cores = feature('numcores');

% Launching either in Parallel or Serial Execution
try
    if n_cores >= 4
        parpool(4)
        obj.run_parallel = true;
    end
catch
    obj.run_parallel = false;
    warning(['Parallel Processing Disabled ' ...
             'or not Installed on Machine. Optimization '...
             'will execute as a serial process!'])
end

for field = {'start', 'end'}
    f = field{:};
    switch f
        case 'start'
            data.(f).aircraft = aircraft.Aircraft(run_case.aircraft.name);
            x = run_case.x.history(:, 1);
            results = run_case.cache.results(1);
        case 'end'
            data.(f).aircraft = run_case.aircraft; % Final iter aircraft
            x = run_case.x_final;
            results = run_case.fetch_results(x);
    end
    
    ac = data.(f).aircraft;
    
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
end

poolobj = gcp('nocreate');
delete(poolobj);

%%
data.start.aircraft = aircraft.Aircraft('A320');
data.start.aero = aerodynamics.Aerodynamics(data.start.aircraft);

% Plotting Convergence History
% figure('Name', 'ObjectiveConvergence')
% hold on; grid minor
% plot(obj.x_upper, obj.y_upper)
% plot(obj.x_lower, obj.y_lower)
% axis([min(obj.x_upper), max(obj.x_upper),...
%       -max(obj.x_upper) * 0.5, max(obj.x_upper)*0.5])
% legend('Upper Surface', 'Lower Surface')
% xlabel('Normalized Chord Location (x/c)','Color','k');
% ylabel('Normalized Chord-Normal Location (y/c)','Color','k');
% title('Convergence History of Fuel Weight')

% Running simulations for the start/end vectors since ever result is not cached
