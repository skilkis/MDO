classdef FuelTank < handle
    %FUELTANK Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        structures_in       % Structures Object
    end
    
    methods
        function obj = FuelTank(structures_in)
            %FUELTANK Construct an instance of this class
            %   Detailed explanation goes here
            obj.structures_in = structures_in;
        end
        
        function build_tank_array(obj)
            in = obj.structures_in.EMWET_input;
            out = obj.structures_in.EMWET_output;
            ac = obj.structures_in.aircraft_in;
            % Locations in which the fuel tank must lie
            tank_locs = [in.fuel_start ]
        end
        
        function interp_array = EMWET_interp(obj, span_loc)
            %ENWET_interp Interpolates EMWET data at the desired
            %normalized span location provided by `span_loc`
            
            out = obj.structures_in.EMWET_output;
            [~, idx] = min(abs(out.half_span - span_loc));
            %idx_nn =  Correct neighbouring index
            if span_loc < out.half_span(idx)
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
            interp_array = util.interparray(span_loc,...
                                            start_span,...
                                            end_span,...
                                            start_array,...
                                            end_array);
        end
    end
end

