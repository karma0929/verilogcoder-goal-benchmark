export PLATFORM         = nangate45
export DESIGN_NAME      = prob130_area_top
export VERILOG_FILES    = ./designs/nangate45/prob130_area/wrapper.sv /workspace/benchmark/prob130_circuit5/src/top_area.sv
export SDC_FILE         = ./designs/nangate45/prob130_area/constraint.sdc

export DIE_AREA         = 0 0 80 80
export CORE_AREA        = 4 4 76 76
export PLACE_DENSITY    = 0.55
export TNS_END_PERCENT  = 100
