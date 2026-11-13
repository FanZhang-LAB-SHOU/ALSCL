# 模拟调查数据

读完本页，你会得到拟合函数可以直接使用的模拟调查表、重复文件（每个文件是一套模拟数据集，连同生成它的种群一起保存），以及对这些重复的拟合结果的偏差、RMSE 和区间覆盖率表。你需要已安装的软件包；每一步都使用软件包中的函数。

<h2 id="choose">1. 选择模拟器</h2>

```r
library(ALSCL)
quick <- simulate_example_data(
  years = 2000:2019, seed = 42, bin_breaks = seq(5, 51, 2),
  Linf = 60, vbk = 0.2, t0 = 1/60, M = 0.2, nage = 15,
  L50_sel = 15, L95_sel = 20, L50_mat = 35, L95_mat = 40,
  wgt_a = exp(-12), wgt_b = 3, mean_F = 0.3,
  cv_catch = 0.2, rec_sigma = 0.3,
  save_csv = TRUE, output_dir = "my_simulation")
str(quick, max.level = 1)
initialize_params(species = "?")
```

`simulate_example_data()` 是快速模拟器，用于测试导入、拟合和绘图：一次调用返回调查指数表 `data.CatL`、体重表 `data.wgt` 和成熟比例表 `data.mat`，生成时使用的真值放在 `true_params` 中，`save_csv = TRUE` 还会把它们写成 CSV 文件保存到 `output_dir`。它对所有年龄使用同一个捕捞死亡率，体长 CV 固定为 0.1。`years` 必须是连续的日历年；把列名改成季度并不会产生季度动态。

完整操作模型用于对照已知种群的实验，需要三次调用：`initialize_params()` 由预设生成参数列表，`sim_cal()` 据此推导生物学数组，`sim_data()` 让种群经过预热期（最初被丢弃的年份）向前演进，并为每次重复写一个文件；补充量服从 Beverton-Holt 曲线，补充量和捕捞死亡率都带有 AR(1) 过程偏差。下表比较两个预设；[`initialize_params()` 的函数参考](../reference/initialize_params.html)列出全部设置。

| 设置 | flatfish | tuna |
|---|---|---|
| 操作模型 | 年龄结构 | 年龄与体长联合 |
| `growth_step` | 1 年 | 0.25 年 |
| `nyear`、`burn_in` | 100、80 年 | 100、95 年 |
| 保留的观测 | 20 个年度时间步 | 20 个季度时间步 |
| `nage`、`rec.age` | 15 个年龄组、1 年 | 20 个年龄组、0.25 年 |
| `Linf`、`vbk` | 60、每年 0.2 | 152、每年 0.38 |
| `M`、`F_mean` | 0.2、0.3（每个年度时间步） | 0.2、0.2（每个季度时间步） |

`str()` 显示三张表和 `true_params`；`initialize_params(species = "?")` 列出各预设。无效输入，例如 `L95_sel` 小于 `L50_sel`，会在写任何文件之前停止调用。

<h2 id="generate">2. 生成重复并转换成输入表</h2>

```r
pa <- initialize_params(species = "flatfish", first.year = 2000,
                        observation_error = "independent")
bio <- sim_cal(pa)
sm <- sim_data(bio, pa, iter_range = 4:5, return_iter = 4,
               output_dir = "simulation_examples/flatfish")
inputs <- simulation_to_tables(sm, pa)
tuna_pa <- initialize_params(species = "tuna", first.year = 2000)
tuna <- sim_data(sim_cal(tuna_pa), tuna_pa, iter_range = 4:5,
                 return_iter = 4, output_dir = "simulation_examples/tuna")
tuna_inputs <- simulation_to_tables(tuna, tuna_pa)
sm$years
tuna$years
str(inputs)
```

`iter_range` 给出互不重复的非负整数编号，同时也是随机种子；`sim_data()`、`sim_model()`、`sim_acl()` 和 `sim_alscl()` 均接受编号 0；`sim_data()` 用 `save()` 把每次重复保存为 `output_dir` 中的 `sim_rep<id>` 文件，读取时用 `load()`，`return_iter` 选择返回到内存的那一次。每次重复自行设定种子和随机数发生器，并连同软件包版本记录在 `provenance` 中，因此同一编号在任何会话中给出相同数据，调用结束后你会话中的随机数流保持不变。默认情况下，一次重复的所有过程从同一个随机数流中抽取，所以改变某个过程的设置（例如补充量的相关系数 `R_ar`）也会改变其他过程的抽样。使用 `initialize_params(random_numbers = "by_process")` 时，补充量、F、初始尾数和调查误差各有自己的随机数流，抽取次数固定，因此只在一个过程上不同的情景在其他过程上使用相同的随机数。两种设置对同一编号给出不同的数据，每次重复把所用设置记录在 `provenance$random_numbers` 中。在 `sm` 中，`SN_at_len` 是按时间乘体长排列的调查尾数矩阵，`weight` 和 `mat` 按体长乘时间排列，`years` 是保留时间步的日历，`nyear` 是它们的个数，`SSB`、`Rec`、`TB` 和 `N_at_age` 是生成真值。

