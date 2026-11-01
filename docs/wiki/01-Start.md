# 01 安装与第一次拟合 · Install and run a first fit

[目录 · Contents](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [下一章 · Next →](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/02-Theory)

**ALSCL 2.3.0 · 简体中文 / English**

本页带你安装软件包、确认它能加载，并用内置示例拟合一个模型。你需要 R 4.1 或更高版本和网络连接；现在还不需要自己的调查数据。整个过程约十五分钟，其中大部分是第 4 步只需一次的模型编译。

On this page you install the package, confirm that it loads, and fit one model to the bundled example. You need R 4.1 or later and an internet connection; you do not need survey data of your own yet. Allow about fifteen minutes, most of it for the one-time compilation in step 4.

| 步骤 / Step | 完成后得到什么 / What you will have afterwards |
|---|---|
| 1. 安装编译器 / 1. Install the compiler | 在本机构建两个模型所需的工具 / The tools that build the two models on your computer |
| 2. 安装软件包 / 2. Install the package | 从 GitHub 安装的 ALSCL 及其依赖包 / ALSCL and its dependencies installed from GitHub |
| 3. 加载并检查 / 3. Load and check | 已加载的软件包和示例数据 / The package and the example data loaded in your session |
| 4. 拟合示例 / 4. Fit the example | 一个拟合好的 ACL 模型及其数值检查 / A fitted ACL model and its numerical checks |

<a id="getting-started-compiler"></a>

### 1. 安装编译器 / Install the compiler

两个模型用 C++ 编写，由 Template Model Builder（TMB）调用。第一次拟合时会在你的电脑上编译模型，之后的拟合直接使用编译结果。第一次拟合前，先按系统安装编译器。

The two models are written in C++ for Template Model Builder (TMB). The first fit compiles them on your computer; later fits reuse the compiled files. Install the compiler for your system before the first fit.

| 系统 / System | 需要安装 / What to install |
|---|---|
| Windows | 与 R 版本对应的 [Rtools](https://cran.r-project.org/bin/windows/Rtools/) / [Rtools](https://cran.r-project.org/bin/windows/Rtools/) for your R version |
| macOS | Xcode Command Line Tools（在终端运行 `xcode-select --install`） / The Xcode Command Line Tools (`xcode-select --install` in Terminal) |
| Linux | C++ 编译器和 `make`，例如 Debian、Ubuntu 上的 `build-essential` / A C++ compiler and `make`, for example `build-essential` on Debian and Ubuntu |

如果没有编译器，第 4 步的第一次拟合会报错，错误信息中会出现编译器或 `TMB::compile` 字样。安装工具后重启 R，再运行一次拟合。

If the compiler is missing, the first fit in step 4 stops with an error that mentions the compiler or `TMB::compile`. Install the tools, restart R and run the fit again.

<a id="getting-started-install"></a>

### 2. 安装软件包 / Install the package

```r
install.packages("remotes")
remotes::install_github("FanZhang-LAB-SHOU/ALSCL")
```

ALSCL 发布在 GitHub 而不是 CRAN，因此用 `remotes` 安装，它会一并安装依赖包（TMB、ggplot2 等）。有新版本时重新运行这两行即可；[更新日志](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/NEWS.md)列出每个版本的变化。

ALSCL is published on GitHub, not on CRAN, so `remotes` installs it together with the packages it depends on (TMB, ggplot2 and others). Run the same two lines again when a new release appears; the [changelog](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/NEWS.md) lists what changed.

如果安装在某个依赖包上停止，用 `install.packages()` 安装该包，再运行第二行。如果错误信息提到编译器，回到第 1 步。

If the installation stops on a dependency, install that package with `install.packages()` and run the second line again. If it stops with a compiler message, go back to step 1.

<a id="getting-started-load"></a>

### 3. 加载软件包和示例数据 / Load the package and the example data

```r
library(ALSCL)
packageVersion("ALSCL")
data("YTF_example")
str(YTF_example[c("data.CatL", "data.wgt", "data.mat")])
```

每个会话都从 `library(ALSCL)` 开始。`YTF_example` 是一套模拟数据，形式与黄盖鲽调查相同：调查指数表 `data.CatL`、体重表 `data.wgt` 和成熟比例表 `data.mat`，每张表 23 个体长组为行、20 个年份为列。第一列是体长组标签，其余各列是年份。

Every session starts with `library(ALSCL)`. `YTF_example` is a synthetic dataset shaped like a yellowtail flounder survey: a survey index table `data.CatL`, a weight table `data.wgt` and a maturity table `data.mat`, each with 23 length bins in rows and 20 years in columns. The first column holds the length-bin labels; the other columns are the years.

你应看到 2.3.0 或更高的版本号，以及三张大小相同的数据框。这一步不编译任何东西，只确认安装可用。

You should see version 2.3.0 or later and three data frames of the same size. Nothing is compiled yet; this step only confirms that the installation works.

<a id="getting-started-first-fit"></a>

### 4. 拟合示例 / Fit the example

```r
x <- YTF_example
a <- run_acl(x, silent = TRUE)
diagnose_model(x$data.CatL, a)
```

`run_acl()` 用 `x` 中保存的生物学设置和初值，把年龄结构模型 ACL 拟合到三张表。第一次调用会编译模型，需要一到三分钟；拟合本身约二十秒。`silent = TRUE` 不显示进度信息。

`run_acl()` fits the age-structured model, ACL, to the three tables using the biological settings and starting values stored in `x`. The first call compiles the model, which takes one to three minutes; the fit itself takes about twenty seconds. `silent = TRUE` hides the progress messages.

`diagnose_model()` 打印这次拟合的数值检查：优化器收敛码（0 表示正常结束）、解处的最大绝对梯度（应小于 0.001）、Hessian 是否正定（`TRUE` 表示可以计算标准误）、是否有参数落在边界上（`FALSE`）。`Numerical screen: TRUE` 一行是这些检查的汇总，同一结果也保存在 `a$diagnostics$numerical_ok`。若为 `FALSE`，`a$diagnostics$issues` 会给出未通过的项目，[理解第一次拟合](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin)解释每项检查的含义和处理办法。

`diagnose_model()` prints the numerical checks of the fit: the optimizer convergence code (0 means it finished normally), the maximum absolute gradient at the solution (below 0.001), whether the Hessian is positive definite (`TRUE`, so standard errors can be computed) and whether a parameter sits on a bound (`FALSE`). The line `Numerical screen: TRUE` summarizes them; the same value is stored in `a$diagnostics$numerical_ok`. If it is `FALSE`, `a$diagnostics$issues` names the failed check, and [Understand your first fit](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin) explains each check and what to do about it.

<a id="getting-started-next"></a>

### 下一步 / What next

| 想做什么 / What you want to do | 阅读 / Read |
|---|---|
| 了解拟合结果包含什么、如何判断它可用 / See what the fitted object contains and how to judge it | [理解第一次拟合](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin) / [Understand your first fit](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin) |
| 拟合自己的调查数据 / Fit your own survey tables | [准备调查数据](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel) / [Prepare your survey data](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel) |
| 解决安装或编译问题 / Fix an installation or compilation problem | [复现与故障处理](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ADVANCED_WORKFLOWS.md) / [Reproducibility and troubleshooting](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ADVANCED_WORKFLOWS.md) |

本网站的内容都可以在安装好的软件包中直接运行。只有调用 `source("scripts/...")` 或读取 `docs/data/...` 路径的示例，才需要下载[仓库](https://github.com/FanZhang-LAB-SHOU/ALSCL)，并把仓库根目录设为 R 工作目录。

Everything on this website works from an installed package. Only examples that call `source("scripts/...")` or read a `docs/data/...` path need a downloaded copy of the [repository](https://github.com/FanZhang-LAB-SHOU/ALSCL), opened as the R working directory.

---

[目录 · Contents](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [下一章 · Next →](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/02-Theory)
