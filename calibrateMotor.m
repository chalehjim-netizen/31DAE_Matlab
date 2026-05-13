function calibrateMotor(StepMot)
    % calibrateMotor - Automatically finds the zero position using the limit switch.
    % It moves the motor backwards until it hits the physical end switch, 
    % then backs off slightly and sets that as Position 0.

    disp('--------------------------------------------------');
    disp('*** AUTOMATED CALIBRATION ***');
    disp('Moving motor to find the physical limit switch...');
    
    % Start moving infinitely in the backward direction (direction = 0)
    % at a speed of 1000 steps per second. (-1 means infinite steps)
    StepMot.startMoving(0, 1000, -1);
    
    % Wait in a loop until the limit switch is pressed
    while ~StepMot.endSwitchPushed()
        pause(0.1); % Check the switch every 0.1 seconds
    end
    
    % As soon as the switch is pushed, stop the motor!
    StepMot.stopMoving();
    disp('Limit switch reached!');
    
    % Set the internal tracker to exactly 0 at the limit switch
    StepMot.actualPos = 0; 
    
    % Move slightly forward to position 500 so the switch isn't constantly pressed.
    % We reuse our moveMotor function here to keep things clean!
    disp('Backing off the switch slightly to position 500...');
    moveMotor(StepMot, 500);
    
    disp('Calibration complete. Position is now 500.');
    disp('--------------------------------------------------');
end
