classdef Structures < handle
    %STRUCTURES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        fuel_tank = struct('start', 0.1, 'end', 0.9)
        aircraft_in = aircraft.Aircraft('A320');
    end
    
    methods
        function obj = Structures()
            %STRUCTURES Construct an instance of this class
            %   Detailed explanation goes here
        end
    end
end

