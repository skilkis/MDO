classdef Constraints < handle
    %% Constraints outputs
    properties
        
        C_eq;       %Array containing the values for the equality and consistency const.
        C_ineq;     %Array containing the inequality constraints
        

    end
    %% Constraint functions
    methods
        function obj = Constraints(aircraft_in, results, x)
            
            %Comparing the guess value for Cd against the actual Cd
            Cd_true = results.C_dw;
            Cd_guess = aircraft_in.C_d_w;
            
            % Drag Consistency Constraint
            C_cd = (Cd_guess/sum(Cd_true))-1; % TODO check if this is still necessary

            %Comparing the guessed lift and moment distributions against a
            % a Bernstein polynomial fitted to the actual data
            L_distr_true = results.Loading.L_distr;
            M_distr_true = results.Loading.M_distr;
            Y = results.Loading.Y_coord.';
            yrange = Y/max(Y); % Normalizing span
            
            % Localizing Guess Lift/Moment Coefficients
            A_L = aircraft_in.A_L;
            A_M = aircraft_in.A_M;
            
            % Obtaining Resultant Coefficients from Loads Calc.
            A_L_true = obj.fitCST(yrange, L_distr_true', A_L);
            A_M_true = obj.fitCST(yrange, M_distr_true', A_M);
            
%             shape = @geometry.CSTAirfoil.shapeFunction;
%             figure('Name', 'MomentDistribution')
%             hold on;
%             L_dist = shape(yrange, A_L);
%             M_dist = shape(yrange, A_M);
%             
%             L_dist_true = shape(yrange, A_L_true);
%             M_dist_true_CST = shape(yrange, A_M_true);
%             
%             plot(yrange, M_dist, 'DisplayName', 'Guess Value');
%             plot(yrange, M_dist_true_CST, 'DisplayName', 'Final CST');
%             plot(yrange, M_distr_true, 'DisplayName', 'Actual');
%             legend('location', 'Best');
            
            % Consistency is = 0 when A_L = A_L_true & A_M = A_M_true
            C_lift = 1 - sum(A_L./A_L_true);
            C_mom = 1 - sum(A_M./A_M_true);
            
            %Comparing the wing structual weight against the guessed value.        
            W_w_true = results.Struc.W_w;
            W_w_guess = aircraft_in.W_w;
            C_ww = (W_w_guess/W_w_true)-1;

            W_f_true = results.W_f;
            W_f_guess = aircraft_in.W_f;
            C_wf = (W_f_guess/W_f_true)-1;

            %Inequality constraint setting the wing loading equal or lower 
            %than initial value
            % TODO change aircraft.S to aircraft.S_ref to avoid confusion
            WL_0 = (aircraft_in.W_aw + x.W_f_0 + x.W_w_0)/aircraft_in.S;
            WL_guess = (aircraft_in.W_aw + aircraft_in.W_f + aircraft_in.W_w)...
                /aircraft_in.planform.S;
            C_wl = 1 - (WL_0/WL_guess);

            %Inequality constraint checking for the sufficient front spar 
            %clearance at the fuselage line
            Fs_fus = aircraft_in.planform.FS_fus;
            C_fs = 1 - (Fs_fus/0.15);

              
            %Inequality constraint ensuring a tank volume equal or larger 
            %than the fuel required for the mission
            W_f_true = results.W_f;
            V_t = results.Struc.V_t;

            C_fuel = (W_f_true/(V_t*aircraft_in.rho_f))-1;
            

                
            obj.C_eq = [C_cd, C_lift, C_mom, C_ww, C_wf];
            obj.C_ineq = [C_wl, C_fs, C_fuel];
        end
            
        function Z = Bernplotter(Y, A, N)
           
            
            n = length(A)-1;
            i = 0:n;

            
            yrange = Y.'/max(Y);

            B = ((factorial(n)./(factorial(i).*factorial(n-i))).*(yrange.^i).*(1-yrange)...
                .^(n-i)).*(yrange*N(1) + N(2));

            Z = B*A;
        end        
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
    
    
    
