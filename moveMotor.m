function moveMotor(targetPos,rangeScan, actualPos, motorObj)
% moveMotor  Move motor/stage to target position.
%   actualPos = moveMotor(targetPos) simulates a short move and returns
%   the target as the actual position. If a `motorObj` is provided, the
%   function will attempt to use it.
steps_to_move = actualPos - targetPos %number of steps the stepper motor has to move to reach ideal sharpness

% Direction the stepper motor has to follow according to the distance
if steps_to_move < 0
    dir = 1
end
if steps_to_move > 0
    dir = 0
end

% Moving the motor
for i = rangeScan[1]:rangeScan[2]:
    if i > 1
        motorObj.startMoving(dir, 1000, steps_to_move);
    end
end

actualPos = targetPos % Re-iteration of current position