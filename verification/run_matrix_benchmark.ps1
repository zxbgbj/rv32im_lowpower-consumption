param(
    [string]$ModelSimExe = "vsim",
    [int]$MaxCycles = 2000000,
    [int]$Iterations = 12,
    [int]$Dim = 16,
    [ValidateSet("O0", "O1", "O2", "O3", "Os")][string]$OptLevel = "O2",
    [string]$VcdFile = ""
)

$ErrorActionPreference = "Stop"

$runScript = Join-Path $PSScriptRoot "run_benchmark.ps1"

& $runScript `
    -Name "matrix_mul" `
    -ModelSimExe $ModelSimExe `
    -Defines @(
        "MATRIX_ITERATIONS=$Iterations",
        "MATRIX_DIM=$Dim"
    ) `
    -OptLevel $OptLevel `
    -MaxCycles $MaxCycles `
    -VcdFile $VcdFile

exit $LASTEXITCODE
