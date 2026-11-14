# 判断拟合是否可用

本页从四个方面检查一次拟合：优化器的数值检查、残差规律、与其他设置的比较，以及对固定值的敏感性。你需要[理解第一次拟合](first-model.html)中的对象：输入列表 `x`、ACL 拟合 `a` 和 ALSCL 拟合 `b`。代码以 `b` 为例，对 `a` 用法相同。

<h2 id="numerical">1. 数值检查</h2>

```r
diagnose_model(x$data.CatL, b)
b$diagnostics$issues
b$diagnostics$high_correlations
b$refinement$status
b$start_diagnostics
```

`diagnose_model()` 打印优化器原始收敛码、最大绝对梯度、Hessian 和协方差状态，以及参数边界检查。数值筛查使用 0.001 的梯度阈值、Hessian 和协方差矩阵的正定性、边界检查，以及对实际上已到极限的参数的检查（见下一小节）；优化器原始收敛码另行报告。`b$diagnostics$issues` 列出全部诊断提示。`high_correlations` 列出估计相关系数绝对值至少为 0.95 的参数对，包括负相关；应结合剖面、其他初值或敏感性分析检查这些参数的可辨识性。`b$refinement` 记录收尾的 Newton 步（满足梯度准则时 `status = "gradient_tolerance"`），`b$start_diagnostics` 记录每个初值的目标函数值。

