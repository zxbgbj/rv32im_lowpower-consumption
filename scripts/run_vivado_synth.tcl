set origin_dir [file normalize [file dirname [info script]]]
set project_root [file normalize [file join $origin_dir ..]]
set proj_file [file join $project_root vivado_proj rv32im_low_power_zynq7000.xpr]
set reports_dir [file join $project_root reports]
file mkdir $reports_dir

if {![file exists $proj_file]} {
    source [file join $origin_dir create_vivado_project.tcl]
} else {
    open_project $proj_file
}

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
open_run synth_1
check_timing
report_timing_summary -delay_type max -report_unconstrained -file [file join $reports_dir synth_timing_summary.rpt]
report_utilization -file [file join $reports_dir synth_utilization.rpt]
puts "Synthesis finished. Reports are under $reports_dir"
