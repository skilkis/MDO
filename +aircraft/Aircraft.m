classdef Aircraft
    %AIRCRAFT Base-Class of a generic Aircraft.
    % Defines the inputs and methods necessary set-up an initial design 
    % condition for the optimizer.
    
    properties
        h_cruise        % Cruise altitude in SI meter
        M_cruise        % Cruise Mach Number
        S_wet           % Aircraft Wetted Area
        S_ref           % Reference Wing-planform area
        
        
    end
    
    methods
        function obj = Aircraft(inputArg1,inputArg2)
            %AIRCRAFT Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

