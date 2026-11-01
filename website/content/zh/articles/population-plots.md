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

每个体长组一个面板，横轴为时间，纵轴为对数调查指数：朱红色点为观测的对数指数，深蓝色曲线为拟合的 `Elog_index`。用它逐组检查拟合；点连续偏在曲线一侧（如本例的 16 组和 50 组）说明该组被系统低估或高估，对数尺度让大小体长组的偏离同样可读。

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

同样的面板改为原尺度：深蓝色曲线为 `exp(Elog_index)`，即拟合对数正态分布的中位数，朱红色点为观测指数。用它按指数单位读取偏差；误差是乘性的，高值处看似很大的差距与低值处的小差距可能是相同的相对偏差。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_CatL)

## 调查拟合 year 对数尺度

```r
# 绘制本图
plot_CatL(b, type = "year", exp_transform = FALSE, facet_ncol = 4,
  line_size1 = 0.6, line_size2 = 0.4,
  x_breaks = c(10, 30, 50),
  ylab = "Log survey index")
```

[![调查拟合 year 对数尺度](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/CatL_year_FALSE.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/CatL_year_FALSE.png?raw=true)

`line_size1 = 0.6` 控制拟合线，`line_size2 = 0.4` 控制观测线。`type = "year"` 应使用这两个参数，而不是体长模式的 `line_size` 和 `point_size`。

每个时间步一个面板，横轴为体长，纵轴为对数调查指数：细朱红线为观测对数指数随体长的变化，粗深蓝线为拟合的 `Elog_index`。用它检查同一时间步内的拟合形状；深蓝线没有跟上的突起（如本例后几年最大体长组处）就是拟合未能解释的体长结构。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_CatL)

## 调查拟合 year 原尺度

```r
# 绘制本图
plot_CatL(b, type = "year", exp_transform = TRUE, facet_ncol = 4,
  line_size1 = 0.6, line_size2 = 0.4,
  x_breaks = c(10, 30, 50),
  ylab = "Survey index")
```

[![调查拟合 year 原尺度](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/CatL_year_TRUE.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/CatL_year_TRUE.png?raw=true)

`line_size1 = 0.6` 控制拟合线，`line_size2 = 0.4` 控制观测线。`type = "year"` 应使用这两个参数，而不是体长模式的 `line_size` 和 `point_size`。

同样的面板改为原尺度，曲线为 `exp(Elog_index)` 中位数与观测指数。用它看每个时间步的指数主要来自哪些体长；峰的位置和高度显示调查捕到的主要体长，观测峰偏离深蓝线的时间步值得再看残差图。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_CatL)

## 丰度 N

```r
# 绘制本图
plot_abundance(b, type = "N", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![丰度 N](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_abundance_N.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_abundance_N.png?raw=true)

各组之和的总丰度随时间步变化；阴影为近似 95% 区间，即估计值加减 1.96 倍标准误。用它看全种群的趋势及其精度；本例 2012 年的跳升是同年的强补充量进入最小年龄组。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_abundance)

## 丰度 NA

```r
# 绘制本图
plot_abundance(b, type = "NA", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![丰度 NA](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_abundance_NA.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_abundance_NA.png?raw=true)

年龄别丰度，每个年龄组一个面板，纵轴各自取值，均带 95% 区间。用它追踪年级群：强年级群表现为每个时间步向右移一个面板的峰；年龄越大区间越宽，因为老龄组数量少，调查对它们的信息也少。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_abundance)

## 丰度 NL

```r
# 绘制本图
plot_abundance(b, type = "NL", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![丰度 NL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_abundance_NL.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_abundance_NL.png?raw=true)

体长别丰度，每个体长组一个面板，均带 95% 区间。用它看数量集中在哪些体长；本例 2012 年的峰先出现在小体长组，随年级群生长再出现在较大的组，最大的组变化平缓，因为鱼在此累积。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_abundance)

## 生物量 B

```r
# 绘制本图
plot_biomass(b, type = "B", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![生物量 B](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_biomass_B.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_biomass_B.png?raw=true)

总生物量随时间步变化，带 95% 区间。与总丰度对照：小鱼体重小，所以生物量比丰度平滑，补充量脉冲要等年级群长大后才在生物量中显现。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_biomass)

## 生物量 BA

```r
# 绘制本图
plot_biomass(b, type = "BA", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![生物量 BA](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_biomass_BA.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_biomass_BA.png?raw=true)

年龄别生物量，每个年龄组一个面板，纵轴各自取值，带 95% 区间。用它看生物量集中在哪些年龄；注意各面板的纵轴刻度，自由刻度会让数量很小的老龄组看起来和大的年轻组一样多变。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_biomass)

## 生物量 BL

```r
# 绘制本图
plot_biomass(b, type = "BL", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![生物量 BL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_biomass_BL.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_biomass_BL.png?raw=true)

体长别生物量，每个体长组一个面板，带 95% 区间。用它看生物量集中在哪些体长；本例 36 以上各组占大部分，它们在 2013 年后的上升是 2012 年级群长入大体长组。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_biomass)

