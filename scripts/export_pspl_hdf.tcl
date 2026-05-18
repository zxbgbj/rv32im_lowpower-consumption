set origin_dir [file normalize [file dirname [info script]]]
set project_root [file normalize [file join $origin_dir ..]]
set proj_dir [file join $project_root vivado_pspl_handoff_proj]
set ip_dir [file join $proj_dir ip]
set artifacts_dir [file join $project_root artifacts]
set bit_dir [file join $project_root bitstreams]

set board_bench "coremark"
set freq_mhz 80.0
set freq_tag "80m"
if {$argc >= 1} {
    set board_bench [string tolower [lindex $argv 0]]
}
if {$argc >= 2} {
    set freq_mhz [lindex $argv 1]
}
if {$argc >= 3} {
    set freq_tag [string tolower [lindex $argv 2]]
}

switch -- $board_bench {
    "coremark" {
        set bit_name cpu_pspl_coremark_${freq_tag}.bit
    }
    "matrix" -
    "matrix_mul" {
        set board_bench "matrix"
        set bit_name cpu_pspl_matrix_${freq_tag}.bit
    }
    default {
        error "Unsupported board benchmark '$board_bench'."
    }
}

file mkdir $artifacts_dir

if {[file exists $proj_dir]} {
    file delete -force $proj_dir
}
file mkdir $proj_dir
file mkdir $ip_dir

create_project rv32im_low_power_pspl_handoff_${board_bench}_${freq_tag} $proj_dir -part xc7z020clg400-1 -force
set_property target_language Verilog [current_project]

create_bd_design "pspl_handoff"
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR" apply_board_preset "0" Master "Disable" Slave "Disable"} \
    [get_bd_cells processing_system7_0]

set_property -dict [list \
    CONFIG.PCW_EN_CLK0_PORT {1} \
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ $freq_mhz \
    CONFIG.PCW_USE_M_AXI_GP0 {0} \
    CONFIG.PCW_UART0_PERIPHERAL_ENABLE {0} \
    CONFIG.PCW_UART1_PERIPHERAL_ENABLE {1} \
    CONFIG.PCW_UART1_UART1_IO {MIO 48 .. 49} \
    CONFIG.PCW_GPIO_EMIO_GPIO_ENABLE {1} \
    CONFIG.PCW_GPIO_EMIO_GPIO_IO {64} \
] [get_bd_cells processing_system7_0]

validate_bd_design
save_bd_design
generate_target all [get_files [list [file join $proj_dir rv32im_low_power_pspl_handoff_${board_bench}_${freq_tag}.srcs sources_1 bd pspl_handoff pspl_handoff.bd]]]

if {$freq_tag eq "80m"} {
    set hwdef_file [file join $artifacts_dir pspl_${board_bench}.hwdef]
    set hdf_file [file join $artifacts_dir pspl_${board_bench}.hdf]
} else {
    set hwdef_file [file join $artifacts_dir pspl_${board_bench}_${freq_tag}.hwdef]
    set hdf_file [file join $artifacts_dir pspl_${board_bench}_${freq_tag}.hdf]
}
set bit_file [file join $bit_dir $bit_name]

write_hwdef -force -file $hwdef_file
write_sysdef -force -hwdef $hwdef_file -bitfile $bit_file -file $hdf_file

puts "Generated PS+PL handoff for $board_bench"
puts "Clock : ${freq_mhz} MHz (${freq_tag})"
puts "HWDEF : $hwdef_file"
puts "HDF   : $hdf_file"
