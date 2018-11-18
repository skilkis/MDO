classdef Objective
    % This is the objective
    properties
        Fuelfrac
        
    end
    
    methods
        function obj = Objective(aircraft_in)
            W_f = aircraft_in.W_f;
            W_f0 = aircraft_in.W_f_hat_0;
            obj.Fuelfrac = W_f/W_f0;
        end
        
    end
end