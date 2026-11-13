# Unreleased

- Fixes from a full code review. Default fits keep their estimates; changes that alter results are listed first. Changed results: (1) `sim_model()`, `sim_acl()` and `sim_alscl()` fit each replicate with the natural mortality rate recorded in its file (the default was `M = 0.2`); a supplied `M` that differs is an error unless `allow_M_mismatch = TRUE`. (2) In `retro_model()`, a `mean_log_R` fixed through `map` without a value uses the full-data value in every peel. (3) Interval plots draw lognormal intervals by default (see below). (4) `plot_SSB_Rec()` pairs SSB with recruitment at the youngest fitted age, so quarterly fits with `rec.age = 0.25` use a lag of one quarter, not four, and annual fits with a recruitment age other than 1 use that age. (5) `run_acl()` uses data-based Linf start and bounds when its defaults do not suit the length bins, and for M above 0.7 its default init_Z start is no longer moved onto the upper bound.
- New `structure` argument of `run_acl()`, `run_alscl()` and `retro_model()` selects optional model structures; the default is the published structure. `initial_plus_group = "equilibrium"` makes the first-period plus group the sum of all older cohorts at init_Z. For ALSCL, `initial_length = "growth"` builds the first-period lengths at age from the growth transition, `growth_increment = "von_bertalanffy"` uses the von Bertalanffy increment over the time step, and `growth_transition = "bin"` integrates the transition over the source length bin. With the consistent initial state, a population with constant recruitment and no fishing stays constant; with the published structure it does not. `sim_cal()` and `sim_data()` take the same list as `params$structure`.
- A map that ties or fixes entries of dev_log_R, dev_log_F or dev_log_N0 is rejected when the matching standard deviation or correlation is estimated, because those estimates were biased (the standard deviation could run to its bound). With these parameters fixed the map is accepted, and the fit lists the arrays in `restricted_random`. Use `F_structure = "year"` for one F deviation per time step.
- The ACL defaults for Linf (start 60, bounds 10 to 100) are replaced by data-based values when they do not suit the length bins, for example tuna lengths in cm: the start is 1.1 times the length below which 99 percent of the summed survey index lies, the upper bound is twice the largest bin midpoint, and the lower bound is not raised above the default. Starting values moved into their bounds are reported (a warning for supplied starts, a message for default starts) and listed in `clamped_starts`. The default init_Z start no longer sits on its upper bound for large M.
- New `start_spread` argument sets the spread of the second and later starts. Fits record `start_summary`; converged starts that differ by more than 2 objective units are added to `diagnostics$issues`. The help pages explain that a single start can stop at a local optimum that passes every numerical check. Sequential multistart fits reuse one TMB object with identical results.
- Fits report the number of zero survey observations treated as missing. Numeric length labels with unequal spacing and no `len_border` give a warning. Logical survey, weight or maturity columns are rejected. `create_parameters()` errors name the unknown parameter and its name in the other model. `read_survey_excel()` stops on Excel error cells (#DIV/0!, #N/A) and names the sheet and cells. `len_lower` and `len_upper` are deprecated in `prepare_alscl_data()`, `retro_model()` and bundles fitted with ACL (they cannot change a fit); `run_alscl()` still accepts them without a warning.
- `sim_data()` and `simulate_example_data(seed = )` no longer change the caller's random-number stream. Replicates record their seed, generator settings and package version, and a replicate ID gives the same data under any session generator. Replicate files are written only after every replicate is valid, with integer names (`sim_rep100000`). A zero AR(1) coefficient no longer warns, `initialize_params()$years` ends at the last observation period, and a discontinuous dome selectivity gives a warning. `simulate_example_data()` reports with `message()`.
- Results of `sim_model()`, `sim_acl()` and `sim_alscl()` no longer hold the TMB object (about 0.9 GiB per ALSCL replicate); use `refit_model()` when one is needed. New `simulation_to_tables()` converts a `sim_data()` replicate to fitting tables. `summarize_simulations()` also returns `summary_converged` and `failures`. Failure records of batch fits have class `alscl_fit_error` with print, summary, coef and vcov methods.
- `print()`, `summary()`, `extract_parameters()` and `refit_model()` work again on assessments saved by 2.4.3. A fit has one numerical-screen verdict in all summaries. `save_assessment(x = )` keeps the observations and time metadata of an older fit; archives use RDS version 3. `vcov()` returns NULL when the covariance is not finite or not positive definite. New `fitted()`, `logLik()` (so `AIC()` and `BIC()`) and `nobs()` methods. `extract_estimates()` has a new last column `extrapolated` for terminal-period F and catch, which no observation informs.
- `retro_model()`: new `peel_step` (for example 4 for annual peels of a quarterly model); per-fit warnings in `fit_diagnostics$warnings`; `retro_acl(x, 3)` is accepted; the full fit runs in the same batch as the peels; delta-method standard errors that the retrospective does not use are skipped (also in `hindcast_model()` without `save_fits`). `plot_retro()` draws fits that failed the numerical screen with dashed lines, keeps fits without estimates in the legend, keeps colours with the peel and labels quarterly peels as "2001 Q4".
- `compare_models()` records `delta_aic`, `aic_threshold` and `reason`, and reports a failed fit as such. A bundle whose `fit_config` has an entry for one model can be fitted with the other; misplaced top-level fitting arguments give a warning. `check_fit()` describes the QQ reference correctly: standardized conditional residuals have a standard deviation below 1 under a correct model.
- Plots: intervals of abundance, biomass, SSB, recruitment, catch and fishing mortality are lognormal by default, `exp(log(estimate) +/- 1.96 * SE / estimate)`, and cannot fall below zero; use `interval = "wald"` or `acl_theme_set(interval = "wald")` for the previous interval. Age panels and axes show fitted ages and mark the plus group ("Age 15+"). `plot_compare_F_ts()` gains `basis = "age"` for a common age basis. A global `x_breaks` applies only to axes it lies on. Faceted survey plots no longer overprint year labels. Error bars are opaque by default. `plot_ridges()` has one figure title and quarter labels. Shared F is drawn as one panel. Labels state the time basis of F and spell out SSB. `acl_theme_set()` rejects unsupported settings.
- Speed and infrastructure: the compile cache key includes the platform and C++ settings and builds are installed atomically (existing persistent caches are rebuilt once). `sd_cores = "auto"` respects `SLURM_CPUS_PER_TASK` and `options(mc.cores)` and avoids forking with a threaded BLAS. Sequential batch fits use the session's `sd_cores`. A malformed speed option stops the fit with a message that names it. Diagnostics report unfinished refinement and standard deviations close to zero. Socket workers stop when they load a different TMB version. Internal options `ALSCL.se_level` and `ALSCL.delta_method` are available.
- The development version is 2.4.3.9000. `reshape2` and `cowplot` are no longer required. The built package no longer contains unused figures. Documentation states that outputs are on the scale of the survey index unless the index is absolute, corrects the `growth_step` default and the description of process maps, and maintainer scripts check that the loaded package has the code of the checkout.
- Tests compare the joint likelihood, the growth transition matrix, the population dynamics and Mohn's rho with independent R implementations, check that the operating models reproduce the templates, and fit `YTF_example` to check recovery of the simulated truth.
- `structure` has a fifth setting, `correlation_range`, for ACL and ALSCL. `"positive"` (default) keeps the AR(1) correlations of recruitment and F between 0 and 1, the logistic transform of the `logit_*` parameters. `"symmetric"` lets them lie between -1 and 1 (2 * logistic - 1), so a correlation of zero is no longer a boundary in the numerical checks and a negative correlation can be estimated. Under `"symmetric"` a correlation rho is `qlogis((rho + 1) / 2)` on the optimizer scale; default starts keep their natural value, and `inspect_parameters()`, `extract_parameters()`, `profile_model()` and `simulate_fit()` use the same transform. Use it when recruitment has no or negative autocorrelation: with the default range such a fit runs to the lower boundary and fails the numerical checks.
- New argument `t0_lower` (default 0) of `run_alscl()` and `retro_model()`. ALSCL uses t0 = t0_lower + exp(log_t0), so a negative t0 can be fixed or estimated, for example with `t0_lower = -1` and `parameters = list(log_t0 = log(t0 + 1))`. Reported t0 values are on the natural scale. In an input bundle, store it under `fit_config$alscl`.
- Changed output: ALSCL reports F at age (`report$FA`) and total mortality at age (`report$ZA`) for every age, including the plus group, and for every period (A x Y; earlier versions reported (A-1) x (Y-1)). The values of the cells that existed before are unchanged. Plots and `extract_estimates()` accept fits of both forms. `extract_estimates()` marks the terminal-period rows of FA as `extrapolated`. When the last periods have no positive survey observation, it also marks F and catch from the last period with an observation onwards.
- `extract_estimates()` accepts `N_at_age` as an alias of `NA` (numbers at age), because a table labelled "NA" loses the label when it is written to a CSV file and read back with the defaults of `read.csv()`.
- New argument `random_numbers` of `initialize_params()`. With `"by_process"`, `sim_data()` draws recruitment, F, initial numbers and survey errors from separate streams with a fixed number of draws each, so scenarios that differ in one process share the random numbers of the others. `"sequential"` (default) draws as before. The two settings give different data for the same replicate ID, and each replicate records the setting in `provenance$random_numbers`.
- Changed results: `YTF_example$fit_config` fixes the standard deviation of log F at the marginal SD of the generating AR(1) process, F_sd / sqrt(1 - F_ar^2) = 0.302, for both models; it was the innovation SD 0.2. The data tables are unchanged. Fits of `YTF_example` with its stored configuration change: the ACL and ALSCL objectives are -335.14 and -28.59 (were -335.69 and 22.29) and the AIC difference is 613.09 (was 715.96). The tables and figures of the documentation were regenerated, and the articles quote the new values.
- `plot_retro()` labels quarterly terminal periods ("2004 Q4") also when `peel_step` is above 1. The lower bound of a lognormal interval never falls below zero for a nonnegative estimate. `plot_compare_F_ts(basis = "age")` stops when the two fits have different time steps. `plot_pla()` labels the axis "Age group" for a result without age metadata. `sim_model()`, `sim_acl()` and `sim_alscl()` read replicate files written under their earlier names (`sim_rep1e+05`). `profile_model()` reports the same numerical verdict as `summary()` for older fits. Help pages of the exported functions have examples that run in the package checks.
- Draw single estimates as points with error bars when intervals are requested. Keep the full length range in ridge panels and the full time range in mean-residual comparisons when boundary observations are missing. Validate ridge-height multipliers; add rendering regression tests and bilingual examples without gridlines.
- Keep gaps in mean-residual comparison lines and observed ridge polygons, show isolated observations, and align ridge panels and time colors. Support Brewer palettes for two-period results; add rendering regression tests and refresh affected figures without gridlines.
- Use the checked parallel Hessian during optimizer refinement where forked processes are selected, with sequential fallback and per-step method records. Simulate fitted processes without constructing unused derivative tapes; fitting interfaces and model equations are unchanged.
- Revised some wording to make the documentation more precise.
- Compare positive survey observations cell by cell before reporting fit metrics or choosing a model by AIC. Protect archives from overlapping writes to the same path.
- Check every map name, including named NULL releases, and normalize unused factor levels before fitting. Preflight and fitting now validate the same optimizer controls.
- Preserve small positive probabilities in the simulated age–length key and growth transitions. In age-based simulations, average dome-shaped fishery selectivity over length at each age.
- Show isolated survey observations and residuals as points and keep gaps in observed lines and trends. Preserve scientific-notation length labels and use the fitted ages on ACL fishing mortality heatmaps.
- Preserve an actually converged optimization pass when a numerically equivalent restart reports false convergence; retain all original pass records and still select materially lower objectives.
- Retain optimizer messages, selected passes and refinement evidence in retrospective diagnostics; missing legacy records remain missing.
- Preserve native numeric precision when survey, weight or maturity tables mix numeric, text and factor columns; use the same conversion in diagnostics and reject complex cells.
- Require one-dimensional real numeric time coordinates and quantity vectors in simulation summaries; reject matrices and arrays before they can be recycled into misleading statistics.
- Validate retrospective plot/silent flags before fitting. Reject plots without any finite time/estimate pair while retaining gaps in partially observed series.

### 简体中文

- 完整代码审查后的修复。默认拟合的估计值不变；会改变结果的改动列在前面。结果有变的地方：(1) `sim_model()`、`sim_acl()` 和 `sim_alscl()` 用每个重复文件中记录的自然死亡率拟合（原默认 `M = 0.2`）；给定的 `M` 与记录不同时报错，除非 `allow_M_mismatch = TRUE`。(2) `retro_model()` 中，通过 `map` 固定但未给值的 `mean_log_R` 在每个 peel 中都使用全数据的值。(3) 区间图默认绘制对数正态区间（见下）。(4) `plot_SSB_Rec()` 按最小拟合年龄配对 SSB 与补充量，`rec.age = 0.25` 的季度拟合滞后一个季度，而不是四个；补充年龄不为 1 的年度拟合按该年龄滞后。(5) ACL 的 Linf 默认值不适合体长组时，`run_acl()` 使用按数据推导的起点和边界；M 大于 0.7 时，init_Z 的默认起点不再被移到上界。
- `run_acl()`、`run_alscl()` 和 `retro_model()` 新增 `structure` 参数，用于选择可选的模型结构；默认为已发表的结构。`initial_plus_group = "equilibrium"` 使第一期的 plus group 等于在 init_Z 下所有更老世代之和。ALSCL 另有三项：`initial_length = "growth"` 由生长转移推算第一期各年龄的体长分布，`growth_increment = "von_bertalanffy"` 采用一个时间步长内的 von Bertalanffy 增量，`growth_transition = "bin"` 在原体长组内对转移概率积分。采用一致的初始状态时，补充量恒定且无捕捞的种群保持不变；已发表的结构做不到这一点。`sim_cal()` 和 `sim_data()` 通过 `params$structure` 接受同一列表。
- map 把 dev_log_R、dev_log_F 或 dev_log_N0 的元素设为共享值或固定值时，如果对应的标准差或相关系数仍在估计，现在会报错，因为这些估计有偏（标准差可能落到边界）。这些参数固定时仍然接受，拟合结果在 `restricted_random` 中列出涉及的数组。每个时间步长只用一个 F 偏差时，请用 `F_structure = "year"`。
- ACL 的 Linf 默认值（起点 60，边界 10 到 100）不适合数据的体长组时（例如以 cm 计的金枪鱼体长），改用按数据推导的值：起点为累计调查指数 99% 处体长的 1.1 倍，上界为最大体长组中点的 2 倍，下界不高于原默认值。被移入边界的起点会报告（用户给定的起点给出警告，默认起点给出提示），并列在 `clamped_starts` 中。M 较大时，init_Z 的默认起点不再落在上界。
- 新增 `start_spread` 参数，控制第二个及之后起点的离散程度。拟合结果记录 `start_summary`；收敛的起点之间目标函数相差超过 2 时，写入 `diagnostics$issues`。帮助页说明单个起点可能停在通过全部数值检查的局部最优。顺序多起点拟合共用一个 TMB 对象，结果完全相同。
- 拟合时报告被当作缺失的零观测个数。数值型体长标签间距不等且未提供 `len_border` 时给出警告。拒绝逻辑型的调查、体重或成熟度列。`create_parameters()` 的报错指出未知参数名及其在另一模型中的名称。`read_survey_excel()` 遇到 Excel 错误单元格（#DIV/0!、#N/A）时停止，并指出工作表和单元格。`len_lower` 和 `len_upper` 在 `prepare_alscl_data()`、`retro_model()` 和用 ACL 拟合的数据包中已弃用（它们不会改变拟合结果）；`run_alscl()` 仍接受它们且不给出警告。
- `sim_data()` 和 `simulate_example_data(seed = )` 不再改变调用者的随机数流。每个重复记录种子、随机数发生器设置和包版本，相同的重复编号在任何会话设置下给出相同数据。全部重复通过检查后才写文件，文件名为整数形式（`sim_rep100000`）。AR(1) 系数为零时不再出现警告，`initialize_params()$years` 结束于最后一个观测期，穹顶形选择性不连续时给出警告。`simulate_example_data()` 改用 `message()` 报告。
- `sim_model()`、`sim_acl()` 和 `sim_alscl()` 的结果不再保存 TMB 对象（每个 ALSCL 重复约 0.9 GiB）；需要时用 `refit_model()`。新增 `simulation_to_tables()`，把一个 `sim_data()` 重复转换为拟合用的表。`summarize_simulations()` 另外返回 `summary_converged` 和 `failures`。批量拟合的失败记录属于 `alscl_fit_error` 类，有 print、summary、coef 和 vcov 方法。
- 对 2.4.3 保存的评估结果，`print()`、`summary()`、`extract_parameters()` 和 `refit_model()` 恢复可用。各处汇总对同一拟合只给出一个数值检查结论。`save_assessment(x = )` 保留旧拟合的观测数据和时间信息；存档使用 RDS 第 3 版。协方差非有限或非正定时，`vcov()` 返回 NULL。新增 `fitted()`、`logLik()`（因此可用 `AIC()` 和 `BIC()`）和 `nobs()` 方法。`extract_estimates()` 新增最后一列 `extrapolated`，标出没有观测支持的末期 F 和渔获量。
- `retro_model()`：新增 `peel_step`（例如季度模型按年剥离时设为 4）；各拟合的警告记录在 `fit_diagnostics$warnings`；接受 `retro_acl(x, 3)`；全数据拟合与各 peel 在同一批中运行；跳过回溯用不到的 delta 方法标准误（`hindcast_model()` 不保存拟合时同样跳过）。`plot_retro()` 用虚线绘制未通过数值检查的拟合，图例保留没有估计值的拟合，颜色随 peel 固定，季度 peel 标为"2001 Q4"。
- `compare_models()` 记录 `delta_aic`、`aic_threshold` 和 `reason`，并如实报告失败的拟合。`fit_config` 只含一个模型设置的数据包可以用另一个模型拟合；放错位置的顶层拟合参数给出警告。`check_fit()` 正确说明 QQ 图的参照：模型正确时，标准化条件残差的标准差小于 1。
- 绘图：丰度、生物量、SSB、补充量、渔获量和捕捞死亡率的区间默认为对数正态区间 `exp(log(estimate) +/- 1.96 * SE / estimate)`，不会低于零；用 `interval = "wald"` 或 `acl_theme_set(interval = "wald")` 恢复原区间。年龄分面和坐标轴显示拟合年龄，并标出 plus group（"Age 15+"）。`plot_compare_F_ts()` 新增 `basis = "age"`，在共同的年龄基础上比较。全局 `x_breaks` 只作用于包含这些值的坐标轴。分面调查图的年份标签不再重叠。误差线默认不透明。`plot_ridges()` 只有一个总标题，并使用季度标签。共享 F 只画一个分面。标签注明 F 的时间基准，SSB 写出全称。`acl_theme_set()` 拒绝不支持的设置。
- 速度与基础设施：编译缓存的键包含平台和 C++ 设置，编译结果以原子方式安装（已有的持久缓存会重建一次）。`sd_cores = "auto"` 遵守 `SLURM_CPUS_PER_TASK` 和 `options(mc.cores)`，使用多线程 BLAS 时不 fork。顺序批量拟合使用会话的 `sd_cores`。速度选项写错时，拟合停止并指出该选项。诊断报告未完成的收尾和接近零的标准差。socket worker 加载的 TMB 版本与主进程不同时停止。提供内部选项 `ALSCL.se_level` 和 `ALSCL.delta_method`。
- 开发版本号为 2.4.3.9000。不再依赖 `reshape2` 和 `cowplot`。构建的包不再包含未使用的图片。文档说明：除非指数是绝对丰度，输出都在调查指数的尺度上；更正了 `growth_step` 默认值和过程偏差 map 的说明；维护脚本会检查已加载的包与当前代码一致。
- 测试用独立的 R 实现核对联合似然、生长转移矩阵、种群动态和 Mohn's rho，检查操作模型与模板一致，并拟合 `YTF_example` 检查能否恢复模拟真值。
- `structure` 新增第五项设置 `correlation_range`，ACL 和 ALSCL 都可使用。`"positive"`（默认）使补充量和 F 的 AR(1) 相关系数在 0 和 1 之间，是 `logit_*` 参数的 logistic 变换。`"symmetric"` 使相关系数在 -1 和 1 之间（2 * logistic - 1），因此相关系数为零在数值检查中不再是边界，也可以估计负相关。`"symmetric"` 下相关系数 rho 在优化器尺度上为 `qlogis((rho + 1) / 2)`；默认起点保持原来的自然尺度取值，`inspect_parameters()`、`extract_parameters()`、`profile_model()` 和 `simulate_fit()` 使用同一变换。补充量没有自相关或呈负自相关时请使用它：默认范围下这样的拟合会落到下界，无法通过数值检查。
- `run_alscl()` 和 `retro_model()` 新增参数 `t0_lower`（默认 0）。ALSCL 使用 t0 = t0_lower + exp(log_t0)，因此可以固定或估计负的 t0，例如设 `t0_lower = -1` 和 `parameters = list(log_t0 = log(t0 + 1))`。报告的 t0 在自然尺度上。在数据包中请把它存在 `fit_config$alscl` 之下。
- 输出有变：ALSCL 报告每个年龄（包括 plus group）和每个时期的年龄别 F（`report$FA`）和年龄别总死亡率（`report$ZA`），维度为 A x Y；早期版本为 (A-1) x (Y-1)。原有单元格的数值不变。绘图函数和 `extract_estimates()` 接受两种形式的拟合。`extract_estimates()` 把 FA 的末期各行标为 `extrapolated`。最后几期没有正的调查观测时，从最后一个有观测的时期起的 F 和渔获量也会被标记。
- `extract_estimates()` 接受 `N_at_age` 作为 `NA`（年龄别尾数）的别名，因为标签为 "NA" 的表写入 CSV 文件后，用 `read.csv()` 的默认设置读回时会丢失标签。
- `initialize_params()` 新增参数 `random_numbers`。取 `"by_process"` 时，`sim_data()` 从各自独立、抽取次数固定的随机数流中抽取补充量、F、初始尾数和调查误差，因此只在一个过程上不同的情景在其他过程上使用相同的随机数。`"sequential"`（默认）与以前相同。两种设置对同一重复编号给出不同的数据，每个重复把所用设置记录在 `provenance$random_numbers` 中。
- 结果有变：`YTF_example$fit_config` 把两个模型对数 F 的标准差固定在生成数据的 AR(1) 过程的边际标准差 F_sd / sqrt(1 - F_ar^2) = 0.302；原来是新息标准差 0.2。数据表没有变化。用保存的配置拟合 `YTF_example` 的结果因此改变：ACL 和 ALSCL 的目标函数值为 -335.14 和 -28.59（原为 -335.69 和 22.29），AIC 之差为 613.09（原为 715.96）。文档中的表格和图已重新生成，文章引用的是新值。
- `peel_step` 大于 1 时，`plot_retro()` 也把季度末期标为 "2004 Q4" 这样的形式。估计值非负时，对数正态区间的下限不会低于零。两个拟合的时间步长不同时，`plot_compare_F_ts(basis = "age")` 停止。结果没有年龄元数据时，`plot_pla()` 的坐标轴标签为 "Age group"。`sim_model()`、`sim_acl()` 和 `sim_alscl()` 能读取以早期名称（`sim_rep1e+05`）写出的重复文件。对旧拟合，`profile_model()` 给出的数值检查结论与 `summary()` 一致。导出函数的帮助页带有在包检查中实际运行的示例。
- 单个估计值显示为点，请求区间时显示误差棒。边界观测缺失时，山脊图保留完整体长范围，平均残差比较图保留完整时间范围。校验山脊高度缩放参数，补充实际渲染回归测试和无网格线的双语示例。
- 平均残差比较线和观测山脊图在缺测处断开，保留孤立观测，并统一山脊图两栏的坐标与时间配色。Brewer 配色支持两个时期的结果；补充绘图回归测试，重新生成受影响配图并保持无网格线。
- 选择 fork 进程的会话中，优化收尾使用已验证的并行 Hessian，失败时退回顺序计算，并逐次记录计算方法。拟合过程模拟省去未使用的导数构建；拟合接口和模型方程保持不变。
- 修订了一些表述，让说明更加精确。
- 报告拟合指标或按 AIC 选择模型前，逐格核对调查正观测。多个进程向同一路径存档时会检查写入冲突。
- 校验全部映射参数名，包括具名 NULL 释放项，并在拟合前清除未使用的因子水平。预检和拟合采用相同的优化器控制项校验。
- 保留模拟年龄–体长概率和生长转移中的微小正概率。年龄结构模拟按每个年龄的体长分布对穹顶形渔业选择性加权。
- 调查图和残差图显示孤立观测，遇到缺测会断开观测线和趋势线。保留科学计数法的体长标签，ACL 捕捞死亡率热图按拟合年龄标注。
- 数值上等价的重启报告 false convergence 时，保留实际收敛的轮次；保留全部原始记录，目标函数有实质改善时仍按较低值选择。
- 回溯诊断保留优化器消息、所选轮次及收尾证据；旧结果缺少的信息继续保留为缺失值。
- 调查、体重和成熟度表混合数值、文本与因子列时保留原有数值精度；诊断采用相同转换，并拒绝复数单元格。
- 模拟汇总要求时间坐标和各量为一维实数数值向量；提前拒绝矩阵和数组，避免回收或拆列产生误导统计。
- 回溯开始拟合前校验 plot/silent；没有有限时间与估计值配对时拒绝绘图，部分有效序列仍保留缺失间隔。

# ALSCL 2.4.3

- Check that simulation biology matches the supplied parameters and arrays before drawing data or writing files. Reject inconsistent saved survey catchability before fitting; matching legacy simulation objects remain supported.
- Correct the worked simulation cases to use the marginal F standard deviation implied by the operating model's innovation SD and temporal correlation. Regenerate the data, fitted results and figures, and explain the remaining differences between generating and fitted process assumptions.
- Make the growth comparison reference example self-contained, with its reference data defined in the example. Execute the English and Chinese website examples in isolated environments.
- Preserve the `alscl_fit` class when the own-data example saves results without the live TMB object, so `summary()` retains its diagnostic output after reading the file.
- Apply the global comparison legend position to F heatmaps and growth probability panels, and the global point size to lag and QQ diagnostics. Refresh affected figures without gridlines.
- Clarify that process resampling recomputes survey predictions from the new population states, and that shared F is one time series across groups. Add regression checks and execute the complete fitting and validation examples.

### 2.4.3 · 简体中文

- 在抽样或写文件前核对模拟生物学数组与参数的一致性；拟合前拒绝已保存调查可捕性与元数据不一致的模拟。内容匹配的旧模拟对象仍可使用。
- 模拟案例的 F 标准差改为由操作模型的创新标准差和时间相关系数换算的边际标准差。重新生成数据、拟合结果和配图，并说明生成过程与拟合过程仍有哪些不同假设。
- 生长比较函数的参考示例直接定义所需参考数据，可独立运行；在独立环境中执行中英文网站示例。
- 正式数据示例去掉当前会话的 TMB 对象后仍保留 `alscl_fit` 类，使保存后读取的结果继续通过 `summary()` 输出诊断。
- F 热图和生长概率面板统一采用全局比较图例位置，lag 和 QQ 诊断统一采用全局散点大小。重新生成受影响的配图，保持无网格线。
- 说明过程重抽样会从新种群状态重新计算调查预测，共用 F 指各组共用一条时间序列。补充回归检查并实际执行完整拟合及验证示例。


# ALSCL 2.4.2

- Allow `plot_compare_selectivity()` to use saved assessments without refitting, recovering fixed survey catchability from the retained input recipe.
- Restore nullable theme settings, including automatic axis breaks and survey labels, when a saved `acl_theme()` snapshot is applied. Retrospective rho and comparison metric labels inherit the chosen font.
- Use fitted ages for comparative growth plots and reject explicit ranges before either model's `t0`, preventing negative-length extrapolation. Existing valid explicit ranges remain supported.
- Accept replicate ID 0 consistently in simulation generation and fitting; require distinct nonnegative integer IDs.
- Execute the current plotting tutorial blocks and check the `facet_by` examples, with grid-free checks included in the automated workflow.
- Preserve every executable line when merging bilingual code examples with different comment or blank-line counts; add generator regression checks.

### 2.4.2 · 简体中文

- `plot_compare_selectivity()` 可直接使用保存后读取的评估结果，从保留的输入配方恢复固定调查可捕性，无须重新拟合。
- 应用保存的 `acl_theme()` 设置时，可恢复自动坐标刻度和调查标签等可为空的设置。回溯图 rho 和比较图数值标注继承所选字体。
- 生长比较图默认采用拟合年龄，显式范围不得早于任一模型的 `t0`，避免负体长外推；原有有效的显式范围仍可使用。
- 模拟生成和拟合统一接受编号 0，重复编号须为互不重复的非负整数。
- 绘图教程检查执行当前的多个代码块，并按 `facet_by` 检查示例，将无网格线验证纳入自动检查流程。
- 合并中英文代码示例时，即使注释或空行数不同，也保留全部可执行代码，并新增生成器回归检查。


# ALSCL 2.4.1

- `README.md` is an English entry page: what the package does, documentation links, installation, a ten-line example with figures and the citation. `README.zh-CN.md` is the Chinese version, and `website/check.py` verifies the counts and version strings in both files.
- Preserve effective fixed scalar values in each `simulate_fit()` input bundle, including a data-derived `mean_log_R` that was fixed without an explicit value. Refit the simulated data under the same fixed assumptions while retaining the original starting-value strategy for free parameters.
- Record `dev_log_N0` in new ALSCL reports so conditional simulations retain all three process-deviation arrays, including after saving and reading an assessment. Older saved reports with missing deviations remain readable.
- Complete `point_size` support in comparison plots. Unset point sizes inherit the global value (2.5); explicit legacy `obs_size` and `compare_point_size` settings remain supported, and a per-call `point_size` takes priority. Refresh affected figures without gridlines.
- Preserve positional `base_theme` calls to `plot_fishing_mortality()` by appending new typography arguments after the existing arguments.
- Stop the own-data example before fitting when ALSCL is older than 2.4.0. Align the declared minimum R version and installation instructions at R 4.1.
- Explain that process deviations are estimated by default but may be fixed or tied through `map`; document the restrictions for process resampling and hindcast validation.
- Separate data loading from source-model fitting in the validation tutorial, so the hindcast-only route needs `x` and no full-data fit. Add regression checks for the tutorial route and early version gate.

### 2.4.1 · 简体中文

- `README.md` 改为英文入口页：软件包功能、文档链接、安装、带图的十行示例和引用。`README.zh-CN.md` 是中文版，`website/check.py` 核对两个文件中的数量和版本号。
- `simulate_fit()` 返回的输入列表保存实际固定的标量参数值，包括未显式提供、由数据计算后固定的 `mean_log_R`。模拟数据重新拟合时保持相同固定假设，自由参数仍使用原来的初值策略。
- 新 ALSCL 报告保存 `dev_log_N0`，使条件模拟保留三组过程偏差，保存和读取评估后也可使用。缺少该偏差的旧报告仍能读取。
- 补齐比较图的 `point_size`。未设置时继承全局值（2.5）；显式设置的旧参数 `obs_size` 和 `compare_point_size` 仍有效，调用中的 `point_size` 优先。重新生成受影响的配图，继续保持无网格线。
- 将新增字体参数放在原参数之后，保留 `plot_fishing_mortality()` 按位置传入 `base_theme` 的旧写法。
- 正式数据示例在拟合前检查 ALSCL 至少为 2.4.0；软件包声明和安装说明统一要求 R 4.1 或更高版本。
- 说明过程偏差默认参与估计，也可通过 `map` 固定或绑定，并列出过程重抽样和预测检验对此的限制。
- 模型验证教程拆开数据加载与源模型拟合，仅做预测检验时只需 `x`，不再要求完整数据拟合通过。新增教程路径和提前版本检查的回归测试。


# ALSCL 2.4.0

- Plot functions share one set of argument names. The facet layout is `facet_ncol` and `facet_scales` in every plot (the comparison plots used `ncol` and `scales`; the retrospective plots used `facet_col` and `facet_row`, now `facet_nrow`). The line width is `line_size` everywhere (the comparison plots used `linewidth`; the theme key `compare_linewidth` is now `compare_line_size`). Every plot that draws points takes `point_size = NULL`, which inherits the new theme key `point_size` (2.5). `se = FALSE` is the default in every plot, including `plot_deviance()`. `plot_CatL()` and `plot_residuals()` choose their layout with `facet_by` ("length" or "year") instead of `type`, which names the plotted quantity in the other functions. The former names still work and warn once per session; a later release removes them.
- The population plots `plot_SSB()`, `plot_biomass()`, `plot_abundance()` and `plot_catch()`, and `plot_deviance()`, take the same `title`, `xlab` and `ylab` arguments and the same typography arguments (`font_family`, `title_size`, `axis_title_size`, `axis_text_size`, `strip_text_size`, `legend_text_size`, `x_breaks`, `base_theme`, `title_hjust`) as the other single-model plots; `plot_fishing_mortality()` gains the five typography arguments it lacked. A value given in the call replaces the theme setting, and the defaults are unchanged.
- `plot_compare_annual_F()` is renamed `plot_compare_F_ts()`: it summarizes F per model time step and never annualized quarterly values. The former name warns once per session.
- Plot titles use sentence case, so every title reads the same way ("Estimated total abundance (N)"). The title keys `CatL_by_length` and `CatL_by_year` replace `CatL_year` and `CatL_year_dist`, whose names were inverted; `compare_F_ts` replaces `compare_annualF`; `plot_retro()` uses the `retro` key; `plot_pla()` uses the new `ylab$length`; the unused `ylab$deviance` is removed. Time-step panels are labelled "Year 2000" in every plot, or "2000 Q2" for quarterly fits, and age panels "Age bin".
- `docs/SPEED.md` now also holds the change report of the 2.1.0 release (commits, files, cross-platform checks, open points, reproduction steps), so `SPEED_REPORT.md` is removed; `RELEASE_2.2.2.md` is removed as the other release notes were. The function reference no longer carries version subsections or dated notes. `website/check.py` also flags former argument names and deprecated functions in documented code, full-width punctuation on English pages and broken links in the Markdown manuals, and it verifies the reference index, the function and figure counts quoted in the manuals and the version strings.
- Rewrite the website tutorials as task pages: each page states its goal, then numbered steps with the code to run, why, what to expect and what to do when it fails, and a closing table of next steps. Version history is kept in this file only. The English and Chinese pages share one block structure.
- Generate the bilingual manuals (`docs/USER_GUIDE.md`, `ASSESSMENT_WORKFLOWS.md`, `MODEL_VALIDATION.md`, `CASE_STUDIES.md`, `PLOT_STYLE.md`, `SPEED_GUIDE.md`, `ADVANCED_WORKFLOWS.md` and the new `CASES.md`), the book and the Wiki from the article pairs with `scripts/build_manual.py`, so every tutorial is written once per language. Remove `MATHEMATICAL_FRAMEWORK.md`, `BOOK_THEORY_NOTES.md` and the `RELEASE_2.2.x.md` notes, whose content is in the theory page and in this file.
- Example figures: every plotting function's reference page, and the reference entries of `check_fit()`, `fit_scenarios()`, `profile_model()`, `project_model()`, `hindcast_model()`, `simulate_fit()`, `sim_data()` and the retrospective functions, show the figure their example produces. `acl_theme_set()` shows the five palettes with the role of each colour (`docs/figures/palettes/`, drawn by `scripts/palette_swatches.R`), and the colours page shows the same plot under every palette.
- Plot labels name each quantity the same way everywhere: "Spawning biomass (SSB)", "Catch numbers (CN)", "Abundance"; `plot_recruitment()` labels its axis "Recruitment". The gallery figures are regenerated with these labels and every figure description says what the figure shows, when to use it and what a pattern means.
- Tidy the fitting code without changing results: one helper runs batches on socket workers for scenarios, profiles, hindcasts, retrospective peels and simulation replicates; one helper saves and restores the random-number state; one helper checks TRUE/FALSE arguments. `retro_model()` reports progress through `message()` so `suppressMessages()` silences it, and `profile_model()` runs its grid fits silently. Core input errors omit the internal call and the survey-index message names the survey index.

### 2.4.0 · 简体中文

- 绘图函数统一参数名。所有图的分面布局用 `facet_ncol` 和 `facet_scales`（比较图原来用 `ncol`、`scales`；回溯图原来用 `facet_col`、`facet_row`，后者现为 `facet_nrow`）。线宽统一为 `line_size`（比较图原来用 `linewidth`；主题键 `compare_linewidth` 改为 `compare_line_size`）。画点的图都接受 `point_size = NULL`，继承新的主题键 `point_size`（2.5）。所有图默认 `se = FALSE`，包括 `plot_deviance()`。`plot_CatL()` 和 `plot_residuals()` 用 `facet_by`（"length" 或 "year"）选择布局，不再用 `type`；`type` 在其他函数中表示所画的量。旧参数名仍可用，每个会话警告一次，以后的版本将删除。
- 种群图 `plot_SSB()`、`plot_biomass()`、`plot_abundance()`、`plot_catch()` 和 `plot_deviance()` 与其他单模型图一样接受 `title`、`xlab`、`ylab` 和字体参数（`font_family`、`title_size`、`axis_title_size`、`axis_text_size`、`strip_text_size`、`legend_text_size`、`x_breaks`、`base_theme`、`title_hjust`）；`plot_fishing_mortality()` 补上缺少的五个字体参数。调用中给出的值替换主题设置，默认值不变。
- `plot_compare_annual_F()` 更名为 `plot_compare_F_ts()`：它按模型时间步汇总 F，从未把季度值年化。旧名每个会话警告一次。
- 图标题改为句首大写（如 "Estimated total abundance (N)"），所有标题格式一致。标题键 `CatL_by_length`、`CatL_by_year` 取代名称写反的 `CatL_year`、`CatL_year_dist`；`compare_F_ts` 取代 `compare_annualF`；`plot_retro()` 使用 `retro` 键；`plot_pla()` 使用新增的 `ylab$length`；删除未使用的 `ylab$deviance`。时间步面板在所有图中标为 "Year 2000"，季度拟合标为 "2000 Q2"；年龄面板统一标为 "Age bin"。
- `docs/SPEED.md` 并入 2.1.0 发布时的改动报告（提交、文件、三平台检查、未决问题、复现步骤），删除 `SPEED_REPORT.md`；`RELEASE_2.2.2.md` 与其他发布说明一样删除。函数参考不再保留版本小节和带版本号的说明。`website/check.py` 还会检查文档代码中的旧参数名和已弃用函数、英文页面中的全角标点，以及 Markdown 手册中的失效链接，并核对参考索引、手册中引用的函数和图数量以及版本号。
- 网站教程改写为任务页：每页先说明目的，再按编号步骤给出要运行的代码、原因、应看到的结果和出错时的处理，最后列出下一步。版本历史只保留在本文件中。中英文页面采用相同的段落结构。
- 双语手册（`docs/USER_GUIDE.md`、`ASSESSMENT_WORKFLOWS.md`、`MODEL_VALIDATION.md`、`CASE_STUDIES.md`、`PLOT_STYLE.md`、`SPEED_GUIDE.md`、`ADVANCED_WORKFLOWS.md` 和新增的 `CASES.md`）、书稿和 Wiki 由 `scripts/build_manual.py` 从中英文章对生成，每篇教程每种语言只写一次。删除 `MATHEMATICAL_FRAMEWORK.md`、`BOOK_THEORY_NOTES.md` 和 `RELEASE_2.2.x.md`，其内容已在模型原理页和本文件中。
- 示例图：每个绘图函数的参考页，以及 `check_fit()`、`fit_scenarios()`、`profile_model()`、`project_model()`、`hindcast_model()`、`simulate_fit()`、`sim_data()` 和回溯函数的参考条目，都展示示例代码生成的图。`acl_theme_set()` 展示五种色板及各颜色的用途（`docs/figures/palettes/`，由 `scripts/palette_swatches.R` 生成），配色页展示同一张图在每种色板下的效果。
- 绘图标签对同一个量使用同一名称："Spawning biomass (SSB)"、"Catch numbers (CN)"、"Abundance"；`plot_recruitment()` 的坐标轴标为 "Recruitment"。图谱按新标签重新生成，每张图的说明都写明图中内容、何时使用和图形规律的含义。
- 整理拟合代码，结果不变：情景、剖面、预测检验、回溯各轮和模拟重复共用一个 socket 批处理函数；随机数状态的保存与恢复、TRUE/FALSE 参数检查各用一个辅助函数。`retro_model()` 改用 `message()` 报告进度，`suppressMessages()` 可以关闭；`profile_model()` 的网格拟合不再打印进度。核心输入错误不再显示内部调用，调查指数的错误信息改为指明调查指数。

# ALSCL 2.3.0

- Release the nineteen assessment-workflow functions added since 2.2.9 (data preparation and checks, result extraction and archives, sensitivity scenarios, profiles, projections, fitted-model simulation and hindcast validation): 64 exported functions.
- `run_alscl()` and `retro_alscl()` infer `growth_step` like `run_acl()`: NULL uses rec.age when it is below one, otherwise one. Pass `growth_step = 1` explicitly for annual ALSCL data with rec.age below one.
- `fit_scenarios()` defaults to `model = "acl"`, like the other workflow functions, and uses one start per scenario unless the bundle or the call sets `nstarts`, the rule of `hindcast_model()` and `retro_model()`. `retro_model()` accepts `model` as well as `model_type`.
- Simulated bundles from `simulate_fit()` no longer carry the source fit's `output`, `ncores` and `silent` settings; choose them when the bundle is fitted.
- Every worker count respects the two-process limit of `R CMD check` (`_R_CHECK_LIMIT_CORES_`), so checks no longer fail or fall back on it.
- The example script uses the exported `read_survey_csv()`, `prepare_alscl_data()` and `check_alscl_data()`; the legacy helper script now calls the exported readers instead of masking them. The gallery lists 44 figures: the ACL F-at-length entry duplicated the F-at-age figure. Stale statements in the speed documents, the user guide's gradient values and chapter count, the function reference index and argument tables, and four website pages are corrected.

### 2.3.0 · 简体中文

- 正式发布 2.2.9 之后新增的 19 个评估工作流函数（数据准备与检查、结果提取与存档、敏感性情景、剖面、投影、拟合模型模拟与留出预测检验），共 64 个导出函数。
- `run_alscl()` 和 `retro_alscl()` 与 `run_acl()` 一样推断 `growth_step`：NULL 时 rec.age 小于 1 取 rec.age，否则取 1。年度 ALSCL 数据若 rec.age 小于 1，请显式传入 `growth_step = 1`。
- `fit_scenarios()` 默认 `model = "acl"`，与其他工作流函数一致；每个情景只用一个初值，除非 x 或调用设置了 `nstarts`，与 `hindcast_model()`、`retro_model()` 规则相同。`retro_model()` 同时接受 `model` 和 `model_type`。
- `simulate_fit()` 生成的输入列表不再携带源拟合的 `output`、`ncores` 和 `silent` 设置；在拟合时自行指定。
- 所有工作进程数都遵守 `R CMD check` 的两进程限制（`_R_CHECK_LIMIT_CORES_`），检查不再因此失败或回退。
- 示例脚本改用导出的 `read_survey_csv()`、`prepare_alscl_data()` 和 `check_alscl_data()`；旧辅助脚本的读取函数改为调用包函数，不再遮蔽它们。图谱改为 44 张：ACL 体长别 F 条目与年龄别 F 图重复。修正速度文档中的过时表述、使用指南的梯度数值和章节数、函数参考索引和参数表，以及四个网页。

- Add fitted-model survey simulation with conditional observations or resampled stationary process deviations, retained truth and directly reusable input bundles. Add expanding-window time-held-out survey prediction checks with numerical screening, paired persistence baselines, log-scale scores and explicit denominators. Document both in a new bilingual worked case with grid-free figures.

- Reject deterministic projections from known failed fits unless explicitly overridden with a warning; preserve unknown legacy status. Add independent starts to simulation batches while keeping one fitting worker per replicate.
- Record available source revisions, core/R source fingerprints and runtime provenance in assessment recipes, and warn on known implementation changes when refitting.

- Align model names and descriptions with the implemented population, observation and growth processes. Clarify survey catchability, simulation F baselines and innovation standard deviations, natural parameter scales and nominal confidence levels without changing existing argument names or calculations.
- Correct residual facet documentation, document the shared ACL/ALSCL simulation entry points, complete Chinese return-value descriptions, remove escaped paragraph artifacts and organize current tutorials by task. Probability-matrix and survey-catchability plot titles use the same terminology as the manuals.

- Add public CSV/Excel preparation and compilation-free data/parameter checks, using the same effective starts, bounds and maps as fitting; preserve original numeric precision and validate scalar logical controls consistently.
- Add fitted-result summaries and extraction, portable assessment archives and recipe-based refitting; retain legacy list access and fitting syntax.
- Add standardized conditional residual tables and grid-free heatmap, actual-time lag and QQ diagnostics, without claiming calibrated tests.
- Add named sensitivity batches and free-scalar parameter profiles with per-fit numerical status, warnings and errors; parallelize independent fits without nested workers.
- Add deterministic ACL/ALSCL projections with explicit future F, recruitment and biology, correct terminal-mortality timing and no implied uncertainty, MSY or TAC calculation.
- Add shared ACL/ALSCL simulation fitting and bias/RMSE/coverage summaries with aligned truth, failure rates and explicit denominators. Document all six workflows in English, Simplified Chinese, the website and Wiki chapter 16, with six new grid-free figures.

### 新增评估能力 · 简体中文

- 新增拟合模型调查模拟，可固定状态模拟观测或重新抽取平稳过程，保留真值及可直接拟合的输入列表；新增扩展窗口时间留出预测检验，包含数值检查、配对持平基准、对数评分及明确分母，配中英文完整案例与无网格图。

- 默认拒绝已知数值失败拟合的确定性投影；显式覆盖会警告，旧结果缺失的状态保持未知。模拟批次新增独立多初值，每个重复仍使用单个拟合进程。
- 评估配方记录可取得的源码提交、核心／R 源码摘要与运行环境；重新拟合时提示已知实现变化。

- 统一模型名称，分别说明种群数量、调查观测、存活和生长过程；明确调查可捕性、模拟 F 基准与创新标准差、自然参数尺度和名义置信水平，保留现有参数名与计算方式。
- 修正残差图分面说明，介绍统一的 ACL／ALSCL 模拟入口，补齐中文返回字段解释，清理段落转义符，并按当前操作重组教程。概率矩阵及调查可捕性图标题与说明书保持一致。

- 新增公开 CSV／Excel 导入、无须编译的数据与参数检查，和核心拟合共用实际初值、上下界及 map；保留原始数值精度，并统一检查逻辑控制参数。
- 新增拟合结果汇总与提取、可移植评估文件和基于记录的重新拟合，保留旧列表访问及拟合语法。
- 新增条件标准化残差表及无网格热图、实际时间滞后图和 QQ 图，不宣称为校准过的统计检验。
- 新增具名敏感性批次和自由标量参数剖面，逐项保留数值状态、警告与错误；只并行独立拟合，避免嵌套进程。
- 新增确定性 ACL／ALSCL 投影，显式提供未来 F、补充与生物学输入，正确处理末期死亡率时序，不隐含不确定性、MSY 或 TAC 计算。
- 新增统一 ACL／ALSCL 模拟拟合与偏差、RMSE、覆盖率汇总，按真值对齐并报告失败率及各项分母；中英文文档、网站及 Wiki 第 16 章完整说明六类工作流，配六张新无网格图。

### Existing development fixes

- Growth plots default to fitted ages and reject explicit pre-t0 ranges, preventing negative-length extrapolations and reversed intervals. Parameter annotations, fonts and growth-axis labels are consistent with and without intervals.
- Fishing-mortality plots inherit global titles, axis labels, breaks and expansion. Theme names and existing theme objects are both supported with grid-free panels.
- Survey comparison axes use survey-index labels independently of fishery catch; the new survey label takes precedence while preserving legacy custom abundance labels.
- Retrospective tutorials correctly show that saved observations and reports support ridge plots without a live TMB object.
- Growth-reference labels must be nonempty and distinct from both model labels, preventing unrelated curves from being connected.
- Residual smoothers choose their method and span independently in each facet; a sparse group no longer removes or changes trends in other groups.
- All SSB, biomass, abundance and catch plot modes inherit global titles, axis labels, breaks and expansion, including interval variants.
- Process-deviation labels distinguish log deviations from multiplicative factors; survey-index and composition titles describe the plotted quantities.
- Bilingual examples define the retrospective result before use and use the effective year-profile line-width arguments. Manual figures are regenerated with no gridlines.

### 既有功能修正 · 简体中文

- 生长曲线图默认使用拟合年龄范围，并拒绝显式的 t0 之前区间，避免负体长外推和区间反向；有无区间时的参数标注、字体和生长坐标轴标签一致。
- 捕捞死亡率图继承全局标题、坐标轴标签、刻度和扩展；主题名称和已有主题对象都可使用，面板不带网格。
- 调查比较图的坐标轴使用调查指数标签，与渔业捕获量无关；新的调查标签优先，同时保留旧的自定义丰度标签。
- 回溯教程正确说明：已保存的观测和报告无需活跃 TMB 对象即可绘制山脊图。
- 生长参照标签必须非空且与两个模型标签不同，避免把无关曲线连在一起。
- 残差平滑曲线在每个分面内独立选择方法和跨度；稀疏分组不再删除或改变其他分组的趋势。
- SSB、生物量、丰度和捕获量的所有绘图模式（含区间变体）继承全局标题、坐标轴标签、刻度和扩展。
- 过程偏差标签区分对数偏差与乘数；调查指数和组成图的标题描述所绘数量。
- 双语示例在使用前先定义回溯结果，并使用有效的年份剖面线宽参数；手册图形重新生成，不带网格线。

# ALSCL 2.2.9

- In 2.2.9, omitted generic `line_size` and `se_alpha` inherit `acl_theme_set()` (defaults 1.5 and 0.2); explicit function arguments take priority. Comparison curves honor `linetypes` and `compare_linetypes`. Combined residual/metric titles and F facet labels inherit the global typography. Grid lines remain absent by default. ACL F-deviation age panels use numeric order. `plot_pla(x_breaks = c(1, 5, 10, 15))` selects age-bin ticks without removing heatmap cells.
- The default `plot_CatL(exp_transform = FALSE)` displays natural-log survey indices and labels that scale explicitly. `exp_transform = TRUE` displays original-scale survey indices; curves are fitted medians. An explicit `ylab` overrides the automatic label. Ridge compositions are normalized stably on the log scale, including very large or small finite log predictions; nonfinite predictions are rejected.
- `sim_acl()` saves the status of every replicate, including failures, to `result_rep_<iter>`. Reusing an output directory replaces an earlier success with the current failure record; inspect `converge` and `error` before summarizing results. Output write failures are reported and must not be treated as saved results. `simulation_to_tables(sm, pa)` uses the simulation length coordinates and rejects conflicting parameter coordinates instead of relabeling observations; legacy simulations without coordinates can use matching parameter metadata.
- `create_parameters(species = "krill", model_type = "acl")` supplies a Linf start of 90 and bounds, but does not fix Linf or change M, nage or the time step. To fix it, explicitly pass `map = list(log_Linf = factor(NA))` with the chosen starting value. Biological settings still belong in the fitting arguments.
- Both compiled models evaluate the Baranov catch fraction stably for very small total mortality, consistently with the simulator. This prevents cancellation to zero at extreme values; ordinary-scale results may differ only at floating-point precision.

- After standard-error calculation, the returned live TMB objective is restored to the final fitted parameters. In the fitting R session, `fit$obj$report()` therefore describes the same fitted state as `fit$report`, including sequential standard errors and a fallback from parallel calculation. This does not change the saved estimates or standard errors. Serialized fits still require refitting before using a live TMB objective.
- `plot_compare_residuals()` and `plot_compare_CatL()` verify known observations and their positive-observation mask as well as time and length metadata. Pass the original fitting table; changing its values or turning a missing cell into an observation is an error. Older fits without stored observations remain usable, but their observation alignment cannot be fully verified. Zero and NA observations are omitted from the comparison points, consistently with fitting; prediction curves remain available at those positions.
- Full simulations retain genuine zero and very small positive survey observations; they no longer replace values below `1e-6` with `1e-6`. Survey biomass equals survey abundance times weight, including extinction scenarios. This changes only newly generated data that previously hit that floor; saved datasets are not rewritten. The fitting convention is unchanged: zero observations are missing with `zero_action = "missing"` and rejected with `"error"`; an entirely zero survey contains no positive observations and cannot be fitted by the current lognormal model.
- Simulation length midpoints must lie within their corresponding bins, using the same containment rules as fitting. The first and last bins absorb the tails. Invalid bin geometry is rejected during parameter preparation and rechecked before biological calculations or simulation, including manually modified inputs, before random draws or output files.
- The checked TMB versions are 1.9.21 and 1.9.25. TMB 1.9.25 passed the strict, no-fallback parallel-equivalence tests for both models and both AD frameworks in the existing Windows, macOS and Linux checks; Windows uses socket workers and skips Unix-fork tests. Other TMB versions retain the sequential safety fallback. This extends eligibility for acceleration, without promising a speed-up for small fits; inspect `fit$sd_info` for the actual method.

### 简体中文

- 2.2.9 中，省略的通用 `line_size` 与 `se_alpha` 继承 `acl_theme_set()`（默认 1.5 与 0.2），函数显式参数优先。比较曲线遵守 `linetypes` 与 `compare_linetypes`，残差／指标组合图标题及 F 分面文字继承全局字体设置。默认仍无网格。ACL F 偏差图按年龄数字排序；`plot_pla(x_breaks = c(1, 5, 10, 15))` 选择年龄组刻度，不删除热图单元。
- 默认 `plot_CatL(exp_transform = FALSE)` 绘制自然对数调查指数，并在纵轴标明尺度；`exp_transform = TRUE` 绘制原尺度调查指数，预测曲线为中位数。显式 `ylab` 覆盖自动标签。山脊图在对数尺度稳定归一化，极大或极小的有限对数预测仍可绘制；非有限预测会报错。
- `sim_acl()` 将每次重复的结果（包括失败状态）保存到 `result_rep_<iter>`。复用输出目录时，本轮失败记录会替换旧成功结果；汇总前检查 `converge` 和 `error`。写入失败会明确报告，不能视为已经保存。`simulation_to_tables(sm, pa)` 使用模拟结果的长度坐标，并拒绝与参数不一致的坐标，不再给观测重新贴错标签；没有坐标的旧模拟可使用匹配的参数元数据。
- `create_parameters(species = "krill", model_type = "acl")` 提供 Linf 初值 90 和边界，不会自动固定 Linf，也不更改 M、nage 或时间步长。需要固定时，显式传入 `map = list(log_Linf = factor(NA))` 和选定初值；生物设置仍需在拟合参数中提供。
- 两个编译模型在极小总死亡率下稳定计算 Baranov 渔获比例，与模拟器一致，避免相减抵消为零；普通量级结果仅可能在浮点精度上变化。

- 标准误计算结束后，返回的可执行 TMB 对象会恢复到最终拟合参数。在拟合所在的 R 会话中，`fit$obj$report()` 与 `fit$report` 因此描述同一个拟合状态，包括顺序计算及并行失败后的回退。已保存的估计值和标准误不因此改变。序列化保存的结果仍需重新拟合后才能使用可执行 TMB 对象。
- `plot_compare_residuals()` 和 `plot_compare_CatL()` 除时间及体长元数据外，也核对已知观测值及正观测掩码。请传原始拟合表；修改数值或将缺失单元改为观测会报错。没有保存观测的旧结果仍可使用，但无法完整核验观测匹配。比较图的观测点排除零值和 NA，与拟合约定一致；这些位置仍可显示预测曲线。
- 完整模拟保留真实零值和极小正调查观测，不再把小于 `1e-6` 的值替换为 `1e-6`。调查生物量等于调查尾数乘以重量，零资源情形也保持一致。只有原先触发下限的新模拟数据会变化，旧保存数据不改写。拟合规则不变：`zero_action = "missing"` 将零视为缺失，`"error"` 拒绝零值；全零调查没有正观测，不能使用当前对数正态模型拟合。
- 模拟体长中点必须落在对应组内，检查规则与拟合一致；首尾组仍吸收分布尾部。参数准备阶段会拒绝无效分组，生物量计算和模拟前还会再次检查，包括用户手动修改的输入；错误发生在随机抽样和写文件前。
- 已验证的 TMB 版本为 1.9.21 和 1.9.25。现有 Windows、macOS、Linux 检查已在 1.9.25 上通过两模型、两种 AD 框架的严格并行一致性测试，不允许用单核回退代替通过；Windows 使用 socket，并跳过 Unix fork 测试。其他 TMB 版本继续使用顺序计算保护。这扩大了可启用加速的版本范围，不保证小模型也会提速；实际方法请看 `fit$sd_info`。

# ALSCL 2.2.8

- Align survey observations and predictions independently of matrix names; validate residual caps and full-simulator process inputs before random draws or file writes.
- Match quick-simulation tail probabilities to the model core; validate biological inputs, generated outputs and full-simulator probability sums before saving.
- Normalize tibble and factor survey inputs consistently across fitting, diagnostics and comparison; slice time-dependent maps for retrospective peels.
- Validate all requested F/comparison uncertainty, retain numeric age ordering and matrix-position coordinates, and honor residual labels and title alignment.
- Direct F time-series comparisons to the explicit apical/mean helper instead of silently omitting F. Keep grid-free defaults and refresh affected manual figures.
- Load the same source checkout on development socket workers; check source and installed workflows in CI.

### 简体中文

- 调查拟合图不受矩阵行列名影响；残差截断必须为正，完整模拟过程参数在随机抽样及写文件前验证。
- 快速模拟的尾部概率与核心一致；保存前检查生物输入、生成结果及完整模拟器概率和。
- 拟合、诊断与比较统一解析 tibble 和因子观测；回溯同步截短按时期设置的 map。
- F 和比较图检查完整不确定性，统一年龄顺序及矩阵位置坐标，残差图遵守标签和标题位置。
- F 时间序列比较明确转用最大值／均值汇总函数，不再静默丢弃；保留默认无网格并刷新相关配图。
- 开发模式的 socket 进程加载同一源码目录；CI 检查源码及安装模式。

# ALSCL 2.2.7

- Reject explicitly finite outer length bounds with an actionable message; the model retains tail-absorbing first/last bins, existing interval labels and default inputs.
- Align abundance plots by matrix positions and fitted time/length metadata, independent of matrix dimnames.
- Validate complete, finite, nonnegative standard errors for abundance, recruitment and deviation intervals. Estimate-only deviation plots use reported estimates without requiring a standard-error table.
- Honor ylab in every growth-plot mode and retain text sizes, breaks, themes and annotations when covariance is unavailable. Synchronize bilingual documentation, website, Wiki and help pages; retain grid-free defaults.

### 简体中文

- 显式有限外体长边界会明确报错；模型继续以首尾组吸收分布尾部，原有区间标签及默认输入保持兼容。
- 丰度图按矩阵位置与拟合年份、体长标签对齐，行列名称不会造成坐标丢失或组别错配。
- 丰度、补充量和偏差区间检查标准误的完整性、有限性及非负性；偏差图在 se = FALSE 时可直接使用报告估计，不依赖标准误表。
- 生长曲线在所有模式遵守 ylab；没有可用协方差时，保留字号、刻度、主题和标注设置。同步中英文文档、网站、Wiki 与帮助页，保留默认无网格样式。

# ALSCL 2.2.6

- Version 2.2.6 also keeps SSB, abundance, biomass, catch, deviation and fishing-mortality plots grid-free if theme loading fails. Explicit theme choices remain available. Manual ggplot exports check major and minor grids in every panel; a visible grid stops export without replacing an existing file. The 2.2.6 release archive includes the refreshed help images.

### 简体中文

- 2.2.6 进一步保证 SSB、丰度、生物量、捕获量、偏差和捕捞死亡率图在主题加载失败后的回退路径也不显示网格。显式指定的主题仍优先。说明书的 ggplot 导出统一检查各子图的主、次网格；发现网格时停止导出并保留原文件。正式 2.2.6 下载包包含更新后的帮助图片。

# ALSCL 2.2.5

- Refresh every documentation plot, including legacy help assets, simulation cases, own-data examples and benchmark PNG/SVG files. Check gallery panel themes before export and version website/Wiki image URLs by content to avoid stale cached figures. / 补齐所有文档绘图，含旧帮助图、模拟案例、正式数据示例及基准图的 PNG/SVG；导出前检查图库主题，网站及 Wiki 图片按内容添加版本标记，避免旧图缓存。

- All package plots now omit major and minor panel gridlines by default. Explicit ggplot2 theme overrides remain available. / 所有包内绘图默认无主、次网格线，仍可显式使用 ggplot2 主题添加。
- Use the same package installation on socket workers, validate fitted-data alignment in diagnostics, share robust comparison metrics, stabilize steep logistic curves and zero-mortality simulations, honor available biomass intervals and explain unsupported plots. Synchronize bilingual guides and executable help examples; homepage installation versions follow DESCRIPTION.

### 简体中文

- 统一 socket 进程安装库，诊断核对拟合数据，共用稳健比较指标，修正陡峭 logistic 与零死亡率模拟，绘制可用生物量区间并明确不支持的绘图；同步双语指南及可运行帮助例子，网站安装版本由 DESCRIPTION 生成。

# ALSCL 2.2.4

- Resolve path and parameter variables before socket batch fitting; retain diagnostics when all retrospective fits fail, including with plotting requested.
- Give same-model configurations distinct comparison labels, preserve each trajectory's calendar and validate metadata for observation-paired plots.
- Preserve missing/zero observation masks in ridges and residual plots, including portable saved results; convert recruitment ages in years to the correct model-step lag.
- Make quick-simulator mean_F match the actual trajectory mean and allow zero F. Newly generated examples change; previously bundled data retain their original truth.
- Validate burn-in and simulation durations against the time step, preserve one-period matrix dimensions and carry first.year through simulation, tables and batch fitting.
- Update English and Simplified Chinese documentation, reference pages, book and Wiki.

### 简体中文

- 在 socket 批次拟合前求值路径及参数变量；全部回溯拟合失败时仍返回诊断，包括请求绘图的情况。
- 同模型不同配置使用独立图例，轨迹保留各自年份，与观测配对的图核对元数据。
- 山脊图、残差图及保存结果保留缺测和零值掩码；补充年龄按年换算成正确时间步滞后。
- 快速模拟器的 mean_F 等于实际轨迹平均值，并支持零 F；新生成示例会改变，原内附数据保留原始真值。
- 核对预热与模拟时长是否对齐时间步，单期输出保持矩阵，并在模拟、转表及批次拟合中保留 first.year。
- 同步中英文文档、函数参考、书稿与 Wiki。

# ALSCL 2.2.3

- Check time-column spacing against growth_step in both fitting functions; missing periods must remain on the time grid.
- Validate matching observations, masks, bins and periods before comparing models. Retain raw AIC but withhold automatic preferences for failed numerical screens or unverifiable older results.
- Accept the same input bundle in retro_acl(x, nyear = 3) and retro_alscl(x, nyear = 3), preserving legacy calls and explicit overrides. Forward zero handling, optimizer controls and starts; keep peel workers separate from fitting workers.
- Retain full-fit and per-peel diagnostics and errors. Mark authoritative Mohn's rho unavailable if any required fit or endpoint is invalid, while retaining explicitly labelled raw estimates for inspection.
- Share diagnostic calculations with comparison plots so NA observations are handled consistently. Plot ALSCL F against actual length midpoints in length mode; preserve the ACL legacy length alias with a warning.
- Add multiple-parameter regression fits for both F structures, annual and quarterly inputs, missing observations and boundary diagnostics. Update the bilingual manual, website and Wiki sources.

### 简体中文

- 两个拟合入口核对时间列间隔与 growth_step；缺失时段必须保留在完整时间轴中。
- 模型比较核对观测、缺失掩码、体长组及时间。不合格拟合或无法核验的旧结果保留原始 AIC，但不自动给出模型偏好。
- 回溯支持同一份 x，保留旧写法及显式覆盖，并转送零值处理、优化控制和起点数；回溯并行与单轮拟合并行分开。
- 保留完整拟合和逐轮诊断、错误。任一必要拟合或末端比较不合格时，正式 Mohn rho 为 NA，并保留明确标记的原始结果供排查。
- 比较图共用诊断指标计算，正确排除 NA。ALSCL 的 length 模式以实际体长为横轴；ACL 旧 length 别名保留并警告。
- 新增两个模型、两种 F 结构、年度及季度、缺失值和边界的多参数回归测试，同步双语文档、网站及 Wiki 来源。

# ALSCL 2.2.2

- Add safeguarded Newton refinement (`polish = TRUE`) and preserve every raw optimizer pass. An unchanged failed restart no longer replaces an earlier successful result. Raw convergence codes remain available.
- Add `F_structure = "year"` to both fitting functions, retrospectives and simulation fitting: one shared F per time step with a correctly normalized 1D AR(1) likelihood. The default remains the original group-by-time field; legacy calls and speed settings remain supported.
- Add natural-scale boundaries, covariance conditioning, high parameter correlations and an independent numerical screen. Shared-F deviation plots use one series. See the [complete survey example](https://fanzhang-lab-shou.github.io/ALSCL/articles/case-fit-survey.html).
- Update English and Simplified Chinese documentation, website and Wiki. Refinement can change estimates at numerical precision; the old speed benchmark is not a promise of cross-version identity. The numerical checks of this release (gradient before and after refinement for four model and F-structure combinations) are in `docs/results/convergence-2.2.2.csv`, produced by `scripts/check_convergence_222.R`.

### 简体中文

- 默认新增受保护的 Newton 收尾（`polish = TRUE`），保留每轮原始优化结果；同一点后续误报失败不再覆盖先前成功结果，原始收敛代码仍可核查。
- 两个拟合函数、回溯分析及模拟拟合新增 `F_structure = "year"`：每时间步共用一个 F，使用正确归一化的一维 AR(1) 似然。默认保留原来的组别 × 时间结构，旧调用写法和加速设置继续支持。
- 新增自然尺度边界、协方差条件数、高参数相关和独立数值筛查。共用 F 偏差图显示单一序列，详见[完整调查案例](https://fanzhang-lab-shou.github.io/ALSCL/zh/articles/case-fit-survey.html)。
- 同步中英文文档、网站及 Wiki。收尾可能改变数值精度层面的估计；旧加速基准不构成跨版本逐位一致的承诺。

# ALSCL 2.2.1

- Documentation update: distinguish required inputs, starting values and estimable parameters; document default maps and explicit NULL releases. The own-data script now uses model-default maps (10 / 13 free scalars), with fresh fit diagnostics and figures. / 文档更新：区分必需输入、初值和可估计参数，说明默认 map 与具名 NULL 的解除方法；正式数据脚本改用模型默认 map（10 / 13 个自由标量参数），重新验证拟合并生成配图。

- Add `scripts/fit_own_data_example.R`: import aligned CSV or Excel inputs, build a structured input bundle for both models, inspect diagnostics, save PNG figures and portable results. / 新增三表导入、组装 x、双模型拟合、诊断、配图与保存的完整脚本。
- Expand the English and Simplified Chinese own-data article, Wiki and book with the complete example, explicit adaptation instructions and figures generated from the synthetic CSV workflow. / 同步中英文正式数据案例、Wiki 与书稿，包含完整代码、修改说明及实际运行生成的图。
- Preserve model likelihoods, interfaces and acceleration defaults. / 模型似然、接口和默认加速设置保持不变。

# ALSCL 2.2.0

ALSCL 2.2.0 accepts `run_acl(x)` and `run_alscl(x)` directly. For `YTF_example`, each function selects its model-specific `fit_config` automatically; explicit call arguments override stored settings. The original separate-argument and `do.call()` forms remain valid. Both use the same built-in acceleration; inspect `a$sd_info` or `b$sd_info` for actual execution.

ALSCL 2.2.0 支持直接使用 `run_acl(x)` 和 `run_alscl(x)`。对于 `YTF_example`，函数自动选择对应模型的 `fit_config`，显式传参可覆盖已有设置。原来的逐项传参和 `do.call()` 写法继续有效。两种写法共用内置加速，可查看 `a$sd_info` 或 `b$sd_info` 确认实际执行方式。

- Validate input bundles and preserve explicit overrides, including NULL; keep simulation parameters separate from model fitting settings. / 检查输入列表，保留显式覆盖设置（包括 NULL），并区分模拟与拟合参数。
- Update bilingual examples, R help, function references and workflow scripts. / 更新双语示例、R 帮助、函数参考与工作流脚本。
- Avoid starting a socket worker when only one delta-method quantity remains; compute it directly instead of encountering a one-chunk splitting error. / delta 方法只剩一项待算量时直接计算，避免单进程分组出错。

# ALSCL 2.1.0

- Standard errors now also use several cores on Windows and in GUI front-ends (RStudio, R.app, RGui, Positron), where forked processes are unavailable or discouraged: socket workers compute the delta method when it would take more than about 3 seconds, with results identical to `TMB::sdreport()`. Each fit records how its standard errors were computed in `fit$sd_info` (and prints it when `silent = FALSE`), and the new `alscl_speed_info()` shows what the speed settings mean on the current computer. A new user guide, `docs/SPEED_GUIDE.md` (also on the website), explains every setting, how to check and record them, and when to use TMBad.
- Faster fits, set with the new `alscl_speed()`. By default, standard errors are computed in parallel within one fit (the fixed-effect Hessian by column and the delta method by ADREPORT quantity), with results identical to `TMB::sdreport()` and to ALSCL 2.0.0; fits were 1.13-1.24 times faster in the benchmark. `alscl_speed(framework = "TMBad")` compiles the models with TMB's TMBad library, which made fits 1.25-1.68 times faster, but estimates differ slightly from CppAD (by up to 2.7e-8, relative, in the fits tested). See `docs/SPEED.md`.
- Separate total optimization starts (`nstarts`) from socket workers (`ncores`), preserving `nstarts = ncores` by default. Record per-start PIDs, elapsed and CPU time, and optimizer diagnostics. / 分开控制总起点数与并行进程数，并返回逐起点执行证据。
- Add reproducible equal-work ACL/ALSCL benchmarks and parallel regression tests. / 新增相同工作量的并行实测与回归测试。

# ALSCL 2.0.0

- ACL 与 ALSCL 两种调查体长模型，支持年度及季度时间步。 / Two survey catch-at-length models with annual or quarterly steps.
- 内置 YTF 教学数据、完整模拟器、Excel 示例及实测数据导入说明。 / Built-in YTF teaching data, simulation, worksheets and observation import.
- 拟合诊断、模型比较、回溯分析，以及可调节的 ggsci 配色。山脊图默认使用 viridis 年份渐变。 / Diagnostics, comparisons, retrospectives and customizable ggsci colors; ridges use sequential viridis by default.
- 简体中文与英文对照的主页及 15 章 Wiki，包含全部公开函数和可复现 R 示例。 / Bilingual README and 15-chapter Wiki with all public functions and reproducible R examples.

安装 / Installation: `remotes::install_github("FanZhang-LAB-SHOU/ALSCL")`.
