function img = captureFrame(vid)
% captureFrame  Acquire a single frame from a video input object
%   img = captureFrame(vid) triggers the camera associated with `vid`
%   and returns one frame. Throws an error on timeout or invalid input.

if nargin < 1 || isempty(vid)
    error('captureFrame:MissingInput','`vid` video input object is required.');
end

if ~isvalid(vid)
    error('captureFrame:InvalidVid','Provided video input object is not valid.');
end

% Trigger acquisition
trigger(vid);

% Wait for a frame to become available (timeout protection)
timeout = 5; % seconds
tstart = tic;
while vid.FramesAvailable == 0
    pause(0.01);
    if toc(tstart) > timeout
        error('captureFrame:Timeout','Timed out waiting for a frame from camera.');
    end
end

% Retrieve one frame
img = getdata(vid,1);

% Some setups return a struct with cdata
if isstruct(img) && isfield(img,'cdata')
    img = img.cdata;
end

end
