
classdef Planform
    %Class responsible for calculating the various geometry properties of
    %the wing planform. Gamma is set to a fixed value
    

    properties
        %The properties in this list are variables. Their default values
        %correspond to the A320-200.
        
        Cr = 7.6863;     %Root chord[m]
        Sweep =25*pi/180;  %Quarter chord sweep angle[rad]
        tau = 0.24;    %Taper ratio(Ct/Cr)[-]
        b = 33.91;      %Wing span(total)[m]
        
        
    end
    properties(SetAccess = 'private')
        %Since this property is set, it has been set as private access.
        
        gamma = 8.3402  %Straight TE length of the first trapezoid[m]
        fs = 0.25       %Front spar position of second trapezoid
        rs = 0.75       %Rear spar position of second trapezoid
    end
    

    properties(Dependent)
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
            s = obj.Sweep;
            B = obj.b;
            t = obj.tau;
            
            a = g*(2*cr - (4/3)*g*tan(s)) + (0.5*B-g)*((1+t)*cr-(4/3)*...
                g*tan(s));
        end
        
        function b = get.Chords(obj)
            %Function for calculating the various wing chords
            b(1) = obj.Cr;
            b(2) = obj.Cr - (4/3)*obj.gamma*tan(obj.Sweep) + 0.05;
            b(3) = obj.tau*obj.Cr;
        end
        
        function c = get.Coords(obj)
            %Function for calculating the coordinates of the chord leading
            %edges
            x0 = 0;
            y0 = 0;
            z0 = 0;
            x1 = (4/3)*obj.gamma*tan(obj.Sweep);
            y1 = obj.gamma;
            z1 = 0;
            x2 = 0.25*obj.Cr + 0.5*obj.b*tan(obj.Sweep)-0.25*obj.tau*obj.Cr;
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
            s = obj.Sweep;
            B = obj.b;
            t = obj.tau;
            cm = cr - (4/3)*g*tan(s);
            ct = t*cr;
            
            a = g*(2*cr - (4/3)*g*tan(s)) + (0.5*B-g)*((1+t)*cr-(4/3)*...
                g*tan(s));
            
            C1 = (1/(4*tan(s)))*(cr^3 -(cr-(4/3)*tan(s)*g)^3);
            C2 = (0.5*B - g)*(cm^2)*(1 - (ct/cm)^3)/(3*(1-(ct/cm)));
            d = 2*(C1 + C2)/a;
            
        end
        function e = get.Twists(obj)
            e = [obj.t_1, obj.t_2, obj.t_3];
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
            s = obj.Sweep;
            Fs = obj.fs;
            tanfs = (cm-ct)*(0.25-Fs)/(0.5*B-g) + tan(s);
            g = (g*((4*tan(s)/3)-tanfs) + Fs*cm)/cr;
        end
        function g = get.rs_r(obj)
            cr = obj.Chords(1);
            cm = obj.Chords(2);
            ct = obj.Chords(3);
            g = obj.gamma;
            B = obj.b;
            s = obj.Sweep;
            Fs = obj.rs;
            tanfs = (cm-ct)*(0.25-Fs)/(0.5*B-g) + tan(s);
            g = (g*((4*tan(s)/3)-tanfs) + Fs*cm)/cr;
        end
        
        
        
        
        
        
       
        
        
    end
end

     

