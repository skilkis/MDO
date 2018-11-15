classdef (Abstract) Airfoil < handle
    %AIRFOIL Parent-class setting required properties
    
    properties (Abstract, SetAccess = private)
        x_upper     % Column vector of upper surface x-ordinates
        x_lower     % Column vector of lower surface x-ordinates
        y_upper     % Column vector of upper surface y-ordinates
        y_lower     % Column vector of lower surface y-ordinates
    end
    
    methods (Abstract)
        scale(obj, chord, thickness)
    end
    
    methods
        function handle = plot(obj)            
            figure('Name', obj.name);
            hold on; grid on; grid minor;
            plot(obj.x_upper, obj.y_upper)
            plot(obj.x_lower, obj.y_lower)
            chord = max([obj.x_upper; obj.x_lower]);
            axis([0, chord, -0.5 * chord, 0.5 * chord])
            hold off;
            xlabel('Normalized Chord Location (x/c)','Color','k');
            ylabel('Normalized Chord-Normal Location (y/c)','Color','k');
            legend('Upper Surface', 'Lower Surface')
            title(sprintf('%s Geometry', obj.name))
            handle = gcf();
        end
        
        function copy_obj = copy(obj)
        %Makes a fast object copy utilizing the MATLAB ByteStream
            try
                % R2010b or newer - directly in memory (faster)
                objByteArray = getByteStreamFromArray(obj);
                copy_obj = getArrayFromByteStream(objByteArray);
            catch
                % R2010a or earlier - serialize via temp file (slower)
                fname = tempname([pwd '\temp\']);
                save(fname, 'obj');
                newObj = load(fname);
                copy_obj = newObj.obj;
                delete(fname);
            end
        end
        
        function write(obj, filepath)
            % Writes an Airfoil .dat file where the order of points is from
            % TE -> Upper Surface -> LE -> Lower Surface -> TE. Assumes
            % that the minimum x starts at zero
            
            x_max = max([obj.x_upper; obj.x_lower]);
            if x_max <= 1.0
                ratio = x_max^-1;
                x_u = obj.x_upper * ratio;
                x_l = obj.x_lower * ratio;
                y_u = obj.y_upper * ratio;
                y_l = obj.y_lower * ratio;
                data = [flipud(x_u), flipud(y_u); ...
                        x_l(2:end), y_l(2:end)];
            else
                data = [flipud(obj.x_upper), flipud(obj.y_upper); ...
                        obj.x_lower(2:end), obj.y_lower(2:end)];
            end
            fid = fopen(filepath, 'w');
                for i = 1:length(data)
                    fprintf(fid, '%.6f %.6f\n', data(i,1), data(i,2));
                end
            fclose(fid);
        end
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

