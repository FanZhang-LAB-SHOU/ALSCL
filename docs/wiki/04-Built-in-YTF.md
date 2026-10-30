# 04 内置数据与首个拟合 · Built-in YTF

[← 上一章 · Previous](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/03-Data-and-Excel) · [目录 · Contents](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [下一章 · Next →](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/05-Simulation)

**ALSCL 2.2.8 · 简体中文 / English**

```r
install.packages("remotes")
remotes::install_github("FanZhang-LAB-SHOU/ALSCL")
library(ALSCL)
data("YTF_example")
x <- YTF_example
inputs <- x[c("data.CatL", "data.wgt", "data.mat")]
# 检查维度与来源 / Inspect dimensions and provenance
str(inputs)
x$provenance
# 两模型使用相同观测及条件设置 / Same observations and conditional settings
a <- run_acl(x, train_times = 2, silent = TRUE)
b <- run_alscl(x, train_times = 2, silent = TRUE)
plot_compare_ts(a, b, quantities = c("B", "SSB", "Rec"), se = TRUE)
```

ALSCL 2.2.0 支持直接使用 `run_acl(x)` 和 `run_alscl(x)`。对于 `YTF_example`，函数自动选择对应模型的 `fit_config`，显式传参可覆盖已有设置。原来的逐项传参和 `do.call()` 写法继续有效。两种写法共用内置加速，可查看 `a$sd_info` 或 `b$sd_info` 确认实际执行方式。

ALSCL 2.2.0 accepts `run_acl(x)` and `run_alscl(x)` directly. For `YTF_example`, each function selects its model-specific `fit_config` automatically; explicit call arguments override stored settings. The original separate-argument and `do.call()` forms remain valid. Both use the same built-in acceleration; inspect `a$sd_info` or `b$sd_info` for actual execution.

![模型比较 / Model comparison](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_ts.png?raw=true&v=92c7a56eb1fb)

| 对象 / Object | 内容和适用方式 / Contents and use |
|---|---|
| `YTF` | 原有 26 项参数列表，无 `data.CatL` / Original 26-element biological parameter list, no survey table |
| `YTF_example` | 23 个体长组 × 20 期；三张表、参数、模拟真值、拟合设置、来源 / 23 bins × 20 periods, three tables, parameters, truth, fit settings and provenance |
| `example_data` | 从原 ALSCL 保留的 9 组 × 21 年三张表；来源待核实 / Legacy ALSCL tables, 9 bins × 21 years, provenance unverified |

`YTF_example` 复用 `YTF` 的共有参数，特别是调查对数 SD = 0.1；其余采用 flatfish 模拟预设。随机种子 4，预热 80 年、保留 20 年；2000–2019 仅为示意年份。教学单位约定为 cm、kg，数据不是论文实测样本。调用 [data-raw/YTF_example.R](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/data-raw/YTF_example.R) 可重建 `.rda`，脚本恢复调用者的随机状态。

`YTF_example` reuses shared YTF parameters, including survey log SD 0.1, with remaining flatfish defaults. Seed 4, 80 burn-in years and 20 retained years are used. Dates are illustrative; cm and kg are teaching conventions. These are not empirical paper data. The data-raw script rebuilds the object and restores the caller's RNG state.

`x$fit_config` 固定已知生长、部分过程误差及相关参数，让示例聚焦工作流程。区间是在这些固定参数条件下的近似区间，不包含全部生物不确定性。这种教学拟合不能证明同时估计所有参数时可识别。

`x$fit_config` fixes known growth and selected process/correlation parameters. Intervals are conditional on these assumptions and omit their uncertainty. The example does not establish identifiability when all parameters are estimated together.

这仅指内置 `YTF_example` 的教学配置。第 5 节的正式数据导入脚本使用较少固定项的模型默认 map，勿混淆两者。 / This refers only to the bundled `YTF_example` teaching configuration. The own-data import script in section 5 uses the less restrictive model-default maps.

---

[← 上一章 · Previous](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/03-Data-and-Excel) · [目录 · Contents](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [下一章 · Next →](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/05-Simulation)
