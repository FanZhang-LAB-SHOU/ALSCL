# 05 模拟与批量实验 · Simulation

[← 上一章 · Previous](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/04-Built-in-YTF) · [目录 · Contents](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [下一章 · Next →](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/06-Fitting)

**ALSCL 2.2.9 · 简体中文 / English**

### 3.1 快速生成三张表 / Quick input-table simulator

```r
# 简单年度模拟，可直接导出 CSV / Simple annual simulation with CSV export
quick <- simulate_example_data(
  years = 2000:2019, seed = 42, bin_breaks = seq(5, 51, 2),
  Linf = 60, vbk = 0.2, t0 = 1/60, M = 0.2, nage = 15,
  L50_sel = 15, L95_sel = 20, L50_mat = 35, L95_mat = 40,
  wgt_a = exp(-12), wgt_b = 3, mean_F = 0.3,
  cv_catch = 0.2, rec_sigma = 0.3,
  save_csv = TRUE, output_dir = "my_simulation")
str(quick)
```

`years` 必须是连续年度，不能通过写季度列名把该简易模拟器变成季度模型。`cv_catch` 控制调查观测 CV；`rec_sigma` 控制对数补充变异；该函数使用简化的共同 F、独立补充扰动及固定长度 CV = 0.1。它不等于完整 Beverton–Holt 模拟器，也不等于内置 `YTF_example` 的生成流程。

Use consecutive annual `years`. Changing labels does not create quarterly dynamics. `cv_catch` controls survey observation CV and `rec_sigma` log recruitment variation. This simplified simulator uses common F, independent recruitment perturbations and fixed length CV 0.1; it differs from both the full operating model and the bundled YTF generation recipe.

### 3.2 完整模拟器与两个案例 / Full simulator and two cases

两个预设的 seed 4 数据、三张 CSV 和完整真值对象已随文档保存：[下载及读取方法 / Download and read the two saved cases](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/data/cases/README.md)。

```r
# 参数 → 生物量表 → 随机模拟 / Parameters → biological arrays → simulation
pa <- initialize_params(species = "flatfish", first.year = 2000,
                        observation_error = "independent")
bio <- sim_cal(pa)
sm <- sim_data(bio, pa, iter_range = 4:5, return_iter = 4,
               output_dir = "simulation_examples/flatfish")
# 长度型季度案例 / Length-based quarterly case
tuna_pa <- initialize_params(species = "tuna", first.year = 2000)
tuna <- sim_data(sim_cal(tuna_pa), tuna_pa, iter_range = 4:5,
                 return_iter = 4, output_dir = "simulation_examples/tuna")
# 将模拟矩阵变成模型输入 / Convert simulated matrices to input tables
source("scripts/simulation_workflow.R", encoding = "UTF-8")
flatfish_inputs <- simulation_to_tables(sm, pa)
tuna_inputs <- simulation_to_tables(tuna, tuna_pa)
```

| 设置 / Setting | flatfish / YTF 风格 | tuna / 金枪鱼风格 |
|---|---|---|
| 生成模型 / Operating model | 年龄型 / Age-based | 年龄与长度联合 / Joint age-length |
| `growth_step` | 1 年 / year | 0.25 年 / year |
| `nyear`, `burn_in` | 100, 80 年 / years | 100, 95 年 / years |
| 保留观测 / Retained observations | 20 年度 / annual steps | 20 季度 / quarterly steps |
| `nage`, `rec.age` | 15, 1 年 / year | 20, 0.25 年 / year |
| `Linf`, `vbk` | 60, 0.2/年 / year | 152, 0.38/年 / year |
| `M`, `F_mean` | 0.2, 0.3 每年 / per step | 0.2, 0.2 每季度 / per step |

这是包内的两个模拟预设案例，不能当成已取得论文两个案例的原始观测。完整参数见 [initialize_params](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#initialize_params)。`nyear`、`burn_in`、`sim_year` 的单位是**年**；返回 `sm$nyear` 是保留的**时间步数**。`SN_at_len` 是时间 × 长度，导入时要转置；`weight` 和 `mat` 已是长度 × 时间。

These are the two package simulation presets, not recovered empirical datasets from the paper. Duration arguments are in **years**, whereas returned `sm$nyear` counts retained **steps**. Transpose `SN_at_len` (time × length); weight and maturity are already length × time.

`iter_range` 同时指定重复编号和随机种子；`return_iter` 选择在内存中返回哪次重复。每个 `sim_rep4` 等文件由 `save()` 写出，应用 `load()`，不是 `readRDS()`。`observation_error="independent"` 让每个长度与时间单元有独立扰动；`"shared_time"` 让同一期的长度组共享扰动，适合专门的误差结构实验。

`iter_range` provides replicate IDs and seeds; `return_iter` selects the in-memory replicate. `sim_rep*` files use `save()/load()`, not RDS. Independent error varies across cells, while shared-time error applies the same perturbation to all length bins in a period.

```r
# 同时生成两个案例及 CSV、真值文件 / Generate both cases, CSV and truth files
cases <- run_simulation_examples(out = "simulation_examples", fit_batch = FALSE)
# 加上两个 ACL 重复拟合，保存失败诊断 / Add two ACL fits and retain failures
# run_simulation_examples(out = "simulation_examples", fit_batch = TRUE)
e <- new.env()
load("simulation_examples/flatfish/sim_rep4", envir = e)
str(e$sim.data)
```

### 3.3 死亡率、变异和时间单位 / Rates, variation and time units

`simulate_example_data()` 的 `mean_F` 是生成年度 F 序列的算术平均值。完整模拟器的 `F_mean` 则是 `F[t] = F_mean * exp(d[t])` 中的过程基准水平；加入随机偏差后，通常不等于实际序列的算术平均值。`F_sd` 是对数 F 的 AR(1) 创新标准差，平稳相关为 `F_ar` 时，边际标准差为 `F_sd / sqrt(1 - F_ar^2)`，不同于拟合模型采用的边际对数 F 标准差。`q_surv_L50` 和 `q_surv_L95` 定义调查可捕性曲线，是调查输入，不是捕捞选择性的估计结果。

完整模拟器的 `nyear`、`burn_in` 都以年为单位，且分别必须对应整数个 `growth_step`。因此季度模式允许半年预热，年度模式不允许。返回的 `sm$nyear` 是保留时间步数；`first.year` 是第一期保留观测的年份，`sm$years` 保存完整观测时间轴。`simulation_to_tables()` 与批量拟合函数保留这条时间轴；完全没有年份元数据的旧文件仍可使用从 2000 开始的后备规则。只保留一期时仍返回矩阵，但拟合至少需要两期。

`mean_F` in `simulate_example_data()` is the arithmetic mean of the generated annual F trajectory. In the full simulator, `F_mean` instead sets the process baseline in `F[t] = F_mean * exp(d[t])`; random variation means it is not generally the realized arithmetic mean. `F_sd` is the innovation SD of the log-F AR(1) process. For stationary correlation `F_ar`, its marginal SD is `F_sd / sqrt(1 - F_ar^2)`. This differs from the marginal log-F SD used by the fitted models. Survey catchability is set by `q_surv_L50` and `q_surv_L95`; these are survey inputs, not fishing selectivity estimates.

For the full simulator, `nyear` and `burn_in` are durations in years and must each contain a whole number of `growth_step` intervals. Thus a half-year burn-in is valid with quarterly steps, but not annual steps. Returned `sm$nyear` counts retained steps. `first.year` labels the first retained observation, and `sm$years` records the complete retained calendar. `simulation_to_tables()` and the batch-fitting functions preserve this calendar; old files lacking year metadata still have a documented 2000-based fallback. A single retained period stays a matrix, although fitting requires at least two periods.

```r
quick <- simulate_example_data(years = 2000:2019, mean_F = 0.3, seed = 42)
stopifnot(isTRUE(all.equal(mean(quick$true_params$F_trend), 0.3)))
zero_F <- simulate_example_data(years = 2000:2019, mean_F = 0, seed = 42)
stopifnot(all(zero_F$true_params$F_trend == 0))
pa <- initialize_params(species = "flatfish", nyear = 5, burn_in = 2,
                        first.year = 2024)
sm <- sim_data(sim_cal(pa), pa, iter_range = 4:5, return_iter = 4,
               output_dir = "simulation_224")
stopifnot(identical(as.numeric(sm$years), as.numeric(2024:2026)))
source("scripts/simulation_workflow.R", encoding = "UTF-8")
inputs <- simulation_to_tables(sm, pa)
```

### 3.4 生物输入与零值 / Biological inputs and zeros

`mat_func()` 使用稳定的 logistic 计算，陡峭上升曲线接近 1 时不会溢出。`L50` 与 `L95` 必须是不同的有限标量；仍允许下降曲线（`L95 < L50`），用于穹顶选择性。体长及派生生物矩阵必须有限，模拟的自然与捕捞死亡率必须非负。当 `M = 0` 且 `F_mean = 0` 时，渔获尾数和生物量为零，不再返回未定义数值；丰度和补充量仍按选定模拟模型演变。



`mat_func()` uses a stable logistic calculation: a steep increasing curve approaches one without overflowing. `L50` and `L95` must be distinct finite scalars; a descending curve (`L95 < L50`) remains available for dome selectivity. Length values and derived biological arrays must be finite. Simulated natural and fishing mortality must be nonnegative. With both `M = 0` and `F_mean = 0`, fishery catch numbers and biomass are zero, rather than undefined; abundance and recruitment still follow the chosen operating model.

```r
stopifnot(all(is.finite(mat_func(20, 20.1, c(20, 30, 50)))))
pa0 <- initialize_params(species = "flatfish", nyear = 4, burn_in = 2,
                         M = 0, F_mean = 0)
sm0 <- sim_data(sim_cal(pa0), pa0, iter_range = 4,
                output_dir = file.path(tempdir(), "alscl-zero-mortality"))
stopifnot(all(sm0$CN == 0), all(sm0$CB == 0))
```


### 体长分组与过程参数 / Length bins and process parameters

快速模拟器把首尾体长组分别积分到负无穷和正无穷，与拟合模型一致。有限 `bin_breaks` 仍用于标签与中点，不截断概率。M、F 和噪声尺度必须非负，生长参数为正、重量系数非负，选择性及成熟曲线的 95% 端点高于 50% 端点。非法参数或非有限生成结果会在创建 CSV 前报错。完整模拟器还检查年龄—体长概率及生长转移概率的归一化。

The quick simulator integrates the first and last length bins to negative and positive infinity, matching the fitted models. Finite `bin_breaks` still determine labels and midpoints; they do not truncate probability. Use nonnegative M, F and noise scales, positive growth parameters and a nonnegative weight coefficient, and increasing selectivity/maturity endpoints. Invalid parameters or nonfinite generated values stop before CSV files are created. The full simulator also requires normalized age-length keys and growth transitions.

完整模拟器要求 `init_Z`、过程与观测标准差、F 过程基准水平均为有限非负值。`F_ar` 与 `R_ar` 必须严格介于 -1 和 1 之间，允许负的平稳相关。Beverton–Holt 的 alpha 和初始补充量可以为零，beta 必须为正。非法过程输入会在随机抽样或创建文件前报错，保留已有模拟文件及调用者的随机数状态。

The full simulator validates `init_Z`, process and observation standard deviations, and the F process baseline as finite nonnegative values. `F_ar` and `R_ar` must lie strictly between -1 and 1; negative stationary correlations remain valid. Beverton–Holt alpha and initial recruitment may be zero, while beta must be positive. Invalid process inputs stop before random draws or file creation, preserving existing simulations and the caller's random-number state.

### 观测尺度与坐标 / Observation scale and coordinates

完整模拟保留零值和极小正调查观测。调查生物量等于调查尾数乘以重量，零资源情形也保持一致。拟合时，`zero_action = "missing"` 将零视为缺失，`"error"` 拒绝零值；全零调查没有正观测，不能使用当前对数正态模型拟合。

Full simulations retain zero and very small positive survey observations. Survey biomass equals survey abundance times weight, including extinction scenarios. For fitting, zero observations are missing with `zero_action = "missing"` and rejected with `"error"`; an entirely zero survey contains no positive observations and cannot be fitted by the current lognormal model.

模拟体长中点必须落在对应组内，检查规则与拟合一致；首尾组仍吸收分布尾部。参数准备阶段会拒绝无效分组，生物量计算和模拟前还会再次检查，包括用户手动修改的输入；错误发生在随机抽样和写文件前。

Simulation length midpoints must lie within their corresponding bins, using the same containment rules as fitting. The first and last bins absorb the tails. Invalid bin geometry is rejected during parameter preparation and rechecked before biological calculations or simulation, including manually modified inputs, before random draws or output files.

### 3.5 批量拟合与表现汇总 / Batch fitting and performance summaries

`sim_model(model = "acl")` 和 `sim_model(model = "alscl")` 可批量拟合重复文件；`sim_acl()` 和 `sim_alscl()` 提供模型专用入口，原来的 `sim_acl()` 写法保留。自行循环调用 `run_acl()` 或 `run_alscl()` 也是可选方式。生成器与拟合器的参数名不同，应使用对应模型的初值与 map，保留每次重复及其生成真值，并报告偏差、RMSE、区间覆盖率和失败率。匹配输入与汇总分母见[完整批量示例](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ASSESSMENT_WORKFLOWS.md)。

`sim_model(model = "acl")` and `sim_model(model = "alscl")` fit replicate files with the selected model. `sim_acl()` and `sim_alscl()` provide model-specific interfaces; the original `sim_acl()` calls remain valid. A custom loop around `run_acl()` or `run_alscl()` is optional. Generator and estimator parameter names differ. Use model-specific starts and maps, retain every replicate and its generating truth, and report bias, RMSE, interval coverage and failure rates. See the [complete batch example](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ASSESSMENT_WORKFLOWS.md) for matched inputs and summary denominators.

`sim_model()`、`sim_acl()` 和 `sim_alscl()` 在发送 socket 任务前求值路径与参数变量，因此一般控制台或脚本中的变量传参也支持多核。保留失败重复并检查逐次拟合诊断；工作进程运行成功并不单独证明评估结果可用。

`sim_model()`, `sim_acl()` and `sim_alscl()` resolve path and parameter variables before sending tasks to socket workers, so ordinary console/script calls work with multiple cores. Retain failed replicates and inspect each fit's diagnostics; successful worker execution alone does not establish a usable assessment.

`sim_model()`、`sim_acl()` 和 `sim_alscl()` 将每次重复的结果（包括失败状态）保存到 `result_rep_<iter>`。复用输出目录时，本轮失败记录会替换旧成功结果；汇总前检查 `converge` 和 `error`。写入失败会明确报告，不能视为已经保存。`simulation_to_tables(sm, pa)` 使用模拟结果的长度坐标，并拒绝与参数不一致的坐标，不再给观测重新贴错标签；没有坐标的旧模拟可使用匹配的参数元数据。

`sim_model()`, `sim_acl()` and `sim_alscl()` save the status of every replicate, including failures, to `result_rep_<iter>`. Reusing an output directory replaces an earlier success with the current failure record; inspect `converge` and `error` before summarizing results. Output write failures are reported and must not be treated as saved results. `simulation_to_tables(sm, pa)` uses the simulation length coordinates and rejects conflicting parameter coordinates instead of relabeling observations; legacy simulations without coordinates can use matching parameter metadata.

### 复现已保存实验 / Reproducing saved experiments

复现旧实验时，应保存原始输入、生成真值、种子和包的代码版本。2.2.4 对快速模拟器 `mean_F` 的修正、首尾组概率积分修正，以及 2.2.9 取消完整模拟器调查值的 `1e-6` 下限，都可能使相同种子重新生成不同观测。已保存的数据不会被改写。版本沿革见[更新日志](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/NEWS.md)。

To reproduce an older experiment, keep its saved inputs, generating truth, seed and package revision. The correction to quick-simulator `mean_F` in 2.2.4, tail-bin integration changes, and removal of the full simulator's `1e-6` survey floor in 2.2.9 can change regenerated observations with the same seed. Saved datasets are not rewritten. See the [changelog](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/NEWS.md) for version history.

### 拟合模型生成与预测验证 / Fitted-model generation and prediction validation

新增 `simulate_fit()` 区分固定状态的观测模拟与固定标量参数的过程重抽样，返回可直接拟合的输入及真值；`hindcast_model()` 用早期数据拟合，再对留出调查指数评分。完整运行步骤见[模型验证案例](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md)。模拟批次的 `nstarts` 控制每个重复的独立初值数，`ncores` 仍控制外层并行。

`simulate_fit()` distinguishes observation simulation at fitted states from process resampling at fixed scalar estimates, retaining reusable inputs and truth. `hindcast_model()` fits earlier data and scores withheld survey observations. See the complete [model-validation case](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md). Simulation-batch `nstarts` controls independent starts per replicate; `ncores` controls outer parallelism.

---

[← 上一章 · Previous](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/04-Built-in-YTF) · [目录 · Contents](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [下一章 · Next →](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/06-Fitting)
