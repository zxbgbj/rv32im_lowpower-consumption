param(
    [string]$ArchTestRoot = "D:\riscv-arch-test-git",
    [string]$Extensions = "",
    [string]$ExcludeExtensions = "",
    [switch]$Debug,
    [switch]$Fast
)

$projectRoot = Split-Path -Parent $PSScriptRoot
$generatedRoot = Join-Path $projectRoot 'verification\generated\arch-act4'
$generatedConfigDir = Join-Path $generatedRoot 'config'
New-Item -ItemType Directory -Force -Path $generatedConfigDir | Out-Null

function Convert-ToWslPath([string]$path) {
    $resolved = (Resolve-Path $path).Path
    $drive = $resolved.Substring(0, 1).ToLower()
    $rest = $resolved.Substring(2).Replace('\', '/')
    return "/mnt/$drive$rest"
}

$workspaceWslLink = '/mnt/d/rv32im_low_power_ws'
$projectRootWsl = Convert-ToWslPath $projectRoot
$archTestRootWsl = Convert-ToWslPath $ArchTestRoot
$compilerWsl = '/root/opt/xpack-riscv-none-elf-gcc-15.2.0-1/bin/riscv-none-elf-gcc'
$objdumpWsl = '/root/opt/xpack-riscv-none-elf-gcc-15.2.0-1/bin/riscv-none-elf-objdump'
$sailWsl = '/root/.local/bin/sail_riscv_sim'
$wslConfigPath = Join-Path $generatedConfigDir 'test_config.wsl.yaml'
$workDirWsl = "$workspaceWslLink/verification/generated/arch-act4/work"

$yaml = @"
name: rv32im-low-power-act4
compiler_exe: '$compilerWsl'
objdump_exe: '$objdumpWsl'
ref_model_exe: '$sailWsl'
ref_model_type: sail
udb_config: '$workspaceWslLink/verification/arch/local_config/rv32im-low-power.yaml'
linker_script: '$workspaceWslLink/verification/arch/local_config/link.ld'
dut_include_dir: '$workspaceWslLink/verification/arch/local_config'
include_priv_tests: false
"@
Set-Content -Path $wslConfigPath -Value $yaml -Encoding ascii
$wslConfigPathWsl = "$workspaceWslLink/verification/generated/arch-act4/config/test_config.wsl.yaml"

$makeArgs = @(
    'make',
    'elfs',
    "CONFIG_FILES='$wslConfigPathWsl'",
    "WORKDIR='$workDirWsl'"
)
if ($Extensions) { $makeArgs += "EXTENSIONS='$Extensions'" }
if ($ExcludeExtensions) { $makeArgs += "EXCLUDE_EXTENSIONS='$ExcludeExtensions'" }
if ($Debug) { $makeArgs += 'DEBUG=True' }
if ($Fast) { $makeArgs += 'FAST=True' }
$makeArgsText = ($makeArgs -join ' ')

$makeCmd = @(
    'set -e',
    'mkdir -p /mnt/d',
    "ln -sfn '$projectRootWsl' '$workspaceWslLink'",
    'export PATH="$HOME/.local/bin:$PATH"',
    '. "$HOME/.venvs/act4/bin/activate"',
    "cd '$archTestRootWsl'",
    $makeArgsText
)
$makeCmdText = ($makeCmd -join '; ')

Write-Host 'Generating ACT4 self-checking arch-test ELFs inside WSL'
Write-Host "Arch repo : $ArchTestRoot"
Write-Host "Config    : $wslConfigPath"
Write-Host "Work dir  : $(Join-Path $generatedRoot 'work')"

& wsl.exe -e bash -lc $makeCmdText
if ($LASTEXITCODE -ne 0) {
    throw 'WSL ACT4 ELF generation failed. Inspect the first upstream error above.'
}

$elfDir = Join-Path $generatedRoot 'work\rv32im-low-power-act4\elfs'
Write-Host ''
Write-Host 'WSL ACT4 ELF generation completed.' -ForegroundColor Green
Write-Host "ELF dir: $elfDir"
Write-Host 'Next step:'
Write-Host "  `$env:RISCV_ARCH_TEST_ROOT = `"$elfDir`""
Write-Host '  .\run_arch_test.ps1 -ModelSimExe "D:\software_fpga\Modelsim10_6\win64pe\vsim.exe"'
