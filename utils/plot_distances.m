function plot_distances(distances)
    % Creates scatter plot of the measured distances with a linear
    % regression that estimates the general trend of the distances
    % throughout the frames.

    x_arr = linspace(1, length(distances), length(distances));
    figure; hold on;
    scatter(x_arr, distances);
    
    % Linear regression to plot the distance trend
    coefficients = polyfit(x_arr, distances, 1);
    fittedY = polyval(coefficients, x_arr);
    
    % Do the plotting:
    plot(x_arr, fittedY, 'rs-', 'LineWidth', 3, 'MarkerSize', 0.5);
    
    title('Distance measurement over the video');
    xlabel('Iteration');
    ylabel('Measured distance (m)');

    sum = 0;
    for i=1:length(distances)
        sum = sum + abs(distances(i) - (coefficients(1)*i + coefficients(2))).^2;
    end
    
    standard_deviation = sqrt(sum / length(distances));
    disp("Standard deviation of the distances to the linear regression model: " + standard_deviation);
end

