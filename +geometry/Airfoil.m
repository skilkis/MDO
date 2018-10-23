classdef (Abstract) Airfoil
    %AIRFOIL Parent-class setting required properties
    
    properties (Abstract, SetAccess = private)
        x_upper     % Column vector of upper surface x-ordinates
        x_lower     % Column vector of lower surface x-ordinates
        y_upper     % Column vector of upper surface y-ordinates
        y_lower     % Column vector of lower surface y-ordinates
    end
    
    methods (Abstract)
        plot(obj)
    end
%     
%     methods
%         function obj = Airfoil(inputArg1,inputArg2)
%             %AIRFOIL Construct an instance of this class
%             %   Detailed explanation goes here
%             obj.Property1 = inputArg1 + inputArg2;
%         end
%         
%         function outputArg = method1(obj,inputArg)
%             %METHOD1 Summary of this method goes here
%             %   Detailed explanation goes here
%             outputArg = obj.Property1 + inputArg;
%         end
%     end
end