`simulation_to_tables(sm, pa)` 转置 `SN_at_len`，用体长中点作为行标签、用 `sm$years` 作为列名，并把三张表作为一个列表返回；[模拟调查数据案例](case-simulate-survey.html)从 `pa` 加入生物学设置并拟合一次重复。在仓库副本中，`scripts/simulation_workflow.R` 的 `run_simulation_examples(out = "simulation_examples")` 为两个预设完成本步骤，把表写成 CSV 文件并在旁边保存 `truth.rds`；两个预设的第 4 次重复已保存在仓库中，见[下载和读取说明](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/data/cases/README.md)。

如果 `simulation_to_tables()` 因参数列表中的 `len_mid` 与重复文件记录的坐标不同而停止，请传入生成该文件的参数列表。把 `sim_rep` 文件、参数列表和软件包版本与实验一起保存。

`sim_data()` 在抽样或写文件前核对生物学数组及其来源参数是否与 `pa` 一致。修改生长、年龄、时间步、体长组、重量、成熟、调查可捕性或选择性后，应重新运行 `bio <- sim_cal(pa)`，不要手动修改数组。只修改死亡率、补充量、误差、时长或日期，无须重算生物学数组。要用可选的模型结构模拟，在 `sim_cal(pa)` 之前把拟合函数 `structure` 参数接受的同一列表赋给 `pa$structure`，例如 `pa$structure <- list(initial_plus_group = "equilibrium")`（[选择拟合设置](fitting-controls.html#structure)）。没有来源记录但内容一致的旧对象仍可使用。拟合已保存重复时，调查可捕性与元数据不一致会生成错误记录，应使用一致的输入重新生成模拟。

年龄别体长分布的尾部体长组仍可具有很小的正概率，这些组的模拟调查指数会保留相应的正值。自定义穹顶形渔业选择性时，将 `pa$sel_type` 设为 `"dome"` 并提供上升段和下降段的参数。年龄结构模拟用各年龄的体长分布对体长别选择性加权，得到年龄别选择性。体长结构模拟直接使用体长别曲线。

<h2 id="rates">3. 设置死亡率、变异和时间单位</h2>

```r
mean(quick$true_params$F_trend)
pa$F_sd / sqrt(1 - pa$F_ar^2)
short_pa <- initialize_params(species = "flatfish", nyear = 5, burn_in = 2,
                              first.year = 2024)
short <- sim_data(sim_cal(short_pa), short_pa, iter_range = 4:5,
                  return_iter = 4, output_dir = "simulation_examples/short")
short$years
short$nyear
```

快速模拟器的 `mean_F` 是生成的年度 F 的算术平均值。完整模拟器的 `F_mean` 是 `F[t] = F_mean * exp(d[t])` 中的基准水平，其中 `d[t]` 是均值为零的 AR(1) 过程，系数为 `F_ar`，创新标准差为 `F_sd`，所以生成的 F 的平均值与 `F_mean` 不同；与拟合所得对数 F 标准差比较时，应使用边际标准差 `F_sd / sqrt(1 - F_ar^2)`，而不是 `F_sd`。`std_logR` 和 `R_ar` 对补充量起同样作用，`std_SN` 是对数调查误差的标准差，`M` 和 `F_mean` 是每个时间步的速率，因此 tuna 的取值按季度计。

`nyear` 和 `burn_in` 都是以年为单位的时长；`growth_step` 必须能整除一年，`burn_in` 必须是 `growth_step` 的整数倍且小于 `nyear`，并且至少要保留两个时间步才能拟合。`first.year` 标记第一个保留的时间步，`sm$nyear` 是保留的时间步数。如果调用因 `burn_in` 不是 `growth_step` 的整数倍而停止，年度时间步请用整年，季度时间步请用整季度。

<h2 id="fit">4. 拟合重复并汇总</h2>

```r
data("YTF_example")
cfg <- YTF_example$fit_config$acl
cfg$parameters$log_std_log_F <- log(pa$F_sd / sqrt(1 - pa$F_ar^2))
fits <- sim_acl(iter_range = 4:5, sim_data_path = "simulation_examples/flatfish",
                output_dir = "simulation_examples/fits_acl",
                parameters = cfg$parameters, map = cfg$map,
                nstarts = 2, ncores = 2)
truth <- setNames(lapply(4:5, function(i) {
  e <- new.env(parent = emptyenv())
  load(file.path("simulation_examples/flatfish", paste0("sim_rep", i)), envir = e)
  s <- e$sim.data
  list(year = s$years, SSB = as.numeric(s$SSB), Rec = as.numeric(s$Rec))
}), paste0("result_rep_", 4:5))
performance <- summarize_simulations(fits, truth, quantities = c("SSB", "Rec"))
performance$replicates
performance$summary
performance$summary_converged
performance$failures
```

`sim_acl()` 读取 `sim_data_path` 中的每个 `sim_rep<id>` 文件，从文件构造三张表和生物学设置，再用你传入的初值和 `map` 以及文件中记录的自然死亡率拟合 ACL；`sim_alscl()` 用 ALSCL 的参数名做同样的事。早期版本以 `sim_rep1e+05` 这类名称写出的文件也能读取。给定的 `M` 必须等于记录值。要研究自然死亡率设定有误的情形，传入 `M` 并设 `allow_M_mismatch = TRUE`。

本例使用 `YTF_example` 中的鲽鱼生长设置，将对数 F 的边际标准差固定为根据 `pa` 换算的 0.3023716。`YTF_example` 保存的配置中也是这个值，因为随包数据就是用这一预设生成的；修改 `pa` 中的 `F_sd` 或 `F_ar` 时，设置 `log_std_log_F` 的那一行使拟合的标准差与操作模型保持一致。操作模型用共用时间序列和选择性生成 F，ACL 拟合采用年龄与时间可分离的 F 过程。两者都在对数尺度上加入独立扰动，逐龄递推初始尾数。要调整拟合假设，见[选择拟合设置](fitting-controls.html)。

每次重复在一个工作进程中拟合，它的 `nstarts` 个初值依次运行；`ncores` 决定同时运行多少次重复。每次重复的结果，包括带有 `converge = "FAILED"` 和 `error` 信息的失败，都会返回并保存为 `output_dir` 下的 `result_rep_<id>`。结果不含 TMB 对象 `obj`；需要时对结果调用 `refit_model()`。

`summarize_simulations()` 需要真值列表与拟合列表同名，每个元素包含 `year` 和每个量的一个向量，这里从重复文件读取，使时间坐标一致。`performance$replicates` 给出每次重复的数值检查和错误信息；`performance$summary` 按量给出失败率、偏差、相对偏差、RMSE 和区间覆盖率，以及各自的计数。偏差和 RMSE 只使用通过数值检查的拟合，覆盖率还需要有限的标准误，所以报告统计量时要一并报告 `failure_rate`。`performance$summary_converged` 对全部收敛的拟合给出同样的统计量，不论是否通过数值检查；`performance$failures` 按原因统计失败的重复。比较这两张汇总表，看被数值检查排除的拟合是否改变偏差、RMSE 或覆盖率。如果调用停止并提示“identical unique replicate names”或“time coordinates differ”，说明真值不是从拟合所用的同一批文件读取的。

时间坐标和每个量必须是一维实数数值向量。矩阵和数组即使总长度与时间步数相同也会被拒绝。先将年龄别或体长别数量按所需定义汇总为时间序列，不要把分组数据直接展平当作时间。

<h2 id="fitted">5. 从拟合模型模拟调查数据</h2>

```r
fit <- run_acl(YTF_example, silent = TRUE)
simulated <- simulate_fit(fit, nsim = 3, seed = 42, process = "resample")
names(simulated$simulations[[1]])
simulated$simulations[[1]]$truth$SSB
```

`simulate_fit()` 从拟合好的 ACL 或 ALSCL 模型模拟新的调查数据。`process = "conditional"` 保留拟合的种群，只重新抽取观测误差；`process = "resample"` 还在拟合的标量参数值下重新抽取补充量、捕捞死亡率和初始丰度的过程偏差。`simulated$simulations` 的每个元素包含 `x`（`run_acl(x)` 可用的输入列表）、`observations` 和 `truth`，所以可以用 `lapply(simulated$simulations, function(s) s$truth)` 作为真值，对再拟合结果运行 `summarize_simulations()`。未通过数值检查的拟合会被拒绝，除非设置 `allow_failed_fit = TRUE`；[模型验证案例](case-model-validation.html)再拟合这些重复，并继续做预测检验。

<h2 id="next">下一步</h2>

| 想做什么 | 阅读 |
|---|---|
| 绘制一次重复，用两个模型拟合并与真值比较 | [如何模拟调查数据？](case-simulate-survey.html) |
| 用模拟调查数据重新拟合，并预测留出的年份 | [模型验证](case-model-validation.html) |
| 用更少的时间运行更多重复 | [速度设置](speed.html) |
| 保存种子、设置和版本以便重复实验 | [复现结果](reproducibility.html) |
| 比较年度和季度设置 | [年度与季度时间步](case-studies.html) |
| 拟合自己的表 | [准备调查数据](data-preparation.html) |
