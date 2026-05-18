param(
    [string]$ModelSimExe = "vsim",
    [string]$TestsRoot = "D:\riscv-tests-git",
    [switch]$DebugIsa
)

$ErrorActionPreference = "Stop"

$tests = @(
    @{ Suite = "rv32ui"; Test = "add"   },
    @{ Suite = "rv32ui"; Test = "addi"  },
    @{ Suite = "rv32ui"; Test = "sub"   },
    @{ Suite = "rv32ui"; Test = "and"   },
    @{ Suite = "rv32ui"; Test = "andi"  },
    @{ Suite = "rv32ui"; Test = "or"    },
    @{ Suite = "rv32ui"; Test = "ori"   },
    @{ Suite = "rv32ui"; Test = "xor"   },
    @{ Suite = "rv32ui"; Test = "xori"  },
    @{ Suite = "rv32ui"; Test = "sll"   },
    @{ Suite = "rv32ui"; Test = "slli"  },
    @{ Suite = "rv32ui"; Test = "srl"   },
    @{ Suite = "rv32ui"; Test = "srli"  },
    @{ Suite = "rv32ui"; Test = "sra"   },
    @{ Suite = "rv32ui"; Test = "srai"  },
    @{ Suite = "rv32ui"; Test = "slt"   },
    @{ Suite = "rv32ui"; Test = "slti"  },
    @{ Suite = "rv32ui"; Test = "sltu"  },
    @{ Suite = "rv32ui"; Test = "sltiu" },
    @{ Suite = "rv32ui"; Test = "lui"   },
    @{ Suite = "rv32ui"; Test = "auipc" },
    @{ Suite = "rv32ui"; Test = "beq"   },
    @{ Suite = "rv32ui"; Test = "bne"   },
    @{ Suite = "rv32ui"; Test = "blt"   },
    @{ Suite = "rv32ui"; Test = "bge"   },
    @{ Suite = "rv32ui"; Test = "bltu"  },
    @{ Suite = "rv32ui"; Test = "bgeu"  },
    @{ Suite = "rv32ui"; Test = "jal"   },
    @{ Suite = "rv32ui"; Test = "jalr"  },
    @{ Suite = "rv32ui"; Test = "lb"    },
    @{ Suite = "rv32ui"; Test = "lbu"   },
    @{ Suite = "rv32ui"; Test = "lh"    },
    @{ Suite = "rv32ui"; Test = "lhu"   },
    @{ Suite = "rv32ui"; Test = "lw"    },
    @{ Suite = "rv32ui"; Test = "sb"    },
    @{ Suite = "rv32ui"; Test = "sh"    },
    @{ Suite = "rv32ui"; Test = "sw"    },
    @{ Suite = "rv32um"; Test = "mul"   },
    @{ Suite = "rv32um"; Test = "mulh"  },
    @{ Suite = "rv32um"; Test = "mulhsu"},
    @{ Suite = "rv32um"; Test = "mulhu" },
    @{ Suite = "rv32um"; Test = "div"   },
    @{ Suite = "rv32um"; Test = "divu"  },
    @{ Suite = "rv32um"; Test = "rem"   },
    @{ Suite = "rv32um"; Test = "remu"  }
)

$pass = 0
$fail = 0
$runner = Join-Path $PSScriptRoot "run_official_test.ps1"

foreach ($entry in $tests) {
    Write-Host "== official local suite: $($entry.Suite)/$($entry.Test) =="
    $runnerParams = @{
        ModelSimExe = $ModelSimExe
        TestsRoot   = $TestsRoot
        Suite       = $entry.Suite
        Test        = $entry.Test
    }
    if ($DebugIsa) {
        $runnerParams.DebugIsa = $true
    }

    try {
        & $runner @runnerParams
        if ($LASTEXITCODE -eq 0) {
            $pass++
        } else {
            $fail++
        }
    } catch {
        $fail++
        Write-Host "official local suite error: $($entry.Suite)/$($entry.Test)" -ForegroundColor Red
        Write-Host $_ -ForegroundColor Red
    }
}

Write-Host "official local suite summary: PASS=$pass FAIL=$fail"
if ($fail -ne 0) { exit 1 }