检查未通过时，每次只改一处：增加初值（`nstarts = 4`），检查参数尺度和边界，并用剖面调查难以确定的参数。有依据时再固定某个参数，或让各组共用 F（`F_structure = "year"`），方法见[拟合设置](fitting-controls.html)。在第 3 步比较修改后的拟合与原拟合。通过数值筛查不能确认唯一解、全局最优解、参数可辨识性或模型适用性。单个初值可能停在通过全部检查的局部最优，所以用于报告的结果请运行多个初值并加大 `start_spread`，再读 `b$start_summary`（[选择拟合设置](fitting-controls.html#optimizer)）。[Carvalho 等（2021）第 2.1 节](https://repository.library.noaa.gov/view/noaa/32687/noaa_32687_DS1.pdf)解释了为何需要结合多项诊断。

<h3 id="limits">已到极限的参数、处理建议和合理性提示</h3>

```r
# 未通过检查的拟合：放开 F 在年龄间的相关系数，它的估计值走到 1
cfg <- x$fit_config$acl
cfg$map["logit_log_F_a"] <- list(NULL)
a_limit <- run_acl(x, map = cfg$map, silent = TRUE)
a_limit$diagnostics$numerical_ok
a_limit$diagnostics$limit_parameters[, c("parameter", "estimate", "natural")]
a_limit$diagnostics$advice
# 通过检查但带有提示的拟合：M 设得高于初始总死亡率
a_note <- run_acl(x, M = 0.5, silent = TRUE)
a_note$diagnostics$numerical_ok
a_note$diagnostics$plausibility[, c("check", "parameter", "value", "threshold")]
a_note$diagnostics$plausibility$note
a_note$diagnostics$check_thresholds
```

参数可以在没有碰到优化器边界的情况下到达极限：它在优化器尺度上走得很远，自然尺度上的值已等于极限值。数值筛查判这样的拟合不通过，与停在边界上的拟合一样。检查三种情形。`log_t0` 低于 -10（ALSCL）表示 `t0` 等于下限 `t0_lower`。标准差的对数低于 -9 表示方差被估计为零。logit 相关系数的绝对值大于 15 表示相关系数落在取值范围的端点。`diagnostics$limit_parameters` 列出这些参数的估计值和自然尺度上的值，`diagnostics$issues` 中也会点名。代码块的第一次拟合中，F 在年龄间的相关系数在 logit 尺度上估计为 19.1，即相关系数为 1，`numerical_ok` 为 `FALSE`。R 还会警告产生了 NaN，因为这次拟合的协方差矩阵不正定。

`diagnostics$advice` 给出处理建议，拟合的提示信息、`print()` 和 `summary()` 都会显示它。参数估计在边界上，说明数据或模型结构可能有问题；检查收敛时，第一步就是找出这样的参数（[Carvalho 等 2021](https://doi.org/10.1016/j.fishres.2021.105959)）。实际上已到极限的参数属于同一种情形，只是没有碰到边界。方差被估计为零不应解释为该过程没有变异；通常的做法是固定或去掉这个参数。所以建议是：用 `map` 把该参数固定在有依据的值上，然后重新拟合。有两种情形另有办法：相关系数为零时，`structure = list(correlation_range = "symmetric")` 使零成为取值范围内部的值（[选择拟合设置](fitting-controls.html#correlation-range)）；`t0` 等于 `t0_lower` 时，调低 `t0_lower` 可以允许更小的 `t0`。建议还涉及两类上界。ACL 有五个参数的默认上界低于 ALSCL，拟合停在其中之一时，建议用 `bounds = "wide"` 重新拟合（[选择拟合设置](fitting-controls.html#starts)）；`t0` 停在上界时，建议会说明这个上界的含义。

合理性提示针对的是通过了数值检查、但数值提示需要核查输入的估计值。它们不改变 `numerical_ok`。四项检查见下表。除补充个体的平均体长外，这些检查只针对被估计的参数，因为用 `map` 固定的值是假定，不是拟合的结果。代码块的第二次拟合中，`M = 0.5` 高于估计的初始总死亡率（每个时间步 0.49），所以拟合通过检查并带有一条提示。

| 检查 | 何时给出提示 | 应核查什么 |
|---|---|---|
| `recruit_length` | 由 `Linf`、`k`、`t0` 和 `rec.age` 算出的补充个体平均体长，比第二个体长组的下界低两个体长组宽度以上 | `rec.age` 是否为调查指数中最小个体的年龄，以及生长参数 |
| `observation_sd` | 对数尺度上观测误差标准差的估计值大于 0.9 | 残差，以及生长和调查可捕性的设置 |
| `growth_cv` | 年龄别体长的变异系数（`cv_len`）或生长增量的变异系数（`cv_grow`，ALSCL）的估计值大于 0.3。Stock Synthesis 手册中 `cv_len` 的示例范围是 0.10 到 0.25；`cv_grow` 没有已发表的范围 | 用年龄资料核对拟合的各年龄体长（[评估工作流](assessment-workflows.html#outputs)），或把该参数固定在由年龄资料得到的值上 |
| `initial_Z` | 估计的初始总死亡率低于最小的自然死亡率 | `M`、调查可捕性，以及第一个时间步之前补充量是否在增加 |

阈值保存在 `diagnostics$check_thresholds` 中。它们是本包选定的筛查值，并非取自文献。`diagnose_model()` 报告已到极限的参数个数和提示条数，`summarize_simulations()` 把参数到达极限计入失败原因。早期版本保存的拟合保留其原有的检查结论。

<h2 id="residuals">2. 残差规律</h2>

```r
plot_residuals(b, facet_by = "year", facet_ncol = 5)
plot_residuals(b, facet_by = "length", facet_ncol = 4)
checks <- check_fit(b, max_lag = 4)
checks$plots$heatmap
checks$plots$lag
checks$plots$qq
checks$lag_correlations
```

残差是观测的对数调查指数减去拟合值。`facet_by = "year"` 按年份分面画残差随体长的变化；`facet_by = "length"` 按体长组分面画残差随时间的变化。`check_fit()` 用标准化残差绘制三种视图：时间乘体长的热图，用于寻找持续同号或有规律的偏差；滞后 1 到 `max_lag` 个模型时间步的相关系数，用于检查时间依赖；QQ 图，用于将残差分布与正态参照分布比较。QQ 图的参考线是标准正态分布 N(0,1)。即使模型设定正确，标准化条件残差的标准差也小于 1，因为拟合的过程偏差吸收了一部分观测误差。在模型设定正确的模拟检验中，这一标准差约为 0.91 到 0.96。因此两端的点会略微落在参考线内侧，不要把这一斜率解读为误差分布尾部偏轻或离散不足。偏斜或单侧重尾仍值得检查。

根据这些规律选择需要检验的假设。最小体长组中的规律可提示检查调查可捕性（`sel_L50`、`sel_L95`）的敏感性；斜向规律可提示检查生长与世代动态。两种图形都不能唯一确定原因，短滞后相关本身也不能证明缺少年份效应。残差以拟合的过程偏差为条件，这些图没有校准的显著性阈值。解释生物学原因前，应比较不同假设。

<h2 id="compare">3. 比较设置和模型</h2>

```r
comparison <- compare_models(a, b, x$data.CatL)
comparison$comparison
comparison$fit_metrics
comparison$length_at_age
comparison$growth
comparison$correlation
plot_compare_residuals(a, b, x$data.CatL)
plot_compare_ts(a, b, quantities = c("SSB", "Rec"), se = TRUE)
```

`compare_models()` 适用于同一观测的任意两次拟合：ACL 对 ALSCL，或同一模型的两种设置，例如某个参数固定与释放。它先核对两次拟合使用了同一张调查表（`data_verified`），再比较 AIC、BIC 和 `fit_metrics` 中的拟合统计量。`preferred` 只在两次拟合都通过数值检查（`eligible`）且两个 AIC 相差至少 2 时给出 AIC 较低的模型。某次拟合未通过检查时，`preferred` 留空，`issues` 说明原因。两次拟合都合格但 AIC 之差小于 2 时，`preferred` 同样留空，而 `issues` 为空：函数会打印 AIC 差别很小的提示，差值见 `comparison$summary` 的 `Delta AIC` 行。`comparison$comparison` 还记录 `delta_aic`（第二个模型的 AIC 减去第一个模型的 AIC）、`aic_threshold`（2）和 `reason`，后者说明没有给出优选的原因。差值小于 2 并不说明两个模型等价。用比较结果在统计上可比的设置之间做选择；AIC 较低并不能让固定值或结构不适合该种群的模型变得可用。

有三张表比较两次拟合的估计结果。`comparison$length_at_age` 给出两次拟合各年龄的平均体长（对各时间步取平均），每个模型一列。两次拟合的调查可捕性都可用时，`Basis` 为 `"survey"`（体长别尾数乘以体长别调查可捕性），否则为 `"population"`。生长的比较看这张表。`comparison$growth` 把参数 `Linf`、`k`、`t0`、`cv_len`、`cv_grow`（ALSCL）和观测误差的标准差按模型各列成一组行，列名为 `Model`、`Parameter`、`Estimate` 和 `Meaning`。参数不并排放置，因为在 ACL 中 `Linf`、`k` 和 `t0` 是各年龄平均体长的 von Bertalanffy 曲线参数，在 ALSCL 中它们决定体长别生长增量和补充个体的平均体长（[模型原理与时间尺度](model-theory.html#difference-increment)）。`comparison$correlation` 对产卵生物量、补充量、生物量和丰度给出两条序列之间的相关系数，以及 `Ratio_Mean`，即第二次拟合的均值除以第一次拟合的均值。尾数和重量计的渔获量按相对渔获量比较，见 `CN (relative)` 和 `CB (relative)` 两行：只给出相关系数，因为只拟合调查指数时渔获量的水平无法确定。

比较时请提供两次拟合共同使用的调查表。程序逐格按该正观测自身的大小核对，相对容差为 `1e-12`。例如，把 `1e-13` 改成 `1e-20` 会使对数观测相差约 16，程序会在选择模型前报错。

<h2 id="sensitivity">4. 对固定值的敏感性</h2>

```r
scenarios <- fit_scenarios(x, list(reference = list(), low_M = list(M = 0.15), high_M = list(M = 0.25)),
                           model = "acl", ncores = 2)
scenarios$status
subset(scenarios$estimates, quantity == "SSB" & year == max(year))
# 输入的其他形式：按年龄组的 M 和穹顶形调查可捕性
q_dome <- survey_catchability(x$fit_args$len_mid, "dome", L50 = 15, L95 = 20,
                              L50_desc = 42, L95_desc = 34, minimum = 0.2)
inputs <- fit_scenarios(x, list(
  reference = list(),
  M_by_age = list(M = matrix(c(0.4, 0.3, rep(0.2, 13)), ncol = 1)),
  dome = list(survey_q = q_dome, sel_L50 = NULL, sel_L95 = NULL)),
  model = "acl", ncores = 2, F_summary = "mean", silent = TRUE)
inputs$status[, c("scenario", "numerical_ok")]
mean_F <- subset(inputs$estimates, quantity == "F")
tapply(mean_F$estimate, mean_F$scenario, mean)
ssb <- subset(inputs$estimates, quantity == "SSB")
tapply(ssb$estimate, ssb$scenario, mean)
tapply(ssb$estimate, ssb$scenario, function(v) v[length(v)] / mean(v))
```

固定输入（自然死亡率 `M`、调查可捕性、固定的生长参数）决定估计值的尺度。`fit_scenarios()` 在具名的改动下重新拟合同一观测，返回每次拟合的状态和按情景整理的估计值表，可以看出 `M` 在有依据的范围内变化时，最后一年的产卵生物量变动多少。先看 `status`：未通过数值检查的情景保留在表中并加以标记。[评估工作流](assessment-workflows.html)继续介绍似然剖面和投影。

情景可以把 `M` 换成它的任何一种形式，也可以用 `survey_q` 代替 logistic 调查可捕性；因为输入列表里存有 `sel_L50` 和 `sel_L95`，这样的情景要把它们设为 `NULL`。每项输入的变动范围应根据它的来源确定。按最大年龄估计的 M，估计式的一个标准差（对数尺度上 0.31）相当于把 M 乘以 0.73 和 1.36（[Hamel 和 Cope 2022](https://doi.org/10.1016/j.fishres.2022.106477)）。穹顶形调查可捕性会压低估计的死亡率，并与 M 相互混淆，所以每次都要同时运行 logistic 曲线的情景。

与趋势相比，F 和种群数量的水平更依赖这些输入。在代码块的第二部分，F 对各年龄和各年份的均值在参考拟合中为 0.32，最小两个年龄组的 M 调高后为 0.28，使用穹顶形曲线后为 0.12；产卵生物量的均值分别为 57、57 和 141。最后一年的产卵生物量与其多年均值之比分别为 1.33、1.34 和 1.19。调查指数提供的是总死亡率和相对数量的信息，不能确定总死亡率在 F 和 M 之间的划分，也不能确定可捕性的水平（[模型原理与时间尺度](model-theory.html#survey)）。报告趋势和总死亡率时给出它们在各情景下的范围；给出 F 的水平时，同时说明它所依赖的 M 和调查可捕性。

<h2 id="stability">5. 随时间的稳定性</h2>

另外两项检查针对时间维度。回溯分析依次去掉最后 1、2、3 个时间步后重新拟合，报告末端估计值的变化幅度（Mohn's rho），见[回溯分析](retrospectives.html)。预测检验用较早的时间步拟合，再用留出的观测给之后时间步的预测评分，见[模型验证](case-model-validation.html)。

<h2 id="next">下一步</h2>

| 想做什么 | 阅读 |
|---|---|
| 修改检查指出的设置 | [拟合设置](fitting-controls.html) |
| 运行回溯分析 | [回溯分析](retrospectives.html) |
| 做参数剖面或向前投影 | [评估工作流](assessment-workflows.html) |
| 检验对未来时间步的预测 | [模型验证](case-model-validation.html) |
| 绘制其他比较图 | [模型比较图](model-comparison.html) |
