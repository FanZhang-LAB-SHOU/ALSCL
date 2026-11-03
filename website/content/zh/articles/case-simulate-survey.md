# 如何模拟调查数据？

本页带你从已知的种群生成调查表，对一次重复拟合 ACL 和 ALSCL，并把估计值与真值比较。你需要已安装的软件包（[安装 ALSCL](getting-started.html)）和一份仓库副本，并从仓库根目录运行 R，因为第 2 步要加载 `scripts/simulation_workflow.R`。结束时你会有这些表、一次重复及其真值、两个拟合，以及估计值与真值对照的图。本页配图是 flatfish 预设的第 4 次重复，由 [scripts/case_studies.R](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/scripts/case_studies.R) 绘制。

<h2 id="quick">1. 用快速模拟器生成年度输入表</h2>

```r
library(ALSCL)
quick <- simulate_example_data(
  years = 2000:2019, seed = 42, bin_breaks = seq(5, 51, 2),
  Linf = 60, vbk = 0.2, t0 = 1/60, M = 0.2, nage = 15,
  L50_sel = 15, L95_sel = 20, L50_mat = 35, L95_mat = 40,
  wgt_a = exp(-12), wgt_b = 3, mean_F = 0.3,
  cv_catch = 0.2, rec_sigma = 0.3,
  save_csv = TRUE, output_dir = "my_annual_simulation")
str(quick, max.level = 1)
```

