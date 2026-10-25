# 移除近期数据后，估计结果会怎样变化？

## 要解决的问题

新增观测后，资源评估可能修订历史生物量或补充量。回溯分析通过移除末端观测并重新拟合同一模型，检查估计的变化。它不衡量预测准确度。

## 重新拟合截短序列

以下完整设置使用模拟 YTF 示例及其条件生物假设。需要可用的编译器，并会执行多次拟合。

```r
library(ALSCL)
data("YTF_example")
x <- YTF_example
inputs <- x[c("data.CatL", "data.wgt", "data.mat")]
rb <- retro_alscl(x, nyear = 3, train_times = 2, silent = TRUE)
plot_retro(rb, facet_col = 2, rho_digits = 3)
rb$rho_text
```

## 检查轨迹与 Mohn rho

![仓库提供的 ALSCL 回溯示例](../assets/manual/figures/ytf/retro_ALSCL.png)

在每次截短序列的最后一个时间点，将其估计与完整拟合比较。正 rho 表示截短拟合在这些末端时期往往偏高，负值则相反。方向相反的偏差可能抵消，所以应查看单条轨迹及每次拟合的数值状态。参考估计为零时，相对差异无定义。

## 对照 ACL 的回溯结果

使用相同观测与截短次数，同时保留 ACL 自己的参数名与 map。

```r
ra <- retro_acl(x, nyear = 3, train_times = 2, silent = TRUE)
plot_retro(ra, facet_col = 2, rho_digits = 3)
ra$rho_text
```

![模拟 YTF：ACL 回溯轨迹](../assets/manual/figures/ytf/retro_ACL.png)

两种模型的配图均为仓库已有示例。先检查各模型内部的修订，再比较同一指标与末端时期的 rho。不同纵轴尺度可能放大或掩盖视觉差异。

## 检查返回表

```r
head(rb$results)
rb$last_points
rb$rho_text
names(rb)
```

`fit_diagnostics` 保存完整拟合（`Peel = 0`）和每个请求的截短拟合，包含耗时、原始优化状态、梯度、Hessian、边界与错误。`rho_by_peel` 包含筛查后的 `Rho`、诊断用的 `RawRho` 及 `Valid`。只有完整拟合和所有请求的截短拟合都通过数值筛查，且所有末端比较有限、参考值非零时，才在 `rho_text$Rho` 中报告该指标的 rho；否则返回 `NA` 并警告，不会悄悄删除失败的截短结果。`raw_rho_text` 是未经筛查的诊断汇总，不能替代正式报告值；若任一末端比较缺失，它仍为 `NA`。可用轨迹保留在 `results` 中供检查。

### 直接检查每次拟合，无须重复计算

```r
rb$fit_diagnostics
rb$rho_by_peel
rb$rho_text
rb$raw_rho_text
rb$errors
```

2.2.3 可直接使用与拟合函数相同的输入：`retro_acl(x, nyear = 3)` 和 `retro_alscl(x, nyear = 3)`。通用写法为 `retro_model(data.CatL = x, model_type = "alscl", nyear = 3)`。各次拟合依次使用共用设置、模型专用设置及调用时显式覆盖值；显式 `map`、`parameters` 和 `control` 会整体替换对应列表。`zero_action`、`control`、`nstarts`、`F_structure` 和 `polish` 都传给每次拟合。`x` 内用于拟合的 `ncores` 不用于回溯：请在回溯调用中显式设置 `ncores`，控制同时运行的截短拟合数。每个截短拟合内部依序运行 `nstarts` 个起点。

## 应用于自己的评估

将输入与生物参数替换为完整数据拟合时使用的同一套配置。固定参数、观测处理和时间单位应保持一致。`nyear` 计算移除的末端时间步：三个季度步并不是三年。每次截短后应保留足够观测，详见 [函数使用说明](retrospectives.html)。

## 导出回溯记录

```r
dir.create("my_retrospective", showWarnings = FALSE)
write.csv(rb$results, "my_retrospective/alscl_trajectories.csv", row.names = FALSE)
write.csv(rb$rho_text, "my_retrospective/alscl_rho.csv", row.names = FALSE)
write.csv(rb$fit_diagnostics, "my_retrospective/fit_diagnostics.csv", row.names = FALSE)
write.csv(rb$rho_by_peel, "my_retrospective/rho_by_peel.csv", row.names = FALSE)
write.csv(ra$rho_text, "my_retrospective/acl_rho.csv", row.names = FALSE)
p_retro <- plot_retro(rb, facet_col = 2, rho_digits = 3)
ggplot2::ggsave("my_retrospective/alscl.png", p_retro,
               width = 10, height = 7, dpi = 300)
saveRDS(list(ACL = ra, ALSCL = rb, fit_args = x$fit_args,
             fit_config = x$fit_config), "my_retrospective/results.rds")
writeLines(capture.output(sessionInfo()), "my_retrospective/session.txt")
```

|现象|解释或检查|
|---|---|
|截短后时间步太少|减少截短次数，每次拟合至少保留两个时间步|
|末端偏差正负交替|查看各次截短，平均 rho 可能掩盖抵消|
|将季度分析理解为年度分析|用 `growth_step` 将移除步数转换为时长|
|需要自定义 `zero_action`|在 `x$fit_args` 中设置，或显式传给 `retro_alscl(x, ...)`；各次拟合使用同一设置|
|短序列拟合不稳定|先检查诊断，再解释末端修订|

## 决定下一步检查什么

持续同向的修订提示需要检查输入变化、模型假设和参数敏感性。rho 本身不能确定成因，也不能直接作为修正系数。作出结论前，应记录完整拟合、各次截短的诊断及末端时间。
