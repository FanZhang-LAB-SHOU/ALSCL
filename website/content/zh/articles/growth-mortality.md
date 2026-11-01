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

生长参数在本例中固定，区间退化为曲线；释放参数后区间才反映估计不确定性，不是个体长度分布。

`age_range = NULL` 时，`plot_VB()` 使用拟合结果中的年龄范围；没有年龄元数据的旧结果从 1–25 岁开始。自动范围的起点不早于 `t0`，若没有正跨度则报错。显式范围必须为两个有限、递增的年龄，且起点不早于 `t0`，避免在生长曲线起点之前出现负体长和上下界倒置的区间。仍支持合法的显式范围，包括超出最老拟合年龄的外推。

曲线和区间均继承 `ylab$growth` 及所选字体。无论是否显示区间，都保留 Linf/k 标注，并遵守 `text_size`、`text_color`；显式 `ylab` 覆盖全局标签。如果 `se = TRUE` 但协方差不可用，会提示并仅绘制曲线，同时保留指定的标签、字号、刻度、基础主题和标注设置。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_VB)



## 年龄长度转换

```r
# 绘制本图
plot_pla(b) + scale_x_discrete(labels = as.character(1:15))
```

[![年龄长度转换](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/pla.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/pla.png?raw=true)

色值是长度组给定年龄的概率；不是增长转移矩阵 G。年龄标签为组序号。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_pla)



## ACL 捕捞死亡率 year

`plot_fishing_mortality()` 也继承全局标题、标签、`x_breaks` 与 `x_expand`。标题键为 `F_year`、`F_age`、`F_length`，区间版本加 `_se`；横轴分别使用 `xlab$year`、`xlab$age`、`xlab$length`，纵轴使用 `ylab$F`。年龄模式的坐标是组序号，因此未修改时默认标签仍为 “Age Group”，自定义的 `xlab$age` 则会生效。ACL 的旧 length 别名使用年龄模式设置。单次调用中显式指定的标签和刻度优先。`base_theme` 支持 `"theme_bw"`、`"bw"` 等名称、`ggplot2::theme_bw()` 等现有主题对象，或以 `NULL` 继承全局设置；这些形式均保持无主、次网格线。

```r
# 绘制本图
plot_fishing_mortality(a, type = "year",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ACL 捕捞死亡率 year](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ACL_year.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ACL_year.png?raw=true)

年度示例的 F 为每年瞬时率；季度数据得到每季度率。不同模型的原生 F 维度不同。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)



## ACL 捕捞死亡率 age

```r
# 绘制本图
plot_fishing_mortality(a, type = "age",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ACL 捕捞死亡率 age](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ACL_age.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ACL_age.png?raw=true)

年度示例的 F 为每年瞬时率；季度数据得到每季度率。不同模型的原生 F 维度不同。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)



## ALSCL 捕捞死亡率 year

```r
# 绘制本图
plot_fishing_mortality(b, type = "year",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ALSCL 捕捞死亡率 year](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_year.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_year.png?raw=true)

年度示例的 F 为每年瞬时率；季度数据得到每季度率。不同模型的原生 F 维度不同。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)



## ALSCL 捕捞死亡率 age

```r
# 绘制本图
plot_fishing_mortality(b, type = "age",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ALSCL 捕捞死亡率 age](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_age.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_age.png?raw=true)

年度示例的 F 为每年瞬时率；季度数据得到每季度率。不同模型的原生 F 维度不同。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)



## ALSCL 捕捞死亡率 length

2.2.3 的 `type = "length"` 以真实数值 `b$len_mid` 为横轴，每个时期一个面板；不等宽体长组保留实际横轴间距，置信带和误差棒与同一体长—时间单元对应。`type = "year"` 仍以时间为横轴、按体长组分面。

```r
# 绘制本图
plot_fishing_mortality(b, type = "length",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ALSCL 捕捞死亡率 length](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_length.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_length.png?raw=true)

年度示例的 F 为每年瞬时率；季度数据得到每季度率。不同模型的原生 F 维度不同。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)



## 对数残差 length

```r
# 绘制本图
plot_residuals(b, type = "length", facet_ncol = 4, line_size = 0.6,
  x_breaks = c(2000, 2010, 2015))
