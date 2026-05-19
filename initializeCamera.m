function [vid, src] = initializeCamera(exposureTime, gainValue)
    % Connect to the Basler camera
    
    disp('Resetting imaging module...');
    imaqreset; 
    
    disp('Connecting to camera...');
    vid = videoinput("gentl", 1, "Mono12"); 
    
    % Set the camera to take one picture at a time
    triggerconfig(vid, 'immediate'); 
    vid.FramesPerTrigger = 1; 
    vid.TriggerRepeat = 0; 
    vid.FrameGrabInterval = 1; 
    
    % Set the camera settings
    src = getselectedsource(vid); 
    src.ExposureTime = exposureTime;
    src.Gain = gainValue;
    src.BlackLevel = 0; 
    src.Gamma = 1; 
    
    disp('Camera initialized and ready to capture frames.');
end
