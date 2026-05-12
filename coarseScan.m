function [positions, sharpnessValues] = coarseScan( ...
    vid, ...
    scanRange, ...
    coarseStep, ...
    settlingTime)

% Arrays to store results
positions = [];
sharpnessValues = [];

% Loop through all scan positions
for pos = scanRange[1]:coarseStep:scanRange[2]

    % Move motor to target position
    moveMotor(pos,scanRange,motorObj.actualPos);
 
    % Wait for stage vibrations to settle
    pause(settlingTime);

    % Acquire image
    img = captureFrame(vid);

    % Optional ROI cropping
    % img = img(300:700,300:700);

    % Compute sharpness metric
    sharpness = computeSharpness(img);

    % Store results
    positions(end+1) = pos;
    sharpnessValues(end+1) = sharpness;

    % Display progress in command window
    fprintf('Position: %d | Sharpness: %.2f\n', pos, sharpness);

end

end