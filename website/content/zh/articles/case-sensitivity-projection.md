# 评估对假设有多敏感，未来 F 情景会怎样改变结果？

本页对同一个拟合好的评估（模拟 YTF 示例）提出三个问题：固定的自然死亡率或 F 结构改变时估计值移动多少，数据对一个被估计的参数能确定到什么程度，以及确定性的未来 F 情景意味着什么。你需要已安装的软件包（[安装 ALSCL](getting-started.html)）；代码从第 1 步的拟合开始按顺序运行，需要几分钟。结束时你会有情景表和图、一个参数剖面和两个投影，各自带有数值检查。

<h2 id="fit">1. 拟合参考模型</h2>

```r
library(ALSCL)
library(ggplot2)
data("YTF_example")
x <- YTF_example
acl_theme_set(palette = "npg", base_theme = "theme_bw")

check_alscl_data(x, "acl")$summary
check_alscl_data(x, "alscl")$summary
a <- run_acl(x, silent = TRUE)
b <- run_alscl(x, silent = TRUE)
summary(a)
summary(b)
```

ACL 拟合 `a` 用于情景和剖面，因为一次 ACL 重新拟合约需二十秒；ALSCL 拟合 `b` 用于投影。`summary()` 打印时间步、F 结构、数值检查（`numerical_ok` 应为 `TRUE`）和自然尺度上的标量参数。`YTF_example` 把生长、体长 CV、两个过程标准差和补充量相关系数固定在教学值上，`M` 为每个年度时间步 0.20，F 结构为默认的 `F_structure = "group_year"`；你自己的输入列表需要有依据的生物学设置（[选择拟合设置](fitting-controls.html)）。若检查未通过，先修好拟合再做任何情景（[判断拟合是否可用](diagnostics.html)）。

<h2 id="scenarios">2. 拟合敏感性情景</h2>

```r
scenarios <- fit_scenarios(x, list(
  reference = list(),
  low_M = list(M = 0.15),
  shared_F = list(F_structure = "year")
), model = "acl", ncores = 1, nstarts = 1,
   F_summary = "mean", silent = TRUE)
scenarios$status
head(scenarios$estimates)

scenario_ssb <- subset(scenarios$estimates, quantity == "SSB")
ggplot(scenario_ssb, aes(year, estimate, color = scenario)) +
  geom_line() + labs(x = "Year", y = "SSB") +
  theme_bw() + theme(panel.grid = element_blank())
```

`fit_scenarios()` 在模型照原样使用的输入发生具名改变时，重新拟合同样的三张表：每个情景是一个替换 `x` 设置的参数列表，空列表是参考情景，`map` 这样的列表会整体替换保存的列表。`low_M` 把每个时间步的自然死亡率从 0.20 降到 0.15；`shared_F` 设置 `F_structure = "year"`，每个时间步所有年龄共用一个 F（季度数据就是每季度一个），年龄间的相关系数随之变为 inactive。`ncores` 在独立的工作进程上运行各情景，每次拟合使用一个工作进程和输入列表或调用中的 `nstarts`（两者都未设置时用一个初值）；`F_summary = "mean"` 对每个时间步的各年龄取 F 的均值，`"apical"` 取最大值。先读 `scenarios$status`：每个情景一行，含耗时、警告、报错和数值检查。未通过检查的情景保留在 `scenarios$estimates` 中并标为 `numerical_ok = FALSE`，报错终止的情景没有估计值。

![ACL 对输入 M 与共享 F 结构的敏感性](../assets/manual/figures/workflows/scenario-SSB.png)

在记录运行中三个拟合都通过检查（[scenario-status.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/workflows/scenario-status.csv)），最后一个时间步（2019 年）的结果如下（[scenario-estimates.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/workflows/scenario-estimates.csv)）：

| 情景 | 2019 年产卵生物量 | 每时间步平均 F |
|---|---:|---:|
| `reference` | 75.5 | 0.320 |
| `low_M` | 75.4 | 0.371 |
| `shared_F` | 74.1 | 0.335 |

较低的 M 抬高了估计的 F，而末期产卵生物量几乎没变，三条曲线几乎重合；用你自己的数据时，曲线之间的差距就是要报告的敏感性。

<h2 id="profile">3. 对一个被估计的参数做剖面</h2>

```r
profile_values <- exp(a$opt$par[["mean_log_F"]]) * c(0.9, 1, 1.1)
profile_F <- profile_model(a, "mean_log_F", profile_values,
                           scale = "natural", ncores = 1)
profile_F$grid
ggplot(profile_F$grid, aes(value, delta_nll)) +
  geom_line() + geom_point() +
  labs(x = "F process baseline", y = "Change in negative log likelihood") +
  theme_bw() + theme(panel.grid = element_blank())
```

