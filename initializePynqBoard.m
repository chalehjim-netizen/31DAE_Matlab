function initializePynqBoard()
if var('PYNQ_obj', 'var') == 0
    clearvars; clc; close all;
end

PYNQ_obj = PYNQ_LIB.PYNQ_ML;

PYNQ_obj.ADC_Ext_initialize;
motor = PYNQ_LIB.PYNQ_StepMot(PYNQ_obj);

PYNQ_obj.ADC_Ext_set("A0TG",1,1);


