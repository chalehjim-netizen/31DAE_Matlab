function moveMotor(motorObj, targetPos)
    % Move the motor to the target position
    
    currentPos = motorObj.actualPos;
    steps_to_move = targetPos - currentPos;
    
    if steps_to_move == 0
        return;
    end
    
    % Figure out the direction (1 is forward, 0 is backward)
    if steps_to_move > 0
        dir = 1;
    else
        dir = 0;
    end
    
    abs_steps = abs(steps_to_move);
    frequency = 1000; % Speed: steps per second
    
    motorObj.startMoving(dir, frequency, abs_steps);
    
    % Wait for the motor to finish moving
    moving_time = abs_steps / frequency;
    pause(moving_time); 
    
    % Update the current position tracker
    motorObj.actualPos = targetPos;
end