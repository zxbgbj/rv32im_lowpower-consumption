# README v5

## 1. Project Snapshot

`rv32im_low_power_v5` is the current `v5` working branch of a low-power `RV32IM`
soft CPU for `Xilinx Zynq-7000 XC7Z020`.

This version is no longer only an RTL sandbox. It already includes:

- a verified 5-stage single-issue `RV32IM` core
- minimal machine-mode privilege support
- scripted RTL / ISA / arch-test / benchmark verification flows
- FPGA implementation scripts and reports
- PS+PL benchmark bring-up for `CoreMark` and `matrix_mul`
- ready-made board artifacts such as `.bit`, `.hdf/.hwdef`, and `BOOT.BIN`

The present project story is:

1. complete correctness verification in simulation
2. keep `v5` as the strongest board-bring-up candidate
3. use `v2` as the low-resource / timing-reference branch
4. continue with physical board validation on the Zynq-7020 platform

## 2. Design Goal

Project goal:

- ISA: `RV32I + M`
- microarchitecture: 5-stage, single-issue, in-order pipeline
- board target: `Zynq-7020 XC7Z020`
- toolchain: `Vivado 2018.3`, `ModelSim/Questa`, RISC-V GCC toolchain
- direction: low power first, while pushing toward the performance target

Current privilege scope:

- minimal machine-mode only
- implemented around `csr_file.v`
- supports basic CSR access, trap entry, `mret`, and `mcycle`

Important note:

- historical project notes use a `CoreMark`-based convergence metric around
  `250 iter/s @ 100 MHz`
- that is a project-internal performance proxy, not a literal ISA-level `MIPS`
  definition

## 3. Why v5 Matters

Among the preserved low-power iterations, `v5` is the strongest combined
performance candidate currently kept in the repository.

From `version_comparison_report_v1_to_v5.md`:

- `CoreMark avg`: `396838.9 cycles/iter`
- normalized `100 MHz` view: about `252.00 iter/s`
- estimated routed `fmax`: about `89.43 MHz`
- estimated routed throughput: about `225.36 iter/s`
- dynamic power: about `0.035 W`

This means:

- cycle efficiency has already crossed the internal `250 iter/s @ 100 MHz`
  reference
- the remaining bottleneck is routed frequency, not benchmark cycle count alone

Also important:

- `improvement_report_19.md` records one later experiment
- that experiment was rejected
- the workspace was restored to the accepted round-17 baseline afterward
- so the mainline `v5` RTL here should be treated as the accepted baseline for
  board validation

## 4. Directory Map

- `rtl/`: core RTL, wrappers, BRAMs, predictor, CSR, M-unit, board tops
- `tb/`: module-level and top-level testbenches
- `verification/`: scripted ISA, arch-test, benchmark, and board-benchmark flow
- `scripts/`: ModelSim and Vivado entry scripts
- `constraints/`: XDC files for pure PL and PS+PL builds
- `reports/`: implementation, timing, utilization, and power reports
- `bitstreams/`: generated board-ready `.bit` files
- `artifacts/`: exported handoff files and packaged boot images
- `software/ps_bench_reporter/`: PS-side UART reporter application
- `docs/`: architecture notes and draw.io diagrams

## 5. RTL Architecture

### 5.1 Core Top

The main CPU top is `rtl/cpu_top.v`.

It integrates:

- fetch front end
- decode
- ID/EX, EX/MEM, MEM/WB pipeline registers
- hazard and forwarding logic
- execute stage
- memory stage
- write-back stage
- `RV32M` multiply/divide unit
- branch predictor + BTB + return-address stack support
- minimal CSR / trap path

Visible top-level signals include:

- instruction and data memory interfaces
- fetch / prediction debug outputs
- redirect outputs
- issue stall / EX busy / M-unit status
- trap outputs

### 5.2 Front End

`rtl/front_end.v` is the fetch-side control center.

It contains:

- `pc_manager.v`
- `branch_predictor.v`
- `btb.v`
- a small return-address stack
- `imem_bram.v`

Behavior highlights:

- direct-mapped target prediction through `BTB`
- conditional direction prediction through `BHT`
- call/return-aware RAS handling
- explicit `imem_en` gating for FPGA-friendly low-power fetch behavior
- redirect handling from branch recovery, trap return, and direct jump correction

### 5.3 Decode / Execute / Memory

Key files:

- `decoder_rv32im.v`: decodes `RV32I`, `RV32M`, CSR, `ecall`, `ebreak`, `mret`,
  and `fence.i`
- `imm_gen.v`: immediate generation
- `hazard_unit.v`: hazard detection
- `forward_unit.v`: forwarding selection
- `ex_stage.v`: ALU, branch resolution, redirect/mispredict logic, CSR write
  path, trap request generation
