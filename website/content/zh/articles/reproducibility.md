# 进阶、复现与故障处理

先完成 [YTF 拟合示例](first-model.html)。以下代码使用其中的 `x`、`inputs`、`a`（ACL）和 `b`（ALSCL）对象。

## 固定参数敏感性

改变 M、q 或固定 CV 可能明显改变绝对丰度与 SSB。一次改变一个有科学依据的假设，使用同一观测，保留数值诊断和全过程设置，而不是只寻找最小 AIC。


```r
# 使用指南中的 inputs、x
sensitivity <- lapply(c(.15, .20, .25), function(M_value) {
  fit <- run_alscl(x, M = M_value, train_times = 2, silent = TRUE)
  list(M=M_value, diagnostics=diagnose_model(x$data.CatL, fit), fit=fit)
})
# 确认每个诊断后比较
lapply(sensitivity, function(z) z$diagnostics)
plot_compare_ts(sensitivity[[1]]$fit, sensitivity[[3]]$fit,
                model1_name="M = 0.15", model2_name="M = 0.25")
```

释放参数前先检查上下界和映射：`generate_map(list(t0=NULL))` 释放 ACL 默认固定的 t0；ALSCL 使用 `log_t0`，不能直接套同一列表。对自由参数可使用多个合理起点，比较目标函数、梯度与派生量。


## 并行与编译

```r
# CPU 数量未知时回退单进程
cores <- parallel::detectCores()
workers <- if (is.na(cores)) 1L else max(1L, min(4L, cores - 1L))
# 在原拟合中替换 ncores，不重复传参
multi <- run_acl(x, ncores=workers, nstarts=4, train_times=2, silent=TRUE)
```

|入口| ncores=1 | ncores>1 |
|---|---|---|
| `run_acl`, `run_alscl` |依次完成 nstarts 个起点|最多 min(ncores, nstarts) 个 socket 进程|
| `sim_acl` |依序拟合重复|按重复分工|
| `retro_model`, `retro_acl`, `retro_alscl` |依序删除末期|按回溯拟合分工|

对 `retro_acl(x)` 和 `retro_alscl(x)`，输入中原拟合的 `ncores` 不会自动用于回溯；请在回溯调用中显式指定 `ncores`，控制截短拟合的并行数。`nstarts` 仍控制每次拟合的起点总数，内部依序执行。解读 `rho_text` 前查看 `fit_diagnostics`；必要拟合未通过检查时，不报告通过筛查的 rho。

多起点的目标是稳健性，墙钟时间仍受最慢起点及进程开销影响。避免外层重复与内层多起点同时占满 CPU。Windows、macOS、Linux 均使用可移植 socket 路径。


编译由 `run_*()` 自动完成，源文件随包分发，缓存键含模板、头文件、R/TMB/RcppEigen 版本和编译选项。`compile_and_load_acl()` 是内部辅助函数；开启编译选项本身不保证模板的似然计算自动并行。


```r
# 仅在默认缓存不合适时设置
options(ALSCL.tmb.cache=file.path(tempdir(), "alscl_tmb_cache"))
```

macOS 需要配套命令行 C++ 工具链，Windows 使用匹配 R 版本的 Rtools，Linux 需要 C++/make。依赖安装失败应先解决编译工具和依赖，再重新拟合；不应通过关闭检查掩盖问题。


## 保存可移植结果

```r
# obj 含当前会话的外部指针
portable <- function(fit) fit[setdiff(names(fit), "obj")]
saveRDS(portable(b), "alscl_report.rds")
capture.output(sessionInfo(), file="sessionInfo.txt")
saved <- readRDS("alscl_report.rds")
saved$report$SSB
# 这些图只需已保存报告
plot_SSB(saved)
```

`plot_ridges()` 需要活跃 TMB 对象，应在新会话重新拟合。记录包版本、提交号、随机种子、数据来源、三表单位、固定参数、边界、时间步和诊断。保存 `.rds` 不等于保存可跨机器运行的编译模型。


## 常见问题


|现象|处理|
|---|---|
| `YTF$data.CatL` 是 NULL |载入 `YTF_example`；YTF 是参数列表|
| Excel 年份变成 X2000 |用指南读取函数或 `check.names=FALSE`|
| 长度边界不连续 |核对真实测量定义，不要自动消除间隙|
| 出现零调查值 |判断真实零还是缺失编码，再明确 `zero_action`|
| 体重/成熟缺失 |依据可靠资料补全并记录方法|
| 优化码非 0、梯度大、Hessian 非正定 |检查尺度、边界、初值和可识别性；不能只增加次数|
| 季度 F 看起来偏小 |输出是每步瞬时率；`annual_F` 名称不意味着自动年化|
| ACL 的 F 图 `type="length"` |当前兼容分支仍输出年龄曲线；真正长度别 F 用 ALSCL|
| 生长区间退化为线 |本例固定生长参数，属于预期行为|

本文的可执行脚本和实际数值结果随仓库发布；所有图应结合模型假设与数据来源解释。


固定 `nstarts` 后再比较 `ncores`，才能保证工作量相同。为兼容旧调用，`nstarts` 默认等于 `ncores`；只改变 `ncores` 也会改变总工作量。`multi$start_diagnostics` 记录各起点的 PID、起止时间、CPU 时间、目标函数和优化码。串行和并行使用相同的确定性初值扰动。结果仍按最低有限目标函数选择，需要另行检查梯度与 Hessian。数据准备、最终报告和标准误计算仍有串行部分，因此不保证线性加速。

