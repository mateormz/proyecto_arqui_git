## Clock signal
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## VOLTAGE SETUP
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

## Reset button (btnC)
set_property PACKAGE_PIN U18 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

## Switches for display selection
set_property PACKAGE_PIN V17 [get_ports {display_sel[0]}]
set_property PACKAGE_PIN V16 [get_ports {display_sel[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {display_sel[*]}]

## 7-segment display cathodes
set_property PACKAGE_PIN W7 [get_ports {catode[7]}] ;# A
set_property PACKAGE_PIN W6 [get_ports {catode[6]}] ;# B
set_property PACKAGE_PIN U8 [get_ports {catode[5]}] ;# C
set_property PACKAGE_PIN V8 [get_ports {catode[4]}] ;# D
set_property PACKAGE_PIN U5 [get_ports {catode[3]}] ;# E
set_property PACKAGE_PIN V5 [get_ports {catode[2]}] ;# F
set_property PACKAGE_PIN U7 [get_ports {catode[1]}] ;# G
set_property PACKAGE_PIN V7 [get_ports {catode[0]}] ;# P (decimal point)
set_property IOSTANDARD LVCMOS33 [get_ports {catode[*]}]
set_property DRIVE 4 [get_ports {catode[*]}]
set_property SLEW SLOW [get_ports {catode[*]}]

## 7-segment display anodes
set_property PACKAGE_PIN U2 [get_ports {anode[0]}]
set_property PACKAGE_PIN U4 [get_ports {anode[1]}]
set_property PACKAGE_PIN V4 [get_ports {anode[2]}]
set_property PACKAGE_PIN W4 [get_ports {anode[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {anode[*]}]
set_property DRIVE 4 [get_ports {anode[*]}]
set_property SLEW SLOW [get_ports {anode[*]}]