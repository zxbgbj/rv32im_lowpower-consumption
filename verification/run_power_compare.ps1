param(
    [string]$CurrentProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$BaselineProjectRoot = "D:\Codex project\RISC-V CPU\rv32im_perf_baseline_v1",
    [string]$CoreMarkRoot = "D:\benchmarks\coremark",
    [string]$ModelSimExe = "vsim",
    [string]$VivadoBat = "D:\Xilinx\Vivado\2018.3\bin\vivado.bat",
    [string]$RiscvToolBin = "D:\tools\riscv\xpack-riscv-none-elf-gcc-15.2.0-1\bin",
    [switch]$SkipActivityPower
)

$ErrorActionPreference = "Stop"

function Parse-CoreMarkCycles {
    param([string[]]$OutputLines)
    $text = $OutputLines -join "`n"
    $match = [regex]::Match($text, 'PASS tb_cpu_top_isa cycles=(\d+)')
    if (-not $match.Success) {
        throw "Unable to parse benchmark cycles"
    }
    return [double]$match.Groups[1].Value
}

function Parse-MatrixCycles {
    param([string[]]$OutputLines)
    return Parse-CoreMarkCycles -OutputLines $OutputLines
}

function Parse-TimingReport {
    param([string]$ReportPath)
    $text = Get-Content $ReportPath -Raw
    $wnsMatch = [regex]::Match($text, 'WNS\(ns\)\s+TNS\(ns\)[\s\S]*?\n\s*(-?\d+\.\d+)\s+(-?\d+\.\d+)')
    if (-not $wnsMatch.Success) {
        throw "Unable to parse timing report: $ReportPath"
    }
    $wns = [double]$wnsMatch.Groups[1].Value
    $tns = [double]$wnsMatch.Groups[2].Value
    $periodNs = 10.0 - $wns
    $fmaxMHz = if ($periodNs -gt 0) { 1000.0 / $periodNs } else { 0.0 }
    [pscustomobject]@{
        WnsNs = $wns
        TnsNs = $tns
        FmaxMHz = $fmaxMHz
    }
}

function Parse-PowerReport {
    param([string]$ReportPath)
    $text = Get-Content $ReportPath -Raw
    function Get-Field([string]$Pattern, [string]$Label) {
        $match = [regex]::Match($text, $Pattern)
        if (-not $match.Success) {
            throw "Unable to parse $Label from $ReportPath"
        }
        return $match.Groups[1].Value
    }
    [pscustomobject]@{
        TotalW = [double](Get-Field '\|\s+Total On-Chip Power \(W\)\s+\|\s+([0-9.]+)' 'total power')
        DynamicW = [double](Get-Field '\|\s+Dynamic \(W\)\s+\|\s+([0-9.]+)' 'dynamic power')
        StaticW = [double](Get-Field '\|\s+Device Static \(W\)\s+\|\s+([0-9.]+)' 'static power')
        Confidence = Get-Field '\|\s+Confidence Level\s+\|\s+([A-Za-z]+)' 'confidence level'
    }
}

function Invoke-PowerFlow {
    param(
        [string]$ProjectRoot,
        [string]$ReportPrefix,
        [string]$VcdFile = ""
    )

    $env:PROJECT_ROOT_OVERRIDE = $ProjectRoot
    $env:POWER_REPORT_PREFIX = $ReportPrefix
    if ($VcdFile) {
        $env:POWER_VCD_FILE = $VcdFile
        $env:POWER_VCD_SCOPE = "cpu_core_u"
        $env:POWER_VCD_STRIP_PATH = "tb_cpu_top_isa/dut"
    } else {
        Remove-Item Env:POWER_VCD_FILE -ErrorAction SilentlyContinue
        Remove-Item Env:POWER_VCD_SCOPE -ErrorAction SilentlyContinue
        Remove-Item Env:POWER_VCD_STRIP_PATH -ErrorAction SilentlyContinue
    }

    & $VivadoBat -mode batch -source (Join-Path $CurrentProjectRoot "scripts\run_vivado_power.tcl")
    if ($LASTEXITCODE -ne 0) {
        throw "Vivado power run failed for $ProjectRoot ($ReportPrefix)"
    }

    Remove-Item Env:PROJECT_ROOT_OVERRIDE -ErrorAction SilentlyContinue
    Remove-Item Env:POWER_REPORT_PREFIX -ErrorAction SilentlyContinue
    Remove-Item Env:POWER_VCD_FILE -ErrorAction SilentlyContinue
    Remove-Item Env:POWER_VCD_SCOPE -ErrorAction SilentlyContinue
    Remove-Item Env:POWER_VCD_STRIP_PATH -ErrorAction SilentlyContinue
}

