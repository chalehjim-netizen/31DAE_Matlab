function [PYNQ_obj, StepMot] = initializePynqBoard()
    % Initialize PYNQ board and stepper motor
    
    disp('Connecting to the PYNQ board...');
    PYNQ_obj = PYNQ_LIB.PYNQ_ML;
    
    % Initialize ADC (if needed for later)
    PYNQ_obj.ADC_Ext_initialize();
    PYNQ_obj.ADC_Ext_set("A0TG", 1, 1);
    
    % Create the Stepper motor object
    disp('Initializing stepper motor...');
    StepMot = PYNQ_LIB.PYNQ_StepMot(PYNQ_obj);
    
    disp('Initialization done.');
end
