% Clear all variables (including an existing PYNQ_obj)
clearvars

% Make a PYNQ_obj object. This can only be done if no PYNQ_obj exists yet.
PYNQ_obj = PYNQ_LIB.PYNQ_ML;
% Write something to the display
PYNQ_obj.Display_ShowMessage(["Basics example","","Have fun!"]);
    
%% Set values
MEASUREMENT_TIME = 8;       % Measurement time in seconds
ABORT_BUTTON_1 = 1;          % Number of the button used to abort the measurement
PLOT_TIME = 1;               % Time between plotting in seconds
LED_NR = 1;                   % The LED to be used

%% The real program should start here.

disp("Starting");           % Message in the command window
tic;                        % Get the current time
tPrint = 1;                 % Used as counter for printing every second  
switchPressed = false;

PYNQ_obj.LED_switch(LED_NR,1);    % Switch on LED1 to indicate the start of the loop

% Run this loop for the duration of MEASUREMENT_TIME
while (toc<MEASUREMENT_TIME) && (switchPressed == false)
    if toc>tPrint                                                        % If-statement
        tPrint= toc + PLOT_TIME;                                         % Update the value of tPrint to reable the ability of MATLAB to enter this if-statement
        fprintf("Still %.1f seconds to go.\n", MEASUREMENT_TIME-toc);
        PYNQ_obj.Display_ShowMessage(sprintf("%.1f s to go.", MEASUREMENT_TIME-toc));
    end                                                                 % End of the if statement
    if PYNQ_obj.Button_read(ABORT_BUTTON_1)                              % Check if abort button is pressed
        switchPressed = true;                                           % If pressed the loop is ended and the measurement stopped
        disp("Abort button 1 pressed. Stopping measurement");
    end
end                                                                     % End of the while iteration
PYNQ_obj.LED_switch(LED_NR,0);       % Switch off LED1 to indicate the end of the loop


%% Finish up

PYNQ_obj.LEDs_switch([false, false, false, false]); % Switch off all four green LED's just to be sure
disp("Finished."); % Print on screen