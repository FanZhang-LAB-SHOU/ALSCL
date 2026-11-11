# 09 生长、死亡与残差图 · Growth, mortality and residuals

[← 上一章 · Previous](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/08-Population-Plots) · [目录 · Contents](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [下一章 · Next →](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/10-Model-Comparisons)

**ALSCL 2.4.3 · 简体中文 / English**

先完成第 04 章的 YTF 拟合，得到 `a`、`b`、`x`、`inputs`，并设置 `dat <- x$data.CatL`。加载 ggplot2 和 patchwork。第 11 章建立回溯对象 `ra/rb`。
First complete chapter 04, define `dat <- x$data.CatL`, and load ggplot2 and patchwork. Chapter 11 defines retrospective objects.

```r
library(ggplot2)
library(patchwork)
acl_theme_set(palette="npg", base_theme="theme_bw")
```

## 19. 生长曲线与区间 / Growth curve and interval

```r
# 绘制本图 / Draw this figure
plot_VB(b, se = TRUE)
```

[![生长曲线与区间 / Growth curve and interval](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/VB.png?raw=true&v=e2a1e504fa32)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/VB.png?raw=true&v=e2a1e504fa32)

von Bertalanffy 曲线给出图中 `Linf`、`k` 和 `t0` 对应的各年龄平均体长。`se = TRUE` 时，95% 区间反映这些参数的估计不确定性。本例固定了三个参数，因此区间宽度为零。同龄个体的体长差异见下方的年龄－体长转换矩阵。

The von Bertalanffy curve gives mean length at age for the displayed `Linf`, `k` and `t0`. With `se = TRUE`, the 95% band reflects uncertainty in those parameters. All three are fixed in this example, so the band has zero width. Variation in length among fish of the same age is shown separately in the length-at-age matrix below.

`age_range = NULL` 时绘制拟合的年龄范围，起点不早于 `t0`；显式 `age_range` 必须是两个递增的有限年龄，且不早于 `t0`。若 `se = TRUE` 但参数协方差不可用，函数会警告并只画曲线，保留传入的标签、字号、刻度和主题。

`age_range = NULL` draws the fitted age range, starting no earlier than `t0`; an explicit `age_range` must be two increasing finite ages at or after `t0`. If `se = TRUE` but the parameter covariance is unavailable, the function warns and draws the curve alone, keeping the labels, text sizes, breaks and theme you passed.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_VB)



## 20. 年龄—体长概率矩阵 / Age–length probability matrix

```r
# 绘制本图 / Draw this figure
plot_pla(b) + scale_x_discrete(labels = as.character(1:15))
```

[![年龄—体长概率矩阵 / Age–length probability matrix](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/pla.png?raw=true&v=3f17714c7721)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/pla.png?raw=true&v=3f17714c7721)

`pla` 的每一列表示一个年龄组的体长分布，列内概率之和为 1。颜色表示该年龄的个体落入各体长组的概率。对每个年龄组，最高体长组都包括超过最后一道体长分界的个体。横轴的 1 至 15 是年龄组序号。

Each column of `pla` gives the distribution of length for one age class and sums to one. The colour shows the probability of falling in each length bin. For every age, the last length bin includes the upper tail beyond the last length boundary. The horizontal labels 1 to 15 identify the age classes.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_pla)



## 21. ACL 各年龄组捕捞死亡率随时间的变化 / ACL fishing mortality over time by age class

`plot_fishing_mortality()` 从 `acl_theme_set()` 取标题、坐标轴标签、`x_breaks` 和 `x_expand`：标题键为 `F_year`、`F_age`、`F_length`，区间图加 `_se`；标签为 `xlab$year`、`xlab$age` 或 `xlab$length` 以及 `ylab$F`。年龄模式的横坐标是年龄组的位置，所以未设置 `xlab$age` 时默认标签为 Age group；调用中给出的标签和刻度优先。`base_theme` 接受 `"theme_bw"`、`"bw"` 等主题名、ggplot2 主题对象或 `NULL`（全局设置），各种情况下都不显示网格线。

