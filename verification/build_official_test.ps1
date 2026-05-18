param(
    [string]$TestsRoot = "D:\riscv-tests-git",
    [Parameter(Mandatory = $true)][string]$Suite,
    [Parameter(Mandatory = $true)][string]$Test
)

function Get-EnvValue([string]$name) {
    $item = Get-Item -Path ("Env:" + $name) -ErrorAction SilentlyContinue
    if ($null -ne $item) { return $item.Value }
    return $null
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
$generatedDir = Join-Path $projectRoot "verification\generated"
$localEnvDir = Join-Path $PSScriptRoot "official\local_env"
New-Item -ItemType Directory -Force -Path $generatedDir | Out-Null

$src = Join-Path $TestsRoot ("isa\" + $Suite + "\" + $Test + ".S")
if (-not (Test-Path $src)) {
    throw "Official test source not found: $src"
}

$base = "official_" + $Suite + "_" + $Test
$elf = Join-Path $generatedDir ($base + ".elf")
$imemHex = Join-Path $generatedDir ($base + ".imem.hex")
$dmemHex = Join-Path $generatedDir ($base + ".dmem.hex")
$sym = Join-Path $generatedDir ($base + ".sym")
$lst = Join-Path $generatedDir ($base + ".lst")
$map = Join-Path $generatedDir ($base + ".map")
$linkerScript = Join-Path $localEnvDir "link.ld"

$gcc = Resolve-Tool "gcc" "RISCV_GCC" "riscv-none-elf-gcc"
$objcopy = Resolve-Tool "objcopy" "RISCV_OBJCOPY" "riscv-none-elf-objcopy"
$nm = Resolve-Tool "nm" "RISCV_NM" "riscv-none-elf-nm"
$objdumpTool = $null
try {
    $objdumpTool = Resolve-Tool "objdump" "RISCV_OBJDUMP" "riscv-none-elf-objdump"
} catch {
    $objdumpTool = $null
}

Write-Host "Building official source test: $Suite/$Test"
Write-Host "Source   : $src"

$gccArgs = @(
    "-march=rv32im",
    "-mabi=ilp32",
    "-nostdlib",
    "-nostartfiles",
    "-ffreestanding",
    "-fno-builtin",
    "-fno-stack-protector",
    "-O2",
    "-I$localEnvDir",
    "-I" + (Join-Path $TestsRoot "env"),
    "-I" + (Join-Path $TestsRoot "isa\macros\scalar"),
    "-Xlinker", "-T",
    "-Xlinker", $linkerScript,
    "-Xlinker", "--no-relax",
    "-Xlinker", "-Map=$map",
    "-o", $elf,
    $src
)

& $gcc @gccArgs
if ($LASTEXITCODE -ne 0) {
    throw "GCC failed while building $elf"
}

& $objcopy -O verilog --verilog-data-width 4 `
    --only-section=.text.init `
    --only-section=.text `
    --only-section=.text.startup `
    --only-section=.text.unlikely `
    --only-section=.rodata `
    $elf $imemHex
if ($LASTEXITCODE -ne 0) {
    throw "objcopy failed while generating IMEM hex: $imemHex"
}

& $objcopy -O verilog --verilog-data-width 4 `
    --only-section=.tohost `
    --only-section=.data `
    --only-section=.sdata `
    $elf $dmemHex
if ($LASTEXITCODE -ne 0) {
    throw "objcopy failed while generating DMEM hex: $dmemHex"
}

& $nm $elf | Tee-Object -FilePath $sym | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "nm failed while generating $sym"
}

if ($objdumpTool) {
    & $objdumpTool -d $elf | Tee-Object -FilePath $lst | Out-Null
}

$tohostLine = Get-Content $sym | Select-String ' tohost$' | Select-Object -First 1
if (-not $tohostLine) {
    throw "tohost symbol not found in $elf"
}
$tohost = ($tohostLine.Line -split '\s+')[0]

Write-Host "Built ELF  : $elf"
Write-Host "IMEM HEX   : $imemHex"
Write-Host "DMEM HEX   : $dmemHex"
Write-Host "tohost     : $tohost"
