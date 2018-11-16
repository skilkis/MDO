classdef RunCase
    %RUNCASE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        aircraft;
        x;
        x0;
        results;
    end
    
    methods
        
        function obj = RunCase(x0)
            
            
        end
        function Optimizer(obj)
            
            options = optimoptions('fmincon', 'Display', 'iter', 'Algorithm', 'sqp', 'StepTolerance', 1e-9, ...
                'MaxFunctionEvaluations',13000,'MaxIterations',800);
            tic;
            [opt, fval, exitflag, output] = fmincon(f, x0, [], [], [], [], lb, ...
                ub, [], options);
            time = toc;
            
        end
        
        
        function solv = objective(obj)
            O = objective.Objective(obj.aircraft);
            solv = O.Fuelfrac;
           
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
        
        function C = constraints(obj)
            Cons = constraints.Constraints(obj.aircraft,obj.results);
            C = [Cons.C_ineq, Cons.C_eq];
        end
        
        function x_true = get_results(obj)
            
            x_true.C_d_w = obj.aerodynamics(obj);
            x_true.Loading = obj.loads(obj);
            x_true.Struc = obj.structures(obj);
            x_true.W_f = obj.performance(obj);
            
        end
        
        function A = aerodynamics(obj)
            Aero = aerodynamics.Aerodynmics(obj.aircraft);
            A = Aero.C_d_w;
        end
        
        function L = loads(obj)
            Loads = loads.Loads(obj.aircraft);
            L.M_distr = Loads.M_distr;
            L.L_distr = Loads.L_distr;
            L.Y_coord = Loads.Y_coord;
            
        end
        
        function S = structures(obj)
           Structures = structures.Structures(obj.aircraft);
           S.W_w = Structures.W_w;
           S.V_t = Structures.V_t;
        end
        
        function P = performance(obj)
            P = performance.Performance(obj.aircraft);
        end
        
        
    end
end

