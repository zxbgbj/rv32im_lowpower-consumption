param(
    [Parameter(Mandatory = $true)][string]$Name,
    [string]$ModelSimExe = "vsim",
    [string[]]$Sources = @(),
    [string[]]$IncludeDirs = @(),
    [string[]]$Defines = @(),
    [ValidateSet("O0", "O1", "O2", "O3", "Os")][string]$OptLevel = "O2",
    [int]$MaxCycles = 6000000
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$generatedDir = Join-Path $projectRoot "verification\generated"
$setProfile = Join-Path $PSScriptRoot "set_board_benchmark_profile.ps1"
$buildScript = Join-Path $PSScriptRoot "build_board_benchmark.ps1"
$runTbScript = Join-Path $projectRoot "scripts\run_modelsim_tb.ps1"
$base = "board_" + $Name
$symPath = Join-Path $generatedDir ($base + ".sym")
$sigRel = "verification/generated/$base.rtl.signature"
$imemRel = "verification/generated/$base.imem.hex"
$dmemRel = "verification/generated/$base.dmem.hex"

& $setProfile
& $buildScript -Name $Name -Sources $Sources -IncludeDirs $IncludeDirs -Defines $Defines -OptLevel $OptLevel

$symLines = Get-Content $symPath
$tohostLine = $symLines | Select-String ' tohost$' | Select-Object -First 1
$sigStartLine = $symLines | Select-String ' begin_signature$' | Select-Object -First 1
$sigEndLine = $symLines | Select-String ' end_signature$' | Select-Object -First 1

$tohost = ($tohostLine.Line -split '\s+')[0]
$sigStart = ($sigStartLine.Line -split '\s+')[0]
$sigEnd = ($sigEndLine.Line -split '\s+')[0]

$extraArgs = @(
    "+IMEM_HEX=$imemRel",
    "+DMEM_HEX=$dmemRel",
    "+TOHOST_ADDR=$tohost",
    "+SIG_START=$sigStart",
    "+SIG_END=$sigEnd",
    "+SIG_FILE=$sigRel",
    "+MAX_CYCLES=$MaxCycles"
)

$output = & $runTbScript `
    -ModelSimExe $ModelSimExe `
    -Testbench "tb_cpu_top_isa" `
    -ExtraArgs $extraArgs 2>&1

$output | ForEach-Object { Write-Host $_ }

if (($output -join "`n") -notmatch 'PASS tb_cpu_top_isa cycles=(\d+)') {
    throw "Board benchmark run failed for $Name"
}

$cycleMatch = [regex]::Match(($output -join "`n"), 'PASS tb_cpu_top_isa cycles=(\d+)')
$cycles = [int]$cycleMatch.Groups[1].Value
Write-Host "Board benchmark PASS cycles=$cycles"
