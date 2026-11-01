# 评估对假设有多敏感，未来 F 情景会怎样改变结果？

## 要回答的问题

改变外部输入 M、改变 F 结构、指定未来 F，回答的是不同问题。本案例对同一份模拟 YTF 数据分别检查：相同观测下的假设敏感性、自由 F 参数的信息，以及条件未来轨迹。下列代码完整，可按顺序运行。

内置生物学输入与固定参数 map 是教学假设。使用真实种群时，按[评估工作流](assessment-workflows.html)整理三张表，并提供独立依据的生物学输入；不要只为促使收敛而复制 YTF 固定规则。

## 拟合同一份数据

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

## 区分假设敏感性与参数剖面

`fit_scenarios()` 保持相同三张观测输入表，只应用具名设置变化。这里使用 ACL 缩短示例运行时间；改为 `model = "alscl"` 即选取相应 ALSCL 设置，参数名和 map 必须与模型匹配。M = 0.15 只是围绕 YTF 输入的示例扰动，不是生物学建议。

三套 ACL 配置使用相同调查表、生长输入、提供的初值和 map，仅改变下表列出的设置。`YTF_example` 的 M 为每年度时间步 0.20，默认 F 结构为 `"group_year"`。

| 情景 ID | 每时间步 M | F 结构 | 相对参考配置的改变 |
|---|---:|---|---|
| `reference` | 0.20 | `group_year`：年龄 × 时间 | 无 |
| `low_M` | 0.15 | `group_year`：年龄 × 时间 | 外部提供的自然死亡率 |
| `shared_F` | 0.20 | `year`：每时间步内各年龄共用 F | F 结构；不使用的年龄相关参数变为 inactive |

季度数据的 `"year"` 仍表示每模型时间步一个 F，即每季度一个，并非每日历年一个。后面的两套 ALSCL 未来情景另比较每时间步 F = 0.10 和 F = 0.25，补充量、体重、成熟比例及 M 均相同。

比较轨迹前先检查 `status` 的每一行，包括警告和失败拟合；函数不自动排名。`F_summary = "mean"` 是未加权组间均值，`"apical"` 是最大值，两者含义不同，也都不把季度 F 转为年率。`ncores` 并行运行独立情景；内层拟合和标准误使用单个 worker，并保留指定的 `nstarts`。列表覆盖整体替换，map 也不逐项深度合并。

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

![ACL 对输入 M 与共享 F 结构的敏感性](../assets/manual/figures/workflows/scenario-SSB.png)

## 对实际参与估计的参数做剖面

参数剖面将一个自由标量依次固定在网格值上，重新估计其他自由标量与随机效应。YTF 示例固定了 `log_Linf`，因此这里不能对它做剖面。`mean_log_F` 参与估计，下面三个点演示自然基准尺度的接口；有科学意义的剖面通常需要更密、理由明确的范围及各点成功拟合。

`delta_nll` 相对于原始拟合计算。负值表示网格拟合找到更低的目标函数，应重新检查原始最优点；不会截成零。失败点保留。函数不自动推导置信区间或似然比阈值。M 和调查可捕性等外部输入应使用敏感性情景，而不是标量参数剖面。

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

![自由 F 过程基准水平的示例剖面](../assets/manual/figures/workflows/profile-F.png)

## 投影假设明确的未来情景

`project_model()` 根据提供的未来 F、补充量、体重和成熟比例推进保存的种群状态。下面**明确选择**将末次观测的体重／成熟比例及末期拟合补充量延续四期；这是示例假设，不是函数自动决定的默认值。生长保持拟合的年龄—体长键，ALSCL 还保持拟合的生长转移矩阵。未来 M 默认使用原始记录输入，也可显式指定。

状态、B 和 SSB 表示每个未来时期的**期初**。第一未来状态先经历末期拟合 F 与原始 M，再加入第一期补充；未来 F[t] 影响当期渔获及存活到 t+1 的数量。因此两个情景的第一期未来 SSB 相同，但第一期渔获不同，后续 SSB 才出现响应。M 和 F 均为每个模型时间步的瞬时率，季度模型也一样。

这只是确定性的条件情景，没有不确定性区间、估计的亲体补充关系、MSY 或 TAC 计算。结果用于检视明确假设，不能表示确定的预测或管理建议。

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

![显式保持未来生物学输入的 ALSCL 条件 SSB 情景](../assets/manual/figures/workflows/projection-SSB.png)

## 本次实际运行显示什么

记录中的基准、低 M、共享 F 三个 ACL 拟合，以及三个剖面点，都通过数值检查。最后拟合时期（2019 年）的结果为：

| 情景 | SSB | 每模型时间步的平均 F |
|---|---:|---:|
| 基准 | 75.655 | 0.3184 |
| M = 0.15 | 75.579 | 0.3694 |
| 共享 F | 74.292 | 0.3308 |

本例降低输入 M 后，估计 F 增加，末期 SSB 变化很小。这只是同一模拟数据及其条件生物假设下的敏感性，不是一般可辨识结论，也不证明哪个结构更优。表中 F 是未加权的年龄组均值。

F 基准水平的剖面点约为 0.2811、0.3123、0.3436，负对数似然变化分别为 0.9321、接近零、0.7623。中点约 −7.7e−11 的微小负值是数值舍入差异。三个点只演示方法，并不定义置信区间。

两个 ALSCL 投影在 2020 年均从 SSB 65.032 开始，因为第一未来状态由末期拟合死亡率产生。在显式固定的未来补充量和生物学输入下，2023 年 SSB 在 F = 0.10 时为 114.631，在 F = 0.25 时为 73.311；首期渔获已经不同。单位由示例重量决定，不能把这些数值当作真实种群预测。

完整记录表：[情景状态](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/workflows/scenario-status.csv)、[情景估计](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/workflows/scenario-estimates.csv)、[参数剖面](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/workflows/profile-F.csv)、[未来投影](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/workflows/projections.csv)。

## 保留诊断与假设

逐个检查警告、错误、梯度、Hessian 和边界。通过数值检查不代表残差没有结构，也不证明模型适当。[完整工作流](assessment-workflows.html)还介绍条件残差诊断、可移植记录及模拟失败率／覆盖率汇总。


明确未通过数值检查的拟合默认拒绝投影。allow_failed_fit = TRUE 可在警告后进行探索性投影；旧结果缺少诊断时记为 unknown，不视为通过。assumptions 保存状态及是否覆盖。
