function sharpness = computeSharpness(img)
    % Calculate the Tenengrad sharpness of an image
    
    % Make sure the image is grayscale
    if ndims(img) == 3 && size(img,3) == 3
        img = rgb2gray(img);
    end
    
    img = double(img);
    
    % Apply a small blur to remove camera noise before calculating sharpness
    h = fspecial('gaussian', [5 5], 1.0);
    img_smooth = imfilter(img, h, 'replicate');
    
    % Define the Sobel filters (these detect edges)
    S_x = [-1 0 1; -2 0 2; -1 0 1] / 8;
    S_y = S_x';
    
    % Find edges in X and Y directions
    G_x = imfilter(img_smooth, S_x, 'replicate');
    G_y = imfilter(img_smooth, S_y, 'replicate');
    
    % Tenengrad calculates the squared magnitude of the edges
    G_sq = G_x.^2 + G_y.^2;
    
    % Average it so the score doesn't depend on image size
    sharpness = mean(G_sq(:));
end