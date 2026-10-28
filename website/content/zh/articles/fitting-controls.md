# 初值、边界与拟合

先完成 [YTF 拟合示例](first-model.html)。以下代码使用其中的 `x`、`inputs`、`a`（ACL）和 `b`（ALSCL）对象。

|设置|怎么调整及影响|
|---|---|
| `rec.age`, `nage` |起始年龄（年）和年龄组数；年龄网格为 rec.age + (0:nage-1) × growth_step|
| `growth_step` |每步多少年；ACL 的 NULL 按 rec.age<1 时取 rec.age、否则取 1，ALSCL 默认 1，季度应显式设 0.25|
| `M` |每模型步长自然死亡瞬时率；年率转季度需相应换算|
| `sel_L50`, `sel_L95` |固定调查 q 的位置和斜率，L95 必须大于 L50|
| `len_mid`, `len_border` |组中心及内部边界；ALSCL 外端点必须为 −∞/+∞|
| `parameters`, `.L`, `.U` |命名初值、下界、上界；在程序参数化尺度上提供|
| `map` |固定或释放参数；固定值来自 `parameters`|
| `train_times` |从优化结果继续优化的次数，并非随机多起点|
| `control` |传给 `nlminb` 的控制项，如 `eval.max`、`iter.max`|
| `ncores` |同时运行的最大 socket 进程数，不是单个起点内部的线程数|
| `nstarts` |拟合的总初始点数，默认等于 ncores；比较并行数时固定此值|
| `output` |FALSE 不写文件，TRUE 在 output 目录导出诊断与图|

`initialize_params(species=...)` 建立模拟参数；`create_parameters(model_type=..., species=...)` 建立估计初值及边界。后者的物种预设不会自动替你更改 `run_*` 的 M、年龄、调查 q 或数据。


```r
p <- create_parameters(model_type = "acl", species = "flatfish")
names(p) # 查看初值及上下界列表
# 明确固定参数；不同模型参数名不同
fixed <- list(log_Linf = factor(NA), log_vbk = factor(NA))
# factor(NA) 固定；映射中的 NULL 可释放默认固定项
released <- list(logit_log_F_y = NULL)
VB_func(Linf = 60, k = 0.2, t0 = 1/60, age = 1:15)
mat_func(L50 = 35, L95 = 40, length = seq(6, 50, 2))
```

|生物含义|ACL 参数名|ALSCL 参数名|
|---|---|---|
|生长| `log_Linf`, `log_vbk`, `t0` | `log_Linf`, `log_vbk`, `log_t0` |
|长度离散| `log_cv_len` | `log_cv_len`, `log_cv_grow` |
|过程 SD| `log_std_log_R`, `log_std_log_F`, `log_std_log_N0` | `log_sigma_log_R`, `log_sigma_log_F`, `log_sigma_log_N0` |
|F 相关| `logit_log_F_a`, `logit_log_F_y` | `logit_log_F_l`, `logit_log_F_y` |
|补充相关| `logit_log_R` | `logit_log_R` |

`log_` 参数通常用 `log(自然尺度值)`，相关系数的变换必须以对应模板为准。尤其 ACL 的 `t0` 是原尺度，而 ALSCL 的 `log_t0` 经 exp 变换，因此本版 ALSCL 的该参数化不支持负 t0。不要将 ACL 参数表直接用于 ALSCL。全部 14/15 个估计参数的名称、变换及上下界查询方法见 [初值列表参考](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#estimation_parameters)。

必需输入、全部可估计参数、准确的默认 map 和完整示例见[正式调查数据拟合](case-fit-survey.html)。解除列表应直接作为 `map` 传入；`generate_map()` 会移除 NULL 项，将其返回值再传给拟合函数可能恢复默认固定项。

从 2.2.3 起，两个核心拟合函数直接检查时间网格：相邻数值表头之差必须等于 `growth_step`。年度数据 `2000, 2001, 2003` 会因缺少 2002 而报错；应保留 2002 列，调查值填 `NA`，并提供该期完整的重量和成熟数据。季度表头如 `2000, 2000.25, 2000.5` 必须设置 `growth_step = 0.25`。模型不会自动插补缺失时间步，也不会把不规则间隔重新解释为等间隔。

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
