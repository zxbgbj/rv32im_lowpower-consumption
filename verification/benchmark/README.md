## Benchmark Flow

This directory provides a small bare-metal benchmark framework that reuses the
existing `tb_cpu_top_isa` execution path.

### Files

- `benchmark.ld`: local Harvard-memory linker script for benchmark ELFs
- `crt0.S`: minimal startup that zeros `.bss`, sets the stack, and exits by
  writing `tohost`
- `benchmark_support.[ch]`: `tohost`/signature helpers shared by local
  benchmarks
- `mini_libc.c`: tiny freestanding libc subset for benchmark builds
- `matrix_mul.c`: included local matrix-multiply benchmark

### Scripts

- `../build_benchmark.ps1`: compile a local or external benchmark into
  `verification/generated`
- `../run_benchmark.ps1`: build and run a benchmark on `tb_cpu_top_isa`
- `../run_matrix_benchmark.ps1`: convenience wrapper for the bundled matrix
  benchmark

### Notes

- The benchmark run flow automatically selects the verification memory profile.
- `tb_cpu_top_isa` now prints `cycles=<N>` on PASS so the run script can report
  simulation cycles directly.
- The local matrix benchmark writes a small summary into the signature region:
  `magic`, `status`, `bench_id`, `dim`, `iterations`, `checksum`, `c[0][0]`,
  `c[last][last]`.
