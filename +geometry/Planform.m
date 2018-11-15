classdef Planform < handle
    %Class responsible for calculating the various geometry properties of
    %the wing planform. Gamma is set to a fixed value
    

    properties (SetAccess = 'private')
        %The properties in this list are variables. Their default values
        %correspond to the A320-200.
        
        aircraft_in          % Input Aircraft Object
        
        % Variables
        c_r = 7.3834;        % Root chord [m]
        lambda_1 = 31.87;    % Inboard Quarter chord sweep angle [rad]
        lambda_2 = 27.285;   % Outboard Quarter chord sweep angle [rad]
        tau = 0.2002;        % Taper ratio(Ct/Cr) [-]
        b = 33.91;           % Wing span(total) [m]
        beta_root = 4.82;    % Twist angle value for root [deg]
        beta_kink = 0.62;    % Twist angle at kink [deg]
        beta_tip = -0.56;    % Twist angle at tip [deg]
        
        % Parameters
        d_TE = 6.0134        %Straight TE length of the first trapezoid[m]
        FS = 0.2;%0.1937     %Front spar position of second trapezoid
        RS = 0.7255;%0.6801  %Rear spar position of second trapezoid
        D_fus = 3.95         %Fuselage diameter
    end
    

    properties (Dependent)
        %These properties result from the input variables and can be used
        %as geometry inputs for the analysis blocks.
        
        Chords          %Root, mid and tip chord in order[m]
        Coords          %Coordinates of root, mid and tip chord LE(x,y,z)[m]
        Twists          %Airfoil twists [root, kink, tip]
        MAC             %Mean aerodynamic chord[m]
        S               %Wing planform area[m^2]
        eta             %Normalized span [root, kink, tip] 
        FS_fus          %Front spar chordwise position at fuselage line
        RS_fus          %Rear spar chordwise position at fuselage line
        FS_root         %Front spar chord-wise position at root
        RS_root         %Rear spar chord-wise position at root
        FS_proj         %Projected front spar position at root
        RS_proj         %Projected rear spar position at root
    end
    
    
    methods
        function obj = Planform(aircraft_in)
            obj.aircraft_in = aircraft_in;
            % Variables
            obj.c_r = aircraft_in.c_r;
            obj.lambda_1 = aircraft_in.lambda_1;
            obj.lambda_2 = aircraft_in.lambda_2;
            obj.tau = aircraft_in.tau;
            obj.b = aircraft_in.b;
            obj.beta_root = aircraft_in.beta_root;
            obj.beta_kink = aircraft_in.beta_kink;
            obj.beta_tip = aircraft_in.beta_tip;
            % Parameters        
            obj.d_TE = aircraft_in.d_TE; %Straight TE length of the first trapezoid[m]
            obj.FS = aircraft_in.FS; %0.1937       %Front spar position of second trapezoid
            obj.RS = aircraft_in.RS; %0.6801       %Rear spar position of second trapezoid
            obj.D_fus = aircraft_in.D_fus;        %Fuselage diameter
        end
        
        function modify(obj, design_vector)
            x = design_vector;
            obj.c_r = x.c_r;
            obj.lambda_1 = x.lambda_1;
            obj.lambda_1 = x.lambda_2;
            obj.tau = x.tau;
            obj.b = x.b;
            obj.beta_root = x.beta_root;
            obj.beta_kink = x.beta_kink;
            obj.beta_tip = x.beta_tip;
        end
        
        function a = get.S(obj)
            %Function for calculating the wing planform area
            cr = obj.c_r;
            g = obj.d_TE;
%             s1 = obj.lambda_1;
%             s2 = obj.lambda_2;
            B = obj.b;
