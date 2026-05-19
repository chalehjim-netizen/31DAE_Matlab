function img = captureFrame(vid)
    % Take a single picture
    
    flushdata(vid); % Clear buffer
    
    start(vid);
    
    % Wait up to 5 seconds for the picture
    tstart = tic;
    while vid.FramesAvailable == 0
        pause(0.01);
        if toc(tstart) > 5
            stop(vid);
            error('Camera timeout: Frame acquisition failed.');
        end
    end
    
    img = getdata(vid, 1);
    
    % If the image is a struct, extract the pixel data
    if isstruct(img) && isfield(img, 'cdata')
        img = img.cdata;
    end
end
