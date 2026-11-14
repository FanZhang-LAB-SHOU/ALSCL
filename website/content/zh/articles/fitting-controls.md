# 选择拟合设置

本页帮你决定模型估计哪些参数、固定哪些参数、捕捞死亡率采用什么结构，以及优化器如何运行。你需要一个输入列表 `x`（[准备调查数据](data-preparation.html)），并且最好已读过[理解第一次拟合](first-model.html)，其中的检查会告诉你哪项设置需要调整。

设置分三组：`x$fit_args` 中的生物学和数据设置，见[准备调查数据](data-preparation.html)；模型配置（初值、边界、`map`、F 结构和可选的模型结构），ACL 和 ALSCL 分别设置；优化器设置（初值个数、工作进程、优化轮数），它们改变求解方式，模型本身保持不变。

<h2 id="settings">1. 了解各项设置及其位置</h2>

| 设置 | 含义 | 放在哪里 |
|---|---|---|
| `rec.age`、`nage`、`M`、`sel_L50`、`sel_L95`、`growth_step`、`len_mid`、`len_border` | 生物学、调查可捕性和时间步 | `x$fit_args`，两个模型共用 |
| `zero_action` | 调查零值按缺失处理（默认 `"missing"`）或终止拟合（`"error"`） | `x$fit_args` |
| `parameters`、`parameters.L`、`parameters.U` | 标量参数在优化器尺度上的初值和边界 | `x$fit_config$acl` 或 `x$fit_config$alscl` |
| `map` | 哪些参数固定在初值、哪些默认固定的参数被释放 | `x$fit_config$acl` 或 `x$fit_config$alscl` |
| `F_structure` | `"group_year"`（默认）：F 随年龄或体长及时间步变化；`"year"`：每个时间步一个 F | `x$fit_args` 或调用 |
| `structure` | 可选的模型结构，包括 AR(1) 相关系数的取值范围；默认是原始结构，即本包最初发布时的结构 | `x$fit_config$acl` 或 `x$fit_config$alscl`，或调用 |
| `t0_lower` | ALSCL 生长参数 `t0` 的下限，单位为年（默认 0）；取负值时允许 `t0` 为负 | `x$fit_config$alscl`，或 `run_alscl()` 的调用 |
| `nstarts`、`ncores` | 独立初值的个数和运行它们的工作进程数 | 调用 |
| `start_spread` | 第二个及之后的初值围绕第一个初值的离散程度（默认 0.15） | 调用 |
| `train_times` | 每个初值连续优化的轮数（默认 1） | 调用 |
| `polish` | 对最佳初值做带检查的 Newton 收尾（默认 `TRUE`） | 调用 |
| `control` | `nlminb()` 的控制参数，如 `iter.max` | 调用 |
| `silent`、`output` | 不显示进度信息；把诊断和图写入 `output/` | 调用 |

调用中给出的值只在本次调用中覆盖保存的值。希望之后的每项分析（回溯分析、情景、预测检验）都使用某个选择时，把它存入 `x`，做法见第 8 步。

<h2 id="parameters">2. 查看哪些参数会被估计</h2>

```r
plan <- inspect_parameters(x, "acl")
plan[, c("parameter", "kind", "status", "map_source", "natural_start")]
inspect_parameters(x, "alscl")[, c("parameter", "status", "natural_start")]
```

`inspect_parameters()` 列出所选模型的标量参数和过程偏差块、初值及状态，例如 `free`（估计）、`fixed`（固定）或 `tied`（共享）。`map_source` 说明固定状态来自模型默认还是你的 `map`。下面每做一次修改都可以再运行它；它只读取输入列表，既不编译也不拟合。

