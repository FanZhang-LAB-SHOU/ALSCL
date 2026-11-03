# 06 选择拟合设置 · Choose the fitting settings

[← 上一章 · Previous](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/05-Simulation) · [目录 · Contents](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [下一章 · Next →](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/07-Diagnostics)

**ALSCL 2.4.3 · 简体中文 / English**

本页帮你决定模型估计哪些参数、固定哪些参数、捕捞死亡率采用什么结构，以及优化器如何运行。你需要一个输入列表 `x`（[准备调查数据](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel)），并且最好已读过[理解第一次拟合](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin)，其中的检查会告诉你哪项设置需要调整。

On this page you decide which parameters the models estimate, which are fixed, how fishing mortality is structured, and how the optimizer runs. You need an input bundle `x` ([Prepare your survey data](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel)) and you should have read [Understand your first fit](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin), whose checks tell you whether a setting needs changing.

设置分三组：`x$fit_args` 中的生物学和数据设置，见[准备调查数据](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel)；模型配置（初值、边界、`map`、F 结构），ACL 和 ALSCL 分别设置；优化器设置（初值个数、工作进程、优化轮数），它们改变求解方式，模型本身保持不变。

The settings fall into three groups: the biology and data settings in `x$fit_args`, which [Prepare your survey data](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel) explains; the model configuration (starting values, bounds, `map`, F structure), chosen separately for ACL and ALSCL; and the optimizer settings (starts, workers, passes), which change how the answer is found and leave the model unchanged.

<a id="fitting-controls-settings"></a>

### 1. 了解各项设置及其位置 / Know the settings and where they live

| 设置 / Setting | 含义 / Meaning | 放在哪里 / Where to put it |
|---|---|---|
| `rec.age`、`nage`、`M`、`sel_L50`、`sel_L95`、`growth_step`、`len_mid`、`len_border` / `rec.age`, `nage`, `M`, `sel_L50`, `sel_L95`, `growth_step`, `len_mid`, `len_border` | 生物学、调查可捕性和时间步 / Biology, survey catchability and time step | `x$fit_args`，两个模型共用 / `x$fit_args`, shared by both models |
| `zero_action` | 调查零值按缺失处理（默认 `"missing"`）或终止拟合（`"error"`） / Treat survey zeros as missing (`"missing"`, default) or stop (`"error"`) | `x$fit_args` |
| `parameters`、`parameters.L`、`parameters.U` / `parameters`, `parameters.L`, `parameters.U` | 标量参数在优化器尺度上的初值和边界 / Starting values and bounds of the scalar parameters, on the optimizer scale | `x$fit_config$acl` 或 `x$fit_config$alscl` / `x$fit_config$acl` or `x$fit_config$alscl` |
| `map` | 哪些参数固定在初值、哪些参数共享 / Which parameters are fixed at their starting value or tied together | `x$fit_config$acl` 或 `x$fit_config$alscl` / `x$fit_config$acl` or `x$fit_config$alscl` |
| `F_structure` | `"group_year"`（默认）：F 随年龄或体长及时间步变化；`"year"`：每个时间步一个 F / `"group_year"` (default): F varies by age or length and by time step; `"year"`: one F per time step | `x$fit_args` 或调用 / `x$fit_args` or the call |
| `nstarts`、`ncores` / `nstarts`, `ncores` | 独立初值的个数和运行它们的工作进程数 / Number of independent optimizer starts and of worker processes running them | 调用 / The call |
| `train_times` | 每个初值连续优化的轮数（默认 1） / Successive optimizer passes from each start (default 1) | 调用 / The call |
| `polish` | 对最佳初值做带检查的 Newton 收尾（默认 `TRUE`） / Finish the best start with checked Newton steps (default `TRUE`) | 调用 / The call |
| `control` | `nlminb()` 的控制参数，如 `iter.max` / `nlminb()` controls such as `iter.max` | 调用 / The call |
| `silent`、`output` / `silent`, `output` | 不显示进度信息；把诊断和图写入 `output/` / Hide progress messages; write diagnostics and plots to `output/` | 调用 / The call |

调用中给出的值只在本次调用中覆盖保存的值。希望之后的每项分析（回溯分析、情景、预测检验）都使用某个选择时，把它存入 `x`，做法见第 7 步。

Values in the call override the stored ones for that call only. Store a choice in `x` when every later analysis (retrospectives, scenarios, hindcast validation) should use it; step 7 shows how.

<a id="fitting-controls-parameters"></a>

### 2. 查看哪些参数会被估计 / See which parameters are estimated

```r
plan <- inspect_parameters(x, "acl")
plan[, c("parameter", "kind", "status", "map_source", "natural_start")]
inspect_parameters(x, "alscl")[, c("parameter", "status", "natural_start")]
```

`inspect_parameters()` 列出所选模型的标量参数和过程偏差块、初值及状态，例如 `free`（估计）、`fixed`（固定）或 `tied`（共享）。`map_source` 说明固定状态来自模型默认还是你的 `map`。下面每做一次修改都可以再运行它；它只读取输入列表，既不编译也不拟合。

`inspect_parameters()` lists the scalar parameters and process-deviation blocks of the chosen model, with their starting values and status, including `free` (estimated), `fixed` or `tied`. `map_source` tells whether a fixed status comes from the model default or from your `map`. Run it after every change below; it compiles and fits nothing.

| 含义 / Meaning | ACL 参数 / ACL parameter | ALSCL 参数 / ALSCL parameter |
|---|---|---|
| 生长（von Bertalanffy） / Growth (von Bertalanffy) | `log_Linf`、`log_vbk`、`t0` / `log_Linf`, `log_vbk`, `t0` | `log_Linf`、`log_vbk`、`log_t0` / `log_Linf`, `log_vbk`, `log_t0` |
| 年龄别体长的离散程度；生长增量 CV / Spread of length at age; growth increment CV | `log_cv_len` | `log_cv_len`、`log_cv_grow` / `log_cv_len`, `log_cv_grow` |
| 平均补充量和平均 F（对数尺度） / Mean recruitment and mean F (log scale) | `mean_log_R`、`mean_log_F` / `mean_log_R`, `mean_log_F` | `mean_log_R`、`mean_log_F` / `mean_log_R`, `mean_log_F` |
| 过程偏差的标准差 / Standard deviations of the process deviations | `log_std_log_R`、`log_std_log_F`、`log_std_log_N0` / `log_std_log_R`, `log_std_log_F`, `log_std_log_N0` | `log_sigma_log_R`、`log_sigma_log_F`、`log_sigma_log_N0` / `log_sigma_log_R`, `log_sigma_log_F`, `log_sigma_log_N0` |
| F 在时间上的相关；在年龄或体长上的相关 / Correlation of F across time; across ages or lengths | `logit_log_F_y`、`logit_log_F_a` / `logit_log_F_y`, `logit_log_F_a` | `logit_log_F_y`、`logit_log_F_l` / `logit_log_F_y`, `logit_log_F_l` |
| 补充量在时间上的相关 / Correlation of recruitment across time | `logit_log_R` | `logit_log_R` |
| 初始总死亡率；调查观测 SD / Initial total mortality; survey observation SD | `log_init_Z`、`log_std_index` / `log_init_Z`, `log_std_index` | `log_init_Z`、`log_sigma_index` / `log_init_Z`, `log_sigma_index` |

默认情况下，ACL 固定 `log_std_log_F`、`logit_log_F_y`、`logit_log_F_a` 和 `t0`，ALSCL 固定 `log_sigma_log_F` 和 `log_t0`，其余都估计。`YTF_example` 固定得更多（生长参数和两个过程 SD），因为它的教学配置以运行快为目标；你自己的输入列表从默认设置开始。过程偏差 `dev_log_R`、`dev_log_F` 和 `dev_log_N0` 按数据维度生成，默认作为随机效应估计。它们的 `map` 可以固定某些偏差，或让多个偏差共享一个估计值；查看 `n_free`、`n_fixed` 和 `n_tied`，确认每个块中还有多少自由值。

By default ACL fixes `log_std_log_F`, `logit_log_F_y`, `logit_log_F_a` and `t0`, and ALSCL fixes `log_sigma_log_F` and `log_t0`; everything else is estimated. `YTF_example` fixes more (the growth parameters and two process SDs) so that its teaching configuration runs quickly; your own bundle starts from the defaults. The process deviations `dev_log_R`, `dev_log_F` and `dev_log_N0` are created from the data dimensions and estimated as random effects by default. Their `map` entries can fix individual deviations or tie them together; inspect `n_free`, `n_fixed` and `n_tied` to see how many remain free in each block.

<a id="fitting-controls-map"></a>

### 3. 用 map 固定或释放参数 / Fix or release parameters with map

```r
# 把生长参数固定在初值，并估计 F 在时间上的相关 / Fix growth at the starting values and estimate the F correlation across time
my_map <- list(log_Linf = factor(NA), log_vbk = factor(NA), logit_log_F_y = NULL)
a_map <- run_acl(x, map = my_map, silent = TRUE)
extract_parameters(a_map)
# 把选择存入输入列表，供之后的分析使用 / Keep the choice in the bundle for later analyses
x$fit_config$acl$map <- my_map
```

`factor(NA)` 把参数固定在初值；具名 `NULL` 释放一个模型默认固定的参数。调用中或 `x$fit_config` 中给出的 `map` 会整体替换保存的 map，所以每次都要列出全部想固定的项。当数据无法确定某个参数（常见迹象是 Hessian 不正定或相关系数估计到接近 1），或外部研究给出的值比拟合更可靠时，就固定该参数；每个固定值的来源都要随评估一起记录。`generate_map()` 把列表与 ACL 默认设置合并，但会丢掉 `NULL` 项，所以释放参数的列表要直接作为 `map` 传入。

`factor(NA)` fixes a parameter at its starting value; a named `NULL` releases a parameter that the model fixes by default. A `map` given in the call or stored in `x$fit_config` replaces the stored map completely, so list every fix you want each time. Fix a parameter when the data leave it undetermined (a Hessian that is not positive definite or a correlation estimated near 1 are the usual signs) or when an external study gives a better value than the fit could; record the source of every fixed value with the assessment. `generate_map()` merges a list with the ACL defaults but drops `NULL` entries, so pass release lists directly as `map`.

对过程偏差块，提供与偏差数量相同的因子：`NA` 将对应偏差固定在初值（零），重复的因子水平让对应偏差共享一个估计值。`simulate_fit(process = "resample")` 要求过程偏差不受这类限制；条件模拟也支持固定或共享的 map。`hindcast_model()` 要求随时间变化的 `dev_log_R` 和 `dev_log_F` 不受这类限制，但支持固定或共享的静态 `dev_log_N0`。在验证研究中使用这些限制前，见[拟合模型模拟与预测检验](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md)。

For a process-deviation block, supply a factor with one entry per deviation: `NA` fixes that entry at its starting value (zero), and repeated factor levels tie entries to one estimated value. `simulate_fit(process = "resample")` requires unrestricted process deviations; conditional simulation also supports fixed or tied maps. `hindcast_model()` requires unrestricted time-varying `dev_log_R` and `dev_log_F` maps, but supports fixed or tied static `dev_log_N0` values. See [Simulate and validate a fitted model](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md) before using these restrictions in a validation study.

<a id="fitting-controls-starts"></a>

### 4. 设置初值和边界 / Set starting values and bounds

```r
p <- create_parameters(model_type = "acl", species = "flatfish")
p$parameters$log_Linf <- log(65)
p$parameters.U$log_Linf <- log(90)
x$fit_config$acl$parameters <- p$parameters
x$fit_config$acl$parameters.U <- p$parameters.U
inspect_parameters(x, "acl")[, c("parameter", "natural_start", "lower", "upper")]
```

初值和边界在优化器尺度上填写：渐近体长 65 cm 写 `log_Linf = log(65)`，相关系数 0.5 写 `logit_log_R = qlogis(0.5)`。`create_parameters()` 按物种预设（`"flatfish"`、`"tuna"`、`"krill"` 或不指定）返回完整的初值（`parameters`）、下界（`parameters.L`）和上界（`parameters.U`）列表；有信息的项目改掉即可。ACL 直接使用 `t0`，ALSCL 使用 `log_t0`，因此 ALSCL 的 `t0` 必须在 0 和 `rec.age` 之间。超出边界的初值会在拟合前移到最近的边界。[估计参数清单](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting)给出完整列表和变换方式。

Starting values and bounds are entered on the optimizer scale: `log_Linf = log(65)` for an asymptotic length of 65 cm, `logit_log_R = qlogis(0.5)` for a correlation of 0.5. `create_parameters()` returns complete lists of starts (`parameters`), lower bounds (`parameters.L`) and upper bounds (`parameters.U`) for a species preset (`"flatfish"`, `"tuna"`, `"krill"` or none); change the entries you have information about. ACL uses `t0` directly, while ALSCL uses `log_t0`, so an ALSCL `t0` must lie between 0 and `rec.age`. A starting value outside its bounds is moved to the nearest bound before fitting. [Estimation parameter lists](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) gives the full list with transformations.

<a id="fitting-controls-f-structure"></a>

### 5. 选择 F 结构 / Choose the F structure

默认 `F_structure = "group_year"` 时，捕捞死亡率在每个时间步对每个年龄（ACL）或体长组（ALSCL）各有一个值，偏差在时间上以及年龄或体长之间相关。`F_structure = "year"` 时，每个时间步所有年龄或体长共用一个 F，季度数据就是每季度一个值。渔业对各体长作用相同，或数据无法确定年龄别或体长别 F（表现为组间相关估计到接近 1，或 Hessian 不正定）时，选 `"year"`。

With the default `F_structure = "group_year"`, fishing mortality has one value for every age (ACL) or length bin (ALSCL) in every time step, with deviations correlated across time and across ages or lengths. With `F_structure = "year"`, all ages or lengths share one F in each time step: one value per quarter for quarterly data. Choose `"year"` when the fishery acts on all sizes alike, or when age- or length-specific F is undetermined by the data, which shows as a correlation across groups estimated near 1 or a Hessian that is not positive definite.

```r
a_year <- run_acl(x, F_structure = "year", silent = TRUE)
diagnose_model(x$data.CatL, a_year)
plot_fishing_mortality(a_year, se = TRUE)
plot_deviance(a_year, type = "F", se = TRUE)
```

选 `"year"` 后，组间相关参数（`logit_log_F_a` 或 `logit_log_F_l`）被排除在拟合之外；`report$dev_log_F` 只有一行，`report$F` 保持年龄（或体长）乘时间的形状，各行相同。同一输入列表之后的每项分析（包括回溯）都要用同一种结构。

With `"year"` the correlation across groups (`logit_log_F_a` or `logit_log_F_l`) is unused and left out of the fit, `report$dev_log_F` has one row, and `report$F` keeps its age (or length) by time shape with identical rows. Use the same structure in every later analysis of the same bundle, including retrospectives.

<a id="fitting-controls-optimizer"></a>

### 6. 控制优化器 / Control the optimizer

```r
a4 <- run_acl(x, nstarts = 4, ncores = 2, silent = TRUE)
a4$start_diagnostics
a4$refinement$status
```

`nstarts` 运行多个独立初值：第一个使用给定的初值，之后的初值由确定性扰动得到，最终保留目标函数值最低的拟合。`start_diagnostics` 列出每个初值的目标函数值和收敛码；不同初值停在不同的目标函数值，说明目标函数面有多个极小值，最佳的那个值得进一步检查。`ncores` 设定同时运行初值的工作进程数（`nstarts` 默认等于 `ncores`，比较耗时时两者都要设定）。`train_times` 从每个初值的终点再次运行优化器；`polish = TRUE` 对最佳初值做最多五步 Newton 收尾，只在梯度减小且 Hessian 保持正定时接受，`a4$refinement` 记录结果。`control = list(iter.max = 3000)` 把限制传给 `nlminb()`。

`nstarts` runs independent starts: the first from the supplied starting values, the later ones from deterministic perturbations of them, and the lowest objective is kept. `start_diagnostics` lists every start with its objective and convergence code; starts that end at different objectives mean the surface has several minima and the best one deserves a closer look. `ncores` sets how many worker processes run the starts at the same time (`nstarts` defaults to `ncores`, so set both when you compare timings). `train_times` repeats the optimizer from each start's end point; `polish = TRUE` finishes the best start with up to five Newton steps that are accepted only when the gradient decreases and the Hessian stays positive definite, and `a4$refinement` records what happened. `control = list(iter.max = 3000)` passes limits to `nlminb()`.

<a id="fitting-controls-record"></a>

### 7. 记录你的选择 / Record your choices

```r
x$fit_args$F_structure <- "year"
x$fit_config$acl$map <- my_map
saveRDS(x, "my_bundle.rds")
a <- run_acl(x, silent = TRUE)
save_assessment(a, "my_acl.rds")
```

所有工作流函数都读取输入列表，因此存入 `x` 的选择会被 `retro_acl(x)`、`fit_scenarios(x, ...)`、`hindcast_model(x)` 和模拟函数一致地使用。`save_assessment()` 把完整配方与拟合结果一起保存，读者可以看到哪些值被固定，并用 `refit_model()` 重新拟合。

Every workflow function reads the bundle, so a choice stored in `x` is applied consistently by `retro_acl(x)`, `fit_scenarios(x, ...)`, `hindcast_model(x)` and the simulation functions. `save_assessment()` keeps the complete recipe with the fit, so a reader can see which values were fixed and refit the model with `refit_model()`.

<a id="fitting-controls-next"></a>

### 下一步 / What next

| 想做什么 / What you want to do | 阅读 / Read |
|---|---|
| 判断拟合并寻找残差规律 / Judge the fit and look for residual patterns | [诊断](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) / [Diagnostics](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) |
| 查看参数和变换的完整列表 / See the full list of parameters and transformations | [估计参数清单](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) / [Estimation parameter lists](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) |
| 检验固定值对结果的影响 / Test how fixed values change the answer | [评估工作流](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ASSESSMENT_WORKFLOWS.md) / [Assessment workflows](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ASSESSMENT_WORKFLOWS.md) |
| 让拟合更快 / Make fits faster | [速度设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/SPEED_GUIDE.md) / [Speed settings](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/SPEED_GUIDE.md) |

<a id="estimation-parameters"></a>
### 估计参数列表 / Estimation parameter lists

本页列出两个模型的全部标量参数、它们到自然尺度的变换，以及一个预设的初值和边界。表中的键名就是 `parameters`、`parameters.L` 和 `parameters.U` 的条目名，都在优化尺度上填写。

On this page you see every scalar parameter of both models, its transformation to the natural scale, and the starts and bounds of a preset. The keys are the entries of `parameters`, `parameters.L` and `parameters.U`, on the optimizer scale.

| ACL 键名 / ACL key | ALSCL 键名 / ALSCL key | 变换 / Transform to natural scale | 含义 / Meaning |
|---|---|---|---|
| `log_init_Z` | `log_init_Z` | exp | 初始平衡总死亡率 / Initial equilibrium total mortality |
| `log_std_log_N0` | `log_sigma_log_N0` | exp | 初始年龄尾数偏差 SD / Initial log-number deviation SD |
| `mean_log_R` | `mean_log_R` | exp | 对数补充过程的位置参数 / Location of the log recruitment process |
| `log_std_log_R` | `log_sigma_log_R` | exp | 对数补充过程 SD 缩放 / Log recruitment process SD scale |
| `logit_log_R` | `logit_log_R` | plogis | 补充 AR(1) 相关，限定 (0,1) / Recruitment correlation restricted to (0,1) |
| `mean_log_F` | `mean_log_F` | exp | 对数 F 过程的位置参数 / Location of the log F process |
| `log_std_log_F` | `log_sigma_log_F` | exp | F 偏差 SD 缩放 / F deviation SD scale |
| `logit_log_F_y` | `logit_log_F_y` | plogis | F 的时间相关 / Temporal F correlation |
| `logit_log_F_a` | `logit_log_F_l` | plogis | F 的年龄/体长相关 / Age/length F correlation |
| `log_vbk` | `log_vbk` | exp | VB k，单位为每年 / Annual VB k |
| `log_Linf` | `log_Linf` | exp | 渐近体长 / Asymptotic length |
| `t0` | `log_t0` | ACL 原值；ALSCL exp / Identity (ACL); exp (ALSCL) | VB t0；ALSCL 限定为正值 / VB t0; ALSCL restricts it to positive values |
| `log_cv_len` | `log_cv_len` | exp | 年龄体长 CV / Length-at-age CV |
| 无 / none | `log_cv_grow` | exp | 增长增量 CV / Growth-increment CV |
| `log_std_index` | `log_sigma_index` | exp | 对数调查观测 SD / Log survey observation SD |

<a id="estimation-parameters-inspect"></a>

#### 1. 查看一个预设 / Inspect a preset

```r
p <- create_parameters(model_type = "alscl", species = "flatfish")
keys <- names(p$parameters)
parameter_table <- data.frame(
  Parameter = keys,
  Start = unlist(p$parameters[keys]),
  Lower = unlist(p$parameters.L[keys]),
  Upper = unlist(p$parameters.U[keys]))
parameter_table
p$parameters$log_sigma_index <- log(0.15)
p$parameters.U$log_sigma_index <- log(0.5)
fixed_index <- list(log_sigma_index = factor(NA))
```

`create_parameters()` 返回所选模型和预设的三个列表。改初值或边界后参数仍然自由；只有 `fixed_index` 这样的 `map` 条目才会固定它。随机效应 `dev_log_R`、`dev_log_F` 和 `dev_log_N0` 在上表中没有键名。

`create_parameters()` returns the three lists for the model and preset. A changed start or bound leaves the parameter free; only a `map` entry such as `fixed_index` fixes it. The random effects `dev_log_R`, `dev_log_F` and `dev_log_N0` have no key above.

<a id="estimation-parameters-next"></a>

#### 下一步 / What next

| 想做什么 / What you want to do | 阅读 / Read |
|---|---|
| 在输入列表中固定或释放参数 / Fix or release parameters in the bundle | [选择拟合设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) / [Choose the fitting settings](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) |
| 在完整脚本中查看默认固定项和解除方法 / See the default fixes and releases in a complete script | [如何拟合自己的调查数据？](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md) / [How do I fit my own survey data?](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md) |

---

[← 上一章 · Previous](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/05-Simulation) · [目录 · Contents](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [下一章 · Next →](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/07-Diagnostics)
