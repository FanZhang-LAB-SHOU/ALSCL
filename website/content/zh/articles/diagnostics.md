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

`diagnose_model()` 打印优化器原始收敛码、最大绝对梯度、Hessian 和协方差状态，以及参数边界检查。数值筛查使用 0.001 的梯度阈值、Hessian 和协方差矩阵的正定性及边界检查；优化器原始收敛码另行报告。`b$diagnostics$issues` 列出全部诊断提示。`high_correlations` 列出估计相关系数绝对值至少为 0.95 的参数对，包括负相关；应结合剖面、其他初值或敏感性分析检查这些参数的可辨识性。`b$refinement` 记录收尾的 Newton 步（满足梯度准则时 `status = "gradient_tolerance"`），`b$start_diagnostics` 记录每个初值的目标函数值。

检查未通过时，每次只改一处：增加初值（`nstarts = 4`），检查参数尺度和边界，并用剖面调查难以确定的参数。有依据时再固定某个参数，或让各组共用 F（`F_structure = "year"`），方法见[拟合设置](fitting-controls.html)。在第 3 步比较修改后的拟合与原拟合。通过数值筛查不能确认唯一解、全局最优解、参数可辨识性或模型适用性。[Carvalho 等（2021）第 2.1 节](https://repository.library.noaa.gov/view/noaa/32687/noaa_32687_DS1.pdf)解释了为何需要结合多项诊断。

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

残差是观测的对数调查指数减去拟合值。`facet_by = "year"` 按年份分面画残差随体长的变化；`facet_by = "length"` 按体长组分面画残差随时间的变化。`check_fit()` 用标准化残差绘制三种视图：时间乘体长的热图，用于寻找持续同号或有规律的偏差；滞后 1 到 `max_lag` 个模型时间步的相关系数，用于检查时间依赖；QQ 图，用于将残差分布与正态参照分布比较。偏离 QQ 参考线反映分布形状的差异，包括偏斜或尾部特征。

根据这些规律选择需要检验的假设。最小体长组中的规律可提示检查调查可捕性（`sel_L50`、`sel_L95`）的敏感性；斜向规律可提示检查生长与世代动态。两种图形都不能唯一确定原因，短滞后相关本身也不能证明缺少年份效应。残差以拟合的过程偏差为条件，这些图没有校准的显著性阈值。解释生物学原因前，应比较不同假设。

<h2 id="compare">3. 比较设置和模型</h2>

```r
comparison <- compare_models(a, b, x$data.CatL)
comparison$comparison
comparison$fit_metrics
plot_compare_residuals(a, b, x$data.CatL)
plot_compare_ts(a, b, quantities = c("SSB", "Rec"), se = TRUE)
```

`compare_models()` 适用于同一观测的任意两次拟合：ACL 对 ALSCL，或同一模型的两种设置，例如某个参数固定与释放。它先核对两次拟合使用了同一张调查表（`data_verified`），再比较 AIC、BIC 和 `fit_metrics` 中的拟合统计量。`preferred` 只在两次拟合都通过数值检查（`eligible`）时给出 AIC 较低的模型，否则留空并在 `issues` 中说明原因。用比较结果在统计上可比的设置之间做选择；AIC 较低并不能让固定值或结构不适合该种群的模型变得可用。

比较时请提供两次拟合共同使用的调查表。程序逐格按该正观测自身的大小核对，相对容差为 `1e-12`。例如，把 `1e-13` 改成 `1e-20` 会使对数观测相差约 16，程序会在选择模型前报错。

<h2 id="sensitivity">4. 对固定值的敏感性</h2>

```r
scenarios <- fit_scenarios(x, list(reference = list(), low_M = list(M = 0.15), high_M = list(M = 0.25)),
                           model = "acl", ncores = 2)
scenarios$status
subset(scenarios$estimates, quantity == "SSB" & year == max(year))
```

固定输入（自然死亡率 `M`、调查可捕性、固定的生长参数）决定估计值的尺度。`fit_scenarios()` 在具名的改动下重新拟合同一观测，返回每次拟合的状态和按情景整理的估计值表，可以看出 `M` 在有依据的范围内变化时，最后一年的产卵生物量变动多少。先看 `status`：未通过数值检查的情景保留在表中并加以标记。[评估工作流](assessment-workflows.html)继续介绍似然剖面和投影。

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
