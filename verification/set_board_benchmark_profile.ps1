param()

$projectRoot = Split-Path -Parent $PSScriptRoot
$profileFile = Join-Path $projectRoot "rtl\memory_profile_overrides.vh"

@'
`ifndef RV32IM_MEMORY_PROFILE_OVERRIDES_VH
`define RV32IM_MEMORY_PROFILE_OVERRIDES_VH

// Board benchmark profile: sized to fit CoreMark and matrix bring-up in PL BRAM.
`define RV32IM_IMEM_DEPTH_WORDS 8192
`define RV32IM_DMEM_DEPTH_WORDS 8192
`define RV32IM_TB_IMEM_INIT_WORDS 8192
`define RV32IM_TB_DMEM_INIT_WORDS 8192

`endif
'@ | Set-Content -Path $profileFile -Encoding ASCII

Write-Host "Selected board benchmark memory profile."
Write-Host "  IMEM depth words : 8192"
Write-Host "  DMEM depth words : 8192"
