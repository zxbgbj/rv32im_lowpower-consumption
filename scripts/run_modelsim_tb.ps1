param(
    [string]$ModelSimExe = "vsim",
    [string]$Testbench = "tb_cpu_top",
    [string[]]$ExtraArgs = @(),
    [switch]$SkipCompile,
    [switch]$CompileOnly
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$reportsDir = Join-Path $projectRoot "reports\modelsim"
New-Item -ItemType Directory -Force -Path $reportsDir | Out-Null

$logPath = Join-Path $reportsDir ($Testbench + ".log")
New-Item -ItemType File -Force -Path $logPath | Out-Null

$scriptDirTcl = ($scriptDir -replace "\\", "/")
$projectRootTcl = ($projectRoot -replace "\\", "/")
$extra = if ($ExtraArgs.Count -gt 0) { " " + ($ExtraArgs -join " ") } else { "" }
$skipCompileTcl = if ($SkipCompile) { 1 } else { 0 }
$compileOnlyTcl = if ($CompileOnly) { 1 } else { 0 }

# Pass the project root and testbench name through Tcl variables so the
# .do file does not depend on ModelSim argv or pref.tcl script context.
$cmd = "set PROJECT_ROOT {" + $projectRootTcl + "}; set TB_NAME {" + $Testbench + "}; set EXTRA_ARGS {" + $extra.Trim() + "}; set SKIP_COMPILE " + $skipCompileTcl + "; set COMPILE_ONLY " + $compileOnlyTcl + "; do {" + $scriptDirTcl + "/run_modelsim_tb.do}; quit -f"

Write-Host "Launching ModelSim for $Testbench"
Write-Host "Log file: $logPath"
Write-Host "Command: $cmd"

$output = & $ModelSimExe -c -do $cmd 2>&1
$output | Tee-Object -FilePath $logPath
exit $LASTEXITCODE
