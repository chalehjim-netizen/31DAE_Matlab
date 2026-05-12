%% f:Initialization
clearvars
PYNQ_obj = PYNQ_LIB.PYNQ_ML;

PYNQ_obj.ADC_Ext_initialize;
motor = PYNQ_LIB.PYNQ_StepMot(PYNQ_obj);


PYNQ_obj.ADC_Ext_set("A0TG",1,1); 

%% Parameters
num_positions = 20; % # distances to set
steps_per_move = 1000; % steps
num_repeats = 10; % samples per position
step_to_m = 1e-6; 
r0 = 0.13; % distance from lamp to detector

%% Data storage
physical_distances = zeros(1, num_positions);
avg_voltages = zeros(1, num_positions);
sem_voltages = zeros(1, num_positions);

%% Measurements
for i = 1:num_positions
    % move motor to new distance
    if i > 1
        motor.startMoving(0, 1000, steps_per_move); % Direction, frequency, steps
    end

    
    % note current physical distance r = r0 + moved_distance
    physical_distances(i) = r0 + ((i-1) * steps_per_move * step_to_m);
    
    % acquire 10 voltage samples at this distance
    v_data = zeros(1, num_repeats);
    for j = 1:num_repeats
        v_data(j) = PYNQ_obj.ADC_Ext_read; % reads V
        pause(0.05); % delay to get independent samples
    end
    
    % statistical analysis for every pos
    avg_voltages(i) = mean(v_data);
    sem_voltages(i) = std(v_data) / sqrt(num_repeats);
end

%% Fitting
% custom fittype for 1/r^2 law: y = a / x^2
%ft = fittype('a / x^2');
%[f_result, gof] = fit(physical_distances', avg_voltages', ft, 'StartPoint', 1);

%% Plot with error bars
figure;
errorbar(physical_distances, avg_voltages, sem_voltages, 'bo', 'DisplayName', 'Averaged Data');
hold on;
plot(physical_distances, avg_voltages, 'bo');
xlabel('Distance r (m)');
ylabel('Irradiance (Detector Voltage V)');
title('Verification of Inverse Square Law (1/r^2)');
legend('show');
grid on;
%% Data storage
data = table(physical_distances.', avg_voltages.', ...
          'VariableNames', {'Position_steps','Voltage_V'});
writetable(data, 'inverselaw_final.csv');