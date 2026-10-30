# 如何把自己的正式数据整理成 x？

## 输入列表的结构

ALSCL 2.2.3 提供了[完整可执行脚本](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/scripts/fit_own_data_example.R)：读取 CSV 或 Excel 三表、组装 `x`、直接调用 `run_acl(x)` 和 `run_alscl(x)`、检查诊断、绘图并保存结果。演示使用内附的模拟 YTF 数据。**换成正式数据时，必须修改第 1–3 步的数据、生物参数、参数边界和固定假设，不能只换文件路径。**

|x 中的字段|内容|
|---|---|
|`data.CatL`|按体长和时间排列的调查数量或口径一致的标准化数量指数|
|`data.wgt`|平均单尾重量，不是该组总捕获重量|
|`data.mat`|成熟比例，取值为零到一|
|`fit_args`|共用生物参数、时间步、体长分组与拟合控制|
|`fit_config$acl`|ACL 的初值、可选边界与 map|
|`fit_config$alscl`|ALSCL 的初值、可选边界与 map|

两个函数读取相同三表与共用设置，再选择对应模型配置。调用时显式传参优先级最高；列表参数会整体替换已有列表。具体规则见[输入列表与参数覆盖](first-model.html)。

## 准备三张表

把 `data.CatL.csv`、`data.wgt.csv` 和 `data.mat.csv` 放在同一文件夹。三表都以 `LengthBin` 为第一列，其余表头为数值时间；维度、标签和顺序必须一致。示例的标签是数值体长中点。年度或季度序列应保留所有规则时间点；调查缺测填写 `NA`，体重和成熟比例仍须完整。不要把缺失观测改成零。

也可以使用 [Excel 模板](../assets/manual/data/ALSCL_Data_Entry_Example.xlsx)，工作表名称分别为 `data.CatL`、`data.wgt` 和 `data.mat`。另外记录物种、指数标准化方法、单位、体长边界及零值含义。

![调查数量：模拟工作簿格式](../assets/manual/figures/excel_CatL.png)

![平均单尾重量：模拟工作簿格式](../assets/manual/figures/excel_wgt.png)

![成熟比例：模拟工作簿格式](../assets/manual/figures/excel_mat.png)

这些图片展示内附模拟数据，不是你的研究种群的实测结果。体长和重量单位必须在整个分析中保持一致。

## 哪些输入需要自己提供

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

## 哪些参数可以由模型估计

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

## 如何设置 map 而不把参数都固定住

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

## 运行完整示例

安装 ALSCL 2.2.3 并下载仓库，从仓库根目录运行。导入辅助函数属于仓库脚本，不是安装包的导出函数。读取 CSV 不需要额外读取器；读取 Excel 时先安装一次 `readxl`。

```r
library(ALSCL)
packageVersion("ALSCL")
source("scripts/fit_own_data_example.R", encoding = "UTF-8")
```

脚本创建 `x`、`a`（ACL）和 `b`（ALSCL），并在 `output/own-data-example` 保存输入、可移植结果摘要、两张 PNG 图和会话信息。正式分析时也应修改输出目录。下面是完整代码，可复制为 R 脚本，也可直接修改配套文件。

