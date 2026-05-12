%% f:Initialization
clearvars
PYNQ_obj = PYNQ_LIB.PYNQ_ML;

PYNQ_obj.ADC_Ext_initialize;
motor = PYNQ_LIB.PYNQ_StepMot(PYNQ_obj);

motor.startMoving(0, 1000, 50000); % Direction, frequency, steps