set origin_dir [file normalize [file dirname [info script]]]
set project_root [file normalize [file join $origin_dir ..]]
set reports_dir [file join $project_root reports]
set bit_dir [file join $project_root bitstreams]
set artifacts_dir [file join $project_root artifacts]

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
        set top_module cpu_pspl_coremark_top
        set bit_copy_name cpu_pspl_coremark_${freq_tag}.bit
    }
    "matrix" -
    "matrix_mul" {
        set board_bench "matrix"
        set top_module cpu_pspl_matrix_top
        set bit_copy_name cpu_pspl_matrix_${freq_tag}.bit
    }
    default {
        error "Unsupported board benchmark '$board_bench'."
    }
}

file mkdir $reports_dir
file mkdir $bit_dir
file mkdir $artifacts_dir

set argv [list $board_bench $freq_mhz $freq_tag]
set argc [llength $argv]
source [file join $origin_dir create_pspl_vivado_project.tcl]

if {$freq_mhz >= 90.0} {
    puts "Applying high-frequency implementation strategy for ${freq_mhz} MHz build"
    set_property strategy Flow_PerfOptimized_high [get_runs synth_1]
    set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]
    set_property STEPS.OPT_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
    set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE Explore [get_runs impl_1]
    set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
    set_property STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore [get_runs impl_1]
    set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE MoreGlobalIterations [get_runs impl_1]
    set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
    set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.ARGS.DIRECTIVE AggressiveExplore [get_runs impl_1]
}

reset_run synth_1
reset_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
open_run impl_1

if {$freq_tag eq "80m"} {
    set timing_report_name pspl_${board_bench}_impl_timing_summary.rpt
    set util_report_name pspl_${board_bench}_impl_utilization.rpt
    set power_report_name pspl_${board_bench}_impl_power_vectorless.rpt
    set drc_report_name pspl_${board_bench}_impl_drc.rpt
} else {
    set timing_report_name pspl_${board_bench}_${freq_tag}_impl_timing_summary.rpt
    set util_report_name pspl_${board_bench}_${freq_tag}_impl_utilization.rpt
    set power_report_name pspl_${board_bench}_${freq_tag}_impl_power_vectorless.rpt
    set drc_report_name pspl_${board_bench}_${freq_tag}_impl_drc.rpt
}

report_timing_summary -delay_type max -report_unconstrained -file [file join $reports_dir $timing_report_name]
report_utilization -file [file join $reports_dir $util_report_name]
report_power -file [file join $reports_dir $power_report_name]
report_drc -file [file join $reports_dir $drc_report_name]

set proj_dir [file join $project_root vivado_pspl_proj]
set bit_file [file join $proj_dir rv32im_low_power_pspl_${board_bench}_${freq_tag}.runs impl_1 ${top_module}.bit]

if {[file exists $bit_file]} {
    file copy -force $bit_file [file join $bit_dir $bit_copy_name]
}

puts "PS+PL bitstream finished for $board_bench"
puts "Clock         : ${freq_mhz} MHz (${freq_tag})"
puts "Bitstream copy : [file join $bit_dir $bit_copy_name]"
