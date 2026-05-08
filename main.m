clearvars; clc; close all;
%=========================

% === SECTION 1 - DEFINE PARAMETERS ===
step_to_m = 1e-6;

stepsStart = 0;
stepsEnd = 15000;


t_expo = 4;
gain = 0.2;
s_coarse_step = 1000; % yards
s_fine_step = 100; % micrometers
t_pause = 2; % seconds


range_scan = stepsStart : stepsEnd;





sharpness = computeSharpness(frame)





