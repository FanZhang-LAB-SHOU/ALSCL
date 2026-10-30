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

只比较共同输出与相同时间窗；自由纵轴不能直接比较不同量的振幅。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_compare_ts)



## 死亡率矩阵比较

```r
# 绘制本图
plot_compare_F(a, b) + scale_x_continuous(breaks = c(2000, 2010, 2019))
```

[![死亡率矩阵比较](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_F.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_F.png?raw=true)

ACL 纵轴是年龄，ALSCL 纵轴是长度；颜色可辅助观察，但两行不逐格对应。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_compare_F)



## 残差联合诊断

```r
# 绘制本图
plot_compare_residuals(a, b, dat)
```

[![残差联合诊断](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_residuals.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_residuals.png?raw=true)

包括直方图、QQ 图、年度残差和长度组箱线图。年度误差棒是标准差，不是置信区间。


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

灰色参照曲线来自模拟 Age 与 Length；不代表论文实测生长。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_compare_growth)



## 两模型调查拟合

```r
# 绘制本图
plot_compare_CatL(a, b, dat, years = c(2000, 2005, 2010, 2015), ncol = 2)
```

[![两模型调查拟合](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_CatL.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_CatL.png?raw=true)

显示 4 个指定年份；省略 years 将显示全部年份。点为调查数据，线为拟合中位数。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_compare_CatL)



## 拟合指标比较

```r
# 绘制本图
plot_compare_metrics(a, b, dat, ncol = 2) & scale_y_continuous(expand = expansion(mult = c(0,
    0.3)))
```

[![拟合指标比较](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_metrics.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_metrics.png?raw=true)

当前数据由年龄模型生成。图示差异不能证明任一模型普遍较优；IC 还需要相同数据与似然口径。


指标柱图现在与 `diagnostic_metrics()` 共用计算方法，只纳入有限正观测；缺失值和零值不会再令全部误差指标变成 `NA`。观测单元中的非有限预测及维度不一致会报错；常数观测的 R² 等无定义指标仍保留为 `NA`。图形用于描述比较，解读差异前应使用 `compare_models()` 核对数据可比性和数值状态。

[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_compare_metrics)



## 固定调查可捕性

```r
# 绘制本图
plot_compare_selectivity(a, b)
```

[![固定调查可捕性](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_selectivity.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_selectivity.png?raw=true)

当前函数展示输入 q 的连接线，不是估计的渔业选择性。两模型使用同一输入，曲线重合。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_compare_selectivity)



## 总体 F 比较 apical

```r
# 绘制本图
plot_compare_annual_F(a, b, method = "apical") +
  labs(title = "Apical fishing mortality")
```

[![总体 F 比较 apical](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_F_apical.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_F_apical.png?raw=true)

apical 取最大值，mean 取组间算术平均，均非丰度加权。函数名称含 annual，但不会自动把季度率年化。


[参数及默认值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_compare_annual_F)



## 总体 F 比较 mean

```r
# 绘制本图
plot_compare_annual_F(a, b, method = "mean") +
  labs(title = "Mean fishing mortality")
```

[![总体 F 比较 mean](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_F_mean.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_F_mean.png?raw=true)

apical 取最大值，mean 取组间算术平均，均非丰度加权。函数名称含 annual，但不会自动把季度率年化。


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

黑虚线为生成真值；固定生物参数，且模拟与拟合的补充过程不同。

## 2.2.4 中比较同模型的两套配置

同一模型的两份结果会自动使用不同图例，例如 `ACL (group_year)` 和 `ACL (year)`，仍支持显式指定不同的 `model1_name`、`model2_name`。时间序列与 F 图保留每份结果自己的真实年份，可以显示不同时间范围。与 `data.CatL` 配对的图会核对已知时间和体长元数据，再匹配观测与预测；网格不一致时明确报错。图形比较不代表似然或生物假设具有可比性。

```r
a_group <- run_acl(x, F_structure = "group_year", silent = TRUE)
a_shared <- run_acl(x, F_structure = "year", silent = TRUE)
plot_compare_ts(a_group, a_shared, quantities = "SSB")
plot_compare_annual_F(a_group, a_shared)
plot_compare_F(a_group, a_shared)
```

### 2.2.5 的拟合数据匹配检查

`diagnostic_metrics()`、`diagnose_model()` 和 `compare_models()` 核对已知时间标签、体长标签、正观测掩码及拟合时保存的观测。即使维度相同，颠倒年份或体长组顺序也会报错。请传原始拟合表，例如 `diagnose_model(x$data.CatL, b)`；这些是样本内诊断，不是留出预测接口。缺少元数据的旧结果仍可计算原始指标，但不能据此确认模型可比较。

比较表和指标图共用计算规则：只使用有限正观测，常数观测的 R 方为 `NA`，观测位置的原尺度预测非有限时会报错；缺测与零值仍被排除。通过这些检查不代表模型在生物学上充分。

### 一致性修正

捕捞死亡率图按矩阵位置和拟合年份、组别元数据构造坐标，矩阵行列名不会改变坐标。生物量、SSB、捕获量和 F 的年龄分面在有无区间时都按数值组序排列。F 图和时间序列比较在 `se = TRUE` 时要求完整、有限的估计与有限非负标准误；缺失摘要会报错，不再重复填充或静默取消区间。只画估计时请明确使用 `se = FALSE`。

`plot_compare_ts()` 默认比较两模型共有的 SSB、补充量、B、N、CN。显式请求 CB 时，两模型都必须包含它（ACL 不报告 CB）；当前两模型均不报告 CB 标准误。请求的每种输出都必须存在；未知或不可用的输出会明确报错。捕捞死亡率请使用 `plot_compare_annual_F(a, b, method = "apical")` 或 `method = "mean"`。这两个选项分别取每个模型时期的组间最大值或非加权均值，不合并多个时期；该函数不提供汇总 F 的不确定性区间。

拟合、诊断和模型比较统一解析普通 data.frame、matrix、tibble 及保存数值文本的 factor 列。因子按标签转为观测值，不使用内部等级编码；体长标签按向量提取。修改了观测值、缺测掩码、年份或体长组顺序时，原有匹配检查仍会报错。
