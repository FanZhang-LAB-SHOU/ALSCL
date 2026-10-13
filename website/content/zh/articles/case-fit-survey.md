# 如何把自己的正式数据整理成 x？

## 输入列表的结构

ALSCL 2.2.1 提供了[完整可执行脚本](https://github.com/Linbojun99/ALSCL/blob/main/scripts/fit_own_data_example.R)：读取 CSV 或 Excel 三表、组装 `x`、直接调用 `run_acl(x)` 和 `run_alscl(x)`、检查诊断、绘图并保存结果。演示使用内附的模拟 YTF 数据。**换成正式数据时，必须修改第 1–3 步的数据、生物参数、参数边界和固定假设，不能只换文件路径。**

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

## 运行完整示例

安装 ALSCL 2.2.1 并下载仓库，从仓库根目录运行。导入辅助函数属于仓库脚本，不是安装包的导出函数。读取 CSV 不需要额外读取器；读取 Excel 时先安装一次 `readxl`。

```r
library(ALSCL)
packageVersion("ALSCL")
source("scripts/fit_own_data_example.R", encoding = "UTF-8")
```

脚本创建 `x`、`a`（ACL）和 `b`（ALSCL），并在 `output/own-data-example` 保存输入、可移植结果摘要、两张 PNG 图和会话信息。正式分析时也应修改输出目录。下面是完整代码，可复制为 R 脚本，也可直接修改配套文件。

```r
# ALSCL 2.2.1: CSV -> x -> ACL / ALSCL -> diagnostics and saved summaries.
# 从仓库根目录运行 / Run from the repository root:
# source("scripts/fit_own_data_example.R", encoding = "UTF-8")
# 默认读取内附模拟数据。正式分析必须修改第 1、2、3 步。
# The supplied numbers describe the synthetic YTF example, not your stock.

library(ALSCL)
stopifnot(packageVersion("ALSCL") >= "2.2.1")
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
# 下面是模拟示例中已知的条件设置；不要直接当作正式数据的固定值。
# For observations, review starts, bounds and every fixed parameter independently.
# Other parameters use the package's default starts, bounds and maps.
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
# factor(NA) 固定在给定值；这些固定假设不贡献估计不确定性。
map_acl <- lapply(p_acl, function(z) factor(NA))
map_alscl <- lapply(p_alscl, function(z) factor(NA))
map_alscl$logit_log_F_l <- map_alscl$logit_log_F_y <- factor(NA)
# 显式 NULL 可释放某一项，包括模型默认固定的项：
# map_acl["log_Linf"] <- list(NULL)
# map_alscl["log_Linf"] <- list(NULL)
# 注意：map_acl$log_Linf <- NULL 是删除条目，含义不同。

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
    zero_action = "error", train_times = 1,
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
  print(list(convergence = fit$convergence_code,
             max_gradient = fit$max_abs_gradient,
             pdHess = fit$pdHess, bound_hit = fit$bound_hit))
}
residual_plot <- plot_residuals(b, type = "year", facet_ncol = 4,
                                x_breaks = pretty(len_mid, n = 4))
ssb_plot <- plot_SSB(b, se = TRUE)
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
4. **模型假设：**检查 `p_acl`、`p_alscl` 和两个 map。教学例子用 `factor(NA)` 固定已知的生长及部分过程参数，因此属于条件拟合，区间不包含这些固定值的不确定性。只给初值不等于固定参数。显式命名的 `NULL` 可释放参数，包括模型默认固定项；写法是 `map["参数名"] <- list(NULL)`。未指定的参数、边界及映射采用包默认设置。如需自定上下界，在对应 `fit_config` 中加入 `parameters.L` 和 `parameters.U`。
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