- `mem_stage.v`: load/store handling
- `wb_stage.v`: final write-back selection

### 5.4 M Extension

`rtl/m_unit.v` implements the `M` extension.

Low-power / FPGA-oriented direction:

- multiplication is mapped in a DSP-friendly style
- division and remainder use an iterative state machine
- this keeps the pipeline simple and avoids unnecessary fully combinational
  divider cost

### 5.5 CSR and Trap Support

`rtl/csr_file.v` is intentionally minimal.

Implemented CSRs include:

- `mstatus`
- `mtvec`
- `mscratch`
- `mepc`
- `mcause`
- `mcycle / mcycleh`
- `cycle / cycleh`

This is enough for:

- trap entry
- `mret`
- cycle counting
- basic machine-mode software execution

### 5.6 Memory Profile Switching

The memory profile is controlled by:

- `rtl/memory_profile.vh`
- `rtl/memory_profile_overrides.vh`

Default fallback values inside `memory_profile.vh` are:

- `IMEM = 1024 words`
- `DMEM = 1024 words`

But the currently checked-in override file is set to the board benchmark profile:

- `IMEM = 8192 words`
- `DMEM = 8192 words`

So before running different flows, pay attention to:

- `verification/set_verification_profile.ps1`
- `verification/set_fpga_profile.ps1`
- `verification/set_board_benchmark_profile.ps1`

## 6. Board and Wrapper Tops

This repository now contains multiple top-level integration styles.

### 6.1 Pure PL Bring-Up

`rtl/cpu_fpga_top.v` is the simpler FPGA wrapper.

It provides:

- heartbeat LED
- PL UART output
- `tohost`-based pass/fail reporting
- trap reporting

This top is suitable for:

- pure PL smoke validation
- lightweight board observation

### 6.2 PL Benchmark Wrapper

`rtl/cpu_board_pl.v` is the benchmark-oriented PL wrapper.

It adds:

- benchmark status packing
- cycle count capture
- `tohost` and signature observation
- PS-visible status words
- optional PL UART debug text

Specialized wrappers:

- `cpu_board_coremark_pl.v`
- `cpu_board_matrix_pl.v`

These wrappers bind the generated benchmark memory images directly into the
core.

### 6.3 PS+PL Tops

Board-ready benchmark tops:

- `rtl/cpu_pspl_coremark_top.v`
- `rtl/cpu_pspl_matrix_top.v`

They instantiate:

- `processing_system7_0`
- the corresponding PL benchmark wrapper

In this flow:

- PS7 provides the `80 MHz` clock and reset framework
- PL still runs the RISC-V benchmark
- PS GPIO reads benchmark status and cycle count
- PS UART is the formal result channel

### 6.4 PS Reporter Software

`software/ps_bench_reporter/main.c` is the PS-side bare-metal reporter.

It:

- reads GPIO status exported from PL
- prints benchmark name
- prints cycle count
- prints pass/fail/trap status over PS UART

## 7. Verification Flow

The generic execution bench is `tb/tb_cpu_top_isa.v`.

It supports plusargs such as:

- `IMEM_HEX`
- `DMEM_HEX`
- `TOHOST_ADDR`
- `SIG_START`
- `SIG_END`
- `SIG_FILE`
- `MAX_CYCLES`

This makes it the common bridge for:

- smoke tests
- local ISA tests
- official-source adapted tests
- architecture tests
- benchmarks

### 7.1 Module and Directed Testbenches

Representative module / directed TBs:

- `tb_alu.v`
- `tb_branch_predictor.v`
- `tb_btb.v`
- `tb_csr_file.v`
- `tb_m_unit.v`
- `tb_cpu_top_forwarding.v`
- `tb_cpu_top_load_hazard.v`
- `tb_cpu_top_control_flow.v`
- `tb_cpu_top_m_extension.v`
- `tb_cpu_top_mmode.v`
- `tb_cpu_top_rv32im_full.v`

Main launcher:

```powershell
cd "D:\Codex project\RISC-V CPU\rv32im_low_power_v5\scripts"
.\run_modelsim_tb.ps1 -Testbench tb_cpu_top_rv32im_full
```

### 7.2 ISA and Architecture Verification

Main verification entry points:

- `verification/build_smoke_elf.ps1`
- `verification/run_smoke_isa.ps1`
- `verification/run_local_isa_suite.ps1`
- `verification/run_official_local_suite.ps1`
- `verification/run_riscv_tests.ps1`
- `verification/build_arch_act4_elfs.ps1`
- `verification/build_arch_act4_elfs_wsl.ps1`
- `verification/run_arch_test.ps1`

Recommended order:

