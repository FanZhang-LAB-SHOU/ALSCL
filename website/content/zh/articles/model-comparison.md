# 模型比较与真值

先完成 [YTF 拟合示例](first-model.html)，得到 `a`、`b`、`x`、`inputs`，并设置 `dat <- x$data.CatL`。加载 ggplot2 和 patchwork。[回溯分析指南](retrospectives.html) 建立 `ra`、`rb`。

```r
library(ggplot2)
library(patchwork)
acl_theme_set(palette="npg", base_theme="theme_bw")
```

## 种群时间序列比较

```r
# 绘制本图
plot_compare_ts(a, b, se = TRUE, ncol = 2)
```

[![种群时间序列比较](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_ts.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_ts.png?raw=true)

两组拟合的产卵生物量、补充量、总生物量、总丰度和捕获尾数时间序列，每个量一个面板，纵轴各自取值：ACL 为深蓝实线，ALSCL 为朱红虚线（`compare_colors`、`compare_linetypes`），`se = TRUE` 时加上各自的 95% 区间。用它看两个模型在哪里分歧；本例生物量和产卵生物量在 2014 年后分开，自由纵轴使振幅只能在面板内比较，不能跨面板比较。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_compare_ts)

## 死亡率矩阵比较

```r
# 绘制本图
plot_compare_F(a, b) + scale_x_continuous(breaks = c(2000, 2010, 2019))
```

[![死亡率矩阵比较](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_F.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_F.png?raw=true)

两组拟合各一张捕捞死亡率热图，横轴为时间，纵轴为各自的组（ACL 为年龄组，ALSCL 为体长组），共用一个 `F` 色标。用它看每个模型中捕捞在何时、哪些组最重；两图的行是不同维度，所以比较深色列的时间（本例 2007 至 2010 年）而不是逐格比较，一对一的比较用总体 F 图。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_compare_F)

## 残差联合诊断

```r
# 绘制本图
plot_compare_residuals(a, b, dat)
```

[![残差联合诊断](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_residuals.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_residuals.png?raw=true)

两组拟合的样本内对数残差四联图：直方图、对正态分布的 QQ 图、各时间步的平均残差及加减一个标准差的误差棒（不是置信区间）、各体长组绝对残差的箱线图；ACL 为深蓝，ALSCL 为朱红。用它判断哪组拟合留下的结构更少：直方图更宽、QQ 点偏离直线表示残差更大（本例的 ALSCL），高箱体标出该拟合偏差大的体长组（本例 ALSCL 的 16 组和 50 组）。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_compare_residuals)

## 生长与外部参照接口

参考数据与排版辅助函数

```r
# 模拟参考生长点，并非论文实测
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
# 绘制本图
growth_display(plot_compare_growth(a, b, age_range = c(1, 15), ref_data = ref, ref_name = "Synthetic reference",
    nls_start = list(Linf = 60, k = 0.2, t0 = 1/60)))
```

[![生长与外部参照接口](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_growth.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_growth.png?raw=true)

左图：两组拟合的 von Bertalanffy 曲线（ACL 深蓝实线，ALSCL 朱红虚线），副标题给出各自的 `Linf` 和 `k`，另有 `nls()` 对 `ref_data` 拟合的灰色参照曲线及该数据的灰点；右图：两组拟合的年龄体长矩阵热图，纵轴为体长组序号。用它看两个模型是否假设相同的生长，以及它们与独立年龄体长数据的差距；本例两条曲线重合，因为生长固定为相同值，参照数据由上面的代码生成，是模拟值而非实测。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_compare_growth)

## 两模型调查拟合

```r
# 绘制本图
plot_compare_CatL(a, b, dat, years = c(2000, 2005, 2010, 2015), ncol = 2)
```

[![两模型调查拟合](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_CatL.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_CatL.png?raw=true)

所选时间步（`years`，省略则显示全部）的调查指数随体长变化，每个时间步一个面板：灰点为观测指数，深蓝实线为 ACL 拟合，朱红虚线为 ALSCL 拟合，均为 `exp(Elog_index)` 中位数，零值和缺失观测不画点。用它看哪个模型跟得上观测的体长组成；本例两者都跟上 20 附近的峰，ALSCL 曲线起伏更多，因为它的 F 按体长组变化。

纵轴标签来自 `ylab$survey`，默认为 Survey index；用 `acl_theme_set(ylab = list(survey = "Survey index (relative units)"))` 可一次改好所有调查拟合图的标签，单模型对数图会加上前缀 Log。`ylab$catch` 只用于捕获量图。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_compare_CatL)

