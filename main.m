clearvars -except PYNQ_obj StepMot; clc; close all;
disp('--- Starting Autofocus Pipeline ---');

% === 1. DEFINE PARAMETERS ===
% Camera Parameters
t_expo = 4000; % How long the camera takes to take a picture
gain = 0.1;

% Motor Parameters
motorFrequency = 4000; % Speed: steps per second (default is 1000)

% Scan Parameters
settlingTime = 0.2; % Wait time after moving the motor
coarseStep = 1000;  % Step size for the fast scan
fineStep = 100;     % Step size for the slow scan
fineRangeOffset = 1500; % How far to scan around the fast scan peak
range_scan = [0, 15000]; % The total allowed movement range

% === 2. INITIALIZATION ===
if ~exist('PYNQ_obj', 'var') || ~isvalid(PYNQ_obj) || ~exist('StepMot', 'var') || ~isvalid(StepMot)
    disp('Initializing Hardware...');
    [PYNQ_obj, StepMot] = initializePynqBoard();
else
    disp('Hardware already initialized.');
end


disp('--- Calibrating Motor ---')
calibrateMotor(StepMot);


disp('--- Initializing Camera ---')
[vid, src] = initializeCamera(t_expo, gain);

% === 3. COARSE SCAN ===
autofocusTimer = tic;
disp('Starting Coarse Scan...');
[coarsePos, coarseSharpness, coarseResults] = coarseScan(vid, StepMot, range_scan, coarseStep, settlingTime, motorFrequency);

disp('Analyzing Coarse Data...');
[bestCoarsePos, coarseFig] = findBestFocus(coarsePos, coarseSharpness, 'coarse_sharpness_vs_position');
fprintf('Coarse Peak found at step: %d\n', bestCoarsePos);

% === 4. FINE SCAN ===
disp('Starting Fine Scan...');
fineStart = max(0, bestCoarsePos - fineRangeOffset);
fineEnd = bestCoarsePos + fineRangeOffset;
fine_range_scan = [fineStart, fineEnd];

[finePos, fineSharpness, fineResults] = fineScan(vid, StepMot, fine_range_scan, fineStep, settlingTime, motorFrequency);

disp('Analyzing Fine Data...');
[bestFinePos, fineFig] = findBestFocus(finePos, fineSharpness, 'fine_sharpness_vs_position');
fprintf('Ultimate Best Focus found at step: %d\n', bestFinePos);

% === 5. FINAL POSITIONING ===
disp('Moving motor to final best focus...');
moveMotor(StepMot, bestFinePos, motorFrequency);
pause(settlingTime);

disp('Autofocus Complete');
autofocusTime = toc(autofocusTimer);
fprintf('Total Autofocus Search Time: %.2f seconds\n', autofocusTime);

% Capture and display final sharp frame
finalImg = captureFrame(vid);
finalFig = figure('Name', 'final_focused_image');
imshow(finalImg, []);
title('Final Autofocused Image');

% === 6. SAVE DATA ===
disp('Saving session data...');
figs = [coarseFig, fineFig, finalFig];
saveData(coarseResults, fineResults, bestCoarsePos, bestFinePos, figs);

% Clean up camera resources
delete(vid);
