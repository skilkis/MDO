classdef RunCase < handle
    %RUNCASE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        aircraft;       % Aircraft instance with all parameters and vars
        x;              % DesignVector object for fmincon & ease of use
        results;
        x_final;
        converged;
        options;
    end

    properties (SetAccess = private, GetAccess = public)
        cache = struct()
        first_run
    end
    
    methods
        
        function obj = RunCase(aircraft_name, options)
            obj.aircraft = aircraft.Aircraft(aircraft_name);
            obj.options = options;
            obj.init_design_vector(); % Creating the design vector object
            obj.cache.x = ones(size(obj.x.vector));
            obj.cache.results = [];
            obj.first_run = true;
        end

        function init_design_vector(obj)
            dv = @optimize.DesignVector;
            ac = obj.aircraft;
            obj.x = dv({'lambda_1', ac.lambda_1, 0, 1.25;...
                        'lambda_2', ac.lambda_2, 0.94, 1.25;...
                        'b', ac.b, 0.71, 1.06;...
                        'c_r', ac.c_r, 0.68, 1.15;...
                        'tau', ac.tau, 0.16, 2.5;...
                        'A_root', ac.A_root', -2.0, 2.0;...
                        'A_tip', ac.A_tip', -2.0, 2.0;...
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
            [opt, ~] = fmincon(@obj.objective,...
                               obj.x.vector, [], [], [], [],...
                               obj.x.lb, obj.x.ub, @obj.constraints,...
                               obj.options);
            obj.x_final = opt;
            time = toc;
        end
        
        function [c, ceq] = constraints(obj, x)
            obj.x.vector = x;
            res = obj.fetch_results(x);
            Cons = optimize.Constraints(obj.aircraft, res, obj.x);
            c = Cons.C_ineq; ceq = Cons.C_eq;
        end

        function fval = objective(obj, x)
            res = obj.fetch_results(x);
            fval = res.W_f/obj.x.W_f_0;
        end
        
        function res = fetch_results(obj, x)
            if all(obj.cache.x(:, end) == x) && ~obj.first_run
                res = obj.cache.results(end);
            else
                try
                    obj.aircraft.modify(obj.x);
                    res.C_dw = obj.run_aerodynamics();
                    res.Loading = obj.run_loads();
                    res.Struc = obj.run_structures();
                    res.W_f = obj.run_performance();
                catch
                    res.C_dw = NaN;
                    res.Loading.M_distr = NaN; res.Loading.L_distr = NaN;
                    res.Loading.Y_coord = NaN;
                    res.Struc.V_t = NaN; res.Struct.W_w = NaN;
                    res.W_f = NaN;
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
            Aero = aerodynamics.Aerodynamics(obj.aircraft);
            A = Aero.C_d_w;
        end
        
        function L = run_loads(obj)
            Loads = loads.Loads(obj.aircraft);
            L.M_distr = Loads.M_distr;
            L.L_distr = Loads.L_distr;
            L.Y_coord = Loads.Y_coord;
            
        end
        
        function S = run_structures(obj)
           Structures = structures.Structures(obj.aircraft);
           S.W_w = Structures.W_w;
           S.V_t = Structures.V_t;
        end
        
        function P = run_performance(obj)
            perf = performance.Performance(obj.aircraft);
            P = perf.W_fuel;
        end
    end
end

