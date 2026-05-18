param(
    [string]$ModelSimExe = "vsim",
    [string]$Name = "smoke_tohost",
    [int]$MaxCycles = 5000
)

$projectRoot = Split-Path -Parent $PSScriptRoot
$buildScript = Join-Path $PSScriptRoot "build_smoke_elf.ps1"
$runTbScript = Join-Path $projectRoot "scripts\run_modelsim_tb.ps1"
$generatedDir = Join-Path $projectRoot "verification\generated"

& $buildScript -Name $Name
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$symPath = Join-Path $generatedDir ($Name + ".sym")
$hexRel = "verification/generated/$Name.hex"
$tohostLine = Get-Content $symPath | Select-String ' tohost$' | Select-Object -First 1
if (-not $tohostLine) {
    throw "tohost symbol not found in $symPath"
}
$tohost = ($tohostLine.Line -split '\s+')[0]

Write-Host "Running smoke ISA program on tb_cpu_top_isa"
Write-Host "IMEM_HEX : $hexRel"
Write-Host "TOHOST   : $tohost"

& $runTbScript `
    -ModelSimExe $ModelSimExe `
    -Testbench "tb_cpu_top_isa" `
    -ExtraArgs @("+IMEM_HEX=$hexRel", "+TOHOST_ADDR=$tohost", "+MAX_CYCLES=$MaxCycles")
exit $LASTEXITCODE
