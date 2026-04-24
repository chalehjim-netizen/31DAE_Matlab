classdef PYNQ_ML_DigiTwin < handle

    properties (Constant, Access=private)
        BGImageFilename = "Images\PYNQ-SIM-BG.jpg";
        UIWidth = 600;
        UIHeight = floor(600*649/874);
        VersionNr = 1;
        DateString = "May 2025";
        OffsetLEDNr = 10;
        OffsetRGBLEDNr= 14;
        OffsetButtonNr = 4;
        OffsetSwitchNr = 8;
    end

    properties (Constant)
        %% General
        % Define possible states for the LEDs and switches on the board
        STATES = ["LOW","HIGH"];
        % Define possible directions for GPIO pins
        DIRECTIONS = ["IN","OUT"];
        % The possible modules to use on the PYNQ board
        % The possible modules to use on the PYNQ board
        PYNQ_MODULES = ["GPIO", "UART0_TX", "UART0_RX", "SPICLK0", "MISO0", "MOSI0",...
            "SS0", "SPICLK1", "MISO1", "MOSI1", "SS1", "SDA0", "SCL0", "SDA1", "SCL1",...
            "PWM0", "PWM1","PWM2", "PWM3","PWM4", "PWM5",...
            "PULSECOUNTER0","PULSECOUNTER1",...
            "UART1_TX", "UART1_RX","IIC0_SDA","IIC0_SCL"];
        %% DIO stuff
        % All useable channels for digital operations:
        ALL_DIO_CHANNELS = ["AR2","AR3","AR4","AR5",...
            "BTN0","BTN1","BTN2","BTN3",...
            "SW0","SW1",...
            "LD0","LD1","LD2","LD3",...
            "LD4R","LD4G","LD4B","LD5R","LD5G","LD5B"];
        % Define the names of the LEDs on the board
        LED_CHANNELS = ["LD0","LD1","LD2","LD3"];
        % Define the names of the LEDs on the board
        RGB_LED_CHANNELS = ["LD4R","LD4G","LD4B","LD5R","LD5G","LD5B"];
        % Define the names of the switches on the board
        SWITCH_CHANNELS = ["SW0","SW1"];
        % Define the names of the buttons on the board
        BUTTON_CHANNELS = ["BTN0","BTN1","BTN2","BTN3"];
        % Define the names of the PWM channels on the board
        PWM_NAMES = ["PWM0","PWM1","PWM2","PWM3","PWM4","PWM5"];
        % Define the names for the general purpose DIO BNC connectors on
        % the shield:
        DIO_PINS = ["AR2","AR3","AR4","AR5"];
        % Define counter edges
        COUNTER_EDGES = ["RISING","FALLING","BOTH"];
        % Define the names and pins to be used by standard IO functions
        % (e.g. Counter, Interval timer,...)
        STANDARD_CHANNEL_NAMES = ["BNC DI0","BNC DI1","BNC DI2","BNC DI3","Button 1", "Button 2","LED 1"];
        STANDARD_CHANNEL_PINS = ["AR2","AR3","AR4","AR5","BTN0", "BTN1", "LD0"];
        % The maximum number of interval timings that the PYNQ board can
        % store.
        MAX_INTERVAL_TIMINGS = 2000;
        %% Internal ADC
        % Define the names of the ADC channels on the board
        ADC_PYNQ_CHANNELS = ["A0","A1","A2","A3","A4","A5",];
        %% External ADC
        % Define the names of the channels of the ADS1115
        ADC_EXT_CHANNELS = ["A0TA1","A0TA3","A1TA3","A2TA3","A0TG","A1TG","A2TG","A3TG",];
        ADC_EXT_CHANNEL_NAMES = ["A0 to A1","A0 to A3","A1 to A3","A2 to A3","A0 to ground","A1 to ground","A2 to ground","A3 to ground",];
        % Define the voltage level ranges and sampling rates of the ADS1115
        ADC_EXT_RANGES = ["V6P144","V4P096","V2P048","V1P024","V0P512","V0P256"];
        ADC_EXT_RANGE_VALUES = [6.144,4.096,2.048,1.024,0.512,0.256];
        ADC_EXT_RANGE_NAMES = ["±6.144V","±4.096V","±2.048V","±1.024V","±0.512V","±0.256V"];
        ADC_EXT_RATES = ["SPS8","SPS16","SPS32","SPS64","SPS128","SPS250","SPS475","SPS860"];
        ADC_EXT_WAIT_TIMES = [0.15, 0.08, 0.04, 0.02, 0.01, 0.005, 0.003, 0.0015]; % How long, per data rate setting should be waited before a measurement can be performed.
        ADC_EXT_OUT_OF_RANGE = [-Inf,Inf]; % These values are returned by the PYNQ board when the voltage was out of range
        ADC_EXT_VOLTAGE_WARNING_LIMIT = 0.01; % The voltage difference with the range voltage which will result in an out-of-range warning.
        MAX_ADC_SAMPLES = 10000;
        %% DAC
        % Define the names of the pins used as DAC channels on the shield:
        DAC_CHANNELS = ["AR0","AR1"];
        % Define PWM channels used for the DAC channels
        DAC_PWMs= ["PWM0","PWM1"];
        % Set the number of clock-ticks (of 100MHz) to be used for DAC
        % duty-cycle setting
        DAC_Clockticks = [1000 1000];
        % Define the DAC maximum voltage
        DAC_Max_V = 3.3;

    end

    properties %(Access=private)

        Active = false;
        SupportObject;
        TimerObj;
        % User interface elements
        UIFig
        LEDs
        RGBLEDs
        Switches
        Buttons
        Display
        DisplayAxes
        
        % ADC DAC stuff
        DAC_Initialized = [false, false];
        ADS1115_Initialized = false;
        ADS1115_Channels_Added = false;
        ADS1115_Fast_Started = false;
    end
        
    methods
        %% Creator and destructor methods
        function obj = PYNQ_ML_DigiTwin()
            obj.SupportObject=PYNQ_LIB.PYNQ_ML_DigiTwin_Support;
            obj.createPYNQ_DigiTwin_UI();
            disp("'Connected' to PYNQ Digital Twin UI.")
            obj.LEDs_flash;
            obj.Active = true;
        end
        function delete(obj)
            % Destructor function to clear a PYNQ_ML object
            disp("Closing PYNQ Digital Twin UI.")
            obj.Active = false;
            if ~isempty(obj.UIFig) && isvalid(obj.UIFig)
                delete(obj.UIFig);
            end
        end
             
        %% General methods
        function [response, version] = ID(obj)
            % Reads the ID of the connected SCPI object
            response = "PYNQ_ML_DigiTwin v"+sprintf("%0.1f",obj.VersionNr);
            version = obj.VersionNr;
        end
        function response = isConnected(~)
            % Tests if device is responding properly.
            response = true;
        end
        function reset(~)
            % Reset GPIO and switchbox
            warning("The reset method is not (yet) implemented in PYNQ_ML_DigiTwin")
        end
        function initializeLEDButtons(~)
            % Not needed in sim
        end
        function System_Set_time(~,~,~)
            % Not needed in sim
        end
        function System_Shutdown(~,~)
            % Not needed in sim
        end
        
        %% Mapping methods
        function SwitchBox_map(obj,pin,module)
            % Maps a certain pin of the the PYNQ-board to a module. 
            % Inputs are the pin (a string, e.g. "AR2") and the module 
            % (e.g. "GPIO" or "PWM0")
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin %#ok<INUSA>
                pin {mustBeTextScalar} %#ok<INUSA>
                module {mustBeNumberOrStr} %#ok<INUSA>
            end
            warning("The mapping method is not (yet) implemented in PYNQ_ML_DigiTwin, but also not really needed.")
        end
        function state = SwitchBox_getMapping(obj,pin)
            %getMapping Reads mapping from a pin
            % Input is a string for the pin (e.g. "AR2")
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin %#ok<INUSA>
                pin {mustBeTextScalar} %#ok<INUSA>
            end
            warning("The mapping method is not (yet) implemented in PYNQ_ML_DigiTwin.")
            state= true;
        end
        
        %% Basic GPIO methods
        function DigitalPin_set_Dir(obj,pin,dir)
            %setDigitalPinDir Writes direction (input/output) to a digital pin
            % Inputs are the pin (a string, e.g. "AR2") and 
            % the direction "IN" or "OUT".
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin
                pin {mustBeTextScalar}
                dir {mustBeTextScalar}
            end
            dirstring = obj.replaceNumeric(dir,obj.DIRECTIONS);
            pinnr = find(strcmp(obj.DIO_PINS,pin));
            if isempty(pinnr)
                warning("Pin " + pin + " does not exist or direction cannot be set in PYNQ_ML_DigiTwin.");
            else
                obj.SupportObject.PinDirs(pinnr)=dirstring;
            end
        end
        function state = DigitalPin_get_Dir(obj,pin)
            %ReadDigitalPin Reads current direction setting from a digital pin
            % Input is the pin (a string, e.g. "AR2") and 
            % output the direction of the pin ("INPUT"/"OUTPUT")
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin
                pin {mustBeTextScalar}
            end
            pinnr = find(strcmp(obj.ALL_DIO_CHANNELS,pin));
            if isempty(pinnr)
                warning("Pin " + pin + " does not exist or direction cannot be used in PYNQ_ML_DigiTwin.");
            else
                state = obj.SupportObject.PinDirs(pinnr);
            end
        end
        function DigitalPin_write(obj,pin,state,doWrite)
            % WriteDigitalPin Writes state to a digital pin
            % Inputs are the pin (a string, e.g. "AR2"),
            % the state (true/false) and, optionally doWrite.
            % If doWrite is false then the command will not be sent to the
            % PYNQ-board yet, but only given as output.
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin
                pin {mustBeTextScalar}
                state {mustBeState} = false
                doWrite {mustBeNumericOrLogical} = true %#ok<INUSA>
            end
            pinnr = find(strcmp(obj.ALL_DIO_CHANNELS,pin));
            if isempty(pinnr)
                warning("Pin " + pin + " does not exist or cannot be used to write to in PYNQ_ML_DigiTwin.");
            elseif strcmp(obj.SupportObject.PinDirs(pinnr),"IN")
                warning("Pin " + pin + " is set for input. Set to output before trying to write.");
            else
                obj.SupportObject.PinStates(pinnr)=obj.toStateBool(state);
                if pinnr<=obj.OffsetButtonNr
                    obj.SupportObject.ApplyDIOCables;
                elseif pinnr>obj.OffsetLEDNr
                    obj.setLEDs;
                end
            end
        end
        function state = DigitalPin_read(obj,pin)
            %ReadDigitalPin Reads state from a digital pin
            % Input is the pin (a string, e.g. "AR2") and 
            % output the state (true/false)
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin
                pin {mustBeTextScalar}
            end
            state = [];
            pinnr = find(strcmp(obj.ALL_DIO_CHANNELS,pin));
            if isempty(pinnr)
                warning("Pin " + pin + " does not exist or cannot be used to read in PYNQ_ML_DigiTwin.");
            else
                stateString=obj.SupportObject.PinStates(pinnr);
                state = strcmpi(stateString,"HIGH");
            end
        end

        %% PYNQ ADC methods
        function voltage = ADC_PYNQ_read(obj,channel,LEDflash)
            %ADC_PYNQ_read Read voltage over PYNQ internal ADC channel #1 to #6. 
            % Input is the channel number (1-6) for A0 - A5
            % Optionally briefly flashes an LED during the operation if LEDflash > 0
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin %#ok<INUSA>
                channel {mustBeInteger, mustBeInRange(channel,1,6)} = 1 %#ok<INUSA>
                LEDflash {mustBeNumberOrStr} = 0 %#ok<INUSA>
            end
            warning("The internal ADC method is not implemented in PYNQ_ML_DigiTwin, please use the external ADC.")
            voltage = 0;
        end

        %% ADS1115 ADC methods   
        function ADC_Ext_initialize(obj, samplewait)
            % Initializes the ADS1115 board and maps switchbox.
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin
                samplewait {mustBeNumberOrStr} = 5 %#ok<INUSA>
            end
            if ~obj.ADS1115_Initialized 
                disp("Initializing ADS1115 on the PYNQ board.");
                obj.ADS1115_Initialized = true;
                obj.ADS1115_Channels_Added = false;
                obj.ADS1115_Fast_Started = false;
                obj.SupportObject.ADC_Fast_Channels = [];
                obj.SupportObject.ADC_Fast_Ranges = [];
                obj.ADC_Ext_set(5,1,1);
            end
        end

        function settingsChanged = ADC_Ext_set(obj,channel,range,rate) %#ok<STOUT>
            %ADC_Ext_set Sets channel, range and data rate of the ADS1115 board
            % channel is an integer number between 1 and 8, or a string from ADC_EXT_CHANNELS
            % range is an integer number between 1 and 6, or a string from ADC_EXT_RANGES
            % rate is an integer number between 1 and 8, or a string from ADC_EXT_RATES
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin
                channel {mustBeNumberOrStr} = 0
                range {mustBeNumberOrStr} = 0
                rate {mustBeNumberOrStr} = 0
            end
            obj.ADC_Ext_initialize

            if isStringScalar(channel) || channel~= 0
                % Sets the ADS1115 channel
                obj.SupportObject.ADC_Ext_currentChannel = obj.replaceString(channel,obj.ADC_EXT_CHANNELS);
            end
            if isStringScalar(range) || range~= 0
                % Sets the ADS1115 voltage range
                obj.SupportObject.ADC_Ext_currentRange = obj.replaceString(range,obj.ADC_EXT_RANGES);
            end
            if isStringScalar(rate) || rate~= 0
                % Sets the ADS1115 data rate
                obj.SupportObject.ADC_Ext_currentRate = obj.replaceString(rate,obj.ADC_EXT_RATES);
            end
        end

        function [voltage, inrange] = ADC_Ext_read(obj,channel,range,rate,LEDflash)
            % Reads a voltage from the ADS1115 board. channel, range and
            % rate are optional parameters. If one of them is defined, a
            % pause is added to allow time for the ADS1115 to acquire a new
            % voltage.
            % Optionally briefly flashes an LED during the operation if LEDflash > 0
            % For definitions of channel, range and rate see setADC_Ext
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin
                channel {mustBeNumberOrStr} = 0
                range {mustBeNumberOrStr} = 0
                rate {mustBeNumberOrStr} = 0
                LEDflash {mustBeNumberOrStr} = 0 %#ok<INUSA>
            end       
            obj.ADC_Ext_set(channel,range,rate);
            
            % Read the voltage
            
            voltage = obj.SupportObject.readADC; % Outputs voltage as double
            inrange = obj.ADC_Ext_Check_Inrange(voltage,false);
            if ~inrange
                warning("ADS1115 input voltage out of measurement range.")
            end
        end
        function voltage = ADC_Ext_AllowedVoltage(obj,range)
            % Gives back the maximum allowed voltage for a measurement
            % using the ADS1115 before triggering an out-of-range warning.
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin
                range {mustBeNumberOrStr}
            end
            rangestring = obj.replaceNumeric(range,obj.ADC_EXT_RANGES);
            rangenumber = find(strcmp(obj.ADC_EXT_RANGES,rangestring));
            voltage = obj.ADC_EXT_RANGE_VALUES(rangenumber)-obj.ADC_EXT_VOLTAGE_WARNING_LIMIT;
        end
        function ADC_Ext_Fast_Add_Channel(obj,channel,range)
            %ADC_Ext_Fast_Add_Channel Adds a channel to the list of ADS1115 channels for measuring fast
            % channel is an integer number between 1 and 8, or a string from ADC_EXT_CHANNELS
            % range is an integer number between 1 and 6, or a string from ADC_EXT_RANGES
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin
                channel {mustBeNumberOrStr}
                range {mustBeNumberOrStr} = 1
            end
            obj.ADC_Ext_initialize
            if obj.ADS1115_Fast_Started
                warning("Trying to add a channel while measurement is running."+newline+...
                    "Measurement has been stopped automatically. Please start again if required.")
                obj.ADC_Ext_Fast_Stop;
            end

            % Sets the ADS1115 channel and range
            channelnr = obj.replaceString(channel,obj.ADC_EXT_CHANNELS);
            rangenr = obj.replaceString(range,obj.ADC_EXT_RANGES);
            obj.SupportObject.ADC_Fast_Channels(end+1)=channelnr;
            obj.SupportObject.ADC_Fast_Ranges(end+1)=rangenr;
            obj.ADS1115_Channels_Added = true;
        end
        function inrange = ADC_Ext_Check_Inrange(obj,Voltages,fast) %#ok<INUSD>
            %ADC_Ext_Check_Inrange Checks if a set of voltages is all in the allowed range.
            % Working depends on the PYNQ board firmware version.
            inrange = ~(any(Voltages==obj.ADC_EXT_OUT_OF_RANGE(1)) ||...
                    any(Voltages==obj.ADC_EXT_OUT_OF_RANGE(2)));
        end
        function ADC_Ext_Fast_Start(obj,delay)
            %ADC_Ext_Fast_Start Starts the fast acquisition of data from the ADS1115
            % Input is the delay between two acquisitions in microseconds
            % (default at 10000).
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin
                delay {mustBeNumeric,mustBeScalarOrEmpty} = 10000
            end
            if ~obj.ADS1115_Channels_Added
                error("No channels added yet to fast ADS1115 acquisition."+newline+...
                    "Please use ADC_Ext_Fast_Add_Channel to add channels first.")
            elseif obj.ADS1115_Fast_Started
                warning("Measurement is already running. It will be stopped first before restarting.")
                obj.ADC_Ext_Fast_Stop;
            end

            % Sets the ADS1115 channel
            obj.SupportObject.FastADC_start(delay);
            obj.ADS1115_Fast_Started = true;
        end

        function [voltagetable,inrange] = ADC_Ext_Fast_Get_Points(obj)
            %ADC_Ext_Fast_Get_Points Reads the latest samples from the fast ADS1115 ADC thread.
            % Requires channels to be added and start to have been done.
            % This command returns a table array of the new values obtained since
            % the start or since the last use of ADC_Ext_Fast_Get_Points
            % (whichever comes last).
            % A maximum of 10000 samples can be stored on the PYNQ board.
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin
            end
            if obj.ADS1115_Fast_Started
                voltagetable = obj.SupportObject.FastADC_read;

                if ~isempty(voltagetable)
                    voltagetable.Channels=obj.ADC_EXT_CHANNELS(voltagetable.Channels)';

                    % Check if all voltages are in range and give a warning and
                    % a false inrange output if not.
                    inrange = obj.ADC_Ext_Check_Inrange(voltagetable.Voltages,true);
                    if ~inrange
                        warning("ADS1115 input voltage(s) out of measurement range.")
                    end
                    voltagetable.Properties.VariableUnits=["s","","V"];
                end
            else
                error("Trying to acquire points while fast measurement has not been started yet."+newline+...
                    "Please use ADC_Ext_Fast_Start to start acquisition first.")
            end
        end
        function voltagetable = ADC_Ext_Fast_Stop(obj)
            %ADC_Ext_Fast_Stop Stops the fast ADS1115 data acquisition. 
            % The last remaining data points are given as output.
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin
            end
            voltagetable = obj.ADC_Ext_Fast_Get_Points;
            obj.ADS1115_Fast_Started = false;
        end
        function ADC_Ext_Fast_ClearChannels(obj)
            %ADC_Ext_Fast_ClearChannels Clears the data acquisition
            %channels of the ADS1115
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin
            end
            if obj.ADS1115_Fast_Started
                warning("Fast measurement still running. Stopping first before clearing channels.");
                obj.ADC_Ext_Fast_Stop;
            end
            obj.SupportObject.ADC_Fast_Channels = [];
            obj.SupportObject.ADC_Fast_Ranges = [];
            obj.ADS1115_Channels_Added = false;
        end
        %% DAC methods
        function DAC_initialize(obj,channel)
            %DAC_initialize Initializes DAC number one or two on the
            %breakout board.
            % channel is 1 or 2 and corresponds with connector DAC0 or DAC1
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin
                channel {mustBeNumberOrStr} = 1
            end
            obj.DAC_Initialized(channel)=true;
        end
        function DAC_set(obj,channel,duty)
            %DAC_set Sets the output of the DAC channel to a value using a 
            % duty cycle (number between 0 and 1).
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin
                channel {mustBeInteger, mustBeInRange(channel,1,2)} = 1
                duty {mustBeNumeric, mustBeInRange(duty,0,1)} = 0.5
            end
            if ~obj.DAC_Initialized(channel)
                obj.DAC_initialize(channel);
            end
            voltage = obj.DAC_Max_V*duty;
            obj.DAC_setV(voltage);
        end
        function DAC_setV(obj,channel,voltage)
            %DAC_setV Sets the output of the DAC channel to a value using a
            %voltage. Use a voltage between 0 and 3.3 V.
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin
                channel {mustBeInteger, mustBeInRange(channel,1,2)} = 1
                voltage {mustBeNumeric, mustBeInRange(voltage,0,3.3)} = 1
            end
            obj.SupportObject.DAC_CurrentVoltages(channel)=voltage;
        end
        %% PulseCounter methods
        function PulseCounter_enable(obj,nr,pin,edge)
            %PulseCounter_enable Enables the fast pulse counter on a pin
            %nr is which of the two pulse counters is started (1 or 2)
            %pin is a digital pin (e.g. "AR2")
            %edge determines which edge of a signal to count on (1 = rising, 2 = falling).
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin %#ok<INUSA>
                nr (1,1) {mustBeInteger, mustBeInRange(nr,1,2)} %#ok<INUSA>
                pin {mustBeTextScalar} %#ok<INUSA>
                edge (1,1) {mustBeInteger, mustBeInRange(edge,1,2)} = 1; %#ok<INUSA>
            end
            warning("The pulse counter is not (yet) implemented in PYNQ_ML_DigiTwin.")
        end
        function PulseCounter_reset(obj,nr)
            %PulseCounter_reset Resets one of the fast pulse counters.
            %nr should be 1 or 2
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin %#ok<INUSA>
                nr (1,1) {mustBeInteger, mustBeInRange(nr,1,2)} %#ok<INUSA>
            end
            warning("The pulse counter is not (yet) implemented in PYNQ_ML_DigiTwin.")
        end
        function [counts,time] = PulseCounter_read(obj,nr) %#ok<STOUT>
            %PulseCounter_read Reads pulse counter state from a digital pin
            %nr should be 1 or 2
            %Outputs the number of counts and the time elapsed since last reset as doubles.
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin %#ok<INUSA>
                nr (1,1) {mustBeInteger, mustBeInRange(nr,1,2)} %#ok<INUSA>
            end
            warning("The pulse counter is not (yet) implemented in PYNQ_ML_DigiTwin.")
        end
        %% Interval timer methods
        function IntervalTimer_enable(obj,pin,edge)
            %IntervalTimer_enable Enables the interval timer on a pin
            %pin: a string for the pin to use (e.g. "AR2")
            %edge determines which edge of a signal to count on ("RISING","FALLING" or "BOTH")..
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin %#ok<INUSA>
                pin {mustBeTextScalar} %#ok<INUSA>
                edge {mustBeNumberOrStr} = 1 %#ok<INUSA>
            end
            % First enable a counter
            warning("The interval timer is not (yet) implemented in PYNQ_ML_DigiTwin.")
        end
        function IntervalTimer_disable(obj,pin) %#ok<INUSD>
            %IntervalTimer_disable Disables the interval timer on a pin (e.g. "AR2")
            warning("The interval timer is not (yet) implemented in PYNQ_ML_DigiTwin.")
        end
        function IntervalTimer_start(obj,pin)
            %IntervalTimer_start Starts the interval timer on the indicated pin. 
            % The interval timer first needs to have been enabled on this pin.
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin %#ok<INUSA>
                pin {mustBeTextScalar} %#ok<INUSA>
            end
            warning("The interval timer is not (yet) implemented in PYNQ_ML_DigiTwin.")
        end
        function IntervalTimer_reset(obj,pin)
            %IntervalTimer_reset Resets interval timer on a pin
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin %#ok<INUSA>
                pin {mustBeTextScalar} %#ok<INUSA>
            end
            warning("The interval timer is not (yet) implemented in PYNQ_ML_DigiTwin.")
        end
        function timings = IntervalTimer_read(obj,pin) %#ok<STOUT>
            %IntervalTimer_read Reads interval timer state from a digital pin. The interval
            % timer needs to be enabled and started first. Then this
            % command returns an array of the new intervals obtained since
            % the start, a reset or since the last use of IntervalTimer_read
            % (whichever comes last).
            % A maximum of 2000 intervals can be stored on the PYNQ board.
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin %#ok<INUSA>
                pin {mustBeTextScalar} %#ok<INUSA>
            end
            warning("The interval timer is not (yet) implemented in PYNQ_ML_DigiTwin.")
        end

        %% PWM methods
        function PWM_set(obj,PWM,period,duty,steps)
            %PWM_set Sets one of the PWM modules using the following settings:
            % period: integer number indicating how many clock cycles of 
            %   a 100 MHz clock. So 100 equals a period of 1 microsecond.
            % duty: sets the duty cycle. This can either be a fraction
            %   between 0 and 1 or a number of clock cycles.
            % steps: the number of steps for which to perform the PWM. If
            %   omitted or set at -1, the PWM will run indefinetely.
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin %#ok<INUSA>
                PWM {mustBeNumberOrStr} %#ok<INUSA>
                period {mustBeInteger,mustBeScalarOrEmpty} %#ok<INUSA>
                duty {mustBeNumeric, mustBeNonnegative, mustBeScalarOrEmpty, mustBeLessThanOrEqual(duty,1)} = 0.5 %#ok<INUSA>
                steps {mustBeInteger,mustBeScalarOrEmpty} = -1 %#ok<INUSA>
            end               
            warning("The PWM functionality is not (yet) implemented in PYNQ_ML_DigiTwin.")
        end
        function steps = PWM_get_steps_left(obj,PWM)
            %PWM_get_steps_left Reads how many steps are left on a PWM
            %module. Returns 4294967295 when the PWM is running
            %indefinetely.
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin %#ok<INUSA>
                PWM {mustBeNumberOrStr} %#ok<INUSA>
            end    
            warning("The PWM functionality is not (yet) implemented in PYNQ_ML_DigiTwin.")
            steps=0;
        end

        %% LEDs, switches and button methods
        function status = Button_read(obj,Button)
            %Button_read Reads a button (1-4 or "BTN0"-"BTN3") on the PCB
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin
                Button {mustBeNumberOrStr}
            end
            if isnumeric(Button) && Button==0
                status = false;
            else 
                status = obj.SupportObject.PinStates(obj.OffsetButtonNr + obj.replaceString(Button, obj.BUTTON_CHANNELS));
            end
        end
        function States = Buttons_read(obj)
            %Buttons_read Read the states of all buttons on the PYNQ PCB.
            % Returns a States array of four logicals (e.g. [1,0,0,0]).
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin
            end
            States = [obj.Button_read(1) obj.Button_read(2) obj.Button_read(3) obj.Button_read(4)];
        end
        function status = Switch_read(obj,Switch)
            %Switch_read Read state of a switch  (1-2 or "SW0"-"SW1") on the PCB.
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin
                Switch {mustBeNumberOrStr}
            end
            status = obj.SupportObject.PinStates(obj.OffsetSwitchNr + obj.replaceString(Switch, obj.SWITCH_CHANNELS));
        end
        function LED_switch(obj,LEDNumber,state, dummy)
            %LED_switch Switches on/off a desired LED, with number between 1 and 4
            % If doWrite is false then the command will not be sent to the
            % PYNQ-board yet, but only given as output.
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin
                LEDNumber {mustBeNumberOrStr}
                state {mustBeState} = false
                dummy = false %#ok<INUSA>
            end
            if LEDNumber>0
                obj.SupportObject.PinStates(LEDNumber+obj.OffsetLEDNr) = obj.toStateBool(state);
                obj.setLEDs;
            end
        end
        function LEDs_switch(obj,States)
            %LEDs_switch Write state of all LED on the PYNQ PCB. Uses a States array
            % of four logicals as input. E.g. [0,1,0,1]
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin
                States (1,4) logical
            end
            for i=1:4
                obj.LED_switch(i,States(i));
            end
        end
        function LED_Flash(obj,LEDflash)
            %LED_add_Flash Adds LED flashing commands to a command string when
            % LEDflash>0
           arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin 
                LEDflash {mustBeNumberOrStr} = 0
           end
            if LEDflash~=0
                obj.LED_switch(LEDflash,true);
                pause(0.2);
                obj.LED_switch(LEDflash,false);
            end            
        end
        % Flashing wave LED sequence
        function LEDs_flash(obj)
            %LEDs_flash Flash LED's on the PCB board. Is now used
            % after initialisation.
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin
            end
            for i=1:4
                obj.LED_switch(i,true);
                pause(0.05)
            end
            for i=1:4
                obj.LED_switch(i,false);
                pause(0.05)
            end
        end
        function RGBLED_set(obj,LedNr,RGB)
            %RGBLED_set Sets an RGB LED using the LED number (1 or 2) and a
            % three-row logical array to switch the R, G and B colours on
            % or off. E.g. [1,1,0] for yellow.
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin
                LedNr {mustBeScalarOrEmpty,mustBeInteger,mustBeInRange(LedNr,1,2)} = 1
                RGB (1,3) logical = [1,1,1];
            end
            startPos = obj.OffsetRGBLEDNr+1+(LedNr-1)*3;
            obj.SupportObject.PinStates(startPos:startPos+2)=RGB;
            obj.setLEDs;
        end
        function LEDs_switchoff(obj)
            % Switches off all LED's, including the RGB LED's
            obj.LEDs_switch([0, 0, 0, 0]);
            obj.RGBLED_set(1,[0, 0, 0]);
            obj.RGBLED_set(2,[0, 0, 0]);
        end
        %% Audio in/out methods
        function response = FrequencyResponse_get(obj,freq,nperiods,volume,usestartup)
            %getFrequencyResponse Reads the frequency response on the
            % audio-ports. Inputs are frequency (in Hz) and number of periods.
            % Output is an array with 2 columns, one for each of the two
            % channels.
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin
                freq {mustBeNumeric, mustBeScalarOrEmpty, mustBeInRange(freq,1,10000)} = 1000
                nperiods {mustBeInteger, mustBeScalarOrEmpty} = 5
                volume {mustBeInteger, mustBeScalarOrEmpty, mustBeNonnegative, mustBeLessThanOrEqual(volume,100)} = 100
                usestartup {mustBeNumericOrLogical, mustBeScalarOrEmpty} = true %#ok<INUSA>
            end
            if nperiods/freq>10
                error("Please give a combination of frequency and number of periods that takes less than 10s to acquire.");
            end
            response = obj.SupportObject.audioResponse(freq,nperiods,volume);
        end
        %% Display methods
        function Display_ShowMessage(obj,message)
            %Display_ShowMessage Shows a message on the LCD-display.
            %message should be a string array, of which each element
            %will be displayed on a separate line. Note that there is
            %a maximum of six lines and twenty characters (including) spaces
            %per line. Excessive lines or characters will be ignored.
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin
                message {mustBeText} = "" % A string or char variable containing the message to be shown
            end
            message = strrep(message,"~",newline);
            newmessage = "";
            % Split lines including a newline character.
            for i=1:numel(message)
                splitmessage = strsplit(message(i),newline);
                newmessage = [newmessage, splitmessage]; %#ok<AGROW>
            end
            message = newmessage;
            newmessage = "";
            % Split long lines
            for i=1:numel(message)
                splitmessage = regexp(message(i),".{1,20}", "match");
                newmessage = [newmessage, splitmessage]; %#ok<AGROW>
            end
            newmessage = newmessage(2:end);
            if numel(message)>7
                newmessage = newmessage(1:7);
            end
            rectangle(obj.Display,"FaceColor",[1 1 1],"EdgeColor","none", ...
                 "Position",[0 0.26 1 0.74]);
            text(obj.Display, 0.05, 0.95, newmessage, ...
                'Color', 'black', ...
                'FontSize', 7, ...
                'FontName', 'Courier New', ...
                'HorizontalAlignment', 'left', ...
                'VerticalAlignment', 'top', ...
                'Interpreter','none');
            drawnow;
        end
      
    end
    %% Some private methods.
    methods (Access=private)
        function createPYNQ_DigiTwin_UI(obj)
            % Create the figure
            obj.UIFig = uifigure('Name', 'PYNQ Digital Twin', 'NumberTitle', 'off', ...
                'MenuBar', 'none', ...
                'ToolBar', 'none', ...
                'Position', [700, 100, obj.UIWidth, obj.UIHeight], ...
                'Units','Normalize',...
                'Resize', 'off' );
            obj.UIFig.CloseRequestFcn = @(src, event) delete(obj);

            bgaxes= uiaxes(obj.UIFig, ...
                'Position', [0 0 obj.UIWidth obj.UIHeight], ...
                'XTick', [ ], 'YTick', []);

            % Add background image
            bgImage=imread(obj.BGImageFilename);
            hIm = imshow(bgImage, 'Parent',bgaxes,'Border','tight', ...
                'XData', [1 bgaxes.Position(3)], ...
                'YData', [1 bgaxes.Position(4)]);
            bgaxes.XLim = [0 hIm.XData(2)];
            bgaxes.YLim = [0 hIm.YData(2)];
            disableDefaultInteractivity(bgaxes);   
            bgaxes.Interactions = [];              
            bgaxes.Toolbar.Visible = 'off';

  

            % Create LEDs
            obj.LEDs{4} = uicontrol(obj.UIFig,'Style', 'text', 'Position', obj.abspos([455,545,20,12]), 'BackgroundColor', 'black');
            obj.LEDs{3} = uicontrol(obj.UIFig,'Style', 'text', 'Position', obj.abspos([500,545,20,12]), 'BackgroundColor', 'black');
            obj.LEDs{2} = uicontrol(obj.UIFig,'Style', 'text', 'Position', obj.abspos([545,545,20,12]), 'BackgroundColor', 'black');
            obj.LEDs{1} = uicontrol(obj.UIFig,'Style', 'text', 'Position', obj.abspos([590,545,20,12]), 'BackgroundColor', 'black');

            obj.RGBLEDs{2} = uicontrol(obj.UIFig,'Style', 'text', 'Position', obj.abspos([198,515,20,12]), 'BackgroundColor', 'black');
            obj.RGBLEDs{1} = uicontrol(obj.UIFig,'Style', 'text', 'Position', obj.abspos([230,515,20,12]), 'BackgroundColor', 'black');

            % Create buttons
            obj.Buttons{4} = uicontrol(obj.UIFig,'Style', 'togglebutton', 'Position', obj.abspos([455,565,20,20]),'Callback',@(src, event) obj.toggleCallback(src, 4),'BackgroundColor', [1 1 1], 'ForegroundColor', 'black');
            obj.Buttons{3} = uicontrol(obj.UIFig,'Style', 'togglebutton', 'Position', obj.abspos([500,565,20,20]),'Callback',@(src, event) obj.toggleCallback(src, 3),'BackgroundColor', [1 1 1], 'ForegroundColor', 'black');
            obj.Buttons{2} = uicontrol(obj.UIFig,'Style', 'togglebutton', 'Position', obj.abspos([545,565,20,20]),'Callback',@(src, event) obj.toggleCallback(src, 2),'BackgroundColor', [1 1 1], 'ForegroundColor', 'black');
            obj.Buttons{1} = uicontrol(obj.UIFig,'Style', 'togglebutton', 'Position', obj.abspos([590,565,20,20]),'Callback',@(src, event) obj.toggleCallback(src, 1),'BackgroundColor', [1 1 1], 'ForegroundColor', 'black');

            % Add a switch (toggle style)
            obj.Switches{2} = uiswitch(obj.UIFig, 'Items', {'', ''},'Position', obj.abspos([198, 495, 45, 80]),'Orientation','vertical','ItemsData', [false true],'ValueChangedFcn',@(src, event) obj.toggleCallback(src, 6));
            obj.Switches{1} = uiswitch(obj.UIFig, 'Items', {'', ''},'Position', obj.abspos([230, 495, 45, 80]),'Orientation','vertical','ItemsData', [false true],'ValueChangedFcn',@(src, event) obj.toggleCallback(src, 5));

            % Create virtual display
            obj.Display = uiaxes(obj.UIFig, ...
                'Position', obj.abspos([83, 220, 150, 150]), ...
                'XTick', [], 'YTick', [], ...
                'Box', 'on',...
                'Color','white');
            obj.Display.XLim = [0 1];
            obj.Display.YLim = [0 1];
            disableDefaultInteractivity(obj.Display);   
            obj.Display.Interactions = [];              
            obj.Display.Toolbar.Visible = 'off';

            % Add green box in bottom of display
            rectangle(obj.Display,"FaceColor",[0 0.8 0],"EdgeColor","black", ...
                 "Position",[0 0 1 0.25]);
            text(obj.Display, 0.5, 0.125, ["PYNQ\_ML\_DigiTwin","Connected"], ...
                'Color', 'black', ...
                'FontSize', 7, ...
                'FontName', 'Courier New', ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle');
            % Add startup text
            obj.Display_ShowMessage(["PYNQ_ML Digital Twin","", ...
                "     Version "+sprintf("%0.1f",obj.VersionNr), ...
                "     "+obj.DateString]);
            drawnow;
        end


        function toggleCallback(obj, src, buttonNumber)
            if buttonNumber<5
                % For the pushbuttons
                if get(src, 'Value') == 1
                    % Button is pressed
                    set(src, 'BackgroundColor', [0.2 0.2 0.2], 'ForegroundColor', 'white');
                    obj.SupportObject.PinStates(obj.OffsetButtonNr + buttonNumber)=true;

                    % Create the timer which switches off the button after
                    % one second.
                    obj.TimerObj = timer( ...
                        'StartDelay', 1, ...
                        'TimerFcn', @(~,~)obj.switchOffButton(src,buttonNumber));

                    % Start the timer
                    start(obj.TimerObj);
                else
                    % Button is released
                    set(src, 'BackgroundColor', [1 1 1], 'ForegroundColor', 'black');
                    obj.SupportObject.PinStates(obj.OffsetButtonNr + buttonNumber)=false;
                end
            else
                % For the switches
                obj.SupportObject.PinStates(obj.OffsetButtonNr + buttonNumber)=src.Value;
            end
        end
        function switchOffButton(obj,src,buttonNumber)
            % Button is released
            set(src, 'BackgroundColor', [1 1 1], 'ForegroundColor', 'black');
            obj.SupportObject.PinStates(obj.OffsetButtonNr + buttonNumber)=false;
            obj.Buttons{buttonNumber}.Value=0;
        end

        function setLEDs(obj)
            % Set the green LED's
            for i=1:4
                if obj.SupportObject.PinStates(i+obj.OffsetLEDNr)
                    set(obj.LEDs{i}, 'BackgroundColor', 'green');
                else
                    set(obj.LEDs{i}, 'BackgroundColor', 'black');
                end
            end
            % Set the RGB LEDs
            for i=1:2
                startpos = obj.OffsetRGBLEDNr+1+(i-1)*3;
                RGB=obj.SupportObject.PinStates(startpos:startpos+2);
                set(obj.RGBLEDs{i}, 'BackgroundColor', RGB);
            end
            drawnow;
        end

        function output = abspos(obj,relposarray)
            output=relposarray;
            IMHeight = 649;
            IMWidth = 874;
            output(1)=round(output(1)*obj.UIWidth/IMWidth);
            output(3)=round(output(3)*obj.UIWidth/IMWidth);
            output(4)=round(output(4)*obj.UIHeight/IMHeight);
            output(2)=round(obj.UIHeight-output(2)*obj.UIHeight/IMHeight-output(4));
        end
        function outputnr = replaceString(~,input,strings)
            % Takes an input and if a string, uses it to choose a numeric
            % from the strings (array of strings) input. If the input is a
            % numeric, it needs to be in this array range as well.
            if isnumeric(input)
                outputnr = input;
            elseif (ischar(input) || isstring(input)) && ismember(upper(input),strings)
                outputnr = find(strcmp(strings,input));
            else
                error("Input value is invalid: "+ string(input));
            end
        end
        function outputstr = replaceNumeric(~,input,strings)
            % Takes an input and if numeric, uses it to choose a string
            % from the strings (array of strings) input. If the input is a
            % string or char, it needs to be in this array as well.
            if isnumeric(input)
                try 
                    outputstr = strings{input};
                catch
                    error("Input value is not in the range of this parameter.")
                end
            elseif (ischar(input) || isstring(input)) && ismember(upper(input),strings)
                outputstr = upper(input);
            else
                error("Input value is invalid: "+ string(input));
            end
        end
        function outputstr = toStateString(obj,input)
            % Takes an input and if numeric, uses it to choose a string
            % from the States. If the input is a string or char, it needs to be in this array as well.
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin                
                input {mustBeState}
            end
            if isnumeric(input) || islogical(input)
                try 
                    outputstr = obj.STATES(input+1);
                catch
                    error("Input value is not in the range of this parameter.")
                end
            elseif (ischar(input) || isstring(input)) && ismember(input,obj.STATES)
                outputstr = input;
            else
                error(strcat("Input value is invalid: ", string(input)));
            end
        end
        function outputbool = toStateBool(obj,input)
            % Takes an input and if numeric, uses it to choose a string
            % from the States. If the input is a string or char, it needs to be in this array as well.
            arguments
                obj PYNQ_LIB.PYNQ_ML_DigiTwin                
                input {mustBeState}
            end
            if isnumeric(input) || islogical(input)
                outputbool = input;
            elseif (ischar(input) || isstring(input)) && ismember(upper(input),obj.STATES)
                outputbool = strcmpi(input,"HIGH");
            else
                error(strcat("Input value is invalid: ", string(input)));
            end
        end
    end
end

function mustBeNumberOrStr(f)
    % Checks whether an input is a scalar numeric or a string. Both are OK
    assert((isnumeric(f) && isscalar(f)) || isStringScalar(f))
end
function mustBeState(f)
    % Checks whether an input is a scalar numeric or logical or a string. All are OK
    assert(((isnumeric(f) || islogical(f)) && isscalar(f)) || isStringScalar(f))
end