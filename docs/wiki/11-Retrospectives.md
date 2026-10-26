# 11 回溯分析 · Retrospectives

[← 上一章 · Previous](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/10-Model-Comparisons) · [目录 · Contents](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [下一章 · Next →](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/12-Case-Studies)

**ALSCL 2.2.5 · 简体中文 / English**

```r
# 删除最后 1、2、3 个时间步后分别重拟合 / Refit after peeling 1, 2 and 3 steps
ra <- retro_acl(x, nyear = 3, train_times = 2, silent = TRUE)
rb <- retro_alscl(x, nyear = 3, train_times = 2, silent = TRUE)
plot_retro(rb, facet_col = 2, rho_digits = 3)
rb$fit_diagnostics
rb$rho_by_peel
rb$rho_text
```

这里 `nyear` 是删除的**末端时间步数**，季度数据中 4 步才是一年。保留至少两个观测期，各次回溯使用一致的生物假设与固定参数。Mohn's rho 衡量末端修订方向和幅度，不是未来预测准确率，也不能替代检查每次拟合的数值状态。

Here `nyear` counts terminal **steps**: four quarterly steps equal one year. Retain at least two observations and keep assumptions consistent across peels. Mohn's rho measures retrospective revision, not forecast accuracy; inspect each fit's numerical status.

2.2.3 起，同一份正式数据 `x` 可直接传给 `retro_acl()`、`retro_alscl()`；也可用 `retro_model(data.CatL = x, model_type = "alscl", nyear = 3)`。显式参数覆盖 x 中的设置，`map = NULL` 等覆盖仍被保留。`zero_action`、`control` 和 `nstarts` 会传到各次拟合。`ncores` 在这里表示并行回溯轮数，默认 1；x 中用于多起点拟合的 ncores 不会自动变成回溯并行数，每轮内部依次运行 nstarts 个起点。

Since 2.2.3, the same own-data bundle works with both retrospective wrappers or `retro_model(data.CatL = x, model_type = "alscl", nyear = 3)`. Explicit arguments override stored settings, including `map = NULL`. Each fit receives zero_action, control and nstarts. Here ncores explicitly selects peel workers (default 1); stored fitting ncores is not reused. Starts within each fit run sequentially.

`fit_diagnostics` 保留完整拟合（Peel = 0）和各轮的优化代码、最大梯度、Hessian、边界及错误。只要完整拟合或任一要求的回溯不合格，或末端相对差无定义，对应的 `rho_text$Rho` 就是 NA，并发出警告，不会悄悄删除失败轮次。`rho_by_peel` 的 RawRho 和 `raw_rho_text` 仅供追查原始数值，不是可靠结论；`plot_retro()` 也会标明不可用的 rho。数值筛查通过仍不等于模型适合数据。

`fit_diagnostics` retains the full fit (Peel = 0) and every peel's raw code, maximum gradient, Hessian, boundaries and error. If the full fit or any requested peel fails its numerical screen, or a terminal relative difference is undefined, the corresponding rho_text$Rho is NA with a warning. Failed peels are not silently dropped. RawRho in rho_by_peel and raw_rho_text are exploratory records only; plots label unavailable rho. Passing a numerical screen does not establish model adequacy.


![ALSCL 回溯 / ALSCL retrospective](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ALSCL.png?raw=true)

```r
# 从仓库根目录重建图、结果 CSV 和会话记录 / Rebuild figures, CSV and session record
source("scripts/ytf_workflow.R", encoding = "UTF-8")
result <- run_ytf_guide(out = "my_ytf_guide", npeels = 3)
# 使用保存的观测绘图 / Plot using the stored observations
plot_ridges(result$alscl)
```

默认输出目录为 `docs`，会覆盖同名图和结果文件；使用自己的目录可保留仓库版本。工作流依赖 `ggplot2`、`patchwork`、`jsonlite`。首次 TMB 编译需要编译器，回溯要执行多次优化。可设置 `options(ALSCL.tmb.cache="可写路径")`；保存 `.rds` 不能保证其中 TMB 外部指针跨会话有效，重新打开 R 后应重拟合依赖活跃 `obj` 的操作。

The default output is `docs` and overwrites matching outputs; choose another folder to preserve bundled files. The workflow requires ggplot2, patchwork and jsonlite. Initial compilation needs a compiler, and retrospectives involve multiple fits. A writable TMB cache can be configured. Saved R objects do not preserve usable TMB external pointers across sessions; refit for operations requiring a live `obj`.

### 全部拟合失败时保留诊断 / Retaining diagnostics when every fit fails

当全部回溯拟合失败或没有有限轨迹时，`plot = TRUE` 会警告并返回 `plot = NULL`，同时保留 `fit_diagnostics`、`errors` 及不可用的 rho。应根据这些字段修正输入或拟合设置。请求绘图不再阻止读取失败记录。

When all retrospective fits fail or no finite trajectories remain, `plot = TRUE` now warns and returns `plot = NULL` while preserving `fit_diagnostics`, `errors` and the unavailable rho values. Inspect those fields to correct the input or fitting problem. Requesting a plot must not prevent access to the failure record.
## Mohn rho 的含义 · Meaning of Mohn's rho

对每个删除末端数据的拟合，在其最后保留期与完整拟合同期的估计比较，再取相对差的平均：
Compare each peeled estimate with the full fit at that peel's terminal period, then average relative differences:

```math
\rho=\frac{1}{K}\sum_{k=1}^{K}\frac{\hat\theta^{(-k)}_{T-k}-\hat\theta^{(0)}_{T-k}}{\hat\theta^{(0)}_{T-k}}.
```

正值表示较短序列在这些终点总体偏高，负值表示偏低；正负可能互相抵消。检查每条曲线与每次拟合，而不只报告单个 rho 数字。全长基准为零时相对差没有定义，应检查数据与结果。
Positive rho means shorter fits tend to be higher at their terminal periods; signs can cancel. Inspect individual trajectories and fits. A zero full-fit denominator makes the relative difference undefined.


## 43. ACL 回溯分析 / ACL retrospective analysis

```r
# 绘制本图 / Draw this figure
plot_retro(ra, facet_col = 2, rho_digits = 3, rho_size = 3, point_size = 1, line_size = 0.6)
```

[![ACL 回溯分析 / ACL retrospective analysis](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ACL.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ACL.png?raw=true)



逐步删除末端观测并重拟合；各颜色代表不同截止期。 / Successively peel terminal observations and refit; colors indicate different terminal periods.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_retro)



## 44. ALSCL 回溯分析 / ALSCL retrospective analysis

```r
# 绘制本图 / Draw this figure
plot_retro(rb, facet_col = 2, rho_digits = 3, rho_size = 3, point_size = 1, line_size = 0.6)
```

[![ALSCL 回溯分析 / ALSCL retrospective analysis](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ALSCL.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ALSCL.png?raw=true)



逐步删除末端观测并重拟合；各颜色代表不同截止期。 / Successively peel terminal observations and refit; colors indicate different terminal periods.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_retro)



---

[← 上一章 · Previous](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/10-Model-Comparisons) · [目录 · Contents](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [下一章 · Next →](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/12-Case-Studies)
