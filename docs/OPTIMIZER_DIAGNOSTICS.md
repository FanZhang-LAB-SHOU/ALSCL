# Retrospective optimizer restart investigation

## Finding / 结论

The ALSCL peels ending in 2018 and 2016 reached the same fitted solution but reported optimizer code 1 because the pass-selection rule replaced an actually successful first pass with a numerically equivalent failed restart. The correction selects the successful pass, retains both original optimizer records, and runs the existing refinement and numerical checks. It does not change the likelihood, data, parameter map, bounds, stopping criteria or diagnostic thresholds.

截至 2018 年和 2016 年的两次 ALSCL 回溯已得到相同的拟合解，但轮次选择规则用数值等价、退出码为 1 的重启结果覆盖了实际成功的第一轮。修正后选择成功轮次，保留两轮原始记录，并继续执行已有的收尾与数值检查。似然、数据、参数 map、边界、停止标准和诊断阈值均未改变。

These are the maintained own-data tutorial's teaching data, derived from `YTF_example`, not a new assessment of a user's empirical stock data. The baseline is release 2.4.3 (`ba99d52`); the correction is currently unreleased. Runs used macOS arm64, R 4.6.0, TMB 1.9.21, CppAD and one standard-error worker. Exact timings and floating-point values can vary across systems.

这些数据来自维护中的正式数据整理教程，内容是 `YTF_example` 的教学数据，并不是对用户实际调查数据的新评估。基线为 2.4.3（`ba99d52`），本修正尚未发布。检查环境为 macOS arm64、R 4.6.0、TMB 1.9.21、CppAD，标准误使用单核计算。其他系统的耗时与浮点数值可能不同。

## What happened / 原因

Both fits used two optimization passes and one starting-value set. The first pass returned `relative convergence (4)`, code 0. The next pass returned `false convergence (8)`, code 1, after a negligible objective decrease. The old protection only retained a successful pass when the two parameter vectors were exactly identical; that condition failed here.

两次拟合均采用两轮优化、一个初值。第一轮返回 `relative convergence (4)`，码 0；第二轮的目标函数仅有极小降低，却返回 `false convergence (8)`，码 1。旧规则仅在两个参数向量完全相同时保护已成功的轮次，因此未能保护这两次拟合。

| Peel / 回溯轮次 | Terminal year / 截止年份 | Pass 1 code / 第一轮码 | Pass 2 code / 第二轮码 | Objective decrease / 目标函数降低 | Largest parameter change / 最大参数变化 |
|---|---:|---:|---:|---:|---:|
| 1 | 2018 | 0 | 1 | 7.78e-10 | 3.27e-7 |
| 3 | 2016 | 0 | 1 | 2.91e-10 | 1.63e-8 |

The new rule treats passes as numerically equivalent only when the absolute objective difference is at most `1e-8`, parameter names match, all coordinates are finite, and every coordinate differs by at most `1e-6 * max(1, abs(old), abs(new))`. If exactly one equivalent pass succeeded, it is retained. Otherwise the lower objective wins, including when the improvement exceeds the objective tolerance or either parameter vector is materially different. Independent starting-value searches still select the lowest finite objective.

新规则仅在目标函数绝对差不超过 `1e-8`、参数名称匹配、所有坐标有限，且每个坐标差不超过 `1e-6 * max(1, abs(old), abs(new))` 时将两轮视为数值等价。如果等价的两轮中恰有一轮成功，就保留它；其他情况仍选择较低目标函数，包括改善超过目标函数容差或任一参数存在实质差异时。不同初值之间仍选择最低的有限目标函数。

The first-pass gradients before refinement were approximately `0.00744` and `0.00292`. Code 0 alone was therefore insufficient: the existing one-step refinement was still needed, and reduced the gradients to the values below. A genuine nonzero selected code is never relabelled as 0, and good optimizer status never overrides the independent gradient, Hessian or boundary screen.

第一轮收尾前的梯度约为 `0.00744` 和 `0.00292`，因此不能仅凭码 0 判断拟合可用。已有的一步收尾仍然必要，收尾后梯度降至下表水平。实际选中的非零码不会被改成 0，优化器状态也不会替代独立的梯度、Hessian 和边界检查。

