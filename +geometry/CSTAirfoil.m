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

classdef CSTAirfoil < geometry.Airfoil
%RESPONSIBLE FOR BLAH BLAH

    properties (SetAccess = private)
        x_upper   % x coordinates of upper-surface points (column vector)
        x_lower   % y coordinates of upper-surface points (column vector)
        A_upper   % Upper surface Bernstein Coefficients
        A_lower   % Lower surface Bernstein coefficients
        N1        % LE Class Function value
        N2        % TE Class Function value
        y_upper   % y coordinate of upper-surface points (column vector)
        y_lower   % y coordinate of lower-surface points (column vector)
        x_max     % x location of maximum thickness
        t_max     % Normalized maximum thickness (t/c)
    end
    
    properties (SetAccess = private, GetAccess = private)
        classValues  % Class Function values w/ fields 'upper' and 'lower'
        shapeValues  % Shape Function values w/ fields 'upper' and 'lower'
    end
   
    
   methods
      %% Class Constructor
      function obj = CSTAirfoil(x_upper, varargin)
            %CLASS CONSTRUCTOR!
            
            % Default Values
            A_upper = [1, 1, 1, 1, 1];
            A_lower = [1, 1, 1, 1, 1];
            N1 = 0.5;
            N2 = 1.0;

            % Ability to add validator functions for
            p = inputParser; % Analyzes passed arguments
            addRequired(p, 'x_upper', @geometry.Validators.isvector)
            addOptional(p, 'x_lower', x_upper, ...
                @geometry.Validators.isvector);
            addOptional(p, 'A_upper', A_upper, ...
                @geometry.Validators.isvector);
            addOptional(p, 'A_lower', A_lower, ...
                @geometry.Validators.isvector);
            addOptional(p, 'N1', N1)
            addOptional(p, 'N2', N2)

            parse(p, x_upper, varargin{:});
            
            obj.x_upper = p.Results.x_upper;
            obj.x_lower = p.Results.x_lower;
            obj.A_upper = p.Results.A_upper;
            obj.A_lower = p.Results.A_lower;
            obj.N1 = p.Results.N1;
            obj.N2 = p.Results.N2;

            % Calculating Output
            obj.fetchClassValues();
            obj.fetchShapeValues();
            obj.fetchYValues();
      end
      
      % Dependent Attribute Getters
      function fetchClassValues(obj)
            % Localizing variables for clarity
            x_u = obj.x_upper;
            x_l = obj.x_lower;
            
            value.upper = obj.classFunction(x_u, obj.N1, obj.N2);
            value.lower = obj.classFunction(x_l, obj.N1, obj.N2);

            obj.classValues = value;
      end
      
      function fetchShapeValues(obj)
            % Localizing variables for clarity
            x_u = obj.x_upper;
            x_l = obj.x_lower;
            
            value.upper = obj.shapeFunction(x_u, obj.A_upper);
            value.lower = obj.shapeFunction(x_l, obj.A_lower);

            obj.shapeValues = value;
      end
      
      function fetchYValues(obj)
          obj.y_upper = obj.classValues.upper .* obj.shapeValues.upper;
          obj.y_lower = obj.classValues.lower .* obj.shapeValues.lower;    
      end
      
      function handle = plot(obj)
          figure('Name', inputname(1))
          hold on; grid minor
          plot(obj.x_upper, obj.y_upper)
          plot(obj.x_lower, obj.y_lower)
          axis([min(obj.x_upper), max(obj.x_upper),...
                -max(obj.x_upper) * 0.5, max(obj.x_upper)*0.5])
          legend('Upper Surface', 'Lower Surface')
          xlabel('Normalized Chord Location (x/c)','Color','k');
          ylabel('Normalized Chord-Normal Location (y/c)','Color','k');
          title('CSTAirfoil Geometry')
          handle = gcf();
      end

      function scaled = scale(obj, thickness)
            upper_func = @(x) obj.classFunction(x, obj.N1, obj.N2) * ...
                              obj.shapeFunction(x, obj.A_upper);
            lower_func = @(x) obj.classFunction(x, obj.N1, obj.N2) * ...
                               obj.shapeFunction(x, obj.A_lower);
            
            % Objective Function used to find the current thickness
            f = @(x) -(upper_func(x) - lower_func(x));
            
            % Normalized maximum thickness value and location
            [obj.x_max, obj.t_max] = fminbnd(f, 0.0, 1.0);
            obj.t_max = -obj.t_max; % Reverting thickness value;
            
            %  Establishing thickness scaling ratio
            ratio = thickness / obj.t_max;
            
            scaled = obj.copy(); scaled.t_max = thickness;            
            scaled.y_upper = obj.y_upper * ratio;
            scaled.y_lower = obj.y_lower * ratio;
            scaled.A_upper = obj.A_upper * ratio;
            scaled.A_lower = obj.A_lower * ratio;
      end
      
      function y_at_length(x)
          
      end
   end

   methods (Static)
     function classValue = classFunction(x, N1, N2)
          classValue = (x.^N1).*(1-x).^N2;
      end
      
      function shapeValue = shapeFunction(x, A)
        if isrow(A), else A = A'; end % Assert A is a row vector
        
        N = length(A)-1; % Degree of Max. Berstein Polynomial
        j = 0:N; % Setting up Degree Vector (0 to N)
        
        Krnu = factorial(N)./(factorial(j).*factorial(N-j));
        
        coeff = A.*Krnu;
        coeff_mat = repmat(coeff,length(x),1);
 
        x_mat = repmat(x, 1, N+1);
        j_mat = repmat(j, length(x), 1);
        
        shape_mat = ((1 - x_mat) .^ (N - j_mat)) .* (x_mat.^j_mat);       
        shapeValue = sum(coeff_mat .* shape_mat, 2);
      end
   end
end