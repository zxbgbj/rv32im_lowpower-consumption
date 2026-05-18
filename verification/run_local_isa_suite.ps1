param(
    [string]$ModelSimExe = "vsim"
)

$tests = @(
    "rv32ui_add",
    "rv32ui_addi",
    "rv32ui_branch",
    "rv32ui_load_store",
    "rv32um_mul",
    "rv32um_div",
    "smoke_mcycle",
    "smoke_tohost",
    "smoke_tohost_c"
)

$pass = 0
$fail = 0
$runner = Join-Path $PSScriptRoot "run_smoke_isa.ps1"

foreach ($test in $tests) {
    Write-Host "== local isa suite: $test =="
    & $runner -Name $test -ModelSimExe $ModelSimExe
    if ($LASTEXITCODE -eq 0) {
        $pass++
    } else {
        $fail++
    }
}

Write-Host "local isa suite summary: PASS=$pass FAIL=$fail"
if ($fail -ne 0) { exit 1 }
