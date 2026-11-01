# 09 生长、死亡与残差图 · Growth, mortality and residuals

[← 上一章 · Previous](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/08-Population-Plots) · [目录 · Contents](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [下一章 · Next →](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/10-Model-Comparisons)

**ALSCL 2.3.0 · 简体中文 / English**

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

[![生长曲线与区间 / Growth curve and interval](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/VB.png?raw=true&v=6dcfc65cbadd)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/VB.png?raw=true&v=6dcfc65cbadd)

由拟合的 `Linf`、`k`、`t0`（角上标注）得到的 von Bertalanffy 体长随年龄曲线；`se = TRUE` 时按参数协方差加上 95% 区间。本例生长参数固定，区间宽度为零；估计生长时区间表示年龄别平均体长的参数不确定性，不是个体体长的分布，老龄处区间很宽说明 `Linf` 难以确定。

The von Bertalanffy curve of length against age from the fitted `Linf`, `k` and `t0` (printed in the corner); `se = TRUE` adds a 95% band from the parameter covariance. Growth is fixed in this example, so the band has zero width; with estimated growth the band is parameter uncertainty about the mean length at age, not the spread of individual lengths, and a wide band at old ages means `Linf` is poorly determined.

`age_range = NULL` 时绘制拟合的年龄范围，起点不早于 `t0`；显式 `age_range` 必须是两个递增的有限年龄，且不早于 `t0`。若 `se = TRUE` 但参数协方差不可用，函数会警告并只画曲线，保留传入的标签、字号、刻度和主题。

`age_range = NULL` draws the fitted age range, starting no earlier than `t0`; an explicit `age_range` must be two increasing finite ages at or after `t0`. If `se = TRUE` but the parameter covariance is unavailable, the function warns and draws the curve alone, keeping the labels, text sizes, breaks and theme you passed.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_VB)



## 20. 年龄—体长概率矩阵 / Age–length probability matrix

```r
# 绘制本图 / Draw this figure
plot_pla(b) + scale_x_discrete(labels = as.character(1:15))
```

[![年龄—体长概率矩阵 / Age–length probability matrix](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/pla.png?raw=true&v=ef5002aab224)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/pla.png?raw=true&v=ef5002aab224)

年龄体长概率矩阵 `pla` 的热图：每列一个年龄组，每行一个体长组，颜色为该年龄的鱼落入该体长组的概率，每列之和为 1；代码把横轴改标为年龄组序号 1 至 15。用它看体长对年龄的区分度；对角带随年龄变宽是因为生长放慢、体长重叠，老龄在最大体长组的深色格是聚集所有老鱼的加和组。

A heat map of the age length probability matrix `pla`: one column per age class, one row per length bin, and the fill is the probability that a fish of that age falls in that bin, so each column sums to one; the code relabels the age axis with the class index 1 to 15. Use it to see how well length identifies age; the diagonal band widens with age because growth slows and lengths overlap, and the dark cells in the largest bin at old ages are the plus group collecting all old fish.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_pla)



## 21. ACL 捕捞死亡率 year / ACL fishing mortality year

`plot_fishing_mortality()` 从 `acl_theme_set()` 取标题、坐标轴标签、`x_breaks` 和 `x_expand`：标题键为 `F_year`、`F_age`、`F_length`，区间图加 `_se`；标签为 `xlab$year`、`xlab$age` 或 `xlab$length` 以及 `ylab$F`。年龄模式的横坐标是年龄组的位置，所以未设置 `xlab$age` 时默认标签为 Age Group；调用中给出的标签和刻度优先。`base_theme` 接受 `"theme_bw"`、`"bw"` 等主题名、ggplot2 主题对象或 `NULL`（全局设置），各种情况下都不显示网格线。

`plot_fishing_mortality()` takes its title, axis labels, `x_breaks` and `x_expand` from `acl_theme_set()`: title keys `F_year`, `F_age` and `F_length`, with `_se` added for interval plots, and labels `xlab$year`, `xlab$age` or `xlab$length` and `ylab$F`. In age mode the horizontal coordinate is the position of the age class, so the default label reads Age Group unless you set `xlab$age`; labels and breaks given in the call take precedence. `base_theme` accepts a theme name such as `"theme_bw"` or `"bw"`, a ggplot2 theme object, or `NULL` for the global setting, and gridlines stay hidden in every case.

