# ModelSim/QuestaSim launcher for rv32im_low-power
# Usage:
#   do run_modelsim_tb.do tb_cpu_top_rv32im_full
#   do run_modelsim_tb.do tb_cpu_top_isa +IMEM_HEX=verification/generated/test.hex +TOHOST_ADDR=80001000
# Note:
#   Use this script directly from the ModelSim Transcript window.
#   The PowerShell wrapper should call run_modelsim_tb.ps1.

transcript on
onbreak {resume}

if {[info exists ::TB_NAME]} {
    set tb_name $::TB_NAME
} else {
    set tb_name tb_cpu_top
}
if {[info exists ::EXTRA_ARGS] && [string length [string trim $::EXTRA_ARGS]] > 0} {
    set extra_args [split [string trim $::EXTRA_ARGS] " "]
} else {
    set extra_args [list]
}
if {[info exists ::SKIP_COMPILE]} {
    set skip_compile $::SKIP_COMPILE
} else {
    set skip_compile 0
}
if {[info exists ::COMPILE_ONLY]} {
    set compile_only $::COMPILE_ONLY
} else {
    set compile_only 0
}

if {[info exists ::PROJECT_ROOT]} {
    set project_root [file normalize $::PROJECT_ROOT]
    set script_dir [file normalize [file join $project_root scripts]]
} else {
    set script_dir [pwd]
    set project_root [file normalize [file join $script_dir ..]]
}
set rtl_dir [file join $project_root rtl]
set tb_dir [file join $project_root tb]

cd $project_root
puts "== rv32im_low-power ModelSim run =="
puts "Project root: $project_root"
puts "Selected testbench: $tb_name"
if {[llength $extra_args] > 0} {
    puts "Extra args: $extra_args"
}
puts "Skip compile: $skip_compile"
puts "Compile only: $compile_only"

set rtl_files [list]
foreach rtl_file [lsort [glob -nocomplain [file join $rtl_dir *.v]]] {
    set rtl_tail [file tail $rtl_file]
    if {[string match "cpu_pspl_*_top.v" $rtl_tail]} {
        puts "Skipping PS+PL-only RTL for ModelSim: $rtl_file"
        continue
    }
    lappend rtl_files $rtl_file
}
set tb_files [lsort [glob -nocomplain [file join $tb_dir tb_*.v]]]

if {[llength $rtl_files] == 0} {
    puts "ERROR: No RTL files found under $rtl_dir"
    quit -code 2
}
if {[llength $tb_files] == 0} {
    puts "ERROR: No TB files found under $tb_dir"
    quit -code 3
}

set found_tb 0
foreach tb_file $tb_files {
    if {[file rootname [file tail $tb_file]] eq $tb_name} {
        set found_tb 1
    }
}
if {!$found_tb} {
    puts "ERROR: Unsupported testbench '$tb_name'"
    puts "Available testbenches:"
    foreach tb_file $tb_files {
        puts "  [file rootname [file tail $tb_file]]"
    }
    quit -code 4
}

if {!$skip_compile} {
    if {[file exists work]} {
        vdel -lib work -all
    }
    vlib work
    vmap work work

    foreach f $rtl_files {
        puts "Compiling RTL: $f"
        if {[catch {vlog -work work $f} msg]} {
            puts $msg
            quit -code 5
        }
    }
    foreach f $tb_files {
        puts "Compiling TB: $f"
        if {[catch {vlog -work work $f} msg]} {
            puts $msg
            quit -code 6
        }
    }
} else {
    if {![file exists work]} {
        puts "ERROR: work library does not exist; compile phase must run first"
        quit -code 8
    }
    if {[catch {vmap work work} msg]} {
        puts $msg
        quit -code 8
    }
}

if {$compile_only} {
    puts "== ModelSim compile complete for $tb_name =="
    return
}

set vsim_args [list -voptargs=+acc work.$tb_name]
foreach a $extra_args {
    lappend vsim_args $a
}
if {[catch {eval vsim $vsim_args} msg]} {
    puts $msg
    quit -code 7
}

log -r /*
run -all
puts "== ModelSim run complete for $tb_name =="
