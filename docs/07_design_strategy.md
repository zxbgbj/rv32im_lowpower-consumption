# rv32im_low-power 设计说明

## 1. 项目定位

本项目面向 `Xilinx Zynq-7000 XC7Z020` FPGA，实现了一颗以低功耗和可落地实现为导向的 `RV32IM` 五级单发射流水 CPU。设计目标不是单纯压缩资源，也不是片面追求理论 IPC，而是在保持基础性能可用的前提下，通过 FPGA 友好的实现方式降低无效切换、控制资源占用，并尽可能逼近 `100MHz` 目标频率。

整体设计策略可以概括为三点：

- 架构层面保持经典五级流水，不通过大幅删减功能来换低功耗。
- 实现层面采用 `enable/CE`、BRAM 使能、DSP 友好映射、迭代除法等方式降低动态翻转和面积压力。
- 评估层面同时关注功能正确性、实现后时序以及 `CoreMark/矩阵乘法` 的真实吞吐，而不是只看单一指标。

## 2. 低功耗设计思路

### 2.1 基本原则

本项目的低功耗优化重点不在“减少指令能力”，而在“减少不必要的活动”。

在 FPGA 上，没有采用普通 `clk & en` 形式的门控时钟，而是坚持使用 FPGA 友好的低功耗手段，例如寄存器 `CE/enable`、BRAM 的 `EN` 信号，以及必要时由专用时钟资源支持的门控方式。这是因为 LUT 级门控时钟容易引入毛刺、时钟偏斜和布线风险，不利于在 Vivado 中实现稳定的时序收敛。

### 2.2 已采用的低功耗实现

#### 1. BRAM 按需激活

- 指令存储器 [imem_bram.v](D:\Codex project\RISC-V CPU\rv32im_low-power\rtl\imem_bram.v) 和数据存储器 [dmem_bram.v](D:\Codex project\RISC-V CPU\rv32im_low-power\rtl\dmem_bram.v) 都加入了 `EN` 控制。
- 在流水线停顿、前端暂停或没有实际访存请求时，BRAM 不会在每个周期被无意义激活，从而减少动态功耗。

#### 2. 前端按需取指

- 前端 [front_end.v](D:\Codex project\RISC-V CPU\rv32im_low-power\rtl\front_end.v) 使用 `stall` 和 `redirect_valid` 组合控制 `imem_en`。
- 当前实现为 `imem_en = rst || redirect_valid || !stall`，只有在复位、跳转重定向或真正发起取指时才访问 IMEM。
- 这种写法避免了 stall 期间的取指空转，有利于降低前端翻转。

#### 3. 流水寄存器保持策略

- [pipeline_regs.v](D:\Codex project\RISC-V CPU\rv32im_low-power\rtl\pipeline_regs.v) 普遍采用 `stall / enable / flush` 风格的更新方式。
- 寄存器在停顿时保持原值，在没有新数据进入时不会重复写入，本质上减少了不必要的寄存器切换。
- 顶层 [cpu_top.v](D:\Codex project\RISC-V CPU\rv32im_low-power\rtl\cpu_top.v) 中的 `m_wait`、`mem_wait`、`front_stall`、`id_ex_enable` 等控制信号共同保证了乘除等待、访存等待和前端停顿时，流水线不会产生额外无效活动。

#### 4. M 扩展单元的资源友好实现

- [m_unit.v](D:\Codex project\RISC-V CPU\rv32im_low-power\rtl\m_unit.v) 中的乘法映射到 DSP 友好路径，避免用大量 LUT 拼乘法器。
- 除法和求余没有使用大组合结构，而是采用迭代状态机逐步完成运算。
- 这种做法虽然牺牲了一部分单次延迟，但有效控制了面积、翻转和时序复杂度，更符合“低功耗、可落地”的目标。

### 2.3 低功耗设计结论

本项目的低功耗设计不是激进地削弱能力，而是在保持 `RV32IM` 可用性和 benchmark 可运行性的前提下，通过“活动按需发生”和“资源友好映射”来降低功耗。换句话说，低功耗来自实现方式，而不是来自功能退化。

## 3. 时序优化思路

### 3.1 从可仿真到可实现评估

为了让设计真正适合 FPGA 综合与实现，额外构建了板级 wrapper 顶层 [cpu_fpga_top.v](D:\Codex project\RISC-V CPU\rv32im_low-power\rtl\cpu_fpga_top.v)。原始 `cpu_top` 暴露了大量用于仿真和观测的内部信号，如果直接作为 FPGA 顶层，会占用过多 IO，导致设计甚至无法放置。

引入 wrapper 之后：

- 只保留 `clk/rst` 等必要板级接口。
- CPU 核心被包裹在内部。
- Vivado 可以完成真实的 `synth/impl` 流程，并输出有效的时序和资源报告。

这一步解决的是“让设计真正适合上 FPGA”而不是“直接提升频率”，但它是后续时序优化的前提。

### 3.2 当前实现结果

