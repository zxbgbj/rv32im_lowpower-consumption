param()

$projectRoot = Split-Path -Parent $PSScriptRoot
$profileFile = Join-Path $projectRoot "rtl\memory_profile_overrides.vh"

@'
`ifndef RV32IM_MEMORY_PROFILE_OVERRIDES_VH
`define RV32IM_MEMORY_PROFILE_OVERRIDES_VH

// Verification profile: large memories for official ISA suites and ACT4 arch-test.
`define RV32IM_IMEM_DEPTH_WORDS 65536
`define RV32IM_DMEM_DEPTH_WORDS 262144
`define RV32IM_TB_IMEM_INIT_WORDS 65536
`define RV32IM_TB_DMEM_INIT_WORDS 262144

`endif
'@ | Set-Content -Path $profileFile -Encoding ASCII

Write-Host "Selected verification memory profile."
Write-Host "  IMEM depth words : 65536"
Write-Host "  DMEM depth words : 262144"