## Actual refits / 实际重新拟合

Both corrected fits were run from the original truncated inputs, rather than reconstructed from recorded optimizer histories. Each selected pass 1; the raw history still records `0; 1`. All four fits below passed the numerical checks, had positive-definite Hessians and did not hit bounds.

修正后的两次拟合均从原始截断输入重新运行，并非根据保存的优化记录推算。两次均选择第一轮，原始历史仍记录 `0; 1`。下表的四次拟合均通过数值检查，Hessian 正定，且没有触碰边界。

| Terminal year / 截止年份 | Code before → after / 修正前后码 | Gradient before / 修正前梯度 | Gradient after / 修正后梯度 | Maximum relative SSB change / SSB 最大相对变化 | Maximum relative F-at-length change / 体长别 F 最大相对变化 |
|---|---|---:|---:|---:|---:|
| 2018 | 1 → 0 | 1.284e-8 | 1.770e-8 | 9.43e-13 | 1.18e-11 |
| 2016 | 1 → 0 | 6.162e-9 | 4.371e-9 | 6.83e-13 | 2.95e-12 |

Relative differences use the corresponding baseline estimate as the denominator, and the maximum covers all retained time steps (and all length bins for F). Final objective differences were below `4e-12`.

相对变化以相应基线估计为分母，最大值覆盖所有保留时间步；F 还覆盖全部体长组。最终目标函数差小于 `4e-12`。

Machine-readable records / 可读取记录:

- [Final diagnostics / 最终诊断](results/optimizer-restart-diagnostics.csv)
- [Original pass records / 原始轮次记录](results/optimizer-restart-passes.csv)
- [Estimate comparisons / 估计比较](results/optimizer-restart-estimates.csv)
- [Alternative-start comparisons / 替代初值比较](results/optimizer-alternative-starts.csv)

## Data, model and control checks / 数据、模型及优化设置检查

The peels contain 437 and 391 positive observations across 19 and 17 annual periods, with 23 length bins and no zero or missing cells. They estimate 13 fixed-effect scalars and retain the original fixed `log_t0` and `log_sigma_log_F`; no extra parameters were fixed to obtain code 0. The many latent process effects are integrated under their distributional assumptions, so counting them against observations alone does not establish a lack of identification.

两次回溯分别有 437 和 391 个正观测值、19 和 17 个年度时间步、23 个体长组，没有零值或缺失单元。拟合估计 13 个固定效应标量，仅保留原先固定的 `log_t0` 和 `log_sigma_log_F`，没有为了获得码 0 额外固定参数。潜在过程效应是在相应分布假设下积分处理的，因此仅将它们的数量与观测数比较，不能判断不可识别。

Growth parameters remain strongly correlated: the estimated correlation between `log_Linf` and `log_vbk` is approximately −0.993 in both peels. This is a real sensitivity issue to examine with independent biological information and profiles, but it does not explain the replacement of a successful pass. The full fit and the corresponding ACL fits also have strongly correlated growth parameters and return code 0. No claim of global identification or a unique global optimum follows from these checks.

生长参数仍高度相关：两次回溯中 `log_Linf` 与 `log_vbk` 的估计相关系数约为 −0.993。这是需要结合独立生物学资料和参数剖面评估的敏感性问题，但不能解释为何已成功轮次被覆盖。完整拟合与相应 ACL 拟合也存在高度相关的生长参数，却返回码 0。这些检查不证明全局可识别或全局最优解唯一。

Changing the free growth starts to `Linf = 72`, `k = 0.16`, `cv_len = 0.15` and `cv_grow = 0.3`, with all data and model assumptions unchanged, recovered the same solution. Under the old selection rule both runs still ended with code 1; their maximum relative SSB differences were below `5e-12` and F-at-length differences below `3.4e-11`. Increasing evaluation limits or tightening the relative tolerance from the raw endpoint did not remove the false-convergence message. Re-optimizing an already refined solution could return code 0 but sometimes increased its gradient, so it was not adopted as a fix.