1. module and directed TBs
2. smoke ELF flow
3. local ISA suite
4. adapted official local suite
5. official `riscv-tests`
6. arch-test build
7. arch-test execution
8. benchmark execution

### 7.3 Benchmark Verification

Main benchmark scripts:

- `verification/run_matrix_benchmark.ps1`
- `verification/run_coremark.ps1`
- `verification/run_benchmark.ps1`

Board-oriented benchmark scripts:

- `verification/build_board_benchmark.ps1`
- `verification/run_board_benchmark.ps1`
- `verification/run_board_coremark.ps1`

From the recorded board-profile simulation status:

- matrix benchmark: `PASS`, about `582552 cycles`
- CoreMark (`10` iterations): `PASS`, `3975611 cycles`

## 8. FPGA Status

### 8.1 Core v5 Implementation View

For the accepted `v5` core itself, the preserved comparison note reports:

- `LUT as Logic = 3291`
- `Slice LUTs = 3675`
- `Registers = 2546`
- `DSP = 12`
- `BRAM = 2`
- estimated `fmax = 89.43 MHz`
- estimated routed throughput `~225.36 iter/s`
- dynamic power `~0.035 W`

This is the best preserved high-performance / low-power balance among the
archived candidate versions.

### 8.2 PS+PL 80 MHz Build View

The newer PS+PL benchmark top already closes timing at `80 MHz`.

From `fpga_board_result_2.md` and the routed reports:

- design: `cpu_pspl_coremark_top`
- timing constraint: `12.500 ns` (`80 MHz`)
- `WNS = 0.343 ns`
- `TNS = 0`
- `Slice LUTs = 3992`
- `LUT as Logic = 3608`
- `Slice Registers = 2751`
- `Block RAM Tile = 16`
- `DSP = 12`

Power report summary:

- total on-chip power: `1.710 W`
- dynamic: `1.567 W`
- static: `0.143 W`

Important interpretation:

- this power number is vector-less and low-confidence
- PS7 dominates the total
- PL benchmark hierarchy is only a small fraction of the total

## 9. Existing Board Artifacts

Important generated files:

- `bitstreams/cpu_fpga_top_v5.bit`
- `bitstreams/cpu_pspl_coremark_80m.bit`
- `bitstreams/cpu_pspl_matrix_80m.bit`
- `artifacts/pspl_coremark.hdf`
- `artifacts/pspl_matrix.hdf`
- `artifacts/BOOT_coremark.bin`
- `artifacts/BOOT_matrix.bin`

These already cover:

- JTAG programming
- SDK/XSCT handoff
- boot image packaging for later QSPI solidification

## 10. Current Project Status

What is already complete:

- soft-core RTL design
- directed and ISA-level verification flow
- arch-test flow integration
- benchmark flow integration
- multi-round performance iteration from `v1` to `v5`
- `v5` PS+PL `80 MHz` build closure
- bitstream and boot-image generation

What is still pending:

- physical board-side JTAG validation of the `80 MHz` PS+PL images
- confirmation of `PS UART` output on the real board
- capture of real board `CoreMark` and matrix result printouts
- first `BOOT.BIN` / `QSPI` validation

## 11. Suggested Next Step for v5 Validation

If the next milestone is board validation, the most practical order is:

1. JTAG-download `bitstreams/cpu_pspl_coremark_80m.bit`
2. confirm `PS UART` prints `BOOT`, benchmark name, cycle count, and `PASS/FAIL`
3. repeat with `bitstreams/cpu_pspl_matrix_80m.bit`
4. compare on-board cycle reports with the recorded simulation baselines
5. move to `artifacts/BOOT_coremark.bin` and `artifacts/BOOT_matrix.bin`
6. attempt the first `QSPI` boot validation

For this stage, the most important files are:

- `fpga_board_result_2.md`
- `verification/run_board_benchmark.ps1`
- `verification/run_board_coremark.ps1`
- `rtl/cpu_board_pl.v`
- `rtl/cpu_pspl_coremark_top.v`
- `rtl/cpu_pspl_matrix_top.v`
- `software/ps_bench_reporter/main.c`

## 12. Reading Order for a New Contributor

Recommended reading order:

1. `version_comparison_report_v1_to_v5.md`
2. `fpga_board_result_2.md`
3. `rtl/cpu_top.v`
4. `rtl/front_end.v`
5. `rtl/decoder_rv32im.v`
6. `rtl/ex_stage.v`
7. `rtl/m_unit.v`
8. `rtl/csr_file.v`
9. `tb/tb_cpu_top_isa.v`
10. `verification/README.md`
11. `docs/README.md`

That reading order is enough to understand:

- why `v5` was kept
- how the pipeline is organized
- how the benchmark flow works
- where the board-validation work should continue next
