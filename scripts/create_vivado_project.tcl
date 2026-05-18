set origin_dir [file normalize [file dirname [info script]]]
set project_root [file normalize [file join $origin_dir ..]]
set rtl_dir [file join $project_root rtl]
set tb_dir [file join $project_root tb]
set constr_dir [file join $project_root constraints]
set generated_dir [file join $project_root verification generated]
set proj_dir [file join $project_root vivado_proj]

cd $project_root

create_project rv32im_low_power_zynq7000 $proj_dir -part xc7z020clg400-1 -force
set_property target_language Verilog [current_project]
set_property default_lib xil_defaultlib [current_project]

set rtl_files [glob -nocomplain [file join $rtl_dir *.v]]
if {[llength $rtl_files] == 0} {
    error "No RTL files found under $rtl_dir"
}
foreach rtl_file $rtl_files {
    add_files [file join rtl [file tail $rtl_file]]
}

set tb_files [glob -nocomplain [file join $tb_dir tb_*.v]]
if {[llength $tb_files] > 0} {
    foreach tb_file $tb_files {
        add_files -fileset sim_1 [file join tb [file tail $tb_file]]
    }
}

set board_xdc [file join constraints alientek_pioneer_zynq_v2_board.xdc]
if {[file exists [file join $project_root $board_xdc]]} {
    add_files -fileset constrs_1 $board_xdc
} else {
    add_files -fileset constrs_1 [file join constraints cpu_top.xdc]
}
set smoke_hex [file join verification generated smoke_tohost.hex]
if {[file exists [file join $project_root $smoke_hex]]} {
    add_files -fileset sources_1 $smoke_hex
}
if {[file exists [file join $rtl_dir cpu_fpga_top.v]]} {
    set_property top cpu_fpga_top [current_fileset]
} else {
    set_property top cpu_top [current_fileset]
}
if {[llength $tb_files] > 0} {
    set_property top tb_cpu_top [get_filesets sim_1]
}

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Project created at: $proj_dir"
puts "RTL count: [llength $rtl_files]"
puts "TB count: [llength $tb_files]"
