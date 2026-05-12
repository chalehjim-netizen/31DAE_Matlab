function sharpness = computeSharpness(img)
% computeSharpness  Return Tenengrad sharpness value for an image
%   Applies optional Gaussian smoothing, computes Sobel gradients,
%   and returns the summed gradient energy (Tenengrad metric).

% Convert RGB to grayscale if needed
if ndims(img) == 3 && size(img,3) == 3
    img = rgb2gray(img);
end

img = double(img);

% Small Gaussian smoothing to reduce sensor noise (5x5, sigma=1)
h = fspecial('gaussian', [5 5], 1.0);
img_smooth = imfilter(img, h, 'replicate');

% Sobel kernels (normalized)
S_x = [-1 0 1; -2 0 2; -1 0 1] / 8;
S_y = S_x';

% Compute gradients using convolution
G_x = imfilter(img_smooth, S_x, 'replicate');
G_y = imfilter(img_smooth, S_y, 'replicate');

% Tenengrad: gradient magnitude and sum of squared magnitudes
G = sqrt(G_x.^2 + G_y.^2);
sharpness = sum(G(:).^2);

end