%             t = obj.tau;
            
            cm = obj.Chords(2)+0.02;
            ct = obj.Chords(3);
            a = g*(cr+cm) + (0.5*B-g)*(cm+ct);
        end
        
        function b = get.Chords(obj)
            %Function for calculating the various wing chords
            s1 = deg2rad(obj.lambda_1);
            b(1) = obj.c_r;
            b(2) = obj.c_r - obj.d_TE*tan(s1) - 0.02;
            b(3) = obj.tau*obj.c_r;
        end
        
        function c = get.Coords(obj)
            %Function for calculating the coordinates of the chord leading
            %edges
            x0 = 0;
            y0 = 0;
            z0 = 0;
            s1 = deg2rad(obj.lambda_1); s2 = deg2rad(obj.lambda_2);
            x1 = obj.d_TE*tan(s1);
            y1 = obj.d_TE;
            z1 = 0;
            x2 = x1 + (0.5*obj.b-obj.d_TE)*tan(s2);
            y2 = 0.5*obj.b;
            z2 = 0;
            
            c = [x0, y0, z0;
                x1, y1, z1;
                x2, y2, z2];
        end
        
        function d = get.MAC(obj)
            %Function for calculating the mean aerodynamic chord
            cr = obj.Chords(1);
            g = obj.d_TE;
            
            B = obj.b;
            
            cm = obj.Chords(2)+0.02;
            ct = obj.Chords(3);
            
            C1 = g*(cr^2 + cm*cr + cm^2)/3;
            C2 = (0.5*B-g)*(cm^2 + cm*ct + ct^2)/3;
            
            d = 2*(C1 + C2)/obj.S;
            
        end
        
        function e = get.Twists(obj)
            e = [obj.beta_root, obj.beta_kink, obj.beta_tip];
        end
        
        function f = get.eta(obj)
            f = [0, obj.d_TE/(0.5*obj.b), 1];
        end

        function fsr = get.FS_proj(obj)
            cr = obj.Chords(1);
            cm = obj.Chords(2);
            ct = obj.Chords(3);
            g = obj.d_TE;
            B = obj.b;
            s1 = deg2rad(obj.lambda_1);
            s2 = deg2rad(obj.lambda_2);
            Fs = obj.FS;
            
            
            tanfs = tan(s2) - Fs*(cm-ct)/(0.5*B-g);

            % Projected FS position at root
            fsr = (g/cr)*(tan(s1) - tanfs) + Fs*cm/cr;
        end
        
        function g = get.FS_fus(obj)
            fsr = obj.FS_proj; % Projected FS position at root
            g = fsr - (fsr - obj.FS)*(0.5*obj.D_fus/obj.d_TE);
        end

        function rsr = get.RS_proj(obj)
            cr = obj.Chords(1);
            cm = obj.Chords(2);
            ct = obj.Chords(3);
            g = obj.d_TE;
            B = obj.b;
            s1 = deg2rad(obj.lambda_1);
            s2 = deg2rad(obj.lambda_2);
            Rs = obj.RS;
            
            tanrs = tan(s2) - Rs*(cm-ct)/(0.5*B-g);
            % Projected RS position at root
            rsr = (g/cr)*(tan(s1) - tanrs) + Rs*cm/cr;
        end
        
        function g = get.RS_fus(obj)
            rsr = obj.RS_proj;
            g = rsr - (rsr - obj.RS)*(0.5*obj.D_fus/obj.d_TE);
        end
        
        % TODO change these two dependent properties to not use other
        % dependent properties (increase performance, but requires your equations Evert)
        function FS_root = get.FS_root(obj)
            cr = obj.c_r;
            eta_fus = obj.D_fus / obj.b;
            
            % Obtaining chord at span
            x_LE_fus = obj.LE_at_span(eta_fus);
            c_fus = obj.chord_at_span(eta_fus);
            
            % Obtaining x-location of FS_fus and RS_fus
            x_FS = x_LE_fus + (c_fus * obj.FS_fus);
            FS_root = x_FS / cr;
        end
        
        function RS_root = get.RS_root(obj)
            cr = obj.c_r;
            eta_fus = obj.D_fus / obj.b;
            
            % Obtaining chord at span
            x_LE_fus = obj.LE_at_span(eta_fus);
            c_fus = obj.chord_at_span(eta_fus);
            
            % Obtaining x-location of FS_fus and RS_fus
            x_RS = x_LE_fus + (c_fus * obj.RS_fus);
            RS_root = x_RS / cr;
        end
        
        function x = LE_at_span(obj, y)
        %Leading edge function as a function of spanwise
        %y-coordinate(fraction of semi span)
            sympref('HeavisideAtOrigin',0.5);
            Y = y*0.5*obj.b;

            s1 = deg2rad(obj.lambda_1);
            s2 = deg2rad(obj.lambda_2);
            
            x = heaviside(obj.d_TE-Y).*(Y*tan(s1)) + ...
                heaviside(Y-obj.d_TE).*((Y-obj.d_TE)*tan(s2) + ...
                obj.d_TE*tan(s2));
            
        end

        function c = chord_at_span(obj,y)
        %Chord length function as a function of spanwise
        %y-coordinate(fraction of semi span)
            Y = y*0.5*obj.b;
            
            cr = obj.Chords(1);
            cm = obj.Chords(2);
            ct = obj.Chords(3);
            
            c = heaviside(obj.d_TE-Y).*(cr - (cr-cm).*Y./obj.d_TE) + ...
                heaviside(Y-obj.d_TE).*(cm - (cm-ct).*((Y-obj.d_TE)/(...
                0.5*obj.b-obj.d_TE)));
        end
        
        function handle = plot(obj)
            figure('Name', 'Planform');
            hold on; grid on; grid minor;
            
            % Gathering Outer Planform Points
            x = [obj.Coords(:, 1); flipud(obj.Coords(:, 1) + obj.Chords');...
                obj.Coords(1,1)];
            y = [obj.Coords(:, 2); flipud(obj.Coords(:, 2));...
                obj.Coords(1,2)];

            % Gathering Spar Parameters
            eta_spar = [0, obj.D_fus/(obj.b), obj.eta(2:end)];
            x_le = [obj.Coords(1, 1); obj.LE_at_span(eta_spar(2)); ...
                    obj.Coords(2:end, 1)];
            chords = [obj.Chords(1), obj.chord_at_span(eta_spar(2)), ...
                    obj.Chords(2:end)]';
            disp(chords)

            FS_frac = [obj.FS_root, obj.FS_fus, obj.FS, obj.FS]';
            RS_frac = [obj.RS_root, obj.RS_fus, obj.RS, obj.RS]';
            
            x_FS = chords .* FS_frac + x_le;
            x_RS = chords .* RS_frac + x_le;

            plot(y, x, 'DisplayName', 'Planform')
            line(0.5*[obj.D_fus obj.D_fus],get(gca,'YLim'),...
                'LineStyle', '-.', 'Color', 'k', 'DisplayName',...
                'Fuselage-Line')
            plot((eta_spar * 0.5 * obj.b), x_FS, 'DisplayName',...
                'Front Spar')
            plot((eta_spar * 0.5 * obj.b), x_RS, 'DisplayName',...
                'Rear Spar')
            plot(0, obj.FS_proj * chords(1), 'o', 'DisplayName',...
                'Projected FS')
            plot(0, obj.RS_proj * chords(1), 'o', 'DisplayName',...
                'Projected RS')
            axis image
            set(gca,'Ydir','reverse')
            hold off;
            xlabel('Half-Span (y) [m]','Color','k');
            ylabel('Chord-Wise Length (x)','Color','k');
            legend()
            title(sprintf('%s Planform Geometry', obj.aircraft_in.name))
            handle = gcf();
        end
    end
end

     