```r
# 绘制本图 / Draw this figure
plot_fishing_mortality(a, type = "year",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ACL 捕捞死亡率 year / ACL fishing mortality year](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ACL_year.png?raw=true&v=6459bbc874c9)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ACL_year.png?raw=true&v=6459bbc874c9)

ACL 拟合的捕捞死亡率 `F`，每个年龄组一个面板，横轴为时间，带 95% 区间（`se = TRUE`）；`F` 是每个时间步的瞬时率，季度拟合显示的是季度率。用它看捕捞压力何时变化：本例 2008 年的峰出现在大多数年龄组，13 至 15 龄的宽区间说明调查对老龄鱼的信息很少。

Fishing mortality `F` of the ACL fit, one panel per age class, time on the horizontal axis and the 95% band (`se = TRUE`); `F` is an instantaneous rate per time step, so a quarterly fit shows quarterly rates. Use it to see when fishing pressure changed: the 2008 peak here appears in most age classes, and the wide bands at ages 13 to 15 show how little the survey says about old fish.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)



## 22. ACL 捕捞死亡率 age / ACL fishing mortality age

```r
# 绘制本图 / Draw this figure
plot_fishing_mortality(a, type = "age",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ACL 捕捞死亡率 age / ACL fishing mortality age](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ACL_age.png?raw=true&v=fdd297ac4b33)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ACL_age.png?raw=true&v=fdd297ac4b33)

同一组 `F` 按年龄排列：每个时间步一个面板，横轴为年龄组序号（标为 Age Group，因为坐标是组的位置），带 95% 区间。用它读每个时间步渔业的选择模式；本例近乎水平的线说明 ACL 拟合对各年龄施加相近的死亡率，若呈穹形或斜坡则显示渔具主要捕哪些年龄。

The same `F` values arranged by age: one panel per time step, the age class index on the horizontal axis (labelled Age Group because the coordinate is the class position), with the 95% band. Use it to read the selection pattern of the fishery at each time step; a flat line, as here, means the ACL fit applies similar mortality to all ages, and a dome or ramp would show which ages the gear takes.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)



## 23. ALSCL 捕捞死亡率 year / ALSCL fishing mortality year

```r
# 绘制本图 / Draw this figure
plot_fishing_mortality(b, type = "year",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ALSCL 捕捞死亡率 year / ALSCL fishing mortality year](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_year.png?raw=true&v=8cc56a095b67)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_year.png?raw=true&v=8cc56a095b67)

ALSCL 拟合的体长别捕捞死亡率 `FL`，每个体长组一个面板，横轴为时间，带 95% 区间。用它看各体长组的捕捞压力何时变化；本例 2008 年的峰在 20 至 34 组最强，44 以上各组的 F 最低，因为该体长的鱼很少被捕。

Fishing mortality at length `FL` of the ALSCL fit, one panel per length bin, time on the horizontal axis and the 95% band. Use it to see when pressure changed in each length bin; the 2008 peak is strongest in bins 20 to 34 here, and the bins above 44 have the lowest F because few fish of that size are taken.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)



## 24. ALSCL 捕捞死亡率 age / ALSCL fishing mortality age

```r
# 绘制本图 / Draw this figure
plot_fishing_mortality(b, type = "age",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ALSCL 捕捞死亡率 age / ALSCL fishing mortality age](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_age.png?raw=true&v=0c7d455f97cc)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_age.png?raw=true&v=0c7d455f97cc)

ALSCL 拟合的年龄别捕捞死亡率 `FA`，由 `FL` 经年龄体长矩阵换算：每个时间步一个面板，横轴为年龄组序号，带 95% 区间；`FA` 在相邻时间步之间计算，所以比体长图少一个时间步和一个年龄。用它与 ACL 的年龄图比较选择模式；本例在 3 龄达到峰值的穹形，就是体长别 F 映射到对应年龄后的结果。

Fishing mortality at age `FA` of the ALSCL fit, derived from `FL` through the age length matrix: one panel per time step, the age class index on the horizontal axis, with the 95% band; there is one time step and one age fewer than in the length figures because `FA` is computed between consecutive steps. Use it to compare the ALSCL selection with the ACL age figure; the dome peaking at age 3 here is the length-based F mapped onto the ages that have those lengths.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)



## 25. ALSCL 捕捞死亡率 length / ALSCL fishing mortality length

