param(
    [string]$ModelSimExe = "vsim",
    [string]$TestsRoot = "D:\riscv-tests-git",
    [Parameter(Mandatory = $true)][string]$Suite,
    [Parameter(Mandatory = $true)][string]$Test,
    [int]$MaxCycles = 30000,
    [switch]$DebugIsa
)

$projectRoot = Split-Path -Parent $PSScriptRoot
$buildScript = Join-Path $PSScriptRoot "build_official_test.ps1"
$runTbScript = Join-Path $projectRoot "scripts\run_modelsim_tb.ps1"
$generatedDir = Join-Path $projectRoot "verification\generated"

& $buildScript -TestsRoot $TestsRoot -Suite $Suite -Test $Test
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$base = "official_" + $Suite + "_" + $Test
$symPath = Join-Path $generatedDir ($base + ".sym")
$imemRel = "verification/generated/$base.imem.hex"
$dmemRel = "verification/generated/$base.dmem.hex"
$tohostLine = Get-Content $symPath | Select-String ' tohost$' | Select-Object -First 1
if (-not $tohostLine) {
    throw "tohost symbol not found in $symPath"
}
$tohost = ($tohostLine.Line -split '\s+')[0]

Write-Host "Running official source test on tb_cpu_top_isa"
Write-Host "Suite     : $Suite"
Write-Host "Test      : $Test"
Write-Host "IMEM_HEX  : $imemRel"
Write-Host "DMEM_HEX  : $dmemRel"
Write-Host "TOHOST    : $tohost"

$extraArgs = @("+IMEM_HEX=$imemRel", "+DMEM_HEX=$dmemRel", "+TOHOST_ADDR=$tohost", "+MAX_CYCLES=$MaxCycles")
if ($DebugIsa) {
    $extraArgs += "+DEBUG_ISA"
}

& $runTbScript `
    -ModelSimExe $ModelSimExe `
    -Testbench "tb_cpu_top_isa" `
    -ExtraArgs $extraArgs
exit $LASTEXITCODE
