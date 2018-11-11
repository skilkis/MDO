% classdef CSTAirfoil < geometry.Airfoil
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
            value.lower = -obj.classFunction(x_l, obj.N1, obj.N2);

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
          plot(obj.x_upper, obj.classValues.upper .* obj.shapeValues.upper)
          plot(obj.x_lower, obj.classValues.lower .* obj.shapeValues.lower)
          axis([min(obj.x_upper), max(obj.x_upper),...
                -max(obj.x_upper) * 0.5, max(obj.x_upper)*0.5])
          legend('Upper Surface', 'Lower Surface')
          xlabel('Normalized Chord Location (x/c)','Color','k');
          ylabel('Normalized Chord-Normal Location (y/c)','Color','k');
          title('CSTAirfoil Geometry')
          handle = gcf();
      end

      function output = scale(obj, chord, thickness)
          % TODO implement scaling functionality for a CSTAirfoil
        output = 'test';
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