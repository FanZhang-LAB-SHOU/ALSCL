# ACL 与 ALSCL 的评估结果有什么不同？

本页带你对同一组模拟 YTF 观测拟合 ACL 和 ALSCL，看两种种群结构在哪些方面一致、在哪些方面不同。你需要已安装的软件包（[安装 ALSCL](getting-started.html)）；`YTF_example` 提供数据表、生物学设置和两个模型的固定参数，因此这一比较以这些教学数值为条件。结束时你会有比较表、四张图和一个保存文件夹。

<h2 id="fit">1. 对同一组观测拟合两个模型</h2>

```r
library(ALSCL)
data("YTF_example")
x <- YTF_example
inputs <- x[c("data.CatL", "data.wgt", "data.mat")]
a <- run_acl(x, train_times = 2, silent = TRUE)
b <- run_alscl(x, train_times = 2, silent = TRUE)
```

两次拟合都读取输入列表 `x`，因此共用数据表、`M`、调查可捕性和时间网格，每个模型从 `x$fit_config` 取自己的初值和 `map`；固定的生长和过程参数值对区间没有贡献不确定性。给两个模型相同的数据表和生物学设置，这样下面的每一处差异都来自模型结构。

<h2 id="checks">2. 检查两次拟合并比较拟合统计量</h2>

```r
diagnose_model(x$data.CatL, a)
diagnose_model(x$data.CatL, b)
comparison <- compare_models(a, b, x$data.CatL)
comparison$summary
comparison$fit_diagnostics
comparison$comparison
plot_compare_residuals(a, b, x$data.CatL)
```

先读每次拟合的数值检查（[理解第一次拟合](first-model.html#checks)）。`compare_models()` 核对两次拟合使用了同一张调查表，再比较目标函数、AIC、BIC 和 `fit_metrics` 中的拟合统计量。`comparison$comparison` 记录 `data_verified`、`eligible`（两次拟合都通过检查）、`preferred`（AIC 较低者，仅在两者都合格时给出）和 `issues`。在记录运行（[comparison_summary.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/comparison_summary.csv)）中，两次拟合都通过检查；ACL 的 AIC 更低，调查指数 RMSE 也更小，为 2.5 对 4.7。AIC 较低只是这些数据上的统计支持；结构是否适合这个种群，要用生物学知识判断。

![模拟 YTF：ACL 与 ALSCL 的残差比较](../assets/manual/figures/ytf/compare_residuals.png)

四个面板分别是残差直方图、QQ 图、逐年平均残差（误差线为一个标准差）和按体长组的绝对残差；[判断拟合是否可用](diagnostics.html#residuals)解释这些规律。

<h2 id="survey">3. 比较对调查观测的拟合</h2>

```r
plot_compare_CatL(a, b, x$data.CatL,
                  years = c(2000, 2005, 2010, 2015), facet_ncol = 2)
```

![模拟 YTF：四个年份的调查观测及拟合中位数](../assets/manual/figures/ytf/compare_CatL.png)

点是观测，曲线是选定四个年份的拟合中位数。读丰度差异之前，先比较拟合形状，特别是观测稀疏的较大体长组。

<h2 id="estimates">4. 比较种群估计</h2>

```r
plot_compare_ts(a, b, quantities = c("B", "SSB", "Rec"), se = TRUE)
```

![模拟 YTF 示例的条件种群估计](../assets/manual/figures/ytf/compare_ts.png)

观察时间位置、趋势和尺度上的差异；`se = TRUE` 加上由标准误得到的区间。区间重叠说明两个条件估计在这组数据上相近；一组数据给不出两种结构的一般排序。

<h2 id="mortality">5. 比较捕捞死亡率</h2>

```r
plot_compare_F(a, b)
```

![模拟 YTF：年龄别与体长别捕捞死亡率](../assets/manual/figures/ytf/compare_F.png)

ACL 按年龄估计捕捞死亡率，ALSCL 按体长估计，所以两个面板的单元格只在时间上对应。`plot_compare_F_ts()` 用最大值（`method = "apical"`，默认）或均值汇总每个时间步的各组；季度值仍按季度计。

<h2 id="save">6. 保存比较结果供复核</h2>

```r
dir.create("my_model_comparison", showWarnings = FALSE)
write.csv(comparison$summary, "my_model_comparison/summary.csv", row.names = FALSE)
write.csv(comparison$fit_metrics, "my_model_comparison/fit_metrics.csv", row.names = FALSE)
write.csv(comparison$fit_diagnostics, "my_model_comparison/fit_diagnostics.csv", row.names = FALSE)
p_population <- plot_compare_ts(a, b, quantities = c("B", "SSB", "Rec"), se = TRUE)
ggplot2::ggsave("my_model_comparison/population.png", p_population,
               width = 10, height = 7, dpi = 300)
saveRDS(list(inputs = inputs, fit_args = x$fit_args, fit_config = x$fit_config,
             comparison = comparison, ACL_report = a$report, ALSCL_report = b$report),
        "my_model_comparison/summary.rds")
writeLines(capture.output(sessionInfo()), "my_model_comparison/session.txt")
```

文件夹里有 CSV 表、种群图、装有输入、设置、比较结果和两个报告的 RDS 文件，以及会话信息。报告时一并写明时间窗、固定的生物学设置、零值的处理和对固定值的敏感性。

<h2 id="next">下一步</h2>

| 想做什么 | 阅读 |
|---|---|
| 绘制其他比较图 | [模型比较与真值](model-comparison.html) |
| 检查单个拟合的残差规律 | [判断拟合是否可用](diagnostics.html) |
| 去掉近期时间步后重新拟合 | [移除近期数据后，估计结果会怎样变化？](case-retrospective-bias.html) |
| 检验对 M 和 F 结构的敏感性 | [评估对假设有多敏感，未来 F 情景会怎样改变结果？](case-sensitivity-projection.html) |
| 对自己的数据表拟合两个模型 | [如何拟合自己的调查数据？](case-fit-survey.html) |