| 含义 | ACL 参数 | ALSCL 参数 |
|---|---|---|
| 生长（von Bertalanffy） | `log_Linf`、`log_vbk`、`t0` | `log_Linf`、`log_vbk`、`log_t0` |
| 年龄别体长的离散程度；生长增量 CV | `log_cv_len` | `log_cv_len`、`log_cv_grow` |
| 平均补充量和平均 F（对数尺度） | `mean_log_R`、`mean_log_F` | `mean_log_R`、`mean_log_F` |
| 过程偏差的标准差 | `log_std_log_R`、`log_std_log_F`、`log_std_log_N0` | `log_sigma_log_R`、`log_sigma_log_F`、`log_sigma_log_N0` |
| F 在时间上的相关；在年龄或体长上的相关 | `logit_log_F_y`、`logit_log_F_a` | `logit_log_F_y`、`logit_log_F_l` |
| 补充量在时间上的相关 | `logit_log_R` | `logit_log_R` |
| 初始总死亡率；调查观测 SD | `log_init_Z`、`log_std_index` | `log_init_Z`、`log_sigma_index` |

默认情况下，ACL 固定 `log_std_log_F`、`logit_log_F_y`、`logit_log_F_a` 和 `t0`，ALSCL 固定 `log_sigma_log_F` 和 `log_t0`，其余都估计。`YTF_example` 固定得更多，因为它的教学配置以运行快为目标：生长参数（`log_Linf`、`log_vbk`、`t0` 或 `log_t0`、`log_cv_len`，ALSCL 还有 `log_cv_grow`）、F 偏差的标准差（0.302，即生成数据的 AR(1) 过程的边际标准差 `F_sd / sqrt(1 - F_ar^2)`）、初始丰度偏差的标准差，以及全部 AR(1) 相关系数（`logit_log_R`、`logit_log_F_y`，以及 `logit_log_F_a` 或 `logit_log_F_l`）。于是每个模型只估计五个标量参数：`log_init_Z`、`mean_log_R`、`mean_log_F`、补充量偏差的标准差和调查观测标准差。示例的区间以所有这些固定值为条件。你自己的输入列表从默认设置开始。过程偏差 `dev_log_R`、`dev_log_F` 和 `dev_log_N0` 按数据维度生成，作为随机效应估计；第 3 步说明为什么它们的 `map` 应保持默认。`n_free`、`n_fixed` 和 `n_tied` 列给出每个块中被估计的偏差数量。

<h2 id="map">3. 用 map 固定或释放参数</h2>

```r
# 把生长参数固定在初值，并估计 F 在时间上的相关
my_map <- list(log_Linf = factor(NA), log_vbk = factor(NA), logit_log_F_y = NULL)
a_map <- run_acl(x, map = my_map, silent = TRUE)
extract_parameters(a_map)
# 把选择存入输入列表，供之后的分析使用
x$fit_config$acl$map <- my_map
```

`factor(NA)` 把参数固定在初值；具名 `NULL` 释放一个模型默认固定的参数。调用中或 `x$fit_config` 中给出的 `map` 会整体替换保存的 map，所以每次都要列出全部想固定的项。Hessian 不正定或相关系数接近边界时，先检查梯度、参数尺度、边界、其他初值和剖面。在这些检查支持固定参数，且外部估计或生物学假设能提供合理取值时，再固定该参数；每个固定值的依据都要随评估一起记录。`generate_map()` 把列表与 ACL 默认设置合并，但会丢掉 `NULL` 项，所以释放参数的列表要直接作为 `map` 传入。输入列表没有保存的配置时，这次赋值会建立 `x$fit_config$acl`。`x$fit_config` 中没有条目的模型使用共用的 `x$fit_args` 和模型默认设置，所以只为 ACL 保存了配置的输入列表仍然可以用 ALSCL 拟合。

不要把过程偏差块 `dev_log_R`、`dev_log_F` 和 `dev_log_N0` 写进 `map`。模型对每个块的全部偏差计算过程似然。因此，用 `NA` 固定其中一些偏差，或让多个偏差使用同一个因子水平，得到的并不是偏差更少的模型的似然。除非该过程的标准差和 AR(1) 相关系数也都固定，否则这样的 map 会被拒绝，因为这些参数的估计会有偏。即使固定了，目标函数也不能与对这些偏差使用其他 map 的拟合比较，不要用 AIC 比较；拟合结果在 `restricted_random` 中列出涉及的偏差块。要让所有年龄组或体长组在每个时间步共用一个捕捞死亡率，使用 `F_structure = "year"`（第 5 步），它有自己的一维 AR(1) 似然。`simulate_fit(process = "resample")` 要求过程偏差不受限制，`hindcast_model()` 要求 `dev_log_R` 和 `dev_log_F` 不受限制。见[模拟调查数据并检验预测](case-model-validation.html)。

