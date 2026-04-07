###############################################################################
# Created by write_sdc
###############################################################################
current_design prob155_perf_top
###############################################################################
# Timing Constraints
###############################################################################
create_clock -name core_clock -period 10.0000 [get_ports {clk}]
set_input_delay 2.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {areset}]
set_input_delay 2.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {bump_left}]
set_input_delay 2.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {bump_right}]
set_input_delay 2.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {dig}]
set_input_delay 2.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {ground}]
set_output_delay 2.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {aaah}]
set_output_delay 2.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {digging}]
set_output_delay 2.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {walk_left}]
set_output_delay 2.0000 -clock [get_clocks {core_clock}] -add_delay [get_ports {walk_right}]
###############################################################################
# Environment
###############################################################################
###############################################################################
# Design Rules
###############################################################################
