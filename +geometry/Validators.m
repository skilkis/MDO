classdef Validators
    %VALIDATORS A convenience class that groups all custom validator
    % functions in a single file. This class utilizes a simple static
    % methods to house all validators in a convienient class
    methods (Static)
%         function obj = validators(inputArg1,inputArg2)
%             %VALIDATORS Construct an instance of this class
%             %   Detailed explanation goes here
%             obj.Property1 = inputArg1 + inputArg2;
%         end
        
        function valid = isvector(input)
            if isa(input, 'double')
                if iscolumn(input)
                    valid = 1;
                else
                    valid = 0;
                end
            else
                valid = 0;
            end
       end
    end
end

