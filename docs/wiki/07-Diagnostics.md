# 07 诊断与结果解读 · Diagnostics

[← 上一章 · Previous](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/06-Fitting) · [目录 · Contents](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [下一章 · Next →](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/08-Population-Plots)

**ALSCL 2.2.2 · 简体中文 / English**

```r
# 数值检查 / Numerical checks
c(code = b$convergence_code, gradient = b$max_abs_gradient,
  pdHess = b$pdHess, boundary = b$bound_hit)
diagnose_model(x$data.CatL, b)
diagnostic_metrics(x$data.CatL, b)
comparison <- compare_models(a, b, x$data.CatL)
comparison$fit_metrics
comparison$correlation # 包括 Ratio_Mean / Includes Ratio_Mean
plot_residuals(b, type = "length", facet_ncol = 4)
plot_compare_residuals(a, b, x$data.CatL)
```

本次 YTF 主拟合的优化码均为 0，最大绝对梯度约为 ACL `1.22e-4`、ALSCL `5.75e-9`，Hessian 均正定，没有检测到边界命中。结果记录见 [convergence.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/convergence.csv)。梯度 < 0.001 是本教学流程的数值筛查阈值，不是适用于所有模型的科学有效性标准。

Both example fits returned code 0, positive-definite Hessians and no detected bound hits. Maximum absolute gradients were about `1.22e-4` and `5.75e-9`. The tutorial's 0.001 screening threshold is not a universal validity criterion.

还需查看残差结构、不同初值和固定参数假设的敏感性、时间末端稳定性以及生物合理性。图中残差是“观测对数 − 预测对数”，没有除以观测 SD；`plot_deviance` 展示的是过程偏差，不是似然 deviance。AIC/BIC 比较需使用相同观测与可比似然口径；当前由年龄模型生成的一个样本不能证明 ACL 或 ALSCL 普遍更好。

Also assess residual structure, sensitivity to starts and fixed assumptions, terminal stability and biological plausibility. Plotted residuals are raw log residuals, and process-deviation plots are not likelihood deviance. Information criteria require comparable observations and likelihoods; one age-generated sample cannot establish general model superiority.

2.2.3 起，`compare_models()` 会核对时间、体长标签、实际用于拟合的正观测及缺失掩码；已知不一致会报错。返回的 `fit_diagnostics` 和 `comparison` 说明数值状态和可比较性。若任一拟合不合格，或旧结果缺少核验数据的元信息，仍显示原始 AIC，但警告并取消自动偏好结论。保留的非零原始优化代码不单独决定失败，需结合收尾后的梯度、Hessian 和边界。

Since 2.2.3, compare_models checks periods, length labels, fitted positive observations and the missing-data mask. Known mismatches are errors. Its fit_diagnostics and comparison outputs record numerical status and comparability. Failed numerical screens or old objects with insufficient metadata retain raw AIC but produce a warning and no automatic preference. A nonzero raw optimizer code alone does not imply failure after refinement; examine the final gradient, Hessian and boundaries together.

`plot_compare_metrics()` 与 `diagnostic_metrics()` 使用同一套正观测筛选，NA 和零观测不会污染整组指标。`plot_fishing_mortality(b, type = "length", se = TRUE)` 对 ALSCL 以真实体长中点为横轴，按年份分面；year 模式保持以时间为横轴。ACL 没有独立的长度别 F，旧 length 别名仍画年龄别 F，但会警告，建议改用 age。

plot_compare_metrics uses the same positive-observation mask as diagnostic_metrics, excluding NA and zeros consistently. For ALSCL, plot_fishing_mortality(b, type = "length", se = TRUE) uses actual length midpoints on the horizontal axis and facets by year; year mode retains time on the horizontal axis. ACL has no independent F-at-length: its legacy length alias still plots F-at-age with a warning; use age explicitly.

---

[← 上一章 · Previous](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/06-Fitting) · [目录 · Contents](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [下一章 · Next →](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/08-Population-Plots)
