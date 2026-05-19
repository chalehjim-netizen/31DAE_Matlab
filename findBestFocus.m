function [bestPos, fig] = findBestFocus(positions, sharpnessValues, scanName)
    % Find the motor position with the best sharpness
    if nargin < 3
        scanName = 'Autofocus Focus Curve';
    end
    
    % Smooth out the sharpness scores to ignore random spikes
    smoothedSharpness = movmean(sharpnessValues, 3);
    
    [~, maxIdx] = max(smoothedSharpness);
    bestPos = positions(maxIdx);
    
    % Show a plot of the sharpness
    fig = figure('Name', scanName);
    plot(positions, sharpnessValues, 'bo-', 'DisplayName', 'Raw Sharpness'); 
    hold on;
    plot(positions, smoothedSharpness, 'r--', 'DisplayName', 'Smoothed Sharpness');
    plot(bestPos, smoothedSharpness(maxIdx), 'g*', 'MarkerSize', 10, 'LineWidth', 2, 'DisplayName', 'Best Focus');
    
    xlabel('Motor Position (Steps)');
    ylabel('Sharpness (Tenengrad)');
    title(scanName);
    legend('show');
    grid on;
    hold off;
end
