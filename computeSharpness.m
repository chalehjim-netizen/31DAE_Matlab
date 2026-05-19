function sharpness = computeSharpness(img)
    % Calculate how sharp the picture is
    
    % Convert to grayscale if needed
    if ndims(img) == 3 && size(img,3) == 3
        img = rgb2gray(img);
    end
    
    img = double(img);
    
    % Slightly blur the image to remove camera noise
    h = fspecial('gaussian', [5 5], 1.0);
    img_smooth = imfilter(img, h, 'replicate');
    
    % Detect edges in the image
    S_x = [-1 0 1; -2 0 2; -1 0 1] / 8;
    S_y = S_x';
    
    G_x = imfilter(img_smooth, S_x, 'replicate');
    G_y = imfilter(img_smooth, S_y, 'replicate');
    
    % Combine the edges to get a score
    G_sq = G_x.^2 + G_y.^2;
    
    % Average the score over the whole image (Tenengrand)
    sharpness = mean(G_sq(:));
end