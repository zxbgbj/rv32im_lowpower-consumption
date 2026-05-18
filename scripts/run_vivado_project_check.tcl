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
report_compile_order -used_in synthesis -file [file join $reports_dir compile_order_synth.rpt]
report_compile_order -used_in simulation -file [file join $reports_dir compile_order_sim.rpt]
launch_simulation -scripts_only
close_sim
puts "Project structure prepared. Review compile-order reports under $reports_dir"
