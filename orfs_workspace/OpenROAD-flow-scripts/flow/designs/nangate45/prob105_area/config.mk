export PLATFORM         = nangate45
export DESIGN_NAME      = prob105_area_top
export VERILOG_FILES    = ./designs/nangate45/prob105_area/wrapper.sv /workspace/benchmark/prob105_rotate100/src/top_area.sv
export SDC_FILE         = ./designs/nangate45/prob105_area/constraint.sdc

export DIE_AREA         = 0 0 40 40
export CORE_AREA        = 2 2 38 38
export PLACE_DENSITY    = 0.40
export TNS_END_PERCENT  = 100
