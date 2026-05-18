# rv32im_low_power_v5

## 中文说明

### 1. 项目简介

`rv32im_low_power_v5` 是一个面向 FPGA 的低功耗 `RV32IM` 软核 CPU 项目，
目标平台为 `Xilinx Zynq-7000 XC7Z020`。该处理器采用五级流水、单发射、
顺序执行架构，当前仓库已经整理为适合版本管理和公开展示的 `v5` 主版本。

这个版本不是单纯的 RTL 练习工程，而是一个已经具备较完整验证与实现链路的
RISC-V 处理器项目，包含：

- 五级流水 `RV32IM` 核心 RTL
- 基本的 `M-mode / CSR / trap / mret / mcycle` 支持
- hazard detection 与 forwarding 机制
- `RV32M` 乘除法单元
- 前端分支预测、`BTB` 与返回地址栈
- 仿真、ISA、arch-test、benchmark 验证脚本
- 面向 FPGA 的综合、实现与功耗/时序报告
- 面向 `CoreMark` 与 `matrix_mul` 的板级验证路径

### 2. 项目目标

本项目希望在有限 FPGA 资源下，完成一个结构清晰、可验证、可复现、可扩展的
`RV32IM` 处理器实现，并尽量在以下目标之间取得平衡：

- 正确性
- 性能
- 低功耗
- 工程可复现性
- 板级落地能力

这既是一个处理器设计项目，也是一个逐步沉淀验证方法、性能迭代记录和 FPGA
部署经验的工程化项目。

### 3. 当前版本定位

`v5` 是目前保留下来的成熟主版本，默认应视为后续工作的主要基线。

默认工作理解：

- ISA：`RV32I + M`
- 架构：五级流水、单发射、顺序执行
- 特权支持：最小 `M-mode`
- 主要板级目标：`90m` 路线
- 主要 benchmark：`CoreMark` 与 `matrix_mul`

项目内部历史上做过多轮性能与功耗迭代，`v5` 是综合平衡最强的一版。根据已接
受的基线记录，代表性结果包括：

- `CoreMark 10 iter = 3968389 cycles`
- `CoreMark avg = 396838.9 cycles/iter`
- `matrix_mul = 582544 cycles`
- 估计综合后吞吐约 `225.36 iter/s`
- 估计 `fmax` 约 `89.43 MHz`

面向最终板级交付时，建议优先参考 `90m` 相关结果，而不是历史性的 `100m`
探索版本。

### 4. 仓库结构

- `rtl/`：核心 RTL、前端、流水级、乘除法单元、CSR、板级顶层封装
- `tb/`：模块级与顶层 testbench
- `verification/`：ISA、arch-test、benchmark、板级 benchmark 脚本
- `scripts/`：ModelSim / Vivado / XSCT 相关脚本
- `constraints/`：XDC 约束
- `reports/`：综合、实现、时序、功耗、利用率报告
- `docs/`：架构说明与设计笔记
- `drawio/`：配图与结构图
- `mem/`：本地测试和定向验证用的存储初始化文件
- `software/ps_bench_reporter/`：PS 侧结果回读与串口打印程序

### 5. 核心实现特征

#### 5.1 流水线

主核心位于 `rtl/cpu_top.v`，组织方式为标准五级流水：

- IF
- ID
- EX
- MEM
- WB

配套实现包括：

- `hazard_unit.v`
- `forward_unit.v`
- `pipeline_regs.v`
- `decoder_rv32im.v`
- `ex_stage.v`
- `mem_stage.v`
- `wb_stage.v`

#### 5.2 前端与预测

前端核心位于 `rtl/front_end.v`，集成：

- `pc_manager.v`
- `branch_predictor.v`
- `btb.v`
- 小型返回地址栈
- `imem_bram.v`

这一部分体现了项目相对很多教学型 RV32I 仓库更完整的地方：不仅有基本流水，
还显式加入了前端预测与低功耗取指控制。

#### 5.3 M 扩展与低功耗导向

`rtl/m_unit.v` 实现 `RV32M`，设计思路偏向 FPGA 友好与低功耗：

- 乘法采用 DSP 友好映射
- 除法/取余采用迭代状态机

这样可以在保持功能完整的同时，避免高代价的全组合除法器。

