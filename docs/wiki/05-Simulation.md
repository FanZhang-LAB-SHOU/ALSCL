# 05 模拟与批量实验 · Simulation

[← 上一章 · Previous](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/04-Built-in-YTF) · [目录 · Contents](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [下一章 · Next →](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/06-Fitting)

**ALSCL 2.4.3 · 简体中文 / English**

读完本页，你会得到拟合函数可以直接使用的模拟调查表、重复文件（每个文件是一套模拟数据集，连同生成它的种群一起保存），以及对这些重复的拟合结果的偏差、RMSE 和区间覆盖率表。你需要软件包；步骤 2 到 4 还使用 `scripts/simulation_workflow.R` 中的 `simulation_to_tables()` 和 `run_simulation_examples()`，请在仓库根目录运行 R。

At the end of this page you have simulated survey tables that the fitting functions accept, replicate files (one simulated dataset each, saved with its generating population) and a table of bias, RMSE and interval coverage for fits to those replicates. You need the package; steps 2 to 4 also use `simulation_to_tables()` and `run_simulation_examples()` from `scripts/simulation_workflow.R`, so run R from the repository root.

<a id="simulation-choose"></a>

### 1. 选择模拟器 / Choose a simulator

```r
library(ALSCL)
quick <- simulate_example_data(
  years = 2000:2019, seed = 42, bin_breaks = seq(5, 51, 2),
  Linf = 60, vbk = 0.2, t0 = 1/60, M = 0.2, nage = 15,
  L50_sel = 15, L95_sel = 20, L50_mat = 35, L95_mat = 40,
  wgt_a = exp(-12), wgt_b = 3, mean_F = 0.3,
  cv_catch = 0.2, rec_sigma = 0.3,
  save_csv = TRUE, output_dir = "my_simulation")
str(quick, max.level = 1)
initialize_params(species = "?")
```

`simulate_example_data()` 是快速模拟器，用于测试导入、拟合和绘图：一次调用返回调查指数表 `data.CatL`、体重表 `data.wgt` 和成熟比例表 `data.mat`，生成时使用的真值放在 `true_params` 中，`save_csv = TRUE` 还会把它们写成 CSV 文件保存到 `output_dir`。它对所有年龄使用同一个捕捞死亡率，体长 CV 固定为 0.1。`years` 必须是连续的日历年；把列名改成季度并不会产生季度动态。

`simulate_example_data()` is the quick simulator for testing import, fitting and plotting: one call returns the survey index table `data.CatL`, the weight table `data.wgt` and the maturity table `data.mat` with the generating values in `true_params`, and `save_csv = TRUE` writes them as CSV files to `output_dir`. It applies one fishing mortality to all ages and fixes the length CV at 0.1. `years` must be consecutive calendar years; relabeling columns as quarters does not create quarterly dynamics.

完整操作模型用于对照已知种群的实验，需要三次调用：`initialize_params()` 由预设生成参数列表，`sim_cal()` 据此推导生物学数组，`sim_data()` 让种群经过预热期（最初被丢弃的年份）向前演进，并为每次重复写一个文件；补充量服从 Beverton-Holt 曲线，补充量和捕捞死亡率都带有 AR(1) 过程偏差。下表比较两个预设；[`initialize_params()` 的函数参考](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#initialize_params)列出全部设置。

The full operating model, for experiments against a known population, takes three calls: `initialize_params()` builds the parameter list from a preset, `sim_cal()` derives the biological arrays, and `sim_data()` runs the population through a burn-in (discarded first years) and writes one file per replicate, with Beverton-Holt recruitment and AR(1) process deviations in recruitment and fishing mortality. The table compares the two presets; the [reference of `initialize_params()`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#initialize_params) lists every setting.

| 设置 / Setting | flatfish | tuna |
|---|---|---|
| 操作模型 / Operating model | 年龄结构 / Age-based | 年龄与体长联合 / Joint age-length |
| `growth_step` | 1 年 / 1 year | 0.25 年 / 0.25 year |
| `nyear`、`burn_in` / `nyear`, `burn_in` | 100、80 年 / 100, 80 years | 100、95 年 / 100, 95 years |
| 保留的观测 / Retained observations | 20 个年度时间步 / 20 annual steps | 20 个季度时间步 / 20 quarterly steps |
| `nage`、`rec.age` / `nage`, `rec.age` | 15 个年龄组、1 年 / 15 classes, 1 year | 20 个年龄组、0.25 年 / 20 classes, 0.25 year |
| `Linf`、`vbk` / `Linf`, `vbk` | 60、每年 0.2 / 60, 0.2 per year | 152、每年 0.38 / 152, 0.38 per year |
| `M`、`F_mean` / `M`, `F_mean` | 0.2、0.3（每个年度时间步） / 0.2, 0.3 per annual step | 0.2、0.2（每个季度时间步） / 0.2, 0.2 per quarterly step |

`str()` 显示三张表和 `true_params`；`initialize_params(species = "?")` 列出各预设。无效输入，例如 `L95_sel` 小于 `L50_sel`，会在写任何文件之前停止调用。

`str()` shows the three tables and `true_params`; `initialize_params(species = "?")` lists the presets. Invalid inputs, such as `L95_sel` below `L50_sel`, stop the call before any file is written.

<a id="simulation-generate"></a>

### 2. 生成重复并转换成输入表 / Generate replicates and convert them to input tables

```r
source("scripts/simulation_workflow.R", encoding = "UTF-8")
pa <- initialize_params(species = "flatfish", first.year = 2000,
                        observation_error = "independent")
bio <- sim_cal(pa)
sm <- sim_data(bio, pa, iter_range = 4:5, return_iter = 4,
               output_dir = "simulation_examples/flatfish")
inputs <- simulation_to_tables(sm, pa)
tuna_pa <- initialize_params(species = "tuna", first.year = 2000)
tuna <- sim_data(sim_cal(tuna_pa), tuna_pa, iter_range = 4:5,
                 return_iter = 4, output_dir = "simulation_examples/tuna")
tuna_inputs <- simulation_to_tables(tuna, tuna_pa)
sm$years
tuna$years
str(inputs)
```

`iter_range` 给出互不重复的非负整数编号，同时也是随机种子；`sim_data()`、`sim_model()`、`sim_acl()` 和 `sim_alscl()` 均接受编号 0；`sim_data()` 用 `save()` 把每次重复保存为 `output_dir` 中的 `sim_rep<id>` 文件，读取时用 `load()`，`return_iter` 选择返回到内存的那一次。在 `sm` 中，`SN_at_len` 是按时间乘体长排列的调查尾数矩阵，`weight` 和 `mat` 按体长乘时间排列，`years` 是保留时间步的日历，`nyear` 是它们的个数，`SSB`、`Rec`、`TB` 和 `N_at_age` 是生成真值。

`iter_range` gives distinct nonnegative integer replicate IDs, which are also the seeds; ID 0 is accepted by `sim_data()`, `sim_model()`, `sim_acl()` and `sim_alscl()`; `sim_data()` saves each replicate as `sim_rep<id>` in `output_dir` with `save()`, read back with `load()`, and `return_iter` selects the one returned in memory. In `sm`, `SN_at_len` is a time by length matrix of survey numbers, `weight` and `mat` are length by time, `years` is the calendar of retained time steps and `nyear` their count, and `SSB`, `Rec`, `TB` and `N_at_age` are the generating truth.

`simulation_to_tables(sm, pa)` 转置 `SN_at_len`，用体长中点作为行标签、用 `sm$years` 作为列名，并把三张表作为一个列表返回；[模拟调查数据案例](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md#case-simulate-survey)从 `pa` 加入生物学设置并拟合一次重复。`run_simulation_examples(out = "simulation_examples")` 为两个预设完成本步骤，把表写成 CSV 文件并在旁边保存 `truth.rds`；两个预设的第 4 次重复已保存在仓库中，见[下载和读取说明](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/data/cases/README.md)。

`simulation_to_tables(sm, pa)` transposes `SN_at_len`, labels rows with the length midpoints and columns with `sm$years`, and returns the three tables as a list; the [simulate survey case](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md#case-simulate-survey) adds the biology from `pa` and fits one replicate. `run_simulation_examples(out = "simulation_examples")` runs this step for both presets and writes CSV tables with `truth.rds` beside them; the seed-4 replicate of both presets is in the repository with [download and reading instructions](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/data/cases/README.md).

如果 `simulation_to_tables()` 因参数列表中的 `len_mid` 与重复文件记录的坐标不同而停止，请传入生成该文件的参数列表。把 `sim_rep` 文件、参数列表和软件包版本与实验一起保存。

If `simulation_to_tables()` stops because `len_mid` differs from the coordinates recorded in the replicate, pass the parameter list that generated the file. Keep the `sim_rep` files, the parameter list and the package version with an experiment.

`sim_data()` 在抽样或写文件前核对生物学数组及其来源参数是否与 `pa` 一致。修改生长、年龄、时间步、体长组、重量、成熟、调查可捕性或选择性后，应重新运行 `bio <- sim_cal(pa)`，不要手动修改数组。只修改死亡率、补充量、误差、时长或日期，无须重算生物学数组。没有来源记录但内容一致的旧对象仍可使用。拟合已保存重复时，调查可捕性与元数据不一致会生成错误记录，应使用一致的输入重新生成模拟。

`sim_data()` checks that the biological arrays and their recorded inputs match `pa` before drawing data or writing files. After changing growth, ages, the time step, length bins, weight, maturity, catchability or selectivity, run `bio <- sim_cal(pa)` again; do not edit the arrays by hand. Changes only to mortality, recruitment, error, duration or dates do not require rebuilding biology. Matching older objects without recorded inputs still work. When fitting saved replicates, inconsistent survey-catchability metadata produces an error record: regenerate the simulation with matching inputs.

<a id="simulation-rates"></a>

### 3. 设置死亡率、变异和时间单位 / Set rates, variation and time units

```r
mean(quick$true_params$F_trend)
pa$F_sd / sqrt(1 - pa$F_ar^2)
short_pa <- initialize_params(species = "flatfish", nyear = 5, burn_in = 2,
                              first.year = 2024)
short <- sim_data(sim_cal(short_pa), short_pa, iter_range = 4:5,
                  return_iter = 4, output_dir = "simulation_examples/short")
short$years
short$nyear
```

快速模拟器的 `mean_F` 是生成的年度 F 的算术平均值。完整模拟器的 `F_mean` 是 `F[t] = F_mean * exp(d[t])` 中的基准水平，其中 `d[t]` 是均值为零的 AR(1) 过程，系数为 `F_ar`，创新标准差为 `F_sd`，所以生成的 F 的平均值与 `F_mean` 不同；与拟合所得对数 F 标准差比较时，应使用边际标准差 `F_sd / sqrt(1 - F_ar^2)`，而不是 `F_sd`。`std_logR` 和 `R_ar` 对补充量起同样作用，`std_SN` 是对数调查误差的标准差，`M` 和 `F_mean` 是每个时间步的速率，因此 tuna 的取值按季度计。

In the quick simulator `mean_F` is the arithmetic mean of the generated annual F. In the full simulator `F_mean` is the baseline of `F[t] = F_mean * exp(d[t])`, where `d[t]` is a zero-mean AR(1) process with coefficient `F_ar` and innovation SD `F_sd`, so the mean of the generated F differs from `F_mean`; compare the marginal SD `F_sd / sqrt(1 - F_ar^2)`, not `F_sd`, with a fitted log-F SD. `std_logR` and `R_ar` do the same for recruitment, `std_SN` is the SD of the log survey error, and `M` and `F_mean` are rates per time step, so the tuna values are per quarter.

`nyear` 和 `burn_in` 都是以年为单位的时长；`growth_step` 必须能整除一年，`burn_in` 必须是 `growth_step` 的整数倍且小于 `nyear`，并且至少要保留两个时间步才能拟合。`first.year` 标记第一个保留的时间步，`sm$nyear` 是保留的时间步数。如果调用因 `burn_in` 不是 `growth_step` 的整数倍而停止，年度时间步请用整年，季度时间步请用整季度。

`nyear` and `burn_in` are durations in years; `growth_step` must divide one year, `burn_in` must be an exact multiple of `growth_step` and smaller than `nyear`, and at least two time steps must be retained for fitting. `first.year` labels the first retained step, and `sm$nyear` counts retained steps. If the call stops because `burn_in` is not an exact multiple of `growth_step`, use whole years for annual steps and quarter years for quarterly steps.

<a id="simulation-fit"></a>

### 4. 拟合重复并汇总 / Fit the replicates and summarize

```r
data("YTF_example")
cfg <- YTF_example$fit_config$acl
cfg$parameters$log_std_log_F <- log(pa$F_sd / sqrt(1 - pa$F_ar^2))
fits <- sim_acl(iter_range = 4:5, sim_data_path = "simulation_examples/flatfish",
                output_dir = "simulation_examples/fits_acl",
                parameters = cfg$parameters, map = cfg$map, M = pa$M,
                nstarts = 2, ncores = 2)
truth <- setNames(lapply(4:5, function(i) {
  e <- new.env(parent = emptyenv())
  load(file.path("simulation_examples/flatfish", paste0("sim_rep", i)), envir = e)
  s <- e$sim.data
  list(year = s$years, SSB = as.numeric(s$SSB), Rec = as.numeric(s$Rec))
}), paste0("result_rep_", 4:5))
performance <- summarize_simulations(fits, truth, quantities = c("SSB", "Rec"))
performance$replicates
performance$summary
```

`sim_acl()` 读取 `sim_data_path` 中的每个 `sim_rep<id>` 文件，从文件构造三张表和生物学设置，再用你传入的初值、`map` 和 `M` 拟合 ACL；`sim_alscl()` 用 ALSCL 的参数名做同样的事。

`sim_acl()` reads each `sim_rep<id>` in `sim_data_path`, builds the tables and the biology from the file and fits ACL with the starting values, `map` and `M` you pass; `sim_alscl()` does the same with ALSCL parameter names.

`YTF_example` 的配置提供 flatfish 的生长设置和指定的过程假设。本例把其中固定的 log-F SD 改为从 `pa` 换算的边际 SD，即 0.3023716。固定的初始数量及相关系数设置属于拟合假设：操作模型使用共用 F 与选择性，并沿年龄累加初始偏差；ACL 使用年龄与时间可分离的 F，以及独立初始偏差。SD 换算后，这些结构仍然不同。自己的配置按[选择拟合设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting)建立。

The `YTF_example` configuration supplies the flatfish growth settings and a conditional process specification. The example overrides its fixed log-F SD with the marginal SD converted from `pa`, 0.3023716. Fixed initial-abundance and correlation settings are fitting assumptions: the operating model has shared F with selectivity and cumulative initial-age deviations, while ACL uses separable age-by-time F and independent initial deviations. These structures still differ after the SD conversion. Build your own configuration as in [Choose the fitting settings](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting).

每次重复在一个工作进程中拟合，它的 `nstarts` 个初值依次运行；`ncores` 决定同时运行多少次重复。每次重复的结果，包括带有 `converge = "FAILED"` 和 `error` 信息的失败，都会返回并保存为 `output_dir` 下的 `result_rep_<id>`。

Each replicate is fitted on one worker with its `nstarts` starts run one after the other, and `ncores` sets how many replicates run at the same time. Every result, including a failure with `converge = "FAILED"` and an `error` message, is returned and saved as `result_rep_<id>` in `output_dir`.

`summarize_simulations()` 需要真值列表与拟合列表同名，每个元素包含 `year` 和每个量的一个向量，这里从重复文件读取，使时间坐标一致。`performance$replicates` 给出每次重复的数值检查和错误信息；`performance$summary` 按量给出失败率、偏差、相对偏差、RMSE 和区间覆盖率，以及各自的计数。偏差和 RMSE 只使用通过数值检查的拟合，覆盖率还需要有限的标准误，所以报告统计量时要一并报告 `failure_rate`。如果调用停止并提示“identical unique replicate names”或“time coordinates differ”，说明真值不是从拟合所用的同一批文件读取的。

`summarize_simulations()` needs the truth as a list with the same names as the fits, each with `year` and one vector per quantity, read here from the replicate files so that the time coordinates match. `performance$replicates` gives the numerical checks and error of each replicate; `performance$summary` gives, per quantity, failure rate, bias, relative bias, RMSE and interval coverage with their counts. Bias and RMSE use fits that passed the numerical checks and coverage also needs finite standard errors, so report `failure_rate` with the statistics. If the call stops with "identical unique replicate names" or "time coordinates differ", the truth was not read from the same files as the fits.

时间坐标和每个量必须是一维实数数值向量。矩阵和数组即使总长度与时间步数相同也会被拒绝。先将年龄别或体长别数量按所需定义汇总为时间序列，不要把分组数据直接展平当作时间。

Both the time coordinates and each quantity must be one-dimensional real numeric vectors. Matrices and arrays are rejected even when their total length matches the number of periods. Aggregate age- or length-specific quantities to the intended time series before calling; do not flatten grouped values into time.

<a id="simulation-fitted"></a>

### 5. 从拟合模型模拟 / Simulate from a fitted model

```r
fit <- run_acl(YTF_example, silent = TRUE)
simulated <- simulate_fit(fit, nsim = 3, seed = 42, process = "resample")
names(simulated$simulations[[1]])
simulated$simulations[[1]]$truth$SSB
```

`simulate_fit()` 从拟合好的 ACL 或 ALSCL 模型生成数据集，这就是拟合模型模拟。`process = "conditional"` 保留拟合的种群，只重新抽取观测误差；`process = "resample"` 还在拟合的标量参数值下重新抽取补充量、捕捞死亡率和初始丰度的过程偏差。`simulated$simulations` 的每个元素包含 `x`（`run_acl(x)` 可用的输入列表）、`observations` 和 `truth`，所以可以用 `lapply(simulated$simulations, function(s) s$truth)` 作为真值，对再拟合结果运行 `summarize_simulations()`。未通过数值检查的拟合会被拒绝，除非设置 `allow_failed_fit = TRUE`；[模型验证案例](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md)再拟合这些重复，并继续做预测检验。

`simulate_fit()` generates datasets from a fitted ACL or ALSCL model: fitted-model simulation. `process = "conditional"` keeps the fitted population and redraws only the observation error; `process = "resample"` also draws new recruitment, fishing mortality and initial-abundance process deviations at the fitted scalar parameter values. Each element of `simulated$simulations` has `x`, an input bundle for `run_acl(x)`, `observations` and `truth`, so `summarize_simulations()` applies to the refits with `lapply(simulated$simulations, function(s) s$truth)` as the truth. A fit that failed the numerical checks is rejected unless `allow_failed_fit = TRUE`; the [model validation case](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md) refits the replicates and continues with hindcast validation.

<a id="simulation-next"></a>

### 下一步 / What next

| 想做什么 / What you want to do | 阅读 / Read |
|---|---|
| 绘制一次重复，用两个模型拟合并与真值比较 / Plot one replicate, fit both models and compare with the truth | [如何模拟调查数据？](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md#case-simulate-survey) / [How do I simulate survey data?](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md#case-simulate-survey) |
| 再拟合拟合模型模拟的数据并预测留出年份 / Refit fitted-model simulations and predict withheld years | [模型验证](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md) / [Model validation](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md) |
| 用更少的时间运行更多重复 / Run more replicates in less time | [速度设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/SPEED_GUIDE.md) / [Speed settings](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/SPEED_GUIDE.md) |
| 保存种子、设置和版本以便重复实验 / Keep seeds, settings and versions for a repeatable experiment | [复现结果](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ADVANCED_WORKFLOWS.md) / [Reproducibility](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ADVANCED_WORKFLOWS.md) |
| 比较年度和季度设置 / Compare annual and quarterly settings | [年度与季度时间步](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASE_STUDIES.md) / [Annual and quarterly time steps](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASE_STUDIES.md) |
| 拟合自己的表 / Fit your own tables | [准备调查数据](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel) / [Prepare your survey data](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel) |

---

[← 上一章 · Previous](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/04-Built-in-YTF) · [目录 · Contents](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [下一章 · Next →](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/06-Fitting)
