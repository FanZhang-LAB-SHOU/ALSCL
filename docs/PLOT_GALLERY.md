# YTF 绘图图谱 · YTF plot gallery

**44 张图，覆盖 22 个公开绘图函数及主要类型。44 figures covering all 22 public plotting functions and major variants.**

另附单点估计与缺测绘图示例。 / Additional examples show single estimates and missing observations.

全部 44 张图使用当前绘图函数从内置教学拟合生成，默认不显示网格线；BL/SBL 图包含可用的近似 95% 区间。 / All 44 figures are drawn with the current plotting functions from the built-in teaching fits; the defaults show no gridlines, and the BL/SBL figures include the available approximate 95% intervals.

[使用指南 / Guide](USER_GUIDE.md) · [完整参数 / API](FUNCTION_REFERENCE.md) · [可运行脚本 / R workflow](../scripts/ytf_workflow.R)

先运行[指南第 4 节](USER_GUIDE.md#builtin)，得到输入列表 `x` 和拟合结果 `a`、`b`；再定义 `dat <- x$data.CatL`，并加载 `ggplot2`、`patchwork`。回溯图使用[指南第 8 节](USER_GUIDE.md#retrospective)的 `ra` 和 `rb`。全部图来自同一个模拟 YTF 数据和固定部分生物参数的条件拟合。

Run [section 4 of the guide](USER_GUIDE.md#builtin) to create the input bundle `x` and the fits `a` and `b`. Then define `dat <- x$data.CatL` and load ggplot2 and patchwork. Retrospective plots use `ra` and `rb` from [section 8](USER_GUIDE.md#retrospective). Every fit uses the same synthetic YTF data and conditional fixed-biology settings.

代码中的额外主题、刻度及组合布局仅调整显示。图像可点击放大；保存时建议宽 11 英寸、多分面高 8.5 英寸。 / Extra theme, scale and layout calls affect presentation only. Click figures to enlarge; use wide output for multi-panel figures.

```r
# 全图共用主题 / Shared gallery theme
acl_theme_set(base_theme="bw", font_family="sans", title_size=12,
  axis_title_size=10, axis_text_size=9, strip_text_size=9,
  palette="npg")
```

## 图目录 / Figure index

- [1. 各体长组的调查指数（对数尺度） / Survey index by length bin (log scale)](#CatL_length_FALSE)
- [2. 各体长组的调查指数（原尺度） / Survey index by length bin (original scale)](#CatL_length_TRUE)
- [3. 各时间步的调查指数（对数尺度） / Survey index by time step (log scale)](#CatL_year_FALSE)
- [4. 各时间步的调查指数（原尺度） / Survey index by time step (original scale)](#CatL_year_TRUE)
- [5. 丰度 N / Abundance N](#plot_abundance_N)
- [6. 丰度 NA / Abundance NA](#plot_abundance_NA)
- [7. 丰度 NL / Abundance NL](#plot_abundance_NL)
- [8. 生物量 B / Biomass B](#plot_biomass_B)
- [9. 生物量 BA / Biomass BA](#plot_biomass_BA)
- [10. 生物量 BL / Biomass BL](#plot_biomass_BL)
- [11. 产卵生物量 SSB / Spawning biomass SSB](#plot_SSB_SSB)
- [12. 产卵生物量 SBA / Spawning biomass SBA](#plot_SSB_SBA)
- [13. 产卵生物量 SBL / Spawning biomass SBL](#plot_SSB_SBL)
- [14. 捕获尾数 CN / Catch numbers CN](#plot_catch_CN)
- [15. 捕获尾数 CNA / Catch numbers CNA](#plot_catch_CNA)
- [16. 捕获尾数 CNL / Catch numbers CNL](#plot_catch_CNL)
- [17. 补充量 / Recruitment](#recruitment)
- [18. 亲体与补充关系 / Spawning biomass and recruitment](#SSB_Rec)
- [19. 生长曲线与区间 / Growth curve and interval](#VB)
- [20. 年龄—体长概率矩阵 / Age–length probability matrix](#pla)
- [21. ACL 各年龄组捕捞死亡率随时间的变化 / ACL fishing mortality over time by age class](#F_ACL_year)
- [22. ACL 各期的年龄别捕捞死亡率 / ACL fishing mortality at age by time step](#F_ACL_age)
- [23. ALSCL 各体长组捕捞死亡率随时间的变化 / ALSCL fishing mortality over time by length bin](#F_ALSCL_year)
- [24. ALSCL 各期的年龄别捕捞死亡率 / ALSCL fishing mortality at age by time step](#F_ALSCL_age)
- [25. ALSCL 各期的体长别捕捞死亡率 / ALSCL fishing mortality at length by time step](#F_ALSCL_length)
- [26. 按体长组分面的对数残差 / Log residuals by length bin](#residuals_length)
- [27. 按时间步分面的对数残差 / Log residuals by time step](#residuals_year)
- [28. 补充量的对数偏差 / Log recruitment deviations](#deviation_R_TRUE)
- [29. 补充量相对于中位数的倍数 / Recruitment relative to the process median](#deviation_R_FALSE)
- [30. 捕捞死亡率的对数偏差 / Log fishing mortality deviations](#deviation_F_TRUE)
- [31. 捕捞死亡率相对于中位数的倍数 / Fishing mortality relative to the process median](#deviation_F_FALSE)
- [32. 长度组成山脊图 / Length composition ridges](#ridges)
- [33. 种群时间序列比较 / Population time series comparison](#compare_ts)
- [34. 死亡率矩阵比较 / Fishing mortality matrices](#compare_F)
- [35. 残差联合诊断 / Combined residual diagnostics](#compare_residuals)
- [36. 生长与外部参照接口 / Growth and reference-data interface](#compare_growth)
- [37. 两模型调查拟合 / Survey fits from both models](#compare_CatL)
- [38. 拟合指标比较 / Fit metric comparison](#compare_metrics)
- [39. 固定调查可捕性 / Fixed survey catchability](#compare_selectivity)
- [40. 每个时间步的最大捕捞死亡率 / Maximum fishing mortality by time step](#compare_F_apical)
- [41. 每个时间步的平均捕捞死亡率 / Mean fishing mortality by time step](#compare_F_mean)
- [42. ACL 回溯分析 / ACL retrospective analysis](#retro_ACL)
- [43. ALSCL 回溯分析 / ALSCL retrospective analysis](#retro_ALSCL)
- [44. 模拟真值与条件估计 / Simulation truth and conditional estimates](#truth)

<a id="plot_CatL"></a>

<a id="CatL_length_FALSE"></a>
## 1. 各体长组的调查指数（对数尺度） / Survey index by length bin (log scale)

```r
# 绘制本图 / Draw this figure
plot_CatL(b, facet_by = "length", exp_transform = FALSE, facet_ncol = 4,
  point_size = 1, line_size = 0.6,
  x_breaks = c(2000, 2010, 2015),
  ylab = "Log survey index")
```

[![各体长组的调查指数（对数尺度） / Survey index by length bin (log scale)](figures/ytf/CatL_length_FALSE.png)](figures/ytf/CatL_length_FALSE.png)

每个体长组一个面板，横轴为时间，纵轴为对数调查指数：朱红色点为观测的对数指数，深蓝色曲线为拟合的 `Elog_index`。用它逐组检查拟合；点连续偏在曲线一侧（如本例的 16 组和 50 组）说明该组被系统低估或高估，对数尺度让大小体长组的偏离同样可读。

One panel per length bin, time on the horizontal axis and the log survey index on the vertical axis: vermilion points are the observed log index and the navy curve is the fitted `Elog_index`. Use it to judge the fit bin by bin; a run of points on one side of the curve, as in bins 16 and 50 here, marks a bin the model under- or over-predicts, and the log scale shows this equally well in small and large bins.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_CatL)

<a id="CatL_length_TRUE"></a>
## 2. 各体长组的调查指数（原尺度） / Survey index by length bin (original scale)

```r
# 绘制本图 / Draw this figure
plot_CatL(b, facet_by = "length", exp_transform = TRUE, facet_ncol = 4,
  point_size = 1, line_size = 0.6,
  x_breaks = c(2000, 2010, 2015),
  ylab = "Survey index")
```

[![各体长组的调查指数（原尺度） / Survey index by length bin (original scale)](figures/ytf/CatL_length_TRUE.png)](figures/ytf/CatL_length_TRUE.png)

同样的面板改为原尺度：深蓝色曲线为 `exp(Elog_index)`，即拟合对数正态分布的中位数，朱红色点为观测指数。用它按指数单位读取偏差；误差是乘性的，高值处看似很大的差距与低值处的小差距可能是相同的相对偏差。

The same panels on the original scale: the navy curve is `exp(Elog_index)`, the median of the fitted lognormal distribution, and the vermilion points are the observed index. Use it to read the misfit in index units; the error is multiplicative, so a gap that looks large at high values can be the same relative misfit as a small gap at low values.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_CatL)

<a id="CatL_year_FALSE"></a>
## 3. 各时间步的调查指数（对数尺度） / Survey index by time step (log scale)

```r
# 绘制本图 / Draw this figure
plot_CatL(b, facet_by = "year", exp_transform = FALSE, facet_ncol = 4,
  line_size1 = 0.6, line_size2 = 0.4,
  x_breaks = c(10, 30, 50),
  ylab = "Log survey index")
```

[![各时间步的调查指数（对数尺度） / Survey index by time step (log scale)](figures/ytf/CatL_year_FALSE.png)](figures/ytf/CatL_year_FALSE.png)

按年份分面时，`line_size1` 设置拟合线宽，`line_size2` 设置观测线宽。遇到缺测会断开观测线，孤立的观测以点显示，大小由 `point_size` 控制。 / In year facets, `line_size1` sets the fitted line width and `line_size2` the observed line width. Gaps split the observed line. An isolated observation appears as a point sized by `point_size`.

每个时间步一个面板，横轴为体长，纵轴为对数调查指数：细朱红线为观测对数指数随体长的变化，粗深蓝线为拟合的 `Elog_index`。用它检查同一时间步内的拟合形状；深蓝线没有跟上的突起（如本例后几年最大体长组处）就是拟合未能解释的体长结构。

One panel per time step, length on the horizontal axis and the log survey index on the vertical axis: the thin vermilion curve is the observed log index across lengths and the thick navy curve is the fitted `Elog_index`. Use it to check the shape of the fit within a time step; a bump the navy curve misses, as at the largest bin in the later years here, is length structure the fit leaves unexplained.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_CatL)

<a id="CatL_year_TRUE"></a>
## 4. 各时间步的调查指数（原尺度） / Survey index by time step (original scale)

```r
# 绘制本图 / Draw this figure
plot_CatL(b, facet_by = "year", exp_transform = TRUE, facet_ncol = 4,
  line_size1 = 0.6, line_size2 = 0.4,
  x_breaks = c(10, 30, 50),
  ylab = "Survey index")
```

[![各时间步的调查指数（原尺度） / Survey index by time step (original scale)](figures/ytf/CatL_year_TRUE.png)](figures/ytf/CatL_year_TRUE.png)

按年份分面时，`line_size1` 设置拟合线宽，`line_size2` 设置观测线宽。遇到缺测会断开观测线，孤立的观测以点显示，大小由 `point_size` 控制。 / In year facets, `line_size1` sets the fitted line width and `line_size2` the observed line width. Gaps split the observed line. An isolated observation appears as a point sized by `point_size`.

曲线表示调查指数在原尺度上的拟合中位数 `exp(Elog_index)`，观测值按体长组显示。比较观测指数和拟合指数峰值所在的体长组，再查看这些体长组的残差。

The curves show fitted survey-index medians on the original scale, `exp(Elog_index)`, with the observed index in each length bin. Compare the lengths at which the observed and fitted indices peak, then examine the residuals for those bins.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_CatL)

<a id="plot_abundance"></a>

<a id="plot_abundance_N"></a>
## 5. 丰度 N / Abundance N

面板或模型组只有一个估计值时显示为点。设置 `se = TRUE` 后，以误差棒显示 95% 区间（默认为对数正态区间，见 `interval` 参数），因为只有一个点的带状区间没有可见宽度。该规则适用于种群与捕捞死亡率图，也分别适用于 `plot_compare_ts()` 中的每个模型。点大小继承 `point_size`；单模型图的点继承 `line_color`，区间继承 `se_color`。所有面板仍不显示网格线。

A panel or model group containing only one estimate is shown as a point. With `se = TRUE`, an error bar shows the 95% interval (lognormal by default; see the `interval` argument) because a one-point ribbon has no visible width. This applies to population and fishing-mortality plots and to each model separately in `plot_compare_ts()`. Point size follows `point_size`; single-model points retain `line_color` and intervals retain `se_color`. Panels remain free of gridlines.

```r
# 绘制本图 / Draw this figure
plot_abundance(b, type = "N", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![丰度 N / Abundance N](figures/ytf/plot_abundance_N.png)](figures/ytf/plot_abundance_N.png)

总丰度是每个时间步各组估计尾数之和。阴影为近似 95% 区间，默认是对数正态区间 `exp(log(estimate) +/- 1.96 * SE / estimate)`，其中 SE 是估计值的标准误。该区间不会低于零；`interval = "wald"` 绘制早期版本使用的对称区间 `estimate +/- 1.96 * SE`。本例总丰度在 2012 年上升，同年估计补充量达到峰值。

Total abundance sums the estimated numbers across all groups in each time step. Shading shows the approximate 95% interval, which is lognormal by default: `exp(log(estimate) +/- 1.96 * SE / estimate)`, where SE is the standard error of the estimate. This interval cannot fall below zero; `interval = "wald"` draws the symmetric interval `estimate +/- 1.96 * SE` used by earlier versions. The rise in abundance in 2012 coincides with a peak in estimated recruitment.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_abundance)

<a id="plot_abundance_NA"></a>
## 6. 丰度 NA / Abundance NA

```r
# 绘制本图 / Draw this figure
plot_abundance(b, type = "NA", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![丰度 NA / Abundance NA](figures/ytf/plot_abundance_NA.png)](figures/ytf/plot_abundance_NA.png)

每个面板显示一个年龄组的估计尾数和近似 95% 区间。面板用拟合年龄标注，最大的年龄组是末组（plus group），用加号标出（“Age 15+”）。追踪同一世代时，将某期该年龄组的尾数与下一期相邻较高年龄组的尾数对照。各面板使用各自的纵轴尺度。

Each panel shows numbers at one age with an approximate 95% interval. Panels are labelled with the fitted ages, and the oldest age class, a plus group, is marked with a plus sign ("Age 15+"). To follow a cohort, compare its abundance in one age class with abundance one time step later in the next age class. Read the vertical scales separately.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_abundance)

<a id="plot_abundance_NL"></a>
## 7. 丰度 NL / Abundance NL

```r
# 绘制本图 / Draw this figure
plot_abundance(b, type = "NL", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![丰度 NL / Abundance NL](figures/ytf/plot_abundance_NL.png)](figures/ytf/plot_abundance_NL.png)

每个面板显示一个体长组的估计尾数和近似 95% 区间。本例中，小体长组在 2012 年前后先出现峰值，大体长组的峰值出现得较晚。一个体长组可包含多个年龄组的个体。

Each panel shows estimated numbers in one length bin with an approximate 95% interval. In this example the peak in smaller bins around 2012 precedes the peaks in larger bins. Several age classes can contribute to a length bin.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_abundance)

<a id="plot_biomass"></a>

### 模型、输出与区间支持范围

`se = TRUE` 绘制逐点近似 95% 区间，默认为对数正态区间（见 `interval` 参数）；下表列出每个模型哪些量带标准误。数量或标准误不可用时报错，只需要估计线时用 `se = FALSE`；解读区间前先通过数值检查。

| 函数 | 类型 | ACL | ALSCL |
|---|---|---|---|
| `plot_biomass()` | `B` | 估计 + 区间 | 估计 + 区间 |
| `plot_biomass()` | `BL` | 仅估计 | 估计 + 区间 |
| `plot_biomass()` | `BA` | 不可用 | 估计 + 区间 |
| `plot_SSB()` | `SSB` | 估计 + 区间 | 估计 + 区间 |
| `plot_SSB()` | `SBL` | 仅估计 | 估计 + 区间 |
| `plot_SSB()` | `SBA` | 不可用 | 估计 + 区间 |
| `plot_catch()` | `CN` | 估计 + 区间 | 估计 + 区间 |
| `plot_catch()` | `CNA` | 仅估计 | 估计 + 区间 |
| `plot_catch()` | `CNL` | 不可用 | 估计 + 区间 |

```r
plot_biomass(b, type = "BL", se = TRUE)
plot_SSB(b, type = "SBL", se = TRUE)
plot_catch(a, type = "CNA", se = FALSE)
```

### Model, output and interval support

`se = TRUE` draws pointwise approximate 95% intervals, lognormal by default (see the `interval` argument); the table lists which quantities each model reports with standard errors. An unavailable quantity or standard error is an error, and `se = FALSE` draws the estimate alone; pass the numerical checks before reading an interval.

| Function | Type | ACL | ALSCL |
|---|---|---|---|
| `plot_biomass()` | `B` | Estimate + interval | Estimate + interval |
| `plot_biomass()` | `BL` | Estimate only | Estimate + interval |
| `plot_biomass()` | `BA` | Unavailable | Estimate + interval |
| `plot_SSB()` | `SSB` | Estimate + interval | Estimate + interval |
| `plot_SSB()` | `SBL` | Estimate only | Estimate + interval |
| `plot_SSB()` | `SBA` | Unavailable | Estimate + interval |
| `plot_catch()` | `CN` | Estimate + interval | Estimate + interval |
| `plot_catch()` | `CNA` | Estimate only | Estimate + interval |
| `plot_catch()` | `CNL` | Unavailable | Estimate + interval |

```r
plot_biomass(b, type = "BL", se = TRUE)
plot_SSB(b, type = "SBL", se = TRUE)
plot_catch(a, type = "CNA", se = FALSE)
```

<a id="plot_biomass_B"></a>
## 8. 生物量 B / Biomass B

```r
# 绘制本图 / Draw this figure
plot_biomass(b, type = "B", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![生物量 B / Biomass B](figures/ytf/plot_biomass_B.png)](figures/ytf/plot_biomass_B.png)

总生物量随时间步变化，带近似 95% 区间。与总丰度对照，可看出平均个体体重如何影响生物量估计。补充个体从进入模型的第一个时间步就贡献生物量，其贡献可随生长增加。生物量不一定比丰度更平滑。

Total biomass by time step with an approximate 95% interval. Compare it with total abundance to see how mean individual weight affects the estimated biomass. Recruits contribute biomass from their first modelled time step; their contribution can increase as they grow. Biomass need not be smoother than abundance.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_biomass)

<a id="plot_biomass_BA"></a>
## 9. 生物量 BA / Biomass BA

```r
# 绘制本图 / Draw this figure
plot_biomass(b, type = "BA", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![生物量 BA / Biomass BA](figures/ytf/plot_biomass_BA.png)](figures/ytf/plot_biomass_BA.png)

年龄别生物量，每个年龄组一个面板，纵轴各自取值，带 95% 区间。用它看生物量集中在哪些年龄；注意各面板的纵轴刻度，自由刻度会让数量很小的老龄组看起来和大的年轻组一样多变。

Biomass at age, one panel per age class with free vertical scales and the 95% band. Use it to see which ages hold the biomass; read the axis of each panel, because the free scales make a small old class look as variable as a large young one.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_biomass)

<a id="plot_biomass_BL"></a>
## 10. 生物量 BL / Biomass BL

```r
# 绘制本图 / Draw this figure
plot_biomass(b, type = "BL", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![生物量 BL / Biomass BL](figures/ytf/plot_biomass_BL.png)](figures/ytf/plot_biomass_BL.png)

每个面板显示一个体长组的生物量和近似 95% 区间。按各面板纵轴的数值比较体长组对总生物量的贡献。本例中，多个较大体长组的生物量在 2013 年后上升。

Each panel shows biomass in one length bin and its approximate 95% interval. Compare axis values across panels to identify the bins contributing most biomass. Several of the larger bins show an increase after 2013.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_biomass)

<a id="plot_SSB"></a>

<a id="plot_SSB_SSB"></a>
## 11. 产卵生物量 SSB / Spawning biomass SSB

```r
# 绘制本图 / Draw this figure
plot_SSB(b, type = "SSB", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![产卵生物量 SSB / Spawning biomass SSB](figures/ytf/plot_SSB_SSB.png)](figures/ytf/plot_SSB_SSB.png)

产卵群体生物量（SSB）由各组尾数乘以平均体重和成熟比例后求和得到，阴影为近似 95% 区间。本次拟合的 SSB 在 2010 年达到低点，随后回升。用 SSB 判断资源状态时，还需说明所采用的参考点。

Spawning stock biomass (SSB) sums numbers multiplied by mean weight and the proportion mature across groups. The shading gives an approximate 95% interval. In this fit, SSB reached a low in 2010 and subsequently increased. Assessing stock status also requires a stated reference point.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_SSB)


### 显示一个已保存的估计值 / Displaying a single saved estimate

此列表仅用于显示 `b` 最后一期的产卵群体生物量及其标准误，不表示只用一个观测拟合了模型，也不能作为模拟或预测的输入。点与近似 95% 区间均保持可见，不改变原估计值。

This display-only list contains the final spawning-biomass estimate from `b` and its standard error. It is not a model fitted to one observation and is not an input for simulation or forecasting. The point and approximate 95% interval remain visible without changing the estimate.

```r
# Display one saved estimate without refitting.
ssb_rows <- which(rownames(b$est_std) == "SSB")
one_period <- list(
  model_type = b$model_type,
  year = tail(b$year, 1L),
  report = list(SSB = tail(b$report$SSB, 1L)),
  est_std = b$est_std[tail(ssb_rows, 1L), , drop = FALSE]
)
plot_SSB(one_period, se = TRUE, x_breaks = one_period$year) +
  ggplot2::coord_cartesian(xlim = one_period$year + c(-0.5, 0.5))
```

![Displaying a single saved estimate](figures/sparse-panels/single-period-SSB.png)

<a id="plot_SSB_SBA"></a>
## 12. 产卵生物量 SBA / Spawning biomass SBA

```r
# 绘制本图 / Draw this figure
plot_SSB(b, type = "SBA", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![产卵生物量 SBA / Spawning biomass SBA](figures/ytf/plot_SSB_SBA.png)](figures/ytf/plot_SSB_SBA.png)

年龄别产卵生物量，每个年龄组一个面板，带 95% 区间。用它看产卵来自哪些年龄；最小的几个年龄组接近零，因为成熟比例表几乎不给它们成熟个体，比较面板时看纵轴数值而不是曲线形状。

Spawning biomass at age, one panel per age class with the 95% band. Use it to see which ages spawn; the youngest classes sit near zero because the maturity table gives them almost no mature fish, so compare panels by their axis values rather than by the shape of the curves.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_SSB)

<a id="plot_SSB_SBL"></a>
## 13. 产卵生物量 SBL / Spawning biomass SBL

```r
# 绘制本图 / Draw this figure
plot_SSB(b, type = "SBL", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![产卵生物量 SBL / Spawning biomass SBL](figures/ytf/plot_SSB_SBL.png)](figures/ytf/plot_SSB_SBL.png)

体长别产卵生物量，每个体长组一个面板，带 95% 区间。用它看产卵来自哪些体长；小体长组同样接近零，30 以上的成熟组走势与总产卵生物量一致。

Spawning biomass at length, one panel per length bin with the 95% band. Use it to see which lengths spawn; the small bins sit near zero for the same reason, and the mature bins above 30 follow the total spawning biomass.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_SSB)

<a id="plot_catch"></a>

<a id="plot_catch_CN"></a>
## 14. 捕获尾数 CN / Catch numbers CN

```r
# 绘制本图 / Draw this figure
plot_catch(b, type = "CN", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![捕获尾数 CN / Catch numbers CN](figures/ytf/plot_catch_CN.png)](figures/ytf/plot_catch_CN.png)

模型推导的捕捞尾数（`CN`）随时间步变化，带近似 95% 区间。它根据丰度和捕捞死亡率计算；YTF 教学数据不含实测渔获量。与独立渔获资料比较前，须统一数量定义、单位、丰度尺度、时期和区域。登陆量可能不包括弃捕，还需核对其涵盖的捕捞移除量（[FAO 定义](https://www.fao.org/4/x8923e/X8923E03.htm)）。区间较宽表示给定拟合假设下不确定性较大；仅凭宽度不能确定其原因。

Model-derived catch in numbers (`CN`) by time step with an approximate 95% interval. It is computed from abundance and fishing mortality; the YTF teaching data include no observed fishery catch. Compare it with independent catch data only after matching the quantity, units, abundance scale, period and area. Landings may omit discarded fish, so their coverage of fishing removals also needs checking ([FAO definitions](https://www.fao.org/4/x8923e/X8923E03.htm)). A wide interval indicates substantial uncertainty under the fitted assumptions; its width alone does not identify the cause.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_catch)

<a id="plot_catch_CNA"></a>
## 15. 捕获尾数 CNA / Catch numbers CNA

```r
# 绘制本图 / Draw this figure
plot_catch(b, type = "CNA", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![捕获尾数 CNA / Catch numbers CNA](figures/ytf/plot_catch_CNA.png)](figures/ytf/plot_catch_CNA.png)

每个面板显示一个年龄组的估计渔获尾数和近似 95% 区间。本例中，较年轻的年龄组渔获尾数较高。比较时请看各面板纵轴的数值。

Each panel shows estimated catch in numbers for one age class, with an approximate 95% interval. In this example, catches are largest in the younger age classes. Read the values against the vertical scale of each panel.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_catch)

<a id="plot_catch_CNL"></a>
## 16. 捕获尾数 CNL / Catch numbers CNL

```r
# 绘制本图 / Draw this figure
plot_catch(b, type = "CNL", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![捕获尾数 CNL / Catch numbers CNL](figures/ytf/plot_catch_CNL.png)](figures/ytf/plot_catch_CNL.png)

每个面板显示一个体长组的预期渔获尾数和近似 95% 区间。设组内期初尾数为 N，F 和 M 分别为每个时间步的瞬时捕捞死亡率和自然死亡率。按 Baranov 渔获方程，`C = N × (F/Z) × (1 − exp(−Z))`，其中 `Z = F + M`。ALSCL 将同一体长组各年龄的渔获尾数相加。[Baranov 渔获方程，式（15）](https://repository.library.noaa.gov/view/noaa/4847/noaa_4847_DS1.pdf#page=11)。

Each panel shows the expected catch in numbers for one length bin, with an approximate 95% interval. For a group with starting abundance N and instantaneous mortality rates F and M per time step, the Baranov catch equation gives `C = N × (F/Z) × (1 − exp(−Z))`, where `Z = F + M`. ALSCL sums these catches across ages within each length bin. [Baranov catch equation, eq. 15](https://repository.library.noaa.gov/view/noaa/4847/noaa_4847_DS1.pdf#page=11).

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_catch)

<a id="plot_recruitment"></a>

<a id="recruitment"></a>
## 17. 补充量 / Recruitment

```r
# 绘制本图 / Draw this figure
plot_recruitment(b, se = TRUE)
```

[![补充量 / Recruitment](figures/ytf/recruitment.png)](figures/ytf/recruitment.png)

补充量表示每个时间步进入最小年龄组的估计尾数，阴影为近似 95% 区间。本例估计补充量在 2012 年达到峰值。`rec.age` 指定个体进入模型的年龄。

Recruitment is the estimated number entering the youngest age class per time step. The shaded band gives the approximate 95% interval. Estimated recruitment peaks in 2012 in this example. The age at entry is set by `rec.age`.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_recruitment)

<a id="plot_SSB_Rec"></a>

<a id="SSB_Rec"></a>
## 18. 亲体与补充关系 / Spawning biomass and recruitment

`age_at_recruitment` 的单位是年，默认 NULL 取最小拟合年龄（没有年龄元数据的结果用 1 年）。`plot_SSB_Rec()` 把给定的值除以拟合的 `growth_step`，要求在规则时间网格上对应整数个时间步。季度数据中，0.25 表示滞后一季度，1 表示四季度。允许零滞后；拒绝负值、非有限值及非整数步滞后。没有 `growth_step` 的结果使用规则年份间隔；两类时间元数据都没有时沿用年度步长。

`age_at_recruitment` is in years, and the default NULL uses the youngest fitted age (1 year for a result saved without age metadata). `plot_SSB_Rec()` divides a supplied value by the fit's `growth_step` and requires an integer lag on a regular time grid. With quarterly data, 0.25 means one step and 1 means four steps. Zero lag is allowed; negative, nonfinite and fractional-step lags are rejected. Results without `growth_step` use their regular time spacing, or an annual step when `year` is missing as well.

```r
# 绘制本图 / Draw this figure
plot_SSB_Rec(b, age_at_recruitment = 1)
```

[![亲体与补充关系 / Spawning biomass and recruitment](figures/ytf/SSB_Rec.png)](figures/ytf/SSB_Rec.png)

每个点把某期的产卵群体生物量与 `age_at_recruitment` 年后的补充量配对，可用来查看两组估计值的关系。默认 `age_at_recruitment = NULL` 使用最小拟合年龄：本例的年度拟合为 1 年，`rec.age = 0.25` 的季度拟合为一个季度。评估模型用 AR(1) 过程描述补充量的对数偏差。绘图函数只绘制配对值。

Each point pairs spawning stock biomass with recruitment `age_at_recruitment` years later. The default, `age_at_recruitment = NULL`, uses the youngest fitted age: 1 year for this annual fit and one quarter for a quarterly fit with `rec.age = 0.25`. The scatter shows the association in the fitted series. The assessment models log recruitment deviations as an AR(1) process, and the plotting function draws the pairs without fitting a stock–recruitment curve.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_SSB_Rec)

<a id="plot_VB"></a>

<a id="VB"></a>
## 19. 生长曲线与区间 / Growth curve and interval

```r
# 绘制本图 / Draw this figure
plot_VB(b, se = TRUE)
```

[![生长曲线与区间 / Growth curve and interval](figures/ytf/VB.png)](figures/ytf/VB.png)

von Bertalanffy 曲线是由图中 `Linf`、`k` 和 `t0` 计算的参考曲线。`se = TRUE` 时，95% 区间反映这些参数的估计不确定性。本例固定了三个参数，因此区间宽度为零。在 ALSCL 中，各期实际的年龄别平均体长还取决于生长转移和体长别死亡；这条参考曲线不代表种群演变后的平均体长。

The von Bertalanffy curve is a reference calculated from the displayed `Linf`, `k` and `t0`. With `se = TRUE`, the 95% band reflects uncertainty in those parameters. All three are fixed in this example, so the band has zero width. In ALSCL, the realized mean length at age also depends on growth transitions and length-specific mortality; this reference curve does not summarize the evolving population.

`age_range = NULL` 时绘制拟合的年龄范围，起点不早于 `t0`；显式 `age_range` 必须是两个递增的有限年龄，且不早于 `t0`。若 `se = TRUE` 但参数协方差不可用，函数会警告并只画曲线，保留传入的标签、字号、刻度和主题。

`age_range = NULL` draws the fitted age range, starting no earlier than `t0`; an explicit `age_range` must be two increasing finite ages at or after `t0`. If `se = TRUE` but the parameter covariance is unavailable, the function warns and draws the curve alone, keeping the labels, text sizes, breaks and theme you passed.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_VB)

<a id="plot_pla"></a>

<a id="pla"></a>
## 20. 年龄—体长概率矩阵 / Age–length probability matrix

```r
# 绘制本图 / Draw this figure
plot_pla(b)
```

[![年龄—体长概率矩阵 / Age–length probability matrix](figures/ytf/pla.png)](figures/ytf/pla.png)

静态矩阵 `pla` 的每一列给出一个年龄组的体长组概率，列内概率之和为 1。ACL 在每个时间步用它将年龄别尾数转换为体长别尾数。ALSCL 用它初始化种群并分配补充个体的体长，后续体长分布由生长和存活过程决定。要得到 ALSCL 某年龄、某时期的实际体长分布，应将 `NLA` 中对应的体长向量归一化。颜色表示各组概率，最高体长组包含右尾。横轴显示拟合年龄，最大的年龄是末组（plus group），标为“15+”。保存时没有年龄元数据的结果按年龄组的位置绘制，横轴标签为 Age group。

Each column of the static `pla` matrix gives length-bin probabilities for one age class and sums to one. ACL uses this matrix to convert numbers at age to numbers at length in every time step. ALSCL uses it to initialize the population and assign lengths to recruits; subsequent length distributions follow growth and survival. To obtain the realized distribution at a given age and time in ALSCL, normalize the corresponding length vector in `NLA`. The colour shows the probability in each bin, and the last bin includes the upper tail. The horizontal axis shows the fitted ages, and the oldest age, a plus group, is marked "15+". A result saved without age metadata is plotted against the position of the age class, and its axis label reads Age group.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_pla)

<a id="plot_fishing_mortality"></a>

<a id="F_ACL_year"></a>
## 21. ACL 各年龄组捕捞死亡率随时间的变化 / ACL fishing mortality over time by age class

每个面板只有一个估计值时显示为点，带状区间改用误差棒；已选择 `se_type = "errorbar"` 时不会重复添加区间。

A panel with one estimate uses a point and an error bar in place of a ribbon. Choosing `se_type = "errorbar"` does not add a duplicate interval.

`plot_fishing_mortality()` 从 `acl_theme_set()` 取标题、坐标轴标签、`x_breaks` 和 `x_expand`：标题键为 `F_year`、`F_age`、`F_length`，区间图加 `_se`；标签为 `xlab$year`、`xlab$age` 或 `xlab$length` 以及 `ylab$F`。年龄模式的横轴显示拟合年龄，末组标为“15+”这样的形式；早期版本的 ALSCL 拟合没有末组的值。保存时没有年龄元数据的结果按年龄组的位置绘制，未设置 `xlab$age` 时默认标签为 Age group。默认的 `ylab$F` 标签注明捕捞死亡率的时间基准，例如“Fishing mortality rate (per year)”；调用中给出的标签和刻度优先。`base_theme` 接受 `"theme_bw"`、`"bw"` 等主题名、ggplot2 主题对象或 `NULL`（全局设置），各种情况下都不显示网格线。

`plot_fishing_mortality()` takes its title, axis labels, `x_breaks` and `x_expand` from `acl_theme_set()`: title keys `F_year`, `F_age` and `F_length`, with `_se` added for interval plots, and labels `xlab$year`, `xlab$age` or `xlab$length` and `ylab$F`. In age mode the horizontal axis shows the fitted ages, and the plus group is marked as in "15+"; ALSCL fits made by earlier versions have no value for the plus group. A result saved without age metadata is plotted against the position of the age class, and its default label reads Age group unless you set `xlab$age`. The default `ylab$F` label states the time basis of the rate, for example "Fishing mortality rate (per year)"; labels and breaks given in the call take precedence. `base_theme` accepts a theme name such as `"theme_bw"` or `"bw"`, a ggplot2 theme object, or `NULL` for the global setting, and gridlines stay hidden in every case.

```r
# 绘制本图 / Draw this figure
plot_fishing_mortality(a, type = "year",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ACL 各年龄组捕捞死亡率随时间的变化 / ACL fishing mortality over time by age class](figures/ytf/F_ACL_year.png)](figures/ytf/F_ACL_year.png)

每个面板显示 ACL 一个年龄组的瞬时捕捞死亡率（`F`）及其近似 95% 区间。F 的时间单位由模型时间步决定，本例为一年，季度拟合则为一个季度。

Each panel shows the estimated instantaneous fishing mortality rate (`F`) for one ACL age class, with its approximate 95% interval. F is expressed per model time step. The time step is one year here and one quarter in a quarterly fit.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_fishing_mortality)

<a id="F_ACL_age"></a>
## 22. ACL 各期的年龄别捕捞死亡率 / ACL fishing mortality at age by time step

```r
# 绘制本图 / Draw this figure
plot_fishing_mortality(a, type = "age",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ACL 各期的年龄别捕捞死亡率 / ACL fishing mortality at age by time step](figures/ytf/F_ACL_age.png)](figures/ytf/F_ACL_age.png)

每个面板显示 ACL 在一个时间步的估计值及其近似 95% 区间，横轴为拟合年龄（末组标为“15+”）。本例中多数年份的曲线较平，表示各年龄组的估计捕捞死亡率相近；2007 至 2010 年低龄组的估计值较高。

Each panel shows the same ACL estimates for one time step, with the fitted ages on the horizontal axis (the plus group is marked "15+") and approximate 95% intervals. In most years of this example the profiles are nearly flat, which indicates similar estimated fishing mortality across ages; from 2007 to 2010 the estimates are higher at the younger ages.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_fishing_mortality)

<a id="F_ALSCL_year"></a>
## 23. ALSCL 各体长组捕捞死亡率随时间的变化 / ALSCL fishing mortality over time by length bin

```r
# 绘制本图 / Draw this figure
plot_fishing_mortality(b, type = "year",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ALSCL 各体长组捕捞死亡率随时间的变化 / ALSCL fishing mortality over time by length bin](figures/ytf/F_ALSCL_year.png)](figures/ytf/F_ALSCL_year.png)

每个面板显示一个体长组的捕捞死亡率（`FL`）随时间的变化及其近似 95% 区间。本例在 2008 年前后的高值以中等体长组最为明显。

Each panel shows how fishing mortality at length (`FL`) changes over time for one length bin, with an approximate 95% interval. The estimated peak around 2008 is most pronounced at intermediate lengths.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_fishing_mortality)

<a id="F_ALSCL_age"></a>
## 24. ALSCL 各期的年龄别捕捞死亡率 / ALSCL fishing mortality at age by time step

```r
# 绘制本图 / Draw this figure
plot_fishing_mortality(b, type = "age",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ALSCL 各期的年龄别捕捞死亡率 / ALSCL fishing mortality at age by time step](figures/ytf/F_ALSCL_age.png)](figures/ytf/F_ALSCL_age.png)

ALSCL 先把同一年龄组各体长组的存活尾数相加，再除以该年龄组的期初尾数，得到存活比例。年龄别捕捞死亡率为 `FA = -log(存活比例) - M`。每个面板显示一个时间步的估计值和近似 95% 区间。`FA` 对每个年龄（包括末组“15+”）和每个时间步都有值，`report$ZA` 保存对应的年龄别总死亡率。最后一个时间步的 F 由 F 过程预测，没有观测为它提供信息。早期版本的拟合中，`FA` 不含末组和最后一个时间步；两种形式函数都能绘制。

For each age class, ALSCL sums the numbers surviving across length bins and divides by the number present at the start of the step. Fishing mortality at age is `FA = -log(survival proportion) - M`. Each panel shows the estimates and approximate 95% intervals for one time step. `FA` has a value for every age, including the plus group ("15+"), and for every time step, and `report$ZA` holds the matching total mortality at age. F in the last time step is predicted by the F process; no observation informs it. Fits made by earlier versions hold `FA` without the plus group and without the last time step, and the function draws both forms.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_fishing_mortality)

<a id="F_ALSCL_length"></a>
## 25. ALSCL 各期的体长别捕捞死亡率 / ALSCL fishing mortality at length by time step

```r
# 绘制本图 / Draw this figure
plot_fishing_mortality(b, type = "length",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ALSCL 各期的体长别捕捞死亡率 / ALSCL fishing mortality at length by time step](figures/ytf/F_ALSCL_length.png)](figures/ytf/F_ALSCL_length.png)

每个面板显示一个时间步各体长组的捕捞死亡率及其近似 95% 区间。横轴按体长组中点（`len_mid`）的实际间距绘制。本例中，体长约 20 至 35 的组估计捕捞死亡率较高。

Each panel shows fishing mortality at length for one time step, with an approximate 95% interval. Length-bin midpoints (`len_mid`) are plotted at their actual spacing. In this example, estimated fishing mortality is higher at intermediate lengths, around 20 to 35.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_fishing_mortality)

<a id="plot_residuals"></a>

<a id="residuals_length"></a>
## 26. 按体长组分面的对数残差 / Log residuals by length bin

```r
# 绘制本图 / Draw this figure
plot_residuals(b, facet_by = "length", facet_ncol = 4, line_size = 0.6,
  x_breaks = c(2000, 2010, 2015))
```

[![按体长组分面的对数残差 / Log residuals by length bin](figures/ytf/residuals_length.png)](figures/ytf/residuals_length.png)

对数残差，即观测对数调查指数减拟合值，每个体长组一个面板，横轴为时间：深蓝线连接残差，灰线为零，青绿色虚线为平滑线。用它找模型拟合不好的体长组（零值和缺失观测没有残差）；多年同号的残差（如本例 16 组为正、20 组为负）说明系统性偏差，序列末端的趋势（如 50 组）提示模型没有跟上的变化。

每个分面内，缺失或排除的观测会断开残差线和趋势线。单个有效观测画成点。连续 2–5 个观测用直线拟合趋势，连续至少 6 个观测用 loess。

Log residuals, the observed minus the fitted log survey index, one panel per length bin with time on the horizontal axis: the navy line joins the residuals, the grey line is zero and the dashed teal curve is a smoother. Use it to find bins the model misfits (zero and missing observations have no residual); residuals of one sign over many years, as in bins 16 (positive) and 20 (negative) here, mean a systematic misfit, and a trend at the end of the series, as in bin 50, points to a change the model misses.

Within each facet, a missing or excluded observation breaks the residual line and its trend. A single observed value is drawn as a point. Each consecutive run of 2–5 observations has a linear trend, and a run of 6 or more uses loess.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_residuals)

<a id="residuals_year"></a>
## 27. 按时间步分面的对数残差 / Log residuals by time step

```r
# 绘制本图 / Draw this figure
plot_residuals(b, facet_by = "year", facet_ncol = 4, line_size = 0.6,
  x_breaks = c(10, 30, 50))
```

[![按时间步分面的对数残差 / Log residuals by time step](figures/ytf/residuals_year.png)](figures/ytf/residuals_year.png)

同一组残差按体长排列：每个时间步一个面板，横轴为体长，带零线和平滑线。观察哪些体长范围的残差持续高于或低于零。本例 2015 年起最大体长组的正尖峰表示那几年的观测指数高于拟合值。重复出现的符号变化可提示偏差随体长变化；平滑线在某个体长穿过零线，本身不表示该体长存在偏差。

The same residuals arranged by length: one panel per time step, with length on the horizontal axis, a zero line and a smoother. Look for length ranges with residuals persistently above or below zero. The positive spikes in the largest bin from 2015 onward indicate observed indices above the fitted values in those years. Repeated changes in sign can suggest length-dependent misfit; the smoother crossing zero at a particular length is not itself evidence of bias at that length.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_residuals)

<a id="plot_deviance"></a>

<a id="deviation_R_TRUE"></a>
## 28. 补充量的对数偏差 / Log recruitment deviations

```r
# 绘制本图 / Draw this figure
plot_deviance(b, type = "R", log = TRUE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![补充量的对数偏差 / Log recruitment deviations](figures/ytf/deviation_R_TRUE.png)](figures/ytf/deviation_R_TRUE.png)

点表示估计的补充量对数偏差，误差棒表示近似 95% 区间。对数偏差为零时，补充量等于拟合过程的中位数 `exp(mean_log_R)`。负值表示该期补充量低于这个中位数。

The points are estimated log recruitment deviations and the bars are approximate 95% intervals. Zero corresponds to the median recruitment of the fitted process, `exp(mean_log_R)`. A negative estimate indicates recruitment below that median.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_deviance)

<a id="deviation_R_FALSE"></a>
## 29. 补充量相对于中位数的倍数 / Recruitment relative to the process median

```r
# 绘制本图 / Draw this figure
plot_deviance(b, type = "R", log = FALSE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![补充量相对于中位数的倍数 / Recruitment relative to the process median](figures/ytf/deviation_R_FALSE.png)](figures/ytf/deviation_R_FALSE.png)

设置 `log = FALSE` 后，每个点表示该期补充量与过程中位数之比。2012 年的比值为 1.77，表示估计补充量比中位数高 77%。区间端点由对数尺度的端点取指数得到。

With `log = FALSE`, each point is recruitment divided by the process median. A ratio of 1.77, as in 2012, means that estimated recruitment was 77% above that median. The interval endpoints are exponentiated from the log scale.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_deviance)

<a id="deviation_F_TRUE"></a>
## 30. 捕捞死亡率的对数偏差 / Log fishing mortality deviations

```r
# 绘制本图 / Draw this figure
plot_deviance(b, type = "F", log = TRUE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![捕捞死亡率的对数偏差 / Log fishing mortality deviations](figures/ytf/deviation_F_TRUE.png)](figures/ytf/deviation_F_TRUE.png)

点和近似 95% 区间表示各期捕捞死亡率的对数偏差。偏差为零对应原尺度上的过程中位数 `exp(mean_log_F)`。ALSCL 按体长组分面，ACL 按年龄组分面。各组共用 F 时只有一个面板。

Points and approximate 95% intervals show log fishing mortality deviations over time. Zero corresponds to the process median, `exp(mean_log_F)`, on the original scale. ALSCL shows one panel per length bin, ACL one per age class. A fit with shared F has one panel.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_deviance)

<a id="deviation_F_FALSE"></a>
## 31. 捕捞死亡率相对于中位数的倍数 / Fishing mortality relative to the process median

```r
# 绘制本图 / Draw this figure
plot_deviance(b, type = "F", log = FALSE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![捕捞死亡率相对于中位数的倍数 / Fishing mortality relative to the process median](figures/ytf/deviation_F_FALSE.png)](figures/ytf/deviation_F_FALSE.png)

每个点表示估计捕捞死亡率与过程中位数之比。比值为 0.5 表示该期该组的捕捞死亡率为中位数的一半。误差棒为对数尺度区间端点取指数后得到的近似 95% 区间。

Each point is the fitted fishing mortality rate divided by the process median. A ratio of 0.5 means fishing mortality was half that median. The error bars show the approximate 95% intervals after exponentiation.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_deviance)

<a id="plot_ridges"></a>

<a id="ridges"></a>
## 32. 长度组成山脊图 / Length composition ridges

山脊图两栏均保留模型的完整体长范围，包括最小或最大体长组缺测以及全部观测缺失的情况。自定义 `x_breaks` 和全局 `x_expand` 同时作用于两栏。`ridges_scale` 必须为 `NULL`（自动高度）或一个有限正数；零、负数、缺失值、无穷大和向量均会报错。

Both ridge panels retain the full model length range, even when the shortest or longest bins are unobserved or all observations are missing. Custom `x_breaks` and global `x_expand` apply to both panels. `ridges_scale` must be `NULL` (automatic height) or one finite positive number; zero, negative values, missing values, infinity and vectors are rejected.

```r
# 绘制本图 / Draw this figure
plot_ridges(b) # 默认 viridis 渐变 / Default viridis gradient
```

[![长度组成山脊图 / Length composition ridges](figures/ytf/ridges.png)](figures/ytf/ridges.png)

每条曲线表示一个时间步各体长组调查指数的相对组成，左图为观测值，右图为拟合值。`plot_ridges()` 返回 patchwork 对象，整张图有一个总标题，两个面板各有标题；`p[[1]]` 和 `p[[2]]` 分别取出观测面板和拟合面板。时间轴在年度拟合中显示年份，在季度拟合中显示季度（如“2000 Q2”）。2012 年之后，峰值向较大的体长组移动。可比较两图的峰值位置和分布宽度。某期全部缺测时不绘制该期的观测曲线，部分缺测时仅用有观测的体长组计算观测比例。

Each ridge shows the relative survey index across lengths in one time step, with observations on the left and the fit on the right. `plot_ridges()` returns a patchwork object with one figure title and a title on each panel; `p[[1]]` and `p[[2]]` extract the observed and the fitted panel. The time axis shows years for annual fits and quarters, as in "2000 Q2", for quarterly fits. The peak shifts toward larger lengths after 2012. Compare the position and spread of the distributions. A step with no observations has no observed ridge, and a partially observed step is normalized over the observed bins only.

缺失或被排除的体长组会断开观测轮廓和填色。孤立的观测体长组在缩放后的组成高度处画为点；归一化仍使用该期全部正观测。左右面板使用相同的时间位置、纵轴范围和时间配色，包括完全缺测的时期。`spectral` 等 Brewer 配色也支持只有两个时期的结果。

Missing or excluded length bins break the observed outline and fill. An isolated observed bin is drawn as a point at its scaled composition height; normalization still uses all positive observations in that period. Both panels keep the same time positions, vertical range and time colors, including periods without observations. Brewer palettes such as `spectral` also support two-period results.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_ridges)


### 边界体长组缺测 / Missing boundary length bins

这个合成绘图示例的最小两个和最大两个体长组均缺测，第一期也全部缺测。两栏仍显示 10–90 个长度单位的范围，并保留四个时期的位置。观测组成用剩余体长组归一化，拟合组成用全部体长组归一化，两者的归一化总量不同。空白区域不代表零观测。

This synthetic illustration has no observations in the two smallest or two largest length bins, and no observations in the first period. Both panels still span 10–90 length units and keep all four time positions. The observed composition uses the remaining bins; the fitted composition uses all bins, so their normalizing totals differ. Blank areas are not zero observations.

```r
# Synthetic display example with missing boundary length bins.
lengths <- seq(10, 90, 10)
years <- 2000:2003
log_index <- outer(lengths, seq(35, 50, 5),
  function(length, center) -((length - center) / 18)^2)
ridge_example <- list(year = years, len_mid = lengths,
  observations = exp(log_index), report = list(Elog_index = log_index))
ridge_example$observations[c(1, 2, 8, 9), ] <- NA_real_
ridge_example$observations[, 1L] <- NA_real_
plot_ridges(ridge_example, ridges_scale = 1,
  x_breaks = seq(10, 90, 20))
```

![Missing boundary length bins](figures/sparse-panels/ridges-missing-edges.png)

<a id="plot_compare_ts"></a>

<a id="compare_ts"></a>
## 33. 种群时间序列比较 / Population time series comparison

每个模型分别判断是否只有一个估计值；单点用点与误差棒，多期结果仍用曲线与带状区间。

Each model is handled separately: a single estimate uses a point and error bar, while a multi-period series retains its line and ribbon.

```r
# 绘制本图 / Draw this figure
plot_compare_ts(a, b, se = TRUE, facet_ncol = 2)
```

[![种群时间序列比较 / Population time series comparison](figures/ytf/compare_ts.png)](figures/ytf/compare_ts.png)

两组拟合的产卵生物量、补充量、总生物量、总丰度和捕获尾数时间序列，每个量一个面板，纵轴各自取值：ACL 为深蓝实线，ALSCL 为朱红虚线（`compare_colors`、`compare_linetypes`），`se = TRUE` 时加上各自的 95% 区间。用它看两个模型在哪里分歧；本例生物量和产卵生物量在 2014 年后分开，自由纵轴使振幅只能在面板内比较，不能跨面板比较。

Time series of spawning biomass, recruitment, total biomass, total abundance and catch in numbers from two fits, one panel per quantity with its own vertical scale: ACL is the navy solid line and ALSCL the vermilion dashed line (`compare_colors`, `compare_linetypes`), and `se = TRUE` adds each fit's 95% band. Use it to see where the two models disagree; the ACL and ALSCL series separate after 2014 in biomass and spawning biomass here, and the free vertical scales make amplitudes comparable within a panel but not across panels.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_compare_ts)

<a id="plot_compare_F"></a>

<a id="compare_F"></a>
## 34. 死亡率矩阵比较 / Fishing mortality matrices

```r
# 绘制本图 / Draw this figure
plot_compare_F(a, b) + scale_x_continuous(breaks = c(2000, 2010, 2019))
```

[![死亡率矩阵比较 / Fishing mortality matrices](figures/ytf/compare_F.png)](figures/ytf/compare_F.png)

两组拟合各一张捕捞死亡率热图，横轴为时间，纵轴为各自的组（ACL 为年龄组，ALSCL 为体长组），共用一个 `F` 色标。用它看每个模型中捕捞在何时、哪些组最重；两图的行是不同维度，所以比较深色列的时间（本例 2007 至 2010 年）而不是逐格比较，F 汇总图可比较各模型的组间最大值或均值，解读时须区分年龄组和体长组的定义。 ACL 热图按拟合使用的年龄标示各行，季度数据可显示小数年龄；最大的年龄组是末组（plus group），用加号标出（“Age 15+”）。旧拟合缺少年龄坐标时，行标签会明确标为年龄组序号。要在相同年龄上汇总两个拟合，使用 `plot_compare_F_ts(basis = "age")`。

Heat maps of fishing mortality, one per fit, time on the horizontal axis and the fit's own groups on the vertical axis (age classes for ACL, length bins for ALSCL) with one colour scale for `F`. Use it to see when and in which groups fishing was heaviest in each model; the rows are different dimensions, so compare the timing of the dark columns (2007 to 2010 here) rather than single cells, and use the summary F figures to compare each model's group maximum or mean, keeping the age and length definitions explicit. The ACL rows show fitted ages, including fractional ages for seasonal data, and the oldest age class, a plus group, is marked with a plus sign ("Age 15+"). For an older fit without age coordinates, the rows are labelled as numbered age groups. For a summary of both fits over the same ages, use `plot_compare_F_ts(basis = "age")`.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_compare_F)

<a id="plot_compare_residuals"></a>

<a id="compare_residuals"></a>
## 35. 残差联合诊断 / Combined residual diagnostics

平均残差面板保留完整拟合时间范围，包括首期或末期全部缺测的情况。这些时期保留横轴位置，但不会补造残差或误差棒。

The mean-residual panel retains the full fitted time range, including unobserved first or last periods. These periods occupy space on the axis but do not acquire fabricated residuals or error bars.

```r
# 绘制本图 / Draw this figure
plot_compare_residuals(a, b, dat)
```

[![残差联合诊断 / Combined residual diagnostics](figures/ytf/compare_residuals.png)](figures/ytf/compare_residuals.png)

四个面板显示两组拟合的样本内对数残差：直方图、以正态分布为参照的 QQ 图、各时间步的平均残差及加减一个标准差的误差棒，以及各体长组绝对残差的箱线图。ACL 为深蓝，ALSCL 为朱红。直方图较宽表示离散程度较大；QQ 图中看点的弯曲和不对称，它们提示偏斜或重尾，不要看斜率：这些残差以拟合的过程偏差为条件，即使模型设定正确，标准化条件残差的标准差也只有约 0.91 到 0.96。绝对残差较大的体长组拟合较差，例如本例 ALSCL 的 16 组和 50 组。标准差误差棒表示残差的离散程度，不是均值的置信区间。

Four panels show the in-sample log residuals of both fits: a histogram, a QQ plot against a normal reference, the mean residual by time step with bars of plus or minus one standard deviation, and box plots of absolute residuals by length bin. ACL is navy and ALSCL vermilion. A wider histogram indicates greater dispersion; in the QQ plot, read curvature and asymmetry of the points as signs of skewness or heavy tails, not the slope: the residuals are conditional on the fitted process deviations, and even a correct model gives standardized conditional residuals with a standard deviation of about 0.91 to 0.96. Higher absolute residuals identify poorly fitted bins, including bins 16 and 50 for ALSCL here. The standard-deviation bars describe residual spread, not confidence intervals for the mean.

整期缺测会断开平均残差线，孤立的有效时期仍显示为点。只有该期至少有两个观测体长组时才绘制标准差误差棒；仅有一个观测时仍保留残差点。

A wholly unobserved period breaks the mean-residual line. Isolated observed periods remain visible as points. An SD bar is drawn only when the period contains at least two observed length bins; a single observation still contributes its residual point.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_compare_residuals)

<a id="plot_compare_growth"></a>

<a id="compare_growth"></a>
## 36. 生长与外部参照接口 / Growth and reference-data interface

参考数据与排版辅助函数 / Reference data and layout helper:

```r
# 模拟参考生长点，并非论文实测 / Synthetic reference points, not paper observations
set.seed(42)
ref <- data.frame(Age = rep(1:15, each = 5))
ref$Length <- VB_func(60, .2, 1/60, ref$Age) + rnorm(nrow(ref), 0, 2)
growth_display <- function(p) {
  p[[1]] <- p[[1]] + labs(subtitle = paste(strsplit(
    p[[1]]$labels$subtitle, " | ", fixed=TRUE)[[1]], collapse="\n")) +
    theme(legend.text=element_text(size=7))
  p[[2]] <- p[[2]] + scale_x_continuous(breaks=c(1,5,10,15))
  p
}
```

```r
# 绘制本图 / Draw this figure
growth_display(plot_compare_growth(a, b, age_range = c(1, 15), ref_data = ref, ref_name = "Synthetic reference",
    nls_start = list(Linf = 60, k = 0.2, t0 = 1/60)))
```

[![生长与外部参照接口 / Growth and reference-data interface](figures/ytf/compare_growth.png)](figures/ytf/compare_growth.png)

左图：两组拟合的 von Bertalanffy 曲线（ACL 深蓝实线，ALSCL 朱红虚线），副标题给出各自的 `Linf` 和 `k`，另有 `nls()` 对 `ref_data` 拟合的灰色参照曲线及该数据的灰点；右图：两组拟合的年龄体长矩阵热图，横轴为拟合年龄，纵轴为体长组中点。保存时没有这些元数据的拟合按年龄组和体长组的位置绘制，并在坐标轴上注明。用它比较由参数计算的 VB 曲线和静态 `pla` 矩阵。曲线重合表示 VB 参数相同；ALSCL 各期实际的年龄别体长分布还取决于生长转移和存活。本例的生长参数固定为相同值。参照点由上面的代码模拟生成，也可传入独立的年龄体长数据进行比较。

Left: the von Bertalanffy curves of both fits (ACL navy solid, ALSCL vermilion dashed) with their `Linf` and `k` in the subtitle, the grey reference curve that `nls()` fits to `ref_data`, and the grey points of that data; right: the age length matrices of both fits as heat maps, with the fitted ages on the horizontal axis and the length-bin midpoints on the vertical axis. Fits saved without this metadata are drawn against age-class and length-bin positions, and the axes say so. Use it to compare the parameter-based VB curves and static `pla` matrices. Matching curves indicate matching VB parameters; the realized length distribution at age in ALSCL also depends on growth transitions and survival. Here the growth parameters are fixed at the same values. The reference points are simulated by the code above; an independent age-length dataset can be supplied for comparison.

省略 `age_range` 时，采用两份拟合年龄的合并范围，起点不早于两个模型的 `t0`。缺少年龄信息的旧结果使用 1-20 岁范围。显式范围须为两个有限且递增的年龄，起点不早于两个 `t0`；没有正跨度的范围会报错。

Omit `age_range` to use the combined fitted age range, starting at or after both models' `t0`. A model without saved age metadata contributes the legacy range 1-20 years. An explicit range must contain two finite increasing ages and start at or after both `t0` values. A range with no positive span is rejected.

可选参考曲线仅在不早于其自身拟合 `t0` 的年龄绘制。若其生长参数无效，或没有剩余的正年龄跨度，会警告说明省略参考曲线的原因；评估模型曲线和观测点仍保留。

The optional reference curve is drawn only at ages at or above its own fitted `t0`. If its fitted growth parameters are invalid or no positive age span remains, a warning explains why the reference curve is omitted; the assessment curves and observed points remain.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_compare_growth)

<a id="plot_compare_CatL"></a>

<a id="compare_CatL"></a>
## 37. 两模型调查拟合 / Survey fits from both models

```r
# 绘制本图 / Draw this figure
plot_compare_CatL(a, b, dat, years = c(2000, 2005, 2010, 2015), facet_ncol = 2)
```

[![两模型调查拟合 / Survey fits from both models](figures/ytf/compare_CatL.png)](figures/ytf/compare_CatL.png)

所选时间步（`years`，省略则显示全部）的调查指数随体长变化，每个时间步一个面板：灰点为观测指数，深蓝实线为 ACL 拟合，朱红虚线为 ALSCL 拟合，均为 `exp(Elog_index)` 中位数，零值和缺失观测不画点。用它看哪个模型跟得上观测的体长组成；本例两者都跟上 20 附近的峰，ALSCL 曲线的局部起伏更多。可结合体长别 F 和其他设置检查这些起伏的原因。

Survey index against length for the selected time steps (`years`; omit it for all), one panel per time step: grey points are the observed index, the navy solid curve the ACL fit and the vermilion dashed curve the ALSCL fit, both as `exp(Elog_index)` medians, and zero and missing observations are left out of the points. Use it to see which model follows the observed length composition; both follow the mode near length 20 here, and the ALSCL curve has more local variation. Examine length-specific F and alternative settings to investigate that variation.

纵轴标签来自 `ylab$survey`，默认为 Survey index；用 `acl_theme_set(ylab = list(survey = "Survey index (relative units)"))` 可一次改好所有调查拟合图的标签，单模型对数图会加上前缀 Log。`ylab$catch` 只用于捕获量图。

The vertical label comes from `ylab$survey` and reads Survey index by default; set `acl_theme_set(ylab = list(survey = "Survey index (relative units)"))` to relabel every survey-fit plot at once, and single-model log-scale plots add the prefix Log. `ylab$catch` labels the catch plots only.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_compare_CatL)

<a id="plot_compare_metrics"></a>

<a id="compare_metrics"></a>
## 38. 拟合指标比较 / Fit metric comparison

```r
# 绘制本图 / Draw this figure
plot_compare_metrics(a, b, dat, facet_ncol = 2) & scale_y_continuous(expand = expansion(mult = c(0,
    0.3)))
```

[![拟合指标比较 / Fit metric comparison](figures/ytf/compare_metrics.png)](figures/ytf/compare_metrics.png)

柱图汇总 `diagnostic_metrics()` 的样本内拟合指标：RMSE、MAE、R 平方、MAPE、AIC、BIC、负对数似然和标量参数个数。ACL 为深蓝，ALSCL 为朱红。按各指标的定义解读：误差指标较低、R 平方较高表示对这些观测的拟合较近；AIC 和 BIC 还惩罚参数数量。信息准则只应在同一观测、相容似然的拟合之间比较。本例 ACL 的指标值较好；一个模拟数据集不能证明普遍优势，也不能确定差异原因。

Bars summarize the in-sample fit metrics from `diagnostic_metrics()`: RMSE, MAE, R-squared, MAPE, AIC, BIC, negative log-likelihood and the number of scalar parameters. ACL is navy and ALSCL vermilion. Read each metric according to its definition: lower error metrics and higher R-squared describe closer fits to these observations, whereas AIC and BIC also penalize parameter count. Compare information criteria only for compatible likelihoods fitted to the same observations. ACL has better metric values in this example; one simulated dataset does not establish a general advantage or identify its cause.

柱图与 `diagnostic_metrics()` 使用同一计算：只纳入有限的正观测，观测单元处的非有限预测或维度不一致会报错，常数观测的 R 平方等无定义指标显示为 `NA`。先运行 `compare_models()` 核对两组拟合是否可比。

The bars use the same calculation as `diagnostic_metrics()`: only finite positive observations enter, a nonfinite prediction at an observed cell or a dimension mismatch is an error, and an undefined measure such as R-squared for constant observations is shown as `NA`. Run `compare_models()` first to check that the two fits are comparable.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_compare_metrics)

<a id="plot_compare_selectivity"></a>

<a id="compare_selectivity"></a>
## 39. 固定调查可捕性 / Fixed survey catchability

```r
# 绘制本图 / Draw this figure
plot_compare_selectivity(a, b)
```

[![固定调查可捕性 / Fixed survey catchability](figures/ytf/compare_selectivity.png)](figures/ytf/compare_selectivity.png)

各拟合输入的体长别调查可捕性 `q`（`sel_L50`、`sel_L95`），ACL 为深蓝实线加点，ALSCL 为朱红虚线加点。用它确认每组拟合用的可捕性曲线；本例两条曲线重合，因为输入相同；这些值是固定输入而不是估计的选择性，两组拟合若不同，只说明输入不同。

Survey catchability `q` at length from the input of each fit (`sel_L50`, `sel_L95`), as lines with points for ACL (navy solid) and ALSCL (vermilion dashed). Use it to confirm which catchability curve each fit used; the curves coincide here because both fits took the same input, and the values are fixed inputs, not an estimated selectivity, so a difference between two fits means different inputs.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_compare_selectivity)

<a id="plot_compare_F_ts"></a>

<a id="compare_F_apical"></a>
## 40. 每个时间步的最大捕捞死亡率 / Maximum fishing mortality by time step

```r
# 绘制本图 / Draw this figure
plot_compare_F_ts(a, b, method = "apical") +
  labs(title = "Apical fishing mortality")
```

[![每个时间步的最大捕捞死亡率 / Maximum fishing mortality by time step](figures/ytf/compare_F_apical.png)](figures/ytf/compare_F_apical.png)

每个时间步内，ACL 取各年龄组捕捞死亡率的最大值，ALSCL 取各体长组的最大值，即 apical F。图中每个点对应该模型在该期估计 F 最高的组。即使针对同一种群，年龄组最大值与体长组最大值也未必相同，因为年龄别 F 汇总了各体长的存活；这时应读两条线的时间变化，不要比较水平。`basis = "age"` 对两个拟合都汇总年龄别 F，只用两者共有的拟合年龄和时间步。ALSCL 的年龄别 F 覆盖每个年龄和每个时间步；早期版本的拟合没有末组一行，也没有最后一个时间步的值。F 是每个时间步的瞬时率，所以两个拟合的时间步长必须相同，不同时函数会停止。季度拟合得到每季度的瞬时率，纵轴标签注明捕捞死亡率的时间基准。[BAM 模型中的 apical F，式（14b）](https://repository.library.noaa.gov/view/noaa/4847/noaa_4847_DS1.pdf#page=11)。

Apical F is the maximum fishing mortality rate across age classes in ACL or across length bins in ALSCL within each time step. The height of each point therefore refers to the group with the highest estimated F in that model and period. An age-group maximum and a length-bin maximum need not be equal, even for the same population, because age-specific F combines survival across lengths. Read the time pattern of such a pair, not the difference in level. `basis = "age"` summarizes F at age for both fits over the fitted ages and time steps that both have. ALSCL F at age covers every age and time step; fits made by earlier versions have no plus-group row and no value for the last time step. The two fits must have the same time step, because F is a rate per time step, and the function stops when the steps differ. Quarterly fits give quarterly rates, and the y-axis label states the time basis of the rate. [Apical F in the BAM model, eq. 14b](https://repository.library.noaa.gov/view/noaa/4847/noaa_4847_DS1.pdf#page=11).

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_compare_F_ts)

<a id="compare_F_mean"></a>
## 41. 每个时间步的平均捕捞死亡率 / Mean fishing mortality by time step

```r
# 绘制本图 / Draw this figure
plot_compare_F_ts(a, b, method = "mean") +
  labs(title = "Mean fishing mortality")
```

[![每个时间步的平均捕捞死亡率 / Mean fishing mortality by time step](figures/ytf/compare_F_mean.png)](figures/ytf/compare_F_mean.png)

两组拟合的平均捕捞死亡率，即每个时间步各组 `F` 的非加权平均，样式同上。当关心整个选择模式而不是其峰值时用它；平均值取决于模型有多少低 F 的组（本例 15 个年龄组对 23 个体长组），所以看时间模式（两者都在 2008 年达峰）而不是水平高低。

Mean fishing mortality, the unweighted average of `F` over the groups at each time step, for both fits in the same styling. Use it when the whole selection pattern matters more than its peak; the mean depends on how many low-F groups a model has (15 ages against 23 length bins here), so read the time pattern, which both fits share with a 2008 peak, rather than the level.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_compare_F_ts)

<a id="plot_retro"></a>

<a id="retro_ACL"></a>
## 42. ACL 回溯分析 / ACL retrospective analysis

```r
# 绘制本图 / Draw this figure
plot_retro(ra, facet_ncol = 2, rho_digits = 3, rho_size = 3, point_size = 1, line_size = 0.6)
```

[![ACL 回溯分析 / ACL retrospective analysis](figures/ytf/retro_ACL.png)](figures/ytf/retro_ACL.png)

ACL 拟合的回溯分析：每个量（`B`、`N`、`Rec`、`SSB`）一个面板，横轴为时间，每次拟合一条线，颜色按其最后时间步区分（图例“Terminal year”：完整拟合与各轮截短；未通过数值检查的拟合用虚线绘制），空心点为各拟合的末端估计，每个面板按 `rho_digits` 位小数标出 Mohn's rho。用它看去掉时间步后末端估计移动多少；各线贴合完整拟合、只在末尾几年分开，且 rho 很小（本例绝对值不超过 0.011），说明修正很小；若各量、各轮符号相同，则提示存在回溯模式。

Retrospective analysis of the ACL fit: one panel per quantity (`B`, `N`, `Rec`, `SSB`), time on the horizontal axis, one line per fit coloured by its last time step (legend "Terminal year": the full fit and the peels; a fit that failed the numerical checks is drawn with a dashed line), an open point at each fit's terminal estimate, and Mohn's rho printed in each panel with `rho_digits` decimals. Use it to see how far the terminal estimates move when time steps are removed; lines that lie on the full fit and split only in the last years, with rho no larger than 0.011 in size as here, show small revisions, while the same sign across quantities and peels would point to a retrospective pattern.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_retro)

<a id="retro_ALSCL"></a>
## 43. ALSCL 回溯分析 / ALSCL retrospective analysis

```r
# 绘制本图 / Draw this figure
plot_retro(rb, facet_ncol = 2, rho_digits = 3, rho_size = 3, point_size = 1, line_size = 0.6)
```

[![ALSCL 回溯分析 / ALSCL retrospective analysis](figures/ytf/retro_ALSCL.png)](figures/ytf/retro_ALSCL.png)

ALSCL 拟合的同一回溯分析，布局与颜色相同。用它比较两个模型的稳定性；本例生物量（0.022）、丰度（0.016）和产卵生物量（0.010）的 rho 更大，且三者都为正，说明较短的 ALSCL 拟合对这些量的末端估计高于完整拟合；补充量的 rho 很小且为负（−0.005）。这种轻微的向上修正在正式评估中值得关注。

The same retrospective analysis for the ALSCL fit, with the same layout and colours. Use it to compare the stability of the two models; the rho values are larger here for biomass (0.022), abundance (0.016) and spawning biomass (0.010), and all three are positive, so the shorter ALSCL fits end above the full fit for these quantities; rho for recruitment is small and negative (−0.005). A mild upward revision of this kind would deserve attention in a real assessment.

[参数及默认值 / Arguments and defaults](FUNCTION_REFERENCE.md#plot_retro)

<a id="truth"></a>
## 44. 模拟真值与条件估计 / Simulation truth and conditional estimates

```r
# 将生成真值与报告中的估计对齐 / Align truth and fitted reports
years <- a$year
truth <- data.frame(Year=rep(years,3),
  Quantity=rep(c("B","SSB","Rec"),each=length(years)),
  Truth=c(x$truth$TB,x$truth$SSB,x$truth$Rec))
estimates <- rbind(
  data.frame(Year=rep(years,3),Quantity=truth$Quantity,
    Value=c(a$report$B,a$report$SSB,a$report$Rec),Model="ACL"),
  data.frame(Year=rep(years,3),Quantity=truth$Quantity,
    Value=c(b$report$B,b$report$SSB,b$report$Rec),Model="ALSCL"))
```

```r
# 绘制本图 / Draw this figure
ggplot(estimates, aes(Year, Value, color = Model)) + geom_line() + scale_color_manual(values = setNames(acl_theme("compare_colors"),
    c("ACL", "ALSCL"))) + geom_line(data = truth, aes(Year, Truth), inherit.aes = FALSE, linetype = 2) +
    facet_wrap(~Quantity, scales = "free_y", ncol = 1) + theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()) + labs(y = NULL)
```

[![模拟真值与条件估计 / Simulation truth and conditional estimates](figures/ytf/truth.png)](figures/ytf/truth.png)

生成模拟的生物量、补充量和产卵生物量（黑色虚线）与 ACL（深蓝）、ALSCL（朱红）拟合的对照，每个量一个面板。上面的代码由 `x$truth` 和两份报告构造 `truth` 与 `estimates`。本例 ACL 紧贴模拟真值，ALSCL 的生物量和产卵生物量在 2013 年后低于真值。这是年龄结构操作模型的一次模拟及给定设置下的拟合。要评估表现如何随模型结构变化，需要在不同生成假设下开展重复模拟。

Biomass, recruitment and spawning biomass of the generating simulation (black dashed) and the ACL (navy) and ALSCL (vermilion) fits, one panel per quantity. The code above constructs `truth` and `estimates` from `x$truth` and the two reports. ACL follows the simulated truth closely here, while ALSCL biomass and spawning biomass fall below it after 2013. This is one realization from the age-based operating model under the stated fitting settings. Repeated simulations under alternative generating assumptions are needed to assess how performance depends on model structure.

