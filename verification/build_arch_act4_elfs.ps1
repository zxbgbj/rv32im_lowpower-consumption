param(
    [string]$ArchTestRoot = $(if ($env:RISCV_ARCH_TEST_REPO) { $env:RISCV_ARCH_TEST_REPO } else { "D:\riscv-arch-test-git" }),
    [string]$WorkDir = "",
    [string]$MakeExe = "make",
    [string]$Extensions = "",
    [string]$ExcludeExtensions = "",
    [switch]$Debug,
    [switch]$Fast
)

$projectRoot = Split-Path -Parent $PSScriptRoot
$localConfigDir = Join-Path $projectRoot 'verification\arch\local_config'
$generatedRoot = Join-Path $projectRoot 'verification\generated\arch-act4'
$generatedConfigDir = Join-Path $generatedRoot 'config'
if (-not $WorkDir) {
    $WorkDir = Join-Path $generatedRoot 'work'
}

function Get-EnvValue([string]$name) {
    $item = Get-Item -Path ("Env:" + $name) -ErrorAction SilentlyContinue
    if ($null -ne $item) { return $item.Value }
    return $null
}

function Resolve-Exe([string]$explicit, [string]$fallback, [string]$label) {
    if ($explicit) {
        if (Test-Path $explicit) { return (Resolve-Path $explicit).Path }
        throw "$label not found at $explicit"
    }
    $cmd = Get-Command $fallback -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

function Resolve-RiscvTool([string]$suffix, [string]$envName, [string]$fallbackName) {
    $explicit = Get-EnvValue $envName
    if ($explicit) {
        if (Test-Path $explicit) { return (Resolve-Path $explicit).Path }
        throw "$envName points to a missing file: $explicit"
    }
    if ($env:RISCV_GCC_PREFIX) {
        $candidate = $env:RISCV_GCC_PREFIX + $suffix + '.exe'
        if (Test-Path $candidate) { return (Resolve-Path $candidate).Path }
        $candidate = $env:RISCV_GCC_PREFIX + $suffix
        if (Test-Path $candidate) { return (Resolve-Path $candidate).Path }
    }
    $cmd = Get-Command $fallbackName -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

if (-not (Test-Path $ArchTestRoot)) {
    throw "riscv-arch-test repository not found: $ArchTestRoot"
}

$missing = @()
$makePath = Resolve-Exe $null $MakeExe 'make'
if (-not $makePath) { $missing += 'make' }

$gccPath = Resolve-RiscvTool 'gcc' 'RISCV_GCC' 'riscv-none-elf-gcc'
if (-not $gccPath) { $missing += 'riscv-none-elf-gcc' }

$objdumpPath = Resolve-RiscvTool 'objdump' 'RISCV_OBJDUMP' 'riscv-none-elf-objdump'
if (-not $objdumpPath) { $missing += 'riscv-none-elf-objdump' }

$sailPath = Resolve-Exe (Get-EnvValue 'SAIL_RISCV_SIM') 'sail_riscv_sim' 'sail_riscv_sim'
if (-not $sailPath) { $missing += 'sail_riscv_sim' }

$uvPath = Resolve-Exe $null 'uv' 'uv'
$misePath = Resolve-Exe $null 'mise' 'mise'
$bundlePath = Resolve-Exe $null 'bundle' 'bundle'
if (-not $uvPath -and -not $misePath) { $missing += 'uv-or-mise' }
if (-not $misePath -and -not $bundlePath -and -not $env:VIRTUAL_ENV) { $missing += 'bundle' }

if ($missing.Count -ne 0) {
    Write-Host 'ACT4 arch-test prerequisites are incomplete.' -ForegroundColor Yellow
    Write-Host 'Missing tools:' -ForegroundColor Yellow
    $missing | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    Write-Host ''
    Write-Host 'Expected next tools for this flow:' -ForegroundColor Yellow
    Write-Host '  - make'
    Write-Host '  - sail_riscv_sim'
    Write-Host '  - uv or mise'
    Write-Host '  - bundle (unless you use mise or an already-prepared virtualenv)'
    throw 'Cannot generate arch-test ELFs until the missing ACT4 prerequisites are installed.'
}

New-Item -ItemType Directory -Force -Path $generatedConfigDir | Out-Null
New-Item -ItemType Directory -Force -Path $WorkDir | Out-Null

function As-YamlPath([string]$path) {
    return ((Resolve-Path $path).Path).Replace('\', '/')
}

$generatedConfigPath = Join-Path $generatedConfigDir 'test_config.generated.yaml'
$udbPath = Join-Path $localConfigDir 'rv32im-low-power.yaml'
$linkerPath = Join-Path $localConfigDir 'link.ld'
$includeDir = $localConfigDir

$yaml = @"
name: rv32im-low-power-act4
compiler_exe: '$([string](As-YamlPath $gccPath))'
objdump_exe: '$([string](As-YamlPath $objdumpPath))'
ref_model_exe: '$([string](As-YamlPath $sailPath))'
ref_model_type: sail
udb_config: '$([string](As-YamlPath $udbPath))'
linker_script: '$([string](As-YamlPath $linkerPath))'
dut_include_dir: '$([string](As-YamlPath $includeDir))'
include_priv_tests: false
"@
Set-Content -Path $generatedConfigPath -Value $yaml -Encoding ascii

Write-Host 'Generating ACT4 self-checking arch-test ELFs'
Write-Host "Arch repo : $ArchTestRoot"
Write-Host "Config    : $generatedConfigPath"
Write-Host "Work dir  : $WorkDir"
Write-Host "Compiler  : $gccPath"
Write-Host "Objdump   : $objdumpPath"
Write-Host "Ref model : $sailPath"

$args = @(
    'elfs',
    "CONFIG_FILES=$generatedConfigPath",
    "WORKDIR=$WorkDir"
)
if ($Extensions) { $args += "EXTENSIONS=$Extensions" }
if ($ExcludeExtensions) { $args += "EXCLUDE_EXTENSIONS=$ExcludeExtensions" }
if ($Debug) { $args += 'DEBUG=True' }
if ($Fast) { $args += 'FAST=True' }

& $makePath @args
if ($LASTEXITCODE -ne 0) {
    throw "ACT4 ELF generation failed. Inspect the output above for the first upstream tool error."
}

$elfDir = Join-Path $WorkDir 'rv32im-low-power-act4\elfs'
Write-Host ''
Write-Host 'ACT4 ELF generation completed.' -ForegroundColor Green
Write-Host "ELF dir: $elfDir"
Write-Host 'Next step:'
Write-Host "  `$env:RISCV_ARCH_TEST_ROOT = `"$elfDir`""
Write-Host '  .\run_arch_test.ps1 -ModelSimExe "D:\software_fpga\Modelsim10_6\win64pe\vsim.exe"'
