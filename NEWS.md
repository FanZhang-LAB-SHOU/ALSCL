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
