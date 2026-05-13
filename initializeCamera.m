function [vid, src] = initializeCamera(exposureTime, gainValue)
    % Sets up the Basler monochrome camera for our autofocus experiment
    
    disp('Resetting imaging module...');
    imaqreset; 
    
    disp('Connecting to camera...');
    vid = videoinput("gentl", 1, "Mono12"); 
    
    % Set it up so we can manually trigger it from our scan loops
    triggerconfig(vid, 'manual'); 
    vid.FramesPerTrigger = 1; 
    vid.TriggerRepeat = Inf; % Allow us to trigger it as many times as we need
    vid.FrameGrabInterval = 1; 
    
    % Get the source object so we can adjust hardware settings
    src = getselectedsource(vid); 
    
    % Apply camera settings directly
    src.ExposureTime = exposureTime;
    src.Gain = gainValue;
    src.BlackLevel = 0; 
    src.Gamma = 1; 
    
    % Turn the video stream on so it's ready to take pictures
    start(vid);
    
    disp('Camera initialized and ready to capture frames.');
end