```r
# 绘制本图 / Draw this figure
plot_fishing_mortality(b, type = "length",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ALSCL 捕捞死亡率 length / ALSCL fishing mortality length](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_length.png?raw=true&v=3e7b72988619)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_length.png?raw=true&v=3e7b72988619)

同一组 `FL` 按体长排列：每个时间步一个面板，横轴为体长组中点 `len_mid`（不等宽组表现为不等间距），带 95% 区间。用它读每个时间步渔业的体长选择；本例 20 至 35 之间的穹形是渔具捕捞的体长范围，各面板穹形的高低就是时间效应。

The same `FL` values arranged by length: one panel per time step, the length bin midpoints `len_mid` on the horizontal axis (unequal bins show as unequal spacing), with the 95% band. Use it to read the length selection of the fishery at each time step; the dome between lengths 20 and 35 here is the size the gear takes, and its height from panel to panel is the time effect.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)



## 26. 对数残差 length / Log residuals length

```r
# 绘制本图 / Draw this figure
plot_residuals(b, type = "length", facet_ncol = 4, line_size = 0.6,
  x_breaks = c(2000, 2010, 2015))
```

[![对数残差 length / Log residuals length](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/residuals_length.png?raw=true&v=b5821541998b)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/residuals_length.png?raw=true&v=b5821541998b)

对数残差，即观测对数调查指数减拟合值，每个体长组一个面板，横轴为时间：深蓝线连接残差，灰线为零，青绿色虚线为平滑线（有观测的时间步少于 6 个时用线性，否则用 loess）。用它找模型拟合不好的体长组（零值和缺失观测没有残差）；多年同号的残差（如本例 16 组为正、20 组为负）说明系统性偏差，序列末端的趋势（如 50 组）提示模型没有跟上的变化。

Log residuals, the observed minus the fitted log survey index, one panel per length bin with time on the horizontal axis: the navy line joins the residuals, the grey line is zero and the dashed teal curve is a smoother (linear with fewer than six observed time steps, loess otherwise). Use it to find bins the model misfits (zero and missing observations have no residual); residuals of one sign over many years, as in bins 16 (positive) and 20 (negative) here, mean a systematic misfit, and a trend at the end of the series, as in bin 50, points to a change the model misses.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_residuals)



## 27. 对数残差 year / Log residuals year

```r
# 绘制本图 / Draw this figure
plot_residuals(b, type = "year", facet_ncol = 4, line_size = 0.6,
  x_breaks = c(10, 30, 50))
```

[![对数残差 year / Log residuals year](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/residuals_year.png?raw=true&v=33d40c01318a)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/residuals_year.png?raw=true&v=33d40c01318a)

同一组残差按体长排列：每个时间步一个面板，横轴为体长，带零线和平滑线。用它看一个时间步内的偏差是否随体长变化；本例 2015 年起最大体长组的正尖峰说明那几年调查看到的大鱼多于拟合，平滑线每年在同一体长穿过零线则是模型系统性放错的体长。

The same residuals arranged by length: one panel per time step, length on the horizontal axis, with the zero line and the smoother. Use it to see whether misfit has a length pattern within a time step; the positive spike at the largest bin from 2015 on here means the survey saw more large fish than the fit in those years, and a smoother that crosses zero at the same length every year marks a length the model systematically misplaces.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_residuals)



## 28. 对数过程偏差 R / Log process deviations R

```r
# 绘制本图 / Draw this figure
plot_deviance(b, type = "R", log = TRUE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![对数过程偏差 R / Log process deviations R](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_R_TRUE.png?raw=true&v=a9db81d17a07)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_R_TRUE.png?raw=true&v=a9db81d17a07)

补充量的对数过程偏差（模型的随机效应，不是似然偏差）随时间步变化：点为估计值，误差棒为 95% 区间，零对应平均补充量。用它看调查支持的年级群信号；本例 2000 至 2008 年的连续负值是低于平均的补充量，若误差棒都跨过零线，说明调查几乎没有补充量信息。

Log process deviations of recruitment (the random effects of the model, not a likelihood deviance) by time step: points are the estimates, the error bars their 95% intervals, and zero is mean recruitment. Use it to see the year-class signal the survey supports; the negative run from 2000 to 2008 here is below-average recruitment, and error bars that all cross zero would mean the survey carries little recruitment information.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_deviance)



## 29. 过程乘数 R / Process multipliers R

