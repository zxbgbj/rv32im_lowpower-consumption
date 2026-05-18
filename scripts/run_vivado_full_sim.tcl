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
launch_simulation
run all
close_sim
puts "Behavioral simulation finished. Inspect the waveform and transcript in Vivado."
