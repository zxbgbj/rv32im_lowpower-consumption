if { $argc < 2 } {
    puts "Usage: xsct build_pspl_boot.tcl <coremark|matrix> <project_root> ?freq_tag?"
    exit 1
}

set board_bench [string tolower [lindex $argv 0]]
set project_root [lindex $argv 1]
set freq_tag "80m"
if {$argc >= 3} {
    set freq_tag [string tolower [lindex $argv 2]]
}
set artifacts_dir [file join $project_root artifacts]
if {$freq_tag eq "80m"} {
    set workspace_dir "D:/xsct_workspace_$board_bench"
    set hdf_file [file join $artifacts_dir pspl_${board_bench}.hdf]
} else {
    set workspace_dir "D:/xsct_workspace_${board_bench}_${freq_tag}"
    set hdf_file [file join $artifacts_dir pspl_${board_bench}_${freq_tag}.hdf]
}
set hw_project hw_$board_bench
set fsbl_project fsbl_$board_bench
set app_project bench_reporter_$board_bench
set bsp_project ${app_project}_bsp
set sdk_app_dir [file join $project_root software ps_bench_reporter]
set bit_dir [file join $project_root bitstreams]

switch -- $board_bench {
    "coremark" {
        set bit_name cpu_pspl_coremark_${freq_tag}.bit
        if {$freq_tag eq "80m"} {
            set boot_name BOOT_coremark.bin
        } else {
            set boot_name BOOT_coremark_${freq_tag}.bin
        }
        set fallback_bit [file join $project_root vivado_pspl_proj rv32im_low_power_pspl_coremark_${freq_tag}.runs impl_1 cpu_pspl_coremark_top.bit]
    }
    "matrix" {
        set bit_name cpu_pspl_matrix_${freq_tag}.bit
        if {$freq_tag eq "80m"} {
            set boot_name BOOT_matrix.bin
        } else {
            set boot_name BOOT_matrix_${freq_tag}.bin
        }
        set fallback_bit [file join $project_root vivado_pspl_proj rv32im_low_power_pspl_matrix_${freq_tag}.runs impl_1 cpu_pspl_matrix_top.bit]
    }
    default {
        puts "Unsupported board benchmark '$board_bench'"
        exit 1
    }
}

if {[file exists $workspace_dir]} {
    file delete -force $workspace_dir
}
file mkdir $workspace_dir
setws $workspace_dir

if {![file exists $hdf_file]} {
    puts "Missing HDF: $hdf_file"
    exit 1
}

createhw -name $hw_project -hwspec $hdf_file
createapp -name $fsbl_project -app {Zynq FSBL} -hwproject $hw_project -proc ps7_cortexa9_0 -os standalone -lang c
createbsp -name $bsp_project -hwproject $hw_project -proc ps7_cortexa9_0 -os standalone
createapp -name $app_project -app {Empty Application} -hwproject $hw_project -bsp $bsp_project -proc ps7_cortexa9_0 -os standalone -lang c

importsources -name $app_project -path $sdk_app_dir
projects -build

set fsbl_elf [file join $workspace_dir $fsbl_project Debug ${fsbl_project}.elf]
set app_elf [file join $workspace_dir $app_project Debug ${app_project}.elf]
set bit_file [file join $bit_dir $bit_name]
if {![file exists $bit_file]} {
    set bit_file $fallback_bit
}

if {$freq_tag eq "80m"} {
    set bif_file [file join $artifacts_dir ${board_bench}_boot.bif]
    set stage_dir "D:/boot_${board_bench}"
    set stage_bif [file join $stage_dir ${board_bench}_boot.bif]
} else {
    set bif_file [file join $artifacts_dir ${board_bench}_boot_${freq_tag}.bif]
    set stage_dir "D:/boot_${board_bench}_${freq_tag}"
    set stage_bif [file join $stage_dir ${board_bench}_boot_${freq_tag}.bif]
}
set boot_file [file join $artifacts_dir $boot_name]
set stage_fsbl [file join $stage_dir ${fsbl_project}.elf]
set stage_app [file join $stage_dir ${app_project}.elf]
set stage_bit [file join $stage_dir $bit_name]
set stage_boot [file join $stage_dir $boot_name]

if {[file exists $stage_dir]} {
    file delete -force $stage_dir
}
file mkdir $stage_dir
file copy -force $fsbl_elf $stage_fsbl
file copy -force $app_elf $stage_app
file copy -force $bit_file $stage_bit

set bif_fh [open $bif_file "w"]
puts $bif_fh "the_ROM_image:"
puts $bif_fh "\{"
puts $bif_fh "  \[bootloader\]$stage_fsbl"
puts $bif_fh "  $stage_bit"
puts $bif_fh "  $stage_app"
puts $bif_fh "\}"
close $bif_fh
file copy -force $bif_file $stage_bif

set bootgen_exe [file normalize "D:/Xilinx/SDK/2018.3/bin/bootgen.bat"]
exec $bootgen_exe -arch zynq -image $stage_bif -o i $stage_boot -w on
file copy -force $stage_boot $boot_file

puts "Generated BOOT image: $boot_file"
