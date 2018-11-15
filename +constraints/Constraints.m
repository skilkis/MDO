classdef Constraints < handle
    %% Constraints outputs
    properties
        
        C_eq;       %Array containing the values for the equality and consistency const.
        C_ineq;     %Array containing the inequality constraints
        

    end
    %% Constraint functions
    methods
        function obj = Constraints(runcase_n)
            P = runcase_n.Planform;
            
            %Comparing the guess value for Cd against the actual Cd
            Cd_true = runcase_n.C_dw;
            Cd_guess = runcase_n.aircraft.C_dw_hat;
            C_cd = (Cd_guess/Cd_true)-1;
                
            %Comparing the guessed lift and moment distributions against the
            %actual distributions.
            L_distr_true = runcase_n.L_distr;
            M_distr_true = runcase_n.M_distr;
            
            L_distr_guess = runcase_n.Berns_L;
            M_distr_guess = runcase_n.Berns_Mom;
                    
            C_lift = sum((L_distr_true-L_distr_guess).^2);
            C_mom = sum((M_distr_true-M_distr_guess).^2);
               
            %Comparing the wing structual weight against the guessed value.        
            W_w_true = runcase_n.W_w;
            W_w_guess = runcase_n.W_w_hat;
            C_ww = (W_w_guess/W_w_true)-1;
                
                
            W_f_true = runcase_n.W_f;
            W_f_guess = runcase_n.W_f_hat;
            C_wf = (W_f_guess/W_f_true)-1;
                
                
            %Inequality constraint setting the wing loading equal or lower 
            %than initial value
            WL_0 = runcase_n.WL_0;
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
        end
            
        
end
    
    
    