`simulate_example_data()` 是用来测试导入、拟合和绘图的快速模拟器：它返回三张表 `data.CatL`、`data.wgt`、`data.mat` 和生成值 `true_params`，`save_csv = TRUE` 还把三个 CSV 文件写入 `output_dir`。做实验要用第 2 步的操作模型。无效的设置，例如 `L95_sel` 小于 `L50_sel`，会在写出任何文件之前终止调用；[模拟调查数据](simulation.html#choose)列出了全部设置。

<h2 id="replicate">2. 用完整操作模型生成一次重复</h2>

```r
source("scripts/simulation_workflow.R", encoding = "UTF-8")
pa <- initialize_params(species = "flatfish", first.year = 2000,
                        observation_error = "independent")
bio <- sim_cal(pa)
sm <- sim_data(bio, pa, iter_range = 4:5, return_iter = 4,
               output_dir = "my_full_simulation")
inputs <- simulation_to_tables(sm, pa)
saveRDS(list(parameters = pa, truth = sm, inputs = inputs),
        "my_full_simulation/truth_and_inputs.rds")
str(inputs)
```

`initialize_params()` 建立 flatfish 预设（年龄结构动态，80 年预热后保留 20 个年度时间步，标签 2000-2019），`sim_cal()` 推出生物学数组，`sim_data()` 运行种群：`iter_range` 给出重复编号，也是随机种子；每次重复用 `save()` 保存为 `sim_rep<编号>`（用 `load()` 读回）；`return_iter = 4` 把该次重复作为 `sm` 返回，其中有调查数量 `SN_at_len`、保留的 `years` 以及真值 `SSB`、`Rec` 和 `TB`（[模拟调查数据](simulation.html#generate)列出了每个元素）。`simulation_to_tables(sm, pa)` 返回三张表，行是体长组中点，列是 `sm$years`；`str(inputs)` 应显示三个 23 行 21 列的数据框。若转换器因 `len_mid` 与重复中记录的坐标不同而停止，请传入生成该文件的参数列表。

<h2 id="plot">3. 绘制模拟观测</h2>

```r
library(ggplot2)
years <- as.numeric(names(inputs$data.CatL)[-1])
observations <- data.frame(
  Year = rep(years, each = length(pa$len_mid)),
  Length = rep(pa$len_mid, length(years)),
  Index = as.vector(as.matrix(inputs$data.CatL[-1])))
p_data <- ggplot(observations, aes(Year, Length, fill = log10(Index))) +
  geom_tile() + scale_fill_gradient(low = "white", high = "steelblue") +
  labs(fill = "log10 index") + theme_bw() +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
p_data
ggsave("my_full_simulation/survey.png", p_data, width = 10, height = 4, dpi = 160)
```

热图显示按年份和体长组排列的 log10 调查指数，`pa$len_mid` 是 23 个体长组中点。

![完整 flatfish 模拟：体长与年份上的调查数量](../assets/manual/figures/cases/flatfish_data.png)

逐年穿过各体长组的条带是在调查中生长的世代。指数在 10 cm 以下很小（那里的可捕性低于 0.1），在 15-30 cm 最大；可捕性的变化会改变这个观测面，而种群本身不变。

![生成模型的生长曲线、成熟比例与调查可捕性](../assets/manual/figures/cases/flatfish_biology.png)

上图是生长曲线，从 1 龄 11 cm 到 15 龄 57 cm。下图是成熟比例（L50 为 35 cm，来自 `data.mat`）和调查可捕性（L50 为 15 cm，来自 `sel_L50` 和 `sel_L95`）；你的种群需要自己的数值。

<h2 id="fit">4. 对这次重复拟合两个模型</h2>

```r
F_marginal_sd <- pa$F_sd / sqrt(1 - pa$F_ar^2)
pA <- list(log_Linf = log(pa$Linf), log_vbk = log(pa$vbk), t0 = pa$t0,
           log_cv_len = log(pa$cv_L), log_std_log_F = log(F_marginal_sd),
           log_std_log_N0 = log(pa$std_logN0), logit_log_R = qlogis(pa$R_ar))
pB <- list(log_Linf = log(pa$Linf), log_vbk = log(pa$vbk), log_t0 = log(pa$t0),
           log_cv_len = log(pa$cv_L), log_cv_grow = log(pa$cv_inc),
           log_sigma_log_F = log(F_marginal_sd), log_sigma_log_N0 = log(pa$std_logN0),
           logit_log_R = qlogis(pa$R_ar))
mA <- lapply(pA, function(value) factor(NA))
mB <- lapply(pB, function(value) factor(NA))
mB$logit_log_F_l <- mB$logit_log_F_y <- factor(NA)
x <- prepare_alscl_data(inputs,
  fit_args = list(rec.age = pa$rec.age, nage = pa$nage, M = pa$M,
    sel_L50 = pa$q_surv_L50, sel_L95 = pa$q_surv_L95,
    len_mid = pa$len_mid, len_border = pa$len_border[-c(1, length(pa$len_border))],
    growth_step = pa$growth_step, train_times = 2, ncores = 1, silent = TRUE),
  fit_config = list(acl = list(parameters = pA, map = mA),
                    alscl = list(parameters = pB, map = mB)))
for (model in c("acl", "alscl")) print(check_alscl_data(x, model)$summary)
a <- run_acl(x)
b <- run_alscl(x)
checks <- list(ACL = diagnose_model(x$data.CatL, a),
               ALSCL = diagnose_model(x$data.CatL, b))
c(a$diagnostics$numerical_ok, b$diagnostics$numerical_ok)
```

输入列表 `x` 在 `fit_args` 中装入生成模型的生物学设置，在 `fit_config` 中按各模型自己的参数名装入初值和 `map`。平均生长参数和同龄体长 CV 固定在预设值上。ALSCL 的生长增量 CV 也固定在预设值上，但年龄型 flatfish 生成器不使用这个参数。对于 F，`pa$F_sd` 是创新 SD，因此代码用 `pa$F_sd / sqrt(1 - pa$F_ar^2)` 换算成拟合模型的边际 SD（该预设为 0.3023716）。初始数量 SD 和补充量相关系数按指定的拟合假设固定，两个 F 相关系数均固定为 0.75。每个模型估计 5 个标量参数。

这些条件拟合并没有重现全部生成假设：操作模型将各组共用、随时间变化的 F 与选择性相乘，并将初始数量偏差沿年龄累加；拟合模型则使用组别与时间可分离的 F 过程，以及独立的初始偏差。[年度与季度时间步](case-studies.html#annual)使用相同设置。

`pa$len_border` 从 `-Inf` 到 `Inf`，去掉首尾剩下 22 个内部边界。两个模型的 `check_alscl_data()` 都应报告 23 个体长组、20 个时间步、460 个正观测和 `free_fixed` 为 5；最后一行应打印 `TRUE TRUE`。拟合耗时取决于机器和优化路径，`a$elapsed` 和 `b$elapsed` 会分别记录。若检查未通过，按[理解第一次拟合](first-model.html#checks)运行 `diagnose_model()`，并用 `nstarts` 增加初值。

<h2 id="truth">5. 将估计值与生成真值比较</h2>

```r
truth <- data.frame(Year = rep(years, 3),
  Quantity = rep(c("B", "SSB", "Rec"), each = length(years)),
  Truth = c(sm$TB, sm$SSB, sm$Rec))
estimates <- rbind(
  data.frame(Year = rep(years, 3), Quantity = truth$Quantity,
    Value = c(a$report$B, a$report$SSB, a$report$Rec), Model = "ACL"),
  data.frame(Year = rep(years, 3), Quantity = truth$Quantity,
    Value = c(b$report$B, b$report$SSB, b$report$Rec), Model = "ALSCL"))
p_truth <- ggplot(estimates, aes(Year, Value, color = Model)) + geom_line() +
  geom_line(data = truth, aes(Year, Truth), inherit.aes = FALSE, linetype = 2) +
  facet_wrap(~ Quantity, scales = "free_y", ncol = 1) + theme_bw() +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
p_truth
ggsave("my_full_simulation/truth_comparison.png", p_truth,
       width = 10, height = 6, dpi = 160)
saveRDS(list(parameters = pa, truth = sm, inputs = inputs, checks = checks,
             ACL_report = a$report, ALSCL_report = b$report),
        "my_full_simulation/assessment_summary.rds")
```

模拟器把总生物量叫 `TB`，拟合报告叫 `B`；代码先按年份和指标把两者对齐。

![flatfish 第 4 次重复：生成真值与 ACL/ALSCL 条件估计](../assets/manual/figures/cases/flatfish_truth.png)

虚线是真值，实线是两个条件估计；各面板的纵轴自由缩放，所以在同一面板内比较。对于生物量和产卵生物量，两个模型都跟上了 2010 年前的下降和之后的回升，ALSCL 在 2014 年后的生物量和产卵生物量低于真值。这里只展示年龄结构生成模型的一次重复；要给模型排序，需要很多次重复并保留失败的拟合，[模拟调查数据](simulation.html#fit)用 `summarize_simulations()` 做汇总。

<h2 id="next">下一步</h2>

| 想做什么 | 阅读 |
|---|---|
| 拟合季度 tuna 重复 | [年度与季度时间步](case-studies.html) |
| 拟合多次重复并汇总偏差、RMSE 和覆盖率 | [模拟调查数据](simulation.html#fit) |
| 从拟合模型模拟并重新拟合 | [模型能重现观测并预测留出时间步吗？](case-model-validation.html) |
| 保存种子、设置和版本 | [复现结果与排除故障](reproducibility.html) |
