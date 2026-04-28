current_design prob240_perf
set clk_port_name clk
set clk_period 5.0
create_clock [get_ports $clk_port_name] -name core_clock -period $clk_period
