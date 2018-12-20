% Copyright 2018 Evert Bunschoten, San Kilkis
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

classdef Constraints < handle
    %% Constraints outputs
    properties
        C_eq;           %Array containing the values for the equality and consistency const.
        C_ineq;         %Array containing the inequality constraints
    end
    
    properties (GetAccess = private, SetAccess = private)
        aircraft_in;    % Current state of the aircraft object
        vector_in;      % Input Design Vector 
        results;        % Results obtained from current discipline runs
%         lift_dist;      % Lift distribution values at normalized span
%         mom_dist;       % Moment distribution values at normalized span
        y_range;        % Normalized half-span coordinates
        shape_fcn       % CST shape function handle
        A_M_hat
        A_M
        A_L_hat
        A_L
    end
    
    methods
        function obj = Constraints(aircraft_in, results, vector_in)
            
            % Localizing inputs to current object
            obj.aircraft_in = aircraft_in; obj.results = results;
            obj.shape_fcn = @geometry.CSTAirfoil.shapeFunction;
            obj.vector_in = vector_in; x = vector_in;
            
            % Normalizing span coordinates of current wing
            obj.y_range = obj.normalize_span();

            % Evaluating Consistency Constraints
            C_cd = obj.drag_constraint();
            C_lift = obj.lift_constraint();
            C_mom = obj.moment_constraint();
            
%             % Localizing Guess Lift/Moment Coefficients
%             A_L_hat = aircraft_in.A_L;
%             A_M_hat = aircraft_in.A_M;
%             
%             % Obtaining Resultant Coefficients from Loads Calc.
%             A_L = obj.fitCST(yrange, L_distr_true', A_L_hat);
%             A_M = obj.fitCST(yrange, M_distr_true', A_M_hat);
         
            % Consistency is = 0 when A_L = A_L_true & A_M = A_M_true
%             C_lift = 1 - sum(A_L_hat./A_L);
%             C_mom = 1 - sum(A_M_hat./A_M);
            
            %Comparing the wing structual weight against the guessed value.        
            W_w_true = results.Struc.W_w;
            W_w_guess = aircraft_in.W_w;
            C_ww = 1-(W_w_guess/W_w_true);

            W_f_true = results.W_f;
            W_f_guess = aircraft_in.W_f;
            C_wf = 1-(W_f_guess/W_f_true);

            %Inequality constraint setting the wing loading equal or lower 
            %than initial value
            % TODO change aircraft.S to aircraft.S_ref to avoid confusion
            WL_0 = (aircraft_in.W_aw + aircraft_in.W_p + x.W_f_0 + x.W_w_0)...
                /aircraft_in.S;
            WL_guess = (aircraft_in.W_aw + aircraft_in.W_p + aircraft_in.W_f...
                + aircraft_in.W_w)...
                /aircraft_in.planform.S;
            C_wl = 1-(WL_0/WL_guess);

            %Inequality constraint checking for the sufficient front spar 
            %clearance at the fuselage line
            Fs_fus = aircraft_in.planform.FS_fus;
            C_fs = 1-(Fs_fus/0.15);

              
            %Inequality constraint ensuring a tank volume equal or larger 
            %than the fuel required for the mission
            W_f_true = results.W_f;
            V_t = results.Struc.V_t;

            C_fuel = 1-(W_f_true/(V_t*aircraft_in.rho_f));
            

                
            obj.C_eq = [C_cd, C_lift, C_mom, C_ww, C_wf];
            obj.C_ineq = [C_wl, C_fs, C_fuel];
        end
        
        function y_range = normalize_span(obj)
            % Obtains the normalized span coordinates of the current wing
            Y = obj.results.Loading.Y_coord.'; % Physical Span
            y_range = Y/max(Y); % Normalizing Span
        end
        
        function C_lift = lift_constraint(obj)
            obj.A_L_hat = obj.aircraft_in.A_L; % Guessed Coefficients

            % Obtaining best-fit coefficients from disciplines
            L_dist = obj.results.Loading.L_distr;
            obj.A_L = obj.fitCST(obj.y_range, L_dist', obj.A_L_hat);

            % Evaluating consistency constraint
            C_lift = 1 - obj.A_L_hat'./obj.A_L';
        end

        function C_mom = moment_constraint(obj)
            obj.A_M_hat = obj.aircraft_in.A_M; % Guessed Coefficients
            % True moment distribution
            M_dist = obj.results.Loading.M_distr; 
            obj.A_M = obj.fitCST(obj.y_range, M_dist', obj.A_M_hat);

            % Evaluating consistency constraint
            C_mom = 1 - obj.A_M_hat'./obj.A_M';
        end
        
        function C_cd = drag_constraint(obj)
            % Computed Drag Coefficient; Guessed Wing Drag Coefficient
            Cd_true = obj.results.C_dw; Cd_guess = obj.aircraft_in.C_d_w;
            
            % Drag Consistency Constraint
            C_cd = (Cd_guess / sum(Cd_true)) - 1;
        end
        
        function handle = plot_moment(obj)
            handle = figure('Name', 'MomentDistribution');
            hold on;
            dist = obj.results.Loading.M_distr;
            M_dist_hat = obj.shape_fcn(obj.y_range, obj.A_M_hat);            
            M_dist = obj.shape_fcn(obj.y_range, obj.A_M);
            
            plot(obj.y_range, M_dist_hat, 'DisplayName', 'Guess Value');
            plot(obj.y_range, M_dist, 'DisplayName', 'Final CST');
            plot(obj.y_range, dist, 'DisplayName', 'Actual');
            legend('location', 'Best');
            hold off;
        end
        
        function handle = plot_lift(obj)
            handle = figure('Name', 'LiftDistribution');
            hold on;
            dist = obj.results.Loading.L_distr;
            L_dist_hat = obj.shape_fcn(obj.y_range, obj.A_L_hat);            
            L_dist = obj.shape_fcn(obj.y_range, obj.A_L);
            
            plot(obj.y_range, L_dist_hat, 'DisplayName', 'Guess Value');
            plot(obj.y_range, L_dist, 'DisplayName', 'Final CST');
            plot(obj.y_range, dist, 'DisplayName', 'Actual');
            legend('location', 'Best');
            hold off;
        end
            
%         function Z = Bernplotter(Y, A, N)
%            
%             
%             n = length(A)-1;
%             i = 0:n;
% 
%             
%             yrange = Y.'/max(Y);
% 
%             B = ((factorial(n)./(factorial(i).*factorial(n-i))).*(yrange.^i).*(1-yrange)...
%                 .^(n-i)).*(yrange*N(1) + N(2));
% 
%             Z = B*A;
%         end        
    end
    
    methods (Static)
        function coeff = fitCST(norm_range, data, x0)
            % Starts from the current guess values of the Bernstein coefs,
            % and tries to find a better fit to the actual data
            optimset('MaxFunEvals',1e4);
            shape = @geometry.CSTAirfoil.shapeFunction;
            obj_func = @(x) sum(((data - shape(norm_range, x))./data).^2);
            coeff = fminsearch(obj_func, x0);
        end
    end
end
    
    
    