用具名 `NULL` 释放参数时，从 `inspect_parameters(x, model)` 复制该模型的参数名。名称有误会报错。截取映射因子的子集后，程序会去掉未使用的水平，其余单元保持原来的固定或估计状态。

<h2 id="starts">4. 设置初值和边界</h2>

```r
p <- create_parameters(model_type = "acl", species = "flatfish")
p$parameters$log_Linf <- log(65)
p$parameters.U$log_Linf <- log(90)
x$fit_config$acl$parameters <- p$parameters
x$fit_config$acl$parameters.U <- p$parameters.U
inspect_parameters(x, "acl")[, c("parameter", "natural_start", "lower", "upper")]
```

初值和边界在优化器尺度上填写：渐近体长 65 cm 写 `log_Linf = log(65)`，相关系数 0.5 写 `logit_log_R = qlogis(0.5)`（相关系数取默认范围时；取值在 -1 和 1 之间时的写法见第 6 步）。`create_parameters()` 按物种预设（`"flatfish"`、`"tuna"`、`"krill"` 或不指定）返回完整的初值（`parameters`）、下界（`parameters.L`）和上界（`parameters.U`）列表；有信息的项目改掉即可。这些预设是取自模拟操作模型的初始配置，不是针对某个种群验证过的设置。例如 `"tuna"` 预设对应模拟研究中的类金枪鱼操作模型 M6：20 个季度年龄组，末组从 5 龄起，渐近体长 152 cm，自然死亡率恒定。ACL 直接使用 `t0`，ALSCL 使用 `log_t0`，`t0 = t0_lower + exp(log_t0)`，因此默认 `t0_lower = 0` 时 ALSCL 的 `t0` 必须在 0 和 `rec.age` 之间；允许 `t0` 为负的做法见第 6 步。超出边界的初值会在拟合前移到最近的边界：你给定的初值给出警告，默认初值给出提示，拟合结果在 `clamped_starts` 中列出这些初值。ACL 中 `Linf` 的默认值（初值 60，边界 10 到 100）采用黄尾鲽示例的体长单位。默认值不适合你的体长组时（例如以 cm 计的金枪鱼体长），`run_acl()` 按数据设置你没有给定的初值和边界。初值是这样一个体长的 1.1 倍：调查指数合计值的 99% 位于该体长以下。上界为最大体长组中点的 2 倍。下界取默认值（10）与该 99% 体长的一半两者中较小的一个，因此体长组延伸到最大个体以上时，真实的 `Linf` 不会被排除在外。`run_alscl()` 对你没有给定的值总是按数据设置：初值为最大体长组中点的 1.1 倍，边界为该中点的 0.7 倍和 2 倍，所以体长组远超最大个体时请给出 `parameters.L$log_Linf`。[估计参数清单](estimation-parameters.html)给出完整列表和变换方式。

<h2 id="f-structure">5. 选择 F 结构</h2>

默认 `F_structure = "group_year"` 时，捕捞死亡率在每个时间步对每个年龄（ACL）或体长组（ALSCL）各有一个值，偏差在时间上以及年龄或体长之间相关。`F_structure = "year"` 时，每个时间步所有年龄或体长共用一个 F，季度数据就是每季度一个值。各组 F 相同具有合理依据，或诊断提示数据对组间变化提供的信息较少时，可考虑 `"year"`。组间相关接近 1 或 Hessian 不正定都需要调查，但不能单凭其中一项选择 F 结构。应比较两种结构的拟合、残差和敏感性。

