function bestPos = findBestFocus(positions, sharpnessValues)
    % findBestFocus Returns the position with the maximum sharpness
    
    % Smooth the data slightly to remove single-point noise
    smoothedSharpness = movmean(sharpnessValues, 3);
    
    % Find the index of the highest sharpness value
    [~, maxIdx] = max(smoothedSharpness);
    
    % Get the corresponding motor position
    bestPos = positions(maxIdx);
    
    % Plot the focus curve so we can visually check if the peak is real
    figure;
    plot(positions, sharpnessValues, 'bo-', 'DisplayName', 'Raw Sharpness'); 
    hold on;
    plot(positions, smoothedSharpness, 'r--', 'DisplayName', 'Smoothed Sharpness');
    plot(bestPos, smoothedSharpness(maxIdx), 'g*', 'MarkerSize', 10, 'LineWidth', 2, 'DisplayName', 'Best Focus');
    
    xlabel('Motor Position (Steps)');
    ylabel('Sharpness (Tenengrad)');
    title('Autofocus Curve');
    legend('show');
    grid on;
    hold off;
end
