param(
    [string]$Name = "smoke_tohost"
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
$smokeDir = Join-Path $PSScriptRoot "smoke"
$generatedDir = Join-Path $projectRoot "verification\generated"
New-Item -ItemType Directory -Force -Path $generatedDir | Out-Null

$srcAsm = Join-Path $smokeDir ($Name + ".S")
$srcC = Join-Path $smokeDir ($Name + ".c")
$ld = Join-Path $smokeDir "smoke.ld"
$elf = Join-Path $generatedDir ($Name + ".elf")
$hex = Join-Path $generatedDir ($Name + ".hex")
$lst = Join-Path $generatedDir ($Name + ".lst")
$sym = Join-Path $generatedDir ($Name + ".sym")
$map = Join-Path $generatedDir ($Name + ".map")

if (Test-Path $srcAsm) {
    $src = $srcAsm
} elseif (Test-Path $srcC) {
    $src = $srcC
} else {
    throw "Smoke source not found: $srcAsm or $srcC"
}

$gcc = Resolve-Tool "gcc" "RISCV_GCC" "riscv-none-elf-gcc"
$objcopy = Resolve-Tool "objcopy" "RISCV_OBJCOPY" "riscv-none-elf-objcopy"
$nm = Resolve-Tool "nm" "RISCV_NM" "riscv-none-elf-nm"
$objdumpTool = $null
try {
    $objdumpTool = Resolve-Tool "objdump" "RISCV_OBJDUMP" "riscv-none-elf-objdump"
} catch {
    $objdumpTool = $null
}

Write-Host "Building smoke ELF: $Name"
Write-Host "GCC: $gcc"
Write-Host "OBJCOPY: $objcopy"
Write-Host "NM: $nm"

$gccArgs = @(
    "-march=rv32im",
    "-mabi=ilp32",
    "-nostdlib",
    "-nostartfiles",
    "-ffreestanding",
    "-fno-builtin",
    "-fno-stack-protector",
    "-O2",
    "-Wl,-T,$ld",
    "-Wl,--no-relax",
    "-Wl,-Map,$map",
    "-o", $elf,
    $src
)

& $gcc @gccArgs
if ($LASTEXITCODE -ne 0) {
    throw "GCC failed while building $elf"
}

& $objcopy -O verilog --verilog-data-width 4 $elf $hex
if ($LASTEXITCODE -ne 0) {
    throw "objcopy failed while generating $hex"
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

Write-Host "Built ELF : $elf"
Write-Host "Built HEX : $hex"
Write-Host "tohost    : $tohost"