```r
# 绘制本图 / Draw this figure
plot_deviance(b, type = "R", log = FALSE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![过程乘数 R / Process multipliers R](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_R_FALSE.png?raw=true&v=59993ea53790)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_R_FALSE.png?raw=true&v=59993ea53790)

同一组偏差取指数（`log = FALSE`）：纵轴为补充量乘数，1 对应平均值，区间不对称，因为它们是对数区间取指数的结果。用它把偏差读成倍数；本例 2012 年约 1.7 表示补充量高于平均 70%，它与对数图是同一拟合过程，按读者要读取的量选择尺度。

The same deviations exponentiated (`log = FALSE`): the vertical axis is the recruitment multiplier, one is the mean, and the intervals are asymmetric because they are exponentiated log intervals. Use it to read a deviation as a factor; the 2012 value of about 1.7 here means recruitment 70% above the mean, and it is the same fitted process as the log figure, so choose the scale by what the reader needs to read off.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_deviance)



## 30. 对数过程偏差 F / Log process deviations F

```r
# 绘制本图 / Draw this figure
plot_deviance(b, type = "F", log = TRUE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![对数过程偏差 F / Log process deviations F](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_F_TRUE.png?raw=true&v=da77cce5c3aa)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_F_TRUE.png?raw=true&v=da77cce5c3aa)

捕捞死亡率的对数过程偏差，每个体长组一个面板（ACL 为每个年龄组，共享 F 时只有一个面板），点、95% 误差棒和作为平均值的零线。用它看拟合的 F 在各组、各时间步偏离平均的程度；本例小、中体长组为正，40 以上为负，即模型抬高了 40 以下的 F、压低了 40 以上的 F，36 至 50 组在 2012 年前后的下陷与 F 图中该处的低值一致。

Log process deviations of fishing mortality, one panel per length bin (per age class for ACL, a single panel for a shared F), with points, 95% error bars and zero as the mean. Use it to see how the fitted F departs from its mean in each bin and time step; here the deviations are positive in the small and middle bins and negative above length 40, so the model raises F below 40 and lowers it above, and the dip around 2012 in bins 36 to 50 matches the low F there in the F figures.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_deviance)



## 31. 过程乘数 F / Process multipliers F

```r
# 绘制本图 / Draw this figure
plot_deviance(b, type = "F", log = FALSE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![过程乘数 F / Process multipliers F](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_F_FALSE.png?raw=true&v=069999ae5a7e)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_F_FALSE.png?raw=true&v=069999ae5a7e)

同一组 F 偏差改为乘数（`log = FALSE`），1 为平均值，区间不对称。用它把偏离读成 F 的倍数；本例 48 组 2012 年前后约 0.5 表示 F 为平均值的一半，区间宽窄与对数尺度对应，两张图对哪些格不确定的判断一致。

The same F deviations as multipliers (`log = FALSE`), with one as the mean and asymmetric intervals. Use it to read the departure as a factor on F; a value of 0.5 in bin 48 around 2012 here means F at half its mean, and the interval widths carry over from the log scale, so the two figures agree on which cells are uncertain.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_deviance)



## 32. 长度组成山脊图 / Length composition ridges

```r
# 绘制本图 / Draw this figure
plot_ridges(b) # 默认 viridis 渐变 / Default viridis gradient
```

[![长度组成山脊图 / Length composition ridges](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/ridges.png?raw=true&v=0e54771c9642)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/ridges.png?raw=true&v=0e54771c9642)

调查指数的体长组成，每个时间步一条山脊（最早在底部，颜色按时间步取 viridis 渐变），横轴为体长：左图为观测，右图为拟合，每条山脊归一化为和为 1，所以高度只比较形状。用它检查拟合是否再现每个时间步的峰位和展布；本例 2012 年后峰从 20 向 25 移动是强年级群在生长，没有调查数据的时间步没有观测山脊，部分观测的时间步只在有观测的体长组内归一化。

Length compositions of the survey index, one ridge per time step (earliest at the bottom, colour by time step from the viridis gradient) with length on the horizontal axis: the left panel is observed, the right panel fitted, and each ridge is normalized to sum to one, so ridge height compares shape only. Use it to check that the fit reproduces the mode and spread of each time step; the mode moving from length 20 toward 25 after 2012 here is the strong cohort growing, a time step without survey data has no observed ridge, and a partly observed time step is normalized over the observed bins only.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_ridges)



---

[← 上一章 · Previous](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/08-Population-Plots) · [目录 · Contents](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [下一章 · Next →](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/10-Model-Comparisons)