`plot_fishing_mortality()` takes its title, axis labels, `x_breaks` and `x_expand` from `acl_theme_set()`: title keys `F_year`, `F_age` and `F_length`, with `_se` added for interval plots, and labels `xlab$year`, `xlab$age` or `xlab$length` and `ylab$F`. In age mode the horizontal coordinate is the position of the age class, so the default label reads Age group unless you set `xlab$age`; labels and breaks given in the call take precedence. `base_theme` accepts a theme name such as `"theme_bw"` or `"bw"`, a ggplot2 theme object, or `NULL` for the global setting, and gridlines stay hidden in every case.

```r
# 绘制本图 / Draw this figure
plot_fishing_mortality(a, type = "year",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ACL 各年龄组捕捞死亡率随时间的变化 / ACL fishing mortality over time by age class](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ACL_year.png?raw=true&v=12c599aa4391)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ACL_year.png?raw=true&v=12c599aa4391)

每个面板显示 ACL 一个年龄组的瞬时捕捞死亡率（`F`）及其近似 95% 区间。F 的时间单位由模型时间步决定，本例为一年，季度拟合则为一个季度。

Each panel shows the estimated instantaneous fishing mortality rate (`F`) for one ACL age class, with its approximate 95% interval. F is expressed per model time step. The time step is one year here and one quarter in a quarterly fit.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)



## 22. ACL 各期的年龄别捕捞死亡率 / ACL fishing mortality at age by time step

```r
# 绘制本图 / Draw this figure
plot_fishing_mortality(a, type = "age",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ACL 各期的年龄别捕捞死亡率 / ACL fishing mortality at age by time step](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ACL_age.png?raw=true&v=d94d92433096)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ACL_age.png?raw=true&v=d94d92433096)

每个面板显示 ACL 在一个时间步的估计值及其近似 95% 区间，横轴为年龄组序号。本例中曲线较平，表示该时间步各年龄组的估计捕捞死亡率相近。

Each panel shows the same ACL estimates for one time step, with age-class indices on the horizontal axis and approximate 95% intervals. The nearly flat profiles in this example indicate similar estimated fishing mortality across ages.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)



## 23. ALSCL 各体长组捕捞死亡率随时间的变化 / ALSCL fishing mortality over time by length bin

```r
# 绘制本图 / Draw this figure
plot_fishing_mortality(b, type = "year",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ALSCL 各体长组捕捞死亡率随时间的变化 / ALSCL fishing mortality over time by length bin](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_year.png?raw=true&v=098d37cae7d1)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_year.png?raw=true&v=098d37cae7d1)

每个面板显示一个体长组的捕捞死亡率（`FL`）随时间的变化及其近似 95% 区间。本例在 2008 年前后的高值以中等体长组最为明显。

Each panel shows how fishing mortality at length (`FL`) changes over time for one length bin, with an approximate 95% interval. The estimated peak around 2008 is most pronounced at intermediate lengths.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)



## 24. ALSCL 各期的年龄别捕捞死亡率 / ALSCL fishing mortality at age by time step

```r
# 绘制本图 / Draw this figure
plot_fishing_mortality(b, type = "age",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ALSCL 各期的年龄别捕捞死亡率 / ALSCL fishing mortality at age by time step](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_age.png?raw=true&v=80c608c9f9b8)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_age.png?raw=true&v=80c608c9f9b8)

ALSCL 先把同一年龄组各体长组的存活尾数相加，再除以该年龄组的期初尾数，得到存活比例。年龄别捕捞死亡率为 `FA = -log(存活比例) - M`。每个面板显示一个时间步的估计值和近似 95% 区间。`FA` 的输出不含最高年龄组和最后一个时间步。

For each age class, ALSCL sums the numbers surviving across length bins and divides by the number present at the start of the step. Fishing mortality at age is `FA = -log(survival proportion) - M`. Each panel shows the estimates and approximate 95% intervals for one time step. The oldest age class and the final time step are omitted from `FA`.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)



## 25. ALSCL 各期的体长别捕捞死亡率 / ALSCL fishing mortality at length by time step

