# 04 理解第一次拟合 · Understand your first fit

[← 上一章 · Previous](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/03-Data-and-Excel) · [目录 · Contents](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [下一章 · Next →](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/05-Simulation)

**ALSCL 2.4.3 · 简体中文 / English**

[安装软件包](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#start)之后，你已经有了输入列表 `x` 和拟合好的 ACL 模型 `a`。本页说明拟合结果包含什么、怎样判断它可用、怎样读估计值，以及第二个模型 ALSCL 与它有何不同。请在同一个 R 会话中按步骤运行；后面的页面会继续使用 `x`、`a` 和 `b`。

After [installing the package](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#start) you have the input bundle `x` and a fitted ACL model `a`. On this page you learn what a fitted object contains, how to judge whether a fit can be used, how to read its estimates, and how the second model, ALSCL, compares with it. Run the steps in one R session; later pages reuse `x`, `a` and `b`.

`YTF_example` 是模拟数据：23 个体长组、20 个年份，由一个已知的种群生成。它保存的设置固定了生长参数和部分过程参数，因此你看到的不确定性区间是在这些固定值之下得到的。先用它熟悉流程，再为自己的种群选择假设。

`YTF_example` is synthetic: 23 length bins and 20 years generated from a known population. Its stored settings fix growth and some process parameters, so the uncertainty intervals you will see are conditional on those fixed values. Learn the workflow on it before choosing assumptions for your own stock.

<a id="first-model-fit"></a>

### 1. 拟合两个模型 / Fit the two models

```r
library(ALSCL)
data("YTF_example")
x <- YTF_example
a <- run_acl(x, silent = TRUE)
b <- run_alscl(x, silent = TRUE)
```

ALSCL 为同一套调查数据提供两个模型。ACL（`run_acl()`）追踪每个年龄的尾数，用年龄-体长概率矩阵把年龄换算成体长。ALSCL（`run_alscl()`）追踪每个体长和年龄的尾数，用生长转移矩阵把存活个体在体长组之间推进，适合难以鉴定年龄的种群。本例 ACL 拟合约二十秒，ALSCL 约两分钟，不含每个模型只做一次的编译。

ALSCL offers two models of the same data. ACL (`run_acl()`) follows the number of fish at each age and converts ages to lengths with an age-length probability matrix. ALSCL (`run_alscl()`) follows the number of fish at each length and age and moves survivors between length bins with a growth transition matrix, which suits stocks that are hard to age. The ACL fit takes about twenty seconds for this example and the ALSCL fit about two minutes, after the one-time compilation of each model.

两次调用读取同一个 `x`：三张表、`x$fit_args` 中两个模型共用的生物学设置（补充年龄、年龄组数、自然死亡率 `M`、调查可捕性 `sel_L50` 和 `sel_L95`、体长组和时间步），以及 `x$fit_config$acl` 或 `x$fit_config$alscl` 中各模型自己的初值和 `map`。[输入列表一节](#first-model-bundle)详细说明 `x`。

Both calls read the same `x`: the three tables, the shared biology in `x$fit_args` (recruitment age, number of ages, natural mortality `M`, survey catchability `sel_L50` and `sel_L95`, length bins and time step) and the model's own starting values and `map` in `x$fit_config$acl` or `x$fit_config$alscl`. The [bundle section](#first-model-bundle) explains `x` in detail.

<a id="first-model-checks"></a>

### 2. 读数值检查 / Read the numerical checks

```r
diagnose_model(x$data.CatL, a)
a$diagnostics$numerical_ok
a$diagnostics$issues
```

解释估计值之前先读数值检查。`diagnose_model()` 打印优化器原始收敛码（0 表示正常结束）、最大绝对梯度、Hessian 和协方差状态，以及参数边界检查。`Numerical checks` 与 `a$diagnostics$numerical_ok` 相同，要求梯度小于 0.001、Hessian 和协方差矩阵正定，且没有标记出的参数边界问题。该筛查不包括优化器原始收敛码和强参数相关；须在 `a$diagnostics$issues` 中另行检查。通过筛查后仍需评估拟合，不能据此确认唯一解或全局最优解。

Read the numerical checks before interpreting estimates. `diagnose_model()` prints the raw optimizer convergence code (0 means normal termination), the maximum absolute gradient, Hessian and covariance status, and parameter-boundary checks. `Numerical checks`, also stored as `a$diagnostics$numerical_ok`, requires a gradient below 0.001, a positive-definite Hessian and covariance matrix, and no flagged parameter boundaries. This numerical screen does not include the raw optimizer code or strong parameter correlations; inspect those separately in `a$diagnostics$issues`. Passing the screen supports further examination of the fit but does not establish a unique or global optimum.

| 未通过的检查 / Failed check | 可能原因 / Possible causes | 可以尝试 / What to try |
|---|---|---|
| 收敛码不是 0，或梯度很大 / Convergence code is not 0, or the gradient is large | 优化器提前停止，或目标函数面很平 / The optimizer stopped early or the surface is flat | 多用几个初值，`run_acl(x, nstarts = 4, ncores = 2)`，在 `a$start_diagnostics` 中比较各初值的目标函数值 / Run more starts, `run_acl(x, nstarts = 4, ncores = 2)`, and compare their objectives in `a$start_diagnostics` |
| Hessian 不正定 / Hessian not positive definite | 拟合尚未到达极小值、参数尺度造成数值困难，或部分参数识别较弱 / The fit is away from a minimum, parameter scales cause numerical difficulty, or some parameters are weakly identified | 先检查梯度、尺度和其他初值；结合剖面或敏感性分析，再决定固定参数或简化 F（[拟合设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting)） / Check gradients, scales and additional starts; use profiles or sensitivity analyses before fixing parameters or simplifying F ([Fitting controls](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting)) |
| 参数落在边界上 / Parameter on a bound | 约束下的最优点位于边界，或拟合尚未达到稳定解 / The constrained optimum is at a bound, or the fit has not reached a stable solution | 检查边界及其生物学依据，尝试其他初值，并结合剖面判断是否调整 / Inspect the bound and its biological basis, try other starts, and examine a profile before changing it |
| 自然尺度边界 / Natural-scale boundary | 标准差接近 0，或相关系数接近 0 或 1 / A standard deviation near 0 or a correlation near 0 or 1 | 把该参数固定在有依据的值，或简化 F 结构 / Fix the parameter at a supported value, or simplify the F structure |
| 检查通过但残差有规律 / Checks pass but residuals show patterns | 模型漏掉了数据中的某种特征 / The model misses a feature of the data | 继续阅读[诊断](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) / Continue with [Diagnostics](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) |

<a id="first-model-estimates"></a>

### 3. 读估计值 / Read the estimates

```r
estimates <- extract_estimates(a)
head(estimates)
subset(estimates, quantity == "SSB")
extract_parameters(a)
plot_SSB(a, se = TRUE)
```

`extract_estimates()` 把种群量整理成一张表：产卵生物量 `SSB`、补充量 `Rec`、总生物量 `B`、丰度 `N`、捕获尾数 `CN` 和捕捞死亡率 `F`，每行有年份、该量所在的年龄或体长（如有）、估计值、标准误和 95% 区间。`extract_parameters()` 列出标量参数的状态（`estimated`、`fixed` 或 `inactive`）和自然尺度上的估计值。`plot_SSB()` 画出产卵生物量及其区间，其他绘图函数用法相同。

`extract_estimates()` returns one table for the population quantities: spawning biomass `SSB`, recruitment `Rec`, total biomass `B`, abundance `N`, catch numbers `CN` and fishing mortality `F`, with the year, the age or length where the quantity has one, the estimate, its standard error and a 95% interval. `extract_parameters()` lists the scalar parameters with their status (`estimated`, `fixed` or `inactive`) and estimates on the natural scale. `plot_SSB()` draws spawning biomass with its interval; the other plot functions follow the same pattern.

区间只来自被估计参数的标准误；`x$fit_config` 中固定的值不贡献不确定性。表格背后的原始数组在 `a$report` 中（例如 `a$report$SSB`），`a$sd_info` 记录标准误的计算方式。

The intervals come from the standard errors of the estimated parameters only; the fixed values in `x$fit_config` contribute no uncertainty. The raw arrays behind the table are in `a$report` (for example `a$report$SSB`), and `a$sd_info` records how the standard errors were computed.

<a id="first-model-fit-to-data"></a>

### 4. 检查对观测的拟合 / Check the fit to the observations

```r
plot_CatL(a, facet_by = "year", facet_ncol = 5)
plot_residuals(a, facet_by = "year", facet_ncol = 5)
```

`plot_CatL()` 按年份分面显示各体长组的观测与拟合调查指数。`plot_residuals()` 显示相应面板中对数尺度的观测值减去拟合值。检查残差是否以零附近为中心，以及是否沿体长或时间持续同号。这些规律可提示检查生长、世代动态或调查可捕性，但不能唯一确定原因；[诊断](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics)说明如何进一步检查。

`plot_CatL()` shows the observed and fitted survey indices across length bins, one panel per year. `plot_residuals()` shows observed minus fitted values on the log scale for those panels. Look for residuals centred near zero and for persistent signs across lengths or time. Such patterns can motivate checks of growth, cohort dynamics or survey catchability, but do not identify a unique cause; [Diagnostics](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) explains how to investigate them.

<a id="first-model-compare"></a>

### 5. 比较 ACL 与 ALSCL / Compare ACL and ALSCL

```r
plot_compare_ts(a, b, quantities = c("B", "SSB", "Rec"), se = TRUE)
comparison <- compare_models(a, b, x$data.CatL)
comparison$comparison
comparison$fit_diagnostics
```

![ACL 与 ALSCL 的生物量、产卵生物量和补充量估计 / ACL and ALSCL biomass, spawning biomass and recruitment estimates](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_ts.png?raw=true&v=6e0c7883ce7f)

图中是两个模型的总生物量、产卵生物量和补充量及其区间。轨迹相似说明两种种群结构对趋势的判断一致；若估计尺度持续不同，应进一步比较两种结构的生长、死亡率和年龄–体长转换假设。

The figure shows both models' total biomass, spawning biomass and recruitment with intervals. Similar trajectories mean the two population structures agree on the trend; a persistent difference in scale calls for closer comparison of growth, mortality and age-length conversion assumptions.

`compare_models()` 先核对两次拟合使用的观测相同，再打印 AIC、BIC 和拟合统计量。`comparison$comparison` 记录 `data_verified`、`eligible`（两次拟合都通过数值检查）、`preferred`（AIC 较低的模型，仅在两者都合格时给出）和 `issues`。AIC 在似然拟合与参数数量之间作权衡；对同一观测和相容似然，AIC 较低表示该准则更支持该候选模型。它的假设是否适合这个种群，是另一个需要用生物学知识回答的问题。

`compare_models()` first verifies that both fits used the same observations, then prints AIC, BIC and fit statistics. `comparison$comparison` records `data_verified`, `eligible` (both fits passed the numerical checks), `preferred` (the model with the lower AIC, given only when both are eligible) and any `issues`. AIC balances likelihood fit against parameter count; among compatible fits to the same observations, a lower value supports that candidate under this criterion. Whether its assumptions suit the stock is a separate, biological decision.

<a id="first-model-save"></a>

### 6. 保存拟合结果 / Save the fit

```r
save_assessment(a, "ytf_acl.rds")
saved <- read_assessment("ytf_acl.rds")
plot_SSB(saved, se = TRUE)
```

`save_assessment()` 保存拟合结果中除 `a$obj` 以外的全部内容（`a$obj` 是只在当前会话有效的 TMB 对象指针），并保存重新拟合所需的信息（数据表、设置和软件包版本），以后可用 `refit_model(saved)` 重建可执行对象。绘图和提取函数都能直接使用保存的拟合结果。文件已存在时调用会停止；传入 `overwrite = TRUE` 即可覆盖。

`save_assessment()` writes everything in the fit except the live TMB object `a$obj`, a pointer valid only in the current session, and stores the recipe (the tables, settings and package version) so that `refit_model(saved)` can rebuild the live object later. Plots and extraction functions work directly on the saved fit. The call stops when the file exists; pass `overwrite = TRUE` to replace it.

<a id="first-model-bundle"></a>

### run_acl(x) 如何读取输入列表 / How run_acl(x) reads the input bundle

输入列表 `x` 是一个命名列表。三张表 `data.CatL`、`data.wgt` 和 `data.mat` 存放观测。`x$fit_args` 存放两个模型共用的设置：`rec.age`、`nage`、`M`、`sel_L50`、`sel_L95`、`len_mid`、`len_border` 和 `growth_step`。`x$fit_config$acl` 和 `x$fit_config$alscl` 存放各模型的初值（`parameters`）和 `map`。其他元素，例如 `YTF_example` 中的模拟真值 `truth` 和来源 `provenance`，拟合函数不会读取。

The input bundle `x` is a named list. Its three tables `data.CatL`, `data.wgt` and `data.mat` hold the observations. `x$fit_args` holds the settings both models share: `rec.age`, `nage`, `M`, `sel_L50`, `sel_L95`, `len_mid`, `len_border` and `growth_step`. `x$fit_config$acl` and `x$fit_config$alscl` hold the starting values (`parameters`) and the `map` of each model. The fitting functions ignore other elements, such as the simulation `truth` and `provenance` of `YTF_example`.

设置按这个顺序读取：数据表，然后 `fit_args`，然后所选模型的 `fit_config`，最后是调用时给出的参数。因此调用中的参数会覆盖保存的值，而 `map` 这类列表参数会整体替换保存的列表。

Settings are read in this order: the tables, then `fit_args`, then the `fit_config` entry of the chosen model, then the arguments of the call. An argument in the call therefore overrides the stored value, and a list argument such as `map` replaces the stored list completely.

```r
# 两个工作进程运行四个初值；保存的 M 仅在本次调用中换成 0.25 / Four starts on two workers; the stored M is replaced by 0.25 for this call only
a4 <- run_acl(x, nstarts = 4, ncores = 2, M = 0.25)
```

也可以把每张表和每项设置作为单独参数传入，如 `do.call(run_acl, args)`；两种写法使用同一套拟合代码。只包含三张表和 `rec.age`、`nage`、`M`、`sel_L50`、`sel_L95` 的扁平命名列表同样可以作为输入列表。

Every table and setting can also be passed as a separate argument, as in `do.call(run_acl, args)`; both forms use the same fitting code. A flat named list with the three tables, `rec.age`, `nage`, `M`, `sel_L50` and `sel_L95` is accepted as a bundle too.

<a id="first-model-data-provenance"></a>

### 内置数据说明 / About the bundled data

| 对象 / Object | 内容 / Contents |
|---|---|
| `YTF_example` | 三张表（23 个体长组、20 个年份）、`fit_args`、`fit_config`、生成真值 `truth` 和来源 `provenance` / The three tables (23 bins by 20 years), `fit_args`, `fit_config`, the generating `truth` and `provenance` |
| `YTF` | 原有的 26 项生物参数列表，不含调查表 / The original list of 26 biological parameters, without survey tables |
| `example_data` | 三张 ALSCL 数据表（9 个体长组，2001-2021），来源未核实，只用于试运行函数 / Three ALSCL tables (9 bins, 2001-2021) of unverified origin, for trying the functions only |

`YTF_example` 由 ALSCL 2.0.0 的模拟器生成（种子 4，预热 80 年，保留 20 年，调查对数 SD 0.1），不是论文的实测数据。[生成脚本](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/data-raw/YTF_example.R)会用当前安装的模拟器运行同一组设置，并记录版本。复现本说明书中的数值时，请读取包内随附的数据。

`YTF_example` was generated with ALSCL 2.0.0 (seed 4, 80 burn-in years, 20 retained years, survey log SD 0.1) and is not the empirical dataset of the paper. The [generation script](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/data-raw/YTF_example.R) runs the same settings with the installed simulator and records its version. Load the bundled dataset to reproduce the values used in this guide.

<a id="first-model-next"></a>

### 下一步 / What next

| 想做什么 / What you want to do | 阅读 / Read |
|---|---|
| 把示例换成自己的数据表 / Replace the example with your own tables | [准备调查数据](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel) / [Prepare your survey data](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel) |
| 决定哪些参数固定、哪些估计 / Decide which parameters to fix or estimate | [拟合设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) / [Fitting controls](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) |
| 检查残差、比较不同设置 / Examine residuals and compare configurations | [诊断](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) / [Diagnostics](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) |
| 绘制某个种群量 / Plot a particular quantity | [调查与种群图](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md) / [Survey and population plots](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md) |
| 做敏感性分析、参数剖面和投影 / Test sensitivity, profile a parameter, project forward | [评估工作流](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ASSESSMENT_WORKFLOWS.md) / [Assessment workflows](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ASSESSMENT_WORKFLOWS.md) |
| 从拟合模型模拟调查数据，或检验对未来年份的预测 / Simulate from the fit or test predictions of future years | [模型验证](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md) / [Model validation](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md) |

---

[← 上一章 · Previous](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/03-Data-and-Excel) · [目录 · Contents](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [下一章 · Next →](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/05-Simulation)
