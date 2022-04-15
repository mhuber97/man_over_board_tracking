function horizon_height = get_stable_horizon_height(horizon_height_history, buffer_size)
    % In order to smoothen possible mistakes of the horizon height
    % detection we build a buffer-array that considers the mean of the last
    % #buffer_size horizon heights.
    
    buffer_len = length(horizon_height_history);
    if length(horizon_height_history) >= buffer_size
        horizon_height = mean(horizon_height_history(buffer_len - buffer_size + 1: buffer_len));
    else
        horizon_height = mean(horizon_height_history);
    end
end