```r
# 绘制本图 / Draw this figure
plot_fishing_mortality(b, type = "length",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ALSCL 各期的体长别捕捞死亡率 / ALSCL fishing mortality at length by time step](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_length.png?raw=true&v=2afc5a8f35d0)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_length.png?raw=true&v=2afc5a8f35d0)

每个面板显示一个时间步各体长组的捕捞死亡率及其近似 95% 区间。横轴按体长组中点（`len_mid`）的实际间距绘制。本例中，体长约 20 至 35 的组估计捕捞死亡率较高。

Each panel shows fishing mortality at length for one time step, with an approximate 95% interval. Length-bin midpoints (`len_mid`) are plotted at their actual spacing. In this example, estimated fishing mortality is higher at intermediate lengths, around 20 to 35.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)



## 26. 按体长组分面的对数残差 / Log residuals by length bin

```r
# 绘制本图 / Draw this figure
plot_residuals(b, facet_by = "length", facet_ncol = 4, line_size = 0.6,
  x_breaks = c(2000, 2010, 2015))
```

[![按体长组分面的对数残差 / Log residuals by length bin](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/residuals_length.png?raw=true&v=649d9ca9500a)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/residuals_length.png?raw=true&v=649d9ca9500a)

对数残差，即观测对数调查指数减拟合值，每个体长组一个面板，横轴为时间：深蓝线连接残差，灰线为零，青绿色虚线为平滑线。用它找模型拟合不好的体长组（零值和缺失观测没有残差）；多年同号的残差（如本例 16 组为正、20 组为负）说明系统性偏差，序列末端的趋势（如 50 组）提示模型没有跟上的变化。

每个分面内，缺失或排除的观测会断开残差线和趋势线。单个有效观测画成点。连续 2–5 个观测用直线拟合趋势，连续至少 6 个观测用 loess。

Log residuals, the observed minus the fitted log survey index, one panel per length bin with time on the horizontal axis: the navy line joins the residuals, the grey line is zero and the dashed teal curve is a smoother. Use it to find bins the model misfits (zero and missing observations have no residual); residuals of one sign over many years, as in bins 16 (positive) and 20 (negative) here, mean a systematic misfit, and a trend at the end of the series, as in bin 50, points to a change the model misses.

Within each facet, a missing or excluded observation breaks the residual line and its trend. A single observed value is drawn as a point. Each consecutive run of 2–5 observations has a linear trend, and a run of 6 or more uses loess.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_residuals)



## 27. 按时间步分面的对数残差 / Log residuals by time step

```r
# 绘制本图 / Draw this figure
plot_residuals(b, facet_by = "year", facet_ncol = 4, line_size = 0.6,
  x_breaks = c(10, 30, 50))
```

[![按时间步分面的对数残差 / Log residuals by time step](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/residuals_year.png?raw=true&v=d23449a96976)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/residuals_year.png?raw=true&v=d23449a96976)

同一组残差按体长排列：每个时间步一个面板，横轴为体长，带零线和平滑线。观察哪些体长范围的残差持续高于或低于零。本例 2015 年起最大体长组的正尖峰表示那几年的观测指数高于拟合值。重复出现的符号变化可提示偏差随体长变化；平滑线在某个体长穿过零线，本身不表示该体长存在偏差。

The same residuals arranged by length: one panel per time step, with length on the horizontal axis, a zero line and a smoother. Look for length ranges with residuals persistently above or below zero. The positive spikes in the largest bin from 2015 onward indicate observed indices above the fitted values in those years. Repeated changes in sign can suggest length-dependent misfit; the smoother crossing zero at a particular length is not itself evidence of bias at that length.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_residuals)



## 28. 补充量的对数偏差 / Log recruitment deviations

```r
# 绘制本图 / Draw this figure
plot_deviance(b, type = "R", log = TRUE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![补充量的对数偏差 / Log recruitment deviations](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_R_TRUE.png?raw=true&v=e16626d72746)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_R_TRUE.png?raw=true&v=e16626d72746)

