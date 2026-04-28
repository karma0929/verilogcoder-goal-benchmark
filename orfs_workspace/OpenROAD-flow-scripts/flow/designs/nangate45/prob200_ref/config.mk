export PLATFORM         = nangate45
export DESIGN_NAME      = prob200_ref_top
export VERILOG_FILES    = ./designs/nangate45/prob200_ref/wrapper.sv ./designs/nangate45/prob200_ref/top_ref_synth.sv
export SDC_FILE         = ./designs/nangate45/prob200_ref/constraint.sdc

export DIE_AREA         = 0 0 250 250
export CORE_AREA        = 10 10 240 240
export PLACE_DENSITY    = 0.55
export TNS_END_PERCENT  = 100