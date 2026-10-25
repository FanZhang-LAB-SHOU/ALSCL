# 03 数据、Excel 与实测导入 · Data and observations

[← 上一章 · Previous](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/02-Theory) · [目录 · Contents](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [下一章 · Next →](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/04-Built-in-YTF)

**ALSCL 2.2.4 · 简体中文 / English**

下载 [ALSCL_Data_Entry_Example.xlsx](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/data/ALSCL_Data_Entry_Example.xlsx)。工作簿的 `Instructions` 是双语说明页；其余三张表已填入与 `YTF_example` 相同的数值。请另存副本再替换数据。

Download the workbook. `Instructions` contains bilingual directions, and the other three sheets contain the exact YTF example. Save a copy before replacing values.

| 位置 / Location | 填写规则 / Entry rule |
|---|---|
| 工作表名 / Sheet names | 必须为 `data.CatL`、`data.wgt`、`data.mat` / Use these exact names |
| A1 | `LengthBin`，不要在表头上方加标题 / No title rows above the header |
| A2:A… | 每行一个体长组；示例为中心值 6、8、…、50 / One length-bin label per row; example uses midpoints |
| B1、C1、… | 递增数字年份，如 2000、2001；季度如 2000、2000.25 / Increasing numeric time headers |
| B2 等数值单元 / Numeric cells | 对应这一体长组、这一期的值 / Value for that bin and period |
| 三表顺序 / Alignment | 体长组、时间、行列顺序必须完全相同 / Exact same bins, periods and order |

**调查数量指数 `data.CatL` / Survey number index**

![调查数据填表示例 / Survey data worksheet](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/excel_CatL.png?raw=true)

填数量或已标准化为可比尺度的数量指数；若使用 CPUE，各期努力量、单位和标准化方式必须一致。正数可为小数。未知调查单元留空或填 `NA`；不要用 0、破折号、`<1` 或“未测”代替缺失值。

Enter counts or a consistently standardized number index. For CPUE, maintain comparable effort, units and standardization. Decimals are valid. Use blank/`NA` for unknown observations; do not use zero, dashes, `<1` or text labels as missing-value substitutes.

**平均个体重量 `data.wgt` / Mean individual weight**

![平均体重填表示例 / Mean-weight worksheet](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/excel_wgt.png?raw=true)

填每组每期的平均单尾重量，不是该组总重。选择同一重量单位并记录在说明页。没有逐年数据时，可以在有依据的条件下重复同一长度重量关系，但要在分析报告说明。不得留缺失值。

Enter mean weight per fish, not the total weight in the bin. Use one unit and document it separately. Repeating a defensible length-weight relationship across periods is possible but must be reported. Missing weights are not accepted.

**成熟比例 `data.mat` / Maturity proportion**

![成熟比例填表示例 / Maturity worksheet](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/excel_mat.png?raw=true)

填写 0–1，例如 60% 填 `0.6`，不要填 `60`。0 和 1 在成熟表中是合法值；不要将“调查零值”的规则误用于成熟表。三张表的数据区不要插入单位行、合计、合并单元格或解释文字。

Enter proportions in [0,1], e.g. `0.6` for 60%. Both 0 and 1 are valid maturity values. Do not insert units, totals, merged cells or prose inside the three data grids.

Excel 使用科学记数显示小数，例如 `5.1361E-02` 等于 `0.051361`；显示精度不会改变保存的底层数值。 / Scientific notation avoids displaying tiny positive values as zero; it does not round the stored values.

**体长边界与缺测期 / Bin boundaries and missing periods.** 本示例中心值是 6:50，每隔 2 cm；拟合时显式传入 22 个内部边界 7:49，首尾尾部按模型约定处理。自己的不等宽组应提供真实边界。区间标签如 `0-20`、`20-25` 要连续且不重叠；原标签若为 `0-20`、`21-25`，不能未经核实就消除间隙。缺整个年度时保留对应列并在调查表填 NA，重量和成熟表仍需完整；不要删掉这一列而假装时间间隔没变。

The example uses midpoints 6:50 by 2 and 22 explicit internal boundaries 7:49. Supply the actual boundaries for unequal bins. Interval labels must be contiguous and non-overlapping; do not silently close gaps in legacy labels. Retain an entirely missing period as an NA survey column while supplying weight and maturity, so the temporal grid remains regular.

## 5. 导入自己的实测数据 / Importing your observations

[real_data_workflow.R](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/scripts/real_data_workflow.R) 提供指南辅助函数，需 `source()`，不属于包的导出 API。Excel 读取采用 [readxl::read_excel](https://readxl.tidyverse.org/reference/read_excel.html)，保留原始年份表头并显式转换数值。

These are guide helpers, sourced from the repository, not package exports. The Excel reader preserves original time headers and converts numeric cells explicitly.

```r
install.packages("readxl") # 只需安装一次 / Install once
source("scripts/real_data_workflow.R", encoding = "UTF-8")
# 先用附带工作簿练习 / Start with the supplied workbook
my_inputs <- read_survey_excel("docs/data/ALSCL_Data_Entry_Example.xlsx")
validate_survey_tables(my_inputs, growth_step = 1, zero_action = "error")
# CSV 也可以，目录内需有三张同名 CSV / Three named CSV files also work
csv_inputs <- read_survey_csv("docs/data")
str(csv_inputs)
```

导入步骤只检查三表，不自动套用内置 YTF 的固定参数。完整的 x、参数分类、map 和双模型拟合见本节下方 5.2–5.3。 / Importing checks the three tables without applying the bundled YTF fixed-parameter configuration. Sections 5.2–5.3 below provide the complete x, parameter classification, maps and both fits.

换成自己的文件时，替换路径，并依据自己的物种设置 `rec.age`、`nage`、`M`、`sel_L50`、`sel_L95`、`growth_step`、边界及拟合初值/固定参数。不能因为输入表尺寸相同，就沿用 YTF 的生物参数或固定参数表。生长、长度重量关系、成熟信息和调查可捕性应有独立依据。

For your own workbook, replace the path and supply species-specific biology, boundaries, starts and fixed parameters. Equal table dimensions do not justify reusing YTF biology. Growth, weight, maturity and survey catchability need independent support.

`validate_survey_tables()` 默认遇到调查零值报错，要求先确认其含义。包的拟合入口默认 `zero_action="missing"`，把零值从对数似然中排除。如果零是真实的无捕获结果，排除它会改变推断；本包没有提供零膨胀观测模型，不应随意加小常数伪装为正数。

The guide validator rejects survey zeros by default. Package fits retain the historical default `zero_action="missing"`, excluding zeros from the log likelihood. Excluding genuine zero catches changes inference. This package does not implement a zero-inflated observation model; arbitrary small constants are not a principled substitute.

### 5.1 原有 `example_data` / Legacy data inspection

```r
data("example_data")
names(example_data)
head(example_data$data.CatL)
# 查看标签与零值，暂不盲目拟合 / Inspect bins and zeros before fitting
example_data$data.CatL[[1]]
sum(as.matrix(example_data$data.CatL[-1]) == 0, na.rm = TRUE)
```

这三张表从原 ALSCL 仓库原样保留，原说明称匿名调查数据，列为 2001–2021，9 个长度组。物种、单位、原始出处和零值含义没有得到核实，而且 `0-20`、`21-25` 等标签存在间隔。当前长度检查会拒绝这些不连续区间。读者应先补齐元数据和真实分组边界，不能把它标注成本文论文的已核实实测数据，也不能擅自改标签后给出正式评估。

The legacy tables are preserved unchanged from ALSCL. Their old help calls them anonymized survey data, but species, units, original source and zero meanings are unverified. Their gapped interval labels are rejected by the current bin parser. Recover metadata and actual boundaries before assessment; these are not verified empirical data from the cited paper.

### 5.2 参数与 map：正式分析前的设置 / Parameters and maps before assessment

#### 哪些输入需要自己提供

`parameters` 提供初值，或由 `map` 固定的参数取值。**填写一个数值本身不等于固定参数。** 以下数据和生物设置不会由任一拟合函数估计。

|输入|需要提供的内容|
|---|---|
|`data.CatL`|按体长和时间排列的调查数量或口径一致的标准化数量指数，不是总捕获重量|
|`data.wgt`, `data.mat`|与调查表对齐的平均单尾重量和成熟比例；作为已提供的值使用|
|`M`|有外部依据的每模型步长自然死亡率；年度瞬时率乘以 `growth_step`|
|`rec.age`, `nage`, `growth_step`|补充年龄（年）、包含加组的年龄组数、每步多少年|
|`sel_L50`, `sel_L95`|固定调查可捕性曲线的位置，L95 大于 L50；不是待估的捕捞选择性|
|`len_mid`, `len_border`|实际体长组中点和内部边界；核对任何从标签推导的值|

`map` 不能让 `M`、调查可捕性或年龄与分组定义变成待估参数：它们是当前模型的输入，不属于参数向量。模型不会自动传播这些输入的不确定性。请记录来源、单位和敏感性情景；脚本中的生物数值是演示设置，不是你研究种群的估计结果。

#### 哪些参数可以由模型估计

只要 map 允许，下表中的每个标量参数都可以参与估计。未提供的初值和边界使用套件默认值，部分初值会根据数据调整；仍需核对是否适合你的物种。`log_` 参数填写 `log(原尺度值)`，相关系数初值填写 `qlogis(rho)`，其中 `0 < rho < 1`；当前模型的这些相关系数限于正值。

|含义|ACL 名称|ALSCL 名称|
|---|---|---|
|用于初始年龄结构的总死亡率|`log_init_Z`|`log_init_Z`|
|初始对数数量偏差标准差|`log_std_log_N0`|`log_sigma_log_N0`|
|对数补充量的位置参数|`mean_log_R`|`mean_log_R`|
|补充过程标准差尺度|`log_std_log_R`|`log_sigma_log_R`|
|补充量时间相关性|`logit_log_R`|`logit_log_R`|
|对数捕捞死亡率的位置参数|`mean_log_F`|`mean_log_F`|
|捕捞死亡率过程标准差尺度|`log_std_log_F`|`log_sigma_log_F`|
|捕捞死亡率时间相关性|`logit_log_F_y`|`logit_log_F_y`|
|捕捞死亡率年龄／体长相关性|`logit_log_F_a`|`logit_log_F_l`|
|渐近体长和年度 VB 生长 k|`log_Linf`, `log_vbk`|`log_Linf`, `log_vbk`|
|VB t0|`t0`（原尺度）|`log_t0`（对数尺度）|
|年龄对应体长的 CV|`log_cv_len`|`log_cv_len`|
|生长增量 CV|无此参数|`log_cv_grow`|
|对数调查观测标准差|`log_std_index`|`log_sigma_index`|

`log_init_Z` 与输入的自然死亡率 `M` 不同。对数过程位置参数取指数不等于无条件算术均值。ACL 允许负的 `t0`；ALSCL 当前要求 `0 < t0 < rec.age`，不能把外部负 t0 取绝对值后使用。初值和 `parameters.L` / `parameters.U` 均采用优化器尺度；相等上下界会报错，固定参数请使用 map。

模型还会推断随机效应 `dev_log_R`、`dev_log_F` 和 `dev_log_N0`。它们的维度根据数据构建，不要加入标量初值列表。ACL 的 F 随年龄和年份变化，ALSCL 的 F 随体长和年份变化。这些随机效应不列在 `fit$opt$par` 中。

#### 如何设置 map 而不把参数都固定住

|设置|效果|
|---|---|
|`parameters = list(log_Linf = log(60))`|自由参数的初值；只有 map 固定它时才成为固定值|
|`map = list(log_Linf = factor(NA))`|将 Linf 固定在提供的值，未提供时使用其模型默认值|
|`map = list(log_std_log_F = NULL)`|解除 ACL 这一默认固定项，其他项仍按模型默认规则|
|`map = NULL` 或 `map = list()`|使用模型默认规则，不是全部开放估计|
|`run_acl(x)` / `run_alscl(x)` 不写 `map`|使用对应 `x$fit_config` 中保存的 map（如果存在）|

|模型|默认固定的标量参数|其余自由标量参数数目|
|---|---|---|
|ACL|`log_std_log_F`, `logit_log_F_y`, `logit_log_F_a`, `t0`|10|
|ALSCL|`log_sigma_log_F`, `log_t0`|13|

下方完整脚本使用 `map_acl <- list()` 和 `map_alscl <- list()`：**取消旧教学例子对生长、初始数量变异和补充量相关性等参数的额外固定**，保留上表列明的模型默认固定项。所有固定值仍需审查。默认设置是可复现的对照配置，不代表每个数据集都能识别全部自由参数。

本脚本仍固定的标量取值为：两个模型的 F 过程标准差 0.2、t0 = 1/60，以及 ACL 跨年份和跨年龄的 F 相关系数 0.75（这两个固定相关参数的套件初值）。这些数值也必须按你的种群审查。脚本使用两轮连续优化（`train_times = 2`），不是两个独立起点。

不修改旧 x，也可以直接取消其中额外的教学固定设置：

```r
fit_acl <- run_acl(x, map = NULL)
fit_alscl <- run_alscl(x, map = NULL)
```

如果只固定 t0、估计其余标量参数，需要显式解除其他默认固定项。将 map 保存回 x 后仍可直接调用：

```r
x$fit_config$acl$map <- list(
  t0 = factor(NA), log_std_log_F = NULL,
  logit_log_F_y = NULL, logit_log_F_a = NULL)
x$fit_config$alscl$map <- list(
  log_t0 = factor(NA), log_sigma_log_F = NULL)
# 先审查 parameters 中保存的 t0 / log_t0 取值。
fit_acl <- run_acl(x)
fit_alscl <- run_alscl(x)
# ACL 有 13 个自由标量参数，ALSCL 有 14 个。
```

这组更灵活的设置是可选方案，不是下方配图使用的基线。若 t0 也需要估计，应保留具名 NULL 项：

```r
x$fit_config$acl$map["t0"] <- list(NULL)
x$fit_config$alscl$map["log_t0"] <- list(NULL)
# 下次拟合时，全部 14 / 15 个标量参数均自由。
```

不要用 `map$t0 <- NULL` 解除默认固定的 t0：它会删除条目，随后默认规则会再次固定 t0。解除列表应直接传给 `run_*()` 或保存在 x 中。`generate_map()` 仅使用 ACL 默认规则，而且返回值会移除 NULL 项；将其结果再交给 `run_acl()` 会重新补入缺失的默认项，可能撤销原本的解除设置。

显式传入的 `map` 会整体替换 x 中原有 map，然后应用模型默认规则。若只修改保存的一个项目并保留其他设置，例如使用 `x$fit_config$acl$map["log_Linf"] <- list(NULL)`。正式分析不要对每个初值自动应用 `factor(NA)` 来生成 map。

拟合后检查实际自由参数和诊断：

```r
names(fit_acl$opt$par)
fit_acl$par_low_up
names(fit_alscl$opt$par)
fit_alscl$par_low_up
diagnose_model(x$data.CatL, fit_acl)
diagnose_model(x$data.CatL, fit_alscl)
```

同时检查优化码、梯度、Hessian、边界、估计不确定性和残差。将逐组解除的配置分别保存并比较诊断；增加优化次数或起点数不能让缺乏信息的参数变得可识别。较少固定项的拟合可能暴露旧教学设置掩盖的问题，应报告这些问题，不能为了得到好看的诊断而悄悄增加固定项。

#### Inputs you must supply

`parameters` supplies starting values, or the values of parameters fixed by `map`. **Supplying a number does not itself fix a parameter.** The input data and biological settings below are not estimated by either fitting function.

|Input|What you must provide|
|---|---|
|`data.CatL`|Survey numbers or a consistently standardized number index by length and time; not total catch weight|
|`data.wgt`, `data.mat`|Aligned mean individual weights and mature proportions; these are treated as supplied values|
|`M`|Natural mortality per model step, supported by external information; annual instantaneous M multiplied by `growth_step`|
|`rec.age`, `nage`, `growth_step`|Recruitment age in years, number of age classes including the plus group, and years per step|
|`sel_L50`, `sel_L95`|Locations of the fixed survey catchability curve, with L95 greater than L50; not estimated fishery selectivity|
|`len_mid`, `len_border`|Actual bin midpoints and internal boundaries; verify any values inferred from labels|

Changing `map` cannot make `M`, survey catchability or the age/bin definitions estimable: they are model inputs, not entries in the current parameter vector. Their uncertainty is not propagated automatically. Record sources, units and sensitivity scenarios. The script's biological values are illustrative, not estimates for your stock.

#### Parameters the models can estimate

Every scalar parameter below can be estimated if its map allows it. Unspecified starting values and bounds use package defaults, with some starts adapted to the data. Check their suitability for your species. `log_` values use `log(value)` and correlation starts use `qlogis(rho)` for `0 < rho < 1`; the current models restrict these correlations to positive values.

|Meaning|ACL name|ALSCL name|
|---|---|---|
|Initial total mortality setting the initial age structure|`log_init_Z`|`log_init_Z`|
|Initial log-number deviation SD|`log_std_log_N0`|`log_sigma_log_N0`|
|Log recruitment location|`mean_log_R`|`mean_log_R`|
|Recruitment process SD scale|`log_std_log_R`|`log_sigma_log_R`|
|Recruitment time correlation|`logit_log_R`|`logit_log_R`|
|Log fishing-mortality location|`mean_log_F`|`mean_log_F`|
|Fishing-mortality process SD scale|`log_std_log_F`|`log_sigma_log_F`|
|Fishing-mortality time correlation|`logit_log_F_y`|`logit_log_F_y`|
|Fishing-mortality age / length correlation|`logit_log_F_a`|`logit_log_F_l`|
|Asymptotic length and annual VB growth k|`log_Linf`, `log_vbk`|`log_Linf`, `log_vbk`|
|VB t0|`t0` (untransformed)|`log_t0` (log scale)|
|Length-at-age CV|`log_cv_len`|`log_cv_len`|
|Growth-increment CV|Not present|`log_cv_grow`|
|Log survey observation SD|`log_std_index`|`log_sigma_index`|

`log_init_Z` is distinct from the supplied natural mortality `M`. Exponentiating a log-process location is not the unconditional arithmetic mean. ACL allows negative `t0`; ALSCL currently requires `0 < t0 < rec.age`. Do not replace a negative external t0 by its absolute value. Starts and `parameters.L` / `parameters.U` use the optimizer scale; equal bounds are rejected, so use a map to fix a parameter.

The models also infer random effects `dev_log_R`, `dev_log_F` and `dev_log_N0`. Their dimensions are constructed from the data; do not add them to the scalar starting-value list. F varies over ages and years in ACL, and lengths and years in ALSCL. These random effects are not listed in `fit$opt$par`.

#### Set map without fixing everything

|Setting|Effect|
|---|---|
|`parameters = list(log_Linf = log(60))`|A starting value if free; a fixed value only if the map fixes it|
|`map = list(log_Linf = factor(NA))`|Fix Linf at the supplied value, or its model default when omitted|
|`map = list(log_std_log_F = NULL)`|Release this default-fixed ACL parameter; keep other model defaults|
|`map = NULL` or `map = list()`|Apply model defaults, not an all-free model|
|Omit `map` in `run_acl(x)` / `run_alscl(x)`|Use the map stored in the selected `x$fit_config`, if present|

|Model|Default-fixed scalar parameters|Other free scalar parameters|
|---|---|---|
|ACL|`log_std_log_F`, `logit_log_F_y`, `logit_log_F_a`, `t0`|10|
|ALSCL|`log_sigma_log_F`, `log_t0`|13|

The complete script below uses `map_acl <- list()` and `map_alscl <- list()`: **it removes the previous teaching-only fixes on growth, initial-number variability and recruitment correlation**, while retaining the documented model defaults. All fixed values still require review. The defaults are a reproducible baseline, not proof of identifiability for every dataset.

The remaining fixed scalar values in this script are F-process SD 0.2 and t0 = 1/60 in both models, plus F correlations 0.75 across years and ages in ACL (the package starting values for those two fixed correlations). These numbers must also be reviewed for your stock. The script uses two successive optimization passes (`train_times = 2`); this is not two independent starts.

To remove an older bundle's extra fixed assumptions without editing it:

```r
fit_acl <- run_acl(x, map = NULL)
fit_alscl <- run_alscl(x, map = NULL)
```

To fix only t0 and estimate all remaining scalar parameters, explicitly release the other defaults. Save the maps in `x` to retain the direct-call syntax:

```r
x$fit_config$acl$map <- list(
  t0 = factor(NA), log_std_log_F = NULL,
  logit_log_F_y = NULL, logit_log_F_a = NULL)
x$fit_config$alscl$map <- list(
  log_t0 = factor(NA), log_sigma_log_F = NULL)
# Review the t0 / log_t0 values already stored in parameters first.
fit_acl <- run_acl(x)
fit_alscl <- run_alscl(x)
# 13 free scalar parameters in ACL; 14 in ALSCL.
```

This more flexible configuration is an option, not the baseline used for the figures. If t0 should also be estimated, preserve an explicit named NULL:

```r
x$fit_config$acl$map["t0"] <- list(NULL)
x$fit_config$alscl$map["log_t0"] <- list(NULL)
# All 14 / 15 scalar parameters are now free on the next fit.
```

Do not use `map$t0 <- NULL` to release default-fixed t0: it deletes the entry and the default will fix it again. Pass release lists directly to `run_*()` or store them in `x`. `generate_map()` is ACL-specific and removes NULL entries from its result; feeding that result back into `run_acl()` re-applies absent defaults and can undo a release.

Explicit `map` arguments replace the whole map stored in `x`, after which model defaults are applied. To change one stored entry while preserving the rest, use `x$fit_config$acl$map["log_Linf"] <- list(NULL)`, for example. Do not generate a map by applying `factor(NA)` to every supplied start for an empirical assessment.

After fitting, inspect the actual free parameters and diagnostics:

```r
names(fit_acl$opt$par)
fit_acl$par_low_up
names(fit_alscl$opt$par)
fit_alscl$par_low_up
diagnose_model(x$data.CatL, fit_acl)
diagnose_model(x$data.CatL, fit_alscl)
```

Check the optimizer code, gradient, Hessian, boundary hits, uncertainty and residuals together. Release parameter groups in separate, saved configurations and compare diagnostics; increasing optimizer iterations or the number of starts does not make weakly identified parameters identifiable. The more flexible map may expose problems that a heavily fixed teaching fit hid. Report those problems rather than silently fixing additional parameters to obtain a favorable diagnostic.

### 5.3 完整 CSV → x → 双模型示例 / Complete CSV-to-both-models example

2.2.2 新增完整脚本 [fit_own_data_example.R](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/scripts/fit_own_data_example.R)。先从仓库根目录运行下面的教学流程，再修改数据路径、生物参数、体长边界、初值及固定参数。内附数据是模拟数据，不能只换观测文件便沿用其固定假设。

Version 2.2.2 adds a complete executable script. Run the teaching workflow from the repository root, then replace the data, biology, bin definitions, initial values and fixed assumptions for your stock. The bundled observations are synthetic; changing only the input file does not justify retaining their conditional settings.

`x` 包含三表、共用 `fit_args`，以及 `fit_config$acl` 和 `fit_config$alscl`。两个模型共用观测，自动选择自己的配置；显式传参优先，内置加速继续生效。

`x` contains the three tables, shared `fit_args`, and separate `fit_config$acl` and `fit_config$alscl`. Both models use the same observations and select their own settings. Explicit call arguments take precedence and built-in acceleration remains active.

```r
source("scripts/fit_own_data_example.R", encoding = "UTF-8")
```

以下为完整脚本 / Complete script:

```r
# ALSCL 2.2.2: CSV -> x -> ACL / ALSCL -> diagnostics and saved summaries.
# 从仓库根目录运行 / Run from the repository root:
# source("scripts/fit_own_data_example.R", encoding = "UTF-8")
# 默认读取内附模拟数据。正式分析必须修改第 1、2、3 步。
# The supplied numbers describe the synthetic YTF example, not your stock.

library(ALSCL)
stopifnot(packageVersion("ALSCL") >= "2.2.2")
source("scripts/real_data_workflow.R", encoding = "UTF-8")

# 1. 读取三表 / Read the three aligned tables -------------------------------
# 正式数据改成 "my_data"，其中放以下三个 CSV：
# data.CatL.csv, data.wgt.csv, data.mat.csv.
data_dir <- "docs/data"
inputs <- read_survey_csv(data_dir)
# Excel 可替换上一行 / Excel alternative (requires readxl):
# inputs <- read_survey_excel("my_survey.xlsx")

# 2. 共用生物设置 / Shared biology -----------------------------------------
# 以下是年度 YTF 教学值，正式数据必须采用自己的生物学依据。
# M_annual and vbk are annual; lengths are cm; weights in the example are kg.
bio <- list(rec.age = 1, nage = 15, M_annual = 0.2,
            growth_step = 1, sel_L50 = 15, sel_L95 = 20,
            Linf = 60, vbk = 0.2, t0 = 1 / 60,
            cv_len = 0.2, cv_grow = 0.2)
# 当前 ALSCL 使用 log_t0，故要求 0 < t0 < rec.age；不要对负 t0 取绝对值。
stopifnot(bio$t0 > 0, bio$t0 < bio$rec.age)

# 此例 LengthBin 填数值中点：6, 8, ..., 50。
# For labels such as "5-7", supply the actual midpoints explicitly instead.
len_mid <- as.numeric(inputs$data.CatL[[1]])
stopifnot(all(is.finite(len_mid)), all(diff(len_mid) > 0))
# 此例为连续等宽组；非等宽组请直接填写实测的 nlen-1 个内部边界。
# This midpoint formula is only used for the equal-width demonstration bins.
stopifnot(max(abs(diff(len_mid) - diff(len_mid)[1])) < 1e-8)
len_border <- (head(len_mid, -1) + tail(len_mid, -1)) / 2
validate_survey_tables(inputs, growth_step = bio$growth_step, zero_action = "error")

# 3. 各模型拟合设置 / Model-specific settings ------------------------------
# 生长和多数过程参数作为初值，不再自动固定每个提供的参数。
# Growth and most process values below are starts, not automatic fixes.
# Review starts, bounds and the documented default fixed values for your stock.
p_acl <- list(
  log_Linf = log(bio$Linf), log_vbk = log(bio$vbk), t0 = bio$t0,
  log_cv_len = log(bio$cv_len),
  log_std_log_F = log(0.2), log_std_log_N0 = log(0.2),
  logit_log_R = qlogis(0.1))
p_alscl <- list(
  log_Linf = log(bio$Linf), log_vbk = log(bio$vbk), log_t0 = log(bio$t0),
  log_cv_len = log(bio$cv_len), log_cv_grow = log(bio$cv_grow),
  log_sigma_log_F = log(0.2), log_sigma_log_N0 = log(0.2),
  logit_log_R = qlogis(0.1))
# 使用模型默认 map：ACL 固定 4 项、估计 10 项；ALSCL 固定 2 项、估计 13 项。
# Default maps: ACL fixes 4 and estimates 10 scalars; ALSCL fixes 2 and estimates 13.
# ACL fixes log_std_log_F, logit_log_F_y, logit_log_F_a and t0.
# ALSCL fixes log_sigma_log_F and log_t0. These values still need justification.
map_acl <- list()
map_alscl <- list()
# 可选：只固定 t0；更灵活的设置必须另做诊断，不保证可识别。
# Optional: fix only t0; diagnose this more flexible configuration separately.
# map_acl <- list(t0 = factor(NA), log_std_log_F = NULL,
#                 logit_log_F_y = NULL, logit_log_F_a = NULL)
# map_alscl <- list(log_t0 = factor(NA), log_sigma_log_F = NULL)
# 解除默认固定项需保留具名 NULL；$t0 <- NULL 仅删除条目。
# Preserve a named NULL to release a default fix; $t0 <- NULL deletes the entry.
# map_acl["t0"] <- list(NULL)
# map_alscl["log_t0"] <- list(NULL)

# 4. 组装 x / Assemble the input bundle -----------------------------------
x <- list(
  data.CatL = inputs$data.CatL,
  data.wgt = inputs$data.wgt,
  data.mat = inputs$data.mat,
  fit_args = list(
    rec.age = bio$rec.age, nage = bio$nage,
    M = bio$M_annual * bio$growth_step,
    sel_L50 = bio$sel_L50, sel_L95 = bio$sel_L95,
    growth_step = bio$growth_step,
    len_mid = len_mid, len_border = len_border,
    zero_action = "error", train_times = 2,
    nstarts = 1, ncores = 1, silent = FALSE),
  fit_config = list(
    acl = list(parameters = p_acl, map = map_acl),
    alscl = list(parameters = p_alscl, map = map_alscl)))

# 5. 直接拟合 / Fit directly ----------------------------------------------
# 内置加速使用当前 alscl_speed() 设置，无需额外包装。
alscl_speed_info()
a <- run_acl(x)
b <- run_alscl(x)
# 可直接覆盖设置；固定 nstarts 才能公平比较并行数：
# a <- run_acl(x, nstarts = 4, ncores = 2)
# b <- run_alscl(x, nstarts = 4, ncores = 2)

# 6. 检查、绘图、保存 / Inspect, plot and save ------------------------------
checks <- list(ACL = diagnose_model(x$data.CatL, a),
               ALSCL = diagnose_model(x$data.CatL, b))
print(checks)
print(a$sd_info)
print(b$sd_info)
for (fit in list(a, b)) {
  print(fit$par_low_up) # 实际自由参数及边界 / Actual free scalars and bounds
  print(list(convergence = fit$convergence_code,
             max_gradient = fit$max_abs_gradient,
             pdHess = fit$pdHess, bound_hit = fit$bound_hit))
  print(fit$refinement)
  print(fit$diagnostics)
  if (!isTRUE(fit$convergence_code == 0L) || !isTRUE(fit$pdHess) ||
      !isTRUE(fit$diagnostics$numerical_ok))
    warning("Review fit diagnostics before interpreting this assessment.")
}
residual_plot <- plot_residuals(b, type = "year", facet_ncol = 4,
                                x_breaks = pretty(len_mid, n = 4))
# 非正定 Hessian 时不展示标准误区间 / Omit SE intervals if Hessian is not positive definite.
ssb_plot <- plot_SSB(b, se = isTRUE(b$pdHess))
print(residual_plot)
print(ssb_plot)
# obj 是当前会话的 TMB 指针，不包含在可移植结果中。
portable <- function(fit) fit[setdiff(names(fit), "obj")]
output_dir <- "output/own-data-example"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
ggplot2::ggsave(file.path(output_dir, "residuals.png"), residual_plot,
                width = 10, height = 8, dpi = 150)
ggplot2::ggsave(file.path(output_dir, "SSB.png"), ssb_plot,
                width = 8, height = 5, dpi = 150)
saveRDS(x, file.path(output_dir, "inputs_x.rds"))
saveRDS(list(ACL = portable(a), ALSCL = portable(b), diagnostics = checks),
        file.path(output_dir, "assessment_summary.rds"))
writeLines(capture.output(sessionInfo()), file.path(output_dir, "sessionInfo.txt"))
# 新会话可读取 x 并重新拟合 / Refit in a new session:
# x <- readRDS("output/own-data-example/inputs_x.rds")
# b <- run_alscl(x)
```

实测的模拟 CSV 流程中，ACL 与 ALSCL 都得到收敛码 0、正定 Hessian、无边界命中及小于 0.001 的最大梯度。以下图由该脚本生成。正式数据仍需独立诊断与敏感性检查。

Both models completed the synthetic CSV workflow with convergence code 0, a positive-definite Hessian, no boundary hits and maximum gradients below 0.001. These figures come from that run; empirical assessments require their own diagnostics and sensitivity checks.

更新后的脚本使用模型默认 map、两轮连续优化重新运行，保存的[诊断记录](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/own-data-example-checks.csv)如下：

|模型|自由标量参数|收敛码|最大梯度|Hessian 正定|命中边界|
|---|---|---|---|---|---|
|ACL|10|0|2.62e-9|是|否|
|ALSCL|13|0|2.59e-9|是|否|

2.2.2 此次运行使用 4 核计算标准误，并启用默认受保护的收尾。这是模拟数据的数值检查，不是对尚未提供的正式评估的验证。加入收尾前（2.2.1），只固定 t0 的 ALSCL 可能在相同最优点误报 false convergence；2.2.2 保留先前成功轮次，并将梯度修正至约 5.37e-9。原 F 结构下只固定 t0 的 ACL 仍存在年龄相关边界，不能通过数值筛查；改用共用 F 是另一项生物学模型选择，下文说明。

The updated script was rerun with the model-default maps and two successive optimization passes. The recorded [diagnostics](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/own-data-example-checks.csv) are:

|Model|Free scalars|Convergence code|Maximum gradient|Positive-definite Hessian|Boundary hit|
|---|---|---|---|---|---|
|ACL|10|0|2.62e-9|Yes|No|
|ALSCL|13|0|2.59e-9|Yes|No|

The 2.2.2 run used four cores for standard errors and the default safeguarded refinement. These are numerical checks of synthetic data, not validation of an unseen stock assessment. Before refinement was added (2.2.1), the t0-only ALSCL fit could return false convergence at an unchanged optimum. Version 2.2.2 retains the successful earlier pass and refines its gradient to about 5.37e-9. The t0-only ACL with the original F structure still has an age-correlation boundary and fails the numerical screen; choosing shared F is a separate biological model decision, described below.

![CSV 示例残差 / CSV example residuals](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/own-data-example/residuals.png?raw=true)

![CSV 示例亲体生物量 / CSV example spawning biomass](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/own-data-example/SSB.png?raw=true)

详细的修改步骤 / Detailed adaptation instructions: [简体中文](https://fanzhang-lab-shou.github.io/ALSCL/zh/articles/case-fit-survey.html) · [English](https://fanzhang-lab-shou.github.io/ALSCL/articles/case-fit-survey.html).



---

[← 上一章 · Previous](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/02-Theory) · [目录 · Contents](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [下一章 · Next →](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/04-Built-in-YTF)
