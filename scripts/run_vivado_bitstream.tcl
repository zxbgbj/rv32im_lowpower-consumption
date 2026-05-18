set origin_dir [file normalize [file dirname [info script]]]
set project_root [file normalize [file join $origin_dir ..]]
set proj_file [file join $project_root vivado_proj rv32im_low_power_zynq7000.xpr]
set reports_dir [file join $project_root reports]
set bit_dir [file join $project_root bitstreams]
file mkdir $reports_dir
file mkdir $bit_dir

source [file join $origin_dir create_vivado_project.tcl]

update_compile_order -fileset sources_1
reset_run synth_1
reset_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
open_run impl_1

report_timing_summary -delay_type max -report_unconstrained -file [file join $reports_dir impl_timing_summary.rpt]
report_utilization -file [file join $reports_dir impl_utilization.rpt]
report_power -file [file join $reports_dir impl_power_vectorless.rpt]
report_drc -file [file join $reports_dir impl_drc.rpt]

set bit_file [file join $project_root vivado_proj rv32im_low_power_zynq7000.runs impl_1 cpu_fpga_top.bit]
if {[file exists $bit_file]} {
    file copy -force $bit_file [file join $bit_dir cpu_fpga_top_v5.bit]
}

puts "Bitstream finished. Reports are under $reports_dir"
puts "Bitstream copy: [file join $bit_dir cpu_fpga_top_v5.bit]"
