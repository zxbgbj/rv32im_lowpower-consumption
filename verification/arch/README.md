## ACT4 Arch-Test Adapter

This directory contains a local `riscv-arch-test` configuration for the
`rv32im_low-power` CPU.

### What this config is for

The upstream `riscv-arch-test` ACT4 flow needs a DUT-specific configuration:

- `test_config.yaml`
- a UDB architecture config
- `rvmodel_macros.h`
- `link.ld`
- `rvtest_config.h`

This local config adapts the ACT4 flow to the current low-address Harvard-memory
testbench used by `tb_cpu_top_isa`.

### Current assumptions

- ISA baseline: `rv32im_zicsr`
- optional local support for `Zifencei`
- no compressed extension
- no PMP entries
- privilege tests are disabled for now
- code starts at address `0x00000000`
- `tohost` is placed at `0x0006F000`
- `.data` / signature region starts at `0x00070000`

### Recommended flow

1. Generate self-checking ELFs with:

   ```powershell
   .\build_arch_act4_elfs.ps1 -ArchTestRoot "D:\riscv-arch-test-git"
   ```

2. After ELFs are generated, point `RISCV_ARCH_TEST_ROOT` at:

   ```text
   D:\Codex project\RISC-V CPU\rv32im_low-power\verification\generated\arch-act4\work\rv32im-low-power-act4\elfs
   ```

3. Run the existing RTL-vs-reference signature flow with:

   ```powershell
   $env:RISCV_ARCH_TEST_ROOT = "D:\Codex project\RISC-V CPU\rv32im_low-power\verification\generated\arch-act4\work\rv32im-low-power-act4\elfs"
   .\run_arch_test.ps1 -ModelSimExe "D:\software_fpga\Modelsim10_6\win64pe\vsim.exe"
   ```

### Known external prerequisites

The ACT4 ELF-generation step depends on upstream tools that are not bundled in
this workspace:

- `make`
- `sail_riscv_sim`
- `uv` or `mise` or an already-prepared ACT4 Python environment
- Ruby/Bundler for the UDB gem

The helper script checks for the most important blockers first and prints the
exact missing tools before trying to invoke the upstream flow.
