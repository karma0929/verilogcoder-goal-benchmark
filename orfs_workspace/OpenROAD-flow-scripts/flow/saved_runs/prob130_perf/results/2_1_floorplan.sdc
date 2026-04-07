###############################################################################
# Created by write_sdc
###############################################################################
current_design prob130_perf_top
###############################################################################
# Timing Constraints
###############################################################################
create_clock -name virtual_clk -period 10.0000 
set_input_delay 2.0000 -clock [get_clocks {virtual_clk}] -add_delay [get_ports {a[0]}]
set_input_delay 2.0000 -clock [get_clocks {virtual_clk}] -add_delay [get_ports {a[1]}]
set_input_delay 2.0000 -clock [get_clocks {virtual_clk}] -add_delay [get_ports {a[2]}]
set_input_delay 2.0000 -clock [get_clocks {virtual_clk}] -add_delay [get_ports {a[3]}]
set_input_delay 2.0000 -clock [get_clocks {virtual_clk}] -add_delay [get_ports {b[0]}]
set_input_delay 2.0000 -clock [get_clocks {virtual_clk}] -add_delay [get_ports {b[1]}]
set_input_delay 2.0000 -clock [get_clocks {virtual_clk}] -add_delay [get_ports {b[2]}]
set_input_delay 2.0000 -clock [get_clocks {virtual_clk}] -add_delay [get_ports {b[3]}]
set_input_delay 2.0000 -clock [get_clocks {virtual_clk}] -add_delay [get_ports {c[0]}]
set_input_delay 2.0000 -clock [get_clocks {virtual_clk}] -add_delay [get_ports {c[1]}]
set_input_delay 2.0000 -clock [get_clocks {virtual_clk}] -add_delay [get_ports {c[2]}]
set_input_delay 2.0000 -clock [get_clocks {virtual_clk}] -add_delay [get_ports {c[3]}]
set_input_delay 2.0000 -clock [get_clocks {virtual_clk}] -add_delay [get_ports {d[0]}]
set_input_delay 2.0000 -clock [get_clocks {virtual_clk}] -add_delay [get_ports {d[1]}]
set_input_delay 2.0000 -clock [get_clocks {virtual_clk}] -add_delay [get_ports {d[2]}]
set_input_delay 2.0000 -clock [get_clocks {virtual_clk}] -add_delay [get_ports {d[3]}]
set_input_delay 2.0000 -clock [get_clocks {virtual_clk}] -add_delay [get_ports {e[0]}]
set_input_delay 2.0000 -clock [get_clocks {virtual_clk}] -add_delay [get_ports {e[1]}]
set_input_delay 2.0000 -clock [get_clocks {virtual_clk}] -add_delay [get_ports {e[2]}]
set_input_delay 2.0000 -clock [get_clocks {virtual_clk}] -add_delay [get_ports {e[3]}]
set_output_delay 2.0000 -clock [get_clocks {virtual_clk}] -add_delay [get_ports {q[0]}]
set_output_delay 2.0000 -clock [get_clocks {virtual_clk}] -add_delay [get_ports {q[1]}]
set_output_delay 2.0000 -clock [get_clocks {virtual_clk}] -add_delay [get_ports {q[2]}]
set_output_delay 2.0000 -clock [get_clocks {virtual_clk}] -add_delay [get_ports {q[3]}]
###############################################################################
# Environment
###############################################################################
###############################################################################
# Design Rules
###############################################################################
