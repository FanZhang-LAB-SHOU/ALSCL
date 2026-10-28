# 调查与种群图

先完成 [YTF 拟合示例](first-model.html)，得到 `a`、`b`、`x`、`inputs`，并设置 `dat <- x$data.CatL`。加载 ggplot2 和 patchwork。[回溯分析指南](retrospectives.html) 建立 `ra`、`rb`。

```r
library(ggplot2)
library(patchwork)
acl_theme_set(palette="npg", base_theme="theme_bw")
```

## 调查拟合 length 对数尺度

```r
# 绘制本图
plot_CatL(b, type = "length", exp_transform = FALSE, facet_ncol = 4,
  point_size = 1, line_size = 0.6,
  x_breaks = c(2000, 2010, 2015),
  ylab = "Log survey index")
```

[![调查拟合 length 对数尺度](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/CatL_length_FALSE.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/CatL_length_FALSE.png?raw=true)

点为观测对数，曲线为拟合的 Elog_index。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_CatL)



## 调查拟合 length 原尺度

```r
# 绘制本图
plot_CatL(b, type = "length", exp_transform = TRUE, facet_ncol = 4,
  point_size = 1, line_size = 0.6,
  x_breaks = c(2000, 2010, 2015),
  ylab = "Survey index")
```

[![调查拟合 length 原尺度](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/CatL_length_TRUE.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/CatL_length_TRUE.png?raw=true)

原尺度曲线为 exp(Elog_index)，即对数正态中位数。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_CatL)



## 调查拟合 year 对数尺度

```r
# 绘制本图
plot_CatL(b, type = "year", exp_transform = FALSE, facet_ncol = 4,
  point_size = 1, line_size = 0.6,
  x_breaks = c(10, 30, 50),
  ylab = "Log survey index")
```

[![调查拟合 year 对数尺度](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/CatL_year_FALSE.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/CatL_year_FALSE.png?raw=true)

朱红色为观测对数，深蓝色为拟合的 Elog_index。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_CatL)



## 调查拟合 year 原尺度

```r
# 绘制本图
plot_CatL(b, type = "year", exp_transform = TRUE, facet_ncol = 4,
  point_size = 1, line_size = 0.6,
  x_breaks = c(10, 30, 50),
  ylab = "Survey index")
```

[![调查拟合 year 原尺度](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/CatL_year_TRUE.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/CatL_year_TRUE.png?raw=true)

原尺度曲线为 exp(Elog_index)，即对数正态中位数。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_CatL)



## 丰度 N

```r
# 绘制本图
plot_abundance(b, type = "N", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![丰度 N](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_abundance_N.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_abundance_N.png?raw=true)

ALSCL 示例；A 表示年龄组，L 表示长度组。有可用标准误时显示近似 95% 区间。 总量图显示各组之和；分面图的纵轴按组调整。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_abundance)



## 丰度 NA

```r
# 绘制本图
plot_abundance(b, type = "NA", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![丰度 NA](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_abundance_NA.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_abundance_NA.png?raw=true)

ALSCL 示例；A 表示年龄组，L 表示长度组。有可用标准误时显示近似 95% 区间。 总量图显示各组之和；分面图的纵轴按组调整。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_abundance)



## 丰度 NL

```r
# 绘制本图
plot_abundance(b, type = "NL", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![丰度 NL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_abundance_NL.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_abundance_NL.png?raw=true)

ALSCL 示例；A 表示年龄组，L 表示长度组。有可用标准误时显示近似 95% 区间。 总量图显示各组之和；分面图的纵轴按组调整。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_abundance)



## 生物量 B

```r
# 绘制本图
plot_biomass(b, type = "B", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![生物量 B](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_biomass_B.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_biomass_B.png?raw=true)

ALSCL 示例；A 表示年龄组，L 表示长度组。有可用标准误时显示近似 95% 区间。 总量图显示各组之和；分面图的纵轴按组调整。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_biomass)



## 生物量 BA

```r
# 绘制本图
plot_biomass(b, type = "BA", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![生物量 BA](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_biomass_BA.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_biomass_BA.png?raw=true)

ALSCL 示例；A 表示年龄组，L 表示长度组。有可用标准误时显示近似 95% 区间。 总量图显示各组之和；分面图的纵轴按组调整。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_biomass)



## 生物量 BL

```r
# 绘制本图
plot_biomass(b, type = "BL", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![生物量 BL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_biomass_BL.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_biomass_BL.png?raw=true)

ALSCL 示例；A 表示年龄组，L 表示长度组。有可用标准误时显示近似 95% 区间。 总量图显示各组之和；分面图的纵轴按组调整。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_biomass)



## 产卵生物量 SSB

```r
# 绘制本图
plot_SSB(b, type = "SSB", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![产卵生物量 SSB](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_SSB_SSB.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_SSB_SSB.png?raw=true)

ALSCL 示例；A 表示年龄组，L 表示长度组。有可用标准误时显示近似 95% 区间。 总量图显示各组之和；分面图的纵轴按组调整。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_SSB)



## 产卵生物量 SBA

```r
# 绘制本图
plot_SSB(b, type = "SBA", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![产卵生物量 SBA](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_SSB_SBA.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_SSB_SBA.png?raw=true)

ALSCL 示例；A 表示年龄组，L 表示长度组。有可用标准误时显示近似 95% 区间。 总量图显示各组之和；分面图的纵轴按组调整。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_SSB)



## 产卵生物量 SBL

