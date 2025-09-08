##file: uart-alu-8bit.scd
##
##Author: JChirino

## Clock
set_units -time ns
create_clock [get_ports i_clk]  -name core_clock  -period 100

set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports { i_clk }];
#create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { i_clk }];


## Reset
#set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports { i_reset }];

##USB-RS232 

#set_property -dict { PACKAGE_PIN B18    IOSTANDARD LVCMOS33 } [get_ports { i_uartRx }]; 
#set_property -dict { PACKAGE_PIN A18    IOSTANDARD LVCMOS33 } [get_ports { o_uartTx }]; 


## Leds

#set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports { result_leds[0] }]; 
#set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS33 } [get_ports { result_leds[1] }]; 
#set_property -dict { PACKAGE_PIN U19 IOSTANDARD LVCMOS33 } [get_ports { result_leds[2] }]; 
#set_property -dict { PACKAGE_PIN V19 IOSTANDARD LVCMOS33 } [get_ports { result_leds[3] }]; 
#set_property -dict { PACKAGE_PIN W18 IOSTANDARD LVCMOS33 } [get_ports { result_leds[4] }]; 
#set_property -dict { PACKAGE_PIN U15 IOSTANDARD LVCMOS33 } [get_ports { result_leds[5] }]; 
#set_property -dict { PACKAGE_PIN U14 IOSTANDARD LVCMOS33 } [get_ports { result_leds[6] }]; 
#set_property -dict { PACKAGE_PIN V14 IOSTANDARD LVCMOS33 } [get_ports { result_leds[7] }]; 