```

[![对数残差 length](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/residuals_length.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/residuals_length.png?raw=true)

观测对数减预测对数；未经标准差标准化。平滑线用于发现结构，不是显著性检验。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_residuals)



## 对数残差 year

```r
# 绘制本图
plot_residuals(b, type = "year", facet_ncol = 4, line_size = 0.6,
  x_breaks = c(10, 30, 50))
```

[![对数残差 year](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/residuals_year.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/residuals_year.png?raw=true)

观测对数减预测对数；未经标准差标准化。平滑线用于发现结构，不是显著性检验。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_residuals)



## 对数过程偏差 R

```r
# 绘制本图
plot_deviance(b, type = "R", log = TRUE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![对数过程偏差 R](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_R_TRUE.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_R_TRUE.png?raw=true)

对数过程偏差以 0 为参照。这不是似然偏差统计量。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_deviance)



## 过程乘数 R

```r
# 绘制本图
plot_deviance(b, type = "R", log = FALSE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![过程乘数 R](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_R_FALSE.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_R_FALSE.png?raw=true)

指数转换后以 1 为参照，区间不对称。这不是原尺度残差。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_deviance)



## 对数过程偏差 F

```r
# 绘制本图
plot_deviance(b, type = "F", log = TRUE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![对数过程偏差 F](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_F_TRUE.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_F_TRUE.png?raw=true)

对数过程偏差以 0 为参照。这不是似然偏差统计量。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_deviance)



## 过程乘数 F

```r
# 绘制本图
plot_deviance(b, type = "F", log = FALSE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![过程乘数 F](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_F_FALSE.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_F_FALSE.png?raw=true)

指数转换后以 1 为参照，区间不对称。这不是原尺度残差。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_deviance)



## 长度组成山脊图

```r
# 绘制本图
plot_ridges(b) # 默认 viridis 渐变
```

[![长度组成山脊图](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/ridges.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/ridges.png?raw=true)

每期分别归一化；左为观测，右为拟合。不能由此读出总丰度趋势。保留 observations 的保存结果无需活跃 obj。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_ridges)

## 2.2.4 的缺测与保存结果绘图

`plot_ridges()` 和 `plot_residuals()` 使用保存的 `observations`，保留与拟合一致的正观测掩码；旧结果可读取 TMB 数据。NA 和拟合时排除的零值不会变成人造观测或零残差。整期缺测不绘制观测山脊；部分缺测时，观测比例只在有效正观测中归一化，预测比例则覆盖全部体长组，不能把它解释为未观测组也拟合良好。保留 `observations` 的拟合结果移除 `obj` 后仍可使用这两个绘图函数。

```r
portable <- b
portable$obj <- NULL
plot_residuals(portable)
plot_ridges(portable)
```

### 2.2.7 的生长图设置

`plot_VB()` 在仅绘制曲线和绘制区间时均遵守 `ylab`。如果 `se = TRUE` 但协方差不可用，会提示并仅绘制曲线，同时保留指定的标签、字号、刻度、基础主题和标注设置。

```r
plot_VB(b, se = FALSE, ylab = "Length (cm)",
        axis_text_size = 12, x_breaks = c(1, 5, 10, 15),
        age_range = c(1, 15), text_size = 4)
```

### 一致性修正

捕捞死亡率图按矩阵位置和拟合年份、组别元数据构造坐标，矩阵行列名不会改变坐标。生物量、SSB、捕获量和 F 的年龄分面在有无区间时都按数值组序排列。F 图和时间序列比较在 `se = TRUE` 时要求完整、有限的估计与有限非负标准误；缺失摘要会报错，不再重复填充或静默取消区间。只画估计时请明确使用 `se = FALSE`。

每个分面按自身有效观测的不同横坐标数量选择趋势：少于 2 个不画平滑线，2–5 个使用线性趋势，至少 6 个使用 loess；需要时仅增加该分面的 span，以包含至少 5 个邻近点。稀疏尾部体长组不会删除或改变其他分面的趋势。

调查拟合图标题表示调查指数，山脊图标题表示调查体长组成，两者都不是渔业捕获量估计。过程偏差图在 `log = TRUE` 时标为对数偏差（参照值 0），在 `log = FALSE` 时标为乘数（参照值 1）。取指数只改变尺度，不改变已拟合的过程；两者都不是似然偏差统计量。
