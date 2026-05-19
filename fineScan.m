function [positions, sharpnessValues, results] = fineScan(vid, StepMot, scanRange, fineStep, settlingTime)
    % Do a slow, detailed scan around the best coarse position
    
    positions = [];
    sharpnessValues = [];
    
    for pos = scanRange(1):fineStep:scanRange(2)
        moveMotor(StepMot, pos);
        pause(settlingTime); % Wait for the stage to stop shaking
    
        img = captureFrame(vid);
        sharpness = computeSharpness(img);
    
        positions(end+1) = pos;
        sharpnessValues(end+1) = sharpness;
    
        fprintf('Fine Scan - Position: %d | Sharpness: %.2f\n', pos, sharpness);
    end

    % Package the data into a simple table for saving
    results = [positions(:), sharpnessValues(:)];
end
