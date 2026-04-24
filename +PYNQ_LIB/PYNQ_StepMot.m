classdef PYNQ_StepMot < handle
    %PYNQ_StepMot 
    % Class which can start/stop moving moving a stepper motor and
    % read two end switches so that the motor cannot move too far and destroy
    % equipement


    % Set up default properties of the stepper motor:
    % The pulse frequencies are send through pin AR13
    % The direction of motor is send through pin AR12

    % Two switches are placed at each end, if the motor reaches one end the
    % switch will switch on and the motor will stop
    % Mainly safety precaution
    % Switch 1 output is send through pin AR11
    % Switch 2 output is send through pin AR10

    % PWM output is send through PWM channel 0
    properties (Constant, Access = private)
        defaultPulsePin = "RBPI07";
        defaultDirPin = "RBPI29";
        defaultEndSwitch1Pin = "RBPI27";
        defaultEndSwitch2Pin = "RBPI28";
        defaultPWMDevice = "PWM0";
    end

    % Frequency and DutyCycle are set by default
    properties (SetAccess = private)
        PulsePin;
        DirPin;
        EndSwitch1Pin;
        EndSwitch2Pin;
        PWMDevice;
        PYNQ_obj = "";
        Frequency {mustBeNumeric, mustBeNonnegative, mustBeScalarOrEmpty, mustBeLessThanOrEqual(Frequency,4500)} = 4500;
        DutyCycle {mustBeNumeric, mustBeNonnegative, mustBeScalarOrEmpty, mustBeLessThanOrEqual(DutyCycle,1)} = 0.1;
    end

    methods
        function obj = PYNQ_StepMot(PYNQ_obj,pulsepin,dirpin,EndSwitch1Pin,EndSwitch2Pin,PWMDevice)
            %PYNQ_StepMot Construct an instance of this class
            %   Makes a stepper motor object, to be used in combination
            %   with an PYNQ_ML object. The first argument is this PYNQ
            %   object, the other, optional arguments are the pins to be
            %   used for pulsing, direction, two endswitches and the PWM
            %   device. Each of these is a string variable.
          
            arguments
                PYNQ_obj PYNQ_LIB.PYNQ_ML
                pulsepin {mustBeText} = PYNQ_LIB.PYNQ_StepMot.defaultPulsePin;
                dirpin {mustBeText} = PYNQ_LIB.PYNQ_StepMot.defaultDirPin;
                EndSwitch1Pin {mustBeText} = PYNQ_LIB.PYNQ_StepMot.defaultEndSwitch1Pin;
                EndSwitch2Pin {mustBeText} = PYNQ_LIB.PYNQ_StepMot.defaultEndSwitch2Pin;
                PWMDevice {mustBeText} = PYNQ_LIB.PYNQ_StepMot.defaultPWMDevice;
            end

            obj.PYNQ_obj = PYNQ_obj;
            try
                obj.PYNQ_obj.ID;
            catch
                error('The supplied PYNQ object does not seem to be working correctly.')
            end

            obj.PulsePin = pulsepin;
            obj.DirPin = dirpin;
            obj.EndSwitch1Pin = EndSwitch1Pin;
            obj.EndSwitch2Pin = EndSwitch2Pin;
            obj.PWMDevice = PWMDevice;

            % All pins set will be connected on the PYNQ here, with its
            % channels
            obj.setPWM(0,0,0);
            obj.PYNQ_obj.SwitchBox_map(obj.PulsePin,obj.PWMDevice);
            obj.PYNQ_obj.SwitchBox_map(obj.DirPin,"GPIO");
            obj.PYNQ_obj.SwitchBox_map(obj.EndSwitch1Pin,"GPIO");
            obj.PYNQ_obj.SwitchBox_map(obj.EndSwitch2Pin,"GPIO");
            obj.PYNQ_obj.DigitalPin_set_Dir(obj.DirPin,"Out");
            obj.PYNQ_obj.DigitalPin_set_Dir(obj.EndSwitch1Pin,"In");
            obj.PYNQ_obj.DigitalPin_set_Dir(obj.EndSwitch2Pin,"In");
        end
        function delete(obj)
            % Destructor function to clear a PYNQ_ML object
            obj.setPWM(0,0);
        end
        function startMoving(obj,direction,frequency,steps)
            %startMoving This method starts movement of the stepper motor in the 
            % desired direction, step interval and optional number of 
            % steps to take where -1 indicates infinite steps.
            arguments
                obj PYNQ_LIB.PYNQ_StepMot
                direction {mustBeNumericOrLogical, mustBeScalarOrEmpty}
                frequency {mustBeNumeric, mustBeNonnegative, mustBeScalarOrEmpty} = 4500
                steps {mustBeNumeric} = -1
            end   

            % The movement is initiated with preffered function arguments
            obj.PYNQ_obj.DigitalPin_write(obj.DirPin,direction);
            obj.Frequency=frequency;
            obj.setPWM(obj.Frequency,obj.DutyCycle,steps);
        end
        function stopMoving(obj)
            %stopMoving This method stops the movement of the stepper motor.
            obj.setPWM(0,0,0);
        end
        function steps = stepsLeft(obj)
            steps = obj.PYNQ_obj.PWM_get_steps_left(obj.PWMDevice);
        end
        function [result,switch1,switch2] = endSwitchPushed(obj)
            %endSwitchPushed Checks whether one of the two end-switches is activated.
            % Returns a global result as
            % well as the results from the two individual switches.

            switch1 = ~obj.PYNQ_obj.DigitalPin_read(obj.EndSwitch1Pin);
            switch2 = ~obj.PYNQ_obj.DigitalPin_read(obj.EndSwitch2Pin);
            result = switch1 || switch2; % Gives a True statement if one of the two switches is switched on, else False
        end
    end
    methods (Access = private)
        function setPWM(obj,Frequency,Duty,Steps)
            % Function used to set the PWM 
            % Earlier in class used to move the motor
            arguments
                obj PYNQ_LIB.PYNQ_StepMot
                Frequency {mustBeNumeric,mustBeScalarOrEmpty}
                Duty {mustBeNumeric, mustBeNonnegative, mustBeScalarOrEmpty, mustBeLessThanOrEqual(Duty,1)} = 0.5
                Steps {isinteger} = -1
            end   

            if Frequency==0 % Motor will not move
                Period = 0;Duty=0;
            else
                % Calculating the period of the PWM signal
                Period = floor(1E8/Frequency);
            end
            % Sending the PWM over the desired pin
            obj.PYNQ_obj.PWM_set(obj.PWMDevice,Period,Duty,Steps)
        end
    end
end