## 产卵生物量 SSB

```r
# 绘制本图
plot_SSB(b, type = "SSB", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![产卵生物量 SSB](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_SSB_SSB.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_SSB_SSB.png?raw=true)

产卵生物量随时间步变化，带 95% 区间。用它作为资源状态序列：只有成熟鱼计入，所以它滞后于总生物量；本例 2010 年前后的低点之后才出现回升。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_SSB)

## 产卵生物量 SBA

```r
# 绘制本图
plot_SSB(b, type = "SBA", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![产卵生物量 SBA](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_SSB_SBA.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_SSB_SBA.png?raw=true)

年龄别产卵生物量，每个年龄组一个面板，带 95% 区间。用它看产卵来自哪些年龄；最小的几个年龄组接近零，因为成熟比例表几乎不给它们成熟个体，比较面板时看纵轴数值而不是曲线形状。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_SSB)

## 产卵生物量 SBL

```r
# 绘制本图
plot_SSB(b, type = "SBL", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![产卵生物量 SBL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_SSB_SBL.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_SSB_SBL.png?raw=true)

体长别产卵生物量，每个体长组一个面板，带 95% 区间。用它看产卵来自哪些体长；小体长组同样接近零，30 以上的成熟组走势与总产卵生物量一致。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_SSB)

## 捕获尾数 CN

```r
# 绘制本图
plot_catch(b, type = "CN", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![捕获尾数 CN](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_catch_CN.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_catch_CN.png?raw=true)

捕获尾数随时间步变化，带 95% 区间。捕获量由模型根据丰度和捕捞死亡率推算，YTF 数据没有渔获观测；用它与已知的渔获量对照，宽区间说明仅凭调查对捕获量的约束较弱。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_catch)

## 捕获尾数 CNA

```r
# 绘制本图
plot_catch(b, type = "CNA", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![捕获尾数 CNA](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_catch_CNA.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_catch_CNA.png?raw=true)

年龄别捕获尾数，每个年龄组一个面板，带 95% 区间。用它看渔业主要移除哪些年龄；本例捕获集中在 1 至 3 龄，因为小鱼数量多，老龄组的区间更宽。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_catch)

## 捕获尾数 CNL

```r
# 绘制本图
plot_catch(b, type = "CNL", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![捕获尾数 CNL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_catch_CNL.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_catch_CNL.png?raw=true)

体长别捕获尾数，每个体长组一个面板，带 95% 区间。与体长别捕捞死亡率对照：某组的捕获等于该组丰度与捕捞死亡率的乘积，F 高但捕获少的组只是鱼少。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_catch)

## 补充量

```r
# 绘制本图
plot_recruitment(b, se = TRUE)
```

[![补充量](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/recruitment.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/recruitment.png?raw=true)

各时间步进入最小年龄组的补充量，带 95% 区间；纵轴标签为 `ylab$rec`。用它找强弱年级群：本例 2012 年的峰就是之后丰度和生物量上升的来源，它对应的日历时间取决于 `rec.age` 和时间步长。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_recruitment)

## 亲体与补充关系

```r
# 绘制本图
plot_SSB_Rec(b, age_at_recruitment = 1)
```

[![亲体与补充关系](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/SSB_Rec.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/SSB_Rec.png?raw=true)

横轴为某时间步的产卵生物量，纵轴为 `age_at_recruitment` 年后的补充量，每对一点，不拟合曲线。用它看补充量是否随产卵生物量变化；本例各点没有关系，这在意料之中，因为模型逐时间步自由估计补充量，而不用亲体补充函数。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_SSB_Rec)

## 季度网格上的补充滞后

`age_at_recruitment` 的单位是年。`plot_SSB_Rec()` 除以拟合的 `growth_step`，要求在规则时间网格上对应整数个时间步。季度数据中，0.25 表示滞后一季度，1 表示四季度。允许零滞后；拒绝负值、非有限值及非整数步滞后。没有 `growth_step` 的结果使用规则年份间隔；两类时间元数据都没有时沿用年度步长。

```r
q <- list(year = 2000 + (0:7)/4, growth_step = 0.25,
          report = list(SSB = 1:8, Rec = 101:108))
paired <- plot_SSB_Rec(q, age_at_recruitment = 0.25, return_data = TRUE)$data
stopifnot(identical(paired$SSB, 1:7), identical(paired$Rec, 102:108))
```
