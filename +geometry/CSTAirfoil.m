classdef CSTAirfoil
%RESPONSIBLE FOR BLAH BLAH

   properties
      x_upper   % x coordinates of upper-surface points
      x_lower   % y coordinates of upper-surface points
      A_upper   % Upper surface Bernstein Coefficients
      A_lower   % Lower surface Bernstein coefficients
      N1        % LE Class Function value
      N2        % TE Class Function value
   end
   
   properties (Dependent, SetAccess = private) % Only can set by itself
       classValues  % Class Function values w/ fields 'upper' and 'lower'
       shapeValues  % Shape Function values w/ fields 'upper' and 'lower'
       y_upper      % y coordinate of upper-surface points
       y_lower      % y coordinate of lower-surface points
   end
   
   methods
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
            addOptional(p, 'x_lower', x_upper);
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
        
      end
      
      function value = get.classValues(obj)
            % Localizing variables for clarity
            x_u = obj.x_upper;
            x_l = obj.x_lower;
            
            value.upper = obj.classFunction(x_u, obj.N1, obj.N2);
            value.lower = -obj.classFunction(x_l, obj.N1, obj.N2);
      end
      
      function value = get.shapeValues(obj)
            % Localizing variables for clarity
            x_u = obj.x_upper;
            x_l = obj.x_lower;
            
            value.upper = obj.shapeFunction(x_u, obj.A_upper);
            value.lower = obj.shapeFunction(x_l, obj.A_lower);
      end
      
      function value = get.y_upper(obj)
          value = obj.classValues.upper .* obj.shapeValues.upper;    
      end
      
      function value = get.y_lower(obj)
          value = obj.classValues.lower .* obj.shapeValues.lower;
      end
      
      function plot(obj)
          figure('Name', inputname(1))
          hold on; grid minor
          plot(obj.x_upper, obj.classValues.upper .* obj.shapeValues.upper)
          plot(obj.x_lower, obj.classValues.lower .* obj.shapeValues.lower)
          xlabel('Normalized Chord (x/c)')
          ylabel('Normalized Thickness (t/c)')
          axis([min(obj.x_upper), max(obj.x_upper),...
                -max(obj.x_upper) * 1.0, max(obj.x_upper)*1.0])
      end
   end
   methods (Static)
      function obj = loadobj(s)
          obj.A_upper = s;
          disp('I Loaded')
      end
      
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