```r
a_year <- run_acl(x, F_structure = "year", silent = TRUE)
diagnose_model(x$data.CatL, a_year)
plot_fishing_mortality(a_year, se = TRUE)
plot_deviance(a_year, type = "F", se = TRUE)
```

选 `"year"` 后，组间相关参数（`logit_log_F_a` 或 `logit_log_F_l`）被排除在拟合之外；`report$dev_log_F` 只有一行，`report$F` 保持年龄（或体长）乘时间的形状，各行相同。同一输入列表之后的每项分析（包括回溯）都要用同一种结构。

<h2 id="structure">6. 选择可选的模型结构</h2>

```r
b_structure <- run_alscl(x, structure = "von_bertalanffy", silent = TRUE)
b_structure$structure
b_structure$growth_check$stalled
a_structure <- run_acl(x, structure = list(initial_plus_group = "equilibrium"),
                       silent = TRUE)
a_structure$structure
```

`structure` 参数选择可选的模型结构。默认值（空列表）是原始结构，即本包最初发布时的结构，它实现了 Zhang 和 Cadigan (2022) 的模型。所以不带 `structure` 的调用拟合的模型与以前相同。原始结构的生长增量有两处细节只在代码里，论文没有给出。论文定义了下表中的 logistic 函数，但没有给出增量等于最大值 50% 和 95% 时的体长（代码取 0.5 `Linf` 和 0.05 `Linf`），也没有说明增量怎样换算到短于一年的时间步（代码把它乘以 `growth_step`）。`structure = "von_bertalanffy"` 同时选用表中前四项设置，使第一个时间步和生长转移遵循同一个生长模型；`structure = "original"` 即默认结构。命名列表可以选择单项设置，也可以先指定一组设置再追加，例如 `list(set = "von_bertalanffy", correlation_range = "symmetric")`。`"published"` 和 `"consistent"` 是 `"original"` 和 `"von_bertalanffy"` 以前的名称，仍然可以使用。ACL 有表中的第一项和最后一项设置，ALSCL 五项都有。

| 设置 | 原始结构（默认） | 可选的结构 |
|---|---|---|
| `initial_plus_group`（ACL 和 ALSCL） | `"single_cohort"`：第一个时间步的末组（plus group）只含一个世代 | `"equilibrium"`：末组等于在初始总死亡率 `init_Z` 下所有更老世代之和 |
| `initial_length`（ALSCL） | `"length_at_age"`：第一个时间步每个年龄都采用变异系数为 `cv_len` 的年龄别体长分布 | `"growth"`：第一个年龄采用该分布，其后每个年龄由前一年龄按 `init_Z` 存活并生长一步得到，与之后各时间步相同 |
| `growth_increment`（ALSCL） | `"logistic"`：期望生长增量是体长的递减 logistic 函数，再乘以 `growth_step` | `"von_bertalanffy"`：体长 `L` 低于 `Linf` 时，一个时间步的期望增量为 `(Linf - L) * (1 - exp(-vbk * growth_step))`，高于 `Linf` 时平滑降到零，因此 `Linf` 和 `vbk` 的含义与年龄别体长曲线中相同。这时个体长到 `Linf` 附近就停止生长，`Linf` 在第一个时间步之后相当于体长的上限：数据中有许多个体大于平均渐近体长时拟合较差，`Linf` 的标准误可能非常小。logistic 增量在 `Linf` 以上仍为正 |
| `growth_transition`（ALSCL） | `"midpoint"`：体长组内所有个体都从组中点开始生长 | `"bin"`：起始体长在组内均匀分布，转移概率在整个体长组上积分，因此每个时间步的生长增量相对组宽较小时，个体仍会进入下一个体长组 |
| `correlation_range`（ACL 和 ALSCL） | `"positive"`：补充量和 F 的 AR(1) 相关系数在 0 和 1 之间，是 `logit_*` 参数的 logistic 变换 | `"symmetric"`：相关系数在 -1 和 1 之间，等于 logistic 变换的 2 倍减 1，因此相关系数为零不在边界上，也可以估计负相关 |