function Invoke-ProjectCommand {
    param(
        [string]$FilePath,
        [string[]]$Arguments
    )
    if ([System.IO.Path]::GetExtension($FilePath).ToLowerInvariant() -eq ".ps1") {
        $output = & powershell -ExecutionPolicy Bypass -File $FilePath @Arguments 2>&1
    } else {
        $output = & $FilePath @Arguments 2>&1
    }
    if ($LASTEXITCODE -ne 0) {
        $output | ForEach-Object { Write-Host $_ }
        throw "Command failed: $FilePath"
    }
    $output | ForEach-Object { Write-Host $_ }
    return @($output)
}

function Evaluate-Version {
    param(
        [string]$Label,
        [string]$ProjectRoot,
        [string]$CoreMarkRoot,
        [string]$ModelSimExe,
        [bool]$DoActivityPower
    )

    Write-Host "========== $Label =========="
    $verificationDir = Join-Path $ProjectRoot "verification"
    $scriptsDir = Join-Path $ProjectRoot "scripts"
    $reportsDir = Join-Path $ProjectRoot "reports"
    $generatedDir = Join-Path $verificationDir "generated"
    New-Item -ItemType Directory -Force -Path $reportsDir | Out-Null
    New-Item -ItemType Directory -Force -Path $generatedDir | Out-Null

    Invoke-ProjectCommand -FilePath (Join-Path $verificationDir "set_fpga_profile.ps1") -Arguments @()

    $coremark1 = Invoke-ProjectCommand -FilePath (Join-Path $verificationDir "run_coremark.ps1") -Arguments @(
        "-CoreMarkRoot", $CoreMarkRoot,
        "-ModelSimExe", $ModelSimExe,
        "-Iterations", "1"
    )
    $coremark10 = Invoke-ProjectCommand -FilePath (Join-Path $verificationDir "run_coremark.ps1") -Arguments @(
        "-CoreMarkRoot", $CoreMarkRoot,
        "-ModelSimExe", $ModelSimExe,
        "-Iterations", "10"
    )
    $matrix = Invoke-ProjectCommand -FilePath (Join-Path $verificationDir "run_matrix_benchmark.ps1") -Arguments @(
        "-ModelSimExe", $ModelSimExe
    )

    & $VivadoBat -mode batch -source (Join-Path $scriptsDir "run_vivado_impl.tcl")
    if ($LASTEXITCODE -ne 0) {
        throw "Vivado implementation failed for $ProjectRoot"
    }

    Invoke-PowerFlow -ProjectRoot $ProjectRoot -ReportPrefix "impl_power_vectorless"

    $activityStatus = "not-run"
    if ($DoActivityPower) {
        $matrixVcd = Join-Path $generatedDir "power_matrix_mul.vcd"
        try {
            Invoke-ProjectCommand -FilePath (Join-Path $verificationDir "run_matrix_benchmark.ps1") -Arguments @(
                "-ModelSimExe", $ModelSimExe,
                "-VcdFile", $matrixVcd
            ) | Out-Null
            Invoke-PowerFlow -ProjectRoot $ProjectRoot -ReportPrefix "impl_power_matrix_activity" -VcdFile $matrixVcd
            $activityStatus = "matrix-only"
        } catch {
            $activityStatus = "failed: $($_.Exception.Message)"
        }
    }

    $timing = Parse-TimingReport -ReportPath (Join-Path $reportsDir "impl_timing_summary.rpt")
    $power = Parse-PowerReport -ReportPath (Join-Path $reportsDir "impl_power_vectorless.rpt")

    $cyclesPerIter = (Parse-CoreMarkCycles -OutputLines $coremark10) / 10.0
    $throughputAt100 = 100000000.0 / $cyclesPerIter
    $throughputAtFmax = ($timing.FmaxMHz * 1000000.0) / $cyclesPerIter

    [pscustomobject]@{
        Label = $Label
        ProjectRoot = $ProjectRoot
        CoreMark1Cycles = Parse-CoreMarkCycles -OutputLines $coremark1
        CoreMark10Cycles = Parse-CoreMarkCycles -OutputLines $coremark10
        MatrixCycles = Parse-MatrixCycles -OutputLines $matrix
        WnsNs = $timing.WnsNs
        TnsNs = $timing.TnsNs
        FmaxMHz = $timing.FmaxMHz
        ThroughputAt100 = $throughputAt100
        ThroughputAtFmax = $throughputAtFmax
        DynamicW = $power.DynamicW
        StaticW = $power.StaticW
        TotalW = $power.TotalW
        Confidence = $power.Confidence
        ThroughputPerDynamicW = $throughputAtFmax / $power.DynamicW
        ThroughputPerTotalW = $throughputAtFmax / $power.TotalW
        ActivityPowerStatus = $activityStatus
    }
}

