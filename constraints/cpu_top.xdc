create_clock -name sys_clk -period 10.000 [get_ports clk]
set_input_delay -clock [get_clocks sys_clk] 2.000 [get_ports rst]
set_false_path -from [get_ports rst]
