function sharpness = computeSharpness(img)
% Convert to double
img = double(img);

% Sobel filters
Gx = imfilter(img, fspecial('sobel')'/8, 'replicate');
Gy = imfilter(img, fspecial('sobel')/8, 'replicate');

% Gradient magnitude
G = sqrt(Gx.^2 + Gy.^2);

% Tenengrad sharpness metric
sharpness = sum(G(:).^2);

end