有两对设置具有原始结构所没有的性质。`initial_length = "growth"` 与 `initial_plus_group = "equilibrium"` 同时使用时，补充量恒定、没有捕捞且 `init_Z` 等于 `M` 的种群保持不变。`growth_increment = "von_bertalanffy"` 与 `growth_transition = "bin"` 同时使用时，组宽为每个时间步生长增量的几倍时，世代的平均体长与 von Bertalanffy 曲线接近。组宽大得多时仍是近似，因为每个时间步之后个体都在所在体长组内均匀分布。在原始结构下，每个时间步的增量相对组宽较小时（例如季度时间步配较宽的体长组），平均体长明显低于该曲线。举一个例子：一个世代从最接近 40 cm 的体长组开始，时间步为季度，`Linf` 为 152 cm，`vbk` 为每年 0.38，生长增量的变异系数为 0.3。10 年后 von Bertalanffy 曲线给出 149.5 cm。使用 `"von_bertalanffy"` 和 `"bin"` 时，组宽 1 cm 的平均体长为 149.6 cm，组宽 5 cm 为 148.3 cm，组宽 10 cm 为 146.6 cm。在原始结构下，组宽 1 cm 为 143.0 cm，组宽 5 cm 为 121.7 cm，组宽 10 cm 为 105.3 cm。

`"von_bertalanffy"` 的四项设置要一起使用。`growth_transition = "midpoint"` 时，在每个时间步的生长增量远小于半个组宽的体长处，个体不再生长，与 `Linf` 的取值无关。在季度时间步、组宽 5 cm 的模拟检验中（`Linf` 为 152 cm），原始结构下的生长在 113 到 120 cm 之间停止。这时只用两项初始状态设置或只用两项生长设置的拟合，要么不能通过数值检查，要么对捕捞死亡率的估计有很大偏差，因为第一个时间步与之后各时间步遵循不同的生长模型。`"von_bertalanffy"` 既是这组设置的名称，也是单项设置 `growth_increment` 的一个取值：`structure = list(growth_increment = "von_bertalanffy")` 只改一项，`structure = "von_bertalanffy"` 四项都改。ALSCL 拟合的 `structure` 列表只改了四项中的一项、两项或三项时，拟合会给出一条提示，列出仍为原始取值的设置（`silent = TRUE` 时不显示；`fit_scenarios()`、`hindcast_model()` 和 `retro_model()` 每次调用只提示一次）。先指定这组设置再替换其中一项的列表，例如 `list(set = "von_bertalanffy", growth_transition = "midpoint")`，视为有意的选择，不给提示。拟合得到的转移矩阵中，如果有中点低于 `Linf` 估计值 90% 的体长组，且个体每个时间步留在该组的概率不低于 0.99，`run_alscl()` 会给出提示（`silent = TRUE` 时不显示），`summary()` 会显示这条提示，拟合结果中的 `growth_check` 保存这项检查的结果。原始结构与 `"von_bertalanffy"` 这组设置的参数个数相同，可以两种各拟合一次并比较目标函数值。

