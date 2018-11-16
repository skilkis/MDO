classdef Constraints < handle
    %% Constraints outputs
    properties
        
        C_eq;       %Array containing the values for the equality and consistency const.
        C_ineq;     %Array containing the inequality constraints
        

    end
    %% Constraint functions
    methods
        function obj = Constraints(runcase_n, results)
            
            
            %Comparing the guess value for Cd against the actual Cd
            Cd_true = results.C_dw;
            Cd_guess = runcase_n.C_dw_hat;
            C_cd = (Cd_guess/Cd_true)-1;
                
            %Comparing the guessed lift and moment distributions against the
            %actual distributions.
            L_distr_true = results.Loading.L_distr;
            M_distr_true = results.Loading.M_distr;
            Y = results.Loading.Y_coord.';
            
            
            A_L = runcase_n.A_L.';
            A_M = runcase_n.A_M.';
            
            
            n = length(A_L)-1;
            i = 0:n;


            yrange = Y/max(Y);

            B = ((factorial(n)./(factorial(i).*factorial(n-i))).*(yrange.^i).*(1-yrange)...
                .^(n-i));
            
            Z_L = B*A_L;
            Z_M = B*A_M;
            
            C_lift = sum(((L_distr_true-Z_L)./L_distr_true).^2);
            if C_lift <= 0.085
                C_lift = 0;
            end
            C_mom = sum(((M_distr_true-Z_M)./M_distr_true).^2);
            if C_mom <= 0.085
                C_mom = 0;
            end
               
            %Comparing the wing structual weight against the guessed value.        
            W_w_true = results.Struc.W_w;
            W_w_guess = runcase_n.W_w_hat;
            C_ww = (W_w_guess/W_w_true)-1;
                
                
            W_f_true = results.W_f;
            W_f_guess = runcase_n.W_f_hat;
            C_wf = (W_f_guess/W_f_true)-1;
                
                
            %Inequality constraint setting the wing loading equal or lower 
            %than initial value
            WL_0 = (runcase_n.W_aw + runcase_n.x.W_f_0 + runcase_n.W_w_0)/122.4;
            WL_guess = (runcase_n.W_aw + runcase_n.W_f_hat + runcase_n.W_w_hat)...
                /P.S;
            C_wl = 1 - (WL_0/WL_guess);
                    
            %Inequality constraint checking for the sufficient front spar 
            %clearance at the fuselage line
            Fs_fus = P.fs_f;
            C_fs = 1 - (Fs_fus/0.15);
                
            %Inequality constraint ensuring a tank volume equal or larger 
            %than the fuel required for the mission
            W_f_true = runcase_n.W_f;
            V_t = runcase_n.V_t;
            C_fuel = (W_f_true/params.rho_f)-V_t;
                
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
        
            
        
end
    
    
    
