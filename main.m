clearvars; clc; close all;
disp('--- Starting Autofocus Pipeline ---');

% === SECTION 1 - DEFINE PARAMETERS ===
% Camera Settings
t_expo = 4000; % Usually in microseconds for basler
gain = 0.2;

% Scan Settings
settlingTime = 0.2; % Time for stage vibrations to settle after moving
coarseStep = 1000;  % Steps to jump in coarse scan
fineStep = 100;     % Steps to jump in fine scan
fineRangeOffset = 1500; % Scan this many steps before and after the coarse peak

% Absolute Start and End points for the initial sweep
stepsStart = 0;
stepsEnd = 15000;
range_scan = [stepsStart, stepsEnd];


% === SECTION 2 - INITIALIZATION ===
disp('Initializing Hardware...');
[PYNQ_obj, StepMot] = initializePynqBoard();
StepMot.actualPos = 0; % Initialize the internal tracker to zero

[vid, src] = initializeCamera(t_expo, gain);


% === SECTION 3 - COARSE SCAN ===
disp('Starting Coarse Scan...');
[coarsePos, coarseSharpness] = coarseScan(vid, StepMot, range_scan, coarseStep, settlingTime);

% Find the peak of the coarse scan
disp('Analyzing Coarse Data...');
bestCoarsePos = findBestFocus(coarsePos, coarseSharpness);
fprintf('Coarse Peak found at step: %d\n', bestCoarsePos);

% === SECTION 2 - FIRST MEASUREMENTS ===

% === SECTION 4 - FINE SCAN ===
disp('Starting Fine Scan...');
% Define a narrow window around the coarse peak
fineStart = bestCoarsePos - fineRangeOffset;
fineEnd = bestCoarsePos + fineRangeOffset;

% Ensure we don't try to move below zero if the peak was very early
if fineStart < 0
    fineStart = 0;
end

fine_range_scan = [fineStart, fineEnd];

[finePos, fineSharpness] = fineScan(vid, StepMot, fine_range_scan, fineStep, settlingTime);

% Find the absolute best focus from the fine scan
disp('Analyzing Fine Data...');
bestFinePos = findBestFocus(finePos, fineSharpness);
fprintf('Ultimate Best Focus found at step: %d\n', bestFinePos);


% === SECTION 5 - FINAL POSITIONING ===
disp('Moving motor to final best focus...');
moveMotor(StepMot, bestFinePos);
pause(settlingTime);

disp('Autofocus Complete! Enjoy your sharp image.');

% Optional: Capture and display final sharp frame
finalImg = captureFrame(vid);
figure; 
imshow(finalImg, []); 
title('Final Autofocused Image');

% Clean up camera resources (do not clear PYNQ so you don't have to wait 45s next time)
delete(vid);
