function [positions, sharpnessValues] = fineScan(vid, StepMot, scanRange, fineStep, settlingTime)
    % fineScan - Does a small, high-resolution sweep to find the exact focus peak
    
    % Arrays to store our data
    positions = [];
    sharpnessValues = [];
    
    % Loop through the fine scan range
    for pos = scanRange(1):fineStep:scanRange(2)
    
        % Move motor to target position
        moveMotor(StepMot, pos);
    
        % Wait a tiny bit for the physical stage to stop shaking
        pause(settlingTime);
    
        % Take a picture
        img = captureFrame(vid);
    
        % Calculate how sharp the picture is
        sharpness = computeSharpness(img);
    
        % Save the data
        positions(end+1) = pos;
        sharpnessValues(end+1) = sharpness;
    
        % Print progress to the console
        fprintf('Fine Scan - Position: %d | Sharpness: %.2f\n', pos, sharpness);
    end
    % Determine best focus 
    bestPos = findBestFocus(positions, sharpnessValues);
    fprintf('\nFine best-focus position: %d steps\n\n', bestPos);

    % Plot the sharpness curve
    figure;
    plot(positions, sharpnessValues, 'b.-', 'MarkerSize', 10, 'LineWidth', 1.2);
    hold on;
    xline(bestPos, 'r--', 'LineWidth', 1.5, 'Label', sprintf('Best: %d', bestPos));
    xlabel('Stage position (steps)');
    ylabel('Tenengrad sharpness');
    title('Fine scan – sharpness vs. stage position');
    grid on;

end