将自由生长参数的初值改为 `Linf = 72`、`k = 0.16`、`cv_len = 0.15`、`cv_grow = 0.3`，其余数据与模型假设保持不变，仍得到同一解。旧选择规则下两次仍为码 1，但 SSB 最大相对差小于 `5e-12`，体长别 F 小于 `3.4e-11`。从原始终点增加计算次数或收紧相对容差并未消除 false-convergence 消息。对已收尾的解再优化可能得到码 0，但有时会增大梯度，因此未采用这一做法。

These teaching observations were generated by an age-based operating model. ALSCL's length-transition approximation need not recover the generating growth parameters exactly; numerical convergence does not resolve that structural difference. Model suitability still requires residual, sensitivity and prediction checks.

这些教学观测由年龄结构操作模型生成，ALSCL 的体长转移近似并不一定精确恢复生成时的生长参数。数值收敛不能消除这种结构差异，模型是否适用仍需通过残差、敏感性和预测检查判断。

## Regression checks and reproduction / 回归检查与复现

At the optimizer-fix stage, the complete local suite passed **6,783 assertions with no failures, warnings or skips**. Added tests cover nearly identical failed restarts, a later successful equivalent pass, materially better failed solutions, distinct parameter vectors, coordinate-specific scaling, parameter-name alignment, objective failures and preserved histories. Retrospective tests verify that selected codes, all pass messages and refinement evidence survive aggregation, while missing legacy records stay missing. Genuine selected code 1 remains code 1 even after successful refinement.

完成优化器修正时，本地完整测试通过 **6,783 项断言，无失败、警告或跳过**。新增测试覆盖近似相同但失败的重启、后续成功且等价的轮次、目标函数实质更优的失败解、不同参数向量、逐坐标缩放、参数名称匹配、目标函数失败与历史保留。回溯测试确认汇总时保留所选退出码、全部轮次消息和收尾证据，旧结果缺少的记录仍为缺失值。即使收尾成功，实际选中的码 1 也继续保留为 1。

The source package also passed `R CMD check --no-manual --no-tests` with `Status: OK`; tests were run separately as reported above. The local website build and checks passed for 186 pages, 65 function references per language and 554 parsed R blocks. The bilingual manuals, book and Wiki sources were regenerated. These checks do not constitute Windows or Linux verification of this unreleased change.

源码包的 `R CMD check --no-manual --no-tests` 结果为 `Status: OK`，完整测试另行运行，结果如上。本地网站构建与检查通过，覆盖 186 页、每种语言 65 个函数参考与 554 个解析通过的 R 代码块。中英文说明书、书籍与 Wiki 源文件已重新生成。这些结果不代表本次未发布修正在 Windows 或 Linux 上已验证。

Run from the repository root with the development checkout loaded. The maintained checker executes the current tutorial's input preparation, verifies its data and fixed assumptions, and performs both actual fits. It writes safe assessment archives, session information, raw pass records, final diagnostics and SSB/mean-F series. It requires code 0 and a maximum final gradient below `1e-6`; neither the optimizer nor the package's diagnostic thresholds are relaxed.

从仓库根目录加载开发代码后运行。维护脚本执行当前教程的数据准备，核对数据与固定假设，然后实际完成两次拟合，写出安全评估归档、会话信息、原始轮次记录、最终诊断和 SSB/平均 F 序列。检查要求码 0 且最终最大梯度低于 `1e-6`，不会放宽优化器或软件包的诊断阈值。

This maintained script was also executed end to end in a separate session using the corrected package. Both actual fits passed, and SSB, mean F, every F-at-length cell, recruitment, predictions and the outer parameter vector were bit-for-bit identical to the corrected fits reported above.

维护脚本还在独立会话中使用修正后的软件包从头实际执行过。两次拟合均通过检查，SSB、平均 F、每个体长别 F、补充量、预测值和外层参数向量均与上表修正后的拟合逐位一致。

