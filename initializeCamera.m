
imaqreset %This resets the imaging module, is optional but might prevent errors

hw = imaqhwinfo;
hw.InstalledAdaptors

imaqInfo = imaqhwinfo('gentl',1); % Prints properties of imaging module
vid = videoinput("gentl",1,"Mono12"); %Create a video object with the camera input
get(vid) %Outputs a list of all video properties
triggerconfig(vid,'manual'); % Sets the trigger mode to trigger only when you
%issue the trigger function
vid.FramesPerTrigger = 1; % How many frames are collected per trigger
vid.TriggerRepeat = 0; %How many times the trigger should auto-repeat
vid.FrameGrabInterval = 1; %This allows to acquire 1 every n frames, use if MATLAB
% can't keep up with the stream

src = getselectedsource(vid); % Creates video source object, this holds the camera
%settings, feel free to adjust any settings
src.ExposureTime = 200; % Adjust exposure time (in milliseconds)
src.Gain = 0; % Adjust gain, increases sensor light sensitivity, but be cautious
%as an increased gain will introduce more noise
src.BlackLevel = 0; % Adjust black level, increase this if there is much
%background noise in the dark areas
src.Gamma = 1; % Adjust gamma correction, typically set to 1 for linear response,
%can adjust for brightness/contrast


%% Note on triggers:
% To acquire data, a video input object must execute a trigger.
% Triggers can occur in several ways, depending on how the TriggerType property is
%configured.
% For example, if you specify an immediate trigger, the object executes a trigger
%automatically, immediately after it starts.
% If you specify a manual trigger, the object waits for a call to the trigger
%function before it initiates data acquisition.


%% Acquire frames
figure
counter = 0;
while counter < 100
    start(vid) % Start the video stream
    trigger(vid) % Triggers the camera, also stops the video stream after all
    %frames are captures
    data = getdata(vid); % Load the frame data into an array containing the
    %brightness of each pixel




    imshow(data(:,:,1),[0 4096]) % Displays the first frame in the triggered
    %series. The second argument [0 4096] sets the grayscale display range, i.e. the
    %pixel value that will be displayed as black (0 in this case) and the pixel value
    %that will be displayed as white (4069 in this case).
    drawnow % Update figure
    counter = counter + 1;
end

%% Clean up
delete(vid)
