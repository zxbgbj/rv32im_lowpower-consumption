set origin_dir [file normalize [file dirname [info script]]]
set project_root [file normalize [file join $origin_dir ..]]
set rtl_dir [file join $project_root rtl]
set constr_dir [file join $project_root constraints]
set proj_dir [file join $project_root vivado_pspl_proj]
set ip_dir [file join $proj_dir ip]

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

if {![string length [string trim $freq_tag]]} {
    set freq_tag [string map {. ""} [format "%.1fm" $freq_mhz]]
}

switch -- $board_bench {
    "coremark" {
        set top_module cpu_pspl_coremark_top
    }
    "matrix" -
    "matrix_mul" {
        set board_bench "matrix"
        set top_module cpu_pspl_matrix_top
    }
    default {
        error "Unsupported board benchmark '$board_bench'. Use coremark or matrix."
    }
}

cd $project_root
if {[file exists $proj_dir]} {
    file delete -force $proj_dir
}
create_project rv32im_low_power_pspl_${board_bench}_${freq_tag} $proj_dir -part xc7z020clg400-1 -force
set_property target_language Verilog [current_project]
set_property default_lib xil_defaultlib [current_project]
file mkdir $ip_dir

set rtl_files [glob -nocomplain [file join $rtl_dir *.v]]
foreach rtl_file $rtl_files {
    add_files [list $rtl_file]
}

add_files -fileset constrs_1 [list [file join $constr_dir alientek_pioneer_zynq_v2_pspl.xdc]]

create_ip -name processing_system7 -vendor xilinx.com -library ip -version 5.5 -module_name processing_system7_0 -dir $ip_dir
set ps7_xci [file join $ip_dir processing_system7_0 processing_system7_0.xci]
set_property -dict [list \
    CONFIG.PCW_USE_DEFAULT_ACP_USER_VAL {1} \
    CONFIG.PCW_EN_CLK0_PORT {1} \
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ $freq_mhz \
    CONFIG.PCW_UART0_PERIPHERAL_ENABLE {0} \
    CONFIG.PCW_UART1_PERIPHERAL_ENABLE {1} \
    CONFIG.PCW_UART1_UART1_IO {MIO 48 .. 49} \
    CONFIG.PCW_GPIO_EMIO_GPIO_ENABLE {1} \
    CONFIG.PCW_GPIO_EMIO_GPIO_IO {64} \
] [get_ips processing_system7_0]
generate_target all [get_files [list $ps7_xci]]
export_ip_user_files -of_objects [get_files [list $ps7_xci]] -no_script -sync -force -quiet
create_ip -name proc_sys_reset -vendor xilinx.com -library ip -version 5.0 -module_name proc_sys_reset_0 -dir $ip_dir
set ps_reset_xci [file join $ip_dir proc_sys_reset_0 proc_sys_reset_0.xci]
generate_target all [get_files [list $ps_reset_xci]]
export_ip_user_files -of_objects [get_files [list $ps_reset_xci]] -no_script -sync -force -quiet

update_compile_order -fileset sources_1
set_property top $top_module [current_fileset]

puts "Created direct-instantiation PS+PL project for $board_bench at $proj_dir"
puts "Top module: $top_module"
puts "Clock     : ${freq_mhz} MHz (${freq_tag})"
