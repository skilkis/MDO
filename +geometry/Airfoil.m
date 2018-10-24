classdef (Abstract) Airfoil < handle
    %AIRFOIL Parent-class setting required properties
    
    properties (Abstract, SetAccess = private)
        x_upper     % Column vector of upper surface x-ordinates
        x_lower     % Column vector of lower surface x-ordinates
        y_upper     % Column vector of upper surface y-ordinates
        y_lower     % Column vector of lower surface y-ordinates
    end
    
    methods (Abstract)
        plot(obj)
        scale(obj, chord, thickness)
    end
end
    
%     methods
%          function scale_thickness(obj, t_over_c)
%             upper_spline = spline(obj.x_upper, obj.y_upper);
%             lower_spline = spline(obj.x_lower, obj.y_lower);
%             
%             % Objective Function used to find the current thickness
%             f = @(x) -(ppval(upper_spline, x) - ppval(lower_spline, x));
%             
%             % Normalized maximum thickness value and location
%             [x_max, t_max] = fminbnd(f, 0.0, 1.0);
%             
%             current_thickness = -t_max;
%             ratio = t_over_c / current_thickness;
%             
%             obj.y_upper = obj.y_upper * (ratio / 2);
%             obj.y_lower = obj.y_lower * (ratio / 2);
%         end

