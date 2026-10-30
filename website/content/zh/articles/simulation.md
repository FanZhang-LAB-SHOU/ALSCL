# 模拟与批量实验

运行以下示例前先加载 R 包。

```r
library(ALSCL)
```

### 1 快速生成三张表

```r
# 简单年度模拟，可直接导出 CSV
quick <- simulate_example_data(
  years = 2000:2019, seed = 42, bin_breaks = seq(5, 51, 2),
  Linf = 60, vbk = 0.2, t0 = 1/60, M = 0.2, nage = 15,
  L50_sel = 15, L95_sel = 20, L50_mat = 35, L95_mat = 40,
  wgt_a = exp(-12), wgt_b = 3, mean_F = 0.3,
  cv_catch = 0.2, rec_sigma = 0.3,
  save_csv = TRUE, output_dir = "my_simulation")
str(quick)
```

`years` 必须是连续年度，不能通过写季度列名把该简易模拟器变成季度模型。`cv_catch` 控制调查观测 CV；`rec_sigma` 控制对数补充变异；该函数使用简化的共同 F、独立补充扰动及固定长度 CV = 0.1。它不等于完整 Beverton–Holt 模拟器，也不等于内置 `YTF_example` 的生成流程。


### 2 完整模拟器与两个案例

两个预设的 seed 4 数据、三张 CSV 和完整真值对象已随文档保存：[下载及读取方法

```r
# 参数 → 生物量表 → 随机模拟
pa <- initialize_params(species = "flatfish", first.year = 2000,
                        observation_error = "independent")
bio <- sim_cal(pa)
sm <- sim_data(bio, pa, iter_range = 4:5, return_iter = 4,
               output_dir = "simulation_examples/flatfish")
# 长度型季度案例
tuna_pa <- initialize_params(species = "tuna", first.year = 2000)
tuna <- sim_data(sim_cal(tuna_pa), tuna_pa, iter_range = 4:5,
                 return_iter = 4, output_dir = "simulation_examples/tuna")
# 将模拟矩阵变成模型输入
source("scripts/simulation_workflow.R", encoding = "UTF-8")
flatfish_inputs <- simulation_to_tables(sm, pa)
tuna_inputs <- simulation_to_tables(tuna, tuna_pa)
```

|设置| flatfish / YTF 风格 | tuna / 金枪鱼风格 |
|---|---|---|
|生成模型|年龄型|年龄与长度联合|
| `growth_step` |1 年|0.25 年|
| `nyear`, `burn_in` |100, 80 年|100, 95 年|
|保留观测|20 年度|20 季度|
| `nage`, `rec.age` |15, 1 年|20, 0.25 年|
| `Linf`, `vbk` |60, 0.2/年|152, 0.38/年|
| `M`, `F_mean` |0.2, 0.3 每年|0.2, 0.2 每季度|

这是包内的两个模拟预设案例，不能当成已取得论文两个案例的原始观测。完整参数见 [initialize_params](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#initialize_params)。`nyear`、`burn_in`、`sim_year` 的单位是**年**；返回 `sm$nyear` 是保留的**时间步数**。`SN_at_len` 是时间 × 长度，导入时要转置；`weight` 和 `mat` 已是长度 × 时间。


`iter_range` 同时指定重复编号和随机种子；`return_iter` 选择在内存中返回哪次重复。每个 `sim_rep4` 等文件由 `save()` 写出，应用 `load()`，不是 `readRDS()`。`observation_error="independent"` 让每个长度与时间单元有独立扰动；`"shared_time"` 让同一期的长度组共享扰动，适合专门的误差结构实验。


```r
# 同时生成两个案例及 CSV、真值文件
cases <- run_simulation_examples(out = "simulation_examples", fit_batch = FALSE)
# 加上两个 ACL 重复拟合，保存失败诊断
# run_simulation_examples(out = "simulation_examples", fit_batch = TRUE)
e <- new.env()
load("simulation_examples/flatfish/sim_rep4", envir = e)
str(e$sim.data)
```

批量入口 `sim_acl()` 仅拟合 ACL；ALSCL 可对各重复转表后循环调用 `run_alscl()`。生成器与拟合器的参数名不完全一致，不要直接把 `pa` 整表传入 `parameters`。两个重复只用于确认流程；正式性能实验应增加重复、保存真值并报告偏差、RMSE、区间覆盖率以及拟合失败率，不能只分析成功的重复。

## 2.2.4 的模拟设置与年份标签

从 2.2.4 起，快速年度模拟器的 `mean_F` 等于生成 F 序列的算术平均值；`mean_F = 0` 生成零捕捞死亡率。修正后的轨迹会改变重新生成的观测，即使使用旧种子也是如此。仓库已保存的数据和配图仍对应各自原始生成真值。

完整模拟器的 `nyear`、`burn_in` 都以年为单位，且分别必须对应整数个 `growth_step`。因此季度模式允许半年预热，年度模式不允许。返回的 `sm$nyear` 是保留时间步数；`first.year` 是第一期保留观测的年份，`sm$years` 保存完整观测时间轴。`simulation_to_tables()` 和 `sim_acl()` 保留这条时间轴；完全没有年份元数据的旧文件仍可使用从 2000 开始的后备规则。只保留一期时仍返回矩阵，但拟合至少需要两期。

`sim_acl()` 在发送 socket 任务前求值路径与参数变量，因此一般控制台或脚本中的变量传参也支持多核。保留失败重复并检查逐次拟合诊断；工作进程运行成功并不单独证明评估结果可用。

```r
quick <- simulate_example_data(years = 2000:2019, mean_F = 0.3, seed = 42)
stopifnot(isTRUE(all.equal(mean(quick$true_params$F_trend), 0.3)))
zero_F <- simulate_example_data(years = 2000:2019, mean_F = 0, seed = 42)
stopifnot(all(zero_F$true_params$F_trend == 0))
pa <- initialize_params(species = "flatfish", nyear = 5, burn_in = 2,
                        first.year = 2024)
sm <- sim_data(sim_cal(pa), pa, iter_range = 4:5, return_iter = 4,
               output_dir = "simulation_224")
stopifnot(identical(as.numeric(sm$years), as.numeric(2024:2026)))
source("scripts/simulation_workflow.R", encoding = "UTF-8")
inputs <- simulation_to_tables(sm, pa)
```

### 2.2.5 的模拟数值边界

`mat_func()` 使用稳定的 logistic 计算，陡峭上升曲线接近 1 时不会溢出。`L50` 与 `L95` 必须是不同的有限标量；仍允许下降曲线（`L95 < L50`），用于穹顶选择性。体长及派生生物矩阵必须有限，模拟的自然与捕捞死亡率必须非负。当 `M = 0` 且 `F_mean = 0` 时，渔获尾数和生物量为零，不再返回未定义数值；丰度和补充量仍按选定模拟模型演变。

```r
stopifnot(all(is.finite(mat_func(20, 20.1, c(20, 30, 50)))))
pa0 <- initialize_params(species = "flatfish", nyear = 4, burn_in = 2,
                         M = 0, F_mean = 0)
sm0 <- sim_data(sim_cal(pa0), pa0, iter_range = 4,
                output_dir = file.path(tempdir(), "alscl-zero-mortality"))
stopifnot(all(sm0$CN == 0), all(sm0$CB == 0))
```

### 一致性修正

快速模拟器现在把首尾体长组分别积分到负无穷和正无穷，与拟合模型一致。有限 `bin_breaks` 仍用于标签与中点，不截断概率。修正后，即使种子相同，新模拟结果也可能改变，尤其是首边界排除了较小个体时；已保存数据仍保留原始生成真值。M、F 和噪声尺度必须非负，生长参数为正、重量系数非负，选择性及成熟曲线的 95% 端点高于 50% 端点。非法参数或非有限生成结果会在创建 CSV 前报错。完整模拟器还检查年龄—体长概率及生长转移概率的归一化。

完整模拟器要求 `init_Z`、过程与观测标准差、平均捕捞死亡率均为有限非负值。`F_ar` 与 `R_ar` 必须严格介于 -1 和 1 之间，允许负的平稳相关。Beverton–Holt 的 alpha 和初始补充量可以为零，beta 必须为正。非法过程输入会在随机抽样或创建文件前报错，保留已有模拟文件及调用者的随机数状态。
