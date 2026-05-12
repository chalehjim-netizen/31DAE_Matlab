function bestPos = findBestFocus(positions, sharpnessValues)
% findBestFocus  Return the position corresponding to maximum sharpness
%   bestPos = findBestFocus(positions, sharpnessValues)
%   Performs a small smoothing of the sharpness curve and returns the
%   `positions` entry with the highest (smoothed) sharpness.

if nargin < 2
    error('findBestFocus:NotEnoughInputs','Require positions and sharpnessValues.');
end

if isempty(positions) || isempty(sharpnessValues)
    error('findBestFocus:EmptyInputs','Inputs must be non-empty arrays.');
end

% Ensure column vectors
positions = positions(:);
sharpnessValues = sharpnessValues(:);

% Slight smoothing to reduce single-point noise (window=3)
if numel(sharpnessValues) >= 3
    s = movmean(sharpnessValues, 3);
else
    s = sharpnessValues;
end

[~, idx] = max(s);
bestPos = positions(idx);

end
