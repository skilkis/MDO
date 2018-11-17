classdef FuelTank < handle
    %FUELTANK Constructs a plotable fuel-tank from the output of EMWET
    % Utilizes an array interpolation to obtain wing-structure data at

    
    properties
        structures_in       % Structures Object
        tank_data           % Interpolated Data for Fuel-Tank
        V_t                   % Total Fuel Tank Volume [m^3]
        convex_hull         % Structs containing pts, convhull
    end
    
    methods
        function obj = FuelTank(structures_in)
            %FUELTANK Construct an instance of this class
            %   Detailed explanation goes here
            obj.structures_in = structures_in;
            obj.fetch_data();
            obj.build_convexhull();
        end
        
        function fetch_data(obj)
            in = obj.structures_in.EMWET_input;
            out = obj.structures_in.EMWET_output;
            ac = obj.structures_in.aircraft_in;
            
            % Locations in which the fuel tank must lie
            req_locs = [0, in.fuel_start,...
                         ac.planform.eta(2), in.fuel_end];
                     
            % Keeping EMWET data less than the allowable fuel-tank span
            idx_fuel = (out.half_span < in.fuel_end);
            data = [out.half_span(idx_fuel), out.t_u(idx_fuel),...
                    out.t_l(idx_fuel), out.t_fs(idx_fuel),...
                    out.t_rs(idx_fuel)];
            
            % Interpolating at the locations where EMWET data might not 
            % exist [root, fuselage, kink, tip]
            for i = 1:length(req_locs)
                span = data(:,1); % Span entries
                loc = req_locs(i); % Localizing for clarity
                interp_data = obj.EMWET_interp(loc);
                
                %Determining where to add interpolated data
                keep_idx = loc < span; % Indices of data to keep
                if all(keep_idx)
                    data = [interp_data; data];
                elseif ~all(keep_idx) && ~any(keep_idx)
                    data = [data; interp_data];
                else
                    data = [data(~keep_idx, :); interp_data;...
                            data(keep_idx, :)];
                end
            end

            % Assigning back to struct
            obj.tank_data.half_span = data(:, 1);
            obj.tank_data.t_u = data(:, 2);
            obj.tank_data.t_l = data(:, 3);
            obj.tank_data.t_fs = data(:, 4);
            obj.tank_data.t_rs = data(:, 5);
            
            % Fetching FS and RS location at each station
            pln = ac.planform; y = obj.tank_data.half_span;
            obj.tank_data.FS = pln.FS_at_span(y);
            obj.tank_data.RS = pln.RS_at_span(y);
            obj.tank_data.LE = pln.LE_at_span(y);
            
            % Fetching Chord at eatch station
            obj.tank_data.chord = pln.chord_at_span(y);
            
            % Fetching Bernstien Coefficients at each station
            A_root = ac.A_root;
            A_tip = ac.A_tip;
            
            obj.tank_data.A = util.interparray(y,...
                                               0, 1, A_root, A_tip);
        end
        
        function [x, y, z] = get_bounds(obj)
            data = obj.tank_data;
            half_span = data.half_span;
            ac = obj.structures_in.aircraft_in;
            N = 20; % Must be an even number
            pnt_mat = zeros(N * length(half_span), 3);
            for i = 1:length(half_span)
                % Localizing Data
                FS = data.FS(i); RS = data.RS(i); LE = data.LE(i);
                A = data.A(i, :);
                A_upper = A(1:length(A)/2);
                A_lower = A((length(A)/2)+1:end);
                chord = data.chord(i);
                
                % Spar-web and skin thickness is in [mm]
                t_fs = data.t_fs(i) * 1e-3; t_rs = data.t_rs(i) * 1e-3;
                t_u = data.t_u(i) * 1e-3; t_l = data.t_l(i) * 1e-3;
                
                % N = Number of Upper/Lower Points
                % Constructing CST Airfoil from current points
                airfoil = geometry.CSTAirfoil(linspace(FS, RS, N/2)',...
                              'A_upper', A_upper', 'A_lower', A_lower');
                          
                % Fetching Points form constructed Airfoil and translating
                % them by the spar-web and skin panel thickness
                x_upper = airfoil.x_upper * chord  + LE;
                x_translate = zeros(size(x_upper));
                x_translate(1) = t_fs/2.0;
                x_translate(end) = -t_rs/2.0;
                
                x_upper = x_upper + x_translate; x_lower = x_upper;
                
                y_upper = airfoil.y_upper * chord - t_u;
                y_lower = airfoil.y_lower * chord + t_l;

                i_start = ((i-1)*N) + 1; i_end = i_start + N -1;
                
                % Due to local airfoil coordinates vs. global reference
                % system, x = x_airfoil; y = local span, z = y_airfoil
                span_vec = half_span(i) * (ac.b / 2.0) * ones(N, 1);
                pnt_mat(i_start:i_end, :) = [[x_upper; x_lower], ...
                                             span_vec,...
                                             [y_upper; y_lower]];
            end
            
            x = pnt_mat(:, 1); y = pnt_mat(:, 2); z = pnt_mat(:, 3);
        end
        
        function plot(obj)
            c = obj.convex_hull.center; w = obj.convex_hull.wing;
            hold on
            surf(c.x(c.K), c.y(c.K), c.z(c.K))
            surf(w.x(w.K), w.y(w.K), w.z(w.K))
            axis image
            xlabel('Chord')
            ylabel('Span')
            zlabel('Height') 
        end
        
        function build_convexhull(obj)
            [x, y, z] = obj.get_bounds();
            ac = obj.structures_in.aircraft_in;

            idx_c= (y <= (ac.D_fus / 2.0)); % Center-tank Indices
            x_c = x(idx_c); y_c = y(idx_c); z_c = z(idx_c);
            [K_center, V_center] = convhull(x_c,y_c,z_c, 'simplify', true);
            V_center = 2 * V_center * 0.93;
            center.K = K_center; center.V = V_center;
            center.x = x_c; center.y = y_c; center.z = z_c;
            
            idx_o = (y >= (ac.D_fus / 2.0)); % Wing-tank Indices
            x_o = x(idx_o); y_o = y(idx_o); z_o = z(idx_o);
            [K_outer, V_outer] = convhull(x_o, y_o, z_o, 'simplify', true);
            V_outer = 2 * V_outer * 0.93;
            wing.K = K_outer; wing.V = V_outer;
            wing.x = x_o; wing.y = y_o; wing.z = z_o;

            obj.convex_hull.wing = wing;
            obj.convex_hull.center = center;

            obj.V_t = center.V + wing.V;
        end
            
        function interp_array = EMWET_interp(obj, span_loc)
            % Interpolates EMWET data at the desired normalized span 
            %location provided by `span_loc`. Returns a row vector of 
            % [half_span, t_u, t_l, t_fs, t_rs].
            
            out = obj.structures_in.EMWET_output;
            [~, idx] = min(abs(out.half_span - span_loc));
            %idx_nn =  Correct neighbouring index
            if span_loc < min(out.half_span)
                idx_nn = idx + 1;
            elseif span_loc > max(out.half_span)
                idx_nn = idx - 1;
            elseif span_loc < out.half_span(idx)
                idx_nn = idx - 1;
            elseif span_loc > out.half_span(idx)
                idx_nn = idx + 1; 
            else
                interp_array = [out.t_u(idx), out.t_l(idx),...
                                out.t_fs(idx), out.t_rs(idx)];
                return
            end
            % Obtaining data at either side of the required value
            start_array = [out.t_u(idx_nn), out.t_l(idx_nn),...
                           out.t_fs(idx_nn), out.t_rs(idx_nn)];
            end_array = [out.t_u(idx), out.t_l(idx),...
                         out.t_fs(idx), out.t_rs(idx)];

            % Obtaning the span at either side of the required value
            start_span = out.half_span(idx_nn);
            end_span = out.half_span(idx);
            interp_array = [span_loc, util.interparray(span_loc,...
                                            start_span,...
                                            end_span,...
                                            start_array,...
                                            end_array)];
        end
    end
end

