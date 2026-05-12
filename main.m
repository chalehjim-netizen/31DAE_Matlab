clearvars; clc; close all;
%=========================

% === SECTION 1 - DEFINE PARAMETERS ===
step_to_m = 1e-6;

stepsStart = 0;
stepsEnd = 15000;
range_scan = [stepsStart, stepsEnd];


t_expo = 4;
gain = 0.2;
coarseStep = 1000; % yards
fineStep = 100; % micrometers
t_pause = 2; % seconds



sharpness = computeSharpness(frame);







