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

classdef DesignVector < dynamicprops & handle
    %DESIGNVECTOR Utility class allowing key, value, lb, up pairs
    %   Solves the hassle of having to remember indices w/ fmincon

    properties
        init                % Initial Values of the Design Vector
        vector              % Current Design Vector (Normalized)
    end
    
    properties (SetAccess = private, GetAccess = private)
        keys                % Design Vector Keys
        cell_in             % Input cell containing key, value pairs
        lengths             % Lengths of each value to support arrays
    end
    
    properties (SetAccess = private)
        lb                  % Normalized Lower Bounds of Design Variable
        ub                  % Normalized Upper Bound of Design Variable
        history = []        % Stores previous values of the solver
    end
    
    methods
        
       % TODO add validator to check if correct inputs are provided
       % TODO add validator to check lb < ub
        function obj = DesignVector(cell_in)
            
            obj.cell_in = cell_in;
            obj.keys = cell_in(:,1);
            obj.lengths = cellfun(@(x) length(x), cell_in(:,2));
            obj.init = cat(2, obj.cell_in{:,2})'; 
            obj.vector = obj.init ./ obj.init; % Normalized
            obj.lb = zeros(length(obj.init), 1); obj.ub = obj.lb;
            
            key_idx = 1;
            vec_idx = 1; % Look-up index from
            for key = obj.keys'
                % Creating a getter for each key
                len = obj.lengths(key_idx);
                % Adding property per entry in design vector
                P = addprop(obj, key{:});
                P.GetMethod = @(obj) ...
                    obj.vector(vec_idx:(vec_idx + len - 1)) .* ...
                    obj.init(vec_idx:(vec_idx + len - 1));
                    obj.lb(vec_idx:(vec_idx + len - 1))...
                        = obj.cell_in{key_idx, 3};
                    obj.ub(vec_idx:(vec_idx + len - 1))...
                        = obj.cell_in{key_idx, 4};
                
                % Adding property per initial design vector
                P = addprop(obj, [key{:} '_0']);
                P.GetMethod = @(getter) ...
                    obj.init(vec_idx:(vec_idx + len - 1));
                
                % TODO experiment with set method
%                 P.SetMethod = @(setter) ...
%                     obj.vector(index:(index + len - 1)) .* ...
%                     obj.init(index:(index + len - 1));
                key_idx = key_idx + 1;
                vec_idx = vec_idx + len;
            end
        end
        
        function append_history(obj)
            % Appends the current vector to the history.
            obj.history = [obj.history, obj.vector];
        end
        
        function set.vector(obj, vector)
            % Setter of a vector, for when x.vector = vector syntax is used
            obj.append_history()
            obj.vector = vector;
        end

        function history = fetch_history(obj, varargin)
            % Fetches the history of the design vector from obj.history
            % and returns either the normalized or unormalized result
            % depending on user input
            %
            % Return Normalized History (Default behavior w/o argument):
            % obj.fetch_history('normalized', true)
            %
            % Return Proper History
            % obj.fetch_history('normalized', false)
            % 
            % Usage w/o arguments returns normalized history
            % obj.fetch_history()
            
            %Parsing arguments
            arg = inputParser; % Analyzes passed arguments
            addOptional(arg, 'normalized', true, @islogical);
            parse(arg, varargin{:});
            normalized = arg.Results.normalized;
            
            % Fetching desired history
            if normalized
                history = obj.history;
            else
                history = obj.history .* obj.init;
            end
        end
        
        function bool = isnew(obj, vector)
            % Determines if the supplied vector is a new entry
            if all(obj.vector == vector)
                bool = false;
            else
                bool = true;
            end
        end
  end
end
