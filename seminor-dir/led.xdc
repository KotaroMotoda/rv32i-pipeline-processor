## Configuration options
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

## Clock signal
# 100 MHz clock
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { CLK }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {CLK}];

## Reset
set_property -dict { PACKAGE_PIN C12   IOSTANDARD LVCMOS33 } [get_ports { RSTN }];

## LEDs
# Mapping WB_RD_VAL[0:15] to LD0-LD15
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { WB_RD_VAL[0] }];  # LD0
set_property -dict { PACKAGE_PIN K15   IOSTANDARD LVCMOS33 } [get_ports { WB_RD_VAL[1] }];  # LD1
set_property -dict { PACKAGE_PIN J13   IOSTANDARD LVCMOS33 } [get_ports { WB_RD_VAL[2] }];  # LD2
set_property -dict { PACKAGE_PIN N14   IOSTANDARD LVCMOS33 } [get_ports { WB_RD_VAL[3] }];  # LD3
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports { WB_RD_VAL[4] }];  # LD4
set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports { WB_RD_VAL[5] }];  # LD5
set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports { WB_RD_VAL[6] }];  # LD6
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33 } [get_ports { WB_RD_VAL[7] }];  # LD7
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports { WB_RD_VAL[8] }];  # LD8
set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS33 } [get_ports { WB_RD_VAL[9] }];  # LD9
set_property -dict { PACKAGE_PIN U14   IOSTANDARD LVCMOS33 } [get_ports { WB_RD_VAL[10] }]; # LD10
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { WB_RD_VAL[11] }]; # LD11
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { WB_RD_VAL[12] }]; # LD12
set_property -dict { PACKAGE_PIN V14   IOSTANDARD LVCMOS33 } [get_ports { WB_RD_VAL[13] }]; # LD13
set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports { WB_RD_VAL[14] }]; # LD14
set_property -dict { PACKAGE_PIN V11   IOSTANDARD LVCMOS33 } [get_ports { WB_RD_VAL[15] }]; # LD15
