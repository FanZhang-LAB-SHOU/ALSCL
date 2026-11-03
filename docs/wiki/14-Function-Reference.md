# 14 全部函数与参数 · Complete function reference

[← 上一章 · Previous](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/13-Colors-and-Export) · [目录 · Contents](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [下一章 · Next →](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/15-Reproducibility)

**ALSCL 2.4.3 · 简体中文 / English**

对应 ALSCL 2.4.3，覆盖 **65 个公开函数**。签名及默认值从实际 R 函数提取；每项参数均有中文说明和英文帮助。签名中的 `c(...)` 通常列出可选值，默认取第一项。`NULL` 的含义依函数而异，未必表示停用。

All **65 exported functions** of ALSCL 2.4.3 are covered. Signatures/defaults were extracted from R. Each argument has Chinese guidance and English help. For a choice argument, `c(...)` lists options and the first is the default.

[使用指南 / Guide](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md) · [图谱 / Gallery](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md)

## 示例环境 / Example context

先执行使用指南中的内置数据拟合，得到 `x`、`inputs`、`a`（ACL）、`b`（ALSCL），并设 `dat <- x$data.CatL`。回溯示例生成 `ra`、`rb`；模拟依次运行 `initialize_params`、`sim_cal`、`sim_data`。独立参数函数无需拟合对象。

First run the guide's built-in fitting example to define `x`, `inputs`, `a` and `b`; set `dat <- x$data.CatL`. Retrospective examples define `ra/rb`. Run simulation constructors in order. Standalone biological functions need no fitted model.

```r
library(ALSCL)
library(ggplot2)
library(patchwork)
data(YTF_example)
x <- YTF_example
inputs <- x[c("data.CatL", "data.wgt", "data.mat")]
dat <- x$data.CatL
```

## 索引 / Index

- [simulate_fit](#simulate_fit) — 给定拟合种群状态，或重新抽取其过程偏差后，模拟调查观测。 / Simulate survey observations conditionally on a fitted population or after resampling its process deviations.
- [summarize_simulations](#summarize_simulations) — 使用明确分母汇总模拟偏差、RMSE、区间覆盖率、拟合失败与耗时。 / Summarize simulation bias, RMSE, interval coverage, fitting failures and timing with explicit denominators.
- [sim_model](#sim_model) — 使用统一批次流程，把 ACL 或 ALSCL 拟合到已保存的模拟重复数据。 / Fit ACL or ALSCL to saved simulation replicates using the same batch pipeline.
- [sim_alscl](#sim_alscl) — 使用 ALSCL 拟合模拟批次的便捷入口。 / Convenience interface for simulation batches fitted with ALSCL.
- [save_assessment](#save_assessment) — 保存完整可移植评估 / Save a portable assessment
- [refit_model](#refit_model) — 按保存配方重新拟合 / Refit a stored assessment recipe
- [read_survey_excel](#read_survey_excel) — 读取 Excel 工作簿中的调查、体重和成熟比例工作表。 / Read survey, weight and maturity sheets from an Excel workbook.
- [read_survey_csv](#read_survey_csv) — 从三个 CSV 文件读取对齐的调查、体重和成熟比例数据表。 / Read aligned survey, weight and maturity tables from three CSV files.
- [read_assessment](#read_assessment) — 读取可移植评估存档 / Read a portable assessment archive
- [project_model](#project_model) — 从 ACL 或 ALSCL 拟合末期状态开始，按明确给定的假设推演确定性种群情景。 / Project explicit deterministic population scenarios from the terminal fitted ACL or ALSCL state.
- [profile_model](#profile_model) — 逐网格固定一个自由标量参数，重新优化其余参数及随机效应。 / Fix a free scalar at each grid value and reoptimize the remaining parameters and random effects.
- [prepare_alscl_data](#prepare_alscl_data) — 把三张数据表、三个 CSV 文件或 Excel 工作簿整理为可直接拟合的输入列表。 / Prepare a reusable input bundle from tables, three CSV files or an Excel workbook.
- [hindcast_model](#hindcast_model) — 逐步扩展训练窗口，对真正留出的调查指数进行点预测并评分。 / Fit expanding training windows and score survey-index point predictions against genuinely withheld periods.
- [inspect_parameters](#inspect_parameters) — 查看实际初值、上下界，以及自由、固定或共享的参数状态。 / Inspect effective parameter starts, bounds and free/fixed/tied restrictions.
- [fit_scenarios](#fit_scenarios) — 在同一观测数据上串行或 socket 并行拟合具名敏感性情景。 / Fit named sensitivity scenarios on common observations with serial or socket execution.
- [extract_parameters](#extract_parameters) — 提取参数、尺度与固定状态 / Extract parameters, scales and estimation status
- [extract_estimates](#extract_estimates) — 统一提取带坐标的种群估计 / Extract population estimates with coordinates
- [check_fit](#check_fit) — 用时间–体长热图、按实际时间间隔计算的滞后相关及正态 QQ 图检查条件观测残差。 / Inspect conditional observation residuals with a time–length heatmap, actual-time lag correlations and a normal QQ plot.
- [check_alscl_data](#check_alscl_data) — 在编译或拟合之前检查完整数据和模型设置。 / Check complete data and model settings before compiling or fitting.
- [acl_theme](#acl_theme) — 读取全局主题 / Read global theme settings
- [acl_theme_reset](#acl_theme_reset) — 恢复默认主题 / Reset theme settings
- [acl_theme_set](#acl_theme_set) — 设置全局主题 / Set global theme settings
- [alscl_speed](#alscl_speed) — 设置拟合速度选项 / Set speed options for model fitting
- [alscl_speed_info](#alscl_speed_info) — 查看速度设置的实际效果 / Show how fits will use the speed settings
- [compare_models](#compare_models) — 生成两个模型的数值比较表 / Compare fitted model summaries
- [create_parameters](#create_parameters) — 建立模型初值及边界 / Construct estimation starts and bounds
- [create_parameters_alscl](#create_parameters_alscl) — ALSCL 初值及边界便捷入口 / ALSCL parameter constructor
- [diagnose_model](#diagnose_model) — 汇总诊断指标 / Summarize diagnostics
- [diagnostic_metrics](#diagnostic_metrics) — 计算样本内拟合误差和信息指标 / Calculate in-sample fit errors and information criteria
- [generate_map](#generate_map) — 合并 ACL 默认固定参数与自定义映射 / Merge ACL default and custom maps
- [initialize_params](#initialize_params) — 建立模拟生物参数 / Initialize simulation biology
- [mat_func](#mat_func) — 计算 logistic 成熟比例 / Calculate logistic maturity
- [plot_abundance](#plot_abundance) — 丰度 N / Abundance N
- [plot_biomass](#plot_biomass) — 生物量 B / Biomass B
- [plot_catch](#plot_catch) — 捕获尾数 CN / Catch numbers CN
- [plot_CatL](#plot_CatL) — 调查拟合 length 对数尺度 / Survey fit length log scale
- [plot_compare_annual_F](#plot_compare_annual_F) — 已弃用，改用 plot_compare_F_ts / Deprecated, use plot_compare_F_ts
- [plot_compare_CatL](#plot_compare_CatL) — 两模型调查拟合 / Survey fits from both models
- [plot_compare_F](#plot_compare_F) — 死亡率矩阵比较 / Fishing mortality matrices
- [plot_compare_F_ts](#plot_compare_F_ts) — 各时间步 F 比较 / Fishing mortality by time step
- [plot_compare_growth](#plot_compare_growth) — 生长与外部参照接口 / Growth and reference-data interface
- [plot_compare_metrics](#plot_compare_metrics) — 拟合指标比较 / Fit metric comparison
- [plot_compare_residuals](#plot_compare_residuals) — 残差联合诊断 / Combined residual diagnostics
- [plot_compare_selectivity](#plot_compare_selectivity) — 固定调查可捕性 / Fixed survey catchability
- [plot_compare_ts](#plot_compare_ts) — 种群时间序列比较 / Population time series comparison
- [plot_deviance](#plot_deviance) — 过程偏差 R TRUE / Process deviations R TRUE
- [plot_fishing_mortality](#plot_fishing_mortality) — ACL 捕捞死亡率 year / ACL fishing mortality year
- [plot_pla](#plot_pla) — 年龄长度转换 / Age length conversion
- [plot_recruitment](#plot_recruitment) — 补充量 / Recruitment
- [plot_residuals](#plot_residuals) — 对数残差 length / Log residuals length
- [plot_retro](#plot_retro) — ACL 回溯分析 / ACL retrospective analysis
- [plot_ridges](#plot_ridges) — 长度组成山脊图 / Length composition ridges
- [plot_SSB](#plot_SSB) — 产卵生物量 SSB / Spawning biomass SSB
- [plot_SSB_Rec](#plot_SSB_Rec) — 亲体与补充关系 / Spawning biomass and recruitment
- [plot_VB](#plot_VB) — 生长曲线与区间 / Growth curve and interval
- [retro_acl](#retro_acl) — ACL 回溯入口 / ACL retrospective wrapper
- [retro_alscl](#retro_alscl) — ALSCL 回溯入口 / ALSCL retrospective wrapper
- [retro_model](#retro_model) — 统一回溯分析 / Unified retrospective analysis
- [run_acl](#run_acl) — 拟合年龄型 ACL / Fit age-based ACL
- [run_alscl](#run_alscl) — 拟合年龄与长度联合 ALSCL / Fit joint age-length ALSCL
- [sim_acl](#sim_acl) — 批量拟合 ACL 模拟重复 / Fit simulated replicates with ACL
- [sim_cal](#sim_cal) — 从参数计算生物矩阵 / Calculate biological arrays
- [sim_data](#sim_data) — 运行完整随机种群模拟 / Simulate full population dynamics
- [simulate_example_data](#simulate_example_data) — 快速年度教学数据生成 / Generate simple annual teaching data
- [VB_func](#VB_func) — 计算 VB 平均体长 / Calculate VB mean length

<a id="acl_theme"></a>
## `acl_theme()`

读取全局主题 / Read global theme settings

```r
acl_theme (what = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `what` | `NULL` | NULL 返回全部全局主题设置，字符名称返回单项。 | Optional character. Retrieve a specific element, e.g. "titles", "font_family", "compare_colors". |

**返回 / Returns:** `what=NULL` 时返回完整设置列表，否则返回指定设置项。

The complete settings list when `what=NULL`, or the requested setting otherwise.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
acl_theme()
acl_theme("line_color")
```

![示例图 / Example figure: `plot_SSB(b, se = TRUE) under each palette of acl_theme_set()`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/palettes/ssb_by_palette.png?raw=true&v=3e6eab644390)

<a id="acl_theme_reset"></a>
## `acl_theme_reset()`

恢复默认主题 / Reset theme settings

```r
acl_theme_reset ()
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|

**返回 / Returns:** 重置选项并打印提示后，不可见地返回 NULL。

Invisibly returns NULL after resetting the option and printing a confirmation.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
acl_theme_reset()
```

<a id="acl_theme_set"></a>
## `acl_theme_set()`

设置全局主题 / Set global theme settings

保存 `old <- acl_theme()`，再用 `do.call(acl_theme_set, old)` 完整恢复设置。显式 `x_breaks = NULL` 恢复自动刻度，`ylab = list(survey = NULL)` 清除调查标签覆盖值；省略参数保留当前值。

Save `old <- acl_theme()` and restore the settings with `do.call(acl_theme_set, old)`. Explicit `x_breaks = NULL` restores automatic breaks and `ylab = list(survey = NULL)` clears a survey-label override; omitted arguments leave current values unchanged.

省略的 `line_size` 与 `se_alpha` 参数继承 `acl_theme_set()`（默认 1.5 与 0.2），函数显式参数优先。比较曲线遵守 `linetypes` 与 `compare_linetypes`，残差和指标组合图的标题及 F 分面文字继承全局字体设置。默认无网格。

Omitted `line_size` and `se_alpha` arguments inherit `acl_theme_set()` (defaults 1.5 and 0.2); explicit function arguments take priority. Comparison curves honor `linetypes` and `compare_linetypes`, and the titles of the combined residual and metric plots and the F facet labels inherit the global typography. Grid lines are absent by default.

```r
acl_theme_set (base_theme = NULL, font_family = NULL, title_size = NULL, title_hjust = NULL,
    axis_title_size = NULL, axis_text_size = NULL, strip_text_size = NULL, legend_text_size = NULL,
    x_breaks = NULL, x_expand = NULL, line_color = NULL, line_size = NULL, point_size = NULL,
    se_color = NULL, se_alpha = NULL, compare_colors = NULL, compare_linetypes = NULL,
    compare_line_size = NULL, compare_point_size = NULL, compare_se_alpha = NULL,
    compare_legend_pos = NULL, compare_facet_ncol = NULL, compare_facet_scales = NULL,
    titles = NULL, xlab = NULL, ylab = NULL, palette = NULL, point_color = NULL,
    observed_color = NULL, smooth_color = NULL, hline_color = NULL, low_col = NULL,
    high_col = NULL, ...)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character. Base ggplot2 theme name. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character. Font family for all text. |
| `title_size` | `NULL` | 图标题字号。 | Numeric. Plot title size in pt. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric. Title alignment (0=left, 0.5=center, 1=right). |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric. Axis title size. |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric. Axis tick label size. |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric. Facet label size. |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric. Legend text size. |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector or NULL. Custom x-axis breaks. |
| `x_expand` | `NULL` | 横轴留白设置，长度 2 的数值向量。 | Numeric vector of length 2. X-axis expansion. |
| `line_color` | `NULL` | 单模型线条颜色。 | Character. Default line color for single-model plots. |
| `line_size` | `NULL` | NULL 继承全局 line_size，显式值优先。 | NULL inherits global line_size; explicit values take priority. |
| `point_size` | `NULL` | 所有含点图的默认点大小（2.5）；比较图可单独覆盖。 | Default point size for all point-drawing plots (2.5); comparison plots can override it. |
| `se_color` | `NULL` | 区间阴影或误差棒的颜色。 | Character. Default CI color. |
| `se_alpha` | `NULL` | NULL 继承全局 se_alpha，显式值优先。 | NULL inherits global se_alpha; explicit values take priority. |
| `compare_colors` | `NULL` | 按两个模型顺序提供两种颜色；名称可选。 | Character vector of 2 colors. Can be unnamed (positional) or named. The first color is always model1, second is model2. Examples: c("blue", "red"), c(ACL = "blue", ALSCL = "red"), c("M=0" = "steelblue", "M=0.5" = "tomato"). |
| `compare_linetypes` | `NULL` | 按模型顺序提供两种线型。 | Character vector of 2 linetypes. Same rules as colors. |
| `compare_line_size` | `NULL` | 比较图全局线宽。 | Numeric. Line width for comparison plots. |
| `compare_point_size` | `NULL` | 可选的比较图点大小；显式 NULL 清除覆盖，恢复继承 point_size。 | Optional comparison point-size override; explicit NULL clears it and restores point_size inheritance. |
| `compare_se_alpha` | `NULL` | 比较图区间透明度。 | Numeric. CI ribbon alpha for comparison plots. |
| `compare_legend_pos` | `NULL` | 图例位置，如 bottom、right、none。 | Character. Legend position for comparison plots. |
| `compare_facet_ncol` | `NULL` | 比较图全局分面列数。 | Integer. Default facet columns in comparison plots. |
| `compare_facet_scales` | `NULL` | 比较图全局分面尺度。 | Character. Facet scales for comparison plots. |
| `titles` | `NULL` | 以图名为键的标题列表，用于全局覆盖。 | Named list. Override specific titles. |
| `xlab` | `NULL` | 坐标轴标签；主题设置函数中使用命名列表。 | Named list. Override specific x-axis labels. |
| `ylab` | `NULL` | 坐标轴标签；主题设置函数中使用命名列表。 | Named list. Override specific y-axis labels. |
| `palette` | `NULL` | ggsci 色板名；NULL 继承全局设置，部分图也保留旧色板。 | Character or NULL. ggsci palette: "npg" (default), "aaas", "nejm", "lancet", or "jama". Changing it resets palette-derived colors; explicit color arguments in the same call take precedence. No arguments leaves settings unchanged; use acl_theme_reset() to reset. |
| `point_color` | `NULL` | 点颜色。 | Character or NULL. Default point, observation, smoother and reference-line colors. |
| `observed_color` | `NULL` | 观测数据颜色；NULL 继承全局角色。 | Character or NULL. Default point, observation, smoother and reference-line colors. |
| `smooth_color` | `NULL` | 残差平滑线颜色。 | Character or NULL. Default point, observation, smoother and reference-line colors. |
| `hline_color` | `NULL` | 残差零参考线颜色。 | Character or NULL. Default point, observation, smoother and reference-line colors. |
| `low_col` | `NULL` | 概率热图的低值 / 高值颜色。 | Character or NULL. Continuous heatmap endpoints. |
| `high_col` | `NULL` | 概率热图的低值 / 高值颜色。 | Character or NULL. Continuous heatmap endpoints. |
| `...` | 可选 / optional | 旧参数名 compare_linewidth，仍可使用但会给出警告。 | The former argument name compare_linewidth, accepted with a warning. |

**返回 / Returns:** 不可见地返回原 `acl.theme` 选项，并更新当前全局选项。

The previous `acl.theme` option, returned invisibly. The active global option is updated.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
acl_theme_set(base_theme = "bw", line_color = "navy")
```

![示例图 / Example figure: `acl_theme_set(palette = "npg")`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/palettes/palettes.png?raw=true&v=b700769161ed)

<a id="alscl_speed"></a>
## `alscl_speed()`

Installed socket workers load the same package installation as the parent. During `pkgload::load_all()` or `testthat::test_local()`, workers instead load the same source checkout with pkgload. Install the optional development dependency pkgload for this workflow. CI exercises both source-mode parallel tests and the complete installed-package checks.

```r
alscl_speed (sd_cores = getOption("ALSCL.sd_cores", "auto"), framework = getOption("ALSCL.framework",
    "CppAD"))
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `sd_cores` | `getOption("ALSCL.sd_cores", "auto")` | 单次拟合中计算标准误所用的核数，结果与顺序计算逐位相同。"auto" 最多使用 4 个物理核并保留 1 个；macOS、Linux 终端中用分叉进程计算 Hessian 与 delta 方法，在 Windows、图形界面（R.app、RGui、RStudio、Positron）及 Apple Accelerate BLAS 下改用 socket 进程计算 delta 方法。 | "auto" or a positive integer. Cores used within one fit to compute standard errors; results are identical to the sequential calculation. "auto" uses up to four physical cores and keeps one free; forked processes compute the Hessian and the delta method on macOS and Linux, and socket workers compute the delta method on Windows, in GUI front-ends and with Apple's Accelerate BLAS. |
| `framework` | `getOption("ALSCL.framework", "CppAD")` | TMB 编译模型所用的自动微分库。"CppAD" 为默认库；"TMBad" 更快但结果略有不同。收尾步骤可能微调最优点，不保证与旧版本逐位一致。 | Character. Automatic-differentiation library: "CppAD" is the default; "TMBad" is faster but results differ slightly. The refinement steps can move the optimum slightly, so results are not guaranteed to be identical across versions. |

**返回 / Returns:** 不可见地返回原 `ALSCL.sd_cores` 与 `ALSCL.framework` 选项，可用 `options(old)` 恢复。

The previous `ALSCL.sd_cores` and `ALSCL.framework` options, returned invisibly; `options(old)` restores them.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
old <- alscl_speed(sd_cores = 1)
alscl_speed(framework = "TMBad")
options(old)
```

<a id="alscl_speed_info"></a>
## `alscl_speed_info()`

查看速度设置的实际效果 / Show how fits will use the speed settings

```r
alscl_speed_info ()
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|

**返回 / Returns:** 带有 alscl_speed_info 类的两列数据框：item 是设置或说明项目，value 是其值。内容包括标准误核数、计算方式及原因、自动微分框架、TMB 版本及跨版本数值一致性提示。

A data frame with class alscl_speed_info and columns item (setting or information item) and value. It reports standard-error workers, computation method and reason, the automatic-differentiation framework, the TMB version and the cross-version numerical-identity notice.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
alscl_speed_info()
```

<a id="compare_models"></a>
## `compare_models()`

生成两个模型的数值比较表 / Compare fitted model summaries

拟合、诊断和模型比较统一解析普通 data.frame、matrix、tibble 及保存数值文本的 factor 列。因子按标签转为观测值，不使用内部等级编码；体长标签按向量提取。修改了观测值、缺测掩码、年份或体长组顺序时，原有匹配检查仍会报错。

Fitting, diagnostics and comparison use the same interpretation of ordinary data frames, matrices, tibbles and numeric-text factor columns. Factor labels are converted to observation values, never to internal level codes. Length labels are extracted as a vector. The checks for changed observations, missing-data masks, time labels and length-bin order still apply.

```r
compare_models (model1, model2, data.CatL, model1_name = NULL, model2_name = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model1` | `必填 / required` | 第一个拟合对象。 | A list from run_acl or run_alscl. Treated as the reference model. |
| `model2` | `必填 / required` | 第二个拟合对象。 | A list from run_acl or run_alscl. Treated as the alternative model. |
| `data.CatL` | `必填 / required` | 调查数量指数表：首列体长标签，其余列为时间。 | The original survey numbers-at-length or index table used for in-sample goodness-of-fit. |
| `model1_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Label for model1. Default is auto-detected from model_type. |
| `model2_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Label for model2. Default is auto-detected from model_type. |

**返回 / Returns:** 不可见地返回列表：summary 为优化状态、目标函数、信息准则和耗时比较；growth 为生长参数；fit_metrics 为样本内调查拟合误差；correlation 为共同种群时间序列的 Pearson 相关系数及均值比 Ratio_Mean（model2/model1）。fit_diagnostics 保存数值诊断；comparison 包含数据是否核验（data_verified）、比较是否满足条件（eligible）、满足条件时的优选标签（preferred）及问题（issues）。model1_name 和 model2_name 保存显示标签。

Invisibly returns a list: summary compares optimizer status, objectives, information criteria and timing; growth contains growth parameters; fit_metrics contains in-sample survey-fit errors; correlation contains Pearson correlations and Ratio_Mean (model2/model1) for shared population series. fit_diagnostics records numerical diagnostics. comparison contains data_verified, eligible, preferred and issues; a preference is reported only when comparison conditions are met. model1_name and model2_name retain display labels.

**检查 / Checks:** 要求相同时间、体长标签、正观测及缺失掩码；不匹配报错。返回 fit_diagnostics 和 comparison；不合格拟合或无法核验的旧结果保留原始 AIC，但不自动推荐模型。 / Requires matching periods, length labels, positive observations and masks. Returns fit_diagnostics and comparison; failed or unverifiable fits retain raw AIC without an automatic preference.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
compare_models(a, b, dat)
```

<a id="create_parameters"></a>
## `create_parameters()`

建立模型初值及边界 / Construct estimation starts and bounds

`create_parameters(species = "krill", model_type = "acl")` 提供 Linf 初值 90 和边界，不会自动固定 Linf，也不更改 M、nage 或时间步长。需要固定时，显式传入 `map = list(log_Linf = factor(NA))` 和选定初值；生物设置仍需在拟合参数中提供。

`create_parameters(species = "krill", model_type = "acl")` supplies a Linf start of 90 and bounds, but does not fix Linf or change M, nage or the time step. To fix it, explicitly pass `map = list(log_Linf = factor(NA))` with the chosen starting value. Biological settings still belong in the fitting arguments.

```r
create_parameters (model_type = c("acl", "alscl"), species = NULL, parameters = NULL, parameters.L = NULL,
    parameters.U = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model_type` | `c("acl", "alscl")` | 模型选择：acl 或 alscl。 | Character. Either "acl" or "alscl". Determines which TMB model parameter names and defaults to use. |
| `species` | `NULL` | 物种预设 flatfish、tuna、krill；? 列出预设。 | Character or NULL. Optional species preset: "flatfish" (M7 yellowtail flounder-like, annual, Linf=60), "tuna" (M6 tuna-like, quarterly, Linf=152), or "krill" (Antarctic krill-like, Linf=60-90). When NULL (default), generic wide-range defaults are used. Each preset provides species-specific initial values and bounds that have been tested in simulation studies. See Details. |
| `parameters` | `NULL` | 命名参数初值列表，采用优化器尺度。 | A list of custom initial values (default NULL = use all defaults). Only the parameters you specify will be overridden; all others keep their default (or species-preset) values. |
| `parameters.L` | `NULL` | 命名下界列表，采用优化器尺度。 | A list of custom lower bounds (default NULL). |
| `parameters.U` | `NULL` | 命名上界列表，采用优化器尺度。 | A list of custom upper bounds (default NULL). |

**返回 / Returns:** 包含 parameters（初值）、parameters.L（下界）和 parameters.U（上界）的列表；三个元素均为优化器尺度上的命名列表，名称对应所选 TMB 模型参数。

A list with parameters (starts), parameters.L (lower bounds) and parameters.U (upper bounds). Each is a named list on the optimizer scale, with names matching the selected TMB model.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
create_parameters(model_type = "acl", species = "flatfish")
```

<a id="create_parameters_alscl"></a>
## `create_parameters_alscl()`

ALSCL 初值及边界便捷入口 / ALSCL parameter constructor

`create_parameters(species = "krill", model_type = "acl")` 提供 Linf 初值 90 和边界，不会自动固定 Linf，也不更改 M、nage 或时间步长。需要固定时，显式传入 `map = list(log_Linf = factor(NA))` 和选定初值；生物设置仍需在拟合参数中提供。

`create_parameters(species = "krill", model_type = "acl")` supplies a Linf start of 90 and bounds, but does not fix Linf or change M, nage or the time step. To fix it, explicitly pass `map = list(log_Linf = factor(NA))` with the chosen starting value. Biological settings still belong in the fitting arguments.

```r
create_parameters_alscl (species = NULL, parameters = NULL, parameters.L = NULL, parameters.U = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `species` | `NULL` | 物种预设 flatfish、tuna、krill；? 列出预设。 | Character or NULL. Optional species preset: "flatfish" (M7 yellowtail flounder-like, annual, Linf=60), "tuna" (M6 tuna-like, quarterly, Linf=152), or "krill" (Antarctic krill-like, Linf=60-90). When NULL (default), generic wide-range defaults are used. Each preset provides species-specific initial values and bounds that have been tested in simulation studies. See Details. |
| `parameters` | `NULL` | 命名参数初值列表，采用优化器尺度。 | A list of custom initial values (default NULL = use all defaults). Only the parameters you specify will be overridden; all others keep their default (or species-preset) values. |
| `parameters.L` | `NULL` | 命名下界列表，采用优化器尺度。 | A list of custom lower bounds (default NULL). |
| `parameters.U` | `NULL` | 命名上界列表，采用优化器尺度。 | A list of custom upper bounds (default NULL). |

**返回 / Returns:** 包含 parameters（初值）、parameters.L（下界）和 parameters.U（上界）的列表；三个元素均为优化器尺度上的命名列表，名称对应所选 TMB 模型参数。

A list with parameters (starts), parameters.L (lower bounds) and parameters.U (upper bounds). Each is a named list on the optimizer scale, with names matching the selected TMB model.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
create_parameters_alscl(species = "flatfish")
```

<a id="diagnose_model"></a>
## `diagnose_model()`

汇总诊断指标 / Summarize diagnostics

拟合、诊断和模型比较统一解析普通 data.frame、matrix、tibble 及保存数值文本的 factor 列。因子按标签转为观测值，不使用内部等级编码；体长标签按向量提取。修改了观测值、缺测掩码、年份或体长组顺序时，原有匹配检查仍会报错。

Fitting, diagnostics and comparison use the same interpretation of ordinary data frames, matrices, tibbles and numeric-text factor columns. Factor labels are converted to observation values, never to internal level codes. Length labels are extracted as a vector. The checks for changed observations, missing-data masks, time labels and length-bin order still apply.

```r
diagnose_model (data.CatL, model_result)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `data.CatL` | `必填 / required` | 调查数量指数表：首列体长标签，其余列为时间。 | Length labels followed by time columns. |
| `model_result` | `必填 / required` | 单次模型拟合结果。 | A fitted model result. |

**返回 / Returns:** 包含 Metric（指标名称）和 Value（数值）的数据框，合并样本内拟合误差与优化、梯度、Hessian 和边界诊断；已有 diagnostics 时还包括数值筛查、协方差条件数及高相关参数对数量。未定义或不可用的指标为 NA，同时在控制台打印主要诊断。

A data frame with Metric and Value, combining in-sample fit metrics with optimizer, gradient, Hessian and boundary diagnostics. When diagnostics are available, it also includes the numerical screen, covariance condition number and count of highly correlated parameter pairs. Undefined or unavailable metrics are NA; key diagnostics are also printed.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
diagnose_model(dat, b)
```

<a id="diagnostic_metrics"></a>
## `diagnostic_metrics()`

计算样本内拟合误差和信息指标 / Calculate in-sample fit errors and information criteria

拟合、诊断和模型比较统一解析普通 data.frame、matrix、tibble 及保存数值文本的 factor 列。因子按标签转为观测值，不使用内部等级编码；体长标签按向量提取。修改了观测值、缺测掩码、年份或体长组顺序时，原有匹配检查仍会报错。

Fitting, diagnostics and comparison use the same interpretation of ordinary data frames, matrices, tibbles and numeric-text factor columns. Factor labels are converted to observation values, never to internal level codes. Length labels are extracted as a vector. The checks for changed observations, missing-data masks, time labels and length-bin order still apply.

```r
diagnostic_metrics (data.CatL, model_result)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `data.CatL` | `必填 / required` | 调查数量指数表：首列体长标签，其余列为时间。 | Length labels followed by time columns. |
| `model_result` | `必填 / required` | 单次模型拟合结果。 | A fitted ACL or ALSCL result. |

**返回 / Returns:** 包含 Metric（指标名称）和 Value（数值）的样本内拟合指标数据框；未定义的指标为 NA。

A data frame of in-sample fit metrics with columns Metric and Value. Undefined metrics are NA.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
diagnostic_metrics(dat, b)
```

<a id="generate_map"></a>
## `generate_map()`

合并 ACL 默认固定参数与自定义映射 / Merge ACL default and custom maps

```r
generate_map (map = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `map` | `NULL` | TMB 映射；factor(NA) 固定，具名 NULL 项释放该项；整个 map=NULL 则使用模型默认固定规则。 | A list containing the custom values for the map elements (default is NULL). log_std_log_F: Custom value for log_std_log_F (default is NA). logit_log_F_y: Custom value for logit_log_F_y (default is NA). logit_log_F_a: Custom value for logit_log_F_a (default is NA). t0: Custom value for t0 (default is NA). Growth parameters log_vbk and log_Linf are free unless explicitly mapped. |

**返回 / Returns:** 合并 ACL 默认规则与用户设置后的具名 TMB 映射列表。factor(NA) 固定参数；具名 NULL 项解除该项默认固定。

A named TMB mapping list combining ACL defaults and supplied settings. factor(NA) fixes a parameter; a named NULL entry releases that default fix.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
generate_map(list(log_Linf = factor(NA), logit_log_F_y = NULL))
```

该函数提供 ACL 默认映射。ALSCL 请使用本例 `x$fit_config$alscl$map` 或模型相应命名参数。默认 `t0/log_std_log_F/logit_log_F_y/logit_log_F_a` 固定，`log_vbk/log_Linf` 默认可估计；自定义未列出的项仍保留默认映射。 / This constructor uses ACL defaults. Use model-specific names for ALSCL. Unmentioned default mappings remain in force.

注意：`generate_map()` 返回值会移除 NULL 项。不要用 `run_acl(x, map = generate_map(list(t0 = NULL)))` 解除 t0，因为拟合函数会再次补入默认项。应直接用 `run_acl(x, map = list(t0 = NULL))`。`map = NULL` 和 `list()` 都是使用模型默认规则，不是全部释放。

The returned map drops NULL entries. Do not use `run_acl(x, map = generate_map(list(t0 = NULL)))` to release t0: the fitter will reapply the absent default. Pass `run_acl(x, map = list(t0 = NULL))` directly. A whole `map = NULL` or `list()` uses model defaults rather than releasing everything.

<a id="initialize_params"></a>
## `initialize_params()`

建立模拟生物参数 / Initialize simulation biology

```r
initialize_params (nyear = NULL, rec.age = NULL, first.year = NULL, nage = NULL, M = NULL,
    init_Z = NULL, vbk = NULL, Linf = NULL, t0 = NULL, len_mid = NULL, len_border = NULL,
    a = NULL, b = NULL, mat_L50 = NULL, mat_L95 = NULL, cv_L = NULL, cv_inc = NULL,
    std_logR = NULL, std_logN0 = NULL, alpha = NULL, beta = NULL, std_SN = NULL,
    q_surv_L50 = NULL, q_surv_L95 = NULL, R_init = NULL, F_mean = NULL, F_ar = NULL,
    F_sd = NULL, R_ar = NULL, species = NULL, growth_step = NULL, burn_in = NULL,
    observation_error = c("independent", "shared_time"))
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `nyear` | `NULL` | 模拟器为总年数；回溯函数为删除的末端时间步数。 | Integer. Total simulation years including burn-in (default 100). |
| `rec.age` | `NULL` | 补充年龄，单位为年。 | Numeric. Age of recruitment (default 1; use 0.25 for quarterly). |
| `first.year` | `NULL` | 模拟返回观测的起始年份标签。 | Numeric. First retained observation year (default 2020); fractional years are allowed. |
| `nage` | `NULL` | 年龄组数量，包括最大年龄加组。 | Integer. Number of age classes including plus-group (default 15). |
| `M` | `NULL` | 每个模型时间步的自然死亡瞬时率。 | Numeric. Natural mortality rate (default 0.2). |
| `init_Z` | `NULL` | 构造初始平衡年龄结构的总死亡率。 | Numeric. Initial total mortality for equilibrium (default 0.5). |
| `vbk` | `NULL` | VB 生长系数，以年为时间单位。 | Numeric. Von Bertalanffy k (default 0.2). |
| `Linf` | `NULL` | VB 渐近体长，与输入体长单位一致。 | Numeric. Asymptotic length (default 60). |
| `t0` | `NULL` | VB 理论零体长年龄，单位为年。 | Numeric. Von Bertalanffy t0 (default 1/60). |
| `len_mid` | `NULL` | 每个体长组的中心值向量，长度与数据行数相同。 | Numeric vector. Midpoints of length bins. |
| `len_border` | `NULL` | 体长边界；拟合入口需要 nlen-1 个内部边界，模拟器使用 nlen+1 个完整边界。 | Complete boundary vector of nlen+1 entries, including outer boundaries. |
| `a` | `NULL` | 长度重量关系 W=a*L^b 的系数，需匹配单位。 | Numeric. Length-weight coefficient (default exp(-12)). |
| `b` | `NULL` | 长度重量关系 W=a*L^b 的指数。 | Numeric. Length-weight exponent (default 3). |
| `mat_L50` | `NULL` | 成熟比例为 0.5 的体长。 | Numeric. Length at 50 pct maturity (default 35). |
| `mat_L95` | `NULL` | 比例为 0.95 的体长，必须不同于 L50；下降选择性可小于 L50。 | Numeric. Length at 95 pct maturity (default 40). |
| `cv_L` | `NULL` | 给定年龄时体长的变异系数。 | Numeric. CV of length-at-age (default 0.2). |
| `cv_inc` | `NULL` | 生长增量的变异系数。 | Numeric. CV of growth increment (default 0.2). |
| `std_logR` | `NULL` | 模拟对数补充偏差的 SD 缩放。 | Numeric. SD of log-recruitment deviations (default 0.3). |
| `std_logN0` | `NULL` | 初始对数年龄组尾数偏差的 SD。 | Numeric. SD of initial log-N deviations (default 0.2). |
| `alpha` | `NULL` | Beverton–Holt 补充关系系数，量纲随丰度与生物量单位改变。 | Numeric. Beverton-Holt alpha (default 400). |
| `beta` | `NULL` | Beverton–Holt 补充关系系数，量纲随丰度与生物量单位改变。 | Numeric. Beverton-Holt beta (default 10). |
| `std_SN` | `NULL` | 调查观测对数误差的标准差。 | Numeric. Survey observation error SD (default 0.2). |
| `q_surv_L50` | `NULL` | 调查可捕性达到 0.5 的体长。 | Length at survey catchability 0.5; the default depends on the species preset. |
| `q_surv_L95` | `NULL` | 调查可捕性达到 0.95 的体长，必须大于 q_surv_L50。 | Length at survey catchability 0.95, greater than q_surv_L50; the default depends on the species preset. |
| `R_init` | `NULL` | 初始补充尾数。 | Numeric. Initial recruitment (default 500). |
| `F_mean` | `NULL` | 每模型时间步的乘法 F 基准水平；不是生成序列的算术平均值。 | Multiplicative F baseline per model step; not the arithmetic mean of the realized trajectory. |
| `F_ar` | `NULL` | 模拟对数 F 过程的 AR(1) 相关参数。 | Numeric. AR(1) correlation of the simulated log-F process (default 0.75). |
| `F_sd` | `NULL` | 对数 F 的 AR(1) 创新标准差；平稳标准差为 F_sd / sqrt(1 - F_ar^2)。 | Innovation SD of the log-F AR(1) process; stationary SD is F_sd / sqrt(1 - F_ar^2). |
| `R_ar` | `NULL` | 模拟补充偏差的 AR(1) 相关参数。 | Numeric. AR1 coefficient for recruitment deviations (default 0.1). |
| `species` | `NULL` | 物种预设 flatfish、tuna、krill；? 列出预设。 | Character or NULL. Species preset name, one of "flatfish", "tuna", "krill", or "?" to list presets. NULL (default) uses generic defaults equivalent to flatfish. |
| `growth_step` | `NULL` | 每个时间步包含的年数；季度为 0.25。 | Time step in years; defaults to the species preset. |
| `burn_in` | `NULL` | 模拟预热年数，必须对齐 growth_step 且小于总模拟年数。 | Burn-in duration in years; must be a whole number of model steps and less than the simulation duration. |
| `observation_error` | `c("independent", "shared_time")` | independent：各单元独立；shared_time：同一期共享误差。 | Independent lognormal errors per length and time cell, or shared_time for an explicitly misspecified, perfectly correlated scenario. |

**返回 / Returns:** 包含物种、年龄/时间/体长网格、生长、死亡率、补充、观测和过程设置的命名参数列表。

A named parameter list with species, age/time/length grids, growth, mortality, recruitment, observation and process settings.

快速年度模拟器的 `mean_F` 等于生成 F 序列的算术平均值；`mean_F = 0` 生成零捕捞死亡率。

完整模拟器的 `nyear`、`burn_in` 都以年为单位，且分别必须对应整数个 `growth_step`。因此季度模式允许半年预热，年度模式不允许。返回的 `sm$nyear` 是保留时间步数；`first.year` 是第一期保留观测的年份，`sm$years` 保存完整观测时间轴。`simulation_to_tables()` 和 `sim_acl()` 保留这条时间轴；完全没有年份元数据的旧文件仍可使用从 2000 开始的后备规则。只保留一期时仍返回矩阵，但拟合至少需要两期。

`sim_acl()` 在发送 socket 任务前求值路径与参数变量，因此一般控制台或脚本中的变量传参也支持多核。保留失败重复并检查逐次拟合诊断；工作进程运行成功并不单独证明评估结果可用。

In the quick annual simulator, `mean_F` is the arithmetic mean of the generated F trajectory; `mean_F = 0` generates zero F.

For the full simulator, `nyear` and `burn_in` are durations in years and must each contain a whole number of `growth_step` intervals. Thus a half-year burn-in is valid with quarterly steps, but not annual steps. Returned `sm$nyear` counts retained steps. `first.year` labels the first retained observation, and `sm$years` records the complete retained calendar. `simulation_to_tables()` and `sim_acl()` preserve this calendar; old files lacking year metadata still have a documented 2000-based fallback. A single retained period stays a matrix, although fitting requires at least two periods.

`sim_acl()` resolves path and parameter variables before sending tasks to socket workers, so ordinary console/script calls work with multiple cores. Retain failed replicates and inspect each fit's diagnostics; successful worker execution alone does not establish a usable assessment.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
pa <- initialize_params(species = "flatfish", nyear = 100, burn_in = 80)
```

表中 NULL 表示从物种预设取值，英文括号中的数值是通用/flatfish 基线，并非所有物种的默认值。查看 `str(initialize_params(species="tuna"))` 得到完整季度预设。 / NULL inherits the selected preset; numeric defaults mentioned in help describe the generic/flatfish baseline.


完整模拟器的 `F_mean` 是每模型时间步的乘法基准水平：`F_t = F_mean * exp(u_t)`。`F_sd` 是对数 F 的 AR(1) 过程 `u_t` 的创新标准差，平稳标准差为 `F_sd / sqrt(1 - F_ar^2)`；因此 `F_mean` 不是所生成 F 序列的算术平均值。另一个快速模拟器的 `mean_F` 才表示其生成序列的算术平均值。

In the full simulator, `F_mean` is a multiplicative baseline per model step: `F_t = F_mean * exp(u_t)`. `F_sd` is the innovation SD of the AR(1) process `u_t` on the log-F scale; its stationary SD is `F_sd / sqrt(1 - F_ar^2)`. Thus `F_mean` is not the arithmetic mean of a realized F trajectory. The separate quick simulator uses `mean_F` for its realized arithmetic mean.

<a id="mat_func"></a>
## `mat_func()`

计算 logistic 成熟比例 / Calculate logistic maturity

```r
mat_func (L50, L95, length)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `L50` | `必填 / required` | 成熟比例为 0.5 的体长。 | Length at which 50% of individuals are mature. |
| `L95` | `必填 / required` | 比例为 0.95 的体长，必须不同于 L50；下降选择性可小于 L50。 | Length at which 95% of individuals are mature. |
| `length` | `必填 / required` | 计算成熟比例的体长向量。 | Length of the fish. |

**返回 / Returns:** 所给体长对应的比例数值向量。

A numeric vector of proportions at the supplied lengths.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
mat_func(L50 = 35, L95 = 40, length = seq(6, 50, 2))
```

<a id="plot_abundance"></a>
## `plot_abundance()`

丰度 N / Abundance N

所有模式继承全局标题（N, NA_, NL；区间使用对应的 `_se` 键，年龄丰度为 `NA_se`）、`xlab$year`、`ylab$abundance`、`x_breaks` 与 `x_expand`。调用中给出的 `title`、`xlab`、`ylab`、字体和线条参数优先，默认无网格。

All modes inherit global titles (N, NA_, NL; interval variants use the corresponding `_se` keys, with `NA_se` for abundance at age), `xlab$year`, `ylab$abundance`, `x_breaks` and `x_expand`. A `title`, `xlab`, `ylab`, typography or line argument given in the call takes priority. Default panels have no gridlines.

矩阵行列名称不作为下标；年份及体长标签来自拟合元数据。标准误必须完整、有限且非负。 Matrix dimnames are not indices; time and length labels come from fitted metadata. Standard errors must be complete, finite and nonnegative.

```r
plot_abundance (model_result, line_size = NULL, line_color = NULL, line_type = "solid",
    se = FALSE, se_color = NULL, se_alpha = NULL, type = c("N", "NA", "NL"), facet_ncol = NULL,
    facet_scales = "free", return_data = FALSE, title = NULL, xlab = NULL, ylab = NULL,
    font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL,
    strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL,
    title_hjust = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model_result` | `必填 / required` | 单次模型拟合结果。 | A list from run_acl or run_alscl. |
| `line_size` | `NULL` | NULL 继承全局 line_size，显式值优先。 | NULL inherits global line_size; explicit values take priority. |
| `line_color` | `NULL` | 单模型线条颜色。 | Character or NULL. NULL inherits the global line_color setting. |
| `line_type` | `"solid"` | 线型，如 solid、dashed。 | Character. Line type. Default is "solid". |
| `se` | `FALSE` | 是否绘制可用标准误对应的近似区间。 | Logical. Whether to plot confidence intervals. Default is FALSE. |
| `se_color` | `NULL` | 区间阴影或误差棒的颜色。 | Character or NULL. NULL inherits the global se_color setting. |
| `se_alpha` | `NULL` | NULL 继承全局 se_alpha，显式值优先。 | NULL inherits global se_alpha; explicit values take priority. |
| `type` | `c("N", "NA", "NL")` | N 为总尾数，NA 为年龄别尾数，NL 为体长别尾数。 | Character. "N" (total), "NA" (at age), or "NL" (at length). Default is "N". |
| `facet_ncol` | `NULL` | 分面排列的列数。 | Number of columns in facet wrap. Default is NULL. |
| `facet_scales` | `"free"` | fixed、free、free_x 或 free_y；自由尺度有助观察组内变化。 | Scales for facet wrap. Default is "free". |
| `return_data` | `FALSE` | TRUE 同时返回绘图对象及整理后的数据；结构见返回说明。 | Logical. Whether to return processed data. Default is FALSE. |
| `title` | `NULL` | 自定义图标题；NULL 继承主题。 | Character or NULL. Custom plot title. If NULL, uses global theme setting. See acl_theme_set(). |
| `xlab` | `NULL` | 自定义横轴标签；NULL 继承主题。 | Character or NULL. Custom x-axis label. If NULL, uses global theme setting. |
| `ylab` | `NULL` | 自定义纵轴标签；NULL 继承主题。 | Character or NULL. Custom y-axis label. If NULL, uses global theme setting. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character or NULL. Custom font family. If NULL, uses global theme setting (default "sans"). |
| `title_size` | `NULL` | 图标题字号。 | Numeric or NULL. Plot title size in pt. If NULL, uses global theme (default 14). |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12). |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10). |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10). |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10). |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector or NULL. Custom x-axis breaks (e.g. seq(1, 20, by = 2)). NULL = auto. |
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character or NULL. Base ggplot2 theme name (e.g. "theme_bw"). NULL = global setting. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting. |

**返回 / Returns:** ggplot 对象；`return_data=TRUE` 时返回含 `plot` 和整理后的 `data` 的列表。

A ggplot object; with `return_data=TRUE`, a list with `plot` and the processed `data`.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_abundance(b, type = "N", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

![示例图 / Example figure: `plot_abundance(b, type = "N", se = TRUE, facet_ncol = 3, line_size = 0.6)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_abundance_N.png?raw=true&v=028b3b37517a)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_abundance)。

<a id="plot_biomass"></a>
## `plot_biomass()`

生物量 B / Biomass B

所有模式继承全局标题（B, BL, BA；区间使用对应的 `_se` 键，年龄丰度为 `NA_se`）、`xlab$year`、`ylab$biomass`、`x_breaks` 与 `x_expand`。调用中给出的 `title`、`xlab`、`ylab`、字体和线条参数优先，默认无网格。

All modes inherit global titles (B, BL, BA; interval variants use the corresponding `_se` keys, with `NA_se` for abundance at age), `xlab$year`, `ylab$biomass`, `x_breaks` and `x_expand`. A `title`, `xlab`, `ylab`, typography or line argument given in the call takes priority. Default panels have no gridlines.

捕捞死亡率图按矩阵位置和拟合年份、组别元数据构造坐标，矩阵行列名不会改变坐标。生物量、SSB、捕获量和 F 的年龄分面在有无区间时都按数值组序排列。F 图和时间序列比较在 `se = TRUE` 时要求完整、有限的估计与有限非负标准误；缺失摘要会报错，不再重复填充或静默取消区间。只画估计时请明确使用 `se = FALSE`。

Fishing-mortality plots use matrix positions and fitted time/group metadata, so matrix dimnames cannot alter the coordinates. Age panels in biomass, SSB, catch and F plots retain numeric group order with or without intervals. F plots and time-series comparisons require complete finite estimates and nonnegative finite standard errors when `se = TRUE`; missing summaries are errors rather than recycled values or silently removed intervals. Use `se = FALSE` explicitly for estimates only.

```r
plot_biomass (model_result, line_size = NULL, line_color = NULL, line_type = "solid",
    se = FALSE, se_color = NULL, se_alpha = NULL, type = c("B", "BL", "BA"), facet_ncol = NULL,
    facet_scales = "free", return_data = FALSE, title = NULL, xlab = NULL, ylab = NULL,
    font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL,
    strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL,
    title_hjust = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model_result` | `必填 / required` | 单次模型拟合结果。 | A list from run_acl or run_alscl. |
| `line_size` | `NULL` | NULL 继承全局 line_size，显式值优先。 | NULL inherits global line_size; explicit values take priority. |
| `line_color` | `NULL` | 单模型线条颜色。 | Character or NULL. NULL inherits the global line_color setting. |
| `line_type` | `"solid"` | 线型，如 solid、dashed。 | Character. Line type. Default is "solid". |
| `se` | `FALSE` | 是否绘制可用标准误对应的近似区间。 | Logical. Whether to plot confidence intervals. Default is FALSE. |
| `se_color` | `NULL` | 区间阴影或误差棒的颜色。 | Character or NULL. NULL inherits the global se_color setting. |
| `se_alpha` | `NULL` | NULL 继承全局 se_alpha，显式值优先。 | NULL inherits global se_alpha; explicit values take priority. |
| `type` | `c("B", "BL", "BA")` | B 为总生物量，BA 为年龄别生物量，BL 为体长别生物量。 | Character. "B" (total), "BL" (at length), or "BA" (at age). Default is "B". |
| `facet_ncol` | `NULL` | 分面排列的列数。 | Integer. Columns in facet_wrap. Default is NULL. |
| `facet_scales` | `"free"` | fixed、free、free_x 或 free_y；自由尺度有助观察组内变化。 | Character. Scales for facet_wrap. Default is "free". |
| `return_data` | `FALSE` | TRUE 同时返回绘图对象及整理后的数据；结构见返回说明。 | Logical. Whether to return processed data. Default is FALSE. |
| `title` | `NULL` | 自定义图标题；NULL 继承主题。 | Character or NULL. Custom plot title. If NULL, uses global theme setting. See acl_theme_set(). |
| `xlab` | `NULL` | 自定义横轴标签；NULL 继承主题。 | Character or NULL. Custom x-axis label. If NULL, uses global theme setting. |
| `ylab` | `NULL` | 自定义纵轴标签；NULL 继承主题。 | Character or NULL. Custom y-axis label. If NULL, uses global theme setting. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character or NULL. Custom font family. If NULL, uses global theme setting (default "sans"). |
| `title_size` | `NULL` | 图标题字号。 | Numeric or NULL. Plot title size in pt. If NULL, uses global theme (default 14). |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12). |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10). |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10). |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10). |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector or NULL. Custom x-axis breaks (e.g. seq(1, 20, by = 2)). NULL = auto. |
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character or NULL. Base ggplot2 theme name (e.g. "theme_bw"). NULL = global setting. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting. |

**返回 / Returns:** ggplot 对象；`return_data=TRUE` 时返回含 `plot` 和整理后的 `data` 的列表。

A ggplot object; with `return_data=TRUE`, a list with `plot` and the processed `data`.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_biomass(b, type = "B", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

![示例图 / Example figure: `plot_biomass(b, type = "B", se = TRUE, facet_ncol = 3, line_size = 0.6)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_biomass_B.png?raw=true&v=3d2df45029c9)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_biomass)。

<a id="plot_catch"></a>
## `plot_catch()`

捕获尾数 CN / Catch numbers CN

所有模式继承全局标题（CN, CNA, CNL；区间使用对应的 `_se` 键，年龄丰度为 `NA_se`）、`xlab$year`、`ylab$catch`、`x_breaks` 与 `x_expand`。调用中给出的 `title`、`xlab`、`ylab`、字体和线条参数优先，默认无网格。

All modes inherit global titles (CN, CNA, CNL; interval variants use the corresponding `_se` keys, with `NA_se` for abundance at age), `xlab$year`, `ylab$catch`, `x_breaks` and `x_expand`. A `title`, `xlab`, `ylab`, typography or line argument given in the call takes priority. Default panels have no gridlines.

捕捞死亡率图按矩阵位置和拟合年份、组别元数据构造坐标，矩阵行列名不会改变坐标。生物量、SSB、捕获量和 F 的年龄分面在有无区间时都按数值组序排列。F 图和时间序列比较在 `se = TRUE` 时要求完整、有限的估计与有限非负标准误；缺失摘要会报错，不再重复填充或静默取消区间。只画估计时请明确使用 `se = FALSE`。

Fishing-mortality plots use matrix positions and fitted time/group metadata, so matrix dimnames cannot alter the coordinates. Age panels in biomass, SSB, catch and F plots retain numeric group order with or without intervals. F plots and time-series comparisons require complete finite estimates and nonnegative finite standard errors when `se = TRUE`; missing summaries are errors rather than recycled values or silently removed intervals. Use `se = FALSE` explicitly for estimates only.

```r
plot_catch (model_result, line_size = NULL, line_color = NULL, line_type = "solid",
    se = FALSE, se_color = NULL, se_alpha = NULL, facet_ncol = NULL, facet_scales = "free",
    type = c("CN", "CNA", "CNL"), return_data = FALSE, title = NULL, xlab = NULL,
    ylab = NULL, font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL,
    strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL,
    title_hjust = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model_result` | `必填 / required` | 单次模型拟合结果。 | A list from run_acl or run_alscl. |
| `line_size` | `NULL` | NULL 继承全局 line_size，显式值优先。 | NULL inherits global line_size; explicit values take priority. |
| `line_color` | `NULL` | 单模型线条颜色。 | Character or NULL. NULL inherits the global line_color setting. |
| `line_type` | `"solid"` | 线型，如 solid、dashed。 | Character. Line type. Default is "solid". |
| `se` | `FALSE` | 是否绘制可用标准误对应的近似区间。 | Logical. Whether to plot confidence intervals. Default is FALSE. |
| `se_color` | `NULL` | 区间阴影或误差棒的颜色。 | Character or NULL. NULL inherits the global se_color setting. |
| `se_alpha` | `NULL` | NULL 继承全局 se_alpha，显式值优先。 | NULL inherits global se_alpha; explicit values take priority. |
| `facet_ncol` | `NULL` | 分面排列的列数。 | Numeric. Columns in facet wrap. Default is NULL. |
| `facet_scales` | `"free"` | fixed、free、free_x 或 free_y；自由尺度有助观察组内变化。 | Character. Scales for facet wrap. Default is "free". |
| `type` | `c("CN", "CNA", "CNL")` | CN 为总捕捞尾数，CNA 为年龄别捕捞尾数，CNL 为体长别捕捞尾数。 | Character. "CN" (total), "CNA" (at age), or "CNL" (at length). Default is "CN". |
| `return_data` | `FALSE` | TRUE 同时返回绘图对象及整理后的数据；结构见返回说明。 | Logical. Whether to return processed data. Default is FALSE. |
| `title` | `NULL` | 自定义图标题；NULL 继承主题。 | Character or NULL. Custom plot title. If NULL, uses global theme setting. See acl_theme_set(). |
| `xlab` | `NULL` | 自定义横轴标签；NULL 继承主题。 | Character or NULL. Custom x-axis label. If NULL, uses global theme setting. |
| `ylab` | `NULL` | 自定义纵轴标签；NULL 继承主题。 | Character or NULL. Custom y-axis label. If NULL, uses global theme setting. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character or NULL. Custom font family. If NULL, uses global theme setting (default "sans"). |
| `title_size` | `NULL` | 图标题字号。 | Numeric or NULL. Plot title size in pt. If NULL, uses global theme (default 14). |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12). |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10). |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10). |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10). |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector or NULL. Custom x-axis breaks (e.g. seq(1, 20, by = 2)). NULL = auto. |
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character or NULL. Base ggplot2 theme name (e.g. "theme_bw"). NULL = global setting. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting. |

**返回 / Returns:** ggplot 对象；`return_data=TRUE` 时返回含 `plot` 和整理后的 `data` 的列表。

A ggplot object; with `return_data=TRUE`, a list with `plot` and the processed `data`.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_catch(b, type = "CN", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

![示例图 / Example figure: `plot_catch(b, type = "CN", se = TRUE, facet_ncol = 3, line_size = 0.6)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_catch_CN.png?raw=true&v=c03ee7bf1c85)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_catch)。

<a id="plot_CatL"></a>
## `plot_CatL()`

调查拟合 length 对数尺度 / Survey fit length log scale

标题明确标为调查指数。`facet_by = "year"` 使用 `line_size1` 设置拟合线、`line_size2` 设置观测线；`line_size` 与 `point_size` 仅用于 `facet_by = "length"`。按年份分面时也遵守全局 `CatL_by_year` 标题。

Titles identify survey indices. In `facet_by = "year"`, use `line_size1` for fitted lines and `line_size2` for observed lines; `line_size` and `point_size` control only `facet_by = "length"`. The global `CatL_by_year` title now applies to year facets.

默认 `plot_CatL(exp_transform = FALSE)` 绘制自然对数调查指数，并在纵轴标明尺度；`exp_transform = TRUE` 绘制原尺度调查指数，预测曲线为中位数。显式 `ylab` 覆盖自动标签。山脊图在对数尺度稳定归一化，极大或极小的有限对数预测仍可绘制；非有限预测会报错。

The default `plot_CatL(exp_transform = FALSE)` displays natural-log survey indices and labels that scale explicitly. `exp_transform = TRUE` displays original-scale survey indices; curves are fitted medians. An explicit `ylab` overrides the automatic label. Ridge compositions are normalized stably on the log scale, including very large or small finite log predictions; nonfinite predictions are rejected.

调查拟合图按矩阵位置及拟合年份、体长元数据对齐观测与预测，增删行列名不会改变坐标；缺失及零观测继续排除。若预测取指数会溢出，请使用 `exp_transform = FALSE`。残差图的 `resid_cap` 必须为有限正标量，或以 `NULL` 关闭截断；不再允许负值或零值抹去诊断特征。

Survey fit plots align both observed and predicted matrices by their positions and fitted calendar/length metadata, even if dimnames are added or removed. Missing and zero observations stay excluded. Use `exp_transform = FALSE` if exponentiating predictions would overflow. In residual plots, `resid_cap` must be a finite positive scalar or `NULL` to disable capping; negative or zero caps cannot erase the diagnostic pattern.

```r
plot_CatL (model_result, point_size = NULL, point_color = NULL, point_shape = 16,
    line_size = NULL, line_color = NULL, line_type = "solid", line_size1 = NULL,
    line_color1 = NULL, line_type1 = "solid", line_alpha1 = 1, line_size2 = NULL,
    line_color2 = NULL, line_type2 = "solid", line_alpha2 = 0.6, facet_ncol = NULL,
    facet_scales = "free", facet_by = c("length", "year"), exp_transform = FALSE,
    return_data = FALSE, title = NULL, xlab = NULL, ylab = NULL, font_family = NULL,
    title_size = NULL, axis_title_size = NULL, axis_text_size = NULL, strip_text_size = NULL,
    legend_text_size = NULL, x_breaks = NULL, base_theme = NULL, title_hjust = NULL,
    ...)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model_result` | `必填 / required` | 单次模型拟合结果。 | A list that contains the model output. The list should have a "report" component which contains an "Elog_index" component representing counts in length groups. |
| `point_size` | `NULL` | 点大小；NULL 继承全局 point_size（默认 2.5）。 | Numeric or NULL. NULL inherits the global point_size setting (default 2.5). |
| `point_color` | `NULL` | 点颜色。 | Character or NULL. NULL inherits the global observed_color setting. |
| `point_shape` | `16` | 点形状编号，如 16、21。 | Numeric. Specifies the shape of the point in the plot. Default is 16 (filled circle). Common: 1=open circle, 16=filled circle, 17=triangle, 15=square. |
| `line_size` | `NULL` | NULL 继承全局 line_size，显式值优先。 | NULL inherits global line_size; explicit values take priority. |
| `line_color` | `NULL` | 单模型线条颜色。 | Character or NULL. NULL inherits the global line_color setting. |
| `line_type` | `"solid"` | 线型，如 solid、dashed。 | Character. Line type for type="length" plot. Default is "solid". |
| `line_size1` | `NULL` | NULL 使用全局 line_size 的 1.2 倍。 | NULL uses 1.2 times global line_size. |
| `line_color1` | `NULL` | 拟合曲线颜色；NULL 继承全局 line_color。 | Character or NULL. NULL inherits the global line_color setting. |
| `line_type1` | `"solid"` | 拟合曲线线型。 | Character. Line type for estimated line. Default is "solid". |
| `line_alpha1` | `1` | 拟合曲线透明度（0–1）。 | Numeric. Transparency for estimated line (0-1). Default is 1. |
| `line_size2` | `NULL` | NULL 使用全局 line_size 的 2/3 倍。 | NULL uses 2/3 times global line_size. |
| `line_color2` | `NULL` | 观测曲线颜色；NULL 继承全局 observed_color。 | Character or NULL. NULL inherits the global observed_color setting. |
| `line_type2` | `"solid"` | 观测曲线线型。 | Character. Line type for observed line. Default is "solid". |
| `line_alpha2` | `0.6` | 观测曲线透明度（0–1）。 | Numeric. Transparency for observed line (0-1). Default is 0.6. |
| `facet_ncol` | `NULL` | 分面排列的列数。 | Integer. Specifies the number of columns in the facet_wrap. Default is NULL. |
| `facet_scales` | `"free"` | fixed、free、free_x 或 free_y；自由尺度有助观察组内变化。 | Character. Specifies scales for facet_wrap. Default is "free". |
| `facet_by` | `c("length", "year")` | 布局："length" 每个体长组一个面板、横轴为时间；"year" 每个时间步一个面板、横轴为体长。 | "length" (default) draws one panel per length bin with time on the x axis; "year" draws one panel per time step with length on the x axis. |
| `exp_transform` | `FALSE` | 对数调查值取指数，显示原尺度；拟合曲线是中位数。 | Logical. Specifies whether to apply the exponential function to the data before plotting. If TRUE, the exponential of the data values is plotted. Default is FALSE. |
| `return_data` | `FALSE` | TRUE 同时返回绘图对象及整理后的数据；结构见返回说明。 | A logical indicating whether to return the processed data alongside the plot. Default is FALSE. |
| `title` | `NULL` | 自定义图标题；NULL 继承默认。 | Character or NULL. Custom plot title. If NULL, uses global theme setting. See acl_theme_set(). |
| `xlab` | `NULL` | 自定义横轴标签；NULL 继承主题。 | Character or NULL. Custom x-axis label. If NULL, uses global theme setting. |
| `ylab` | `NULL` | 自定义纵轴标签；NULL 继承主题。 | Character or NULL. Custom y-axis label. If NULL, uses global theme setting. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character or NULL. Custom font family. If NULL, uses global theme setting (default "sans"). |
| `title_size` | `NULL` | 图标题字号。 | Numeric or NULL. Plot title size in pt. If NULL, uses global theme (default 14). |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12). |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10). |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10). |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10). |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector or NULL. Custom x-axis breaks (e.g. seq(1, 20, by = 2)). NULL = auto. |
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character or NULL. Base ggplot2 theme name (e.g. "theme_bw"). NULL = global setting. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting. |
| `...` | 可选 / optional | 旧参数名 type，仍可使用但会给出警告。 | The former argument name type, accepted with a warning. |

**返回 / Returns:** ggplot 对象；`return_data=TRUE` 时返回含 `plot`、`data1`（拟合）、`data2`（观测）的列表。

A ggplot object; with `return_data=TRUE`, a list with `plot`, `data1` (fitted) and `data2` (observed).

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_CatL(b, facet_by = "length", exp_transform = FALSE, facet_ncol = 4,
  point_size = 1, line_size = 0.6,
  x_breaks = c(2000, 2010, 2015),
  ylab = "Log survey index")
```

![示例图 / Example figure: `plot_CatL(b, facet_by = "year", facet_ncol = 4)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/CatL_year_FALSE.png?raw=true&v=27b8dc9d9c6c)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_CatL)。

<a id="plot_compare_annual_F"></a>
## `plot_compare_annual_F()`

已弃用：请改用 plot_compare_F_ts() / Deprecated: use plot_compare_F_ts()

```r
plot_compare_annual_F (...)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `...` | 可选 / optional | 传给 plot_compare_F_ts() 的参数。 | Arguments passed to plot_compare_F_ts(). |

**返回 / Returns:** ggplot 对象。

A ggplot object.

本函数按模型时间步汇总 F，从未把季度值年化，因此更名为 `plot_compare_F_ts()`。旧名每个会话警告一次，以后的版本将删除。

The function summarizes F per model time step and never annualized quarterly values, so it is now called `plot_compare_F_ts()`. The former name warns once per session and will be removed in a later release.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_compare_F_ts(a, b, method = "apical")
```

<a id="plot_compare_CatL"></a>
## `plot_compare_CatL()`

两模型调查拟合 / Survey fits from both models

```r
plot_compare_CatL (model1, model2, data.CatL, years = NULL, model1_name = NULL, model2_name = NULL,
    colors = NULL, linetypes = NULL, line_size = NULL, facet_ncol = 4, facet_scales = "free_y",
    obs_color = "grey40", obs_size = NULL, obs_alpha = 0.6, obs_shape = 16, legend_pos = NULL,
    ..., point_size = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model1` | `必填 / required` | 第一个拟合对象。 | First model result (reference). |
| `model2` | `必填 / required` | 第二个拟合对象。 | Second model result (alternative). |
| `data.CatL` | `必填 / required` | 调查数量指数表：首列体长标签，其余列为时间。 | Original survey numbers-at-length or index data frame. |
| `years` | `NULL` | 年份向量；快速模拟器要求连续年度，比较图用它筛选时期。 | Numeric vector of years to show. Default NULL = all years. Use e.g. years = seq(1991, 2011, by = 2) to select specific years. |
| `model1_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `model2_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `colors` | `NULL` | 按两个模型顺序提供两种颜色；名称可选。 | Named character vector of 2 colors. NULL = use global theme. |
| `linetypes` | `NULL` | 按模型顺序提供两种线型。 | Named character vector of 2 linetypes. NULL = use global theme. |
| `line_size` | `NULL` | 线宽；参数名按函数区别使用。 | Numeric. NULL = use global theme. |
| `facet_ncol` | `4` | 分面排列的列数。 | Integer. Facet columns. Default 4. |
| `facet_scales` | `"free_y"` | fixed、free、free_x 或 free_y；自由尺度有助观察组内变化。 | Character. Facet facet_scales. Default "free_y". |
| `obs_color` | `"grey40"` | 观测点颜色。 | Character. Color for observed points. Default "grey40". |
| `obs_size` | `NULL` | 旧的观测点大小设置；NULL 继承主题。显式 point_size 优先于此值。 | Legacy observed-point size; NULL inherits the theme. An explicit point_size takes priority. |
| `obs_alpha` | `0.6` | 观测点透明度。 | Numeric. Transparency of observed points. Default 0.6. |
| `obs_shape` | `16` | 观测点形状。 | Integer. Shape of observed points. Default 16. |
| `legend_pos` | `NULL` | 图例位置，如 bottom、right、none。 | Character. Legend position. NULL = use global theme. |
| `...` | 可选 / optional | 旧参数名 linewidth、ncol、scales，仍可使用但会给出警告。 | The former argument names linewidth, ncol and scales, accepted with a warning. |
| `point_size` | `NULL` | 点大小；NULL 先使用显式 obs_size，再继承比较图覆盖值或全局 point_size（默认 2.5）。显式值优先。 | Point size; NULL uses an explicit obs_size first, then a comparison override or global point_size (default 2.5). A supplied value takes priority. |

**返回 / Returns:** ggplot 对象，可继续调整样式或用 `ggplot2::ggsave()` 保存。

A ggplot object, suitable for further styling or `ggplot2::ggsave()`.

同一模型的两份结果会自动使用不同图例，例如 `ACL (group_year)` 和 `ACL (year)`，仍支持显式指定不同的 `model1_name`、`model2_name`。时间序列与 F 图保留每份结果自己的真实年份，可以显示不同时间范围。与 `data.CatL` 配对的图会核对已知时间和体长元数据，再匹配观测与预测；网格不一致时明确报错。图形比较不代表似然或生物假设具有可比性。

Comparison plots give distinct default labels to two fits of the same model: for example, `ACL (group_year)` and `ACL (year)`. Explicit distinct `model1_name` and `model2_name` remain supported. Time-series and F plots retain each fit's own calendar, including different time spans. Plots paired with `data.CatL` check known time and length metadata before matching observations to predictions; inconsistent grids are errors. A visual comparison does not establish that likelihoods or biological assumptions are comparable.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_compare_CatL(a, b, dat, years = c(2000, 2005, 2010, 2015), facet_ncol = 2)
```

![示例图 / Example figure: `plot_compare_CatL(a, b, dat, years = c(2000, 2005, 2010, 2015), facet_ncol = 2)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_CatL.png?raw=true&v=06278fecb8b7)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_compare_CatL)。

<a id="plot_compare_F"></a>
## `plot_compare_F()`

死亡率矩阵比较 / Fishing mortality matrices

```r
plot_compare_F (model1, model2, model1_name = NULL, model2_name = NULL, palette = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model1` | `必填 / required` | 第一个拟合对象。 | First model result (reference). |
| `model2` | `必填 / required` | 第二个拟合对象。 | Second model result (alternative). |
| `model1_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `model2_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `palette` | `NULL` | ggsci 色板名；NULL 继承全局设置，部分图也保留旧色板。 | Character or NULL. NULL uses the global sequential colors; a ggsci palette name or a viridis option overrides them. |

**返回 / Returns:** ggplot 对象，可继续调整样式或用 `ggplot2::ggsave()` 保存。

A ggplot object, suitable for further styling or `ggplot2::ggsave()`.

同一模型的两份结果会自动使用不同图例，例如 `ACL (group_year)` 和 `ACL (year)`，仍支持显式指定不同的 `model1_name`、`model2_name`。时间序列与 F 图保留每份结果自己的真实年份，可以显示不同时间范围。与 `data.CatL` 配对的图会核对已知时间和体长元数据，再匹配观测与预测；网格不一致时明确报错。图形比较不代表似然或生物假设具有可比性。

Comparison plots give distinct default labels to two fits of the same model: for example, `ACL (group_year)` and `ACL (year)`. Explicit distinct `model1_name` and `model2_name` remain supported. Time-series and F plots retain each fit's own calendar, including different time spans. Plots paired with `data.CatL` check known time and length metadata before matching observations to predictions; inconsistent grids are errors. A visual comparison does not establish that likelihoods or biological assumptions are comparable.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_compare_F(a, b) + scale_x_continuous(breaks = c(2000, 2010, 2019))
```

![示例图 / Example figure: `plot_compare_F(a, b)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_F.png?raw=true&v=416cab4229d5)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_compare_F)。

<a id="plot_compare_F_ts"></a>
## `plot_compare_F_ts()`

各时间步 F 比较 / Fishing mortality by time step

```r
plot_compare_F_ts (model1, model2, model1_name = NULL, model2_name = NULL, method = c("apical",
    "mean"), colors = NULL, linetypes = NULL, line_size = NULL, ..., point_size = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model1` | `必填 / required` | 第一个拟合对象。 | First model result (reference). |
| `model2` | `必填 / required` | 第二个拟合对象。 | Second model result (alternative). |
| `model1_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `model2_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `method` | `c("apical", "mean")` | apical 取组间最大 F；mean 取非加权均值，不自动年化。 | Character. How to summarize F across age/length groups each model time step; quarterly fits are not aggregated to years. "apical" (default): maximum F across groups -- comparable across age-based and length-based models. "mean": arithmetic mean across all groups -- can be misleading when models differ in dimension (e.g. 20 ages vs 22 length bins with many near-zero). |
| `colors` | `NULL` | 按两个模型顺序提供两种颜色；名称可选。 | Named character vector of 2 colors. NULL = use global theme. |
| `linetypes` | `NULL` | 按模型顺序提供两种线型。 | Named character vector of 2 linetypes. NULL = use global theme. |
| `line_size` | `NULL` | 线宽；参数名按函数区别使用。 | Numeric. NULL = use global theme. |
| `...` | 可选 / optional | 旧参数名 linewidth，仍可使用但会给出警告。 | The former argument name linewidth, accepted with a warning. |
| `point_size` | `NULL` | 点大小；NULL 优先继承比较图覆盖值，否则继承全局 point_size（默认 2.5）。显式值优先。 | Point size; NULL inherits an explicit comparison override or global point_size (default 2.5). A supplied value takes priority. |

**返回 / Returns:** ggplot 对象，可继续调整样式或用 `ggplot2::ggsave()` 保存。

A ggplot object, suitable for further styling or `ggplot2::ggsave()`.

同一模型的两份结果会自动使用不同图例，例如 `ACL (group_year)` 和 `ACL (year)`，仍支持显式指定不同的 `model1_name`、`model2_name`。时间序列与 F 图保留每份结果自己的真实年份，可以显示不同时间范围。与 `data.CatL` 配对的图会核对已知时间和体长元数据，再匹配观测与预测；网格不一致时明确报错。图形比较不代表似然或生物假设具有可比性。

Comparison plots give distinct default labels to two fits of the same model: for example, `ACL (group_year)` and `ACL (year)`. Explicit distinct `model1_name` and `model2_name` remain supported. Time-series and F plots retain each fit's own calendar, including different time spans. Plots paired with `data.CatL` check known time and length metadata before matching observations to predictions; inconsistent grids are errors. A visual comparison does not establish that likelihoods or biological assumptions are comparable.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_compare_F_ts(a, b, method = "apical") +
  labs(title = "Apical fishing mortality")
```

![示例图 / Example figure: `plot_compare_F_ts(a, b, method = "apical")`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_F_apical.png?raw=true&v=04d0e9ec5dd1)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_compare_F_ts)。

<a id="plot_compare_growth"></a>
## `plot_compare_growth()`

生长与外部参照接口 / Growth and reference-data interface

可选参考曲线仅在不早于其自身拟合 `t0` 的年龄绘制。若其生长参数无效，或没有剩余的正年龄跨度，会警告说明省略参考曲线的原因；评估模型曲线和观测点仍保留。

The optional reference curve is drawn only at ages at or above its own fitted `t0`. If its fitted growth parameters are invalid or no positive age span remains, a warning explains why the reference curve is omitted; the assessment curves and observed points remain.

省略 `age_range` 时，采用两份拟合年龄的合并范围，起点不早于两个模型的 `t0`。缺少年龄信息的旧结果使用 1-20 岁范围。显式范围须为两个有限且递增的年龄，起点不早于两个 `t0`；没有正跨度的范围会报错。

Omit `age_range` to use the combined fitted age range, starting at or after both models' `t0`. A model without saved age metadata contributes the legacy range 1-20 years. An explicit range must contain two finite increasing ages and start at or after both `t0` values. A range with no positive span is rejected.

提供 `ref_data` 时，`ref_name` 必须为非空字符串，且与两个模型标签均不同；重复名称会在拟合参考曲线前报错。

When supplying `ref_data`, use a nonempty `ref_name` distinct from both model labels; duplicate names are rejected before fitting the reference curve.

```r
plot_compare_growth (model1, model2, age_range = NULL, model1_name = NULL, model2_name = NULL,
    colors = NULL, linetypes = NULL, line_size = NULL, ref_data = NULL, ref_name = "Observed VB",
    ref_color = "grey30", ref_linetype = "dotdash", show_points = TRUE, point_size = NULL,
    point_alpha = 0.4, nls_start = NULL, ...)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model1` | `必填 / required` | 第一个拟合对象。 | First model result (reference). |
| `model2` | `必填 / required` | 第二个拟合对象。 | Second model result (alternative). |
| `age_range` | `NULL` | 两份拟合的合并年龄范围，自动起点不早于两个 t0；旧结果回退到 1-20 岁。显式值须为有限递增的二元向量，起点不早于两个 t0。 | Combined fitted ages, starting at or after both t0 values; legacy fallback 1-20. An explicit finite increasing pair must start at or after both t0 values. |
| `model1_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `model2_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `colors` | `NULL` | 按两个模型顺序提供两种颜色；名称可选。 | Named character vector of 2 colors. NULL = use global theme. |
| `linetypes` | `NULL` | 按模型顺序提供两种线型。 | Named character vector of 2 linetypes. NULL = use global theme. |
| `line_size` | `NULL` | 线宽；参数名按函数区别使用。 | Numeric. NULL = use global theme. |
| `ref_data` | `NULL` | 可选 Age、Length 列的参考个体生长数据。 | Optional data.frame with columns Age and Length containing observed age-length measurements (e.g. from otolith readings). If provided, a VB curve is fitted via nls() and overlaid as a reference, with the raw data as scatter points. |
| `ref_name` | `"Observed VB"` | 参考曲线名称；提供 ref_data 时必须非空，且不与任一模型标签重复。 | Nonempty reference-curve label distinct from both model labels when ref_data is supplied. |
| `ref_color` | `"grey30"` | 参考曲线颜色。 | Character. Color for reference curve/points. Default "grey30". |
| `ref_linetype` | `"dotdash"` | 参考曲线线型。 | Character. Linetype for reference curve. Default "dotdash". |
| `show_points` | `TRUE` | 是否显示参考数据点。 | Logical. Show raw data points from ref_data. Default TRUE. |
| `point_size` | `NULL` | 点大小；NULL 优先继承比较图覆盖值，否则继承全局 point_size（默认 2.5）。显式值优先。 | Point size; NULL inherits an explicit comparison override or global point_size (default 2.5). A supplied value takes priority. |
| `point_alpha` | `0.4` | 点透明度，0–1。 | Numeric. Transparency of data points. Default 0.4. |
| `nls_start` | `NULL` | 参考数据 VB 非线性回归初值：Linf、k、t0。 | Named list. Starting values for nls. Default attempts auto-detection from data range. |
| `...` | 可选 / optional | 旧参数名 linewidth，仍可使用但会给出警告。 | The former argument name linewidth, accepted with a warning. |

**返回 / Returns:** 可直接显示或用 `ggplot2::ggsave()` 保存的组合图对象。

A plot composition that can be displayed or saved with `ggplot2::ggsave()`.

同一模型的两份结果会自动使用不同图例，例如 `ACL (group_year)` 和 `ACL (year)`，仍支持显式指定不同的 `model1_name`、`model2_name`。时间序列与 F 图保留每份结果自己的真实年份，可以显示不同时间范围。与 `data.CatL` 配对的图会核对已知时间和体长元数据，再匹配观测与预测；网格不一致时明确报错。图形比较不代表似然或生物假设具有可比性。

Comparison plots give distinct default labels to two fits of the same model: for example, `ACL (group_year)` and `ACL (year)`. Explicit distinct `model1_name` and `model2_name` remain supported. Time-series and F plots retain each fit's own calendar, including different time spans. Plots paired with `data.CatL` check known time and length metadata before matching observations to predictions; inconsistent grids are errors. A visual comparison does not establish that likelihoods or biological assumptions are comparable.

**示例 / Example:**

```r
# 本例生成参考数据；a 和 b 来自准备代码 / Generate reference data here; a and b come from the setup
set.seed(42)
ref <- data.frame(Age = rep(1:15, each = 5))
ref$Length <- VB_func(60, 0.2, 1/60, ref$Age) + stats::rnorm(nrow(ref), sd = 2)
plot_compare_growth(a, b, age_range = c(1, 15), ref_data = ref,
    ref_name = "Synthetic reference", nls_start = list(Linf = 60, k = 0.2, t0 = 1/60))
```

![示例图 / Example figure: `plot_compare_growth(a, b, age_range = c(1, 15))`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_growth.png?raw=true&v=bfb640833596)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_compare_growth)。

这里的参考点是本例生成的模拟年龄–体长数据，用于演示参考曲线拟合；请用独立采集的年龄–体长观测替换它们。 / These reference points are synthetic age–length data generated in this example to demonstrate the reference fit; replace them with independently collected age–length observations.

<a id="plot_compare_metrics"></a>
## `plot_compare_metrics()`

拟合指标比较 / Fit metric comparison

```r
plot_compare_metrics (model1, model2, data.CatL, model1_name = NULL, model2_name = NULL, colors = NULL,
    metrics = NULL, facet_ncol = NULL, legend_pos = NULL, label_size = 3.2, bar_width = 0.6,
    bar_alpha = 0.85, ...)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model1` | `必填 / required` | 第一个拟合对象。 | First model result (reference). |
| `model2` | `必填 / required` | 第二个拟合对象。 | Second model result (alternative). |
| `data.CatL` | `必填 / required` | 调查数量指数表：首列体长标签，其余列为时间。 | Original survey numbers-at-length or index data frame. |
| `model1_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `model2_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `colors` | `NULL` | 按两个模型顺序提供两种颜色；名称可选。 | Named character vector of 2 colors. NULL = use global theme. |
| `metrics` | `NULL` | 选择 error、R2、MAPE、IC、npar 面板。 | Character vector selecting which panels to show. Options: "error" (RMSE, MAE), "R2", "MAPE", "IC" (AIC, BIC, NLL), "npar". Default NULL = all five panels. E.g. metrics = c("error", "R2", "IC"). |
| `facet_ncol` | `NULL` | 分面排列的列数。 | Integer. Columns for panel layout. Default: auto. |
| `legend_pos` | `NULL` | 图例位置，如 bottom、right、none。 | Character. Legend position. NULL = use global theme. |
| `label_size` | `3.2` | 柱图数值标签字号。 | Numeric. Text label size on bars. Default 3.2. |
| `bar_width` | `0.6` | 柱子宽度。 | Numeric. Bar width. Default 0.6. |
| `bar_alpha` | `0.85` | 柱子透明度。 | Numeric. Bar transparency. Default 0.85. |
| `...` | 可选 / optional | 旧参数名 ncol，仍可使用但会给出警告。 | The former argument name ncol, accepted with a warning. |

**返回 / Returns:** 可直接显示或用 `ggplot2::ggsave()` 保存的组合图对象。

A plot composition that can be displayed or saved with `ggplot2::ggsave()`.

同一模型的两份结果会自动使用不同图例，例如 `ACL (group_year)` 和 `ACL (year)`，仍支持显式指定不同的 `model1_name`、`model2_name`。时间序列与 F 图保留每份结果自己的真实年份，可以显示不同时间范围。与 `data.CatL` 配对的图会核对已知时间和体长元数据，再匹配观测与预测；网格不一致时明确报错。图形比较不代表似然或生物假设具有可比性。

Comparison plots give distinct default labels to two fits of the same model: for example, `ACL (group_year)` and `ACL (year)`. Explicit distinct `model1_name` and `model2_name` remain supported. Time-series and F plots retain each fit's own calendar, including different time spans. Plots paired with `data.CatL` check known time and length metadata before matching observations to predictions; inconsistent grids are errors. A visual comparison does not establish that likelihoods or biological assumptions are comparable.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_compare_metrics(a, b, dat, facet_ncol = 2) & scale_y_continuous(expand = expansion(mult = c(0,
    0.3)))
```

![示例图 / Example figure: `plot_compare_metrics(a, b, dat, facet_ncol = 2)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_metrics.png?raw=true&v=f429da60dffc)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_compare_metrics)。

<a id="plot_compare_residuals"></a>
## `plot_compare_residuals()`

残差联合诊断 / Combined residual diagnostics

```r
plot_compare_residuals (model1, model2, data.CatL, model1_name = NULL, model2_name = NULL, colors = NULL,
    linetypes = NULL, line_size = NULL, point_size = NULL, legend_pos = NULL, bins = 35,
    qq_alpha = 0.6, errorbar_width = 0.3, ...)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model1` | `必填 / required` | 第一个拟合对象。 | First model result (reference). |
| `model2` | `必填 / required` | 第二个拟合对象。 | Second model result (alternative). |
| `data.CatL` | `必填 / required` | 调查数量指数表：首列体长标签，其余列为时间。 | Original survey numbers-at-length or index data frame. |
| `model1_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `model2_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `colors` | `NULL` | 按两个模型顺序提供两种颜色；名称可选。 | Named character vector of 2 colors. NULL = use global theme. |
| `linetypes` | `NULL` | 按模型顺序提供两种线型。 | Named character vector of 2 linetypes. NULL = use global theme. |
| `line_size` | `NULL` | 线宽；参数名按函数区别使用。 | Numeric. NULL = use global theme. |
| `point_size` | `NULL` | 点大小；NULL 优先继承比较图覆盖值，否则继承全局 point_size（默认 2.5）。显式值优先。 | Point size; NULL inherits an explicit comparison override or global point_size (default 2.5). A supplied value takes priority. |
| `legend_pos` | `NULL` | 图例位置，如 bottom、right、none。 | Character. Legend position. NULL = use global theme (default "bottom"). |
| `bins` | `35` | 残差直方图分箱数量。 | Integer. Histogram bins. Default 35. |
| `qq_alpha` | `0.6` | QQ 图点的透明度。 | Numeric. QQ point transparency. Default 0.6. |
| `errorbar_width` | `0.3` | 年度残差 SD 误差棒端帽宽度。 | Numeric. Error bar cap width. Default 0.3. |
| `...` | 可选 / optional | 旧参数名 linewidth，仍可使用但会给出警告。 | The former argument name linewidth, accepted with a warning. |

**返回 / Returns:** 可直接显示或用 `ggplot2::ggsave()` 保存的组合图对象。

A plot composition that can be displayed or saved with `ggplot2::ggsave()`.

同一模型的两份结果会自动使用不同图例，例如 `ACL (group_year)` 和 `ACL (year)`，仍支持显式指定不同的 `model1_name`、`model2_name`。时间序列与 F 图保留每份结果自己的真实年份，可以显示不同时间范围。与 `data.CatL` 配对的图会核对已知时间和体长元数据，再匹配观测与预测；网格不一致时明确报错。图形比较不代表似然或生物假设具有可比性。

Comparison plots give distinct default labels to two fits of the same model: for example, `ACL (group_year)` and `ACL (year)`. Explicit distinct `model1_name` and `model2_name` remain supported. Time-series and F plots retain each fit's own calendar, including different time spans. Plots paired with `data.CatL` check known time and length metadata before matching observations to predictions; inconsistent grids are errors. A visual comparison does not establish that likelihoods or biological assumptions are comparable.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_compare_residuals(a, b, dat)
```

![示例图 / Example figure: `plot_compare_residuals(a, b, dat)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_residuals.png?raw=true&v=f97bb9ff3e81)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_compare_residuals)。

<a id="plot_compare_selectivity"></a>
## `plot_compare_selectivity()`

固定调查可捕性 / Fixed survey catchability

`read_assessment()` 读取的评估结果可直接绘图，固定调查可捕性从保留的输入配方恢复。旧会话中的拟合可使用其 TMB 数据；若旧保存结果缺少所需输入，须先用原始输入列表 `x` 重新保存。

Saved assessments from `read_assessment()` can be plotted directly: fixed survey catchability is recovered from the retained input recipe. A legacy live fit can use its TMB data; an older saved fit without the required inputs must first be saved again with its original input bundle `x`.

```r
plot_compare_selectivity (model1, model2, model1_name = NULL, model2_name = NULL, colors = NULL,
    linetypes = NULL, line_size = NULL, ..., point_size = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model1` | `必填 / required` | 第一个拟合对象。 | First fit; its fixed survey catchability is plotted. |
| `model2` | `必填 / required` | 第二个拟合对象。 | Second model result (alternative). |
| `model1_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `model2_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `colors` | `NULL` | 按两个模型顺序提供两种颜色；名称可选。 | Named character vector of 2 colors. NULL = use global theme. |
| `linetypes` | `NULL` | 按模型顺序提供两种线型。 | Named character vector of 2 linetypes. NULL = use global theme. |
| `line_size` | `NULL` | 线宽；参数名按函数区别使用。 | Numeric. NULL = use global theme. |
| `...` | 可选 / optional | 旧参数名 linewidth，仍可使用但会给出警告。 | The former argument name linewidth, accepted with a warning. |
| `point_size` | `NULL` | 点大小；NULL 优先继承比较图覆盖值，否则继承全局 point_size（默认 2.5）。显式值优先。 | Point size; NULL inherits an explicit comparison override or global point_size (default 2.5). A supplied value takes priority. |

**返回 / Returns:** ggplot 对象，可继续调整样式或用 `ggplot2::ggsave()` 保存。

A ggplot object, suitable for further styling or `ggplot2::ggsave()`.

同一模型的两份结果会自动使用不同图例，例如 `ACL (group_year)` 和 `ACL (year)`，仍支持显式指定不同的 `model1_name`、`model2_name`。时间序列与 F 图保留每份结果自己的真实年份，可以显示不同时间范围。与 `data.CatL` 配对的图会核对已知时间和体长元数据，再匹配观测与预测；网格不一致时明确报错。图形比较不代表似然或生物假设具有可比性。

Comparison plots give distinct default labels to two fits of the same model: for example, `ACL (group_year)` and `ACL (year)`. Explicit distinct `model1_name` and `model2_name` remain supported. Time-series and F plots retain each fit's own calendar, including different time spans. Plots paired with `data.CatL` check known time and length metadata before matching observations to predictions; inconsistent grids are errors. A visual comparison does not establish that likelihoods or biological assumptions are comparable.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_compare_selectivity(a, b)
```

![示例图 / Example figure: `plot_compare_selectivity(a, b)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_selectivity.png?raw=true&v=8910454b5721)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_compare_selectivity)。

<a id="plot_compare_ts"></a>
## `plot_compare_ts()`

种群时间序列比较 / Population time series comparison

捕捞死亡率图按矩阵位置和拟合年份、组别元数据构造坐标，矩阵行列名不会改变坐标。生物量、SSB、捕获量和 F 的年龄分面在有无区间时都按数值组序排列。F 图和时间序列比较在 `se = TRUE` 时要求完整、有限的估计与有限非负标准误；缺失摘要会报错，不再重复填充或静默取消区间。只画估计时请明确使用 `se = FALSE`。

Fishing-mortality plots use matrix positions and fitted time/group metadata, so matrix dimnames cannot alter the coordinates. Age panels in biomass, SSB, catch and F plots retain numeric group order with or without intervals. F plots and time-series comparisons require complete finite estimates and nonnegative finite standard errors when `se = TRUE`; missing summaries are errors rather than recycled values or silently removed intervals. Use `se = FALSE` explicitly for estimates only.

`plot_compare_ts()` 默认比较两模型共有的 SSB、补充量、B、N、CN。显式请求 CB 时，两模型都必须包含它（ACL 不报告 CB）；当前两模型均不报告 CB 标准误。请求的每种输出都必须存在；未知或不可用的输出会明确报错。捕捞死亡率请使用 `plot_compare_annual_F(a, b, method = "apical")` 或 `method = "mean"`。这两个选项分别取每个模型时期的组间最大值或非加权均值，不合并多个时期；该函数不提供汇总 F 的不确定性区间。

`plot_compare_ts()` defaults to the common SSB, recruitment, B, N and CN series. Explicit CB comparisons require CB in both models (ACL does not report it); CB uncertainty is not reported by either current model. Every requested quantity must be available; unknown or unavailable quantities produce an error. For fishing mortality use `plot_compare_annual_F(a, b, method = "apical")` or `method = "mean"`. These summarize F across groups per model period, not across periods; the mean is unweighted. This helper does not provide an uncertainty interval for the aggregate.

```r
plot_compare_ts (model1, model2, quantities = c("SSB", "R", "B", "N", "CN"), se = FALSE,
    model1_name = NULL, model2_name = NULL, colors = NULL, linetypes = NULL, line_size = NULL,
    facet_ncol = NULL, facet_scales = NULL, return_data = FALSE, ...)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model1` | `必填 / required` | 第一个拟合对象。 | First model result (reference). |
| `model2` | `必填 / required` | 第二个拟合对象。 | Second model result (alternative). |
| `quantities` | `c("SSB", "R", "B", "N", "CN")` | 选定标量输出：SSB、R/Rec、B、N、CN、CB；F 使用 plot_compare_annual_F。 | Character vector. Quantities to compare. Accepts: "SSB", "R" (or "Rec"), "B", "N", "CN", "CB". For F use plot_compare_annual_F(). Default c("SSB","R","B","N","CN"). |
| `se` | `FALSE` | 是否绘制可用标准误对应的近似区间。 | Logical. Show confidence intervals. Default FALSE. |
| `model1_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `model2_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `colors` | `NULL` | 按两个模型顺序提供两种颜色；名称可选。 | Named character vector of 2 colors. NULL = use global theme. |
| `linetypes` | `NULL` | 按模型顺序提供两种线型。 | Named character vector of 2 linetypes. NULL = use global theme. |
| `line_size` | `NULL` | 线宽；参数名按函数区别使用。 | Numeric. NULL = use global theme. |
| `facet_ncol` | `NULL` | 分面排列的列数。 | Integer. Facet columns. NULL = use global theme. |
| `facet_scales` | `NULL` | fixed、free、free_x 或 free_y；自由尺度有助观察组内变化。 | Character. Facet facet_scales. NULL = use global theme. |
| `return_data` | `FALSE` | TRUE 同时返回绘图对象及整理后的数据；结构见返回说明。 | Logical. Return data alongside plot. Default FALSE. |
| `...` | 可选 / optional | 旧参数名 linewidth、ncol、scales，仍可使用但会给出警告。 | The former argument names linewidth, ncol and scales, accepted with a warning. |

**返回 / Returns:** ggplot 对象；`return_data=TRUE` 时返回含 `plot` 和整理后的 `data` 的列表。

A ggplot object; with `return_data=TRUE`, a list with `plot` and the processed `data`.

同一模型的两份结果会自动使用不同图例，例如 `ACL (group_year)` 和 `ACL (year)`，仍支持显式指定不同的 `model1_name`、`model2_name`。时间序列与 F 图保留每份结果自己的真实年份，可以显示不同时间范围。与 `data.CatL` 配对的图会核对已知时间和体长元数据，再匹配观测与预测；网格不一致时明确报错。图形比较不代表似然或生物假设具有可比性。

Comparison plots give distinct default labels to two fits of the same model: for example, `ACL (group_year)` and `ACL (year)`. Explicit distinct `model1_name` and `model2_name` remain supported. Time-series and F plots retain each fit's own calendar, including different time spans. Plots paired with `data.CatL` check known time and length metadata before matching observations to predictions; inconsistent grids are errors. A visual comparison does not establish that likelihoods or biological assumptions are comparable.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_compare_ts(a, b, se = TRUE, facet_ncol = 2)
```

![示例图 / Example figure: `plot_compare_ts(a, b, se = TRUE, facet_ncol = 2)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_ts.png?raw=true&v=6e0c7883ce7f)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_compare_ts)。

<a id="plot_deviance"></a>
## `plot_deviance()`

过程偏差 R TRUE / Process deviations R TRUE

`log = TRUE` 标明对数过程偏差；`log = FALSE` 标明乘数。标题和纵轴标签分别使用 `dev_R`/`dev_F`，指数转换后使用 `dev_R_multiplier`/`dev_F_multiplier`。这些量不是似然偏差统计量。

`log = TRUE` labels log process deviations; `log = FALSE` labels multiplicative factors. Titles and y-axis labels use `dev_R`/`dev_F`, or `dev_R_multiplier`/`dev_F_multiplier` after exponentiation. These quantities are not likelihood deviances.

调用中给出的 `title`、`xlab`、`ylab` 和字体参数替换对应的主题设置。ACL 的 F 偏差图按年龄数字顺序排列面板。

A `title`, `xlab`, `ylab` or typography argument given in the call replaces the corresponding theme setting. ACL F-deviation age panels keep numeric order.

`se = FALSE` 使用报告中的过程偏差，无需标准误表；绘制区间则要求完整、有限、非负的标准误。 `se = FALSE` uses reported deviations without a standard-error table; intervals require complete, finite, nonnegative standard errors.

```r
plot_deviance (model_result, se = FALSE, point_size = NULL, point_color = "white", point_shape = 21,
    line_size = NULL, line_color = NULL, line_type = "solid", se_color = NULL, se_width = 0.5,
    facet_ncol = NULL, facet_scales = "free", log = TRUE, type = c("R", "F"), title = NULL,
    xlab = NULL, ylab = NULL, font_family = NULL, title_size = NULL, axis_title_size = NULL,
    axis_text_size = NULL, strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL,
    base_theme = NULL, title_hjust = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model_result` | `必填 / required` | 单次模型拟合结果。 | A list from run_acl or run_alscl. |
| `se` | `FALSE` | 是否画标准误区间；默认 FALSE。 | Logical. Whether to draw 95% intervals from the standard errors. Default is FALSE. |
| `point_size` | `NULL` | 点大小；NULL 继承全局 point_size（默认 2.5）。 | Numeric or NULL. NULL inherits the global point_size setting (default 2.5). |
| `point_color` | `"white"` | 点颜色。 | Character. The color of the point. Default is "white". |
| `point_shape` | `21` | 点形状编号，如 16、21。 | Numeric. The shape of the point. Default is 21. |
| `line_size` | `NULL` | NULL 继承全局 line_size，显式值优先。 | NULL inherits global line_size; explicit values take priority. |
| `line_color` | `NULL` | 单模型线条颜色。 | Character or NULL. NULL inherits the global line_color setting. |
| `line_type` | `"solid"` | 线型，如 solid、dashed。 | Character, the line type. |
| `se_color` | `NULL` | 区间阴影或误差棒的颜色。 | Character or NULL. NULL inherits the global se_color setting. |
| `se_width` | `0.5` | 误差棒端帽宽度。 | Numeric, the width of the standard error. |
| `facet_ncol` | `NULL` | 分面排列的列数。 | Number of columns in facet wrap. Default is NULL. |
| `facet_scales` | `"free"` | fixed、free、free_x 或 free_y；自由尺度有助观察组内变化。 | Scales for facet wrap. Default is "free". |
| `log` | `TRUE` | TRUE 为对数过程偏差；FALSE 取指数，参考值为 1。 | TRUE plots log process deviations; FALSE plots exponentiated multipliers, not likelihood deviances. |
| `type` | `c("R", "F")` | R 为补充过程偏差，F 为捕捞死亡率过程偏差；均不是似然离差。 | Character. "R" for recruitment deviation, "F" for fishing mortality deviation. |
| `title` | `NULL` | 自定义图标题；NULL 继承主题。 | Character or NULL. Custom plot title. If NULL, uses global theme setting. See acl_theme_set(). |
| `xlab` | `NULL` | 自定义横轴标签；NULL 继承主题。 | Character or NULL. Custom x-axis label. If NULL, uses global theme setting. |
| `ylab` | `NULL` | 自定义纵轴标签；NULL 继承主题。 | Character or NULL. Custom y-axis label. If NULL, uses global theme setting. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character or NULL. Custom font family. If NULL, uses global theme setting (default "sans"). |
| `title_size` | `NULL` | 图标题字号。 | Numeric or NULL. Plot title size in pt. If NULL, uses global theme (default 14). |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12). |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10). |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10). |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10). |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector or NULL. Custom x-axis breaks (e.g. seq(1, 20, by = 2)). NULL = auto. |
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character or NULL. Base ggplot2 theme name (e.g. "theme_bw"). NULL = global setting. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting. |

**返回 / Returns:** ggplot 对象，可继续调整样式或用 `ggplot2::ggsave()` 保存。

A ggplot object, suitable for further styling or `ggplot2::ggsave()`.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_deviance(b, type = "R", log = TRUE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

![示例图 / Example figure: `plot_deviance(b, type = "R", log = TRUE, se = TRUE, facet_ncol = 3)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_R_TRUE.png?raw=true&v=e16626d72746)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_deviance)。

<a id="plot_fishing_mortality"></a>
## `plot_fishing_mortality()`

ACL 捕捞死亡率 year / ACL fishing mortality year

所有模式继承全局标题 `F_year`、`F_age` 或 `F_length`（区间加 `_se`）、对应的横轴标签、`ylab$F`、`x_breaks` 和 `x_expand`；显式绘图参数优先。默认年龄横坐标为组序号，标为 Age group。`base_theme` 接受 `"theme_bw"` 等主题名称，也保留 `ggplot2::theme_bw()` 等主题对象，两种方式均保持无网格。

All modes inherit global titles `F_year`, `F_age`, or `F_length` (append `_se` for intervals), matching x-axis labels, `ylab$F`, `x_breaks`, and `x_expand`. Explicit plot arguments take priority. Default age coordinates are group indices and are labeled Age group. `base_theme` accepts a theme name such as `"theme_bw"` or a ggplot2 theme object such as `ggplot2::theme_bw()`; both preserve grid-free panels.

捕捞死亡率图按矩阵位置和拟合年份、组别元数据构造坐标，矩阵行列名不会改变坐标。生物量、SSB、捕获量和 F 的年龄分面在有无区间时都按数值组序排列。F 图和时间序列比较在 `se = TRUE` 时要求完整、有限的估计与有限非负标准误；缺失摘要会报错，不再重复填充或静默取消区间。只画估计时请明确使用 `se = FALSE`。

Fishing-mortality plots use matrix positions and fitted time/group metadata, so matrix dimnames cannot alter the coordinates. Age panels in biomass, SSB, catch and F plots retain numeric group order with or without intervals. F plots and time-series comparisons require complete finite estimates and nonnegative finite standard errors when `se = TRUE`; missing summaries are errors rather than recycled values or silently removed intervals. Use `se = FALSE` explicitly for estimates only.

```r
plot_fishing_mortality (model_result, line_size = NULL, line_color = NULL, line_type = "solid",
    facet_ncol = NULL, facet_scales = "free", se = FALSE, se_color = NULL, se_alpha = NULL,
    se_type = "ribbon", type = c("year", "age", "length"), return_data = FALSE, x_breaks = NULL,
    title = NULL, xlab = NULL, ylab = NULL, font_family = NULL, title_size = NULL,
    base_theme = NULL, axis_title_size = NULL, axis_text_size = NULL, strip_text_size = NULL,
    legend_text_size = NULL, title_hjust = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model_result` | `必填 / required` | 单次模型拟合结果。 | A list obtained from run_acl or run_alscl. |
| `line_size` | `NULL` | NULL 继承全局 line_size，显式值优先。 | NULL inherits global line_size; explicit values take priority. |
| `line_color` | `NULL` | 单模型线条颜色。 | Character or NULL. NULL inherits the global line_color setting. |
| `line_type` | `"solid"` | 线型，如 solid、dashed。 | Character. The type of the line. Default is "solid". |
| `facet_ncol` | `NULL` | 分面排列的列数。 | Integer. The number of columns in facet_wrap. |
| `facet_scales` | `"free"` | fixed、free、free_x 或 free_y；自由尺度有助观察组内变化。 | Character. Scales for facet_wrap. Default is "free". |
| `se` | `FALSE` | 是否绘制可用标准误对应的近似区间。 | Logical. Whether to plot confidence intervals. Default is FALSE. |
| `se_color` | `NULL` | 区间阴影或误差棒的颜色。 | Character or NULL. NULL inherits the global se_color setting. |
| `se_alpha` | `NULL` | NULL 继承全局 se_alpha，显式值优先。 | NULL inherits global se_alpha; explicit values take priority. |
| `se_type` | `"ribbon"` | 区间样式：ribbon 或 errorbar。 | Character. "ribbon" or "errorbar". Default is "ribbon". |
| `type` | `c("year", "age", "length")` | year 为时间横轴；age 按年绘年龄别 F；ALSCL length 按年绘实际体长别 F。ACL 旧 length 别名仍画年龄并警告。 | year uses a time axis; age facets F-at-age by year; ALSCL length uses actual midpoints and year facets. The legacy ACL length alias still draws age and warns. |
| `return_data` | `FALSE` | TRUE 同时返回绘图对象及整理后的数据；结构见返回说明。 | Logical. Whether to return data alongside the plot. Default is FALSE. |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector. Custom x-axis breaks. |
| `title` | `NULL` | 自定义图标题；NULL 继承默认。 | Character. Custom plot title. |
| `xlab` | `NULL` | 自定义横轴标签；NULL 继承主题。 | Character. Custom x-axis label. |
| `ylab` | `NULL` | 自定义纵轴标签；NULL 继承主题。 | Character. Custom y-axis label. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character. Font family for text elements. |
| `title_size` | `NULL` | 图标题字号。 | Numeric. Title text size. |
| `base_theme` | `NULL` | 主题名称（如 theme_bw）或 ggplot2 主题对象（如 theme_bw()）；NULL 继承全局，保持无网格。 | Theme name or ggplot2 theme object; NULL inherits the global base theme. Panels remain grid-free. |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12). |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10). |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10). |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10). |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting. |

**返回 / Returns:** ggplot 对象；`return_data=TRUE` 时返回含 `plot` 和整理后的 `data` 的列表。

A ggplot object; with `return_data=TRUE`, a list with `plot` and the processed `data`.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_fishing_mortality(a, type = "year",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

![示例图 / Example figure: `plot_fishing_mortality(b, type = "year", se = TRUE, facet_ncol = 4, line_size = 0.6)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_year.png?raw=true&v=098d37cae7d1)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_fishing_mortality)。

ACL 的 `type="length"` 当前与 `"age"` 是兼容别名，不能解释为长度别 F。 / For ACL, length remains an age-plot compatibility alias.

<a id="plot_pla"></a>
## `plot_pla()`

年龄长度转换 / Age length conversion

`plot_pla(x_breaks = c(1, 5, 10, 15))` 选择年龄组刻度，不删除热图单元。

`plot_pla(x_breaks = c(1, 5, 10, 15))` selects age-bin ticks without removing heatmap cells.

```r
plot_pla (model_result, low_col = NULL, high_col = NULL, title = NULL, xlab = NULL,
    ylab = NULL, font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL,
    strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL,
    title_hjust = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model_result` | `必填 / required` | 单次模型拟合结果。 | A list that contains model output. The model output should include a PLA report. |
| `low_col` | `NULL` | 概率热图的低值 / 高值颜色。 | Character or NULL. NULL inherits the global low_col setting. |
| `high_col` | `NULL` | 概率热图的低值 / 高值颜色。 | Character or NULL. NULL inherits the global high_col setting. |
| `title` | `NULL` | 自定义图标题；NULL 继承默认。 | Character or NULL. Custom plot title. If NULL, uses global theme setting. See acl_theme_set(). |
| `xlab` | `NULL` | 自定义横轴标签；NULL 继承主题。 | Character or NULL. Custom x-axis label. If NULL, uses global theme setting. |
| `ylab` | `NULL` | 自定义纵轴标签；NULL 继承主题。 | Character or NULL. Custom y-axis label. If NULL, uses global theme setting. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character or NULL. Custom font family. If NULL, uses global theme setting (default "sans"). |
| `title_size` | `NULL` | 图标题字号。 | Numeric or NULL. Plot title size in pt. If NULL, uses global theme (default 14). |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12). |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10). |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10). |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10). |
| `x_breaks` | `NULL` | 整数年龄组位置；仅选择刻度，不删除热图单元。NULL 继承全局值。 | Integer age-bin positions selecting ticks without removing cells; NULL inherits the global setting. |
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character or NULL. Base ggplot2 theme name (e.g. "theme_bw"). NULL = global setting. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting. |

**返回 / Returns:** ggplot 对象，可继续调整样式或用 `ggplot2::ggsave()` 保存。

A ggplot object, suitable for further styling or `ggplot2::ggsave()`.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_pla(b) + scale_x_discrete(labels = as.character(1:15))
```

![示例图 / Example figure: `plot_pla(b)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/pla.png?raw=true&v=3f17714c7721)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_pla)。

<a id="plot_recruitment"></a>
## `plot_recruitment()`

补充量 / Recruitment

标准误必须完整、有限且非负；仅绘制估计值时使用 `se = FALSE`。 Standard errors must be complete, finite and nonnegative; use `se = FALSE` for estimates only.

```r
plot_recruitment (model_result, line_size = NULL, line_color = NULL, line_type = "solid",
    se = FALSE, se_color = NULL, se_alpha = NULL, se_type = c("ribbon", "errorbar"),
    return_data = FALSE, title = NULL, xlab = NULL, ylab = NULL, font_family = NULL,
    title_size = NULL, axis_title_size = NULL, axis_text_size = NULL, strip_text_size = NULL,
    legend_text_size = NULL, x_breaks = NULL, base_theme = NULL, title_hjust = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model_result` | `必填 / required` | 单次模型拟合结果。 | A list that contains the model output. The list should have a "report" component which contains a "Rec" component representing Recruitment. |
| `line_size` | `NULL` | NULL 继承全局 line_size，显式值优先。 | NULL inherits global line_size; explicit values take priority. |
| `line_color` | `NULL` | 单模型线条颜色。 | Character or NULL. NULL inherits the global line_color setting. |
| `line_type` | `"solid"` | 线型，如 solid、dashed。 | Character. Specifies the type of the line in the plot. Default is "solid". |
| `se` | `FALSE` | 是否绘制可用标准误对应的近似区间。 | Logical. Draw approximate pointwise 95% confidence intervals using model-based standard errors. Default FALSE. |
| `se_color` | `NULL` | 区间阴影或误差棒的颜色。 | Character or NULL. NULL inherits the global se_color setting. |
| `se_alpha` | `NULL` | NULL 继承全局 se_alpha，显式值优先。 | NULL inherits global se_alpha; explicit values take priority. |
| `se_type` | `c("ribbon", "errorbar")` | 区间样式：ribbon 或 errorbar。 | Character. Type of CI display: "ribbon" (shaded area) or "errorbar" (error bars). Default is "ribbon". |
| `return_data` | `FALSE` | TRUE 同时返回绘图对象及整理后的数据；结构见返回说明。 | A logical indicating whether to return the processed data alongside the plot. Default is FALSE. |
| `title` | `NULL` | 自定义图标题；NULL 继承默认。 | Character or NULL. Custom plot title. If NULL, uses global theme setting. See acl_theme_set(). |
| `xlab` | `NULL` | 自定义横轴标签；NULL 继承主题。 | Character or NULL. Custom x-axis label. If NULL, uses global theme setting. |
| `ylab` | `NULL` | 自定义纵轴标签；NULL 继承主题。 | Character or NULL. Custom y-axis label. If NULL, uses global theme setting. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character or NULL. Custom font family. If NULL, uses global theme setting (default "sans"). |
| `title_size` | `NULL` | 图标题字号。 | Numeric or NULL. Plot title size in pt. If NULL, uses global theme (default 14). |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12). |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10). |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10). |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10). |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector or NULL. Custom x-axis breaks (e.g. seq(1, 20, by = 2)). NULL = auto. |
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character or NULL. Base ggplot2 theme name (e.g. "theme_bw"). NULL = global setting. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting. |

**返回 / Returns:** ggplot 对象；`return_data=TRUE` 时返回含 `plot` 和整理后的 `data` 的列表。

A ggplot object; with `return_data=TRUE`, a list with `plot` and the processed `data`.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_recruitment(b, se = TRUE)
```

![示例图 / Example figure: `plot_recruitment(b, se = TRUE)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/recruitment.png?raw=true&v=f3b37834bb1a)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_recruitment)。

<a id="plot_residuals"></a>
## `plot_residuals()`

对数残差 length / Log residuals length

每个分面按有效且不同的横坐标数量独立选择平滑方法：不足 2 个不画趋势，2–5 个使用线性拟合，6 个以上使用独立 span 的 loess。一个稀疏组不会改变其他组的趋势。

Each facet selects its smoother independently using the number of distinct valid x values: fewer than 2 omits the trend, 2–5 uses a linear fit, and 6 or more uses loess with its own span. A sparse group never changes another group's trend.

调查拟合图按矩阵位置及拟合年份、体长元数据对齐观测与预测，增删行列名不会改变坐标；缺失及零观测继续排除。若预测取指数会溢出，请使用 `exp_transform = FALSE`。残差图的 `resid_cap` 必须为有限正标量，或以 `NULL` 关闭截断；不再允许负值或零值抹去诊断特征。

Survey fit plots align both observed and predicted matrices by their positions and fitted calendar/length metadata, even if dimnames are added or removed. Missing and zero observations stay excluded. Use `exp_transform = FALSE` if exponentiating predictions would overflow. In residual plots, `resid_cap` must be a finite positive scalar or `NULL` to disable capping; negative or zero caps cannot erase the diagnostic pattern.

残差图的两种布局均遵守单次调用的 `title`、`xlab`、`ylab` 和 `title_hjust`。例如 `plot_residuals(b, type = "year", title = "Survey residuals", xlab = "Length (cm)", ylab = "Log residual", title_hjust = 0)` 使用指定标签并左对齐标题。所有默认图继续不显示主、次网格线。

Both residual layouts honor per-call `title`, `xlab`, `ylab` and `title_hjust`. For example, `plot_residuals(b, type = "year", title = "Survey residuals", xlab = "Length (cm)", ylab = "Log residual", title_hjust = 0)` uses the supplied labels and a left-aligned title. Default plots remain free of major and minor gridlines.

```r
plot_residuals (model_result, f = 0.4, line_color = NULL, smooth_color = NULL, hline_color = NULL,
    line_size = NULL, facet_scales = "free", facet_ncol = NULL, facet_by = c("length",
        "year"), resid_cap = NULL, return_data = FALSE, title = NULL, xlab = NULL,
    ylab = NULL, font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL,
    strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL,
    title_hjust = NULL, ...)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model_result` | `必填 / required` | run_acl() 或 run_alscl() 的拟合结果，需保存 report 及观测信息。 | A fit from run_acl() or run_alscl(), retaining report and observation information. |
| `f` | `0.4` | 残差平滑参数，越大越平滑。 | Numeric. The smoother span for the loess smooth line in the plot. This gives the proportion of points in the plot which influence the smooth at each value. Larger values result in more smoothing. Default is 0.4. Each facet independently uses no trend with fewer than 2 valid distinct x values, a linear fit with 2–5, or loess with at least 6; span is enlarged for at least five neighbors. |
| `line_color` | `NULL` | 单模型线条颜色。 | Character or NULL. NULL inherits the global line_color setting. |
| `smooth_color` | `NULL` | 残差平滑线颜色。 | Character or NULL. NULL inherits the global smooth_color setting. |
| `hline_color` | `NULL` | 残差零参考线颜色。 | Character or NULL. NULL inherits the global hline_color setting. |
| `line_size` | `NULL` | NULL 继承全局 line_size，显式值优先。 | NULL inherits global line_size; explicit values take priority. |
| `facet_scales` | `"free"` | fixed、free、free_x 或 free_y；自由尺度有助观察组内变化。 | Character. The "scales" argument for the facet_wrap function in ggplot2. Default is "free". |
| `facet_ncol` | `NULL` | 分面排列的列数。 | Numeric, optional. Number of columns in facet wrap. Default is NULL. |
| `facet_by` | `c("length", "year")` | 布局："length" 每个体长组一个面板、横轴为时间；"year" 每个时间步一个面板、横轴为体长。 | "length" (default) draws one panel per length bin with time on the x axis; "year" draws one panel per time step with length on the x axis. |
| `resid_cap` | `NULL` | 可选残差显示裁剪阈值；使用时需说明。 | Numeric or NULL. Symmetrically cap residuals at +/- this value. Useful for species with many length bins where tail bins (e.g. >120 for tuna) have very few observations, producing extreme log-residuals that distort the plot. Default is NULL (no capping). Use capping only when its threshold and effect on displayed residuals are reported. |
| `return_data` | `FALSE` | TRUE 同时返回绘图对象及整理后的数据；结构见返回说明。 | A logical indicating whether to return the processed data alongside the plot. Default is FALSE. |
| `title` | `NULL` | 自定义图标题；NULL 继承默认。 | Character or NULL. Custom plot title. If NULL, uses global theme setting. See acl_theme_set(). |
| `xlab` | `NULL` | 自定义横轴标签；NULL 继承主题。 | Character or NULL. Custom x-axis label. If NULL, uses global theme setting. |
| `ylab` | `NULL` | 自定义纵轴标签；NULL 继承主题。 | Character or NULL. Custom y-axis label. If NULL, uses global theme setting. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character or NULL. Custom font family. If NULL, uses global theme setting (default "sans"). |
| `title_size` | `NULL` | 图标题字号。 | Numeric or NULL. Plot title size in pt. If NULL, uses global theme (default 14). |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12). |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10). |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10). |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10). |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector or NULL. Custom x-axis breaks (e.g. seq(1, 20, by = 2)). NULL = auto. |
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character or NULL. Base ggplot2 theme name (e.g. "theme_bw"). NULL = global setting. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting. |
| `...` | 可选 / optional | 旧参数名 type，仍可使用但会给出警告。 | The former argument name type, accepted with a warning. |

**返回 / Returns:** ggplot 对象；`return_data=TRUE` 时返回含 `plot` 和整理后的 `data` 的列表。

A ggplot object; with `return_data=TRUE`, a list with `plot` and the processed `data`.

`plot_ridges()` 和 `plot_residuals()` 使用保存的 `observations`，保留与拟合一致的正观测掩码；旧结果可读取 TMB 数据。NA 和拟合时排除的零值不会变成人造观测或零残差。整期缺测不绘制观测山脊；部分缺测时，观测比例只在有效正观测中归一化，预测比例则覆盖全部体长组，不能把它解释为未观测组也拟合良好。保留 `observations` 的拟合结果移除 `obj` 后仍可使用这两个绘图函数。

`plot_ridges()` and `plot_residuals()` use saved `observations` to preserve the same positive-observation mask as fitting; legacy fits can use their TMB data. NA and excluded zero cells are never converted to artificial observations or zero residuals. A wholly unobserved period has no observed ridge. With partial coverage, the observed ridge is normalized over observed positive cells, whereas predictions cover all bins: do not interpret this as agreement over unobserved bins. These plots work after removing `obj` from a fit that retains `observations`.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_residuals(b, facet_by = "length", facet_ncol = 4, line_size = 0.6,
  x_breaks = c(2000, 2010, 2015))
```

![示例图 / Example figure: `plot_residuals(b, facet_by = "year", facet_ncol = 4)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/residuals_year.png?raw=true&v=d23449a96976)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_residuals)。

<a id="plot_retro"></a>
## `plot_retro()`

ACL 回溯分析 / ACL retrospective analysis

```r
plot_retro (retro_result, rho_digits = 4, rho_position = "top_right", rho_size = 3.5,
    line_size = NULL, point_size = NULL, point_shape = 21, facet_scales = "free",
    facet_ncol = NULL, facet_nrow = NULL, title = NULL, xlab = NULL, ylab = NULL,
    font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL,
    strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL,
    title_hjust = NULL, palette = NULL, colors = NULL, ...)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `retro_result` | `必填 / required` | retro_model/retro_acl/retro_alscl 的回溯结果。 | A list returned by retro_model(), retro_acl(), or retro_alscl(). |
| `rho_digits` | `4` | Mohn rho 显示的小数位数。 | Integer. Decimal places for Mohn's rho. Default is 4. |
| `rho_position` | `"top_right"` | Mohn rho 标注位置。 | Character. Position of rho text. Default is "top_right". |
| `rho_size` | `3.5` | Mohn rho 标注字号。 | Numeric. Font size of rho text. Default is 3.5. |
| `line_size` | `NULL` | NULL 继承全局 line_size，显式值优先。 | NULL inherits global line_size; explicit values take priority. |
| `point_size` | `NULL` | 点大小；NULL 继承全局 point_size（默认 2.5）。 | Numeric or NULL. NULL inherits the global point_size setting (default 2.5). |
| `point_shape` | `21` | 点形状编号，如 16、21。 | Numeric. Point shape. Default is 21. |
| `facet_scales` | `"free"` | fixed、free、free_x 或 free_y；自由尺度有助观察组内变化。 | Character. Facet scales. Default is "free". |
| `facet_ncol` | `NULL` | 分面排列的列数。 | Integer or NULL. Number of facet columns. |
| `facet_nrow` | `NULL` | 分面排列的行数。 | Integer or NULL. Number of facet rows. |
| `title` | `NULL` | 自定义图标题；NULL 继承默认。 | Character or NULL. Custom plot title. |
| `xlab` | `NULL` | 自定义横轴标签；NULL 继承主题。 | Character or NULL. Custom x-axis label. |
| `ylab` | `NULL` | 自定义纵轴标签；NULL 继承主题。 | Character or NULL. Custom y-axis label. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character or NULL. Font family. |
| `title_size` | `NULL` | 图标题字号。 | Numeric or NULL. Title size in pt. |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector or NULL. Custom x-axis breaks. |
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character or NULL. Base ggplot2 theme name. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment. |
| `palette` | `NULL` | ggsci 色板名；NULL 继承全局设置，部分图也保留旧色板。 | Character or NULL. ggsci palette name; NULL inherits acl_theme(). Native colors are interpolated when there are more peels than colors. |
| `colors` | `NULL` | 按截止期降序给色，或按截止期命名；需覆盖每条曲线。 | Character vector or NULL. Explicit period colors, ordered by descending terminal period or named by terminal period. Overrides palette. |
| `...` | 可选 / optional | 旧参数名 facet_col、facet_row，仍可使用但会给出警告。 | The former argument names facet_col and facet_row, accepted with a warning. |

**返回 / Returns:** ggplot 对象，可继续调整样式或用 `ggplot2::ggsave()` 保存。

A ggplot object, suitable for further styling or `ggplot2::ggsave()`.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_retro(rb, facet_ncol = 2, rho_digits = 3)
```

![示例图 / Example figure: `plot_retro(rb, facet_ncol = 2, rho_digits = 3)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ALSCL.png?raw=true&v=a15f447d44dc)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_retro)。

<a id="plot_ridges"></a>
## `plot_ridges()`

长度组成山脊图 / Length composition ridges

分面标题明确标为观测与拟合的调查体长组成，每个时段分别归一化；不表示总捕获量。

Panel titles identify observed and fitted survey length compositions, normalized separately within each period; they do not describe total catch.

保存了观测与拟合报告的结果可直接使用 `plot_ridges()`，不需要活跃 TMB 对象。未保存观测的旧结果仍需原会话对象或重新拟合。记录包版本、提交号、随机种子、数据来源、三表单位、固定参数、边界、时间步和诊断；RDS 不保存可跨会话执行的编译模型。 默认 `plot_CatL(exp_transform = FALSE)` 绘制自然对数调查指数，并在纵轴标明尺度；`exp_transform = TRUE` 绘制原尺度调查指数，预测曲线为中位数。显式 `ylab` 覆盖自动标签。山脊图在对数尺度稳定归一化，极大或极小的有限对数预测仍可绘制；非有限预测会报错。

Saved fits containing observations and fitted reports support `plot_ridges()` without a live TMB object. Older fits without saved observations still require their original live object or refitting. Record version, commit, seed, provenance, units, maps, bounds, time step and diagnostics. An RDS file does not preserve a portable compiled model. The default `plot_CatL(exp_transform = FALSE)` displays natural-log survey indices and labels that scale explicitly. `exp_transform = TRUE` displays original-scale survey indices; curves are fitted medians. An explicit `ylab` overrides the automatic label. Ridge compositions are normalized stably on the log scale, including very large or small finite log predictions; nonfinite predictions are rejected.

```r
plot_ridges (model_result, ridges_alpha = 0.8, ridges_scale = NULL, palette = "viridis",
    title = NULL, xlab = NULL, ylab = NULL, font_family = NULL, title_size = NULL,
    axis_title_size = NULL, axis_text_size = NULL, strip_text_size = NULL, legend_text_size = NULL,
    x_breaks = NULL, base_theme = NULL, title_hjust = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model_result` | `必填 / required` | 单次模型拟合结果。 | A list containing the model result, which includes a data frame of Elog_index and logN_at_len, len_mid, and year. |
| `ridges_alpha` | `0.8` | 山脊图透明度。 | Numeric. Specifies the transparency of the ridgeline plots. Default is 0.8. |
| `ridges_scale` | `NULL` | 山脊图高度/重叠缩放。 | Numeric or NULL. Multiplier for ridge height. When NULL (default), auto-scales so the tallest peak fills ~80\% of inter-year spacing. Increase for taller ridges, decrease for flatter. Useful when many length bins make proportions small (e.g. tuna with 22 bins). |
| `palette` | `"viridis"` | 按时间顺序渐变；NULL 同样使用 viridis，不继承全局分类色板。可选 cividis、plasma、ocean 或自定义渐变端点。 | Sequential gradient across ordered years; NULL also uses viridis independently of the global categorical palette. Accepts other named gradients or a color vector; explicit journal palettes remain available. |
| `title` | `NULL` | 自定义图标题；NULL 继承默认。 | Character or NULL. Custom plot title. If NULL, uses global theme setting. See acl_theme_set(). |
| `xlab` | `NULL` | 自定义横轴标签；NULL 继承主题。 | Character or NULL. Custom x-axis label. If NULL, uses global theme setting. |
| `ylab` | `NULL` | 自定义纵轴标签；NULL 继承主题。 | Character or NULL. Custom y-axis label. If NULL, uses global theme setting. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character or NULL. Custom font family. If NULL, uses global theme setting (default "sans"). |
| `title_size` | `NULL` | 图标题字号。 | Numeric or NULL. Plot title size in pt. If NULL, uses global theme (default 14). |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12). |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10). |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10). |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10). |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector or NULL. Custom x-axis breaks (e.g. seq(1, 20, by = 2)). NULL = auto. |
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character or NULL. Base ggplot2 theme name (e.g. "theme_bw"). NULL = global setting. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting. |

**返回 / Returns:** 包含观测与拟合体长组成两个面板的组合图（ggplot 对象），可用 ggplot2::ggsave() 保存。

A two-panel composition of observed and fitted length distributions, returned as a ggplot object and compatible with ggplot2::ggsave().

`plot_ridges()` 和 `plot_residuals()` 使用保存的 `observations`，保留与拟合一致的正观测掩码；旧结果可读取 TMB 数据。NA 和拟合时排除的零值不会变成人造观测或零残差。整期缺测不绘制观测山脊；部分缺测时，观测比例只在有效正观测中归一化，预测比例则覆盖全部体长组，不能把它解释为未观测组也拟合良好。保留 `observations` 的拟合结果移除 `obj` 后仍可使用这两个绘图函数。

`plot_ridges()` and `plot_residuals()` use saved `observations` to preserve the same positive-observation mask as fitting; legacy fits can use their TMB data. NA and excluded zero cells are never converted to artificial observations or zero residuals. A wholly unobserved period has no observed ridge. With partial coverage, the observed ridge is normalized over observed positive cells, whereas predictions cover all bins: do not interpret this as agreement over unobserved bins. These plots work after removing `obj` from a fit that retains `observations`.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_ridges(b)
```

![示例图 / Example figure: `plot_ridges(b)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/ridges.png?raw=true&v=5be1df0903c5)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_ridges)。

<a id="plot_SSB"></a>
## `plot_SSB()`

产卵生物量 SSB / Spawning biomass SSB

所有模式继承全局标题（SSB, SBL, SBA；区间使用对应的 `_se` 键，年龄丰度为 `NA_se`）、`xlab$year`、`ylab$ssb`、`x_breaks` 与 `x_expand`。调用中给出的 `title`、`xlab`、`ylab`、字体和线条参数优先，默认无网格。

All modes inherit global titles (SSB, SBL, SBA; interval variants use the corresponding `_se` keys, with `NA_se` for abundance at age), `xlab$year`, `ylab$ssb`, `x_breaks` and `x_expand`. A `title`, `xlab`, `ylab`, typography or line argument given in the call takes priority. Default panels have no gridlines.

捕捞死亡率图按矩阵位置和拟合年份、组别元数据构造坐标，矩阵行列名不会改变坐标。生物量、SSB、捕获量和 F 的年龄分面在有无区间时都按数值组序排列。F 图和时间序列比较在 `se = TRUE` 时要求完整、有限的估计与有限非负标准误；缺失摘要会报错，不再重复填充或静默取消区间。只画估计时请明确使用 `se = FALSE`。

Fishing-mortality plots use matrix positions and fitted time/group metadata, so matrix dimnames cannot alter the coordinates. Age panels in biomass, SSB, catch and F plots retain numeric group order with or without intervals. F plots and time-series comparisons require complete finite estimates and nonnegative finite standard errors when `se = TRUE`; missing summaries are errors rather than recycled values or silently removed intervals. Use `se = FALSE` explicitly for estimates only.

```r
plot_SSB (model_result, line_size = NULL, line_color = NULL, line_type = "solid",
    se = FALSE, se_color = NULL, se_alpha = NULL, type = c("SSB", "SBL", "SBA"),
    facet_ncol = NULL, facet_scales = "free", return_data = FALSE, title = NULL,
    xlab = NULL, ylab = NULL, font_family = NULL, title_size = NULL, axis_title_size = NULL,
    axis_text_size = NULL, strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL,
    base_theme = NULL, title_hjust = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model_result` | `必填 / required` | 单次模型拟合结果。 | A list from run_acl or run_alscl. |
| `line_size` | `NULL` | NULL 继承全局 line_size，显式值优先。 | NULL inherits global line_size; explicit values take priority. |
| `line_color` | `NULL` | 单模型线条颜色。 | Character or NULL. NULL inherits the global line_color setting. |
| `line_type` | `"solid"` | 线型，如 solid、dashed。 | Character. Line type. Default is "solid". |
| `se` | `FALSE` | 是否绘制可用标准误对应的近似区间。 | Logical. Whether to plot confidence intervals. Default is FALSE. |
| `se_color` | `NULL` | 区间阴影或误差棒的颜色。 | Character or NULL. NULL inherits the global se_color setting. |
| `se_alpha` | `NULL` | NULL 继承全局 se_alpha，显式值优先。 | NULL inherits global se_alpha; explicit values take priority. |
| `type` | `c("SSB", "SBL", "SBA")` | SSB 为总产卵生物量，SBA 为年龄别产卵生物量，SBL 为体长别产卵生物量。 | Character. "SSB" (total), "SBL" (at length), or "SBA" (at age). Default is "SSB". |
| `facet_ncol` | `NULL` | 分面排列的列数。 | Numeric. Columns in facet wrap. Default is NULL. |
| `facet_scales` | `"free"` | fixed、free、free_x 或 free_y；自由尺度有助观察组内变化。 | Character. Scales for facet wrap. Default is "free". |
| `return_data` | `FALSE` | TRUE 同时返回绘图对象及整理后的数据；结构见返回说明。 | Logical. Whether to return processed data. Default is FALSE. |
| `title` | `NULL` | 自定义图标题；NULL 继承主题。 | Character or NULL. Custom plot title. If NULL, uses global theme setting. See acl_theme_set(). |
| `xlab` | `NULL` | 自定义横轴标签；NULL 继承主题。 | Character or NULL. Custom x-axis label. If NULL, uses global theme setting. |
| `ylab` | `NULL` | 自定义纵轴标签；NULL 继承主题。 | Character or NULL. Custom y-axis label. If NULL, uses global theme setting. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character or NULL. Custom font family. If NULL, uses global theme setting (default "sans"). |
| `title_size` | `NULL` | 图标题字号。 | Numeric or NULL. Plot title size in pt. If NULL, uses global theme (default 14). |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12). |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10). |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10). |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10). |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector or NULL. Custom x-axis breaks (e.g. seq(1, 20, by = 2)). NULL = auto. |
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character or NULL. Base ggplot2 theme name (e.g. "theme_bw"). NULL = global setting. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting. |

**返回 / Returns:** ggplot 对象；`return_data=TRUE` 时返回含 `plot` 和整理后的 `data` 的列表。

A ggplot object; with `return_data=TRUE`, a list with `plot` and the processed `data`.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_SSB(b, type = "SSB", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

![示例图 / Example figure: `plot_SSB(b, se = TRUE, facet_ncol = 3, line_size = 0.6)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_SSB_SSB.png?raw=true&v=d3d36a38c338)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_SSB)。

<a id="plot_SSB_Rec"></a>
## `plot_SSB_Rec()`

亲体与补充关系 / Spawning biomass and recruitment

```r
plot_SSB_Rec (model_result, age_at_recruitment = 1, point_size = NULL, point_color = NULL,
    point_shape = 16, return_data = FALSE, title = NULL, xlab = NULL, ylab = NULL,
    font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL,
    strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL,
    title_hjust = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model_result` | `必填 / required` | 单次模型拟合结果。 | A list containing the model results. It includes a component "report" that comprises "SSB" and "Rec". |
| `age_at_recruitment` | `1` | 以年为单位的补充年龄；除以 growth_step 得到整数步滞后，允许零。 | Recruitment age in years; divided by growth_step to obtain an integer lag. Zero is allowed; default 1 year. |
| `point_size` | `NULL` | 点大小；NULL 继承全局 point_size（默认 2.5）。 | Numeric or NULL. NULL inherits the global point_size setting (default 2.5). |
| `point_color` | `NULL` | 点颜色。 | Character or NULL. NULL inherits the global point_color setting. |
| `point_shape` | `16` | 点形状编号，如 16、21。 | Numeric. The shape of the points in the scatter plot, as an integer value (see ?points in base R for more info). Default is 16 (filled circle). |
| `return_data` | `FALSE` | TRUE 同时返回绘图对象及整理后的数据；结构见返回说明。 | A logical indicating whether to return the processed data alongside the plot. Default is FALSE. |
| `title` | `NULL` | 自定义图标题；NULL 继承默认。 | Character or NULL. Custom plot title. If NULL, uses global theme setting. See acl_theme_set(). |
| `xlab` | `NULL` | 自定义横轴标签；NULL 继承主题。 | Character or NULL. Custom x-axis label. If NULL, uses global theme setting. |
| `ylab` | `NULL` | 自定义纵轴标签；NULL 继承主题。 | Character or NULL. Custom y-axis label. If NULL, uses global theme setting. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character or NULL. Custom font family. If NULL, uses global theme setting (default "sans"). |
| `title_size` | `NULL` | 图标题字号。 | Numeric or NULL. Plot title size in pt. If NULL, uses global theme (default 14). |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12). |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10). |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10). |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10). |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector or NULL. Custom x-axis breaks (e.g. seq(1, 20, by = 2)). NULL = auto. |
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character or NULL. Base ggplot2 theme name (e.g. "theme_bw"). NULL = global setting. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting. |

**返回 / Returns:** ggplot 对象；`return_data=TRUE` 时返回含 `plot` 和整理后的 `data` 的列表。

A ggplot object; with `return_data=TRUE`, a list with `plot` and the processed `data`.

`age_at_recruitment` 的单位是年。`plot_SSB_Rec()` 除以拟合的 `growth_step`，要求在规则时间网格上对应整数个时间步。季度数据中，0.25 表示滞后一季度，1 表示四季度。允许零滞后；拒绝负值、非有限值及非整数步滞后。旧结果没有 `growth_step` 时使用规则年份间隔；两类时间元数据都没有时沿用年度步长。

`age_at_recruitment` is in years. `plot_SSB_Rec()` divides it by the fit's `growth_step` and requires an integer lag on a regular time grid. With quarterly data, 0.25 means one step and 1 means four steps. Zero lag is allowed; negative, nonfinite and fractional-step lags are rejected. Legacy results without `growth_step` use their regular time spacing, or an annual step when neither metadata field is available.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_SSB_Rec(b, age_at_recruitment = 1)
```

![示例图 / Example figure: `plot_SSB_Rec(b, age_at_recruitment = 1)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/SSB_Rec.png?raw=true&v=1ba690a33945)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_SSB_Rec)。

<a id="plot_VB"></a>
## `plot_VB()`

生长曲线与区间 / Growth curve and interval

`age_range = NULL` 使用拟合年龄范围；旧结果没有年龄信息时回退到 1–25 岁，自动起点不早于 `t0`。显式范围必须是有限、递增且起点不早于 `t0` 的二元向量；自动范围没有正跨度时会报错。有效的显式范围仍可使用。两种区间样式均保留参数标注，并遵守 `text_size`、`text_color`、`font_family` 和 `ylab$growth`；单次调用的标签优先。

`age_range = NULL` uses the fitted age range; older results without age metadata fall back to 1–25 years. The automatic lower endpoint is at least `t0`. An explicit range must be a finite increasing pair starting at or after `t0`; an automatic range with no positive span is rejected. Valid explicit ranges remain supported. Both confidence-interval styles retain the parameter annotation and honor `text_size`, `text_color`, `font_family`, and `ylab$growth`; explicit labels override global labels.

`ylab` 在所有模式生效；协方差不可用时提示并仅绘制曲线，保留全部自定义样式。 `ylab` is honored in every mode; unavailable covariance triggers a warning and an estimate-only curve that retains all custom styling.

```r
plot_VB (model_result, age_range = NULL, line_size = NULL, line_color = NULL, line_type = "solid",
    se = FALSE, se_color = NULL, se_alpha = NULL, se_type = c("ribbon", "errorbar"),
    text_color = "black", text_size = 5, title = NULL, xlab = NULL, ylab = NULL,
    font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL,
    strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL,
    title_hjust = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model_result` | `必填 / required` | 单次模型拟合结果。 | A list that contains model output. The list should have a "report" component which contains "Linf", "vbk" and "t0" components. |
| `age_range` | `NULL` | 默认采用拟合年龄范围，旧结果无年龄信息时回退到 1–25 岁，自动起点不早于 t0；显式范围须有限、递增且起点不早于 t0。 | NULL uses fitted ages or the legacy 1–25 fallback, with an automatic start no earlier than t0. Explicit ranges must be finite increasing pairs starting at or after t0. |
| `line_size` | `NULL` | NULL 继承全局 line_size，显式值优先。 | NULL inherits global line_size; explicit values take priority. |
| `line_color` | `NULL` | 单模型线条颜色。 | Character or NULL. NULL inherits the global line_color setting. |
| `line_type` | `"solid"` | 线型，如 solid、dashed。 | Character. The type of the line in the plot. Default is "solid". |
| `se` | `FALSE` | 是否绘制可用标准误对应的近似区间。 | Logical. Draw approximate pointwise 95% confidence intervals using model-based standard errors. Default FALSE. |
| `se_color` | `NULL` | 区间阴影或误差棒的颜色。 | Character or NULL. NULL inherits the global se_color setting. |
| `se_alpha` | `NULL` | NULL 继承全局 se_alpha，显式值优先。 | NULL inherits global se_alpha; explicit values take priority. |
| `se_type` | `c("ribbon", "errorbar")` | 区间样式：ribbon 或 errorbar。 | Character. Type of CI display: "ribbon" (shaded area) or "errorbar" (error bars). Default is "ribbon". |
| `text_color` | `"black"` | 生长参数标注文字颜色。 | Character. The color of the text in the plot. Default is "black". |
| `text_size` | `5` | 生长参数标注文字大小。 | Numeric. The thickness of the text in the plot. Default is 5. |
| `title` | `NULL` | 自定义图标题；NULL 继承默认。 | Character or NULL. Custom plot title. If NULL, uses global theme setting. See acl_theme_set(). |
| `xlab` | `NULL` | 自定义横轴标签；NULL 继承主题。 | Character or NULL. Custom x-axis label. If NULL, uses global theme setting. |
| `ylab` | `NULL` | 自定义纵轴标签；NULL 继承主题。 | Character or NULL. Custom y-axis label. If NULL, uses global theme setting. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character or NULL. Custom font family. If NULL, uses global theme setting (default "sans"). |
| `title_size` | `NULL` | 图标题字号。 | Numeric or NULL. Plot title size in pt. If NULL, uses global theme (default 14). |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12). |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10). |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10). |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10). |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector or NULL. Custom x-axis breaks (e.g. seq(1, 20, by = 2)). NULL = auto. |
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character or NULL. Base ggplot2 theme name (e.g. "theme_bw"). NULL = global setting. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting. |

**返回 / Returns:** ggplot 对象，可继续调整样式或用 `ggplot2::ggsave()` 保存。

A ggplot object, suitable for further styling or `ggplot2::ggsave()`.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_VB(b, se = TRUE)
```

![示例图 / Example figure: `plot_VB(b, se = TRUE)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/VB.png?raw=true&v=e2a1e504fa32)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_VB)。

<a id="retro_acl"></a>
## `retro_acl()`

ACL 回溯入口 / ACL retrospective wrapper

回溯子拟合会随保留时期同步截短 `map$dev_log_R` 与 `map$dev_log_F`。请提供完整数据长度的映射：补充量每期一项；F 按组别×时期矩阵的列顺序排列，ACL 使用年龄组、ALSCL 使用体长组，`F_structure = "year"` 只有一组。因子共享关系和固定的 NA 项会保留；完整映射长度错误会明确报错。标量映射及 `dev_log_N0` 不随回溯截短。

Retrospective peels shorten time-dependent `map$dev_log_R` and `map$dev_log_F` with the retained periods. Supply maps for the full dataset: recruitment uses one entry per period; F uses group-by-time column order (age groups for ACL, length groups for ALSCL, one group for `F_structure = "year"`). Factor ties and fixed NA entries are retained. Invalid full-data map lengths are rejected. Scalar maps and `dev_log_N0` do not change with a peel.

```r
retro_acl (nyear = 5, data.CatL, data.wgt, data.mat, rec.age, nage, M, sel_L50, sel_L95,
    parameters = NULL, parameters.L = NULL, parameters.U = NULL, map = NULL, len_mid = NULL,
    len_border = NULL, plot = FALSE, line_size = NULL, point_size = NULL, point_shape = 21,
    facet_scales = "free", facet_ncol = NULL, facet_nrow = NULL, train_times = 1,
    title = NULL, xlab = NULL, ylab = NULL, font_family = NULL, title_size = NULL,
    axis_title_size = NULL, axis_text_size = NULL, strip_text_size = NULL, legend_text_size = NULL,
    x_breaks = NULL, base_theme = NULL, title_hjust = NULL, rho_digits = 4, rho_position = "top_right",
    rho_size = 3.5, ncores = 1, ...)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `nyear` | `5` | 模拟器为总年数；回溯函数为删除的末端时间步数。 | Number of terminal observation steps peeled, not calendar years for quarterly data. |
| `data.CatL` | `必填 / required` | 原拟合使用的调查数量指数表（首列体长标签，其余列为模型时期），或完整拟合输入列表。 | The original survey numbers-at-length or index table (length labels followed by model periods), or a complete fitting input bundle. |
| `data.wgt` | `必填 / required` | 平均单尾体重表，与调查表完全对齐。 | The weight data. |
| `data.mat` | `必填 / required` | 成熟比例表，0–1，与调查表完全对齐。 | The maturity data. |
| `rec.age` | `必填 / required` | 补充年龄，单位为年。 | The recruitment age. |
| `nage` | `必填 / required` | 年龄组数量，包括最大年龄加组。 | The number of age classes. |
| `M` | `必填 / required` | 每个模型时间步的自然死亡瞬时率。 | The natural mortality rate. |
| `sel_L50` | `必填 / required` | 调查可捕性达到 0.5 的体长。 | Length at survey catchability 0.5. |
| `sel_L95` | `必填 / required` | 调查可捕性达到 0.95 的体长，必须大于 sel_L50。 | Length at survey catchability 0.95, greater than sel_L50. |
| `parameters` | `NULL` | 命名参数初值列表，采用优化器尺度。 | Optional custom starting parameter list. |
| `parameters.L` | `NULL` | 命名下界列表，采用优化器尺度。 | Optional lower bounds for parameters. |
| `parameters.U` | `NULL` | 命名上界列表，采用优化器尺度。 | Optional upper bounds for parameters. |
| `map` | `NULL` | TMB 映射；factor(NA) 固定，具名 NULL 项释放该项；整个 map=NULL 则使用模型默认固定规则。 | Optional TMB map argument for fixing parameters. |
| `len_mid` | `NULL` | 每个体长组的中心值向量，长度与数据行数相同。 | Optional numeric vector of length bin midpoints. |
| `len_border` | `NULL` | 体长边界；拟合入口需要 nlen-1 个内部边界，模拟器使用 nlen+1 个完整边界。 | Optional numeric vector of length bin borders. |
| `plot` | `FALSE` | TRUE 请求附带图；没有有限估计时警告并返回 plot = NULL，仍保留诊断。 | Include a plot when TRUE; if no finite estimates are available, warn and return plot = NULL while retaining diagnostics. |
| `line_size` | `NULL` | NULL 继承全局 line_size，显式值优先。 | NULL inherits global line_size; explicit values take priority. |
| `point_size` | `NULL` | 点大小；NULL 继承全局 point_size（默认 2.5）。 | Numeric or NULL. NULL inherits the global point_size setting (default 2.5). |
| `point_shape` | `21` | 点形状编号，如 16、21。 | Numeric. Point shape for endpoints. Default is 21. |
| `facet_scales` | `"free"` | fixed、free、free_x 或 free_y；自由尺度有助观察组内变化。 | Character. Facet scales argument. Default is "free". |
| `facet_ncol` | `NULL` | 分面排列的列数。 | Integer or NULL. Number of facet columns. |
| `facet_nrow` | `NULL` | 分面排列的行数。 | Integer or NULL. Number of facet rows. |
| `train_times` | `1` | 每个初始点连续优化的次数。 | Number of successive optimization passes per start; not independent random starts. |
| `title` | `NULL` | 自定义图标题；NULL 继承默认。 | Character or NULL. Custom plot title. |
| `xlab` | `NULL` | 坐标轴标签；主题设置函数中使用命名列表。 | Character or NULL. Custom x-axis label. |
| `ylab` | `NULL` | 坐标轴标签；主题设置函数中使用命名列表。 | Character or NULL. Custom y-axis label. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character or NULL. Font family. |
| `title_size` | `NULL` | 图标题字号。 | Numeric or NULL. Title size in pt. |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector or NULL. Custom x-axis breaks. |
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character or NULL. Base ggplot2 theme name. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment. |
| `rho_digits` | `4` | Mohn rho 显示的小数位数。 | Integer. Decimal places for Mohn's rho display. Default is 4. |
| `rho_position` | `"top_right"` | Mohn rho 标注位置。 | Character. Position of rho text. Default is "top_right". |
| `rho_size` | `3.5` | Mohn rho 标注字号。 | Numeric. Font size of rho text. Default is 3.5. |
| `ncores` | `1` | 独立回溯拟合的最大并行工作进程数；1 为顺序执行。 | Maximum workers across independent retrospective peels; 1 runs sequentially. |
| `...` | 可选 / optional | 转发参数；仅使用目标函数接受的命名参数。 | Additional arguments passed to retro_model(). |

**返回 / Returns:** 列表包含 results（各次回溯轨迹）、last_points（各轨迹末点）、rho_by_peel（逐次回溯的相对差异）、rho_text（通过数值筛查后汇总的 Mohn's rho）和 raw_rho_text（未筛查的描述性汇总）。fit_diagnostics 与 errors 保留逐次拟合状态和错误；model_type、workers、nstarts 记录模型与计算设置。plot=TRUE 时另返回 plot 对象；无有效估计可绘制时 plot 为 NULL。

A list with results (peel trajectories), last_points (terminal estimates), rho_by_peel (relative differences by peel), rho_text (numerically screened Mohn's rho) and raw_rho_text (unscreened descriptive summaries). fit_diagnostics and errors retain fit status and errors. model_type, workers and nstarts record model and computation settings. With plot=TRUE, plot contains the plot object, or NULL when no finite estimates can be drawn.

**诊断 / Diagnostics:** 支持同一份拟合 x，显式设置优先；原逐项参数和 do.call 写法保留。fit_diagnostics 保留完整拟合及每轮状态。若任何要求的拟合未通过数值筛查，或末端差无定义，rho_text 的相应 Rho 为 NA 并警告；rho_by_peel、raw_rho_text 和 errors 保留追查记录。 / Accepts the fitting bundle with explicit overrides and preserves legacy calls. fit_diagnostics retains the full fit and all peels. Any failed requested numerical screen or undefined terminal difference makes the corresponding authoritative rho NA with a warning; rho_by_peel, raw_rho_text and errors retain exploratory records.

当全部回溯拟合失败或没有有限轨迹时，`plot = TRUE` 会警告并返回 `plot = NULL`，同时保留 `fit_diagnostics`、`errors` 及不可用的 rho。应根据这些字段修正输入或拟合设置。请求绘图不再阻止读取失败记录。

When all retrospective fits fail or no finite trajectories remain, `plot = TRUE` now warns and returns `plot = NULL` while preserving `fit_diagnostics`, `errors` and the unavailable rho values. Inspect those fields to correct the input or fitting problem. Requesting a plot must not prevent access to the failure record.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
ra <- retro_acl(x, nyear = 3)
ra$fit_diagnostics
ra$rho_text
```

![示例图 / Example figure: `plot_retro(retro_acl(x, nyear = 3), facet_ncol = 2)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ACL.png?raw=true&v=a6c651d2e0de)

<a id="retro_alscl"></a>
## `retro_alscl()`

ALSCL 回溯入口 / ALSCL retrospective wrapper

回溯子拟合会随保留时期同步截短 `map$dev_log_R` 与 `map$dev_log_F`。请提供完整数据长度的映射：补充量每期一项；F 按组别×时期矩阵的列顺序排列，ACL 使用年龄组、ALSCL 使用体长组，`F_structure = "year"` 只有一组。因子共享关系和固定的 NA 项会保留；完整映射长度错误会明确报错。标量映射及 `dev_log_N0` 不随回溯截短。

Retrospective peels shorten time-dependent `map$dev_log_R` and `map$dev_log_F` with the retained periods. Supply maps for the full dataset: recruitment uses one entry per period; F uses group-by-time column order (age groups for ACL, length groups for ALSCL, one group for `F_structure = "year"`). Factor ties and fixed NA entries are retained. Invalid full-data map lengths are rejected. Scalar maps and `dev_log_N0` do not change with a peel.

```r
retro_alscl (nyear = 5, data.CatL, data.wgt, data.mat, rec.age, nage, M, sel_L50, sel_L95,
    growth_step = NULL, ...)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `nyear` | `5` | 模拟器为总年数；回溯函数为删除的末端时间步数。 | Number of terminal observation steps peeled, not calendar years for quarterly data. |
| `data.CatL` | `必填 / required` | 原拟合使用的调查数量指数表（首列体长标签，其余列为模型时期），或完整拟合输入列表。 | The original survey numbers-at-length or index table (length labels followed by model periods), or a complete fitting input bundle. |
| `data.wgt` | `必填 / required` | 平均单尾体重表，与调查表完全对齐。 | The weight data. |
| `data.mat` | `必填 / required` | 成熟比例表，0–1，与调查表完全对齐。 | The maturity data. |
| `rec.age` | `必填 / required` | 补充年龄，单位为年。 | The recruitment age. |
| `nage` | `必填 / required` | 年龄组数量，包括最大年龄加组。 | The number of age classes. |
| `M` | `必填 / required` | 每个模型时间步的自然死亡瞬时率。 | The natural mortality rate. |
| `sel_L50` | `必填 / required` | 调查可捕性达到 0.5 的体长。 | Length at survey catchability 0.5. |
| `sel_L95` | `必填 / required` | 调查可捕性达到 0.95 的体长，必须大于 sel_L50。 | Length at survey catchability 0.95, greater than sel_L50. |
| `growth_step` | `NULL` | 每个时间步包含的年数；NULL 时 rec.age<1 取 rec.age、否则取 1；季度为 0.25。 | Time step in years. NULL uses rec.age when it is below one, otherwise one, as in run_alscl(); a bundle supplies its own value. |
| `...` | 可选 / optional | 转发参数；仅使用目标函数接受的命名参数。 | Additional arguments passed to retro_model(). |

**返回 / Returns:** 列表包含 results（各次回溯轨迹）、last_points（各轨迹末点）、rho_by_peel（逐次回溯的相对差异）、rho_text（通过数值筛查后汇总的 Mohn's rho）和 raw_rho_text（未筛查的描述性汇总）。fit_diagnostics 与 errors 保留逐次拟合状态和错误；model_type、workers、nstarts 记录模型与计算设置。plot=TRUE 时另返回 plot 对象；无有效估计可绘制时 plot 为 NULL。

A list with results (peel trajectories), last_points (terminal estimates), rho_by_peel (relative differences by peel), rho_text (numerically screened Mohn's rho) and raw_rho_text (unscreened descriptive summaries). fit_diagnostics and errors retain fit status and errors. model_type, workers and nstarts record model and computation settings. With plot=TRUE, plot contains the plot object, or NULL when no finite estimates can be drawn.

**诊断 / Diagnostics:** 支持同一份拟合 x，显式设置优先；原逐项参数和 do.call 写法保留。fit_diagnostics 保留完整拟合及每轮状态。若任何要求的拟合未通过数值筛查，或末端差无定义，rho_text 的相应 Rho 为 NA 并警告；rho_by_peel、raw_rho_text 和 errors 保留追查记录。 / Accepts the fitting bundle with explicit overrides and preserves legacy calls. fit_diagnostics retains the full fit and all peels. Any failed requested numerical screen or undefined terminal difference makes the corresponding authoritative rho NA with a warning; rho_by_peel, raw_rho_text and errors retain exploratory records.

当全部回溯拟合失败或没有有限轨迹时，`plot = TRUE` 会警告并返回 `plot = NULL`，同时保留 `fit_diagnostics`、`errors` 及不可用的 rho。应根据这些字段修正输入或拟合设置。请求绘图不再阻止读取失败记录。

When all retrospective fits fail or no finite trajectories remain, `plot = TRUE` now warns and returns `plot = NULL` while preserving `fit_diagnostics`, `errors` and the unavailable rho values. Inspect those fields to correct the input or fitting problem. Requesting a plot must not prevent access to the failure record.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
rb <- retro_alscl(x, nyear = 3)
rb$fit_diagnostics
rb$rho_text
```

![示例图 / Example figure: `plot_retro(retro_alscl(x, nyear = 3), facet_ncol = 2)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ALSCL.png?raw=true&v=a15f447d44dc)

<a id="retro_model"></a>
## `retro_model()`

统一回溯分析 / Unified retrospective analysis

回溯子拟合会随保留时期同步截短 `map$dev_log_R` 与 `map$dev_log_F`。请提供完整数据长度的映射：补充量每期一项；F 按组别×时期矩阵的列顺序排列，ACL 使用年龄组、ALSCL 使用体长组，`F_structure = "year"` 只有一组。因子共享关系和固定的 NA 项会保留；完整映射长度错误会明确报错。标量映射及 `dev_log_N0` 不随回溯截短。

Retrospective peels shorten time-dependent `map$dev_log_R` and `map$dev_log_F` with the retained periods. Supply maps for the full dataset: recruitment uses one entry per period; F uses group-by-time column order (age groups for ACL, length groups for ALSCL, one group for `F_structure = "year"`). Factor ties and fixed NA entries are retained. Invalid full-data map lengths are rejected. Scalar maps and `dev_log_N0` do not change with a peel.

```r
retro_model (nyear = 5, data.CatL, data.wgt, data.mat, rec.age, nage, M, sel_L50, sel_L95,
    model_type = c("acl", "alscl"), growth_step = NULL, parameters = NULL, parameters.L = NULL,
    parameters.U = NULL, map = NULL, len_mid = NULL, len_border = NULL, len_lower = NULL,
    len_upper = NULL, train_times = 1, ncores = 1, silent = FALSE, plot = FALSE,
    line_size = NULL, point_size = NULL, point_shape = 21, facet_scales = "free",
    facet_ncol = NULL, facet_nrow = NULL, title = NULL, xlab = NULL, ylab = NULL,
    font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL,
    strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL,
    title_hjust = NULL, rho_digits = 4, rho_position = "top_right", rho_size = 3.5,
    F_structure = c("group_year", "year"), polish = TRUE, zero_action = c("missing",
        "error"), control = list(), nstarts = 1, model = NULL, ...)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `nyear` | `5` | 模拟器为总年数；回溯函数为删除的末端时间步数。 | Number of terminal observation steps peeled, not calendar years for quarterly data. |
| `data.CatL` | `必填 / required` | 原拟合使用的调查数量指数表（首列体长标签，其余列为模型时期），或完整拟合输入列表。 | The original survey numbers-at-length or index table (length labels followed by model periods), or a complete fitting input bundle. |
| `data.wgt` | `必填 / required` | 平均单尾体重表，与调查表完全对齐。 | The weight data. |
| `data.mat` | `必填 / required` | 成熟比例表，0–1，与调查表完全对齐。 | The maturity data. |
| `rec.age` | `必填 / required` | 补充年龄，单位为年。 | The recruitment age. |
| `nage` | `必填 / required` | 年龄组数量，包括最大年龄加组。 | The number of age classes. |
| `M` | `必填 / required` | 每个模型时间步的自然死亡瞬时率。 | The natural mortality rate. |
| `sel_L50` | `必填 / required` | 调查可捕性达到 0.5 的体长。 | Length at survey catchability 0.5. |
| `sel_L95` | `必填 / required` | 调查可捕性达到 0.95 的体长，必须大于 sel_L50。 | Length at survey catchability 0.95, greater than sel_L50. |
| `model_type` | `c("acl", "alscl")` | 模型选择：acl 或 alscl。 | Character. Model to use: "acl" (default) or "alscl". |
| `growth_step` | `NULL` | 每个时间步包含的年数；季度为 0.25。 | Time step in years. NULL uses recruitment age when below 1, otherwise 1. |
| `parameters` | `NULL` | 命名参数初值列表，采用优化器尺度。 | Optional custom starting parameter list. |
| `parameters.L` | `NULL` | 命名下界列表，采用优化器尺度。 | Optional lower bounds for parameters. |
| `parameters.U` | `NULL` | 命名上界列表，采用优化器尺度。 | Optional upper bounds for parameters. |
| `map` | `NULL` | TMB 映射；factor(NA) 固定，具名 NULL 项释放该项；整个 map=NULL 则使用模型默认固定规则。 | Optional TMB map argument for fixing parameters. |
| `len_mid` | `NULL` | 每个体长组的中心值向量，长度与数据行数相同。 | Optional numeric vector of length bin midpoints. |
| `len_border` | `NULL` | 体长边界；拟合入口需要 nlen-1 个内部边界，模拟器使用 nlen+1 个完整边界。 | Optional numeric vector of length bin borders. |
| `len_lower` | `NULL` | ALSCL 每组下界；首项必须为 `-Inf`，其余项须等于内部边界。 | ALSCL lower bounds: first entry must be `-Inf`; remaining entries must match internal boundaries. |
| `len_upper` | `NULL` | ALSCL 每组上界；末项必须为 `Inf`，其余项须等于内部边界。 | ALSCL upper bounds: final entry must be `Inf`; preceding entries must match internal boundaries. |
| `train_times` | `1` | 每个初始点连续优化的次数。 | Number of successive optimization passes per start; not independent random starts. |
| `ncores` | `1` | 显式指定并行回溯轮数；不沿用 x 内拟合用的 ncores，各轮拟合单进程。 | Explicit peel workers; stored fitting ncores is ignored, and each fit uses one fitting worker. |
| `silent` | `FALSE` | TRUE 减少拟合进度输出。 | Logical. If TRUE, suppress all progress messages. Default is FALSE. |
| `plot` | `FALSE` | TRUE 请求附带图；没有有限估计时警告并返回 plot = NULL，仍保留诊断。 | Include a plot when TRUE; if no finite estimates are available, warn and return plot = NULL while retaining diagnostics. |
| `line_size` | `NULL` | NULL 继承全局 line_size，显式值优先。 | NULL inherits global line_size; explicit values take priority. |
| `point_size` | `NULL` | 点大小；NULL 继承全局 point_size（默认 2.5）。 | Numeric or NULL. NULL inherits the global point_size setting (default 2.5). |
| `point_shape` | `21` | 点形状编号，如 16、21。 | Numeric. Point shape for endpoints. Default is 21. |
| `facet_scales` | `"free"` | fixed、free、free_x 或 free_y；自由尺度有助观察组内变化。 | Character. Facet scales argument. Default is "free". |
| `facet_ncol` | `NULL` | 分面排列的列数。 | Integer or NULL. Number of facet columns. |
| `facet_nrow` | `NULL` | 分面排列的行数。 | Integer or NULL. Number of facet rows. |
| `title` | `NULL` | 自定义图标题；NULL 继承默认。 | Character or NULL. Custom plot title. |
| `xlab` | `NULL` | 坐标轴标签；主题设置函数中使用命名列表。 | Character or NULL. Custom x-axis label. |
| `ylab` | `NULL` | 坐标轴标签；主题设置函数中使用命名列表。 | Character or NULL. Custom y-axis label. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character or NULL. Font family. |
| `title_size` | `NULL` | 图标题字号。 | Numeric or NULL. Title size in pt. |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector or NULL. Custom x-axis breaks. |
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character or NULL. Base ggplot2 theme name. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment. |
| `rho_digits` | `4` | Mohn rho 显示的小数位数。 | Integer. Decimal places for Mohn's rho display. Default is 4. |
| `rho_position` | `"top_right"` | Mohn rho 标注位置。 | Character. Position of rho text. Default is "top_right". |
| `rho_size` | `3.5` | Mohn rho 标注字号。 | Numeric. Font size of rho text. Default is 3.5. |
| `F_structure` | `c("group_year", "year")` | 默认二维组别 × 时间；year 为每期共用的一维 F 过程，组别相关自动排除。 | Original group-by-time AR1 field or one shared F per step with a 1D AR1 density. |
| `polish` | `TRUE` | 默认对所选拟合进行受保护的 Newton 收尾；FALSE 跳过。原始优化代码保留。 | Safeguarded refinement of the selected fit; retain raw optimizer codes and inspect refinement and diagnostics. |
| `zero_action` | `c("missing", "error")` | 各轮对零观测的处理；NA 始终缺失。 | Zero handling forwarded to every fit; NA is always missing. |
| `control` | `list()` | 各轮 nlminb 优化控制；显式列表整体覆盖。 | nlminb controls forwarded to each fit; explicit lists replace stored lists. |
| `nstarts` | `1` | 每轮独立起点数，在该轮内部依次计算；可沿用 x 设置。 | Starts per fit, run sequentially within a peel; may inherit the bundle value. |
| `model` | `NULL` | 与 model_type 相同，为与其他工作流函数一致而提供；两者只填一个。 | Same as model_type, accepted for consistency with the other workflow functions. Supply one of the two. |
| `...` | 可选 / optional | 旧参数名 facet_col、facet_row，仍可使用但会给出警告。 | The former argument names facet_col and facet_row, accepted with a warning. |

**返回 / Returns:** 列表包含 results（各次回溯轨迹）、last_points（各轨迹末点）、rho_by_peel（逐次回溯的相对差异）、rho_text（通过数值筛查后汇总的 Mohn's rho）和 raw_rho_text（未筛查的描述性汇总）。fit_diagnostics 与 errors 保留逐次拟合状态和错误；model_type、workers、nstarts 记录模型与计算设置。plot=TRUE 时另返回 plot 对象；无有效估计可绘制时 plot 为 NULL。

A list with results (peel trajectories), last_points (terminal estimates), rho_by_peel (relative differences by peel), rho_text (numerically screened Mohn's rho) and raw_rho_text (unscreened descriptive summaries). fit_diagnostics and errors retain fit status and errors. model_type, workers and nstarts record model and computation settings. With plot=TRUE, plot contains the plot object, or NULL when no finite estimates can be drawn.

**诊断 / Diagnostics:** 支持同一份拟合 x，显式设置优先；原逐项参数和 do.call 写法保留。fit_diagnostics 保留完整拟合及每轮状态。若任何要求的拟合未通过数值筛查，或末端差无定义，rho_text 的相应 Rho 为 NA 并警告；rho_by_peel、raw_rho_text 和 errors 保留追查记录。 / Accepts the fitting bundle with explicit overrides and preserves legacy calls. fit_diagnostics retains the full fit and all peels. Any failed requested numerical screen or undefined terminal difference makes the corresponding authoritative rho NA with a warning; rho_by_peel, raw_rho_text and errors retain exploratory records.

当全部回溯拟合失败或没有有限轨迹时，`plot = TRUE` 会警告并返回 `plot = NULL`，同时保留 `fit_diagnostics`、`errors` 及不可用的 rho。应根据这些字段修正输入或拟合设置。请求绘图不再阻止读取失败记录。

When all retrospective fits fail or no finite trajectories remain, `plot = TRUE` now warns and returns `plot = NULL` while preserving `fit_diagnostics`, `errors` and the unavailable rho values. Inspect those fields to correct the input or fitting problem. Requesting a plot must not prevent access to the failure record.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
rb <- retro_model(data.CatL = x, model_type = "alscl", nyear = 3)
rb$fit_diagnostics
rb$rho_by_peel
rb$rho_text
```

![示例图 / Example figure: `plot_retro(retro_model(x, nyear = 3, model = "alscl"), facet_ncol = 2)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ALSCL.png?raw=true&v=a15f447d44dc)

<a id="run_acl"></a>
## `run_acl()`

ALSCL 2.2.0 accepts `run_acl(x)` and `run_alscl(x)` directly. For `YTF_example`, each function selects its model-specific `fit_config` automatically; explicit call arguments override stored settings. The original separate-argument and `do.call()` forms remain valid. Both use the same built-in acceleration; inspect `a$sd_info` or `b$sd_info` for actual execution.

```r
run_acl (data.CatL, data.wgt, data.mat, rec.age, nage, M, sel_L50, sel_L95, parameters = NULL,
    parameters.L = NULL, parameters.U = NULL, map = NULL, len_mid = NULL, len_border = NULL,
    output = FALSE, train_times = 1, ncores = 1, silent = FALSE, growth_step = NULL,
    zero_action = c("missing", "error"), control = list(), nstarts = ncores, F_structure = c("group_year",
        "year"), polish = TRUE)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `data.CatL` | `必填 / required` | 调查数量指数表，或包含三表及拟合设置的命名列表（如 YTF_example）。 | Data frame or matrix with length labels in its first column, followed by at least two numerically labelled time columns. Alternatively, a named input bundle such as YTF_example. |
| `data.wgt` | `必填 / required` | 平均单尾体重表，与调查表完全对齐。 | Weight-at-length, with identical labels, columns and dimensions. |
| `data.mat` | `必填 / required` | 成熟比例表，0–1，与调查表完全对齐。 | Maturity-at-length between 0 and 1, with the same layout. |
| `rec.age` | `必填 / required` | 补充年龄，单位为年。 | Recruitment age in years, greater than t0. |
| `nage` | `必填 / required` | 年龄组数量，包括最大年龄加组。 | Number of age classes including the plus group (at least two). |
| `M` | `必填 / required` | 每个模型时间步的自然死亡瞬时率。 | Nonnegative natural mortality per model time step. |
| `sel_L50` | `必填 / required` | 调查可捕性达到 50% 的体长。 | Lengths at 50 and 95 percent survey catchability. |
| `sel_L95` | `必填 / required` | 调查可捕性达到 95% 的体长，必须大于 L50。 | Lengths at 50 and 95 percent survey catchability. |
| `parameters` | `NULL` | 命名参数初值列表，采用优化器尺度。 | Named list of initial fixed-effect values. |
| `parameters.L` | `NULL` | 命名下界列表，采用优化器尺度。 | Named lower and upper bounds. Bounds are aligned with free parameters after applying map. Initial free values are clamped to bounds. |
| `parameters.U` | `NULL` | 命名上界列表，采用优化器尺度。 | Named lower and upper bounds. Bounds are aligned with free parameters after applying map. Initial free values are clamped to bounds. |
| `map` | `NULL` | TMB 映射；factor(NA) 固定，具名 NULL 项释放该项；整个 map=NULL 则使用模型默认固定规则。 | Named TMB factor mappings. factor(NA) fixes a parameter at its supplied value; a named NULL entry releases that parameter. A whole map = NULL or list() applies model defaults. Other unspecified defaults remain in force. |
| `len_mid` | `NULL` | 每个体长组的中心值向量，长度与数据行数相同。 | Finite length-bin midpoints; overrides automatic parsing. |
| `len_border` | `NULL` | 体长边界；拟合入口需要 nlen-1 个内部边界，模拟器使用 nlen+1 个完整边界。 | Interior boundaries, one fewer than the number of length bins. |
| `output` | `FALSE` | 是否导出拟合诊断与图；TRUE 使用 output 目录。 | Save diagnostic tables and plots below output/ when TRUE. |
| `train_times` | `1` | 每个初始点连续优化的次数。 | Number of successive optimization passes per start; not independent random starts. |
| `ncores` | `1` | 独立初始点拟合的最大并行进程数，实际不超过 nstarts；不是单个 TMB 拟合的线程数。 | Maximum socket workers across independent starts, capped at nstarts; not threads within one start. |
| `silent` | `FALSE` | TRUE 减少拟合进度输出。 | Suppress fitting progress messages when TRUE. |
| `growth_step` | `NULL` | 每个时间步包含的年数；NULL 时 rec.age<1 取 rec.age、否则取 1；季度为 0.25，时间标签间隔必须相同。 | Time between consecutive ages, in years; 0.25 for quarters. NULL uses rec.age when it is below one, otherwise one. Numeric time-column labels must have this spacing; keep missing periods as NA survey columns with weights and maturity for every period. |
| `zero_action` | `c("missing", "error")` | missing 排除调查零值；error 报错。NA 始终为缺失。 | Exclude zero observations as missing (historical behavior), or reject them with "error". NA is always missing; negative/infinite values fail. |
| `control` | `list()` | 传入 nlminb 的命名控制列表，如 iter.max、eval.max。 | A named list of nlminb control settings. |
| `nstarts` | `ncores` | 初始点总数；默认等于 ncores 以兼容旧用法。固定此值可公平比较不同并行数；后续起点仅扰动自由参数。 | Total independent starts; defaults to ncores for compatibility. Fix this value for equal-work comparisons. Later starts deterministically jitter free parameters only. |
| `F_structure` | `c("group_year", "year")` | 默认二维组别 × 时间；year 为每期共用的一维 F 过程，组别相关自动排除。 | Original group-by-time AR1 field or one shared F per step with a 1D AR1 density. |
| `polish` | `TRUE` | 默认对所选拟合进行受保护的 Newton 收尾；FALSE 跳过。原始优化代码保留。 | Safeguarded refinement of the selected fit; retain raw optimizer codes and inspect refinement and diagnostics. |

**返回 / Returns:** alscl_fit 类的列表，保留原有 $ 访问方式。report 保存种群量和调查预测；opt 保存所选优化参数、目标函数和原始状态；obj 是当前会话的 TMB 对象；est_std、vcov 和 pdHess 保存近似不确定性及 Hessian 状态。gradient、max_abs_gradient（亦为 final_outer_mgc）、convergence_code、bound_hit 和 diagnostics 用于数值检查。raw_opt、optimizer_history、refinement 保存优化与收尾记录。year、age、体长元数据、growth_step、F_structure 和 elapsed 记录坐标、结构及耗时；starts、start_diagnostics、nstarts 和 workers 记录各起点参数、PID、时间及计算量。recipe 保存重新拟合所需的完整输入与设置。多起点按最低有限目标函数选取，仍须另查数值状态；obj 只可在原会话动态库保持加载时求值。 sd_info 记录标准误的计算方式（方法、核数、耗时）。 / sd_info records how the standard errors were computed (method, cores, seconds).

A list of class alscl_fit, retaining existing $ access. report stores population quantities and survey predictions; opt stores the selected optimizer parameters, objective and raw status; obj is the session-specific TMB object; est_std, vcov and pdHess describe approximate uncertainty and Hessian status. gradient, max_abs_gradient (also final_outer_mgc), convergence_code, bound_hit and diagnostics support numerical checks. raw_opt, optimizer_history and refinement retain optimization records. year, age, length metadata, growth_step, F_structure and elapsed record coordinates, structure and timing. starts, start_diagnostics, nstarts and workers record starting values, PIDs, timestamps and work performed. recipe stores complete inputs and fitting settings. Selection uses the lowest finite objective; inspect numerical status separately. Evaluating obj requires the DLL to remain loaded in the fitting session.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
a <- run_acl(x)
```

**初值与固定 / Starts and fixes:** `parameters` 中的值仅为初值，除非 map 将该项固定。`map = NULL` / `list()` 恢复模型默认规则。ACL 默认固定 `log_std_log_F`、`logit_log_F_y`、`logit_log_F_a`、`t0`；ALSCL 默认固定 `log_sigma_log_F`、`log_t0`。具名 NULL 项（如 `list(log_sigma_log_F = NULL)`，仅 ALSCL）解除对应固定。`map["name"] <- list(NULL)` 保留解除指令，`map$name <- NULL` 则删除条目。

Parameters are estimated from their starting values unless fixed by the map. A whole NULL/empty map restores model defaults: four scalar fixes for ACL, two for ALSCL, as listed above. A named NULL entry releases that parameter. Keep it with single-bracket assignment; deleting the entry re-applies a default fix. See the complete [English](https://fanzhang-lab-shou.github.io/ALSCL/articles/case-fit-survey.html) / [简体中文](https://fanzhang-lab-shou.github.io/ALSCL/zh/articles/case-fit-survey.html) input checklist, parameter table and executable example.

<a id="run_alscl"></a>
## `run_alscl()`

ALSCL 2.2.0 accepts `run_acl(x)` and `run_alscl(x)` directly. For `YTF_example`, each function selects its model-specific `fit_config` automatically; explicit call arguments override stored settings. The original separate-argument and `do.call()` forms remain valid. Both use the same built-in acceleration; inspect `a$sd_info` or `b$sd_info` for actual execution.

```r
run_alscl (data.CatL, data.wgt, data.mat, rec.age, nage, M, sel_L50, sel_L95, growth_step = NULL,
    parameters = NULL, parameters.L = NULL, parameters.U = NULL, map = NULL, len_mid = NULL,
    len_border = NULL, len_lower = NULL, len_upper = NULL, output = FALSE, train_times = 1,
    ncores = 1, silent = FALSE, zero_action = c("missing", "error"), control = list(),
    nstarts = ncores, F_structure = c("group_year", "year"), polish = TRUE)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `data.CatL` | `必填 / required` | 调查数量指数表，或包含三表及拟合设置的命名列表（如 YTF_example）。 | Data frame or matrix with length labels in its first column, followed by at least two numerically labelled time columns. Alternatively, a named input bundle such as YTF_example. |
| `data.wgt` | `必填 / required` | 平均单尾体重表，与调查表完全对齐。 | Weight-at-length, with identical labels, columns and dimensions. |
| `data.mat` | `必填 / required` | 成熟比例表，0–1，与调查表完全对齐。 | Maturity-at-length between 0 and 1, with the same layout. |
| `rec.age` | `必填 / required` | 补充年龄，单位为年。 | Recruitment age in years, greater than t0. |
| `nage` | `必填 / required` | 年龄组数量，包括最大年龄加组。 | Number of age classes including the plus group (at least two). |
| `M` | `必填 / required` | 每个模型时间步的自然死亡瞬时率。 | Nonnegative natural mortality per model time step. |
| `sel_L50` | `必填 / required` | 调查可捕性达到 50% 的体长。 | Lengths at 50 and 95 percent survey catchability. |
| `sel_L95` | `必填 / required` | 调查可捕性达到 95% 的体长，必须大于 L50。 | Lengths at 50 and 95 percent survey catchability. |
| `growth_step` | `NULL` | 每个时间步包含的年数；NULL 时 rec.age<1 取 rec.age、否则取 1；季度为 0.25，时间标签间隔必须相同。 | Time between consecutive ages, in years; 0.25 for quarters. NULL uses rec.age when it is below one, otherwise one. Numeric time-column labels must have this spacing; keep missing periods as NA survey columns with weights and maturity for every period. |
| `parameters` | `NULL` | 命名参数初值列表，采用优化器尺度。 | Named list of initial fixed-effect values. |
| `parameters.L` | `NULL` | 命名下界列表，采用优化器尺度。 | Named lower and upper bounds. Bounds are aligned with free parameters after applying map. Initial free values are clamped to bounds. |
| `parameters.U` | `NULL` | 命名上界列表，采用优化器尺度。 | Named lower and upper bounds. Bounds are aligned with free parameters after applying map. Initial free values are clamped to bounds. |
| `map` | `NULL` | TMB 映射；factor(NA) 固定，具名 NULL 项释放该项；整个 map=NULL 则使用模型默认固定规则。 | Named TMB factor mappings. factor(NA) fixes a parameter at its supplied value; a named NULL entry releases that parameter. A whole map = NULL or list() applies model defaults. Other unspecified defaults remain in force. |
| `len_mid` | `NULL` | 每个体长组的中心值向量，长度与数据行数相同。 | Finite length-bin midpoints; overrides automatic parsing. |
| `len_border` | `NULL` | 体长边界；拟合入口需要 nlen-1 个内部边界，模拟器使用 nlen+1 个完整边界。 | Interior boundaries, one fewer than the number of length bins. |
| `len_lower` | `NULL` | ALSCL 每组下界；首项必须为 `-Inf`，其余项须等于内部边界。 | ALSCL lower bounds: first entry must be `-Inf`; remaining entries must match internal boundaries. |
| `len_upper` | `NULL` | ALSCL 每组上界；末项必须为 `Inf`，其余项须等于内部边界。 | ALSCL upper bounds: final entry must be `Inf`; preceding entries must match internal boundaries. |
| `output` | `FALSE` | 是否导出拟合诊断与图；TRUE 使用 output 目录。 | Save diagnostic tables and plots below output/ when TRUE. |
| `train_times` | `1` | 每个初始点连续优化的次数。 | Number of successive optimization passes per start; not independent random starts. |
| `ncores` | `1` | 独立初始点拟合的最大并行进程数，实际不超过 nstarts；不是单个 TMB 拟合的线程数。 | Maximum socket workers across independent starts, capped at nstarts; not threads within one start. |
| `silent` | `FALSE` | TRUE 减少拟合进度输出。 | Suppress fitting progress messages when TRUE. |
| `zero_action` | `c("missing", "error")` | missing 排除调查零值；error 报错。NA 始终为缺失。 | Exclude zero observations as missing (historical behavior), or reject them with "error". NA is always missing; negative/infinite values fail. |
| `control` | `list()` | 传入 nlminb 的命名控制列表，如 iter.max、eval.max。 | A named list of nlminb control settings. |
| `nstarts` | `ncores` | 初始点总数；默认等于 ncores 以兼容旧用法。固定此值可公平比较不同并行数；后续起点仅扰动自由参数。 | Total independent starts; defaults to ncores for compatibility. Fix this value for equal-work comparisons. Later starts deterministically jitter free parameters only. |
| `F_structure` | `c("group_year", "year")` | 默认二维组别 × 时间；year 为每期共用的一维 F 过程，组别相关自动排除。 | Original group-by-time AR1 field or one shared F per step with a 1D AR1 density. |
| `polish` | `TRUE` | 默认对所选拟合进行受保护的 Newton 收尾；FALSE 跳过。原始优化代码保留。 | Safeguarded refinement of the selected fit; retain raw optimizer codes and inspect refinement and diagnostics. |

**返回 / Returns:** alscl_fit 类的列表，保留原有 $ 访问方式。report 保存种群量和调查预测；opt 保存所选优化参数、目标函数和原始状态；obj 是当前会话的 TMB 对象；est_std、vcov 和 pdHess 保存近似不确定性及 Hessian 状态。gradient、max_abs_gradient（亦为 final_outer_mgc）、convergence_code、bound_hit 和 diagnostics 用于数值检查。raw_opt、optimizer_history、refinement 保存优化与收尾记录。year、age、体长元数据、growth_step、F_structure 和 elapsed 记录坐标、结构及耗时；starts、start_diagnostics、nstarts 和 workers 记录各起点参数、PID、时间及计算量。recipe 保存重新拟合所需的完整输入与设置。多起点按最低有限目标函数选取，仍须另查数值状态；obj 只可在原会话动态库保持加载时求值。 sd_info 记录标准误的计算方式（方法、核数、耗时）。 / sd_info records how the standard errors were computed (method, cores, seconds).

A list of class alscl_fit, retaining existing $ access. report stores population quantities and survey predictions; opt stores the selected optimizer parameters, objective and raw status; obj is the session-specific TMB object; est_std, vcov and pdHess describe approximate uncertainty and Hessian status. gradient, max_abs_gradient (also final_outer_mgc), convergence_code, bound_hit and diagnostics support numerical checks. raw_opt, optimizer_history and refinement retain optimization records. year, age, length metadata, growth_step, F_structure and elapsed record coordinates, structure and timing. starts, start_diagnostics, nstarts and workers record starting values, PIDs, timestamps and work performed. recipe stores complete inputs and fitting settings. Selection uses the lowest finite objective; inspect numerical status separately. Evaluating obj requires the DLL to remain loaded in the fitting session.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
b <- run_alscl(x)
```

**初值与固定 / Starts and fixes:** `parameters` 中的值仅为初值，除非 map 将该项固定。`map = NULL` / `list()` 恢复模型默认规则。ACL 默认固定 `log_std_log_F`、`logit_log_F_y`、`logit_log_F_a`、`t0`；ALSCL 默认固定 `log_sigma_log_F`、`log_t0`。具名 NULL 项（如 `list(log_sigma_log_F = NULL)`，仅 ALSCL）解除对应固定。`map["name"] <- list(NULL)` 保留解除指令，`map$name <- NULL` 则删除条目。

Parameters are estimated from their starting values unless fixed by the map. A whole NULL/empty map restores model defaults: four scalar fixes for ACL, two for ALSCL, as listed above. A named NULL entry releases that parameter. Keep it with single-bracket assignment; deleting the entry re-applies a default fix. See the complete [English](https://fanzhang-lab-shou.github.io/ALSCL/articles/case-fit-survey.html) / [简体中文](https://fanzhang-lab-shou.github.io/ALSCL/zh/articles/case-fit-survey.html) input checklist, parameter table and executable example.

<a id="sim_acl"></a>
## `sim_acl()`

批量拟合 ACL 模拟重复 / Fit simulated replicates with ACL

`sim_acl()` 将每次重复的结果（包括失败状态）保存到 `result_rep_<iter>`。复用输出目录时，本轮失败记录会替换旧成功结果；汇总前检查 `converge` 和 `error`。写入失败会明确报告，不能视为已经保存。`simulation_to_tables(sm, pa)` 使用模拟结果的长度坐标，并拒绝与参数不一致的坐标，不再给观测重新贴错标签；没有坐标的旧模拟可使用匹配的参数元数据。

`sim_acl()` saves the status of every replicate, including failures, to `result_rep_<iter>`. Reusing an output directory replaces an earlier success with the current failure record; inspect `converge` and `error` before summarizing results. Output write failures are reported and must not be treated as saved results. `simulation_to_tables(sm, pa)` uses the simulation length coordinates and rejects conflicting parameter coordinates instead of relabeling observations; legacy simulations without coordinates can use matching parameter metadata.

```r
sim_acl (iter_range = 4:100, sim_data_path = ".", output_dir = ".", parameters = NULL,
    parameters.L = NULL, parameters.U = NULL, map = NULL, M = 0.2, ncores = 1, train_times = 1,
    control = list(), F_structure = c("group_year", "year"), polish = TRUE, nstarts = 1)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `iter_range` | `4:100` | 互不重复的非负整数编号，包括 0；模拟时也用作随机种子。 | Distinct nonnegative integer replicate IDs, including 0; also used as simulation seeds. |
| `sim_data_path` | `"."` | 包含 sim_rep 文件的目录。 | A character string specifying the path to the folder containing the simulation data files (default is the current working directory). |
| `output_dir` | `"."` | 输出目录；必要时自动建立。 | Character, the directory where simulation results will be saved.(default is the current working directory). |
| `parameters` | `NULL` | 命名参数初值列表，采用优化器尺度。 | A list containing the custom initial values for the parameters (default is NULL). |
| `parameters.L` | `NULL` | 命名下界列表，采用优化器尺度。 | A list containing the custom lower bounds for the parameters (default is NULL). |
| `parameters.U` | `NULL` | 命名上界列表，采用优化器尺度。 | A list containing the custom upper bounds for the parameters (default is NULL). |
| `map` | `NULL` | TMB 映射；factor(NA) 固定，具名 NULL 项释放该项；整个 map=NULL 则使用模型默认固定规则。 | A list containing the custom values for the map elements (default is NULL). |
| `M` | `0.2` | 每个模型时间步的自然死亡瞬时率。 | Numeric, natural mortality (default: 0.2) |
| `ncores` | `1` | 独立模拟重复的最大 socket 工作进程数；1 为顺序执行，每次拟合内部使用单进程。 | Maximum socket workers across independent simulated replicates; 1 runs sequentially and each inner fit uses one worker. |
| `train_times` | `1` | 每个初始点连续优化的次数。 | Number of successive optimization passes per start; not independent random starts. |
| `control` | `list()` | 传入 nlminb 的命名控制列表，如 iter.max、eval.max。 | Named nlminb control settings. |
| `F_structure` | `c("group_year", "year")` | 默认二维组别 × 时间；year 为每期共用的一维 F 过程，组别相关自动排除。 | Original group-by-time AR1 field or one shared F per step with a 1D AR1 density. |
| `polish` | `TRUE` | 默认对所选拟合进行受保护的 Newton 收尾；FALSE 跳过。原始优化代码保留。 | Safeguarded refinement of the selected fit; retain raw optimizer codes and inspect refinement and diagnostics. |
| `nstarts` | `1` | 每个模拟重复的独立初值数，在重复内部依次运行；ncores 仍控制外层并行重复数。 | Independent starts per replicate, run sequentially; ncores still controls outer replicate workers. |

**返回 / Returns:** 按重复编号命名的拟合或错误记录列表（`result_rep_<id>`），包含 iter 和 elapsed。每次重复均写入对应文件，包括失败记录；失败项另含 converge="FAILED" 和 error。重跑失败会替换旧成功记录，文件写入失败会明确报告。

A named list of replicate fits or error records (`result_rep_<id>`), including iter and elapsed. Every replicate is written to its corresponding file, including failures; failed records also contain converge="FAILED" and error. A failed rerun replaces an earlier success record, and output-write failures are reported.

快速年度模拟器的 `mean_F` 等于生成 F 序列的算术平均值；`mean_F = 0` 生成零捕捞死亡率。

完整模拟器的 `nyear`、`burn_in` 都以年为单位，且分别必须对应整数个 `growth_step`。因此季度模式允许半年预热，年度模式不允许。返回的 `sm$nyear` 是保留时间步数；`first.year` 是第一期保留观测的年份，`sm$years` 保存完整观测时间轴。`simulation_to_tables()` 和 `sim_acl()` 保留这条时间轴；完全没有年份元数据的旧文件仍可使用从 2000 开始的后备规则。只保留一期时仍返回矩阵，但拟合至少需要两期。

`sim_acl()` 在发送 socket 任务前求值路径与参数变量，因此一般控制台或脚本中的变量传参也支持多核。保留失败重复并检查逐次拟合诊断；工作进程运行成功并不单独证明评估结果可用。

In the quick annual simulator, `mean_F` is the arithmetic mean of the generated F trajectory; `mean_F = 0` generates zero F.

For the full simulator, `nyear` and `burn_in` are durations in years and must each contain a whole number of `growth_step` intervals. Thus a half-year burn-in is valid with quarterly steps, but not annual steps. Returned `sm$nyear` counts retained steps. `first.year` labels the first retained observation, and `sm$years` records the complete retained calendar. `simulation_to_tables()` and `sim_acl()` preserve this calendar; old files lacking year metadata still have a documented 2000-based fallback. A single retained period stays a matrix, although fitting requires at least two periods.

`sim_acl()` resolves path and parameter variables before sending tasks to socket workers, so ordinary console/script calls work with multiple cores. Retain failed replicates and inspect each fit's diagnostics; successful worker execution alone does not establish a usable assessment.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
do.call(sim_acl, c(list(iter_range = 4:5,
  sim_data_path = "simulation_examples/flatfish",
  output_dir = "simulation_examples/fit", M = pa$M), x$fit_config$acl))
```

<a id="sim_cal"></a>
## `sim_cal()`

从参数计算生物矩阵 / Calculate biological arrays

```r
sim_cal (params)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `params` | `必填 / required` | initialize_params() 返回的完整模拟参数列表。 | A list of parameters from initialize_params(). Must contain model_type ("age_based" or "length_based") to determine which transition matrix to build. |

**返回 / Returns:** 生物数组列表：model_type 为生成模型结构；LatA 为平均年龄别体长；W_at_len 为体长别平均个体重量；mat 为成熟比例；q_surv 为调查可捕性；sel 为渔业选择性；pla 为给定年龄的体长概率矩阵。另含体长组坐标和边界；length_based 模型的 Gij 为体长组间一步生长转移矩阵，age_based 模型的 Gij 为 NULL。 另保留 biology_inputs，记录生成数组时采用的规范化生物学参数。

A list of biological arrays: model_type identifies the operating-model structure; LatA is mean length at age; W_at_len is individual weight at length; mat is maturity; q_surv is survey catchability; sel is fishery selectivity; pla is the matrix of length probabilities conditional on age. Length coordinates and bounds are included. Gij is the one-step length-growth transition matrix for length_based models and NULL for age_based models. The list also retains biology_inputs, the canonical biological parameters used to derive the arrays.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
bio <- sim_cal(pa)
```


`pla` 表示给定年龄的体长组概率。age_based 模拟器中行为年龄、列为体长组，每行和为 1；length_based 模拟器中行为体长组、列为年龄，每列和为 1。`Gij[i, j]` 则表示一个模型时间步内从源体长组 j 转入目标组 i 的概率，每列和为 1。修改生物参数后需重新调用 sim_cal()。

`pla` gives length-bin probabilities conditional on age. In the age_based simulator its rows are ages and columns are length bins (each row sums to one); in the length_based simulator its rows are length bins and columns are ages (each column sums to one). `Gij[i, j]` instead gives the probability of moving from source length bin j to destination bin i over one model step; each column sums to one. Call sim_cal() again after modifying biological parameters.


`sim_data()` 在抽取随机数或写文件前，同时核对来源参数和实际数组是否与 `sim_cal(params)` 一致。修改生长、年龄、时间步、体长组、重量、成熟、调查可捕性或渔业选择性后须重算生物学数组；不支持手动编辑数组。只修改死亡率、补充量、误差、模拟时长或日期，无须重算生物学数组。缺少 biology_inputs 的旧对象只要数组一致仍可使用。

`sim_data()` checks both these inputs and the actual arrays against `sim_cal(params)` before drawing random numbers or writing files. Recalculate biology after changing growth, ages, time step, bins, weight, maturity, catchability or fishery selectivity; editing arrays by hand is not supported. Changing only mortality, recruitment, error, simulation duration or calendar settings does not require recalculating biology. Legacy objects without biology_inputs remain valid when their arrays match.

<a id="sim_data"></a>
## `sim_data()`

The quick simulator now integrates the first and last length bins to negative and positive infinity, matching the fitted models. Finite `bin_breaks` still determine labels and midpoints; they do not truncate probability. Corrected simulations can change even with the same seed, especially when the first boundary excludes small fish. Previously saved datasets retain their original generating truth. Use nonnegative M, F and noise scales, positive growth parameters and a nonnegative weight coefficient, and increasing selectivity/maturity endpoints. Invalid parameters or nonfinite generated values stop before CSV files are created. The full simulator also requires normalized age-length keys and growth transitions.

```r
sim_data (bio_vars, params, sim_year = NULL, output_dir = ".", iter_range = 4:100,
    return_iter = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `bio_vars` | `必填 / required` | sim_cal() 返回的生物矩阵及生成模型类型。 | A list from sim_cal() containing biological variables. |
| `params` | `必填 / required` | initialize_params() 返回的完整模拟参数列表。 | A list from initialize_params() containing parameters. |
| `sim_year` | `NULL` | 模拟总年数；NULL 使用 params$nyear。 | Total simulation years; NULL uses params$nyear. |
| `output_dir` | `"."` | 输出目录；必要时自动建立。 | Directory for saving results (default: current directory). |
| `iter_range` | `4:100` | 互不重复的非负整数编号，包括 0；模拟时也用作随机种子。 | Distinct nonnegative integer replicate IDs, including 0; also used as simulation seeds. |
| `return_iter` | `NULL` | 在内存中返回的重复编号；NULL 默认选 iter_range 中的最大编号。 | Replicate ID to return in memory; NULL selects the largest ID in iter_range. |

**返回 / Returns:** 返回 return_iter 指定的重复结果；NULL 默认选择 iter_range 中的最大编号。结果包含调查数量 SN_at_len、种群体长别数量 N_at_len、年龄别数量 N_at_age、SSB、Rec、捕捞量及时间、年龄、体长等元数据。所有重复另以包含 sim.data 的 `sim_rep<id>` 文件写入 output_dir。

The replicate selected by return_iter; NULL selects the largest ID in iter_range. The result includes survey numbers SN_at_len, population numbers at length N_at_len and at age N_at_age, SSB, Rec, fishery catch, and time, age and length metadata. All replicates are also written to output_dir as `sim_rep<id>` files containing sim.data.

快速年度模拟器的 `mean_F` 等于生成 F 序列的算术平均值；`mean_F = 0` 生成零捕捞死亡率。

完整模拟器的 `nyear`、`burn_in` 都以年为单位，且分别必须对应整数个 `growth_step`。因此季度模式允许半年预热，年度模式不允许。返回的 `sm$nyear` 是保留时间步数；`first.year` 是第一期保留观测的年份，`sm$years` 保存完整观测时间轴。`simulation_to_tables()` 和 `sim_acl()` 保留这条时间轴；完全没有年份元数据的旧文件仍可使用从 2000 开始的后备规则。只保留一期时仍返回矩阵，但拟合至少需要两期。

`sim_acl()` 在发送 socket 任务前求值路径与参数变量，因此一般控制台或脚本中的变量传参也支持多核。保留失败重复并检查逐次拟合诊断；工作进程运行成功并不单独证明评估结果可用。

In the quick annual simulator, `mean_F` is the arithmetic mean of the generated F trajectory; `mean_F = 0` generates zero F.

For the full simulator, `nyear` and `burn_in` are durations in years and must each contain a whole number of `growth_step` intervals. Thus a half-year burn-in is valid with quarterly steps, but not annual steps. Returned `sm$nyear` counts retained steps. `first.year` labels the first retained observation, and `sm$years` records the complete retained calendar. `simulation_to_tables()` and `sim_acl()` preserve this calendar; old files lacking year metadata still have a documented 2000-based fallback. A single retained period stays a matrix, although fitting requires at least two periods.

`sim_acl()` resolves path and parameter variables before sending tasks to socket workers, so ordinary console/script calls work with multiple cores. Retain failed replicates and inspect each fit's diagnostics; successful worker execution alone does not establish a usable assessment.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
sm <- sim_data(bio, pa, iter_range = 4:5, return_iter = 4,
               output_dir = "simulation_examples/flatfish")
```

![示例图 / Example figure: `sim_data(sim_cal(pa), pa, iter_range = 4, return_iter = 4)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/cases/flatfish_truth.png?raw=true&v=dc74df7adeb3)

<a id="simulate_example_data"></a>
## `simulate_example_data()`

快速年度教学数据生成 / Generate simple annual teaching data

快速模拟器现在把首尾体长组分别积分到负无穷和正无穷，与拟合模型一致。有限 `bin_breaks` 仍用于标签与中点，不截断概率。修正后，即使种子相同，新模拟结果也可能改变，尤其是首边界排除了较小个体时；已保存数据仍保留原始生成真值。M、F 和噪声尺度必须非负，生长参数为正、重量系数非负，选择性及成熟曲线的 95% 端点高于 50% 端点。非法参数或非有限生成结果会在创建 CSV 前报错。完整模拟器还检查年龄—体长概率及生长转移概率的归一化。

The quick simulator now integrates the first and last length bins to negative and positive infinity, matching the fitted models. Finite `bin_breaks` still determine labels and midpoints; they do not truncate probability. Corrected simulations can change even with the same seed, especially when the first boundary excludes small fish. Previously saved datasets retain their original generating truth. Use nonnegative M, F and noise scales, positive growth parameters and a nonnegative weight coefficient, and increasing selectivity/maturity endpoints. Invalid parameters or nonfinite generated values stop before CSV files are created. The full simulator also requires normalized age-length keys and growth transitions.

```r
simulate_example_data (years = 2000:2025, bin_breaks = c(0, 20, 25, 30, 35, 40, 45, 50, 55, 60),
    Linf = 55, vbk = 0.45, t0 = -0.1, M = 0.8, nage = 7, L50_sel = 28, L95_sel = 36,
    L50_mat = 33, L95_mat = 40, wgt_a = 2.2e-06, wgt_b = 3.2, mean_F = 0.3, cv_catch = 0.3,
    rec_sigma = 0.5, seed = NULL, save_csv = FALSE, output_dir = ".")
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `years` | `2000:2025` | 年份向量；快速模拟器要求连续年度，比较图用它筛选时期。 | Numeric vector of years. Default 2000:2025. |
| `bin_breaks` | `c(0, 20, 25, 30, 35, 40, 45, 50, 55, 60)` | 递增完整边界向量，相邻边界定义一个长度组。 | Numeric vector of bin boundary points. Defines n+1 boundaries for n bins. Default c(0, 20, 25, 30, 35, 40, 45, 50, 55, 60) giving 9 bins: 0-20, 20-25, 25-30, ..., 55-60. Works with any bin width (1mm, 2mm, 3mm, 5mm, etc.) and unequal widths. |
| `Linf` | `55` | VB 渐近体长，与输入体长单位一致。 | Numeric. VB asymptotic length. Default 55. |
| `vbk` | `0.45` | VB 生长系数，以年为时间单位。 | Numeric. VB growth coefficient. Default 0.45. |
| `t0` | `-0.1` | VB 理论零体长年龄，单位为年。 | Numeric. VB theoretical age at length 0. Default -0.1. |
| `M` | `0.8` | 每个模型时间步的自然死亡瞬时率。 | Numeric. Natural mortality. Default 0.8. |
| `nage` | `7` | 年龄组数量，包括最大年龄加组。 | Integer. Maximum age (plus group). Default 7. |
| `L50_sel` | `28` | 调查可捕性达到 50% 的体长。 | Numeric. Length at survey catchability 0.5. Default 28. |
| `L95_sel` | `36` | 调查可捕性达到 95% 的体长，必须大于 L50。 | Numeric. Length at survey catchability 0.95. Default 36. |
| `L50_mat` | `33` | 成熟比例为 0.5 的体长。 | Numeric. Length at 50 percent maturity. Default 33. |
| `L95_mat` | `40` | 成熟比例为 0.95 的体长，必须大于 L50_mat。 | Numeric. Length at 95 percent maturity. Default 40. |
| `wgt_a` | `2.2e-06` | 长度重量关系 W=a*L^b 的系数，需匹配单位。 | Numeric. Weight-length parameter a in W = a * L^b. Default 2.2e-6. |
| `wgt_b` | `3.2` | 长度重量关系 W=a*L^b 的指数。 | Numeric. Weight-length parameter b in W = a * L^b. Default 3.2. |
| `mean_F` | `0.3` | 生成 F 轨迹的算术平均值，必须非负，零表示无捕捞。 | Nonnegative arithmetic mean of the generated F trajectory; zero gives zero fishing mortality. |
| `cv_catch` | `0.3` | 简易模拟调查误差的 CV，而非对数 SD。 | Numeric. CV of survey observation noise, not its log-scale SD. Default 0.3. |
| `rec_sigma` | `0.5` | 简易模拟对数补充扰动 SD。 | Numeric. SD of log-recruitment variation. Default 0.5. |
| `seed` | `NULL` | 随机种子；设定后可重复生成。 | Integer or NULL. Random seed for reproducibility. Default NULL (different result each run). Set e.g. seed = 42 for reproducible output. |
| `save_csv` | `FALSE` | TRUE 将生成的三张输入表写为 CSV。 | Logical. Save CSV files to working directory. Default FALSE. |
| `output_dir` | `"."` | 输出目录；必要时自动建立。 | Character. Directory for CSV output. Default ".". |

**返回 / Returns:** 列表包含 data.CatL（调查数量指数）、data.wgt（平均个体重量）、data.mat（成熟比例）三张对齐表，以及 true_params（生成时使用的参数及真值记录）。

A list with three aligned tables: data.CatL (survey numbers or indices), data.wgt (mean individual weights) and data.mat (mature proportions), plus true_params (generating parameters and truth records).

快速年度模拟器的 `mean_F` 等于生成 F 序列的算术平均值；`mean_F = 0` 生成零捕捞死亡率。

完整模拟器的 `nyear`、`burn_in` 都以年为单位，且分别必须对应整数个 `growth_step`。因此季度模式允许半年预热，年度模式不允许。返回的 `sm$nyear` 是保留时间步数；`first.year` 是第一期保留观测的年份，`sm$years` 保存完整观测时间轴。`simulation_to_tables()` 和 `sim_acl()` 保留这条时间轴；完全没有年份元数据的旧文件仍可使用从 2000 开始的后备规则。只保留一期时仍返回矩阵，但拟合至少需要两期。

`sim_acl()` 在发送 socket 任务前求值路径与参数变量，因此一般控制台或脚本中的变量传参也支持多核。保留失败重复并检查逐次拟合诊断；工作进程运行成功并不单独证明评估结果可用。

In the quick annual simulator, `mean_F` is the arithmetic mean of the generated F trajectory; `mean_F = 0` generates zero F.

For the full simulator, `nyear` and `burn_in` are durations in years and must each contain a whole number of `growth_step` intervals. Thus a half-year burn-in is valid with quarterly steps, but not annual steps. Returned `sm$nyear` counts retained steps. `first.year` labels the first retained observation, and `sm$years` records the complete retained calendar. `simulation_to_tables()` and `sim_acl()` preserve this calendar; old files lacking year metadata still have a documented 2000-based fallback. A single retained period stays a matrix, although fitting requires at least two periods.

`sim_acl()` resolves path and parameter variables before sending tasks to socket workers, so ordinary console/script calls work with multiple cores. Retain failed replicates and inspect each fit's diagnostics; successful worker execution alone does not establish a usable assessment.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
simulate_example_data(years = 2000:2019, seed = 42,
                      save_csv = TRUE, output_dir = "quick_simulation")
```

<a id="VB_func"></a>
## `VB_func()`

计算 VB 平均体长 / Calculate VB mean length

```r
VB_func (Linf, k, t0, age)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `Linf` | `必填 / required` | VB 渐近体长，与输入体长单位一致。 | The asymptotic length. |
| `k` | `必填 / required` | VB 生长系数，以年为时间单位。 | The growth coefficient. |
| `t0` | `必填 / required` | VB 理论零体长年龄，单位为年。 | The theoretical age at zero length. |
| `age` | `必填 / required` | 用于计算生长的年龄向量，单位为年。 | Age of the fish. |

**返回 / Returns:** 与 `age` 对应的平均体长数值向量。

A numeric vector of mean lengths, corresponding to `age`.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
VB_func(Linf = 60, k = 0.2, t0 = 1/60, age = 1:15)
```

<a id="estimation_parameters"></a>
## 初值列表内部可以改什么 / Inside estimation parameter lists

`parameters`、`parameters.L`、`parameters.U` 的键名如下。表中变换指从优化参数到自然尺度；初值和界限都要在优化尺度填写。`create_parameters()` 返回的三个命名列表就是传给拟合入口的同名参数。

The keys below apply to starting values and bounds. Transformations map optimizer values to the natural scale; enter starts and bounds on the optimizer scale. The constructor's three named components match the corresponding fit arguments.

| ACL 键名 / Key | ALSCL 键名 / Key | 变换 / Transform | 含义 / Meaning |
|---|---|---|---|
| `log_init_Z` | `log_init_Z` | exp | 初始平衡总死亡率 / Initial equilibrium total mortality |
| `log_std_log_N0` | `log_sigma_log_N0` | exp | 初始年龄尾数偏差 SD / Initial log-number deviation SD |
| `mean_log_R` | `mean_log_R` | exp | 对数补充过程的位置参数 / Location of the log recruitment process |
| `log_std_log_R` | `log_sigma_log_R` | exp | 对数补充过程 SD 缩放 / Log recruitment process SD scale |
| `logit_log_R` | `logit_log_R` | plogis | 补充 AR(1) 相关，限定 (0,1) / Recruitment correlation restricted to (0,1) |
| `mean_log_F` | `mean_log_F` | exp | 对数 F 过程的位置参数 / Location of the log F process |
| `log_std_log_F` | `log_sigma_log_F` | exp | F 偏差 SD 缩放 / F deviation SD scale |
| `logit_log_F_y` | `logit_log_F_y` | plogis | F 的时间相关 / Temporal F correlation |
| `logit_log_F_a` | `logit_log_F_l` | plogis | F 的年龄/体长相关 / Age/length F correlation |
| `log_vbk` | `log_vbk` | exp | VB k，单位为每年 / Annual VB k |
| `log_Linf` | `log_Linf` | exp | 渐近体长 / Asymptotic length |
| `t0` | `log_t0` | ACL 原值；ALSCL exp / Identity vs exp | VB t0；ALSCL 本版限定正值 / ALSCL restricts t0 to positive values |
| `log_cv_len` | `log_cv_len` | exp | 年龄体长 CV / Length-at-age CV |
| — | `log_cv_grow` | exp | 增长增量 CV / Growth-increment CV |
| `log_std_index` | `log_sigma_index` | exp | 对数调查观测 SD / Log survey observation SD |

`exp(mean_log_R)` 和 `exp(mean_log_F)` 是对数位置的指数转换；有随机偏差时不能直接称作无条件算术平均数。两个模板当前都不支持负的 AR(1) 相关。SD 在相关过程中的具体尺度见指南原理部分。

Exponentiating a log location does not give the unconditional arithmetic mean when random deviations are present. Both templates currently restrict AR(1) correlations to positive values. See the theory section for SD conventions in correlated processes.

```r
# 查看某物种的全部初值和上下界 / Inspect all starts and bounds for a preset
p <- create_parameters(model_type = "alscl", species = "flatfish")
keys <- names(p$parameters)
parameter_table <- data.frame(
  Parameter = keys,
  Start = unlist(p$parameters[keys]),
  Lower = unlist(p$parameters.L[keys]),
  Upper = unlist(p$parameters.U[keys]))
parameter_table
# 改一个初值及上界：此处并未自动固定该参数 / Change a start and upper bound
p$parameters$log_sigma_index <- log(0.15)
p$parameters.U$log_sigma_index <- log(0.5)
# 要固定该 SD，还需显式 map；固定值取自 parameters / Explicit map fixes the value
fixed_index <- list(log_sigma_index = factor(NA))
```

拟合会按数据维度建立 `dev_log_R`、`dev_log_F`、`dev_log_N0` 随机效应。它们不是本表的普通标量初值；不要把生成器的 `std_logR`、`F_mean` 等直接作为估计列表键名。

Fits construct random effects `dev_log_R`, `dev_log_F` and `dev_log_N0` from data dimensions. These are not ordinary scalar entries above. Generator names such as `std_logR` and `F_mean` are not estimator keys.


<a id="check_alscl_data"></a>
## `check_alscl_data`

在编译或拟合之前检查完整数据和模型设置。 / Check complete data and model settings before compiling or fitting.

```r
check_alscl_data (x, model = c("acl", "alscl"))
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `x` | `必填 / required` | run_acl() 或 run_alscl() 接受的具名输入列表。 | Named input bundle accepted by run_acl() or run_alscl(). |
| `model` | `c("acl", "alscl")` | 要检查的模型：acl 或 alscl。 | Model to check: acl or alscl. |

**返回 / Returns:** 返回 valid、model、errors、warnings、summary、time 和 length_bins。输入不合法时 valid = FALSE，并给出错误原因。

A list with valid, model, errors, warnings, summary, time and length_bins. Invalid inputs return valid = FALSE with an error message.

与核心拟合共用三表、时间间隔、体长边界、生物学输入、初值、上下界和 map 的准备逻辑，不编译 TMB、不优化。摘要列出正值、零值、缺失值、完全无观测的时段／体长组，以及独立自由固定效应／随机效应数量。警告指出排除的零值、无观测区块，以及正观测数不超过自由固定效应数的情况。这些只是输入检查，不证明可辨识性、收敛或生物学适用性。

Shares the actual fitting preparation for table alignment, time spacing, bins, biology, starts, bounds and maps. Does not compile TMB or optimize. Summary includes positive/zero/missing observations, entirely unobserved periods/bins and independent free fixed/random parameter counts. Warnings identify excluded zeros, unobserved blocks and positive observations no more numerous than free fixed parameters. These are input screens, not evidence of identifiability, convergence or biological adequacy.

**示例 / Example:**

```r
x <- YTF_example
check <- check_alscl_data(x, "alscl")
check$valid
check$summary
check$warnings
# Review check$errors if check$valid is FALSE.
```


<a id="check_fit"></a>
## `check_fit`

用时间–体长热图、按实际时间间隔计算的滞后相关及正态 QQ 图检查条件观测残差。 / Inspect conditional observation residuals with a time–length heatmap, actual-time lag correlations and a normal QQ plot.

```r
check_fit (fit, max_lag = 5)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `fit` | `必填 / required` | ACL 或 ALSCL 拟合结果。保留观测与报告的保存结果无需活跃 TMB 对象即可使用。 | A fitted ACL or ALSCL result. Saved results with observations and reports work without a live TMB object. |
| `max_lag` | `5` | 以模型时间步为单位的最大滞后阶数，须为正整数；季度模型的四步为一年。 | Positive integer maximum lag in model time steps; four steps are one year for quarterly models. |

**返回 / Returns:** 列表包含残差表 residuals、滞后相关表 lag_correlations（体长、滞后、实际时间差、有效配对数、相关系数与状态）、汇总 QQ 数据、三张图 plots$heatmap/lag/qq、time_step 和解释说明。无法计算的相关系数保留为 NA，并给出原因。

A list with residuals, lag_correlations (length, lag, elapsed_time, n_pairs, correlation, status), pooled qq_data, plots$heatmap, plots$lag, plots$qq, time_step and interpretation notes. Unavailable correlations are NA with an explicit status.

residuals(fit, type = "log") 返回观测对数值减去拟合对数值的长表；type = "standardized" 再除以拟合的观测标准差。表中保留原始观测、模型时间与体长坐标，标记被排除的单元，零值或缺失观测的残差为 NA。check_fit() 使用标准化残差。缺失时段不会压缩；相关系数要求在指定实际时间间隔上至少有三对有限观测，且两侧均非常数。这些残差以拟合的潜在效应为条件：标准化不代表残差独立、检验已校准或模型适合度已得到证明。绘图遵循包的无网格主题。

residuals(fit, type = "log") returns a long table of observed minus fitted log index; type = "standardized" divides by the fitted observation SD. It retains original observations, model times and length coordinates, marks excluded cells, and assigns NA residuals to zero/missing observations. check_fit() uses standardized residuals. Gaps are never compressed; correlations require at least three finite paired values at the requested actual lag and nonconstant values on both sides. These residuals condition on fitted latent effects: standardization is not a guarantee of independence, calibrated tests or model adequacy. Plots follow the package's grid-free theme.

**示例 / Example:**

```r
checks <- check_fit(b, max_lag = 4)
head(residuals(b, type = "standardized"))
checks$lag_correlations
checks$plots$heatmap
checks$plots$lag
checks$plots$qq
```

![示例图 / Example figure: `check_fit(b, max_lag = 4)$plots$heatmap`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/workflows/residual-heatmap.png?raw=true&v=2dbeb4799a6c)


<a id="extract_estimates"></a>
## `extract_estimates`

统一提取带坐标的种群估计 / Extract population estimates with coordinates

```r
extract_estimates (fit, quantities = c("SSB", "Rec", "B", "N", "CN", "F"), conf_level = 0.95)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `fit` | `必填 / required` | ACL 或 ALSCL 拟合结果；保存的可移植结果也可使用。 | An ACL or ALSCL fit, including a portable saved result. |
| `quantities` | `c("SSB", "Rec", "B", "N", "CN", "F")` | SSB、Rec、B、N、CN、CB、F 及模型实际报告的年龄、体长或联合数组。 | Reported population vectors and age, length or joint arrays; F resolves to ACL F or ALSCL FL. |
| `conf_level` | `0.95` | 近似区间的名义置信水平，严格介于 0 与 1。 | Nominal confidence level of the approximate intervals, strictly between zero and one. |

**返回 / Returns:** 含量名、实际报告名、年份、年龄、体长、估计、SE、区间及 numerical_ok 的长表。

A long table containing quantity, report name, time, age, length, estimate, SE, interval and numerical_ok.

估计来自 report，SE 只按完整、精确同名的 est_std 行提取。未报告 SE 时保留 NA，不造出区间。F 保留原分组和每模型步单位，不自动求平均或年化。FA 使用存活区间的起始年龄和时期；正态区间不截零。

Estimates use report and complete exact-name SE rows from est_std. Missing uncertainty remains NA. F retains native groups and per-step units without averaging or annualization. FA uses source ages and periods. Normal intervals are not truncated at zero.

**示例 / Example:**

```r
est <- extract_estimates(b, quantities = c("SSB", "Rec", "F"))
head(est)
```


<a id="extract_parameters"></a>
## `extract_parameters`

提取参数、尺度与固定状态 / Extract parameters, scales and estimation status

```r
extract_parameters (fit, scale = c("natural", "internal"), conf_level = 0.95)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `fit` | `必填 / required` | ACL 或 ALSCL 拟合结果；保存的可移植结果也可使用。 | An ACL or ALSCL fit, including a portable saved result. |
| `scale` | `c("natural", "internal")` | 自然尺度或优化器内部尺度。 | Natural or internal optimizer scale. |
| `conf_level` | `0.95` | 近似区间的名义置信水平，严格介于 0 与 1。 | Nominal confidence level of the approximate intervals, strictly between zero and one. |

**返回 / Returns:** 参数表，包括估计、SE、区间、固定／估计／停用状态及数值检查标记。

A parameter table with estimates, SEs, intervals, fixed/estimated/inactive status and the numerical-screen flag.

有完整配方时包括固定参数；其 SE 和区间为 NA。旧对象仅能可靠列出自由固定效应。自然尺度 SE 用 delta method，区间转换内部尺度 Wald 端点；exp(mean_log_F) 和 exp(mean_log_R) 是过程基准水平，不是时间算术平均。检查 numerical_ok 后再解释不确定性。

With a recipe, fixed parameters are included with NA uncertainty. Legacy objects expose only free fixed effects. Natural-scale SEs use the delta method; intervals transform internal Wald endpoints. exp(mean_log_F) and exp(mean_log_R) are a process baseline, not a time average. Inspect numerical_ok before interpreting uncertainty.

**示例 / Example:**

```r
extract_parameters(a)
extract_parameters(b, scale = "internal")
```


<a id="fit_scenarios"></a>
## `fit_scenarios`

在同一观测数据上串行或 socket 并行拟合具名敏感性情景。 / Fit named sensitivity scenarios on common observations with serial or socket execution.

```r
fit_scenarios (x, scenarios, model = c("acl", "alscl"), ncores = 1, F_summary = c("mean",
    "apical"), ...)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `x` | `必填 / required` | run_acl() 或 run_alscl() 接受的输入集合。 | An input bundle accepted by run_acl() or run_alscl(). |
| `scenarios` | `必填 / required` | 非空具名列表，每项为拟合参数覆盖列表。空列表代表参照情景，不允许修改数据表。 | A nonempty named list of named fitting-argument overrides. An empty list is the reference scenario; data tables cannot be changed. |
| `model` | `c("acl", "alscl")` | "acl"（默认）或 "alscl"。 | "acl" (default) or "alscl". |
| `ncores` | `1` | 不同情景的最大工作进程数；内部拟合和标准误使用一个进程。 | Maximum independent scenario workers; inner fitting and standard errors use one worker. |
| `F_summary` | `c("mean", "apical")` | "mean" 为组间非加权均值，"apical" 为最大值；F 保持每模型时间步单位。 | "mean" for the unweighted group mean, or "apical" for the maximum. F remains per model step. |
| `...` | 可选 / optional | 各情景之前应用的 run_* 共用覆盖。parameters/map/control 均为整份列表替换。 | Common run_* overrides, applied before each scenario. Complete parameter/map/control lists replace their predecessors. |

**返回 / Returns:** 返回具名拟合/错误记录、完整设置、状态、耗时、估计长表、模型、F 汇总方式和工作进程数。

A list with named fits/error records, resolved settings, status, elapsed, estimates, model, F_summary and workers.

保留警告和未通过数值筛查的结果，不自动排名。串行和并行保留相同初始点数量。结果移除会话专用 obj 指针，需要可执行目标函数时使用 refit_model()；本接口不实现断点续跑。

Warnings and failed numerical screens remain visible, with no automatic ranking. Each scenario uses the nstarts of the bundle or of the call; otherwise one start, the rule of hindcast_model() and retro_model(). Fits omit session-specific obj pointers; refit_model() can rebuild a live objective. This interface does not implement checkpoint/resume.

**示例 / Example:**

```r
x <- YTF_example
z <- fit_scenarios(x, list(reference = list(), low_M = list(M = 0.15),
  common_F = list(F_structure = "year")), model = "alscl", ncores = 2,
  F_summary = "mean", silent = TRUE)
z$status
z$estimates
```

![示例图 / Example figure: `fit_scenarios(x, list(reference = list(), low_M = list(M = 0.15), high_M = list(M = 0.25)), model = "acl")`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/workflows/scenario-SSB.png?raw=true&v=7ee6fd0e12d8)


<a id="inspect_parameters"></a>
## `inspect_parameters`

查看实际初值、上下界，以及自由、固定或共享的参数状态。 / Inspect effective parameter starts, bounds and free/fixed/tied restrictions.

```r
inspect_parameters (x, model = c("acl", "alscl"))
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `x` | `必填 / required` | 拟合函数接受的具名输入列表。 | Named input bundle accepted by the fitting functions. |
| `model` | `c("acl", "alscl")` | 要检查的模型：acl 或 alscl。 | Model to inspect: acl or alscl. |

**返回 / Returns:** 包含 parameter、kind、start、natural_start、lower、upper、transform、status、map_source、size、dimensions、n_free、n_fixed、n_tied 的数据框。

A data frame with parameter, kind, start, natural_start, lower, upper, transform, status, map_source, size, dimensions, n_free, n_fixed and n_tied.

使用真实的数据初值、按上下界截断的自由初值、补充年龄约束、默认 map 和共享 F 约束。kind=fixed_effect 指外层模型参数，并不表示该参数被 map 固定。status 可为 free、fixed、tied、mixed 或 inactive；map_source 区分 default、explicit、unmapped 和 F_structure。随机效应块初值为零，n_free 为独立映射值数量，n_tied 为共享这些值的额外元素数量。exp(mean_log_R) 和 exp(mean_log_F) 是自然尺度上的过程基准水平，不是算术平均值；随机效应的 natural_start 是乘数。全程无需编译。

Uses actual data-derived starts, clamped free starts, recruitment-age bounds, default maps and shared-F restrictions. kind=fixed_effect means an outer-model parameter, not necessarily a parameter fixed by map. Status can be free, fixed, tied, mixed or inactive. map_source distinguishes default, explicit, unmapped and F_structure. Random blocks start at zero; n_free counts independent mapped values and n_tied counts additional entries sharing them. exp(mean_log_R) and exp(mean_log_F) are baseline process levels on the natural scale, not arithmetic means; random natural_start is a multiplier. No compilation is performed.

**示例 / Example:**

```r
x <- YTF_example
parameters <- inspect_parameters(x, "acl")
parameters[, c("parameter", "status", "map_source", "start", "natural_start")]
x$fit_config$alscl$F_structure <- "year"
inspect_parameters(x, "alscl")[, c("parameter", "status", "dimensions", "n_free")]
```


<a id="prepare_alscl_data"></a>
## `prepare_alscl_data`

把三张数据表、三个 CSV 文件或 Excel 工作簿整理为可直接拟合的输入列表。 / Prepare a reusable input bundle from tables, three CSV files or an Excel workbook.

```r
prepare_alscl_data (data.CatL = NULL, data.wgt = NULL, data.mat = NULL, file = NULL, format = c("tables",
    "csv", "excel"), fit_args = list(), fit_config = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `data.CatL` | `NULL` | 调查数据表，或包含三张表的具名列表。 | Survey table, or a named list containing all three tables. |
| `data.wgt` | `NULL` | 与调查数据对齐的体长组体重表。 | Weight-at-length table aligned with the survey table. |
| `data.mat` | `NULL` | 与调查数据对齐的体长组成熟比例表。 | Maturity-at-length table aligned with the survey table. |
| `file` | `NULL` | CSV 文件目录或 Excel 工作簿路径。 | Directory for CSV input or workbook path for Excel input. |
| `format` | `c("tables", "csv", "excel")` | 输入格式：tables、csv 或 excel。 | Input format: tables, csv or excel. |
| `fit_args` | `list()` | 共享的生物学输入和拟合设置；三张表单独提供。 | Named list of shared biological and fitting settings. Keep the three tables outside this list. |
| `fit_config` | `NULL` | 可选的 acl 和／或 alscl 模型专属设置列表。 | Optional acl and/or alscl lists of model-specific settings. |

**返回 / Returns:** 包含 data.CatL、data.wgt、data.mat、fit_args 以及可选 fit_config 的结构化列表。

A structured list containing data.CatL, data.wgt, data.mat, fit_args and optional fit_config.

安全转换数字文本，并检查三表的数值和排列是否一致；不填补或重排缺失时段，也不推测生物学参数。在 fit_args 中提供 rec.age、nage、M、sel_L50、sel_L95，再运行 check_alscl_data(x, model)。优先级为共享 fit_args、选中的 fit_config、显式运行参数；列表参数整体替换，具名 NULL 的 map 释放规则保留。零值在导入后仍为零，由拟合的 zero_action 决定排除或拒绝。

This constructor converts numeric text safely and checks table values and alignment. It never fills or reorders missing periods and does not infer biology. Supply rec.age, nage, M, sel_L50 and sel_L95 in fit_args, then run check_alscl_data(x, model). Settings follow shared fit_args, selected fit_config, then explicit run arguments; list-valued settings replace the entire corresponding list. Named NULL map releases remain intact. Zeros remain zeros until the fitting zero_action excludes or rejects them.

**示例 / Example:**

```r
tables <- YTF_example[c("data.CatL", "data.wgt", "data.mat")]
x <- prepare_alscl_data(tables, fit_args = YTF_example$fit_args,
                        fit_config = YTF_example$fit_config)
check_alscl_data(x, "acl")$valid
inspect_parameters(x, "alscl")
```


<a id="profile_model"></a>
## `profile_model`

逐网格固定一个自由标量参数，重新优化其余参数及随机效应。 / Fix a free scalar at each grid value and reoptimize the remaining parameters and random effects.

```r
profile_model (fit, parameter, values, scale = c("natural", "internal"), ncores = 1)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `fit` | `必填 / required` | 保留完整 recipe、最终优化参数和边界的拟合结果。 | A fit retaining its complete recipe, final optimizer estimates and bounds. |
| `parameter` | `必填 / required` | names(fit$opt$par) 中的内部标量名称，如 "log_Linf"；不支持固定参数及外部 M/q。 | One internal scalar name in names(fit$opt$par), such as "log_Linf"; fixed parameters and external M/q are excluded. |
| `values` | `必填 / required` | 原优化边界内互不重复的有限网格值。 | Distinct finite grid values inside the original optimizer bounds. |
| `scale` | `c("natural", "internal")` | "natural"（默认）对 log_*/mean_log_* 使用 exp、logit_* 使用 plogis、t0 使用恒等变换；"internal" 使用优化坐标。参数名始终为内部名称。 | "natural" (default) transforms values using exp for log_*/mean_log_*, plogis for logit_* and identity for t0; "internal" uses optimizer coordinates. Parameter names remain internal. |
| `ncores` | `1` | 最大独立 socket 工作进程数；内部拟合及标准误使用一个进程。 | Maximum independent socket workers; inner fits and standard errors use one worker. |

**返回 / Returns:** 返回网格诊断、目标函数及 delta_nll、可移植拟合、完整设置、参照目标值和耗时。

A list containing grid diagnostics, objectives and delta_nll, portable fits, resolved settings, reference objective and timing.

其余自由标量初值取自拟合最优点，保留固定值和具名 NULL 释放。必须至少保留一个其他自由标量。delta_nll 相对于原拟合，可为负值并提示重查最优点。保留失败点，不自动生成置信区间或卡方阈值；外部假设使用 fit_scenarios()。

Other free scalar starts come from the fitted optimum; fixed values and named NULL releases are preserved. At least one other free scalar must remain. delta_nll is relative to the original fit and can be negative, prompting rechecking of that optimum. Failed points remain visible. No automatic confidence intervals or chi-square cutoffs are provided. External assumptions use fit_scenarios().

**示例 / Example:**

```r
x <- YTF_example
a <- run_acl(x, silent = TRUE)
values <- exp(a$opt$par[["mean_log_F"]]) * c(0.9, 1, 1.1)
p <- profile_model(a, "mean_log_F", values, scale = "natural", ncores = 2)
p$grid
```

![示例图 / Example figure: `profile_model(a, "mean_log_F", values = grid, scale = "natural")`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/workflows/profile-F.png?raw=true&v=cc2a75644194)


<a id="project_model"></a>
## `project_model`

从 ACL 或 ALSCL 拟合末期状态开始，按明确给定的假设推演确定性种群情景。 / Project explicit deterministic population scenarios from the terminal fitted ACL or ALSCL state.

```r
project_model (fit, F, recruitment, weight, maturity, M = NULL, allow_failed_fit = FALSE)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `fit` | `必填 / required` | 保留末期种群数组、年龄/体长/时间坐标的 ACL 或 ALSCL 结果；建议同时保留可移植拟合配方。 | An ACL or ALSCL result retaining terminal population arrays, age/length/time metadata and preferably its portable fit recipe. |
| `F` | `必填 / required` | 每模型时间步的非负瞬时捕捞死亡率：每个未来时段一个值并供所有组共用，或组×未来时段矩阵（ACL 为年龄组，ALSCL 为体长组）。 | Nonnegative instantaneous fishing mortality per model time step: one value per future period shared across groups, or a group-by-period matrix (age for ACL, length for ALSCL). |
| `recruitment` | `必填 / required` | 每个未来时段的有限非负补充数量；向量长度确定推演时段数。 | Finite nonnegative recruitment numbers, one per future period; vector length determines the horizon. |
| `weight` | `必填 / required` | 完整的非负体长×未来时段个体体重矩阵。可选行名须与拟合体长顺序一致，列名须等于未来时间。 | Complete nonnegative length-by-future-period weight matrix. Optional row labels must match fitted length order; column labels must equal future times. |
| `maturity` | `必填 / required` | 完整的体长×未来时段成熟比例矩阵，数值在 [0,1] 内；函数不会隐式延用或循环填充。 | Complete length-by-future-period maturity matrix with values in [0, 1]. No implicit carry-forward or recycling. |
| `M` | `NULL` | 未来每模型时间步的自然死亡率，可为标量或每个未来时段一个值。NULL 使用拟合配方中的原始 M。旧结果须明确提供 M，首值同时用于末期拟合时段的存活计算。 | Future natural mortality per model step, scalar or one value per future period. NULL uses original M from the fit recipe. Legacy fits require explicit M; its first value is also used for the terminal interval. |
| `allow_failed_fit` | `FALSE` | 明确未通过数值检查时默认拒绝投影；TRUE 在警告后允许探索性投影，并记录覆盖。缺诊断的旧结果记为 unknown。 | Reject known numerical-screen failures by default; TRUE permits exploratory projection with a warning and records the override. Legacy missing status remains unknown. |

**返回 / Returns:** summary 包含时间、总数量 N、生物量 B、SSB、补充量 Rec、捕捞数量 CN、捕捞生物量 CB、F_mean 和 F_apical；trajectories 和 fishing_mortality 为长表。states 保存 NA、NL 及 ALSCL 的 NLA；catch 保存 CNA 和 CNL。结果同时保留未来生物资料、F、时间轴及假设。CN 为数量，CB 的单位由个体体重单位决定。

summary contains year, N, B, SSB, Rec, CN, CB, F_mean and F_apical. trajectories and fishing_mortality are long tables. states contains NA, NL and ALSCL NLA; catch contains CNA and CNL. Supplied biology, F, time grid and assumptions are retained. CN is numbers; CB uses the supplied individual-weight units.

种群状态、B 和 SSB 对应每个未来时段开始时。第一期未来状态先让拟合末期种群经历末期拟合 F 和原始 M 的死亡，再加入第一期未来补充量。未来 F[t]/M[t] 决定该期捕捞以及进入 t+1 的存活，因此仅改变一期 F 会改变当期捕捞，而不会改变期初 SSB。ACL 推进年龄组和末龄加组，并使用拟合的年龄–体长键；ALSCL 先按体长存活，再通过拟合的生长矩阵。ACL 的捕捞生物量由年龄捕捞量经该键转换得到。F_mean 是组间未加权平均值，F_apical 是组间最大值，均不把季度死亡率换算成年率。这是固定生长、明确补充量与未来生物资料的确定性条件情景，没有不确定性区间、没有估计的亲体量–补充量关系，也不自动计算 MSY/TAC。

Population states, B and SSB are at the start of each future period. The first future state survives the terminal fitted population through terminal fitted F and original M, then receives the first future recruitment. Future F[t]/M[t] determine catch[t] and survival into t+1, so a one-period F change affects catch but not start-of-period SSB. ACL advances ages and the plus group through its fitted age-length key; ALSCL applies length-specific survival before its fitted growth matrix. ACL catch biomass is derived by mapping catch-at-age through the fitted key. F_mean is an unweighted group mean and F_apical a group maximum; neither annualizes quarterly rates. These are deterministic conditional scenarios with fixed growth, explicit recruitment and future biology, no uncertainty intervals, no estimated stock-recruitment relationship and no automatic MSY/TAC calculation.

明确未通过数值检查的拟合默认拒绝投影。allow_failed_fit = TRUE 可在警告后进行探索性投影；旧结果缺少诊断时记为 unknown，不视为通过。assumptions 保存状态及是否覆盖。

Fits explicitly failing the numerical screen are rejected by default. allow_failed_fit = TRUE permits exploratory projection with a warning. Missing legacy diagnostics are recorded as unknown, not passed; assumptions retain the status and override.

**示例 / Example:**

```r
# Explicit illustrative assumption: retain last observed biology.
h <- 4L
w <- as.matrix(x$data.wgt[-1L])
mat <- as.matrix(x$data.mat[-1L])
future_w <- matrix(w[, ncol(w)], nrow(w), h)
future_mat <- matrix(mat[, ncol(mat)], nrow(mat), h)
scenario <- project_model(b, F = rep(0.15, h),
  recruitment = rep(tail(b$report$Rec, 1), h),
  weight = future_w, maturity = future_mat)
scenario$summary
# F is per model step; supplied recruitment and biology are assumptions.
```

![示例图 / Example figure: `project_model(a, F = F_future, recruitment = R_future, weight = w, maturity = m)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/workflows/projection-SSB.png?raw=true&v=a1acd1f6ce98)


<a id="read_assessment"></a>
## `read_assessment`

读取可移植评估存档 / Read a portable assessment archive

```r
read_assessment (file)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `file` | `必填 / required` | save_assessment() 创建的可信 RDS 文件。 | A trusted RDS archive created by save_assessment(). |

**返回 / Returns:** 带完整配方和估计结果的 alscl_fit 对象；没有活跃 obj。

An alscl_fit with its complete recipe and estimates, without a live obj.

校验存档格式和 schema。读取后可使用 summary、提取函数和基于报告的绘图；需要活跃模型时重新拟合。

Validates the archive format and schema. Summaries, extractors and report-based plots work after reading; refit to obtain a live model.

**示例 / Example:**

```r
path <- tempfile(fileext = ".rds")
save_assessment(a, path)
saved <- read_assessment(path)
plot_SSB(saved)
```


<a id="read_survey_csv"></a>
## `read_survey_csv`

从三个 CSV 文件读取对齐的调查、体重和成熟比例数据表。 / Read aligned survey, weight and maturity tables from three CSV files.

```r
read_survey_csv (folder)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `folder` | `必填 / required` | 包含 data.CatL.csv、data.wgt.csv 和 data.mat.csv 的目录。 | Directory containing data.CatL.csv, data.wgt.csv and data.mat.csv. |

**返回 / Returns:** 包含三张数值数据表的具名列表，可交给 prepare_alscl_data()。

A named list containing the three numeric data tables, ready for prepare_alscl_data().

第一列为体长组标签，后续表头为数值时间标签。空白单元格和 NA 表示缺失；数字文本按显示值转换，不使用因子内部编码。保留原始行列顺序。体重和成熟比例必须完整，调查数据的零值和缺失值保留，不推测生物学输入。

The first column contains length-bin labels and subsequent headers contain numeric time labels. Blank cells and NA represent missing values. Numeric text is converted without using factor level codes. Rows and columns retain their original order. Weight and maturity tables must be complete; survey zeros and missing values remain explicit. Biological inputs are not inferred.

**示例 / Example:**

```r
folder <- tempfile("survey-csv-")
dir.create(folder)
for (nm in c("data.CatL", "data.wgt", "data.mat")) {
  write.csv(YTF_example[[nm]], file.path(folder, paste0(nm, ".csv")),
            row.names = FALSE)
}
tables <- read_survey_csv(folder)
x <- prepare_alscl_data(tables, fit_args = YTF_example$fit_args,
                        fit_config = YTF_example$fit_config)
check_alscl_data(x, "acl")$summary
```


<a id="read_survey_excel"></a>
## `read_survey_excel`

读取 Excel 工作簿中的调查、体重和成熟比例工作表。 / Read survey, weight and maturity sheets from an Excel workbook.

```r
read_survey_excel (file)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `file` | `必填 / required` | 包含 data.CatL、data.wgt、data.mat 三张工作表的 Excel 文件路径。 | Path to an existing workbook with sheets data.CatL, data.wgt and data.mat. |

**返回 / Returns:** 包含三张数值数据表的具名列表。

A named list containing the three numeric data tables.

需要可选的 readxl 包。工作表名称必须完全一致。第一列为体长组标签，后续表头为数值时间标签。使用与 read_survey_csv() 相同的数值和对齐检查；保留调查零值和缺失值，不推测生物学输入或填补时段。

Requires the optional readxl package. Sheet names must match exactly. The first column is the length-bin label; remaining headers are numeric time labels. The reader applies the same value and alignment checks as read_survey_csv(), preserves zero and missing survey cells, and does not infer biology or fill missing periods.

**示例 / Example:**

```r
# Optional dependency: install.packages("readxl")
# Replace this path with your workbook.
if (file.exists("survey.xlsx")) {
  tables <- read_survey_excel("survey.xlsx")
  # Supply biology for your own stock in fit_args before fitting.
  names(tables)
}
```


<a id="refit_model"></a>
## `refit_model`

按保存配方重新拟合 / Refit a stored assessment recipe

```r
refit_model (fit, ...)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `fit` | `必填 / required` | ACL 或 ALSCL 拟合结果；保存的可移植结果也可使用。 | An ACL or ALSCL fit, including a portable saved result. |
| `...` | 可选 / optional | 具名 run_* 覆盖参数；列表整项替换，具名 NULL 保留。 | Named run_* overrides; lists replace whole entries and named NULL is retained. |

**返回 / Returns:** 新的拟合结果、更新后的配方和当前会话活跃 TMB 对象。

A fresh fit with an updated recipe and live TMB object.

默认复用原始初值、完整输入与记录的 AD／标准误设置；完成后恢复调用者速度选项。除非显式 output=TRUE，否则不写绘图文件。更换软件版本不保证逐位一致。

Reuses original starts, complete inputs and recorded AD/SE settings, restoring caller options afterward. File output is disabled unless output=TRUE is explicit. Bitwise identity across software versions is not guaranteed.

`recipe$implementation` 保存可取得的提交号、核心与 R 源码摘要、运行环境。旧存档及来源未知的旧拟合保持可读；重新拟合会提示已知实现或依赖变化。

`recipe$implementation` stores available revision, core/R source hashes and runtime metadata. Legacy archives remain readable; refitting warns about known implementation or dependency changes. A source HEAD does not establish that the working tree was clean.

**示例 / Example:**

```r
updated <- refit_model(a, M = 0.25, silent = TRUE)
summary(updated)
```


<a id="save_assessment"></a>
## `save_assessment`

保存完整可移植评估 / Save a portable assessment

```r
save_assessment (fit, file, x = NULL, overwrite = FALSE)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `fit` | `必填 / required` | ACL 或 ALSCL 拟合结果；保存的可移植结果也可使用。 | An ACL or ALSCL fit, including a portable saved result. |
| `file` | `必填 / required` | 目标 RDS 路径，父目录必须已存在。 | Destination RDS path with an existing parent directory. |
| `x` | `NULL` | 仅给没有配方的旧拟合提供完整输入；原始生物学和设置仍标记为未核实。 | Optional complete input bundle only for a legacy fit without a recipe; original biology and settings remain unverified. |
| `overwrite` | `FALSE` | 是否替换已有文件，默认不覆盖。 | Whether to replace an existing file; FALSE by default. |

**返回 / Returns:** 不可见地返回文件路径；不修改原拟合。

Invisibly returns the file path without changing the original fit.

存档剔除会话专属 obj 指针，保存配方、输入、map、边界、设置、版本和报告。失败时保留原存档。配方不等于可跨会话执行的 TMB 指针；重建需要 refit_model()。

The archive omits the session-specific obj pointer and retains inputs, maps, bounds, settings, versions and reports. Failed replacement preserves the old archive. Use refit_model() to rebuild a live TMB model.

`recipe$implementation` 保存可取得的提交号、核心与 R 源码摘要、运行环境。旧存档及来源未知的旧拟合保持可读；重新拟合会提示已知实现或依赖变化。

`recipe$implementation` stores available revision, core/R source hashes and runtime metadata. Legacy archives remain readable; refitting warns about known implementation or dependency changes. A source HEAD does not establish that the working tree was clean.

**示例 / Example:**

```r
path <- tempfile(fileext = ".rds")
save_assessment(b, path)
saved <- read_assessment(path)
summary(saved)
```


<a id="sim_alscl"></a>
## `sim_alscl`

使用 ALSCL 拟合模拟批次的便捷入口。 / Convenience interface for simulation batches fitted with ALSCL.

`sim_data()`、`sim_model()`、`sim_acl()` 和 `sim_alscl()` 的重复编号须为互不重复的非负整数，可以包含 0。模拟以编号作为随机种子，拟合读取对应的 `sim_rep<id>` 文件。

Replicate IDs must be distinct nonnegative integers, including 0, in `sim_data()`, `sim_model()`, `sim_acl()` and `sim_alscl()`. Simulation uses each ID as its seed and fitting reads the matching `sim_rep<id>` file.

```r
sim_alscl (..., nstarts = 1)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `...` | 可选 / optional | 传入 sim_model() 的参数（model 和 nstarts 除外）；参数名和 map 必须对应 ALSCL。 | Arguments passed to sim_model(), excluding model and nstarts; use ALSCL parameter names and maps. |
| `nstarts` | `1` | 每个模拟重复的独立初值数，在重复内部依次运行；ncores 仍控制外层并行重复数。 | Independent starts per replicate, run sequentially; ncores still controls outer replicate workers. |

**返回 / Returns:** 返回包含 iter 和 elapsed 的具名拟合或错误记录列表；每个结果同时替换对应 `result_rep_<id>` 文件。

A named list of replicate fits or error records, including iter and elapsed. Every result also replaces its `result_rep_<id>` file.

保留模拟文件中的时间和体长坐标。每次拟合内部使用一个进程及顺序标准误。失败重跑会替换旧成功文件。M、F 均为每模型时间步单位。这是操作模型模拟数据拟合，不自动构成拟合模型参数自助法。

Recorded time and length coordinates are retained. Each replicate uses one inner fitting worker and sequential standard errors. Failed reruns replace old success files. M and F are per model step. This fits operating-model simulations; it does not automatically create a fitted parametric bootstrap.

`start_diagnostics` 保留每个初值的结果、进程与耗时。 / `start_diagnostics` retains the result, process and timing of every start.

**示例 / Example:**

```r
x <- YTF_example
pa <- x$parameters
bio <- sim_cal(pa)
folder <- tempfile("alscl-sim-")
sm <- sim_data(bio, pa, iter_range = 1:2, return_iter = 1, output_dir = folder)
cfg <- x$fit_config$alscl
fits <- sim_alscl(1:2, folder, file.path(folder, "fits_alscl"),
  parameters = cfg$parameters, map = cfg$map, M = pa$M, ncores = 2, nstarts = 3)
lapply(fits, function(fit) fit$diagnostics)
```


<a id="sim_model"></a>
## `sim_model`

使用统一批次流程，把 ACL 或 ALSCL 拟合到已保存的模拟重复数据。 / Fit ACL or ALSCL to saved simulation replicates using the same batch pipeline.

```r
sim_model (iter_range = 4:100, sim_data_path = ".", output_dir = ".", parameters = NULL,
    parameters.L = NULL, parameters.U = NULL, map = NULL, M = 0.2, ncores = 1, train_times = 1,
    control = list(), F_structure = c("group_year", "year"), polish = TRUE, model = c("acl",
        "alscl"), nstarts = 1)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `iter_range` | `4:100` | 与 `sim_rep<id>` 文件名对应的互不重复非负整数编号，包括 0。 | Distinct nonnegative integer replicate IDs, including 0, matching `sim_rep<id>` filenames. |
| `sim_data_path` | `"."` | 存放 sim_data() 模拟文件的目录。 | Folder containing simulation files produced by sim_data(). |
| `output_dir` | `"."` | 保存 `result_rep_<id>` 的目录；ACL 和 ALSCL 应使用不同目录。 | Directory for `result_rep_<id>` files; use different directories for ACL and ALSCL. |
| `parameters` | `NULL` | 可选、对应模型的标量参数初值。 | Optional model-specific scalar initial values. |
| `parameters.L` | `NULL` | 可选、对应模型的具名下界。 | Optional named lower bounds, matching the selected model. |
| `parameters.U` | `NULL` | 可选、对应模型的具名上界。 | Optional named upper bounds, matching the selected model. |
| `map` | `NULL` | 对应模型的参数映射；保留具名 NULL 释放。 | Model-specific parameter mappings; named NULL releases are preserved. |
| `M` | `0.2` | 每模型时间步的自然死亡率，默认 0.2。 | Natural mortality per model time step; default 0.2. |
| `ncores` | `1` | 独立模拟重复的最大 socket 工作进程数。 | Maximum independent replicate socket workers. |
| `train_times` | `1` | 每个初值的优化轮数。 | Optimization passes per start. |
| `control` | `list()` | 具名 nlminb 优化控制。 | Named nlminb optimizer controls. |
| `F_structure` | `c("group_year", "year")` | "group_year"（默认）或 "year"，后者在每个模型时间步共用一个 F。 | "group_year" (default), or one F shared across groups per model step with "year". |
| `polish` | `TRUE` | 是否应用有保护的优化收尾，默认 TRUE。 | Apply safeguarded optimization refinement; default TRUE. |
| `model` | `c("acl", "alscl")` | "acl"（默认）或 "alscl"。 | "acl" (default) or "alscl". |
| `nstarts` | `1` | 每个模拟重复的独立初值数，在重复内部依次运行；ncores 仍控制外层并行重复数。 | Independent starts per replicate, run sequentially; ncores still controls outer replicate workers. |

**返回 / Returns:** 返回包含 iter 和 elapsed 的具名拟合或错误记录列表；每个结果同时替换对应 `result_rep_<id>` 文件。

A named list of replicate fits or error records, including iter and elapsed. Every result also replaces its `result_rep_<id>` file.

保留模拟文件中的时间和体长坐标。每次拟合内部使用一个进程及顺序标准误。失败重跑会替换旧成功文件。M、F 均为每模型时间步单位。这是操作模型模拟数据拟合，不自动构成拟合模型参数自助法。

Recorded time and length coordinates are retained. Each replicate uses one inner fitting worker and sequential standard errors. Failed reruns replace old success files. M and F are per model step. This fits operating-model simulations; it does not automatically create a fitted parametric bootstrap.

`start_diagnostics` 保留每个初值的结果、进程与耗时。 / `start_diagnostics` retains the result, process and timing of every start.

**示例 / Example:**

```r
x <- YTF_example
pa <- x$parameters
bio <- sim_cal(pa)
folder <- tempfile("alscl-sim-")
sm <- sim_data(bio, pa, iter_range = 1:2, return_iter = 1, output_dir = folder)
cfg <- x$fit_config$alscl
fits <- sim_model(1:2, folder, file.path(folder, "fits_alscl"),
  parameters = cfg$parameters, map = cfg$map, M = pa$M, model = "alscl", ncores = 2, nstarts = 3)
lapply(fits, function(fit) fit$diagnostics)
```


<a id="summarize_simulations"></a>
## `summarize_simulations`

使用明确分母汇总模拟偏差、RMSE、区间覆盖率、拟合失败与耗时。 / Summarize simulation bias, RMSE, interval coverage, fitting failures and timing with explicit denominators.

```r
summarize_simulations (fits, truth, quantities = c("SSB", "Rec"), conf_level = 0.95)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `fits` | `必填 / required` | 具名拟合或错误记录列表，如 sim_model() 输出。 | A named list of fits or error records, such as sim_model() output. |
| `truth` | `必填 / required` | 与 fits 同名的逐重复列表；每项包含 year 及所选量的真值向量，坐标必须匹配。 | A same-named per-replicate list; each entry contains year and vectors for all requested quantities. Coordinates must match exactly. |
| `quantities` | `c("SSB", "Rec")` | SSB、Rec、B、N、CN、CB 中互不重复的总体时序，默认 SSB 和 Rec。 | Distinct aggregate time series from SSB, Rec, B, N, CN, CB; default SSB and Rec. |
| `conf_level` | `0.95` | 基于报告标准误构造正态区间的名义置信水平；实际覆盖率另行计算。 | Nominal confidence level used to construct normal intervals from reported SEs; empirical coverage is calculated separately. |

**返回 / Returns:** 返回按量跨重复/时间合并的 summary、逐重复状态/耗时，以及保留失败点的逐点估计和真值。

A list with summary pooled over replicates/time by quantity, per-replicate status/timing and all pointwise estimates/truth, including failures.

偏差和 RMSE 使用数值有效估计对，覆盖率额外要求有限的报告标准误。报告尝试/有效重复、点及区间数和 failure_rate。缺失标准误不算覆盖失败。相对偏差排除真值为零的点。F 因需要明确定义聚合和不确定性而排除。这些条件性能统计不证明模型普遍更优。

Bias/RMSE use numerically valid estimate pairs; coverage additionally requires finite reported SEs. Attempted/valid replicate, point and interval counts and failure_rate are reported. Missing SEs are not counted as failed coverage. Relative bias excludes zero truth. F is excluded because its aggregation and uncertainty must be explicitly defined. These conditional performance summaries are not proof of general model superiority.

**示例 / Example:**

```r
x <- YTF_example
a <- run_acl(x, silent = TRUE)
fits <- list(example = a)
truth <- list(example = list(year = as.numeric(names(x$data.CatL)[-1]),
  SSB = x$truth$SSB, Rec = x$truth$Rec))
performance <- summarize_simulations(fits, truth)
performance$summary
performance$replicates
```


<a id="simulate_fit"></a>
## `simulate_fit`

给定拟合种群状态，或重新抽取其过程偏差后，模拟调查观测。 / Simulate survey observations conditionally on a fitted population or after resampling its process deviations.

```r
simulate_fit (fit, nsim = 1, seed = NULL, process = c("conditional", "resample"), preserve_missing = TRUE,
    allow_failed_fit = FALSE)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `fit` | `必填 / required` | 带完整配方及报告的 ACL／ALSCL 拟合，可为可移植存档读取结果。 | ACL/ALSCL fit with a complete recipe and report, including a portable saved fit. |
| `nsim` | `1` | 正整数模拟重复数。 | Positive integer number of replicate datasets. |
| `seed` | `NULL` | 可选非负整数种子；显式种子恢复调用者随机数状态，NULL 消耗当前随机流。 | Optional nonnegative integer seed; explicit seeds restore caller RNG state, NULL consumes the current stream. |
| `process` | `c("conditional", "resample")` | conditional 固定状态模拟观测；resample 固定标量参数并重新抽取过程。 | conditional simulates observations at fixed fitted states; resample draws new processes at fixed scalar estimates. |
| `preserve_missing` | `TRUE` | 保留原 NA 和零位置；FALSE 生成完整正观测。 | Preserve original NA/zero positions; FALSE generates a complete positive survey. |
| `allow_failed_fit` | `FALSE` | 已知失败拟合默认拒绝；TRUE 警告后允许探索。 | Reject known failed fits by default; TRUE permits warned exploratory use. |

**返回 / Returns:** simulations 为具名重复，每项含可直接拟合的 x、observations 及 truth；metadata 记录过程模式、种子／随机数生成器、坐标、原观测掩码、源数值状态和 parameter_uncertainty = none。真值包括时间、种群量、原生组别 F、标量参数、随机效应及期望指数。

simulations contains named replicates with x, observations and truth; metadata records the process, seed/RNG, coordinates, original observation mask, source numerical status and parameter_uncertainty = none. Truth includes year, population quantities, native group-specific F, scalar parameters, random effects and expected indices.

条件模式固定拟合状态，只改变对数正态观测误差。过程重抽样使用平稳 AR(1) 补充、可分离组别／时间 AR(1) F（或仅时间共用 F）及独立初始年龄偏差，再调用现有 C++ 种群方程，无须优化。过程尺度为边际标准差。标量参数、生物学和可捕性保持固定；重抽样拒绝固定／绑定随机效应的 map，不加入参数不确定性或自助法区间。显式种子会恢复调用者随机数状态；默认保留原 NA／零位置。已知失败拟合须显式覆盖并警告。支持读取后的可移植拟合。

Conditional simulation holds fitted states fixed and varies lognormal observation errors. Resampling draws stationary AR(1) recruitment, separable group/time AR(1) F (or shared time-only F) and independent initial-age deviations, then evaluates the existing C++ population equations without optimization. Scales are marginal SDs. Scalar parameters, biology and catchability remain fixed. Fixed/tied random-effect maps are rejected for resampling; no parameter uncertainty or bootstrap intervals are added. Explicit seeds restore caller RNG state; original NA/zero cells are preserved by default. Known failed fits require an explicit warned override. Portable saved fits are supported.

模拟返回的输入列表显式保存源拟合的实际固定标量值；重新拟合不会根据新观测改变这些固定值。自由参数保留原初值策略。新 ALSCL 拟合的条件真值含 dev_log_N0，保存并读取后也保留；缺少该字段的旧存档仍返回 NULL。

Returned input bundles explicitly retain the source fit’s effective fixed scalar values, so refitting does not derive different fixed values from new observations. Free parameters keep their original starting-value strategy. Conditional truth from new ALSCL fits retains dev_log_N0 after saving and reading; older archives without that field still return NULL.

**示例 / Example:**

```r
fit <- run_acl(YTF_example, silent = TRUE)
simulated <- simulate_fit(fit, nsim = 3, seed = 42, process = "resample")
refitted <- run_acl(simulated$simulations[[1]]$x, silent = TRUE)
simulated$simulations[[1]]$truth$SSB
```

![示例图 / Example figure: `simulate_fit(b, nsim = 3, seed = 42, process = "resample")`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/workflows/fitted-simulation.png?raw=true&v=79b8f645c515)


<a id="hindcast_model"></a>
## `hindcast_model`

逐步扩展训练窗口，对真正留出的调查指数进行点预测并评分。 / Fit expanding training windows and score survey-index point predictions against genuinely withheld periods.

```r
hindcast_model (x, model = c("acl", "alscl"), horizon = 1, nfolds = 3, min_train = 3, ncores = 1,
    nstarts = NULL, silent = TRUE, save_fits = FALSE, ...)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `x` | `必填 / required` | 与核心拟合相同的输入列表；起点和假设不得用留出数据调参。 | The same input bundle used for fitting; choose starts and assumptions without tuning to held-out observations. |
| `model` | `c("acl", "alscl")` | 选择 ACL 或 ALSCL。 | Choose ACL or ALSCL. |
| `horizon` | `1` | 正整数预测期距，单位为模型时间步。 | Positive integer forecast horizon in model time steps. |
| `nfolds` | `3` | 最后若干合格训练起点的数量；不足时明确报错。 | Number of final eligible training origins; unavailable requested folds cause an error. |
| `min_train` | `3` | 最少训练时期数，至少 2。 | Minimum training periods, at least two. |
| `ncores` | `1` | 并行折的最大 socket 工作进程数；每折内部单进程。 | Maximum socket workers across folds; each inner fit uses one worker. |
| `nstarts` | `NULL` | 每折独立初值数；NULL 保留列表明确设置，否则 1。 | Independent starts per fold; NULL preserves an explicit bundle setting, otherwise one. |
| `silent` | `TRUE` | 抑制拟合进度；警告仍保留在诊断表。 | Suppress fitting progress; retain warnings in diagnostics. |
| `save_fits` | `FALSE` | 是否返回各折拟合；始终保留配置与诊断。 | Return fold fits; settings and diagnostics are retained regardless. |
| `...` | 可选 / optional | 具名核心拟合覆盖设置，列表整体替换。 | Named core fitting overrides; list arguments replace the complete corresponding list. |

**返回 / Returns:** predictions 按体长／时间／折列出观测、模型和持平基准的对数预测、误差、尺度分母及纳入状态。scores 按期距报告配对对数 RMSE／MAE、对数 MASE 与计数。diagnostics、recipes、settings、start_diagnostics、process_paths 保留状态、失败、警告和复现细节；可选保存 fits。

predictions is a length/time/fold table with observed, model and persistence predictions on the log scale, errors, scaling denominators and inclusion status. scores reports paired log RMSE/MAE, log MASE and counts by horizon. diagnostics, recipes, settings, start_diagnostics and process_paths retain fit status, failures, warnings and reproduction details; fits are optional.

使用至少 min_train 个训练期且能留出完整 horizon 的最后若干起点。每折只拟合截短输入，不使用完整序列拟合估计作为初值。未来对数补充／F 偏差沿 AR(1) 条件均值路径延伸，经种群转移得到代入式调查预测，不是边际预测均值或预测区间。未来生物学沿用训练末期。拒绝固定／绑定随时间变化随机效应的 map。失败／未确认数值状态的拟合保留但不评分。评分使用具备持平预测的配对正观测；对数 MASE 按同体长组连续训练对数差缩放，零／未知分母保持缺失。ncores 并行折，每折内初值和标准误顺序运行。手动假设应在不参考留出数据调参的前提下确定。

Uses the last eligible origins with at least min_train periods and the complete horizon. Each fold fits truncated inputs; no full-series fit supplies starts. Future log recruitment/F deviations follow AR(1) conditional-mean paths, then population transitions give plug-in survey predictions, not marginal predictive means or predictive intervals. Biology is carried forward from the training endpoint. Fixed/tied time-varying random-effect maps are rejected. Failed/unverified fits remain visible but unscored. Scores use paired positive observations with an available persistence forecast; log MASE scales by consecutive training log changes within each length. Zero/undefined scales remain missing. ncores parallelizes folds; starts and SEs are sequential inside each fold. User-supplied assumptions must be chosen without tuning to held-out data.

**示例 / Example:**

```r
validation <- hindcast_model(YTF_example, model = "acl", horizon = 1,
  nfolds = 2, min_train = 8, nstarts = 1, ncores = 2)
validation$diagnostics
validation$scores
head(validation$predictions)
```

![示例图 / Example figure: `hindcast_model(x, model = "acl", horizon = 1, nfolds = 3)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/workflows/hindcast-predictions.png?raw=true&v=6808289fa0c6)

---

[← 上一章 · Previous](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/13-Colors-and-Export) · [目录 · Contents](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [下一章 · Next →](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/15-Reproducibility)
