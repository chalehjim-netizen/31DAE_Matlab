function [vid, src] = initializeCamera(exposureTime, gainValue)
    % Sets up the Basler monochrome camera for our autofocus experiment
    
    disp('Resetting imaging module...');
    imaqreset; 
    
    disp('Connecting to camera...');
    vid = videoinput("gentl", 1, "Mono12"); 
    
    % Set it up so we capture exactly one frame when we start the camera
    triggerconfig(vid, 'immediate'); 
    vid.FramesPerTrigger = 1; 
    vid.TriggerRepeat = 0; % Do not repeat, automatically stop after 1 frame
    vid.FrameGrabInterval = 1; 
    
    % Get the source object so we can adjust hardware settings
    src = getselectedsource(vid); 
    
    % Apply camera settings directly
    src.ExposureTime = exposureTime;
    src.Gain = gainValue;
    src.BlackLevel = 0; 
    src.Gamma = 1; 
    
    % Do NOT start(vid) here. We will start it on-demand in captureFrame
    % to prevent the camera from filling up the RAM with continuous streaming.
    
    disp('Camera initialized and ready to capture frames.');
end
