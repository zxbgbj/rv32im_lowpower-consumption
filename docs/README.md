# rv32im_low-power 图纸与设计文档索引

当前 `docs` 目录包含两类内容：

- 结构图纸：用于理解五级流水、控制流、前端、CSR 和 M 扩展单元。
- 设计说明：用于记录低功耗策略、时序瓶颈和性能评估口径。

## 图纸

1. [01_five_stage_topology.drawio](D:/Codex%20project/RISC-V%20CPU/rv32im_low-power/docs/01_five_stage_topology.drawio)
2. [02_datapath.drawio](D:/Codex%20project/RISC-V%20CPU/rv32im_low-power/docs/02_datapath.drawio)
3. [03_control_and_jump_paths.drawio](D:/Codex%20project/RISC-V%20CPU/rv32im_low-power/docs/03_control_and_jump_paths.drawio)
4. [04_hazard_forwarding.drawio](D:/Codex%20project/RISC-V%20CPU/rv32im_low-power/docs/04_hazard_forwarding.drawio)
5. [05_frontend_topology.drawio](D:/Codex%20project/RISC-V%20CPU/rv32im_low-power/docs/05_frontend_topology.drawio)
6. [06_csr_trap_munit.drawio](D:/Codex%20project/RISC-V%20CPU/rv32im_low-power/docs/06_csr_trap_munit.drawio)

建议阅读顺序：

`01 -> 02 -> 03 -> 04 -> 05 -> 06`

## 设计说明

7. [07_design_strategy.md](D:/Codex%20project/RISC-V%20CPU/rv32im_low-power/docs/07_design_strategy.md)

这份设计说明重点记录：

- 本项目的低功耗实现思路
- 当前 FPGA 实现时序瓶颈
- `CoreMark` 与矩阵乘法的性能口径
- 后续优化应遵循的取舍原则
