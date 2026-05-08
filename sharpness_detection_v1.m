%% Sobel operators
S_x = [-1 0 1; -2 0 2; -1 0 1]*(1/8)
S_y = [1 2 1; 0 0 0; -1 -2 -1]*(1/8)

%% Sobel filters
G_x = S_x * data


%% finding peak positions
thld = 0.1; %a threshold to make up for background noise
middle = y_data(2:end-1); %voltage values except for ends

% neighbours of each point 
% 'left' is points 1 to N-2. 'right' is points 3 to N.
left_neighbors  = y_data(1:end-2); 
right_neighbors = y_data(3:end);

% compare values to their neighbours to find if it's a peak!
is_peak = (middle > left_neighbors) & ...
          (middle > right_neighbors) & ...
          (middle > thld);

% REMEMBER! we ignored the end values so our first value in "middle" is the second element!
locs = find(is_peak) + 1;

% corresponding positions
pks = y_data(locs);
peak_positions = x_data(locs);