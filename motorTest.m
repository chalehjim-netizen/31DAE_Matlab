% motorTest.m
% Simple script to test if the PYNQ board and motor are working.

clearvars; clc;

disp('Connecting to the PYNQ board...');
PYNQ_obj = PYNQ_LIB.PYNQ_ML;

disp('Connecting to Stepper Motor...');
motor = PYNQ_LIB.PYNQ_StepMot(PYNQ_obj);

disp('Hardware connected successfully!');

% Test moving the motor
% Direction: 1 (forward) or 0 (backward)
% Frequency: 1000 steps per second
% Steps: 50000
disp('Moving motor...');
motor.startMoving(0, 1000, 50000); 

disp('Motor test complete.');