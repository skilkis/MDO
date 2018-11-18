% Copyright 2018 San Kilkis
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
                    valid = true;
                else
                    valid = false;
                end
            else
                valid = false;
            end
        end
       
        function valid = validAirfoilData(filename)
            fid = fopen([pwd '\data\airfoil\' filename], 'r');
            header = fgetl(fid);
            if ischar(header)
                data = fscanf(fid, '\t%g\t%g', [2 Inf]);
                fclose(fid);
                if isempty(data) > 0
                    valid = 1;
                end
                else
                fclose(fid);
                error('%s is not a valid airfoil file', filename)
            end
        end
        
        function valid = validAirfoil(airfoil)
            if isa(airfoil, 'geometry.Airfoil')
                
                valid = true; % Initially assuming valid ordinates
                
                % Localizing fields for readability
                x_upper = airfoil.x_upper; x_lower = airfoil.x_lower;
                y_upper = airfoil.y_upper; y_lower = airfoil.y_lower;
                
                % Testing Length of Ordinates
                if length(x_upper) ~= length(y_upper) || ...
                        length(x_lower) ~= length(y_lower)
                    valid = false;
                end
                
                % Testing Normalization of Ordinates
                if min(x_upper) ~= 0 || min(x_lower) ~= 0 ...
                        || max(x_upper) ~= 1 || max(x_lower) ~= 1
                    valid = false;
                end
                
            else
                warning('Input is not a valid Airfoil');
                valid = false;
            end
        end

        function valid = isInteger(num)
            if isfinite(num) && x==floor(x)
                valid = true;
            else
                valid = false;
            end
       end
    end
end

