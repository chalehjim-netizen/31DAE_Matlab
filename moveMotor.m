function moveMotor(motorObj, targetPos)
    % Moves the stepper motor to the specified position
    
    currentPos = motorObj.actualPos;
    steps_to_move = targetPos - currentPos;
    
    % If already at the target position, do nothing
    if steps_to_move == 0
        return;
    end
    
    % Determine direction: 1 for forward, 0 for backward
    if steps_to_move > 0
        dir = 1;
    else
        dir = 0;
    end
    
    % Motor command only takes positive numbers
    abs_steps = abs(steps_to_move);
    frequency = 1000; % Speed: steps per second
    
    % Tell the motor to start moving
    motorObj.startMoving(dir, frequency, abs_steps);
    
    % Wait for the physical motor to finish moving
    moving_time = abs_steps / frequency;
    pause(moving_time); 
    
    % Update our tracker
    motorObj.actualPos = targetPos;
end