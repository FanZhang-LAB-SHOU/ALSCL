# 回溯分析

先完成 [YTF 拟合示例](first-model.html)。以下代码使用其中的 `x`、`inputs`、`a`（ACL）和 `b`（ALSCL）对象。

```r
# 删除最后 1、2、3 个时间步后分别重拟合
ra <- retro_acl(x, nyear = 3, train_times = 2, silent = TRUE)
rb <- retro_alscl(x, nyear = 3, train_times = 2, silent = TRUE)
plot_retro(rb, facet_col = 2, rho_digits = 3)
rb$fit_diagnostics
rb$rho_by_peel
rb$rho_text
```

这里 `nyear` 是删除的**末端时间步数**，季度数据中 4 步才是一年。保留至少两个观测期，各次回溯使用一致的生物假设与固定参数。Mohn's rho 衡量末端修订方向和幅度，不是未来预测准确率，也不能替代检查每次拟合的数值状态。


![ALSCL 回溯](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ALSCL.png?raw=true)

```r
# 从仓库根目录重建图、结果 CSV 和会话记录
source("scripts/ytf_workflow.R", encoding = "UTF-8")
result <- run_ytf_guide(out = "my_ytf_guide", npeels = 3)
# 保留活跃结果用于需要 TMB 对象的图
plot_ridges(result$alscl)
```

默认输出目录为 `docs`，会覆盖同名图和结果文件；使用自己的目录可保留仓库版本。工作流依赖 `ggplot2`、`patchwork`、`jsonlite`。首次 TMB 编译需要编译器，回溯要执行多次优化。可设置 `options(ALSCL.tmb.cache="可写路径")`；保存 `.rds` 不能保证其中 TMB 外部指针跨会话有效，重新打开 R 后应重拟合依赖活跃 `obj` 的操作。

2.2.3 可直接使用与拟合函数相同的输入：`retro_acl(x, nyear = 3)` 和 `retro_alscl(x, nyear = 3)`。通用写法为 `retro_model(data.CatL = x, model_type = "alscl", nyear = 3)`。各次拟合依次使用共用设置、模型专用设置及调用时显式覆盖值；显式 `map`、`parameters` 和 `control` 会整体替换对应列表。`zero_action`、`control`、`nstarts`、`F_structure` 和 `polish` 都传给每次拟合。`x` 内用于拟合的 `ncores` 不用于回溯：请在回溯调用中显式设置 `ncores`，控制同时运行的截短拟合数。每个截短拟合内部依序运行 `nstarts` 个起点。

`fit_diagnostics` 保存完整拟合（`Peel = 0`）和每个请求的截短拟合，包含耗时、原始优化状态、梯度、Hessian、边界与错误。`rho_by_peel` 包含筛查后的 `Rho`、诊断用的 `RawRho` 及 `Valid`。只有完整拟合和所有请求的截短拟合都通过数值筛查，且所有末端比较有限、参考值非零时，才在 `rho_text$Rho` 中报告该指标的 rho；否则返回 `NA` 并警告，不会悄悄删除失败的截短结果。`raw_rho_text` 是未经筛查的诊断汇总，不能替代正式报告值；若任一末端比较缺失，它仍为 `NA`。可用轨迹保留在 `results` 中供检查。

## Mohn rho 的含义

对每个删除末端数据的拟合，在其最后保留期与完整拟合同期的估计比较，再取相对差的平均：

```math
\rho=\frac{1}{K}\sum_{k=1}^{K}\frac{\hat\theta^{(-k)}_{T-k}-\hat\theta^{(0)}_{T-k}}{\hat\theta^{(0)}_{T-k}}.
```

正值表示较短序列在这些终点总体偏高，负值表示偏低；正负可能互相抵消。检查每条曲线与每次拟合，而不只报告单个 rho 数字。全长基准为零时相对差没有定义，应检查数据与结果。


## ACL 回溯分析

```r
# 绘制本图
plot_retro(ra, facet_col = 2, rho_digits = 3, rho_size = 3, point_size = 1, line_size = 0.6)
```

[![ACL 回溯分析](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ACL.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ACL.png?raw=true)



逐步删除末端观测并重拟合；各颜色代表不同截止期。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_retro)



## ALSCL 回溯分析

```r
# 绘制本图
plot_retro(rb, facet_col = 2, rho_digits = 3, rho_size = 3, point_size = 1, line_size = 0.6)
```

[![ALSCL 回溯分析](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ALSCL.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ALSCL.png?raw=true)



逐步删除末端观测并重拟合；各颜色代表不同截止期。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_retro)