`profile_model()` 把一个被估计的标量参数依次固定在网格值上，重新拟合其余标量参数和过程偏差；参数名必须在 `names(a$opt$par)` 中，所以 `YTF_example` 中固定的 `log_Linf` 会报错终止，而 `mean_log_F` 是被估计的。`scale = "natural"` 时网格在自然尺度上，这里是拟合基准值的 0.9、1 和 1.1 倍，并且必须在优化器边界之内。`profile_F$grid` 给出每个值及其目标函数、`delta_nll`（相对于原始拟合的负对数似然增量）和该次重新拟合的数值检查；失败的点保留可见。负的 `delta_nll` 会保留；小于 `-1e-6` 时才会因目标函数值更低而警告。应检查该网格拟合的数值状态，并用更多初值重新拟合原模型。很小的负差值可能来自舍入误差。`M` 和调查可捕性这类固定输入属于第 2 步。

![自由 F 过程基准水平的示例剖面](../assets/manual/figures/workflows/profile-F.png)

在记录运行（[profile-F.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/workflows/profile-F.csv)）中，0.278、0.309 和 0.340 三个点的增量分别为 0.43、约 0（-1e-10，舍入误差）和 0.35，全部通过检查：基准 F 改变 10% 要付出约 0.4 个单位。三个点只演示方法；用于报告的剖面需要更密的网格，函数也不会由此推断置信区间。

<h2 id="project">4. 投影未来 F 情景</h2>

```r
h <- 4L
w <- as.matrix(x$data.wgt[-1L])
mat <- as.matrix(x$data.mat[-1L])
future_w <- matrix(w[, ncol(w)], nrow(w), h)
future_mat <- matrix(mat[, ncol(mat)], nrow(mat), h)
future_rec <- rep(tail(b$report$Rec, 1), h)

low_F <- project_model(b, F = rep(0.10, h), recruitment = future_rec,
                       weight = future_w, maturity = future_mat)
higher_F <- project_model(b, F = rep(0.25, h), recruitment = future_rec,
                          weight = future_w, maturity = future_mat)
low_F$summary
higher_F$summary
low_F$assumptions
projection_ssb <- rbind(
  transform(low_F$summary, scenario = "F = 0.10"),
  transform(higher_F$summary, scenario = "F = 0.25"))
ggplot(projection_ssb, aes(year, SSB, color = scenario)) +
  geom_line() + geom_point() + labs(x = "Year", y = "Start-of-period SSB") +
  theme_bw() + theme(panel.grid = element_blank())
```

`project_model()` 在你提供的数值下把最后拟合的种群推进到未来时间步：`F`（每步一个值、所有组共用，或组 × 步矩阵）、`recruitment`（其长度决定投影期数），以及每个未来步一列的完整 `weight` 和 `maturity` 矩阵；`M` 保持拟合值，除非你另行传入。函数不会替你延续任何值：代码把最后观测的体重和成熟比例列以及末期拟合的补充量重复四步，这是要在报告中写明的选择。`summary` 的每一行描述一个时间步的期初：第一个未来状态是最后拟合的种群经过末期拟合的 F 和 M 存活后，加上第一个提供的补充量；未来的 `F[t]` 决定第 `t` 步的渔获和进入第 `t + 1` 步的存活，所以两个情景的第一个未来产卵生物量相同，从第二步起才分开，但第一步的渔获已经不同。投影是确定性的、以拟合为条件的，没有区间、亲体补充关系或参考点；`low_F$assumptions` 记录每一项选择。未通过数值检查的拟合会被拒绝，除非 `allow_failed_fit = TRUE`，此时会记录这一覆盖。

![显式保持未来生物学输入的 ALSCL 条件 SSB 情景](../assets/manual/figures/workflows/projection-SSB.png)

在记录运行（[projections.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/workflows/projections.csv)）中，两个情景 2020 年都从产卵生物量 66.1 开始；2023 年在 F = 0.10 下为 114，在 F = 0.25 下为 73.0，单位由示例的体重决定，并以保持不变的补充量和生物学设置为条件。

<h2 id="next">下一步</h2>

| 想做什么 | 阅读 |
|---|---|
| 把情景、剖面和投影记录与拟合一起保存 | [评估工作流](assessment-workflows.html#save-workflow) |
| 在相信投影之前检查残差规律 | [判断拟合是否可用](diagnostics.html) |
| 去掉近期时间步后重新拟合 | [移除近期数据后，估计结果会怎样变化？](case-retrospective-bias.html) |
| 从拟合模拟并给留出时间步的预测打分 | [模型能重现观测并预测留出时间步吗？](case-model-validation.html) |