#### 5.4 CSR 与最小机器态支持

`rtl/csr_file.v` 实现了本项目所需的最小机器态支持，覆盖：

- `mstatus`
- `mtvec`
- `mscratch`
- `mepc`
- `mcause`
- `mcycle / mcycleh`
- `cycle / cycleh`

这足以支持：

- trap 进入
- `mret`
- 周期计数
- 基本 machine-mode 软件运行

### 6. 验证与 benchmark

本仓库不是只“跑通几个样例”，而是已经带有较系统的验证入口。

通用执行 testbench 为 `tb/tb_cpu_top_isa.v`，可供以下流程复用：

- smoke 测试
- 本地 ISA 测试
- official-source 适配测试
- arch-test
- benchmark

常见脚本包括：

- `verification/run_smoke_isa.ps1`
- `verification/run_local_isa_suite.ps1`
- `verification/run_riscv_tests.ps1`
- `verification/run_arch_test.ps1`
- `verification/run_coremark.ps1`
- `verification/run_matrix_benchmark.ps1`
- `verification/run_board_benchmark.ps1`

推荐验证顺序：

1. 模块级 testbench
2. smoke
3. 本地 ISA 套件
4. `riscv-tests`
5. arch-test
6. benchmark
7. 板级 benchmark

### 7. FPGA 与板级状态

当前仓库已经保留了 FPGA 相关脚本、封装和关键报告，可继续支撑板级验证工作。

已知的实践结论包括：

- `v5` 是当前主要基线
- `90m` 是最终更实用的板级目标
- `100m` 更适合视为历史探索
- `PS+PL` 路线是当前板级验证重点

已记录的板级 benchmark 代表结果：

- `CoreMark 10 iter = 3975611 cycles`
- `matrix_mul = 582552 cycles`

在板级验证上，一个已知 caveat 是：

- 板载 `CH340` 串口路径不一定对应设计里使用的 `PS UART`

因此在某些情况下，更可靠的证明方式是：

- `JTAG / XSCT`
- `GPIO` 状态字回读
- `GPIO` 周期计数回读

### 8. 适合谁阅读和继续开发

这个仓库适合以下用途：

- RISC-V 五级流水 CPU 课程或毕业设计参考
- Verilog / FPGA 处理器项目展示
- 低功耗导向处理器实现案例
- 带 benchmark 与板级验证链路的教学型工程
- 后续继续扩展 `privilege / SoC / board bring-up` 的基线工程

### 9. 下一步建议

如果继续推进 `v5`，比较建议的方向是：

1. 补强公开仓库层面的使用说明和验证命令示例
2. 继续沉淀 `90m` 板级验证证据
3. 补充更标准化的 compliance / regression 结果
4. 逐步加入更自动化的 CI 检查
5. 继续整理 benchmark、功耗、时序结果的对外呈现

---

## English Summary

`rv32im_low_power_v5` is a low-power FPGA-oriented `RV32IM` soft CPU targeting
the `Xilinx Zynq-7000 XC7Z020`. It implements a 5-stage, single-issue,
in-order pipeline with `RV32M`, basic machine-mode CSR/trap support, hazard
detection, forwarding, branch prediction, benchmark flows, and FPGA build
scripts.

This repository already goes beyond a small RTL demo. It includes:

- core RTL in `rtl/`
- module and top-level testbenches in `tb/`
- scripted ISA / arch-test / benchmark flows in `verification/`
- Vivado / ModelSim / XSCT scripts in `scripts/`
- FPGA timing, utilization, and power reports in `reports/`
- architecture notes in `docs/`

The `v5` branch should be treated as the main mature baseline. The preferred
board-validation focus is the `90m` path, with `CoreMark` and `matrix_mul` as
the main practical benchmark targets.

Representative accepted metrics include:

- `CoreMark 10 iter = 3968389 cycles`
- `CoreMark avg = 396838.9 cycles/iter`
- `matrix_mul = 582544 cycles`
- estimated routed throughput `~225.36 iter/s`
- estimated `fmax ~89.43 MHz`

For board-level proof, note that the board-side `CH340` UART path may not
always match the PS UART used by the design, so `JTAG / XSCT + GPIO readback`
can be the more reliable validation route.
