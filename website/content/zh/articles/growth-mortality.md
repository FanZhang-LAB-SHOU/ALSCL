# 生长、死亡与残差图

先完成 [YTF 拟合示例](first-model.html)，得到 `a`、`b`、`x`、`inputs`，并设置 `dat <- x$data.CatL`。加载 ggplot2 和 patchwork。[回溯分析指南](retrospectives.html) 建立 `ra`、`rb`。

```r
library(ggplot2)
library(patchwork)
acl_theme_set(palette="npg", base_theme="theme_bw")
```

## 生长曲线与区间

```r
# 绘制本图
plot_VB(b, se = TRUE)
```

[![生长曲线与区间](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/VB.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/VB.png?raw=true)

由拟合的 `Linf`、`k`、`t0`（角上标注）得到的 von Bertalanffy 体长随年龄曲线；`se = TRUE` 时按参数协方差加上 95% 区间。本例生长参数固定，区间宽度为零；估计生长时区间表示年龄别平均体长的参数不确定性，不是个体体长的分布，老龄处区间很宽说明 `Linf` 难以确定。

`age_range = NULL` 时绘制拟合的年龄范围，起点不早于 `t0`；显式 `age_range` 必须是两个递增的有限年龄，且不早于 `t0`。若 `se = TRUE` 但参数协方差不可用，函数会警告并只画曲线，保留传入的标签、字号、刻度和主题。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_VB)

## 年龄长度转换

```r
# 绘制本图
plot_pla(b) + scale_x_discrete(labels = as.character(1:15))
```

[![年龄长度转换](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/pla.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/pla.png?raw=true)

年龄体长概率矩阵 `pla` 的热图：每列一个年龄组，每行一个体长组，颜色为该年龄的鱼落入该体长组的概率，每列之和为 1；代码把横轴改标为年龄组序号 1 至 15。用它看体长对年龄的区分度；对角带随年龄变宽是因为生长放慢、体长重叠，老龄在最大体长组的深色格是聚集所有老鱼的加和组。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_pla)

## ACL 捕捞死亡率 year

`plot_fishing_mortality()` 从 `acl_theme_set()` 取标题、坐标轴标签、`x_breaks` 和 `x_expand`：标题键为 `F_year`、`F_age`、`F_length`，区间图加 `_se`；标签为 `xlab$year`、`xlab$age` 或 `xlab$length` 以及 `ylab$F`。年龄模式的横坐标是年龄组的位置，所以未设置 `xlab$age` 时默认标签为 Age Group；调用中给出的标签和刻度优先。`base_theme` 接受 `"theme_bw"`、`"bw"` 等主题名、ggplot2 主题对象或 `NULL`（全局设置），各种情况下都不显示网格线。

```r
# 绘制本图
plot_fishing_mortality(a, type = "year",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ACL 捕捞死亡率 year](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ACL_year.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ACL_year.png?raw=true)

ACL 拟合的捕捞死亡率 `F`，每个年龄组一个面板，横轴为时间，带 95% 区间（`se = TRUE`）；`F` 是每个时间步的瞬时率，季度拟合显示的是季度率。用它看捕捞压力何时变化：本例 2008 年的峰出现在大多数年龄组，13 至 15 龄的宽区间说明调查对老龄鱼的信息很少。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)

## ACL 捕捞死亡率 age

```r
# 绘制本图
plot_fishing_mortality(a, type = "age",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ACL 捕捞死亡率 age](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ACL_age.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ACL_age.png?raw=true)

同一组 `F` 按年龄排列：每个时间步一个面板，横轴为年龄组序号（标为 Age group，因为坐标是组的位置），带 95% 区间。用它读每个时间步渔业的选择模式；本例近乎水平的线说明 ACL 拟合对各年龄施加相近的死亡率，若呈穹形或斜坡则显示渔具主要捕哪些年龄。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)

## ALSCL 捕捞死亡率 year

```r
# 绘制本图
plot_fishing_mortality(b, type = "year",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ALSCL 捕捞死亡率 year](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_year.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_year.png?raw=true)

ALSCL 拟合的体长别捕捞死亡率 `FL`，每个体长组一个面板，横轴为时间，带 95% 区间。用它看各体长组的捕捞压力何时变化；本例 2008 年的峰在 20 至 34 组最强，44 以上各组的 F 最低，因为该体长的鱼很少被捕。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)

## ALSCL 捕捞死亡率 age

```r
# 绘制本图
plot_fishing_mortality(b, type = "age",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ALSCL 捕捞死亡率 age](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_age.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_age.png?raw=true)

ALSCL 拟合的年龄别捕捞死亡率 `FA`，由 `FL` 经年龄体长矩阵换算：每个时间步一个面板，横轴为年龄组序号，带 95% 区间；`FA` 在相邻时间步之间计算，所以比体长图少一个时间步和一个年龄。用它与 ACL 的年龄图比较选择模式；本例在 3 龄达到峰值的穹形，就是体长别 F 映射到对应年龄后的结果。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)

