param(
    [Parameter(Mandatory = $true)][string]$Name,
    [string]$ModelSimExe = "vsim",
    [string[]]$Sources = @(),
    [string[]]$IncludeDirs = @(),
    [string[]]$Defines = @(),
    [ValidateSet("O0", "O1", "O2", "O3", "Os")][string]$OptLevel = "O2",
    [int]$MaxCycles = 2000000,
    [string]$VcdFile = ""
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$generatedDir = Join-Path $projectRoot "verification\generated"
$setVerificationProfile = Join-Path $PSScriptRoot "set_verification_profile.ps1"
$buildScript = Join-Path $PSScriptRoot "build_benchmark.ps1"
$runTbScript = Join-Path $projectRoot "scripts\run_modelsim_tb.ps1"
$base = "bench_" + $Name
$symPath = Join-Path $generatedDir ($base + ".sym")
$sigRel = "verification/generated/$base.rtl.signature"
$sigPath = Join-Path $projectRoot $sigRel
$imemRel = "verification/generated/$base.imem.hex"
$dmemRel = "verification/generated/$base.dmem.hex"

& $setVerificationProfile
if (-not $?) {
    throw "Failed to select verification memory profile"
}

& $buildScript -Name $Name -Sources $Sources -IncludeDirs $IncludeDirs -Defines $Defines -OptLevel $OptLevel
if ($LASTEXITCODE -ne 0) {
    throw "Benchmark build failed for $Name"
}

if (-not (Test-Path $symPath)) {
    throw "Benchmark symbol file not found: $symPath"
}

$symLines = Get-Content $symPath
$tohostLine = $symLines | Select-String ' tohost$' | Select-Object -First 1
$sigStartLine = $symLines | Select-String ' begin_signature$' | Select-Object -First 1
$sigEndLine = $symLines | Select-String ' end_signature$' | Select-Object -First 1

if (-not $tohostLine) {
    throw "tohost symbol not found in $symPath"
}
if (-not $sigStartLine -or -not $sigEndLine) {
    throw "signature symbols not found in $symPath"
}

$tohost = ($tohostLine.Line -split '\s+')[0]
$sigStart = ($sigStartLine.Line -split '\s+')[0]
$sigEnd = ($sigEndLine.Line -split '\s+')[0]

Write-Host "Running benchmark on tb_cpu_top_isa"
Write-Host "Name      : $Name"
Write-Host "IMEM_HEX  : $imemRel"
Write-Host "DMEM_HEX  : $dmemRel"
Write-Host "TOHOST    : $tohost"
Write-Host "SIG_START : $sigStart"
Write-Host "SIG_END   : $sigEnd"
if ($VcdFile) {
    $vcdParent = Split-Path -Parent $VcdFile
    if ($vcdParent) {
        New-Item -ItemType Directory -Force -Path $vcdParent | Out-Null
    }
    Write-Host "VCD_FILE  : $VcdFile"
}

$extraArgs = @(
    "+IMEM_HEX=$imemRel",
    "+DMEM_HEX=$dmemRel",
    "+TOHOST_ADDR=$tohost",
    "+SIG_START=$sigStart",
    "+SIG_END=$sigEnd",
    "+SIG_FILE=$sigRel",
    "+MAX_CYCLES=$MaxCycles"
)
if ($VcdFile) {
    $vcdPathTb = $VcdFile -replace '\\', '/'
    $extraArgs += "+VCD_FILE=$vcdPathTb"
}

$output = & $runTbScript `
    -ModelSimExe $ModelSimExe `
    -Testbench "tb_cpu_top_isa" `
    -ExtraArgs $extraArgs 2>&1

$output | ForEach-Object { Write-Host $_ }

if (($output -join "`n") -notmatch 'PASS tb_cpu_top_isa cycles=(\d+)') {
    throw "Benchmark run failed for $Name"
}

$cycleMatch = [regex]::Match(($output -join "`n"), 'PASS tb_cpu_top_isa cycles=(\d+)')
$cycles = [int]$cycleMatch.Groups[1].Value

$sigWords = @()
if (Test-Path $sigPath) {
    $sigWords = @(Get-Content $sigPath | Where-Object { $_.Trim().Length -gt 0 })
}

Write-Host "Benchmark PASS cycles=$cycles"
if ($sigWords.Count -ge 8 -and $sigWords[0] -eq "42454e43") {
    Write-Host ("Signature : magic={0} status={1} id={2} arg0={3} arg1={4} arg2={5}" -f `
        $sigWords[0], $sigWords[1], $sigWords[2], $sigWords[3], $sigWords[4], $sigWords[5])
    if ($sigWords[1] -ne "00000000") {
        throw "Benchmark signature reported non-zero status: $($sigWords[1])"
    }
}
Write-Host "Signature file: $sigPath"
