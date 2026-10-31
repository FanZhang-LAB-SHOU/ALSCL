# 诊断与结果解读

先完成 [YTF 拟合示例](first-model.html)。以下代码使用其中的 `x`、`inputs`、`a`（ACL）和 `b`（ALSCL）对象。

## 1. 检查数值状态

```r
# 数值检查
c(code = b$convergence_code, gradient = b$max_abs_gradient,
  pdHess = b$pdHess, boundary = b$bound_hit)
diagnose_model(x$data.CatL, b)
diagnostic_metrics(x$data.CatL, b)
comparison <- compare_models(a, b, x$data.CatL)
comparison$fit_metrics
comparison$fit_diagnostics
comparison$comparison
comparison$correlation # 包括 Ratio_Mean
plot_residuals(b, type = "length", facet_ncol = 4)
plot_compare_residuals(a, b, x$data.CatL)
```

本次 YTF 主拟合的优化码均为 0，最大绝对梯度约为 ACL `1.22e-4`、ALSCL `5.75e-9`，Hessian 均正定，没有检测到边界命中。结果记录见 [convergence.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/convergence.csv)。梯度 < 0.001 是本教学流程的数值筛查阈值，不是适用于所有模型的科学有效性标准。

`run_acl(x)` 和 `run_alscl(x)` 默认对选中的拟合执行最多五步受保护的 Newton 收尾（`polish = TRUE`）。每步要求数值 Hessian 正定、参数严格位于上下界内、最大绝对梯度下降，且目标函数增加不超过 `1e-8` 的浮点舍入容差。不满足条件就停止；收尾不能补足资料信息，也不能修复不合适的模型。`polish = FALSE` 可跳过收尾。2.2.2 引入的收尾可能改变数值精度层面的估计；复现旧拟合时应保留包版本与 `polish` 设置。

每轮优化的原始参数、目标函数、代码和信息保存在 `fit$optimizer_history`。后续一轮在同一点误报失败时，保留前一轮成功状态。`fit$raw_opt` 保存收尾前选中的结果；`fit$refinement` 记录接受的步骤及前后梯度。`convergence_code` 始终表示所选优化轮次的原始代码，不会因收尾而强行改为成功。多起点仍按收尾前最低有限目标函数选取；`starts` 和 `start_diagnostics` 记录收尾前各起点的结果。

`fit$diagnostics` 提供独立的数值筛查：最大梯度小于 `1e-3`、Hessian 与协方差正定、不触及优化器边界或自然尺度边界。自由相关系数距离 0 或 1 不超过 `1e-4`，以及自由过程／观测标准差不超过 `1e-4`，都会标记。这些是筛查阈值，不是统计检验。`high_correlations` 列出绝对相关系数至少 0.95 的参数对，需进一步审查，但不能单凭高相关就断言不可识别。协方差条件数取决于参数尺度。`diagnose_model()` 分别显示原始优化代码和数值筛查结果；仍需检查残差、多起点、似然剖面和敏感性。

## 2. 比较拟合前核对观测

`diagnostic_metrics()`、`diagnose_model()` 和 `compare_models()` 核对已知时间标签、体长标签、正观测掩码及拟合时保存的观测。即使维度相同，颠倒年份或体长组顺序也会报错。请传原始拟合表，例如 `diagnose_model(x$data.CatL, b)`；这些是样本内诊断，不是留出预测接口。缺少元数据的旧结果仍可计算原始指标，但不能据此确认模型可比较。

比较表和指标图共用计算规则：只使用有限正观测，常数观测的 R 方为 `NA`，观测位置的原尺度预测非有限时会报错；缺测与零值仍被排除。通过这些检查不代表模型在生物学上充分。

拟合、诊断和模型比较统一解析普通 data.frame、matrix、tibble 及保存数值文本的 factor 列。因子按标签转为观测值，不使用内部等级编码；体长标签按向量提取。修改了观测值、缺测掩码、年份或体长组顺序时，原有匹配检查仍会报错。

`compare_models()` 会核对两个拟合与传入调查表的时间标签、体长标签及顺序、正观测值和观测掩码；确认不一致时直接报错。旧保存结果若缺少核对所需元数据，仍可读取原始统计量，但不自动给出模型偏好。任一拟合未通过数值筛查时，函数发出警告，保留原始 AIC/BIC 和拟合指标供检查，不宣布哪个模型更优。查看 `comparison$fit_diagnostics` 与 `comparison$comparison`（`data_verified`、`eligible`、`preferred`、`issues`）。通过筛查只表示可以开展条件比较，仍需审查似然可比性和生物假设。

## 3. 检查残差模式与绘图尺度

`plot_residuals()` 显示原始对数残差，即观测对数指数减去拟合对数指数。`check_fit()` 另提供条件标准化残差、热图、按实际时间间隔计算的滞后相关和 QQ 图。这些残差以拟合潜在效应为条件，标准化不会使其相互独立。`plot_deviance()` 显示过程偏差，不是似然 deviance。

```r
checks <- check_fit(b, max_lag = 4)
checks$plots$heatmap
checks$plots$lag
checks$plots$qq
checks$lag_correlations
```

调查拟合图按矩阵位置及拟合年份、体长元数据对齐观测与预测，增删行列名不会改变坐标；缺失及零观测继续排除。若预测取指数会溢出，请使用 `exp_transform = FALSE`。残差图的 `resid_cap` 必须为有限正标量，或以 `NULL` 关闭截断；不再允许负值或零值抹去诊断特征。

默认 `plot_CatL(exp_transform = FALSE)` 绘制自然对数调查指数，并在纵轴标明尺度；`exp_transform = TRUE` 绘制原尺度调查指数，预测曲线为中位数。显式 `ylab` 覆盖自动标签。山脊图在对数尺度稳定归一化，极大或极小的有限对数预测仍可绘制；非有限预测会报错。

每个分面按自身有效观测的不同横坐标数量选择趋势：少于 2 个不画平滑线，2–5 个使用线性趋势，至少 6 个使用 loess；需要时仅增加该分面的 span，以包含至少 5 个邻近点。稀疏尾部体长组不会删除或改变其他分面的趋势。

## 4. 检查敏感性与 F 结构

比较不同初值、有生物依据的固定输入及 F 结构下的结果。`F_structure = "group_year"` 对 ACL 估计年龄 × 时间 F，对 ALSCL 估计体长 × 时间 F；`F_structure = "year"` 在每个模型时间步内让所有组共用 F，季度数据对应每季度一个值。应根据渔业和数据选择该假设，不能仅以收敛为依据。AR(1) 参数化、有效 map 和仅固定 t0 的例子见[拟合设置](fitting-controls.html)，完整比较见[敏感性与未来情景](case-sensitivity-projection.html)。

已记录的模拟 YTF 比较中，仅固定 t0 的 ACL 拟合出现年龄相关系数逼近 1；其生成数据在年龄间共用 F，共用结构处理了这项不匹配。仅固定 t0 的 ALSCL 拟合则受益于优化收尾。这是教学数据上的两项不同结果，设置与数值记录见 [2.2.2 验证报告](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/RELEASE_2.2.2.md)。

![YTF 拟合的数值检查记录](../assets/manual/figures/convergence-2.2.2.png)
