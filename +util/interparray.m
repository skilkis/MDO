function array_out = interparray(int_locs, start_scalar, end_scalar, start_array, end_array)
    %LINEARINTERP 1-to-1 interpolation of a vector or matrix point-cloud
    % Start/end arrays must have the same dimension! The interpolation will
    % keep the dimension of the input arrays and return the interpolated
    % data in the other dimension (For a row vector input, int_locs will
    % return n number of row vectors and vice versa). For a matrix the
    % int_locs will be returned in the 3rd dimension (:, :, n).

    % Parameters:
    % int_locs: Location(s) to evaluate between start_scalar/end_scalar
    % start_scalar: Starting 1-D axis value
    % end_scalar: End 1-D axis value
    % start_array: Starting array/vector located at start_scalar
    % end_array: End array/vector located on 1-D axis defined by end_scalar
    
    %% Tests
    transposed = false;
    % Filtering invalid array input
    if size(start_array) ~= size(end_array)
        error('Dimension of interpolated arrays must match')
    end
    
    % Filtering invalid interpolation locations
    if ~isvector(int_locs)
        error('Interpolated locations must be a vector')
    elseif ~isrow(int_locs)
        int_locs = int_locs';
        transposed = true;
    end
    
    % Checking that evaluation scalar(s) are within the bounds
    if ~all(start_scalar <= int_locs) && ~all(int_locs <= end_scalar)
        warning('Some evaluation points are outside of the bounds')
    end
    
    % Correcting non-column vector
    if ~iscolumn(start_array) && isvector(start_array)
        start_array = start_array'; end_array = end_array';
        transposed = true;
    end

    %% Interpolation
    % Vectorized linear intepolation function
    slope = (end_array - start_array) / (end_scalar - start_scalar);
    if isvector(start_array)
        slope_mat = repmat(slope, 1, length(int_locs));
        eval_mat = (int_locs - start_scalar) .* slope_mat;
        start_mat = repmat(start_array, 1, length(int_locs));
    elseif ismatrix(start_array)
        % Turning int_locs into a (1, 1, p) 3-d array
        int_nd = reshape(int_locs, 1, 1, length(int_locs));
        slope_mat = repmat(slope, 1, 1, length(int_locs));
        eval_mat = (int_nd - start_scalar) .* slope_mat;
        start_mat = repmat(start_array, 1, 1, length(int_locs));        
    end
    % array_out = (int_locs - start_scalar) .* slope_mat + (start_array);
    array_out = eval_mat + start_mat;
    
    % Trasposing matrix back into row vector
    if transposed
        array_out = array_out';
    end
end