```r
pkgload::load_all()
options(ALSCL.sd_cores = 1L)
source("scripts/check_optimizer_restarts.R")
run_optimizer_restart_checks("output/optimizer-restarts")
testthat::test_local(stop_on_failure = TRUE)
```

To reproduce the old behavior, run the same script in a separate session using the installed, unmodified 2.4.3 package and its baseline mode. This mode still requires the numerical checks and small gradients, but allows the original nonzero optimizer codes.

若要复现旧行为，在独立会话中使用未修改的已安装 2.4.3 和脚本的 baseline 模式。此模式仍要求通过数值检查且梯度足够小，但允许原始非零退出码。

```sh
Rscript scripts/check_optimizer_restarts.R output/optimizer-baseline baseline
```

## Follow-up review / 后续复查

The subsequent review found and fixed four additional cases. These were independent of the optimizer restart issue.

后续复查发现并修复了以下四类问题，它们与优化器重启问题相互独立。

| Case / 情况 | Reproduced behavior / 复现结果 | Correction / 修正 |
|---|---|---|
| Mixed numeric/text/factor time columns / 混合数值、文本和因子时间列 | Converting the whole table to a character matrix rounded native numbers to display precision; a reproduced difference was 2.1e-7. / 整表转字符矩阵使原有数值按显示精度截断，复现偏差为 2.1e-7。 | Convert each column separately in fitting and diagnostics; reject complex cells. / 拟合与诊断逐列转换，拒绝复数单元格。 |
| Matrix truth in simulation summaries / 模拟汇总中真值为矩阵 | A 2-by-2 truth matrix against four periods produced recycled columns, zero usable pairs and NA bias despite TRUE pair flags. / 四个时间步传入 2×2 真值矩阵，导致拆列和回收；有效配对标记为 TRUE，汇总却为零配对且偏差为 NA。 | Require real numeric vectors for both time coordinates and quantities before aggregation. / 汇总前要求双方时间坐标和各量为实数数值向量。 |
| Retrospective plot without finite estimates / 回溯图没有有限估计 | Nonempty rows with all missing estimates produced an empty plot and rendering warnings. / 有行但估计全部缺失时生成空图并产生绘制警告。 | Require at least one finite time/estimate pair; retain missing gaps in partially valid series. / 要求至少一对有限时间和估计，部分有效序列继续保留缺失间隔。 |
| Invalid retrospective flags / 无效回溯开关 | `plot = NA` failed only after three fits; `silent = 1` was accepted. / `plot = NA` 完成三次拟合后才失败，`silent = 1` 被接受。 | Validate single nonmissing logical values before any fitting. / 拟合开始前要求单个非缺失逻辑值。 |

The updated complete suite passed **6,961 assertions, with zero failures, warnings or skips**. Source-package checking returned `Status: OK`; website/manual checks passed. Actual ACL and ALSCL fits with mixed input columns agree with their numeric counterparts to numerical precision, while native numeric columns remain exact. The full example and both earlier peeled inputs are bit-for-bit unchanged by the conversion fix. Plot tests verify grid-free rendering and preserved internal gaps. Review of simulation, hindcast, projection, result storage and optimizer-status propagation did not reproduce another defect within this review's scope.

更新后的完整测试通过 **6,961 项断言，零失败、零警告、零跳过**。源码包检查为 `Status: OK`，网站和说明书检查通过。实际运行 ACL、ALSCL 后，混合列输入与纯数值输入的拟合在数值精度范围内一致，原有数值列逐位保留。完整示例和前述两个回溯输入在转换修正前后逐位相同。绘图测试确认无网格线并保留内部缺失间隔。在本轮检查范围内，模拟、预测验证、投影、结果保存和优化状态传递未再复现其他缺陷。

These changes are part of the development revision after 2.4.3, listed under Unreleased in NEWS. The `v2.4.3` tag and release archive remain the original baseline; use a checkout containing this report to reproduce the corrected behavior.

这些修正属于 2.4.3 之后的开发修订，列在 NEWS 的 Unreleased 中。`v2.4.3` 标签和发布压缩包仍保留原始基线；复现修正后的行为时，使用包含本报告的代码检出版本。
