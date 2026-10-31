# 15 进阶、复现与故障处理 · Reproducibility

[← 上一章 · Previous](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/14-Function-Reference) · [目录 · Contents](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [下一章 · Next →](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/16-Assessment-Workflows)

**ALSCL 2.2.9 · 简体中文 / English**

## 固定参数敏感性 · Sensitivity to fixed assumptions

改变 M、q 或固定 CV 可能明显改变绝对丰度与 SSB。一次改变一个有科学依据的假设，使用同一观测，保留数值诊断和全过程设置，而不是只寻找最小 AIC。

Changing M, q or fixed CV can alter abundance and SSB. Vary justified assumptions on identical observations and retain diagnostics, rather than optimizing assumptions solely for AIC.

```r
# 使用指南中的 inputs、x / Use inputs and x defined in the guide
sensitivity <- lapply(c(.15, .20, .25), function(M_value) {
  biology <- x$fit_args
  biology$M <- M_value
  fit <- do.call(run_alscl, c(inputs, biology, x$fit_config$alscl,
                             list(train_times=2, silent=TRUE)))
  list(M=M_value, diagnostics=diagnose_model(x$data.CatL, fit), fit=fit)
})
# 确认每个诊断后比较 / Inspect each diagnostic before comparison
lapply(sensitivity, function(z) z$diagnostics)
plot_compare_ts(sensitivity[[1]]$fit, sensitivity[[3]]$fit,
                model1_name="M = 0.15", model2_name="M = 0.25")
```

释放参数前先检查上下界和映射：`generate_map(list(t0=NULL))` 释放 ACL 默认固定的 t0；ALSCL 使用 `log_t0`，不能直接套同一列表。对自由参数可使用多个合理起点，比较目标函数、梯度与派生量。

Review bounds and maps before releasing parameters. ACL and ALSCL use different t0 parameterizations. Compare objectives, gradients and derived quantities across credible starting values.

## 并行与编译 · Parallelism and compilation

```r
# CPU 数量未知时回退单进程 / Fall back safely when core count is unavailable
cores <- parallel::detectCores()
workers <- if (is.na(cores)) 1L else max(1L, min(4L, cores - 1L))
# 在原拟合中替换 ncores，不重复传参 / Supply ncores once
multi <- do.call(run_acl, c(inputs, x$fit_args, x$fit_config$acl,
                           list(ncores=workers, train_times=2, silent=TRUE)))
```

| 入口 / Entry | ncores=1 | ncores>1 |
|---|---|---|
| `run_acl`, `run_alscl` | 一个初始点 / One start | socket 多初始点，扰动自由参数后选择最佳有效结果 / Socket multistart |
| `sim_acl` | 依序拟合重复 / Sequential replicates | 按重复分工 / Parallel replicates |
| `retro_model`, `retro_acl`, `retro_alscl` | 依序删除末期 / Sequential peels | 按回溯拟合分工 / Parallel peels |

多起点的目标是稳健性，墙钟时间仍受最慢起点及进程开销影响。避免外层重复与内层多起点同时占满 CPU。Windows、macOS、Linux 均使用可移植 socket 路径。

Multistart improves robustness; runtime includes the slowest start and worker overhead. Avoid oversubscribing nested parallel jobs. Socket workers support Windows, macOS and Linux.

编译由 `run_*()` 自动完成，源文件随包分发，缓存键含模板、头文件、R/TMB/RcppEigen 版本和编译选项。`compile_and_load_acl()` 是内部辅助函数；开启编译选项本身不保证模板的似然计算自动并行。

Fits compile automatically with a cache keyed by sources, headers, R/TMB/RcppEigen and compilation options. Call run_acl() or run_alscl() directly to compile and fit. An OpenMP compiler option alone does not guarantee parallel likelihood evaluation.

```r
# 仅在默认缓存不合适时设置 / Optional writable compilation cache
options(ALSCL.tmb.cache=file.path(tempdir(), "alscl_tmb_cache"))
```

macOS 需要配套命令行 C++ 工具链，Windows 使用匹配 R 版本的 Rtools，Linux 需要 C++/make。依赖安装失败应先解决编译工具和依赖，再重新拟合；不应通过关闭检查掩盖问题。

Use an R-compatible C++ toolchain: command-line tools on macOS, matching Rtools on Windows, and C++/make on Linux. Resolve dependency and toolchain failures before fitting.

## 保存可移植结果 · Save portable results

```r
# obj 含当前会话的外部指针 / obj contains session-specific external pointers
portable <- function(fit) fit[setdiff(names(fit), "obj")]
saveRDS(portable(b), "alscl_report.rds")
capture.output(sessionInfo(), file="sessionInfo.txt")
saved <- readRDS("alscl_report.rds")
saved$report$SSB
# 这些图只需已保存报告 / These plots can use saved reports
plot_SSB(saved)
```

保存了观测与拟合报告的结果可直接使用 `plot_ridges()`，不需要活跃 TMB 对象。未保存观测的旧结果仍需原会话对象或重新拟合。记录包版本、提交号、随机种子、数据来源、三表单位、固定参数、边界、时间步和诊断；RDS 不保存可跨会话执行的编译模型。

Saved fits containing observations and fitted reports support `plot_ridges()` without a live TMB object. Older fits without saved observations still require their original live object or refitting. Record version, commit, seed, provenance, units, maps, bounds, time step and diagnostics. An RDS file does not preserve a portable compiled model.

## 2.2.9 修订 · Changes in 2.2.9

标准误计算结束后，返回的可执行 TMB 对象会恢复到最终拟合参数。在拟合所在的 R 会话中，`fit$obj$report()` 与 `fit$report` 因此描述同一个拟合状态，包括顺序计算及并行失败后的回退。已保存的估计值和标准误不因此改变。序列化保存的结果仍需重新拟合后才能使用可执行 TMB 对象。

After standard-error calculation, the returned live TMB objective is restored to the final fitted parameters. In the fitting R session, `fit$obj$report()` therefore describes the same fitted state as `fit$report`, including sequential standard errors and a fallback from parallel calculation. This does not change the saved estimates or standard errors. Serialized fits still require refitting before using a live TMB objective.

已验证的 TMB 版本为 1.9.21 和 1.9.25。现有 Windows、macOS、Linux 检查已在 1.9.25 上通过两模型、两种 AD 框架的严格并行一致性测试，不允许用单核回退代替通过；Windows 使用 socket，并跳过 Unix fork 测试。其他 TMB 版本继续使用顺序计算保护。这扩大了可启用加速的版本范围，不保证小模型也会提速；实际方法请看 `fit$sd_info`。

The checked TMB versions are 1.9.21 and 1.9.25. TMB 1.9.25 passed the strict, no-fallback parallel-equivalence tests for both models and both AD frameworks in the existing Windows, macOS and Linux checks; Windows uses socket workers and skips Unix-fork tests. Other TMB versions retain the sequential safety fallback. This extends eligibility for acceleration, without promising a speed-up for small fits; inspect `fit$sd_info` for the actual method.

## 常见问题 · Troubleshooting


| 现象 / Symptom | 处理 / Action |
|---|---|
| `YTF$data.CatL` 是 NULL | 载入 `YTF_example`；YTF 是参数列表 / Load the input-data object |
| Excel 年份变成 X2000 | 用指南读取函数或 `check.names=FALSE` / Preserve original headers |
| 长度边界不连续 | 核对真实测量定义，不要自动消除间隙 / Verify actual bin definitions |
| 出现零调查值 | 判断真实零还是缺失编码，再明确 `zero_action` / Establish meaning before excluding zeros |
| 体重/成熟缺失 | 依据可靠资料补全并记录方法 / Supply defensible complete biology |
| 优化码非 0、梯度大、Hessian 非正定 | 检查尺度、边界、初值和可识别性；不能只增加次数 / Investigate data and parameterization |
| 季度 F 看起来偏小 | 输出是每步瞬时率；`annual_F` 名称不意味着自动年化 / Rates are per step, not auto-annualized |
| ACL 的 F 图 `type="length"` | 当前兼容分支仍输出年龄曲线；真正长度别 F 用 ALSCL / Current ACL compatibility alias plots age-specific F |
| 生长区间退化为线 | 本例固定生长参数，属于预期行为 / Expected when growth parameters are fixed |

本文的可执行脚本和实际数值结果随仓库发布；所有图应结合模型假设与数据来源解释。

Executable scripts and numerical results accompany the guide. Interpret figures in light of model assumptions and data provenance.


---

[← 上一章 · Previous](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/14-Function-Reference) · [目录 · Contents](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [下一章 · Next →](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/16-Assessment-Workflows)
