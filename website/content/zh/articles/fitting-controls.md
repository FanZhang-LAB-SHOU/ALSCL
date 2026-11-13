# 选择拟合设置

本页帮你决定模型估计哪些参数、固定哪些参数、捕捞死亡率采用什么结构，以及优化器如何运行。你需要一个输入列表 `x`（[准备调查数据](data-preparation.html)），并且最好已读过[理解第一次拟合](first-model.html)，其中的检查会告诉你哪项设置需要调整。

设置分三组：`x$fit_args` 中的生物学和数据设置，见[准备调查数据](data-preparation.html)；模型配置（初值、边界、`map`、F 结构），ACL 和 ALSCL 分别设置；优化器设置（初值个数、工作进程、优化轮数），它们改变求解方式，模型本身保持不变。

<h2 id="settings">1. 了解各项设置及其位置</h2>

| 设置 | 含义 | 放在哪里 |
|---|---|---|
| `rec.age`、`nage`、`M`、`sel_L50`、`sel_L95`、`growth_step`、`len_mid`、`len_border` | 生物学、调查可捕性和时间步 | `x$fit_args`，两个模型共用 |
| `zero_action` | 调查零值按缺失处理（默认 `"missing"`）或终止拟合（`"error"`） | `x$fit_args` |
| `parameters`、`parameters.L`、`parameters.U` | 标量参数在优化器尺度上的初值和边界 | `x$fit_config$acl` 或 `x$fit_config$alscl` |
| `map` | 哪些参数固定在初值、哪些默认固定的参数被释放 | `x$fit_config$acl` 或 `x$fit_config$alscl` |
| `F_structure` | `"group_year"`（默认）：F 随年龄或体长及时间步变化；`"year"`：每个时间步一个 F | `x$fit_args` 或调用 |
| `nstarts`、`ncores` | 独立初值的个数和运行它们的工作进程数 | 调用 |
| `train_times` | 每个初值连续优化的轮数（默认 1） | 调用 |
| `polish` | 对最佳初值做带检查的 Newton 收尾（默认 `TRUE`） | 调用 |
| `control` | `nlminb()` 的控制参数，如 `iter.max` | 调用 |
| `silent`、`output` | 不显示进度信息；把诊断和图写入 `output/` | 调用 |

调用中给出的值只在本次调用中覆盖保存的值。希望之后的每项分析（回溯分析、情景、预测检验）都使用某个选择时，把它存入 `x`，做法见第 7 步。

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

默认情况下，ACL 固定 `log_std_log_F`、`logit_log_F_y`、`logit_log_F_a` 和 `t0`，ALSCL 固定 `log_sigma_log_F` 和 `log_t0`，其余都估计。`YTF_example` 固定得更多，因为它的教学配置以运行快为目标：生长参数（`log_Linf`、`log_vbk`、`t0` 或 `log_t0`、`log_cv_len`，ALSCL 还有 `log_cv_grow`）、F 偏差和初始丰度偏差的标准差，以及全部 AR(1) 相关系数（`logit_log_R`、`logit_log_F_y`，以及 `logit_log_F_a` 或 `logit_log_F_l`）。于是每个模型只估计五个标量参数：`log_init_Z`、`mean_log_R`、`mean_log_F`、补充量偏差的标准差和调查观测标准差。示例的区间以所有这些固定值为条件。你自己的输入列表从默认设置开始。过程偏差 `dev_log_R`、`dev_log_F` 和 `dev_log_N0` 按数据维度生成，作为随机效应估计；第 3 步说明为什么它们的 `map` 应保持默认。`n_free`、`n_fixed` 和 `n_tied` 列给出每个块中被估计的偏差数量。

<h2 id="map">3. 用 map 固定或释放参数</h2>

```r
# 把生长参数固定在初值，并估计 F 在时间上的相关
my_map <- list(log_Linf = factor(NA), log_vbk = factor(NA), logit_log_F_y = NULL)
a_map <- run_acl(x, map = my_map, silent = TRUE)
extract_parameters(a_map)
# 把选择存入输入列表，供之后的分析使用
# 未提供 fit_config 的输入列表没有保存的配置：
# 第一次赋值前先为两个模型各建一项
if (is.null(x$fit_config)) x$fit_config <- list(acl = list(), alscl = list())
x$fit_config$acl$map <- my_map
```

`factor(NA)` 把参数固定在初值；具名 `NULL` 释放一个模型默认固定的参数。调用中或 `x$fit_config` 中给出的 `map` 会整体替换保存的 map，所以每次都要列出全部想固定的项。Hessian 不正定或相关系数接近边界时，先检查梯度、参数尺度、边界、其他初值和剖面。在这些检查支持固定参数，且外部估计或生物学假设能提供合理取值时，再固定该参数；每个固定值的依据都要随评估一起记录。`generate_map()` 把列表与 ACL 默认设置合并，但会丢掉 `NULL` 项，所以释放参数的列表要直接作为 `map` 传入。未提供 `fit_config` 的输入列表没有保存的配置，直接给 `x$fit_config$acl$map` 赋值只会建立 ACL 一项。上面的 `if` 一行先为两个模型各建一项，使保存的配置同时列出两个模型；空项表示使用模型默认设置。

