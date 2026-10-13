# 速度设置

本文说明 `run_acl()` 与 `run_alscl()` 如何使用多个核、拟合能快多少、怎样确认本机的实际情况，以及什么时候需要修改设置。每项改动的测试方法见[技术记录](https://github.com/Linbojun99/ALSCL/blob/main/docs/SPEED.md)（英文），各项检查见[审查报告](https://github.com/Linbojun99/ALSCL/blob/main/docs/SPEED_REPORT.md)（英文）。

## 1. 概要

不需要修改任何设置。支持的环境下默认用多个核计算标准误，相同拟合参数处的并行标准误与顺序计算一致。2.2.2 默认新增优化收尾，因此完整拟合不承诺与旧版逐位相同。以下基准记录旧优化流程；`polish = FALSE` 可跳过新收尾。这由两项设置控制，均通过 `alscl_speed()` 设定：

| 设置 | 默认值 | 结果 | 速度 | 何时修改 |
|---|---|---|---|---|
| `sd_cores` | `"auto"`：最多 4 核 | 与顺序计算逐位相同 | 基准测试中拟合快 1.13-1.24 倍（macOS 终端） | 在自己的并行循环中设为 `1`；需要固定核数时设为一个数 |
| `framework` | `"CppAD"` | 与 ALSCL 2.0.0 使用相同 AD 库 | 基准 | `"TMBad"` 使拟合快 1.25-1.68 倍，但结果略有差异（第 6 节） |

`alscl_speed_info()` 显示这些设置在本机上的实际效果；每次拟合都在 `fit$sd_info` 中记录实际的计算方式。

## 2. 快速上手

```r
library(ALSCL)
alscl_speed_info()   # 当前设置在本机上的实际效果
x <- YTF_example
fit <- run_alscl(x, silent = FALSE)
fit$sd_info          # 标准误的计算方式与耗时
```

`silent = FALSE` 时，拟合会打印一行关于标准误的信息；`alscl_speed_info()` 打印各项设置。以下是 macOS 终端中的例子：

```r
#> Standard errors: forked processes on 4 cores, 9.0 s.
alscl_speed_info()
#> ALSCL speed settings
#>   sd_cores setting:                  auto
#>   cores for standard errors:         4
#>   standard errors computed by:       forked processes on 4 cores: Hessian and delta method
#>   reason:                            forked processes are safe here (macOS or Linux outside a GUI front-end)
#>   framework:                         CppAD
#>   cross-version numerical identity:  not guaranteed (2.2.2 adds optimizer refinement)
#>   TMB version:                       1.9.21 (checked)
```

## 3. 拟合的时间花在哪里

一次拟合分两部分：

1. **优化。** `nlminb()` 在固定效应上搜索。每次计算目标函数或梯度都要对随机效应做一次内层牛顿优化（拉普拉斯近似）。这部分只能顺序进行：每一步都依赖上一步，若用多个核会改变优化路径，从而改变结果。
2. **标准误。** 优化结束后，`TMB::sdreport()` 计算（a）固定效应的 Hessian，每个固定效应需要两次梯度计算；（b）每个 ADREPORT 量的 delta 方法标准误（各年份、年龄与体长的补充量、丰度、生物量、产卵生物量、渔获量与捕捞死亡率；20 年 ALSCL 示例共 3,866 个量）。Hessian 的各列互不依赖，各 ADREPORT 量也互不依赖，因此都可以在多个核上计算，结果逐位相同。

用原版代码对 `YTF_example` 的 20 年数据拟合 ALSCL 时，优化约 88 秒，Hessian 11.4 秒，delta 方法 10.6 秒。速度设置缩短标准误的时间；`framework = "TMBad"` 还会缩短优化的时间。

## 4. 标准误如何使用多个核

### 4.1 分叉进程：在终端中运行的 macOS 与 Linux

在安全的环境中，ALSCL 用 `parallel::mclapply()` 启动分叉进程（R 会话的副本）。每个副本已经包含拟合好的模型，因此 Hessian 的各列和 delta 方法都可以几乎零开销地分配出去。这是最快的方式：20 年 ALSCL 示例的标准误在 4 个核上用 9.0 秒，顺序计算需 23.4 秒。

在 macOS 或 Linux 终端中运行 R 或 `Rscript`，以及在计算集群上，都使用分叉进程。

### 4.2 socket 进程：Windows、RStudio、R.app 与 Positron

Windows 不支持分叉；R 的文档（`?parallel::mclapply`）也不建议在图形界面（R.app、RGui、RStudio、Positron）中或搭配多线程库（如 Apple 的 Accelerate BLAS）时分叉。在这些会话中，ALSCL 改用 socket 进程：新启动的 R 进程接收数据并重建模型。

新进程在计算梯度之前必须重建 TMB 的导数计算带；20 年 ALSCL 示例中，第一次梯度计算在 CppAD 下需 14 秒（TMBad 下 42 秒），比整个 Hessian 还长。因此使用 socket 进程时：

- Hessian 在主 R 会话中计算；
- delta 方法分给 socket 进程，它们只需要目标函数的梯度计算带（约 0.1 秒即可建好），并从主会话接收随机效应 Hessian；
- ALSCL 先在主会话中计算几个 ADREPORT 量，测出每个量的耗时；只有当剩余的量预计超过约 3 秒时才启动 socket 进程。因此小模型（如大多数 ACL 拟合）在主会话中计算标准误，这比启动进程更快。

20 年 ALSCL 示例中，delta 方法在 4 个 socket 进程上用 6.5 秒，顺序计算需 13.9 秒（其中启动进程 0.3 秒，在进程中重建模型 0.9 秒）。整个拟合的提升小于分叉进程（第 8 节）。

在 macOS 或 Linux 的 RStudio 中，可用 `options(ALSCL.sd_backend = "fork")` 改用分叉进程，获得完整的加速。这正是 R 文档不建议的做法，只有在你的会话运行拟合没有问题时才使用。

### 4.3 何时顺序计算标准误

| 情况 | 处理方式 |
|---|---|
| `sd_cores = 1`，或只有 1 个核可用 | 顺序计算的 `TMB::sdreport()` |
| `retro_model()` 或 `sim_acl()` 中在并行进程里运行的拟合 | 每个拟合用 1 核，进程数不会成倍增加 |
| 已安装的 TMB 版本不是并行代码核对过的版本（目前为 1.9.21） | 顺序计算的 `TMB::sdreport()`；`fit$sd_info$note` 会注明 |
| 启动 socket 进程不会更快（计算量小） | 在主会话中计算 |
| 并行计算失败（例如无法启动进程） | 给出警告，然后顺序计算 `TMB::sdreport()`；结果不受影响 |

### 4.4 为什么结果逐位相同

并行代码与 `TMB::sdreport()` 执行完全相同的算术运算，每个量内部的运算顺序也相同；不同的只是各量的计算先后，而它们互不依赖。有两个细节很关键：Hessian 复现了 `stats::optimHess()` 遍历参数的方式；存在随机效应时，每次梯度计算都从同一个起点开始内层优化。测试用 `identical()` 将结果的每个分量与 `TMB::sdreport()` 比较，覆盖 ACL 与 ALSCL、CppAD 与 TMBad、分叉进程与 socket 进程；这些测试在 Linux、macOS 和 Windows 上都通过。

## 5. 如何选择核数

- **`"auto"`（默认）** 最多使用 4 个物理核，并为电脑的其他工作保留 1 个。测试中超过 4 个核提升很小，因为优化本身只能顺序进行。
- **指定一个数**，例如 `alscl_speed(sd_cores = 6)`，即使用这么多核。在计算集群上，请使用作业实际分配到的核数；`parallel::detectCores()` 可能报告整个节点的核数。
- **内存。** 分叉进程与 R 会话共享内存，直到内容被修改。每个 socket 进程都保存一份模型和数据；模型很大时，减少进程数可以节省内存。
- **多起点。** `run_acl()` 与 `run_alscl()` 中的 `ncores` 决定同时运行多少个起点；标准误在之后用 `sd_cores` 计算一次。
- **自己的并行循环。** 如果你自己并行运行许多拟合（例如用 `parallel::mclapply()`、`foreach` 或 `future`），请在工作进程中设置 `alscl_speed(sd_cores = 1)`，让每个拟合只用 1 个核。`retro_model()` 与 `sim_acl()` 会自动为其工作进程这样设置。

## 6. TMBad 选项

TMB 可以用两种自动微分库之一编译模型。默认库 CppAD 与 ALSCL 2.0.0 相同，但新版收尾和模型选项可能改变拟合结果；TMBad 计算拉普拉斯近似及其梯度要快几倍：

```r
alscl_speed(framework = "TMBad")   # 下一次拟合会用 TMBad 编译一次模型
```

TMBad 以不同的顺序计算同样的导数，因此结果的最后几位不同。基准测试中估计 5 个固定效应时，估计值的相对差最大 2.3e-11。在一个估计 10 个固定效应的 ACL 拟合中，相对差最大 2.7e-8（目标函数相差 1.7e-11）：自由参数越多，似然面越平，微小差异会在 `nlminb()` 的容差范围内改变它停止的位置。

TMBad 适合探索性拟合、大量拟合（模拟研究、敏感性分析）等这种量级差异无关紧要的场合。要精确复现已发表或以前的结果，请用 CppAD。要在自己的数据上核对，可以两种都拟合后比较：

```r
args <- x  # YTF_example
alscl_speed(framework = "CppAD"); a <- run_alscl(args)
alscl_speed(framework = "TMBad"); b <- run_alscl(args)
max(abs(b$opt$par - a$opt$par) / abs(a$opt$par))   # 估计值的最大相对差
max(abs(b$est_std[, 2] - a$est_std[, 2]) / a$est_std[, 2], na.rm = TRUE)  # 标准误
```

这里的 `args` 是你传给 `run_alscl()` 的参数列表。

## 7. 检查与记录设置

- 拟合前，`alscl_speed_info()` 显示设置值、将使用的核数与方式、原因、自动微分库，以及不保证跨版本逐位一致的提醒。
- 拟合后，`fit$sd_info` 给出 `method`（`"forked processes"`、`"socket workers (delta method)"` 或 `"sequential"`）、`cores`、`seconds`，以及说明为何顺序计算的 `note`。`silent = FALSE` 时也会打印这些信息。
- 报告结果时，请与 `sessionInfo()` 一起记录 `alscl_speed_info()`。默认设置下，结果不随核数或计算方式改变；使用 `framework = "TMBad"` 时结果与 CppAD 略有不同，请注明所用的库。

## 8. 实测加速效果

基准测试共 90 次拟合（ACL 与 ALSCL 分别拟合 `YTF_example`、flatfish 与 tuna 案例，各运行 3 次，Apple M2 Pro，测试期间有其他任务，在 macOS 终端中运行，因此使用分叉进程）：

| 模型、数据 | 原版 | 默认 | TMBad |
|---|---:|---:|---:|
| ACL，YTF_example | 8.6 秒 | 7.7 秒（1.13 倍） | 6.6 秒（1.31 倍） |
| ALSCL，YTF_example | 140.9 秒 | 118.8 秒（1.19 倍） | 83.9 秒（1.68 倍） |
| ALSCL，flatfish | 107.8 秒 | 86.9 秒（1.24 倍） | 78.8 秒（1.37 倍） |
| ALSCL，tuna（季度） | 217.4 秒 | 180.9 秒（1.20 倍） | 141.3 秒（1.54 倍） |

![速度设置前后的拟合耗时](../../../docs/figures/speed/timing.png)

旧版加速基准中所有结果都与当时的原版逐位相同；下图显示 ALSCL 拟合 `YTF_example` 时 `summary(sdreport)` 的全部 4,365 行。

![速度设置前后的估计值与标准误](../../../docs/figures/speed/agreement.png)

在模拟的 RStudio 会话中（macOS，设置 `RSTUDIO=1`，因此使用 socket 进程；10 核机器的负载约为 12），20 年 ALSCL 拟合的标准误在 4 个 socket 进程上用 25.4 秒，顺序计算需 28.3 秒；整个拟合用 114.9 秒，顺序计算需 120.4 秒；结果逐位相同。使用 socket 进程时，提升只来自 delta 方法；在主会话中计算的 Hessian 约占标准误时间的一半。在 macOS 或 Linux 上，`options(ALSCL.sd_backend = "fork")` 可让 RStudio 也获得分叉进程的速度（第 4.2 节）。

固定效应越多（Hessian 的列越多）、ADREPORT 量越多（时间序列越长、体长组越多），提升越大。一个估计 10 个固定效应的 ACL 拟合，标准误在 4 个分叉进程上用 1.6 秒，顺序计算需 3.7 秒。

## 9. 故障排查

| 信息或现象 | 含义与处理 |
|---|---|
| `Parallel standard errors failed (...); computing them sequentially.` | 无法启动进程或某个进程出错。标准误已改为顺序计算，结果正确。若经常出现，请设置 `alscl_speed(sd_cores = 1)`。 |
| `Standard errors: sequential (TMB x.y.z was not checked)` | 并行代码只复现核对过的 TMB 版本的 `TMB::sdreport()`。结果正确；要在新 TMB 版本上并行计算，请用该版本运行包的测试（`tests/testthat/test-speed.R`），再把版本号加入 `R/speed.R` 中的清单。 |
| `Standard errors: sequential (too little work to start socket workers)` | 在图形界面或 Windows 中，模型较小，启动进程不会更快。 |
| RStudio 中没有加速 | 查看 `alscl_speed_info()`。使用 socket 进程时只有 delta 方法被分配出去（第 4.2 节）；在 macOS 或 Linux 上，`options(ALSCL.sd_backend = "fork")` 可获得完整加速，风险自负。 |
| 使用多核时内存不足 | 减少核数，例如 `alscl_speed(sd_cores = 2)`。 |
| 设置 `alscl_speed(framework = "TMBad")` 后第一次拟合较慢 | 模型要用 TMBad 编译一次；同一会话中之后的拟合会重复使用。 |

## 10. 高级选项

这些选项用于测试和特殊情况；默认值适合日常使用。

| 选项 | 作用 |
|---|---|
| `options(ALSCL.sd_backend = "fork")` | 即使 R 不建议，也使用分叉进程（Windows 上从不使用） |
| `options(ALSCL.sd_backend = "socket")` | 即使可以安全分叉，也使用 socket 进程 |
| `options(ALSCL.sd_socket_min_seconds = 3)` | 启动 socket 进程前 delta 方法的最短预计耗时（秒）；设为 `0` 时总是启动 |
| `options(ALSCL.tmb.cache = path)` | 存放已编译模型的文件夹 |

恢复默认，例如 `options(ALSCL.sd_backend = NULL)`。
