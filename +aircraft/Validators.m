classdef Validators
    %VALIDATORS A convenience class that groups all custom validator
    % functions in a single file. This class utilizes a simple static
    % methods to house all validators in a convienient class
    methods (Static)
        function valid = validAircraft(name)
            if exist([pwd '\data\aircraft\' name '.mat'], 'file')
                valid = true;
            else
                valid = false;
            end
        end
    end
end

