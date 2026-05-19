function calibrateMotor(StepMot)
    % Find the 0 position by hitting the physical switch
    
    disp('--------------------------------------------------');
    disp('*** AUTOMATED CALIBRATION ***');
    disp('Moving motor to find the physical limit switch...');
    
    % Start moving backward
    StepMot.startMoving(0, 1000, -1);
    
    % Wait until the switch is hit
    while ~StepMot.endSwitchPushed()
        pause(0.1);
    end
    
    StepMot.stopMoving();
    disp('Limit switch reached!');
    
    % Set this point as position 0
    StepMot.actualPos = 0; 
    
    % Move slightly forward so the switch isn't pressed
    disp('Backing off the switch slightly to position 500...');
    moveMotor(StepMot, 500);
    
    disp('Calibration complete. Position is now 500.');
    disp('--------------------------------------------------');
end
