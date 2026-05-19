% liveCameraPreview.m
% Run this script to open a live video feed from the camera.
% This is useful for manually adjusting the sample position or lighting 
% before running the automated autofocus script

clearvars; clc; close all;

% Camera Settings
t_expo = 4000; % Exposure time in microseconds
gain = 0.2;

disp('Connecting to camera for live preview...');

% Connect to the camera
vid = videoinput("gentl", 1, "Mono12"); 
src = getselectedsource(vid); 

% Apply camera settings
src.ExposureTime = t_expo;
src.Gain = gain;
src.BlackLevel = 0; 
src.Gamma = 1; 

% Open the live preview window
preview(vid);

disp('Live preview running. Close the figure window when you are done.');

