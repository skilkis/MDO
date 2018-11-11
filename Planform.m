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
        D_f = 3.95        %Fuselage diameter
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
        fs_r            %Root chord front spar position
        rs_r            %Root chord rear spar position
    end
    
    
    methods
        function a = get.S(obj)
            %Function for calculating the wing planform area
            cr = obj.Cr;
            g = obj.gamma;
            s1 = obj.S1;
            s2 = obj.S2;
            B = obj.b;
            t = obj.tau;
            
            cm = cr-g*tan(s1);
            ct = t*cr;
            a = g*(cr+cm) + (0.5*B-g)*(cm+ct);
        end
        
        function b = get.Chords(obj)
            %Function for calculating the various wing chords
            b(1) = obj.Cr;
            b(2) = obj.Cr - (4/3)*obj.gamma*tan(obj.S1) - 0.02;
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
            cr = obj.Cr;
            g = obj.gamma;
            s1 = obj.S1;
            
            B = obj.b;
            t = obj.tau;
            cm = cr - g*tan(s1);
            ct = t*cr;
            
            a = g*(cr+cm) + (0.5*B-g)*(cm+ct);
            d = 2*((((cr^3)-(cm^3))/tan(s1)) + (0.5*B-g)*((cm^3)-ct^3)/(cm-ct))/...
                (3*g*cr + 3*B*cm/2 + 3*ct*(0.5*B-g));
            
        end
        function e = get.Twists(obj)
            e = [obj.t_r, obj.t_k, obj.t_t];
        end
        function f = get.eta(obj)
            f = [0, obj.gamma/(0.5*obj.b), 1];
        end
        
        function g = get.fs_r(obj)
            cr = obj.Chords(1);
            cm = obj.Chords(2);
            ct = obj.Chords(3);
            g = obj.gamma;
            B = obj.b;
            df = obj.D_f;
            s1 = obj.S1;
            s2 = obj.S2;
            Fs = obj.fs;
            crf = cr-0.5*df*tan(s1);
            
            g = (Fs/(crf*(B-2*g)))*(cm*(B-df)-ct*(2*g-df)) + (g-df/2)*(...
                tan(s1)-tan(s2));
        end
        function g = get.rs_r(obj)
            cr = obj.Chords(1);
            cm = obj.Chords(2);
            ct = obj.Chords(3);
            g = obj.gamma;
            B = obj.b;
            df = obj.D_f;
            s1 = obj.S1;
            s2 = obj.S2;
            Rs = obj.rs;
            crf = cr-0.5*df*tan(s1);
            
            g = (Rs/(crf*(B-2*g)))*(cm*(B-df)-ct*(2*g-df)) + (g-df/2)*(...
                tan(s1)-tan(s2));
        end
    end
end

     

