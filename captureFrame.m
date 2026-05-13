function img = captureFrame(vid)
    % Capture a single frame from the camera
    
    % Trigger the camera to take a picture
    trigger(vid);
    
    % Wait until the frame is actually ready (timeout after 5 seconds)
    tstart = tic;
    while vid.FramesAvailable == 0
        pause(0.01);
        if toc(tstart) > 5
            error('Camera timed out waiting for a frame.');
        end
    end
    
    % Get the frame data
    img = getdata(vid, 1);
    
    % Some setups return a struct, we just need the image data
    if isstruct(img) && isfield(img, 'cdata')
        img = img.cdata;
    end
end
