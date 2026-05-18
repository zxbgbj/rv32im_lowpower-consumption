param(
    [Parameter(Mandatory = $true)][string]$CoreMarkRoot,
    [string]$ModelSimExe = "vsim",
    [int]$Iterations = 10,
    [int]$MaxCycles = 6000000,
    [ValidateSet("O0", "O1", "O2", "O3", "Os")][string]$OptLevel = "O2",
    [string]$VcdFile = ""
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$portDir = Join-Path $PSScriptRoot "benchmark"
$runScript = Join-Path $PSScriptRoot "run_benchmark.ps1"

if (-not (Test-Path $CoreMarkRoot)) {
    throw "CoreMark root not found: $CoreMarkRoot"
}

$sourceRoot = $CoreMarkRoot
if (-not (Test-Path (Join-Path $sourceRoot "core_main.c"))) {
    $nestedRoot = Join-Path $CoreMarkRoot "coremark"
    if (Test-Path (Join-Path $nestedRoot "core_main.c")) {
        $sourceRoot = $nestedRoot
    }
}

$sources = @(
    (Join-Path $sourceRoot "core_list_join.c"),
    (Join-Path $sourceRoot "core_main.c"),
    (Join-Path $sourceRoot "core_matrix.c"),
    (Join-Path $sourceRoot "core_state.c"),
    (Join-Path $sourceRoot "core_util.c"),
    (Join-Path $portDir "core_portme.c")
)

foreach ($source in $sources) {
    if (-not (Test-Path $source)) {
        throw "CoreMark source not found: $source"
    }
}

& $runScript `
    -Name "coremark" `
    -ModelSimExe $ModelSimExe `
    -Sources $sources `
    -IncludeDirs @($sourceRoot, $portDir) `
    -Defines @(
        "PERFORMANCE_RUN=1",
        "ITERATIONS=$Iterations",
        "FLAGS_STR=rv32im_$OptLevel",
        "TOTAL_DATA_SIZE=2000",
        "MAIN_HAS_NOARGC=1",
        "HAS_STDIO=0",
        "HAS_PRINTF=0",
        "HAS_TIME_H=0",
        "USE_CLOCK=0",
        "HAS_FLOAT=0",
        "MEM_METHOD=MEM_STATIC",
        "MAIN_HAS_NORETURN=0"
    ) `
    -OptLevel $OptLevel `
    -MaxCycles $MaxCycles `
    -VcdFile $VcdFile

exit $LASTEXITCODE
