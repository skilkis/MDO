classdef Planform
    %Class responsible for calculating the various geometry properties of
    %the wing planform. Gamma is set to a fixed value
    

    properties
        %The properties in this list are variables. Their default values
        %correspond to the A320-200.
        
        Cr = 7.3834;        % Root chord [m]
        S1 = 31.87*pi/180;  % Inboard Quarter chord sweep angle [rad]
        S2 = 27.285*pi/180; % Outboard Quarter chord sweep angle [rad]
        tau = 0.2002;       % Taper ratio(Ct/Cr) [-]
        b = 33.91;          % Wing span(total) [m]
        t_r = 4.82;         % Twist angle value for root [deg]
        t_k = 0.62;         % Twist angle at kink [deg]
        t_t = -0.56;        % Twist angle at tip [deg]
        
    end

    properties (SetAccess = 'private')
        %Since this property is set, it has been set as private access.
        
        gamma = 6.0134%Straight TE length of the first trapezoid[m]
        fs = 0.2;%0.1937       %Front spar position of second trapezoid
        rs = 0.7255;%0.6801       %Rear spar position of second trapezoid
        D_fus = 3.95        %Fuselage diameter
    end
    

    properties (Dependent)
        %These properties result from the input variables and can be used
        %as geometry inputs for the analysis blocks.
        
        Chords          %Root, mid and tip chord in order[m]
        Coords          %Coordinates of root, mid and tip chord LE(x,y,z)[m]
        Twists
        MAC             %Mean aerodynamic chord[m]
        S               %Wing planform area[m^2]
        eta
        fs_f            %Front spar chordwise position at fuselage line
        rs_f            %Rear spar chordwise position at fuselage line
    end
    
    
    methods
        function obj = Planform(x)
            obj.Cr = x.c_r;
            obj.S1 = x.lambda_1*pi/180;
            obj.S2 = x.lambda_2*pi/180;
            obj.tau = x.tau;
            obj.b = x.b;
            obj.t_r = x.beta_root;
            obj.t_k = x.beta_kink;
            obj.t_t = x.beta_tip;
            
        end
        function a = get.S(obj)
            %Function for calculating the wing planform area
            cr = obj.Cr;
            g = obj.gamma;
            s1 = obj.S1;
            s2 = obj.S2;
            B = obj.b;
            t = obj.tau;
            
            cm = obj.Chords(2)+0.02;
            ct = obj.Chords(3);
            a = g*(cr+cm) + (0.5*B-g)*(cm+ct);
        end
        
        function b = get.Chords(obj)
            %Function for calculating the various wing chords
            b(1) = obj.Cr;
            b(2) = obj.Cr - obj.gamma*tan(obj.S1) - 0.02;
            b(3) = obj.tau*obj.Cr;
        end
        
        function c = get.Coords(obj)
            %Function for calculating the coordinates of the chord leading
            %edges
            x0 = 0;
            y0 = 0;
            z0 = 0;
            x1 = obj.gamma*tan(obj.S1);
            y1 = obj.gamma;
            z1 = 0;
            x2 = x1 + (0.5*obj.b-obj.gamma)*tan(obj.S2);
            y2 = 0.5*obj.b;
            z2 = 0;
            
            c = [x0, y0, z0;
                x1, y1, z1;
                x2, y2, z2];
        end
        
        function d = get.MAC(obj)
            %Function for calculating the mean aerodynamic chord
            cr = obj.Chords(1);
            g = obj.gamma;
            s1 = obj.S1;
            
            B = obj.b;
            
            cm = obj.Chords(2)+0.02;
            ct = obj.Chords(3);
            
            C1 = g*(cr^2 + cm*cr + cm^2)/3;
            C2 = (0.5*B-g)*(cm^2 + cm*ct + ct^2)/3;
            
            d = 2*(C1 + C2)/obj.S;
            
        end
        function e = get.Twists(obj)
            e = [obj.t_r, obj.t_k, obj.t_t];
        end
        function f = get.eta(obj)
            f = [0, obj.gamma/(0.5*obj.b), 1];
        end
        
        function g = get.fs_f(obj)
            cr = obj.Chords(1);
            cm = obj.Chords(2);
            ct = obj.Chords(3);
            g = obj.gamma;
            B = obj.b;
            df = obj.D_fus;
            s1 = obj.S1;
            s2 = obj.S2;
            Fs = obj.fs;
            
            
            tanfs = tan(s2) - Fs*(cm-ct)/(0.5*B-g);

            fsr = (g/cr)*(tan(s1) - tanfs) + Fs*cm/cr;
            g = fsr - (fsr - Fs)*(0.5*df/g);
        end
        
        function g = get.rs_f(obj)
            cr = obj.Chords(1);
            cm = obj.Chords(2);
            ct = obj.Chords(3);
            g = obj.gamma;
            B = obj.b;
            df = obj.D_fus;
            s1 = obj.S1;
            s2 = obj.S2;
            Rs = obj.rs;
            
            tanrs = tan(s2) - Rs*(cm-ct)/(0.5*B-g);

            rsr = (g/cr)*(tan(s1) - tanrs) + Rs*cm/cr;
            g = rsr - (rsr - Rs)*(0.5*df/g);
        end
    end
    
    methods (Static)
        %Leading edge function as a function of spanwise
        %y-coordinate(fraction of semi span)
        function x = X_LE(obj, y)
            sympref('HeavisideAtOrigin',0.5);
            Y = y*0.5*obj.b;
            
            x = heaviside(obj.gamma-Y).*(Y*tan(obj.S1)) + ...
                heaviside(Y-obj.gamma).*((Y-obj.gamma)*tan(obj.S2) + ...
                obj.gamma*tan(obj.S1));
            
        end
        %Chord length function as a function of spanwise
        %y-coordinate(fraction of semi span)
        function c = C(obj,y)
            Y = y*0.5*obj.b;
            
            cr = obj.Chords(1);
            cm = obj.Chords(2);
            ct = obj.Chords(3);
            
            c = heaviside(obj.gamma-Y).*(cr - (cr-cm).*Y./obj.gamma) + ...
                heaviside(Y-obj.gamma).*(cm - (cm-ct).*((Y-obj.gamma)/(...
                obj.b-obj.gamma)));
        end
        
    end
    
    


end

     