## 拟合指标比较

```r
# 绘制本图
plot_compare_metrics(a, b, dat, ncol = 2) & scale_y_continuous(expand = expansion(mult = c(0,
    0.3)))
```

[![拟合指标比较](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_metrics.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_metrics.png?raw=true)

两组拟合由 `diagnostic_metrics()` 得到的拟合指标柱图：RMSE 与 MAE、R 平方、MAPE、AIC、BIC 与负对数似然、标量参数个数，柱上标数值；ACL 深蓝，ALSCL 朱红。用它概括拟合质量：误差指标和信息准则越低、R 平方越高越好，本例 ACL 更好在意料之中，因为数据由年龄模型生成；信息准则只能在同一数据、同一似然的拟合之间比较。

柱图与 `diagnostic_metrics()` 使用同一计算：只纳入有限的正观测，观测单元处的非有限预测或维度不一致会报错，常数观测的 R 平方等无定义指标显示为 `NA`。先运行 `compare_models()` 核对两组拟合是否可比。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_compare_metrics)

## 固定调查可捕性

```r
# 绘制本图
plot_compare_selectivity(a, b)
```

[![固定调查可捕性](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_selectivity.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_selectivity.png?raw=true)

各拟合输入的体长别调查可捕性 `q`（`sel_L50`、`sel_L95`），ACL 为深蓝实线加点，ALSCL 为朱红虚线加点。用它确认每组拟合用的可捕性曲线；本例两条曲线重合，因为输入相同；这些值是固定输入而不是估计的选择性，两组拟合若不同，只说明输入不同。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_compare_selectivity)

## 总体 F 比较 apical

```r
# 绘制本图
plot_compare_annual_F(a, b, method = "apical") +
  labs(title = "Apical fishing mortality")
```

[![总体 F 比较 apical](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_F_apical.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_F_apical.png?raw=true)

两组拟合的顶点捕捞死亡率，即每个时间步各组 `F` 的最大值（ACL 深蓝实线，ALSCL 朱红虚线，每个时间步一点）；`labs(title = ...)` 替换默认标题。用它在同一坐标上比较年龄模型与体长模型的总体捕捞压力；本例 ALSCL 更高，因为它的最大值落在选择性最强的体长组；函数名虽含 annual，但汇总在每个时间步内进行，季度拟合显示的仍是季度率。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_compare_annual_F)

## 总体 F 比较 mean

```r
# 绘制本图
plot_compare_annual_F(a, b, method = "mean") +
  labs(title = "Mean fishing mortality")
```

[![总体 F 比较 mean](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_F_mean.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_F_mean.png?raw=true)

两组拟合的平均捕捞死亡率，即每个时间步各组 `F` 的非加权平均，样式同上。当关心整个选择模式而不是其峰值时用它；平均值取决于模型有多少低 F 的组（本例 15 个年龄组对 23 个体长组），所以看时间模式（两者都在 2008 年达峰）而不是水平高低。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_compare_annual_F)

## 模拟真值与条件估计

```r
# 将生成真值与报告中的估计对齐
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
# 绘制本图
ggplot(estimates, aes(Year, Value, color = Model)) + geom_line() + scale_color_manual(values = setNames(acl_theme("compare_colors"),
    c("ACL", "ALSCL"))) + geom_line(data = truth, aes(Year, Truth), inherit.aes = FALSE, linetype = 2) +
    facet_wrap(~Quantity, scales = "free_y", ncol = 1) + theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()) + labs(y = NULL)
```

[![模拟真值与条件估计](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/truth.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/truth.png?raw=true)

生成模拟的生物量、补充量和产卵生物量（黑色虚线）与 ACL（深蓝）、ALSCL（朱红）拟合的对照，每个量一个面板；上面的代码由 `x$truth` 和两份报告构造 `truth` 与 `estimates`。只在模拟数据上用它看哪组拟合更接近真值；本例 ACL 紧贴虚线，因为数据来自同样固定生物参数的年龄模型，ALSCL 的生物量和产卵生物量在 2012 年后低于真值，与时间序列比较图中的差距相同。