基于 `cpu_fpga_top` 的实现结果如下：

- `impl WNS = -1.732ns`
- `impl TNS = -641.465ns`
- 等效可达频率约为 `85.2MHz`

当前资源使用较轻：

- `LUT = 2862`
- `FF = 1958`
- `DSP = 12`
- `BRAM = 2`

这说明当前设计已经具备良好的可实现性和较低资源占用，但离 `100MHz` 仍存在约 `1.7ns` 的关键路径差距。

### 3.3 当前时序瓶颈

实现报告已经确认，当前设计的主要时序瓶颈并不在乘法 DSP 路径，也不在 BRAM 容量本身，而是在控制恢复路径上。最差路径主要集中在：

- `redirect_pc`
- `redirect_valid`
- `actual_target`
- `pred_update_target`
- `ex_mispredict`

也就是分支预测恢复、跳转重定向、流水线冲刷和前端更新这条控制链逻辑过深、扇出过大，并且路由延迟占比较高。

### 3.4 后续时序优化方向

后续时序优化不会优先重写乘法器，而是围绕以下方向展开：

- 拆分 `redirect_valid` 与 `redirect_pc` 的大组合逻辑锥。
- 将 predictor update 与 redirect 恢复解耦，避免一条控制链同时承担“恢复 PC”和“更新预测器”的职责。
- 对 `front_stall`、`issue_stall`、`id_ex_flush`、`predictor_update_valid` 等信号提取公共条件，减少重复展开和大扇出。
- 在资源仍宽松的前提下，用少量额外 LUT/FF 换取更浅的逻辑深度和更短的布线距离。

因此，本项目的时序优化原则可以概括为：优先优化控制路径，而不是盲目压缩逻辑资源；优先提升实现后真实可达频率，而不是只看综合网表阶段的静态结构。

## 4. 性能评估与保证方式

### 4.1 两层性能口径

本项目的性能评估不采用单一指标，而是同时从“微结构效率”和“实现后吞吐”两个层面进行。

#### 第一层：benchmark 周期数

该指标表示程序在 RTL 仿真或功能仿真环境下执行所消耗的总周期数，主要反映流水线、分支预测、乘除法单元和访存路径的微结构效率。

当前已经得到的结果包括：

- `CoreMark iterations=10`：`4,218,156 cycles`
- 单次 CoreMark 平均：`421,815.6 cycles`
- 本地矩阵乘法 benchmark：`631,968 cycles`

#### 第二层：结合实现频率的真实吞吐

由于同样的周期数在不同 FPGA 频率下会对应不同的实际运行速度，因此本项目采用下面的方式估算真实吞吐：

`吞吐 ≈ 工作频率 / 单次运行周期数`

例如，在 `100MHz` 下：

- `CoreMark` 预测约为 `237.07 iter/s`
- `CoreMark/MHz ≈ 2.37`
- 矩阵乘法 benchmark 预测约为 `158.24 次/秒`

而在当前实现频率约 `85.2MHz` 的情况下：

- `CoreMark` 预测约为 `201.98 iter/s`
- 矩阵乘法 benchmark 预测约为 `134.8 次/秒`

### 4.2 性能优化判断原则

因此，后续优化时不会只看“周期数是否下降”，也不会只看“频率是否上升”，而是看二者综合后的真实吞吐：

- 如果某项优化让时序明显改善，虽然 benchmark 周期数略有波动，但总体吞吐上升，则该优化是可接受的。
- 如果某项优化只是为了闭时序，却严重损害 benchmark 周期数，则不符合项目目标。

### 4.3 性能保证方式

为了保证性能不被误伤，本项目在每轮优化后都计划同时进行三类回归：

- 功能回归：基础 smoke test、CSR 测试、本地 ISA/arch 测试。
- benchmark 回归：CoreMark 与矩阵乘法 benchmark 周期数对比。
- FPGA 回归：Vivado `synth/impl` 报告中的 `WNS/TNS` 与资源占用对比。

这种方法保证了性能优化和时序优化不是彼此孤立的，而是在统一指标体系下共同评估。

## 5. 设计边界

当前项目继续保持以下边界：

- 目标器件固定为 `XC7Z020CLG400-1`
- 目标频率固定为 `100MHz`
- 设计继续保持五级单发射结构
- 低功耗优化继续坚持 FPGA 友好的 `enable/CE/BRAM EN/DSP` 路线
- 后续时序优化优先针对控制恢复路径，而非优先重写 `M` 单元

## 6. 总结

本项目可以概括为一句话：

低功耗依靠 `enable/按需激活/迭代单元/DSP 友好映射` 实现，时序瓶颈主要位于 `redirect + predictor + stall/flush` 控制路径，而性能评估采用“benchmark 周期数 + 实现后频率”的联合口径来判断真实吞吐。

后续优化的目标不是单纯追求最小资源，而是在当前资源依然宽松的前提下，适当投入少量额外 LUT/FF，优先换取 `100MHz` 时序闭合和更高的实际 benchmark 吞吐。
