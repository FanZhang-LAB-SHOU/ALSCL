# 06 初值、边界与拟合 · Fitting controls

[← 上一章 · Previous](https://github.com/Linbojun99/ALSCL/wiki/05-Simulation) · [目录 · Contents](https://github.com/Linbojun99/ALSCL/wiki) · [下一章 · Next →](https://github.com/Linbojun99/ALSCL/wiki/07-Diagnostics)

**ALSCL 2.2.2 · 简体中文 / English**

| 设置 / Setting | 怎么调整及影响 / Meaning and effect |
|---|---|
| `rec.age`, `nage` | 起始年龄（年）和年龄组数；年龄网格为 rec.age + (0:nage-1) × growth_step / Recruitment age and number of age classes |
| `growth_step` | 每步多少年；ACL 的 NULL 按 rec.age<1 时取 rec.age、否则取 1，ALSCL 默认 1，季度应显式设 0.25 / Years per step; specify 0.25 for quarterly ALSCL |
| `M` | 每模型步长自然死亡瞬时率；年率转季度需相应换算 / Instantaneous natural mortality per model step |
| `sel_L50`, `sel_L95` | 固定调查 q 的位置和斜率，L95 必须大于 L50 / Fixed survey catchability locations |
| `len_mid`, `len_border` | 组中心及内部边界；ALSCL 还提供 `len_lower/len_upper` / Midpoints and internal boundaries; ALSCL also offers outer bounds |
| `parameters`, `.L`, `.U` | 命名初值、下界、上界；在程序参数化尺度上提供 / Named starting values and bounds on the optimizer scale |
| `map` | 固定或释放参数；固定值来自 `parameters` / Fix or release parameters at their supplied values |
| `train_times` | 从优化结果继续优化的次数，并非随机多起点 / Successive optimization passes, not independent random starts |
| `control` | 传给 `nlminb` 的控制项，如 `eval.max`、`iter.max` / Optimizer controls |
| `ncores` | 最大 socket 并行进程数 / Maximum socket workers |
| `nstarts` | 总起点数，默认等于 ncores；固定后可公平比较并行数 / Total starts, default ncores; hold fixed for timing comparisons |
| `alscl_speed()` | Speed settings for all later fits: `sd_cores` (cores for standard errors) and `framework` (AD library); see 6.1 |
| `output` | FALSE 不写文件，TRUE 在 output 目录导出诊断与图 / Export diagnostics and plots under output when TRUE |

`initialize_params(species=...)` 建立模拟参数；`create_parameters(model_type=..., species=...)` 建立估计初值及边界。后者的物种预设不会自动替你更改 `run_*` 的 M、年龄、调查 q 或数据。

Simulation presets and estimation starts are separate. Choosing a species in `create_parameters()` does not automatically change the biological arguments passed to `run_*()`.

```r
p <- create_parameters(model_type = "acl", species = "flatfish")
names(p) # 查看初值及上下界列表 / Inspect start and bound components
# 明确固定参数；不同模型参数名不同 / Explicit fixed parameters, model-specific names
fixed <- list(log_Linf = factor(NA), log_vbk = factor(NA))
# factor(NA) 固定；映射中的 NULL 可释放默认固定项 / NULL releases a default fixed item
released <- list(logit_log_F_y = NULL) # 直接传给 run_acl 的 map / Pass directly as map
VB_func(Linf = 60, k = 0.2, t0 = 1/60, age = 1:15)
mat_func(L50 = 35, L95 = 40, length = seq(6, 50, 2))
```

| 生物含义 / Meaning | ACL 参数名 / Name | ALSCL 参数名 / Name |
|---|---|---|
| 生长 / Growth | `log_Linf`, `log_vbk`, `t0` | `log_Linf`, `log_vbk`, `log_t0` |
| 长度离散 / Length dispersion | `log_cv_len` | `log_cv_len`, `log_cv_grow` |
| 过程 SD / Process SD | `log_std_log_R`, `log_std_log_F`, `log_std_log_N0` | `log_sigma_log_R`, `log_sigma_log_F`, `log_sigma_log_N0` |
| F 相关 / F correlation | `logit_log_F_a`, `logit_log_F_y` | `logit_log_F_l`, `logit_log_F_y` |
| 补充相关 / Recruitment correlation | `logit_log_R` | `logit_log_R` |

`log_` 参数通常用 `log(自然尺度值)`，相关系数的变换必须以对应模板为准。尤其 ACL 的 `t0` 是原尺度，而 ALSCL 的 `log_t0` 经 exp 变换，因此本版 ALSCL 的该参数化不支持负 t0。不要将 ACL 参数表直接用于 ALSCL。全部 14/15 个估计参数的名称、变换及上下界查询方法见 [初值列表参考](https://github.com/Linbojun99/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#estimation_parameters)。

Most `log_` parameters use log-transformed values; correlation transforms must match the template. ACL `t0` is untransformed, while ALSCL exponentiates `log_t0`, preventing negative t0 in this parameterization. Do not interchange their parameter lists.

### 6.1 Speed settings

`alscl_speed()` sets two options that apply to every later call of `run_acl()`, `run_alscl()`, `retro_model()` and `sim_acl()`:

- `sd_cores` (default `"auto"`): the number of cores used within one fit to compute standard errors. The fixed-effect Hessian and the delta-method standard errors are computed in parallel, and the results match the sequential calculation at the same fitted parameters. Since 2.2.2, refinement can change the optimum, so complete fits need not be identical to older versions. `"auto"` uses up to four cores. On macOS and Linux in a terminal, forked processes compute both; on Windows, in GUI front-ends such as RStudio and R.app, and with Apple's Accelerate BLAS, socket workers compute the delta method when it would take more than about 3 seconds. This is separate from `ncores`, which sets the number of workers for multiple starts.
- `framework` (default `"CppAD"`): the automatic-differentiation library that TMB compiles the model with. `"TMBad"` is faster, but its estimates differ slightly from CppAD (by up to 2.7e-8, relative, in the fits tested), so it is an option.

```r
alscl_speed()                      # defaults: parallel standard errors at the fitted optimum
alscl_speed(framework = "TMBad")   # faster; results not identical to the default
alscl_speed(sd_cores = 1)          # sequential standard errors, e.g. inside your own parallel loop
b <- run_alscl(x, silent = TRUE)
```

In the pre-2.2.2 benchmark of 90 fits (ACL and ALSCL fitted to `YTF_example` and the flatfish and tuna cases), the default settings made fits 1.13-1.24 times faster with every estimate and standard error identical to the original code, and `framework = "TMBad"` made them 1.25-1.68 times faster. `alscl_speed_info()` shows what the settings mean on your computer, and `fit$sd_info` records how the standard errors of a fit were computed. The [speed guide](https://github.com/Linbojun99/ALSCL/blob/main/docs/SPEED_GUIDE.md) explains every setting, how to check and record them, and when to use TMBad; the full record of the checks is [docs/SPEED.md](https://github.com/Linbojun99/ALSCL/blob/main/docs/SPEED.md).

![Fit time before and after the speed settings](https://github.com/Linbojun99/ALSCL/blob/main/docs/figures/speed/timing.png?raw=true)

![Estimates and standard errors before and after the speed settings](https://github.com/Linbojun99/ALSCL/blob/main/docs/figures/speed/agreement.png?raw=true)

## 2.2.2 的优化收尾与年度共用 F

`run_acl(x)` 和 `run_alscl(x)` 默认对选中的拟合执行最多五步受保护的 Newton 收尾（`polish = TRUE`）。每步要求数值 Hessian 正定、参数严格位于上下界内、最大绝对梯度下降，且目标函数增加不超过 `1e-8` 的浮点舍入容差。不满足条件就停止；收尾不能补足资料信息，也不能修复不合适的模型。`polish = FALSE` 可跳过收尾。这可能改变数值精度层面的估计，因此 2.2.2 不承诺与旧版拟合逐位一致。

每轮优化的原始参数、目标函数、代码和信息保存在 `fit$optimizer_history`。后续一轮在同一点误报失败时，不再覆盖前一轮成功状态。`fit$raw_opt` 保存收尾前选中的结果；`fit$refinement` 记录接受的步骤及前后梯度。`convergence_code` 始终表示所选优化轮次的原始代码，不会因收尾而强行改为成功。多起点仍按收尾前最低有限目标函数选取；`starts` 和 `start_diagnostics` 记录收尾前各起点的结果。

`fit$diagnostics` 增加独立的数值筛查：最大梯度小于 `1e-3`、Hessian 与协方差正定、不触及优化器边界或自然尺度边界。自由相关系数距离 0 或 1 不超过 `1e-4`，以及自由过程／观测标准差不超过 `1e-4`，都会标记。这些是筛查阈值，不是统计检验。`high_correlations` 列出绝对相关系数至少 0.95 的参数对，需进一步审查，但不能单凭高相关就断言不可识别。协方差条件数取决于参数尺度。`diagnose_model()` 分别显示原始优化代码和数值筛查结果；仍需检查残差、多起点、似然剖面和敏感性。

### 明确选择 F 结构

默认 `F_structure = "group_year"` 保留原来的年龄 × 时间（ACL）或体长 × 时间（ALSCL）二维可分离 AR(1) 场。可选 `F_structure = "year"` 假设**同一时间步内所有年龄或体长的瞬时 F 相同**。季度数据是每季度一个 F，不是每个日历年一个 F。这项生物学假设必须符合渔业情况，不能只为得到收敛结果而选择。

共用结构为 `log(F[y]) = mean_log_F + u[y]`，采用平稳一维 AR(1)：`u[1]` 的标准差为 `sigma_F`，后续创新标准差为 `sigma_F * sqrt(1 - rho_y^2)`。F 随机效应从 A × Y 或 L × Y 减为 Y 个。C++ 似然只有一个正确归一化的一维 AR(1) 密度，并非把二维密度的单元格强制设成相同值。不再使用的年龄／体长相关参数自动固定，从自由参数及拟合报告中移除，即使其 map 项为 NULL 也不会估计；其他默认 map 规则保持不变。`report$dev_log_F` 为 1 × Y；`report$F`（ACL）或 `report$FL`（ALSCL）仍保留完整的组别 × Y 维度，F 偏差图显示一条共用序列。

以下假设 `x` 已按完整调查案例整理好三表、生物设置与初值。这里只固定**有效标量参数中的 t0**；不使用的组别相关参数由模型结构排除：

```r
map_acl_t0 <- list(t0 = factor(NA), log_std_log_F = NULL,
                   logit_log_F_y = NULL, logit_log_F_a = NULL)
map_alscl_t0 <- list(log_t0 = factor(NA), log_sigma_log_F = NULL)
a_year <- run_acl(x, map = map_acl_t0, F_structure = "year")
b_year <- run_alscl(x, map = map_alscl_t0, F_structure = "year")
a_year$optimizer_history
a_year$refinement
b_year$diagnostics
b_year$sd_info
diagnose_model(x$data.CatL, b_year)
plot_deviance(a_year, type = "F", se = TRUE)
plot_fishing_mortality(b_year, se = TRUE)
# 保存设置后，继续使用最短写法：
x$fit_config$acl$map <- map_acl_t0
x$fit_config$alscl$map <- map_alscl_t0
x$fit_args$F_structure <- "year"
a_year <- run_acl(x)
b_year <- run_alscl(x)
```

原来的逐项传参和 `do.call()` 写法保留。`retro_model()`（含其包装函数）和 `sim_acl()` 也支持 `F_structure` 与 `polish`；回溯每轮应使用相同结构。并行标准误和多起点继续沿用现有加速设置。注意 `sim_data()` 的 F 创新标准差不等于拟合 AR(1) 的边际标准差；一维平稳 AR(1) 的边际标准差为创新标准差除以 `sqrt(1 - rho_y^2)`。

此前模拟 YTF 数据的只固定 t0 ACL 拟合中，年龄相关系数逼近 1；生成数据恰好在同一年对所有年龄使用相同 F，共用 F 结构可处理这种不匹配。只固定 t0 的 ALSCL 则主要受优化收尾误报影响。两项发现都不代表你的正式数据能识别全部参数。实测结果与适用限制见 [2.2.2 可复现验证](https://github.com/Linbojun99/ALSCL/blob/main/docs/RELEASE_2.2.2.md)。

## Refinement and shared F in 2.2.2

`run_acl(x)` and `run_alscl(x)` now finish the selected fit with up to five safeguarded Newton steps (`polish = TRUE`). Each step requires a positive-definite numerical Hessian, parameters strictly inside their bounds, a smaller maximum absolute gradient, and an objective increase no greater than `1e-8` for floating-point roundoff. Refinement stops if a condition fails; it cannot repair insufficient information or an inappropriate model. Set `polish = FALSE` to skip it. This can change estimates at numerical precision, so 2.2.2 does not promise bitwise equality with older fits.

Repeated optimizer passes retain their raw parameters, objective, code and message in `fit$optimizer_history`. An unchanged failed restart no longer overwrites an earlier successful pass. `fit$raw_opt` records the selected result before refinement; `fit$refinement` records accepted steps and before/after gradients. `convergence_code` remains the selected raw optimizer code, not an invented success code after refinement. Multistart selection still uses the lowest finite objective before refinement; `starts` and `start_diagnostics` describe those unrefined starts.

`fit$diagnostics` adds a separate numerical screen: maximum gradient below `1e-3`, positive-definite Hessian and covariance, no optimizer boundary and no natural-scale boundary. Free correlations within `1e-4` of 0 or 1 and free process/observation SDs at or below `1e-4` are flagged. These are screening thresholds, not statistical tests. `high_correlations` lists parameter pairs with absolute correlation at least 0.95; this warrants investigation but does not alone prove non-identifiability. The covariance condition number depends on parameter scaling. `diagnose_model()` prints the raw optimizer status and numerical screen separately; inspect residuals, alternative starts, profiles and sensitivity as well.

### Choose the F structure explicitly

The default `F_structure = "group_year"` preserves the original age × time (ACL) or length × time (ALSCL) separable AR(1) field. The optional `F_structure = "year"` assumes **the same instantaneous F for all ages or lengths within each time step**. For quarterly data, this is one F per quarter, not one per calendar year. This biological assumption is appropriate only when supported by the fishery; it is not an automatic cure for non-convergence.

In the shared structure, `log(F[y]) = mean_log_F + u[y]`, with a stationary one-dimensional AR(1): `u[1]` has SD `sigma_F`, and later innovations have SD `sigma_F * sqrt(1 - rho_y^2)`. There are Y random F effects instead of A × Y or L × Y. The C++ likelihood includes exactly one normalized AR(1) density. It does not tie together cells of a two-dimensional density. The unused age/length correlation is automatically fixed, excluded from free parameters and omitted from the fitted report, even if its map entry is NULL. Other map defaults remain unchanged. `report$dev_log_F` is 1 × Y; `report$F` (ACL) or `report$FL` (ALSCL) retains its full group × Y shape, and F-deviation plots show one shared series.

The following example assumes `x` contains your validated input tables, biology and starting values from the complete survey example. It fixes only t0 among the **active** scalar parameters; the unused group correlation is structurally absent:

```r
map_acl_t0 <- list(t0 = factor(NA), log_std_log_F = NULL,
                   logit_log_F_y = NULL, logit_log_F_a = NULL)
map_alscl_t0 <- list(log_t0 = factor(NA), log_sigma_log_F = NULL)
a_year <- run_acl(x, map = map_acl_t0, F_structure = "year")
b_year <- run_alscl(x, map = map_alscl_t0, F_structure = "year")
a_year$optimizer_history
a_year$refinement
b_year$diagnostics
b_year$sd_info
diagnose_model(x$data.CatL, b_year)
plot_deviance(a_year, type = "F", se = TRUE)
plot_fishing_mortality(b_year, se = TRUE)
# Store the choice to continue using the shortest syntax:
x$fit_config$acl$map <- map_acl_t0
x$fit_config$alscl$map <- map_alscl_t0
x$fit_args$F_structure <- "year"
a_year <- run_acl(x)
b_year <- run_alscl(x)
```

Original separate-argument and `do.call()` calls remain valid. `retro_model()` (including its wrappers) and `sim_acl()` also accept `F_structure` and `polish`; pass the same structure to all retrospective peels. Parallel standard errors and multistart workers continue to use the existing speed settings. In `sim_data()`, F innovation SD is not the same as the marginal SD in the fitting AR(1); for one-dimensional stationary AR(1), marginal SD equals innovation SD divided by `sqrt(1 - rho_y^2)`.

The earlier t0-only ACL failure on the synthetic YTF data was associated with age correlation approaching 1; those data were generated with shared F across ages. The shared-F alternative addresses that mismatch. The t0-only ALSCL false-convergence case instead benefits from numerical refinement. Neither finding establishes that all parameters are identifiable in your own observations. See the [2.2.2 reproducible validation](https://github.com/Linbojun99/ALSCL/blob/main/docs/RELEASE_2.2.2.md) for measured results and limitations.

![2.2.2 convergence checks](https://github.com/Linbojun99/ALSCL/blob/main/docs/figures/convergence-2.2.2.png?raw=true)

---

[← 上一章 · Previous](https://github.com/Linbojun99/ALSCL/wiki/05-Simulation) · [目录 · Contents](https://github.com/Linbojun99/ALSCL/wiki) · [下一章 · Next →](https://github.com/Linbojun99/ALSCL/wiki/07-Diagnostics)
