## Optional PL-side reset/debug UART/LED for the PS+PL benchmark build.
## PS DDR/FIXED_IO are handled by the Processing System block design.

set_property PACKAGE_PIN N16 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

set_property PACKAGE_PIN K14 [get_ports pl_uart_rx]
set_property IOSTANDARD LVCMOS33 [get_ports pl_uart_rx]

set_property PACKAGE_PIN M15 [get_ports pl_uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports pl_uart_tx]

set_property PACKAGE_PIN H15 [get_ports heartbeat_led]
set_property IOSTANDARD LVCMOS33 [get_ports heartbeat_led]