## 并行性能实测

2026 年 10 月 7 日，在 Apple M2 Pro（32 GiB）上实际运行 ACL 和 ALSCL。每次均固定 **4 个相同初始点，每个起点连续优化 2 轮**，使用模拟数据 `YTF_example` 前 10 年、23 个体长组及 15 个年龄组。每项重复 3 次；不计编译及预热，但包含工作进程创建、拟合、报告和标准误计算。

| 模型 | 并行进程数 | 中位耗时（秒） | 范围（秒） | 加速比 |
|---|---:|---:|---:|---:|
| ACL | 1 | 4.23 | 4.18–4.44 | 1.00× |
| ACL | 2 | 3.50 | 3.27–3.90 | 1.21× |
| ACL | 4 | 3.08 | 2.93–3.14 | 1.38× |
| ALSCL | 1 | 71.38 | 71.28–72.35 | 1.00× |
| ALSCL | 2 | 45.03 | 44.55–51.00 | 1.59× |
| ALSCL | 4 | 33.23 | 31.21–33.95 | 2.15× |

![并行拟合总耗时实测](../../../docs/figures/parallel/timing.png)

圆点为全部测量，折线为中位数，误差线为最小至最大值。测试时有其他分析共用电脑，结果只代表该环境和工作负载；小任务可能因启动开销变慢，串行报告阶段也限制加速比。

![真实工作进程的执行时间重叠](../../../docs/figures/parallel/worker-timeline.png)

第一轮四进程测试记录了 4 个不同 PID，执行时间重叠且有实际 CPU 使用。全部 18 次计时拟合、72 个起点通过检查；不同并行数使用相同初值，逐起点目标函数一致，最终模型通过优化码、Hessian、梯度及边界检查。各工作进程调用同一 C++ 似然模型；单个起点内部仍是串行运算。

参见[完整双语报告](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PARALLEL_BENCHMARK.md)、[全部耗时记录](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/parallel/runs.csv)、[逐起点证据](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/parallel/starts.csv)及[复现脚本](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/scripts/benchmark_parallel.R)。报告另外保留原版测试，并明确区分功能验证和相同工作量的速度比较。

## 单次拟合的速度设置

`alscl_speed()` 设置之后每次拟合如何计算标准误，以及 TMB 使用哪个自动微分库。默认设置下结果与 ALSCL 2.0.0 逐位相同：固定效应 Hessian 和 delta 方法标准误在多个核上计算（`sd_cores = "auto"`：最多 4 核；macOS 与 Linux 用分叉进程，Windows 与 RStudio 等图形界面用 socket 进程计算 delta 方法）。`framework = "TMBad"` 改用 TMB 的 TMBad 库编译模型，速度更快，但估计值与默认设置略有差异（在已测试的拟合中相对差最大 2.7e-8）。

```r
# 默认：结果不变，并行计算标准误
alscl_speed()
b <- run_alscl(x, silent = TRUE)
# 更快的选项；结果与默认设置不完全相同
alscl_speed(framework = "TMBad")
# 顺序计算标准误，例如在自己的并行循环中
alscl_speed(sd_cores = 1)
```

2026 年 10 月 12 日的基准测试共 90 次拟合（ACL 与 ALSCL 分别拟合 `YTF_example`、flatfish 与 tuna 案例，各运行 3 次，Apple M2 Pro，测试期间有其他任务）。与原版相比，默认设置使拟合快 1.13-1.24 倍，`framework = "TMBad"` 快 1.25-1.68 倍。

| 模型 | 原版（秒） | 默认（秒） | TMBad（秒） |
|---|---:|---:|---:|
| ACL，YTF_example | 8.6 | 7.7（1.13×） | 6.6（1.31×） |
| ALSCL，YTF_example | 140.9 | 118.8（1.19×） | 83.9（1.68×） |
| ALSCL，flatfish | 107.8 | 86.9（1.24×） | 78.8（1.37×） |
| ALSCL，tuna（季度） | 217.4 | 180.9（1.20×） | 141.3（1.54×） |

![速度设置前后的拟合耗时](../../../docs/figures/speed/timing.png)

默认设置下，六个组合的全部估计值、目标函数及 `summary(sdreport)` 的每一行都与原版逐位相同；`R CMD check` 在 Linux、macOS 和 Windows 上均通过。

![速度设置前后的估计值与标准误](../../../docs/figures/speed/agreement.png)

[速度设置](speed.html)一文详细说明每项设置、怎样检查本会话的实际情况，以及在 Windows 和 RStudio 中如何使用 socket 进程。另见[速度报告](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/SPEED.md)（英文）、[全部耗时记录](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/speed/runs.csv)及[基准测试脚本](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/scripts/benchmark_speed.R)。

### 2.2.5 的并行安装库一致性

多起点拟合、回溯和模拟批次的 socket 进程先接收主会话的库路径，再加载 ALSCL；通过 `.libPaths()` 选择新安装版本时也适用。所有工作进程必须加载与主进程相同的 ALSCL 安装。比较核数时保持 `nstarts` 相同，标准误并行继续由 `alscl_speed()` 控制。
