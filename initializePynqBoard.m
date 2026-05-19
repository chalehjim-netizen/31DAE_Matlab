function [PYNQ_obj, StepMot] = initializePynqBoard()
    % Connect to the PYNQ board and motor
    
    disp('Connecting to the PYNQ board...');
    PYNQ_obj = PYNQ_LIB.PYNQ_ML;
    
    % Setup the board settings
    PYNQ_obj.ADC_Ext_initialize();
    PYNQ_obj.ADC_Ext_set("A0TG", 1, 1);
    
    disp('Initializing stepper motor...');
    StepMot = PYNQ_LIB.PYNQ_StepMot(PYNQ_obj);
    
    disp('Initialization done.');
end
