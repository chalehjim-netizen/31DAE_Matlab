% motorTest.m
% Simple script to test if the PYNQ board and motor are working.

clearvars -except PYNQ_obj motor; clc;

if ~exist('PYNQ_obj', 'var')
    disp('Connecting to the PYNQ board...');
    PYNQ_obj = PYNQ_LIB.PYNQ_ML;
else
    disp('PYNQ board already connected.');
end

if ~exist('motor', 'var') || ~isvalid(motor)
    disp('Connecting to Stepper Motor...');
    motor = PYNQ_LIB.PYNQ_StepMot(PYNQ_obj);
end

disp('Hardware connected successfully!');

% Test moving the motor
% Direction: 1 (forward) or 0 (backward)
% Frequency: 1000 steps per second
% Steps: 5000
disp('Moving motor forward (direction 1) to avoid limit switches...');
motor.startMoving(1, 1000, 5000); 

disp('Monitoring steps left on the board...');
for i = 1:10
    pause(0.5);
    fprintf('Steps left: %d\n', motor.stepsLeft());
end

disp('Motor test complete.');