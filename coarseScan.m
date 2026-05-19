function [positions, sharpnessValues, results] = coarseScan( ...
    vid, ...
    StepMot, ...
    scanRange, ...
    coarseStep, ...
    settlingTime)
    
    % Do a fast, rough scan across the whole range

    positions = [];
    sharpnessValues = [];

    for pos = scanRange(1):coarseStep:scanRange(2)
        moveMotor(StepMot, pos);
 
        % Wait for the stage to stop shaking
        pause(settlingTime);

        img = captureFrame(vid);
        sharpness = computeSharpness(img);

        positions(end+1) = pos;
        sharpnessValues(end+1) = sharpness;

        fprintf('Position: %d | Sharpness: %.2f\n', pos, sharpness);
    end

    % Package the data into a simple table for saving
    results = [positions(:), sharpnessValues(:)];
end