# Power Evaluation Status

## Completed

- Archived the current low-power workspace to:
  - `D:\Codex project\RISC-V CPU\lowest_resource_consumption_version`
- Created an isolated comparison workspace:
  - `D:\Codex project\RISC-V CPU\rv32im_perf_baseline_v1`
- Added reusable power-evaluation infrastructure:
  - `scripts/run_vivado_power.tcl`
  - `verification/run_power_compare.ps1`
  - optional VCD export hook in `tb/tb_cpu_top_isa.v`
- Added methodology documentation:
  - `docs/09_power_evaluation_method.md`

## Current Version Power

The current low-power version already has a routed, vector-less Vivado power report:

- Report path:
  - `D:\Codex project\RISC-V CPU\rv32im_low-power\vivado_proj\rv32im_low_power_zynq7000.runs\impl_1\cpu_fpga_top_power_routed.rpt`
- Key numbers:
  - `Total On-Chip Power = 0.151 W`
  - `Dynamic = 0.048 W`
  - `Static = 0.103 W`
  - `Confidence = Medium`

This is a valid first-pass FPGA power estimate for the current version.

## Baseline Reconstruction Attempt

The requested "first version" was defined as the earlier performance baseline with:

- `CoreMark 10 iter = 4,218,156 cycles`
- `WNS = -1.732 ns`

An isolated baseline workspace was created and only the second-round timing RTL edits were reverted in:

- `rtl/cpu_top.v`
- `rtl/ex_stage.v`

However, after rebuilding and running `CoreMark(1 iter)`, the reconstructed baseline still measured:

- `CoreMark 1 iter = 472,249 cycles`

This matches the current version's degraded behavior rather than the recorded first-version behavior. That means:

- the true "first version" is not fully recoverable from the currently available workspace files
- it was not just the local timing edits in `cpu_top.v` and `ex_stage.v`
- a trustworthy first-version power comparison cannot be produced until an actual source snapshot of that version is available

## Conclusion

- The current low-power version has a valid routed vector-less power estimate.
- The true first-version source snapshot is not present in the current workspace.
- Therefore, a rigorous "current version vs true first version" power comparison is currently blocked by missing baseline source state, not by missing tooling.

## Next Best Action

If the exact first-version source directory or archive can be provided, the new scripts are ready to run:

- benchmark regression
- routed power estimation
- throughput / watt comparison

without changing the current main workspace.
