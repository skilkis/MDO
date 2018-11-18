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

classdef RunCase < handle
    %RUNCASE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        aircraft;           % Aircraft instance with all parameters and vars
        x;                  % DesignVector object for fmincon & ease of use
        results;
        x_final;
        converged;
        options;
        sim_time;           % Total Sim. Time at end of Optimization [s]
    end

    properties (SetAccess = private, GetAccess = public)
        cache = struct()    % Cache of Results & Constraints
        run_parallel        % Bool, True for machines with >= 4 cores
        iter_counter = 0    % Counts the number of function calls
    end
    
    methods
        
        function obj = RunCase(aircraft_name, options)
            obj.aircraft = aircraft.Aircraft(aircraft_name);

            % Augmenting options w/ OutputFnc
            options.OutputFcn = @obj.cache_optimValues;   
            obj.options = options;
            obj.init_design_vector(); % Creating the design vector object
            obj.cache.results = [];
        end

        function init_design_vector(obj)
            dv = @optimize.DesignVector;
            ac = obj.aircraft;
            obj.x = dv({'lambda_1', ac.lambda_1, 0, 1.25;...
                        'lambda_2', ac.lambda_2, 0.94, 1.25;...
                        'b', ac.b, 0.71, 1.06;...
                        'c_r', ac.c_r, 0.68, 1.15;...
                        'tau', ac.tau, 0.16, 2.5;...
                        'A_root', ac.A_root', 0.5, 1.2;...
                        'A_tip', ac.A_tip', 0.5, 1.2;...
                        'beta_root', ac.beta_root, 0, 1.7;...
                        'beta_kink', ac.beta_kink, -0.8, 3.2;...
                        'beta_tip', ac.beta_tip, -3.6, 3.6;...
                        % Get these values from first initial run
                        'A_L', ac.A_L, -1.5, 1.5;...
                        'A_M', ac.A_M, -1.5, 1.5;...
                        'W_w', ac.W_w, 0.8, 1.0;...
                        'W_f', ac.W_f, 0.8, 1.0;...
                        'C_d_w', ac.C_d_w, 0.8, 1.0});
        end

        function optimize(obj)
            tic;
            n_cores = feature('numcores');
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
            [opt, ~] = fmincon(@obj.objective,...
                               obj.x.vector, [], [], [], [],...
                               obj.x.lb, obj.x.ub, @obj.constraints,...
                               obj.options);
            obj.x_final = opt;
            obj.sim_time = toc;
        end
        
        function [c, ceq] = constraints(obj, x)
            obj.x.vector = x; % Updates design vector w/ fmincon value
            res = obj.fetch_results(x);
            Cons = optimize.Constraints(obj.aircraft, res, obj.x);
            c = Cons.C_ineq; ceq = Cons.C_eq;
        end

        function fval = objective(obj, x)
            res = obj.fetch_results(x);
            fval = res.W_f/obj.x.W_f_0;
        end
        
        function res = fetch_results(obj, x)
            if obj.x.isnew(x) % Checking if the fmincon vector is new
                res = obj.cache.results(end);
            else
                obj.aircraft.modify(obj.x);
                obj.iter_counter = obj.iter_counter + 1;
                % Running Analysis Blocks
                if obj.run_parallel
                    tic;
                    spmd
                        if labindex == 1
                            temp = obj.run_aerodynamics();
                        elseif labindex == 2
                            temp = obj.run_structures();
                        elseif labindex == 3
                            temp = obj.run_loads();
                        elseif labindex == 4
                            temp = obj.run_performance();
                        end
                    end
                    t = toc;
                    fprintf('Parallel Process took: %.5f [s]\n', t)
                    res.C_dw = temp{1};
                    res.Struc = temp{2};
                    res.Loading = temp{3};
                    res.W_f = temp{4};
                else
                    res.C_dw = obj.run_aerodynamics();
                    res.Loading = obj.run_loads();
                    res.Struc = obj.run_structures();
                    res.W_f = obj.run_performance();
                end
                
                if isempty(obj.cache.results)
                    obj.cache.results = res;
                else
                    obj.cache.results(end+1) = res;
                    obj.cache.x(:, end+1) = obj.x.vector;
                end
                obj.first_run = false;
            end
        end
        
        function A = run_aerodynamics(obj)
            try
                Aero = aerodynamics.Aerodynamics(obj.aircraft);
                A = Aero.C_d_w;
            catch
                A.C_D_w = NaN;
            end
        end
        
        function L = run_loads(obj)
            try
                Loads = loads.Loads(obj.aircraft);
                L.M_distr = Loads.M_distr;
                L.L_distr = Loads.L_distr;
                L.Y_coord = Loads.Y_coord;
            catch
                L.M_distr = ones.length(obj.x.A_M) * NaN;
                L.L_distr = ones.length(obj.x.A_M) * NaN;
                L.Y_coord = NaN;
            end
        end
        
        function S = run_structures(obj)
            try
               Structures = structures.Structures(obj.aircraft);
               S.W_w = Structures.W_w;
               S.V_t = Structures.V_t;
            catch
                S.W_w = NaN;
                S.V_t = NaN;
            end
        end
        
        function P = run_performance(obj)
            try
                perf = performance.Performance(obj.aircraft);
                P = perf.W_fuel;
            catch
                P.W_fuel = NaN;
            end
        end

        function cache_optimValues(obj, x, optimValues, state)
            disp(optimValues)       
            switch state
                case 'init'
                    % hold on
                case 'iter'
                    % Concatenate current point and objective function
                    % value with history. x must be a row vector.
                    temp.fval = [history.fval; optimValues.fval];
                    temp.x = [history.x; x];
                    % Concatenate current search direction with 
                    % searchdir.
                    temp. searchdir = [searchdir;...
                                        optimValues.searchdirection'];

                    obj.cache = temp;
                    

                    
                    % plot(x(1),x(2),'o');
                    % % Label points with iteration number.
                    % % Add .15 to x(1) to separate label from plotted 'o'
                    % text(x(1)+.15,x(2),num2str(optimValues.iteration));
                case 'done'
                    % hold off
                otherwise
            end
        end

    end
    methods (Static)
         function obj = load_run(run_file)
            filename = [pwd '\data\runs\' run_file '.mat'];
            try
                loaded_obj = load(filename, 'run_case');
                obj = loaded_obj.run_case;
            catch
                error('Supplied file has no property: run_case')
            end
        end
    end
end