```r
# 绘制本图
plot_SSB(b, type = "SBL", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![产卵生物量 SBL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_SSB_SBL.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_SSB_SBL.png?raw=true)

ALSCL 示例；A 表示年龄组，L 表示长度组。有可用标准误时显示近似 95% 区间。 总量图显示各组之和；分面图的纵轴按组调整。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_SSB)



## 捕获尾数 CN

```r
# 绘制本图
plot_catch(b, type = "CN", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![捕获尾数 CN](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_catch_CN.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_catch_CN.png?raw=true)

ALSCL 示例；A 表示年龄组，L 表示长度组。有可用标准误时显示近似 95% 区间。 捕获尾数是模型推算的渔业捕获，不是调查指数。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_catch)



## 捕获尾数 CNA

```r
# 绘制本图
plot_catch(b, type = "CNA", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![捕获尾数 CNA](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_catch_CNA.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_catch_CNA.png?raw=true)

ALSCL 示例；A 表示年龄组，L 表示长度组。有可用标准误时显示近似 95% 区间。 捕获尾数是模型推算的渔业捕获，不是调查指数。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_catch)



## 捕获尾数 CNL

```r
# 绘制本图
plot_catch(b, type = "CNL", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![捕获尾数 CNL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_catch_CNL.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_catch_CNL.png?raw=true)

ALSCL 示例；A 表示年龄组，L 表示长度组。有可用标准误时显示近似 95% 区间。 捕获尾数是模型推算的渔业捕获，不是调查指数。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_catch)



## 补充量

```r
# 绘制本图
plot_recruitment(b, se = TRUE)
```

[![补充量](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/recruitment.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/recruitment.png?raw=true)

补充量对应最小年龄组；受设定的补充年龄和时间步长影响。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_recruitment)



## 亲体与补充关系

```r
# 绘制本图
plot_SSB_Rec(b, age_at_recruitment = 1)
```

[![亲体与补充关系](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/SSB_Rec.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/SSB_Rec.png?raw=true)

本年度示例按 1 年（1 个观测步）对齐 SSB 与后续补充量；季度数据会自动换算为 4 步。这里只画散点，不拟合资源补充函数。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_SSB_Rec)

## 2.2.4 的缺测与保存结果绘图

`plot_ridges()` 和 `plot_residuals()` 使用保存的 `observations`，保留与拟合一致的正观测掩码；旧结果可读取 TMB 数据。NA 和拟合时排除的零值不会变成人造观测或零残差。整期缺测不绘制观测山脊；部分缺测时，观测比例只在有效正观测中归一化，预测比例则覆盖全部体长组，不能把它解释为未观测组也拟合良好。保留 `observations` 的拟合结果移除 `obj` 后仍可使用这两个绘图函数。

```r
portable <- b
portable$obj <- NULL
plot_residuals(portable)
plot_ridges(portable)
```

## 季度网格上的补充滞后

`age_at_recruitment` 的单位是年。`plot_SSB_Rec()` 除以拟合的 `growth_step`，要求在规则时间网格上对应整数个时间步。季度数据中，0.25 表示滞后一季度，1 表示四季度。允许零滞后；拒绝负值、非有限值及非整数步滞后。旧结果没有 `growth_step` 时使用规则年份间隔；两类时间元数据都没有时沿用年度步长。

```r
q <- list(year = 2000 + (0:7)/4, growth_step = 0.25,
          report = list(SSB = 1:8, Rec = 101:108))
paired <- plot_SSB_Rec(q, age_at_recruitment = 0.25, return_data = TRUE)$data
stopifnot(identical(paired$SSB, 1:7), identical(paired$Rec, 102:108))
```

### 2.2.5 的模型、输出与区间支持范围

`se = TRUE` 请求逐点近似 95% 区间（`估计值 ± 1.96 × 标准误`）。体长别生物量和产卵生物量现在会绘制可用区间。数量或标准误不可用时会明确报错；确实只需要估计线时才使用 `se = FALSE`。解释区间前仍须检查收敛与 Hessian。

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

### 2.2.5 默认无网格线

所有包内绘图默认去掉主、次面板网格线，包括模型比较和回溯图；配色、置信区间及坐标轴保留原设置。升级后需重新创建旧图，才会应用新默认值。以下使用完整拟合示例中的 `b`，对旧图或手写 ggplot 图明确应用无网格样式：

```r
p <- plot_SSB(b, se = TRUE)
p + ggplot2::theme(panel.grid.major = ggplot2::element_blank(),
                   panel.grid.minor = ggplot2::element_blank())
```

2.2.6 进一步保证 SSB、丰度、生物量、捕获量、偏差和捕捞死亡率图在主题加载失败后的回退路径也不显示网格。显式指定的主题仍优先。说明书的 ggplot 导出统一检查各子图的主、次网格；发现网格时停止导出并保留原文件。正式 2.2.6 下载包包含更新后的帮助图片。

### 2.2.7 的保存结果与不确定性

丰度图按矩阵位置和拟合结果中的 `year`、`len_label` 对齐。给 `report$NA` 或 `report$NL` 添加行列名称，不会改变年份或组别对应关系。保存结果时应一起保留矩阵原有顺序和拟合元数据。

丰度、补充量和过程偏差的区间需要完整的有限估计值，以及有限、非负的标准误。标准误缺失、非法或不完整时会明确报错。只需绘制估计值时使用 `se = FALSE`；过程偏差图此时读取 `report$dev_log_R` 或 `report$dev_log_F`，没有 `est_std` 也可绘制，旧结果可使用有效摘要表中的估计值。解释区间前仍须查看拟合诊断。

```r
saved <- b
saved$obj <- NULL
saved$est_std <- NULL
plot_abundance(saved, type = "NL", se = FALSE)
plot_recruitment(saved, se = FALSE)
plot_deviance(saved, type = "F", se = FALSE)
```