点表示估计的补充量对数偏差，误差棒表示近似 95% 区间。对数偏差为零时，补充量等于拟合过程的中位数 `exp(mean_log_R)`。负值表示该期补充量低于这个中位数。

The points are estimated log recruitment deviations and the bars are approximate 95% intervals. Zero corresponds to the median recruitment of the fitted process, `exp(mean_log_R)`. A negative estimate indicates recruitment below that median.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_deviance)



## 29. 补充量相对于中位数的倍数 / Recruitment relative to the process median

```r
# 绘制本图 / Draw this figure
plot_deviance(b, type = "R", log = FALSE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![补充量相对于中位数的倍数 / Recruitment relative to the process median](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_R_FALSE.png?raw=true&v=f5ffcc3325be)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_R_FALSE.png?raw=true&v=f5ffcc3325be)

设置 `log = FALSE` 后，每个点表示该期补充量与过程中位数之比。2012 年的比值约为 1.7，表示估计补充量比中位数高约 70%。区间端点由对数尺度的端点取指数得到。

With `log = FALSE`, each point is recruitment divided by the process median. A ratio of 1.7, as in 2012, means that estimated recruitment was about 70% above that median. The interval endpoints are exponentiated from the log scale.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_deviance)



## 30. 捕捞死亡率的对数偏差 / Log fishing mortality deviations

```r
# 绘制本图 / Draw this figure
plot_deviance(b, type = "F", log = TRUE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![捕捞死亡率的对数偏差 / Log fishing mortality deviations](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_F_TRUE.png?raw=true&v=6168d9ff70db)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_F_TRUE.png?raw=true&v=6168d9ff70db)

点和近似 95% 区间表示各期捕捞死亡率的对数偏差。偏差为零对应原尺度上的过程中位数 `exp(mean_log_F)`。ALSCL 按体长组分面，ACL 按年龄组分面。各组共用 F 时只有一个面板。

Points and approximate 95% intervals show log fishing mortality deviations over time. Zero corresponds to the process median, `exp(mean_log_F)`, on the original scale. ALSCL shows one panel per length bin, ACL one per age class. A fit with shared F has one panel.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_deviance)



## 31. 捕捞死亡率相对于中位数的倍数 / Fishing mortality relative to the process median

```r
# 绘制本图 / Draw this figure
plot_deviance(b, type = "F", log = FALSE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![捕捞死亡率相对于中位数的倍数 / Fishing mortality relative to the process median](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_F_FALSE.png?raw=true&v=db5ced1d53d0)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_F_FALSE.png?raw=true&v=db5ced1d53d0)

每个点表示估计捕捞死亡率与过程中位数之比。比值为 0.5 表示该期该组的捕捞死亡率为中位数的一半。误差棒为对数尺度区间端点取指数后得到的近似 95% 区间。

Each point is the fitted fishing mortality rate divided by the process median. A ratio of 0.5 means fishing mortality was half that median. The error bars show the approximate 95% intervals after exponentiation.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_deviance)



## 32. 长度组成山脊图 / Length composition ridges

```r
# 绘制本图 / Draw this figure
plot_ridges(b) # 默认 viridis 渐变 / Default viridis gradient
```

[![长度组成山脊图 / Length composition ridges](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/ridges.png?raw=true&v=5be1df0903c5)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/ridges.png?raw=true&v=5be1df0903c5)

每条曲线表示一个时间步各体长组调查指数的相对组成，左图为观测值，右图为拟合值。2012 年之后，峰值向较大的体长组移动。可比较两图的峰值位置和分布宽度。某期全部缺测时不绘制该期的观测曲线，部分缺测时仅用有观测的体长组计算观测比例。

Each ridge shows the relative survey index across lengths in one time step, with observations on the left and the fit on the right. The peak shifts toward larger lengths after 2012. Compare the position and spread of the distributions. A step with no observations has no observed ridge, and a partially observed step is normalized over the observed bins only.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_ridges)



---

[← 上一章 · Previous](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/08-Population-Plots) · [目录 · Contents](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [下一章 · Next →](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/10-Model-Comparisons)
