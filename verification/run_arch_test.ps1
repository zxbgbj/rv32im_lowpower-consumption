param(
    [string]$ModelSimExe = "vsim",
    [string]$PythonExe = "python",
    [int]$MaxCycles = 400000,
    [switch]$FailFast
)

$projectRoot = Split-Path -Parent $PSScriptRoot
$runTbScript = Join-Path $projectRoot 'scripts\run_modelsim_tb.ps1'
$setVerificationProfile = Join-Path $PSScriptRoot 'set_verification_profile.ps1'
$generatedDir = Join-Path $projectRoot 'verification\generated'
New-Item -ItemType Directory -Force -Path $generatedDir | Out-Null

$testsRoot = $env:RISCV_ARCH_TEST_ROOT
if (-not $testsRoot) {
    Write-Host 'RISCV_ARCH_TEST_ROOT is not set.'
    exit 1
}

function Get-EnvValue([string]$name) {
    $item = Get-Item -Path ("Env:" + $name) -ErrorAction SilentlyContinue
    if ($null -ne $item) { return $item.Value }
    return $null
}

function Resolve-Tool([string]$suffix, [string]$envName) {
    $explicit = Get-EnvValue $envName
    if ($explicit) { return $explicit }
    if ($env:RISCV_GCC_PREFIX) { return ($env:RISCV_GCC_PREFIX + $suffix) }
    $fallback = "riscv-none-elf-" + $suffix
    $cmd = Get-Command $fallback -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    throw "Missing tool: set $envName or RISCV_GCC_PREFIX"
}

$objcopy = Resolve-Tool 'objcopy' 'RISCV_OBJCOPY'
$nm = Resolve-Tool 'nm' 'RISCV_NM'
$comparePy = Join-Path $projectRoot 'verification\compare_signature_files.py'

$tests = Get-ChildItem $testsRoot -Recurse -File | Where-Object { $_.Extension -eq '.elf' } | Sort-Object FullName
if (-not $tests) {
    Write-Host "No arch-test ELF files found under $testsRoot"
    exit 1
}

& $setVerificationProfile
if (-not $?) {
    Write-Host "Failed to select verification memory profile"
    exit 2
}

$compileOutput = & $runTbScript `
    -ModelSimExe $ModelSimExe `
    -Testbench 'tb_cpu_top_isa' `
    -CompileOnly 2>&1
$compileOutput | ForEach-Object { Write-Host $_ }
if ($LASTEXITCODE -ne 0) {
    Write-Host "Initial ModelSim compile failed for tb_cpu_top_isa"
    exit 3
}

$pass = 0
$fail = 0
foreach ($test in $tests) {
    $base = $test.BaseName
    $imemRel = "verification/generated/$base.imem.hex"
    $imemPath = Join-Path $projectRoot $imemRel
    $dmemRel = "verification/generated/$base.dmem.hex"
    $dmemPath = Join-Path $projectRoot $dmemRel
    $rtlSigRel = "verification/generated/$base.rtl.signature"
    $rtlSigPath = Join-Path $projectRoot $rtlSigRel
    $expectedSigPath = $test.FullName.Replace("\elfs\", "\build\").Replace(".elf", ".results")

    Write-Host "== arch-test: $($test.Name) =="

    & $objcopy -O verilog --verilog-data-width 4 `
        --only-section=.text.init `
        --only-section=.text.rvtest `
        --only-section=.text.rvtest.* `
        --only-section=.text `
        --only-section=.text.* `
        --only-section=.text.rvmodel `
        --only-section=.text.rvmodel.* `
        --only-section=.rodata `
        --only-section=.rodata.* `
        $test.FullName $imemPath
    if ($LASTEXITCODE -ne 0) {
        Write-Host "objcopy failed while generating IMEM hex for $($test.FullName)"
        $fail++
        if ($FailFast) { exit 4 }
        continue
    }

    & $objcopy -O verilog --verilog-data-width 4 `
        --only-section=.tohost `
        --only-section=.data `
        --only-section=.data.* `
        --only-section=.sdata `
        --only-section=.sdata.* `
        $test.FullName $dmemPath
    if ($LASTEXITCODE -ne 0) {
        Write-Host "objcopy failed while generating DMEM hex for $($test.FullName)"
        $fail++
        if ($FailFast) { exit 4 }
        continue
    }

    $nmLines = & $nm $test.FullName
    $sigStartLine = $nmLines | Select-String ' begin_signature$' | Select-Object -First 1
    $sigEndLine = $nmLines | Select-String ' end_signature$' | Select-Object -First 1
    if (-not $sigStartLine -or -not $sigEndLine) {
        Write-Host "Signature symbols missing in $($test.FullName)"
        $fail++
        if ($FailFast) { exit 5 }
        continue
    }

    $tohostLine = $nmLines | Select-String ' tohost$' | Select-Object -First 1
    $sigStart = ($sigStartLine.Line -split '\s+')[0]
    $sigEnd = ($sigEndLine.Line -split '\s+')[0]
    $tohost = if ($tohostLine) { ($tohostLine.Line -split '\s+')[0] } else { '00000000' }

    $output = & $runTbScript `
        -ModelSimExe $ModelSimExe `
        -Testbench 'tb_cpu_top_isa' `
        -SkipCompile `
        -ExtraArgs @(
            "+IMEM_HEX=$imemRel",
            "+DMEM_HEX=$dmemRel",
            "+TOHOST_ADDR=$tohost",
            "+SIG_START=$sigStart",
            "+SIG_END=$sigEnd",
            "+SIG_FILE=$rtlSigRel",
            "+MAX_CYCLES=$MaxCycles"
        ) 2>&1
    $output | ForEach-Object { Write-Host $_ }
    if (($output -join "`n") -notmatch 'PASS tb_cpu_top_isa') {
        $fail++
        if ($FailFast) { exit 6 }
        continue
    }

    if (-not (Test-Path $expectedSigPath)) {
        Write-Host "Expected ACT4 results file not found: $expectedSigPath"
        $fail++
        if ($FailFast) { exit 7 }
        continue
    }

    & $PythonExe $comparePy --expected $expectedSigPath --actual $rtlSigPath
    if ($LASTEXITCODE -eq 0) {
        $pass++
    } else {
        $fail++
        if ($FailFast) { exit 8 }
    }
}

Write-Host "arch-test summary: PASS=$pass FAIL=$fail"
if ($fail -ne 0) { exit 9 }
