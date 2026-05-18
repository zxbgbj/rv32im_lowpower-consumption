# 功耗评估方法与当前口径

## 1. 为什么单纯优化时序不等于低功耗
本项目的目标是低功耗设计，但“时序优化”和“低功耗优化”不是同一个问题。

- 时序优化主要回答：这颗核能跑多快、`WNS/TNS` 是否改善。
- 低功耗优化主要回答：单位时间内有多少无效翻转、动态功耗是否增加、吞吐功耗效率是否变差。

如果某次 RTL 修改只是让关键路径更短，却引入更多高扇出翻转、更复杂的控制网络或更高的切换率，那么它可能：

- `WNS` 变好
- 可达主频略升
- 但 `Dynamic Power` 变高
- 甚至因为 `CoreMark cycle` 变差，最终 `throughput/W` 反而下降

因此，本项目不能只看时序报告，而必须把性能和功耗一起评估。

## 2. 本项目当前使用的功耗口径
当前采用 Vivado `report_power` 进行 FPGA 实现后的功耗估算，分两档：

### 2.1 Vector-less 功耗
这是首轮默认口径，特点是：

- 不依赖仿真活动文件
- Vivado 自动传播默认切换率
- 获取速度快
- 适合先做版本之间的快速对比

但它的局限也很明确：

- 对内部节点活动的估算精度有限
- 对 benchmark 的真实负载行为反映不完整
- 报告可信度通常是 `Medium`

### 2.2 Activity-based 功耗
这是第二轮更可信的口径，做法是：

- 跑 benchmark 仿真
- 导出 VCD 活动文件
- 将活动文件读回 Vivado routed 设计
- 再执行 `report_power`

这类结果更接近真实 workload 下的动态功耗，但实现难度更高，且 VCD 大小、层级匹配、注入覆盖率都会影响结果质量。

## 3. 为什么重点看 Dynamic Power
对于本项目这种小型软核来说，`Static Power` 很大一部分来自 FPGA 器件本身，与 RTL 细节的关系没有那么直接。

真正更能体现 RTL 低功耗设计效果的是：

- `Dynamic Power`
- `Throughput / Dynamic Power`

原因是：

- `Dynamic Power` 更直接反映翻转活动和资源使用方式
- `Throughput / Dynamic Power` 更能体现“同样功耗下能做多少事”

所以后续判断版本优劣时，优先级应为：

1. `Dynamic Power`
2. `Throughput / Dynamic Power`
3. `Total Power`

## 4. 当前版本已知首轮功耗结果
截至当前工作区已有的 routed、vector-less 功耗报告，当前版本的首轮结果为：

- `Total On-Chip Power = 0.151W`
- `Dynamic = 0.048W`
- `Static = 0.103W`
- `Confidence = Medium`

这份结果可以作为首轮参考，但还不能直接等同于 benchmark 真实负载下的最终结论。

## 5. 推荐的最终判断方式
最终应采用统一的联合判断：

- `CoreMark cycles`
- `Fmax`
- `Dynamic Power`
- `Throughput @ Fmax`
- `Throughput / Dynamic Power`

如果某个版本满足下面任一情况，就不应被视为更优的低功耗版本：

- `Dynamic Power` 更高，且吞吐更低
- `WNS` 略有改善，但 `CoreMark cycle` 恶化更多
- 频率提升不足以覆盖功耗上升和跑分退化

一句话总结：

低功耗 CPU 的评估不能只看“能不能跑更快”，而要看“在给定功耗下能不能更有效地完成工作”。
