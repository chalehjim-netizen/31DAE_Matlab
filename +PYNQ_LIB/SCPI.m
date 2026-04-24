classdef SCPI < handle
    % SCPI Class definition for SCPI (Standard Commands for Programmable Instruments)
    %
    % This class inherits from the handle class, allowing for reference 
    % semantics in MATLAB. It is designed to manage communication with 
    % SCPI-compliant instruments.
    properties % (Access = private)
        tcpClient       % TCP/IP object for communication
        connecttimeout  % Timeout for connection (default = 2 seconds)
        timeout         % Timeout for data transfers (default = 2 seconds)
        debug = false   % Write debug info to file if put to true
        debugfile = "scpi.log" % Filename of debugging file
    end
    properties (Hidden)
        cleanup         % Placeholder for cleanup operations
    end

    methods
        function obj = SCPI(tcpHost, tcpPort)
            % SCPI Constructor for establishing a TCP/IP connection to a device
            %
            % Input Arguments:
            %     tcpHost - Host address of the device
            %     tcpPort - Port number for the connection
            %
            % Output Arguments:
            %     obj - Instance of the SCPI class

            obj.cleanup = onCleanup(@()delete(obj)); % Ensure cleanup on object deletion
            if ~isMATLABReleaseOlderThan("R2024a")
                % Check for existing TCP connection to prevent multiple connections
                if ~isempty(tcpclientfind(Tag="PYNQ-SCPI"))
                    error("SCPI:ExistingConnection","A PYNQ SCPI-connection already exists. It is not allowed to make a second one.")
                end
            end
            % Constructor function
            disp(strcat("Connecting device on address ", tcpHost,":", num2str(tcpPort)));
            try
                obj.connecttimeout = 2; % Maximum allowed time to connect
                obj.timeout = 20;
                if isMATLABReleaseOlderThan("R2024a")
                    % Create TCP client for older MATLAB releases
                    obj.tcpClient = tcpclient(tcpHost, tcpPort,...
                        "ConnectTimeout",obj.connecttimeout,...
                        "Timeout",obj.timeout);
                else
                    % Create TCP client for newer MATLAB releases with a tag
                    obj.tcpClient = tcpclient(tcpHost, tcpPort,...
                        "ConnectTimeout",obj.connecttimeout,...
                        "Timeout",obj.timeout,...
                        "Tag","PYNQ-SCPI");
                end
                % Set the terminator for the connection to 'LF'
                obj.tcpClient.configureTerminator('LF');
            catch ME
                % If the connection fails, throw an error with the message
                error('Failed to connect to instrument: %s', ME.message);
            end
        end
        function flush(obj)
            % FLUSH Method to flush the input and output buffers of the TCP/IP object
            %
            % This method clears the buffers of the TCP/IP object stored in the tcpClient property
            % and logs a debug message indicating that the buffers have been flushed.

            % Flush the input and output buffers of the TCP/IP object
            obj.tcpClient.flush;
            % Log debug message
            obj.debugline('DEBUG: Flushed buffers.');
        end

        function disconnect(obj)
            % DISCONNECT Method to set the instrument to local control mode and disconnect the TCP/IP object
            %
            % This method checks if the TCP/IP connection is open, sends a command to set the instrument to local control mode,
            % and then disconnects the TCP/IP object stored in the tcpClient property.

            try
                % Check if the TCP/IP connection is open
                if strcmp(obj.tcpClient.Status, 'open')
                    % Send command to set instrument to local control mode
                    obj.tcpClient.write('SYSTem:LOCal');
                    % Disconnect the TCP/IP object
                    obj.tcpClient.disconnect();
                    % Log debug message
                    obj.debugline('DEBUG: Disconnecting.');
                end
            catch
                % Handle any errors that occur during the process
            end
        end
        function response = writeReadCommand(obj, command)
            % WRITEREADCOMMAND Sends a SCPI command to the instrument and waits for a response
            %
            % Input Arguments:
            %     obj - The object containing the TCP/IP client
            %     command - The SCPI command to be sent to the instrument
            %
            % Output Arguments:
            %     response - The response received from the instrument after sending the command

            obj.flush; % Clear any existing data in the TCP/IP buffer
            obj.debugline(command); % Log the command for debugging
            % try
            response = strtrim (obj.tcpClient.writeread(command)); % Trim the response and return it
            % catch
            %     disp('Error communicating with instrument.');
            % end
            if isempty(response) % Check if the response is empty
                disp('No response from instrument'); % Notify if no response was received
                obj.debugline('DEBUG: No response from instrument.'); % Log debug information
            else
                obj.debugline(response); % Log the received response for debugging
            end
        end

        function response = writeCommand(obj, command)
            % Send a SCPI command to the instrument using the TCP/IP object stored in the tcpClient property
            obj.flush; % Clear any existing data in the TCP/IP buffer
            obj.tcpClient.writeline(command); % Send the command to the instrument
            obj.debugline(command); % Log the command for debugging
            response = ""; % Initialize response variable
            pause(0.05); % Pause briefly to allow for response
            % Check if there are bytes available to read
            while obj.tcpClient.NumBytesAvailable>0
                pause(0.05); % Pause briefly to allow for more data to arrive
                % If more than 5 bytes are available
                if obj.tcpClient.NumBytesAvailable>5
                    response = obj.tcpClient.readline; % Read a line of response
                    obj.debugline(response); % Log the response for debugging
                    % Check for error in response
                    if contains(string(response),"error")
                        disp(strcat("Error message received on command ", command, " Error: " , response)); % Display error message
                    end
                else
                    response = obj.tcpClient.read; % Read remaining bytes
                    disp(response); % Display the response
                end
            end
        end

        function writeReadCommandBlock(obj, commandblock)
            % WRITEREADCOMMANDBLOCK Function to process a block of commands
            %
            % Input Arguments:
            %     obj - the object that contains the command methods
            %     commandblock - a string containing multiple commands
            %
            % This function splits the command block into individual commands,
            % displays each command, and sends it for execution, handling
            % queries and write commands appropriately.

            commands=splitlines(commandblock); % Split the command block into individual commands
            for i=1:numel(commands) % Iterate over each command
                command=commands{i}; % Get the current command
                disp(command); % Display the command
                if contains(command,"?") % Check if the command is a query
                    response = obj.writeReadCommand(command); % Send a read command
                else
                    response = obj.writeCommand(command); % Send a write command
                end
                disp(response); % Display the response
            end
        end
        function writeReadCommandBlockFromFile(obj, filename)
            % WRITEREADCOMMANDBLOCKFROMFILE Function to read and execute a command block from a file
            %
            % Input Arguments:
            %     obj - the object that will execute the command block
            %     filename - the name of the file containing the commands

            % Read commands from the specified file
            comblock = fileread(filename);
            % Execute the command block
            obj.writeReadCommandBlock(comblock);
        end
        function binaryData = readBinary(obj, command)
            % READBINARY Sends a SCPI command to the instrument and retrieves binary data
            %
            % Input Arguments:
            %     obj     - The object instance containing the TCP/IP client
            %     command - The SCPI command to send to the instrument
            %
            % Output Arguments:
            %     binaryData - The binary data returned from the instrument

            obj.flush; % Clear any existing data in the TCP/IP buffer
            obj.tcpClient.writeline(command); % Send the command to the instrument
            obj.debugline(command); % Log the command for debugging
            pause(0.001); % Brief pause to allow for response
            binaryData = obj.tcpClient.read(); % Read the binary data from the instrument
            obj.debugline(binaryData); % Log the binary data for debugging
            if isempty(binaryData) % Check if the binary data is empty
                error('No response from instrument'); % Raise an error if no data was received
            end
        end
        function status = isConnected(obj)
            % ISCONNECTED Method to check the connection status of the TCP/IP object
            %
            % Output Arguments:
            %     status - boolean indicating whether the TCP/IP object is connected

            % Check whether the TCP/IP object stored in the tcpClient property is connected to the instrument
            status = strcmp(obj.tcpClient.Status, 'open'); % Return true if connected
        end
        function delete(obj)
            % DELETE Method to disconnect and delete the TCP/IP object
            %
            % This method disconnects the TCP/IP object stored in the tcpClient property
            % and deletes it to free up resources.

            obj.disconnect(); % Disconnect from the instrument
            pause(0.2); % Brief pause to ensure disconnection
            delete(obj.tcpClient); % Delete the TCP/IP object
        end
        function debugline(obj,inputline)
            % DEBUGLINE Method to log input lines to a debug file if debugging is enabled
            %
            % Input Arguments:
            %     obj - object containing debug settings
            %     inputline - line of input to be logged

            % Check if debugging is enabled
            if obj.debug
                % Open the debug file for appending
                fid = fopen(obj.debugfile,"a");
                % Write the input line to the debug file
                fprintf(fid,'%s\n', inputline);
                % Close the debug file
                fclose(fid);
            end
        end
    end

end
