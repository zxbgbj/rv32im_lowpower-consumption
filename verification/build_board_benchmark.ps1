param(
    [Parameter(Mandatory = $true)][string]$Name,
    [string[]]$Sources = @(),
    [string[]]$IncludeDirs = @(),
    [string[]]$Defines = @(),
    [ValidateSet("O0", "O1", "O2", "O3", "Os")][string]$OptLevel = "O2"
)

function Get-EnvValue([string]$name) {
    $value = [System.Environment]::GetEnvironmentVariable($name, "Process")
    if (-not $value) { $value = [System.Environment]::GetEnvironmentVariable($name, "User") }
    if (-not $value) { $value = [System.Environment]::GetEnvironmentVariable($name, "Machine") }
    return $value
}

function Resolve-Tool([string]$suffix, [string]$envName, [string]$fallbackCommand = "") {
    $explicit = Get-EnvValue $envName
    if ($explicit) { return $explicit }
    if ($env:RISCV_GCC_PREFIX) { return ($env:RISCV_GCC_PREFIX + $suffix) }
    if ($fallbackCommand) {
        $cmd = Get-Command $fallbackCommand -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }
    throw "Missing tool: set $envName, RISCV_GCC_PREFIX, or add $fallbackCommand to PATH"
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$benchmarkDir = Join-Path $PSScriptRoot "benchmark"
$boardDir = Join-Path $PSScriptRoot "board"
$generatedDir = Join-Path $projectRoot "verification\generated"
$localSourceC = Join-Path $benchmarkDir ($Name + ".c")
$localSourceAsm = Join-Path $benchmarkDir ($Name + ".S")

New-Item -ItemType Directory -Force -Path $generatedDir | Out-Null

$userSources = @($Sources | Where-Object { $_ -and $_.Trim().Length -gt 0 })
if ($userSources.Count -eq 0) {
    if (Test-Path $localSourceC) {
        $userSources = @($localSourceC)
    } elseif (Test-Path $localSourceAsm) {
        $userSources = @($localSourceAsm)
    } else {
        throw "Board benchmark source not found: provide -Sources or add $localSourceC / $localSourceAsm"
    }
}

$crt0 = Join-Path $benchmarkDir "crt0.S"
$support = Join-Path $benchmarkDir "benchmark_support.c"
$miniLibc = Join-Path $benchmarkDir "mini_libc.c"
$linkerScript = Join-Path $boardDir "board_benchmark.ld"
$base = "board_" + $Name
$elf = Join-Path $generatedDir ($base + ".elf")
$imemHex = Join-Path $generatedDir ($base + ".imem.hex")
$dmemHex = Join-Path $generatedDir ($base + ".dmem.hex")
$sym = Join-Path $generatedDir ($base + ".sym")
$lst = Join-Path $generatedDir ($base + ".lst")
$map = Join-Path $generatedDir ($base + ".map")

$gcc = Resolve-Tool "gcc" "RISCV_GCC" "riscv-none-elf-gcc"
$objcopy = Resolve-Tool "objcopy" "RISCV_OBJCOPY" "riscv-none-elf-objcopy"
$nm = Resolve-Tool "nm" "RISCV_NM" "riscv-none-elf-nm"
$objdumpTool = Resolve-Tool "objdump" "RISCV_OBJDUMP" "riscv-none-elf-objdump"

$includeArgs = @("-I$benchmarkDir")
foreach ($includeDir in $IncludeDirs) {
    if ($includeDir -and $includeDir.Trim().Length -gt 0) {
        $includeArgs += "-I$includeDir"
    }
}

$defineArgs = @("-DBOARD_BENCHMARK=1")
foreach ($define in $Defines) {
    if ($define -and $define.Trim().Length -gt 0) {
        $defineArgs += "-D$define"
    }
}

$gccArgs = @(
    "-march=rv32im",
    "-mabi=ilp32",
    "-nostdlib",
    "-nostartfiles",
    "-ffreestanding",
    "-fno-builtin",
    "-fno-stack-protector",
    "-fno-common",
    "-Wall",
    "-Wextra",
    "-$OptLevel"
) + $includeArgs + $defineArgs + @(
    "-Wl,-T,$linkerScript",
    "-Wl,--no-relax",
    "-Wl,-Map,$map",
    "-o", $elf,
    $crt0,
    $support,
    $miniLibc
) + $userSources

Write-Host "Building board benchmark: $Name"
& $gcc @gccArgs
if ($LASTEXITCODE -ne 0) {
    throw "GCC failed while building $elf"
}

& $objcopy -O verilog --verilog-data-width 4 `
    --only-section=.text.init `
    --only-section=.text `
    --only-section=.text.* `
    $elf $imemHex
if ($LASTEXITCODE -ne 0) {
    throw "objcopy failed while generating IMEM hex: $imemHex"
}

& $objcopy -O verilog --verilog-data-width 4 `
    --only-section=.tohost `
    --only-section=.fromhost `
    --only-section=.signature `
    --only-section=.rodata `
    --only-section=.rodata.* `
    --only-section=.srodata `
    --only-section=.srodata.* `
    --only-section=.data `
    --only-section=.data.* `
    --only-section=.sdata `
    --only-section=.sdata.* `
    $elf $dmemHex
if ($LASTEXITCODE -ne 0) {
    throw "objcopy failed while generating DMEM hex: $dmemHex"
}

& $nm $elf | Tee-Object -FilePath $sym | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "nm failed while generating $sym"
}

& $objdumpTool -d $elf | Tee-Object -FilePath $lst | Out-Null

Write-Host "Built board ELF  : $elf"
Write-Host "IMEM HEX         : $imemHex"
Write-Host "DMEM HEX         : $dmemHex"
Write-Host "SYM              : $sym"
Write-Host "MAP              : $map"
