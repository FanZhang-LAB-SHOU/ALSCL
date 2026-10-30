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
- Update English and Simplified Chinese documentation, website and Wiki. Refinement can change estimates at numerical precision; the old speed benchmark is not a promise of cross-version identity.

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
