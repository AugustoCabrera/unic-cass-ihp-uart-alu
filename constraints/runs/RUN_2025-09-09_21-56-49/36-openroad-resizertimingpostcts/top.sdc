###############################################################################
# Created by write_sdc
###############################################################################
current_design top
###############################################################################
# Timing Constraints
###############################################################################
create_clock -name clk -period 100.0000 
set_clock_uncertainty 0.1500 clk
set_input_delay 20.0000 -clock [get_clocks {clk}] -add_delay [get_ports {i_clk}]
set_input_delay 20.0000 -clock [get_clocks {clk}] -add_delay [get_ports {i_reset}]
set_input_delay 20.0000 -clock [get_clocks {clk}] -add_delay [get_ports {i_uartRx}]
set_output_delay 20.0000 -clock [get_clocks {clk}] -add_delay [get_ports {o_uartTx}]
###############################################################################
# Environment
###############################################################################
set_load -pin_load 0.0334 [get_ports {o_uartTx}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {i_clk}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {i_reset}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {i_uartRx}]
###############################################################################
# Design Rules
###############################################################################
set_max_transition 0.7500 [current_design]
set_max_capacitance 0.2000 [current_design]
set_max_fanout 10.0000 [current_design]
