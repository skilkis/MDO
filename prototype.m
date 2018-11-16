% clc
% clear all
% close all
% 
% A1 = [1.0, 1.5, 2.0]';
% A2 = [0.5, 0.75, 1.0]';
% 
% y1 = 0; y2 = 2;
% y = 3.0;
% 
% tic;
% Ay = util.interparray([0.0 1.0 2.0], 0.0, 1.0, A_root, A_tip);
% toc;
% 
% M1 = ones(2, 2);
% M2 = 2*ones(2, 2);
% 
% tic;
% A_i = util.interparray([0.0, 0.5, 1.0], 0, 1, M1, M2);
% toc;

in = s.EMWET_input;
out = s.EMWET_output;
span_loc = in.fuel_start;
[val, idx] = min(abs(out.half_span - span_loc));
%idx_nn =  Correct neighbouring index
if span_loc < out.half_span(idx)
    idx_nn = idx - 1;
else
    idx_nn = idx + 1;
end
% Obtaining data at either side of the required value
start_array = [out.t_u(idx_nn), out.t_l(idx_nn), out.t_fs(idx_nn),...
               out.t_rs(idx-1)];
end_array = [out.t_u(idx), out.t_l(idx), out.t_fs(idx), out.t_rs(idx)];

% Obtaning the span at either side of the required value
start_span = out.half_span(idx_nn); end_span = out.half_span(idx);
interp_array = util.interparray(span_loc,...
                                start_span,...
                                end_span,...
                                start_array,...
                                end_array);


