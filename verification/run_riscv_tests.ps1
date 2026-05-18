param(
    [string]$ModelSimExe = "vsim",
    [int]$MaxCycles = 200000,
    [switch]$FailFast
)

$projectRoot = Split-Path -Parent $PSScriptRoot
$doFile = Join-Path $projectRoot 'scripts\run_modelsim_tb.do'
$generatedDir = Join-Path $projectRoot 'verification\generated'
New-Item -ItemType Directory -Force -Path $generatedDir | Out-Null

$testsRoot = $env:RISCV_TESTS_ROOT
if (-not $testsRoot) {
    Write-Host 'RISCV_TESTS_ROOT is not set.'
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
    throw "Missing tool: set $envName or RISCV_GCC_PREFIX"
}

$objcopy = Resolve-Tool 'objcopy' 'RISCV_OBJCOPY'
$nm = Resolve-Tool 'nm' 'RISCV_NM'

$tests = Get-ChildItem $testsRoot -Recurse -File | Where-Object {
    $_.Name -like 'rv32ui-p-*' -or $_.Name -like 'rv32um-p-*'
} | Sort-Object FullName
if (-not $tests) {
    Write-Host "No rv32ui/rv32um binaries found under $testsRoot"
    exit 1
}

$pass = 0
$fail = 0
foreach ($test in $tests) {
    $base = $test.BaseName
    $hexRel = "verification/generated/$base.hex"
    $hexPath = Join-Path $projectRoot $hexRel
    Write-Host "== riscv-tests: $($test.Name) =="
    & $objcopy -O verilog --verilog-data-width 4 $test.FullName $hexPath
    if ($LASTEXITCODE -ne 0) {
        Write-Host "objcopy failed for $($test.FullName)"
        $fail++
        if ($FailFast) { exit 2 }
        continue
    }
    $nmLine = & $nm $test.FullName | Select-String ' tohost$' | Select-Object -First 1
    if (-not $nmLine) {
        Write-Host "tohost symbol not found in $($test.FullName)"
        $fail++
        if ($FailFast) { exit 3 }
        continue
    }
    $tohost = ($nmLine.Line -split '\s+')[0]
    $cmd = "do {$doFile} tb_cpu_top_isa +IMEM_HEX=$hexRel +TOHOST_ADDR=$tohost +MAX_CYCLES=$MaxCycles; quit -f"
    $output = & $ModelSimExe -c -do $cmd 2>&1
    $output | ForEach-Object { Write-Host $_ }
    if (($output -join "`n") -match 'PASS tb_cpu_top_isa') {
        $pass++
    } else {
        $fail++
        if ($FailFast) { exit 4 }
    }
}

Write-Host "riscv-tests summary: PASS=$pass FAIL=$fail"
if ($fail -ne 0) { exit 5 }
