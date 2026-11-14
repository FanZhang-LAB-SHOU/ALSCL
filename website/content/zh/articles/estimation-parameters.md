# 估计参数列表

本页列出两个模型的全部标量参数、它们到自然尺度的变换，以及一个预设的初值和边界。表中的键名就是 `parameters`、`parameters.L` 和 `parameters.U` 的条目名，都在优化尺度上填写。

|ACL 键名|ALSCL 键名|变换|含义|
|---|---|---|---|
| `log_init_Z` | `log_init_Z` | exp |用于构造初始年龄结构的总死亡率参数|
| `log_std_log_N0` | `log_sigma_log_N0` | exp |初始年龄结构中逐龄独立对数增量的标准差|
| `mean_log_R` | `mean_log_R` | exp |对数补充量过程的均值；exp 后为自然尺度的中位数|
| `log_std_log_R` | `log_sigma_log_R` | exp |对数补充量偏差的边际标准差|
| `logit_log_R` | `logit_log_R` | plogis；`correlation_range = "symmetric"` 时为 2 * plogis - 1 |补充 AR(1) 相关，默认在 0 和 1 之间，对称范围下在 -1 和 1 之间|
| `mean_log_F` | `mean_log_F` | exp |对数 F 过程的均值；exp 后为自然尺度的中位数|
| `log_std_log_F` | `log_sigma_log_F` | exp |对数 F 偏差的边际标准差|
| `logit_log_F_y` | `logit_log_F_y` | 同 `logit_log_R` |F 的时间相关|
| `logit_log_F_a` | `logit_log_F_l` | 同 `logit_log_R` |F 的年龄/体长相关|
| `log_vbk` | `log_vbk` | exp |VB k，单位为每年|
| `log_Linf` | `log_Linf` | exp |渐近体长|
| `t0` | `log_t0` |ACL 原值；ALSCL 为 `t0_lower` + exp|VB t0；ALSCL 中它大于 `t0_lower`（默认 0），因此除非把 `t0_lower` 设为负值，否则为正|
| `log_cv_len` | `log_cv_len` | exp |同龄个体体长的变异系数|
| 无 | `log_cv_grow` | exp |生长增量的变异系数|
| `log_std_index` | `log_sigma_index` | exp |对数调查观测 SD|

<h2 id="inspect">1. 查看一个预设</h2>

```r
p <- create_parameters(model_type = "alscl", species = "flatfish")
keys <- names(p$parameters)
parameter_table <- data.frame(
  Parameter = keys,
  Start = unlist(p$parameters[keys]),
  Lower = unlist(p$parameters.L[keys]),
  Upper = unlist(p$parameters.U[keys]))
parameter_table
p$parameters$log_sigma_index <- log(0.15)
p$parameters.U$log_sigma_index <- log(0.5)
fixed_index <- list(log_sigma_index = factor(NA))
```

`create_parameters()` 返回所选模型和预设的三个列表。改初值或边界后参数仍然自由；只有 `fixed_index` 这样的 `map` 条目才会固定它。随机效应 `dev_log_R`、`dev_log_F` 和 `dev_log_N0` 在上表中没有键名。`correlation_range` 和 `t0_lower` 的说明见[选择拟合设置](fitting-controls.html#correlation-range)。`create_parameters(model_type = "acl", bounds = "wide")` 返回的 ACL 列表中，有五个参数采用 ALSCL 的边界（[选择拟合设置](fitting-controls.html#starts)）。在采用原始结构的 ALSCL 中，`Linf` 和 `k` 决定体长别生长增量；两个模型中 F 过程和补充量过程的标准差都是边际标准差。这两点的说明见[模型原理与时间尺度](model-theory.html#paper-differences)。

<h2 id="next">下一步</h2>

| 想做什么 | 阅读 |
|---|---|
| 在输入列表中固定或释放参数 | [选择拟合设置](fitting-controls.html) |
| 在完整脚本中查看默认固定项和解除方法 | [如何拟合自己的调查数据？](case-fit-survey.html) |
