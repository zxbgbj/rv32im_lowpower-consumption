param()

$projectRoot = Split-Path -Parent $PSScriptRoot
$profileFile = Join-Path $projectRoot "rtl\memory_profile_overrides.vh"

@'
`ifndef RV32IM_MEMORY_PROFILE_OVERRIDES_VH
`define RV32IM_MEMORY_PROFILE_OVERRIDES_VH

// FPGA profile: compact memories for implementation/resource reporting.
`define RV32IM_IMEM_DEPTH_WORDS 1024
`define RV32IM_DMEM_DEPTH_WORDS 1024
`define RV32IM_TB_IMEM_INIT_WORDS 1024
`define RV32IM_TB_DMEM_INIT_WORDS 1024

`endif
'@ | Set-Content -Path $profileFile -Encoding ASCII

Write-Host "Selected FPGA-target memory profile."
Write-Host "  IMEM depth words : 1024"
Write-Host "  DMEM depth words : 1024"
