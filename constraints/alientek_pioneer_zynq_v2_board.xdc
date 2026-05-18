## ALIENTEK Pioneer ZYNQ V2 board-level constraints
## Sources used for pin mapping:
## - Official ALIENTEK product/download portal
## - ALIENTEK UART experiment guide (sys_clk U18, sys_rst_n N16, uart_rxd K14, uart_txd M15)
## - ALIENTEK LED experiment guide (PL LED0 H15)

create_clock -name sys_clk -period 20.000 [get_ports clk]

set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports clk]
set_property -dict {PACKAGE_PIN N16 IOSTANDARD LVCMOS33} [get_ports rst]
set_property -dict {PACKAGE_PIN K14 IOSTANDARD LVCMOS33} [get_ports uart_rx]
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS33} [get_ports uart_tx]
set_property -dict {PACKAGE_PIN H15 IOSTANDARD LVCMOS33} [get_ports heartbeat_led]

set_false_path -from [get_ports rst]
