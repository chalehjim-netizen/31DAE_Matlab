classdef PYNQ_ML < handle
    %PYNQ_ML Class used to connect and control a PYNQ-Z2 board from Matlab
    
    % Initiating the default communicstion settings of the PYNQ-Z2 board 
    properties (Constant)
        defaultAddress = "10.43.0.1";
        defaultPort = 11008;
        defaultResetPort = 11009;
        maxConnectionTime = 12;
    
        % In and outputs of the board
        %% General
        % Define possible states for the LEDs and switches on the board
        STATES = ["LOW","HIGH"];
        % Define possible directions for GPIO pins
        DIRECTIONS = ["IN","OUT"];
        % The possible modules to use on the PYNQ board
        PYNQ_MODULES = ["GPIO", "UART0_TX", "UART0_RX", "SPICLK0", "MISO0", "MOSI0",...
            "SS0", "SPICLK1", "MISO1", "MOSI1", "SS1", "SDA0", "SCL0", "SDA1", "SCL1",...
            "PWM0", "PWM1","PWM2", "PWM3","PWM4", "PWM5",...
            "PULSECOUNTER0","PULSECOUNTER1",...
            "UART1_TX", "UART1_RX","IIC0_SDA","IIC0_SCL"];
        %% DIO stuff
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
        % The pins and address used to connect the ADS1115.
        ADC_EXT_PINS = ["AR_SDA","AR_SCL"];
        ADC_EXT_ADDRESS = "#B01001000";
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
        %% Display
        DISPallowedCharExpr = "[^a-zA-Z\d ~!@#$%^&*()_+`=[]{}|\;:""<>?./-,]";
    end

    properties (SetAccess = private)
        % A low-level PYNQ_SCPI object which does the real communication.
        scpiObj 

        % An object of the PYNQ_UI to control the user interface
        UI
       
        % Flag to indicate whether a connection to the board is active or not
        Active = false;

        % IP adress of the board
        Address;
        % Port number of the board
        Port;

        % Version of the firmware on the PYNQ-board
        firmwareversion = 0;
    end
    properties (Access = private)
        % Are true if a DAC is initialized.
        DAC_Initialized = [false, false];
        ADS1115_Initialized = false;
        ADS1115_Channels_Added = false;
        ADS1115_Fast_Started = false;
        ADC_Ext_Wait_Time = 0.15;
        ADC_Ext_currentRange = 0;
        ADC_Ext_SampleWait = 4;
    end

    properties (Hidden)
        cleanup
    end

    methods
        %% Creator and destructor methods
        function obj = PYNQ_ML(address,port,resetport) % Can be as many input variables as wanted
            % Creator function. Makes a new connection to a PYNQ-board, sets
            % up the required port and opens it.

            % Check if an alternate address or port number were passed as arguments
            arguments
                address {mustBeText} = PYNQ_LIB.PYNQ_ML.defaultAddress;
                port {mustBeScalarOrEmpty,mustBeNonnegative,mustBeInteger} = PYNQ_LIB.PYNQ_ML.defaultPort;
                resetport {mustBeScalarOrEmpty,mustBeNonnegative,mustBeInteger} = PYNQ_LIB.PYNQ_ML.defaultResetPort;
            end

            % Check if another instance of PYNQ_ML has been created before.
            % If so, give an error.
            % For Matlab versions of 2024a or newer, we do not do this,
            % because there we can check if a tcpclient connection already
            % exists, which is more robust.
            global PYNQ_created %#ok<*GVMIS>
            if isempty(PYNQ_created) || ~PYNQ_created
                PYNQ_created = false;
            else
                if isMATLABReleaseOlderThan("R2024a")
                    error("Only one instance of PYNQ_ML can exist simultaneously."+newline+...
                        "If you want to create a new instance, please clear the old one first, for example using clearvars.");
                end
            end

            % Check if the library is called from the correct location
            classlocation = mfilename('fullpath');
            if  ~contains(classlocation,"+PYNQ_LIB")
                error("PYNQ_ML.m is not located in the +PYNQ_LIB package folder. Please correct this.")
            end
            if contains(pwd,"+PYNQ_LIB")
                error("Please do not try to make a PYNQ_ML object when using the +PYNQ_LIB folder as Current Folder.")
            end

            obj.Address=address;
            obj.Port = port;

            % Define a cleanup function to be run when the object is deleted
            obj.cleanup = onCleanup(@()delete(obj));

            tic;
            created = false;
            pinggood = true;
            restartinggood = true;
            while ~created && pinggood && toc<obj.maxConnectionTime
                % Connect to the instrument.
                try
                    % Create an instance of the SCPI class
                    obj.scpiObj = PYNQ_LIB.SCPI(obj.Address,obj.Port);
                    created = true;
                catch ME
                    % If the connection attempt gave an error, we
                    % first check if we can get a ping response from the
                    % PYNQ-board.
                    [status,~]=system("ping -n 1 -w 2 "+obj.Address);
                    pinggood = status == 0;
                    % If this is not the case, we stop trying and advise
                    % the user to check the network connection.
                    if ~pinggood
                        error("The PYNQ-board is not started or the network connection to " + obj.Address + " is not working. Please fix this before retrying.")
                    elseif ME.identifier=="SCPI:ExistingConnection"
                        error(ME.identifier,ME.message);
                    elseif restartinggood
                        restartinggood = PYNQ_LIB.PYNQ_ML.restartPYNQBridge(address,resetport);
                        if restartinggood
                            disp("Trying connectiong again.")
                        end
                    else
                        disp("Network connection to "+ obj.Address + " is working, but connection to SCPI is not working.")
                        warning(ME.identifier,"%s", ME.message);
                    end
                end
            end
            if ~created
                error("Network connection to "+ obj.Address + " is working, but connection to SCPI is not working.")
            end
             % Send the "*IDN?" command to the board to check the connection
            try
                obj.ID;
                obj.scpiObj.flush;
                [response,obj.firmwareversion] = obj.ID;
                disp(strcat("Connected to ",response));
                PYNQ_created = true;
            catch ME
                error("Device did not seem to respond to IDN command.");
            end
            obj.reset;
            obj.initializeLEDButtons;
            obj.System_Set_time('now',false);
            obj.LEDs_flash; % Call flashLEDs method
            obj.UI = PYNQ_LIB.PYNQ_UI(obj);
            obj.Active = true; % Set the PYNQ board connection to be active
        end
        function delete(obj)
            % Destructor function to clear a PYNQ_ML object
            if obj.Active
                obj.Display_ShowMessage(["PYNQ object","disconnected."]);
            end
            global PYNQ_created
            PYNQ_created = false;
            obj.Active = false;
            delete(obj.scpiObj);
        end

        %% General methods
        function [response, version] = ID(obj)
            % Reads the ID of the connected SCPI object
            response = obj.scpiObj.writeReadCommand("*IDN?");
            response = erase(response, '"');
            results = split(response,",");
            response = strrep(response,",",", ");
            if numel(results)>1
                version = str2double(results(4));
                response = results(1)+ " " +results(2)+ " V"+results(4)...
                    + ", updated: " + results(3);
            else
                version = sscanf(response,'PYNQRYB V%f');
            end
            if numel(version)==0
                version = 0.1;
            end
        end
        function response = isConnected(obj)
            % Tests if device is responding properly.
            try
                response = obj.scpiObj.isConnected;
                if response
                    try
                        obj.ID;
                    catch
                        pause(0.2);
                        try
                            obj.ID;
                        catch
                            response = false;
                        end
                    end
                end
            catch
                response=false;
            end
        end
        function reset(obj)
            % Reset GPIO and switchbox
            obj.scpiObj.writeCommand(":GPIO:RST");
            obj.scpiObj.writeCommand(":SWITCHBOX:RST");
        end
        function initializeLEDButtons(obj)
            % Initialize LED GPIO directions
            obj.scpiObj.writeCommand(":GPIO:DIR LD0,Out;DIR LD1,Out;DIR LD2,Out;DIR LD3,Out");
            % Initialize RGB LED GPIO directions
            obj.scpiObj.writeCommand(":GPIO:DIR LD4R,Out;DIR LD4G,Out;DIR LD4B,Out;DIR LD5R,Out;DIR LD5G,Out;DIR LD5B,Out");
            % Initialize button GPIO directions
            obj.scpiObj.writeCommand(":GPIO:DIR BTN0,In;DIR BTN1,In;DIR BTN2,In;DIR BTN3,In;DIR SW0,In;DIR SW1,In");
        end
        function System_Set_time(obj,time,showerror)
            % Updates the time on the PYNQ board to the current system time
            arguments
                obj PYNQ_LIB.PYNQ_ML
                time {mustBeTextScalar}
                showerror {mustBeNumericOrLogical} = true
            end
            if obj.firmwareversion>1
                timestring = string(datetime(time,'Format','yyyyMMddHHmmss'));
                obj.scpiObj.writeCommand(":SYSTEM:Timeset '"+timestring+"'");
            else
                if showerror
                    disp('Cannot set time for this firmware version.')
                end
            end
        end
        function System_Shutdown(obj,showerror)
            % Shuts down the PYNQ board. Not often needed.
            arguments
                obj PYNQ_LIB.PYNQ_ML
                showerror {mustBeNumericOrLogical} = true
            end
            if obj.firmwareversion>1
                disp("PYNQ board shutting down and PYNQ object being deleted.")
                obj.Display_ShowMessage("Shutting down PYNQ");
                obj.scpiObj.writeCommand(":SYSTEM:Shutdown");
                try
                    delete(obj);
                    clear obj;
                catch
                end
            else
                if showerror
                    disp('Cannot shut down in this firmware version.')
                end
            end
        end
        %% Mapping methods
        function SwitchBox_map(obj,pin,module)
            % Maps a certain pin of the the PYNQ-board to a module. 
            % Inputs are the pin (a string, e.g. "AR2") and the module 
            % (e.g. "GPIO" or "PWM0")
            arguments
                obj PYNQ_LIB.PYNQ_ML
                pin {mustBeTextScalar}
                module {mustBeNumberOrStr}
            end
            module = obj.replaceNumeric(module,obj.PYNQ_MODULES);
            commandString = strcat(":SWITCHBOX:MAP ",pin,",",module);
            obj.scpiObj.writeCommand(commandString);

            % Set DAC initialized to false if a DAC pinned is mapped. This
            % means it will have to be initialized again if the DAC is
            % used.
            if ~isempty(find(obj.DAC_CHANNELS==pin, 1))
                obj.DAC_Initialized(find(obj.DAC_CHANNELS==pin, 1))=false;
            end
        end
        function state = SwitchBox_getMapping(obj,pin)
            %getMapping Reads mapping from a pin
            % Input is a string for the pin (e.g. "AR2")
            arguments
                obj PYNQ_LIB.PYNQ_ML
                pin {mustBeTextScalar}
            end
            commandString = strcat(":SWITCHBOX:MAP? ",pin);
            state= obj.scpiObj.writeReadCommand(commandString);
        end
        %% Basic GPIO methods
        function DigitalPin_set_Dir(obj,pin,dir)
            %setDigitalPinDir Writes direction (input/output) to a digital pin
            % Inputs are the pin (a string, e.g. "AR2") and 
            % the direction "IN" or "OUT".
            arguments
                obj PYNQ_LIB.PYNQ_ML
                pin {mustBeTextScalar}
                dir {mustBeTextScalar}
            end
            dirstring = obj.replaceNumeric(dir,obj.DIRECTIONS);
            commandString = strcat(":GPIO:DIR ",pin,", ",dirstring);
            obj.scpiObj.writeCommand(commandString);
        end
        function state = DigitalPin_get_Dir(obj,pin)
            %ReadDigitalPin Reads current direction setting from a digital pin
            % Input is the pin (a string, e.g. "AR2") and 
            % output the direction of the pin ("INPUT"/"OUTPUT")
            arguments
                obj PYNQ_LIB.PYNQ_ML
                pin {mustBeTextScalar}
            end
            commandString = strcat(":GPIO:DIR? ",pin);
            state = obj.scpiObj.writeReadCommand(commandString);
        end
        function commandString = DigitalPin_write(obj,pin,state,doWrite)
            % WriteDigitalPin Writes state to a digital pin
            % Inputs are the pin (a string, e.g. "AR2"),
            % the state (true/false) and, optionally doWrite.
            % If doWrite is false then the command will not be sent to the
            % PYNQ-board yet, but only given as output.
            arguments
                obj PYNQ_LIB.PYNQ_ML
                pin {mustBeTextScalar}
                state {mustBeState} = false
                doWrite {mustBeNumericOrLogical} = true
            end
            statestring = obj.toStateString(state);
            commandString = strcat(":GPIO:LEVEL ",pin,", ",statestring);
            if doWrite
                obj.scpiObj.writeCommand(commandString);
            end
        end
        function state = DigitalPin_read(obj,pin)
            %ReadDigitalPin Reads state from a digital pin
            % Input is the pin (a string, e.g. "AR2") and 
            % output the state (true/false)
            arguments
                obj PYNQ_LIB.PYNQ_ML
                pin {mustBeTextScalar}
            end
            commandString = strcat(":GPIO:LEVEL? ",pin);
            stateString = obj.scpiObj.writeReadCommand(commandString);
            state = strcmp(stateString,"High");
        end

        %% PYNQ ADC methods
        function voltage = ADC_PYNQ_read(obj,channel,LEDflash)
            %ADC_PYNQ_read Read voltage over PYNQ internal ADC channel #1 to #6. 
            % Input is the channel number (1-6) for A0 - A5
            % Optionally briefly flashes an LED during the operation if LEDflash > 0
            arguments
                obj PYNQ_LIB.PYNQ_ML
                channel {mustBeInteger, mustBeInRange(channel,1,6)} = 1
                LEDflash {mustBeNumberOrStr} = 0
            end
            % Read the voltage over desired channel
            commandString = strcat(":ADC:READ? ", obj.replaceNumeric(channel,obj.ADC_PYNQ_CHANNELS));
            commandString = obj.LED_add_Flash(commandString,LEDflash);

            response = obj.scpiObj.writeReadCommand(commandString);
            voltage = str2double(response); % Outputs voltage as double 
        end
        
        %% ADS1115 ADC methods   
        function ADC_Ext_initialize(obj, samplewait)
            % Initializes the ADS1115 board and maps switchbox.
            arguments
                obj PYNQ_LIB.PYNQ_ML
                samplewait {mustBeNumberOrStr} = 5
            end
            if ~obj.ADS1115_Initialized || ...
                    (samplewait~=obj.ADC_Ext_SampleWait && nargin>1)
                disp("Initializing ADS1115 on the PYNQ board.");
                obj.ADC_Ext_SampleWait = samplewait;
                obj.SwitchBox_map(obj.ADC_EXT_PINS{1},"IIC0_SDA");
                obj.SwitchBox_map(obj.ADC_EXT_PINS{2},"IIC0_SCL");
                commandString = strcat(":ADS1115:INIT ",obj.ADC_EXT_ADDRESS);
                if samplewait~=4
                    commandString = strcat(commandString,",",num2str(samplewait));
                end
                obj.scpiObj.writeCommand(commandString);
                obj.ADS1115_Initialized = true;
                obj.ADS1115_Channels_Added = false;
                obj.ADS1115_Fast_Started = false;
                obj.ADC_Ext_set(5,1,1);
            end
        end

        function settingsChanged = ADC_Ext_set(obj,channel,range,rate)
            %ADC_Ext_set Sets channel, range and data rate of the ADS1115 board
            % channel is an integer number between 1 and 8, or a string from ADC_EXT_CHANNELS
            % range is an integer number between 1 and 6, or a string from ADC_EXT_RANGES
            % rate is an integer number between 1 and 8, or a string from ADC_EXT_RATES
            arguments
                obj PYNQ_LIB.PYNQ_ML
                channel {mustBeNumberOrStr} = 0
                range {mustBeNumberOrStr} = 0
                rate {mustBeNumberOrStr} = 0
            end
            obj.ADC_Ext_initialize

            commandString = "";
            if isStringScalar(channel) || channel~= 0
                % Sets the ADS1115 channel
                valuestring = obj.replaceNumeric(channel,obj.ADC_EXT_CHANNELS);
                commandString = strcat(commandString, ";:ADS1115:CH ",valuestring);
            end
            if isStringScalar(range) || range~= 0
                % Sets the ADS1115 voltage range
                valuestring = obj.replaceNumeric(range,obj.ADC_EXT_RANGES);
                commandString = strcat(commandString, ";:ADS1115:RANGE ",valuestring);
                obj.ADC_Ext_currentRange = range;
            end
            if isStringScalar(rate) || rate~= 0
                % Sets the ADS1115 data rate
                valuestring = obj.replaceNumeric(rate,obj.ADC_EXT_RATES);
                commandString = strcat(commandString, ";:ADS1115:RATE ",valuestring);
                rangenumber = find(strcmp(obj.ADC_EXT_RATES,valuestring));
                obj.ADC_Ext_Wait_Time = obj.ADC_EXT_WAIT_TIMES(rangenumber);
            end

            settingsChanged = strlength(commandString)>0;
            
            if settingsChanged
                obj.scpiObj.writeCommand(commandString);
                % Make sure that the right settings are really used.
                if obj.ADC_Ext_SampleWait>1
                    obj.scpiObj.writeReadCommand(":ADS1115:Voltread?");
                    pause(obj.ADC_Ext_Wait_Time);
                    obj.scpiObj.writeReadCommand(":ADS1115:Voltread?");                    
                end
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
                obj PYNQ_LIB.PYNQ_ML
                channel {mustBeNumberOrStr} = 0
                range {mustBeNumberOrStr} = 0
                rate {mustBeNumberOrStr} = 0
                LEDflash {mustBeNumberOrStr} = 0
            end       
            settingschanged = obj.ADC_Ext_set(channel,range,rate);
            
            % Wait a short time if any of the settings have been provided such 
            % that the new reading has been surely acquired.
            if settingschanged 
                pause(obj.ADC_Ext_Wait_Time);
            end

            % Read the voltage
            commandString = strcat(":ADS1115:Voltread?");
            commandString = obj.LED_add_Flash(commandString,LEDflash);

            response = obj.scpiObj.writeReadCommand(commandString);
            voltage = str2double(response); % Outputs voltage as double
            inrange = obj.ADC_Ext_Check_Inrange(voltage,false);
            if ~inrange
                warning("ADS1115 input voltage out of measurement range.")
            end
        end
        function voltage = ADC_Ext_AllowedVoltage(obj,range)
            % Gives back the maximum allowed voltage for a measurement
            % using the ADS1115 before triggering an out-of-range warning.
            arguments
                obj PYNQ_LIB.PYNQ_ML
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
                obj PYNQ_LIB.PYNQ_ML
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
            channelstring = obj.replaceNumeric(channel,obj.ADC_EXT_CHANNELS);
            rangestring = obj.replaceNumeric(range,obj.ADC_EXT_RANGES);
            commandString = strcat("ADS1115:ADDChannel ",channelstring,",",rangestring);
            obj.scpiObj.writeCommand(commandString);
            obj.ADS1115_Channels_Added = true;
        end
        function inrange = ADC_Ext_Check_Inrange(obj,Voltages,fast)
            %ADC_Ext_Check_Inrange Checks if a set of voltages is all in the allowed range.
            % Working depends on the PYNQ board firmware version.
            if obj.firmwareversion<1.3
                % For older firmware versions, compare with the known
                % maximum voltage for the current setting. This does not
                % work for fast voltage acquisitions where the maximum may
                % be different per channel
                if ~fast
                    inrange = ~any(abs(Voltages)>=obj.ADC_Ext_AllowedVoltage(obj.ADC_Ext_currentRange));
                else
                    inrange = true;
                end
            else
                % For newer firmwares, the PYNQ board returns an out of
                % range value. Check if any of these are found.
                inrange = ~(any(Voltages==obj.ADC_EXT_OUT_OF_RANGE(1)) ||...
                    any(Voltages==obj.ADC_EXT_OUT_OF_RANGE(2)));
            end
        end
        function ADC_Ext_Fast_Start(obj,delay)
            %ADC_Ext_Fast_Start Starts the fast acquisition of data from the ADS1115
            % Input is the delay between two acquisitions in microseconds
            % (default at 10000).
            arguments
                obj PYNQ_LIB.PYNQ_ML
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
            commandString = strcat("ADS1115:RUn ",num2str(delay));
            obj.scpiObj.writeCommand(commandString);
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
                obj PYNQ_LIB.PYNQ_ML
            end
            if obj.ADS1115_Fast_Started
                commandString = ":ADS1115:Samples?";
                response = obj.scpiObj.writeReadCommand(commandString);
                if response~=""
                    response = str2double(strsplit(response,",")); % Outputs the intervals as an array of doubles.
                    % Data contains
                    response = reshape(response,3,[])';
                    % And here it is converted back to a more physical
                    % quantity because they are encoded 32 bit (signed).
                    if size(response,1)>=obj.MAX_ADC_SAMPLES
                        warning("Number of returned samples is at its maximum. You may have missed some samples because of this.");
                    end
                    % Convert timestamps, channels and samples to a nice Matlab
                    % table
                    Timestamps=response(:,1);
                    try
                        Channels = obj.ADC_EXT_CHANNELS(response(:,2)+1)';
                    catch
                        error("Something wrong with acquired data from ADS1115. Please re-initialize.")
                    end
                    Voltages=response(:,3);
                    voltagetable = table(Timestamps,Channels,Voltages);

                    % Check if all voltages are in range and give a warning and
                    % a false inrange output if not.
                    inrange = obj.ADC_Ext_Check_Inrange(voltagetable.Voltages,true);
                    if ~inrange
                        warning("ADS1115 input voltage(s) out of measurement range.")
                    end
                    voltagetable.Properties.VariableUnits=["s","","V"];
                else
                    voltagetable=[];
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
                obj PYNQ_LIB.PYNQ_ML
            end
            commandString = "ADS1115:STOP";
            obj.scpiObj.writeCommand(commandString);
            try
                voltagetable = obj.ADC_Ext_Fast_Get_Points;
            catch
            end
            obj.ADS1115_Fast_Started = false;
        end
        function ADC_Ext_Fast_ClearChannels(obj)
            %ADC_Ext_Fast_ClearChannels Clears the data acquisition
            %channels of the ADS1115
            arguments
                obj PYNQ_LIB.PYNQ_ML
            end
            if obj.ADS1115_Fast_Started
                warning("Fast measurement still running. Stopping first before clearing channels.");
                obj.ADC_Ext_Fast_Stop;
            end
            commandString = "ADS1115:CLEARChannel";
            obj.scpiObj.writeCommand(commandString);
            obj.ADS1115_Channels_Added = false;
        end
        %% DAC methods
        function DAC_initialize(obj,channel)
            %DAC_initialize Initializes DAC number one or two on the
            %breakout board.
            % channel is 1 or 2 and corresponds with connector DAC0 or DAC1
            arguments
                obj PYNQ_LIB.PYNQ_ML
                channel {mustBeNumberOrStr} = 1
            end
            obj.SwitchBox_map(obj.replaceNumeric(channel, obj.DAC_CHANNELS),obj.DAC_PWMs(channel));
            obj.DAC_Initialized(channel)=true;
        end
        function DAC_set(obj,channel,duty)
            %DAC_set Sets the output of the DAC channel to a value using a 
            % duty cycle (number between 0 and 1).
            arguments
                obj PYNQ_LIB.PYNQ_ML
                channel {mustBeInteger, mustBeInRange(channel,1,2)} = 1
                duty {mustBeNumeric, mustBeInRange(duty,0,1)} = 0.5
            end
            if ~obj.DAC_Initialized(channel)
                obj.DAC_initialize(channel);
            end
            obj.PWM_set(obj.DAC_PWMs(channel),obj.DAC_Clockticks(channel),duty);
        end
        function DAC_setV(obj,channel,voltage)
            %DAC_setV Sets the output of the DAC channel to a value using a
            %voltage. Use a voltage between 0 and 3.3 V.
            arguments
                obj PYNQ_LIB.PYNQ_ML
                channel {mustBeInteger, mustBeInRange(channel,1,2)} = 1
                voltage {mustBeNumeric, mustBeInRange(voltage,0,3.3)} = 1
            end
            duty = voltage/obj.DAC_Max_V;
            obj.DAC_set(channel,duty);
        end

        %% Counter methods
        function Counter_enable(obj,pin,edge)
            %Counter_enable Enables the counter on a pin.
            % Inputs are the pin string (e.g. "AR2") and the edge of a signal 
            % to count on ("RISING","FALLING" or "BOTH").
            arguments
                obj PYNQ_LIB.PYNQ_ML
                pin {mustBeTextScalar}
                edge {mustBeNumberOrStr} = 1
            end
            obj.SwitchBox_map(pin,"GPIO");
            obj.DigitalPin_set_Dir(pin,"IN");
            commandString = strcat(":COUNTER:ENABLE ",pin);
            obj.scpiObj.writeCommand(commandString);
            if ~exist('edge','var') 
                edge = 2;
            end
            commandString = strcat(":COUNTER:EDGE ",pin,",",obj.replaceNumeric(edge,obj.COUNTER_EDGES));
            obj.scpiObj.writeCommand(commandString);
        end
        function Counter_reset(obj,pin)
            %Counter_reset Resets counter on a pin (e.g. "AR2")
            arguments
                obj PYNQ_LIB.PYNQ_ML
                pin {mustBeTextScalar}
            end
            commandString = strcat(":COUNTER:RST ",pin);
            obj.scpiObj.writeCommand(commandString);
        end
        function [counts,time] = Counter_read(obj,pin)
            %Counter_read Reads counter state from a digital pin (e.g. "AR2")
            %Outputs the number of counts and the time elapsed since last reset as doubles.
            arguments
                obj PYNQ_LIB.PYNQ_ML
                pin {mustBeTextScalar}
            end
            commandString = strcat(":COUNTER? ",pin);
            response = obj.scpiObj.writeReadCommand(commandString);
            responses = str2double(strsplit(response,","));
            counts = responses(1); % Outputs the number of counts as double 
            time = responses(2); % The time in seconds since the last reset.
        end
        %% PulseCounter methods
        function PulseCounter_enable(obj,nr,pin,edge)
            %PulseCounter_enable Enables the fast pulse counter on a pin
            %nr is which of the two pulse counters is started (1 or 2)
            %pin is a digital pin (e.g. "AR2")
            %edge determines which edge of a signal to count on (1 = rising, 2 = falling).
            arguments
                obj PYNQ_LIB.PYNQ_ML
                nr (1,1) {mustBeInteger, mustBeInRange(nr,1,2)}
                pin {mustBeTextScalar}
                edge (1,1) {mustBeInteger, mustBeInRange(edge,1,2)} = 1;
            end
            PCstring = strcat("PULSECOUNTER",num2str(nr-1));
            obj.SwitchBox_map(pin,PCstring);
            commandString = strcat(PCstring,":EDGE ",obj.replaceNumeric(3-edge,obj.STATES));
            obj.scpiObj.writeCommand(commandString);
        end
        function PulseCounter_reset(obj,nr)
            %PulseCounter_reset Resets one of the fast pulse counters.
            %nr should be 1 or 2
            arguments
                obj PYNQ_LIB.PYNQ_ML
                nr (1,1) {mustBeInteger, mustBeInRange(nr,1,2)}
            end
            PCstring = strcat("PULSECOUNTER",num2str(nr-1));
            commandString = strcat(PCstring,":RESET");
            obj.scpiObj.writeCommand(commandString);
        end
        function [counts,time] = PulseCounter_read(obj,nr)
            %PulseCounter_read Reads pulse counter state from a digital pin
            %nr should be 1 or 2
            %Outputs the number of counts and the time elapsed since last reset as doubles.
            arguments
                obj PYNQ_LIB.PYNQ_ML
                nr (1,1) {mustBeInteger, mustBeInRange(nr,1,2)}
            end
            PCstring = strcat("PULSECOUNTER",num2str(nr-1));
            commandString = strcat(PCstring,":COUNT?");
            response = obj.scpiObj.writeReadCommand(commandString);
            responses = str2double(strsplit(response,","));
            counts = responses(1); % Outputs the number of counts as double 
            time = responses(2)*1e-8; % The time in seconds since the last query.
        end
        %% Interval timer methods
        function IntervalTimer_enable(obj,pin,edge)
            %IntervalTimer_enable Enables the interval timer on a pin
            %pin: a string for the pin to use (e.g. "AR2")
            %edge determines which edge of a signal to count on ("RISING","FALLING" or "BOTH")..
            arguments
                obj PYNQ_LIB.PYNQ_ML
                pin {mustBeTextScalar}
                edge {mustBeNumberOrStr} = 1
            end
            % First enable a counter
            obj.Counter_enable(pin,edge);
            obj.IntervalTimer_start(pin)
        end
        function IntervalTimer_disable(obj,pin)
            %IntervalTimer_disable Disables the interval timer on a pin (e.g. "AR2")
            commandString = strcat(":COUNTER:INTERVAL:DISABLE ",pin);
            obj.scpiObj.writeCommand(commandString);
        end
        function IntervalTimer_start(obj,pin)
            %IntervalTimer_start Starts the interval timer on the indicated pin. 
            % The interval timer first needs to have been enabled on this pin.
            arguments
                obj PYNQ_LIB.PYNQ_ML
                pin {mustBeTextScalar}
            end
            commandString = strcat(":COUNTER:INTERVAL:ENABLE ",pin);
            obj.scpiObj.writeCommand(commandString);
        end
        function IntervalTimer_reset(obj,pin)
            %IntervalTimer_reset Resets interval timer on a pin
            arguments
                obj PYNQ_LIB.PYNQ_ML
                pin {mustBeTextScalar}
            end
            obj.IntervalTimer_read(pin);
            obj.IntervalTimer_disable(pin);
            obj.IntervalTimer_start(pin);
        end
        function timings = IntervalTimer_read(obj,pin)
            %IntervalTimer_read Reads interval timer state from a digital pin. The interval
            % timer needs to be enabled and started first. Then this
            % command returns an array of the new intervals obtained since
            % the start, a reset or since the last use of IntervalTimer_read
            % (whichever comes last).
            % A maximum of 2000 intervals can be stored on the PYNQ board.
            arguments
                obj PYNQ_LIB.PYNQ_ML
                pin {mustBeTextScalar}
            end
            commandString = strcat(":COUNTER:INTERVAL? ",pin);
            response = obj.scpiObj.writeReadCommand(commandString);
            if response~=""
                timings = str2double(strsplit(response,",")); % Outputs the intervals as an array of doubles.
            else
                timings=[];
            end
            if numel(timings)>=obj.MAX_INTERVAL_TIMINGS
                warning("Number of returned intervals is at its maximum. You may have missed some intervals because of this.");
            end
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
                obj PYNQ_LIB.PYNQ_ML
                PWM {mustBeNumberOrStr}
                period {mustBeInteger,mustBeScalarOrEmpty}
                duty {mustBeNumeric, mustBeNonnegative, mustBeScalarOrEmpty, mustBeLessThanOrEqual(duty,1)} = 0.5
                steps {mustBeInteger,mustBeScalarOrEmpty} = -1
            end    
            
            % setPWM sends PWM signal to desired pin, with specified period
            % and duty cycle [0,1]
            PWM=obj.replaceNumeric(PWM,obj.PWM_NAMES);
            commandString = strcat(":",PWM,":PERIOD ",num2str(period));
            obj.scpiObj.writeCommand(commandString);

            % Checks and adapts period, in the end it will be a number of
            % clock cycles.
            if duty==1
                duty = period-1;
            elseif duty<1
                duty = floor(period*duty);
            elseif (duty > 1) && (duty < period)
                duty = floor(duty);
            else
                error("Duty cycle must either be a fraction between 0 and 1 or and integer smaller than period.")
            end
            commandString = strcat(":",PWM,":DUTY ",num2str(duty));
            obj.scpiObj.writeCommand(commandString);
            commandString = strcat(":",PWM,":STEPS ",num2str(steps));
            obj.scpiObj.writeCommand(commandString);
        end
        function steps = PWM_get_steps_left(obj,PWM)
            %PWM_get_steps_left Reads how many steps are left on a PWM
            %module. Returns 4294967295 when the PWM is running
            %indefinetely.
            arguments
                obj PYNQ_LIB.PYNQ_ML
                PWM {mustBeNumberOrStr}
            end    
            
            PWM=obj.replaceNumeric(PWM,obj.PWM_NAMES);
            commandString = strcat(":",PWM,":STEPS?");
            response = obj.scpiObj.writeReadCommand(commandString);
            steps = str2double(response);
        end

        %% LEDs, switches and button methods
        function commandString = LED_switch(obj,LEDNumber,state, doWrite)
            %LED_switch Switches on/off a desired LED, with number between 1 and 4
            % If doWrite is false then the command will not be sent to the
            % PYNQ-board yet, but only given as output.
            arguments
                obj PYNQ_LIB.PYNQ_ML
                LEDNumber {mustBeNumberOrStr}
                state {mustBeState} = false
                doWrite {mustBeNumericOrLogical} = true
            end
            if LEDNumber>0
                commandString = obj.DigitalPin_write(obj.replaceNumeric(LEDNumber,obj.LED_CHANNELS),...
                    state,doWrite);
            end
        end

        function commandString = LED_add_Flash(obj,commandString,LEDflash)
            %LED_add_Flash Adds LED flashing commands to a command string when
            % LEDflash>0
           arguments
                obj PYNQ_LIB.PYNQ_ML
                commandString {mustBeTextScalar}
                LEDflash {mustBeNumberOrStr} = 0
           end
            if LEDflash~=0
                commandString = strcat(obj.LED_switch(LEDflash,true,false),";",...
                    commandString,";",obj.LED_switch(LEDflash,false,false));
            end            
        end

        % Flashing wave LED sequence
        function LEDs_flash(obj)
            %LEDs_flash Flash LED's on the PCB board. Is now used
            % after initialisation.
            arguments
                obj PYNQ_LIB.PYNQ_ML
            end
            for i=1:4
                obj.LED_switch(i,true);
            end
            for i=1:4
                obj.LED_switch(i,false);
            end
        end

        function status = Switch_read(obj,Switch)
            %Switch_read Read state of a switch  (1-2 or "SW0"-"SW1") on the PCB.
            arguments
                obj PYNQ_LIB.PYNQ_ML
                Switch {mustBeNumberOrStr}
            end
            status = obj.DigitalPin_read(obj.replaceNumeric(Switch,obj.SWITCH_CHANNELS));
        end
        
        function status = Button_read(obj,Button)
            %Button_read Reads a button (1-4 or "BTN0"-"BTN3") on the PCB
            arguments
                obj PYNQ_LIB.PYNQ_ML
                Button {mustBeNumberOrStr}
            end
            if isnumeric(Button) && Button==0
                status = false;
            else 
                status = obj.DigitalPin_read(obj.replaceNumeric(Button,obj.BUTTON_CHANNELS));
            end
        end
        function LEDs_switch(obj,States)
            %LEDs_switch Write state of all LED on the PYNQ PCB. Uses a States array
            % of four logicals as input. E.g. [0,1,0,1]
            arguments
                obj PYNQ_LIB.PYNQ_ML
                States (1,4) logical
            end
            commandString = ":GPIO:LEVEL ";
            for i=1:4
                commandString = strcat(commandString,obj.LED_CHANNELS(i),", "...
                    ,obj.STATES(States(i)+1));
                if i<4
                    commandString = strcat(commandString,";LEVEL ");
                end
            end
            obj.scpiObj.writeCommand(commandString);
        end
        function RGBLED_set(obj,LedNr,RGB)
            %RGBLED_set Sets an RGB LED using the LED number (1 or 2) and a
            % three-row logical array to switch the R, G and B colours on
            % or off. E.g. [1,1,0] for yellow.
            arguments
                obj PYNQ_LIB.PYNQ_ML
                LedNr {mustBeScalarOrEmpty,mustBeInteger,mustBeInRange(LedNr,1,2)} = 1
                RGB (1,3) logical = [1,1,1];
            end
            commandString = ":GPIO:LEVEL ";
            for i=1:3
                commandString = strcat(commandString,obj.RGB_LED_CHANNELS((LedNr-1)*3+i),", "...
                    ,obj.STATES(RGB(i)+1));
                if i<3
                    commandString = strcat(commandString,";LEVEL ");
                end
            end
            obj.scpiObj.writeCommand(commandString);
        end
        function States = Buttons_read(obj)
            %Buttons_read Read the states of all buttons on the PYNQ PCB.
            % Returns a States array of four logicals (e.g. [1,0,0,0]).
            arguments
                obj PYNQ_LIB.PYNQ_ML
            end
            commandString = ":GPIO:LEVEL? ";
            for i=1:4
                commandString = strcat(commandString,obj.BUTTON_CHANNELS(i));
                if i<4
                    commandString = strcat(commandString,";LEVEL? ");
                end
            end
            stateString = obj.scpiObj.writeReadCommand(commandString);
            States = strcmp(strsplit(stateString,";"),"High");
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
                obj PYNQ_LIB.PYNQ_ML
                freq {mustBeNumeric, mustBeScalarOrEmpty, mustBeInRange(freq,1,10000)} = 1000
                nperiods {mustBeInteger, mustBeScalarOrEmpty} = 5
                volume {mustBeInteger, mustBeScalarOrEmpty, mustBeNonnegative, mustBeLessThanOrEqual(volume,100)} = 100
                usestartup {mustBeNumericOrLogical, mustBeScalarOrEmpty} = true
            end
            if obj.firmwareversion<1.2
                oldversion = true;
                if volume < 100
                    warning("For this firmware version (" + num2str(obj.firmwareversion) +...
                        "), volume settings are not yet implemented. Please update PYNQ firmware to use" + ...
                        "volume below 100. Volume will be set to 100.");
                    volume = 100;
                end
            else
                oldversion = false;
            end
            if nperiods/freq>10
                error("Please give a combination of frequency and number of periods that takes less than 10s to acquire.");
            end
            if usestartup
                nperiodspre=round(0.5/freq);
                commandString = strcat(":FRESPONSE:Ping? ",num2str(freq),", ",num2str(nperiodspre));
                if ~oldversion
                    commandString = commandString + ", " + num2str(volume);
                end
                obj.scpiObj.writeReadCommand(commandString);
            end
            commandString = strcat(":FRESPONSE:Ping? ",num2str(freq),", ",num2str(nperiods));
            if ~oldversion
                commandString = commandString + ", " + num2str(volume);
            end

            response = obj.scpiObj.writeReadCommand(commandString);
            if response~=""
                response = str2double(strsplit(response,",")); % Outputs the intervals as an array of doubles.
                % Data is interleaved, left and right channels seperately.
                % Here these are split again.
                response = reshape(response,2,[])';
                % And here it is converted back to a more physical
                % quantity because they are encoded 32 bit (signed).
                response = response/2^31;
            else
                response=[];
            end
        end
        %% Display methods
        function Display_ShowMessage(obj,message)
            %Display_ShowMessage Shows a message on the LCD-display.
            %message should be a string array, of which each element
            %will be displayed on a separate line. Note that there is
            %a maximum of six lines and twenty characters (including) spaces
            %per line. Excessive lines or characters will be ignored.
            arguments
                obj PYNQ_LIB.PYNQ_ML
                message {mustBeText} = "" % A string or char variable containing the message to be shown
            end
            if obj.firmwareversion>=1.2
                % If this is a string array with multiple elements, then tie
                % them together using the newline character "~"
                if numel(message)>1
                    multilinemessage = message(1);
                    for i=2:numel(message)
                        multilinemessage = multilinemessage+"~"+message(i);
                    end
                else
                    multilinemessage = message;
                end
                % As a final check, filter out any other "complex" character.
                finalmessage = regexprep(multilinemessage,obj.DISPallowedCharExpr,"");
                if ~strcmp(finalmessage,multilinemessage)
                    warning("Some characters have been filtered out of the text string. Please use only a simple subset of ASCII characters (except for ', \ and ~).")
                end
                commandString = strcat(":DISPLAY:MESSAGE '",finalmessage,"'");
                obj.scpiObj.writeCommand(commandString);
            else
                warning("Writing a message on the display requires PYNQ scpi firmware version 1.2 or higher.")
            end
        end
    end
    methods (Access=private)
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
                obj PYNQ_LIB.PYNQ_ML                
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
    end
    methods (Static) 
        function result = restartPYNQBridge(address,port)
            % Check if an alternate address or port number were passed as arguments
            arguments
                address {mustBeText} = PYNQ_LIB.PYNQ_ML.defaultAddress;
                port {mustBeScalarOrEmpty,mustBeNonnegative,mustBeInteger} = PYNQ_LIB.PYNQ_ML.defaultResetPort;
            end
            disp("Trying to restart SCPI-bridge app on PYNQ board using "+address +":"+ num2str(port)+".");
            try
                % Make a connection to this port
                test=tcpclient(address,port);
                test.flush;
                % and close it again.
                delete(test);
                pause(2);
                disp("Restarted SCPI-bridge app on PYNQ board.")
                result = true;
            catch ME
                warning("PYNQ board did not respond to restarting the SCPI-bridge app. This requires PYNQ firmware 1.4 or higher.")
                warning(ME.identifier,"%s", ME.message);
                result = false;
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