`b_structure$structure` 和 `a_structure$structure` 列出每项设置实际采用的取值，保存的拟合结果也保留它们。采用可选结构的拟合是另一个模型，选用之前先把它的数值检查、残差和估计值与默认拟合比较（[诊断](diagnostics.html)）。如果 `run_acl()` 因某项设置“applies to ALSCL only”而停止，请从 ACL 的调用中去掉生长和初始体长的设置：ACL 没有生长转移矩阵。把选择存在所属模型之下，例如 `x$fit_config$alscl$structure`，这样该输入列表之后的拟合（包括回溯分析的每一轮）都会使用它。要用同样的结构模拟数据，见[模拟调查数据](simulation.html#generate)。

<h3 id="correlation-range">允许 AR(1) 相关系数为负</h3>

```r
# 从 YTF_example 保存的配置开始
cfg <- YTF_example$fit_config$acl
cfg$parameters$logit_log_R <- qlogis((0.1 + 1) / 2)  # 相关系数 0.1
cfg$map$logit_log_R <- NULL                          # 估计补充量的相关系数
a_sym <- run_acl(YTF_example, parameters = cfg$parameters, map = cfg$map,
                 structure = list(correlation_range = "symmetric"), silent = TRUE)
a_sym$structure$correlation_range
subset(extract_parameters(a_sym), parameter == "logit_log_R")
```

默认 `correlation_range = "positive"` 时，每个 AR(1) 相关系数（补充量在时间上的相关；F 在时间上以及在年龄或体长之间的相关）都在 0 和 1 之间，因为相关系数是对应 `logit_*` 参数的 logistic 变换。如果某个种群的补充量偏差没有自相关或呈负自相关，估计值会落到下限，拟合报告自然尺度边界，无法通过数值检查。`correlation_range = "symmetric"` 时，相关系数在 -1 和 1 之间。此时相关系数为零对应 `logit_*` 等于 0，不在边界上；负相关可以估计；数值检查只在相关系数接近 -1 或 1 时给出标记。上面的代码估计示例数据的补充量相关系数：估计值为 0.18，标准误为 0.23，95% 区间为 -0.27 到 0.57，包含零和负值。

`logit_*` 的初值或固定值在两种设置下含义不同：相关系数 `rho` 在 `"positive"` 下写 `qlogis(rho)`，在 `"symmetric"` 下写 `qlogis((rho + 1) / 2)`。你自己给出的每个 `logit_*` 值都要换算，如代码中设置 `logit_log_R` 的那一行所示。没有给出的初值在两种设置下保持原来的自然尺度取值；本例中 F 的两个相关系数仍固定在 0.75。`inspect_parameters()`、`extract_parameters()`、`profile_model()` 和 `simulate_fit()` 使用输入列表或拟合结果的变换，因此它们在自然尺度上显示或接受的值在两种设置下都是相关系数。把这项选择和换算后的值一起保存，例如存入 `x$fit_config$acl$structure` 和 `x$fit_config$acl$parameters`，这样该输入列表之后的拟合会同时使用两者。

<h3 id="t0-lower">在 ALSCL 中允许 t0 为负</h3>

```r
x_t0 <- YTF_example
x_t0$fit_config$alscl$t0_lower <- -1
x_t0$fit_config$alscl$parameters$log_t0 <- log(-0.2 + 1)  # t0 = -0.2 年
plan_t0 <- inspect_parameters(x_t0, "alscl")
plan_t0[plan_t0$parameter == "log_t0", c("parameter", "natural_start", "transform", "status")]
b_t0 <- run_alscl(x_t0, silent = TRUE)
subset(extract_parameters(b_t0), parameter == "log_t0")
b_t0$t0_lower
```

ALSCL 在对数尺度上保存 von Bertalanffy 参数 `t0`：`t0 = t0_lower + exp(log_t0)`。默认 `t0_lower = 0` 是原始的参数化，此时 `t0` 为正。种群的 `t0` 为负时，把 `t0_lower` 设为低于你所考虑的最小 `t0` 的值，例如 -1，并把 `t0` 写成 `log_t0 = log(t0 - t0_lower)`：上面的代码用 `log(-0.2 + 1)` 把 `t0` 固定在 -0.2 年。`t0_lower` 必须小于补充年龄，`t0` 本身也始终小于补充年龄。`inspect_parameters()` 显示自然尺度上的初值 -0.2 和变换 `t0_lower+exp`。`extract_parameters()`、`plot_VB()`、`profile_model()` 和 `b_t0$report$t0` 给出或接受的 `t0` 都以年为单位，拟合结果把下限保存在 `b_t0$t0_lower` 中。要估计 `t0` 而不是固定它，在 `map` 中用具名 `NULL` 释放（第 3 步）。

-0.2 这个值只用来说明参数的用法。`YTF_example` 是用 1/60 年的 `t0` 生成的，所以这次拟合的目标函数值高于默认拟合。ACL 不需要这个参数：它的 `t0` 在自然尺度上，可以为负，`run_acl()` 不接受 `t0_lower`。请按上面的代码把 `t0_lower` 存在 `x$fit_config$alscl` 之下，不要存入两个模型都读取的 `x$fit_args`；这样该输入列表之后的 ALSCL 拟合（包括回溯分析的每一轮）都会使用它。`retro_alscl()` 和 `retro_model()` 也可以在调用中给出 `t0_lower`。

<h2 id="optimizer">7. 控制优化器</h2>

```r
a4 <- run_acl(x, nstarts = 4, ncores = 2, silent = TRUE)
a4$start_diagnostics
a4$start_summary
a4$refinement$status
# 用于报告的结果：增加初值个数，并加大初值的离散程度
a5 <- run_acl(x, nstarts = 5, start_spread = 0.5, ncores = 2, silent = TRUE)
a5$start_summary
```

`nstarts` 运行多个独立初值：第一个使用给定的初值，之后的初值由确定性扰动得到，最终保留目标函数值最低的拟合。扰动是优化器尺度上标准差为 `start_spread`（默认 0.15）的正态偏差。`start_diagnostics` 列出每个初值的目标函数值和收敛码，`start_summary` 给出收敛的初值个数、它们目标函数值的范围以及与最优值一致的个数；范围超过 2 时写入 `diagnostics$issues`。如果各次优化的目标函数终值不同，先检查收敛情况，比较终点梯度和参数估计，再判断是否存在多个局部极小值。`ncores` 设定同时运行初值的工作进程数（`nstarts` 默认等于 `ncores`，比较耗时时两者都要设定）。`train_times` 从每个初值的终点再次运行优化器；`polish = TRUE` 对最佳初值做最多五步 Newton 收尾，只在梯度减小且 Hessian 保持正定时接受，`a4$refinement` 记录结果。`control = list(iter.max = 3000)` 把限制传给 `nlminb()`。

单个初值可能停在通过全部数值检查的局部最优，ALSCL 的生长参数尤其如此。数值检查只针对所得到的解，不能说明是否存在更好的解。用于报告的结果请使用多个初值（例如 `nstarts = 5`）和更大的 `start_spread`（例如 0.5），如代码块最后两行所示，并比较 `start_diagnostics` 中的目标函数值。

如果目标函数值之差不超过 `1e-8`，且每个参数之差不超过 `1e-6 * max(1, abs(p1), abs(p2))`，失败重启不会覆盖实际返回成功的轮次。这些容差只用于识别数值上等价的重复轮次；目标函数有实质改善或参数向量相距较远时，仍选择较低的目标函数值。全部原始退出码和消息保留在 `optimizer_history`，`raw_opt$selected_pass` 指出所保留轮次。最终梯度、Hessian 和边界检查仍独立于优化器退出码。

`nlminb()` 的每个控制项只按名称提供一次，例如 `control = list(iter.max = 3000L)`。预检和拟合都会在优化前校验名称和值。

<h2 id="record">8. 记录你的选择</h2>

```r
x$fit_args$F_structure <- "year"
x$fit_config$acl$map <- my_map
saveRDS(x, "my_bundle.rds")
a <- run_acl(x, silent = TRUE)
save_assessment(a, "my_acl.rds")
```

所有工作流函数都读取输入列表，因此存入 `x` 的选择会被 `retro_acl(x)`、`fit_scenarios(x, ...)`、`hindcast_model(x)` 和模拟函数一致地使用。`save_assessment()` 同时保存拟合结果及重新拟合所需的输入和设置，读者可以看到哪些值被固定，并用 `refit_model()` 重新拟合。

<h2 id="next">下一步</h2>

| 想做什么 | 阅读 |
|---|---|
| 判断拟合并寻找残差规律 | [诊断](diagnostics.html) |
| 查看参数和变换的完整列表 | [估计参数清单](estimation-parameters.html) |
| 检验固定值对结果的影响 | [评估工作流](assessment-workflows.html) |
| 让拟合更快 | [速度设置](speed.html) |
