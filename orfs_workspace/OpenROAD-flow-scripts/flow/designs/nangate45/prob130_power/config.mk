export PLATFORM         = nangate45
export DESIGN_NAME      = prob130_power_top
export VERILOG_FILES    = ./designs/nangate45/prob200_power/wrapper.sv ./designs/nangate45/prob200_power/top_ref_synth.sv
export SDC_FILE         = ./designs/nangate45/prob130_power/constraint.sdc

export DIE_AREA         = 0 0 80 80
export CORE_AREA        = 4 4 76 76
export PLACE_DENSITY    = 0.55
export TNS_END_PERCENT  = 100
