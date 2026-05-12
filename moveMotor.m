function moveMotor(targetPos,rangeScan, actualPos, motorObj)
    % moveMotor  Move motor/stage to target position.
    % actualPos = moveMotor(targetPos) simulates a short move and returns the target as the actual position. 
    % If a `motorObj` is provided, the function will attempt to use it.
    steps_to_move = actualPos - targetPos %number of steps the stepper motor has to move to reach ideal sharpness

    % Direction the stepper motor has to follow according to the distance
    if steps_to_move < 0
        dir = 0
    end
    if steps_to_move > 0
        dir = 1
    end

    motorObj.startMoving(dir, 1000, steps_to_move);% Moving the motor


    actualPos = targetPos % Re-iteration of current position
end