## ALSCL 捕捞死亡率 length

```r
# 绘制本图
plot_fishing_mortality(b, type = "length",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ALSCL 捕捞死亡率 length](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_length.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_length.png?raw=true)

同一组 `FL` 按体长排列：每个时间步一个面板，横轴为体长组中点 `len_mid`（不等宽组表现为不等间距），带 95% 区间。用它读每个时间步渔业的体长选择；本例 20 至 35 之间的穹形是渔具捕捞的体长范围，各面板穹形的高低就是时间效应。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)

## 对数残差 length

```r
# 绘制本图
plot_residuals(b, facet_by = "length", facet_ncol = 4, line_size = 0.6,
  x_breaks = c(2000, 2010, 2015))
```

[![对数残差 length](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/residuals_length.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/residuals_length.png?raw=true)

对数残差，即观测对数调查指数减拟合值，每个体长组一个面板，横轴为时间：深蓝线连接残差，灰线为零，青绿色虚线为平滑线（有观测的时间步少于 6 个时用线性，否则用 loess）。用它找模型拟合不好的体长组（零值和缺失观测没有残差）；多年同号的残差（如本例 16 组为正、20 组为负）说明系统性偏差，序列末端的趋势（如 50 组）提示模型没有跟上的变化。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_residuals)

## 对数残差 year

```r
# 绘制本图
plot_residuals(b, facet_by = "year", facet_ncol = 4, line_size = 0.6,
  x_breaks = c(10, 30, 50))
```

[![对数残差 year](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/residuals_year.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/residuals_year.png?raw=true)

同一组残差按体长排列：每个时间步一个面板，横轴为体长，带零线和平滑线。用它看一个时间步内的偏差是否随体长变化；本例 2015 年起最大体长组的正尖峰说明那几年调查看到的大鱼多于拟合，平滑线每年在同一体长穿过零线则是模型系统性放错的体长。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_residuals)

## 对数过程偏差 R

```r
# 绘制本图
plot_deviance(b, type = "R", log = TRUE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![对数过程偏差 R](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_R_TRUE.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_R_TRUE.png?raw=true)

补充量的对数过程偏差（模型的随机效应，不是似然偏差）随时间步变化：点为估计值，误差棒为 95% 区间，零对应平均补充量。用它看调查支持的年级群信号；本例 2000 至 2008 年的连续负值是低于平均的补充量，若误差棒都跨过零线，说明调查几乎没有补充量信息。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_deviance)

## 过程乘数 R

```r
# 绘制本图
plot_deviance(b, type = "R", log = FALSE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![过程乘数 R](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_R_FALSE.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_R_FALSE.png?raw=true)

同一组偏差取指数（`log = FALSE`）：纵轴为补充量乘数，1 对应平均值，区间不对称，因为它们是对数区间取指数的结果。用它把偏差读成倍数；本例 2012 年约 1.7 表示补充量高于平均 70%，它与对数图是同一拟合过程，按读者要读取的量选择尺度。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_deviance)

## 对数过程偏差 F

```r
# 绘制本图
plot_deviance(b, type = "F", log = TRUE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![对数过程偏差 F](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_F_TRUE.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_F_TRUE.png?raw=true)

捕捞死亡率的对数过程偏差，每个体长组一个面板（ACL 为每个年龄组，共享 F 时只有一个面板），点、95% 误差棒和作为平均值的零线。用它看拟合的 F 在各组、各时间步偏离平均的程度；本例小、中体长组为正，40 以上为负，即模型抬高了 40 以下的 F、压低了 40 以上的 F，36 至 50 组在 2012 年前后的下陷与 F 图中该处的低值一致。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_deviance)

## 过程乘数 F

```r
# 绘制本图
plot_deviance(b, type = "F", log = FALSE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![过程乘数 F](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_F_FALSE.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_F_FALSE.png?raw=true)

同一组 F 偏差改为乘数（`log = FALSE`），1 为平均值，区间不对称。用它把偏离读成 F 的倍数；本例 48 组 2012 年前后约 0.5 表示 F 为平均值的一半，区间宽窄与对数尺度对应，两张图对哪些格不确定的判断一致。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_deviance)

## 长度组成山脊图

```r
# 绘制本图
plot_ridges(b) # 默认 viridis 渐变
```

[![长度组成山脊图](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/ridges.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/ridges.png?raw=true)

调查指数的体长组成，每个时间步一条山脊（最早在底部，颜色按时间步取 viridis 渐变），横轴为体长：左图为观测，右图为拟合，每条山脊归一化为和为 1，所以高度只比较形状。用它检查拟合是否再现每个时间步的峰位和展布；本例 2012 年后峰从 20 向 25 移动是强年级群在生长，没有调查数据的时间步没有观测山脊，部分观测的时间步只在有观测的体长组内归一化。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_ridges)