不要把过程偏差块 `dev_log_R`、`dev_log_F` 和 `dev_log_N0` 写进 `map`。模型对每个块的全部偏差计算过程似然。因此，用 `NA` 固定其中一些偏差，或让多个偏差使用同一个因子水平，得到的并不是偏差更少的模型的似然。除非该过程的标准差和 AR(1) 相关系数也都固定，否则这样的 map 会被拒绝。即使固定了，目标函数也不能与其他拟合比较，不要用 AIC 比较。要让所有年龄组或体长组在每个时间步共用一个捕捞死亡率，使用 `F_structure = "year"`（第 5 步），它有自己的一维 AR(1) 似然。`simulate_fit(process = "resample")` 要求过程偏差不受限制，`hindcast_model()` 要求 `dev_log_R` 和 `dev_log_F` 不受限制。见[模拟调查数据并检验预测](case-model-validation.html)。

用具名 `NULL` 释放参数时，从 `inspect_parameters(x, model)` 复制该模型的参数名。名称有误会报错。截取映射因子的子集后，程序会去掉未使用的水平，其余单元保持原来的固定或估计状态。

<h2 id="starts">4. 设置初值和边界</h2>

```r
p <- create_parameters(model_type = "acl", species = "flatfish")
p$parameters$log_Linf <- log(65)
p$parameters.U$log_Linf <- log(90)
if (is.null(x$fit_config)) x$fit_config <- list(acl = list(), alscl = list())
x$fit_config$acl$parameters <- p$parameters
x$fit_config$acl$parameters.U <- p$parameters.U
inspect_parameters(x, "acl")[, c("parameter", "natural_start", "lower", "upper")]
```

初值和边界在优化器尺度上填写：渐近体长 65 cm 写 `log_Linf = log(65)`，相关系数 0.5 写 `logit_log_R = qlogis(0.5)`。`create_parameters()` 按物种预设（`"flatfish"`、`"tuna"`、`"krill"` 或不指定）返回完整的初值（`parameters`）、下界（`parameters.L`）和上界（`parameters.U`）列表；有信息的项目改掉即可。这些预设是取自模拟操作模型的初始配置，不是针对某个种群验证过的设置。例如 `"tuna"` 预设对应模拟研究中的类金枪鱼操作模型 M6：20 个季度年龄组，末组从 5 龄起，渐近体长 152 cm，自然死亡率恒定。ACL 直接使用 `t0`，ALSCL 使用 `log_t0`，因此 ALSCL 的 `t0` 必须在 0 和 `rec.age` 之间。超出边界的初值会在拟合前移到最近的边界。[估计参数清单](estimation-parameters.html)给出完整列表和变换方式。

<h2 id="f-structure">5. 选择 F 结构</h2>

默认 `F_structure = "group_year"` 时，捕捞死亡率在每个时间步对每个年龄（ACL）或体长组（ALSCL）各有一个值，偏差在时间上以及年龄或体长之间相关。`F_structure = "year"` 时，每个时间步所有年龄或体长共用一个 F，季度数据就是每季度一个值。各组 F 相同具有合理依据，或诊断提示数据对组间变化提供的信息较少时，可考虑 `"year"`。组间相关接近 1 或 Hessian 不正定都需要调查，但不能单凭其中一项选择 F 结构。应比较两种结构的拟合、残差和敏感性。

```r
a_year <- run_acl(x, F_structure = "year", silent = TRUE)
diagnose_model(x$data.CatL, a_year)
plot_fishing_mortality(a_year, se = TRUE)
plot_deviance(a_year, type = "F", se = TRUE)
```

选 `"year"` 后，组间相关参数（`logit_log_F_a` 或 `logit_log_F_l`）被排除在拟合之外；`report$dev_log_F` 只有一行，`report$F` 保持年龄（或体长）乘时间的形状，各行相同。同一输入列表之后的每项分析（包括回溯）都要用同一种结构。

<h2 id="optimizer">6. 控制优化器</h2>

```r
a4 <- run_acl(x, nstarts = 4, ncores = 2, silent = TRUE)
a4$start_diagnostics
a4$refinement$status
```

`nstarts` 运行多个独立初值：第一个使用给定的初值，之后的初值由确定性扰动得到，最终保留目标函数值最低的拟合。`start_diagnostics` 列出每个初值的目标函数值和收敛码。如果各次优化的目标函数终值不同，先检查收敛情况，比较终点梯度和参数估计，再判断是否存在多个局部极小值。`ncores` 设定同时运行初值的工作进程数（`nstarts` 默认等于 `ncores`，比较耗时时两者都要设定）。`train_times` 从每个初值的终点再次运行优化器；`polish = TRUE` 对最佳初值做最多五步 Newton 收尾，只在梯度减小且 Hessian 保持正定时接受，`a4$refinement` 记录结果。`control = list(iter.max = 3000)` 把限制传给 `nlminb()`。

如果目标函数值之差不超过 `1e-8`，且每个参数之差不超过 `1e-6 * max(1, abs(p1), abs(p2))`，失败重启不会覆盖实际返回成功的轮次。这些容差只用于识别数值上等价的重复轮次；目标函数有实质改善或参数向量相距较远时，仍选择较低的目标函数值。全部原始退出码和消息保留在 `optimizer_history`，`raw_opt$selected_pass` 指出所保留轮次。最终梯度、Hessian 和边界检查仍独立于优化器退出码。

`nlminb()` 的每个控制项只按名称提供一次，例如 `control = list(iter.max = 3000L)`。预检和拟合都会在优化前校验名称和值。

<h2 id="record">7. 记录你的选择</h2>

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
