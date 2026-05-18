## Verification Flow

This directory contains the scripted verification flow for the `rv32im_low-power`
CPU project.

### Main entry points

- `build_smoke_elf.ps1`: build a tiny bare-metal ELF/HEX smoke program.
- `run_smoke_isa.ps1`: run the smoke program on `tb_cpu_top_isa`.
- `run_local_isa_suite.ps1`: run a small local directed ISA/M regression suite.
- `build_official_test.ps1`: compile an official `riscv-tests` source into local IMEM/DMEM HEX files.
- `run_official_test.ps1`: run one adapted official test source on `tb_cpu_top_isa`.
- `run_official_local_suite.ps1`: run a small official-source suite in the local low-address environment.
- `run_riscv_tests.ps1`: batch-run official `rv32ui` and `rv32um` binaries.
- `set_verification_profile.ps1`: select the large-memory verification profile.
- `set_fpga_profile.ps1`: restore the compact FPGA-target memory profile.
- `build_arch_act4_elfs.ps1`: generate ACT4 self-checking arch-test ELFs with the local DUT config.
- `build_arch_act4_elfs_wsl.ps1`: generate ACT4 self-checking arch-test ELFs inside Ubuntu WSL.
- `build_benchmark.ps1`: compile a local or external benchmark into IMEM/DMEM HEX files.
- `run_arch_test.ps1`: batch-run architecture tests with signature dump/compare.
- `run_benchmark.ps1`: build and run a benchmark on `tb_cpu_top_isa`.
- `run_matrix_benchmark.ps1`: run the bundled matrix benchmark and report simulation cycles.
- `run_coremark.ps1`: run CoreMark with the local bare-metal port once a CoreMark source tree is available.
- `compare_signature_files.py`: compare RTL signature output against ACT4 expected results.

### Required environment variables

- `RISCV_GCC_PREFIX`: optional cross-tool prefix such as
  `D:\tools\riscv\bin\riscv-none-elf-`
- `RISCV_GCC`: optional explicit GCC path
- `RISCV_OBJCOPY`: optional explicit objcopy path
- `RISCV_NM`: optional explicit nm path
- `RISCV_TESTS_ROOT`: root directory containing built `rv32ui-p-*` and
  `rv32um-p-*` binaries
- `RISCV_ARCH_TEST_ROOT`: root directory containing built architecture-test ELF
  files
### Recommended order

1. Run module and top-level smoke testbenches from `scripts/`.
2. Run `build_smoke_elf.ps1` and `run_smoke_isa.ps1`.
3. Run `run_local_isa_suite.ps1`.
4. Run `run_official_local_suite.ps1`.
5. Run `run_riscv_tests.ps1`.
6. Run `set_verification_profile.ps1`.
7. Run `build_arch_act4_elfs.ps1` or `build_arch_act4_elfs_wsl.ps1`.
8. Run `run_arch_test.ps1`.
9. Run `run_matrix_benchmark.ps1` and `run_coremark.ps1`.
10. Run `set_fpga_profile.ps1` before FPGA synthesis/resource reporting.
11. Run benchmark and FPGA validation flows.

### Manual ELF/HEX flow

You can also use the toolchain manually without scripts:

1. Compile source to ELF.
2. Use `objcopy -O verilog` to export IMEM HEX.
3. Use `nm` to extract symbols such as `tohost`.
4. Run `tb_cpu_top_isa` with `+IMEM_HEX=...` and `+TOHOST_ADDR=...`.

Example commands for the included smoke programs:

```powershell
riscv-none-elf-gcc -march=rv32im -mabi=ilp32 -nostdlib -nostartfiles -ffreestanding -fno-builtin -fno-stack-protector -O2 -Wl,-T,verification/smoke/smoke.ld -Wl,--no-relax -o verification/generated/smoke_tohost_c.elf verification/smoke/smoke_tohost_c.c
riscv-none-elf-objcopy -O verilog verification/generated/smoke_tohost_c.elf verification/generated/smoke_tohost_c.hex
riscv-none-elf-nm verification/generated/smoke_tohost_c.elf
```

The same flow works for assembly by replacing the source file with
`verification/smoke/smoke_tohost.S`.

### Local directed ISA tests

The following local tests are included so you can keep moving before the
official `riscv-tests` binaries are available:

- `rv32ui_add`
- `rv32ui_addi`
- `rv32ui_branch`
- `rv32ui_load_store`
- `rv32um_mul`
- `rv32um_div`

You can run the whole local suite with:

```powershell
.\run_local_isa_suite.ps1 -ModelSimExe "D:\software_fpga\Modelsim10_6\win64pe\vsim.exe"
```

### Adapted official-source tests

The `official/local_env` directory provides a small-address adapter for a subset
of official `riscv-tests` assembly sources. This keeps the official test source
but replaces the platform environment so the tests can run on the local
Harvard-memory testbench.

Run a single adapted official test:

```powershell
.\run_official_test.ps1 -ModelSimExe "D:\software_fpga\Modelsim10_6\win64pe\vsim.exe" -TestsRoot "D:\riscv-tests-git" -Suite rv32ui -Test add
```

Run the bundled adapted-official suite:

```powershell
.\run_official_local_suite.ps1 -ModelSimExe "D:\software_fpga\Modelsim10_6\win64pe\vsim.exe" -TestsRoot "D:\riscv-tests-git"
```

### Notes

- `tb_cpu_top_isa.v` is the generic ISA bench used by the scripted ELF flows.
- `run_riscv_tests.ps1` checks pass/fail through the `tohost` convention.
- `run_arch_test.ps1` dumps RTL signature memory and compares it to ACT4/Sail-generated expected results.
- `run_benchmark.ps1` also uses the `tohost` convention and now parses the
  `cycles=<N>` marker printed by `tb_cpu_top_isa`.
- `verification/arch/local_config` stores the local DUT config used to generate
  ACT4 ELFs for this CPU.
- The official ISA and architecture scripts expect prebuilt test binaries. If
  you only have source trees, build those tests first.

### Benchmarks

The new `benchmark` directory provides a small bare-metal runtime plus a local
matrix-multiply benchmark so longer-running software can use the same
`ELF -> IMEM/DMEM HEX -> tb_cpu_top_isa` flow as the ISA suites.

Run the bundled matrix benchmark:

```powershell
.\run_matrix_benchmark.ps1 -ModelSimExe "D:\software_fpga\Modelsim10_6\win64pe\vsim.exe"
```

Run CoreMark after placing a standard CoreMark source tree somewhere local:

```powershell
.\run_coremark.ps1 -CoreMarkRoot "D:\benchmarks\coremark" -ModelSimExe "D:\software_fpga\Modelsim10_6\win64pe\vsim.exe"
```

### Memory profiles

This project now separates two memory-capacity goals:

- Verification profile:
  - larger IMEM/DMEM for long official ISA suites and ACT4 arch-test
  - select with:

    ```powershell
    .\set_verification_profile.ps1
    ```

- FPGA profile:
  - compact IMEM/DMEM for implementation, utilization, timing, and power reports
  - select with:

    ```powershell
    .\set_fpga_profile.ps1
    ```

The active profile is stored in:

- `rtl/memory_profile_overrides.vh`

So the recommended project story is:

- verify correctness with the verification profile
- report FPGA implementation results with the FPGA profile
