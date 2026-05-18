set origin_dir [file normalize [file dirname [info script]]]
if {[info exists ::env(PROJECT_ROOT_OVERRIDE)] && $::env(PROJECT_ROOT_OVERRIDE) ne ""} {
    set project_root [file normalize $::env(PROJECT_ROOT_OVERRIDE)]
} else {
    set project_root [file normalize [file join $origin_dir ..]]
}
set proj_file [file join $project_root vivado_proj rv32im_low_power_zynq7000.xpr]
set reports_dir [file join $project_root reports]
file mkdir $reports_dir

if {[info exists ::env(POWER_REPORT_PREFIX)] && $::env(POWER_REPORT_PREFIX) ne ""} {
    set report_prefix $::env(POWER_REPORT_PREFIX)
} else {
    set report_prefix "impl_power"
}

set power_vcd_file ""
if {[info exists ::env(POWER_VCD_FILE)] && $::env(POWER_VCD_FILE) ne ""} {
    set power_vcd_file [file normalize $::env(POWER_VCD_FILE)]
}

set power_vcd_scope ""
if {[info exists ::env(POWER_VCD_SCOPE)] && $::env(POWER_VCD_SCOPE) ne ""} {
    set power_vcd_scope $::env(POWER_VCD_SCOPE)
}

set power_vcd_strip_path ""
if {[info exists ::env(POWER_VCD_STRIP_PATH)] && $::env(POWER_VCD_STRIP_PATH) ne ""} {
    set power_vcd_strip_path $::env(POWER_VCD_STRIP_PATH)
}

if {![file exists $proj_file]} {
    source [file join $origin_dir create_vivado_project.tcl]
} else {
    open_project $proj_file
}

update_compile_order -fileset sources_1
set impl_status [get_property STATUS [get_runs impl_1]]
if {[string match "*Running*" $impl_status]} {
    wait_on_run impl_1
} elseif {![string match "*route_design Complete*" $impl_status]} {
    catch {launch_runs impl_1 -to_step route_design -jobs 4}
    wait_on_run impl_1
}
open_run impl_1

if {$power_vcd_file ne ""} {
    if {![file exists $power_vcd_file]} {
        error "VCD file not found: $power_vcd_file"
    }
    if {$power_vcd_scope ne "" && $power_vcd_strip_path ne ""} {
        read_vcd -scope $power_vcd_scope -strip_path $power_vcd_strip_path $power_vcd_file
    } elseif {$power_vcd_scope ne ""} {
        read_vcd -scope $power_vcd_scope $power_vcd_file
    } elseif {$power_vcd_strip_path ne ""} {
        read_vcd -strip_path $power_vcd_strip_path $power_vcd_file
    } else {
        read_vcd $power_vcd_file
    }
}

report_power -file [file join $reports_dir "${report_prefix}.rpt"] \
             -pb [file join $reports_dir "${report_prefix}.pb"] \
             -rpx [file join $reports_dir "${report_prefix}.rpx"]
puts "Power report finished. Reports are under $reports_dir"