```r
# ALSCL 2.2.3: CSV -> x -> ACL / ALSCL -> diagnostics and saved summaries.
# 从仓库根目录运行 / Run from the repository root:
# source("scripts/fit_own_data_example.R", encoding = "UTF-8")
# 默认读取内附模拟数据。正式分析必须修改第 1、2、3 步。
# The supplied numbers describe the synthetic YTF example, not your stock.

library(ALSCL)
stopifnot(packageVersion("ALSCL") >= "2.2.3")
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

## 替换成自己的正式数据

1. **文件：**把 `data_dir` 改为自己的 CSV 文件夹，例如 `"my_data"`。读取 Excel 则改用 `read_survey_excel("my_survey.xlsx")`。保留数值时间表头，辅助函数会避免 R 自动将 `2000` 改名为 `X2000`。
2. **生物参数与单位：**修改 `bio`。`rec.age` 以年为单位，`nage` 是含加组的年龄组数量。年度序列使用 `growth_step = 1`；规则季度表头如 `2020`、`2020.25`、`2020.5`、`2020.75`，使用 `0.25`。脚本将年瞬时自然死亡率乘以时间步长度，得到每步 `M`；生长参数 `vbk` 仍以年为单位。`sel_L50`、`sel_L95` 表示调查可捕性，不是待估的渔业选择性。
3. **体长组：**填写真实的 `len_mid` 和 `len_border`。示例按中点计算边界，仅适用于其中连续等宽的体长组。内部边界数应比体长组数少一，首尾尾部由模型处理。若标签为 `"5-7"` 这类区间，本脚本需要另外填写数值中点向量。
4. **模型假设：**审查 `p_acl`、`p_alscl`、边界和 map。新版例子使用模型默认 map，ACL 估计 10 个、ALSCL 估计 13 个标量参数，不再额外固定生长等参数。默认仍固定的值需要外部依据和敏感性检查。具名 NULL 可解除默认固定项，详见上文。可在对应 `fit_config` 中添加 `parameters.L` 和 `parameters.U`。
5. **零值与缺失：**脚本设置 `zero_action = "error"`，遇到调查零值先停止。确认含义后再决定处理方式；`"missing"` 会把零值从似然中排除。不要随意添加极小常数。参见[数据准备](data-preparation.html)。

ACL 使用原尺度 `t0`，ALSCL 使用 `log_t0`，当前要求 `0 < t0 < rec.age`。不要对负的外部 t0 估计取对数或绝对值以强行兼容。两个模型的若干方差参数名称也不同，不能直接互换整套参数列表。

## 直接拟合与检查加速

组装好自己的 `x` 后，调用仍然很简单：

```r
a <- run_acl(x)
b <- run_alscl(x)
# 相同总工作量：四个独立起点，最多两个并行进程
a_multi <- run_acl(x, nstarts = 4, ncores = 2)
b_multi <- run_alscl(x, nstarts = 4, ncores = 2)
# 实际标准误计算方式与核心数
a$sd_info
b$sd_info
```

现有 `alscl_speed()` 设置自动生效。`ncores` 控制独立优化起点的并行数，`sd_cores` 控制单次拟合的标准误计算。默认自动微分框架仍为 CppAD。小任务使用更多进程不保证更快，详见[加速设置](speed.html)。

## 检查结果

分别检查收敛码、最大梯度、Hessian、参数边界及残差模式。运行结束不代表所有参数都可识别或模型假设成立。完整模拟 CSV 流程已对两个模型实际运行：收敛码均为 0，Hessian 正定，没有命中参数边界，最大梯度低于 0.001。这验证的是示例流程，不是尚未提供的正式数据评估。

下面两张图由该脚本用模拟 CSV 输入实际生成。

更新后的脚本使用模型默认 map、两轮连续优化重新运行，保存的[诊断记录](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/own-data-example-checks.csv)如下：

|模型|自由标量参数|收敛码|最大梯度|Hessian 正定|命中边界|
|---|---|---|---|---|---|
|ACL|10|0|2.62e-9|是|否|
|ALSCL|13|0|2.59e-9|是|否|

2.2.2 此次运行使用 4 核计算标准误，并启用默认受保护的收尾。这是模拟数据的数值检查，不是对尚未提供的正式评估的验证。加入收尾前（2.2.1），只固定 t0 的 ALSCL 可能在相同最优点误报 false convergence；2.2.2 保留先前成功轮次，并将梯度修正至约 5.37e-9。原 F 结构下只固定 t0 的 ACL 仍存在年龄相关边界，不能通过数值筛查；改用共用 F 是另一项生物学模型选择，下文说明。

![完整 CSV 示例的 ALSCL 年度残差](../assets/manual/figures/own-data-example/residuals.png)

![完整 CSV 示例的 ALSCL 产卵亲体生物量](../assets/manual/figures/own-data-example/SSB.png)

亲体生物量区间以固定的模型假设为条件。正式分析应检查自己的图，并对有依据的 M、调查可捕性及固定生物参数做敏感性分析。

## 保存并复用 x

脚本保存 `inputs_x.rds`、`assessment_summary.rds`、`residuals.png`、`SSB.png` 和 `sessionInfo.txt`。可移植摘要不包含 `obj`，因为其 TMB 指针只属于当前 R 会话。在新会话中可重新拟合：

```r
library(ALSCL)
x <- readRDS("output/own-data-example/inputs_x.rds")
a <- run_acl(x)
b <- run_alscl(x)
```

将原始数据、配置、来源和包版本一起保留。旧的 `fit_survey_tables()` 辅助函数、逐项传参和 `do.call()` 写法继续支持。

## 在 2.2.3 中继续比较和回溯

从 2.2.3 起，两个核心拟合函数直接检查时间网格：相邻数值表头之差必须等于 `growth_step`。年度数据 `2000, 2001, 2003` 会因缺少 2002 而报错；应保留 2002 列，调查值填 `NA`，并提供该期完整的重量和成熟数据。季度表头如 `2000, 2000.25, 2000.5` 必须设置 `growth_step = 0.25`。模型不会自动插补缺失时间步，也不会把不规则间隔重新解释为等间隔。

```r
comparison <- compare_models(a, b, x$data.CatL)
comparison$fit_diagnostics
comparison$comparison
ra <- retro_acl(x, nyear = 3, train_times = 2, silent = TRUE)
rb <- retro_alscl(x, nyear = 3, train_times = 2, silent = TRUE)
rb$fit_diagnostics
rb$rho_by_peel
rb$rho_text
plot_fishing_mortality(b, type = "length", se = TRUE)
```

2.2.3 的 `compare_models()` 会核对两个拟合与传入调查表的时间标签、体长标签及顺序、正观测值和观测掩码；确认不一致时直接报错。旧保存结果若缺少核对所需元数据，仍可读取原始统计量，但不自动给出模型偏好。任一拟合未通过数值筛查时，函数发出警告，保留原始 AIC/BIC 和拟合指标供检查，不宣布哪个模型更优。查看 `comparison$fit_diagnostics` 与 `comparison$comparison`（`data_verified`、`eligible`、`preferred`、`issues`）。通过筛查只表示可以开展条件比较，仍需审查似然可比性和生物假设。

`fit_diagnostics` 保存完整拟合（`Peel = 0`）和每个请求的截短拟合，包含耗时、原始优化状态、梯度、Hessian、边界与错误。`rho_by_peel` 包含筛查后的 `Rho`、诊断用的 `RawRho` 及 `Valid`。只有完整拟合和所有请求的截短拟合都通过数值筛查，且所有末端比较有限、参考值非零时，才在 `rho_text$Rho` 中报告该指标的 rho；否则返回 `NA` 并警告，不会悄悄删除失败的截短结果。`raw_rho_text` 是未经筛查的诊断汇总，不能替代正式报告值；若任一末端比较缺失，它仍为 `NA`。可用轨迹保留在 `results` 中供检查。

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

此前模拟 YTF 数据的只固定 t0 ACL 拟合中，年龄相关系数逼近 1；生成数据恰好在同一年对所有年龄使用相同 F，共用 F 结构可处理这种不匹配。只固定 t0 的 ALSCL 则主要受优化收尾误报影响。两项发现都不代表你的正式数据能识别全部参数。实测结果与适用限制见 [2.2.2 可复现验证](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/RELEASE_2.2.2.md)。

![2.2.2 convergence checks](../assets/manual/figures/convergence-2.2.2.png)

### 2.2.5 的拟合数据匹配检查

`diagnostic_metrics()`、`diagnose_model()` 和 `compare_models()` 核对已知时间标签、体长标签、正观测掩码及拟合时保存的观测。即使维度相同，颠倒年份或体长组顺序也会报错。请传原始拟合表，例如 `diagnose_model(x$data.CatL, b)`；这些是样本内诊断，不是留出预测接口。缺少元数据的旧结果仍可计算原始指标，但不能据此确认模型可比较。

比较表和指标图共用计算规则：只使用有限正观测，常数观测的 R 方为 `NA`，观测位置的原尺度预测非有限时会报错；缺测与零值仍被排除。通过这些检查不代表模型在生物学上充分。

### 2.2.7 的体长组边界

模型首尾体长组吸收分布尾部。`len_border` 只包含内部边界，`len_mid` 是每组递增的中心值。ALSCL 可以省略 `len_lower` 和 `len_upper`，由内部边界生成；若显式提供，必须分别为 `c(-Inf, len_border)` 和 `c(len_border, Inf)`。显式有限外端点会被拒绝，不会实现有限截断的体长分布。`0-20` 等有限区间标签仍可使用，但遵循原有首尾组吸收尾部的约定。

```r
# x 是调查数据示例中已对齐的输入组合。
borders <- x$fit_args$len_border
if (!is.null(borders)) {
  fit <- run_alscl(x, len_lower = c(-Inf, borders),
                  len_upper = c(borders, Inf))
}
```

### 一致性修正

拟合、诊断和模型比较统一解析普通 data.frame、matrix、tibble 及保存数值文本的 factor 列。因子按标签转为观测值，不使用内部等级编码；体长标签按向量提取。修改了观测值、缺测掩码、年份或体长组顺序时，原有匹配检查仍会报错。
