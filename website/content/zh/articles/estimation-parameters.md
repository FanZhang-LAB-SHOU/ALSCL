# 估计参数列表

本页列出两个模型的全部标量参数、它们到自然尺度的变换，以及一个预设的初值和边界。表中的键名就是 `parameters`、`parameters.L` 和 `parameters.U` 的条目名，都在优化尺度上填写。

|ACL 键名|ALSCL 键名|变换|含义|
|---|---|---|---|
| `log_init_Z` | `log_init_Z` | exp |初始平衡总死亡率|
| `log_std_log_N0` | `log_sigma_log_N0` | exp |初始年龄尾数偏差 SD|
| `mean_log_R` | `mean_log_R` | exp |对数补充过程的位置参数|
| `log_std_log_R` | `log_sigma_log_R` | exp |对数补充过程 SD 缩放|
| `logit_log_R` | `logit_log_R` | plogis |补充 AR(1) 相关，限定 (0,1)|
| `mean_log_F` | `mean_log_F` | exp |对数 F 过程的位置参数|
| `log_std_log_F` | `log_sigma_log_F` | exp |F 偏差 SD 缩放|
| `logit_log_F_y` | `logit_log_F_y` | plogis |F 的时间相关|
| `logit_log_F_a` | `logit_log_F_l` | plogis |F 的年龄/体长相关|
| `log_vbk` | `log_vbk` | exp |VB k，单位为每年|
| `log_Linf` | `log_Linf` | exp |渐近体长|
| `t0` | `log_t0` |ACL 原值；ALSCL exp|VB t0；ALSCL 限定为正值|
| `log_cv_len` | `log_cv_len` | exp |年龄体长 CV|
| 无 | `log_cv_grow` | exp |增长增量 CV|
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

`create_parameters()` 返回所选模型和预设的三个列表。改初值或边界后参数仍然自由；只有 `fixed_index` 这样的 `map` 条目才会固定它。随机效应 `dev_log_R`、`dev_log_F` 和 `dev_log_N0` 在上表中没有键名。

<h2 id="next">下一步</h2>

| 想做什么 | 阅读 |
|---|---|
| 在输入列表中固定或释放参数 | [选择拟合设置](fitting-controls.html) |
| 在完整脚本中查看默认固定项和解除方法 | [如何拟合自己的调查数据？](case-fit-survey.html) |
