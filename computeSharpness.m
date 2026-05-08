function sharpness = computeSharpness(img)
    %% Convert to double
        img = double(img);
    %% Sobel operators
        S_x = [-1 0 1; -2 0 2; -1 0 1]*(1/8)
        S_y = [1 2 1; 0 0 0; -1 -2 -1]*(1/8)

    %% Sobel filters
        G_x = S_x * img
        G_y = S_y * img

    %% Tenengrad sharpness operator
        G = sqrt(G_x.^2 + G_y.^2);
        sharpness = sum(G(:).^2);

end