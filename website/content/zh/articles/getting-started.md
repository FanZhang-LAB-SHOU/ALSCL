# 安装 ALSCL 并完成第一次拟合

本页带你安装软件包、确认它能加载，用内置示例拟合一个模型，检查拟合并画出一个估计值。你需要 R 4.1 或更高版本和网络连接；示例数据随包附带。整个过程约十五分钟，包括第 4 步只需一次的模型编译。

| 步骤 | 完成后得到什么 |
|---|---|
| 1. 安装编译器 | 在本机构建两个模型所需的工具 |
| 2. 安装软件包 | 从 GitHub 安装的 ALSCL 及其依赖包 |
| 3. 加载并检查 | 已加载的软件包和示例数据 |
| 4. 拟合示例 | 一个拟合好的 ACL 模型、它的数值检查和产卵生物量图 |

<h2 id="compiler">1. 安装编译器</h2>

两个模型用 C++ 编写，由 Template Model Builder（TMB）调用。第一次拟合时会在你的电脑上编译模型，之后的拟合直接使用编译结果。第一次拟合前，先按系统安装编译器。

| 系统 | 需要安装 |
|---|---|
| Windows | 与 R 版本对应的 [Rtools](https://cran.r-project.org/bin/windows/Rtools/) |
| macOS | Xcode Command Line Tools（在终端运行 `xcode-select --install`） |
| Linux | C++ 编译器和 `make`，例如 Debian、Ubuntu 上的 `build-essential` |

如果没有编译器，第 4 步的第一次拟合会报错，错误信息中会出现编译器或 `TMB::compile` 字样。安装工具后重启 R，再运行一次拟合。

<h2 id="install">2. 安装软件包</h2>

```r
install.packages("remotes")
remotes::install_github("FanZhang-LAB-SHOU/ALSCL")
```

ALSCL 发布在 GitHub 而不是 CRAN，因此用 `remotes` 安装，它会一并安装依赖包，其中包括 TMB 1.9.17 或更高版本和 ggplot2 4.0.0 或更高版本。有新版本时重新运行这两行即可；[更新日志](../news/index.html)列出每个版本的变化。

在 Windows 和 macOS 上，R 尽量安装现成的二进制包。如果它询问是否从源码安装软件包（`Do you want to install from sources the packages which need compilation?`），按下表中你的 R 版本回答：

| R 版本 | R 安装的内容 | 回答 |
|---|---|---|
| 4.4 或更高 | 全部软件包都是二进制包 | `no` |
| 4.3 | TMB 是二进制包；ggplot2、patchwork 等几个不含编译代码的包从源码安装，不需要编译器 | `no` |
| 4.1 和 4.2 | TMB 和其他一些包用第 1 步的编译器从源码编译；在 macOS 上，TMB 还需要 [CRAN macOS 工具页](https://mac.r-project.org/tools/)上的 GNU Fortran 编译器 | `yes` |

在 Windows 上使用 R 4.1 至 4.2.2 时，编译器无法构建 TMB 1.9.22 或更高版本。先安装 TMB 1.9.21，再安装 ALSCL，并且不升级 TMB：

```r
remotes::install_version("TMB", "1.9.21")
remotes::install_github("FanZhang-LAB-SHOU/ALSCL", upgrade = "never")
```

在 Linux 上，R 从源码编译所有软件包；[Posit Package Manager](https://packagemanager.posit.co/) 为 R 4.1 及更高版本提供二进制包。

如果安装在某个依赖包上停止，用 `install.packages()` 安装该包，再运行 `remotes::install_github()`。如果错误信息提到编译器，回到第 1 步。

本网站的内容都可以在安装好的软件包中直接运行。只有调用 `source("scripts/...")` 或读取 `docs/data/...` 路径的示例，才需要下载[仓库](https://github.com/FanZhang-LAB-SHOU/ALSCL)，并把仓库根目录设为 R 工作目录。

<h2 id="load">3. 加载软件包和示例数据</h2>

```r
library(ALSCL)
packageVersion("ALSCL")
data("YTF_example")
str(YTF_example[c("data.CatL", "data.wgt", "data.mat")])
```

每个会话都从 `library(ALSCL)` 开始。`YTF_example` 是用 `YTF` 中保存的 yellowtail flounder（*Limanda ferruginea*，[物种资料](https://www.fisheries.noaa.gov/species/yellowtail-flounder)）生物学设置生成的模拟教学数据。它包含调查指数表 `data.CatL`、体重表 `data.wgt` 和成熟比例表 `data.mat`，每个体长组一行。

你应看到 2.5.2 或更高的版本号，每张表显示 `23 obs. of 21 variables`，即 23 个体长组和 21 列，第一列是体长组标签，其余各列依次是 2000 至 2019 年。这一步不编译任何东西，只确认安装可用。

如果加载时出现警告，说 TMB 构建时用的是另一个 Matrix ABI 版本，说明 TMB 的二进制包与已安装的 Matrix 不匹配，之后每次拟合都可能以 `All optimization starts failed` 和 `NA/NaN` 失败。运行 `install.packages(c("Matrix", "TMB"))` 并重启 R。如果警告仍在，用 `install.packages("TMB", type = "source")` 编译 TMB（在 macOS 上需要第 2 步提到的 GNU Fortran 编译器），重启 R 后重新加载软件包。

<h2 id="first-fit">4. 拟合示例</h2>

```r
x <- YTF_example
a <- run_acl(x, silent = TRUE)
diagnose_model(x$data.CatL, a)
plot_SSB(a, se = TRUE)
```

`x` 是输入列表，其中有三张表和各项设置。`run_acl()` 用 `x` 中保存的生物学设置和初值，把年龄结构模型 ACL 拟合到三张表。第一次调用会编译模型，需要一到三分钟，并打印编译器的命令；拟合本身约十秒。`silent = TRUE` 不显示拟合的进度信息。

`diagnose_model()` 先打印数值检查，再打印一张拟合统计量和检查结果的表，表下简要说明各统计量。本例的检查中有 `Optimizer convergence code: 0`、`Numerical checks: TRUE`、`Parameters at their limit in practice: 0` 和 `Plausibility notes: 0`。`Numerical checks: TRUE` 保存在 `a$diagnostics$numerical_ok` 中，表示梯度、Hessian、协方差和边界准则通过，并且没有实际上已到极限的参数。优化器收敛码和强参数相关另行报告，见 `a$diagnostics$issues`。拟合统计量（拟合调查指数的误差、AIC 和 BIC）留待以后比较不同拟合时使用。检查未通过时，[理解第一次拟合](first-model.html#checks)说明可以尝试的办法。

`plot_SSB()` 画出产卵生物量及其 95% 区间。本次拟合的产卵生物量在 2010 年降到最低，随后上升到 2016 年。

<h2 id="next">下一步</h2>

| 想做什么 | 阅读 |
|---|---|
| 了解拟合结果包含什么、如何判断它可用 | [理解第一次拟合](first-model.html) |
| 拟合自己的调查数据 | [准备调查数据](data-preparation.html) |
| 解决安装或编译问题 | [复现结果与排除故障](reproducibility.html) |
