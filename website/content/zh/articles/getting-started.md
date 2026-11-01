# 安装 ALSCL 并完成第一次拟合

本页带你安装软件包、确认它能加载，并用内置示例拟合一个模型。你需要 R 4.1 或更高版本和网络连接；现在还不需要自己的调查数据。整个过程约十五分钟，其中大部分是第 4 步只需一次的模型编译。

| 步骤 | 完成后得到什么 |
|---|---|
| 1. 安装编译器 | 在本机构建两个模型所需的工具 |
| 2. 安装软件包 | 从 GitHub 安装的 ALSCL 及其依赖包 |
| 3. 加载并检查 | 已加载的软件包和示例数据 |
| 4. 拟合示例 | 一个拟合好的 ACL 模型及其数值检查 |

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

ALSCL 发布在 GitHub 而不是 CRAN，因此用 `remotes` 安装，它会一并安装依赖包（TMB、ggplot2 等）。有新版本时重新运行这两行即可；[更新日志](../news/index.html)列出每个版本的变化。

如果安装在某个依赖包上停止，用 `install.packages()` 安装该包，再运行第二行。如果错误信息提到编译器，回到第 1 步。

<h2 id="load">3. 加载软件包和示例数据</h2>

```r
library(ALSCL)
packageVersion("ALSCL")
data("YTF_example")
str(YTF_example[c("data.CatL", "data.wgt", "data.mat")])
```

每个会话都从 `library(ALSCL)` 开始。`YTF_example` 是一套模拟数据，形式与黄盖鲽调查相同：调查指数表 `data.CatL`、体重表 `data.wgt` 和成熟比例表 `data.mat`，每张表 23 个体长组为行、20 个年份为列。第一列是体长组标签，其余各列是年份。

你应看到 2.3.0 或更高的版本号，以及三张大小相同的数据框。这一步不编译任何东西，只确认安装可用。

<h2 id="first-fit">4. 拟合示例</h2>

```r
x <- YTF_example
a <- run_acl(x, silent = TRUE)
diagnose_model(x$data.CatL, a)
```

`run_acl()` 用 `x` 中保存的生物学设置和初值，把年龄结构模型 ACL 拟合到三张表。第一次调用会编译模型，需要一到三分钟；拟合本身约二十秒。`silent = TRUE` 不显示进度信息。

`diagnose_model()` 打印这次拟合的数值检查：优化器收敛码（0 表示正常结束）、解处的最大绝对梯度（应小于 0.001）、Hessian 是否正定（`TRUE` 表示可以计算标准误）、是否有参数落在边界上（`FALSE`）。`Numerical screen: TRUE` 一行是这些检查的汇总，同一结果也保存在 `a$diagnostics$numerical_ok`。若为 `FALSE`，`a$diagnostics$issues` 会给出未通过的项目，[理解第一次拟合](first-model.html)解释每项检查的含义和处理办法。

<h2 id="next">下一步</h2>

| 想做什么 | 阅读 |
|---|---|
| 了解拟合结果包含什么、如何判断它可用 | [理解第一次拟合](first-model.html) |
| 拟合自己的调查数据 | [准备调查数据](data-preparation.html) |
| 解决安装或编译问题 | [复现与故障处理](reproducibility.html) |

本网站的内容都可以在安装好的软件包中直接运行。只有调用 `source("scripts/...")` 或读取 `docs/data/...` 路径的示例，才需要下载[仓库](https://github.com/FanZhang-LAB-SHOU/ALSCL)，并把仓库根目录设为 R 工作目录。
