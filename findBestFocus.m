function bestPos = findBestFocus(positions, sharpnessValues)
    % Find the motor position with the best sharpness
    
    % Smooth out the sharpness scores to ignore random spikes
    smoothedSharpness = movmean(sharpnessValues, 3);
    
    [~, maxIdx] = max(smoothedSharpness);
    bestPos = positions(maxIdx);
    
    % Show a plot of the sharpness
    figure;
    plot(positions, sharpnessValues, 'bo-', 'DisplayName', 'Raw Sharpness'); 
    hold on;
    plot(positions, smoothedSharpness, 'r--', 'DisplayName', 'Smoothed Sharpness');
    plot(bestPos, smoothedSharpness(maxIdx), 'g*', 'MarkerSize', 10, 'LineWidth', 2, 'DisplayName', 'Best Focus');
    
    xlabel('Motor Position (Steps)');
    ylabel('Sharpness (Tenengrad)');
    title('Autofocus Focus Curve');
    legend('show');
    grid on;
    hold off;
end