if (-not (Test-Path $CurrentProjectRoot)) {
    throw "Current project root not found: $CurrentProjectRoot"
}
if (-not (Test-Path $BaselineProjectRoot)) {
    throw "Baseline project root not found: $BaselineProjectRoot"
}
if (-not $env:RISCV_GCC -and (Test-Path (Join-Path $RiscvToolBin "riscv-none-elf-gcc.exe"))) {
    $env:RISCV_GCC = Join-Path $RiscvToolBin "riscv-none-elf-gcc.exe"
}
if (-not $env:RISCV_OBJCOPY -and (Test-Path (Join-Path $RiscvToolBin "riscv-none-elf-objcopy.exe"))) {
    $env:RISCV_OBJCOPY = Join-Path $RiscvToolBin "riscv-none-elf-objcopy.exe"
}
if (-not $env:RISCV_NM -and (Test-Path (Join-Path $RiscvToolBin "riscv-none-elf-nm.exe"))) {
    $env:RISCV_NM = Join-Path $RiscvToolBin "riscv-none-elf-nm.exe"
}
if (-not $env:RISCV_OBJDUMP -and (Test-Path (Join-Path $RiscvToolBin "riscv-none-elf-objdump.exe"))) {
    $env:RISCV_OBJDUMP = Join-Path $RiscvToolBin "riscv-none-elf-objdump.exe"
}

$currentResult = Evaluate-Version `
    -Label "current_low_power_v2" `
    -ProjectRoot $CurrentProjectRoot `
    -CoreMarkRoot $CoreMarkRoot `
    -ModelSimExe $ModelSimExe `
    -DoActivityPower (-not $SkipActivityPower)

$baselineResult = Evaluate-Version `
    -Label "perf_baseline_v1" `
    -ProjectRoot $BaselineProjectRoot `
    -CoreMarkRoot $CoreMarkRoot `
    -ModelSimExe $ModelSimExe `
    -DoActivityPower (-not $SkipActivityPower)

$summaryDir = Join-Path $CurrentProjectRoot "reports"
$summaryCsv = Join-Path $summaryDir "power_compare_summary.csv"
$summaryMd = Join-Path $summaryDir "power_compare_summary.md"

@($currentResult, $baselineResult) |
    Select-Object Label, CoreMark1Cycles, CoreMark10Cycles, MatrixCycles, WnsNs, TnsNs, FmaxMHz, ThroughputAt100, ThroughputAtFmax, DynamicW, StaticW, TotalW, Confidence, ThroughputPerDynamicW, ThroughputPerTotalW, ActivityPowerStatus |
    Export-Csv -NoTypeInformation -Path $summaryCsv -Encoding UTF8

$comparison = @"
# Power And Throughput Comparison

| Version | CoreMark 10 cycles | Fmax (MHz) | Throughput @100MHz (iter/s) | Throughput @Fmax (iter/s) | Dynamic (W) | Static (W) | Total (W) | iter/s/W dynamic | iter/s/W total | Confidence | Activity |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- | --- |
| $($currentResult.Label) | $([math]::Round($currentResult.CoreMark10Cycles, 0)) | $([math]::Round($currentResult.FmaxMHz, 2)) | $([math]::Round($currentResult.ThroughputAt100, 2)) | $([math]::Round($currentResult.ThroughputAtFmax, 2)) | $([math]::Round($currentResult.DynamicW, 3)) | $([math]::Round($currentResult.StaticW, 3)) | $([math]::Round($currentResult.TotalW, 3)) | $([math]::Round($currentResult.ThroughputPerDynamicW, 2)) | $([math]::Round($currentResult.ThroughputPerTotalW, 2)) | $($currentResult.Confidence) | $($currentResult.ActivityPowerStatus) |
| $($baselineResult.Label) | $([math]::Round($baselineResult.CoreMark10Cycles, 0)) | $([math]::Round($baselineResult.FmaxMHz, 2)) | $([math]::Round($baselineResult.ThroughputAt100, 2)) | $([math]::Round($baselineResult.ThroughputAtFmax, 2)) | $([math]::Round($baselineResult.DynamicW, 3)) | $([math]::Round($baselineResult.StaticW, 3)) | $([math]::Round($baselineResult.TotalW, 3)) | $([math]::Round($baselineResult.ThroughputPerDynamicW, 2)) | $([math]::Round($baselineResult.ThroughputPerTotalW, 2)) | $($baselineResult.Confidence) | $($baselineResult.ActivityPowerStatus) |

## Conclusion

- Lower dynamic power: $(if ($currentResult.DynamicW -lt $baselineResult.DynamicW) { $currentResult.Label } else { $baselineResult.Label })
- Higher throughput @ Fmax: $(if ($currentResult.ThroughputAtFmax -gt $baselineResult.ThroughputAtFmax) { $currentResult.Label } else { $baselineResult.Label })
- Better throughput / dynamic watt: $(if ($currentResult.ThroughputPerDynamicW -gt $baselineResult.ThroughputPerDynamicW) { $currentResult.Label } else { $baselineResult.Label })
"@

Set-Content -Path $summaryMd -Value $comparison -Encoding UTF8
Write-Host "Summary CSV: $summaryCsv"
Write-Host "Summary MD : $summaryMd"
