# ALSCL 完整使用手册 · Complete user manual

<img src="https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/ALSCLlogo.png?raw=true" alt="ALSCL logo" align="right" height="140" />

**调查体长数据的种群评估 · Survey catch-at-length stock assessment**

**ALSCL 2.4.1 · 简体中文与英文 · 18 章 / chapters**

本手册按主题整理模型原理、数据、拟合、诊断、绘图、模拟与预测验证。第一次使用可按下面的路线完成操作，再查阅需要的技术细节。本手册对应 ALSCL 2.4.1。

This manual groups model principles, data, fitting, diagnostics, plotting, simulation and prediction checks by task. Follow a reading path below, then consult the technical sections you need. The manual describes ALSCL 2.4.1.

[开始使用 · Getting started](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/01-Start) · [仓库主页 · Repository](https://github.com/FanZhang-LAB-SHOU/ALSCL/tree/main) · [单页书稿 · Single-page book](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/BOOK.md) · [Excel 示例 · Workbook](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/data/ALSCL_Data_Entry_Example.xlsx)

## 选择阅读路线 · Choose a reading path

| 你的任务 / Your task | 建议顺序 / Suggested order |
|---|---|
| 第一次使用 / First run | [安装 / Install](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/01-Start) → [内置拟合 / First fit](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/04-Built-in-YTF) → [诊断 / Diagnostics](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/07-Diagnostics) |
| 拟合自己的数据 / Your own data | [准备数据 / Prepare data](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/03-Data-and-Excel) → [参数与 map / Parameters and maps](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/06-Fitting) → [诊断 / Diagnostics](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/07-Diagnostics) |
| 整理和评估拟合结果 / Work with fitted results | [结果、敏感性与情景 / Results, sensitivity and scenarios](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/16-Assessment-Workflows) |
| 模拟或检验未来预测 / Simulation or prediction checks | [模型验证完整案例 / Model-validation case](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/17-Model-Validation) |
| 选择图形与导出 / Plot and export | [种群图 / Population plots](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/08-Population-Plots) → [配色和导出 / Style and export](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki/13-Colors-and-Export) |

这些是按任务选择的入口，不必按章节编号从头读起。需要逐项查参数时使用第 14 章；想用单一语言连续阅读时，访问 [English website](https://fanzhang-lab-shou.github.io/ALSCL/) 或 [简体中文网站](https://fanzhang-lab-shou.github.io/ALSCL/zh/)。

Use these task-based entry points without reading every chapter in numerical order. Chapter 14 is an argument reference. The website provides continuous reading in either language.


## 全书目录 · Book contents

- [01 安装与第一次拟合 · Install and run a first fit](#chapter-01)
- [02 模型原理与时间尺度 · Model principles](#chapter-02)
- [03 准备调查数据 · Prepare your survey data](#chapter-03)
- [04 理解第一次拟合 · Understand your first fit](#chapter-04)
- [05 模拟与批量实验 · Simulation](#chapter-05)
- [06 选择拟合设置 · Choose the fitting settings](#chapter-06)
- [07 判断拟合是否可用 · Judge whether a fit can be used](#chapter-07)
- [08 调查与种群图 · Survey and population plots](#chapter-08)
- [09 生长、死亡与残差图 · Growth, mortality and residuals](#chapter-09)
- [10 模型比较与真值 · Model comparisons](#chapter-10)
- [11 回溯分析 · Retrospectives](#chapter-11)
- [12 年度与季度案例 · Annual and quarterly cases](#chapter-12)
- [13 ggsci 配色与导出 · Colors and export](#chapter-13)
- [14 全部函数与参数 · Complete function reference](#chapter-14)
- [15 复现与故障处理 · Reproducibility and troubleshooting](#chapter-15)
- [16 评估工作流 · Assessment workflows](#chapter-16)
- [17 模型模拟与预测验证 · Model simulation and prediction checks](#chapter-17)
- [18 工作案例 · Worked cases](#chapter-18)

<a id="chapter-01"></a>
## 01 安装与第一次拟合 · Install and run a first fit

本页带你安装软件包、确认它能加载，并用内置示例拟合一个模型。你需要 R 4.1 或更高版本和网络连接；示例数据随包附带。整个过程约十五分钟，其中大部分是第 4 步只需一次的模型编译。

On this page you install the package, confirm that it loads, and fit one model to the bundled example. You need R 4.1 or later and an internet connection; the example data are included. Allow about fifteen minutes, most of it for the one-time compilation in step 4.

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

你应看到 2.4.0 或更高的版本号，以及三张大小相同的数据框。这一步不编译任何东西，只确认安装可用。

You should see version 2.4.0 or later and three data frames of the same size. Nothing is compiled yet; this step only confirms that the installation works.

<a id="getting-started-first-fit"></a>

### 4. 拟合示例 / Fit the example

```r
x <- YTF_example
a <- run_acl(x, silent = TRUE)
diagnose_model(x$data.CatL, a)
```

`run_acl()` 用 `x` 中保存的生物学设置和初值，把年龄结构模型 ACL 拟合到三张表。第一次调用会编译模型，需要一到三分钟；拟合本身约二十秒。`silent = TRUE` 不显示进度信息。

`run_acl()` fits the age-structured model, ACL, to the three tables using the biological settings and starting values stored in `x`. The first call compiles the model, which takes one to three minutes; the fit itself takes about twenty seconds. `silent = TRUE` hides the progress messages.

`diagnose_model()` 打印这次拟合的数值检查：优化器收敛码（0 表示正常结束）、解处的最大绝对梯度（应小于 0.001）、Hessian 是否正定（`TRUE` 表示可以计算标准误）、是否有参数落在边界上（`FALSE`）。打印的 `Numerical checks: TRUE` 一行是这些检查的汇总，同一结果也保存在 `a$diagnostics$numerical_ok`。若为 `FALSE`，`a$diagnostics$issues` 会给出未通过的项目，[理解第一次拟合](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin)解释每项检查的含义和处理办法。

`diagnose_model()` prints the numerical checks of the fit: the optimizer convergence code (0 means it finished normally), the maximum absolute gradient at the solution (below 0.001), whether the Hessian is positive definite (`TRUE`, so standard errors can be computed) and whether a parameter sits on a bound (`FALSE`). The line `Numerical checks: TRUE` summarizes the checks; the same value is stored in `a$diagnostics$numerical_ok`. If it is `FALSE`, `a$diagnostics$issues` names the failed check, and [Understand your first fit](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin) explains each check and what to do about it.

本网站的内容都可以在安装好的软件包中直接运行。只有调用 `source("scripts/...")` 或读取 `docs/data/...` 路径的示例，才需要下载[仓库](https://github.com/FanZhang-LAB-SHOU/ALSCL)，并把仓库根目录设为 R 工作目录。

Everything on this website works from an installed package. Only examples that call `source("scripts/...")` or read a `docs/data/...` path need a downloaded copy of the [repository](https://github.com/FanZhang-LAB-SHOU/ALSCL), opened as the R working directory.

<a id="getting-started-next"></a>

### 下一步 / What next

| 想做什么 / What you want to do | 阅读 / Read |
|---|---|
| 了解拟合结果包含什么、如何判断它可用 / See what the fitted object contains and how to judge it | [理解第一次拟合](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin) / [Understand your first fit](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin) |
| 拟合自己的调查数据 / Fit your own survey tables | [准备调查数据](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel) / [Prepare your survey data](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel) |
| 解决安装或编译问题 / Fix an installation or compilation problem | [复现与故障处理](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ADVANCED_WORKFLOWS.md) / [Reproducibility and troubleshooting](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ADVANCED_WORKFLOWS.md) |

<a id="chapter-02"></a>
## 02 模型原理与时间尺度 · Model principles

本页带你阅读 ACL 和 ALSCL 背后的方程（采用本包的时间单位和随机效应参数化）、检查一次拟合中的两种概率矩阵，并把年率换算到模型时间步。第 1 步需要[理解第一次拟合](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin)中的 ALSCL 拟合 `b`；方程采用 [Zhang & Cadigan (2022)](https://doi.org/10.1111/faf.12673) 的模型框架。

On this page you read the equations behind ACL and ALSCL in the package's time units and parameterization, check the two probability matrices of a fit, and convert annual rates to the model time step. Step 1 needs the ALSCL fit `b` from [Understand your first fit](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin); the equations follow [Zhang & Cadigan (2022)](https://doi.org/10.1111/faf.12673).

<a id="model-theory-equations"></a>

### 方程 / The equations

<a id="model-theory-dynamics"></a>

#### 种群动态 / Population dynamics

令 $`i=1,\ldots,A`$ 为年龄组索引，$`a_i=a_{rec}+(i-1)\Delta t`$ 为实际年龄，$`t`$ 为时间步。ACL 在年龄维度推进存活；补充量进入第一组，最大年龄组为加组：

Let $`i=1,\ldots,A`$ index age classes, with actual age $`a_i=a_{rec}+(i-1)\Delta t`$, and let $`t`$ index time steps. ACL advances survivors by age, introduces recruitment in the first class, and retains survivors in the oldest plus group:

```math
N_{1,t}=R_t,\qquad Z_{i,t}=M+F_{i,t},
```

```math
N_{i+1,t+1}=N_{i,t}\exp(-Z_{i,t}),\qquad i=1,\ldots,A-2,
```

```math
N_{A,t+1}=N_{A-1,t}\exp(-Z_{A-1,t})+N_{A,t}\exp(-Z_{A,t}).
```

M 和 F 是每个时间步的瞬时死亡率；季度模型的 `growth_step=0.25`，M 和 F 也须使用季度率。生长参数 $`k`$ 按年定义。

M and F are instantaneous rates per time step. A quarterly model uses `growth_step=0.25` and quarterly mortality rates; the growth parameter $`k`$ is annual.

<a id="model-theory-fishing"></a>

#### 捕捞死亡率 / Fishing mortality

ACL 按年龄估计 F，ALSCL 按体长估计 F。以 $`s`$ 表示相应的年龄或体长组，两个模型均使用可分离的 AR(1) × AR(1) 对数 F 偏差：

ACL estimates F by age, whereas ALSCL estimates F by length. With $`s`$ denoting the age or length class, both use separable AR(1) × AR(1) deviations in log F:

```math
F_{s,t}=\exp(\mu_F+d_{s,t}),\qquad
\mathrm{Cov}(d_{s,t},d_{s-h,t-j})=\sigma_F^2\phi_S^{|h|}\phi_T^{|j|}.
```

这里 $`\sigma_F`$ 是 TMB 可分离 AR(1) 密度经缩放后的边际标准差；相关参数描述组间和时间上的相关性。该式已经包含边际方差，无需再除以 $`1-\phi^2`$ 因子，那是创新方差参数化的写法。自然死亡率 M 作为已知输入。

Here $`\sigma_F`$ is the marginal SD in TMB's scaled, separable AR(1) density, and the correlation parameters describe dependence across groups and time. The expression already contains the marginal variance, so it needs no further division by $`1-\phi^2`$ factors, which belong to innovation-variance parameterizations. Natural mortality M is supplied as known.

<a id="model-theory-recruitment"></a>

#### 补充量 / Recruitment

拟合模型用 AR(1) 对数偏差描述补充量。与边际标准差 $`\sigma_R`$ 一致的平稳形式为：

The fitted models use AR(1) log recruitment deviations. The stationary representation with marginal SD $`\sigma_R`$ is:

```math
R_t=\exp(\mu_R+r_t),\qquad
r_1\sim N(0,\sigma_R^2),\qquad
r_{t+1}=\phi_R r_t+\eta_t,\quad
\eta_t\sim N\!\left(0,\sigma_R^2(1-\phi_R^2)\right).
```

$`\exp(\mu_R)`$ 是补充量的中位数；算术均值还包含 $`r_t`$ 的方差。完整模拟器 `sim_data()` 使用 Beverton-Holt 亲体补充关系及随机偏差，是另一套补充过程。

$`\exp(\mu_R)`$ is the median recruitment; the arithmetic mean also includes the variance of $`r_t`$. The full `sim_data()` operating model uses Beverton-Holt stock-recruitment with random deviations, a recruitment process of its own.

<a id="model-theory-initial"></a>

#### 初始条件 / Initial conditions

第一期最小年龄组由 $`R_1`$ 给定，其余年龄组按初始死亡率与逐组扰动递推：

Initial recruitment defines the youngest class; the other classes follow a recursive decline with an initial mortality rate and class-to-class deviations:

```math
\log N_{1,1}=\log R_1,\qquad
\log N_{i,1}=\log N_{i-1,1}-Z_{init}+u_{i-1},\quad
u_{i-1}\sim N(0,\sigma_{N0}^2).
```

因此 $`\log N_{i,1}=\log R_1-(i-1)Z_{init}+\sum_{j=1}^{i-1}u_j`$：扰动沿年龄组累积，相邻年龄组的总扰动相互相关。ALSCL 再用初始年龄-体长概率分配这些个体。

The initial log abundance of a class therefore contains the cumulative sum of the deviations of the younger classes, so the total deviations of neighbouring classes are correlated. ALSCL allocates these initial numbers across length using age-length probabilities.

<a id="model-theory-pla"></a>

#### 年龄-体长转换（ACL） / Age-to-length conversion (ACL)

给定年龄的长度服从均值由 von Bertalanffy 曲线决定的正态分布：

Length conditional on age follows a normal distribution whose mean is defined by the von Bertalanffy curve:

```math
\mu_i=L_\infty\left[1-e^{-k(a_i-t_0)}\right],\qquad
\sigma_i=CV_L\mu_i,
```

```math
p_{l|i}=\Phi\!\left(\frac{UB_l-\mu_i}{\sigma_i}\right)
       -\Phi\!\left(\frac{LB_l-\mu_i}{\sigma_i}\right),\qquad
N_{l,t}=\sum_i p_{l|i}N_{i,t}.
```

`pla` 表示这个年龄-体长概率矩阵，`plot_pla()` 用热图展示。实现使用支持自动微分的正态 CDF 差，并通过右尾对称计算和归一化处理数值稳定性，以此代替论文 Appendix S1 的固定阶 Taylor 近似；长度边界必须与调查分组一致。

`pla` is the age-length probability matrix shown by `plot_pla()`. The implementation uses differentiable normal CDF differences with symmetric right-tail calculations and normalization, in place of the fixed-order Taylor approximation of Appendix S1; boundaries must match the survey bins.

<a id="model-theory-growth"></a>

#### 生长转移矩阵（ALSCL） / Growth transition matrix (ALSCL)

ALSCL 保留 $`N_{l,i,t}`$ 的体长、年龄、时间三个维度。$`G_{j,l}`$ 表示从源体长组 $`l`$ 转入目的体长组 $`j`$ 的概率。普通年龄组的存活与增长为：

ALSCL retains length, age and time in $`N_{l,i,t}`$. Entry $`G_{j,l}`$ is the probability of moving from source length bin $`l`$ to destination bin $`j`$. Survival and growth for ordinary age classes follow:

```math
N_{j,i+1,t+1}=\sum_l G_{j,l}N_{l,i,t}\exp[-(M+F_{l,t})].
```

加组累加前一年龄组和原最大年龄组的存活及增长；补充量按最小年龄的长度分布进入第一年龄组。G 的各列和为 1，不允许缩短，最大体长组吸收右尾概率。

The plus group combines survivors and growth from the preceding and oldest age classes. Recruitment enters the youngest class with its length distribution. Columns of G sum to one, shrinkage is excluded, and the largest bin absorbs the right-tail probability.

增长增量使用下面的平滑下降函数，标准差为 $`CV_G\mu_{\Delta L}`$：

Growth increments use the following smooth decreasing mean, with SD $`CV_G\mu_{\Delta L}`$:

```math
\mu_{\Delta L}(L)=\frac{\Delta t(1-e^{-k})L_\infty}
{1+\exp\!\left(-\log(19)\frac{L-0.5L_\infty}{0.05L_\infty-0.5L_\infty}\right)}.
```

此函数与精确的任意时间步 VB 增量 $`(L_\infty-L)(1-e^{-k\Delta t})`$ 不同。`pla` 是给定年龄的长度分布，G 是给定源长度的一步转移概率，各模型使用各自的矩阵。`FL` 是长度别 F，`FA` 则由原队列的存活率推导。

This curve differs from the exact von Bertalanffy increment $`(L_\infty-L)(1-e^{-k\Delta t})`$. `pla` describes length given age, while G describes a one-step transition given source length; each model uses its own. `FL` is length-specific F; `FA` is derived from original-cohort survival.

<a id="model-theory-derived"></a>

#### 派生量 / Derived quantities

输入的平均个体重量 $`w_{l,t}`$ 和成熟比例 $`m_{l,t}`$ 用于计算体长别生物量、成熟生物量及总量：

Mean individual weight $`w_{l,t}`$ and maturity proportion $`m_{l,t}`$ convert abundance into length-specific biomass, spawning biomass and totals:

```math
b_{l,t}=N_{l,t}w_{l,t},\qquad sb_{l,t}=b_{l,t}m_{l,t},\qquad
B_t=\sum_l b_{l,t},\qquad SSB_t=\sum_l sb_{l,t}.
```

`CN`、`CB` 是模型推算的渔业捕获尾数与重量，区别于输入的调查数量指数。生物量单位由个体重量单位和丰度尺度共同决定。

`CN` and `CB` are derived fishery catch numbers and biomass, distinct from the input survey number index. Biomass units depend on the weight units and the abundance scale.

<a id="model-theory-survey"></a>

#### 调查观测 / Survey observations

令 $`I_{l,t}`$ 为调查数量指数，$`N_{l,t}`$ 为种群尾数。调查观测使用对数正态模型：

Let $`I_{l,t}`$ denote the survey number index and $`N_{l,t}`$ population abundance. Survey observations follow a lognormal model:

```math
\log I_{l,t}=\log q_l+\log N_{l,t}+\epsilon_{l,t},\qquad
\epsilon_{l,t}\sim N(0,\sigma_I^2),
```

```math
q_l=\left[1+\exp\!\left(-\log(19)\frac{L_l-L_{50}}{L_{95}-L_{50}}\right)\right]^{-1}.
```

`sel_L50`、`sel_L95` 固定调查可捕性 q，在两个指定体长处分别取 0.5 和 0.95；它们描述的是调查，渔业选择性是另一个量。`exp(report$Elog_index)` 给出原尺度的中位数，算术均值还需乘以 $`\exp(\sigma_I^2/2)`$。

`sel_L50` and `sel_L95` fix survey catchability at 0.5 and 0.95 at the specified lengths; they describe the survey, and fishery selectivity is a separate quantity. `exp(report$Elog_index)` is the original-scale median; the arithmetic mean also includes $`\exp(\sigma_I^2/2)`$.

<a id="model-theory-estimation"></a>

#### 估计与区间 / Estimation and uncertainty

TMB 用自动微分计算目标函数及导数，对随机效应采用 Laplace 近似；R 的 `nlminb()` 优化固定效应。`sdreport()` 使用局部曲率及 delta 方法给出近似标准误。绘图中的 95% 区间是逐点区间，只有被估计的参数对它有贡献：`YTF_example` 固定了生长和部分过程参数，因此生长区间退化为一条线，其余区间以这些固定值为条件。生长区间描述平均曲线的不确定性，单尾鱼按 $`CV_L`$ 散布在曲线周围。解读任何区间之前，先读 Hessian、边界和梯度检查。

TMB uses automatic differentiation and a Laplace approximation for the random effects; R's `nlminb()` optimizes the fixed effects. `sdreport()` obtains approximate standard errors from local curvature and the delta method. Plotted 95% intervals are pointwise, and only the estimated parameters contribute to them: `YTF_example` fixes growth and some process parameters, so its growth interval collapses to a line and the other intervals are conditional on the fixed values. Growth intervals describe the uncertainty of the mean curve; individual fish scatter around it with $`CV_L`$. Read the Hessian, bound and gradient checks before interpreting any interval.

<a id="model-theory-matrices"></a>

### 2. 检查两种概率矩阵 / Check the two probability matrices

```r
# b 为 ALSCL 拟合对象 / b is an ALSCL fit
G <- b$report$G
range(colSums(G))
stopifnot(all(G >= 0), max(abs(colSums(G) - 1)) < 1e-8)
```

| 矩阵 / Matrix | 含义 / Meaning | 检查 / Check |
|---|---|---|
| `pla` | 给定年龄的长度分布；模拟器中的方向随模型而异 / Length given age; simulator orientation varies | 先检查方向 / Check orientation |
| `G` | 给定源长度列的目的长度行 / Destination row conditional on source column | 非负、列和为 1、不缩短 / Nonnegative, normalized, no shrinkage |

`range(colSums(G))` 应打印两个在舍入误差内等于 1 的值，`stopifnot()` 静默返回。若它停止，说明保存的矩阵不满足这些性质；使用 `b` 之前先读它的数值检查。`plot_pla()` 画的是年龄-体长概率。下面是 tuna 条件 ALSCL 拟合的生长转移矩阵，显示留在原组和进入较大组的概率：

`range(colSums(G))` should print two values equal to 1 within rounding, and `stopifnot()` returns silently. A stop means the stored matrix fails these properties; read the numerical checks of `b` before using it. `plot_pla()` shows the age-length probabilities. The tuna ALSCL growth matrix below shows the probabilities of staying in a bin or advancing to larger bins:

![tuna 生长转移矩阵 / Growth transition](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/cases/tuna_growth_transition.png?raw=true&v=339fc98c53c1)

生长可以留在同一组内：鱼长大了，而分组是离散的。最后一组承接右尾概率。改变体长组边界会改变两个矩阵和状态的含义。

Growth can remain within the same bin: the fish grew, and the bins are discrete. The largest bin absorbs the right tail. Changing the bin boundaries changes both matrices and the meaning of the states.

<a id="model-theory-units"></a>

### 2. 把年率换算到模型时间步 / Convert annual rates to the model time step

```r
rec.age <- .25; nage <- 20; growth_step <- .25
ages <- rec.age + (seq_len(nage) - 1) * growth_step
range(ages) # 年 / years
M_quarter <- .8 * growth_step
# 四个季度的累计瞬时率 / Sum four quarterly instantaneous rates
F_quarter <- c(.1, .15, .2, .15)
F_annual <- sum(F_quarter)
```

年龄按设定的步长排列。生长参数 k 按年；M 和 F 是每个时间步的瞬时率，所以年 M = 0.8 对应季度 M = 0.2，一个时间步内的存活概率是 $`\exp[-(M+F)]`$。`range(ages)` 打印 0.25 和 5。`plot_compare_F_ts()` 不会把季度值年化；`method = "apical"` 是每个时间步的组间最大值，`"mean"` 是非加权平均，两个模型的原生 F 维度不同。

Ages use the stated step. Growth k is annual; M and F are instantaneous rates per time step, so an annual M of 0.8 becomes a quarterly M of 0.2, and survival over a step is $`\exp[-(M+F)]`$. `range(ages)` prints 0.25 and 5. `plot_compare_F_ts()` does not annualize quarterly values; `method = "apical"` is the within-step group maximum and `"mean"` the unweighted mean, and the native F dimensions differ between the models.

<a id="model-theory-next"></a>

### 下一步 / What next

| 想做什么 / What you want to do | 阅读 / Read |
|---|---|
| 查看各模型估计哪些参数及其变换 / See which parameters each model estimates and their transformations | [估计参数清单](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) / [Estimation parameter lists](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) |
| 固定或释放参数，选择 F 结构 / Fix or release parameters, choose the F structure | [选择拟合设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) / [Choose the fitting settings](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) |
| 拟合季度调查 / Fit a quarterly survey | [年度与季度时间步](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASE_STUDIES.md) / [Annual and quarterly time steps](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASE_STUDIES.md) |

<a id="chapter-03"></a>
## 03 准备调查数据 · Prepare your survey data

本页把你的调查观测整理成 `run_acl(x)` 和 `run_alscl(x)` 可以接受的输入列表 `x`，并在第一次拟合前检查它。你需要已安装的软件包（[安装 ALSCL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#start)）、按年或按季度的体长别调查尾数、体长别平均体重和成熟比例，以及第 4 步列出的本种群生物学数值。

On this page you turn your survey observations into an input bundle `x` that `run_acl(x)` and `run_alscl(x)` accept, and you check it before the first fit. You need the package installed ([Install ALSCL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#start)), your survey numbers at length by year or quarter, mean weight and maturity at length, and the biological values of your stock listed in step 4.

| 步骤 / Step | 完成后得到什么 / What you will have afterwards |
|---|---|
| 1. 排好三张表 / 1. Lay out three tables | 行列完全一致的工作簿或三个 CSV 文件 / A workbook or three CSV files with identical rows and columns |
| 2. 确定时间步 / 2. Choose the time step | 没有隐藏缺口的时间网格，以及零值的处理决定 / A time grid without hidden gaps and a decision about zeros |
| 3. 读入文件 / 3. Read the files | R 中已检查对齐的三张表列表 / The three tables as a list in R, already checked for alignment |
| 4. 加入生物学设置 / 4. Add the biology | 带有本种群设置的输入列表 `x` / The input bundle `x` with your stock's settings |
| 5. 检查输入列表 / 5. Check the bundle | 确认 `x` 可以拟合，并得到将被估计的参数清单 / A confirmation that `x` can be fitted, and the list of parameters that will be estimated |

<a id="data-preparation-table-layout"></a>

### 1. 排好三张匹配的表 / Lay out three matching tables

两个模型读取布局相同的三张表：调查指数表 `data.CatL`（每个体长组、每个时间步调查捕到的尾数）、体重表 `data.wgt`（每个体长组、每个时间步一尾鱼的平均体重）和成熟比例表 `data.mat`（成熟个体比例）。行是体长组，列是时间步，三张表顺序相同。下载[示例工作簿](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/data/ALSCL_Data_Entry_Example.xlsx)，留一份副本，再把其中的数值换成你的数据。

Both models read three tables with the same layout: the survey index table `data.CatL` (numbers of fish caught by the survey in each length bin and time step), the weight table `data.wgt` (mean weight of one fish in each bin and time step) and the maturity table `data.mat` (proportion mature). The rows are the length bins and the columns are the time steps, in the same order in all three tables. Download the [example workbook](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/data/ALSCL_Data_Entry_Example.xlsx), keep a copy, and replace its values with yours.

| 位置 / Location | 规则 / Rule |
|---|---|
| 工作表名 / Sheet names | 必须是 `data.CatL`、`data.wgt` 和 `data.mat`（或三个同名的 CSV 文件） / Exactly `data.CatL`, `data.wgt` and `data.mat` (or three CSV files with these names) |
| A1 单元格 / Cell A1 | `LengthBin`；表头上方不要有标题行 / `LengthBin`; no title rows above the header |
| A 列 / Column A | 每行一个体长组；示例用中点 6、8、...、50 cm / One length bin per row; the example uses the midpoints 6, 8, ..., 50 cm |
| 第 1 行 / Row 1 | 递增的数值时间标签：年度为 2000、2001、...；季度为 2000、2000.25、2000.5、... / Increasing numeric time labels: 2000, 2001, ... for years; 2000, 2000.25, 2000.5, ... for quarters |
| 其他单元格 / Other cells | 每个体长组和时间步一个数字；表格内不放其他内容 / One number per bin and time step; nothing else inside the grid |
| 三张表 / All three tables | 体长组、时间标签和顺序完全相同 / Identical bins, time labels and order |

<a id="data-preparation-survey-table"></a>

#### 调查指数表 data.CatL / Survey index table data.CatL

填入体长别调查尾数，或经一致标准化的指数（例如每网次尾数），可以有小数。某个体长组在某个时间步没有观测时，单元格留空或写 `NA`；不要用 0、短横线或 `<1` 表示未知。0 表示调查在该体长组确实没有捕到。

Enter the survey numbers at length, or a consistently standardized index of them (for example numbers per tow). Decimals are fine. Leave a cell blank, or write `NA`, when that bin was not observed in that time step; do not write 0, a dash or `<1` for an unknown value. A 0 means the survey observed nothing in that bin.

![调查指数工作表 / Survey index worksheet](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/excel_CatL.png?raw=true&v=86653ca443d4)

<a id="data-preparation-weight-table"></a>

#### 体重表 data.wgt / Weight table data.wgt

填入每个体长组、每个时间步一尾鱼的平均体重，全表使用同一单位（示例为 kg）。每个单元格都要有值，因为模型用尾数乘体重得到生物量。如果只有体长-体重关系而没有逐年测量值，就用关系式的结果填满所有时间步，并在报告评估时说明。

Enter the mean weight of one fish in each bin and time step, in one unit throughout (the example uses kg). Every cell needs a value, because the model multiplies numbers by weight to obtain biomass. If you have a length-weight relationship instead of yearly measurements, fill all time steps with its values and say so when you report the assessment.

![体重工作表 / Weight worksheet](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/excel_wgt.png?raw=true&v=d9137372f011)

<a id="data-preparation-maturity-table"></a>

#### 成熟比例表 data.mat / Maturity table data.mat

填入 0 到 1 之间的成熟比例（60% 写 0.6）。每个单元格都要有值，0 和 1 都可以。产卵生物量等于尾数乘体重乘成熟比例，这张表决定哪些体长组算作亲体。

Enter the proportion mature as a number between 0 and 1 (0.6 for 60%). Every cell needs a value; 0 and 1 are valid. Spawning biomass is numbers times weight times maturity, so this table decides which bins count as spawners.

![成熟比例工作表 / Maturity worksheet](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/excel_mat.png?raw=true&v=8d3c34642af1)

<a id="data-preparation-time-and-bins"></a>

### 2. 确定时间步并处理缺口 / Choose the time step and handle gaps

模型逐个时间步推进种群，`growth_step` 是一个时间步的长度（年）：年度调查为 1，季度调查为 0.25。相邻列标签之差必须恰好等于 `growth_step`，模型才知道两列之间过了多长时间。没有调查的时间步仍要保留为一列，调查单元格留空，体重和成熟比例照常填写；模型会把这一步当作未观测。

The models advance the population one time step at a time, and `growth_step` is the length of that step in years: 1 for annual surveys, 0.25 for quarterly surveys. Consecutive column labels must differ by exactly `growth_step`, so the models know how much time passed between two columns. A time step without a survey stays in the table as a column of blank survey cells with its weight and maturity filled in; the models then treat that step as unobserved.

| 情况 / Situation | 如何填写 / What to enter |
|---|---|
| 年度调查，2002 年没有调查 / Annual survey, no survey in 2002 | 保留 2002 列；调查单元格留空；填写体重和成熟比例 / Keep a 2002 column; leave its survey cells blank; fill weight and maturity |
| 季度调查 / Quarterly survey | 标签 2000、2000.25、2000.5、2000.75、...；第 4 步设 `growth_step = 0.25` / Labels 2000, 2000.25, 2000.5, 2000.75, ...; `growth_step = 0.25` in step 4 |
| 某个体长组在某个时间步没有观测 / One bin not observed in one time step | 该调查单元格留空 / Leave that survey cell blank |
| 记录到的零值 / A recorded zero | 保留 0；在第 4 步决定零值按缺失处理（默认 `zero_action = "missing"`）还是终止拟合（`"error"`） / Keep the 0; decide in step 4 whether zeros are treated as missing (`zero_action = "missing"`, the default) or stop the fit (`"error"`) |

体长组需要中点（`len_mid`，每行一个）和相邻体长组之间的内部边界（`len_border`，比行数少一个）。第一组和最后一组分别延伸到 0 和无穷大，比你的范围更小或更大的鱼都计入两端的组。等宽体长组的中点就是行标签，边界在相邻中点的中间；不等宽时填写调查设计中的实际边界。

The length bins need their midpoints (`len_mid`, one per row) and the internal boundaries between bins (`len_border`, one fewer than the rows). The first and last bins extend to zero and infinity, so fish smaller or larger than your range are counted in the end bins. If your bins have equal width, the midpoints are the row labels and the boundaries lie halfway between them; if not, enter the actual boundaries from your survey design.

<a id="data-preparation-import"></a>

### 3. 把文件读入 R / Read the files into R

两个读取函数任选其一。两者都返回包含三张表的列表，把数字文本转换为数值，并在表格不一致时停止并给出提示。

Use one of the two readers. Both return a list with the three tables, convert numeric text to numbers, and stop with a message when the tables differ.

```r
library(ALSCL)
install.packages("readxl") # 只需一次；仅读取 Excel 文件时需要 / once; only needed for Excel files
tables <- read_survey_excel("my_survey.xlsx")
str(tables)
```

```r
# 同一文件夹中的三个文件 data.CatL.csv、data.wgt.csv 和 data.mat.csv / Three files data.CatL.csv, data.wgt.csv and data.mat.csv in one folder
tables <- read_survey_csv("my_data")
str(tables)
```

`str(tables)` 应显示三张行列数相同的数据框，每张表第一列是体长标签。提示“nonnumeric cell in time column 2003”说明表格里有文本；“must match data.CatL length labels and time columns”说明某张表的行或列与其他表不同。修改文件后重新读取。

`str(tables)` should show three data frames with the same number of rows and columns, the first column of each being the length labels. A message such as "nonnumeric cell in time column 2003" points to a text entry in the grid; "must match data.CatL length labels and time columns" means the rows or columns of one table differ from the others. Fix the file and read it again.

<a id="data-preparation-bundle"></a>

### 4. 加入生物学设置，组成输入列表 / Add the biology and build the input bundle

`prepare_alscl_data()` 把三张表和两个模型共用的设置 `fit_args` 组合成输入列表 `x`。这些设置描述你的种群和调查，模型把它们当作已知值。

`prepare_alscl_data()` combines the three tables with the settings both models share, `fit_args`, into the input bundle `x`. The settings describe your stock and your survey; the models take them as given.

| 设置 / Setting | 含义 / Meaning | 数值来源 / Where the value comes from |
|---|---|---|
| `rec.age` | 模型中最小年龄组的年龄（年） / Age of the youngest age class in the model, in years | 鱼首次出现在调查中的年龄 / Age at which fish first appear in the survey |
| `nage` | 年龄组数；最后一组是加组 / Number of age classes; the last one is a plus group | 值得追踪的最大年龄除以 `growth_step` / Oldest age worth tracking, divided by `growth_step` |
| `M` | 每个时间步的自然死亡率 / Natural mortality per time step | 文献或生活史方法；季度时间步时把年值除以 4 / Literature or life-history methods; divide an annual value by 4 for quarterly steps |
| `sel_L50`、`sel_L95` / `sel_L50`, `sel_L95` | 调查可捕性达到 50% 和 95% 的体长 / Lengths at which survey catchability reaches 50% and 95% | 渔具选择性研究或渔获体长分布 / Gear selectivity studies or the length distribution of the catch |
| `growth_step` | 每个时间步的年数 / Years per time step | 第 2 步 / Step 2 |
| `len_mid`、`len_border` / `len_mid`, `len_border` | 体长组中点和内部边界 / Bin midpoints and internal boundaries | 第 2 步 / Step 2 |
| `zero_action` | 调查表中 0 的处理方式 / How a 0 in the survey table is treated | `"missing"`（默认）或 `"error"` / `"missing"` (default) or `"error"` |

```r
x <- prepare_alscl_data(tables, fit_args = list(
  rec.age = 1, nage = 15, M = 0.2, sel_L50 = 15, sel_L95 = 20,
  growth_step = 1, len_mid = seq(6, 50, 2), len_border = seq(7, 49, 2)))
saveRDS(x, "my_bundle.rds")
```

上面的数值是模拟示例的设置，请换成你的种群的值。`x` 是普通列表，用 `saveRDS()` 保存后可在以后的会话中用 `readRDS()` 读回。各模型的初值和 `map` 可以之后以 `fit_config` 的形式加入；没有时模型使用默认初值，并固定[拟合设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting)中列出的参数。

The numbers above are the settings of the synthetic example; replace them with the values for your stock. `x` is a plain list, so `saveRDS()` keeps it for later sessions and `readRDS()` brings it back. Starting values and a `map` for each model can be added later as `fit_config`; without them the models use their default starting values and fix the parameters listed in [Fitting controls](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting).

<a id="data-preparation-check"></a>

### 5. 拟合前检查输入列表 / Check the bundle before fitting

```r
check <- check_alscl_data(x, "acl")
check$valid
check$errors
check$warnings
check$summary
plan <- inspect_parameters(x, "acl")
plan[, c("parameter", "status", "natural_start", "n_free")]
```

`check_alscl_data()` 按拟合时的方式准备数据，但不编译任何东西，然后报告输入列表能否拟合。`check$summary` 统计体长组数、时间步数、正观测数、零值数、空白数、没有任何观测的时间步和体长组，以及将被估计的标量参数（`free_fixed`）和随机效应（`free_random`）数量。`inspect_parameters()` 列出每个参数在自然尺度上的初值及其状态：`free`（估计）、`fixed`（固定）或 `tied`（共享）。打算拟合 ALSCL 时，用 `"alscl"` 再运行一遍这两个函数。

`check_alscl_data()` prepares the data exactly as a fit would, without compiling anything, and reports whether the bundle can be fitted. `check$summary` counts the bins, time steps, positive observations, zeros, blanks, time steps and bins without any observation, and the numbers of scalar (`free_fixed`) and random-effect (`free_random`) parameters that will be estimated. `inspect_parameters()` lists every parameter with its starting value on the natural scale and its status: `free` (estimated), `fixed` or `tied`. Run both again with `"alscl"` when you intend to fit that model.

若 `check$valid` 为 `FALSE`，`check$errors` 中的信息会指出要修改的表、列或设置；警告提示值得查看的情况，例如零值很多或某个时间步没有观测。检查通过后，用 `run_acl(x)` 或 `run_alscl(x)` 拟合，并按[理解第一次拟合](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin)继续。

If `check$valid` is `FALSE`, the messages in `check$errors` name the table, column or setting to correct; warnings point to things worth a look, such as many zeros or an unobserved time step. When the check passes, fit with `run_acl(x)` or `run_alscl(x)` and continue as in [Understand your first fit](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin).

<a id="data-preparation-legacy"></a>

### 仓库脚本和兼容数据 / Repository script and compatibility data

调用仓库中 `scripts/real_data_workflow.R` 的 `validate_survey_tables()` 或 `fit_survey_tables()` 的脚本仍可使用，该脚本的读取函数直接调用上面的包函数。软件包还附带 `example_data`，是三张 ALSCL 数据表（9 个体长组，2001-2021），物种、单位和体长组边界都没有记录；只用它试运行函数。

Scripts that call `validate_survey_tables()` or `fit_survey_tables()` from `scripts/real_data_workflow.R` in the repository still work; the script's readers call the package functions above. The package also ships `example_data`, three ALSCL tables with 9 bins and the years 2001-2021 whose species, units and bin boundaries are undocumented; use it only to try the functions.

<a id="data-preparation-next"></a>

### 下一步 / What next

| 想做什么 / What you want to do | 阅读 / Read |
|---|---|
| 拟合输入列表并判断结果 / Fit the bundle and judge the result | [理解第一次拟合](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin) / [Understand your first fit](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin) |
| 决定哪些参数固定、哪些估计，选择 F 结构 / Decide which parameters to fix or estimate, choose the F structure | [拟合设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) / [Fitting controls](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) |
| 跟着完整的实测数据示例从 CSV 做到保存结果 / Follow a complete own-data example from CSV to saved results | [如何拟合自己的调查数据？](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md) / [How do I fit my own survey data?](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md) |
| 检查季度调查的时间网格 / Check the time grid of a quarterly survey | [年度与季度时间步](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASE_STUDIES.md) / [Annual and quarterly time steps](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASE_STUDIES.md) |

<a id="chapter-04"></a>
## 04 理解第一次拟合 · Understand your first fit

[安装软件包](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#start)之后，你已经有了输入列表 `x` 和拟合好的 ACL 模型 `a`。本页说明拟合结果包含什么、怎样判断它可用、怎样读估计值，以及第二个模型 ALSCL 与它有何不同。请在同一个 R 会话中按步骤运行；后面的页面会继续使用 `x`、`a` 和 `b`。

After [installing the package](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#start) you have the input bundle `x` and a fitted ACL model `a`. On this page you learn what a fitted object contains, how to judge whether a fit can be used, how to read its estimates, and how the second model, ALSCL, compares with it. Run the steps in one R session; later pages reuse `x`, `a` and `b`.

`YTF_example` 是模拟数据：23 个体长组、20 个年份，由一个已知的种群生成。它保存的设置固定了生长参数和部分过程参数，因此你看到的不确定性区间是在这些固定值之下得到的。先用它熟悉流程，再为自己的种群选择假设。

`YTF_example` is synthetic: 23 length bins and 20 years generated from a known population. Its stored settings fix growth and some process parameters, so the uncertainty intervals you will see are conditional on those fixed values. Learn the workflow on it before choosing assumptions for your own stock.

<a id="first-model-fit"></a>

### 1. 拟合两个模型 / Fit the two models

```r
library(ALSCL)
data("YTF_example")
x <- YTF_example
a <- run_acl(x, silent = TRUE)
b <- run_alscl(x, silent = TRUE)
```

ALSCL 为同一套调查数据提供两个模型。ACL（`run_acl()`）追踪每个年龄的尾数，用年龄-体长概率矩阵把年龄换算成体长。ALSCL（`run_alscl()`）追踪每个体长和年龄的尾数，用生长转移矩阵把存活个体在体长组之间推进，适合难以鉴定年龄的种群。本例 ACL 拟合约二十秒，ALSCL 约两分钟，不含每个模型只做一次的编译。

ALSCL offers two models of the same data. ACL (`run_acl()`) follows the number of fish at each age and converts ages to lengths with an age-length probability matrix. ALSCL (`run_alscl()`) follows the number of fish at each length and age and moves survivors between length bins with a growth transition matrix, which suits stocks that are hard to age. The ACL fit takes about twenty seconds for this example and the ALSCL fit about two minutes, after the one-time compilation of each model.

两次调用读取同一个 `x`：三张表、`x$fit_args` 中两个模型共用的生物学设置（补充年龄、年龄组数、自然死亡率 `M`、调查可捕性 `sel_L50` 和 `sel_L95`、体长组和时间步），以及 `x$fit_config$acl` 或 `x$fit_config$alscl` 中各模型自己的初值和 `map`。[输入列表一节](#first-model-bundle)详细说明 `x`。

Both calls read the same `x`: the three tables, the shared biology in `x$fit_args` (recruitment age, number of ages, natural mortality `M`, survey catchability `sel_L50` and `sel_L95`, length bins and time step) and the model's own starting values and `map` in `x$fit_config$acl` or `x$fit_config$alscl`. The [bundle section](#first-model-bundle) explains `x` in detail.

<a id="first-model-checks"></a>

### 2. 读数值检查 / Read the numerical checks

```r
diagnose_model(x$data.CatL, a)
a$diagnostics$numerical_ok
a$diagnostics$issues
```

看任何估计值之前先读数值检查。`diagnose_model()` 打印优化器收敛码（0 表示正常结束）、解处的最大绝对梯度（优化器到达极小值时小于 0.001）、Hessian 是否正定（计算标准误的前提）、是否有参数落在边界上，以及是否有方差或相关系数估计到了自然尺度的极限。打印的 `Numerical checks` 一行汇总以上各项，与 `a$diagnostics$numerical_ok` 相同；`a$diagnostics$issues` 给出未通过的项目。

Read the numerical checks before any estimate. `diagnose_model()` prints the optimizer convergence code (0 means it finished normally), the maximum absolute gradient at the solution (below 0.001 at a minimum), whether the Hessian is positive definite (needed for standard errors), whether a parameter sits on a bound, and whether a variance or correlation was estimated at its natural limit. The printed line `Numerical checks` summarizes them, the same value as `a$diagnostics$numerical_ok`; `a$diagnostics$issues` names any failed check.

| 未通过的检查 / Failed check | 常见原因 / Usual cause | 可以尝试 / What to try |
|---|---|---|
| 收敛码不是 0，或梯度很大 / Convergence code is not 0, or the gradient is large | 优化器提前停止，或目标函数面很平 / The optimizer stopped early or the surface is flat | 多用几个初值，`run_acl(x, nstarts = 4, ncores = 2)`，在 `a$start_diagnostics` 中比较各初值的目标函数值 / Run more starts, `run_acl(x, nstarts = 4, ncores = 2)`, and compare their objectives in `a$start_diagnostics` |
| Hessian 不正定 / Hessian not positive definite | 某个参数得不到数据的信息 / A parameter is not informed by the data | 用 `map` 固定该参数，或用 `F_structure = "year"` 让各组共用 F（[拟合设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting)） / Fix that parameter with `map` or share F across groups with `F_structure = "year"` ([Fitting controls](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting)) |
| 参数落在边界上 / Parameter on a bound | 边界或初值不适合这个种群 / A bound or starting value is wrong for this stock | 用 `inspect_parameters(x, "acl")` 查看初值和边界并调整 / Inspect starts and bounds with `inspect_parameters(x, "acl")` and adjust them |
| 自然尺度边界 / Natural-scale boundary | 标准差接近 0 或相关系数接近 1 / A standard deviation near 0 or a correlation near 1 | 把该参数固定在有依据的值，或简化 F 结构 / Fix the parameter at a supported value, or simplify the F structure |
| 检查通过但残差有规律 / Checks pass but residuals show patterns | 模型漏掉了数据中的某种特征 / The model misses a feature of the data | 继续阅读[诊断](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) / Continue with [Diagnostics](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) |

<a id="first-model-estimates"></a>

### 3. 读估计值 / Read the estimates

```r
estimates <- extract_estimates(a)
head(estimates)
subset(estimates, quantity == "SSB")
extract_parameters(a)
plot_SSB(a, se = TRUE)
```

`extract_estimates()` 把种群量整理成一张表：产卵生物量 `SSB`、补充量 `Rec`、总生物量 `B`、丰度 `N`、捕获尾数 `CN` 和捕捞死亡率 `F`，每行有年份、该量所在的年龄或体长（如有）、估计值、标准误和 95% 区间。`extract_parameters()` 列出标量参数的状态（`estimated`、`fixed` 或 `inactive`）和自然尺度上的估计值。`plot_SSB()` 画出产卵生物量及其区间，其他绘图函数用法相同。

`extract_estimates()` returns one table for the population quantities: spawning biomass `SSB`, recruitment `Rec`, total biomass `B`, abundance `N`, catch numbers `CN` and fishing mortality `F`, with the year, the age or length where the quantity has one, the estimate, its standard error and a 95% interval. `extract_parameters()` lists the scalar parameters with their status (`estimated`, `fixed` or `inactive`) and estimates on the natural scale. `plot_SSB()` draws spawning biomass with its interval; the other plot functions follow the same pattern.

区间只来自被估计参数的标准误；`x$fit_config` 中固定的值不贡献不确定性。表格背后的原始数组在 `a$report` 中（例如 `a$report$SSB`），`a$sd_info` 记录标准误的计算方式。

The intervals come from the standard errors of the estimated parameters only; the fixed values in `x$fit_config` contribute no uncertainty. The raw arrays behind the table are in `a$report` (for example `a$report$SSB`), and `a$sd_info` records how the standard errors were computed.

<a id="first-model-fit-to-data"></a>

### 4. 检查对观测的拟合 / Check the fit to the observations

```r
plot_CatL(a, facet_by = "year", facet_ncol = 5)
plot_residuals(a, facet_by = "year", facet_ncol = 5)
```

`plot_CatL()` 按年份分面，画出各体长组的观测调查指数（点）和拟合指数（线）。`plot_residuals()` 画同样分面的对数残差，即对数尺度上观测减拟合。可用的拟合在每个面板中残差都围绕 0 散布。若同一年相邻体长组的残差同号成串，或同一体长组多年同号成串，说明模型漏掉了数据中的某种特征，例如一个队列穿过调查范围，或实际选择性与假设不同；[诊断](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics)说明如何检查这类规律。

`plot_CatL()` shows the observed survey index (points) and the fitted index (line) across length bins, one panel per year. `plot_residuals()` shows the log residuals, observed minus fitted on the log scale, for the same panels. A usable fit has residuals scattered around zero in every panel. A run of residuals with the same sign across neighbouring lengths in one year, or across years in one length bin, means the model misses a feature of the data, such as a cohort passing through the survey or a selectivity that differs from the assumed one; [Diagnostics](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) shows how to examine such patterns.

<a id="first-model-compare"></a>

### 5. 比较 ACL 与 ALSCL / Compare ACL and ALSCL

```r
plot_compare_ts(a, b, quantities = c("B", "SSB", "Rec"), se = TRUE)
comparison <- compare_models(a, b, x$data.CatL)
comparison$comparison
comparison$fit_diagnostics
```

![ACL 与 ALSCL 的生物量、产卵生物量和补充量估计 / ACL and ALSCL biomass, spawning biomass and recruitment estimates](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_ts.png?raw=true&v=6e0c7883ce7f)

图中是两个模型的总生物量、产卵生物量和补充量及其区间。轨迹相似说明两种种群结构对趋势的判断一致；尺度上持续的差异通常来自两个模型在年龄与体长之间换算方式的不同。

The figure shows both models' total biomass, spawning biomass and recruitment with intervals. Similar trajectories mean the two population structures agree on the trend; a persistent scale difference usually comes from how each model converts between age and length.

`compare_models()` 先核对两次拟合使用的观测相同，再打印 AIC、BIC 和拟合统计量。`comparison$comparison` 记录 `data_verified`、`eligible`（两次拟合都通过数值检查）、`preferred`（AIC 较低的模型，仅在两者都合格时给出）和 `issues`。AIC 较低只说明该模型在统计上更贴合这些数据；它的假设是否适合这个种群，是另一个需要用生物学知识回答的问题。

`compare_models()` first verifies that both fits used the same observations, then prints AIC, BIC and fit statistics. `comparison$comparison` records `data_verified`, `eligible` (both fits passed the numerical checks), `preferred` (the model with the lower AIC, given only when both are eligible) and any `issues`. A lower AIC supports a model statistically on these data; whether its assumptions suit the stock is a separate, biological decision.

<a id="first-model-save"></a>

### 6. 保存拟合结果 / Save the fit

```r
save_assessment(a, "ytf_acl.rds")
saved <- read_assessment("ytf_acl.rds")
plot_SSB(saved, se = TRUE)
```

`save_assessment()` 保存拟合结果中除 `a$obj` 以外的全部内容（`a$obj` 是只在当前会话有效的 TMB 对象指针），并记录配方（数据表、设置和软件包版本），以后可用 `refit_model(saved)` 重建可执行对象。绘图和提取函数都能直接使用保存的拟合结果。文件已存在时调用会停止；传入 `overwrite = TRUE` 即可覆盖。

`save_assessment()` writes everything in the fit except the live TMB object `a$obj`, a pointer valid only in the current session, and stores the recipe (the tables, settings and package version) so that `refit_model(saved)` can rebuild the live object later. Plots and extraction functions work directly on the saved fit. The call stops when the file exists; pass `overwrite = TRUE` to replace it.

<a id="first-model-bundle"></a>

### run_acl(x) 如何读取输入列表 / How run_acl(x) reads the input bundle

输入列表 `x` 是一个命名列表。三张表 `data.CatL`、`data.wgt` 和 `data.mat` 存放观测。`x$fit_args` 存放两个模型共用的设置：`rec.age`、`nage`、`M`、`sel_L50`、`sel_L95`、`len_mid`、`len_border` 和 `growth_step`。`x$fit_config$acl` 和 `x$fit_config$alscl` 存放各模型的初值（`parameters`）和 `map`。其他元素，例如 `YTF_example` 中的模拟真值 `truth` 和来源 `provenance`，拟合函数不会读取。

The input bundle `x` is a named list. Its three tables `data.CatL`, `data.wgt` and `data.mat` hold the observations. `x$fit_args` holds the settings both models share: `rec.age`, `nage`, `M`, `sel_L50`, `sel_L95`, `len_mid`, `len_border` and `growth_step`. `x$fit_config$acl` and `x$fit_config$alscl` hold the starting values (`parameters`) and the `map` of each model. The fitting functions ignore other elements, such as the simulation `truth` and `provenance` of `YTF_example`.

设置按这个顺序读取：数据表，然后 `fit_args`，然后所选模型的 `fit_config`，最后是调用时给出的参数。因此调用中的参数会覆盖保存的值，而 `map` 这类列表参数会整体替换保存的列表。

Settings are read in this order: the tables, then `fit_args`, then the `fit_config` entry of the chosen model, then the arguments of the call. An argument in the call therefore overrides the stored value, and a list argument such as `map` replaces the stored list completely.

```r
# 两个工作进程运行四个初值；保存的 M 仅在本次调用中换成 0.25 / Four starts on two workers; the stored M is replaced by 0.25 for this call only
a4 <- run_acl(x, nstarts = 4, ncores = 2, M = 0.25)
```

也可以把每张表和每项设置作为单独参数传入，如 `do.call(run_acl, args)`；两种写法使用同一套拟合代码。只包含三张表和 `rec.age`、`nage`、`M`、`sel_L50`、`sel_L95` 的扁平命名列表同样可以作为输入列表。

Every table and setting can also be passed as a separate argument, as in `do.call(run_acl, args)`; both forms use the same fitting code. A flat named list with the three tables, `rec.age`, `nage`, `M`, `sel_L50` and `sel_L95` is accepted as a bundle too.

<a id="first-model-data-provenance"></a>

### 内置数据说明 / About the bundled data

| 对象 / Object | 内容 / Contents |
|---|---|
| `YTF_example` | 三张表（23 个体长组、20 个年份）、`fit_args`、`fit_config`、生成真值 `truth` 和来源 `provenance` / The three tables (23 bins by 20 years), `fit_args`, `fit_config`, the generating `truth` and `provenance` |
| `YTF` | 原有的 26 项生物参数列表，不含调查表 / The original list of 26 biological parameters, without survey tables |
| `example_data` | 三张 ALSCL 数据表（9 个体长组，2001-2021），来源未核实，只用于试运行函数 / Three ALSCL tables (9 bins, 2001-2021) of unverified origin, for trying the functions only |

`YTF_example` 由包内模拟器生成（种子 4，预热 80 年，保留 20 年，调查对数 SD 0.1），不是论文的实测数据。[生成脚本](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/data-raw/YTF_example.R)可以重建它。

`YTF_example` was generated with the package simulator (seed 4, 80 burn-in years, 20 retained years, survey log SD 0.1) and is not the empirical dataset of the paper. The [generation script](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/data-raw/YTF_example.R) rebuilds it.

<a id="first-model-next"></a>

### 下一步 / What next

| 想做什么 / What you want to do | 阅读 / Read |
|---|---|
| 把示例换成自己的数据表 / Replace the example with your own tables | [准备调查数据](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel) / [Prepare your survey data](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel) |
| 决定哪些参数固定、哪些估计 / Decide which parameters to fix or estimate | [拟合设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) / [Fitting controls](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) |
| 检查残差、比较不同设置 / Examine residuals and compare configurations | [诊断](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) / [Diagnostics](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) |
| 绘制某个种群量 / Plot a particular quantity | [调查与种群图](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md) / [Survey and population plots](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md) |
| 做敏感性分析、参数剖面和投影 / Test sensitivity, profile a parameter, project forward | [评估工作流](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ASSESSMENT_WORKFLOWS.md) / [Assessment workflows](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ASSESSMENT_WORKFLOWS.md) |
| 从拟合模型模拟，或检验对未来年份的预测 / Simulate from the fit or test predictions of future years | [模型验证](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md) / [Model validation](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md) |

<a id="chapter-05"></a>
## 05 模拟与批量实验 · Simulation

读完本页，你会得到拟合函数可以直接使用的模拟调查表、重复文件（每个文件是一套模拟数据集，连同生成它的种群一起保存），以及对这些重复的拟合结果的偏差、RMSE 和区间覆盖率表。你需要软件包；步骤 2 到 4 还使用 `scripts/simulation_workflow.R` 中的 `simulation_to_tables()` 和 `run_simulation_examples()`，请在仓库根目录运行 R。

At the end of this page you have simulated survey tables that the fitting functions accept, replicate files (one simulated dataset each, saved with its generating population) and a table of bias, RMSE and interval coverage for fits to those replicates. You need the package; steps 2 to 4 also use `simulation_to_tables()` and `run_simulation_examples()` from `scripts/simulation_workflow.R`, so run R from the repository root.

<a id="simulation-choose"></a>

### 1. 选择模拟器 / Choose a simulator

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

`simulate_example_data()` is the quick simulator for testing import, fitting and plotting: one call returns the survey index table `data.CatL`, the weight table `data.wgt` and the maturity table `data.mat` with the generating values in `true_params`, and `save_csv = TRUE` writes them as CSV files to `output_dir`. It applies one fishing mortality to all ages and fixes the length CV at 0.1. `years` must be consecutive calendar years; relabeling columns as quarters does not create quarterly dynamics.

完整操作模型用于对照已知种群的实验，需要三次调用：`initialize_params()` 由预设生成参数列表，`sim_cal()` 据此推导生物学数组，`sim_data()` 让种群经过预热期（最初被丢弃的年份）向前演进，并为每次重复写一个文件；补充量服从 Beverton-Holt 曲线，补充量和捕捞死亡率都带有 AR(1) 过程偏差。下表比较两个预设；[`initialize_params()` 的函数参考](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#initialize_params)列出全部设置。

The full operating model, for experiments against a known population, takes three calls: `initialize_params()` builds the parameter list from a preset, `sim_cal()` derives the biological arrays, and `sim_data()` runs the population through a burn-in (discarded first years) and writes one file per replicate, with Beverton-Holt recruitment and AR(1) process deviations in recruitment and fishing mortality. The table compares the two presets; the [reference of `initialize_params()`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#initialize_params) lists every setting.

| 设置 / Setting | flatfish | tuna |
|---|---|---|
| 操作模型 / Operating model | 年龄结构 / Age-based | 年龄与体长联合 / Joint age-length |
| `growth_step` | 1 年 / 1 year | 0.25 年 / 0.25 year |
| `nyear`、`burn_in` / `nyear`, `burn_in` | 100、80 年 / 100, 80 years | 100、95 年 / 100, 95 years |
| 保留的观测 / Retained observations | 20 个年度时间步 / 20 annual steps | 20 个季度时间步 / 20 quarterly steps |
| `nage`、`rec.age` / `nage`, `rec.age` | 15 个年龄组、1 年 / 15 classes, 1 year | 20 个年龄组、0.25 年 / 20 classes, 0.25 year |
| `Linf`、`vbk` / `Linf`, `vbk` | 60、每年 0.2 / 60, 0.2 per year | 152、每年 0.38 / 152, 0.38 per year |
| `M`、`F_mean` / `M`, `F_mean` | 0.2、0.3（每个年度时间步） / 0.2, 0.3 per annual step | 0.2、0.2（每个季度时间步） / 0.2, 0.2 per quarterly step |

`str()` 显示三张表和 `true_params`；`initialize_params(species = "?")` 列出各预设。无效输入，例如 `L95_sel` 小于 `L50_sel`，会在写任何文件之前停止调用。

`str()` shows the three tables and `true_params`; `initialize_params(species = "?")` lists the presets. Invalid inputs, such as `L95_sel` below `L50_sel`, stop the call before any file is written.

<a id="simulation-generate"></a>

### 2. 生成重复并转换成输入表 / Generate replicates and convert them to input tables

```r
source("scripts/simulation_workflow.R", encoding = "UTF-8")
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

`iter_range` 给出重复编号，编号同时作为随机种子；`sim_data()` 用 `save()` 把每次重复保存为 `output_dir` 中的 `sim_rep<id>` 文件，读取时用 `load()`，`return_iter` 选择返回到内存的那一次。在 `sm` 中，`SN_at_len` 是按时间乘体长排列的调查尾数矩阵，`weight` 和 `mat` 按体长乘时间排列，`years` 是保留时间步的日历，`nyear` 是它们的个数，`SSB`、`Rec`、`TB` 和 `N_at_age` 是生成真值。

`iter_range` gives the replicate ids, which are also the seeds; `sim_data()` saves each replicate as `sim_rep<id>` in `output_dir` with `save()`, read back with `load()`, and `return_iter` selects the one returned in memory. In `sm`, `SN_at_len` is a time by length matrix of survey numbers, `weight` and `mat` are length by time, `years` is the calendar of retained time steps and `nyear` their count, and `SSB`, `Rec`, `TB` and `N_at_age` are the generating truth.

`simulation_to_tables(sm, pa)` 转置 `SN_at_len`，用体长中点作为行标签、用 `sm$years` 作为列名，并把三张表作为一个列表返回；[模拟调查数据案例](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md#case-simulate-survey)从 `pa` 加入生物学设置并拟合一次重复。`run_simulation_examples(out = "simulation_examples")` 为两个预设完成本步骤，把表写成 CSV 文件并在旁边保存 `truth.rds`；两个预设的第 4 次重复已保存在仓库中，见[下载和读取说明](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/data/cases/README.md)。

`simulation_to_tables(sm, pa)` transposes `SN_at_len`, labels rows with the length midpoints and columns with `sm$years`, and returns the three tables as a list; the [simulate survey case](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md#case-simulate-survey) adds the biology from `pa` and fits one replicate. `run_simulation_examples(out = "simulation_examples")` runs this step for both presets and writes CSV tables with `truth.rds` beside them; the seed-4 replicate of both presets is in the repository with [download and reading instructions](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/data/cases/README.md).

如果 `simulation_to_tables()` 因参数列表中的 `len_mid` 与重复文件记录的坐标不同而停止，请传入生成该文件的参数列表。把 `sim_rep` 文件、参数列表和软件包版本与实验一起保存。

If `simulation_to_tables()` stops because `len_mid` differs from the coordinates recorded in the replicate, pass the parameter list that generated the file. Keep the `sim_rep` files, the parameter list and the package version with an experiment.

<a id="simulation-rates"></a>

### 3. 设置死亡率、变异和时间单位 / Set rates, variation and time units

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

In the quick simulator `mean_F` is the arithmetic mean of the generated annual F. In the full simulator `F_mean` is the baseline of `F[t] = F_mean * exp(d[t])`, where `d[t]` is a zero-mean AR(1) process with coefficient `F_ar` and innovation SD `F_sd`, so the mean of the generated F differs from `F_mean`; compare the marginal SD `F_sd / sqrt(1 - F_ar^2)`, not `F_sd`, with a fitted log-F SD. `std_logR` and `R_ar` do the same for recruitment, `std_SN` is the SD of the log survey error, and `M` and `F_mean` are rates per time step, so the tuna values are per quarter.

`nyear` 和 `burn_in` 都是以年为单位的时长；`growth_step` 必须能整除一年，`burn_in` 必须是 `growth_step` 的整数倍且小于 `nyear`，并且至少要保留两个时间步才能拟合。`first.year` 标记第一个保留的时间步，`sm$nyear` 是保留的时间步数。如果调用因 `burn_in` 不是 `growth_step` 的整数倍而停止，年度时间步请用整年，季度时间步请用整季度。

`nyear` and `burn_in` are durations in years; `growth_step` must divide one year, `burn_in` must be an exact multiple of `growth_step` and smaller than `nyear`, and at least two time steps must be retained for fitting. `first.year` labels the first retained step, and `sm$nyear` counts retained steps. If the call stops because `burn_in` is not an exact multiple of `growth_step`, use whole years for annual steps and quarter years for quarterly steps.

<a id="simulation-fit"></a>

### 4. 拟合重复并汇总 / Fit the replicates and summarize

```r
data("YTF_example")
cfg <- YTF_example$fit_config$acl
fits <- sim_acl(iter_range = 4:5, sim_data_path = "simulation_examples/flatfish",
                output_dir = "simulation_examples/fits_acl",
                parameters = cfg$parameters, map = cfg$map, M = pa$M,
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
```

`sim_acl()` 读取 `sim_data_path` 中的每个 `sim_rep<id>` 文件，从文件构造三张表和生物学设置，再用你传入的初值、`map` 和 `M` 拟合 ACL；`sim_alscl()` 用 ALSCL 的参数名做同样的事。`YTF_example` 的设置把生长参数和部分过程参数固定在 flatfish 预设值上；自己的设置按[选择拟合设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting)构造。每次重复在一个工作进程中拟合，它的 `nstarts` 个初值依次运行；`ncores` 决定同时运行多少次重复。每次重复的结果，包括带有 `converge = "FAILED"` 和 `error` 信息的失败，都会返回并保存为 `output_dir` 下的 `result_rep_<id>`。

`sim_acl()` reads each `sim_rep<id>` in `sim_data_path`, builds the tables and the biology from the file and fits ACL with the starting values, `map` and `M` you pass; `sim_alscl()` does the same with ALSCL parameter names. The `YTF_example` configuration fixes growth and some process parameters at the flatfish preset values; build your own as in [Choose the fitting settings](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting). Each replicate is fitted on one worker with its `nstarts` starts run one after the other, and `ncores` sets how many replicates run at the same time. Every result, including a failure with `converge = "FAILED"` and an `error` message, is returned and saved as `result_rep_<id>` in `output_dir`.

`summarize_simulations()` 需要真值列表与拟合列表同名，每个元素包含 `year` 和每个量的一个向量，这里从重复文件读取，使时间坐标一致。`performance$replicates` 给出每次重复的数值检查和错误信息；`performance$summary` 按量给出失败率、偏差、相对偏差、RMSE 和区间覆盖率，以及各自的计数。偏差和 RMSE 只使用通过数值检查的拟合，覆盖率还需要有限的标准误，所以报告统计量时要一并报告 `failure_rate`。如果调用停止并提示“identical unique replicate names”或“time coordinates differ”，说明真值不是从拟合所用的同一批文件读取的。

`summarize_simulations()` needs the truth as a list with the same names as the fits, each with `year` and one vector per quantity, read here from the replicate files so that the time coordinates match. `performance$replicates` gives the numerical checks and error of each replicate; `performance$summary` gives, per quantity, failure rate, bias, relative bias, RMSE and interval coverage with their counts. Bias and RMSE use fits that passed the numerical checks and coverage also needs finite standard errors, so report `failure_rate` with the statistics. If the call stops with "identical unique replicate names" or "time coordinates differ", the truth was not read from the same files as the fits.

<a id="simulation-fitted"></a>

### 5. 从拟合模型模拟 / Simulate from a fitted model

```r
fit <- run_acl(YTF_example, silent = TRUE)
simulated <- simulate_fit(fit, nsim = 3, seed = 42, process = "resample")
names(simulated$simulations[[1]])
simulated$simulations[[1]]$truth$SSB
```

`simulate_fit()` 从拟合好的 ACL 或 ALSCL 模型生成数据集，这就是拟合模型模拟。`process = "conditional"` 保留拟合的种群，只重新抽取观测误差；`process = "resample"` 还在拟合的标量参数值下重新抽取补充量、捕捞死亡率和初始丰度的过程偏差。`simulated$simulations` 的每个元素包含 `x`（`run_acl(x)` 可用的输入列表）、`observations` 和 `truth`，所以可以用 `lapply(simulated$simulations, function(s) s$truth)` 作为真值，对再拟合结果运行 `summarize_simulations()`。未通过数值检查的拟合会被拒绝，除非设置 `allow_failed_fit = TRUE`；[模型验证案例](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md)再拟合这些重复，并继续做预测检验。

`simulate_fit()` generates datasets from a fitted ACL or ALSCL model: fitted-model simulation. `process = "conditional"` keeps the fitted population and redraws only the observation error; `process = "resample"` also draws new recruitment, fishing mortality and initial-abundance process deviations at the fitted scalar parameter values. Each element of `simulated$simulations` has `x`, an input bundle for `run_acl(x)`, `observations` and `truth`, so `summarize_simulations()` applies to the refits with `lapply(simulated$simulations, function(s) s$truth)` as the truth. A fit that failed the numerical checks is rejected unless `allow_failed_fit = TRUE`; the [model validation case](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md) refits the replicates and continues with hindcast validation.

<a id="simulation-next"></a>

### 下一步 / What next

| 想做什么 / What you want to do | 阅读 / Read |
|---|---|
| 绘制一次重复，用两个模型拟合并与真值比较 / Plot one replicate, fit both models and compare with the truth | [如何模拟调查数据？](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md#case-simulate-survey) / [How do I simulate survey data?](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md#case-simulate-survey) |
| 再拟合拟合模型模拟的数据并预测留出年份 / Refit fitted-model simulations and predict withheld years | [模型验证](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md) / [Model validation](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md) |
| 用更少的时间运行更多重复 / Run more replicates in less time | [速度设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/SPEED_GUIDE.md) / [Speed settings](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/SPEED_GUIDE.md) |
| 保存种子、设置和版本以便重复实验 / Keep seeds, settings and versions for a repeatable experiment | [复现结果](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ADVANCED_WORKFLOWS.md) / [Reproducibility](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ADVANCED_WORKFLOWS.md) |
| 比较年度和季度设置 / Compare annual and quarterly settings | [年度与季度时间步](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASE_STUDIES.md) / [Annual and quarterly time steps](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASE_STUDIES.md) |
| 拟合自己的表 / Fit your own tables | [准备调查数据](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel) / [Prepare your survey data](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel) |

<a id="chapter-06"></a>
## 06 选择拟合设置 · Choose the fitting settings

本页帮你决定模型估计哪些参数、固定哪些参数、捕捞死亡率采用什么结构，以及优化器如何运行。你需要一个输入列表 `x`（[准备调查数据](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel)），并且最好已读过[理解第一次拟合](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin)，其中的检查会告诉你哪项设置需要调整。

On this page you decide which parameters the models estimate, which are fixed, how fishing mortality is structured, and how the optimizer runs. You need an input bundle `x` ([Prepare your survey data](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel)) and you should have read [Understand your first fit](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin), whose checks tell you whether a setting needs changing.

设置分三组：`x$fit_args` 中的生物学和数据设置，见[准备调查数据](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel)；模型配置（初值、边界、`map`、F 结构），ACL 和 ALSCL 分别设置；优化器设置（初值个数、工作进程、优化轮数），它们改变求解方式，模型本身保持不变。

The settings fall into three groups: the biology and data settings in `x$fit_args`, which [Prepare your survey data](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel) explains; the model configuration (starting values, bounds, `map`, F structure), chosen separately for ACL and ALSCL; and the optimizer settings (starts, workers, passes), which change how the answer is found and leave the model unchanged.

<a id="fitting-controls-settings"></a>

### 1. 了解各项设置及其位置 / Know the settings and where they live

| 设置 / Setting | 含义 / Meaning | 放在哪里 / Where to put it |
|---|---|---|
| `rec.age`、`nage`、`M`、`sel_L50`、`sel_L95`、`growth_step`、`len_mid`、`len_border` / `rec.age`, `nage`, `M`, `sel_L50`, `sel_L95`, `growth_step`, `len_mid`, `len_border` | 生物学、调查可捕性和时间步 / Biology, survey catchability and time step | `x$fit_args`，两个模型共用 / `x$fit_args`, shared by both models |
| `zero_action` | 调查零值按缺失处理（默认 `"missing"`）或终止拟合（`"error"`） / Treat survey zeros as missing (`"missing"`, default) or stop (`"error"`) | `x$fit_args` |
| `parameters`、`parameters.L`、`parameters.U` / `parameters`, `parameters.L`, `parameters.U` | 标量参数在优化器尺度上的初值和边界 / Starting values and bounds of the scalar parameters, on the optimizer scale | `x$fit_config$acl` 或 `x$fit_config$alscl` / `x$fit_config$acl` or `x$fit_config$alscl` |
| `map` | 哪些参数固定在初值、哪些参数共享 / Which parameters are fixed at their starting value or tied together | `x$fit_config$acl` 或 `x$fit_config$alscl` / `x$fit_config$acl` or `x$fit_config$alscl` |
| `F_structure` | `"group_year"`（默认）：F 随年龄或体长及时间步变化；`"year"`：每个时间步一个 F / `"group_year"` (default): F varies by age or length and by time step; `"year"`: one F per time step | `x$fit_args` 或调用 / `x$fit_args` or the call |
| `nstarts`、`ncores` / `nstarts`, `ncores` | 独立初值的个数和运行它们的工作进程数 / Number of independent optimizer starts and of worker processes running them | 调用 / The call |
| `train_times` | 每个初值连续优化的轮数（默认 1） / Successive optimizer passes from each start (default 1) | 调用 / The call |
| `polish` | 对最佳初值做带检查的 Newton 收尾（默认 `TRUE`） / Finish the best start with checked Newton steps (default `TRUE`) | 调用 / The call |
| `control` | `nlminb()` 的控制参数，如 `iter.max` / `nlminb()` controls such as `iter.max` | 调用 / The call |
| `silent`、`output` / `silent`, `output` | 不显示进度信息；把诊断和图写入 `output/` / Hide progress messages; write diagnostics and plots to `output/` | 调用 / The call |

调用中给出的值只在本次调用中覆盖保存的值。希望之后的每项分析（回溯分析、情景、预测检验）都使用某个选择时，把它存入 `x`，做法见第 7 步。

Values in the call override the stored ones for that call only. Store a choice in `x` when every later analysis (retrospectives, scenarios, hindcast validation) should use it; step 7 shows how.

<a id="fitting-controls-parameters"></a>

### 2. 查看哪些参数会被估计 / See which parameters are estimated

```r
plan <- inspect_parameters(x, "acl")
plan[, c("parameter", "kind", "status", "map_source", "natural_start")]
inspect_parameters(x, "alscl")[, c("parameter", "status", "natural_start")]
```

`inspect_parameters()` 列出所选模型的标量参数和过程偏差块、初值及状态，例如 `free`（估计）、`fixed`（固定）或 `tied`（共享）。`map_source` 说明固定状态来自模型默认还是你的 `map`。下面每做一次修改都可以再运行它；它只读取输入列表，既不编译也不拟合。

`inspect_parameters()` lists the scalar parameters and process-deviation blocks of the chosen model, with their starting values and status, including `free` (estimated), `fixed` or `tied`. `map_source` tells whether a fixed status comes from the model default or from your `map`. Run it after every change below; it compiles and fits nothing.

| 含义 / Meaning | ACL 参数 / ACL parameter | ALSCL 参数 / ALSCL parameter |
|---|---|---|
| 生长（von Bertalanffy） / Growth (von Bertalanffy) | `log_Linf`、`log_vbk`、`t0` / `log_Linf`, `log_vbk`, `t0` | `log_Linf`、`log_vbk`、`log_t0` / `log_Linf`, `log_vbk`, `log_t0` |
| 年龄别体长的离散程度；生长增量 CV / Spread of length at age; growth increment CV | `log_cv_len` | `log_cv_len`、`log_cv_grow` / `log_cv_len`, `log_cv_grow` |
| 平均补充量和平均 F（对数尺度） / Mean recruitment and mean F (log scale) | `mean_log_R`、`mean_log_F` / `mean_log_R`, `mean_log_F` | `mean_log_R`、`mean_log_F` / `mean_log_R`, `mean_log_F` |
| 过程偏差的标准差 / Standard deviations of the process deviations | `log_std_log_R`、`log_std_log_F`、`log_std_log_N0` / `log_std_log_R`, `log_std_log_F`, `log_std_log_N0` | `log_sigma_log_R`、`log_sigma_log_F`、`log_sigma_log_N0` / `log_sigma_log_R`, `log_sigma_log_F`, `log_sigma_log_N0` |
| F 在时间上的相关；在年龄或体长上的相关 / Correlation of F across time; across ages or lengths | `logit_log_F_y`、`logit_log_F_a` / `logit_log_F_y`, `logit_log_F_a` | `logit_log_F_y`、`logit_log_F_l` / `logit_log_F_y`, `logit_log_F_l` |
| 补充量在时间上的相关 / Correlation of recruitment across time | `logit_log_R` | `logit_log_R` |
| 初始总死亡率；调查观测 SD / Initial total mortality; survey observation SD | `log_init_Z`、`log_std_index` / `log_init_Z`, `log_std_index` | `log_init_Z`、`log_sigma_index` / `log_init_Z`, `log_sigma_index` |

默认情况下，ACL 固定 `log_std_log_F`、`logit_log_F_y`、`logit_log_F_a` 和 `t0`，ALSCL 固定 `log_sigma_log_F` 和 `log_t0`，其余都估计。`YTF_example` 固定得更多（生长参数和两个过程 SD），因为它的教学配置以运行快为目标；你自己的输入列表从默认设置开始。过程偏差 `dev_log_R`、`dev_log_F` 和 `dev_log_N0` 按数据维度生成，默认作为随机效应估计。它们的 `map` 可以固定某些偏差，或让多个偏差共享一个估计值；查看 `n_free`、`n_fixed` 和 `n_tied`，确认每个块中还有多少自由值。

By default ACL fixes `log_std_log_F`, `logit_log_F_y`, `logit_log_F_a` and `t0`, and ALSCL fixes `log_sigma_log_F` and `log_t0`; everything else is estimated. `YTF_example` fixes more (the growth parameters and two process SDs) so that its teaching configuration runs quickly; your own bundle starts from the defaults. The process deviations `dev_log_R`, `dev_log_F` and `dev_log_N0` are created from the data dimensions and estimated as random effects by default. Their `map` entries can fix individual deviations or tie them together; inspect `n_free`, `n_fixed` and `n_tied` to see how many remain free in each block.

<a id="fitting-controls-map"></a>

### 3. 用 map 固定或释放参数 / Fix or release parameters with map

```r
# 把生长参数固定在初值，并估计 F 在时间上的相关 / Fix growth at the starting values and estimate the F correlation across time
my_map <- list(log_Linf = factor(NA), log_vbk = factor(NA), logit_log_F_y = NULL)
a_map <- run_acl(x, map = my_map, silent = TRUE)
extract_parameters(a_map)
# 把选择存入输入列表，供之后的分析使用 / Keep the choice in the bundle for later analyses
x$fit_config$acl$map <- my_map
```

`factor(NA)` 把参数固定在初值；具名 `NULL` 释放一个模型默认固定的参数。调用中或 `x$fit_config` 中给出的 `map` 会整体替换保存的 map，所以每次都要列出全部想固定的项。当数据无法确定某个参数（常见迹象是 Hessian 不正定或相关系数估计到接近 1），或外部研究给出的值比拟合更可靠时，就固定该参数；每个固定值的来源都要随评估一起记录。`generate_map()` 把列表与 ACL 默认设置合并，但会丢掉 `NULL` 项，所以释放参数的列表要直接作为 `map` 传入。

`factor(NA)` fixes a parameter at its starting value; a named `NULL` releases a parameter that the model fixes by default. A `map` given in the call or stored in `x$fit_config` replaces the stored map completely, so list every fix you want each time. Fix a parameter when the data leave it undetermined (a Hessian that is not positive definite or a correlation estimated near 1 are the usual signs) or when an external study gives a better value than the fit could; record the source of every fixed value with the assessment. `generate_map()` merges a list with the ACL defaults but drops `NULL` entries, so pass release lists directly as `map`.

对过程偏差块，提供与偏差数量相同的因子：`NA` 将对应偏差固定在初值（零），重复的因子水平让对应偏差共享一个估计值。`simulate_fit(process = "resample")` 要求过程偏差不受这类限制；条件模拟也支持固定或共享的 map。`hindcast_model()` 要求随时间变化的 `dev_log_R` 和 `dev_log_F` 不受这类限制，但支持固定或共享的静态 `dev_log_N0`。在验证研究中使用这些限制前，见[拟合模型模拟与预测检验](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md)。

For a process-deviation block, supply a factor with one entry per deviation: `NA` fixes that entry at its starting value (zero), and repeated factor levels tie entries to one estimated value. `simulate_fit(process = "resample")` requires unrestricted process deviations; conditional simulation also supports fixed or tied maps. `hindcast_model()` requires unrestricted time-varying `dev_log_R` and `dev_log_F` maps, but supports fixed or tied static `dev_log_N0` values. See [Simulate and validate a fitted model](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md) before using these restrictions in a validation study.

<a id="fitting-controls-starts"></a>

### 4. 设置初值和边界 / Set starting values and bounds

```r
p <- create_parameters(model_type = "acl", species = "flatfish")
p$parameters$log_Linf <- log(65)
p$parameters.U$log_Linf <- log(90)
x$fit_config$acl$parameters <- p$parameters
x$fit_config$acl$parameters.U <- p$parameters.U
inspect_parameters(x, "acl")[, c("parameter", "natural_start", "lower", "upper")]
```

初值和边界在优化器尺度上填写：渐近体长 65 cm 写 `log_Linf = log(65)`，相关系数 0.5 写 `logit_log_R = qlogis(0.5)`。`create_parameters()` 按物种预设（`"flatfish"`、`"tuna"`、`"krill"` 或不指定）返回完整的初值（`parameters`）、下界（`parameters.L`）和上界（`parameters.U`）列表；有信息的项目改掉即可。ACL 直接使用 `t0`，ALSCL 使用 `log_t0`，因此 ALSCL 的 `t0` 必须在 0 和 `rec.age` 之间。超出边界的初值会在拟合前移到最近的边界。[估计参数清单](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting)给出完整列表和变换方式。

Starting values and bounds are entered on the optimizer scale: `log_Linf = log(65)` for an asymptotic length of 65 cm, `logit_log_R = qlogis(0.5)` for a correlation of 0.5. `create_parameters()` returns complete lists of starts (`parameters`), lower bounds (`parameters.L`) and upper bounds (`parameters.U`) for a species preset (`"flatfish"`, `"tuna"`, `"krill"` or none); change the entries you have information about. ACL uses `t0` directly, while ALSCL uses `log_t0`, so an ALSCL `t0` must lie between 0 and `rec.age`. A starting value outside its bounds is moved to the nearest bound before fitting. [Estimation parameter lists](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) gives the full list with transformations.

<a id="fitting-controls-f-structure"></a>

### 5. 选择 F 结构 / Choose the F structure

默认 `F_structure = "group_year"` 时，捕捞死亡率在每个时间步对每个年龄（ACL）或体长组（ALSCL）各有一个值，偏差在时间上以及年龄或体长之间相关。`F_structure = "year"` 时，每个时间步所有年龄或体长共用一个 F，季度数据就是每季度一个值。渔业对各体长作用相同，或数据无法确定年龄别或体长别 F（表现为组间相关估计到接近 1，或 Hessian 不正定）时，选 `"year"`。

With the default `F_structure = "group_year"`, fishing mortality has one value for every age (ACL) or length bin (ALSCL) in every time step, with deviations correlated across time and across ages or lengths. With `F_structure = "year"`, all ages or lengths share one F in each time step: one value per quarter for quarterly data. Choose `"year"` when the fishery acts on all sizes alike, or when age- or length-specific F is undetermined by the data, which shows as a correlation across groups estimated near 1 or a Hessian that is not positive definite.

```r
a_year <- run_acl(x, F_structure = "year", silent = TRUE)
diagnose_model(x$data.CatL, a_year)
plot_fishing_mortality(a_year, se = TRUE)
plot_deviance(a_year, type = "F", se = TRUE)
```

选 `"year"` 后，组间相关参数（`logit_log_F_a` 或 `logit_log_F_l`）被排除在拟合之外；`report$dev_log_F` 只有一行，`report$F` 保持年龄（或体长）乘时间的形状，各行相同。同一输入列表之后的每项分析（包括回溯）都要用同一种结构。

With `"year"` the correlation across groups (`logit_log_F_a` or `logit_log_F_l`) is unused and left out of the fit, `report$dev_log_F` has one row, and `report$F` keeps its age (or length) by time shape with identical rows. Use the same structure in every later analysis of the same bundle, including retrospectives.

<a id="fitting-controls-optimizer"></a>

### 6. 控制优化器 / Control the optimizer

```r
a4 <- run_acl(x, nstarts = 4, ncores = 2, silent = TRUE)
a4$start_diagnostics
a4$refinement$status
```

`nstarts` 运行多个独立初值：第一个使用给定的初值，之后的初值由确定性扰动得到，最终保留目标函数值最低的拟合。`start_diagnostics` 列出每个初值的目标函数值和收敛码；不同初值停在不同的目标函数值，说明目标函数面有多个极小值，最佳的那个值得进一步检查。`ncores` 设定同时运行初值的工作进程数（`nstarts` 默认等于 `ncores`，比较耗时时两者都要设定）。`train_times` 从每个初值的终点再次运行优化器；`polish = TRUE` 对最佳初值做最多五步 Newton 收尾，只在梯度减小且 Hessian 保持正定时接受，`a4$refinement` 记录结果。`control = list(iter.max = 3000)` 把限制传给 `nlminb()`。

`nstarts` runs independent starts: the first from the supplied starting values, the later ones from deterministic perturbations of them, and the lowest objective is kept. `start_diagnostics` lists every start with its objective and convergence code; starts that end at different objectives mean the surface has several minima and the best one deserves a closer look. `ncores` sets how many worker processes run the starts at the same time (`nstarts` defaults to `ncores`, so set both when you compare timings). `train_times` repeats the optimizer from each start's end point; `polish = TRUE` finishes the best start with up to five Newton steps that are accepted only when the gradient decreases and the Hessian stays positive definite, and `a4$refinement` records what happened. `control = list(iter.max = 3000)` passes limits to `nlminb()`.

<a id="fitting-controls-record"></a>

### 7. 记录你的选择 / Record your choices

```r
x$fit_args$F_structure <- "year"
x$fit_config$acl$map <- my_map
saveRDS(x, "my_bundle.rds")
a <- run_acl(x, silent = TRUE)
save_assessment(a, "my_acl.rds")
```

所有工作流函数都读取输入列表，因此存入 `x` 的选择会被 `retro_acl(x)`、`fit_scenarios(x, ...)`、`hindcast_model(x)` 和模拟函数一致地使用。`save_assessment()` 把完整配方与拟合结果一起保存，读者可以看到哪些值被固定，并用 `refit_model()` 重新拟合。

Every workflow function reads the bundle, so a choice stored in `x` is applied consistently by `retro_acl(x)`, `fit_scenarios(x, ...)`, `hindcast_model(x)` and the simulation functions. `save_assessment()` keeps the complete recipe with the fit, so a reader can see which values were fixed and refit the model with `refit_model()`.

<a id="fitting-controls-next"></a>

### 下一步 / What next

| 想做什么 / What you want to do | 阅读 / Read |
|---|---|
| 判断拟合并寻找残差规律 / Judge the fit and look for residual patterns | [诊断](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) / [Diagnostics](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) |
| 查看参数和变换的完整列表 / See the full list of parameters and transformations | [估计参数清单](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) / [Estimation parameter lists](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) |
| 检验固定值对结果的影响 / Test how fixed values change the answer | [评估工作流](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ASSESSMENT_WORKFLOWS.md) / [Assessment workflows](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ASSESSMENT_WORKFLOWS.md) |
| 让拟合更快 / Make fits faster | [速度设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/SPEED_GUIDE.md) / [Speed settings](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/SPEED_GUIDE.md) |

<a id="estimation-parameters"></a>
### 估计参数列表 / Estimation parameter lists

本页列出两个模型的全部标量参数、它们到自然尺度的变换，以及一个预设的初值和边界。表中的键名就是 `parameters`、`parameters.L` 和 `parameters.U` 的条目名，都在优化尺度上填写。

On this page you see every scalar parameter of both models, its transformation to the natural scale, and the starts and bounds of a preset. The keys are the entries of `parameters`, `parameters.L` and `parameters.U`, on the optimizer scale.

| ACL 键名 / ACL key | ALSCL 键名 / ALSCL key | 变换 / Transform to natural scale | 含义 / Meaning |
|---|---|---|---|
| `log_init_Z` | `log_init_Z` | exp | 初始平衡总死亡率 / Initial equilibrium total mortality |
| `log_std_log_N0` | `log_sigma_log_N0` | exp | 初始年龄尾数偏差 SD / Initial log-number deviation SD |
| `mean_log_R` | `mean_log_R` | exp | 对数补充过程的位置参数 / Location of the log recruitment process |
| `log_std_log_R` | `log_sigma_log_R` | exp | 对数补充过程 SD 缩放 / Log recruitment process SD scale |
| `logit_log_R` | `logit_log_R` | plogis | 补充 AR(1) 相关，限定 (0,1) / Recruitment correlation restricted to (0,1) |
| `mean_log_F` | `mean_log_F` | exp | 对数 F 过程的位置参数 / Location of the log F process |
| `log_std_log_F` | `log_sigma_log_F` | exp | F 偏差 SD 缩放 / F deviation SD scale |
| `logit_log_F_y` | `logit_log_F_y` | plogis | F 的时间相关 / Temporal F correlation |
| `logit_log_F_a` | `logit_log_F_l` | plogis | F 的年龄/体长相关 / Age/length F correlation |
| `log_vbk` | `log_vbk` | exp | VB k，单位为每年 / Annual VB k |
| `log_Linf` | `log_Linf` | exp | 渐近体长 / Asymptotic length |
| `t0` | `log_t0` | ACL 原值；ALSCL exp / Identity (ACL); exp (ALSCL) | VB t0；ALSCL 限定为正值 / VB t0; ALSCL restricts it to positive values |
| `log_cv_len` | `log_cv_len` | exp | 年龄体长 CV / Length-at-age CV |
| 无 / none | `log_cv_grow` | exp | 增长增量 CV / Growth-increment CV |
| `log_std_index` | `log_sigma_index` | exp | 对数调查观测 SD / Log survey observation SD |

<a id="estimation-parameters-inspect"></a>

#### 1. 查看一个预设 / Inspect a preset

```r
p <- create_parameters(model_type = "alscl", species = "flatfish")
keys <- names(p$parameters)
parameter_table <- data.frame(
  Parameter = keys,
  Start = unlist(p$parameters[keys]),
  Lower = unlist(p$parameters.L[keys]),
  Upper = unlist(p$parameters.U[keys]))
parameter_table
p$parameters$log_sigma_index <- log(0.15)
p$parameters.U$log_sigma_index <- log(0.5)
fixed_index <- list(log_sigma_index = factor(NA))
```

`create_parameters()` 返回所选模型和预设的三个列表。改初值或边界后参数仍然自由；只有 `fixed_index` 这样的 `map` 条目才会固定它。随机效应 `dev_log_R`、`dev_log_F` 和 `dev_log_N0` 在上表中没有键名。

`create_parameters()` returns the three lists for the model and preset. A changed start or bound leaves the parameter free; only a `map` entry such as `fixed_index` fixes it. The random effects `dev_log_R`, `dev_log_F` and `dev_log_N0` have no key above.

<a id="estimation-parameters-next"></a>

#### 下一步 / What next

| 想做什么 / What you want to do | 阅读 / Read |
|---|---|
| 在输入列表中固定或释放参数 / Fix or release parameters in the bundle | [选择拟合设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) / [Choose the fitting settings](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) |
| 在完整脚本中查看默认固定项和解除方法 / See the default fixes and releases in a complete script | [如何拟合自己的调查数据？](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md) / [How do I fit my own survey data?](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md) |

<a id="chapter-07"></a>
## 07 判断拟合是否可用 · Judge whether a fit can be used

本页从四个方面检查一次拟合：优化器的数值检查、残差规律、与其他设置的比较，以及对固定值的敏感性。你需要[理解第一次拟合](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin)中的对象：输入列表 `x`、ACL 拟合 `a` 和 ALSCL 拟合 `b`。代码以 `b` 为例，对 `a` 用法相同。

On this page you check a fit from four sides: the numerical checks of the optimizer, the residual patterns, the comparison with other configurations, and the sensitivity to the fixed values. You need the objects of [Understand your first fit](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin): the bundle `x`, the ACL fit `a` and the ALSCL fit `b`. The code uses `b`; it works the same for `a`.

<a id="diagnostics-numerical"></a>

### 1. 数值检查 / Numerical checks

```r
diagnose_model(x$data.CatL, b)
b$diagnostics$issues
b$diagnostics$high_correlations
b$refinement$status
b$start_diagnostics
```

`diagnose_model()` 打印优化器收敛码（0 为正常）、最大绝对梯度（小于 0.001 通过）、Hessian 是否正定、是否有参数落在边界上，以及是否有标准差或相关系数估计到自然尺度的极限。`b$diagnostics$issues` 列出未通过的检查；`high_correlations` 列出估计值相关系数达到 0.95 以上的参数对，说明数据难以把它们分开。`b$refinement` 记录收尾的 Newton 步（满足梯度准则时 `status` 为 `gradient_tolerance`），使用 `nstarts` 时 `b$start_diagnostics` 给出每个初值的目标函数值。

`diagnose_model()` prints the optimizer convergence code (0 is normal), the maximum absolute gradient (below 0.001 passes), whether the Hessian is positive definite, whether a parameter sits on a bound, and whether a standard deviation or correlation was estimated at its natural limit. `b$diagnostics$issues` lists the failed checks; `high_correlations` lists pairs of parameters whose estimates are correlated at 0.95 or more, which means the data separate them poorly. `b$refinement` records the Newton steps that finished the fit (`status` is `gradient_tolerance` when the gradient criterion was met), and `b$start_diagnostics` shows the objective of every start when you used `nstarts`.

检查未通过时，每次只改一处：增加初值（`nstarts = 4`），固定难以确定的参数，或让各组共用 F（`F_structure = "year"`），方法见[拟合设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting)，然后在第 3 步比较新旧拟合。通过检查的拟合有明确的最优解；它是否描述了数据，是第 2 步要回答的问题。

When a check fails, change one thing at a time: run more starts (`nstarts = 4`), fix the parameter that is poorly determined or share F across groups (`F_structure = "year"`), as described in [Fitting controls](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting), and compare the new fit with the old one in step 3. A fit that passes the checks has a well-defined optimum; whether it describes the data is the question of step 2.

<a id="diagnostics-residuals"></a>

### 2. 残差规律 / Residual patterns

```r
plot_residuals(b, facet_by = "year", facet_ncol = 5)
plot_residuals(b, facet_by = "length", facet_ncol = 4)
checks <- check_fit(b, max_lag = 4)
checks$plots$heatmap
checks$plots$lag
checks$plots$qq
checks$lag_correlations
```

残差是观测的对数调查指数减去拟合值。`facet_by = "year"` 按年份分面画残差随体长的变化；`facet_by = "length"` 按体长组分面画残差随年份的变化。`check_fit()` 把残差标准化，并增加三种视图：年份乘体长的热图，同色成块说明模型漏掉了某个队列或某段体长；同一体长组残差相隔 1 到 `max_lag` 个时间步的相关系数，短滞后处明显偏离 0 说明模型漏掉了年份效应；QQ 图，尾部偏离说明存在异常值或观测误差偏离对数正态。

The residual is the observed log survey index minus the fitted one. `facet_by = "year"` draws the residuals against length for each year; `facet_by = "length"` draws them against year for each length bin. `check_fit()` standardizes the residuals and adds three views: a heatmap of year by length, where blocks of the same colour show a cohort or a size range the model misses; the correlation between residuals of the same length bin one to `max_lag` time steps apart, where values far from zero at short lags show year effects missing from the model; and a QQ plot, where heavy tails point to outliers or to observation errors that depart from the lognormal.

把这些视图当作修改方向的提示，而不是检验：残差以拟合的过程偏差为条件，没有附带显著性水平。只出现在最小体长组的规律多半与调查选择性有关（`sel_L50`、`sel_L95`）；在热图上沿对角线移动的规律与生长有关。

Treat these views as guides to what to change, not as tests: the residuals are conditional on the fitted process deviations, so no significance level is attached to them. A pattern confined to the smallest bins often reflects survey selectivity (`sel_L50`, `sel_L95`); a pattern that moves diagonally through the heatmap reflects growth.

<a id="diagnostics-compare"></a>

### 3. 比较设置和模型 / Compare configurations and models

```r
comparison <- compare_models(a, b, x$data.CatL)
comparison$comparison
comparison$fit_metrics
plot_compare_residuals(a, b, x$data.CatL)
plot_compare_ts(a, b, quantities = c("SSB", "Rec"), se = TRUE)
```

`compare_models()` 适用于同一观测的任意两次拟合：ACL 对 ALSCL，或同一模型的两种设置，例如某个参数固定与释放。它先核对两次拟合使用了同一张调查表（`data_verified`），再比较 AIC、BIC 和 `fit_metrics` 中的拟合统计量。`preferred` 只在两次拟合都通过数值检查（`eligible`）时给出 AIC 较低的模型，否则留空并在 `issues` 中说明原因。用比较结果在统计上可比的设置之间做选择；AIC 较低并不能让固定值或结构不适合该种群的模型变得可用。

`compare_models()` works for any two fits of the same observations: ACL against ALSCL, or two configurations of one model, such as a parameter fixed and released. It first verifies that both fits used the same survey table (`data_verified`), then compares AIC, BIC and the fit statistics in `fit_metrics`. The `preferred` entry names the model with the lower AIC only when both fits passed the numerical checks (`eligible`); otherwise it stays empty and `issues` says why. Use the comparison to choose between statistically comparable configurations; a lower AIC does not make a model with unsuitable fixed values or structure usable.

<a id="diagnostics-sensitivity"></a>

### 4. 对固定值的敏感性 / Sensitivity to the fixed values

```r
scenarios <- fit_scenarios(x, list(reference = list(), low_M = list(M = 0.15), high_M = list(M = 0.25)),
                           model = "acl", ncores = 2)
scenarios$status
subset(scenarios$estimates, quantity == "SSB" & year == max(year))
```

固定输入（自然死亡率 `M`、调查可捕性、固定的生长参数）决定估计值的尺度。`fit_scenarios()` 在具名的改动下重新拟合同一观测，返回每次拟合的状态和按情景整理的估计值表，可以看出 `M` 在有依据的范围内变化时，最后一年的产卵生物量变动多少。先看 `status`：未通过数值检查的情景保留在表中并加以标记。[评估工作流](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ASSESSMENT_WORKFLOWS.md)继续介绍似然剖面和投影。

The fixed inputs (natural mortality `M`, survey catchability, fixed growth parameters) set the scale of the estimates. `fit_scenarios()` refits the same observations under named changes and returns every fit's status and a table of estimates by scenario, so you can see how much the spawning biomass in the last year moves when `M` varies over its supported range. Read `status` first: a scenario that failed the numerical checks stays in the table, flagged. [Assessment workflows](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ASSESSMENT_WORKFLOWS.md) continues with likelihood profiles and projections.

<a id="diagnostics-stability"></a>

### 5. 随时间的稳定性 / Stability over time

另外两项检查针对时间维度。回溯分析依次去掉最后 1、2、3 个时间步后重新拟合，报告末端估计值的变化幅度（Mohn's rho），见[回溯分析](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#retrospective)。预测检验用较早的时间步拟合，再用留出的观测给之后时间步的预测评分，见[模型验证](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md)。

Two further checks look at the time dimension. A retrospective analysis refits the model after removing the last one, two and three time steps and reports how much the terminal estimates change (Mohn's rho); see [Retrospectives](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#retrospective). Hindcast validation fits on the earlier time steps and scores the predictions of later ones against the withheld observations; see [Model validation](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md).

<a id="diagnostics-next"></a>

### 下一步 / What next

| 想做什么 / What you want to do | 阅读 / Read |
|---|---|
| 修改检查指出的设置 / Change a setting that a check pointed to | [拟合设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) / [Fitting controls](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) |
| 运行回溯分析 / Run retrospectives | [回溯分析](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#retrospective) / [Retrospectives](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#retrospective) |
| 做参数剖面或向前投影 / Profile a parameter or project the stock forward | [评估工作流](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ASSESSMENT_WORKFLOWS.md) / [Assessment workflows](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ASSESSMENT_WORKFLOWS.md) |
| 检验对未来时间步的预测 / Check predictions of future time steps | [模型验证](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md) / [Model validation](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md) |
| 绘制其他比较图 / Draw other comparison figures | [模型比较图](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md) / [Model comparison plots](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md) |

<a id="chapter-08"></a>
## 08 调查与种群图 · Survey and population plots

先完成第 04 章的 YTF 拟合，得到 `a`、`b`、`x`、`inputs`，并设置 `dat <- x$data.CatL`。加载 ggplot2 和 patchwork。第 11 章建立回溯对象 `ra/rb`。
First complete chapter 04, define `dat <- x$data.CatL`, and load ggplot2 and patchwork. Chapter 11 defines retrospective objects.

```r
library(ggplot2)
library(patchwork)
acl_theme_set(palette="npg", base_theme="theme_bw")
```

## 1. 调查拟合 length 对数尺度 / Survey fit length log scale

```r
# 绘制本图 / Draw this figure
plot_CatL(b, facet_by = "length", exp_transform = FALSE, facet_ncol = 4,
  point_size = 1, line_size = 0.6,
  x_breaks = c(2000, 2010, 2015),
  ylab = "Log survey index")
```

[![调查拟合 length 对数尺度 / Survey fit length log scale](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/CatL_length_FALSE.png?raw=true&v=3bc2947125d2)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/CatL_length_FALSE.png?raw=true&v=3bc2947125d2)

每个体长组一个面板，横轴为时间，纵轴为对数调查指数：朱红色点为观测的对数指数，深蓝色曲线为拟合的 `Elog_index`。用它逐组检查拟合；点连续偏在曲线一侧（如本例的 16 组和 50 组）说明该组被系统低估或高估，对数尺度让大小体长组的偏离同样可读。

One panel per length bin, time on the horizontal axis and the log survey index on the vertical axis: vermilion points are the observed log index and the navy curve is the fitted `Elog_index`. Use it to judge the fit bin by bin; a run of points on one side of the curve, as in bins 16 and 50 here, marks a bin the model under- or over-predicts, and the log scale shows this equally well in small and large bins.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_CatL)



## 2. 调查拟合 length 原尺度 / Survey fit length original scale

```r
# 绘制本图 / Draw this figure
plot_CatL(b, facet_by = "length", exp_transform = TRUE, facet_ncol = 4,
  point_size = 1, line_size = 0.6,
  x_breaks = c(2000, 2010, 2015),
  ylab = "Survey index")
```

[![调查拟合 length 原尺度 / Survey fit length original scale](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/CatL_length_TRUE.png?raw=true&v=a9ad83ecd2b6)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/CatL_length_TRUE.png?raw=true&v=a9ad83ecd2b6)

同样的面板改为原尺度：深蓝色曲线为 `exp(Elog_index)`，即拟合对数正态分布的中位数，朱红色点为观测指数。用它按指数单位读取偏差；误差是乘性的，高值处看似很大的差距与低值处的小差距可能是相同的相对偏差。

The same panels on the original scale: the navy curve is `exp(Elog_index)`, the median of the fitted lognormal distribution, and the vermilion points are the observed index. Use it to read the misfit in index units; the error is multiplicative, so a gap that looks large at high values can be the same relative misfit as a small gap at low values.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_CatL)



## 3. 调查拟合 year 对数尺度 / Survey fit year log scale

```r
# 绘制本图 / Draw this figure
plot_CatL(b, facet_by = "year", exp_transform = FALSE, facet_ncol = 4,
  line_size1 = 0.6, line_size2 = 0.4,
  x_breaks = c(10, 30, 50),
  ylab = "Log survey index")
```

[![调查拟合 year 对数尺度 / Survey fit year log scale](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/CatL_year_FALSE.png?raw=true&v=27b8dc9d9c6c)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/CatL_year_FALSE.png?raw=true&v=27b8dc9d9c6c)

`line_size1 = 0.6` 控制拟合线，`line_size2 = 0.4` 控制观测线；年份模式不使用 `line_size` 和 `point_size`。 / `line_size1 = 0.6` controls fitted curves and `line_size2 = 0.4` controls observations; year mode does not use `line_size` or `point_size`.

每个时间步一个面板，横轴为体长，纵轴为对数调查指数：细朱红线为观测对数指数随体长的变化，粗深蓝线为拟合的 `Elog_index`。用它检查同一时间步内的拟合形状；深蓝线没有跟上的突起（如本例后几年最大体长组处）就是拟合未能解释的体长结构。

One panel per time step, length on the horizontal axis and the log survey index on the vertical axis: the thin vermilion curve is the observed log index across lengths and the thick navy curve is the fitted `Elog_index`. Use it to check the shape of the fit within a time step; a bump the navy curve misses, as at the largest bin in the later years here, is length structure the fit leaves unexplained.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_CatL)



## 4. 调查拟合 year 原尺度 / Survey fit year original scale

```r
# 绘制本图 / Draw this figure
plot_CatL(b, facet_by = "year", exp_transform = TRUE, facet_ncol = 4,
  line_size1 = 0.6, line_size2 = 0.4,
  x_breaks = c(10, 30, 50),
  ylab = "Survey index")
```

[![调查拟合 year 原尺度 / Survey fit year original scale](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/CatL_year_TRUE.png?raw=true&v=77c9b0f4936a)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/CatL_year_TRUE.png?raw=true&v=77c9b0f4936a)

`line_size1 = 0.6` 控制拟合线，`line_size2 = 0.4` 控制观测线；年份模式不使用 `line_size` 和 `point_size`。 / `line_size1 = 0.6` controls fitted curves and `line_size2 = 0.4` controls observations; year mode does not use `line_size` or `point_size`.

同样的面板改为原尺度，曲线为 `exp(Elog_index)` 中位数与观测指数。用它看每个时间步的指数主要来自哪些体长；峰的位置和高度显示调查捕到的主要体长，观测峰偏离深蓝线的时间步值得再看残差图。

The same panels on the original scale, with the curves as `exp(Elog_index)` medians and the observed index. Use it to see which lengths carry the index in each time step; the position and height of the peak show where the survey catches most fish, and a time step whose observed peak sits off the navy curve is worth checking in the residual figures.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_CatL)



## 5. 丰度 N / Abundance N

```r
# 绘制本图 / Draw this figure
plot_abundance(b, type = "N", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![丰度 N / Abundance N](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_abundance_N.png?raw=true&v=028b3b37517a)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_abundance_N.png?raw=true&v=028b3b37517a)

各组之和的总丰度随时间步变化；阴影为近似 95% 区间，即估计值加减 1.96 倍标准误。用它看全种群的趋势及其精度；本例 2012 年的跳升是同年的强补充量进入最小年龄组。

Total abundance, summed over all groups, by time step; the shaded band is the approximate 95% interval, the estimate plus or minus 1.96 standard errors. Use it for the stock-wide trend and its precision; the jump in 2012 here is the strong 2012 recruitment entering the youngest age class.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_abundance)



## 6. 丰度 NA / Abundance NA

```r
# 绘制本图 / Draw this figure
plot_abundance(b, type = "NA", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![丰度 NA / Abundance NA](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_abundance_NA.png?raw=true&v=f592f60070a5)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_abundance_NA.png?raw=true&v=f592f60070a5)

年龄别丰度，每个年龄组一个面板，纵轴各自取值，均带 95% 区间。用它追踪年级群：强年级群表现为每个时间步向右移一个面板的峰；年龄越大区间越宽，因为老龄组数量少，调查对它们的信息也少。

Abundance at age, one panel per age class with its own vertical scale, each with the 95% band. Use it to follow cohorts: a strong year class appears as a peak that moves one panel to the right at each time step, and the bands widen with age because the old classes are small and the survey says little about them.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_abundance)



## 7. 丰度 NL / Abundance NL

```r
# 绘制本图 / Draw this figure
plot_abundance(b, type = "NL", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![丰度 NL / Abundance NL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_abundance_NL.png?raw=true&v=d58b6e23d412)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_abundance_NL.png?raw=true&v=d58b6e23d412)

体长别丰度，每个体长组一个面板，均带 95% 区间。用它看数量集中在哪些体长；本例 2012 年的峰先出现在小体长组，随年级群生长再出现在较大的组，最大的组变化平缓，因为鱼在此累积。

Abundance at length, one panel per length bin, each with the 95% band. Use it to see which lengths hold the numbers; the 2012 peak here appears first in the small bins and later in the larger ones as the cohort grows, while the largest bin changes slowly because fish accumulate there.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_abundance)

### 模型、输出与区间支持范围

`se = TRUE` 绘制逐点近似 95% 区间，即估计值加减 1.96 倍标准误；下表列出每个模型哪些量带标准误。数量或标准误不可用时报错，只需要估计线时用 `se = FALSE`；解读区间前先通过数值检查。

| 函数 | 类型 | ACL | ALSCL |
|---|---|---|---|
| `plot_biomass()` | `B` | 估计 + 区间 | 估计 + 区间 |
| `plot_biomass()` | `BL` | 仅估计 | 估计 + 区间 |
| `plot_biomass()` | `BA` | 不可用 | 估计 + 区间 |
| `plot_SSB()` | `SSB` | 估计 + 区间 | 估计 + 区间 |
| `plot_SSB()` | `SBL` | 仅估计 | 估计 + 区间 |
| `plot_SSB()` | `SBA` | 不可用 | 估计 + 区间 |
| `plot_catch()` | `CN` | 估计 + 区间 | 估计 + 区间 |
| `plot_catch()` | `CNA` | 仅估计 | 估计 + 区间 |
| `plot_catch()` | `CNL` | 不可用 | 估计 + 区间 |

```r
plot_biomass(b, type = "BL", se = TRUE)
plot_SSB(b, type = "SBL", se = TRUE)
plot_catch(a, type = "CNA", se = FALSE)
```

### Model, output and interval support

`se = TRUE` draws pointwise approximate 95% intervals, the estimate plus or minus 1.96 standard errors; the table lists which quantities each model reports with standard errors. An unavailable quantity or standard error is an error, and `se = FALSE` draws the estimate alone; pass the numerical checks before reading an interval.

| Function | Type | ACL | ALSCL |
|---|---|---|---|
| `plot_biomass()` | `B` | Estimate + interval | Estimate + interval |
| `plot_biomass()` | `BL` | Estimate only | Estimate + interval |
| `plot_biomass()` | `BA` | Unavailable | Estimate + interval |
| `plot_SSB()` | `SSB` | Estimate + interval | Estimate + interval |
| `plot_SSB()` | `SBL` | Estimate only | Estimate + interval |
| `plot_SSB()` | `SBA` | Unavailable | Estimate + interval |
| `plot_catch()` | `CN` | Estimate + interval | Estimate + interval |
| `plot_catch()` | `CNA` | Estimate only | Estimate + interval |
| `plot_catch()` | `CNL` | Unavailable | Estimate + interval |

```r
plot_biomass(b, type = "BL", se = TRUE)
plot_SSB(b, type = "SBL", se = TRUE)
plot_catch(a, type = "CNA", se = FALSE)
```



## 8. 生物量 B / Biomass B

```r
# 绘制本图 / Draw this figure
plot_biomass(b, type = "B", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![生物量 B / Biomass B](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_biomass_B.png?raw=true&v=3d2df45029c9)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_biomass_B.png?raw=true&v=3d2df45029c9)

总生物量随时间步变化，带 95% 区间。与总丰度对照：小鱼体重小，所以生物量比丰度平滑，补充量脉冲要等年级群长大后才在生物量中显现。

Total biomass by time step with the 95% band. Read it next to total abundance: small fish weigh little, so biomass is smoother than abundance and a recruitment pulse appears in biomass only once the cohort has grown.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_biomass)



## 9. 生物量 BA / Biomass BA

```r
# 绘制本图 / Draw this figure
plot_biomass(b, type = "BA", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![生物量 BA / Biomass BA](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_biomass_BA.png?raw=true&v=b8101e73f537)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_biomass_BA.png?raw=true&v=b8101e73f537)

年龄别生物量，每个年龄组一个面板，纵轴各自取值，带 95% 区间。用它看生物量集中在哪些年龄；注意各面板的纵轴刻度，自由刻度会让数量很小的老龄组看起来和大的年轻组一样多变。

Biomass at age, one panel per age class with free vertical scales and the 95% band. Use it to see which ages hold the biomass; read the axis of each panel, because the free scales make a small old class look as variable as a large young one.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_biomass)



## 10. 生物量 BL / Biomass BL

```r
# 绘制本图 / Draw this figure
plot_biomass(b, type = "BL", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![生物量 BL / Biomass BL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_biomass_BL.png?raw=true&v=28b1f767c765)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_biomass_BL.png?raw=true&v=28b1f767c765)

体长别生物量，每个体长组一个面板，带 95% 区间。用它看生物量集中在哪些体长；本例 36 以上各组占大部分，它们在 2013 年后的上升是 2012 年级群长入大体长组。

Biomass at length, one panel per length bin with the 95% band. Use it to see which lengths hold the biomass; here the bins above 36 carry most of it, and their rise after 2013 is the 2012 cohort growing into the large bins.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_biomass)



## 11. 产卵生物量 SSB / Spawning biomass SSB

```r
# 绘制本图 / Draw this figure
plot_SSB(b, type = "SSB", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![产卵生物量 SSB / Spawning biomass SSB](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_SSB_SSB.png?raw=true&v=d3d36a38c338)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_SSB_SSB.png?raw=true&v=d3d36a38c338)

产卵生物量随时间步变化，带 95% 区间。用它作为资源状态序列：只有成熟鱼计入，所以它滞后于总生物量；本例 2010 年前后的低点之后才出现回升。

Spawning biomass by time step with the 95% band. Use it as the stock status series: only mature fish count, so it lags total biomass, and its low point around 2010 here comes before the recovery of the later years.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_SSB)



## 12. 产卵生物量 SBA / Spawning biomass SBA

```r
# 绘制本图 / Draw this figure
plot_SSB(b, type = "SBA", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![产卵生物量 SBA / Spawning biomass SBA](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_SSB_SBA.png?raw=true&v=d8d67e4ff498)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_SSB_SBA.png?raw=true&v=d8d67e4ff498)

年龄别产卵生物量，每个年龄组一个面板，带 95% 区间。用它看产卵来自哪些年龄；最小的几个年龄组接近零，因为成熟比例表几乎不给它们成熟个体，比较面板时看纵轴数值而不是曲线形状。

Spawning biomass at age, one panel per age class with the 95% band. Use it to see which ages spawn; the youngest classes sit near zero because the maturity table gives them almost no mature fish, so compare panels by their axis values rather than by the shape of the curves.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_SSB)



## 13. 产卵生物量 SBL / Spawning biomass SBL

```r
# 绘制本图 / Draw this figure
plot_SSB(b, type = "SBL", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![产卵生物量 SBL / Spawning biomass SBL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_SSB_SBL.png?raw=true&v=2f29017a0895)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_SSB_SBL.png?raw=true&v=2f29017a0895)

体长别产卵生物量，每个体长组一个面板，带 95% 区间。用它看产卵来自哪些体长；小体长组同样接近零，30 以上的成熟组走势与总产卵生物量一致。

Spawning biomass at length, one panel per length bin with the 95% band. Use it to see which lengths spawn; the small bins sit near zero for the same reason, and the mature bins above 30 follow the total spawning biomass.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_SSB)



## 14. 捕获尾数 CN / Catch numbers CN

```r
# 绘制本图 / Draw this figure
plot_catch(b, type = "CN", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![捕获尾数 CN / Catch numbers CN](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_catch_CN.png?raw=true&v=c03ee7bf1c85)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_catch_CN.png?raw=true&v=c03ee7bf1c85)

捕获尾数随时间步变化，带 95% 区间。捕获量由模型根据丰度和捕捞死亡率推算，YTF 数据没有渔获观测；用它与已知的渔获量对照，宽区间说明仅凭调查对捕获量的约束较弱。

Catch in numbers by time step with the 95% band. The model derives catch from abundance and fishing mortality, and the YTF data contain no catch observations; use it as a plausibility check against known landings, and read the wide band as the weak constraint the survey alone puts on catch.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_catch)



## 15. 捕获尾数 CNA / Catch numbers CNA

```r
# 绘制本图 / Draw this figure
plot_catch(b, type = "CNA", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![捕获尾数 CNA / Catch numbers CNA](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_catch_CNA.png?raw=true&v=0b5e6a3a5865)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_catch_CNA.png?raw=true&v=0b5e6a3a5865)

年龄别捕获尾数，每个年龄组一个面板，带 95% 区间。用它看渔业主要移除哪些年龄；本例捕获集中在 1 至 3 龄，因为小鱼数量多，老龄组的区间更宽。

Catch in numbers at age, one panel per age class with the 95% band. Use it to see which ages the fishery removes; the catch peaks at ages 1 to 3 here because the small fish are numerous, and the bands widen in the old ages.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_catch)



## 16. 捕获尾数 CNL / Catch numbers CNL

```r
# 绘制本图 / Draw this figure
plot_catch(b, type = "CNL", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

[![捕获尾数 CNL / Catch numbers CNL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_catch_CNL.png?raw=true&v=f03eacc1a60f)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_catch_CNL.png?raw=true&v=f03eacc1a60f)

体长别捕获尾数，每个体长组一个面板，带 95% 区间。与体长别捕捞死亡率对照：某组的捕获等于该组丰度与捕捞死亡率的乘积，F 高但捕获少的组只是鱼少。

Catch in numbers at length, one panel per length bin with the 95% band. Read it with the fishing mortality at length: catch in a bin is the product of abundance and fishing mortality there, so a bin with high F but little catch is one with few fish.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_catch)



## 17. 补充量 / Recruitment

```r
# 绘制本图 / Draw this figure
plot_recruitment(b, se = TRUE)
```

[![补充量 / Recruitment](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/recruitment.png?raw=true&v=f3b37834bb1a)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/recruitment.png?raw=true&v=f3b37834bb1a)

各时间步进入最小年龄组的补充量，带 95% 区间；纵轴标签为 `ylab$rec`。用它找强弱年级群：本例 2012 年的峰就是之后丰度和生物量上升的来源，它对应的日历时间取决于 `rec.age` 和时间步长。

Recruitment, the number entering the youngest age class at each time step, with the 95% band; the vertical label is `ylab$rec`. Use it to find strong and weak year classes: the 2012 peak here is the cohort behind the later rise in abundance and biomass, and its calendar position depends on `rec.age` and the time step.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_recruitment)



## 18. 亲体与补充关系 / Spawning biomass and recruitment

`age_at_recruitment` 的单位是年。`plot_SSB_Rec()` 除以拟合的 `growth_step`，要求在规则时间网格上对应整数个时间步。季度数据中，0.25 表示滞后一季度，1 表示四季度。允许零滞后；拒绝负值、非有限值及非整数步滞后。没有 `growth_step` 的结果使用规则年份间隔；两类时间元数据都没有时沿用年度步长。

`age_at_recruitment` is in years. `plot_SSB_Rec()` divides it by the fit's `growth_step` and requires an integer lag on a regular time grid. With quarterly data, 0.25 means one step and 1 means four steps. Zero lag is allowed; negative, nonfinite and fractional-step lags are rejected. Results without `growth_step` use their regular time spacing, or an annual step when `year` is missing as well.

```r
# 绘制本图 / Draw this figure
plot_SSB_Rec(b, age_at_recruitment = 1)
```

[![亲体与补充关系 / Spawning biomass and recruitment](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/SSB_Rec.png?raw=true&v=1ba690a33945)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/SSB_Rec.png?raw=true&v=1ba690a33945)

横轴为某时间步的产卵生物量，纵轴为 `age_at_recruitment` 年后的补充量，每对一点，不拟合曲线。用它看补充量是否随产卵生物量变化；本例各点没有关系，这在意料之中，因为模型逐时间步自由估计补充量，而不用亲体补充函数。

A scatter of spawning biomass at one time step (horizontal) against recruitment `age_at_recruitment` years later (vertical), one point per pair and no fitted curve. Use it to see whether recruitment follows spawning biomass; the points here show no relation, which is expected because the model estimates recruitment freely at each time step instead of through a stock recruitment function.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_SSB_Rec)



<a id="chapter-09"></a>
## 09 生长、死亡与残差图 · Growth, mortality and residuals

先完成第 04 章的 YTF 拟合，得到 `a`、`b`、`x`、`inputs`，并设置 `dat <- x$data.CatL`。加载 ggplot2 和 patchwork。第 11 章建立回溯对象 `ra/rb`。
First complete chapter 04, define `dat <- x$data.CatL`, and load ggplot2 and patchwork. Chapter 11 defines retrospective objects.

```r
library(ggplot2)
library(patchwork)
acl_theme_set(palette="npg", base_theme="theme_bw")
```

## 19. 生长曲线与区间 / Growth curve and interval

```r
# 绘制本图 / Draw this figure
plot_VB(b, se = TRUE)
```

[![生长曲线与区间 / Growth curve and interval](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/VB.png?raw=true&v=e2a1e504fa32)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/VB.png?raw=true&v=e2a1e504fa32)

由拟合的 `Linf`、`k`、`t0`（角上标注）得到的 von Bertalanffy 体长随年龄曲线；`se = TRUE` 时按参数协方差加上 95% 区间。本例生长参数固定，区间宽度为零；估计生长时区间表示年龄别平均体长的参数不确定性，不是个体体长的分布，老龄处区间很宽说明 `Linf` 难以确定。

The von Bertalanffy curve of length against age from the fitted `Linf`, `k` and `t0` (printed in the corner); `se = TRUE` adds a 95% band from the parameter covariance. Growth is fixed in this example, so the band has zero width; with estimated growth the band is parameter uncertainty about the mean length at age, not the spread of individual lengths, and a wide band at old ages means `Linf` is poorly determined.

`age_range = NULL` 时绘制拟合的年龄范围，起点不早于 `t0`；显式 `age_range` 必须是两个递增的有限年龄，且不早于 `t0`。若 `se = TRUE` 但参数协方差不可用，函数会警告并只画曲线，保留传入的标签、字号、刻度和主题。

`age_range = NULL` draws the fitted age range, starting no earlier than `t0`; an explicit `age_range` must be two increasing finite ages at or after `t0`. If `se = TRUE` but the parameter covariance is unavailable, the function warns and draws the curve alone, keeping the labels, text sizes, breaks and theme you passed.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_VB)



## 20. 年龄—体长概率矩阵 / Age–length probability matrix

```r
# 绘制本图 / Draw this figure
plot_pla(b) + scale_x_discrete(labels = as.character(1:15))
```

[![年龄—体长概率矩阵 / Age–length probability matrix](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/pla.png?raw=true&v=3f17714c7721)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/pla.png?raw=true&v=3f17714c7721)

年龄体长概率矩阵 `pla` 的热图：每列一个年龄组，每行一个体长组，颜色为该年龄的鱼落入该体长组的概率，每列之和为 1；代码把横轴改标为年龄组序号 1 至 15。用它看体长对年龄的区分度；对角带随年龄变宽是因为生长放慢、体长重叠，老龄在最大体长组的深色格是聚集所有老鱼的加和组。

A heat map of the age length probability matrix `pla`: one column per age class, one row per length bin, and the fill is the probability that a fish of that age falls in that bin, so each column sums to one; the code relabels the age axis with the class index 1 to 15. Use it to see how well length identifies age; the diagonal band widens with age because growth slows and lengths overlap, and the dark cells in the largest bin at old ages are the plus group collecting all old fish.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_pla)



## 21. ACL 捕捞死亡率 year / ACL fishing mortality year

`plot_fishing_mortality()` 从 `acl_theme_set()` 取标题、坐标轴标签、`x_breaks` 和 `x_expand`：标题键为 `F_year`、`F_age`、`F_length`，区间图加 `_se`；标签为 `xlab$year`、`xlab$age` 或 `xlab$length` 以及 `ylab$F`。年龄模式的横坐标是年龄组的位置，所以未设置 `xlab$age` 时默认标签为 Age group；调用中给出的标签和刻度优先。`base_theme` 接受 `"theme_bw"`、`"bw"` 等主题名、ggplot2 主题对象或 `NULL`（全局设置），各种情况下都不显示网格线。

`plot_fishing_mortality()` takes its title, axis labels, `x_breaks` and `x_expand` from `acl_theme_set()`: title keys `F_year`, `F_age` and `F_length`, with `_se` added for interval plots, and labels `xlab$year`, `xlab$age` or `xlab$length` and `ylab$F`. In age mode the horizontal coordinate is the position of the age class, so the default label reads Age group unless you set `xlab$age`; labels and breaks given in the call take precedence. `base_theme` accepts a theme name such as `"theme_bw"` or `"bw"`, a ggplot2 theme object, or `NULL` for the global setting, and gridlines stay hidden in every case.

```r
# 绘制本图 / Draw this figure
plot_fishing_mortality(a, type = "year",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ACL 捕捞死亡率 year / ACL fishing mortality year](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ACL_year.png?raw=true&v=12c599aa4391)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ACL_year.png?raw=true&v=12c599aa4391)

ACL 拟合的捕捞死亡率 `F`，每个年龄组一个面板，横轴为时间，带 95% 区间（`se = TRUE`）；`F` 是每个时间步的瞬时率，季度拟合显示的是季度率。用它看捕捞压力何时变化：本例 2008 年的峰出现在大多数年龄组，13 至 15 龄的宽区间说明调查对老龄鱼的信息很少。

Fishing mortality `F` of the ACL fit, one panel per age class, time on the horizontal axis and the 95% band (`se = TRUE`); `F` is an instantaneous rate per time step, so a quarterly fit shows quarterly rates. Use it to see when fishing pressure changed: the 2008 peak here appears in most age classes, and the wide bands at ages 13 to 15 show how little the survey says about old fish.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)



## 22. ACL 捕捞死亡率 age / ACL fishing mortality age

```r
# 绘制本图 / Draw this figure
plot_fishing_mortality(a, type = "age",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ACL 捕捞死亡率 age / ACL fishing mortality age](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ACL_age.png?raw=true&v=d94d92433096)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ACL_age.png?raw=true&v=d94d92433096)

同一组 `F` 按年龄排列：每个时间步一个面板，横轴为年龄组序号（标为 Age group，因为坐标是组的位置），带 95% 区间。用它读每个时间步渔业的选择模式；本例近乎水平的线说明 ACL 拟合对各年龄施加相近的死亡率，若呈穹形或斜坡则显示渔具主要捕哪些年龄。

The same `F` values arranged by age: one panel per time step, the age class index on the horizontal axis (labelled Age group because the coordinate is the class position), with the 95% band. Use it to read the selection pattern of the fishery at each time step; a flat line, as here, means the ACL fit applies similar mortality to all ages, and a dome or ramp would show which ages the gear takes.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)



## 23. ALSCL 捕捞死亡率 year / ALSCL fishing mortality year

```r
# 绘制本图 / Draw this figure
plot_fishing_mortality(b, type = "year",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ALSCL 捕捞死亡率 year / ALSCL fishing mortality year](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_year.png?raw=true&v=098d37cae7d1)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_year.png?raw=true&v=098d37cae7d1)

ALSCL 拟合的体长别捕捞死亡率 `FL`，每个体长组一个面板，横轴为时间，带 95% 区间。用它看各体长组的捕捞压力何时变化；本例 2008 年的峰在 20 至 34 组最强，44 以上各组的 F 最低，因为该体长的鱼很少被捕。

Fishing mortality at length `FL` of the ALSCL fit, one panel per length bin, time on the horizontal axis and the 95% band. Use it to see when pressure changed in each length bin; the 2008 peak is strongest in bins 20 to 34 here, and the bins above 44 have the lowest F because few fish of that size are taken.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)



## 24. ALSCL 捕捞死亡率 age / ALSCL fishing mortality age

```r
# 绘制本图 / Draw this figure
plot_fishing_mortality(b, type = "age",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ALSCL 捕捞死亡率 age / ALSCL fishing mortality age](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_age.png?raw=true&v=80c608c9f9b8)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_age.png?raw=true&v=80c608c9f9b8)

ALSCL 拟合的年龄别捕捞死亡率 `FA`，由 `FL` 经年龄体长矩阵换算：每个时间步一个面板，横轴为年龄组序号，带 95% 区间；`FA` 在相邻时间步之间计算，所以比体长图少一个时间步和一个年龄。用它与 ACL 的年龄图比较选择模式；本例在 3 龄达到峰值的穹形，就是体长别 F 映射到对应年龄后的结果。

Fishing mortality at age `FA` of the ALSCL fit, derived from `FL` through the age length matrix: one panel per time step, the age class index on the horizontal axis, with the 95% band; there is one time step and one age fewer than in the length figures because `FA` is computed between consecutive steps. Use it to compare the ALSCL selection with the ACL age figure; the dome peaking at age 3 here is the length-based F mapped onto the ages that have those lengths.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)



## 25. ALSCL 捕捞死亡率 length / ALSCL fishing mortality length

```r
# 绘制本图 / Draw this figure
plot_fishing_mortality(b, type = "length",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ALSCL 捕捞死亡率 length / ALSCL fishing mortality length](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_length.png?raw=true&v=2afc5a8f35d0)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_length.png?raw=true&v=2afc5a8f35d0)

同一组 `FL` 按体长排列：每个时间步一个面板，横轴为体长组中点 `len_mid`（不等宽组表现为不等间距），带 95% 区间。用它读每个时间步渔业的体长选择；本例 20 至 35 之间的穹形是渔具捕捞的体长范围，各面板穹形的高低就是时间效应。

The same `FL` values arranged by length: one panel per time step, the length bin midpoints `len_mid` on the horizontal axis (unequal bins show as unequal spacing), with the 95% band. Use it to read the length selection of the fishery at each time step; the dome between lengths 20 and 35 here is the size the gear takes, and its height from panel to panel is the time effect.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)



## 26. 对数残差 length / Log residuals length

```r
# 绘制本图 / Draw this figure
plot_residuals(b, facet_by = "length", facet_ncol = 4, line_size = 0.6,
  x_breaks = c(2000, 2010, 2015))
```

[![对数残差 length / Log residuals length](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/residuals_length.png?raw=true&v=649d9ca9500a)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/residuals_length.png?raw=true&v=649d9ca9500a)

对数残差，即观测对数调查指数减拟合值，每个体长组一个面板，横轴为时间：深蓝线连接残差，灰线为零，青绿色虚线为平滑线（有观测的时间步少于 6 个时用线性，否则用 loess）。用它找模型拟合不好的体长组（零值和缺失观测没有残差）；多年同号的残差（如本例 16 组为正、20 组为负）说明系统性偏差，序列末端的趋势（如 50 组）提示模型没有跟上的变化。

Log residuals, the observed minus the fitted log survey index, one panel per length bin with time on the horizontal axis: the navy line joins the residuals, the grey line is zero and the dashed teal curve is a smoother (linear with fewer than six observed time steps, loess otherwise). Use it to find bins the model misfits (zero and missing observations have no residual); residuals of one sign over many years, as in bins 16 (positive) and 20 (negative) here, mean a systematic misfit, and a trend at the end of the series, as in bin 50, points to a change the model misses.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_residuals)



## 27. 对数残差 year / Log residuals year

```r
# 绘制本图 / Draw this figure
plot_residuals(b, facet_by = "year", facet_ncol = 4, line_size = 0.6,
  x_breaks = c(10, 30, 50))
```

[![对数残差 year / Log residuals year](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/residuals_year.png?raw=true&v=d23449a96976)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/residuals_year.png?raw=true&v=d23449a96976)

同一组残差按体长排列：每个时间步一个面板，横轴为体长，带零线和平滑线。用它看一个时间步内的偏差是否随体长变化；本例 2015 年起最大体长组的正尖峰说明那几年调查看到的大鱼多于拟合，平滑线每年在同一体长穿过零线则是模型系统性放错的体长。

The same residuals arranged by length: one panel per time step, length on the horizontal axis, with the zero line and the smoother. Use it to see whether misfit has a length pattern within a time step; the positive spike at the largest bin from 2015 on here means the survey saw more large fish than the fit in those years, and a smoother that crosses zero at the same length every year marks a length the model systematically misplaces.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_residuals)



## 28. 对数过程偏差 R / Log process deviations R

```r
# 绘制本图 / Draw this figure
plot_deviance(b, type = "R", log = TRUE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![对数过程偏差 R / Log process deviations R](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_R_TRUE.png?raw=true&v=e16626d72746)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_R_TRUE.png?raw=true&v=e16626d72746)

补充量的对数过程偏差（模型的随机效应，不是似然偏差）随时间步变化：点为估计值，误差棒为 95% 区间，零对应平均补充量。用它看调查支持的年级群信号；本例 2000 至 2008 年的连续负值是低于平均的补充量，若误差棒都跨过零线，说明调查几乎没有补充量信息。

Log process deviations of recruitment (the random effects of the model, not a likelihood deviance) by time step: points are the estimates, the error bars their 95% intervals, and zero is mean recruitment. Use it to see the year-class signal the survey supports; the negative run from 2000 to 2008 here is below-average recruitment, and error bars that all cross zero would mean the survey carries little recruitment information.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_deviance)



## 29. 过程乘数 R / Process multipliers R

```r
# 绘制本图 / Draw this figure
plot_deviance(b, type = "R", log = FALSE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![过程乘数 R / Process multipliers R](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_R_FALSE.png?raw=true&v=f5ffcc3325be)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_R_FALSE.png?raw=true&v=f5ffcc3325be)

同一组偏差取指数（`log = FALSE`）：纵轴为补充量乘数，1 对应平均值，区间不对称，因为它们是对数区间取指数的结果。用它把偏差读成倍数；本例 2012 年约 1.7 表示补充量高于平均 70%，它与对数图是同一拟合过程，按读者要读取的量选择尺度。

The same deviations exponentiated (`log = FALSE`): the vertical axis is the recruitment multiplier, one is the mean, and the intervals are asymmetric because they are exponentiated log intervals. Use it to read a deviation as a factor; the 2012 value of about 1.7 here means recruitment 70% above the mean, and it is the same fitted process as the log figure, so choose the scale by what the reader needs to read off.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_deviance)



## 30. 对数过程偏差 F / Log process deviations F

```r
# 绘制本图 / Draw this figure
plot_deviance(b, type = "F", log = TRUE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![对数过程偏差 F / Log process deviations F](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_F_TRUE.png?raw=true&v=6168d9ff70db)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_F_TRUE.png?raw=true&v=6168d9ff70db)

捕捞死亡率的对数过程偏差，每个体长组一个面板（ACL 为每个年龄组，共享 F 时只有一个面板），点、95% 误差棒和作为平均值的零线。用它看拟合的 F 在各组、各时间步偏离平均的程度；本例小、中体长组为正，40 以上为负，即模型抬高了 40 以下的 F、压低了 40 以上的 F，36 至 50 组在 2012 年前后的下陷与 F 图中该处的低值一致。

Log process deviations of fishing mortality, one panel per length bin (per age class for ACL, a single panel for a shared F), with points, 95% error bars and zero as the mean. Use it to see how the fitted F departs from its mean in each bin and time step; here the deviations are positive in the small and middle bins and negative above length 40, so the model raises F below 40 and lowers it above, and the dip around 2012 in bins 36 to 50 matches the low F there in the F figures.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_deviance)



## 31. 过程乘数 F / Process multipliers F

```r
# 绘制本图 / Draw this figure
plot_deviance(b, type = "F", log = FALSE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![过程乘数 F / Process multipliers F](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_F_FALSE.png?raw=true&v=db5ced1d53d0)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_F_FALSE.png?raw=true&v=db5ced1d53d0)

同一组 F 偏差改为乘数（`log = FALSE`），1 为平均值，区间不对称。用它把偏离读成 F 的倍数；本例 48 组 2012 年前后约 0.5 表示 F 为平均值的一半，区间宽窄与对数尺度对应，两张图对哪些格不确定的判断一致。

The same F deviations as multipliers (`log = FALSE`), with one as the mean and asymmetric intervals. Use it to read the departure as a factor on F; a value of 0.5 in bin 48 around 2012 here means F at half its mean, and the interval widths carry over from the log scale, so the two figures agree on which cells are uncertain.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_deviance)



## 32. 长度组成山脊图 / Length composition ridges

```r
# 绘制本图 / Draw this figure
plot_ridges(b) # 默认 viridis 渐变 / Default viridis gradient
```

[![长度组成山脊图 / Length composition ridges](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/ridges.png?raw=true&v=5be1df0903c5)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/ridges.png?raw=true&v=5be1df0903c5)

调查指数的体长组成，每个时间步一条山脊（最早在底部，颜色按时间步取 viridis 渐变），横轴为体长：左图为观测，右图为拟合，每条山脊归一化为和为 1，所以高度只比较形状。用它检查拟合是否再现每个时间步的峰位和展布；本例 2012 年后峰从 20 向 25 移动是强年级群在生长，没有调查数据的时间步没有观测山脊，部分观测的时间步只在有观测的体长组内归一化。

Length compositions of the survey index, one ridge per time step (earliest at the bottom, colour by time step from the viridis gradient) with length on the horizontal axis: the left panel is observed, the right panel fitted, and each ridge is normalized to sum to one, so ridge height compares shape only. Use it to check that the fit reproduces the mode and spread of each time step; the mode moving from length 20 toward 25 after 2012 here is the strong cohort growing, a time step without survey data has no observed ridge, and a partly observed time step is normalized over the observed bins only.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_ridges)



<a id="chapter-10"></a>
## 10 模型比较与真值 · Model comparisons

先完成第 04 章的 YTF 拟合，得到 `a`、`b`、`x`、`inputs`，并设置 `dat <- x$data.CatL`。加载 ggplot2 和 patchwork。第 11 章建立回溯对象 `ra/rb`。
First complete chapter 04, define `dat <- x$data.CatL`, and load ggplot2 and patchwork. Chapter 11 defines retrospective objects.

```r
library(ggplot2)
library(patchwork)
acl_theme_set(palette="npg", base_theme="theme_bw")
```

## 33. 种群时间序列比较 / Population time series comparison

```r
# 绘制本图 / Draw this figure
plot_compare_ts(a, b, se = TRUE, facet_ncol = 2)
```

[![种群时间序列比较 / Population time series comparison](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_ts.png?raw=true&v=6e0c7883ce7f)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_ts.png?raw=true&v=6e0c7883ce7f)

两组拟合的产卵生物量、补充量、总生物量、总丰度和捕获尾数时间序列，每个量一个面板，纵轴各自取值：ACL 为深蓝实线，ALSCL 为朱红虚线（`compare_colors`、`compare_linetypes`），`se = TRUE` 时加上各自的 95% 区间。用它看两个模型在哪里分歧；本例生物量和产卵生物量在 2014 年后分开，自由纵轴使振幅只能在面板内比较，不能跨面板比较。

Time series of spawning biomass, recruitment, total biomass, total abundance and catch in numbers from two fits, one panel per quantity with its own vertical scale: ACL is the navy solid line and ALSCL the vermilion dashed line (`compare_colors`, `compare_linetypes`), and `se = TRUE` adds each fit's 95% band. Use it to see where the two models disagree; the ACL and ALSCL series separate after 2014 in biomass and spawning biomass here, and the free vertical scales make amplitudes comparable within a panel but not across panels.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_compare_ts)



## 34. 死亡率矩阵比较 / Fishing mortality matrices

```r
# 绘制本图 / Draw this figure
plot_compare_F(a, b) + scale_x_continuous(breaks = c(2000, 2010, 2019))
```

[![死亡率矩阵比较 / Fishing mortality matrices](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_F.png?raw=true&v=545b8b47191d)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_F.png?raw=true&v=545b8b47191d)

两组拟合各一张捕捞死亡率热图，横轴为时间，纵轴为各自的组（ACL 为年龄组，ALSCL 为体长组），共用一个 `F` 色标。用它看每个模型中捕捞在何时、哪些组最重；两图的行是不同维度，所以比较深色列的时间（本例 2007 至 2010 年）而不是逐格比较，一对一的比较用总体 F 图。

Heat maps of fishing mortality, one per fit, time on the horizontal axis and the fit's own groups on the vertical axis (age classes for ACL, length bins for ALSCL) with one colour scale for `F`. Use it to see when and in which groups fishing was heaviest in each model; the rows are different dimensions, so compare the timing of the dark columns (2007 to 2010 here) rather than single cells, and use the summary F figures for a one-to-one comparison.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_compare_F)



## 35. 残差联合诊断 / Combined residual diagnostics

```r
# 绘制本图 / Draw this figure
plot_compare_residuals(a, b, dat)
```

[![残差联合诊断 / Combined residual diagnostics](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_residuals.png?raw=true&v=f97bb9ff3e81)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_residuals.png?raw=true&v=f97bb9ff3e81)

两组拟合的样本内对数残差四联图：直方图、对正态分布的 QQ 图、各时间步的平均残差及加减一个标准差的误差棒（不是置信区间）、各体长组绝对残差的箱线图；ACL 为深蓝，ALSCL 为朱红。用它判断哪组拟合留下的结构更少：直方图更宽、QQ 点偏离直线表示残差更大（本例的 ALSCL），高箱体标出该拟合偏差大的体长组（本例 ALSCL 的 16 组和 50 组）。

Four panels of the in-sample log residuals of both fits: a histogram, a QQ plot against the normal distribution, the mean residual by time step with bars of plus or minus one standard deviation (not a confidence interval), and box plots of absolute residuals by length bin; ACL is navy and ALSCL vermilion. Use it to judge which fit leaves less structure: a wider histogram and QQ points off the line mean larger residuals, as for ALSCL here, and a tall box marks a bin that fit misfits, as bins 16 and 50 for ALSCL.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_compare_residuals)



## 36. 生长与外部参照接口 / Growth and reference-data interface

参考数据与排版辅助函数 / Reference data and layout helper:

```r
# 模拟参考生长点，并非论文实测 / Synthetic reference points, not paper observations
set.seed(42)
ref <- data.frame(Age = rep(1:15, each = 5))
ref$Length <- VB_func(60, .2, 1/60, ref$Age) + rnorm(nrow(ref), 0, 2)
growth_display <- function(p) {
  p[[1]] <- p[[1]] + labs(subtitle = paste(strsplit(
    p[[1]]$labels$subtitle, " | ", fixed=TRUE)[[1]], collapse="\n")) +
    theme(legend.text=element_text(size=7))
  p[[2]] <- p[[2]] + scale_x_continuous(breaks=c(1,5,10,15))
  p
}
```

```r
# 绘制本图 / Draw this figure
growth_display(plot_compare_growth(a, b, age_range = c(1, 15), ref_data = ref, ref_name = "Synthetic reference",
    nls_start = list(Linf = 60, k = 0.2, t0 = 1/60)))
```

[![生长与外部参照接口 / Growth and reference-data interface](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_growth.png?raw=true&v=df436a02744c)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_growth.png?raw=true&v=df436a02744c)

左图：两组拟合的 von Bertalanffy 曲线（ACL 深蓝实线，ALSCL 朱红虚线），副标题给出各自的 `Linf` 和 `k`，另有 `nls()` 对 `ref_data` 拟合的灰色参照曲线及该数据的灰点；右图：两组拟合的年龄体长矩阵热图，纵轴为体长组序号。用它看两个模型是否假设相同的生长，以及它们与独立年龄体长数据的差距；本例两条曲线重合，因为生长固定为相同值，参照数据由上面的代码生成，是模拟值而非实测。

Left: the von Bertalanffy curves of both fits (ACL navy solid, ALSCL vermilion dashed) with their `Linf` and `k` in the subtitle, the grey reference curve that `nls()` fits to `ref_data`, and the grey points of that data; right: the age length matrices of both fits as heat maps, with the length bin index on the vertical axis. Use it to see whether the two models assume the same growth and how they differ from independent age length data; the curves coincide here because growth is fixed at the same values, and the reference data come from the code above, so they are simulated values rather than measurements.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_compare_growth)



## 37. 两模型调查拟合 / Survey fits from both models

```r
# 绘制本图 / Draw this figure
plot_compare_CatL(a, b, dat, years = c(2000, 2005, 2010, 2015), facet_ncol = 2)
```

[![两模型调查拟合 / Survey fits from both models](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_CatL.png?raw=true&v=06278fecb8b7)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_CatL.png?raw=true&v=06278fecb8b7)

所选时间步（`years`，省略则显示全部）的调查指数随体长变化，每个时间步一个面板：灰点为观测指数，深蓝实线为 ACL 拟合，朱红虚线为 ALSCL 拟合，均为 `exp(Elog_index)` 中位数，零值和缺失观测不画点。用它看哪个模型跟得上观测的体长组成；本例两者都跟上 20 附近的峰，ALSCL 曲线起伏更多，因为它的 F 按体长组变化。

Survey index against length for the selected time steps (`years`; omit it for all), one panel per time step: grey points are the observed index, the navy solid curve the ACL fit and the vermilion dashed curve the ALSCL fit, both as `exp(Elog_index)` medians, and zero and missing observations are left out of the points. Use it to see which model follows the observed length composition; both follow the mode near length 20 here, and the ALSCL curve wiggles more because its F varies by length bin.

纵轴标签来自 `ylab$survey`，默认为 Survey index；用 `acl_theme_set(ylab = list(survey = "Survey index (relative units)"))` 可一次改好所有调查拟合图的标签，单模型对数图会加上前缀 Log。`ylab$catch` 只用于捕获量图。

The vertical label comes from `ylab$survey` and reads Survey index by default; set `acl_theme_set(ylab = list(survey = "Survey index (relative units)"))` to relabel every survey-fit plot at once, and single-model log-scale plots add the prefix Log. `ylab$catch` labels the catch plots only.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_compare_CatL)



## 38. 拟合指标比较 / Fit metric comparison

```r
# 绘制本图 / Draw this figure
plot_compare_metrics(a, b, dat, facet_ncol = 2) & scale_y_continuous(expand = expansion(mult = c(0,
    0.3)))
```

[![拟合指标比较 / Fit metric comparison](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_metrics.png?raw=true&v=f429da60dffc)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_metrics.png?raw=true&v=f429da60dffc)

两组拟合由 `diagnostic_metrics()` 得到的拟合指标柱图：RMSE 与 MAE、R 平方、MAPE、AIC、BIC 与负对数似然、标量参数个数，柱上标数值；ACL 深蓝，ALSCL 朱红。用它概括拟合质量：误差指标和信息准则越低、R 平方越高越好，本例 ACL 更好在意料之中，因为数据由年龄模型生成；信息准则只能在同一数据、同一似然的拟合之间比较。

Bars of the fit metrics of both fits from `diagnostic_metrics()`: RMSE and MAE, R-squared, MAPE, AIC, BIC and the negative log-likelihood, and the number of scalar parameters, with the value printed on each bar; ACL navy, ALSCL vermilion. Use it to summarize fit quality: lower error metrics and information criteria and a higher R-squared are better, so ACL fits better here, which is expected because the data were generated by an age-based model, and information criteria are comparable only between fits of the same data with the same likelihood.

柱图与 `diagnostic_metrics()` 使用同一计算：只纳入有限的正观测，观测单元处的非有限预测或维度不一致会报错，常数观测的 R 平方等无定义指标显示为 `NA`。先运行 `compare_models()` 核对两组拟合是否可比。

The bars use the same calculation as `diagnostic_metrics()`: only finite positive observations enter, a nonfinite prediction at an observed cell or a dimension mismatch is an error, and an undefined measure such as R-squared for constant observations is shown as `NA`. Run `compare_models()` first to check that the two fits are comparable.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_compare_metrics)



## 39. 固定调查可捕性 / Fixed survey catchability

```r
# 绘制本图 / Draw this figure
plot_compare_selectivity(a, b)
```

[![固定调查可捕性 / Fixed survey catchability](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_selectivity.png?raw=true&v=8910454b5721)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_selectivity.png?raw=true&v=8910454b5721)

各拟合输入的体长别调查可捕性 `q`（`sel_L50`、`sel_L95`），ACL 为深蓝实线加点，ALSCL 为朱红虚线加点。用它确认每组拟合用的可捕性曲线；本例两条曲线重合，因为输入相同；这些值是固定输入而不是估计的选择性，两组拟合若不同，只说明输入不同。

Survey catchability `q` at length from the input of each fit (`sel_L50`, `sel_L95`), as lines with points for ACL (navy solid) and ALSCL (vermilion dashed). Use it to confirm which catchability curve each fit used; the curves coincide here because both fits took the same input, and the values are fixed inputs, not an estimated selectivity, so a difference between two fits means different inputs.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_compare_selectivity)



## 40. 总体 F 比较 apical / Summary F comparison apical

```r
# 绘制本图 / Draw this figure
plot_compare_F_ts(a, b, method = "apical") +
  labs(title = "Apical fishing mortality")
```

[![总体 F 比较 apical / Summary F comparison apical](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_F_apical.png?raw=true&v=04d0e9ec5dd1)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_F_apical.png?raw=true&v=04d0e9ec5dd1)

两组拟合的顶点捕捞死亡率，即每个时间步各组 `F` 的最大值（ACL 深蓝实线，ALSCL 朱红虚线，每个时间步一点）；`labs(title = ...)` 替换默认标题。用它在同一坐标上比较年龄模型与体长模型的总体捕捞压力；本例 ALSCL 更高，因为它的最大值落在选择性最强的体长组；函数名虽含 annual，但汇总在每个时间步内进行，季度拟合显示的仍是季度率。

Apical fishing mortality, the maximum of `F` over the groups at each time step, for both fits (ACL navy solid, ALSCL vermilion dashed, a point at each time step); the `labs(title = ...)` call replaces the default title. Use it to compare overall fishing pressure between an age-based and a length-based fit on one axis; ALSCL is higher here because its maximum sits in the most selected length bins, and despite the function name a quarterly fit keeps quarterly rates, because the summary is taken within each time step.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_compare_F_ts)



## 41. 总体 F 比较 mean / Summary F comparison mean

```r
# 绘制本图 / Draw this figure
plot_compare_F_ts(a, b, method = "mean") +
  labs(title = "Mean fishing mortality")
```

[![总体 F 比较 mean / Summary F comparison mean](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_F_mean.png?raw=true&v=25c951b5bd17)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_F_mean.png?raw=true&v=25c951b5bd17)

两组拟合的平均捕捞死亡率，即每个时间步各组 `F` 的非加权平均，样式同上。当关心整个选择模式而不是其峰值时用它；平均值取决于模型有多少低 F 的组（本例 15 个年龄组对 23 个体长组），所以看时间模式（两者都在 2008 年达峰）而不是水平高低。

Mean fishing mortality, the unweighted average of `F` over the groups at each time step, for both fits in the same styling. Use it when the whole selection pattern matters more than its peak; the mean depends on how many low-F groups a model has (15 ages against 23 length bins here), so read the time pattern, which both fits share with a 2008 peak, rather than the level.

[参数及默认值 / Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_compare_F_ts)



## 44. 模拟真值与条件估计 / Simulation truth and conditional estimates

```r
# 将生成真值与报告中的估计对齐 / Align truth and fitted reports
years <- a$year
truth <- data.frame(Year=rep(years,3),
  Quantity=rep(c("B","SSB","Rec"),each=length(years)),
  Truth=c(x$truth$TB,x$truth$SSB,x$truth$Rec))
estimates <- rbind(
  data.frame(Year=rep(years,3),Quantity=truth$Quantity,
    Value=c(a$report$B,a$report$SSB,a$report$Rec),Model="ACL"),
  data.frame(Year=rep(years,3),Quantity=truth$Quantity,
    Value=c(b$report$B,b$report$SSB,b$report$Rec),Model="ALSCL"))
```

```r
# 绘制本图 / Draw this figure
ggplot(estimates, aes(Year, Value, color = Model)) + geom_line() + scale_color_manual(values = setNames(acl_theme("compare_colors"),
    c("ACL", "ALSCL"))) + geom_line(data = truth, aes(Year, Truth), inherit.aes = FALSE, linetype = 2) +
    facet_wrap(~Quantity, scales = "free_y", ncol = 1) + theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank()) + labs(y = NULL)
```

[![模拟真值与条件估计 / Simulation truth and conditional estimates](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/truth.png?raw=true&v=a10cc16cca33)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/truth.png?raw=true&v=a10cc16cca33)

生成模拟的生物量、补充量和产卵生物量（黑色虚线）与 ACL（深蓝）、ALSCL（朱红）拟合的对照，每个量一个面板；上面的代码由 `x$truth` 和两份报告构造 `truth` 与 `estimates`。只在模拟数据上用它看哪组拟合更接近真值；本例 ACL 紧贴虚线，因为数据来自同样固定生物参数的年龄模型，ALSCL 的生物量和产卵生物量在 2012 年后低于真值，与时间序列比较图中的差距相同。

Biomass, recruitment and spawning biomass of the generating simulation (black dashed) against the ACL (navy) and ALSCL (vermilion) fits, one panel per quantity; the code above builds `truth` and `estimates` from `x$truth` and the two reports. Use it, with simulated data only, to see which fit recovers the truth; ACL tracks the dashed line closely because the data came from an age-based model with the same fixed biology, and ALSCL falls below it after 2012 in biomass and spawning biomass, the same gap as in the time series comparison.



<a id="chapter-11"></a>
## 11 回溯分析 · Retrospectives

读完本页，你会得到每个模型的 Mohn rho（生物量、产卵生物量、补充量和丰度）、重拟合序列的图和每次重拟合的数值检查。你需要[理解第一次拟合](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin)中的输入列表 `x` 和 ALSCL 拟合结果 `b`。

At the end of this page you have, for each model, Mohn's rho for biomass, spawning biomass, recruitment and abundance, a plot of the refitted series and the numerical checks of every refit. You need the input bundle `x` and the ALSCL fit `b` from [Understand your first fit](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin).

回溯分析从三张表中去掉最后一个时间步并重拟合模型，再去掉一个，再拟合，依此类推；每次截短重拟合称为一轮。把各轮与完整拟合比较，就能看出加入后来的观测后近期估计改变了多少；每一轮都朝同一方向移动的估计很可能再次被修订。

A retrospective analysis removes the last time step from the three tables, refits the model, removes one more, refits again, and so on; each refit is a peel. Comparing the peels with the full fit shows how much the recent estimates change when later observations are added; estimates that move in the same direction at every peel are likely to be revised again.

<a id="retrospectives-run"></a>

### 1. 运行分析 / Run the analysis

```r
ra <- retro_acl(x, nyear = 3, silent = TRUE)
rb <- retro_alscl(x, nyear = 3, silent = TRUE)
```

`retro_acl()` 使用 ACL 模型，`retro_alscl()` 使用 ALSCL 模型。每次调用先用完整的数据表拟合模型，再运行 `nyear` 轮：第 1 轮去掉最后一个时间步并重拟合，第 2 轮去掉最后两个，依此类推。`nyear` 以时间步计数，季度数据一年有四个时间步。

`retro_acl()` uses the ACL model and `retro_alscl()` the ALSCL model. Each call fits the model to the full tables, then runs `nyear` peels: peel 1 drops the last time step and refits, peel 2 drops the last two, and so on. `nyear` counts time steps, four per year for quarterly data.

每次拟合都使用输入列表中保存的设置，与 `run_acl(x)` 相同，初值个数为列表中显式保存的 `nstarts`，没有保存时为一个；调用时给出的参数会对每次拟合覆盖保存的值。`ncores` 让各轮在工作进程上运行；输入列表中保存的拟合用 `ncores` 会被忽略，一次拟合内部的多个初值依次运行。`silent = FALSE` 时控制台每次拟合打印一行。

Every fit uses the settings stored in the bundle, as `run_acl(x)` does, with the bundle's explicit `nstarts` starts or one start when it stores none; arguments in the call override them for every fit. `ncores` runs the peels on worker processes; a fitting `ncores` stored in the bundle is ignored, and the starts inside one fit run one after another. With `silent = FALSE` the console prints one line per fit.

有两种错误会在任何拟合开始之前终止调用：调查指数表的时间列必须带有递增的数字标签（[准备调查数据](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel)），并且每一轮都必须至少保留两个时间步，所以 `nyear` 最多为时间步数减二。某一轮在优化器内部失败时会记录在下一步的表中，分析继续进行。

Two errors stop the call before any fit: the time columns of the survey index table must carry increasing numeric labels ([Prepare your survey data](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel)), and every peel must keep at least two time steps, so `nyear` is at most the number of time steps minus two. A peel that fails inside the optimizer is recorded in the next step's tables while the analysis continues.

<a id="retrospectives-tables"></a>

### 2. 读返回的表 / Read the returned tables

```r
rb$fit_diagnostics
rb$rho_by_peel
rb$rho_text
rb$raw_rho_text
rb$errors
```

返回值是一个由表组成的列表，`ra` 的元素与 `rb` 相同：

The result is a list of tables, and `ra` has the same elements as `rb`:

| 元素 / Element | 每行对应 / One row per | 内容 / Contents |
|---|---|---|
| `fit_diagnostics` | 一次拟合 / fit | `Peel`（0 是完整拟合）、`RetrospectiveYear`（保留的最后一个时间步）、`elapsed`、数值检查及其汇总 `numerical_ok` 和未通过的项目 `issues`，以及拟合中止时的错误信息 `error` / `Peel` (0 is the full fit), `RetrospectiveYear` (last time step kept), `elapsed`, the numerical checks with their summary `numerical_ok` and failed items `issues`, and the message of a fit that stopped in `error` |
| `rho_by_peel` | 一轮和一个量 / peel and quantity | `RawRho`，该轮末端估计与完整拟合在该时间步估计的相对差；`Rho`，两次拟合都通过数值检查且参考值有限、非零时等于 `RawRho`，否则为 `NA`；`Valid` / `RawRho`, the relative difference between the peel's terminal estimate and the full fit's estimate for that time step; `Rho`, the same when both fits passed the numerical checks and the reference is finite and nonzero, otherwise `NA`; `Valid` |
| `rho_text` | 一个量 / quantity | Mohn rho，即各轮 `Rho` 的平均值，附 `Valid`、`ValidPeels` 和 `RequestedPeels`；`Year` 只是标签位置 / Mohn's rho, the mean of `Rho` over the peels, with `Valid`, `ValidPeels` and `RequestedPeels`; `Year` is only a label position |
| `raw_rho_text` | 一个量 / quantity | 不经检查的 `RawRho` 平均值，仅供诊断；任一比较缺失时为 `NA` / the mean of `RawRho` without the checks, for diagnosis only; `NA` when any comparison is missing |
| `errors` | 一次失败的拟合 / failed fit | `Peel`、`RetrospectiveYear` 和错误信息；所有拟合都运行完成时为零行 / `Peel`, `RetrospectiveYear` and the message; zero rows when every fit ran |

这些量是总生物量 `B`、补充量 `Rec`、产卵生物量 `SSB` 和丰度 `N`；完整序列在 `rb$results` 中。当完整拟合或任一轮未通过数值检查，或某个末端比较缺失时，`rho_text$Rho` 为 `NA` 并发出警告，因为把一次停在错误解上的拟合算进平均会把优化器的失败和真实的修订混在一起。请在 `fit_diagnostics$issues` 和 `errors` 中找到失败的拟合，按[判断拟合是否可用](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics)修复它并重新运行；`raw_rho_text` 只用来看可用差值的大小。

The quantities are total biomass `B`, recruitment `Rec`, spawning biomass `SSB` and abundance `N`; the full series are in `rb$results`. `rho_text$Rho` is `NA`, with a warning, when the full fit or any peel failed the numerical checks or a terminal comparison is missing, because a mean over a fit stopped at a wrong solution would mix an optimizer failure with a real revision. Find the failed fit in `fit_diagnostics$issues` and `errors`, repair it as on [Judge whether a fit can be used](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) and rerun; `raw_rho_text` only shows the size of the available differences.

<a id="retrospectives-plot"></a>

### 3. 绘制重拟合序列 / Plot the refitted series

```r
plot_retro(rb, facet_ncol = 2, rho_digits = 3)
```

![示例的 ALSCL 回溯分析 / ALSCL retrospective analysis of the example](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ALSCL.png?raw=true&v=a15f447d44dc)

`plot_retro()` 直接绘制保存的序列，无需重拟合，每个量一个面板，`facet_ncol = 2` 把它们排成两列。每条线是一次拟合，颜色按它的最后一个时间步区分（图例「Retrospective Year」）：完整拟合止于 2019 年，各轮止于 2018、2017 和 2016 年。空心点标出每次拟合的末端估计，也就是 rho 与完整拟合比较的那个值；面板标签给出保留 `rho_digits` 位小数的 Mohn rho。本页的图另加了 `rho_size = 3`、`point_size = 1` 和 `line_size = 0.6`。

`plot_retro()` draws the stored series without refitting, one panel per quantity in the two columns set by `facet_ncol = 2`. Each line is one fit, colored by its last time step (legend "Retrospective Year"): the full fit ends in 2019, the peels in 2018, 2017 and 2016. The open point marks each fit's terminal estimate, the value rho compares with the full fit, and the panel label gives Mohn's rho with `rho_digits` decimals. The figures on this page add `rho_size = 3`, `point_size = 1` and `line_size = 0.6`.

![示例的 ACL 回溯分析 / ACL retrospective analysis of the example](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ACL.png?raw=true&v=a6c651d2e0de)

像两张图这样，截短的线在大部分序列上与完整拟合重合，只在最后几年分开，说明加入观测只修订了近期估计。rho 为 `NA` 时，面板显示 `rho unavailable: check diagnostics`；若没有任何拟合给出估计值，`plot_retro()` 会停止并提示读 `fit_diagnostics` 和 `errors`。标题、标签、字号和各次拟合的颜色（`palette`、`colors`）见 [ggsci 配色与导出](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_STYLE.md)；全部参数见 [plot_retro 参考](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_retro)。

Peeled lines that lie on the full fit for most of the series and split only in the last years, as in both figures, show that adding observations revises the recent estimates only. When rho is `NA` the panel reads `rho unavailable: check diagnostics`; if no fit produced estimates, `plot_retro()` stops and asks you to read `fit_diagnostics` and `errors`. Titles, labels, font sizes and the colors of the fits (`palette`, `colors`) follow [Colors and export](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_STYLE.md); every argument is in the [plot_retro reference](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_retro).

<a id="retrospectives-rho"></a>

### 4. 解释 Mohn rho / Interpret Mohn's rho

Mohn rho 把每一轮的末端估计与完整拟合在同一时间步的估计之间的相对差，对各轮取平均：

Mohn's rho averages, over the peels, the relative difference between the terminal estimate of each peel and the full fit's estimate for the same time step:

```math
\rho=\frac{1}{K}\sum_{k=1}^{K}\frac{\hat\theta^{(-k)}_{T-k}-\hat\theta^{(0)}_{T-k}}{\hat\theta^{(0)}_{T-k}}.
```

`K` 是 `nyear`，`T` 是完整拟合的最后一个时间步；第 `k` 轮止于 `T-k`。rho 为正表示较短的拟合止于完整拟合之上，即加入观测后近期估计下调；为负则相反；rho 为 0.03 表示平均修订 3%。符号相反的项会抵消，所以也要读 `rho_by_peel`；完整拟合的估计为零时该项没有定义。Mohn rho 衡量的是加入后来的观测后末端估计被修订的程度；预测准确度由[预测检验](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md)来回答。在各轮和各模型中符号相同的修订，比它的具体大小更重要。

`K` is `nyear` and `T` the last time step of the full fit; peel `k` ends at `T-k`. A positive rho means that the shorter fits ended above the full fit, so adding observations lowered the recent estimates, a negative rho the opposite, and a rho of 0.03 an average revision of 3%. Terms of opposite sign cancel, so read `rho_by_peel` as well; a full-fit estimate of zero leaves its term undefined. Mohn's rho measures the revision of terminal estimates when later observations are added; forecast accuracy is the question of [hindcast validation](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md). A revision with the same sign across peels and models matters more than its exact size.

<a id="retrospectives-adapt"></a>

### 5. 用于自己的评估 / Adapt the analysis to your assessment

```r
rb2 <- retro_alscl(x, nyear = 3, nstarts = 2, ncores = 3, silent = TRUE)
rb2$fit_diagnostics
```

用你报告的那次拟合的设置运行分析，这样各轮之间的差异只来自去掉的观测。调用中的参数会传给每次拟合：`nstarts = 2` 让每次拟合运行两个初值并保留目标函数值较低的那个，`ncores = 3` 同时拟合三轮（工作进程最多 `nyear` 个），`map`、`parameters` 或 `control` 参数会整体替换保存的列表（[选择拟合设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting)）。对自己的输入列表有四条规则：

Run the analysis with the settings of the fit you report, so that differences between peels come from the removed observations only. Arguments in the call reach every fit: `nstarts = 2` runs two starts per fit and keeps the lower objective, `ncores = 3` fits the three peels at once (at most `nyear` workers), and a `map`, `parameters` or `control` argument replaces the whole stored list ([Choose the fitting settings](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting)). Four rules apply to your own bundle:

- `dev_log_R` 和 `dev_log_F`（补充量和捕捞死亡率的过程偏差）的 map 必须覆盖完整数据表的全部时间步，先排一个时间步的所有组再排下一个（`F_structure = "year"` 时只有一组）；每一轮保留它所保留的时间步及其固定值和绑定关系，长度不符的 map 会终止分析。
- 使用与主拟合相同的 F 结构：保存的 `F_structure` 会被使用，调用中显式给出的则作用于每次拟合。
- 最短的一轮至少保留两个观测时间步，序列较短时要保留更多，因为较短的一轮要用更少的观测估计同样多的参数。
- 按时间步而不是按年计数：季度数据中 `nyear = 4` 去掉一年，`RetrospectiveYear` 显示保留的最后一个时间步。

- Maps for `dev_log_R` and `dev_log_F`, the process deviations of recruitment and fishing mortality, must cover the complete time grid of the full tables, all groups of one time step before the next (one group when `F_structure = "year"`); each peel keeps its retained time steps with their fixed values and ties, and a map of another length stops the analysis.
- Use the same F structure as the main fit: the stored `F_structure` is used, and an explicit one in the call applies to every fit.
- Keep at least two observed time steps in the shortest peel, and more when the series is short, because a short peel estimates the same parameters from fewer observations.
- Count time steps, not years: with quarterly data `nyear = 4` removes one year, and `RetrospectiveYear` shows the last time step kept.

<a id="retrospectives-record"></a>

### 6. 记录结果 / Record the result

```r
save_assessment(b, "ytf_alscl.rds")
saveRDS(rb, "ytf_alscl_retro.rds")
plot_retro(readRDS("ytf_alscl_retro.rds"), facet_ncol = 2, rho_digits = 3)
```

回溯结果只包含表，没有只在当前会话有效的 TMB 对象，所以 `saveRDS()` 能完整保存它，`plot_retro()` 能在新会话中绘制重新读入的对象。`save_assessment()` 用于拟合结果：它把 `b` 连同配方存为保存的拟合结果，供 `refit_model()` 使用；传入回溯结果时以 `A complete fit recipe is required` 停止。把这两个文件放在一起；[进阶、复现与故障处理](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ADVANCED_WORKFLOWS.md)说明如何记录软件包版本和会话。

The retrospective result holds tables only, with no live TMB object, so `saveRDS()` keeps all of it and `plot_retro()` draws the reloaded object in a new session. `save_assessment()` is for fits: it stores `b` as a saved fit with its recipe for `refit_model()` and stops with `A complete fit recipe is required` when given the retrospective result. Keep the two files together; [Reproducibility](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ADVANCED_WORKFLOWS.md) shows how to record the package versions and the session.

<a id="retrospectives-next"></a>

### 下一步 / What next

| 想做什么 / What you want to do | 阅读 / Read |
|---|---|
| 完整做一遍案例 / Work through the case | [移除近期数据后，估计结果会怎样变化？](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md#case-retrospective-bias) / [Do estimates change when recent data are removed?](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md#case-retrospective-bias) |
| 修复失败的一轮 / Repair a failed peel | [判断拟合是否可用](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) / [Judge whether a fit can be used](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) |
| 更改 map、F 结构或初值 / Change the map, F structure or starts | [选择拟合设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) / [Choose the fitting settings](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) |
| 检验对后来时间步的预测 / Test predictions of later time steps | [模型验证](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md) / [Model validation](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md) |
| 用更多核心运行各轮 / Run the peels on more cores | [速度设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/SPEED_GUIDE.md) / [Speed settings](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/SPEED_GUIDE.md) |
| 更改颜色和标签 / Change colors and labels | [ggsci 配色与导出](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_STYLE.md) / [Colors and export](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_STYLE.md) |
| 查阅全部参数 / Read every argument | [retro_model](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#retro_model)、[retro_acl](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#retro_acl)、[retro_alscl](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#retro_alscl)、[plot_retro](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_retro) / [retro_model](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#retro_model), [retro_acl](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#retro_acl), [retro_alscl](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#retro_alscl), [plot_retro](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_retro) |

<a id="chapter-12"></a>
## 12 年度与季度案例 · Annual and quarterly cases

<!-- Generated by scripts/build_manual.py from website/content/{en,zh}/articles/. Edit the article pair, not this file. -->

[使用指南 / User guide](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md) · [首页 / Home](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/README.md)

## 年度与季度时间步 / Annual and quarterly time steps

学完本页，你已经用 ACL 和 ALSCL 拟合了两个附带案例，一个年度鲽鱼调查和一个季度金枪鱼调查，并知道时间步改为季度时哪些设置的含义会改变。两个案例都是模拟数据（由 `scripts/simulation_workflow.R` 以种子 4 生成，各有 23 个体长组和 20 个时间步）；它们不是论文的数据。你需要安装好的软件包和一份仓库副本；请在同一个 R 会话中从仓库根目录运行各步骤。[理解第一次拟合](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin)说明了输入列表和数值检查。

At the end of this page you have fitted ACL and ALSCL to two supplied cases, an annual flatfish survey and a quarterly tuna survey, and you know which settings change their meaning when the time step is a quarter. Both cases are synthetic (`scripts/simulation_workflow.R`, seed 4, 23 length bins and 20 time steps each); they are not the paper's data. You need the package and a copy of the repository; run the steps in one R session from the repository root. [Understand your first fit](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin) explains the input bundle and the numerical checks.

<a id="case-studies-read"></a>

### 1. 读取两个案例 / Read the two cases

```r
library(ALSCL)
flatfish_inputs <- read_survey_csv("docs/data/cases/flatfish")
tuna_inputs <- read_survey_csv("docs/data/cases/tuna")
pa <- readRDS("docs/data/cases/tuna/truth.rds")$parameters
pa[c("growth_step", "rec.age", "nage", "M", "Linf", "vbk")]
names(tuna_inputs$data.CatL)[1:5]
```

每个案例文件夹包含三张表 `data.CatL.csv`、`data.wgt.csv` 和 `data.mat.csv`（一列 `LengthBin` 标签，之后每个时间步一列），以及保存生成设置 `parameters` 和模拟种群 `truth` 的 `truth.rds`。`read_survey_csv()` 检查三张表的标签和维度一致、时间标签递增、体重有限且非负、成熟比例在 0 到 1 之间；它不添加生物学设置。生物学设置在后两步输入：

Each case folder holds the three tables `data.CatL.csv`, `data.wgt.csv` and `data.mat.csv` (a `LengthBin` column, then one column per time step) and `truth.rds` with the generator settings `parameters` and the simulated population `truth`. `read_survey_csv()` checks that the tables share labels and dimensions, that the time labels increase, that weights are finite and nonnegative and that maturity lies between 0 and 1; it adds no biology. You enter the biology in the next two steps:

| 设置 / Setting | 鲽鱼 / Flatfish | 金枪鱼 / Tuna |
|---|---|---|
| 生成器，时间步 / Generator, time step | 年龄型，1 年 / age-based, 1 year | 体长型，0.25 年 / length-based, 0.25 year |
| 时间标签 / Time labels | 2000 至 2019，每年一列 / 2000 to 2019, one per year | 2000 至 2004.75，每季一列 / 2000 to 2004.75, one per quarter |
| `rec.age`、`nage` / `rec.age`, `nage` | 1、15 / 1, 15 | 0.25、20 / 0.25, 20 |
| `Linf`、每年的 `vbk`、`t0` / `Linf`, `vbk` per year, `t0` | 60、0.20、1/60 / 60, 0.20, 1/60 | 152、0.38、1/152 / 152, 0.38, 1/152 |
| 每个时间步的 `M` / `M` per time step | 0.20 | 0.20（每年 0.80） / 0.20 (0.80 per year) |
| 成熟 L50、L95 / Maturity L50, L95 | 35、40 / 35, 40 | 100、120 / 100, 120 |
| 调查可捕性 `sel_L50`、`sel_L95` / Survey catchability `sel_L50`, `sel_L95` | 15、20 / 15, 20 | 30、50 / 30, 50 |
| 体长组中点；调查对数 SD / Bin midpoints; survey log SD | 6 至 50，间隔 2；0.20 / 6 to 50 in steps of 2; 0.20 | 12.5 至 122.5，间隔 5；0.10 / 12.5 to 122.5 in steps of 5; 0.10 |

`pa` 打印出 `growth_step` 0.25、`rec.age` 0.25、`nage` 20、`M` 0.2、`Linf` 152 和 `vbk` 0.38；金枪鱼的列名是 `LengthBin`、`2000`、`2000.25`、`2000.5`、`2000.75`。如果 `read_survey_csv()` 停在 `folder must name an existing directory`，说明 R 不在仓库根目录；如果报错信息点名某张表，按[准备调查数据](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel)修正该文件。

`pa` prints `growth_step` 0.25, `rec.age` 0.25, `nage` 20, `M` 0.2, `Linf` 152 and `vbk` 0.38; the tuna column names are `LengthBin`, `2000`, `2000.25`, `2000.5`, `2000.75`. If `read_survey_csv()` stops with `folder must name an existing directory`, R is not in the repository root; if the message names a table, correct that file as in [Prepare your survey data](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel).

<a id="case-studies-annual"></a>

### 2. 拟合年度鲽鱼案例 / Fit the annual flatfish case

```r
fix <- function(p) lapply(p, function(v) factor(NA))
known <- list(log_Linf = log(60), log_vbk = log(0.2), log_cv_len = log(0.2),
  logit_log_R = qlogis(0.1))
acl_known <- c(known, list(t0 = 1/60, log_std_log_F = log(0.2), log_std_log_N0 = log(0.2)))
alscl_known <- c(known, list(log_t0 = log(1/60), log_cv_grow = log(0.2),
  log_sigma_log_F = log(0.2), log_sigma_log_N0 = log(0.2)))
x <- prepare_alscl_data(flatfish_inputs,
  fit_args = list(rec.age = 1, nage = 15, M = 0.2, sel_L50 = 15, sel_L95 = 20,
    growth_step = 1, silent = TRUE),
  fit_config = list(acl = list(parameters = acl_known, map = fix(acl_known)),
    alscl = list(parameters = alscl_known, map = c(fix(alscl_known),
      list(logit_log_F_l = factor(NA), logit_log_F_y = factor(NA))))))
a <- run_acl(x)
b <- run_alscl(x)
c(a$diagnostics$numerical_ok, b$diagnostics$numerical_ok)
plot_compare_ts(a, b, quantities = c("B", "SSB", "Rec"), se = TRUE)
```

`prepare_alscl_data()` 用三张表和 `fit_args` 中两个模型共用的生物学设置构建输入列表 `x`；体长组来自行标签（中点为 6 至 50、间隔 2，边界取相邻中点的中间值）。`fit_config` 存放各模型的初值和 `map`。生成调查数据时使用的值用 `factor(NA)` 固定：生长参数、体长变异系数、过程标准差和补充量相关系数，ALSCL 还固定两个 F 相关系数。于是每个模型只估计五个标量参数，估计值以已知生物学为条件。这正是 [scripts/case_studies.R](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/scripts/case_studies.R) 的设置，下面的图由该脚本绘制。

`prepare_alscl_data()` builds the input bundle `x` from the three tables and the shared biology in `fit_args`; the length bins come from the row labels (midpoints 6 to 50 in steps of 2, borders halfway between). `fit_config` holds each model's starting values and `map`. The values that generated the survey are fixed with `factor(NA)`: growth, the length CVs, the process standard deviations and the recruitment correlation, plus the two F correlations in ALSCL. Each model then estimates five scalar parameters, conditional on known biology. This is the configuration of [scripts/case_studies.R](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/scripts/case_studies.R), which drew the figures below.

每个模型一次性编译之后，ACL 约需二十秒，ALSCL 约需一分半。数值检查应打印 `TRUE TRUE`，与脚本的[收敛记录](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/case_convergence.csv)一致。若某项检查未通过，按[理解第一次拟合](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#first-model-checks)运行 `diagnose_model(x$data.CatL, a)`，并用 `nstarts` 增加初值。

After the one-time compilation of each model, ACL takes about twenty seconds and ALSCL about one and a half minutes. Expect `TRUE TRUE` from the numerical checks, as in the script's [convergence record](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/case_convergence.csv). If a check fails, run `diagnose_model(x$data.CatL, a)` as on [Understand your first fit](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#first-model-checks) and add starts with `nstarts`.

![鲽鱼模拟调查 / Flatfish synthetic survey](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/cases/flatfish_data.png?raw=true&v=ae2873a39574)

热图按年份和体长组显示 log10 调查指数：10 cm 以下很小，因为那里的调查可捕性低于 0.1；15-30 cm 最大。

The heat map shows the log10 survey index by year and length bin: small below 10 cm, where survey catchability is under 0.1, and largest at 15-30 cm.

![鲽鱼的生长、成熟与调查可捕性 / Flatfish growth, maturity and survey catchability](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/cases/flatfish_biology.png?raw=true&v=b3efd0f2b715)

生长曲线从 1 龄的 11 cm 到 15 龄的 57 cm。成熟（L50 为 35 cm，来自 `data.mat`）和调查可捕性（L50 为 15 cm，由 `sel_L50` 和 `sel_L95` 设定）是两条不同的曲线。

Growth runs from 11 cm at age 1 to 57 cm at age 15. Maturity (L50 35 cm), read from `data.mat`, and survey catchability (L50 15 cm), set by `sel_L50` and `sel_L95`, are different curves.

![鲽鱼的生成真值与条件估计 / Flatfish generating truth and conditional estimates](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/cases/flatfish_truth.png?raw=true&v=c37a38eea1f3)

虚线是生成真值，实线是两个模型的条件估计。两个模型都跟上了 2010 年之前的下降和之后的回升；2014 年以后 ALSCL 的生物量和产卵生物量低于真值。`plot_compare_ts()` 画出的是同样的轨迹，并附有区间。

Dashed lines are the generating truth, solid lines the two conditional estimates. Both models follow the decline to 2010 and the rise after it; ALSCL sits below the truth for biomass and spawning biomass after 2014. `plot_compare_ts()` shows the same trajectories with intervals.

<a id="case-studies-quarterly"></a>

### 3. 拟合季度金枪鱼案例 / Fit the quarterly tuna case

```r
known <- list(log_Linf = log(152), log_vbk = log(0.38), log_cv_len = log(0.2),
  logit_log_R = qlogis(0.1))
acl_known <- c(known, list(t0 = 1/152, log_std_log_F = log(0.2), log_std_log_N0 = log(0.3)))
alscl_known <- c(known, list(log_t0 = log(1/152), log_cv_grow = log(0.3),
  log_sigma_log_F = log(0.2), log_sigma_log_N0 = log(0.3)))
xq <- prepare_alscl_data(tuna_inputs,
  fit_args = list(rec.age = 0.25, nage = 20, M = 0.2, sel_L50 = 30, sel_L95 = 50,
    growth_step = 0.25, silent = TRUE),
  fit_config = list(acl = list(parameters = acl_known, map = fix(acl_known)),
    alscl = list(parameters = alscl_known, map = c(fix(alscl_known),
      list(logit_log_F_l = factor(NA), logit_log_F_y = factor(NA))))))
check_alscl_data(xq, "alscl")$time
aq <- run_acl(xq)
bq <- run_alscl(xq)
c(aq$diagnostics$numerical_ok, bq$diagnostics$numerical_ok)
plot_compare_ts(aq, bq, quantities = c("B", "SSB", "Rec"), se = TRUE)
```

代码相同，但四项设置的含义变了。`growth_step = 0.25` 使每一列代表一个季度，因此时间标签必须相隔 0.25。`M` 和捕捞死亡率都按时间步计：年 M 为 0.8 要输入 `M = 0.2`，而 `vbk` 仍按年计。`rec.age` 以年为单位，0.25 表示一个季度龄补充；`nage = 20` 数的是季度龄组，从 0.25 龄到 5 龄，最后一组为加组；`t0` 必须小于 `rec.age`。

The code is the same; four settings change their meaning. `growth_step = 0.25` makes each column one quarter, so the time labels must be spaced 0.25 apart. `M` and fishing mortality are per time step: an annual M of 0.8 is entered as `M = 0.2`, while `vbk` stays per year. `rec.age` is in years, so 0.25 means recruitment at one quarter, and `nage = 20` counts quarter-age classes from 0.25 to 5 years, the last one the plus group; `t0` must stay below `rec.age`.

`check_alscl_data()$time` 打印 2000 到 2004.75 的 20 个季度：这里的二十个时间步是五年。两次拟合都通过数值检查；ALSCL 约需两分钟。如果标签的间隔不等于 `growth_step`，拟合会停在 `Time column spacing must equal growth_step`；请保留每个季度一列，没有调查的季度填 `NA`，体重和成熟比例则要完整。

`check_alscl_data()$time` prints the 20 quarters from 2000 to 2004.75: twenty time steps are five years here. Both fits pass the numerical checks; ALSCL takes about two minutes. If the label spacing differs from `growth_step`, fitting stops with `Time column spacing must equal growth_step`; keep every quarter as a column, with `NA` survey values for quarters without a survey and complete weights and maturity.

![金枪鱼模拟调查 / Tuna synthetic survey](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/cases/tuna_data.png?raw=true&v=bbff06c12616)

热图每年有四列。指数在 30-70 cm 最大，在 122.5 cm 组最小，生长曲线要到 4 龄以后才到达这个体长。

The heat map has four columns per year. The index is largest at 30-70 cm and smallest in the 122.5 cm bin, which the growth curve reaches only after age 4.

![金枪鱼的生长、成熟与调查可捕性 / Tuna growth, maturity and survey catchability](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/cases/tuna_biology.png?raw=true&v=4ffb044f53da)

生长曲线从 0.25 龄的 13 cm 到 5 龄的 129 cm（`vbk` 为每年 0.38）；成熟（L50 为 100 cm）远高于调查可捕性（L50 为 30 cm）。

Growth runs from 13 cm at age 0.25 to 129 cm at age 5 (`vbk` 0.38 per year); maturity (L50 100 cm) lies far above survey catchability (L50 30 cm).

![金枪鱼的生成真值与条件估计 / Tuna generating truth and conditional estimates](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/cases/tuna_truth.png?raw=true&v=112a7b6bcb17)

补充量按季度计。ALSCL 的生物量和产卵生物量跟随真值；ACL 的生物量低于真值，2000-2001 年的产卵生物量起点过低，并高估了多数季度的补充量。该案例由体长型动态生成，这正是 ALSCL 假设的结构；单个重复不能给两个模型排名。

Recruitment is per quarter. ALSCL follows the truth for biomass and spawning biomass; ACL lies below the truth for biomass, starts spawning biomass far too low in 2000-2001 and overestimates most quarterly recruitments. The case was generated with length-based dynamics, the structure ALSCL assumes; one replicate cannot rank the two models.

<a id="case-studies-simulation"></a>

### 4. 扩展为模拟实验 / Extend to a simulation study

```r
source("scripts/simulation_workflow.R", encoding = "UTF-8")
simulations <- run_simulation_examples(out = "my_simulations", fit_batch = FALSE)
source("scripts/case_studies.R", encoding = "UTF-8")
case_status <- run_case_studies(out = "docs")
```

`run_simulation_examples()` 在 `out` 下重新生成两个案例：每个预设物种的三个 CSV 文件、`truth.rds` 和重复文件；`fit_batch = TRUE` 会再对鲽鱼的重复批量拟合 ACL，并写出保留失败拟合的 `batch_checks.csv`。`run_case_studies()` 用第 2 步和第 3 步的设置重新拟合两个案例，在 `out` 下写出七张案例图和 `results/case_convergence.csv`；它从 `out/data/cases` 读取真值，所以换用其他 `out` 时先把两个案例文件夹复制过去。

`run_simulation_examples()` regenerates both cases under `out`: the three CSV files, `truth.rds` and the replicate files of each preset; `fit_batch = TRUE` adds batch ACL fits of the flatfish replicates and writes `batch_checks.csv`, which keeps the failed fits. `run_case_studies()` refits both cases with the settings of steps 2 and 3 and writes the seven case figures and `results/case_convergence.csv` under `out`; it reads the truth from `out/data/cases`, so copy the two case folders there first when you choose another `out`.

要做模拟实验，就增大 `iter_range` 以生成更多重复，每次只改变一项设置（调查对数 SD、`M`、可捕性、体长组或序列长度），并在偏差、RMSE 和区间覆盖率的汇总中保留失败的拟合；只平均成功的拟合是选择偏差。[模拟与批量实验](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#simulation)介绍模拟器和批量拟合。

For a study, raise `iter_range` for more replicates, vary one setting at a time (survey log SD, `M`, catchability, bins, series length), and keep the failed fits in the summary of bias, RMSE and interval coverage; averaging only the successful fits is selection bias. [Simulation](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#simulation) describes the simulators and batch fitting.

<a id="case-studies-next"></a>

### 下一步 / What next

| 想做什么 / What you want to do | 阅读 / Read |
|---|---|
| 整理自己的数据表并选择时间步 / Lay out your own tables and choose the time step | [准备调查数据](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel) / [Prepare your survey data](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel) |
| 读拟合结果的数值检查、估计值和残差 / Read the numerical checks, estimates and residuals of a fit | [理解第一次拟合](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin) / [Understand your first fit](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin) |
| 决定哪些参数固定、哪些估计 / Decide which parameters to fix or estimate | [拟合设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) / [Fitting controls](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) |
| 生成调查数据并批量拟合重复 / Generate survey data and fit replicates in batch | [模拟与批量实验](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#simulation) / [Simulation](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#simulation) |
| 从拟合模型模拟，或预测留出的年份 / Simulate from a fitted model or predict withheld years | [模型验证](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md) / [Model validation](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md) |

<a id="chapter-13"></a>
## 13 ggsci 配色与导出 · Colors and export

<!-- Generated by scripts/build_manual.py from website/content/{en,zh}/articles/. Edit the article pair, not this file. -->

[使用指南 / User guide](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md) · [首页 / Home](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/README.md)

## ggsci 配色与导出 / Colors and export

本页带你为所有 ALSCL 图一次设置色板和主题、为单张图覆盖颜色、导出图形，以及设置生长图和种群图的标签和坐标轴。你需要[理解第一次拟合](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin)中的 `a`、`b` 和 `x`；第 1 步还会拟合一个回溯分析结果 `rb`（[运行回溯分析](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#retrospective)）。

On this page you set a palette and theme once for every ALSCL plot, override colors for one plot, export a figure, and set the labels and axes of the growth and population plots. You need `a`, `b` and `x` from [Understand your first fit](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin); step 1 also fits a retrospective analysis `rb` ([Run a retrospective analysis](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#retrospective)).

<a id="plot-customization-theme"></a>

### 1. 一次设置主题 / Set the theme once

```r
# 先建立回溯结果，再调整绘图样式 / Create the retrospective result before styling it
rb <- retro_alscl(x, nyear = 3, train_times = 2, ncores = 1, silent = TRUE)

# 一次设置，随后重新创建图 / Set once, then recreate plots
acl_theme_set(palette = "npg", base_theme = "theme_bw", font_family = "sans")
plot_retro(rb, facet_ncol = 2, rho_digits = 3)
plot_compare_ts(a, b, se = TRUE)

# 可选期刊色板 / Alternative journal palettes
acl_theme_set(palette = "jama") # npg, aaas, nejm, lancet, jama
plot_abundance(b, type = "NL", facet_ncol = 3)
```

默认色板是 ggsci NPG：估计值用深蓝，观测用朱红，两模型比较用深蓝和朱红。回溯图的颜色按末端时间步从新到旧分配。`acl_theme_set()` 只影响之后创建的图；要改已有的图，就重新创建它。可选色板为 `npg`（10 色）、`aaas`（10）、`nejm`（8）、`lancet`（9）和 `jama`（7）。

The default palette is ggsci NPG: navy estimates, vermilion observations, and navy and vermilion for model comparisons. Retrospective colors follow the terminal time steps, newest first. `acl_theme_set()` changes the plots created afterwards; recreate an existing plot to restyle it. The palettes are `npg` (10 colors), `aaas` (10), `nejm` (8), `lancet` (9) and `jama` (7).

![五种色板及各颜色的用途 / The five palettes with the roles of their colours](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/palettes/palettes.png?raw=true&v=b700769161ed)

图中是 `acl_theme_set()` 接受的五种色板。每一行里，第一个带标注的颜色用于单模型图的线、区间和点，第二个用于观测和比较图中的第二个模型，第三个用于平滑线；其余颜色按顺序供需要更多分组的图使用，例如回溯图的各轮。下一张图把同一张比较图在每种色板下画出来，便于按视觉效果挑选；仓库中的 `docs/figures/palettes/ssb_by_palette.png` 以同样方式展示单模型图。

The figure shows the five palettes `acl_theme_set()` accepts. In each row the first labelled colour draws lines, intervals and points of single-model plots, the second draws observations and the second model in comparisons, and the third draws smoothers; the remaining colours are used in order when a plot needs more groups, for example the peels of a retrospective. The next figure shows the same comparison plot under every palette, so you can pick one by eye; `docs/figures/palettes/ssb_by_palette.png` in the repository shows a single-model plot in the same way.

![各色板下的 plot_compare_ts(a, b, quantities = "SSB", se = TRUE) / plot_compare_ts(a, b, quantities = "SSB", se = TRUE) under each palette](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/palettes/compare_by_palette.png?raw=true&v=a267f422e5a1)

| 设置 / Setting | 范围与优先级 / Scope and precedence |
|---|---|
| `palette` | 切换时重设派生的颜色角色 / Switching resets derived roles |
| `line_color`、`se_color`、`point_color` / `line_color`, `se_color`, `point_color` | 单模型的线、区间和散点 / Single-model lines, intervals and scatter |
| `observed_color`、`smooth_color`、`hline_color` / `observed_color`, `smooth_color`, `hline_color` | 观测、残差平滑线和参考线 / Observation, residual smoother and reference line |
| `compare_colors` | 模型对，可按模型名称匹配 / Model pair, optionally matched by name |
| `low_col`、`high_col` / `low_col`, `high_col` | 连续热图的端点 / Sequential heatmap endpoints |
| `font_family`、`title_size`、`axis_text_size`、`strip_text_size` / `font_family`, `title_size`, `axis_text_size`, `strip_text_size` | 字体与字号 / Typography |
| `line_size`、`point_size` / `line_size`, `point_size` | 单模型图的线宽和所有图的默认点大小（2.5）；比较图线宽使用 `compare_line_size` / Single-model line width and the default point size for all plots (2.5); comparison line widths use `compare_line_size` |
| `compare_point_size` | 可选的比较图点大小；设为 `NULL` 清除覆盖，恢复继承全局 `point_size` / Optional comparison-only point size; `NULL` clears it and restores global `point_size` inheritance |
| `facet_ncol`、`facet_nrow`、`facet_scales` / `facet_ncol`, `facet_nrow`, `facet_scales` | 分面布局，所有图使用相同的参数名 / Facet layout, with the same argument names in every plot |

<a id="plot-customization-override"></a>

### 2. 为单张图覆盖颜色 / Override colors for one plot

```r
# 单图覆盖优先于全局设置 / Per-call overrides take precedence
plot_retro(rb, palette = "nejm", rho_position = "top_left")
plot_retro(rb, colors = c("2019" = "#3C5488", "2018" = "#E64B35",
                         "2017" = "#00A087", "2016" = "#4DBBD5"))
plot_SSB(b, line_color = "#00A087", se = TRUE, se_color = "#00A087")
plot_compare_ts(a, b, colors = c("ACL" = "#3C5488", "ALSCL" = "#E64B35"))

# 连续量使用渐变色 / Sequential gradients encode continuous quantities
plot_pla(b)                         # 全局端点 / Global endpoints
plot_compare_F(a, b, palette = "npg")
plot_compare_F(a, b, palette = "inferno") # 其他渐变 / Another gradient
plot_ridges(b)                      # 默认年份渐变 / Default time gradient
plot_ridges(b, palette = "cividis")
acl_theme_set(ylab = list(year = "Survey year")) # 山脊图时间轴 / Ridge time axis
plot_ridges(b, palette = c("#E8F1FA", "#3C5488"))

# 恢复默认 / Restore defaults
acl_theme_reset()
```

设置 `acl_theme_set(point_size = 3)` 可统一单模型图和比较图的点大小。调用中的 `point_size` 优先级最高。在 `plot_compare_CatL()` 中，其次是显式传入的旧参数 `obs_size`，再是显式设置的主题 `compare_point_size`，最后是全局 `point_size`。其他含点的比较图遵守相同顺序，但不使用 `obs_size`。用 `acl_theme_set(compare_point_size = NULL)` 清除仅针对比较图的覆盖。

Set `acl_theme_set(point_size = 3)` to change points across single-model and comparison plots. A per-call `point_size` has highest priority. In `plot_compare_CatL()`, an explicit legacy `obs_size` comes next, followed by an explicit `compare_point_size` theme setting and then the global `point_size`. The other point-drawing comparison plots follow the same order without `obs_size`. Use `acl_theme_set(compare_point_size = NULL)` to remove a comparison-only override.

调用中显式给出的颜色优先于主题，也优先于同时传入的 `palette`；`NULL` 继承主题。`se_color` 要与 `line_color` 一起指定，否则它仍取主题值。回溯图的命名颜色必须覆盖每个末端时间步；无名称的颜色按同样的顺序对应。轮数超过色板颜色数时，颜色由插值得到。山脊图使用按输入年份顺序取色的 viridis 渐变，观测与拟合两侧共用，与全局色板无关；`NULL` 也使用 viridis，可改为 `cividis`、`plasma`、`ocean` 或一组颜色。

Explicit colors in a call override the theme and a palette passed with them; `NULL` inherits the theme. Set `se_color` together with `line_color`; it stays at the theme value otherwise. Named retrospective colors must cover every terminal time step; unnamed colors follow the same order. With more peels than palette colors, the colors are interpolated. Ridges use a viridis gradient in input-year order, shared by the observed and fitted panels and independent of the global palette; `NULL` also selects viridis, and `cividis`, `plasma`, `ocean` or a vector of colors replace it.

<a id="plot-customization-export"></a>

### 3. 设置文字并导出 / Set typography and export

```r
# 调整文字与布局 / Typography and layout
acl_theme_set(palette="npg", title_size=16, axis_title_size=12,
              axis_text_size=10, strip_text_size=10, title_hjust=0,
              compare_legend_pos="bottom", compare_linetypes=c("solid","dashed"))
p <- plot_retro(rb, facet_ncol = 2, point_size=1.8, line_size=.8)
ggplot2::ggsave("retrospective.png", p, width=11, height=7, dpi=300, bg="white")
ggplot2::ggsave("retrospective.pdf", p, width=11, height=7)
# 显式保存并恢复设置 / Preserve settings explicitly
old <- acl_theme()
acl_theme_set(palette="aaas")
do.call(acl_theme_set, old)
acl_theme_reset()
```

`ggsave()` 按给定的尺寸和分辨率写出 `p`。`acl_theme()` 返回当前设置，供 `do.call(acl_theme_set, old)` 恢复；`acl_theme_reset()` 回到默认值。色板来源：[ggsci NPG documentation](https://nanx.me/ggsci/reference/pal_npg.html)。

`ggsave()` writes `p` at the given size and resolution. `acl_theme()` returns the current settings for `do.call(acl_theme_set, old)` to restore; `acl_theme_reset()` returns to the defaults. Palette source: [ggsci NPG documentation](https://nanx.me/ggsci/reference/pal_npg.html).

<a id="plot-customization-growth"></a>

### 4. 设置生长图的范围和文字 / Set the growth-plot range and text

```r
plot_VB(b, se = FALSE, ylab = "Length (cm)",
        axis_text_size = 12, x_breaks = c(1, 5, 10, 15),
        age_range = c(1, 15), text_size = 4)
```

`age_range = NULL` 时，`plot_VB()` 使用拟合结果中的年龄范围（没有年龄元数据的结果用 1-25 岁），起点不早于 `t0`；没有正跨度时报错。显式范围必须是两个有限、递增的年龄，且起点不早于 `t0`，以避免在生长曲线起点之前出现负体长。曲线和区间都继承 `ylab$growth` 和所选字体，显式 `ylab` 覆盖全局标签，Linf/k 标注遵守 `text_size` 和 `text_color`。如果 `se = TRUE` 但协方差不可用，函数会给出警告并只画曲线。

`plot_VB()` uses the fitted age range when `age_range = NULL` (1-25 years for a result without age metadata), starting no earlier than `t0`; a range with no positive span produces an error. An explicit range must contain two finite increasing ages and start at or after `t0`, which avoids negative predicted lengths before the growth curve begins. Curves and intervals inherit `ylab$growth` and the selected font, an explicit `ylab` overrides the global label, and the Linf/k annotation honors `text_size` and `text_color`. If the covariance is unavailable and `se = TRUE`, the function warns and draws only the curve.

<a id="plot-customization-labels"></a>

### 5. 设置全局标签与坐标轴 / Set global labels and axes

```r
acl_theme_set(
  titles = list(SSB = "Spawning biomass",
                SSB_se = "Spawning biomass with 95% intervals"),
  xlab = list(year = "Survey year"),
  ylab = list(ssb = "Spawning biomass"),
  x_breaks = c(2000, 2009, 2019), x_expand = c(0, 0)
)
plot_SSB(b, se = TRUE)
acl_theme_reset()
```

`plot_SSB()`、`plot_biomass()`、`plot_abundance()` 和 `plot_catch()` 的总量、年龄和体长模式，无论是否显示区间，都继承全局 `titles`、`xlab`、`ylab`、`x_breaks` 和 `x_expand`。SSB 的纵轴使用 `ylab$ssb`；标题使用数量键，区间版本加 `_se`。这些设置只改变标签和显示范围，网格线保持隐藏。调用中给出的 `title`、`xlab`、`ylab` 替换主题标签，字体参数（`font_family`、`title_size`、`axis_title_size`、`axis_text_size`、`strip_text_size`、`legend_text_size`、`base_theme`、`title_hjust`）替换对应的主题设置，与其他单模型图一致；`plot_deviance()` 也接受这些参数。

The total, age and length modes of `plot_SSB()`, `plot_biomass()`, `plot_abundance()` and `plot_catch()` inherit the global `titles`, `xlab`, `ylab`, `x_breaks` and `x_expand`, with or without intervals. For SSB, use `ylab$ssb`; titles use the quantity key, with `_se` for interval variants. These settings change labels and display ranges only, and the gridlines stay hidden. A `title`, `xlab` or `ylab` given in the call replaces the theme label, and the typography arguments (`font_family`, `title_size`, `axis_title_size`, `axis_text_size`, `strip_text_size`, `legend_text_size`, `base_theme`, `title_hjust`) replace the corresponding settings, as in every other single-model plot; `plot_deviance()` takes the same arguments.

`plot_fishing_mortality()` 继承同样的设置，标题键为 `F_year`、`F_age` 和 `F_length`（区间版本加 `_se`），横轴使用 `xlab$year`、`xlab$age` 或 `xlab$length`，纵轴使用 `ylab$F`。年龄模式的坐标是组序号，所以在你设置 `xlab$age` 之前默认标签是“Age group”；ACL 的 `type = "length"` 别名使用年龄模式的设置。单次调用中指定的标签和刻度优先。`base_theme` 接受 `"theme_bw"`、`"bw"` 等名称、`ggplot2::theme_bw()` 等主题对象，或 `NULL` 表示全局设置。

`plot_fishing_mortality()` inherits the same settings with the title keys `F_year`, `F_age` and `F_length` (plus `_se`), the horizontal label `xlab$year`, `xlab$age` or `xlab$length` and the vertical label `ylab$F`. Age-mode coordinates are group indices, so the default label is "Age group" until you set `xlab$age`; the ACL `type = "length"` alias uses the age settings. Per-call labels and breaks take precedence. `base_theme` accepts a name such as `"theme_bw"` or `"bw"`, a theme object such as `ggplot2::theme_bw()`, or `NULL` for the global setting.

单模型与比较的调查拟合图使用 `ylab$survey`；未设置时，自定义的 `ylab$abundance` 生效，否则为“Survey index”。对数图加“Log”前缀，显式 `ylab` 优先，`ylab$catch` 只用于捕获量图。

Survey-fit plots, single-model and comparison, use `ylab$survey`; when it is unset, a customized `ylab$abundance` applies, otherwise "Survey index". Log plots add a "Log" prefix, an explicit `ylab` wins, and `ylab$catch` labels the catch plots only.

<a id="plot-customization-next"></a>

### 下一步 / What next

| 想做什么 / What you want to do | 阅读 / Read |
|---|---|
| 选择要画的种群图 / Choose which population plot to draw | [调查与种群图](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md) / [Survey and population plots](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md) |
| 在一张图中比较两次拟合 / Compare two fits in one figure | [模型比较与真值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md) / [Model comparisons](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md) |

<a id="chapter-14"></a>
## 14 全部函数与参数 · Complete function reference

对应 ALSCL 2.4.1，覆盖 **65 个公开函数**。签名及默认值从实际 R 函数提取；每项参数均有中文说明和英文帮助。签名中的 `c(...)` 通常列出可选值，默认取第一项。`NULL` 的含义依函数而异，未必表示停用。

All **65 exported functions** of ALSCL 2.4.1 are covered. Signatures/defaults were extracted from R. Each argument has Chinese guidance and English help. For a choice argument, `c(...)` lists options and the first is the default.

[使用指南 / Guide](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md) · [图谱 / Gallery](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md)

## 示例环境 / Example context

先执行使用指南中的内置数据拟合，得到 `x`、`inputs`、`a`（ACL）、`b`（ALSCL），并设 `dat <- x$data.CatL`。回溯示例生成 `ra`、`rb`；模拟依次运行 `initialize_params`、`sim_cal`、`sim_data`。独立参数函数无需拟合对象。

First run the guide's built-in fitting example to define `x`, `inputs`, `a` and `b`; set `dat <- x$data.CatL`. Retrospective examples define `ra/rb`. Run simulation constructors in order. Standalone biological functions need no fitted model.

```r
library(ALSCL)
library(ggplot2)
library(patchwork)
data(YTF_example)
x <- YTF_example
inputs <- x[c("data.CatL", "data.wgt", "data.mat")]
dat <- x$data.CatL
```

## 索引 / Index

- [simulate_fit](#simulate_fit) — 给定拟合种群状态，或重新抽取其过程偏差后，模拟调查观测。 / Simulate survey observations conditionally on a fitted population or after resampling its process deviations.
- [summarize_simulations](#summarize_simulations) — 使用明确分母汇总模拟偏差、RMSE、区间覆盖率、拟合失败与耗时。 / Summarize simulation bias, RMSE, interval coverage, fitting failures and timing with explicit denominators.
- [sim_model](#sim_model) — 使用统一批次流程，把 ACL 或 ALSCL 拟合到已保存的模拟重复数据。 / Fit ACL or ALSCL to saved simulation replicates using the same batch pipeline.
- [sim_alscl](#sim_alscl) — 使用 ALSCL 拟合模拟批次的便捷入口。 / Convenience interface for simulation batches fitted with ALSCL.
- [save_assessment](#save_assessment) — 保存完整可移植评估 / Save a portable assessment
- [refit_model](#refit_model) — 按保存配方重新拟合 / Refit a stored assessment recipe
- [read_survey_excel](#read_survey_excel) — 读取 Excel 工作簿中的调查、体重和成熟比例工作表。 / Read survey, weight and maturity sheets from an Excel workbook.
- [read_survey_csv](#read_survey_csv) — 从三个 CSV 文件读取对齐的调查、体重和成熟比例数据表。 / Read aligned survey, weight and maturity tables from three CSV files.
- [read_assessment](#read_assessment) — 读取可移植评估存档 / Read a portable assessment archive
- [project_model](#project_model) — 从 ACL 或 ALSCL 拟合末期状态开始，按明确给定的假设推演确定性种群情景。 / Project explicit deterministic population scenarios from the terminal fitted ACL or ALSCL state.
- [profile_model](#profile_model) — 逐网格固定一个自由标量参数，重新优化其余参数及随机效应。 / Fix a free scalar at each grid value and reoptimize the remaining parameters and random effects.
- [prepare_alscl_data](#prepare_alscl_data) — 把三张数据表、三个 CSV 文件或 Excel 工作簿整理为可直接拟合的输入列表。 / Prepare a reusable input bundle from tables, three CSV files or an Excel workbook.
- [hindcast_model](#hindcast_model) — 逐步扩展训练窗口，对真正留出的调查指数进行点预测并评分。 / Fit expanding training windows and score survey-index point predictions against genuinely withheld periods.
- [inspect_parameters](#inspect_parameters) — 查看实际初值、上下界，以及自由、固定或共享的参数状态。 / Inspect effective parameter starts, bounds and free/fixed/tied restrictions.
- [fit_scenarios](#fit_scenarios) — 在同一观测数据上串行或 socket 并行拟合具名敏感性情景。 / Fit named sensitivity scenarios on common observations with serial or socket execution.
- [extract_parameters](#extract_parameters) — 提取参数、尺度与固定状态 / Extract parameters, scales and estimation status
- [extract_estimates](#extract_estimates) — 统一提取带坐标的种群估计 / Extract population estimates with coordinates
- [check_fit](#check_fit) — 用时间–体长热图、按实际时间间隔计算的滞后相关及正态 QQ 图检查条件观测残差。 / Inspect conditional observation residuals with a time–length heatmap, actual-time lag correlations and a normal QQ plot.
- [check_alscl_data](#check_alscl_data) — 在编译或拟合之前检查完整数据和模型设置。 / Check complete data and model settings before compiling or fitting.
- [acl_theme](#acl_theme) — 读取全局主题 / Read global theme settings
- [acl_theme_reset](#acl_theme_reset) — 恢复默认主题 / Reset theme settings
- [acl_theme_set](#acl_theme_set) — 设置全局主题 / Set global theme settings
- [alscl_speed](#alscl_speed) — 设置拟合速度选项 / Set speed options for model fitting
- [alscl_speed_info](#alscl_speed_info) — 查看速度设置的实际效果 / Show how fits will use the speed settings
- [compare_models](#compare_models) — 生成两个模型的数值比较表 / Compare fitted model summaries
- [create_parameters](#create_parameters) — 建立模型初值及边界 / Construct estimation starts and bounds
- [create_parameters_alscl](#create_parameters_alscl) — ALSCL 初值及边界便捷入口 / ALSCL parameter constructor
- [diagnose_model](#diagnose_model) — 汇总诊断指标 / Summarize diagnostics
- [diagnostic_metrics](#diagnostic_metrics) — 计算样本内拟合误差和信息指标 / Calculate in-sample fit errors and information criteria
- [generate_map](#generate_map) — 合并 ACL 默认固定参数与自定义映射 / Merge ACL default and custom maps
- [initialize_params](#initialize_params) — 建立模拟生物参数 / Initialize simulation biology
- [mat_func](#mat_func) — 计算 logistic 成熟比例 / Calculate logistic maturity
- [plot_abundance](#plot_abundance) — 丰度 N / Abundance N
- [plot_biomass](#plot_biomass) — 生物量 B / Biomass B
- [plot_catch](#plot_catch) — 捕获尾数 CN / Catch numbers CN
- [plot_CatL](#plot_CatL) — 调查拟合 length 对数尺度 / Survey fit length log scale
- [plot_compare_annual_F](#plot_compare_annual_F) — 已弃用，改用 plot_compare_F_ts / Deprecated, use plot_compare_F_ts
- [plot_compare_CatL](#plot_compare_CatL) — 两模型调查拟合 / Survey fits from both models
- [plot_compare_F](#plot_compare_F) — 死亡率矩阵比较 / Fishing mortality matrices
- [plot_compare_F_ts](#plot_compare_F_ts) — 各时间步 F 比较 / Fishing mortality by time step
- [plot_compare_growth](#plot_compare_growth) — 生长与外部参照接口 / Growth and reference-data interface
- [plot_compare_metrics](#plot_compare_metrics) — 拟合指标比较 / Fit metric comparison
- [plot_compare_residuals](#plot_compare_residuals) — 残差联合诊断 / Combined residual diagnostics
- [plot_compare_selectivity](#plot_compare_selectivity) — 固定调查可捕性 / Fixed survey catchability
- [plot_compare_ts](#plot_compare_ts) — 种群时间序列比较 / Population time series comparison
- [plot_deviance](#plot_deviance) — 过程偏差 R TRUE / Process deviations R TRUE
- [plot_fishing_mortality](#plot_fishing_mortality) — ACL 捕捞死亡率 year / ACL fishing mortality year
- [plot_pla](#plot_pla) — 年龄长度转换 / Age length conversion
- [plot_recruitment](#plot_recruitment) — 补充量 / Recruitment
- [plot_residuals](#plot_residuals) — 对数残差 length / Log residuals length
- [plot_retro](#plot_retro) — ACL 回溯分析 / ACL retrospective analysis
- [plot_ridges](#plot_ridges) — 长度组成山脊图 / Length composition ridges
- [plot_SSB](#plot_SSB) — 产卵生物量 SSB / Spawning biomass SSB
- [plot_SSB_Rec](#plot_SSB_Rec) — 亲体与补充关系 / Spawning biomass and recruitment
- [plot_VB](#plot_VB) — 生长曲线与区间 / Growth curve and interval
- [retro_acl](#retro_acl) — ACL 回溯入口 / ACL retrospective wrapper
- [retro_alscl](#retro_alscl) — ALSCL 回溯入口 / ALSCL retrospective wrapper
- [retro_model](#retro_model) — 统一回溯分析 / Unified retrospective analysis
- [run_acl](#run_acl) — 拟合年龄型 ACL / Fit age-based ACL
- [run_alscl](#run_alscl) — 拟合年龄与长度联合 ALSCL / Fit joint age-length ALSCL
- [sim_acl](#sim_acl) — 批量拟合 ACL 模拟重复 / Fit simulated replicates with ACL
- [sim_cal](#sim_cal) — 从参数计算生物矩阵 / Calculate biological arrays
- [sim_data](#sim_data) — 运行完整随机种群模拟 / Simulate full population dynamics
- [simulate_example_data](#simulate_example_data) — 快速年度教学数据生成 / Generate simple annual teaching data
- [VB_func](#VB_func) — 计算 VB 平均体长 / Calculate VB mean length

<a id="acl_theme"></a>
## `acl_theme()`

读取全局主题 / Read global theme settings

```r
acl_theme (what = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `what` | `NULL` | NULL 返回全部全局主题设置，字符名称返回单项。 | Optional character. Retrieve a specific element, e.g. "titles", "font_family", "compare_colors". |

**返回 / Returns:** `what=NULL` 时返回完整设置列表，否则返回指定设置项。

The complete settings list when `what=NULL`, or the requested setting otherwise.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
acl_theme()
acl_theme("line_color")
```

![示例图 / Example figure: `plot_SSB(b, se = TRUE) under each palette of acl_theme_set()`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/palettes/ssb_by_palette.png?raw=true&v=3e6eab644390)

<a id="acl_theme_reset"></a>
## `acl_theme_reset()`

恢复默认主题 / Reset theme settings

```r
acl_theme_reset ()
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|

**返回 / Returns:** 重置选项并打印提示后，不可见地返回 NULL。

Invisibly returns NULL after resetting the option and printing a confirmation.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
acl_theme_reset()
```

<a id="acl_theme_set"></a>
## `acl_theme_set()`

设置全局主题 / Set global theme settings

省略的 `line_size` 与 `se_alpha` 参数继承 `acl_theme_set()`（默认 1.5 与 0.2），函数显式参数优先。比较曲线遵守 `linetypes` 与 `compare_linetypes`，残差和指标组合图的标题及 F 分面文字继承全局字体设置。默认无网格。

Omitted `line_size` and `se_alpha` arguments inherit `acl_theme_set()` (defaults 1.5 and 0.2); explicit function arguments take priority. Comparison curves honor `linetypes` and `compare_linetypes`, and the titles of the combined residual and metric plots and the F facet labels inherit the global typography. Grid lines are absent by default.

```r
acl_theme_set (base_theme = NULL, font_family = NULL, title_size = NULL, title_hjust = NULL,
    axis_title_size = NULL, axis_text_size = NULL, strip_text_size = NULL, legend_text_size = NULL,
    x_breaks = NULL, x_expand = NULL, line_color = NULL, line_size = NULL, point_size = NULL,
    se_color = NULL, se_alpha = NULL, compare_colors = NULL, compare_linetypes = NULL,
    compare_line_size = NULL, compare_point_size = NULL, compare_se_alpha = NULL,
    compare_legend_pos = NULL, compare_facet_ncol = NULL, compare_facet_scales = NULL,
    titles = NULL, xlab = NULL, ylab = NULL, palette = NULL, point_color = NULL,
    observed_color = NULL, smooth_color = NULL, hline_color = NULL, low_col = NULL,
    high_col = NULL, ...)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character. Base ggplot2 theme name. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character. Font family for all text. |
| `title_size` | `NULL` | 图标题字号。 | Numeric. Plot title size in pt. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric. Title alignment (0=left, 0.5=center, 1=right). |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric. Axis title size. |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric. Axis tick label size. |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric. Facet label size. |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric. Legend text size. |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector or NULL. Custom x-axis breaks. |
| `x_expand` | `NULL` | 横轴留白设置，长度 2 的数值向量。 | Numeric vector of length 2. X-axis expansion. |
| `line_color` | `NULL` | 单模型线条颜色。 | Character. Default line color for single-model plots. |
| `line_size` | `NULL` | NULL 继承全局 line_size，显式值优先。 | NULL inherits global line_size; explicit values take priority. |
| `point_size` | `NULL` | 所有含点图的默认点大小（2.5）；比较图可单独覆盖。 | Default point size for all point-drawing plots (2.5); comparison plots can override it. |
| `se_color` | `NULL` | 区间阴影或误差棒的颜色。 | Character. Default CI color. |
| `se_alpha` | `NULL` | NULL 继承全局 se_alpha，显式值优先。 | NULL inherits global se_alpha; explicit values take priority. |
| `compare_colors` | `NULL` | 按两个模型顺序提供两种颜色；名称可选。 | Character vector of 2 colors. Can be unnamed (positional) or named. The first color is always model1, second is model2. Examples: c("blue", "red"), c(ACL = "blue", ALSCL = "red"), c("M=0" = "steelblue", "M=0.5" = "tomato"). |
| `compare_linetypes` | `NULL` | 按模型顺序提供两种线型。 | Character vector of 2 linetypes. Same rules as colors. |
| `compare_line_size` | `NULL` | 比较图全局线宽。 | Numeric. Line width for comparison plots. |
| `compare_point_size` | `NULL` | 可选的比较图点大小；显式 NULL 清除覆盖，恢复继承 point_size。 | Optional comparison point-size override; explicit NULL clears it and restores point_size inheritance. |
| `compare_se_alpha` | `NULL` | 比较图区间透明度。 | Numeric. CI ribbon alpha for comparison plots. |
| `compare_legend_pos` | `NULL` | 图例位置，如 bottom、right、none。 | Character. Legend position for comparison plots. |
| `compare_facet_ncol` | `NULL` | 比较图全局分面列数。 | Integer. Default facet columns in comparison plots. |
| `compare_facet_scales` | `NULL` | 比较图全局分面尺度。 | Character. Facet scales for comparison plots. |
| `titles` | `NULL` | 以图名为键的标题列表，用于全局覆盖。 | Named list. Override specific titles. |
| `xlab` | `NULL` | 坐标轴标签；主题设置函数中使用命名列表。 | Named list. Override specific x-axis labels. |
| `ylab` | `NULL` | 坐标轴标签；主题设置函数中使用命名列表。 | Named list. Override specific y-axis labels. |
| `palette` | `NULL` | ggsci 色板名；NULL 继承全局设置，部分图也保留旧色板。 | Character or NULL. ggsci palette: "npg" (default), "aaas", "nejm", "lancet", or "jama". Changing it resets palette-derived colors; explicit color arguments in the same call take precedence. No arguments leaves settings unchanged; use acl_theme_reset() to reset. |
| `point_color` | `NULL` | 点颜色。 | Character or NULL. Default point, observation, smoother and reference-line colors. |
| `observed_color` | `NULL` | 观测数据颜色；NULL 继承全局角色。 | Character or NULL. Default point, observation, smoother and reference-line colors. |
| `smooth_color` | `NULL` | 残差平滑线颜色。 | Character or NULL. Default point, observation, smoother and reference-line colors. |
| `hline_color` | `NULL` | 残差零参考线颜色。 | Character or NULL. Default point, observation, smoother and reference-line colors. |
| `low_col` | `NULL` | 概率热图的低值 / 高值颜色。 | Character or NULL. Continuous heatmap endpoints. |
| `high_col` | `NULL` | 概率热图的低值 / 高值颜色。 | Character or NULL. Continuous heatmap endpoints. |
| `...` | 可选 / optional | 旧参数名 compare_linewidth，仍可使用但会给出警告。 | The former argument name compare_linewidth, accepted with a warning. |

**返回 / Returns:** 不可见地返回原 `acl.theme` 选项，并更新当前全局选项。

The previous `acl.theme` option, returned invisibly. The active global option is updated.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
acl_theme_set(base_theme = "bw", line_color = "navy")
```

![示例图 / Example figure: `acl_theme_set(palette = "npg")`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/palettes/palettes.png?raw=true&v=b700769161ed)

<a id="alscl_speed"></a>
## `alscl_speed()`

Installed socket workers load the same package installation as the parent. During `pkgload::load_all()` or `testthat::test_local()`, workers instead load the same source checkout with pkgload. Install the optional development dependency pkgload for this workflow. CI exercises both source-mode parallel tests and the complete installed-package checks.

```r
alscl_speed (sd_cores = getOption("ALSCL.sd_cores", "auto"), framework = getOption("ALSCL.framework",
    "CppAD"))
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `sd_cores` | `getOption("ALSCL.sd_cores", "auto")` | 单次拟合中计算标准误所用的核数，结果与顺序计算逐位相同。"auto" 最多使用 4 个物理核并保留 1 个；macOS、Linux 终端中用分叉进程计算 Hessian 与 delta 方法，在 Windows、图形界面（R.app、RGui、RStudio、Positron）及 Apple Accelerate BLAS 下改用 socket 进程计算 delta 方法。 | "auto" or a positive integer. Cores used within one fit to compute standard errors; results are identical to the sequential calculation. "auto" uses up to four physical cores and keeps one free; forked processes compute the Hessian and the delta method on macOS and Linux, and socket workers compute the delta method on Windows, in GUI front-ends and with Apple's Accelerate BLAS. |
| `framework` | `getOption("ALSCL.framework", "CppAD")` | TMB 编译模型所用的自动微分库。"CppAD" 为默认库；"TMBad" 更快但结果略有不同。收尾步骤可能微调最优点，不保证与旧版本逐位一致。 | Character. Automatic-differentiation library: "CppAD" is the default; "TMBad" is faster but results differ slightly. The refinement steps can move the optimum slightly, so results are not guaranteed to be identical across versions. |

**返回 / Returns:** 不可见地返回原 `ALSCL.sd_cores` 与 `ALSCL.framework` 选项，可用 `options(old)` 恢复。

The previous `ALSCL.sd_cores` and `ALSCL.framework` options, returned invisibly; `options(old)` restores them.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
old <- alscl_speed(sd_cores = 1)
alscl_speed(framework = "TMBad")
options(old)
```

<a id="alscl_speed_info"></a>
## `alscl_speed_info()`

查看速度设置的实际效果 / Show how fits will use the speed settings

```r
alscl_speed_info ()
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|

**返回 / Returns:** 带有 alscl_speed_info 类的两列数据框：item 是设置或说明项目，value 是其值。内容包括标准误核数、计算方式及原因、自动微分框架、TMB 版本及跨版本数值一致性提示。

A data frame with class alscl_speed_info and columns item (setting or information item) and value. It reports standard-error workers, computation method and reason, the automatic-differentiation framework, the TMB version and the cross-version numerical-identity notice.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
alscl_speed_info()
```

<a id="compare_models"></a>
## `compare_models()`

生成两个模型的数值比较表 / Compare fitted model summaries

拟合、诊断和模型比较统一解析普通 data.frame、matrix、tibble 及保存数值文本的 factor 列。因子按标签转为观测值，不使用内部等级编码；体长标签按向量提取。修改了观测值、缺测掩码、年份或体长组顺序时，原有匹配检查仍会报错。

Fitting, diagnostics and comparison use the same interpretation of ordinary data frames, matrices, tibbles and numeric-text factor columns. Factor labels are converted to observation values, never to internal level codes. Length labels are extracted as a vector. The checks for changed observations, missing-data masks, time labels and length-bin order still apply.

```r
compare_models (model1, model2, data.CatL, model1_name = NULL, model2_name = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model1` | `必填 / required` | 第一个拟合对象。 | A list from run_acl or run_alscl. Treated as the reference model. |
| `model2` | `必填 / required` | 第二个拟合对象。 | A list from run_acl or run_alscl. Treated as the alternative model. |
| `data.CatL` | `必填 / required` | 调查数量指数表：首列体长标签，其余列为时间。 | The original survey numbers-at-length or index table used for in-sample goodness-of-fit. |
| `model1_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Label for model1. Default is auto-detected from model_type. |
| `model2_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Label for model2. Default is auto-detected from model_type. |

**返回 / Returns:** 不可见地返回列表：summary 为优化状态、目标函数、信息准则和耗时比较；growth 为生长参数；fit_metrics 为样本内调查拟合误差；correlation 为共同种群时间序列的 Pearson 相关系数及均值比 Ratio_Mean（model2/model1）。fit_diagnostics 保存数值诊断；comparison 包含数据是否核验（data_verified）、比较是否满足条件（eligible）、满足条件时的优选标签（preferred）及问题（issues）。model1_name 和 model2_name 保存显示标签。

Invisibly returns a list: summary compares optimizer status, objectives, information criteria and timing; growth contains growth parameters; fit_metrics contains in-sample survey-fit errors; correlation contains Pearson correlations and Ratio_Mean (model2/model1) for shared population series. fit_diagnostics records numerical diagnostics. comparison contains data_verified, eligible, preferred and issues; a preference is reported only when comparison conditions are met. model1_name and model2_name retain display labels.

**检查 / Checks:** 要求相同时间、体长标签、正观测及缺失掩码；不匹配报错。返回 fit_diagnostics 和 comparison；不合格拟合或无法核验的旧结果保留原始 AIC，但不自动推荐模型。 / Requires matching periods, length labels, positive observations and masks. Returns fit_diagnostics and comparison; failed or unverifiable fits retain raw AIC without an automatic preference.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
compare_models(a, b, dat)
```

<a id="create_parameters"></a>
## `create_parameters()`

建立模型初值及边界 / Construct estimation starts and bounds

`create_parameters(species = "krill", model_type = "acl")` 提供 Linf 初值 90 和边界，不会自动固定 Linf，也不更改 M、nage 或时间步长。需要固定时，显式传入 `map = list(log_Linf = factor(NA))` 和选定初值；生物设置仍需在拟合参数中提供。

`create_parameters(species = "krill", model_type = "acl")` supplies a Linf start of 90 and bounds, but does not fix Linf or change M, nage or the time step. To fix it, explicitly pass `map = list(log_Linf = factor(NA))` with the chosen starting value. Biological settings still belong in the fitting arguments.

```r
create_parameters (model_type = c("acl", "alscl"), species = NULL, parameters = NULL, parameters.L = NULL,
    parameters.U = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model_type` | `c("acl", "alscl")` | 模型选择：acl 或 alscl。 | Character. Either "acl" or "alscl". Determines which TMB model parameter names and defaults to use. |
| `species` | `NULL` | 物种预设 flatfish、tuna、krill；? 列出预设。 | Character or NULL. Optional species preset: "flatfish" (M7 yellowtail flounder-like, annual, Linf=60), "tuna" (M6 tuna-like, quarterly, Linf=152), or "krill" (Antarctic krill-like, Linf=60-90). When NULL (default), generic wide-range defaults are used. Each preset provides species-specific initial values and bounds that have been tested in simulation studies. See Details. |
| `parameters` | `NULL` | 命名参数初值列表，采用优化器尺度。 | A list of custom initial values (default NULL = use all defaults). Only the parameters you specify will be overridden; all others keep their default (or species-preset) values. |
| `parameters.L` | `NULL` | 命名下界列表，采用优化器尺度。 | A list of custom lower bounds (default NULL). |
| `parameters.U` | `NULL` | 命名上界列表，采用优化器尺度。 | A list of custom upper bounds (default NULL). |

**返回 / Returns:** 包含 parameters（初值）、parameters.L（下界）和 parameters.U（上界）的列表；三个元素均为优化器尺度上的命名列表，名称对应所选 TMB 模型参数。

A list with parameters (starts), parameters.L (lower bounds) and parameters.U (upper bounds). Each is a named list on the optimizer scale, with names matching the selected TMB model.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
create_parameters(model_type = "acl", species = "flatfish")
```

<a id="create_parameters_alscl"></a>
## `create_parameters_alscl()`

ALSCL 初值及边界便捷入口 / ALSCL parameter constructor

`create_parameters(species = "krill", model_type = "acl")` 提供 Linf 初值 90 和边界，不会自动固定 Linf，也不更改 M、nage 或时间步长。需要固定时，显式传入 `map = list(log_Linf = factor(NA))` 和选定初值；生物设置仍需在拟合参数中提供。

`create_parameters(species = "krill", model_type = "acl")` supplies a Linf start of 90 and bounds, but does not fix Linf or change M, nage or the time step. To fix it, explicitly pass `map = list(log_Linf = factor(NA))` with the chosen starting value. Biological settings still belong in the fitting arguments.

```r
create_parameters_alscl (species = NULL, parameters = NULL, parameters.L = NULL, parameters.U = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `species` | `NULL` | 物种预设 flatfish、tuna、krill；? 列出预设。 | Character or NULL. Optional species preset: "flatfish" (M7 yellowtail flounder-like, annual, Linf=60), "tuna" (M6 tuna-like, quarterly, Linf=152), or "krill" (Antarctic krill-like, Linf=60-90). When NULL (default), generic wide-range defaults are used. Each preset provides species-specific initial values and bounds that have been tested in simulation studies. See Details. |
| `parameters` | `NULL` | 命名参数初值列表，采用优化器尺度。 | A list of custom initial values (default NULL = use all defaults). Only the parameters you specify will be overridden; all others keep their default (or species-preset) values. |
| `parameters.L` | `NULL` | 命名下界列表，采用优化器尺度。 | A list of custom lower bounds (default NULL). |
| `parameters.U` | `NULL` | 命名上界列表，采用优化器尺度。 | A list of custom upper bounds (default NULL). |

**返回 / Returns:** 包含 parameters（初值）、parameters.L（下界）和 parameters.U（上界）的列表；三个元素均为优化器尺度上的命名列表，名称对应所选 TMB 模型参数。

A list with parameters (starts), parameters.L (lower bounds) and parameters.U (upper bounds). Each is a named list on the optimizer scale, with names matching the selected TMB model.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
create_parameters_alscl(species = "flatfish")
```

<a id="diagnose_model"></a>
## `diagnose_model()`

汇总诊断指标 / Summarize diagnostics

拟合、诊断和模型比较统一解析普通 data.frame、matrix、tibble 及保存数值文本的 factor 列。因子按标签转为观测值，不使用内部等级编码；体长标签按向量提取。修改了观测值、缺测掩码、年份或体长组顺序时，原有匹配检查仍会报错。

Fitting, diagnostics and comparison use the same interpretation of ordinary data frames, matrices, tibbles and numeric-text factor columns. Factor labels are converted to observation values, never to internal level codes. Length labels are extracted as a vector. The checks for changed observations, missing-data masks, time labels and length-bin order still apply.

```r
diagnose_model (data.CatL, model_result)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `data.CatL` | `必填 / required` | 调查数量指数表：首列体长标签，其余列为时间。 | Length labels followed by time columns. |
| `model_result` | `必填 / required` | 单次模型拟合结果。 | A fitted model result. |

**返回 / Returns:** 包含 Metric（指标名称）和 Value（数值）的数据框，合并样本内拟合误差与优化、梯度、Hessian 和边界诊断；已有 diagnostics 时还包括数值筛查、协方差条件数及高相关参数对数量。未定义或不可用的指标为 NA，同时在控制台打印主要诊断。

A data frame with Metric and Value, combining in-sample fit metrics with optimizer, gradient, Hessian and boundary diagnostics. When diagnostics are available, it also includes the numerical screen, covariance condition number and count of highly correlated parameter pairs. Undefined or unavailable metrics are NA; key diagnostics are also printed.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
diagnose_model(dat, b)
```

<a id="diagnostic_metrics"></a>
## `diagnostic_metrics()`

计算样本内拟合误差和信息指标 / Calculate in-sample fit errors and information criteria

拟合、诊断和模型比较统一解析普通 data.frame、matrix、tibble 及保存数值文本的 factor 列。因子按标签转为观测值，不使用内部等级编码；体长标签按向量提取。修改了观测值、缺测掩码、年份或体长组顺序时，原有匹配检查仍会报错。

Fitting, diagnostics and comparison use the same interpretation of ordinary data frames, matrices, tibbles and numeric-text factor columns. Factor labels are converted to observation values, never to internal level codes. Length labels are extracted as a vector. The checks for changed observations, missing-data masks, time labels and length-bin order still apply.

```r
diagnostic_metrics (data.CatL, model_result)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `data.CatL` | `必填 / required` | 调查数量指数表：首列体长标签，其余列为时间。 | Length labels followed by time columns. |
| `model_result` | `必填 / required` | 单次模型拟合结果。 | A fitted ACL or ALSCL result. |

**返回 / Returns:** 包含 Metric（指标名称）和 Value（数值）的样本内拟合指标数据框；未定义的指标为 NA。

A data frame of in-sample fit metrics with columns Metric and Value. Undefined metrics are NA.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
diagnostic_metrics(dat, b)
```

<a id="generate_map"></a>
## `generate_map()`

合并 ACL 默认固定参数与自定义映射 / Merge ACL default and custom maps

```r
generate_map (map = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `map` | `NULL` | TMB 映射；factor(NA) 固定，具名 NULL 项释放该项；整个 map=NULL 则使用模型默认固定规则。 | A list containing the custom values for the map elements (default is NULL). log_std_log_F: Custom value for log_std_log_F (default is NA). logit_log_F_y: Custom value for logit_log_F_y (default is NA). logit_log_F_a: Custom value for logit_log_F_a (default is NA). t0: Custom value for t0 (default is NA). Growth parameters log_vbk and log_Linf are free unless explicitly mapped. |

**返回 / Returns:** 合并 ACL 默认规则与用户设置后的具名 TMB 映射列表。factor(NA) 固定参数；具名 NULL 项解除该项默认固定。

A named TMB mapping list combining ACL defaults and supplied settings. factor(NA) fixes a parameter; a named NULL entry releases that default fix.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
generate_map(list(log_Linf = factor(NA), logit_log_F_y = NULL))
```

该函数提供 ACL 默认映射。ALSCL 请使用本例 `x$fit_config$alscl$map` 或模型相应命名参数。默认 `t0/log_std_log_F/logit_log_F_y/logit_log_F_a` 固定，`log_vbk/log_Linf` 默认可估计；自定义未列出的项仍保留默认映射。 / This constructor uses ACL defaults. Use model-specific names for ALSCL. Unmentioned default mappings remain in force.

注意：`generate_map()` 返回值会移除 NULL 项。不要用 `run_acl(x, map = generate_map(list(t0 = NULL)))` 解除 t0，因为拟合函数会再次补入默认项。应直接用 `run_acl(x, map = list(t0 = NULL))`。`map = NULL` 和 `list()` 都是使用模型默认规则，不是全部释放。

The returned map drops NULL entries. Do not use `run_acl(x, map = generate_map(list(t0 = NULL)))` to release t0: the fitter will reapply the absent default. Pass `run_acl(x, map = list(t0 = NULL))` directly. A whole `map = NULL` or `list()` uses model defaults rather than releasing everything.

<a id="initialize_params"></a>
## `initialize_params()`

建立模拟生物参数 / Initialize simulation biology

```r
initialize_params (nyear = NULL, rec.age = NULL, first.year = NULL, nage = NULL, M = NULL,
    init_Z = NULL, vbk = NULL, Linf = NULL, t0 = NULL, len_mid = NULL, len_border = NULL,
    a = NULL, b = NULL, mat_L50 = NULL, mat_L95 = NULL, cv_L = NULL, cv_inc = NULL,
    std_logR = NULL, std_logN0 = NULL, alpha = NULL, beta = NULL, std_SN = NULL,
    q_surv_L50 = NULL, q_surv_L95 = NULL, R_init = NULL, F_mean = NULL, F_ar = NULL,
    F_sd = NULL, R_ar = NULL, species = NULL, growth_step = NULL, burn_in = NULL,
    observation_error = c("independent", "shared_time"))
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `nyear` | `NULL` | 模拟器为总年数；回溯函数为删除的末端时间步数。 | Integer. Total simulation years including burn-in (default 100). |
| `rec.age` | `NULL` | 补充年龄，单位为年。 | Numeric. Age of recruitment (default 1; use 0.25 for quarterly). |
| `first.year` | `NULL` | 模拟返回观测的起始年份标签。 | Numeric. First retained observation year (default 2020); fractional years are allowed. |
| `nage` | `NULL` | 年龄组数量，包括最大年龄加组。 | Integer. Number of age classes including plus-group (default 15). |
| `M` | `NULL` | 每个模型时间步的自然死亡瞬时率。 | Numeric. Natural mortality rate (default 0.2). |
| `init_Z` | `NULL` | 构造初始平衡年龄结构的总死亡率。 | Numeric. Initial total mortality for equilibrium (default 0.5). |
| `vbk` | `NULL` | VB 生长系数，以年为时间单位。 | Numeric. Von Bertalanffy k (default 0.2). |
| `Linf` | `NULL` | VB 渐近体长，与输入体长单位一致。 | Numeric. Asymptotic length (default 60). |
| `t0` | `NULL` | VB 理论零体长年龄，单位为年。 | Numeric. Von Bertalanffy t0 (default 1/60). |
| `len_mid` | `NULL` | 每个体长组的中心值向量，长度与数据行数相同。 | Numeric vector. Midpoints of length bins. |
| `len_border` | `NULL` | 体长边界；拟合入口需要 nlen-1 个内部边界，模拟器使用 nlen+1 个完整边界。 | Complete boundary vector of nlen+1 entries, including outer boundaries. |
| `a` | `NULL` | 长度重量关系 W=a*L^b 的系数，需匹配单位。 | Numeric. Length-weight coefficient (default exp(-12)). |
| `b` | `NULL` | 长度重量关系 W=a*L^b 的指数。 | Numeric. Length-weight exponent (default 3). |
| `mat_L50` | `NULL` | 成熟比例为 0.5 的体长。 | Numeric. Length at 50 pct maturity (default 35). |
| `mat_L95` | `NULL` | 比例为 0.95 的体长，必须不同于 L50；下降选择性可小于 L50。 | Numeric. Length at 95 pct maturity (default 40). |
| `cv_L` | `NULL` | 给定年龄时体长的变异系数。 | Numeric. CV of length-at-age (default 0.2). |
| `cv_inc` | `NULL` | 生长增量的变异系数。 | Numeric. CV of growth increment (default 0.2). |
| `std_logR` | `NULL` | 模拟对数补充偏差的 SD 缩放。 | Numeric. SD of log-recruitment deviations (default 0.3). |
| `std_logN0` | `NULL` | 初始对数年龄组尾数偏差的 SD。 | Numeric. SD of initial log-N deviations (default 0.2). |
| `alpha` | `NULL` | Beverton–Holt 补充关系系数，量纲随丰度与生物量单位改变。 | Numeric. Beverton-Holt alpha (default 400). |
| `beta` | `NULL` | Beverton–Holt 补充关系系数，量纲随丰度与生物量单位改变。 | Numeric. Beverton-Holt beta (default 10). |
| `std_SN` | `NULL` | 调查观测对数误差的标准差。 | Numeric. Survey observation error SD (default 0.2). |
| `q_surv_L50` | `NULL` | 调查可捕性达到 0.5 的体长。 | Length at survey catchability 0.5; the default depends on the species preset. |
| `q_surv_L95` | `NULL` | 调查可捕性达到 0.95 的体长，必须大于 q_surv_L50。 | Length at survey catchability 0.95, greater than q_surv_L50; the default depends on the species preset. |
| `R_init` | `NULL` | 初始补充尾数。 | Numeric. Initial recruitment (default 500). |
| `F_mean` | `NULL` | 每模型时间步的乘法 F 基准水平；不是生成序列的算术平均值。 | Multiplicative F baseline per model step; not the arithmetic mean of the realized trajectory. |
| `F_ar` | `NULL` | 模拟对数 F 过程的 AR(1) 相关参数。 | Numeric. AR(1) correlation of the simulated log-F process (default 0.75). |
| `F_sd` | `NULL` | 对数 F 的 AR(1) 创新标准差；平稳标准差为 F_sd / sqrt(1 - F_ar^2)。 | Innovation SD of the log-F AR(1) process; stationary SD is F_sd / sqrt(1 - F_ar^2). |
| `R_ar` | `NULL` | 模拟补充偏差的 AR(1) 相关参数。 | Numeric. AR1 coefficient for recruitment deviations (default 0.1). |
| `species` | `NULL` | 物种预设 flatfish、tuna、krill；? 列出预设。 | Character or NULL. Species preset name, one of "flatfish", "tuna", "krill", or "?" to list presets. NULL (default) uses generic defaults equivalent to flatfish. |
| `growth_step` | `NULL` | 每个时间步包含的年数；季度为 0.25。 | Time step in years; defaults to the species preset. |
| `burn_in` | `NULL` | 模拟预热年数，必须对齐 growth_step 且小于总模拟年数。 | Burn-in duration in years; must be a whole number of model steps and less than the simulation duration. |
| `observation_error` | `c("independent", "shared_time")` | independent：各单元独立；shared_time：同一期共享误差。 | Independent lognormal errors per length and time cell, or shared_time for an explicitly misspecified, perfectly correlated scenario. |

**返回 / Returns:** 包含物种、年龄/时间/体长网格、生长、死亡率、补充、观测和过程设置的命名参数列表。

A named parameter list with species, age/time/length grids, growth, mortality, recruitment, observation and process settings.

快速年度模拟器的 `mean_F` 等于生成 F 序列的算术平均值；`mean_F = 0` 生成零捕捞死亡率。

完整模拟器的 `nyear`、`burn_in` 都以年为单位，且分别必须对应整数个 `growth_step`。因此季度模式允许半年预热，年度模式不允许。返回的 `sm$nyear` 是保留时间步数；`first.year` 是第一期保留观测的年份，`sm$years` 保存完整观测时间轴。`simulation_to_tables()` 和 `sim_acl()` 保留这条时间轴；完全没有年份元数据的旧文件仍可使用从 2000 开始的后备规则。只保留一期时仍返回矩阵，但拟合至少需要两期。

`sim_acl()` 在发送 socket 任务前求值路径与参数变量，因此一般控制台或脚本中的变量传参也支持多核。保留失败重复并检查逐次拟合诊断；工作进程运行成功并不单独证明评估结果可用。

In the quick annual simulator, `mean_F` is the arithmetic mean of the generated F trajectory; `mean_F = 0` generates zero F.

For the full simulator, `nyear` and `burn_in` are durations in years and must each contain a whole number of `growth_step` intervals. Thus a half-year burn-in is valid with quarterly steps, but not annual steps. Returned `sm$nyear` counts retained steps. `first.year` labels the first retained observation, and `sm$years` records the complete retained calendar. `simulation_to_tables()` and `sim_acl()` preserve this calendar; old files lacking year metadata still have a documented 2000-based fallback. A single retained period stays a matrix, although fitting requires at least two periods.

`sim_acl()` resolves path and parameter variables before sending tasks to socket workers, so ordinary console/script calls work with multiple cores. Retain failed replicates and inspect each fit's diagnostics; successful worker execution alone does not establish a usable assessment.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
pa <- initialize_params(species = "flatfish", nyear = 100, burn_in = 80)
```

表中 NULL 表示从物种预设取值，英文括号中的数值是通用/flatfish 基线，并非所有物种的默认值。查看 `str(initialize_params(species="tuna"))` 得到完整季度预设。 / NULL inherits the selected preset; numeric defaults mentioned in help describe the generic/flatfish baseline.


完整模拟器的 `F_mean` 是每模型时间步的乘法基准水平：`F_t = F_mean * exp(u_t)`。`F_sd` 是对数 F 的 AR(1) 过程 `u_t` 的创新标准差，平稳标准差为 `F_sd / sqrt(1 - F_ar^2)`；因此 `F_mean` 不是所生成 F 序列的算术平均值。另一个快速模拟器的 `mean_F` 才表示其生成序列的算术平均值。

In the full simulator, `F_mean` is a multiplicative baseline per model step: `F_t = F_mean * exp(u_t)`. `F_sd` is the innovation SD of the AR(1) process `u_t` on the log-F scale; its stationary SD is `F_sd / sqrt(1 - F_ar^2)`. Thus `F_mean` is not the arithmetic mean of a realized F trajectory. The separate quick simulator uses `mean_F` for its realized arithmetic mean.

<a id="mat_func"></a>
## `mat_func()`

计算 logistic 成熟比例 / Calculate logistic maturity

```r
mat_func (L50, L95, length)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `L50` | `必填 / required` | 成熟比例为 0.5 的体长。 | Length at which 50% of individuals are mature. |
| `L95` | `必填 / required` | 比例为 0.95 的体长，必须不同于 L50；下降选择性可小于 L50。 | Length at which 95% of individuals are mature. |
| `length` | `必填 / required` | 计算成熟比例的体长向量。 | Length of the fish. |

**返回 / Returns:** 所给体长对应的比例数值向量。

A numeric vector of proportions at the supplied lengths.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
mat_func(L50 = 35, L95 = 40, length = seq(6, 50, 2))
```

<a id="plot_abundance"></a>
## `plot_abundance()`

丰度 N / Abundance N

所有模式继承全局标题（N, NA_, NL；区间使用对应的 `_se` 键，年龄丰度为 `NA_se`）、`xlab$year`、`ylab$abundance`、`x_breaks` 与 `x_expand`。调用中给出的 `title`、`xlab`、`ylab`、字体和线条参数优先，默认无网格。

All modes inherit global titles (N, NA_, NL; interval variants use the corresponding `_se` keys, with `NA_se` for abundance at age), `xlab$year`, `ylab$abundance`, `x_breaks` and `x_expand`. A `title`, `xlab`, `ylab`, typography or line argument given in the call takes priority. Default panels have no gridlines.

矩阵行列名称不作为下标；年份及体长标签来自拟合元数据。标准误必须完整、有限且非负。 Matrix dimnames are not indices; time and length labels come from fitted metadata. Standard errors must be complete, finite and nonnegative.

```r
plot_abundance (model_result, line_size = NULL, line_color = NULL, line_type = "solid",
    se = FALSE, se_color = NULL, se_alpha = NULL, type = c("N", "NA", "NL"), facet_ncol = NULL,
    facet_scales = "free", return_data = FALSE, title = NULL, xlab = NULL, ylab = NULL,
    font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL,
    strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL,
    title_hjust = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model_result` | `必填 / required` | 单次模型拟合结果。 | A list from run_acl or run_alscl. |
| `line_size` | `NULL` | NULL 继承全局 line_size，显式值优先。 | NULL inherits global line_size; explicit values take priority. |
| `line_color` | `NULL` | 单模型线条颜色。 | Character or NULL. NULL inherits the global line_color setting. |
| `line_type` | `"solid"` | 线型，如 solid、dashed。 | Character. Line type. Default is "solid". |
| `se` | `FALSE` | 是否绘制可用标准误对应的近似区间。 | Logical. Whether to plot confidence intervals. Default is FALSE. |
| `se_color` | `NULL` | 区间阴影或误差棒的颜色。 | Character or NULL. NULL inherits the global se_color setting. |
| `se_alpha` | `NULL` | NULL 继承全局 se_alpha，显式值优先。 | NULL inherits global se_alpha; explicit values take priority. |
| `type` | `c("N", "NA", "NL")` | N 为总尾数，NA 为年龄别尾数，NL 为体长别尾数。 | Character. "N" (total), "NA" (at age), or "NL" (at length). Default is "N". |
| `facet_ncol` | `NULL` | 分面排列的列数。 | Number of columns in facet wrap. Default is NULL. |
| `facet_scales` | `"free"` | fixed、free、free_x 或 free_y；自由尺度有助观察组内变化。 | Scales for facet wrap. Default is "free". |
| `return_data` | `FALSE` | TRUE 同时返回绘图对象及整理后的数据；结构见返回说明。 | Logical. Whether to return processed data. Default is FALSE. |
| `title` | `NULL` | 自定义图标题；NULL 继承主题。 | Character or NULL. Custom plot title. If NULL, uses global theme setting. See acl_theme_set(). |
| `xlab` | `NULL` | 自定义横轴标签；NULL 继承主题。 | Character or NULL. Custom x-axis label. If NULL, uses global theme setting. |
| `ylab` | `NULL` | 自定义纵轴标签；NULL 继承主题。 | Character or NULL. Custom y-axis label. If NULL, uses global theme setting. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character or NULL. Custom font family. If NULL, uses global theme setting (default "sans"). |
| `title_size` | `NULL` | 图标题字号。 | Numeric or NULL. Plot title size in pt. If NULL, uses global theme (default 14). |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12). |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10). |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10). |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10). |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector or NULL. Custom x-axis breaks (e.g. seq(1, 20, by = 2)). NULL = auto. |
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character or NULL. Base ggplot2 theme name (e.g. "theme_bw"). NULL = global setting. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting. |

**返回 / Returns:** ggplot 对象；`return_data=TRUE` 时返回含 `plot` 和整理后的 `data` 的列表。

A ggplot object; with `return_data=TRUE`, a list with `plot` and the processed `data`.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_abundance(b, type = "N", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

![示例图 / Example figure: `plot_abundance(b, type = "N", se = TRUE, facet_ncol = 3, line_size = 0.6)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_abundance_N.png?raw=true&v=028b3b37517a)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_abundance)。

<a id="plot_biomass"></a>
## `plot_biomass()`

生物量 B / Biomass B

所有模式继承全局标题（B, BL, BA；区间使用对应的 `_se` 键，年龄丰度为 `NA_se`）、`xlab$year`、`ylab$biomass`、`x_breaks` 与 `x_expand`。调用中给出的 `title`、`xlab`、`ylab`、字体和线条参数优先，默认无网格。

All modes inherit global titles (B, BL, BA; interval variants use the corresponding `_se` keys, with `NA_se` for abundance at age), `xlab$year`, `ylab$biomass`, `x_breaks` and `x_expand`. A `title`, `xlab`, `ylab`, typography or line argument given in the call takes priority. Default panels have no gridlines.

捕捞死亡率图按矩阵位置和拟合年份、组别元数据构造坐标，矩阵行列名不会改变坐标。生物量、SSB、捕获量和 F 的年龄分面在有无区间时都按数值组序排列。F 图和时间序列比较在 `se = TRUE` 时要求完整、有限的估计与有限非负标准误；缺失摘要会报错，不再重复填充或静默取消区间。只画估计时请明确使用 `se = FALSE`。

Fishing-mortality plots use matrix positions and fitted time/group metadata, so matrix dimnames cannot alter the coordinates. Age panels in biomass, SSB, catch and F plots retain numeric group order with or without intervals. F plots and time-series comparisons require complete finite estimates and nonnegative finite standard errors when `se = TRUE`; missing summaries are errors rather than recycled values or silently removed intervals. Use `se = FALSE` explicitly for estimates only.

```r
plot_biomass (model_result, line_size = NULL, line_color = NULL, line_type = "solid",
    se = FALSE, se_color = NULL, se_alpha = NULL, type = c("B", "BL", "BA"), facet_ncol = NULL,
    facet_scales = "free", return_data = FALSE, title = NULL, xlab = NULL, ylab = NULL,
    font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL,
    strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL,
    title_hjust = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model_result` | `必填 / required` | 单次模型拟合结果。 | A list from run_acl or run_alscl. |
| `line_size` | `NULL` | NULL 继承全局 line_size，显式值优先。 | NULL inherits global line_size; explicit values take priority. |
| `line_color` | `NULL` | 单模型线条颜色。 | Character or NULL. NULL inherits the global line_color setting. |
| `line_type` | `"solid"` | 线型，如 solid、dashed。 | Character. Line type. Default is "solid". |
| `se` | `FALSE` | 是否绘制可用标准误对应的近似区间。 | Logical. Whether to plot confidence intervals. Default is FALSE. |
| `se_color` | `NULL` | 区间阴影或误差棒的颜色。 | Character or NULL. NULL inherits the global se_color setting. |
| `se_alpha` | `NULL` | NULL 继承全局 se_alpha，显式值优先。 | NULL inherits global se_alpha; explicit values take priority. |
| `type` | `c("B", "BL", "BA")` | B 为总生物量，BA 为年龄别生物量，BL 为体长别生物量。 | Character. "B" (total), "BL" (at length), or "BA" (at age). Default is "B". |
| `facet_ncol` | `NULL` | 分面排列的列数。 | Integer. Columns in facet_wrap. Default is NULL. |
| `facet_scales` | `"free"` | fixed、free、free_x 或 free_y；自由尺度有助观察组内变化。 | Character. Scales for facet_wrap. Default is "free". |
| `return_data` | `FALSE` | TRUE 同时返回绘图对象及整理后的数据；结构见返回说明。 | Logical. Whether to return processed data. Default is FALSE. |
| `title` | `NULL` | 自定义图标题；NULL 继承主题。 | Character or NULL. Custom plot title. If NULL, uses global theme setting. See acl_theme_set(). |
| `xlab` | `NULL` | 自定义横轴标签；NULL 继承主题。 | Character or NULL. Custom x-axis label. If NULL, uses global theme setting. |
| `ylab` | `NULL` | 自定义纵轴标签；NULL 继承主题。 | Character or NULL. Custom y-axis label. If NULL, uses global theme setting. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character or NULL. Custom font family. If NULL, uses global theme setting (default "sans"). |
| `title_size` | `NULL` | 图标题字号。 | Numeric or NULL. Plot title size in pt. If NULL, uses global theme (default 14). |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12). |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10). |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10). |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10). |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector or NULL. Custom x-axis breaks (e.g. seq(1, 20, by = 2)). NULL = auto. |
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character or NULL. Base ggplot2 theme name (e.g. "theme_bw"). NULL = global setting. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting. |

**返回 / Returns:** ggplot 对象；`return_data=TRUE` 时返回含 `plot` 和整理后的 `data` 的列表。

A ggplot object; with `return_data=TRUE`, a list with `plot` and the processed `data`.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_biomass(b, type = "B", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

![示例图 / Example figure: `plot_biomass(b, type = "B", se = TRUE, facet_ncol = 3, line_size = 0.6)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_biomass_B.png?raw=true&v=3d2df45029c9)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_biomass)。

<a id="plot_catch"></a>
## `plot_catch()`

捕获尾数 CN / Catch numbers CN

所有模式继承全局标题（CN, CNA, CNL；区间使用对应的 `_se` 键，年龄丰度为 `NA_se`）、`xlab$year`、`ylab$catch`、`x_breaks` 与 `x_expand`。调用中给出的 `title`、`xlab`、`ylab`、字体和线条参数优先，默认无网格。

All modes inherit global titles (CN, CNA, CNL; interval variants use the corresponding `_se` keys, with `NA_se` for abundance at age), `xlab$year`, `ylab$catch`, `x_breaks` and `x_expand`. A `title`, `xlab`, `ylab`, typography or line argument given in the call takes priority. Default panels have no gridlines.

捕捞死亡率图按矩阵位置和拟合年份、组别元数据构造坐标，矩阵行列名不会改变坐标。生物量、SSB、捕获量和 F 的年龄分面在有无区间时都按数值组序排列。F 图和时间序列比较在 `se = TRUE` 时要求完整、有限的估计与有限非负标准误；缺失摘要会报错，不再重复填充或静默取消区间。只画估计时请明确使用 `se = FALSE`。

Fishing-mortality plots use matrix positions and fitted time/group metadata, so matrix dimnames cannot alter the coordinates. Age panels in biomass, SSB, catch and F plots retain numeric group order with or without intervals. F plots and time-series comparisons require complete finite estimates and nonnegative finite standard errors when `se = TRUE`; missing summaries are errors rather than recycled values or silently removed intervals. Use `se = FALSE` explicitly for estimates only.

```r
plot_catch (model_result, line_size = NULL, line_color = NULL, line_type = "solid",
    se = FALSE, se_color = NULL, se_alpha = NULL, facet_ncol = NULL, facet_scales = "free",
    type = c("CN", "CNA", "CNL"), return_data = FALSE, title = NULL, xlab = NULL,
    ylab = NULL, font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL,
    strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL,
    title_hjust = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model_result` | `必填 / required` | 单次模型拟合结果。 | A list from run_acl or run_alscl. |
| `line_size` | `NULL` | NULL 继承全局 line_size，显式值优先。 | NULL inherits global line_size; explicit values take priority. |
| `line_color` | `NULL` | 单模型线条颜色。 | Character or NULL. NULL inherits the global line_color setting. |
| `line_type` | `"solid"` | 线型，如 solid、dashed。 | Character. Line type. Default is "solid". |
| `se` | `FALSE` | 是否绘制可用标准误对应的近似区间。 | Logical. Whether to plot confidence intervals. Default is FALSE. |
| `se_color` | `NULL` | 区间阴影或误差棒的颜色。 | Character or NULL. NULL inherits the global se_color setting. |
| `se_alpha` | `NULL` | NULL 继承全局 se_alpha，显式值优先。 | NULL inherits global se_alpha; explicit values take priority. |
| `facet_ncol` | `NULL` | 分面排列的列数。 | Numeric. Columns in facet wrap. Default is NULL. |
| `facet_scales` | `"free"` | fixed、free、free_x 或 free_y；自由尺度有助观察组内变化。 | Character. Scales for facet wrap. Default is "free". |
| `type` | `c("CN", "CNA", "CNL")` | CN 为总捕捞尾数，CNA 为年龄别捕捞尾数，CNL 为体长别捕捞尾数。 | Character. "CN" (total), "CNA" (at age), or "CNL" (at length). Default is "CN". |
| `return_data` | `FALSE` | TRUE 同时返回绘图对象及整理后的数据；结构见返回说明。 | Logical. Whether to return processed data. Default is FALSE. |
| `title` | `NULL` | 自定义图标题；NULL 继承主题。 | Character or NULL. Custom plot title. If NULL, uses global theme setting. See acl_theme_set(). |
| `xlab` | `NULL` | 自定义横轴标签；NULL 继承主题。 | Character or NULL. Custom x-axis label. If NULL, uses global theme setting. |
| `ylab` | `NULL` | 自定义纵轴标签；NULL 继承主题。 | Character or NULL. Custom y-axis label. If NULL, uses global theme setting. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character or NULL. Custom font family. If NULL, uses global theme setting (default "sans"). |
| `title_size` | `NULL` | 图标题字号。 | Numeric or NULL. Plot title size in pt. If NULL, uses global theme (default 14). |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12). |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10). |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10). |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10). |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector or NULL. Custom x-axis breaks (e.g. seq(1, 20, by = 2)). NULL = auto. |
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character or NULL. Base ggplot2 theme name (e.g. "theme_bw"). NULL = global setting. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting. |

**返回 / Returns:** ggplot 对象；`return_data=TRUE` 时返回含 `plot` 和整理后的 `data` 的列表。

A ggplot object; with `return_data=TRUE`, a list with `plot` and the processed `data`.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_catch(b, type = "CN", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

![示例图 / Example figure: `plot_catch(b, type = "CN", se = TRUE, facet_ncol = 3, line_size = 0.6)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_catch_CN.png?raw=true&v=c03ee7bf1c85)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_catch)。

<a id="plot_CatL"></a>
## `plot_CatL()`

调查拟合 length 对数尺度 / Survey fit length log scale

标题明确标为调查指数。`facet_by = "year"` 使用 `line_size1` 设置拟合线、`line_size2` 设置观测线；`line_size` 与 `point_size` 仅用于 `facet_by = "length"`。按年份分面时也遵守全局 `CatL_by_year` 标题。

Titles identify survey indices. In `facet_by = "year"`, use `line_size1` for fitted lines and `line_size2` for observed lines; `line_size` and `point_size` control only `facet_by = "length"`. The global `CatL_by_year` title now applies to year facets.

默认 `plot_CatL(exp_transform = FALSE)` 绘制自然对数调查指数，并在纵轴标明尺度；`exp_transform = TRUE` 绘制原尺度调查指数，预测曲线为中位数。显式 `ylab` 覆盖自动标签。山脊图在对数尺度稳定归一化，极大或极小的有限对数预测仍可绘制；非有限预测会报错。

The default `plot_CatL(exp_transform = FALSE)` displays natural-log survey indices and labels that scale explicitly. `exp_transform = TRUE` displays original-scale survey indices; curves are fitted medians. An explicit `ylab` overrides the automatic label. Ridge compositions are normalized stably on the log scale, including very large or small finite log predictions; nonfinite predictions are rejected.

调查拟合图按矩阵位置及拟合年份、体长元数据对齐观测与预测，增删行列名不会改变坐标；缺失及零观测继续排除。若预测取指数会溢出，请使用 `exp_transform = FALSE`。残差图的 `resid_cap` 必须为有限正标量，或以 `NULL` 关闭截断；不再允许负值或零值抹去诊断特征。

Survey fit plots align both observed and predicted matrices by their positions and fitted calendar/length metadata, even if dimnames are added or removed. Missing and zero observations stay excluded. Use `exp_transform = FALSE` if exponentiating predictions would overflow. In residual plots, `resid_cap` must be a finite positive scalar or `NULL` to disable capping; negative or zero caps cannot erase the diagnostic pattern.

```r
plot_CatL (model_result, point_size = NULL, point_color = NULL, point_shape = 16,
    line_size = NULL, line_color = NULL, line_type = "solid", line_size1 = NULL,
    line_color1 = NULL, line_type1 = "solid", line_alpha1 = 1, line_size2 = NULL,
    line_color2 = NULL, line_type2 = "solid", line_alpha2 = 0.6, facet_ncol = NULL,
    facet_scales = "free", facet_by = c("length", "year"), exp_transform = FALSE,
    return_data = FALSE, title = NULL, xlab = NULL, ylab = NULL, font_family = NULL,
    title_size = NULL, axis_title_size = NULL, axis_text_size = NULL, strip_text_size = NULL,
    legend_text_size = NULL, x_breaks = NULL, base_theme = NULL, title_hjust = NULL,
    ...)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model_result` | `必填 / required` | 单次模型拟合结果。 | A list that contains the model output. The list should have a "report" component which contains an "Elog_index" component representing counts in length groups. |
| `point_size` | `NULL` | 点大小；NULL 继承全局 point_size（默认 2.5）。 | Numeric or NULL. NULL inherits the global point_size setting (default 2.5). |
| `point_color` | `NULL` | 点颜色。 | Character or NULL. NULL inherits the global observed_color setting. |
| `point_shape` | `16` | 点形状编号，如 16、21。 | Numeric. Specifies the shape of the point in the plot. Default is 16 (filled circle). Common: 1=open circle, 16=filled circle, 17=triangle, 15=square. |
| `line_size` | `NULL` | NULL 继承全局 line_size，显式值优先。 | NULL inherits global line_size; explicit values take priority. |
| `line_color` | `NULL` | 单模型线条颜色。 | Character or NULL. NULL inherits the global line_color setting. |
| `line_type` | `"solid"` | 线型，如 solid、dashed。 | Character. Line type for type="length" plot. Default is "solid". |
| `line_size1` | `NULL` | NULL 使用全局 line_size 的 1.2 倍。 | NULL uses 1.2 times global line_size. |
| `line_color1` | `NULL` | 拟合曲线颜色；NULL 继承全局 line_color。 | Character or NULL. NULL inherits the global line_color setting. |
| `line_type1` | `"solid"` | 拟合曲线线型。 | Character. Line type for estimated line. Default is "solid". |
| `line_alpha1` | `1` | 拟合曲线透明度（0–1）。 | Numeric. Transparency for estimated line (0-1). Default is 1. |
| `line_size2` | `NULL` | NULL 使用全局 line_size 的 2/3 倍。 | NULL uses 2/3 times global line_size. |
| `line_color2` | `NULL` | 观测曲线颜色；NULL 继承全局 observed_color。 | Character or NULL. NULL inherits the global observed_color setting. |
| `line_type2` | `"solid"` | 观测曲线线型。 | Character. Line type for observed line. Default is "solid". |
| `line_alpha2` | `0.6` | 观测曲线透明度（0–1）。 | Numeric. Transparency for observed line (0-1). Default is 0.6. |
| `facet_ncol` | `NULL` | 分面排列的列数。 | Integer. Specifies the number of columns in the facet_wrap. Default is NULL. |
| `facet_scales` | `"free"` | fixed、free、free_x 或 free_y；自由尺度有助观察组内变化。 | Character. Specifies scales for facet_wrap. Default is "free". |
| `facet_by` | `c("length", "year")` | 布局："length" 每个体长组一个面板、横轴为时间；"year" 每个时间步一个面板、横轴为体长。 | "length" (default) draws one panel per length bin with time on the x axis; "year" draws one panel per time step with length on the x axis. |
| `exp_transform` | `FALSE` | 对数调查值取指数，显示原尺度；拟合曲线是中位数。 | Logical. Specifies whether to apply the exponential function to the data before plotting. If TRUE, the exponential of the data values is plotted. Default is FALSE. |
| `return_data` | `FALSE` | TRUE 同时返回绘图对象及整理后的数据；结构见返回说明。 | A logical indicating whether to return the processed data alongside the plot. Default is FALSE. |
| `title` | `NULL` | 自定义图标题；NULL 继承默认。 | Character or NULL. Custom plot title. If NULL, uses global theme setting. See acl_theme_set(). |
| `xlab` | `NULL` | 自定义横轴标签；NULL 继承主题。 | Character or NULL. Custom x-axis label. If NULL, uses global theme setting. |
| `ylab` | `NULL` | 自定义纵轴标签；NULL 继承主题。 | Character or NULL. Custom y-axis label. If NULL, uses global theme setting. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character or NULL. Custom font family. If NULL, uses global theme setting (default "sans"). |
| `title_size` | `NULL` | 图标题字号。 | Numeric or NULL. Plot title size in pt. If NULL, uses global theme (default 14). |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12). |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10). |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10). |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10). |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector or NULL. Custom x-axis breaks (e.g. seq(1, 20, by = 2)). NULL = auto. |
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character or NULL. Base ggplot2 theme name (e.g. "theme_bw"). NULL = global setting. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting. |
| `...` | 可选 / optional | 旧参数名 type，仍可使用但会给出警告。 | The former argument name type, accepted with a warning. |

**返回 / Returns:** ggplot 对象；`return_data=TRUE` 时返回含 `plot`、`data1`（拟合）、`data2`（观测）的列表。

A ggplot object; with `return_data=TRUE`, a list with `plot`, `data1` (fitted) and `data2` (observed).

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_CatL(b, facet_by = "length", exp_transform = FALSE, facet_ncol = 4,
  point_size = 1, line_size = 0.6,
  x_breaks = c(2000, 2010, 2015),
  ylab = "Log survey index")
```

![示例图 / Example figure: `plot_CatL(b, facet_by = "year", facet_ncol = 4)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/CatL_year_FALSE.png?raw=true&v=27b8dc9d9c6c)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_CatL)。

<a id="plot_compare_annual_F"></a>
## `plot_compare_annual_F()`

已弃用：请改用 plot_compare_F_ts() / Deprecated: use plot_compare_F_ts()

```r
plot_compare_annual_F (...)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `...` | 可选 / optional | 传给 plot_compare_F_ts() 的参数。 | Arguments passed to plot_compare_F_ts(). |

**返回 / Returns:** ggplot 对象。

A ggplot object.

本函数按模型时间步汇总 F，从未把季度值年化，因此更名为 `plot_compare_F_ts()`。旧名每个会话警告一次，以后的版本将删除。

The function summarizes F per model time step and never annualized quarterly values, so it is now called `plot_compare_F_ts()`. The former name warns once per session and will be removed in a later release.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_compare_F_ts(a, b, method = "apical")
```

<a id="plot_compare_CatL"></a>
## `plot_compare_CatL()`

两模型调查拟合 / Survey fits from both models

```r
plot_compare_CatL (model1, model2, data.CatL, years = NULL, model1_name = NULL, model2_name = NULL,
    colors = NULL, linetypes = NULL, line_size = NULL, facet_ncol = 4, facet_scales = "free_y",
    obs_color = "grey40", obs_size = NULL, obs_alpha = 0.6, obs_shape = 16, legend_pos = NULL,
    ..., point_size = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model1` | `必填 / required` | 第一个拟合对象。 | First model result (reference). |
| `model2` | `必填 / required` | 第二个拟合对象。 | Second model result (alternative). |
| `data.CatL` | `必填 / required` | 调查数量指数表：首列体长标签，其余列为时间。 | Original survey numbers-at-length or index data frame. |
| `years` | `NULL` | 年份向量；快速模拟器要求连续年度，比较图用它筛选时期。 | Numeric vector of years to show. Default NULL = all years. Use e.g. years = seq(1991, 2011, by = 2) to select specific years. |
| `model1_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `model2_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `colors` | `NULL` | 按两个模型顺序提供两种颜色；名称可选。 | Named character vector of 2 colors. NULL = use global theme. |
| `linetypes` | `NULL` | 按模型顺序提供两种线型。 | Named character vector of 2 linetypes. NULL = use global theme. |
| `line_size` | `NULL` | 线宽；参数名按函数区别使用。 | Numeric. NULL = use global theme. |
| `facet_ncol` | `4` | 分面排列的列数。 | Integer. Facet columns. Default 4. |
| `facet_scales` | `"free_y"` | fixed、free、free_x 或 free_y；自由尺度有助观察组内变化。 | Character. Facet facet_scales. Default "free_y". |
| `obs_color` | `"grey40"` | 观测点颜色。 | Character. Color for observed points. Default "grey40". |
| `obs_size` | `NULL` | 旧的观测点大小设置；NULL 继承主题。显式 point_size 优先于此值。 | Legacy observed-point size; NULL inherits the theme. An explicit point_size takes priority. |
| `obs_alpha` | `0.6` | 观测点透明度。 | Numeric. Transparency of observed points. Default 0.6. |
| `obs_shape` | `16` | 观测点形状。 | Integer. Shape of observed points. Default 16. |
| `legend_pos` | `NULL` | 图例位置，如 bottom、right、none。 | Character. Legend position. NULL = use global theme. |
| `...` | 可选 / optional | 旧参数名 linewidth、ncol、scales，仍可使用但会给出警告。 | The former argument names linewidth, ncol and scales, accepted with a warning. |
| `point_size` | `NULL` | 点大小；NULL 先使用显式 obs_size，再继承比较图覆盖值或全局 point_size（默认 2.5）。显式值优先。 | Point size; NULL uses an explicit obs_size first, then a comparison override or global point_size (default 2.5). A supplied value takes priority. |

**返回 / Returns:** ggplot 对象，可继续调整样式或用 `ggplot2::ggsave()` 保存。

A ggplot object, suitable for further styling or `ggplot2::ggsave()`.

同一模型的两份结果会自动使用不同图例，例如 `ACL (group_year)` 和 `ACL (year)`，仍支持显式指定不同的 `model1_name`、`model2_name`。时间序列与 F 图保留每份结果自己的真实年份，可以显示不同时间范围。与 `data.CatL` 配对的图会核对已知时间和体长元数据，再匹配观测与预测；网格不一致时明确报错。图形比较不代表似然或生物假设具有可比性。

Comparison plots give distinct default labels to two fits of the same model: for example, `ACL (group_year)` and `ACL (year)`. Explicit distinct `model1_name` and `model2_name` remain supported. Time-series and F plots retain each fit's own calendar, including different time spans. Plots paired with `data.CatL` check known time and length metadata before matching observations to predictions; inconsistent grids are errors. A visual comparison does not establish that likelihoods or biological assumptions are comparable.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_compare_CatL(a, b, dat, years = c(2000, 2005, 2010, 2015), facet_ncol = 2)
```

![示例图 / Example figure: `plot_compare_CatL(a, b, dat, years = c(2000, 2005, 2010, 2015), facet_ncol = 2)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_CatL.png?raw=true&v=06278fecb8b7)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_compare_CatL)。

<a id="plot_compare_F"></a>
## `plot_compare_F()`

死亡率矩阵比较 / Fishing mortality matrices

```r
plot_compare_F (model1, model2, model1_name = NULL, model2_name = NULL, palette = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model1` | `必填 / required` | 第一个拟合对象。 | First model result (reference). |
| `model2` | `必填 / required` | 第二个拟合对象。 | Second model result (alternative). |
| `model1_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `model2_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `palette` | `NULL` | ggsci 色板名；NULL 继承全局设置，部分图也保留旧色板。 | Character or NULL. NULL uses the global sequential colors; a ggsci palette name or a viridis option overrides them. |

**返回 / Returns:** ggplot 对象，可继续调整样式或用 `ggplot2::ggsave()` 保存。

A ggplot object, suitable for further styling or `ggplot2::ggsave()`.

同一模型的两份结果会自动使用不同图例，例如 `ACL (group_year)` 和 `ACL (year)`，仍支持显式指定不同的 `model1_name`、`model2_name`。时间序列与 F 图保留每份结果自己的真实年份，可以显示不同时间范围。与 `data.CatL` 配对的图会核对已知时间和体长元数据，再匹配观测与预测；网格不一致时明确报错。图形比较不代表似然或生物假设具有可比性。

Comparison plots give distinct default labels to two fits of the same model: for example, `ACL (group_year)` and `ACL (year)`. Explicit distinct `model1_name` and `model2_name` remain supported. Time-series and F plots retain each fit's own calendar, including different time spans. Plots paired with `data.CatL` check known time and length metadata before matching observations to predictions; inconsistent grids are errors. A visual comparison does not establish that likelihoods or biological assumptions are comparable.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_compare_F(a, b) + scale_x_continuous(breaks = c(2000, 2010, 2019))
```

![示例图 / Example figure: `plot_compare_F(a, b)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_F.png?raw=true&v=545b8b47191d)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_compare_F)。

<a id="plot_compare_F_ts"></a>
## `plot_compare_F_ts()`

各时间步 F 比较 / Fishing mortality by time step

```r
plot_compare_F_ts (model1, model2, model1_name = NULL, model2_name = NULL, method = c("apical",
    "mean"), colors = NULL, linetypes = NULL, line_size = NULL, ..., point_size = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model1` | `必填 / required` | 第一个拟合对象。 | First model result (reference). |
| `model2` | `必填 / required` | 第二个拟合对象。 | Second model result (alternative). |
| `model1_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `model2_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `method` | `c("apical", "mean")` | apical 取组间最大 F；mean 取非加权均值，不自动年化。 | Character. How to summarize F across age/length groups each model time step; quarterly fits are not aggregated to years. "apical" (default): maximum F across groups -- comparable across age-based and length-based models. "mean": arithmetic mean across all groups -- can be misleading when models differ in dimension (e.g. 20 ages vs 22 length bins with many near-zero). |
| `colors` | `NULL` | 按两个模型顺序提供两种颜色；名称可选。 | Named character vector of 2 colors. NULL = use global theme. |
| `linetypes` | `NULL` | 按模型顺序提供两种线型。 | Named character vector of 2 linetypes. NULL = use global theme. |
| `line_size` | `NULL` | 线宽；参数名按函数区别使用。 | Numeric. NULL = use global theme. |
| `...` | 可选 / optional | 旧参数名 linewidth，仍可使用但会给出警告。 | The former argument name linewidth, accepted with a warning. |
| `point_size` | `NULL` | 点大小；NULL 优先继承比较图覆盖值，否则继承全局 point_size（默认 2.5）。显式值优先。 | Point size; NULL inherits an explicit comparison override or global point_size (default 2.5). A supplied value takes priority. |

**返回 / Returns:** ggplot 对象，可继续调整样式或用 `ggplot2::ggsave()` 保存。

A ggplot object, suitable for further styling or `ggplot2::ggsave()`.

同一模型的两份结果会自动使用不同图例，例如 `ACL (group_year)` 和 `ACL (year)`，仍支持显式指定不同的 `model1_name`、`model2_name`。时间序列与 F 图保留每份结果自己的真实年份，可以显示不同时间范围。与 `data.CatL` 配对的图会核对已知时间和体长元数据，再匹配观测与预测；网格不一致时明确报错。图形比较不代表似然或生物假设具有可比性。

Comparison plots give distinct default labels to two fits of the same model: for example, `ACL (group_year)` and `ACL (year)`. Explicit distinct `model1_name` and `model2_name` remain supported. Time-series and F plots retain each fit's own calendar, including different time spans. Plots paired with `data.CatL` check known time and length metadata before matching observations to predictions; inconsistent grids are errors. A visual comparison does not establish that likelihoods or biological assumptions are comparable.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_compare_F_ts(a, b, method = "apical") +
  labs(title = "Apical fishing mortality")
```

![示例图 / Example figure: `plot_compare_F_ts(a, b, method = "apical")`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_F_apical.png?raw=true&v=04d0e9ec5dd1)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_compare_F_ts)。

<a id="plot_compare_growth"></a>
## `plot_compare_growth()`

生长与外部参照接口 / Growth and reference-data interface

提供 `ref_data` 时，`ref_name` 必须为非空字符串，且与两个模型标签均不同；重复名称会在拟合参考曲线前报错。

When supplying `ref_data`, use a nonempty `ref_name` distinct from both model labels; duplicate names are rejected before fitting the reference curve.

```r
plot_compare_growth (model1, model2, age_range = c(1, 20), model1_name = NULL, model2_name = NULL,
    colors = NULL, linetypes = NULL, line_size = NULL, ref_data = NULL, ref_name = "Observed VB",
    ref_color = "grey30", ref_linetype = "dotdash", show_points = TRUE, point_size = NULL,
    point_alpha = 0.4, nls_start = NULL, ...)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model1` | `必填 / required` | 第一个拟合对象。 | First model result (reference). |
| `model2` | `必填 / required` | 第二个拟合对象。 | Second model result (alternative). |
| `age_range` | `c(1, 20)` | 生长图的年龄上下限，单位为年。 | Numeric vector of length 2. Default c(1, 20). |
| `model1_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `model2_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `colors` | `NULL` | 按两个模型顺序提供两种颜色；名称可选。 | Named character vector of 2 colors. NULL = use global theme. |
| `linetypes` | `NULL` | 按模型顺序提供两种线型。 | Named character vector of 2 linetypes. NULL = use global theme. |
| `line_size` | `NULL` | 线宽；参数名按函数区别使用。 | Numeric. NULL = use global theme. |
| `ref_data` | `NULL` | 可选 Age、Length 列的参考个体生长数据。 | Optional data.frame with columns Age and Length containing observed age-length measurements (e.g. from otolith readings). If provided, a VB curve is fitted via nls() and overlaid as a reference, with the raw data as scatter points. |
| `ref_name` | `"Observed VB"` | 参考曲线名称；提供 ref_data 时必须非空，且不与任一模型标签重复。 | Nonempty reference-curve label distinct from both model labels when ref_data is supplied. |
| `ref_color` | `"grey30"` | 参考曲线颜色。 | Character. Color for reference curve/points. Default "grey30". |
| `ref_linetype` | `"dotdash"` | 参考曲线线型。 | Character. Linetype for reference curve. Default "dotdash". |
| `show_points` | `TRUE` | 是否显示参考数据点。 | Logical. Show raw data points from ref_data. Default TRUE. |
| `point_size` | `NULL` | 点大小；NULL 优先继承比较图覆盖值，否则继承全局 point_size（默认 2.5）。显式值优先。 | Point size; NULL inherits an explicit comparison override or global point_size (default 2.5). A supplied value takes priority. |
| `point_alpha` | `0.4` | 点透明度，0–1。 | Numeric. Transparency of data points. Default 0.4. |
| `nls_start` | `NULL` | 参考数据 VB 非线性回归初值：Linf、k、t0。 | Named list. Starting values for nls. Default attempts auto-detection from data range. |
| `...` | 可选 / optional | 旧参数名 linewidth，仍可使用但会给出警告。 | The former argument name linewidth, accepted with a warning. |

**返回 / Returns:** 可直接显示或用 `ggplot2::ggsave()` 保存的组合图对象。

A plot composition that can be displayed or saved with `ggplot2::ggsave()`.

同一模型的两份结果会自动使用不同图例，例如 `ACL (group_year)` 和 `ACL (year)`，仍支持显式指定不同的 `model1_name`、`model2_name`。时间序列与 F 图保留每份结果自己的真实年份，可以显示不同时间范围。与 `data.CatL` 配对的图会核对已知时间和体长元数据，再匹配观测与预测；网格不一致时明确报错。图形比较不代表似然或生物假设具有可比性。

Comparison plots give distinct default labels to two fits of the same model: for example, `ACL (group_year)` and `ACL (year)`. Explicit distinct `model1_name` and `model2_name` remain supported. Time-series and F plots retain each fit's own calendar, including different time spans. Plots paired with `data.CatL` check known time and length metadata before matching observations to predictions; inconsistent grids are errors. A visual comparison does not establish that likelihoods or biological assumptions are comparable.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
growth_display(plot_compare_growth(a, b, age_range = c(1, 15), ref_data = ref, ref_name = "Synthetic reference",
    nls_start = list(Linf = 60, k = 0.2, t0 = 1/60)))
```

![示例图 / Example figure: `plot_compare_growth(a, b, age_range = c(1, 15))`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_growth.png?raw=true&v=df436a02744c)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_compare_growth)。

如使用 `ref_data`，请先执行图谱中的模拟参考数据代码；示例的 `growth_display` 是脚本排版辅助函数，不属于 API。 / Define the synthetic reference data and layout helper from the gallery before using them.

<a id="plot_compare_metrics"></a>
## `plot_compare_metrics()`

拟合指标比较 / Fit metric comparison

```r
plot_compare_metrics (model1, model2, data.CatL, model1_name = NULL, model2_name = NULL, colors = NULL,
    metrics = NULL, facet_ncol = NULL, legend_pos = NULL, label_size = 3.2, bar_width = 0.6,
    bar_alpha = 0.85, ...)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model1` | `必填 / required` | 第一个拟合对象。 | First model result (reference). |
| `model2` | `必填 / required` | 第二个拟合对象。 | Second model result (alternative). |
| `data.CatL` | `必填 / required` | 调查数量指数表：首列体长标签，其余列为时间。 | Original survey numbers-at-length or index data frame. |
| `model1_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `model2_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `colors` | `NULL` | 按两个模型顺序提供两种颜色；名称可选。 | Named character vector of 2 colors. NULL = use global theme. |
| `metrics` | `NULL` | 选择 error、R2、MAPE、IC、npar 面板。 | Character vector selecting which panels to show. Options: "error" (RMSE, MAE), "R2", "MAPE", "IC" (AIC, BIC, NLL), "npar". Default NULL = all five panels. E.g. metrics = c("error", "R2", "IC"). |
| `facet_ncol` | `NULL` | 分面排列的列数。 | Integer. Columns for panel layout. Default: auto. |
| `legend_pos` | `NULL` | 图例位置，如 bottom、right、none。 | Character. Legend position. NULL = use global theme. |
| `label_size` | `3.2` | 柱图数值标签字号。 | Numeric. Text label size on bars. Default 3.2. |
| `bar_width` | `0.6` | 柱子宽度。 | Numeric. Bar width. Default 0.6. |
| `bar_alpha` | `0.85` | 柱子透明度。 | Numeric. Bar transparency. Default 0.85. |
| `...` | 可选 / optional | 旧参数名 ncol，仍可使用但会给出警告。 | The former argument name ncol, accepted with a warning. |

**返回 / Returns:** 可直接显示或用 `ggplot2::ggsave()` 保存的组合图对象。

A plot composition that can be displayed or saved with `ggplot2::ggsave()`.

同一模型的两份结果会自动使用不同图例，例如 `ACL (group_year)` 和 `ACL (year)`，仍支持显式指定不同的 `model1_name`、`model2_name`。时间序列与 F 图保留每份结果自己的真实年份，可以显示不同时间范围。与 `data.CatL` 配对的图会核对已知时间和体长元数据，再匹配观测与预测；网格不一致时明确报错。图形比较不代表似然或生物假设具有可比性。

Comparison plots give distinct default labels to two fits of the same model: for example, `ACL (group_year)` and `ACL (year)`. Explicit distinct `model1_name` and `model2_name` remain supported. Time-series and F plots retain each fit's own calendar, including different time spans. Plots paired with `data.CatL` check known time and length metadata before matching observations to predictions; inconsistent grids are errors. A visual comparison does not establish that likelihoods or biological assumptions are comparable.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_compare_metrics(a, b, dat, facet_ncol = 2) & scale_y_continuous(expand = expansion(mult = c(0,
    0.3)))
```

![示例图 / Example figure: `plot_compare_metrics(a, b, dat, facet_ncol = 2)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_metrics.png?raw=true&v=f429da60dffc)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_compare_metrics)。

<a id="plot_compare_residuals"></a>
## `plot_compare_residuals()`

残差联合诊断 / Combined residual diagnostics

```r
plot_compare_residuals (model1, model2, data.CatL, model1_name = NULL, model2_name = NULL, colors = NULL,
    linetypes = NULL, line_size = NULL, point_size = NULL, legend_pos = NULL, bins = 35,
    qq_alpha = 0.6, errorbar_width = 0.3, ...)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model1` | `必填 / required` | 第一个拟合对象。 | First model result (reference). |
| `model2` | `必填 / required` | 第二个拟合对象。 | Second model result (alternative). |
| `data.CatL` | `必填 / required` | 调查数量指数表：首列体长标签，其余列为时间。 | Original survey numbers-at-length or index data frame. |
| `model1_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `model2_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `colors` | `NULL` | 按两个模型顺序提供两种颜色；名称可选。 | Named character vector of 2 colors. NULL = use global theme. |
| `linetypes` | `NULL` | 按模型顺序提供两种线型。 | Named character vector of 2 linetypes. NULL = use global theme. |
| `line_size` | `NULL` | 线宽；参数名按函数区别使用。 | Numeric. NULL = use global theme. |
| `point_size` | `NULL` | 点大小；NULL 优先继承比较图覆盖值，否则继承全局 point_size（默认 2.5）。显式值优先。 | Point size; NULL inherits an explicit comparison override or global point_size (default 2.5). A supplied value takes priority. |
| `legend_pos` | `NULL` | 图例位置，如 bottom、right、none。 | Character. Legend position. NULL = use global theme (default "bottom"). |
| `bins` | `35` | 残差直方图分箱数量。 | Integer. Histogram bins. Default 35. |
| `qq_alpha` | `0.6` | QQ 图点的透明度。 | Numeric. QQ point transparency. Default 0.6. |
| `errorbar_width` | `0.3` | 年度残差 SD 误差棒端帽宽度。 | Numeric. Error bar cap width. Default 0.3. |
| `...` | 可选 / optional | 旧参数名 linewidth，仍可使用但会给出警告。 | The former argument name linewidth, accepted with a warning. |

**返回 / Returns:** 可直接显示或用 `ggplot2::ggsave()` 保存的组合图对象。

A plot composition that can be displayed or saved with `ggplot2::ggsave()`.

同一模型的两份结果会自动使用不同图例，例如 `ACL (group_year)` 和 `ACL (year)`，仍支持显式指定不同的 `model1_name`、`model2_name`。时间序列与 F 图保留每份结果自己的真实年份，可以显示不同时间范围。与 `data.CatL` 配对的图会核对已知时间和体长元数据，再匹配观测与预测；网格不一致时明确报错。图形比较不代表似然或生物假设具有可比性。

Comparison plots give distinct default labels to two fits of the same model: for example, `ACL (group_year)` and `ACL (year)`. Explicit distinct `model1_name` and `model2_name` remain supported. Time-series and F plots retain each fit's own calendar, including different time spans. Plots paired with `data.CatL` check known time and length metadata before matching observations to predictions; inconsistent grids are errors. A visual comparison does not establish that likelihoods or biological assumptions are comparable.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_compare_residuals(a, b, dat)
```

![示例图 / Example figure: `plot_compare_residuals(a, b, dat)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_residuals.png?raw=true&v=f97bb9ff3e81)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_compare_residuals)。

<a id="plot_compare_selectivity"></a>
## `plot_compare_selectivity()`

固定调查可捕性 / Fixed survey catchability

```r
plot_compare_selectivity (model1, model2, model1_name = NULL, model2_name = NULL, colors = NULL,
    linetypes = NULL, line_size = NULL, ..., point_size = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model1` | `必填 / required` | 第一个拟合对象。 | First fit; its fixed survey catchability is plotted. |
| `model2` | `必填 / required` | 第二个拟合对象。 | Second model result (alternative). |
| `model1_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `model2_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `colors` | `NULL` | 按两个模型顺序提供两种颜色；名称可选。 | Named character vector of 2 colors. NULL = use global theme. |
| `linetypes` | `NULL` | 按模型顺序提供两种线型。 | Named character vector of 2 linetypes. NULL = use global theme. |
| `line_size` | `NULL` | 线宽；参数名按函数区别使用。 | Numeric. NULL = use global theme. |
| `...` | 可选 / optional | 旧参数名 linewidth，仍可使用但会给出警告。 | The former argument name linewidth, accepted with a warning. |
| `point_size` | `NULL` | 点大小；NULL 优先继承比较图覆盖值，否则继承全局 point_size（默认 2.5）。显式值优先。 | Point size; NULL inherits an explicit comparison override or global point_size (default 2.5). A supplied value takes priority. |

**返回 / Returns:** ggplot 对象，可继续调整样式或用 `ggplot2::ggsave()` 保存。

A ggplot object, suitable for further styling or `ggplot2::ggsave()`.

同一模型的两份结果会自动使用不同图例，例如 `ACL (group_year)` 和 `ACL (year)`，仍支持显式指定不同的 `model1_name`、`model2_name`。时间序列与 F 图保留每份结果自己的真实年份，可以显示不同时间范围。与 `data.CatL` 配对的图会核对已知时间和体长元数据，再匹配观测与预测；网格不一致时明确报错。图形比较不代表似然或生物假设具有可比性。

Comparison plots give distinct default labels to two fits of the same model: for example, `ACL (group_year)` and `ACL (year)`. Explicit distinct `model1_name` and `model2_name` remain supported. Time-series and F plots retain each fit's own calendar, including different time spans. Plots paired with `data.CatL` check known time and length metadata before matching observations to predictions; inconsistent grids are errors. A visual comparison does not establish that likelihoods or biological assumptions are comparable.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_compare_selectivity(a, b)
```

![示例图 / Example figure: `plot_compare_selectivity(a, b)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_selectivity.png?raw=true&v=8910454b5721)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_compare_selectivity)。

<a id="plot_compare_ts"></a>
## `plot_compare_ts()`

种群时间序列比较 / Population time series comparison

捕捞死亡率图按矩阵位置和拟合年份、组别元数据构造坐标，矩阵行列名不会改变坐标。生物量、SSB、捕获量和 F 的年龄分面在有无区间时都按数值组序排列。F 图和时间序列比较在 `se = TRUE` 时要求完整、有限的估计与有限非负标准误；缺失摘要会报错，不再重复填充或静默取消区间。只画估计时请明确使用 `se = FALSE`。

Fishing-mortality plots use matrix positions and fitted time/group metadata, so matrix dimnames cannot alter the coordinates. Age panels in biomass, SSB, catch and F plots retain numeric group order with or without intervals. F plots and time-series comparisons require complete finite estimates and nonnegative finite standard errors when `se = TRUE`; missing summaries are errors rather than recycled values or silently removed intervals. Use `se = FALSE` explicitly for estimates only.

`plot_compare_ts()` 默认比较两模型共有的 SSB、补充量、B、N、CN。显式请求 CB 时，两模型都必须包含它（ACL 不报告 CB）；当前两模型均不报告 CB 标准误。请求的每种输出都必须存在；未知或不可用的输出会明确报错。捕捞死亡率请使用 `plot_compare_annual_F(a, b, method = "apical")` 或 `method = "mean"`。这两个选项分别取每个模型时期的组间最大值或非加权均值，不合并多个时期；该函数不提供汇总 F 的不确定性区间。

`plot_compare_ts()` defaults to the common SSB, recruitment, B, N and CN series. Explicit CB comparisons require CB in both models (ACL does not report it); CB uncertainty is not reported by either current model. Every requested quantity must be available; unknown or unavailable quantities produce an error. For fishing mortality use `plot_compare_annual_F(a, b, method = "apical")` or `method = "mean"`. These summarize F across groups per model period, not across periods; the mean is unweighted. This helper does not provide an uncertainty interval for the aggregate.

```r
plot_compare_ts (model1, model2, quantities = c("SSB", "R", "B", "N", "CN"), se = FALSE,
    model1_name = NULL, model2_name = NULL, colors = NULL, linetypes = NULL, line_size = NULL,
    facet_ncol = NULL, facet_scales = NULL, return_data = FALSE, ...)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model1` | `必填 / required` | 第一个拟合对象。 | First model result (reference). |
| `model2` | `必填 / required` | 第二个拟合对象。 | Second model result (alternative). |
| `quantities` | `c("SSB", "R", "B", "N", "CN")` | 选定标量输出：SSB、R/Rec、B、N、CN、CB；F 使用 plot_compare_annual_F。 | Character vector. Quantities to compare. Accepts: "SSB", "R" (or "Rec"), "B", "N", "CN", "CB". For F use plot_compare_annual_F(). Default c("SSB","R","B","N","CN"). |
| `se` | `FALSE` | 是否绘制可用标准误对应的近似区间。 | Logical. Show confidence intervals. Default FALSE. |
| `model1_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `model2_name` | `NULL` | 图例中的模型名称；NULL 自动判断。 | Character. Labels. Auto-detected if NULL. |
| `colors` | `NULL` | 按两个模型顺序提供两种颜色；名称可选。 | Named character vector of 2 colors. NULL = use global theme. |
| `linetypes` | `NULL` | 按模型顺序提供两种线型。 | Named character vector of 2 linetypes. NULL = use global theme. |
| `line_size` | `NULL` | 线宽；参数名按函数区别使用。 | Numeric. NULL = use global theme. |
| `facet_ncol` | `NULL` | 分面排列的列数。 | Integer. Facet columns. NULL = use global theme. |
| `facet_scales` | `NULL` | fixed、free、free_x 或 free_y；自由尺度有助观察组内变化。 | Character. Facet facet_scales. NULL = use global theme. |
| `return_data` | `FALSE` | TRUE 同时返回绘图对象及整理后的数据；结构见返回说明。 | Logical. Return data alongside plot. Default FALSE. |
| `...` | 可选 / optional | 旧参数名 linewidth、ncol、scales，仍可使用但会给出警告。 | The former argument names linewidth, ncol and scales, accepted with a warning. |

**返回 / Returns:** ggplot 对象；`return_data=TRUE` 时返回含 `plot` 和整理后的 `data` 的列表。

A ggplot object; with `return_data=TRUE`, a list with `plot` and the processed `data`.

同一模型的两份结果会自动使用不同图例，例如 `ACL (group_year)` 和 `ACL (year)`，仍支持显式指定不同的 `model1_name`、`model2_name`。时间序列与 F 图保留每份结果自己的真实年份，可以显示不同时间范围。与 `data.CatL` 配对的图会核对已知时间和体长元数据，再匹配观测与预测；网格不一致时明确报错。图形比较不代表似然或生物假设具有可比性。

Comparison plots give distinct default labels to two fits of the same model: for example, `ACL (group_year)` and `ACL (year)`. Explicit distinct `model1_name` and `model2_name` remain supported. Time-series and F plots retain each fit's own calendar, including different time spans. Plots paired with `data.CatL` check known time and length metadata before matching observations to predictions; inconsistent grids are errors. A visual comparison does not establish that likelihoods or biological assumptions are comparable.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_compare_ts(a, b, se = TRUE, facet_ncol = 2)
```

![示例图 / Example figure: `plot_compare_ts(a, b, se = TRUE, facet_ncol = 2)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_ts.png?raw=true&v=6e0c7883ce7f)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_compare_ts)。

<a id="plot_deviance"></a>
## `plot_deviance()`

过程偏差 R TRUE / Process deviations R TRUE

`log = TRUE` 标明对数过程偏差；`log = FALSE` 标明乘数。标题和纵轴标签分别使用 `dev_R`/`dev_F`，指数转换后使用 `dev_R_multiplier`/`dev_F_multiplier`。这些量不是似然偏差统计量。

`log = TRUE` labels log process deviations; `log = FALSE` labels multiplicative factors. Titles and y-axis labels use `dev_R`/`dev_F`, or `dev_R_multiplier`/`dev_F_multiplier` after exponentiation. These quantities are not likelihood deviances.

调用中给出的 `title`、`xlab`、`ylab` 和字体参数替换对应的主题设置。ACL 的 F 偏差图按年龄数字顺序排列面板。

A `title`, `xlab`, `ylab` or typography argument given in the call replaces the corresponding theme setting. ACL F-deviation age panels keep numeric order.

`se = FALSE` 使用报告中的过程偏差，无需标准误表；绘制区间则要求完整、有限、非负的标准误。 `se = FALSE` uses reported deviations without a standard-error table; intervals require complete, finite, nonnegative standard errors.

```r
plot_deviance (model_result, se = FALSE, point_size = NULL, point_color = "white", point_shape = 21,
    line_size = NULL, line_color = NULL, line_type = "solid", se_color = NULL, se_width = 0.5,
    facet_ncol = NULL, facet_scales = "free", log = TRUE, type = c("R", "F"), title = NULL,
    xlab = NULL, ylab = NULL, font_family = NULL, title_size = NULL, axis_title_size = NULL,
    axis_text_size = NULL, strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL,
    base_theme = NULL, title_hjust = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model_result` | `必填 / required` | 单次模型拟合结果。 | A list from run_acl or run_alscl. |
| `se` | `FALSE` | 是否画标准误区间；默认 FALSE。 | Logical. Whether to draw 95% intervals from the standard errors. Default is FALSE. |
| `point_size` | `NULL` | 点大小；NULL 继承全局 point_size（默认 2.5）。 | Numeric or NULL. NULL inherits the global point_size setting (default 2.5). |
| `point_color` | `"white"` | 点颜色。 | Character. The color of the point. Default is "white". |
| `point_shape` | `21` | 点形状编号，如 16、21。 | Numeric. The shape of the point. Default is 21. |
| `line_size` | `NULL` | NULL 继承全局 line_size，显式值优先。 | NULL inherits global line_size; explicit values take priority. |
| `line_color` | `NULL` | 单模型线条颜色。 | Character or NULL. NULL inherits the global line_color setting. |
| `line_type` | `"solid"` | 线型，如 solid、dashed。 | Character, the line type. |
| `se_color` | `NULL` | 区间阴影或误差棒的颜色。 | Character or NULL. NULL inherits the global se_color setting. |
| `se_width` | `0.5` | 误差棒端帽宽度。 | Numeric, the width of the standard error. |
| `facet_ncol` | `NULL` | 分面排列的列数。 | Number of columns in facet wrap. Default is NULL. |
| `facet_scales` | `"free"` | fixed、free、free_x 或 free_y；自由尺度有助观察组内变化。 | Scales for facet wrap. Default is "free". |
| `log` | `TRUE` | TRUE 为对数过程偏差；FALSE 取指数，参考值为 1。 | TRUE plots log process deviations; FALSE plots exponentiated multipliers, not likelihood deviances. |
| `type` | `c("R", "F")` | R 为补充过程偏差，F 为捕捞死亡率过程偏差；均不是似然离差。 | Character. "R" for recruitment deviation, "F" for fishing mortality deviation. |
| `title` | `NULL` | 自定义图标题；NULL 继承主题。 | Character or NULL. Custom plot title. If NULL, uses global theme setting. See acl_theme_set(). |
| `xlab` | `NULL` | 自定义横轴标签；NULL 继承主题。 | Character or NULL. Custom x-axis label. If NULL, uses global theme setting. |
| `ylab` | `NULL` | 自定义纵轴标签；NULL 继承主题。 | Character or NULL. Custom y-axis label. If NULL, uses global theme setting. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character or NULL. Custom font family. If NULL, uses global theme setting (default "sans"). |
| `title_size` | `NULL` | 图标题字号。 | Numeric or NULL. Plot title size in pt. If NULL, uses global theme (default 14). |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12). |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10). |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10). |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10). |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector or NULL. Custom x-axis breaks (e.g. seq(1, 20, by = 2)). NULL = auto. |
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character or NULL. Base ggplot2 theme name (e.g. "theme_bw"). NULL = global setting. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting. |

**返回 / Returns:** ggplot 对象，可继续调整样式或用 `ggplot2::ggsave()` 保存。

A ggplot object, suitable for further styling or `ggplot2::ggsave()`.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_deviance(b, type = "R", log = TRUE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

![示例图 / Example figure: `plot_deviance(b, type = "R", log = TRUE, se = TRUE, facet_ncol = 3)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_R_TRUE.png?raw=true&v=e16626d72746)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_deviance)。

<a id="plot_fishing_mortality"></a>
## `plot_fishing_mortality()`

ACL 捕捞死亡率 year / ACL fishing mortality year

所有模式继承全局标题 `F_year`、`F_age` 或 `F_length`（区间加 `_se`）、对应的横轴标签、`ylab$F`、`x_breaks` 和 `x_expand`；显式绘图参数优先。默认年龄横坐标为组序号，标为 Age group。`base_theme` 接受 `"theme_bw"` 等主题名称，也保留 `ggplot2::theme_bw()` 等主题对象，两种方式均保持无网格。

All modes inherit global titles `F_year`, `F_age`, or `F_length` (append `_se` for intervals), matching x-axis labels, `ylab$F`, `x_breaks`, and `x_expand`. Explicit plot arguments take priority. Default age coordinates are group indices and are labeled Age group. `base_theme` accepts a theme name such as `"theme_bw"` or a ggplot2 theme object such as `ggplot2::theme_bw()`; both preserve grid-free panels.

捕捞死亡率图按矩阵位置和拟合年份、组别元数据构造坐标，矩阵行列名不会改变坐标。生物量、SSB、捕获量和 F 的年龄分面在有无区间时都按数值组序排列。F 图和时间序列比较在 `se = TRUE` 时要求完整、有限的估计与有限非负标准误；缺失摘要会报错，不再重复填充或静默取消区间。只画估计时请明确使用 `se = FALSE`。

Fishing-mortality plots use matrix positions and fitted time/group metadata, so matrix dimnames cannot alter the coordinates. Age panels in biomass, SSB, catch and F plots retain numeric group order with or without intervals. F plots and time-series comparisons require complete finite estimates and nonnegative finite standard errors when `se = TRUE`; missing summaries are errors rather than recycled values or silently removed intervals. Use `se = FALSE` explicitly for estimates only.

```r
plot_fishing_mortality (model_result, line_size = NULL, line_color = NULL, line_type = "solid",
    facet_ncol = NULL, facet_scales = "free", se = FALSE, se_color = NULL, se_alpha = NULL,
    se_type = "ribbon", type = c("year", "age", "length"), return_data = FALSE, x_breaks = NULL,
    title = NULL, xlab = NULL, ylab = NULL, font_family = NULL, title_size = NULL,
    base_theme = NULL, axis_title_size = NULL, axis_text_size = NULL, strip_text_size = NULL,
    legend_text_size = NULL, title_hjust = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model_result` | `必填 / required` | 单次模型拟合结果。 | A list obtained from run_acl or run_alscl. |
| `line_size` | `NULL` | NULL 继承全局 line_size，显式值优先。 | NULL inherits global line_size; explicit values take priority. |
| `line_color` | `NULL` | 单模型线条颜色。 | Character or NULL. NULL inherits the global line_color setting. |
| `line_type` | `"solid"` | 线型，如 solid、dashed。 | Character. The type of the line. Default is "solid". |
| `facet_ncol` | `NULL` | 分面排列的列数。 | Integer. The number of columns in facet_wrap. |
| `facet_scales` | `"free"` | fixed、free、free_x 或 free_y；自由尺度有助观察组内变化。 | Character. Scales for facet_wrap. Default is "free". |
| `se` | `FALSE` | 是否绘制可用标准误对应的近似区间。 | Logical. Whether to plot confidence intervals. Default is FALSE. |
| `se_color` | `NULL` | 区间阴影或误差棒的颜色。 | Character or NULL. NULL inherits the global se_color setting. |
| `se_alpha` | `NULL` | NULL 继承全局 se_alpha，显式值优先。 | NULL inherits global se_alpha; explicit values take priority. |
| `se_type` | `"ribbon"` | 区间样式：ribbon 或 errorbar。 | Character. "ribbon" or "errorbar". Default is "ribbon". |
| `type` | `c("year", "age", "length")` | year 为时间横轴；age 按年绘年龄别 F；ALSCL length 按年绘实际体长别 F。ACL 旧 length 别名仍画年龄并警告。 | year uses a time axis; age facets F-at-age by year; ALSCL length uses actual midpoints and year facets. The legacy ACL length alias still draws age and warns. |
| `return_data` | `FALSE` | TRUE 同时返回绘图对象及整理后的数据；结构见返回说明。 | Logical. Whether to return data alongside the plot. Default is FALSE. |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector. Custom x-axis breaks. |
| `title` | `NULL` | 自定义图标题；NULL 继承默认。 | Character. Custom plot title. |
| `xlab` | `NULL` | 自定义横轴标签；NULL 继承主题。 | Character. Custom x-axis label. |
| `ylab` | `NULL` | 自定义纵轴标签；NULL 继承主题。 | Character. Custom y-axis label. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character. Font family for text elements. |
| `title_size` | `NULL` | 图标题字号。 | Numeric. Title text size. |
| `base_theme` | `NULL` | 主题名称（如 theme_bw）或 ggplot2 主题对象（如 theme_bw()）；NULL 继承全局，保持无网格。 | Theme name or ggplot2 theme object; NULL inherits the global base theme. Panels remain grid-free. |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12). |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10). |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10). |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10). |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting. |

**返回 / Returns:** ggplot 对象；`return_data=TRUE` 时返回含 `plot` 和整理后的 `data` 的列表。

A ggplot object; with `return_data=TRUE`, a list with `plot` and the processed `data`.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_fishing_mortality(a, type = "year",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

![示例图 / Example figure: `plot_fishing_mortality(b, type = "year", se = TRUE, facet_ncol = 4, line_size = 0.6)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_year.png?raw=true&v=098d37cae7d1)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_fishing_mortality)。

ACL 的 `type="length"` 当前与 `"age"` 是兼容别名，不能解释为长度别 F。 / For ACL, length remains an age-plot compatibility alias.

<a id="plot_pla"></a>
## `plot_pla()`

年龄长度转换 / Age length conversion

`plot_pla(x_breaks = c(1, 5, 10, 15))` 选择年龄组刻度，不删除热图单元。

`plot_pla(x_breaks = c(1, 5, 10, 15))` selects age-bin ticks without removing heatmap cells.

```r
plot_pla (model_result, low_col = NULL, high_col = NULL, title = NULL, xlab = NULL,
    ylab = NULL, font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL,
    strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL,
    title_hjust = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model_result` | `必填 / required` | 单次模型拟合结果。 | A list that contains model output. The model output should include a PLA report. |
| `low_col` | `NULL` | 概率热图的低值 / 高值颜色。 | Character or NULL. NULL inherits the global low_col setting. |
| `high_col` | `NULL` | 概率热图的低值 / 高值颜色。 | Character or NULL. NULL inherits the global high_col setting. |
| `title` | `NULL` | 自定义图标题；NULL 继承默认。 | Character or NULL. Custom plot title. If NULL, uses global theme setting. See acl_theme_set(). |
| `xlab` | `NULL` | 自定义横轴标签；NULL 继承主题。 | Character or NULL. Custom x-axis label. If NULL, uses global theme setting. |
| `ylab` | `NULL` | 自定义纵轴标签；NULL 继承主题。 | Character or NULL. Custom y-axis label. If NULL, uses global theme setting. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character or NULL. Custom font family. If NULL, uses global theme setting (default "sans"). |
| `title_size` | `NULL` | 图标题字号。 | Numeric or NULL. Plot title size in pt. If NULL, uses global theme (default 14). |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12). |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10). |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10). |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10). |
| `x_breaks` | `NULL` | 整数年龄组位置；仅选择刻度，不删除热图单元。NULL 继承全局值。 | Integer age-bin positions selecting ticks without removing cells; NULL inherits the global setting. |
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character or NULL. Base ggplot2 theme name (e.g. "theme_bw"). NULL = global setting. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting. |

**返回 / Returns:** ggplot 对象，可继续调整样式或用 `ggplot2::ggsave()` 保存。

A ggplot object, suitable for further styling or `ggplot2::ggsave()`.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_pla(b) + scale_x_discrete(labels = as.character(1:15))
```

![示例图 / Example figure: `plot_pla(b)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/pla.png?raw=true&v=3f17714c7721)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_pla)。

<a id="plot_recruitment"></a>
## `plot_recruitment()`

补充量 / Recruitment

标准误必须完整、有限且非负；仅绘制估计值时使用 `se = FALSE`。 Standard errors must be complete, finite and nonnegative; use `se = FALSE` for estimates only.

```r
plot_recruitment (model_result, line_size = NULL, line_color = NULL, line_type = "solid",
    se = FALSE, se_color = NULL, se_alpha = NULL, se_type = c("ribbon", "errorbar"),
    return_data = FALSE, title = NULL, xlab = NULL, ylab = NULL, font_family = NULL,
    title_size = NULL, axis_title_size = NULL, axis_text_size = NULL, strip_text_size = NULL,
    legend_text_size = NULL, x_breaks = NULL, base_theme = NULL, title_hjust = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model_result` | `必填 / required` | 单次模型拟合结果。 | A list that contains the model output. The list should have a "report" component which contains a "Rec" component representing Recruitment. |
| `line_size` | `NULL` | NULL 继承全局 line_size，显式值优先。 | NULL inherits global line_size; explicit values take priority. |
| `line_color` | `NULL` | 单模型线条颜色。 | Character or NULL. NULL inherits the global line_color setting. |
| `line_type` | `"solid"` | 线型，如 solid、dashed。 | Character. Specifies the type of the line in the plot. Default is "solid". |
| `se` | `FALSE` | 是否绘制可用标准误对应的近似区间。 | Logical. Draw approximate pointwise 95% confidence intervals using model-based standard errors. Default FALSE. |
| `se_color` | `NULL` | 区间阴影或误差棒的颜色。 | Character or NULL. NULL inherits the global se_color setting. |
| `se_alpha` | `NULL` | NULL 继承全局 se_alpha，显式值优先。 | NULL inherits global se_alpha; explicit values take priority. |
| `se_type` | `c("ribbon", "errorbar")` | 区间样式：ribbon 或 errorbar。 | Character. Type of CI display: "ribbon" (shaded area) or "errorbar" (error bars). Default is "ribbon". |
| `return_data` | `FALSE` | TRUE 同时返回绘图对象及整理后的数据；结构见返回说明。 | A logical indicating whether to return the processed data alongside the plot. Default is FALSE. |
| `title` | `NULL` | 自定义图标题；NULL 继承默认。 | Character or NULL. Custom plot title. If NULL, uses global theme setting. See acl_theme_set(). |
| `xlab` | `NULL` | 自定义横轴标签；NULL 继承主题。 | Character or NULL. Custom x-axis label. If NULL, uses global theme setting. |
| `ylab` | `NULL` | 自定义纵轴标签；NULL 继承主题。 | Character or NULL. Custom y-axis label. If NULL, uses global theme setting. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character or NULL. Custom font family. If NULL, uses global theme setting (default "sans"). |
| `title_size` | `NULL` | 图标题字号。 | Numeric or NULL. Plot title size in pt. If NULL, uses global theme (default 14). |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12). |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10). |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10). |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10). |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector or NULL. Custom x-axis breaks (e.g. seq(1, 20, by = 2)). NULL = auto. |
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character or NULL. Base ggplot2 theme name (e.g. "theme_bw"). NULL = global setting. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting. |

**返回 / Returns:** ggplot 对象；`return_data=TRUE` 时返回含 `plot` 和整理后的 `data` 的列表。

A ggplot object; with `return_data=TRUE`, a list with `plot` and the processed `data`.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_recruitment(b, se = TRUE)
```

![示例图 / Example figure: `plot_recruitment(b, se = TRUE)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/recruitment.png?raw=true&v=f3b37834bb1a)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_recruitment)。

<a id="plot_residuals"></a>
## `plot_residuals()`

对数残差 length / Log residuals length

每个分面按有效且不同的横坐标数量独立选择平滑方法：不足 2 个不画趋势，2–5 个使用线性拟合，6 个以上使用独立 span 的 loess。一个稀疏组不会改变其他组的趋势。

Each facet selects its smoother independently using the number of distinct valid x values: fewer than 2 omits the trend, 2–5 uses a linear fit, and 6 or more uses loess with its own span. A sparse group never changes another group's trend.

调查拟合图按矩阵位置及拟合年份、体长元数据对齐观测与预测，增删行列名不会改变坐标；缺失及零观测继续排除。若预测取指数会溢出，请使用 `exp_transform = FALSE`。残差图的 `resid_cap` 必须为有限正标量，或以 `NULL` 关闭截断；不再允许负值或零值抹去诊断特征。

Survey fit plots align both observed and predicted matrices by their positions and fitted calendar/length metadata, even if dimnames are added or removed. Missing and zero observations stay excluded. Use `exp_transform = FALSE` if exponentiating predictions would overflow. In residual plots, `resid_cap` must be a finite positive scalar or `NULL` to disable capping; negative or zero caps cannot erase the diagnostic pattern.

残差图的两种布局均遵守单次调用的 `title`、`xlab`、`ylab` 和 `title_hjust`。例如 `plot_residuals(b, type = "year", title = "Survey residuals", xlab = "Length (cm)", ylab = "Log residual", title_hjust = 0)` 使用指定标签并左对齐标题。所有默认图继续不显示主、次网格线。

Both residual layouts honor per-call `title`, `xlab`, `ylab` and `title_hjust`. For example, `plot_residuals(b, type = "year", title = "Survey residuals", xlab = "Length (cm)", ylab = "Log residual", title_hjust = 0)` uses the supplied labels and a left-aligned title. Default plots remain free of major and minor gridlines.

```r
plot_residuals (model_result, f = 0.4, line_color = NULL, smooth_color = NULL, hline_color = NULL,
    line_size = NULL, facet_scales = "free", facet_ncol = NULL, facet_by = c("length",
        "year"), resid_cap = NULL, return_data = FALSE, title = NULL, xlab = NULL,
    ylab = NULL, font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL,
    strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL,
    title_hjust = NULL, ...)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model_result` | `必填 / required` | run_acl() 或 run_alscl() 的拟合结果，需保存 report 及观测信息。 | A fit from run_acl() or run_alscl(), retaining report and observation information. |
| `f` | `0.4` | 残差平滑参数，越大越平滑。 | Numeric. The smoother span for the loess smooth line in the plot. This gives the proportion of points in the plot which influence the smooth at each value. Larger values result in more smoothing. Default is 0.4. Each facet independently uses no trend with fewer than 2 valid distinct x values, a linear fit with 2–5, or loess with at least 6; span is enlarged for at least five neighbors. |
| `line_color` | `NULL` | 单模型线条颜色。 | Character or NULL. NULL inherits the global line_color setting. |
| `smooth_color` | `NULL` | 残差平滑线颜色。 | Character or NULL. NULL inherits the global smooth_color setting. |
| `hline_color` | `NULL` | 残差零参考线颜色。 | Character or NULL. NULL inherits the global hline_color setting. |
| `line_size` | `NULL` | NULL 继承全局 line_size，显式值优先。 | NULL inherits global line_size; explicit values take priority. |
| `facet_scales` | `"free"` | fixed、free、free_x 或 free_y；自由尺度有助观察组内变化。 | Character. The "scales" argument for the facet_wrap function in ggplot2. Default is "free". |
| `facet_ncol` | `NULL` | 分面排列的列数。 | Numeric, optional. Number of columns in facet wrap. Default is NULL. |
| `facet_by` | `c("length", "year")` | 布局："length" 每个体长组一个面板、横轴为时间；"year" 每个时间步一个面板、横轴为体长。 | "length" (default) draws one panel per length bin with time on the x axis; "year" draws one panel per time step with length on the x axis. |
| `resid_cap` | `NULL` | 可选残差显示裁剪阈值；使用时需说明。 | Numeric or NULL. Symmetrically cap residuals at +/- this value. Useful for species with many length bins where tail bins (e.g. >120 for tuna) have very few observations, producing extreme log-residuals that distort the plot. Default is NULL (no capping). Use capping only when its threshold and effect on displayed residuals are reported. |
| `return_data` | `FALSE` | TRUE 同时返回绘图对象及整理后的数据；结构见返回说明。 | A logical indicating whether to return the processed data alongside the plot. Default is FALSE. |
| `title` | `NULL` | 自定义图标题；NULL 继承默认。 | Character or NULL. Custom plot title. If NULL, uses global theme setting. See acl_theme_set(). |
| `xlab` | `NULL` | 自定义横轴标签；NULL 继承主题。 | Character or NULL. Custom x-axis label. If NULL, uses global theme setting. |
| `ylab` | `NULL` | 自定义纵轴标签；NULL 继承主题。 | Character or NULL. Custom y-axis label. If NULL, uses global theme setting. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character or NULL. Custom font family. If NULL, uses global theme setting (default "sans"). |
| `title_size` | `NULL` | 图标题字号。 | Numeric or NULL. Plot title size in pt. If NULL, uses global theme (default 14). |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12). |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10). |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10). |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10). |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector or NULL. Custom x-axis breaks (e.g. seq(1, 20, by = 2)). NULL = auto. |
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character or NULL. Base ggplot2 theme name (e.g. "theme_bw"). NULL = global setting. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting. |
| `...` | 可选 / optional | 旧参数名 type，仍可使用但会给出警告。 | The former argument name type, accepted with a warning. |

**返回 / Returns:** ggplot 对象；`return_data=TRUE` 时返回含 `plot` 和整理后的 `data` 的列表。

A ggplot object; with `return_data=TRUE`, a list with `plot` and the processed `data`.

`plot_ridges()` 和 `plot_residuals()` 使用保存的 `observations`，保留与拟合一致的正观测掩码；旧结果可读取 TMB 数据。NA 和拟合时排除的零值不会变成人造观测或零残差。整期缺测不绘制观测山脊；部分缺测时，观测比例只在有效正观测中归一化，预测比例则覆盖全部体长组，不能把它解释为未观测组也拟合良好。保留 `observations` 的拟合结果移除 `obj` 后仍可使用这两个绘图函数。

`plot_ridges()` and `plot_residuals()` use saved `observations` to preserve the same positive-observation mask as fitting; legacy fits can use their TMB data. NA and excluded zero cells are never converted to artificial observations or zero residuals. A wholly unobserved period has no observed ridge. With partial coverage, the observed ridge is normalized over observed positive cells, whereas predictions cover all bins: do not interpret this as agreement over unobserved bins. These plots work after removing `obj` from a fit that retains `observations`.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_residuals(b, facet_by = "length", facet_ncol = 4, line_size = 0.6,
  x_breaks = c(2000, 2010, 2015))
```

![示例图 / Example figure: `plot_residuals(b, facet_by = "year", facet_ncol = 4)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/residuals_year.png?raw=true&v=d23449a96976)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_residuals)。

<a id="plot_retro"></a>
## `plot_retro()`

ACL 回溯分析 / ACL retrospective analysis

```r
plot_retro (retro_result, rho_digits = 4, rho_position = "top_right", rho_size = 3.5,
    line_size = NULL, point_size = NULL, point_shape = 21, facet_scales = "free",
    facet_ncol = NULL, facet_nrow = NULL, title = NULL, xlab = NULL, ylab = NULL,
    font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL,
    strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL,
    title_hjust = NULL, palette = NULL, colors = NULL, ...)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `retro_result` | `必填 / required` | retro_model/retro_acl/retro_alscl 的回溯结果。 | A list returned by retro_model(), retro_acl(), or retro_alscl(). |
| `rho_digits` | `4` | Mohn rho 显示的小数位数。 | Integer. Decimal places for Mohn's rho. Default is 4. |
| `rho_position` | `"top_right"` | Mohn rho 标注位置。 | Character. Position of rho text. Default is "top_right". |
| `rho_size` | `3.5` | Mohn rho 标注字号。 | Numeric. Font size of rho text. Default is 3.5. |
| `line_size` | `NULL` | NULL 继承全局 line_size，显式值优先。 | NULL inherits global line_size; explicit values take priority. |
| `point_size` | `NULL` | 点大小；NULL 继承全局 point_size（默认 2.5）。 | Numeric or NULL. NULL inherits the global point_size setting (default 2.5). |
| `point_shape` | `21` | 点形状编号，如 16、21。 | Numeric. Point shape. Default is 21. |
| `facet_scales` | `"free"` | fixed、free、free_x 或 free_y；自由尺度有助观察组内变化。 | Character. Facet scales. Default is "free". |
| `facet_ncol` | `NULL` | 分面排列的列数。 | Integer or NULL. Number of facet columns. |
| `facet_nrow` | `NULL` | 分面排列的行数。 | Integer or NULL. Number of facet rows. |
| `title` | `NULL` | 自定义图标题；NULL 继承默认。 | Character or NULL. Custom plot title. |
| `xlab` | `NULL` | 自定义横轴标签；NULL 继承主题。 | Character or NULL. Custom x-axis label. |
| `ylab` | `NULL` | 自定义纵轴标签；NULL 继承主题。 | Character or NULL. Custom y-axis label. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character or NULL. Font family. |
| `title_size` | `NULL` | 图标题字号。 | Numeric or NULL. Title size in pt. |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector or NULL. Custom x-axis breaks. |
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character or NULL. Base ggplot2 theme name. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment. |
| `palette` | `NULL` | ggsci 色板名；NULL 继承全局设置，部分图也保留旧色板。 | Character or NULL. ggsci palette name; NULL inherits acl_theme(). Native colors are interpolated when there are more peels than colors. |
| `colors` | `NULL` | 按截止期降序给色，或按截止期命名；需覆盖每条曲线。 | Character vector or NULL. Explicit period colors, ordered by descending terminal period or named by terminal period. Overrides palette. |
| `...` | 可选 / optional | 旧参数名 facet_col、facet_row，仍可使用但会给出警告。 | The former argument names facet_col and facet_row, accepted with a warning. |

**返回 / Returns:** ggplot 对象，可继续调整样式或用 `ggplot2::ggsave()` 保存。

A ggplot object, suitable for further styling or `ggplot2::ggsave()`.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_retro(rb, facet_ncol = 2, rho_digits = 3)
```

![示例图 / Example figure: `plot_retro(rb, facet_ncol = 2, rho_digits = 3)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ALSCL.png?raw=true&v=a15f447d44dc)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_retro)。

<a id="plot_ridges"></a>
## `plot_ridges()`

长度组成山脊图 / Length composition ridges

分面标题明确标为观测与拟合的调查体长组成，每个时段分别归一化；不表示总捕获量。

Panel titles identify observed and fitted survey length compositions, normalized separately within each period; they do not describe total catch.

保存了观测与拟合报告的结果可直接使用 `plot_ridges()`，不需要活跃 TMB 对象。未保存观测的旧结果仍需原会话对象或重新拟合。记录包版本、提交号、随机种子、数据来源、三表单位、固定参数、边界、时间步和诊断；RDS 不保存可跨会话执行的编译模型。 默认 `plot_CatL(exp_transform = FALSE)` 绘制自然对数调查指数，并在纵轴标明尺度；`exp_transform = TRUE` 绘制原尺度调查指数，预测曲线为中位数。显式 `ylab` 覆盖自动标签。山脊图在对数尺度稳定归一化，极大或极小的有限对数预测仍可绘制；非有限预测会报错。

Saved fits containing observations and fitted reports support `plot_ridges()` without a live TMB object. Older fits without saved observations still require their original live object or refitting. Record version, commit, seed, provenance, units, maps, bounds, time step and diagnostics. An RDS file does not preserve a portable compiled model. The default `plot_CatL(exp_transform = FALSE)` displays natural-log survey indices and labels that scale explicitly. `exp_transform = TRUE` displays original-scale survey indices; curves are fitted medians. An explicit `ylab` overrides the automatic label. Ridge compositions are normalized stably on the log scale, including very large or small finite log predictions; nonfinite predictions are rejected.

```r
plot_ridges (model_result, ridges_alpha = 0.8, ridges_scale = NULL, palette = "viridis",
    title = NULL, xlab = NULL, ylab = NULL, font_family = NULL, title_size = NULL,
    axis_title_size = NULL, axis_text_size = NULL, strip_text_size = NULL, legend_text_size = NULL,
    x_breaks = NULL, base_theme = NULL, title_hjust = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model_result` | `必填 / required` | 单次模型拟合结果。 | A list containing the model result, which includes a data frame of Elog_index and logN_at_len, len_mid, and year. |
| `ridges_alpha` | `0.8` | 山脊图透明度。 | Numeric. Specifies the transparency of the ridgeline plots. Default is 0.8. |
| `ridges_scale` | `NULL` | 山脊图高度/重叠缩放。 | Numeric or NULL. Multiplier for ridge height. When NULL (default), auto-scales so the tallest peak fills ~80\% of inter-year spacing. Increase for taller ridges, decrease for flatter. Useful when many length bins make proportions small (e.g. tuna with 22 bins). |
| `palette` | `"viridis"` | 按时间顺序渐变；NULL 同样使用 viridis，不继承全局分类色板。可选 cividis、plasma、ocean 或自定义渐变端点。 | Sequential gradient across ordered years; NULL also uses viridis independently of the global categorical palette. Accepts other named gradients or a color vector; explicit journal palettes remain available. |
| `title` | `NULL` | 自定义图标题；NULL 继承默认。 | Character or NULL. Custom plot title. If NULL, uses global theme setting. See acl_theme_set(). |
| `xlab` | `NULL` | 自定义横轴标签；NULL 继承主题。 | Character or NULL. Custom x-axis label. If NULL, uses global theme setting. |
| `ylab` | `NULL` | 自定义纵轴标签；NULL 继承主题。 | Character or NULL. Custom y-axis label. If NULL, uses global theme setting. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character or NULL. Custom font family. If NULL, uses global theme setting (default "sans"). |
| `title_size` | `NULL` | 图标题字号。 | Numeric or NULL. Plot title size in pt. If NULL, uses global theme (default 14). |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12). |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10). |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10). |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10). |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector or NULL. Custom x-axis breaks (e.g. seq(1, 20, by = 2)). NULL = auto. |
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character or NULL. Base ggplot2 theme name (e.g. "theme_bw"). NULL = global setting. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting. |

**返回 / Returns:** 包含观测与拟合体长组成两个面板的组合图（ggplot 对象），可用 ggplot2::ggsave() 保存。

A two-panel composition of observed and fitted length distributions, returned as a ggplot object and compatible with ggplot2::ggsave().

`plot_ridges()` 和 `plot_residuals()` 使用保存的 `observations`，保留与拟合一致的正观测掩码；旧结果可读取 TMB 数据。NA 和拟合时排除的零值不会变成人造观测或零残差。整期缺测不绘制观测山脊；部分缺测时，观测比例只在有效正观测中归一化，预测比例则覆盖全部体长组，不能把它解释为未观测组也拟合良好。保留 `observations` 的拟合结果移除 `obj` 后仍可使用这两个绘图函数。

`plot_ridges()` and `plot_residuals()` use saved `observations` to preserve the same positive-observation mask as fitting; legacy fits can use their TMB data. NA and excluded zero cells are never converted to artificial observations or zero residuals. A wholly unobserved period has no observed ridge. With partial coverage, the observed ridge is normalized over observed positive cells, whereas predictions cover all bins: do not interpret this as agreement over unobserved bins. These plots work after removing `obj` from a fit that retains `observations`.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_ridges(b)
```

![示例图 / Example figure: `plot_ridges(b)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/ridges.png?raw=true&v=5be1df0903c5)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_ridges)。

<a id="plot_SSB"></a>
## `plot_SSB()`

产卵生物量 SSB / Spawning biomass SSB

所有模式继承全局标题（SSB, SBL, SBA；区间使用对应的 `_se` 键，年龄丰度为 `NA_se`）、`xlab$year`、`ylab$ssb`、`x_breaks` 与 `x_expand`。调用中给出的 `title`、`xlab`、`ylab`、字体和线条参数优先，默认无网格。

All modes inherit global titles (SSB, SBL, SBA; interval variants use the corresponding `_se` keys, with `NA_se` for abundance at age), `xlab$year`, `ylab$ssb`, `x_breaks` and `x_expand`. A `title`, `xlab`, `ylab`, typography or line argument given in the call takes priority. Default panels have no gridlines.

捕捞死亡率图按矩阵位置和拟合年份、组别元数据构造坐标，矩阵行列名不会改变坐标。生物量、SSB、捕获量和 F 的年龄分面在有无区间时都按数值组序排列。F 图和时间序列比较在 `se = TRUE` 时要求完整、有限的估计与有限非负标准误；缺失摘要会报错，不再重复填充或静默取消区间。只画估计时请明确使用 `se = FALSE`。

Fishing-mortality plots use matrix positions and fitted time/group metadata, so matrix dimnames cannot alter the coordinates. Age panels in biomass, SSB, catch and F plots retain numeric group order with or without intervals. F plots and time-series comparisons require complete finite estimates and nonnegative finite standard errors when `se = TRUE`; missing summaries are errors rather than recycled values or silently removed intervals. Use `se = FALSE` explicitly for estimates only.

```r
plot_SSB (model_result, line_size = NULL, line_color = NULL, line_type = "solid",
    se = FALSE, se_color = NULL, se_alpha = NULL, type = c("SSB", "SBL", "SBA"),
    facet_ncol = NULL, facet_scales = "free", return_data = FALSE, title = NULL,
    xlab = NULL, ylab = NULL, font_family = NULL, title_size = NULL, axis_title_size = NULL,
    axis_text_size = NULL, strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL,
    base_theme = NULL, title_hjust = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model_result` | `必填 / required` | 单次模型拟合结果。 | A list from run_acl or run_alscl. |
| `line_size` | `NULL` | NULL 继承全局 line_size，显式值优先。 | NULL inherits global line_size; explicit values take priority. |
| `line_color` | `NULL` | 单模型线条颜色。 | Character or NULL. NULL inherits the global line_color setting. |
| `line_type` | `"solid"` | 线型，如 solid、dashed。 | Character. Line type. Default is "solid". |
| `se` | `FALSE` | 是否绘制可用标准误对应的近似区间。 | Logical. Whether to plot confidence intervals. Default is FALSE. |
| `se_color` | `NULL` | 区间阴影或误差棒的颜色。 | Character or NULL. NULL inherits the global se_color setting. |
| `se_alpha` | `NULL` | NULL 继承全局 se_alpha，显式值优先。 | NULL inherits global se_alpha; explicit values take priority. |
| `type` | `c("SSB", "SBL", "SBA")` | SSB 为总产卵生物量，SBA 为年龄别产卵生物量，SBL 为体长别产卵生物量。 | Character. "SSB" (total), "SBL" (at length), or "SBA" (at age). Default is "SSB". |
| `facet_ncol` | `NULL` | 分面排列的列数。 | Numeric. Columns in facet wrap. Default is NULL. |
| `facet_scales` | `"free"` | fixed、free、free_x 或 free_y；自由尺度有助观察组内变化。 | Character. Scales for facet wrap. Default is "free". |
| `return_data` | `FALSE` | TRUE 同时返回绘图对象及整理后的数据；结构见返回说明。 | Logical. Whether to return processed data. Default is FALSE. |
| `title` | `NULL` | 自定义图标题；NULL 继承主题。 | Character or NULL. Custom plot title. If NULL, uses global theme setting. See acl_theme_set(). |
| `xlab` | `NULL` | 自定义横轴标签；NULL 继承主题。 | Character or NULL. Custom x-axis label. If NULL, uses global theme setting. |
| `ylab` | `NULL` | 自定义纵轴标签；NULL 继承主题。 | Character or NULL. Custom y-axis label. If NULL, uses global theme setting. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character or NULL. Custom font family. If NULL, uses global theme setting (default "sans"). |
| `title_size` | `NULL` | 图标题字号。 | Numeric or NULL. Plot title size in pt. If NULL, uses global theme (default 14). |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12). |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10). |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10). |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10). |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector or NULL. Custom x-axis breaks (e.g. seq(1, 20, by = 2)). NULL = auto. |
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character or NULL. Base ggplot2 theme name (e.g. "theme_bw"). NULL = global setting. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting. |

**返回 / Returns:** ggplot 对象；`return_data=TRUE` 时返回含 `plot` 和整理后的 `data` 的列表。

A ggplot object; with `return_data=TRUE`, a list with `plot` and the processed `data`.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_SSB(b, type = "SSB", se = TRUE, facet_ncol = 3,
  line_size = 0.6)
```

![示例图 / Example figure: `plot_SSB(b, se = TRUE, facet_ncol = 3, line_size = 0.6)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/plot_SSB_SSB.png?raw=true&v=d3d36a38c338)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_SSB)。

<a id="plot_SSB_Rec"></a>
## `plot_SSB_Rec()`

亲体与补充关系 / Spawning biomass and recruitment

```r
plot_SSB_Rec (model_result, age_at_recruitment = 1, point_size = NULL, point_color = NULL,
    point_shape = 16, return_data = FALSE, title = NULL, xlab = NULL, ylab = NULL,
    font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL,
    strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL,
    title_hjust = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model_result` | `必填 / required` | 单次模型拟合结果。 | A list containing the model results. It includes a component "report" that comprises "SSB" and "Rec". |
| `age_at_recruitment` | `1` | 以年为单位的补充年龄；除以 growth_step 得到整数步滞后，允许零。 | Recruitment age in years; divided by growth_step to obtain an integer lag. Zero is allowed; default 1 year. |
| `point_size` | `NULL` | 点大小；NULL 继承全局 point_size（默认 2.5）。 | Numeric or NULL. NULL inherits the global point_size setting (default 2.5). |
| `point_color` | `NULL` | 点颜色。 | Character or NULL. NULL inherits the global point_color setting. |
| `point_shape` | `16` | 点形状编号，如 16、21。 | Numeric. The shape of the points in the scatter plot, as an integer value (see ?points in base R for more info). Default is 16 (filled circle). |
| `return_data` | `FALSE` | TRUE 同时返回绘图对象及整理后的数据；结构见返回说明。 | A logical indicating whether to return the processed data alongside the plot. Default is FALSE. |
| `title` | `NULL` | 自定义图标题；NULL 继承默认。 | Character or NULL. Custom plot title. If NULL, uses global theme setting. See acl_theme_set(). |
| `xlab` | `NULL` | 自定义横轴标签；NULL 继承主题。 | Character or NULL. Custom x-axis label. If NULL, uses global theme setting. |
| `ylab` | `NULL` | 自定义纵轴标签；NULL 继承主题。 | Character or NULL. Custom y-axis label. If NULL, uses global theme setting. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character or NULL. Custom font family. If NULL, uses global theme setting (default "sans"). |
| `title_size` | `NULL` | 图标题字号。 | Numeric or NULL. Plot title size in pt. If NULL, uses global theme (default 14). |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12). |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10). |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10). |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10). |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector or NULL. Custom x-axis breaks (e.g. seq(1, 20, by = 2)). NULL = auto. |
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character or NULL. Base ggplot2 theme name (e.g. "theme_bw"). NULL = global setting. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting. |

**返回 / Returns:** ggplot 对象；`return_data=TRUE` 时返回含 `plot` 和整理后的 `data` 的列表。

A ggplot object; with `return_data=TRUE`, a list with `plot` and the processed `data`.

`age_at_recruitment` 的单位是年。`plot_SSB_Rec()` 除以拟合的 `growth_step`，要求在规则时间网格上对应整数个时间步。季度数据中，0.25 表示滞后一季度，1 表示四季度。允许零滞后；拒绝负值、非有限值及非整数步滞后。旧结果没有 `growth_step` 时使用规则年份间隔；两类时间元数据都没有时沿用年度步长。

`age_at_recruitment` is in years. `plot_SSB_Rec()` divides it by the fit's `growth_step` and requires an integer lag on a regular time grid. With quarterly data, 0.25 means one step and 1 means four steps. Zero lag is allowed; negative, nonfinite and fractional-step lags are rejected. Legacy results without `growth_step` use their regular time spacing, or an annual step when neither metadata field is available.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_SSB_Rec(b, age_at_recruitment = 1)
```

![示例图 / Example figure: `plot_SSB_Rec(b, age_at_recruitment = 1)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/SSB_Rec.png?raw=true&v=1ba690a33945)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_SSB_Rec)。

<a id="plot_VB"></a>
## `plot_VB()`

生长曲线与区间 / Growth curve and interval

`age_range = NULL` 使用拟合年龄范围；旧结果没有年龄信息时回退到 1–25 岁，自动起点不早于 `t0`。显式范围必须是有限、递增且起点不早于 `t0` 的二元向量；自动范围没有正跨度时会报错。有效的显式范围仍可使用。两种区间样式均保留参数标注，并遵守 `text_size`、`text_color`、`font_family` 和 `ylab$growth`；单次调用的标签优先。

`age_range = NULL` uses the fitted age range; older results without age metadata fall back to 1–25 years. The automatic lower endpoint is at least `t0`. An explicit range must be a finite increasing pair starting at or after `t0`; an automatic range with no positive span is rejected. Valid explicit ranges remain supported. Both confidence-interval styles retain the parameter annotation and honor `text_size`, `text_color`, `font_family`, and `ylab$growth`; explicit labels override global labels.

`ylab` 在所有模式生效；协方差不可用时提示并仅绘制曲线，保留全部自定义样式。 `ylab` is honored in every mode; unavailable covariance triggers a warning and an estimate-only curve that retains all custom styling.

```r
plot_VB (model_result, age_range = NULL, line_size = NULL, line_color = NULL, line_type = "solid",
    se = FALSE, se_color = NULL, se_alpha = NULL, se_type = c("ribbon", "errorbar"),
    text_color = "black", text_size = 5, title = NULL, xlab = NULL, ylab = NULL,
    font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL,
    strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL,
    title_hjust = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `model_result` | `必填 / required` | 单次模型拟合结果。 | A list that contains model output. The list should have a "report" component which contains "Linf", "vbk" and "t0" components. |
| `age_range` | `NULL` | 默认采用拟合年龄范围，旧结果无年龄信息时回退到 1–25 岁，自动起点不早于 t0；显式范围须有限、递增且起点不早于 t0。 | NULL uses fitted ages or the legacy 1–25 fallback, with an automatic start no earlier than t0. Explicit ranges must be finite increasing pairs starting at or after t0. |
| `line_size` | `NULL` | NULL 继承全局 line_size，显式值优先。 | NULL inherits global line_size; explicit values take priority. |
| `line_color` | `NULL` | 单模型线条颜色。 | Character or NULL. NULL inherits the global line_color setting. |
| `line_type` | `"solid"` | 线型，如 solid、dashed。 | Character. The type of the line in the plot. Default is "solid". |
| `se` | `FALSE` | 是否绘制可用标准误对应的近似区间。 | Logical. Draw approximate pointwise 95% confidence intervals using model-based standard errors. Default FALSE. |
| `se_color` | `NULL` | 区间阴影或误差棒的颜色。 | Character or NULL. NULL inherits the global se_color setting. |
| `se_alpha` | `NULL` | NULL 继承全局 se_alpha，显式值优先。 | NULL inherits global se_alpha; explicit values take priority. |
| `se_type` | `c("ribbon", "errorbar")` | 区间样式：ribbon 或 errorbar。 | Character. Type of CI display: "ribbon" (shaded area) or "errorbar" (error bars). Default is "ribbon". |
| `text_color` | `"black"` | 生长参数标注文字颜色。 | Character. The color of the text in the plot. Default is "black". |
| `text_size` | `5` | 生长参数标注文字大小。 | Numeric. The thickness of the text in the plot. Default is 5. |
| `title` | `NULL` | 自定义图标题；NULL 继承默认。 | Character or NULL. Custom plot title. If NULL, uses global theme setting. See acl_theme_set(). |
| `xlab` | `NULL` | 自定义横轴标签；NULL 继承主题。 | Character or NULL. Custom x-axis label. If NULL, uses global theme setting. |
| `ylab` | `NULL` | 自定义纵轴标签；NULL 继承主题。 | Character or NULL. Custom y-axis label. If NULL, uses global theme setting. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character or NULL. Custom font family. If NULL, uses global theme setting (default "sans"). |
| `title_size` | `NULL` | 图标题字号。 | Numeric or NULL. Plot title size in pt. If NULL, uses global theme (default 14). |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12). |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10). |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10). |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10). |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector or NULL. Custom x-axis breaks (e.g. seq(1, 20, by = 2)). NULL = auto. |
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character or NULL. Base ggplot2 theme name (e.g. "theme_bw"). NULL = global setting. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting. |

**返回 / Returns:** ggplot 对象，可继续调整样式或用 `ggplot2::ggsave()` 保存。

A ggplot object, suitable for further styling or `ggplot2::ggsave()`.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
plot_VB(b, se = TRUE)
```

![示例图 / Example figure: `plot_VB(b, se = TRUE)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/VB.png?raw=true&v=e2a1e504fa32)

[查看实际 YTF 图和解读 / Rendered YTF examples](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md#plot_VB)。

<a id="retro_acl"></a>
## `retro_acl()`

ACL 回溯入口 / ACL retrospective wrapper

回溯子拟合会随保留时期同步截短 `map$dev_log_R` 与 `map$dev_log_F`。请提供完整数据长度的映射：补充量每期一项；F 按组别×时期矩阵的列顺序排列，ACL 使用年龄组、ALSCL 使用体长组，`F_structure = "year"` 只有一组。因子共享关系和固定的 NA 项会保留；完整映射长度错误会明确报错。标量映射及 `dev_log_N0` 不随回溯截短。

Retrospective peels shorten time-dependent `map$dev_log_R` and `map$dev_log_F` with the retained periods. Supply maps for the full dataset: recruitment uses one entry per period; F uses group-by-time column order (age groups for ACL, length groups for ALSCL, one group for `F_structure = "year"`). Factor ties and fixed NA entries are retained. Invalid full-data map lengths are rejected. Scalar maps and `dev_log_N0` do not change with a peel.

```r
retro_acl (nyear = 5, data.CatL, data.wgt, data.mat, rec.age, nage, M, sel_L50, sel_L95,
    parameters = NULL, parameters.L = NULL, parameters.U = NULL, map = NULL, len_mid = NULL,
    len_border = NULL, plot = FALSE, line_size = NULL, point_size = NULL, point_shape = 21,
    facet_scales = "free", facet_ncol = NULL, facet_nrow = NULL, train_times = 1,
    title = NULL, xlab = NULL, ylab = NULL, font_family = NULL, title_size = NULL,
    axis_title_size = NULL, axis_text_size = NULL, strip_text_size = NULL, legend_text_size = NULL,
    x_breaks = NULL, base_theme = NULL, title_hjust = NULL, rho_digits = 4, rho_position = "top_right",
    rho_size = 3.5, ncores = 1, ...)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `nyear` | `5` | 模拟器为总年数；回溯函数为删除的末端时间步数。 | Number of terminal observation steps peeled, not calendar years for quarterly data. |
| `data.CatL` | `必填 / required` | 原拟合使用的调查数量指数表（首列体长标签，其余列为模型时期），或完整拟合输入列表。 | The original survey numbers-at-length or index table (length labels followed by model periods), or a complete fitting input bundle. |
| `data.wgt` | `必填 / required` | 平均单尾体重表，与调查表完全对齐。 | The weight data. |
| `data.mat` | `必填 / required` | 成熟比例表，0–1，与调查表完全对齐。 | The maturity data. |
| `rec.age` | `必填 / required` | 补充年龄，单位为年。 | The recruitment age. |
| `nage` | `必填 / required` | 年龄组数量，包括最大年龄加组。 | The number of age classes. |
| `M` | `必填 / required` | 每个模型时间步的自然死亡瞬时率。 | The natural mortality rate. |
| `sel_L50` | `必填 / required` | 调查可捕性达到 0.5 的体长。 | Length at survey catchability 0.5. |
| `sel_L95` | `必填 / required` | 调查可捕性达到 0.95 的体长，必须大于 sel_L50。 | Length at survey catchability 0.95, greater than sel_L50. |
| `parameters` | `NULL` | 命名参数初值列表，采用优化器尺度。 | Optional custom starting parameter list. |
| `parameters.L` | `NULL` | 命名下界列表，采用优化器尺度。 | Optional lower bounds for parameters. |
| `parameters.U` | `NULL` | 命名上界列表，采用优化器尺度。 | Optional upper bounds for parameters. |
| `map` | `NULL` | TMB 映射；factor(NA) 固定，具名 NULL 项释放该项；整个 map=NULL 则使用模型默认固定规则。 | Optional TMB map argument for fixing parameters. |
| `len_mid` | `NULL` | 每个体长组的中心值向量，长度与数据行数相同。 | Optional numeric vector of length bin midpoints. |
| `len_border` | `NULL` | 体长边界；拟合入口需要 nlen-1 个内部边界，模拟器使用 nlen+1 个完整边界。 | Optional numeric vector of length bin borders. |
| `plot` | `FALSE` | TRUE 请求附带图；没有有限估计时警告并返回 plot = NULL，仍保留诊断。 | Include a plot when TRUE; if no finite estimates are available, warn and return plot = NULL while retaining diagnostics. |
| `line_size` | `NULL` | NULL 继承全局 line_size，显式值优先。 | NULL inherits global line_size; explicit values take priority. |
| `point_size` | `NULL` | 点大小；NULL 继承全局 point_size（默认 2.5）。 | Numeric or NULL. NULL inherits the global point_size setting (default 2.5). |
| `point_shape` | `21` | 点形状编号，如 16、21。 | Numeric. Point shape for endpoints. Default is 21. |
| `facet_scales` | `"free"` | fixed、free、free_x 或 free_y；自由尺度有助观察组内变化。 | Character. Facet scales argument. Default is "free". |
| `facet_ncol` | `NULL` | 分面排列的列数。 | Integer or NULL. Number of facet columns. |
| `facet_nrow` | `NULL` | 分面排列的行数。 | Integer or NULL. Number of facet rows. |
| `train_times` | `1` | 每个初始点连续优化的次数。 | Number of successive optimization passes per start; not independent random starts. |
| `title` | `NULL` | 自定义图标题；NULL 继承默认。 | Character or NULL. Custom plot title. |
| `xlab` | `NULL` | 坐标轴标签；主题设置函数中使用命名列表。 | Character or NULL. Custom x-axis label. |
| `ylab` | `NULL` | 坐标轴标签；主题设置函数中使用命名列表。 | Character or NULL. Custom y-axis label. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character or NULL. Font family. |
| `title_size` | `NULL` | 图标题字号。 | Numeric or NULL. Title size in pt. |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector or NULL. Custom x-axis breaks. |
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character or NULL. Base ggplot2 theme name. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment. |
| `rho_digits` | `4` | Mohn rho 显示的小数位数。 | Integer. Decimal places for Mohn's rho display. Default is 4. |
| `rho_position` | `"top_right"` | Mohn rho 标注位置。 | Character. Position of rho text. Default is "top_right". |
| `rho_size` | `3.5` | Mohn rho 标注字号。 | Numeric. Font size of rho text. Default is 3.5. |
| `ncores` | `1` | 独立回溯拟合的最大并行工作进程数；1 为顺序执行。 | Maximum workers across independent retrospective peels; 1 runs sequentially. |
| `...` | 可选 / optional | 转发参数；仅使用目标函数接受的命名参数。 | Additional arguments passed to retro_model(). |

**返回 / Returns:** 列表包含 results（各次回溯轨迹）、last_points（各轨迹末点）、rho_by_peel（逐次回溯的相对差异）、rho_text（通过数值筛查后汇总的 Mohn's rho）和 raw_rho_text（未筛查的描述性汇总）。fit_diagnostics 与 errors 保留逐次拟合状态和错误；model_type、workers、nstarts 记录模型与计算设置。plot=TRUE 时另返回 plot 对象；无有效估计可绘制时 plot 为 NULL。

A list with results (peel trajectories), last_points (terminal estimates), rho_by_peel (relative differences by peel), rho_text (numerically screened Mohn's rho) and raw_rho_text (unscreened descriptive summaries). fit_diagnostics and errors retain fit status and errors. model_type, workers and nstarts record model and computation settings. With plot=TRUE, plot contains the plot object, or NULL when no finite estimates can be drawn.

**诊断 / Diagnostics:** 支持同一份拟合 x，显式设置优先；原逐项参数和 do.call 写法保留。fit_diagnostics 保留完整拟合及每轮状态。若任何要求的拟合未通过数值筛查，或末端差无定义，rho_text 的相应 Rho 为 NA 并警告；rho_by_peel、raw_rho_text 和 errors 保留追查记录。 / Accepts the fitting bundle with explicit overrides and preserves legacy calls. fit_diagnostics retains the full fit and all peels. Any failed requested numerical screen or undefined terminal difference makes the corresponding authoritative rho NA with a warning; rho_by_peel, raw_rho_text and errors retain exploratory records.

当全部回溯拟合失败或没有有限轨迹时，`plot = TRUE` 会警告并返回 `plot = NULL`，同时保留 `fit_diagnostics`、`errors` 及不可用的 rho。应根据这些字段修正输入或拟合设置。请求绘图不再阻止读取失败记录。

When all retrospective fits fail or no finite trajectories remain, `plot = TRUE` now warns and returns `plot = NULL` while preserving `fit_diagnostics`, `errors` and the unavailable rho values. Inspect those fields to correct the input or fitting problem. Requesting a plot must not prevent access to the failure record.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
ra <- retro_acl(x, nyear = 3)
ra$fit_diagnostics
ra$rho_text
```

![示例图 / Example figure: `plot_retro(retro_acl(x, nyear = 3), facet_ncol = 2)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ACL.png?raw=true&v=a6c651d2e0de)

<a id="retro_alscl"></a>
## `retro_alscl()`

ALSCL 回溯入口 / ALSCL retrospective wrapper

回溯子拟合会随保留时期同步截短 `map$dev_log_R` 与 `map$dev_log_F`。请提供完整数据长度的映射：补充量每期一项；F 按组别×时期矩阵的列顺序排列，ACL 使用年龄组、ALSCL 使用体长组，`F_structure = "year"` 只有一组。因子共享关系和固定的 NA 项会保留；完整映射长度错误会明确报错。标量映射及 `dev_log_N0` 不随回溯截短。

Retrospective peels shorten time-dependent `map$dev_log_R` and `map$dev_log_F` with the retained periods. Supply maps for the full dataset: recruitment uses one entry per period; F uses group-by-time column order (age groups for ACL, length groups for ALSCL, one group for `F_structure = "year"`). Factor ties and fixed NA entries are retained. Invalid full-data map lengths are rejected. Scalar maps and `dev_log_N0` do not change with a peel.

```r
retro_alscl (nyear = 5, data.CatL, data.wgt, data.mat, rec.age, nage, M, sel_L50, sel_L95,
    growth_step = NULL, ...)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `nyear` | `5` | 模拟器为总年数；回溯函数为删除的末端时间步数。 | Number of terminal observation steps peeled, not calendar years for quarterly data. |
| `data.CatL` | `必填 / required` | 原拟合使用的调查数量指数表（首列体长标签，其余列为模型时期），或完整拟合输入列表。 | The original survey numbers-at-length or index table (length labels followed by model periods), or a complete fitting input bundle. |
| `data.wgt` | `必填 / required` | 平均单尾体重表，与调查表完全对齐。 | The weight data. |
| `data.mat` | `必填 / required` | 成熟比例表，0–1，与调查表完全对齐。 | The maturity data. |
| `rec.age` | `必填 / required` | 补充年龄，单位为年。 | The recruitment age. |
| `nage` | `必填 / required` | 年龄组数量，包括最大年龄加组。 | The number of age classes. |
| `M` | `必填 / required` | 每个模型时间步的自然死亡瞬时率。 | The natural mortality rate. |
| `sel_L50` | `必填 / required` | 调查可捕性达到 0.5 的体长。 | Length at survey catchability 0.5. |
| `sel_L95` | `必填 / required` | 调查可捕性达到 0.95 的体长，必须大于 sel_L50。 | Length at survey catchability 0.95, greater than sel_L50. |
| `growth_step` | `NULL` | 每个时间步包含的年数；NULL 时 rec.age<1 取 rec.age、否则取 1；季度为 0.25。 | Time step in years. NULL uses rec.age when it is below one, otherwise one, as in run_alscl(); a bundle supplies its own value. |
| `...` | 可选 / optional | 转发参数；仅使用目标函数接受的命名参数。 | Additional arguments passed to retro_model(). |

**返回 / Returns:** 列表包含 results（各次回溯轨迹）、last_points（各轨迹末点）、rho_by_peel（逐次回溯的相对差异）、rho_text（通过数值筛查后汇总的 Mohn's rho）和 raw_rho_text（未筛查的描述性汇总）。fit_diagnostics 与 errors 保留逐次拟合状态和错误；model_type、workers、nstarts 记录模型与计算设置。plot=TRUE 时另返回 plot 对象；无有效估计可绘制时 plot 为 NULL。

A list with results (peel trajectories), last_points (terminal estimates), rho_by_peel (relative differences by peel), rho_text (numerically screened Mohn's rho) and raw_rho_text (unscreened descriptive summaries). fit_diagnostics and errors retain fit status and errors. model_type, workers and nstarts record model and computation settings. With plot=TRUE, plot contains the plot object, or NULL when no finite estimates can be drawn.

**诊断 / Diagnostics:** 支持同一份拟合 x，显式设置优先；原逐项参数和 do.call 写法保留。fit_diagnostics 保留完整拟合及每轮状态。若任何要求的拟合未通过数值筛查，或末端差无定义，rho_text 的相应 Rho 为 NA 并警告；rho_by_peel、raw_rho_text 和 errors 保留追查记录。 / Accepts the fitting bundle with explicit overrides and preserves legacy calls. fit_diagnostics retains the full fit and all peels. Any failed requested numerical screen or undefined terminal difference makes the corresponding authoritative rho NA with a warning; rho_by_peel, raw_rho_text and errors retain exploratory records.

当全部回溯拟合失败或没有有限轨迹时，`plot = TRUE` 会警告并返回 `plot = NULL`，同时保留 `fit_diagnostics`、`errors` 及不可用的 rho。应根据这些字段修正输入或拟合设置。请求绘图不再阻止读取失败记录。

When all retrospective fits fail or no finite trajectories remain, `plot = TRUE` now warns and returns `plot = NULL` while preserving `fit_diagnostics`, `errors` and the unavailable rho values. Inspect those fields to correct the input or fitting problem. Requesting a plot must not prevent access to the failure record.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
rb <- retro_alscl(x, nyear = 3)
rb$fit_diagnostics
rb$rho_text
```

![示例图 / Example figure: `plot_retro(retro_alscl(x, nyear = 3), facet_ncol = 2)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ALSCL.png?raw=true&v=a15f447d44dc)

<a id="retro_model"></a>
## `retro_model()`

统一回溯分析 / Unified retrospective analysis

回溯子拟合会随保留时期同步截短 `map$dev_log_R` 与 `map$dev_log_F`。请提供完整数据长度的映射：补充量每期一项；F 按组别×时期矩阵的列顺序排列，ACL 使用年龄组、ALSCL 使用体长组，`F_structure = "year"` 只有一组。因子共享关系和固定的 NA 项会保留；完整映射长度错误会明确报错。标量映射及 `dev_log_N0` 不随回溯截短。

Retrospective peels shorten time-dependent `map$dev_log_R` and `map$dev_log_F` with the retained periods. Supply maps for the full dataset: recruitment uses one entry per period; F uses group-by-time column order (age groups for ACL, length groups for ALSCL, one group for `F_structure = "year"`). Factor ties and fixed NA entries are retained. Invalid full-data map lengths are rejected. Scalar maps and `dev_log_N0` do not change with a peel.

```r
retro_model (nyear = 5, data.CatL, data.wgt, data.mat, rec.age, nage, M, sel_L50, sel_L95,
    model_type = c("acl", "alscl"), growth_step = NULL, parameters = NULL, parameters.L = NULL,
    parameters.U = NULL, map = NULL, len_mid = NULL, len_border = NULL, len_lower = NULL,
    len_upper = NULL, train_times = 1, ncores = 1, silent = FALSE, plot = FALSE,
    line_size = NULL, point_size = NULL, point_shape = 21, facet_scales = "free",
    facet_ncol = NULL, facet_nrow = NULL, title = NULL, xlab = NULL, ylab = NULL,
    font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL,
    strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL,
    title_hjust = NULL, rho_digits = 4, rho_position = "top_right", rho_size = 3.5,
    F_structure = c("group_year", "year"), polish = TRUE, zero_action = c("missing",
        "error"), control = list(), nstarts = 1, model = NULL, ...)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `nyear` | `5` | 模拟器为总年数；回溯函数为删除的末端时间步数。 | Number of terminal observation steps peeled, not calendar years for quarterly data. |
| `data.CatL` | `必填 / required` | 原拟合使用的调查数量指数表（首列体长标签，其余列为模型时期），或完整拟合输入列表。 | The original survey numbers-at-length or index table (length labels followed by model periods), or a complete fitting input bundle. |
| `data.wgt` | `必填 / required` | 平均单尾体重表，与调查表完全对齐。 | The weight data. |
| `data.mat` | `必填 / required` | 成熟比例表，0–1，与调查表完全对齐。 | The maturity data. |
| `rec.age` | `必填 / required` | 补充年龄，单位为年。 | The recruitment age. |
| `nage` | `必填 / required` | 年龄组数量，包括最大年龄加组。 | The number of age classes. |
| `M` | `必填 / required` | 每个模型时间步的自然死亡瞬时率。 | The natural mortality rate. |
| `sel_L50` | `必填 / required` | 调查可捕性达到 0.5 的体长。 | Length at survey catchability 0.5. |
| `sel_L95` | `必填 / required` | 调查可捕性达到 0.95 的体长，必须大于 sel_L50。 | Length at survey catchability 0.95, greater than sel_L50. |
| `model_type` | `c("acl", "alscl")` | 模型选择：acl 或 alscl。 | Character. Model to use: "acl" (default) or "alscl". |
| `growth_step` | `NULL` | 每个时间步包含的年数；季度为 0.25。 | Time step in years. NULL uses recruitment age when below 1, otherwise 1. |
| `parameters` | `NULL` | 命名参数初值列表，采用优化器尺度。 | Optional custom starting parameter list. |
| `parameters.L` | `NULL` | 命名下界列表，采用优化器尺度。 | Optional lower bounds for parameters. |
| `parameters.U` | `NULL` | 命名上界列表，采用优化器尺度。 | Optional upper bounds for parameters. |
| `map` | `NULL` | TMB 映射；factor(NA) 固定，具名 NULL 项释放该项；整个 map=NULL 则使用模型默认固定规则。 | Optional TMB map argument for fixing parameters. |
| `len_mid` | `NULL` | 每个体长组的中心值向量，长度与数据行数相同。 | Optional numeric vector of length bin midpoints. |
| `len_border` | `NULL` | 体长边界；拟合入口需要 nlen-1 个内部边界，模拟器使用 nlen+1 个完整边界。 | Optional numeric vector of length bin borders. |
| `len_lower` | `NULL` | ALSCL 每组下界；首项必须为 `-Inf`，其余项须等于内部边界。 | ALSCL lower bounds: first entry must be `-Inf`; remaining entries must match internal boundaries. |
| `len_upper` | `NULL` | ALSCL 每组上界；末项必须为 `Inf`，其余项须等于内部边界。 | ALSCL upper bounds: final entry must be `Inf`; preceding entries must match internal boundaries. |
| `train_times` | `1` | 每个初始点连续优化的次数。 | Number of successive optimization passes per start; not independent random starts. |
| `ncores` | `1` | 显式指定并行回溯轮数；不沿用 x 内拟合用的 ncores，各轮拟合单进程。 | Explicit peel workers; stored fitting ncores is ignored, and each fit uses one fitting worker. |
| `silent` | `FALSE` | TRUE 减少拟合进度输出。 | Logical. If TRUE, suppress all progress messages. Default is FALSE. |
| `plot` | `FALSE` | TRUE 请求附带图；没有有限估计时警告并返回 plot = NULL，仍保留诊断。 | Include a plot when TRUE; if no finite estimates are available, warn and return plot = NULL while retaining diagnostics. |
| `line_size` | `NULL` | NULL 继承全局 line_size，显式值优先。 | NULL inherits global line_size; explicit values take priority. |
| `point_size` | `NULL` | 点大小；NULL 继承全局 point_size（默认 2.5）。 | Numeric or NULL. NULL inherits the global point_size setting (default 2.5). |
| `point_shape` | `21` | 点形状编号，如 16、21。 | Numeric. Point shape for endpoints. Default is 21. |
| `facet_scales` | `"free"` | fixed、free、free_x 或 free_y；自由尺度有助观察组内变化。 | Character. Facet scales argument. Default is "free". |
| `facet_ncol` | `NULL` | 分面排列的列数。 | Integer or NULL. Number of facet columns. |
| `facet_nrow` | `NULL` | 分面排列的行数。 | Integer or NULL. Number of facet rows. |
| `title` | `NULL` | 自定义图标题；NULL 继承默认。 | Character or NULL. Custom plot title. |
| `xlab` | `NULL` | 坐标轴标签；主题设置函数中使用命名列表。 | Character or NULL. Custom x-axis label. |
| `ylab` | `NULL` | 坐标轴标签；主题设置函数中使用命名列表。 | Character or NULL. Custom y-axis label. |
| `font_family` | `NULL` | 文本字体；请使用本机可用字体。 | Character or NULL. Font family. |
| `title_size` | `NULL` | 图标题字号。 | Numeric or NULL. Title size in pt. |
| `axis_title_size` | `NULL` | 坐标轴标题字号。 | Numeric or NULL. Axis title size in pt. |
| `axis_text_size` | `NULL` | 坐标刻度文字字号。 | Numeric or NULL. Axis tick label size in pt. |
| `strip_text_size` | `NULL` | 分面标签字号。 | Numeric or NULL. Facet label size in pt. |
| `legend_text_size` | `NULL` | 图例文字字号。 | Numeric or NULL. Legend text size in pt. |
| `x_breaks` | `NULL` | 横轴刻度向量；NULL 自动。 | Numeric vector or NULL. Custom x-axis breaks. |
| `base_theme` | `NULL` | 基础主题名称，如 bw、minimal 或 theme_bw。 | Character or NULL. Base ggplot2 theme name. |
| `title_hjust` | `NULL` | 标题水平对齐：0 左、0.5 中、1 右。 | Numeric or NULL. Title horizontal alignment. |
| `rho_digits` | `4` | Mohn rho 显示的小数位数。 | Integer. Decimal places for Mohn's rho display. Default is 4. |
| `rho_position` | `"top_right"` | Mohn rho 标注位置。 | Character. Position of rho text. Default is "top_right". |
| `rho_size` | `3.5` | Mohn rho 标注字号。 | Numeric. Font size of rho text. Default is 3.5. |
| `F_structure` | `c("group_year", "year")` | 默认二维组别 × 时间；year 为每期共用的一维 F 过程，组别相关自动排除。 | Original group-by-time AR1 field or one shared F per step with a 1D AR1 density. |
| `polish` | `TRUE` | 默认对所选拟合进行受保护的 Newton 收尾；FALSE 跳过。原始优化代码保留。 | Safeguarded refinement of the selected fit; retain raw optimizer codes and inspect refinement and diagnostics. |
| `zero_action` | `c("missing", "error")` | 各轮对零观测的处理；NA 始终缺失。 | Zero handling forwarded to every fit; NA is always missing. |
| `control` | `list()` | 各轮 nlminb 优化控制；显式列表整体覆盖。 | nlminb controls forwarded to each fit; explicit lists replace stored lists. |
| `nstarts` | `1` | 每轮独立起点数，在该轮内部依次计算；可沿用 x 设置。 | Starts per fit, run sequentially within a peel; may inherit the bundle value. |
| `model` | `NULL` | 与 model_type 相同，为与其他工作流函数一致而提供；两者只填一个。 | Same as model_type, accepted for consistency with the other workflow functions. Supply one of the two. |
| `...` | 可选 / optional | 旧参数名 facet_col、facet_row，仍可使用但会给出警告。 | The former argument names facet_col and facet_row, accepted with a warning. |

**返回 / Returns:** 列表包含 results（各次回溯轨迹）、last_points（各轨迹末点）、rho_by_peel（逐次回溯的相对差异）、rho_text（通过数值筛查后汇总的 Mohn's rho）和 raw_rho_text（未筛查的描述性汇总）。fit_diagnostics 与 errors 保留逐次拟合状态和错误；model_type、workers、nstarts 记录模型与计算设置。plot=TRUE 时另返回 plot 对象；无有效估计可绘制时 plot 为 NULL。

A list with results (peel trajectories), last_points (terminal estimates), rho_by_peel (relative differences by peel), rho_text (numerically screened Mohn's rho) and raw_rho_text (unscreened descriptive summaries). fit_diagnostics and errors retain fit status and errors. model_type, workers and nstarts record model and computation settings. With plot=TRUE, plot contains the plot object, or NULL when no finite estimates can be drawn.

**诊断 / Diagnostics:** 支持同一份拟合 x，显式设置优先；原逐项参数和 do.call 写法保留。fit_diagnostics 保留完整拟合及每轮状态。若任何要求的拟合未通过数值筛查，或末端差无定义，rho_text 的相应 Rho 为 NA 并警告；rho_by_peel、raw_rho_text 和 errors 保留追查记录。 / Accepts the fitting bundle with explicit overrides and preserves legacy calls. fit_diagnostics retains the full fit and all peels. Any failed requested numerical screen or undefined terminal difference makes the corresponding authoritative rho NA with a warning; rho_by_peel, raw_rho_text and errors retain exploratory records.

当全部回溯拟合失败或没有有限轨迹时，`plot = TRUE` 会警告并返回 `plot = NULL`，同时保留 `fit_diagnostics`、`errors` 及不可用的 rho。应根据这些字段修正输入或拟合设置。请求绘图不再阻止读取失败记录。

When all retrospective fits fail or no finite trajectories remain, `plot = TRUE` now warns and returns `plot = NULL` while preserving `fit_diagnostics`, `errors` and the unavailable rho values. Inspect those fields to correct the input or fitting problem. Requesting a plot must not prevent access to the failure record.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
rb <- retro_model(data.CatL = x, model_type = "alscl", nyear = 3)
rb$fit_diagnostics
rb$rho_by_peel
rb$rho_text
```

![示例图 / Example figure: `plot_retro(retro_model(x, nyear = 3, model = "alscl"), facet_ncol = 2)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ALSCL.png?raw=true&v=a15f447d44dc)

<a id="run_acl"></a>
## `run_acl()`

ALSCL 2.2.0 accepts `run_acl(x)` and `run_alscl(x)` directly. For `YTF_example`, each function selects its model-specific `fit_config` automatically; explicit call arguments override stored settings. The original separate-argument and `do.call()` forms remain valid. Both use the same built-in acceleration; inspect `a$sd_info` or `b$sd_info` for actual execution.

```r
run_acl (data.CatL, data.wgt, data.mat, rec.age, nage, M, sel_L50, sel_L95, parameters = NULL,
    parameters.L = NULL, parameters.U = NULL, map = NULL, len_mid = NULL, len_border = NULL,
    output = FALSE, train_times = 1, ncores = 1, silent = FALSE, growth_step = NULL,
    zero_action = c("missing", "error"), control = list(), nstarts = ncores, F_structure = c("group_year",
        "year"), polish = TRUE)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `data.CatL` | `必填 / required` | 调查数量指数表，或包含三表及拟合设置的命名列表（如 YTF_example）。 | Data frame or matrix with length labels in its first column, followed by at least two numerically labelled time columns. Alternatively, a named input bundle such as YTF_example. |
| `data.wgt` | `必填 / required` | 平均单尾体重表，与调查表完全对齐。 | Weight-at-length, with identical labels, columns and dimensions. |
| `data.mat` | `必填 / required` | 成熟比例表，0–1，与调查表完全对齐。 | Maturity-at-length between 0 and 1, with the same layout. |
| `rec.age` | `必填 / required` | 补充年龄，单位为年。 | Recruitment age in years, greater than t0. |
| `nage` | `必填 / required` | 年龄组数量，包括最大年龄加组。 | Number of age classes including the plus group (at least two). |
| `M` | `必填 / required` | 每个模型时间步的自然死亡瞬时率。 | Nonnegative natural mortality per model time step. |
| `sel_L50` | `必填 / required` | 调查可捕性达到 50% 的体长。 | Lengths at 50 and 95 percent survey catchability. |
| `sel_L95` | `必填 / required` | 调查可捕性达到 95% 的体长，必须大于 L50。 | Lengths at 50 and 95 percent survey catchability. |
| `parameters` | `NULL` | 命名参数初值列表，采用优化器尺度。 | Named list of initial fixed-effect values. |
| `parameters.L` | `NULL` | 命名下界列表，采用优化器尺度。 | Named lower and upper bounds. Bounds are aligned with free parameters after applying map. Initial free values are clamped to bounds. |
| `parameters.U` | `NULL` | 命名上界列表，采用优化器尺度。 | Named lower and upper bounds. Bounds are aligned with free parameters after applying map. Initial free values are clamped to bounds. |
| `map` | `NULL` | TMB 映射；factor(NA) 固定，具名 NULL 项释放该项；整个 map=NULL 则使用模型默认固定规则。 | Named TMB factor mappings. factor(NA) fixes a parameter at its supplied value; a named NULL entry releases that parameter. A whole map = NULL or list() applies model defaults. Other unspecified defaults remain in force. |
| `len_mid` | `NULL` | 每个体长组的中心值向量，长度与数据行数相同。 | Finite length-bin midpoints; overrides automatic parsing. |
| `len_border` | `NULL` | 体长边界；拟合入口需要 nlen-1 个内部边界，模拟器使用 nlen+1 个完整边界。 | Interior boundaries, one fewer than the number of length bins. |
| `output` | `FALSE` | 是否导出拟合诊断与图；TRUE 使用 output 目录。 | Save diagnostic tables and plots below output/ when TRUE. |
| `train_times` | `1` | 每个初始点连续优化的次数。 | Number of successive optimization passes per start; not independent random starts. |
| `ncores` | `1` | 独立初始点拟合的最大并行进程数，实际不超过 nstarts；不是单个 TMB 拟合的线程数。 | Maximum socket workers across independent starts, capped at nstarts; not threads within one start. |
| `silent` | `FALSE` | TRUE 减少拟合进度输出。 | Suppress fitting progress messages when TRUE. |
| `growth_step` | `NULL` | 每个时间步包含的年数；NULL 时 rec.age<1 取 rec.age、否则取 1；季度为 0.25，时间标签间隔必须相同。 | Time between consecutive ages, in years; 0.25 for quarters. NULL uses rec.age when it is below one, otherwise one. Numeric time-column labels must have this spacing; keep missing periods as NA survey columns with weights and maturity for every period. |
| `zero_action` | `c("missing", "error")` | missing 排除调查零值；error 报错。NA 始终为缺失。 | Exclude zero observations as missing (historical behavior), or reject them with "error". NA is always missing; negative/infinite values fail. |
| `control` | `list()` | 传入 nlminb 的命名控制列表，如 iter.max、eval.max。 | A named list of nlminb control settings. |
| `nstarts` | `ncores` | 初始点总数；默认等于 ncores 以兼容旧用法。固定此值可公平比较不同并行数；后续起点仅扰动自由参数。 | Total independent starts; defaults to ncores for compatibility. Fix this value for equal-work comparisons. Later starts deterministically jitter free parameters only. |
| `F_structure` | `c("group_year", "year")` | 默认二维组别 × 时间；year 为每期共用的一维 F 过程，组别相关自动排除。 | Original group-by-time AR1 field or one shared F per step with a 1D AR1 density. |
| `polish` | `TRUE` | 默认对所选拟合进行受保护的 Newton 收尾；FALSE 跳过。原始优化代码保留。 | Safeguarded refinement of the selected fit; retain raw optimizer codes and inspect refinement and diagnostics. |

**返回 / Returns:** alscl_fit 类的列表，保留原有 $ 访问方式。report 保存种群量和调查预测；opt 保存所选优化参数、目标函数和原始状态；obj 是当前会话的 TMB 对象；est_std、vcov 和 pdHess 保存近似不确定性及 Hessian 状态。gradient、max_abs_gradient（亦为 final_outer_mgc）、convergence_code、bound_hit 和 diagnostics 用于数值检查。raw_opt、optimizer_history、refinement 保存优化与收尾记录。year、age、体长元数据、growth_step、F_structure 和 elapsed 记录坐标、结构及耗时；starts、start_diagnostics、nstarts 和 workers 记录各起点参数、PID、时间及计算量。recipe 保存重新拟合所需的完整输入与设置。多起点按最低有限目标函数选取，仍须另查数值状态；obj 只可在原会话动态库保持加载时求值。 sd_info 记录标准误的计算方式（方法、核数、耗时）。 / sd_info records how the standard errors were computed (method, cores, seconds).

A list of class alscl_fit, retaining existing $ access. report stores population quantities and survey predictions; opt stores the selected optimizer parameters, objective and raw status; obj is the session-specific TMB object; est_std, vcov and pdHess describe approximate uncertainty and Hessian status. gradient, max_abs_gradient (also final_outer_mgc), convergence_code, bound_hit and diagnostics support numerical checks. raw_opt, optimizer_history and refinement retain optimization records. year, age, length metadata, growth_step, F_structure and elapsed record coordinates, structure and timing. starts, start_diagnostics, nstarts and workers record starting values, PIDs, timestamps and work performed. recipe stores complete inputs and fitting settings. Selection uses the lowest finite objective; inspect numerical status separately. Evaluating obj requires the DLL to remain loaded in the fitting session.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
a <- run_acl(x)
```

**初值与固定 / Starts and fixes:** `parameters` 中的值仅为初值，除非 map 将该项固定。`map = NULL` / `list()` 恢复模型默认规则。ACL 默认固定 `log_std_log_F`、`logit_log_F_y`、`logit_log_F_a`、`t0`；ALSCL 默认固定 `log_sigma_log_F`、`log_t0`。具名 NULL 项（如 `list(log_sigma_log_F = NULL)`，仅 ALSCL）解除对应固定。`map["name"] <- list(NULL)` 保留解除指令，`map$name <- NULL` 则删除条目。

Parameters are estimated from their starting values unless fixed by the map. A whole NULL/empty map restores model defaults: four scalar fixes for ACL, two for ALSCL, as listed above. A named NULL entry releases that parameter. Keep it with single-bracket assignment; deleting the entry re-applies a default fix. See the complete [English](https://fanzhang-lab-shou.github.io/ALSCL/articles/case-fit-survey.html) / [简体中文](https://fanzhang-lab-shou.github.io/ALSCL/zh/articles/case-fit-survey.html) input checklist, parameter table and executable example.

<a id="run_alscl"></a>
## `run_alscl()`

ALSCL 2.2.0 accepts `run_acl(x)` and `run_alscl(x)` directly. For `YTF_example`, each function selects its model-specific `fit_config` automatically; explicit call arguments override stored settings. The original separate-argument and `do.call()` forms remain valid. Both use the same built-in acceleration; inspect `a$sd_info` or `b$sd_info` for actual execution.

```r
run_alscl (data.CatL, data.wgt, data.mat, rec.age, nage, M, sel_L50, sel_L95, growth_step = NULL,
    parameters = NULL, parameters.L = NULL, parameters.U = NULL, map = NULL, len_mid = NULL,
    len_border = NULL, len_lower = NULL, len_upper = NULL, output = FALSE, train_times = 1,
    ncores = 1, silent = FALSE, zero_action = c("missing", "error"), control = list(),
    nstarts = ncores, F_structure = c("group_year", "year"), polish = TRUE)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `data.CatL` | `必填 / required` | 调查数量指数表，或包含三表及拟合设置的命名列表（如 YTF_example）。 | Data frame or matrix with length labels in its first column, followed by at least two numerically labelled time columns. Alternatively, a named input bundle such as YTF_example. |
| `data.wgt` | `必填 / required` | 平均单尾体重表，与调查表完全对齐。 | Weight-at-length, with identical labels, columns and dimensions. |
| `data.mat` | `必填 / required` | 成熟比例表，0–1，与调查表完全对齐。 | Maturity-at-length between 0 and 1, with the same layout. |
| `rec.age` | `必填 / required` | 补充年龄，单位为年。 | Recruitment age in years, greater than t0. |
| `nage` | `必填 / required` | 年龄组数量，包括最大年龄加组。 | Number of age classes including the plus group (at least two). |
| `M` | `必填 / required` | 每个模型时间步的自然死亡瞬时率。 | Nonnegative natural mortality per model time step. |
| `sel_L50` | `必填 / required` | 调查可捕性达到 50% 的体长。 | Lengths at 50 and 95 percent survey catchability. |
| `sel_L95` | `必填 / required` | 调查可捕性达到 95% 的体长，必须大于 L50。 | Lengths at 50 and 95 percent survey catchability. |
| `growth_step` | `NULL` | 每个时间步包含的年数；NULL 时 rec.age<1 取 rec.age、否则取 1；季度为 0.25，时间标签间隔必须相同。 | Time between consecutive ages, in years; 0.25 for quarters. NULL uses rec.age when it is below one, otherwise one. Numeric time-column labels must have this spacing; keep missing periods as NA survey columns with weights and maturity for every period. |
| `parameters` | `NULL` | 命名参数初值列表，采用优化器尺度。 | Named list of initial fixed-effect values. |
| `parameters.L` | `NULL` | 命名下界列表，采用优化器尺度。 | Named lower and upper bounds. Bounds are aligned with free parameters after applying map. Initial free values are clamped to bounds. |
| `parameters.U` | `NULL` | 命名上界列表，采用优化器尺度。 | Named lower and upper bounds. Bounds are aligned with free parameters after applying map. Initial free values are clamped to bounds. |
| `map` | `NULL` | TMB 映射；factor(NA) 固定，具名 NULL 项释放该项；整个 map=NULL 则使用模型默认固定规则。 | Named TMB factor mappings. factor(NA) fixes a parameter at its supplied value; a named NULL entry releases that parameter. A whole map = NULL or list() applies model defaults. Other unspecified defaults remain in force. |
| `len_mid` | `NULL` | 每个体长组的中心值向量，长度与数据行数相同。 | Finite length-bin midpoints; overrides automatic parsing. |
| `len_border` | `NULL` | 体长边界；拟合入口需要 nlen-1 个内部边界，模拟器使用 nlen+1 个完整边界。 | Interior boundaries, one fewer than the number of length bins. |
| `len_lower` | `NULL` | ALSCL 每组下界；首项必须为 `-Inf`，其余项须等于内部边界。 | ALSCL lower bounds: first entry must be `-Inf`; remaining entries must match internal boundaries. |
| `len_upper` | `NULL` | ALSCL 每组上界；末项必须为 `Inf`，其余项须等于内部边界。 | ALSCL upper bounds: final entry must be `Inf`; preceding entries must match internal boundaries. |
| `output` | `FALSE` | 是否导出拟合诊断与图；TRUE 使用 output 目录。 | Save diagnostic tables and plots below output/ when TRUE. |
| `train_times` | `1` | 每个初始点连续优化的次数。 | Number of successive optimization passes per start; not independent random starts. |
| `ncores` | `1` | 独立初始点拟合的最大并行进程数，实际不超过 nstarts；不是单个 TMB 拟合的线程数。 | Maximum socket workers across independent starts, capped at nstarts; not threads within one start. |
| `silent` | `FALSE` | TRUE 减少拟合进度输出。 | Suppress fitting progress messages when TRUE. |
| `zero_action` | `c("missing", "error")` | missing 排除调查零值；error 报错。NA 始终为缺失。 | Exclude zero observations as missing (historical behavior), or reject them with "error". NA is always missing; negative/infinite values fail. |
| `control` | `list()` | 传入 nlminb 的命名控制列表，如 iter.max、eval.max。 | A named list of nlminb control settings. |
| `nstarts` | `ncores` | 初始点总数；默认等于 ncores 以兼容旧用法。固定此值可公平比较不同并行数；后续起点仅扰动自由参数。 | Total independent starts; defaults to ncores for compatibility. Fix this value for equal-work comparisons. Later starts deterministically jitter free parameters only. |
| `F_structure` | `c("group_year", "year")` | 默认二维组别 × 时间；year 为每期共用的一维 F 过程，组别相关自动排除。 | Original group-by-time AR1 field or one shared F per step with a 1D AR1 density. |
| `polish` | `TRUE` | 默认对所选拟合进行受保护的 Newton 收尾；FALSE 跳过。原始优化代码保留。 | Safeguarded refinement of the selected fit; retain raw optimizer codes and inspect refinement and diagnostics. |

**返回 / Returns:** alscl_fit 类的列表，保留原有 $ 访问方式。report 保存种群量和调查预测；opt 保存所选优化参数、目标函数和原始状态；obj 是当前会话的 TMB 对象；est_std、vcov 和 pdHess 保存近似不确定性及 Hessian 状态。gradient、max_abs_gradient（亦为 final_outer_mgc）、convergence_code、bound_hit 和 diagnostics 用于数值检查。raw_opt、optimizer_history、refinement 保存优化与收尾记录。year、age、体长元数据、growth_step、F_structure 和 elapsed 记录坐标、结构及耗时；starts、start_diagnostics、nstarts 和 workers 记录各起点参数、PID、时间及计算量。recipe 保存重新拟合所需的完整输入与设置。多起点按最低有限目标函数选取，仍须另查数值状态；obj 只可在原会话动态库保持加载时求值。 sd_info 记录标准误的计算方式（方法、核数、耗时）。 / sd_info records how the standard errors were computed (method, cores, seconds).

A list of class alscl_fit, retaining existing $ access. report stores population quantities and survey predictions; opt stores the selected optimizer parameters, objective and raw status; obj is the session-specific TMB object; est_std, vcov and pdHess describe approximate uncertainty and Hessian status. gradient, max_abs_gradient (also final_outer_mgc), convergence_code, bound_hit and diagnostics support numerical checks. raw_opt, optimizer_history and refinement retain optimization records. year, age, length metadata, growth_step, F_structure and elapsed record coordinates, structure and timing. starts, start_diagnostics, nstarts and workers record starting values, PIDs, timestamps and work performed. recipe stores complete inputs and fitting settings. Selection uses the lowest finite objective; inspect numerical status separately. Evaluating obj requires the DLL to remain loaded in the fitting session.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
b <- run_alscl(x)
```

**初值与固定 / Starts and fixes:** `parameters` 中的值仅为初值，除非 map 将该项固定。`map = NULL` / `list()` 恢复模型默认规则。ACL 默认固定 `log_std_log_F`、`logit_log_F_y`、`logit_log_F_a`、`t0`；ALSCL 默认固定 `log_sigma_log_F`、`log_t0`。具名 NULL 项（如 `list(log_sigma_log_F = NULL)`，仅 ALSCL）解除对应固定。`map["name"] <- list(NULL)` 保留解除指令，`map$name <- NULL` 则删除条目。

Parameters are estimated from their starting values unless fixed by the map. A whole NULL/empty map restores model defaults: four scalar fixes for ACL, two for ALSCL, as listed above. A named NULL entry releases that parameter. Keep it with single-bracket assignment; deleting the entry re-applies a default fix. See the complete [English](https://fanzhang-lab-shou.github.io/ALSCL/articles/case-fit-survey.html) / [简体中文](https://fanzhang-lab-shou.github.io/ALSCL/zh/articles/case-fit-survey.html) input checklist, parameter table and executable example.

<a id="sim_acl"></a>
## `sim_acl()`

批量拟合 ACL 模拟重复 / Fit simulated replicates with ACL

`sim_acl()` 将每次重复的结果（包括失败状态）保存到 `result_rep_<iter>`。复用输出目录时，本轮失败记录会替换旧成功结果；汇总前检查 `converge` 和 `error`。写入失败会明确报告，不能视为已经保存。`simulation_to_tables(sm, pa)` 使用模拟结果的长度坐标，并拒绝与参数不一致的坐标，不再给观测重新贴错标签；没有坐标的旧模拟可使用匹配的参数元数据。

`sim_acl()` saves the status of every replicate, including failures, to `result_rep_<iter>`. Reusing an output directory replaces an earlier success with the current failure record; inspect `converge` and `error` before summarizing results. Output write failures are reported and must not be treated as saved results. `simulation_to_tables(sm, pa)` uses the simulation length coordinates and rejects conflicting parameter coordinates instead of relabeling observations; legacy simulations without coordinates can use matching parameter metadata.

```r
sim_acl (iter_range = 4:100, sim_data_path = ".", output_dir = ".", parameters = NULL,
    parameters.L = NULL, parameters.U = NULL, map = NULL, M = 0.2, ncores = 1, train_times = 1,
    control = list(), F_structure = c("group_year", "year"), polish = TRUE, nstarts = 1)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `iter_range` | `4:100` | 重复编号；模拟时也用作随机种子。 | A numeric vector specifying the range of iterations to run the stock assessment model for (default is 4:100). |
| `sim_data_path` | `"."` | 包含 sim_rep 文件的目录。 | A character string specifying the path to the folder containing the simulation data files (default is the current working directory). |
| `output_dir` | `"."` | 输出目录；必要时自动建立。 | Character, the directory where simulation results will be saved.(default is the current working directory). |
| `parameters` | `NULL` | 命名参数初值列表，采用优化器尺度。 | A list containing the custom initial values for the parameters (default is NULL). |
| `parameters.L` | `NULL` | 命名下界列表，采用优化器尺度。 | A list containing the custom lower bounds for the parameters (default is NULL). |
| `parameters.U` | `NULL` | 命名上界列表，采用优化器尺度。 | A list containing the custom upper bounds for the parameters (default is NULL). |
| `map` | `NULL` | TMB 映射；factor(NA) 固定，具名 NULL 项释放该项；整个 map=NULL 则使用模型默认固定规则。 | A list containing the custom values for the map elements (default is NULL). |
| `M` | `0.2` | 每个模型时间步的自然死亡瞬时率。 | Numeric, natural mortality (default: 0.2) |
| `ncores` | `1` | 独立模拟重复的最大 socket 工作进程数；1 为顺序执行，每次拟合内部使用单进程。 | Maximum socket workers across independent simulated replicates; 1 runs sequentially and each inner fit uses one worker. |
| `train_times` | `1` | 每个初始点连续优化的次数。 | Number of successive optimization passes per start; not independent random starts. |
| `control` | `list()` | 传入 nlminb 的命名控制列表，如 iter.max、eval.max。 | Named nlminb control settings. |
| `F_structure` | `c("group_year", "year")` | 默认二维组别 × 时间；year 为每期共用的一维 F 过程，组别相关自动排除。 | Original group-by-time AR1 field or one shared F per step with a 1D AR1 density. |
| `polish` | `TRUE` | 默认对所选拟合进行受保护的 Newton 收尾；FALSE 跳过。原始优化代码保留。 | Safeguarded refinement of the selected fit; retain raw optimizer codes and inspect refinement and diagnostics. |
| `nstarts` | `1` | 每个模拟重复的独立初值数，在重复内部依次运行；ncores 仍控制外层并行重复数。 | Independent starts per replicate, run sequentially; ncores still controls outer replicate workers. |

**返回 / Returns:** 按重复编号命名的拟合或错误记录列表（`result_rep_<id>`），包含 iter 和 elapsed。每次重复均写入对应文件，包括失败记录；失败项另含 converge="FAILED" 和 error。重跑失败会替换旧成功记录，文件写入失败会明确报告。

A named list of replicate fits or error records (`result_rep_<id>`), including iter and elapsed. Every replicate is written to its corresponding file, including failures; failed records also contain converge="FAILED" and error. A failed rerun replaces an earlier success record, and output-write failures are reported.

快速年度模拟器的 `mean_F` 等于生成 F 序列的算术平均值；`mean_F = 0` 生成零捕捞死亡率。

完整模拟器的 `nyear`、`burn_in` 都以年为单位，且分别必须对应整数个 `growth_step`。因此季度模式允许半年预热，年度模式不允许。返回的 `sm$nyear` 是保留时间步数；`first.year` 是第一期保留观测的年份，`sm$years` 保存完整观测时间轴。`simulation_to_tables()` 和 `sim_acl()` 保留这条时间轴；完全没有年份元数据的旧文件仍可使用从 2000 开始的后备规则。只保留一期时仍返回矩阵，但拟合至少需要两期。

`sim_acl()` 在发送 socket 任务前求值路径与参数变量，因此一般控制台或脚本中的变量传参也支持多核。保留失败重复并检查逐次拟合诊断；工作进程运行成功并不单独证明评估结果可用。

In the quick annual simulator, `mean_F` is the arithmetic mean of the generated F trajectory; `mean_F = 0` generates zero F.

For the full simulator, `nyear` and `burn_in` are durations in years and must each contain a whole number of `growth_step` intervals. Thus a half-year burn-in is valid with quarterly steps, but not annual steps. Returned `sm$nyear` counts retained steps. `first.year` labels the first retained observation, and `sm$years` records the complete retained calendar. `simulation_to_tables()` and `sim_acl()` preserve this calendar; old files lacking year metadata still have a documented 2000-based fallback. A single retained period stays a matrix, although fitting requires at least two periods.

`sim_acl()` resolves path and parameter variables before sending tasks to socket workers, so ordinary console/script calls work with multiple cores. Retain failed replicates and inspect each fit's diagnostics; successful worker execution alone does not establish a usable assessment.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
do.call(sim_acl, c(list(iter_range = 4:5,
  sim_data_path = "simulation_examples/flatfish",
  output_dir = "simulation_examples/fit", M = pa$M), x$fit_config$acl))
```

<a id="sim_cal"></a>
## `sim_cal()`

从参数计算生物矩阵 / Calculate biological arrays

```r
sim_cal (params)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `params` | `必填 / required` | initialize_params() 返回的完整模拟参数列表。 | A list of parameters from initialize_params(). Must contain model_type ("age_based" or "length_based") to determine which transition matrix to build. |

**返回 / Returns:** 生物数组列表：model_type 为生成模型结构；LatA 为平均年龄别体长；W_at_len 为体长别平均个体重量；mat 为成熟比例；q_surv 为调查可捕性；sel 为渔业选择性；pla 为给定年龄的体长概率矩阵。另含体长组坐标和边界；length_based 模型的 Gij 为体长组间一步生长转移矩阵，age_based 模型的 Gij 为 NULL。

A list of biological arrays: model_type identifies the operating-model structure; LatA is mean length at age; W_at_len is individual weight at length; mat is maturity; q_surv is survey catchability; sel is fishery selectivity; pla is the matrix of length probabilities conditional on age. Length coordinates and bounds are included. Gij is the one-step length-growth transition matrix for length_based models and NULL for age_based models.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
bio <- sim_cal(pa)
```


`pla` 表示给定年龄的体长组概率。age_based 模拟器中行为年龄、列为体长组，每行和为 1；length_based 模拟器中行为体长组、列为年龄，每列和为 1。`Gij[i, j]` 则表示一个模型时间步内从源体长组 j 转入目标组 i 的概率，每列和为 1。修改生物参数后需重新调用 sim_cal()。

`pla` gives length-bin probabilities conditional on age. In the age_based simulator its rows are ages and columns are length bins (each row sums to one); in the length_based simulator its rows are length bins and columns are ages (each column sums to one). `Gij[i, j]` instead gives the probability of moving from source length bin j to destination bin i over one model step; each column sums to one. Call sim_cal() again after modifying biological parameters.

<a id="sim_data"></a>
## `sim_data()`

The quick simulator now integrates the first and last length bins to negative and positive infinity, matching the fitted models. Finite `bin_breaks` still determine labels and midpoints; they do not truncate probability. Corrected simulations can change even with the same seed, especially when the first boundary excludes small fish. Previously saved datasets retain their original generating truth. Use nonnegative M, F and noise scales, positive growth parameters and a nonnegative weight coefficient, and increasing selectivity/maturity endpoints. Invalid parameters or nonfinite generated values stop before CSV files are created. The full simulator also requires normalized age-length keys and growth transitions.

```r
sim_data (bio_vars, params, sim_year = NULL, output_dir = ".", iter_range = 4:100,
    return_iter = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `bio_vars` | `必填 / required` | sim_cal() 返回的生物矩阵及生成模型类型。 | A list from sim_cal() containing biological variables. |
| `params` | `必填 / required` | initialize_params() 返回的完整模拟参数列表。 | A list from initialize_params() containing parameters. |
| `sim_year` | `NULL` | 模拟总年数；NULL 使用 params$nyear。 | Total simulation years; NULL uses params$nyear. |
| `output_dir` | `"."` | 输出目录；必要时自动建立。 | Directory for saving results (default: current directory). |
| `iter_range` | `4:100` | 重复编号；模拟时也用作随机种子。 | Integer vector, which iterations (seeds) to run (default: 4:100). |
| `return_iter` | `NULL` | 在内存中返回的重复编号；NULL 默认选 iter_range 中的最大编号。 | Replicate ID to return in memory; NULL selects the largest ID in iter_range. |

**返回 / Returns:** 返回 return_iter 指定的重复结果；NULL 默认选择 iter_range 中的最大编号。结果包含调查数量 SN_at_len、种群体长别数量 N_at_len、年龄别数量 N_at_age、SSB、Rec、捕捞量及时间、年龄、体长等元数据。所有重复另以包含 sim.data 的 `sim_rep<id>` 文件写入 output_dir。

The replicate selected by return_iter; NULL selects the largest ID in iter_range. The result includes survey numbers SN_at_len, population numbers at length N_at_len and at age N_at_age, SSB, Rec, fishery catch, and time, age and length metadata. All replicates are also written to output_dir as `sim_rep<id>` files containing sim.data.

快速年度模拟器的 `mean_F` 等于生成 F 序列的算术平均值；`mean_F = 0` 生成零捕捞死亡率。

完整模拟器的 `nyear`、`burn_in` 都以年为单位，且分别必须对应整数个 `growth_step`。因此季度模式允许半年预热，年度模式不允许。返回的 `sm$nyear` 是保留时间步数；`first.year` 是第一期保留观测的年份，`sm$years` 保存完整观测时间轴。`simulation_to_tables()` 和 `sim_acl()` 保留这条时间轴；完全没有年份元数据的旧文件仍可使用从 2000 开始的后备规则。只保留一期时仍返回矩阵，但拟合至少需要两期。

`sim_acl()` 在发送 socket 任务前求值路径与参数变量，因此一般控制台或脚本中的变量传参也支持多核。保留失败重复并检查逐次拟合诊断；工作进程运行成功并不单独证明评估结果可用。

In the quick annual simulator, `mean_F` is the arithmetic mean of the generated F trajectory; `mean_F = 0` generates zero F.

For the full simulator, `nyear` and `burn_in` are durations in years and must each contain a whole number of `growth_step` intervals. Thus a half-year burn-in is valid with quarterly steps, but not annual steps. Returned `sm$nyear` counts retained steps. `first.year` labels the first retained observation, and `sm$years` records the complete retained calendar. `simulation_to_tables()` and `sim_acl()` preserve this calendar; old files lacking year metadata still have a documented 2000-based fallback. A single retained period stays a matrix, although fitting requires at least two periods.

`sim_acl()` resolves path and parameter variables before sending tasks to socket workers, so ordinary console/script calls work with multiple cores. Retain failed replicates and inspect each fit's diagnostics; successful worker execution alone does not establish a usable assessment.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
sm <- sim_data(bio, pa, iter_range = 4:5, return_iter = 4,
               output_dir = "simulation_examples/flatfish")
```

![示例图 / Example figure: `sim_data(sim_cal(pa), pa, iter_range = 4, return_iter = 4)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/cases/flatfish_truth.png?raw=true&v=c37a38eea1f3)

<a id="simulate_example_data"></a>
## `simulate_example_data()`

快速年度教学数据生成 / Generate simple annual teaching data

快速模拟器现在把首尾体长组分别积分到负无穷和正无穷，与拟合模型一致。有限 `bin_breaks` 仍用于标签与中点，不截断概率。修正后，即使种子相同，新模拟结果也可能改变，尤其是首边界排除了较小个体时；已保存数据仍保留原始生成真值。M、F 和噪声尺度必须非负，生长参数为正、重量系数非负，选择性及成熟曲线的 95% 端点高于 50% 端点。非法参数或非有限生成结果会在创建 CSV 前报错。完整模拟器还检查年龄—体长概率及生长转移概率的归一化。

The quick simulator now integrates the first and last length bins to negative and positive infinity, matching the fitted models. Finite `bin_breaks` still determine labels and midpoints; they do not truncate probability. Corrected simulations can change even with the same seed, especially when the first boundary excludes small fish. Previously saved datasets retain their original generating truth. Use nonnegative M, F and noise scales, positive growth parameters and a nonnegative weight coefficient, and increasing selectivity/maturity endpoints. Invalid parameters or nonfinite generated values stop before CSV files are created. The full simulator also requires normalized age-length keys and growth transitions.

```r
simulate_example_data (years = 2000:2025, bin_breaks = c(0, 20, 25, 30, 35, 40, 45, 50, 55, 60),
    Linf = 55, vbk = 0.45, t0 = -0.1, M = 0.8, nage = 7, L50_sel = 28, L95_sel = 36,
    L50_mat = 33, L95_mat = 40, wgt_a = 2.2e-06, wgt_b = 3.2, mean_F = 0.3, cv_catch = 0.3,
    rec_sigma = 0.5, seed = NULL, save_csv = FALSE, output_dir = ".")
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `years` | `2000:2025` | 年份向量；快速模拟器要求连续年度，比较图用它筛选时期。 | Numeric vector of years. Default 2000:2025. |
| `bin_breaks` | `c(0, 20, 25, 30, 35, 40, 45, 50, 55, 60)` | 递增完整边界向量，相邻边界定义一个长度组。 | Numeric vector of bin boundary points. Defines n+1 boundaries for n bins. Default c(0, 20, 25, 30, 35, 40, 45, 50, 55, 60) giving 9 bins: 0-20, 20-25, 25-30, ..., 55-60. Works with any bin width (1mm, 2mm, 3mm, 5mm, etc.) and unequal widths. |
| `Linf` | `55` | VB 渐近体长，与输入体长单位一致。 | Numeric. VB asymptotic length. Default 55. |
| `vbk` | `0.45` | VB 生长系数，以年为时间单位。 | Numeric. VB growth coefficient. Default 0.45. |
| `t0` | `-0.1` | VB 理论零体长年龄，单位为年。 | Numeric. VB theoretical age at length 0. Default -0.1. |
| `M` | `0.8` | 每个模型时间步的自然死亡瞬时率。 | Numeric. Natural mortality. Default 0.8. |
| `nage` | `7` | 年龄组数量，包括最大年龄加组。 | Integer. Maximum age (plus group). Default 7. |
| `L50_sel` | `28` | 调查可捕性达到 50% 的体长。 | Numeric. Length at survey catchability 0.5. Default 28. |
| `L95_sel` | `36` | 调查可捕性达到 95% 的体长，必须大于 L50。 | Numeric. Length at survey catchability 0.95. Default 36. |
| `L50_mat` | `33` | 成熟比例为 0.5 的体长。 | Numeric. Length at 50 percent maturity. Default 33. |
| `L95_mat` | `40` | 成熟比例为 0.95 的体长，必须大于 L50_mat。 | Numeric. Length at 95 percent maturity. Default 40. |
| `wgt_a` | `2.2e-06` | 长度重量关系 W=a*L^b 的系数，需匹配单位。 | Numeric. Weight-length parameter a in W = a * L^b. Default 2.2e-6. |
| `wgt_b` | `3.2` | 长度重量关系 W=a*L^b 的指数。 | Numeric. Weight-length parameter b in W = a * L^b. Default 3.2. |
| `mean_F` | `0.3` | 生成 F 轨迹的算术平均值，必须非负，零表示无捕捞。 | Nonnegative arithmetic mean of the generated F trajectory; zero gives zero fishing mortality. |
| `cv_catch` | `0.3` | 简易模拟调查误差的 CV，而非对数 SD。 | Numeric. CV of survey observation noise, not its log-scale SD. Default 0.3. |
| `rec_sigma` | `0.5` | 简易模拟对数补充扰动 SD。 | Numeric. SD of log-recruitment variation. Default 0.5. |
| `seed` | `NULL` | 随机种子；设定后可重复生成。 | Integer or NULL. Random seed for reproducibility. Default NULL (different result each run). Set e.g. seed = 42 for reproducible output. |
| `save_csv` | `FALSE` | TRUE 将生成的三张输入表写为 CSV。 | Logical. Save CSV files to working directory. Default FALSE. |
| `output_dir` | `"."` | 输出目录；必要时自动建立。 | Character. Directory for CSV output. Default ".". |

**返回 / Returns:** 列表包含 data.CatL（调查数量指数）、data.wgt（平均个体重量）、data.mat（成熟比例）三张对齐表，以及 true_params（生成时使用的参数及真值记录）。

A list with three aligned tables: data.CatL (survey numbers or indices), data.wgt (mean individual weights) and data.mat (mature proportions), plus true_params (generating parameters and truth records).

快速年度模拟器的 `mean_F` 等于生成 F 序列的算术平均值；`mean_F = 0` 生成零捕捞死亡率。

完整模拟器的 `nyear`、`burn_in` 都以年为单位，且分别必须对应整数个 `growth_step`。因此季度模式允许半年预热，年度模式不允许。返回的 `sm$nyear` 是保留时间步数；`first.year` 是第一期保留观测的年份，`sm$years` 保存完整观测时间轴。`simulation_to_tables()` 和 `sim_acl()` 保留这条时间轴；完全没有年份元数据的旧文件仍可使用从 2000 开始的后备规则。只保留一期时仍返回矩阵，但拟合至少需要两期。

`sim_acl()` 在发送 socket 任务前求值路径与参数变量，因此一般控制台或脚本中的变量传参也支持多核。保留失败重复并检查逐次拟合诊断；工作进程运行成功并不单独证明评估结果可用。

In the quick annual simulator, `mean_F` is the arithmetic mean of the generated F trajectory; `mean_F = 0` generates zero F.

For the full simulator, `nyear` and `burn_in` are durations in years and must each contain a whole number of `growth_step` intervals. Thus a half-year burn-in is valid with quarterly steps, but not annual steps. Returned `sm$nyear` counts retained steps. `first.year` labels the first retained observation, and `sm$years` records the complete retained calendar. `simulation_to_tables()` and `sim_acl()` preserve this calendar; old files lacking year metadata still have a documented 2000-based fallback. A single retained period stays a matrix, although fitting requires at least two periods.

`sim_acl()` resolves path and parameter variables before sending tasks to socket workers, so ordinary console/script calls work with multiple cores. Retain failed replicates and inspect each fit's diagnostics; successful worker execution alone does not establish a usable assessment.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
simulate_example_data(years = 2000:2019, seed = 42,
                      save_csv = TRUE, output_dir = "quick_simulation")
```

<a id="VB_func"></a>
## `VB_func()`

计算 VB 平均体长 / Calculate VB mean length

```r
VB_func (Linf, k, t0, age)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `Linf` | `必填 / required` | VB 渐近体长，与输入体长单位一致。 | The asymptotic length. |
| `k` | `必填 / required` | VB 生长系数，以年为时间单位。 | The growth coefficient. |
| `t0` | `必填 / required` | VB 理论零体长年龄，单位为年。 | The theoretical age at zero length. |
| `age` | `必填 / required` | 用于计算生长的年龄向量，单位为年。 | Age of the fish. |

**返回 / Returns:** 与 `age` 对应的平均体长数值向量。

A numeric vector of mean lengths, corresponding to `age`.

**示例 / Example:**

```r
# 调用示例；变量按上文创建 / Use objects defined above
VB_func(Linf = 60, k = 0.2, t0 = 1/60, age = 1:15)
```

<a id="estimation_parameters"></a>
## 初值列表内部可以改什么 / Inside estimation parameter lists

`parameters`、`parameters.L`、`parameters.U` 的键名如下。表中变换指从优化参数到自然尺度；初值和界限都要在优化尺度填写。`create_parameters()` 返回的三个命名列表就是传给拟合入口的同名参数。

The keys below apply to starting values and bounds. Transformations map optimizer values to the natural scale; enter starts and bounds on the optimizer scale. The constructor's three named components match the corresponding fit arguments.

| ACL 键名 / Key | ALSCL 键名 / Key | 变换 / Transform | 含义 / Meaning |
|---|---|---|---|
| `log_init_Z` | `log_init_Z` | exp | 初始平衡总死亡率 / Initial equilibrium total mortality |
| `log_std_log_N0` | `log_sigma_log_N0` | exp | 初始年龄尾数偏差 SD / Initial log-number deviation SD |
| `mean_log_R` | `mean_log_R` | exp | 对数补充过程的位置参数 / Location of the log recruitment process |
| `log_std_log_R` | `log_sigma_log_R` | exp | 对数补充过程 SD 缩放 / Log recruitment process SD scale |
| `logit_log_R` | `logit_log_R` | plogis | 补充 AR(1) 相关，限定 (0,1) / Recruitment correlation restricted to (0,1) |
| `mean_log_F` | `mean_log_F` | exp | 对数 F 过程的位置参数 / Location of the log F process |
| `log_std_log_F` | `log_sigma_log_F` | exp | F 偏差 SD 缩放 / F deviation SD scale |
| `logit_log_F_y` | `logit_log_F_y` | plogis | F 的时间相关 / Temporal F correlation |
| `logit_log_F_a` | `logit_log_F_l` | plogis | F 的年龄/体长相关 / Age/length F correlation |
| `log_vbk` | `log_vbk` | exp | VB k，单位为每年 / Annual VB k |
| `log_Linf` | `log_Linf` | exp | 渐近体长 / Asymptotic length |
| `t0` | `log_t0` | ACL 原值；ALSCL exp / Identity vs exp | VB t0；ALSCL 本版限定正值 / ALSCL restricts t0 to positive values |
| `log_cv_len` | `log_cv_len` | exp | 年龄体长 CV / Length-at-age CV |
| — | `log_cv_grow` | exp | 增长增量 CV / Growth-increment CV |
| `log_std_index` | `log_sigma_index` | exp | 对数调查观测 SD / Log survey observation SD |

`exp(mean_log_R)` 和 `exp(mean_log_F)` 是对数位置的指数转换；有随机偏差时不能直接称作无条件算术平均数。两个模板当前都不支持负的 AR(1) 相关。SD 在相关过程中的具体尺度见指南原理部分。

Exponentiating a log location does not give the unconditional arithmetic mean when random deviations are present. Both templates currently restrict AR(1) correlations to positive values. See the theory section for SD conventions in correlated processes.

```r
# 查看某物种的全部初值和上下界 / Inspect all starts and bounds for a preset
p <- create_parameters(model_type = "alscl", species = "flatfish")
keys <- names(p$parameters)
parameter_table <- data.frame(
  Parameter = keys,
  Start = unlist(p$parameters[keys]),
  Lower = unlist(p$parameters.L[keys]),
  Upper = unlist(p$parameters.U[keys]))
parameter_table
# 改一个初值及上界：此处并未自动固定该参数 / Change a start and upper bound
p$parameters$log_sigma_index <- log(0.15)
p$parameters.U$log_sigma_index <- log(0.5)
# 要固定该 SD，还需显式 map；固定值取自 parameters / Explicit map fixes the value
fixed_index <- list(log_sigma_index = factor(NA))
```

拟合会按数据维度建立 `dev_log_R`、`dev_log_F`、`dev_log_N0` 随机效应。它们不是本表的普通标量初值；不要把生成器的 `std_logR`、`F_mean` 等直接作为估计列表键名。

Fits construct random effects `dev_log_R`, `dev_log_F` and `dev_log_N0` from data dimensions. These are not ordinary scalar entries above. Generator names such as `std_logR` and `F_mean` are not estimator keys.


<a id="check_alscl_data"></a>
## `check_alscl_data`

在编译或拟合之前检查完整数据和模型设置。 / Check complete data and model settings before compiling or fitting.

```r
check_alscl_data (x, model = c("acl", "alscl"))
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `x` | `必填 / required` | run_acl() 或 run_alscl() 接受的具名输入列表。 | Named input bundle accepted by run_acl() or run_alscl(). |
| `model` | `c("acl", "alscl")` | 要检查的模型：acl 或 alscl。 | Model to check: acl or alscl. |

**返回 / Returns:** 返回 valid、model、errors、warnings、summary、time 和 length_bins。输入不合法时 valid = FALSE，并给出错误原因。

A list with valid, model, errors, warnings, summary, time and length_bins. Invalid inputs return valid = FALSE with an error message.

与核心拟合共用三表、时间间隔、体长边界、生物学输入、初值、上下界和 map 的准备逻辑，不编译 TMB、不优化。摘要列出正值、零值、缺失值、完全无观测的时段／体长组，以及独立自由固定效应／随机效应数量。警告指出排除的零值、无观测区块，以及正观测数不超过自由固定效应数的情况。这些只是输入检查，不证明可辨识性、收敛或生物学适用性。

Shares the actual fitting preparation for table alignment, time spacing, bins, biology, starts, bounds and maps. Does not compile TMB or optimize. Summary includes positive/zero/missing observations, entirely unobserved periods/bins and independent free fixed/random parameter counts. Warnings identify excluded zeros, unobserved blocks and positive observations no more numerous than free fixed parameters. These are input screens, not evidence of identifiability, convergence or biological adequacy.

**示例 / Example:**

```r
x <- YTF_example
check <- check_alscl_data(x, "alscl")
check$valid
check$summary
check$warnings
# Review check$errors if check$valid is FALSE.
```


<a id="check_fit"></a>
## `check_fit`

用时间–体长热图、按实际时间间隔计算的滞后相关及正态 QQ 图检查条件观测残差。 / Inspect conditional observation residuals with a time–length heatmap, actual-time lag correlations and a normal QQ plot.

```r
check_fit (fit, max_lag = 5)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `fit` | `必填 / required` | ACL 或 ALSCL 拟合结果。保留观测与报告的保存结果无需活跃 TMB 对象即可使用。 | A fitted ACL or ALSCL result. Saved results with observations and reports work without a live TMB object. |
| `max_lag` | `5` | 以模型时间步为单位的最大滞后阶数，须为正整数；季度模型的四步为一年。 | Positive integer maximum lag in model time steps; four steps are one year for quarterly models. |

**返回 / Returns:** 列表包含残差表 residuals、滞后相关表 lag_correlations（体长、滞后、实际时间差、有效配对数、相关系数与状态）、汇总 QQ 数据、三张图 plots$heatmap/lag/qq、time_step 和解释说明。无法计算的相关系数保留为 NA，并给出原因。

A list with residuals, lag_correlations (length, lag, elapsed_time, n_pairs, correlation, status), pooled qq_data, plots$heatmap, plots$lag, plots$qq, time_step and interpretation notes. Unavailable correlations are NA with an explicit status.

residuals(fit, type = "log") 返回观测对数值减去拟合对数值的长表；type = "standardized" 再除以拟合的观测标准差。表中保留原始观测、模型时间与体长坐标，标记被排除的单元，零值或缺失观测的残差为 NA。check_fit() 使用标准化残差。缺失时段不会压缩；相关系数要求在指定实际时间间隔上至少有三对有限观测，且两侧均非常数。这些残差以拟合的潜在效应为条件：标准化不代表残差独立、检验已校准或模型适合度已得到证明。绘图遵循包的无网格主题。

residuals(fit, type = "log") returns a long table of observed minus fitted log index; type = "standardized" divides by the fitted observation SD. It retains original observations, model times and length coordinates, marks excluded cells, and assigns NA residuals to zero/missing observations. check_fit() uses standardized residuals. Gaps are never compressed; correlations require at least three finite paired values at the requested actual lag and nonconstant values on both sides. These residuals condition on fitted latent effects: standardization is not a guarantee of independence, calibrated tests or model adequacy. Plots follow the package's grid-free theme.

**示例 / Example:**

```r
checks <- check_fit(b, max_lag = 4)
head(residuals(b, type = "standardized"))
checks$lag_correlations
checks$plots$heatmap
checks$plots$lag
checks$plots$qq
```

![示例图 / Example figure: `check_fit(b, max_lag = 4)$plots$heatmap`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/workflows/residual-heatmap.png?raw=true&v=2dbeb4799a6c)


<a id="extract_estimates"></a>
## `extract_estimates`

统一提取带坐标的种群估计 / Extract population estimates with coordinates

```r
extract_estimates (fit, quantities = c("SSB", "Rec", "B", "N", "CN", "F"), conf_level = 0.95)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `fit` | `必填 / required` | ACL 或 ALSCL 拟合结果；保存的可移植结果也可使用。 | An ACL or ALSCL fit, including a portable saved result. |
| `quantities` | `c("SSB", "Rec", "B", "N", "CN", "F")` | SSB、Rec、B、N、CN、CB、F 及模型实际报告的年龄、体长或联合数组。 | Reported population vectors and age, length or joint arrays; F resolves to ACL F or ALSCL FL. |
| `conf_level` | `0.95` | 近似区间的名义置信水平，严格介于 0 与 1。 | Nominal confidence level of the approximate intervals, strictly between zero and one. |

**返回 / Returns:** 含量名、实际报告名、年份、年龄、体长、估计、SE、区间及 numerical_ok 的长表。

A long table containing quantity, report name, time, age, length, estimate, SE, interval and numerical_ok.

估计来自 report，SE 只按完整、精确同名的 est_std 行提取。未报告 SE 时保留 NA，不造出区间。F 保留原分组和每模型步单位，不自动求平均或年化。FA 使用存活区间的起始年龄和时期；正态区间不截零。

Estimates use report and complete exact-name SE rows from est_std. Missing uncertainty remains NA. F retains native groups and per-step units without averaging or annualization. FA uses source ages and periods. Normal intervals are not truncated at zero.

**示例 / Example:**

```r
est <- extract_estimates(b, quantities = c("SSB", "Rec", "F"))
head(est)
```


<a id="extract_parameters"></a>
## `extract_parameters`

提取参数、尺度与固定状态 / Extract parameters, scales and estimation status

```r
extract_parameters (fit, scale = c("natural", "internal"), conf_level = 0.95)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `fit` | `必填 / required` | ACL 或 ALSCL 拟合结果；保存的可移植结果也可使用。 | An ACL or ALSCL fit, including a portable saved result. |
| `scale` | `c("natural", "internal")` | 自然尺度或优化器内部尺度。 | Natural or internal optimizer scale. |
| `conf_level` | `0.95` | 近似区间的名义置信水平，严格介于 0 与 1。 | Nominal confidence level of the approximate intervals, strictly between zero and one. |

**返回 / Returns:** 参数表，包括估计、SE、区间、固定／估计／停用状态及数值检查标记。

A parameter table with estimates, SEs, intervals, fixed/estimated/inactive status and the numerical-screen flag.

有完整配方时包括固定参数；其 SE 和区间为 NA。旧对象仅能可靠列出自由固定效应。自然尺度 SE 用 delta method，区间转换内部尺度 Wald 端点；exp(mean_log_F) 和 exp(mean_log_R) 是过程基准水平，不是时间算术平均。检查 numerical_ok 后再解释不确定性。

With a recipe, fixed parameters are included with NA uncertainty. Legacy objects expose only free fixed effects. Natural-scale SEs use the delta method; intervals transform internal Wald endpoints. exp(mean_log_F) and exp(mean_log_R) are a process baseline, not a time average. Inspect numerical_ok before interpreting uncertainty.

**示例 / Example:**

```r
extract_parameters(a)
extract_parameters(b, scale = "internal")
```


<a id="fit_scenarios"></a>
## `fit_scenarios`

在同一观测数据上串行或 socket 并行拟合具名敏感性情景。 / Fit named sensitivity scenarios on common observations with serial or socket execution.

```r
fit_scenarios (x, scenarios, model = c("acl", "alscl"), ncores = 1, F_summary = c("mean",
    "apical"), ...)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `x` | `必填 / required` | run_acl() 或 run_alscl() 接受的输入集合。 | An input bundle accepted by run_acl() or run_alscl(). |
| `scenarios` | `必填 / required` | 非空具名列表，每项为拟合参数覆盖列表。空列表代表参照情景，不允许修改数据表。 | A nonempty named list of named fitting-argument overrides. An empty list is the reference scenario; data tables cannot be changed. |
| `model` | `c("acl", "alscl")` | "acl"（默认）或 "alscl"。 | "acl" (default) or "alscl". |
| `ncores` | `1` | 不同情景的最大工作进程数；内部拟合和标准误使用一个进程。 | Maximum independent scenario workers; inner fitting and standard errors use one worker. |
| `F_summary` | `c("mean", "apical")` | "mean" 为组间非加权均值，"apical" 为最大值；F 保持每模型时间步单位。 | "mean" for the unweighted group mean, or "apical" for the maximum. F remains per model step. |
| `...` | 可选 / optional | 各情景之前应用的 run_* 共用覆盖。parameters/map/control 均为整份列表替换。 | Common run_* overrides, applied before each scenario. Complete parameter/map/control lists replace their predecessors. |

**返回 / Returns:** 返回具名拟合/错误记录、完整设置、状态、耗时、估计长表、模型、F 汇总方式和工作进程数。

A list with named fits/error records, resolved settings, status, elapsed, estimates, model, F_summary and workers.

保留警告和未通过数值筛查的结果，不自动排名。串行和并行保留相同初始点数量。结果移除会话专用 obj 指针，需要可执行目标函数时使用 refit_model()；本接口不实现断点续跑。

Warnings and failed numerical screens remain visible, with no automatic ranking. Each scenario uses the nstarts of the bundle or of the call; otherwise one start, the rule of hindcast_model() and retro_model(). Fits omit session-specific obj pointers; refit_model() can rebuild a live objective. This interface does not implement checkpoint/resume.

**示例 / Example:**

```r
x <- YTF_example
z <- fit_scenarios(x, list(reference = list(), low_M = list(M = 0.15),
  common_F = list(F_structure = "year")), model = "alscl", ncores = 2,
  F_summary = "mean", silent = TRUE)
z$status
z$estimates
```

![示例图 / Example figure: `fit_scenarios(x, list(reference = list(), low_M = list(M = 0.15), high_M = list(M = 0.25)), model = "acl")`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/workflows/scenario-SSB.png?raw=true&v=7ee6fd0e12d8)


<a id="inspect_parameters"></a>
## `inspect_parameters`

查看实际初值、上下界，以及自由、固定或共享的参数状态。 / Inspect effective parameter starts, bounds and free/fixed/tied restrictions.

```r
inspect_parameters (x, model = c("acl", "alscl"))
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `x` | `必填 / required` | 拟合函数接受的具名输入列表。 | Named input bundle accepted by the fitting functions. |
| `model` | `c("acl", "alscl")` | 要检查的模型：acl 或 alscl。 | Model to inspect: acl or alscl. |

**返回 / Returns:** 包含 parameter、kind、start、natural_start、lower、upper、transform、status、map_source、size、dimensions、n_free、n_fixed、n_tied 的数据框。

A data frame with parameter, kind, start, natural_start, lower, upper, transform, status, map_source, size, dimensions, n_free, n_fixed and n_tied.

使用真实的数据初值、按上下界截断的自由初值、补充年龄约束、默认 map 和共享 F 约束。kind=fixed_effect 指外层模型参数，并不表示该参数被 map 固定。status 可为 free、fixed、tied、mixed 或 inactive；map_source 区分 default、explicit、unmapped 和 F_structure。随机效应块初值为零，n_free 为独立映射值数量，n_tied 为共享这些值的额外元素数量。exp(mean_log_R) 和 exp(mean_log_F) 是自然尺度上的过程基准水平，不是算术平均值；随机效应的 natural_start 是乘数。全程无需编译。

Uses actual data-derived starts, clamped free starts, recruitment-age bounds, default maps and shared-F restrictions. kind=fixed_effect means an outer-model parameter, not necessarily a parameter fixed by map. Status can be free, fixed, tied, mixed or inactive. map_source distinguishes default, explicit, unmapped and F_structure. Random blocks start at zero; n_free counts independent mapped values and n_tied counts additional entries sharing them. exp(mean_log_R) and exp(mean_log_F) are baseline process levels on the natural scale, not arithmetic means; random natural_start is a multiplier. No compilation is performed.

**示例 / Example:**

```r
x <- YTF_example
parameters <- inspect_parameters(x, "acl")
parameters[, c("parameter", "status", "map_source", "start", "natural_start")]
x$fit_config$alscl$F_structure <- "year"
inspect_parameters(x, "alscl")[, c("parameter", "status", "dimensions", "n_free")]
```


<a id="prepare_alscl_data"></a>
## `prepare_alscl_data`

把三张数据表、三个 CSV 文件或 Excel 工作簿整理为可直接拟合的输入列表。 / Prepare a reusable input bundle from tables, three CSV files or an Excel workbook.

```r
prepare_alscl_data (data.CatL = NULL, data.wgt = NULL, data.mat = NULL, file = NULL, format = c("tables",
    "csv", "excel"), fit_args = list(), fit_config = NULL)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `data.CatL` | `NULL` | 调查数据表，或包含三张表的具名列表。 | Survey table, or a named list containing all three tables. |
| `data.wgt` | `NULL` | 与调查数据对齐的体长组体重表。 | Weight-at-length table aligned with the survey table. |
| `data.mat` | `NULL` | 与调查数据对齐的体长组成熟比例表。 | Maturity-at-length table aligned with the survey table. |
| `file` | `NULL` | CSV 文件目录或 Excel 工作簿路径。 | Directory for CSV input or workbook path for Excel input. |
| `format` | `c("tables", "csv", "excel")` | 输入格式：tables、csv 或 excel。 | Input format: tables, csv or excel. |
| `fit_args` | `list()` | 共享的生物学输入和拟合设置；三张表单独提供。 | Named list of shared biological and fitting settings. Keep the three tables outside this list. |
| `fit_config` | `NULL` | 可选的 acl 和／或 alscl 模型专属设置列表。 | Optional acl and/or alscl lists of model-specific settings. |

**返回 / Returns:** 包含 data.CatL、data.wgt、data.mat、fit_args 以及可选 fit_config 的结构化列表。

A structured list containing data.CatL, data.wgt, data.mat, fit_args and optional fit_config.

安全转换数字文本，并检查三表的数值和排列是否一致；不填补或重排缺失时段，也不推测生物学参数。在 fit_args 中提供 rec.age、nage、M、sel_L50、sel_L95，再运行 check_alscl_data(x, model)。优先级为共享 fit_args、选中的 fit_config、显式运行参数；列表参数整体替换，具名 NULL 的 map 释放规则保留。零值在导入后仍为零，由拟合的 zero_action 决定排除或拒绝。

This constructor converts numeric text safely and checks table values and alignment. It never fills or reorders missing periods and does not infer biology. Supply rec.age, nage, M, sel_L50 and sel_L95 in fit_args, then run check_alscl_data(x, model). Settings follow shared fit_args, selected fit_config, then explicit run arguments; list-valued settings replace the entire corresponding list. Named NULL map releases remain intact. Zeros remain zeros until the fitting zero_action excludes or rejects them.

**示例 / Example:**

```r
tables <- YTF_example[c("data.CatL", "data.wgt", "data.mat")]
x <- prepare_alscl_data(tables, fit_args = YTF_example$fit_args,
                        fit_config = YTF_example$fit_config)
check_alscl_data(x, "acl")$valid
inspect_parameters(x, "alscl")
```


<a id="profile_model"></a>
## `profile_model`

逐网格固定一个自由标量参数，重新优化其余参数及随机效应。 / Fix a free scalar at each grid value and reoptimize the remaining parameters and random effects.

```r
profile_model (fit, parameter, values, scale = c("natural", "internal"), ncores = 1)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `fit` | `必填 / required` | 保留完整 recipe、最终优化参数和边界的拟合结果。 | A fit retaining its complete recipe, final optimizer estimates and bounds. |
| `parameter` | `必填 / required` | names(fit$opt$par) 中的内部标量名称，如 "log_Linf"；不支持固定参数及外部 M/q。 | One internal scalar name in names(fit$opt$par), such as "log_Linf"; fixed parameters and external M/q are excluded. |
| `values` | `必填 / required` | 原优化边界内互不重复的有限网格值。 | Distinct finite grid values inside the original optimizer bounds. |
| `scale` | `c("natural", "internal")` | "natural"（默认）对 log_*/mean_log_* 使用 exp、logit_* 使用 plogis、t0 使用恒等变换；"internal" 使用优化坐标。参数名始终为内部名称。 | "natural" (default) transforms values using exp for log_*/mean_log_*, plogis for logit_* and identity for t0; "internal" uses optimizer coordinates. Parameter names remain internal. |
| `ncores` | `1` | 最大独立 socket 工作进程数；内部拟合及标准误使用一个进程。 | Maximum independent socket workers; inner fits and standard errors use one worker. |

**返回 / Returns:** 返回网格诊断、目标函数及 delta_nll、可移植拟合、完整设置、参照目标值和耗时。

A list containing grid diagnostics, objectives and delta_nll, portable fits, resolved settings, reference objective and timing.

其余自由标量初值取自拟合最优点，保留固定值和具名 NULL 释放。必须至少保留一个其他自由标量。delta_nll 相对于原拟合，可为负值并提示重查最优点。保留失败点，不自动生成置信区间或卡方阈值；外部假设使用 fit_scenarios()。

Other free scalar starts come from the fitted optimum; fixed values and named NULL releases are preserved. At least one other free scalar must remain. delta_nll is relative to the original fit and can be negative, prompting rechecking of that optimum. Failed points remain visible. No automatic confidence intervals or chi-square cutoffs are provided. External assumptions use fit_scenarios().

**示例 / Example:**

```r
x <- YTF_example
a <- run_acl(x, silent = TRUE)
values <- exp(a$opt$par[["mean_log_F"]]) * c(0.9, 1, 1.1)
p <- profile_model(a, "mean_log_F", values, scale = "natural", ncores = 2)
p$grid
```

![示例图 / Example figure: `profile_model(a, "mean_log_F", values = grid, scale = "natural")`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/workflows/profile-F.png?raw=true&v=cc2a75644194)


<a id="project_model"></a>
## `project_model`

从 ACL 或 ALSCL 拟合末期状态开始，按明确给定的假设推演确定性种群情景。 / Project explicit deterministic population scenarios from the terminal fitted ACL or ALSCL state.

```r
project_model (fit, F, recruitment, weight, maturity, M = NULL, allow_failed_fit = FALSE)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `fit` | `必填 / required` | 保留末期种群数组、年龄/体长/时间坐标的 ACL 或 ALSCL 结果；建议同时保留可移植拟合配方。 | An ACL or ALSCL result retaining terminal population arrays, age/length/time metadata and preferably its portable fit recipe. |
| `F` | `必填 / required` | 每模型时间步的非负瞬时捕捞死亡率：每个未来时段一个值并供所有组共用，或组×未来时段矩阵（ACL 为年龄组，ALSCL 为体长组）。 | Nonnegative instantaneous fishing mortality per model time step: one value per future period shared across groups, or a group-by-period matrix (age for ACL, length for ALSCL). |
| `recruitment` | `必填 / required` | 每个未来时段的有限非负补充数量；向量长度确定推演时段数。 | Finite nonnegative recruitment numbers, one per future period; vector length determines the horizon. |
| `weight` | `必填 / required` | 完整的非负体长×未来时段个体体重矩阵。可选行名须与拟合体长顺序一致，列名须等于未来时间。 | Complete nonnegative length-by-future-period weight matrix. Optional row labels must match fitted length order; column labels must equal future times. |
| `maturity` | `必填 / required` | 完整的体长×未来时段成熟比例矩阵，数值在 [0,1] 内；函数不会隐式延用或循环填充。 | Complete length-by-future-period maturity matrix with values in [0, 1]. No implicit carry-forward or recycling. |
| `M` | `NULL` | 未来每模型时间步的自然死亡率，可为标量或每个未来时段一个值。NULL 使用拟合配方中的原始 M。旧结果须明确提供 M，首值同时用于末期拟合时段的存活计算。 | Future natural mortality per model step, scalar or one value per future period. NULL uses original M from the fit recipe. Legacy fits require explicit M; its first value is also used for the terminal interval. |
| `allow_failed_fit` | `FALSE` | 明确未通过数值检查时默认拒绝投影；TRUE 在警告后允许探索性投影，并记录覆盖。缺诊断的旧结果记为 unknown。 | Reject known numerical-screen failures by default; TRUE permits exploratory projection with a warning and records the override. Legacy missing status remains unknown. |

**返回 / Returns:** summary 包含时间、总数量 N、生物量 B、SSB、补充量 Rec、捕捞数量 CN、捕捞生物量 CB、F_mean 和 F_apical；trajectories 和 fishing_mortality 为长表。states 保存 NA、NL 及 ALSCL 的 NLA；catch 保存 CNA 和 CNL。结果同时保留未来生物资料、F、时间轴及假设。CN 为数量，CB 的单位由个体体重单位决定。

summary contains year, N, B, SSB, Rec, CN, CB, F_mean and F_apical. trajectories and fishing_mortality are long tables. states contains NA, NL and ALSCL NLA; catch contains CNA and CNL. Supplied biology, F, time grid and assumptions are retained. CN is numbers; CB uses the supplied individual-weight units.

种群状态、B 和 SSB 对应每个未来时段开始时。第一期未来状态先让拟合末期种群经历末期拟合 F 和原始 M 的死亡，再加入第一期未来补充量。未来 F[t]/M[t] 决定该期捕捞以及进入 t+1 的存活，因此仅改变一期 F 会改变当期捕捞，而不会改变期初 SSB。ACL 推进年龄组和末龄加组，并使用拟合的年龄–体长键；ALSCL 先按体长存活，再通过拟合的生长矩阵。ACL 的捕捞生物量由年龄捕捞量经该键转换得到。F_mean 是组间未加权平均值，F_apical 是组间最大值，均不把季度死亡率换算成年率。这是固定生长、明确补充量与未来生物资料的确定性条件情景，没有不确定性区间、没有估计的亲体量–补充量关系，也不自动计算 MSY/TAC。

Population states, B and SSB are at the start of each future period. The first future state survives the terminal fitted population through terminal fitted F and original M, then receives the first future recruitment. Future F[t]/M[t] determine catch[t] and survival into t+1, so a one-period F change affects catch but not start-of-period SSB. ACL advances ages and the plus group through its fitted age-length key; ALSCL applies length-specific survival before its fitted growth matrix. ACL catch biomass is derived by mapping catch-at-age through the fitted key. F_mean is an unweighted group mean and F_apical a group maximum; neither annualizes quarterly rates. These are deterministic conditional scenarios with fixed growth, explicit recruitment and future biology, no uncertainty intervals, no estimated stock-recruitment relationship and no automatic MSY/TAC calculation.

明确未通过数值检查的拟合默认拒绝投影。allow_failed_fit = TRUE 可在警告后进行探索性投影；旧结果缺少诊断时记为 unknown，不视为通过。assumptions 保存状态及是否覆盖。

Fits explicitly failing the numerical screen are rejected by default. allow_failed_fit = TRUE permits exploratory projection with a warning. Missing legacy diagnostics are recorded as unknown, not passed; assumptions retain the status and override.

**示例 / Example:**

```r
# Explicit illustrative assumption: retain last observed biology.
h <- 4L
w <- as.matrix(x$data.wgt[-1L])
mat <- as.matrix(x$data.mat[-1L])
future_w <- matrix(w[, ncol(w)], nrow(w), h)
future_mat <- matrix(mat[, ncol(mat)], nrow(mat), h)
scenario <- project_model(b, F = rep(0.15, h),
  recruitment = rep(tail(b$report$Rec, 1), h),
  weight = future_w, maturity = future_mat)
scenario$summary
# F is per model step; supplied recruitment and biology are assumptions.
```

![示例图 / Example figure: `project_model(a, F = F_future, recruitment = R_future, weight = w, maturity = m)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/workflows/projection-SSB.png?raw=true&v=a1acd1f6ce98)


<a id="read_assessment"></a>
## `read_assessment`

读取可移植评估存档 / Read a portable assessment archive

```r
read_assessment (file)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `file` | `必填 / required` | save_assessment() 创建的可信 RDS 文件。 | A trusted RDS archive created by save_assessment(). |

**返回 / Returns:** 带完整配方和估计结果的 alscl_fit 对象；没有活跃 obj。

An alscl_fit with its complete recipe and estimates, without a live obj.

校验存档格式和 schema。读取后可使用 summary、提取函数和基于报告的绘图；需要活跃模型时重新拟合。

Validates the archive format and schema. Summaries, extractors and report-based plots work after reading; refit to obtain a live model.

**示例 / Example:**

```r
path <- tempfile(fileext = ".rds")
save_assessment(a, path)
saved <- read_assessment(path)
plot_SSB(saved)
```


<a id="read_survey_csv"></a>
## `read_survey_csv`

从三个 CSV 文件读取对齐的调查、体重和成熟比例数据表。 / Read aligned survey, weight and maturity tables from three CSV files.

```r
read_survey_csv (folder)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `folder` | `必填 / required` | 包含 data.CatL.csv、data.wgt.csv 和 data.mat.csv 的目录。 | Directory containing data.CatL.csv, data.wgt.csv and data.mat.csv. |

**返回 / Returns:** 包含三张数值数据表的具名列表，可交给 prepare_alscl_data()。

A named list containing the three numeric data tables, ready for prepare_alscl_data().

第一列为体长组标签，后续表头为数值时间标签。空白单元格和 NA 表示缺失；数字文本按显示值转换，不使用因子内部编码。保留原始行列顺序。体重和成熟比例必须完整，调查数据的零值和缺失值保留，不推测生物学输入。

The first column contains length-bin labels and subsequent headers contain numeric time labels. Blank cells and NA represent missing values. Numeric text is converted without using factor level codes. Rows and columns retain their original order. Weight and maturity tables must be complete; survey zeros and missing values remain explicit. Biological inputs are not inferred.

**示例 / Example:**

```r
folder <- tempfile("survey-csv-")
dir.create(folder)
for (nm in c("data.CatL", "data.wgt", "data.mat")) {
  write.csv(YTF_example[[nm]], file.path(folder, paste0(nm, ".csv")),
            row.names = FALSE)
}
tables <- read_survey_csv(folder)
x <- prepare_alscl_data(tables, fit_args = YTF_example$fit_args,
                        fit_config = YTF_example$fit_config)
check_alscl_data(x, "acl")$summary
```


<a id="read_survey_excel"></a>
## `read_survey_excel`

读取 Excel 工作簿中的调查、体重和成熟比例工作表。 / Read survey, weight and maturity sheets from an Excel workbook.

```r
read_survey_excel (file)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `file` | `必填 / required` | 包含 data.CatL、data.wgt、data.mat 三张工作表的 Excel 文件路径。 | Path to an existing workbook with sheets data.CatL, data.wgt and data.mat. |

**返回 / Returns:** 包含三张数值数据表的具名列表。

A named list containing the three numeric data tables.

需要可选的 readxl 包。工作表名称必须完全一致。第一列为体长组标签，后续表头为数值时间标签。使用与 read_survey_csv() 相同的数值和对齐检查；保留调查零值和缺失值，不推测生物学输入或填补时段。

Requires the optional readxl package. Sheet names must match exactly. The first column is the length-bin label; remaining headers are numeric time labels. The reader applies the same value and alignment checks as read_survey_csv(), preserves zero and missing survey cells, and does not infer biology or fill missing periods.

**示例 / Example:**

```r
# Optional dependency: install.packages("readxl")
# Replace this path with your workbook.
if (file.exists("survey.xlsx")) {
  tables <- read_survey_excel("survey.xlsx")
  # Supply biology for your own stock in fit_args before fitting.
  names(tables)
}
```


<a id="refit_model"></a>
## `refit_model`

按保存配方重新拟合 / Refit a stored assessment recipe

```r
refit_model (fit, ...)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `fit` | `必填 / required` | ACL 或 ALSCL 拟合结果；保存的可移植结果也可使用。 | An ACL or ALSCL fit, including a portable saved result. |
| `...` | 可选 / optional | 具名 run_* 覆盖参数；列表整项替换，具名 NULL 保留。 | Named run_* overrides; lists replace whole entries and named NULL is retained. |

**返回 / Returns:** 新的拟合结果、更新后的配方和当前会话活跃 TMB 对象。

A fresh fit with an updated recipe and live TMB object.

默认复用原始初值、完整输入与记录的 AD／标准误设置；完成后恢复调用者速度选项。除非显式 output=TRUE，否则不写绘图文件。更换软件版本不保证逐位一致。

Reuses original starts, complete inputs and recorded AD/SE settings, restoring caller options afterward. File output is disabled unless output=TRUE is explicit. Bitwise identity across software versions is not guaranteed.

`recipe$implementation` 保存可取得的提交号、核心与 R 源码摘要、运行环境。旧存档及来源未知的旧拟合保持可读；重新拟合会提示已知实现或依赖变化。

`recipe$implementation` stores available revision, core/R source hashes and runtime metadata. Legacy archives remain readable; refitting warns about known implementation or dependency changes. A source HEAD does not establish that the working tree was clean.

**示例 / Example:**

```r
updated <- refit_model(a, M = 0.25, silent = TRUE)
summary(updated)
```


<a id="save_assessment"></a>
## `save_assessment`

保存完整可移植评估 / Save a portable assessment

```r
save_assessment (fit, file, x = NULL, overwrite = FALSE)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `fit` | `必填 / required` | ACL 或 ALSCL 拟合结果；保存的可移植结果也可使用。 | An ACL or ALSCL fit, including a portable saved result. |
| `file` | `必填 / required` | 目标 RDS 路径，父目录必须已存在。 | Destination RDS path with an existing parent directory. |
| `x` | `NULL` | 仅给没有配方的旧拟合提供完整输入；原始生物学和设置仍标记为未核实。 | Optional complete input bundle only for a legacy fit without a recipe; original biology and settings remain unverified. |
| `overwrite` | `FALSE` | 是否替换已有文件，默认不覆盖。 | Whether to replace an existing file; FALSE by default. |

**返回 / Returns:** 不可见地返回文件路径；不修改原拟合。

Invisibly returns the file path without changing the original fit.

存档剔除会话专属 obj 指针，保存配方、输入、map、边界、设置、版本和报告。失败时保留原存档。配方不等于可跨会话执行的 TMB 指针；重建需要 refit_model()。

The archive omits the session-specific obj pointer and retains inputs, maps, bounds, settings, versions and reports. Failed replacement preserves the old archive. Use refit_model() to rebuild a live TMB model.

`recipe$implementation` 保存可取得的提交号、核心与 R 源码摘要、运行环境。旧存档及来源未知的旧拟合保持可读；重新拟合会提示已知实现或依赖变化。

`recipe$implementation` stores available revision, core/R source hashes and runtime metadata. Legacy archives remain readable; refitting warns about known implementation or dependency changes. A source HEAD does not establish that the working tree was clean.

**示例 / Example:**

```r
path <- tempfile(fileext = ".rds")
save_assessment(b, path)
saved <- read_assessment(path)
summary(saved)
```


<a id="sim_alscl"></a>
## `sim_alscl`

使用 ALSCL 拟合模拟批次的便捷入口。 / Convenience interface for simulation batches fitted with ALSCL.

```r
sim_alscl (..., nstarts = 1)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `...` | 可选 / optional | 传入 sim_model() 的参数（model 和 nstarts 除外）；参数名和 map 必须对应 ALSCL。 | Arguments passed to sim_model(), excluding model and nstarts; use ALSCL parameter names and maps. |
| `nstarts` | `1` | 每个模拟重复的独立初值数，在重复内部依次运行；ncores 仍控制外层并行重复数。 | Independent starts per replicate, run sequentially; ncores still controls outer replicate workers. |

**返回 / Returns:** 返回包含 iter 和 elapsed 的具名拟合或错误记录列表；每个结果同时替换对应 `result_rep_<id>` 文件。

A named list of replicate fits or error records, including iter and elapsed. Every result also replaces its `result_rep_<id>` file.

保留模拟文件中的时间和体长坐标。每次拟合内部使用一个进程及顺序标准误。失败重跑会替换旧成功文件。M、F 均为每模型时间步单位。这是操作模型模拟数据拟合，不自动构成拟合模型参数自助法。

Recorded time and length coordinates are retained. Each replicate uses one inner fitting worker and sequential standard errors. Failed reruns replace old success files. M and F are per model step. This fits operating-model simulations; it does not automatically create a fitted parametric bootstrap.

`start_diagnostics` 保留每个初值的结果、进程与耗时。 / `start_diagnostics` retains the result, process and timing of every start.

**示例 / Example:**

```r
x <- YTF_example
pa <- x$parameters
bio <- sim_cal(pa)
folder <- tempfile("alscl-sim-")
sm <- sim_data(bio, pa, iter_range = 1:2, return_iter = 1, output_dir = folder)
cfg <- x$fit_config$alscl
fits <- sim_alscl(1:2, folder, file.path(folder, "fits_alscl"),
  parameters = cfg$parameters, map = cfg$map, M = pa$M, ncores = 2, nstarts = 3)
lapply(fits, function(fit) fit$diagnostics)
```


<a id="sim_model"></a>
## `sim_model`

使用统一批次流程，把 ACL 或 ALSCL 拟合到已保存的模拟重复数据。 / Fit ACL or ALSCL to saved simulation replicates using the same batch pipeline.

```r
sim_model (iter_range = 4:100, sim_data_path = ".", output_dir = ".", parameters = NULL,
    parameters.L = NULL, parameters.U = NULL, map = NULL, M = 0.2, ncores = 1, train_times = 1,
    control = list(), F_structure = c("group_year", "year"), polish = TRUE, model = c("acl",
        "alscl"), nstarts = 1)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `iter_range` | `4:100` | 与 `sim_rep<id>` 文件名对应的互不重复正整数编号。 | Distinct positive integer replicate IDs matching `sim_rep<id>` filenames. |
| `sim_data_path` | `"."` | 存放 sim_data() 模拟文件的目录。 | Folder containing simulation files produced by sim_data(). |
| `output_dir` | `"."` | 保存 `result_rep_<id>` 的目录；ACL 和 ALSCL 应使用不同目录。 | Directory for `result_rep_<id>` files; use different directories for ACL and ALSCL. |
| `parameters` | `NULL` | 可选、对应模型的标量参数初值。 | Optional model-specific scalar initial values. |
| `parameters.L` | `NULL` | 可选、对应模型的具名下界。 | Optional named lower bounds, matching the selected model. |
| `parameters.U` | `NULL` | 可选、对应模型的具名上界。 | Optional named upper bounds, matching the selected model. |
| `map` | `NULL` | 对应模型的参数映射；保留具名 NULL 释放。 | Model-specific parameter mappings; named NULL releases are preserved. |
| `M` | `0.2` | 每模型时间步的自然死亡率，默认 0.2。 | Natural mortality per model time step; default 0.2. |
| `ncores` | `1` | 独立模拟重复的最大 socket 工作进程数。 | Maximum independent replicate socket workers. |
| `train_times` | `1` | 每个初值的优化轮数。 | Optimization passes per start. |
| `control` | `list()` | 具名 nlminb 优化控制。 | Named nlminb optimizer controls. |
| `F_structure` | `c("group_year", "year")` | "group_year"（默认）或 "year"，后者在每个模型时间步共用一个 F。 | "group_year" (default), or one F shared across groups per model step with "year". |
| `polish` | `TRUE` | 是否应用有保护的优化收尾，默认 TRUE。 | Apply safeguarded optimization refinement; default TRUE. |
| `model` | `c("acl", "alscl")` | "acl"（默认）或 "alscl"。 | "acl" (default) or "alscl". |
| `nstarts` | `1` | 每个模拟重复的独立初值数，在重复内部依次运行；ncores 仍控制外层并行重复数。 | Independent starts per replicate, run sequentially; ncores still controls outer replicate workers. |

**返回 / Returns:** 返回包含 iter 和 elapsed 的具名拟合或错误记录列表；每个结果同时替换对应 `result_rep_<id>` 文件。

A named list of replicate fits or error records, including iter and elapsed. Every result also replaces its `result_rep_<id>` file.

保留模拟文件中的时间和体长坐标。每次拟合内部使用一个进程及顺序标准误。失败重跑会替换旧成功文件。M、F 均为每模型时间步单位。这是操作模型模拟数据拟合，不自动构成拟合模型参数自助法。

Recorded time and length coordinates are retained. Each replicate uses one inner fitting worker and sequential standard errors. Failed reruns replace old success files. M and F are per model step. This fits operating-model simulations; it does not automatically create a fitted parametric bootstrap.

`start_diagnostics` 保留每个初值的结果、进程与耗时。 / `start_diagnostics` retains the result, process and timing of every start.

**示例 / Example:**

```r
x <- YTF_example
pa <- x$parameters
bio <- sim_cal(pa)
folder <- tempfile("alscl-sim-")
sm <- sim_data(bio, pa, iter_range = 1:2, return_iter = 1, output_dir = folder)
cfg <- x$fit_config$alscl
fits <- sim_model(1:2, folder, file.path(folder, "fits_alscl"),
  parameters = cfg$parameters, map = cfg$map, M = pa$M, model = "alscl", ncores = 2, nstarts = 3)
lapply(fits, function(fit) fit$diagnostics)
```


<a id="summarize_simulations"></a>
## `summarize_simulations`

使用明确分母汇总模拟偏差、RMSE、区间覆盖率、拟合失败与耗时。 / Summarize simulation bias, RMSE, interval coverage, fitting failures and timing with explicit denominators.

```r
summarize_simulations (fits, truth, quantities = c("SSB", "Rec"), conf_level = 0.95)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `fits` | `必填 / required` | 具名拟合或错误记录列表，如 sim_model() 输出。 | A named list of fits or error records, such as sim_model() output. |
| `truth` | `必填 / required` | 与 fits 同名的逐重复列表；每项包含 year 及所选量的真值向量，坐标必须匹配。 | A same-named per-replicate list; each entry contains year and vectors for all requested quantities. Coordinates must match exactly. |
| `quantities` | `c("SSB", "Rec")` | SSB、Rec、B、N、CN、CB 中互不重复的总体时序，默认 SSB 和 Rec。 | Distinct aggregate time series from SSB, Rec, B, N, CN, CB; default SSB and Rec. |
| `conf_level` | `0.95` | 基于报告标准误构造正态区间的名义置信水平；实际覆盖率另行计算。 | Nominal confidence level used to construct normal intervals from reported SEs; empirical coverage is calculated separately. |

**返回 / Returns:** 返回按量跨重复/时间合并的 summary、逐重复状态/耗时，以及保留失败点的逐点估计和真值。

A list with summary pooled over replicates/time by quantity, per-replicate status/timing and all pointwise estimates/truth, including failures.

偏差和 RMSE 使用数值有效估计对，覆盖率额外要求有限的报告标准误。报告尝试/有效重复、点及区间数和 failure_rate。缺失标准误不算覆盖失败。相对偏差排除真值为零的点。F 因需要明确定义聚合和不确定性而排除。这些条件性能统计不证明模型普遍更优。

Bias/RMSE use numerically valid estimate pairs; coverage additionally requires finite reported SEs. Attempted/valid replicate, point and interval counts and failure_rate are reported. Missing SEs are not counted as failed coverage. Relative bias excludes zero truth. F is excluded because its aggregation and uncertainty must be explicitly defined. These conditional performance summaries are not proof of general model superiority.

**示例 / Example:**

```r
x <- YTF_example
a <- run_acl(x, silent = TRUE)
fits <- list(example = a)
truth <- list(example = list(year = as.numeric(names(x$data.CatL)[-1]),
  SSB = x$truth$SSB, Rec = x$truth$Rec))
performance <- summarize_simulations(fits, truth)
performance$summary
performance$replicates
```


<a id="simulate_fit"></a>
## `simulate_fit`

给定拟合种群状态，或重新抽取其过程偏差后，模拟调查观测。 / Simulate survey observations conditionally on a fitted population or after resampling its process deviations.

```r
simulate_fit (fit, nsim = 1, seed = NULL, process = c("conditional", "resample"), preserve_missing = TRUE,
    allow_failed_fit = FALSE)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English |
|---|---|---|---|
| `fit` | `必填 / required` | 带完整配方及报告的 ACL／ALSCL 拟合，可为可移植存档读取结果。 | ACL/ALSCL fit with a complete recipe and report, including a portable saved fit. |
| `nsim` | `1` | 正整数模拟重复数。 | Positive integer number of replicate datasets. |
| `seed` | `NULL` | 可选非负整数种子；显式种子恢复调用者随机数状态，NULL 消耗当前随机流。 | Optional nonnegative integer seed; explicit seeds restore caller RNG state, NULL consumes the current stream. |
| `process` | `c("conditional", "resample")` | conditional 固定状态模拟观测；resample 固定标量参数并重新抽取过程。 | conditional simulates observations at fixed fitted states; resample draws new processes at fixed scalar estimates. |
| `preserve_missing` | `TRUE` | 保留原 NA 和零位置；FALSE 生成完整正观测。 | Preserve original NA/zero positions; FALSE generates a complete positive survey. |
| `allow_failed_fit` | `FALSE` | 已知失败拟合默认拒绝；TRUE 警告后允许探索。 | Reject known failed fits by default; TRUE permits warned exploratory use. |

**返回 / Returns:** simulations 为具名重复，每项含可直接拟合的 x、observations 及 truth；metadata 记录过程模式、种子／随机数生成器、坐标、原观测掩码、源数值状态和 parameter_uncertainty = none。真值包括时间、种群量、原生组别 F、标量参数、随机效应及期望指数。

simulations contains named replicates with x, observations and truth; metadata records the process, seed/RNG, coordinates, original observation mask, source numerical status and parameter_uncertainty = none. Truth includes year, population quantities, native group-specific F, scalar parameters, random effects and expected indices.

条件模式固定拟合状态，只改变对数正态观测误差。过程重抽样使用平稳 AR(1) 补充、可分离组别／时间 AR(1) F（或仅时间共用 F）及独立初始年龄偏差，再调用现有 C++ 种群方程，无须优化。过程尺度为边际标准差。标量参数、生物学和可捕性保持固定；重抽样拒绝固定／绑定随机效应的 map，不加入参数不确定性或自助法区间。显式种子会恢复调用者随机数状态；默认保留原 NA／零位置。已知失败拟合须显式覆盖并警告。支持读取后的可移植拟合。

Conditional simulation holds fitted states fixed and varies lognormal observation errors. Resampling draws stationary AR(1) recruitment, separable group/time AR(1) F (or shared time-only F) and independent initial-age deviations, then evaluates the existing C++ population equations without optimization. Scales are marginal SDs. Scalar parameters, biology and catchability remain fixed. Fixed/tied random-effect maps are rejected for resampling; no parameter uncertainty or bootstrap intervals are added. Explicit seeds restore caller RNG state; original NA/zero cells are preserved by default. Known failed fits require an explicit warned override. Portable saved fits are supported.

模拟返回的输入列表显式保存源拟合的实际固定标量值；重新拟合不会根据新观测改变这些固定值。自由参数保留原初值策略。新 ALSCL 拟合的条件真值含 dev_log_N0，保存并读取后也保留；缺少该字段的旧存档仍返回 NULL。

Returned input bundles explicitly retain the source fit’s effective fixed scalar values, so refitting does not derive different fixed values from new observations. Free parameters keep their original starting-value strategy. Conditional truth from new ALSCL fits retains dev_log_N0 after saving and reading; older archives without that field still return NULL.

**示例 / Example:**

```r
fit <- run_acl(YTF_example, silent = TRUE)
simulated <- simulate_fit(fit, nsim = 3, seed = 42, process = "resample")
refitted <- run_acl(simulated$simulations[[1]]$x, silent = TRUE)
simulated$simulations[[1]]$truth$SSB
```

![示例图 / Example figure: `simulate_fit(b, nsim = 3, seed = 42, process = "resample")`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/workflows/fitted-simulation.png?raw=true&v=79b8f645c515)


<a id="hindcast_model"></a>
## `hindcast_model`

逐步扩展训练窗口，对真正留出的调查指数进行点预测并评分。 / Fit expanding training windows and score survey-index point predictions against genuinely withheld periods.

```r
hindcast_model (x, model = c("acl", "alscl"), horizon = 1, nfolds = 3, min_train = 3, ncores = 1,
    nstarts = NULL, silent = TRUE, save_fits = FALSE, ...)
```

| 参数 / Argument | 默认值 / Default | 中文说明 | English description |
|---|---|---|---|
| `x` | `必填 / required` | 与核心拟合相同的输入列表；起点和假设不得用留出数据调参。 | The same input bundle used for fitting; choose starts and assumptions without tuning to held-out observations. |
| `model` | `c("acl", "alscl")` | 选择 ACL 或 ALSCL。 | Choose ACL or ALSCL. |
| `horizon` | `1` | 正整数预测期距，单位为模型时间步。 | Positive integer forecast horizon in model time steps. |
| `nfolds` | `3` | 最后若干合格训练起点的数量；不足时明确报错。 | Number of final eligible training origins; unavailable requested folds cause an error. |
| `min_train` | `3` | 最少训练时期数，至少 2。 | Minimum training periods, at least two. |
| `ncores` | `1` | 并行折的最大 socket 工作进程数；每折内部单进程。 | Maximum socket workers across folds; each inner fit uses one worker. |
| `nstarts` | `NULL` | 每折独立初值数；NULL 保留列表明确设置，否则 1。 | Independent starts per fold; NULL preserves an explicit bundle setting, otherwise one. |
| `silent` | `TRUE` | 抑制拟合进度；警告仍保留在诊断表。 | Suppress fitting progress; retain warnings in diagnostics. |
| `save_fits` | `FALSE` | 是否返回各折拟合；始终保留配置与诊断。 | Return fold fits; settings and diagnostics are retained regardless. |
| `...` | 可选 / optional | 具名核心拟合覆盖设置，列表整体替换。 | Named core fitting overrides; list arguments replace the complete corresponding list. |

**返回 / Returns:** predictions 按体长／时间／折列出观测、模型和持平基准的对数预测、误差、尺度分母及纳入状态。scores 按期距报告配对对数 RMSE／MAE、对数 MASE 与计数。diagnostics、recipes、settings、start_diagnostics、process_paths 保留状态、失败、警告和复现细节；可选保存 fits。

predictions is a length/time/fold table with observed, model and persistence predictions on the log scale, errors, scaling denominators and inclusion status. scores reports paired log RMSE/MAE, log MASE and counts by horizon. diagnostics, recipes, settings, start_diagnostics and process_paths retain fit status, failures, warnings and reproduction details; fits are optional.

使用至少 min_train 个训练期且能留出完整 horizon 的最后若干起点。每折只拟合截短输入，不使用完整序列拟合估计作为初值。未来对数补充／F 偏差沿 AR(1) 条件均值路径延伸，经种群转移得到代入式调查预测，不是边际预测均值或预测区间。未来生物学沿用训练末期。拒绝固定／绑定随时间变化随机效应的 map。失败／未确认数值状态的拟合保留但不评分。评分使用具备持平预测的配对正观测；对数 MASE 按同体长组连续训练对数差缩放，零／未知分母保持缺失。ncores 并行折，每折内初值和标准误顺序运行。手动假设应在不参考留出数据调参的前提下确定。

Uses the last eligible origins with at least min_train periods and the complete horizon. Each fold fits truncated inputs; no full-series fit supplies starts. Future log recruitment/F deviations follow AR(1) conditional-mean paths, then population transitions give plug-in survey predictions, not marginal predictive means or predictive intervals. Biology is carried forward from the training endpoint. Fixed/tied time-varying random-effect maps are rejected. Failed/unverified fits remain visible but unscored. Scores use paired positive observations with an available persistence forecast; log MASE scales by consecutive training log changes within each length. Zero/undefined scales remain missing. ncores parallelizes folds; starts and SEs are sequential inside each fold. User-supplied assumptions must be chosen without tuning to held-out data.

**示例 / Example:**

```r
validation <- hindcast_model(YTF_example, model = "acl", horizon = 1,
  nfolds = 2, min_train = 8, nstarts = 1, ncores = 2)
validation$diagnostics
validation$scores
head(validation$predictions)
```

![示例图 / Example figure: `hindcast_model(x, model = "acl", horizon = 1, nfolds = 3)`](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/workflows/hindcast-predictions.png?raw=true&v=6808289fa0c6)

<a id="chapter-15"></a>
## 15 复现与故障处理 · Reproducibility and troubleshooting

<!-- Generated by scripts/build_manual.py from website/content/{en,zh}/articles/. Edit the article pair, not this file. -->

[使用指南 / User guide](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md) · [首页 / Home](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/README.md)

## 复现结果与排除故障 / Reproduce results and fix problems

读完[理解第一次拟合](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin)之后，你已经有了输入列表 `x` 和拟合好的 ACL 模型 `a`。本页教你记录拟合依赖的内容、在以后的会话中重建拟合、并行运行拟合、在会话之间保留编译好的模型，以及查找常见错误。

After [Understand your first fit](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin) you have the input bundle `x` and the fitted ACL model `a`. On this page you record what the fit depends on, rebuild it in a later session, run fits in parallel, keep the compiled models between sessions, and look up the common errors.

<a id="reproducibility-record"></a>

### 1. 记录拟合依赖的内容 / Record what a fit depends on

```r
save_assessment(a, "ytf_acl.rds", overwrite = TRUE)
packageVersion("ALSCL")
a$recipe$versions
a$recipe$implementation$source$revision
writeLines(capture.output(sessionInfo()), "sessionInfo.txt")
```

`save_assessment()` 保存拟合结果，不含当前会话的 TMB 对象 `a$obj`，并附上记录拟合全部依赖内容的配方：

`save_assessment()` writes the fit without the live TMB object `a$obj` and with a recipe that records everything the fit depends on:

| 内容 / Item | 在保存的拟合结果中的位置 / Where in the saved fit |
|---|---|
| 数据表、设置、参数初值、边界、`map`、`nstarts` 和调用的其他参数 / Tables, settings, starting values, bounds, `map`, `nstarts` and the other arguments of the call | `recipe$args` |
| ALSCL、TMB 和 R 的版本 / ALSCL, TMB and R versions | `recipe$versions` |
| 模型源文件的 MD5 值、已知时的 Git 修订号、平台、BLAS、LAPACK、Matrix 和 RcppEigen / MD5 hashes of the model source, Git revision when known, platform, BLAS, LAPACK, Matrix and RcppEigen | `recipe$implementation` |
| 速度设置，`framework` 和 `sd_cores` / Speed settings, `framework` and `sd_cores` | `recipe$settings` |

`sessionInfo()` 补充操作系统、BLAS 和 LAPACK 库以及已加载的软件包；把它的输出和保存的文件放在一起。拟合模型模拟还依赖随机种子，`simulate_fit()` 会把它记录在 `metadata$seed` 中。

`sessionInfo()` adds the operating system, the BLAS and LAPACK libraries and the loaded packages; keep its output next to the saved file. A fitted-model simulation also depends on its seed, which `simulate_fit()` records in `metadata$seed`.

当文件已存在（请设置 `overwrite = TRUE`）、文件夹不存在，或拟合结果没有配方时，`save_assessment()` 会报错停止；此时把输入列表作为 `x` 传入，配方会由它重建。

`save_assessment()` stops when the file exists (set `overwrite = TRUE`), when its folder is missing, or when a fit has no recipe; then pass the bundle as `x` and the recipe is rebuilt from it.

<a id="reproducibility-reproduce"></a>

### 2. 在以后重现拟合 / Reproduce a fit later

```r
saved <- read_assessment("ytf_acl.rds")
refit <- refit_model(saved)
max(abs(refit$opt$par - saved$opt$par))
all.equal(refit$report$SSB, saved$report$SSB)
```

`read_assessment()` 返回保存的拟合结果，所有绘图和提取函数都能使用它；它没有可执行的 TMB 对象，因为 `a$obj` 保存的是指向拟合时所在会话中编译模型的指针。`refit_model()` 重新拟合配方，返回带有可执行对象的拟合结果；命名参数会覆盖配方，`map` 这类列表会整体替换保存的列表。

`read_assessment()` returns the saved fit, which every plot and extraction function accepts; it has no live TMB object, because `a$obj` holds pointers into the compiled model of the session that made the fit. `refit_model()` fits the recipe again and returns a fit with a live object; named arguments override the recipe, and a list such as `map` replaces the stored list.

在同一台电脑上使用相同版本的 ALSCL、TMB 和 R 时，标量参数逐位相同，`all.equal()` 返回 `TRUE`。不同机器或不同软件包版本之间末位数字的差异来自浮点运算和优化器的停止规则；大到足以改变结论的差异，说明数据、设置或软件包版本不同。

On the same computer with the same versions of ALSCL, TMB and R, the scalar parameters agree to the last digit and `all.equal()` returns `TRUE`. Differences in the last digits between machines or package versions come from floating-point arithmetic and the optimizer's stopping rule; a difference large enough to change a conclusion means the data, settings or package version differ.

`refit_model()` 发现 ALSCL、TMB、Matrix 或 RcppEigen 的版本或模型源文件与配方不同时会给出警告；要逐位复现，请安装 `saved$recipe$versions` 中的版本。`A complete fit recipe is required` 表示拟合结果没有配方；按第 1 步用 `x` 重新保存。

`refit_model()` warns when the ALSCL, TMB, Matrix or RcppEigen version or the model source differs from the recipe; to reproduce exactly, install the versions in `saved$recipe$versions`. `A complete fit recipe is required` means the fit has no recipe; save it again with `x` as in step 1.

<a id="reproducibility-parallel"></a>

### 3. 并行运行拟合 / Run fits in parallel

```r
a4 <- run_acl(x, nstarts = 4, ncores = 2, silent = TRUE)
a4$start_diagnostics
a4$workers
```

`ncores` 决定一个函数启动多少个 socket 进程，即新的 R 进程。每个进程运行完整的初值或完整的拟合，因此结果与顺序运行相同。

`ncores` sets how many socket workers, new R processes, a function starts. Each worker runs whole starts or whole fits, so the results equal a sequential run.

| 函数 / Function | 分配给进程的工作 / What runs on the workers | 每次拟合的初值个数 / Starts in each fit |
|---|---|---|
| `run_acl()`、`run_alscl()` / `run_acl()`, `run_alscl()` | 各个初值，最多 `min(ncores, nstarts)` 个进程 / The starts, on at most `min(ncores, nstarts)` workers | `nstarts`，默认等于 `ncores` / `nstarts`, default `ncores` |
| `retro_model()`、`retro_acl()`、`retro_alscl()` / `retro_model()`, `retro_acl()`, `retro_alscl()` | 回溯分析的各轮 / The peels of the retrospective analysis | 输入列表或调用中明确给出的 `nstarts`，否则为一个，依次运行 / The explicit `nstarts` of the bundle or call, otherwise one, in sequence |
| `fit_scenarios()`、`hindcast_model()` / `fit_scenarios()`, `hindcast_model()` | 各项任务：每个情景或每个训练折 / The tasks: one scenario or training fold each | 同上 / The same rule |
| `sim_model()`、`sim_acl()`、`sim_alscl()` / `sim_model()`, `sim_acl()`, `sim_alscl()` | 各个重复 / The replicates | `nstarts`，默认为一个 / `nstarts`, default one |

由于 `nstarts` 默认等于 `ncores`，比较耗时时请同时设置两者。后续初值加上固定的扰动，最后选出目标函数最小的初值，因此无论 `ncores` 为多少，结果都相同；`a4$start_diagnostics` 记录每个初值。其他函数不使用输入列表中的 `ncores`，每次拟合只用一个进程并顺序计算标准误。

Because `nstarts` defaults to `ncores`, set both when you compare timings. Later starts add fixed perturbations and the lowest objective is selected, so the result is the same for any `ncores`; `a4$start_diagnostics` records each start. The other functions ignore the `ncores` of a bundle and give each fit one worker and sequential standard errors.

一次拟合内部计算标准误所用的核数是另一项设置，`alscl_speed(sd_cores = ...)`，结果与顺序计算完全相同；[速度设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/SPEED_GUIDE.md)有说明。

The cores used for the standard errors inside one fit are a separate setting, `alscl_speed(sd_cores = ...)`, with results identical to the sequential calculation; [Speed settings](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/SPEED_GUIDE.md) explains it.

2026 年 10 月 7 日的基准测试（Apple M2 Pro，R 4.6.0，TMB 1.9.21）用 `YTF_example` 的前 10 年拟合两个模型，每次使用相同的四个初值，每种进程数重复三次；不计编译，计入进程启动。

In a benchmark on 7 October 2026 (Apple M2 Pro, R 4.6.0, TMB 1.9.21), both models were fitted to the first 10 years of `YTF_example` with the same four starts, three times per number of workers; compilation was excluded and worker start-up included.

| 模型 / Model | 进程数 / Workers | 中位数（秒） / Median (s) | 范围（秒） / Range (s) | 加速比 / Speed-up |
|---|---:|---:|---:|---:|
| ACL | 1 | 4.23 | 4.18-4.44 | 1.00x |
| ACL | 2 | 3.50 | 3.27-3.90 | 1.21x |
| ACL | 4 | 3.08 | 2.93-3.14 | 1.38x |
| ALSCL | 1 | 71.4 | 71.3-72.4 | 1.00x |
| ALSCL | 2 | 45.0 | 44.6-51.0 | 1.59x |
| ALSCL | 4 | 33.2 | 31.2-34.0 | 2.15x |

![一、二、四个进程的拟合耗时实测 / Measured fitting times with one, two and four workers](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/parallel/timing.png?raw=true&v=181f350e0f84)

圆点是三次测量，折线是中位数，误差线是范围。测试时电脑与其他分析共用，结果只在该负载和该机器的条件下成立。参见[基准测试报告](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PARALLEL_BENCHMARK.md)、[原始耗时](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/parallel/runs.csv)和[基准测试脚本](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/scripts/benchmark_parallel.R)。

The points are the three measurements, the lines the medians and the bars the ranges. The computer was shared with other analyses, so the results are conditional on that workload and machine. See the [benchmark report](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PARALLEL_BENCHMARK.md), the [raw timings](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/parallel/runs.csv) and the [benchmark script](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/scripts/benchmark_parallel.R).

<a id="reproducibility-compile"></a>

### 4. 编译与缓存 / Compilation and the cache

```r
options(ALSCL.tmb.cache = tools::R_user_dir("ALSCL", "cache"))
a <- run_acl(x, silent = TRUE)
list.files(getOption("ALSCL.tmb.cache"))
```

每个模型的第一次拟合把它的 C++ 模板编译到缓存的一个文件夹中，文件夹名是一个键，由模型源文件和头文件的 MD5 值、R、TMB 和 RcppEigen 版本、OpenMP 标志以及 `framework` 计算得到；键相同的拟合直接加载库，不再编译。默认缓存位于 `tempdir()` 之下，R 在会话结束时删除它。在第一次拟合之前设置 `ALSCL.tmb.cache`，例如写在 `.Rprofile` 中，编译好的模型就能在会话之间保留；socket 进程加载会话编译好的库。

The first fit of each model compiles its C++ template into a cache folder named by a key computed from the MD5 hashes of the model source and header, the R, TMB and RcppEigen versions, the OpenMP flag and the `framework`; a fit with the same key loads the library without compiling. The default cache lies under `tempdir()`, which R removes at the end of the session. Set `ALSCL.tmb.cache` before the first fit, for example in `.Rprofile`, to keep the compiled models between sessions; socket workers load the library compiled by the session.

编译需要 C++ 编译器：

Compiling needs a C++ compiler:

| 系统 / System | 编译器 / Compiler |
|---|---|
| Windows | 与 R 版本对应的 Rtools / Rtools for your R version |
| macOS | Xcode Command Line Tools（`xcode-select --install`） / The Xcode Command Line Tools (`xcode-select --install`) |
| Linux | C++ 编译器和 `make`，例如 `build-essential` / A C++ compiler and `make`, for example `build-essential` |

[安装 ALSCL 并完成第一次拟合](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#getting-started-compiler)说明安装方法；编译错误中会出现 `TMB::compile`、`make` 或编译器的名字。

[Install ALSCL and run a first fit](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#getting-started-compiler) explains the installation; compilation errors name `TMB::compile`, `make` or the compiler.

<a id="reproducibility-troubleshoot"></a>

### 5. 故障排除 / Troubleshooting

错误信息按软件包打印的原文引用。

Error messages are quoted as the package prints them.

| 现象 / Symptom | 常见原因 / Likely cause | 处理方法 / What to do |
|---|---|---|
| `YTF$data.CatL` 是 `NULL` / `YTF$data.CatL` is `NULL` | `YTF` 存放参数，不是数据表 / `YTF` holds parameters, not tables | 使用 `YTF_example` / Use `YTF_example` |
| 年份标签读成 `X2000`，或 `must match data.CatL length labels and time columns` / Year labels read as `X2000`, or `must match data.CatL length labels and time columns` | `read.csv()` 给列名加上 `X`，各表不一致 / `read.csv()` adds `X`; the tables differ | 用 `check.names = FALSE` 读取全部表 / Read all tables with `check.names = FALSE` |
| `Length intervals must have positive widths and be contiguous` | 体长组标签重叠或有空隙 / Bin labels overlap or leave gaps | 改正标签，或提供 `len_mid` 和 `len_border` / Correct the labels or supply `len_mid` and `len_border` |
| `Time columns must have increasing numeric labels` 或 `Time column spacing must equal growth_step` / `Time columns must have increasing numeric labels` or `Time column spacing must equal growth_step` | 缺少时间步，或 `growth_step` 不对 / A missing time step or a wrong `growth_step` | 缺失的时间步保留为 NA 列，并设置 `growth_step` / Keep the step as an NA column and set `growth_step` |
| 调查表中有零 / Zeros in the survey table | 零按缺失处理（`zero_action = "missing"`） / Zeros count as missing (`zero_action = "missing"`) | 拟合前判断零是否真实 / Decide whether a zero is real before fitting |
| 体重表或成熟比例表有空白单元格 / Blank cells in the weight or maturity table | 两张表必须完整 / Both tables must be complete | 补全并记录来源 / Fill them and record the source |
| 收敛码不是 0、梯度大或 Hessian 不正定 / Convergence code not 0, large gradient or Hessian not positive definite | 优化器提前停止，或某个参数得不到信息 / The optimizer stopped early or a parameter is not informed | 见[理解第一次拟合](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#first-model-checks) / See [Understand your first fit](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#first-model-checks) |
| 季度 F 看起来偏小 / Quarterly F looks small | F 在所有输出中都按时间步计 / Every output gives F per time step | 按时间步报告 F / Report F per time step |
| 对 ACL 拟合调用 `plot_fishing_mortality(a, type = "length")` 给出警告 / `plot_fishing_mortality(a, type = "length")` warns on an ACL fit | ACL 没有按体长的 F；`"length"` 等同 `"age"` / ACL has no F by length; `"length"` means `"age"` | 用 `type = "age"`，或拟合 ALSCL / Use `type = "age"` or fit ALSCL |
| `plot_VB()` 只画出一条线，没有区间 / `plot_VB()` draws a line without an interval | 生长参数被固定 / The growth parameters are fixed | 属于预期；用 `map` 释放 / Expected; release them with `map` |
| 第一次拟合报错，信息中出现 `TMB::compile`、`make`、`g++` 或 `clang` / The first fit names `TMB::compile`, `make`, `g++` or `clang` | 没有编译器，或 Rtools 对应另一个 R 版本 / No compiler, or Rtools for another R version | 安装编译器（第 4 步），重启 R / Install the compiler (step 4), restart R |
| `Install RcppEigen to compile model templates` 或 `Model sources are missing` / `Install RcppEigen to compile model templates` or `Model sources are missing` | 缺少 RcppEigen，或安装损坏 / RcppEigen absent, or a damaged installation | 安装 RcppEigen 或重新安装 ALSCL / Install RcppEigen or reinstall ALSCL |
| `Socket worker loaded a different ALSCL installation` | 进程先找到了另一个库中的副本 / A worker found another copy in a different library | 只保留一个安装，或用 `ncores = 1` / Keep one installation, or use `ncores = 1` |
| Windows 或 RStudio 中 socket 进程失败，或 `Parallel standard errors failed` / Socket workers fail on Windows or in RStudio, or `Parallel standard errors failed` | 新的 R 进程无法启动 / The new R processes could not start | 用 `ncores = 1` 或 `alscl_speed(sd_cores = 1)` / Use `ncores = 1` or `alscl_speed(sd_cores = 1)` |
| 回溯分析后 `rho_text$Rho` 是 `NA` / `rho_text$Rho` is `NA` after a retrospective analysis | 某次拟合未通过数值检查 / A fit failed the numerical checks | 查看 `fit_diagnostics` 和 `rho_by_peel`，修正该拟合 / Read `fit_diagnostics` and `rho_by_peel`, fix that fit |
| `The current implementation differs from the saved assessment` | 保存之后软件包、TMB 或模型源文件变了 / Package, TMB or model source changed since the save | 预期末位有差异，或安装记录的版本 / Expect last-digit differences, or install the recorded versions |
| `A complete fit recipe is required` | 拟合没有配方 / The fit has no recipe | 重新拟合，或带 `x = x` 保存 / Refit, or save with `x = x` |

<a id="reproducibility-next"></a>

### 下一步 / What next

| 想做什么 / What you want to do | 阅读 / Read |
|---|---|
| 检验估计值对固定值的敏感性 / Test the sensitivity of the estimates to the fixed values | [判断拟合是否可用](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics-sensitivity) / [Judge whether a fit can be used](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics-sensitivity) |
| 选择速度设置并检查本会话的实际情况 / Choose the speed settings and check what your session does | [速度设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/SPEED_GUIDE.md) / [Speed settings](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/SPEED_GUIDE.md) |
| 运行回溯分析并解读 Mohn's rho / Run a retrospective analysis and read Mohn's rho | [回溯分析](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#retrospective) / [Retrospectives](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#retrospective) |
| 从拟合模型模拟，或检验对留出时间步的预测 / Simulate from the fit or test predictions of withheld time steps | [模型验证](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md) / [Model validation](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md) |
| 比较情景、做参数剖面和投影 / Compare scenarios, profile a parameter, project forward | [评估工作流](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ASSESSMENT_WORKFLOWS.md) / [Assessment workflows](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ASSESSMENT_WORKFLOWS.md) |

<a id="chapter-16"></a>
## 16 评估工作流 · Assessment workflows

<!-- Generated by scripts/build_manual.py from website/content/{en,zh}/articles/. Edit the article pair, not this file. -->

[使用指南 / User guide](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md) · [首页 / Home](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/README.md)

## 评估工作流：从输入列表到保存结果 / Assessment workflows: from bundle to saved results

本页带你把一个拟合好的模型走完评估报告包含的各项分析：保存估计值、检查残差、检验对固定输入的敏感性、对一个被估计的参数做剖面、投影未来情景、拟合模拟重复，最后得到一份保存的拟合结果和一个结果表文件夹。你需要已安装软件包（[安装并完成第一次拟合](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#start)）；使用自己的数据时，按[准备调查数据](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel)建立输入列表 `x`。第 4 到 7 步每步都要多次重新拟合模型；按需要选做，顺序不限，都从第 1 步的对象开始。

On this page you take one fitted model through the analyses an assessment reports, from saving the estimates to checking residuals, testing sensitivity to fixed inputs, profiling an estimated parameter, projecting future scenarios and fitting simulation replicates, and you end with a saved fit and a folder of result tables. You need the package installed ([Install and run a first fit](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#start)); with your own data, build the input bundle `x` as in [Prepare your survey data](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel). Steps 4 to 7 refit the model several times each; run the ones you need, in any order, from the objects of step 1.

<a id="assessment-workflows-fit-teaching-models"></a>

### 1. 拟合一次，保留对象 / Fit once and keep the objects

```r
library(ALSCL)
library(ggplot2)
data("YTF_example")
x <- YTF_example
a <- run_acl(x, silent = TRUE)
b <- run_alscl(x, silent = TRUE)
summary(a)
summary(b)
```

ACL 拟合 `a` 用于情景和剖面，因为一次 ACL 重新拟合约二十秒；ALSCL 拟合 `b` 用于结果提取、残差和投影。`summary()` 打印模型、时间步、F 结构、一行数值检查（`numerical_ok` 应为 `TRUE`，`issues` 应为空）和自然尺度上的标量参数。先读数值检查：后面的每个函数都会记录它，`project_model()` 会拒绝未通过检查的拟合。若 `numerical_ok` 为 `FALSE`，按[判断拟合是否可用](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics)改一项设置并重新拟合。

The ACL fit `a` serves the scenarios and profiles, because an ACL refit takes about twenty seconds; the ALSCL fit `b` serves results, residuals and projections. `summary()` prints the model, the time steps, the F structure, the numerical checks in one row (`numerical_ok` should be `TRUE`, `issues` empty) and the scalar parameters on the natural scale. Read the checks first: every later function records them, and `project_model()` refuses a fit that failed them. If `numerical_ok` is `FALSE`, change one setting as described in [Judge whether a fit can be used](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) and refit.

<a id="assessment-workflows-section-4"></a>

### 2. 提取结果，保存拟合结果 / Extract results and keep a saved fit

```r
parameter_estimates <- extract_parameters(b)
parameter_estimates
estimates <- extract_estimates(b, quantities = c("SSB", "Rec", "F"))
head(estimates)
write.csv(estimates, "ytf_alscl_estimates.csv", row.names = FALSE)
save_assessment(b, "ytf_alscl.rds")
saved <- read_assessment("ytf_alscl.rds")
summary(saved)
saved$recipe$versions
plot_SSB(saved, se = TRUE)
b_again <- refit_model(saved, silent = TRUE)
```

`extract_parameters()` 每个标量参数返回一行：`status`（`estimated`、`fixed` 或 `inactive`）、自然尺度上的估计值、标准误和 95% 区间（固定参数为 `NA`）；`exp(mean_log_F)` 是 F 过程的基准水平，各年的 F 由它乘以指数化的偏差得到。`extract_estimates()` 返回种群量的长表，带 `year`、`age` 或 `length` 和每个值的区间；ALSCL 的 `F` 按体长组给出（`report_name` 为 `FL`），ACL 按年龄给出，不取平均。

`extract_parameters()` returns one row per scalar parameter: `status` (`estimated`, `fixed` or `inactive`), the estimate on the natural scale, its standard error and a 95% interval (`NA` for fixed parameters); `exp(mean_log_F)` is the baseline of the F process, which the exponentiated yearly deviations scale. `extract_estimates()` returns a long table of population quantities with `year`, `age` or `length` and an interval for each value; `F` comes by length bin for ALSCL (`report_name` is `FL`) and by age for ACL, without averaging.

`save_assessment()` 写出保存的拟合结果：`b` 中除 TMB 对象 `b$obj` 以外的全部内容，加上配方（三张表、设置、`map`、边界、初值、软件包版本和模型源码的哈希值）。`summary()`、提取函数和绘图函数都能直接用于 `read_assessment()` 读回的对象，同事无需重新拟合就能读你的结果；需要可执行模型时，`refit_model()` 重新运行配方，例如用 `refit_model(saved, M = 0.25)` 改变一项假设，并在软件包、TMB 或模型源码与保存时不同时发出警告。文件已存在时 `save_assessment()` 会停止（传入 `overwrite = TRUE`），拟合结果没有配方时也会停止（把它的输入列表作为 `x` 传入）。

`save_assessment()` writes the saved fit: everything in `b` except the live TMB object `b$obj`, plus the recipe (the three tables, settings, `map`, bounds, starting values, package versions and hashes of the model source). `summary()`, the extraction and plot functions work on what `read_assessment()` returns, so a colleague reads your results without refitting; `refit_model()` reruns the recipe when you need a live model, for example `refit_model(saved, M = 0.25)` to change one assumption, and warns when the package, TMB or the model source differ from the saved ones. `save_assessment()` stops when the file exists (pass `overwrite = TRUE`) or when a fit has no recipe (pass its input bundle as `x`).

<a id="assessment-workflows-section-5"></a>

### 3. 按模型时间轴检查残差 / Check residuals on the model time grid

```r
checks <- check_fit(b, max_lag = 4)
head(residuals(b, type = "standardized"))
checks$lag_correlations
checks$plots$heatmap
checks$plots$lag
checks$plots$qq
```

![按体长组和时间步排列的标准化残差 / Standardized residuals by length bin and time step](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/workflows/residual-heatmap.png?raw=true&v=2dbeb4799a6c)

![同一体长组残差相隔一到四个时间步的相关系数 / Correlation between residuals of one length bin at lags of one to four time steps](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/workflows/residual-lag.png?raw=true&v=22adbe12d133)

![合并标准化残差的 QQ 图 / QQ plot of the pooled standardized residuals](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/workflows/residual-qq.png?raw=true&v=3294444a2cd7)

`check_fit()` 把对数残差标准化（观测减拟合的对数指数，再除以拟合的观测 SD），并画三种图。热图按体长组和时间步排列（被排除的零值和空白为灰色），同色成块说明模型漏掉了一个队列或一段体长。滞后图对每个体长组画出相隔一到 `max_lag` 个时间步的残差相关系数；没有调查的时间步仍是空缺，`checks$lag_correlations` 给出每个点背后的配对数。QQ 图把合并后的残差与正态分布比较。教学拟合中，16 cm 体长组几乎每年都是正残差，最大体长组从 2013 年起为正且滞后一步的相关系数接近 0.8，QQ 图正尾偏重：虽然数值检查通过，这些规律仍值得查看。残差以拟合的过程偏差为条件，所以把这些图当作提示而不是检验；[判断拟合是否可用](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics)说明某种规律通常指向哪项设置。

`check_fit()` standardizes the log residuals (observed minus fitted log index, divided by the fitted observation SD) and draws three views. In the heatmap by length bin and time step (excluded zeros and blanks in grey), a block of one colour means the model misses a cohort or a size range. The lag plot shows, per length bin, the correlation between residuals one to `max_lag` time steps apart; an unobserved time step stays a gap, and `checks$lag_correlations` gives the pairs behind each point. The QQ plot compares the pooled residuals with the normal distribution. In the teaching fit the 16 cm bin is positive in nearly every year, the largest bin is positive from 2013 on with a lag-one correlation near 0.8, and the QQ plot has a heavier positive tail: worth a look although the numerical checks pass. The residuals are conditional on the fitted process deviations, so treat the views as pointers, not tests; [Judge whether a fit can be used](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) says which setting a pattern usually points to.

<a id="assessment-workflows-section-6"></a>

### 4. 敏感性情景与参数剖面 / Sensitivity scenarios versus parameter profiles

`fit_scenarios()` 在具名的改动下重新拟合同一观测，改动的是模型视为给定的输入（自然死亡率、调查可捕性、F 结构、某项 `map`），显示假设改变时结果移动多少。`profile_model()` 把一个被估计的标量参数依次固定在网格的每个值上并重新估计其余参数，显示数据对该参数的确定程度。示例检验教学拟合的两项假设：

`fit_scenarios()` refits the same observations under named changes of the inputs the model takes as given (natural mortality, survey catchability, the F structure, a `map` entry) and shows how much the result moves when an assumption changes. `profile_model()` fixes one estimated scalar parameter at each value of a grid, refits the rest, and shows how well the data determine that parameter. The example tests two assumptions of the teaching fit:

| 情景 / Scenario | 相对参考情景的改动 / Change from the reference | 检验什么 / What it tests |
|---|---|---|
| `reference` | 无：每时间步 `M` = 0.20，`F_structure = "group_year"` / None: `M` = 0.20 per time step, `F_structure = "group_year"` | 第 1 步的设置 / The settings of step 1 |
| `low_M` | `M = 0.15` | 自然死亡率是固定值，生物量的尺度依赖于它 / Natural mortality is fixed, and the biomass scale depends on it |
| `shared_F` | `F_structure = "year"`：每个时间步一个 F，各年龄共用 / `F_structure = "year"`: one F per time step shared by all ages | 是否需要年龄别的 F / Whether age-specific F is needed |

```r
scenarios <- fit_scenarios(x, list(
  reference = list(),
  low_M = list(M = 0.15),
  shared_F = list(F_structure = "year")
), model = "acl", ncores = 2, F_summary = "mean", silent = TRUE)
scenarios$status
head(scenarios$estimates)
scenario_ssb <- subset(scenarios$estimates, quantity == "SSB")
ggplot(scenario_ssb, aes(year, estimate, color = scenario)) +
  geom_line() + labs(x = "Year", y = "SSB") +
  theme_bw() + theme(panel.grid = element_blank())
```

![三个 ACL 情景的产卵生物量 / Spawning biomass of the three ACL scenarios](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/workflows/scenario-SSB.png?raw=true&v=7ee6fd0e12d8)

每个情景是一个具名的参数列表，用来替换 `x` 中的设置；空列表就是参考情景，`map` 这类列表会整体替换保存的列表，三张表保持不变。先看 `scenarios$status` 再看曲线：它每个情景一行，记录耗时、错误、警告和数值检查。未通过检查的情景仍留在 `scenarios$estimates` 中且 `numerical_ok = FALSE`；因错误停止的情景没有估计值。估计值表按情景和年份给出产卵生物量、补充量和 F，其中 F 由 `F_summary = "mean"` 在每个时间步内对各年龄（或体长组）取平均，或由 `"apical"` 取最大值。`ncores` 把各情景放在不同的工作进程上运行，每个情景使用 `x` 中保存的初值个数，否则一个初值。这里三条曲线几乎重合：较低的 M 和共用的 F 使产卵生物量至多变动百分之几；换成自己的数据，曲线之间的差距就是要报告的敏感性。

Each scenario is a named list of arguments that replace the settings of `x`; an empty list is the reference, a list such as `map` replaces the stored list completely, and the three tables stay the same. Read `scenarios$status` before the curves: one row per scenario with the time taken, errors, warnings and the numerical checks. A scenario that failed the checks stays in `scenarios$estimates` with `numerical_ok = FALSE`; one that stopped with an error has no estimates. The estimates table holds spawning biomass, recruitment and F by scenario and year, with F averaged over ages (or length bins) within each time step by `F_summary = "mean"` or taken as the maximum by `"apical"`. `ncores` runs scenarios on separate workers, each with the starts stored in `x` or one start. Here the three curves nearly coincide: the lower M and the shared F move spawning biomass by a few percent at most; with your own data, the spread between the curves is the sensitivity to report.

<a id="assessment-workflows-section-7"></a>

#### 对被估计的参数做剖面 / Profile a parameter that was estimated

```r
profile_values <- exp(a$opt$par[["mean_log_F"]]) * c(0.9, 1, 1.1)
profile_F <- profile_model(a, "mean_log_F", profile_values,
                           scale = "natural", ncores = 1)
profile_F$grid
ggplot(profile_F$grid, aes(value, delta_nll)) +
  geom_line() + geom_point() +
  labs(x = "F process baseline", y = "Change in negative log likelihood") +
  theme_bw() + theme(panel.grid = element_blank())
```

![F 过程基准水平在三个网格值上的剖面 / Profile of the F process baseline over three grid values](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/workflows/profile-F.png?raw=true&v=cc2a75644194)

`profile_model()` 接受 `names(a$opt$par)` 中的一个名称，即拟合估计的标量参数；`YTF_example` 固定了 `log_Linf`，对它做剖面会以「parameter must name one free scalar」停止。`scale = "natural"` 时网格按自然尺度给出，且必须落在优化器边界内。`profile_F$grid` 列出每个值的目标函数值、`delta_nll`（相对原拟合的负对数似然增量）和该次重新拟合的数值检查。两侧陡升说明数据能很好地确定该参数；这里基准 F 变动 10% 使负对数似然上升 0.8 到 0.9。`delta_nll` 为负会触发警告：某个网格点找到了更优的解，应先用更多初值重新拟合原模型。用于报告的剖面需要更密的网格，并且每个点的拟合都通过检查。

`profile_model()` takes one name from `names(a$opt$par)`, the scalar parameters the fit estimated; `YTF_example` fixes `log_Linf`, so asking for it stops with "parameter must name one free scalar". With `scale = "natural"` the grid is given on the natural scale and must lie within the optimizer bounds. `profile_F$grid` lists each value with its objective, `delta_nll` (the rise in negative log likelihood relative to the original fit) and the numerical checks of that refit. A steep rise on both sides means the data determine the parameter well; here a 10% change of the baseline F costs 0.8 to 0.9 units. A negative `delta_nll` triggers a warning: a grid refit found a better optimum, so refit the original with more starts first. A profile for a report needs a denser grid and refits that all pass the checks.

<a id="assessment-workflows-section-8"></a>

### 5. 投影未来情景 / Project future scenarios

```r
h <- 4L
w <- as.matrix(x$data.wgt[-1L])
mat <- as.matrix(x$data.mat[-1L])
future_w <- matrix(w[, ncol(w)], nrow(w), h)
future_mat <- matrix(mat[, ncol(mat)], nrow(mat), h)
future_rec <- rep(tail(b$report$Rec, 1), h)
low_F <- project_model(b, F = rep(0.10, h), recruitment = future_rec,
                       weight = future_w, maturity = future_mat)
higher_F <- project_model(b, F = rep(0.25, h), recruitment = future_rec,
                          weight = future_w, maturity = future_mat)
low_F$summary
low_F$assumptions
projection_ssb <- rbind(
  transform(low_F$summary, scenario = "F = 0.10"),
  transform(higher_F$summary, scenario = "F = 0.25"))
ggplot(projection_ssb, aes(year, SSB, color = scenario)) +
  geom_line() + geom_point() + labs(x = "Year", y = "Start-of-period SSB") +
  theme_bw() + theme(panel.grid = element_blank())
```

![两种未来 F 水平下的投影产卵生物量 / Projected spawning biomass under two future F levels](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/workflows/projection-SSB.png?raw=true&v=a1acd1f6ce98)

`project_model()` 用你提供的值把最后一个拟合的种群向未来时间步推进：`F`（每步一个值、各组共用，或组乘时间步的矩阵）、`recruitment`（它的长度决定投影期数），以及完整的 `weight` 和 `maturity` 矩阵，每个未来时间步一列。函数不替你延续任何值；代码重复最后一列观测的体重和成熟比例以及最后一个拟合的补充量，这是需要在报告中说明的选择。`M` 保持拟合时的值，除非另外传入。`low_F$summary` 对每个未来时间步列出丰度、生物量、产卵生物量、补充量、尾数和重量计的渔获以及 F 的平均值和最大值；`low_F$assumptions` 记录每项选择。

`project_model()` advances the last fitted population through future time steps under values you supply: `F` (one value per step shared by all groups, or a group by step matrix), `recruitment` (its length sets the horizon) and complete `weight` and `maturity` matrices with one column per future step. Nothing is carried forward for you; the code repeats the last observed weight and maturity columns and the last fitted recruitment, a choice to state in the report. `M` stays at the fitted value unless you pass another. `low_F$summary` lists, per future step, abundance, biomass, spawning biomass, recruitment, catch in numbers and in weight, and the mean and maximum F; `low_F$assumptions` records every choice.

每一行描述一个时间步的期初：第一个未来状态是最后一个拟合种群经最后一个拟合的 F 和 M 存活后加上第一个提供的补充量，未来的 `F[t]` 决定第 `t` 步的渔获和进入第 `t + 1` 步的存活。因此第一个提供的 F 不会改变第一个未来产卵生物量；两条曲线从第二步起才分开。投影是确定性的，并以拟合为条件，没有区间、亲体补充关系或参考点。来源拟合未通过数值检查时 `project_model()` 会停止，除非 `allow_failed_fit = TRUE`，这时覆盖会记录在 `assumptions` 中；出现「weight must be a finite nonnegative 23-by-4 matrix」这类信息，说明某个矩阵的行数（体长组）或列数（未来时间步）不对。

Each row describes the start of a time step: the first future state is the last fitted population survived through the last fitted F and M plus the first supplied recruitment, and a future `F[t]` sets the catch of step `t` and the survival into step `t + 1`. The first supplied F therefore does not change the first future spawning biomass; the curves separate from the second step on. The projection is deterministic and conditional on the fit, without intervals, stock-recruitment relationship or reference points. `project_model()` stops when the source fit failed the numerical checks unless `allow_failed_fit = TRUE`, which records the override in `assumptions`; a message such as "weight must be a finite nonnegative 23-by-4 matrix" means a matrix has the wrong number of rows (length bins) or columns (future steps).

<a id="assessment-workflows-section-9"></a>

### 6. 拟合模拟重复，报告失败率 / Fit simulation replicates and report failure rates

```r
pa <- x$parameters
bio <- sim_cal(pa)
iterations <- 1:2
simulation_dir <- tempfile("assessment-sim-")
sm <- sim_data(bio, pa, iter_range = iterations,
               return_iter = iterations[1], output_dir = simulation_dir)
cfg <- x$fit_config$alscl
simulation_fits <- sim_model(iterations, simulation_dir,
  file.path(simulation_dir, "fits_alscl"), model = "alscl", ncores = 1,
  parameters = cfg$parameters, parameters.L = cfg$parameters.L,
  parameters.U = cfg$parameters.U, map = cfg$map, M = pa$M)
simulation_truth <- setNames(lapply(iterations, function(i) {
  e <- new.env(parent = emptyenv())
  load(file.path(simulation_dir, paste0("sim_rep", i)), envir = e)
  s <- e$sim.data
  list(year = s$years, SSB = as.numeric(s$SSB), Rec = as.numeric(s$Rec))
}), paste0("result_rep_", iterations))
stopifnot(identical(names(simulation_fits), names(simulation_truth)))
performance <- summarize_simulations(simulation_fits, simulation_truth,
                                     quantities = c("SSB", "Rec"))
performance$replicates
performance$summary
```

这一步问的是模型能否找回一个已知的种群。`x$parameters` 保存生成 `YTF_example` 的模拟器设置；`sim_cal()` 由它推导生物学量，`sim_data()` 为每个重复写一个文件 `sim_rep<i>`，其中的列表 `sim.data` 含调查表以及逐年的真实 `SSB` 和 `Rec`。`sim_model()` 用所选模型及该模型的初值和 `map`（这里是 `x` 中保存的 ALSCL 配置）拟合每个文件，把每个结果保存为 `result_rep_<i>` 并以命名列表返回，因错误停止的重复连同错误信息一起保留。真值列表必须与拟合使用相同的名称和年份，所以代码逐个读取模拟文件；否则 `summarize_simulations()` 会以「identical unique replicate names」或「time coordinates differ」停止。

This step asks whether the model recovers a known population. `x$parameters` holds the settings of the simulator that generated `YTF_example`; `sim_cal()` derives the biology, and `sim_data()` writes one file `sim_rep<i>` per replicate holding a list `sim.data` with the survey tables and the true `SSB` and `Rec` by year. `sim_model()` fits every file with the chosen model and that model's starts and `map` (here the ALSCL configuration stored in `x`), saves each result as `result_rep_<i>` and returns them as a named list, keeping a replicate that stopped with an error together with its message. The truth list must use the same names and years as the fits, which is why the code reads each simulation file; otherwise `summarize_simulations()` stops with "identical unique replicate names" or "time coordinates differ".

读 `performance$summary` 的统计量时同时读它的分母：`n_replicates` 是尝试的拟合数，`n_valid_fits` 是通过数值检查的拟合数（`failure_rate` 是未通过的比例），`n_valid_pairs` 是 `bias`、`relative_bias` 和 `rmse` 所用的估计值与真值配对数，`n_intervals` 是 `coverage` 所用的、标准误有限的区间数，`coverage` 是其中包含真值的比例。缺少标准误的区间不计入覆盖率；`relative_bias` 跳过真值为零的年份。`performance$replicates` 列出每个重复的检查和耗时，`performance$estimates` 列出每个重复的每一年，包括失败的重复。两个重复只演示用法；正式研究需要足够多的重复，失败率和覆盖率才有意义。

Read the denominators of `performance$summary` with its statistics: `n_replicates` fits attempted, `n_valid_fits` fits that passed the numerical checks (`failure_rate` is the share that failed), `n_valid_pairs` the estimate and truth pairs behind `bias`, `relative_bias` and `rmse`, and `n_intervals` the intervals with a finite standard error behind `coverage`, the share of them containing the truth. A missing standard error leaves its interval out of coverage, and `relative_bias` skips years with a true value of zero. `performance$replicates` lists every replicate with its checks and time, `performance$estimates` every year of every replicate, failures included. Two replicates only show the mechanics; a study needs enough replicates for the failure rate and the coverage to mean something.

<a id="assessment-workflows-section-11"></a>

### 7. 模拟拟合模型并验证预测 / Simulate the fitted model and validate predictions

```r
simulated <- simulate_fit(b, nsim = 2, seed = 42, process = "conditional")
names(simulated$simulations[[1]])
validation <- hindcast_model(x, model = "acl", horizon = 1, nfolds = 3, ncores = 2)
validation$diagnostics
validation$scores
```

另外两项检查从拟合本身出发。`simulate_fit()` 是拟合模型模拟：它从拟合模型生成新的调查观测，围绕拟合的种群（`"conditional"`）或先抽取新的过程偏差（`"resample"`），并为每个重复返回一个 `run_alscl()` 可接受的输入列表 `x`，供你重新拟合并与保存的 `truth` 比较；该列表保留 `b` 的拟合配置，但不含 `output`、`ncores` 和 `silent`。`hindcast_model()` 是预测检验：它只用较早的时间步拟合，从最近的 `nfolds` 个训练起点各预测随后 `horizon` 个时间步的调查指数，并把预测与留出的观测对照评分，同时给出朴素预测的分数。[模型能重现并预测调查观测吗？](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md)完整演示这两项检查。

Two further checks start from the fit itself. `simulate_fit()` is the fitted-model simulation: it draws new survey observations from the fitted model, around the fitted population (`"conditional"`) or after drawing new process deviations (`"resample"`), and returns per replicate an input bundle `x` that `run_alscl()` accepts, so you can refit it and compare with the stored `truth`; the bundle keeps the fitting configuration of `b` except `output`, `ncores` and `silent`. `hindcast_model()` is the hindcast validation: it fits on the earlier time steps only, predicts the next `horizon` steps of the survey index from each of the `nfolds` most recent training origins, and scores the predictions against the withheld observations next to a naive forecast. [Can the model reproduce and predict survey observations?](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md) works through both checks.

<a id="assessment-workflows-save-workflow"></a>

#### 保存完成的工作流 / Save the completed workflow

```r
record_dir <- "assessment-record"
dir.create(record_dir)
write.csv(scenarios$status, file.path(record_dir, "scenario_status.csv"), row.names = FALSE)
write.csv(profile_F$grid, file.path(record_dir, "profile_F.csv"), row.names = FALSE)
write.csv(performance$summary, file.path(record_dir, "simulation_summary.csv"), row.names = FALSE)
saveRDS(list(input = x, scenarios = scenarios, profile = profile_F,
  projections = list(low_F = low_F, higher_F = higher_F),
  simulation_truth = simulation_truth, performance = performance,
  validation = validation), file.path(record_dir, "workflow_record.rds"))
writeLines(capture.output(sessionInfo()), file.path(record_dir, "session.txt"))
```

做完所用的步骤后运行这段代码，或只保存已有的对象。第 2 步保存的拟合结果就是评估本身；记录另外加入情景和剖面的拟合（不含 TMB 对象的列表）、带假设的投影、模拟真值与表现、验证分数和会话信息，连同输入列表，评估就可以复现。

Run this after the steps you used, or save the objects you have. The saved fit of step 2 is the assessment; the record adds the scenario and profile fits (lists without a live TMB object), the projections with their assumptions, the simulation truth and performance, the validation scores and the session information, which together with the input bundle make the assessment reproducible.

<a id="assessment-workflows-next"></a>

### 下一步 / What next

| 想做什么 / What you want to do | 阅读 / Read |
|---|---|
| 找出残差规律指向的设置 / Find the setting a residual pattern points to | [判断拟合是否可用](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) / [Judge whether a fit can be used](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) |
| 查看去掉近期时间步后估计值的变化 / See how estimates change when recent time steps are removed | [运行回溯分析](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#retrospective) / [Run a retrospective analysis](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#retrospective) |
| 带图完整演练模拟与预测检验 / Work through simulation and hindcast validation with figures | [模型能重现并预测调查观测吗？](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md) / [Can the model reproduce and predict survey observations?](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md) |
| 针对自己的种群提出敏感性或投影问题 / Ask a sensitivity or projection question about your own stock | [评估对假设有多敏感，未来 F 会怎样改变结果？](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md#case-sensitivity-projection) / [How sensitive is the assessment, and what happens under future F?](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md#case-sensitivity-projection) |
| 复现结果或排除故障 / Reproduce a result or fix a failure | [复现结果与排除故障](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ADVANCED_WORKFLOWS.md) / [Reproduce results and fix problems](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ADVANCED_WORKFLOWS.md) |

<a id="chapter-17"></a>
## 17 模型模拟与预测验证 · Model simulation and prediction checks

<!-- Generated by scripts/build_manual.py from website/content/{en,zh}/articles/. Edit the article pair, not this file. -->

[使用指南 / User guide](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md) · [首页 / Home](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/README.md)

## 模型能重现观测并预测留出时间步吗？ / Can the fitted model reproduce observations and predict withheld time steps?

本页从两个方面检验一个拟合好的模型。拟合模型模拟从拟合中生成新的调查数据并重新拟合，看估计值能否找回已知值；预测检验用较早的时间步拟合，再把留出的后续时间步的预测与观测对照打分。你需要已安装的软件包（[安装 ALSCL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#start)）；代码使用模拟的 `YTF_example`，总共约需十五分钟，因为第 3、4 步要多次重新拟合模型。只做预测检验时，运行第 1 步后直接到第 4 步。结束时你会有带真值的模拟数据集、偏差、RMSE 和区间覆盖率表、两个模型相对于持平基准的预测评分，以及保存的拟合结果。

On this page you check a fitted model from two sides. Fitted-model simulation draws new survey data from the fit and refits them, to see whether the estimates recover the known values; hindcast validation fits on the earlier time steps and scores the predictions of the withheld later ones against the observations. You need the package installed ([Install ALSCL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#start)); the code uses the synthetic `YTF_example` and takes about fifteen minutes in total, because steps 3 and 4 refit the models several times. For hindcast validation alone, run step 1 and go to step 4. At the end you have simulated datasets with their truth, a table of bias, RMSE and interval coverage, the prediction scores of both models against a persistence baseline, and a saved fit.

<a id="case-model-validation-section-1"></a>

### 1. 读取输入列表 / Load the input bundle

```r
library(ALSCL)
data("YTF_example")
x <- YTF_example
```

`x` 包含三张调查表和模型设置。只做预测检验时，直接到[第 4 步](#case-model-validation-section-4)：它从 `x` 拟合各个训练窗口，不需要全数据拟合。需要模拟时，继续第 2 步。

`x` contains the three survey tables and the model settings. For hindcast validation alone, continue directly to [step 4](#case-model-validation-section-4): it fits the training windows from `x` and requires no full-data fit. For simulation, continue to step 2.

<a id="case-model-validation-section-2"></a>

### 2. 从拟合生成调查观测 / Generate survey observations from the fit

<a id="case-model-validation-source-fit"></a>

#### 拟合用于模拟的源模型 / Fit the source model for simulation

```r
b <- run_alscl(x, silent = TRUE)
b$diagnostics
stopifnot(b$diagnostics$numerical_ok)
```

`b` 是模拟的起点 ALSCL 拟合。它的 `numerical_ok` 必须为 `TRUE`，因为除非 `allow_failed_fit = TRUE`，`simulate_fit()` 会拒绝未通过数值检查的拟合；若为 `FALSE`，先按[判断拟合是否可用](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics)处理再模拟。教学示例通过 `map` 固定了生长和若干过程参数；用自己的输入列表时，选择有依据的生物学设置（[选择拟合设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting)）。每份模拟 `x` 都保留源拟合实际采用的固定标量值，包括由原始数据推得的 `mean_log_R`。要自行选择某个固定值，在拟合源模型时将它写入 `parameters`。

`b` is the ALSCL fit that the simulations start from. Its `numerical_ok` must be `TRUE`, because `simulate_fit()` rejects a fit that failed the numerical checks unless `allow_failed_fit = TRUE`; if it is `FALSE`, follow [Judge whether a fit can be used](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) before simulating. The teaching example fixes growth and several process parameters through `map`; with your own bundle choose supported biological settings ([Choose the fitting settings](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting)). Each simulated `x` preserves the source fit's effective fixed scalar values, including `mean_log_R` when its value was derived from the original data. To choose a particular fixed value yourself, provide it in `parameters` when fitting the source model.

<a id="case-model-validation-conditional-draws"></a>

#### 保留拟合的种群状态 / Keep the fitted population states

```r
conditional <- simulate_fit(b, nsim = 3, seed = 20261101,
  process = "conditional")
conditional$metadata
conditional$simulations[[1]]$observations[1:3, 1:3]
```

`process = "conditional"` 保持拟合的种群不变，只重新抽取观测误差，是查看同一状态下重复调查的最短路径。`metadata` 记录模型、过程、种子、原始观测掩码、源拟合的状态和假设 `parameter_uncertainty = "none"`。

`process = "conditional"` keeps the fitted population and redraws only the observation error, the shortest way to see repeated surveys of the same states. `metadata` records the model, the process, the seed, the original observation mask, the status of the source fit and the assumption `parameter_uncertainty = "none"`.

<a id="case-model-validation-process-draws"></a>

#### 生成新的种群轨迹 / Generate new population trajectories

```r
resampled <- simulate_fit(b, nsim = 3, seed = 20261101,
  process = "resample")
resampled$simulations[[1]]$truth$SSB
simulated_x <- resampled$simulations[[1]]$x
```

`process = "resample"` 还在拟合的标量参数值下重新抽取补充量、捕捞死亡率和初始丰度的过程偏差：补充量和 F 遵循拟合的平稳 AR(1) 过程（`F_structure = "year"` 时每个时间步一个 F 序列），初始丰度偏差是独立正态抽样，C++ 种群模型把这些抽样变成新的种群。两种模式都围绕拟合的 `Elog_index`、按拟合的观测标准差抽取对数观测，所以 `exp(Elog_index)` 是中位数；标量参数、生物学设置和调查可捕性保持固定，因此两种模式都没有参数不确定性。`$simulations` 的每个元素包含 `observations`（体长组 × 时间步）、`truth`（种群量、标量参数和所用的偏差）和 `x`，后者是可交给 `run_alscl()` 的输入列表，保留 `b` 的拟合配置，但 `output`、`ncores` 和 `silent` 除外，由你在拟合时指定。原始调查的缺失和零值单元保持原样，除非 `preserve_missing = FALSE`；种子让抽样可以重复，结束后恢复调用者的随机数状态。固定或绑定过程偏差的 `map` 会使重抽模式终止，条件抽样仍可使用。若要用有自己补充量假设的操作模型，见[模拟调查数据](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#simulation)。

`process = "resample"` also draws new process deviations of recruitment, fishing mortality and initial abundance at the fitted scalar parameter values: recruitment and F follow the fitted stationary AR(1) processes (one F series per time step under `F_structure = "year"`), the initial-abundance deviations are independent normals, and the C++ population model turns the draws into a new population. Both modes draw log observations around the fitted `Elog_index` with the fitted observation SD, so `exp(Elog_index)` is the median; scalar parameters, biology and survey catchability stay fixed, so neither mode carries parameter uncertainty. Each element of `$simulations` holds `observations` (length bins by time steps), `truth` (population quantities, scalar parameters and the deviations used) and `x`, an input bundle for `run_alscl()` that keeps the fitting configuration of `b` except `output`, `ncores` and `silent`, which you choose when fitting it. Missing and zero cells of the original survey stay as they are unless `preserve_missing = FALSE`; the seed makes the draws repeatable, and the caller's random-number state is restored afterwards. A `map` that fixes or ties the process deviations stops the resample mode, while conditional draws still work. For an operating model with its own recruitment assumptions, use [Simulate survey data](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#simulation).

![给定状态或重新抽取过程后生成的 ALSCL 调查观测 / ALSCL observations simulated conditionally or with resampled processes](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/workflows/fitted-simulation.png?raw=true&v=79b8f645c515)

图中为三个体长组在两种模式下各三次抽样；虚线是拟合的对数中位数。条件抽样围绕相同的拟合状态散布，重抽过程的抽样还会移动轨迹。每条曲线是一次抽样，是生成分布的一个例子。

The figure shows three draws per mode for three length bins; the dashed line is the fitted log median. Conditional draws scatter around the same fitted states, and resampled draws also move the trajectory. Each curve is one draw, an example of the generating distribution.

<a id="case-model-validation-section-3"></a>

### 3. 重新拟合重复数据并与真值比较 / Refit the replicates and compare with the truth

```r
replicate_fits <- lapply(resampled$simulations, function(s) {
  tryCatch(run_alscl(s$x, nstarts = 2, ncores = 1, silent = TRUE),
    error = function(e) list(error = conditionMessage(e)))
})
truth <- lapply(resampled$simulations, function(s) s$truth)
performance <- summarize_simulations(replicate_fits, truth,
  quantities = c("SSB", "Rec"))
performance$replicates
performance$summary
```

每次重新拟合都是对模拟输入列表的普通拟合，这里用 `run_alscl(s$x)`，来自 ACL 拟合的抽样用 `run_acl(s$x)`，各用两个初值；`tryCatch()` 保留失败重复的报错信息，使它留在汇总中。`summarize_simulations()` 按重复名和年份把拟合与真值对齐，返回 `replicates`（每次拟合的数值检查、耗时和报错）和 `summary`（每个量的失败率、偏差、相对偏差、RMSE 和区间覆盖率及其分母）；偏差和 RMSE 使用通过检查的拟合，覆盖率只使用标准误有限的区间（[模拟调查数据](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#simulation-fit)解释了这些分母）。在记录运行中三次重新拟合都通过检查，每次约需三分钟，60 对数值的覆盖率为产卵生物量 1.0、补充量 0.95（[simulation-performance.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/model-validation/simulation-performance.csv)）。三个重复只演示流程；研究偏差或覆盖率需要足够多的重复，失败率才有意义，参数自助法还需要写明重新拟合的规程和区间构造方法，`simulate_fit()` 只提供生成数据这一步。磁盘上已有的重复数据可用 `sim_model()` 批量拟合（[模拟调查数据](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#simulation-fit)）。

Each refit is an ordinary fit of the simulated bundle, `run_alscl(s$x)` here and `run_acl(s$x)` for draws from an ACL fit, with two starts each; `tryCatch()` keeps the error message of a failed replicate so that it stays in the summary. `summarize_simulations()` matches the fits with the truth by replicate name and year and returns `replicates` (numerical checks, time and error of each fit) and `summary` (per quantity: failure rate, bias, relative bias, RMSE and interval coverage with their denominators); bias and RMSE use the fits that passed the checks, and coverage uses only intervals with a finite standard error ([Simulate survey data](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#simulation-fit) explains the denominators). In the recorded run all three refits passed, each taking about three minutes, with coverage 1.0 for spawning biomass and 0.95 for recruitment over 60 pairs ([simulation-performance.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/model-validation/simulation-performance.csv)). Three replicates show the mechanics; a study of bias or coverage needs enough replicates for the failure rate to mean something, and a parametric bootstrap also needs a stated refitting protocol and interval construction, for which `simulate_fit()` supplies only the generating step. For replicates already on disk, `sim_model()` fits them in batch ([Simulate survey data](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#simulation-fit)).

<a id="case-model-validation-section-4"></a>

### 4. 预测未参与拟合的时间步 / Predict time steps withheld from fitting

```r
acl_validation <- hindcast_model(x, model = "acl", horizon = 1,
  nfolds = 2, min_train = 8, nstarts = 1, ncores = 2)
alscl_validation <- hindcast_model(x, model = "alscl", horizon = 1,
  nfolds = 2, min_train = 8, nstarts = 1, ncores = 2)
acl_validation$diagnostics
alscl_validation$diagnostics
acl_validation$scores
alscl_validation$scores
head(alscl_validation$predictions)
```

`hindcast_model()` 就是预测检验：它用截至某个训练起点的时间步拟合每个模型，预测随后 `horizon` 步的调查指数，起点取最后 `nfolds` 个合格起点，每次拟合都从 `x` 和保存的配置重新开始。本例中每个模型先用截至 2017 年的数据预测 2018 年，再用截至 2018 年的数据预测 2019 年。

`hindcast_model()` is the hindcast validation: it fits each model on the time steps up to a training origin and predicts the survey index of the next `horizon` steps, from the last `nfolds` eligible origins, every fit starting afresh from `x` with the stored configuration. Here each model is fitted through 2017 to predict 2018 and through 2018 to predict 2019.

| 设置 / Setting | 在本年度示例中的含义 / Meaning in this annual example |
|---|---|
| `horizon = 1` | 向前预测一个时间步 / Predict one time step ahead |
| `nfolds = 2` | 使用最后两个合格的训练起点 / Use the last two eligible training origins |
| `min_train = 8` | 要求至少八个训练时间步 / Require at least eight training time steps |
| `ncores = 2` | 最多并行运行两个训练折；一折内的初值依次运行 / Run at most two training folds in parallel; the starts inside a fold run one after another |

`horizon` 和 `min_train` 都按时间步计（季度数据就是季度）；每一折截短三张表和随时间变化的 map，固定或绑定过程偏差随时间变化的 `map` 会使调用终止。先读 `$diagnostics`：每折一行，含 `origin`、数值检查、`prediction_ok`、警告和报错；失败的折留在表中，但不产生预测和评分。`$predictions` 列出每个留出单元的观测、预测和持平基准的对数指数，以及是否纳入的标志。

`horizon` and `min_train` count time steps (quarters for quarterly data); each fold truncates the three tables and the time-varying maps, and a `map` that fixes or ties the process deviations over time stops the call. Read `$diagnostics` first: one row per fold with `origin`, the numerical checks, `prediction_ok`, warnings and errors; a fold that failed stays in the table and contributes no predictions or scores. `$predictions` lists every withheld cell with the observed, predicted and persistence log index and an inclusion flag.

![留出的调查指数与模型预测及持平基准 / Withheld survey indices and model and persistence predictions](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/workflows/hindcast-predictions.png?raw=true&v=6808289fa0c6)

图中比较三个体长组留出的对数调查指数、模型预测和持平基准，持平基准是同一体长组最近一次正训练观测保持不变。预测规则是：补充量和 F 的过程偏差从训练末期沿拟合的 AR(1) 条件均值延伸（最后一个偏差乘以 phi 的预测期数次方），种群方程推进丰度，拟合的调查可捕性把它变成调查指数；训练末期的体重和成熟比例只在计算生物量时重复使用。这些是沿条件过程路径的代入式点预测，没有未来扰动、参数抽样或区间。固定值和初值的选择都应在不看留出数据的前提下确定，比较模型时使用相同的起点、预测期数和单元。

The figure compares the withheld log survey indices with the model prediction and the persistence baseline, the latest positive training observation of the same length bin held constant, for three length bins. The prediction rule: the process deviations of recruitment and F continue along their fitted AR(1) conditional means from the training end (the last deviation times phi to the power of the horizon), the population equations advance abundance, and the fitted survey catchability turns it into survey indices; the last training weights and maturity are repeated for the biomass calculation only. These are plug-in point predictions along the conditional process path, without future shocks, parameter draws or intervals. Choose fixed values and starting values without looking at the withheld data, and compare models on the same origins, horizons and cells.

<a id="case-model-validation-section-5"></a>

### 5. 读评分并保存分析 / Read the scores and save the analysis

<a id="case-model-validation-prediction-scores"></a>

#### 把评分和样本数放在一起读 / Read the scores and their sample sizes together

| 输出 / Output | 读法 / How to read it |
|---|---|
| `n_positive`、`n_prediction`、`n` / `n_positive`, `n_prediction`, `n` | 正的留出观测数、其中有模型预测的数量，以及模型和持平基准共同评分的单元数 / Positive withheld observations, those with a model prediction, and cells scored for both model and persistence |
| `log_RMSE`、`log_MAE` / `log_RMSE`, `log_MAE` | 对数指数尺度上的预测误差；在这些单元上越小越好 / Prediction error on the log-index scale; smaller is better on those cells |
| `naive_log_RMSE`、`naive_log_MAE` / `naive_log_RMSE`, `naive_log_MAE` | 同一批单元上持平基准的误差 / The persistence errors on the same cells |
| `log_MASE`、`naive_log_MASE`、`n_scaled` / `log_MASE`, `naive_log_MASE`, `n_scaled` | 缩放后的绝对误差，以及训练期尺度可用的单元数 / Scaled absolute errors and the number of cells with a usable training scale |

评分使用自然对数调查指数；留出观测中的零值和缺失值被排除，模型和持平基准的误差使用相同的单元。MASE 把每个绝对对数误差除以该体长组训练期内相邻正观测的平均绝对变化；没有这样一对观测的体长组没有缩放评分，所以读它之前先看 `n_scaled`。在记录运行中，两个模型对 2018-2019 年相同的 46 个正观测评分，四个训练拟合都通过检查（[hindcast-scores.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/model-validation/hindcast-scores.csv)）：

Scores use natural-log survey indices; zero and missing withheld observations are excluded, and model and persistence errors use the same cells. For MASE each absolute log error is divided by the length bin's mean absolute change between consecutive positive training observations; a bin without such a pair gets no scaled score, so check `n_scaled` before reading it. In the recorded run both models scored the same 46 positive observations of 2018-2019 and all four training fits passed the checks ([hindcast-scores.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/model-validation/hindcast-scores.csv)):

| 预测 / Prediction | 评分观测数 / Scored observations | 对数 RMSE / Log RMSE | 对数 MAE / Log MAE | 对数 MASE / Log MASE |
|---|---:|---:|---:|---:|
| ACL | 46 | 0.096 | 0.080 | 0.42 |
| ALSCL | 46 | 0.26 | 0.20 | 1.07 |
| 持平基准 / Persistence | 46 | 0.17 | 0.15 | 0.74 |

在这份模拟数据、教学 map 和两个起点下，ACL 的预测好于持平基准，ALSCL 差于基准，尽管两者的优化都收敛了：这个差异值得追查，而两个检验时间步给不出模型的一般排序。

On this synthetic dataset, with the teaching maps and two origins, ACL predicts better than persistence and ALSCL worse, although both optimizations converged: a difference worth investigating, while two validation time steps give no general ranking of the models.

<a id="case-model-validation-save-record"></a>

#### 保存预测检验结果 / Save the validation results

```r
validation_file <- tempfile(fileext = ".rds")
saveRDS(list(acl = acl_validation, alscl = alscl_validation),
  validation_file)
```

预测检验结果是普通列表，`saveRDS()` 将两个模型的结果保存在一起。将临时路径换成永久文件即可。只做预测检验的操作到此完成。

The validation results are plain lists, so `saveRDS()` keeps both models together. Replace the temporary path with a permanent file. This completes the hindcast-only route.

<a id="case-model-validation-simulation-archive"></a>

#### 模拟后保存源拟合 / Save the source fit after simulation

若在第 2 步拟合了 `b`，运行下面的代码。只做了预测检验时，继续到[下一步](#case-model-validation-next)。

Run this block if you fitted `b` in step 2. If you only ran hindcast validation, continue to [What next](#case-model-validation-next).

```r
archive <- tempfile(fileext = ".rds")
save_assessment(b, archive)
saved <- read_assessment(archive)
saved$recipe$implementation
again <- simulate_fit(saved, nsim = 1, seed = 20261101,
  process = "conditional")
```

`save_assessment()` 保存拟合结果时去掉只在当前会话有效的 TMB 对象，`simulate_fit()` 接受 `read_assessment()` 读回的结果，所以新会话无需重新拟合即可模拟；相同种子给出相同抽样。`saved$recipe$implementation` 记录包版本、源码修订和模型源码哈希，`refit_model()` 会与当前安装比较，有差异就警告。把模拟对象和真值与这个拟合一起永久保存。

`save_assessment()` writes the saved fit without the live TMB object, and `simulate_fit()` accepts what `read_assessment()` returns, so a new session can simulate without refitting; the same seed gives the same draws. `saved$recipe$implementation` records the package versions, the source revision and the hashes of the model source, which `refit_model()` compares with the current installation, warning on a difference. Keep the simulation objects and truth beside this fit in permanent files.

<a id="case-model-validation-next"></a>

### 下一步 / What next

| 想做什么 / What you want to do | 阅读 / Read |
|---|---|
| 检查源拟合的残差规律 / Examine residual patterns of the source fit | [判断拟合是否可用](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) / [Judge whether a fit can be used](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) |
| 看去掉近期时间步后估计如何变化 / See how the estimates change when recent time steps are removed | [移除近期数据后，估计结果会怎样变化？](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md#case-retrospective-bias) / [Do estimates change when recent data are removed?](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md#case-retrospective-bias) |
| 检验对固定值的敏感性 / Test the sensitivity to the fixed values | [评估对假设有多敏感，未来 F 情景会怎样改变结果？](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md#case-sensitivity-projection) / [How sensitive is the assessment, and what happens under future F?](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md#case-sensitivity-projection) |
| 批量拟合多次模拟重复 / Fit many simulated replicates in batch | [模拟调查数据](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#simulation-fit) / [Simulate survey data](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#simulation-fit) |
| 重新生成本页的图和表 / Regenerate the figures and tables of this page | 在仓库根目录运行 `pkgload::load_all("."); source("scripts/model_validation.R"); run_model_validation_guide()` / From the repository root: `pkgload::load_all("."); source("scripts/model_validation.R"); run_model_validation_guide()` |

<a id="chapter-18"></a>
## 18 工作案例 · Worked cases

<!-- Generated by scripts/build_manual.py from website/content/{en,zh}/articles/. Edit the article pair, not this file. -->

[使用指南 / User guide](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md) · [首页 / Home](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/README.md)

## 如何拟合自己的调查数据？ / How do I fit my own survey data?

本页带你从 CSV 或 Excel 文件中的三张调查表出发，得到 ACL 和 ALSCL 两个拟合好的模型，以及它们的数值检查、图和保存的结果。本页按照脚本 [fit_own_data_example.R](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/scripts/fit_own_data_example.R) 展开，该脚本用内附的教学数据完整运行一遍，然后你把其中的数值换成自己的。你需要已安装 ALSCL 2.4.0 或更高版本（[安装 ALSCL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#start)）、按[准备调查数据](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel)排好的三张表，以及你的种群的生物学数值（`rec.age`、`nage`、`M`、`sel_L50`、`sel_L95`、`growth_step`、`len_mid`、`len_border`），[该页第 4 步](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#data-preparation-bundle)逐项解释了它们。

On this page you go from three survey tables in CSV or Excel files to two fitted models, ACL and ALSCL, with their numerical checks, plots and saved results. The page follows the script [fit_own_data_example.R](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/scripts/fit_own_data_example.R), which runs the whole sequence on the bundled teaching data; you then replace its values with yours. You need ALSCL 2.4.0 or later installed ([Install ALSCL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#start)), your tables laid out as in [Prepare your survey data](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel), and the biological values of your stock (`rec.age`, `nage`, `M`, `sel_L50`, `sel_L95`, `growth_step`, `len_mid`, `len_border`), which [step 4 of that page](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#data-preparation-bundle) explains one by one.

<a id="case-fit-survey-bundle"></a>

### 1. 准备并检查输入列表 / Prepare and check the input bundle

```r
library(ALSCL)
tables <- read_survey_csv("my_data")
x <- prepare_alscl_data(tables, fit_args = list(
  rec.age = 1, nage = 15, M = 0.2, sel_L50 = 15, sel_L95 = 20,
  growth_step = 1, len_mid = seq(6, 50, 2), len_border = seq(7, 49, 2)))
check <- check_alscl_data(x, "acl")
check$valid
check$summary
```

两个模型都读取输入列表 `x`：调查指数表 `data.CatL`、体重表 `data.wgt` 和成熟比例表 `data.mat`，行是体长组，列是时间步；再加上 `x$fit_args` 中描述你的种群和调查的设置。`read_survey_csv()` 从一个文件夹读取三个文件，`read_survey_excel()` 读取一个工作簿中的三张工作表；表格布局、时间网格以及空白和零值的处理见[准备调查数据](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel)。这些设置是模型照原样使用的输入；请为你的种群逐项提供，并记下来源。代码中的数值是教学数据的设置。

Both models read the input bundle `x`: the survey index table `data.CatL`, the weight table `data.wgt` and the maturity table `data.mat`, with the length bins as rows and the time steps as columns, plus the settings in `x$fit_args` that describe your stock and survey. `read_survey_csv()` reads the three files from one folder and `read_survey_excel()` the three sheets of one workbook; [Prepare your survey data](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#excel) explains the layout, the time grid and the treatment of blanks and zeros. The settings are inputs that the models use as given; supply each one for your stock and record its source. The numbers in the code are those of the teaching data.

`check_alscl_data()` 按拟合时的方式准备数据，但不编译任何东西。`check$valid` 应为 `TRUE`，`check$summary` 应显示你预期的体长组数和时间步数、正观测数，以及将被估计的标量参数个数 `free_fixed`。若 `check$valid` 为 `FALSE`，`check$errors` 会指出要修改的表、时间列或设置；`check$warnings` 提示没有任何观测的时间步或体长组。拟合 ALSCL 之前，用 `"alscl"` 再检查一遍。

`check_alscl_data()` prepares the data as a fit would, without compiling anything. `check$valid` should be `TRUE` and `check$summary` should show the numbers of bins and time steps you expect, the count of positive observations and `free_fixed`, the number of scalar parameters that will be estimated. When `check$valid` is `FALSE`, `check$errors` names the table, time column or setting to correct; `check$warnings` points to time steps or bins without any observation. Repeat the check with `"alscl"` before fitting that model.

<a id="case-fit-survey-map"></a>

### 2. 确定初值和 map / Decide the starting values and the map

```r
plan <- inspect_parameters(x, "acl")
plan[, c("parameter", "status", "map_source", "natural_start")]
inspect_parameters(x, "alscl")[, c("parameter", "status", "map_source", "natural_start")]
```

`inspect_parameters()` 列出一个模型的各个参数、自然尺度上的初值及其状态，例如 `free`（估计）、`fixed`（固定）或 `tied`（共享）；`map_source` 说明固定状态来自模型默认还是你的 `map`。默认情况下，ACL 固定 `log_std_log_F`、`logit_log_F_y`、`logit_log_F_a` 和 `t0`，估计其余 10 个标量参数；ALSCL 固定 `log_sigma_log_F` 和 `log_t0`，估计 13 个。过程偏差 `dev_log_R`、`dev_log_F` 和 `dev_log_N0` 默认作为随机效应估计；`map` 可以固定某些偏差，或让它们共享一个估计值。修改 map 后，用 `inspect_parameters()` 检查它们的 `n_free`、`n_fixed` 和 `n_tied` 数量。[选择拟合设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting-controls-parameters)列出了两个模型的全部标量参数。

`inspect_parameters()` lists the parameters of a model with their starting value on the natural scale and their status, such as `free` (estimated), `fixed` or `tied`; `map_source` says whether a fixed status comes from the model default or from your `map`. By default ACL fixes `log_std_log_F`, `logit_log_F_y`, `logit_log_F_a` and `t0` and estimates the other 10 scalar parameters; ALSCL fixes `log_sigma_log_F` and `log_t0` and estimates 13. The process deviations `dev_log_R`, `dev_log_F` and `dev_log_N0` are estimated as random effects by default; `map` can fix individual deviations or tie them together. Check their `n_free`, `n_fixed` and `n_tied` counts with `inspect_parameters()` after changing a map. [Choose the fitting settings](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting-controls-parameters) names every scalar parameter of both models.

初值写在 `x$fit_config$acl$parameters` 或 `x$fit_config$alscl$parameters` 中，采用优化器尺度：渐近体长 60 cm 写 `log_Linf = log(60)`，相关系数 0.1 写 `logit_log_R = qlogis(0.1)`；ALSCL 使用 `log_t0`，因此它的 `t0` 必须在 0 和 `rec.age` 之间。填写初值不会固定参数：只有模型 `map` 中的 `factor(NA)` 才固定参数，具名 `NULL` 项则释放模型默认固定的参数。当外部研究给出的值比拟合更可靠，或第 5 步的检查表明数据无法确定某个参数时，固定该参数，并记录每个固定值的来源。[选择拟合设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting)给出 `map`、边界和物种预设的规则；[估计参数列表](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting)给出全部变换方式。

Starting values go in `x$fit_config$acl$parameters` or `x$fit_config$alscl$parameters` on the optimizer scale: `log_Linf = log(60)` for an asymptotic length of 60 cm, `logit_log_R = qlogis(0.1)` for a correlation of 0.1; ALSCL uses `log_t0`, so its `t0` must lie between 0 and `rec.age`. A starting value does not fix a parameter: only `factor(NA)` in the model's `map` does, and a named `NULL` entry releases a parameter that the model fixes by default. Fix a parameter when an external study gives a better value than the fit could, or when the checks of step 5 show that the data leave it undetermined, and record the source of every fixed value. [Choose the fitting settings](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) gives the rules for `map`, bounds and species presets; [Estimation parameter lists](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) gives every transformation.

<a id="case-fit-survey-run"></a>

### 3. 运行完整示例 / Run the complete example

下面的脚本用教学数据完整运行每一步：读取 `docs/data` 中的三个 CSV 文件，把生物学设置收在 `bio` 中，由行标签推出体长组中点和边界，设置两个模型的初值和 map，组装并检查 `x`，拟合 ACL（`a`）和 ALSCL（`b`），打印它们的数值检查，绘制 `b` 的残差图和产卵生物量图，并把输入列表、去掉 TMB 对象的两个拟合、两张图和会话信息保存到 `output/own-data-example`。请在下载的仓库根目录运行，因为脚本要加载 `scripts/plot_helpers.R` 并读取 `docs/data`：`source("scripts/fit_own_data_example.R", encoding = "UTF-8")`。

The script below runs every step on the teaching data: it reads the three CSV files in `docs/data`, collects the biology in `bio`, derives the bin midpoints and boundaries from the row labels, sets the starting values and maps of both models, builds and checks `x`, fits ACL (`a`) and ALSCL (`b`), prints their numerical checks, draws the residual and spawning biomass plots of `b`, and saves the bundle, both fits without their live TMB object, the two figures and the session information to `output/own-data-example`. Run it from the root of a downloaded copy of the repository, because it sources `scripts/plot_helpers.R` and reads `docs/data`: `source("scripts/fit_own_data_example.R", encoding = "UTF-8")`.

```r
# ALSCL: CSV -> x -> ACL / ALSCL -> diagnostics and saved summaries.
# 从仓库根目录运行 / Run from the repository root: / Run from the repository root:
# source("scripts/fit_own_data_example.R", encoding = "UTF-8")
# 默认读取内附模拟数据。正式分析必须修改第 1、2、3 步。 / The supplied numbers describe the synthetic YTF example, not your stock.

library(ALSCL)
if (packageVersion("ALSCL") < "2.4.0")
  stop("This example requires ALSCL >= 2.4.0. Update ALSCL before running it.", call. = FALSE)
source('scripts/plot_helpers.R')

# Read the three aligned tables -------------------------------
# 1. 读取三表 / Read the three aligned tables ------------------------------- / data.CatL.csv, data.wgt.csv, data.mat.csv.
data_dir <- "docs/data"
inputs <- read_survey_csv(data_dir)
# Excel alternative (requires readxl):
# inputs <- read_survey_excel("my_survey.xlsx")

# inputs <- read_survey_excel("my_survey.xlsx") / Shared biology -----------------------------------------
# M_annual and vbk are annual; lengths are cm; weights in the example are kg.
bio <- list(rec.age = 1, nage = 15, M_annual = 0.2,
            growth_step = 1, sel_L50 = 15, sel_L95 = 20,
            Linf = 60, vbk = 0.2, t0 = 1 / 60,
            cv_len = 0.2, cv_grow = 0.2)
stopifnot(bio$t0 > 0, bio$t0 < bio$rec.age)

# For labels such as "5-7", supply the actual midpoints explicitly instead.
len_mid <- as.numeric(inputs$data.CatL[[1]])
stopifnot(all(is.finite(len_mid)), all(diff(len_mid) > 0))
# This midpoint formula is only used for the equal-width demonstration bins.
stopifnot(max(abs(diff(len_mid) - diff(len_mid)[1])) < 1e-8)
len_border <- (head(len_mid, -1) + tail(len_mid, -1)) / 2

# Model-specific settings ------------------------------
# 此例为连续等宽组；非等宽组请直接填写实测的 nlen-1 个内部边界。 / Growth and most process values below are starts, not automatic fixes.
# This midpoint formula is only used for the equal-width demonstration bins. / Review starts, bounds and the documented default fixed values for your stock.
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
# Default maps: ACL fixes 4 and estimates 10 scalars; ALSCL fixes 2 and estimates 13.
# ACL fixes log_std_log_F, logit_log_F_y, logit_log_F_a and t0.
# ALSCL fixes log_sigma_log_F and log_t0. These values still need justification.
map_acl <- list()
map_alscl <- list()
# Optional: fix only t0; diagnose this more flexible configuration separately.
# map_acl <- list(t0 = factor(NA), log_std_log_F = NULL,
# 使用模型默认 map：ACL 固定 4 项、估计 10 项；ALSCL 固定 2 项、估计 13 项。 / logit_log_F_y = NULL, logit_log_F_a = NULL)
# Default maps: ACL fixes 4 and estimates 10 scalars; ALSCL fixes 2 and estimates 13. / map_alscl <- list(log_t0 = factor(NA), log_sigma_log_F = NULL)
# ACL fixes log_std_log_F, logit_log_F_y, logit_log_F_a and t0. / Preserve a named NULL to release a default fix; $t0 <- NULL deletes the entry.
# ALSCL fixes log_sigma_log_F and log_t0. These values still need justification. / map_acl["t0"] <- list(NULL)
# map_alscl["log_t0"] <- list(NULL)

# 可选：只固定 t0；更灵活的设置必须另做诊断，不保证可识别。 / Assemble and check the input bundle --------------------
x <- prepare_alscl_data(inputs,
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
# Check data, time grid and settings without compiling.
for (model in c("acl", "alscl")) {
  check <- check_alscl_data(x, model)
  if (!check$valid) stop(paste(check$errors, collapse = "\n"))
  print(check$summary)
}

# Fit directly ----------------------------------------------
alscl_speed_info()
a <- run_acl(x)
b <- run_alscl(x)
# a <- run_acl(x, nstarts = 4, ncores = 2)
# b <- run_alscl(x, nstarts = 4, ncores = 2)

# Inspect, plot and save ------------------------------
checks <- list(ACL = diagnose_model(x$data.CatL, a),
               ALSCL = diagnose_model(x$data.CatL, b))
print(checks)
print(a$sd_info)
print(b$sd_info)
for (fit in list(a, b)) {
  print(fit$par_low_up) # Actual free scalars and bounds
  print(list(convergence = fit$convergence_code,
             max_gradient = fit$max_abs_gradient,
             pdHess = fit$pdHess, bound_hit = fit$bound_hit))
  print(fit$refinement)
  print(fit$diagnostics)
  if (!isTRUE(fit$convergence_code == 0L) || !isTRUE(fit$pdHess) ||
      !isTRUE(fit$diagnostics$numerical_ok))
    warning("Review fit diagnostics before interpreting this assessment.")
}
residual_plot <- plot_residuals(b, facet_by = "year", facet_ncol = 4,
                                x_breaks = pretty(len_mid, n = 4))
# 实际自由参数及边界 / Actual free scalars and bounds / Omit SE intervals if Hessian is not positive definite.
ssb_plot <- plot_SSB(b, se = isTRUE(b$pdHess))
print(residual_plot)
print(ssb_plot)
portable <- function(fit) fit[setdiff(names(fit), "obj")]
output_dir <- "output/own-data-example"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
save_grid_free_plot(file.path(output_dir, "residuals.png"), residual_plot,
                width = 10, height = 8, dpi = 150)
save_grid_free_plot(file.path(output_dir, "SSB.png"), ssb_plot,
                width = 8, height = 5, dpi = 150)
saveRDS(x, file.path(output_dir, "inputs_x.rds"))
saveRDS(list(ACL = portable(a), ALSCL = portable(b), diagnostics = checks),
        file.path(output_dir, "assessment_summary.rds"))
writeLines(capture.output(sessionInfo()), file.path(output_dir, "sessionInfo.txt"))
# Refit in a new session:
# obj 是当前会话的 TMB 指针，不包含在可移植结果中。 / x <- readRDS("output/own-data-example/inputs_x.rds")
# b <- run_alscl(x)
```

脚本运行时会打印两个模型的 `check$summary`；教学数据显示 23 个体长组、20 个时间步、460 个正观测、没有零值和空白，以及 10 个（ACL）或 13 个（ALSCL）自由标量参数。随后 `diagnose_model()` 打印每个拟合的数值检查，第 5 步会解释。在记录运行（[own-data-example-checks.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/own-data-example-checks.csv)）中，两个拟合的收敛码都是 0，Hessian 正定，没有参数落在边界上，最大梯度约为 3e-9。脚本保存的两张图如下：

While the script runs, `check$summary` is printed for both models; with the teaching data it shows 23 length bins, 20 time steps, 460 positive observations, no zeros or blanks, and 10 (ACL) or 13 (ALSCL) free scalar parameters. `diagnose_model()` then prints the numerical checks of each fit, which step 5 explains. In the recorded run ([own-data-example-checks.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/own-data-example-checks.csv)) both fits ended with convergence code 0, a positive definite Hessian, no parameter on a bound and a maximum gradient near 3e-9. The script saved these two figures:

![完整示例的 ALSCL 逐年残差 / ALSCL residuals by year from the complete example](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/own-data-example/residuals.png?raw=true&v=98ba5bb537a3)

![完整示例的 ALSCL 产卵生物量 / ALSCL spawning biomass from the complete example](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/own-data-example/SSB.png?raw=true&v=72263b7e8ee0)

每一年的残差都围绕 0 散布，产卵生物量序列的区间较窄，这就是这组模拟数据上可用拟合的样子；区间以固定值为条件。若脚本提示 "This example requires ALSCL >= 2.4.0"，安装当前版本（[安装 ALSCL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#start)）；若找不到 `scripts/plot_helpers.R` 或 `docs/data`，说明 R 运行在仓库根目录之外；若 `check_alscl_data()` 报错，第 1 步解释了这些信息；若拟合结束时出现 "Review fit diagnostics" 警告，第 5 步说明要改什么。

Residuals scattered around zero in every year, and a spawning biomass series with a narrow interval, are what a usable fit of these synthetic data looks like; the interval is conditional on the fixed values. If the script reports "This example requires ALSCL >= 2.4.0", install the current version ([Install ALSCL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#start)); if it fails to find `scripts/plot_helpers.R` or `docs/data`, R is running outside the repository root; if `check_alscl_data()` reports an error, step 1 explains the messages; if a fit ends with the warning "Review fit diagnostics", step 5 says what to change.

<a id="case-fit-survey-replace"></a>

### 4. 换成自己的观测数据 / Replace the demonstration with your observations

```r
data_dir <- "my_data"
bio <- list(rec.age = 2, nage = 12, M_annual = 0.25,
            growth_step = 1, sel_L50 = 22, sel_L95 = 30,
            Linf = 80, vbk = 0.15, t0 = 0.5,
            cv_len = 0.15, cv_grow = 0.15)
len_mid <- c(8, 11, 14, 17, 20, 24, 28, 33, 39, 46)
len_border <- c(9.5, 12.5, 15.5, 18.5, 22, 26, 30.5, 36, 42.5)
map_acl <- list(log_Linf = factor(NA), log_vbk = factor(NA))
map_alscl <- list(log_Linf = factor(NA), log_vbk = factor(NA))
# 然后运行脚本中的 prepare_alscl_data() 调用，并确认： / Then run the prepare_alscl_data() call of the script and confirm:
for (model in c("acl", "alscl")) {
  check <- check_alscl_data(x, model)
  print(check$valid); print(check$warnings); print(check$summary)
  print(inspect_parameters(x, model)[, c("parameter", "status", "map_source")])
}
```

上面的数值只是说明每一项的形式；请把每一项都换成你的种群的数值。保留 `inputs`、`x`、`a` 和 `b` 这些名字，脚本的其余部分就不用改。

The values above only show the shape of each entry; replace every one with the value for your stock. Keep the names `inputs`, `x`, `a` and `b` so that the rest of the script runs unchanged.

| 脚本中的行 / Lines in the script | 改成 / Replace with | 注意 / Keep in mind |
|---|---|---|
| `data_dir <- "docs/data"` | 你的 CSV 文件夹，或 `inputs <- read_survey_excel("my_survey.xlsx")` / Your CSV folder, or `inputs <- read_survey_excel("my_survey.xlsx")` | 三个文件或工作表必须使用这些名称；调查缺测留空 / Three files or sheets with exactly these names; blank cells for missing survey values |
| `bio <- list(...)` | 你的种群的数值 / The values of your stock | `M_annual` 是年值，会乘以 `growth_step`；`vbk` 仍按年计；ALSCL 要求 `0 < t0 < rec.age` / `M_annual` is per year and is multiplied by `growth_step`; `vbk` stays per year; ALSCL needs `0 < t0 < rec.age` |
| `len_mid <- ...`、`len_border <- ...` / `len_mid <- ...`, `len_border <- ...` | 你的体长组中点和内部边界 / The midpoints and internal boundaries of your bins | 体长组宽度不等时，删除等宽 `stopifnot()` 和中点公式那两行 / Delete the equal-width `stopifnot()` and the midpoint formula when your bins differ in width |
| `p_acl`、`p_alscl` / `p_acl`, `p_alscl` | 优化器尺度上的初值 / Starting values on the optimizer scale | ACL 填 `t0`，ALSCL 填 `log(t0)` / ACL takes `t0`, ALSCL `log(t0)` |
| `map_acl`、`map_alscl` / `map_acl`, `map_alscl` | 你要固定或释放的参数 / The parameters you fix or release | 空列表沿用模型默认；每次都列出全部固定项 / An empty list keeps the model defaults; list every fix each time |
| `zero_action = "error"` | `"missing"`，把零值当作缺失而不是终止 / `"missing"` to treat zeros as missing values instead of stopping | 零值随后不进入似然 / Zeros then drop out of the likelihood |
| `output_dir` | 本次评估的文件夹 / A folder for this assessment | 脚本会覆盖其中的文件 / The script overwrites the files in it |

修改后，把脚本运行到检查循环。两个模型的 `check$valid` 都必须为 `TRUE`，`check$summary` 必须显示你的体长组数和时间步数，`inspect_parameters()` 中状态为 `fixed` 且 `map_source` 为 `explicit` 的参数必须恰好是你固定的那些。类似 "No positive observations in periods: 2004" 的警告表示某个时间步没有调查值，按未观测处理；`zero_action = "missing"` 且调查表含零值时，会出现零值被排除的警告。拟合之前，先想清楚每条警告对你的调查意味着什么。

After editing, run the script down to the check loop. `check$valid` must be `TRUE` for both models, `check$summary` must show your numbers of bins and time steps, and `inspect_parameters()` must show `fixed` with `map_source` equal to `explicit` for exactly the parameters you fixed. A warning such as "No positive observations in periods: 2004" means that a time step has no survey values and is treated as unobserved; the warning about excluded zeros appears when `zero_action = "missing"` and the survey table contains zeros. Decide what each warning means for your survey before you fit.

<a id="case-fit-survey-fit"></a>

### 5. 直接拟合并读结果 / Fit directly and read the results

```r
a <- run_acl(x)
b <- run_alscl(x)
diagnose_model(x$data.CatL, a)
diagnose_model(x$data.CatL, b)
b$diagnostics$issues
estimates <- extract_estimates(b)
subset(estimates, quantity == "SSB")
extract_parameters(b)
plot_CatL(b, facet_by = "year", facet_ncol = 5)
plot_residuals(b, facet_by = "year", facet_ncol = 5)
plot_SSB(b, se = TRUE)
```

`x` 装好你的表和设置后，每个模型的拟合就是一次调用；脚本存入 `x$fit_args` 的 `train_times = 2` 和 `nstarts = 1` 随之生效，调用中给出的参数，例如 `run_acl(x, nstarts = 4, ncores = 2)`，只在本次调用中覆盖保存的值。看任何估计值之前先读数值检查：收敛码 0、最大梯度小于 0.001、Hessian 正定、没有参数落在边界上，以及 `numerical_ok` 为 `TRUE`；`b$diagnostics$issues` 给出未通过的项目。`extract_estimates()` 返回一张表，包含 `quantity`、`year`、该量所在的 `age` 或 `length`（如有）、`estimate`、`std_error` 和区间 `conf_low` 到 `conf_high`；`extract_parameters()` 列出每个标量参数在自然尺度上的值及其状态 `estimated`、`fixed` 或 `inactive`（共用 F 结构用不到的相关系数）。`plot_CatL()`、`plot_residuals()` 和 `plot_SSB()` 分别画出对观测的拟合、对数残差和带区间的产卵生物量，与[理解第一次拟合](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin)中相同。

Once `x` holds your tables and settings, each fit is one call; the `train_times = 2` and `nstarts = 1` that the script stores in `x$fit_args` apply, and an argument in the call, such as `run_acl(x, nstarts = 4, ncores = 2)`, overrides the stored value for that call only. Read the numerical checks before any estimate: convergence code 0, maximum gradient below 0.001, a positive definite Hessian, no parameter on a bound and `numerical_ok` equal to `TRUE`; `b$diagnostics$issues` names any check that failed. `extract_estimates()` returns one table with `quantity`, `year`, the `age` or `length` where the quantity has one, `estimate`, `std_error` and the interval `conf_low` to `conf_high`; `extract_parameters()` lists every scalar parameter on the natural scale with its status, `estimated`, `fixed` or `inactive` (a correlation that the shared F structure leaves unused). `plot_CatL()`, `plot_residuals()` and `plot_SSB()` draw the fit to the observations, the log residuals and the spawning biomass with its interval, as in [Understand your first fit](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#builtin).

检查未通过时，每次只改一处再重新拟合：收敛码不是 0 或梯度很大时，多用几个初值（`nstarts = 4, ncores = 2`）；Hessian 检查未通过时，固定一个参数或改用 `F_structure = "year"`；[理解第一次拟合](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#first-model-checks)中的表把每项未通过的检查对应到常见原因。即使检查通过，相邻体长或相邻年份的残差同号成串也说明模型漏掉了数据中的某种特征；[判断拟合是否可用](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics)说明如何检查这类规律，以及对 `M` 和其他固定值的敏感性。

When a check fails, change one thing at a time and refit: more starts (`nstarts = 4, ncores = 2`) when the code differs from 0 or the gradient is large, a fixed parameter or `F_structure = "year"` when the Hessian check fails; the table in [Understand your first fit](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#first-model-checks) matches each failed check with its usual cause. Residuals with the same sign across neighbouring lengths or years mean that the model misses a feature of the data even when the checks pass; [Judge whether a fit can be used](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) shows how to examine such patterns and the sensitivity to `M` and the other fixed values.

<a id="case-fit-survey-save"></a>

### 6. 保存并复用结果 / Save and reuse the results

```r
dir.create("output/my-assessment", recursive = TRUE, showWarnings = FALSE)
saveRDS(x, "output/my-assessment/inputs_x.rds")
save_assessment(a, "output/my-assessment/acl.rds")
save_assessment(b, "output/my-assessment/alscl.rds")
# 在以后的会话中 / In a later session
x <- readRDS("output/my-assessment/inputs_x.rds")
saved <- read_assessment("output/my-assessment/alscl.rds")
summary(saved)
plot_SSB(saved, se = TRUE)
b2 <- refit_model(saved)
```

`x` 是普通列表，`saveRDS()` 保存表和设置，`readRDS()` 把它们读回。`save_assessment()` 写出保存的拟合结果：拟合中除 `b$obj` 以外的全部内容（`b$obj` 是只在当前会话有效的 TMB 对象指针），加上配方（数据表、设置、map、边界和软件包版本）。`read_assessment()` 把它读回，`summary()`、提取函数和绘图函数都能直接使用；`refit_model()` 按配方重建可执行的拟合，接受 `refit_model(saved, nstarts = 4)` 这样的覆盖参数，并在软件包或 TMB 版本与记录不同时发出警告。文件夹必须已存在，已有文件只有在 `overwrite = TRUE` 时才被替换。脚本则保存 `assessment_summary.rds`，即去掉 `obj` 的两个拟合，以及两张图和 `sessionInfo.txt`。把数据文件、保存的输入列表和保存的拟合结果放在一起。

`x` is a plain list, so `saveRDS()` keeps the tables and settings and `readRDS()` brings them back. `save_assessment()` writes a saved fit: everything in the fit except the live TMB object `b$obj`, a pointer valid only in the current session, together with the recipe (tables, settings, map, bounds and package versions). `read_assessment()` reads it back, and `summary()`, the extraction functions and the plots work on it directly; `refit_model()` rebuilds a live fit from the recipe, accepts overrides such as `refit_model(saved, nstarts = 4)`, and warns when the package or TMB version differs from the recorded one. The folder must exist, and an existing file is replaced only with `overwrite = TRUE`. The script instead stores `assessment_summary.rds`, both fits without `obj`, with the two figures and `sessionInfo.txt`. Keep the data files, the saved bundle and the saved fits together.

<a id="case-fit-survey-continue"></a>

### 7. 继续比较和回溯 / Continue with comparison and retrospectives

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

`compare_models()` 先核对两次拟合使用了同一张调查表，再比较 AIC、BIC 和拟合统计量。`comparison$comparison` 记录 `data_verified`、`eligible`（两次拟合都通过数值检查）、`preferred`（AIC 较低的模型，仅在两者都合格时给出）和 `issues`。AIC 较低只说明该模型在统计上更贴合这些数据；它的结构是否适合这个种群，要用生物学知识判断。[ACL 与 ALSCL 的评估结果有什么不同？](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md#case-compare-assessments)用图继续这一比较。

`compare_models()` first verifies that both fits used the same survey table, then compares AIC, BIC and the fit statistics. `comparison$comparison` records `data_verified`, `eligible` (both fits passed the numerical checks), `preferred` (the model with the lower AIC, given only when both are eligible) and `issues`. A lower AIC supports a model statistically on these data; whether its structure suits the stock is a biological decision. [Do ACL and ALSCL give different answers?](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md#case-compare-assessments) continues the comparison with figures.

回溯分析依次去掉最后 1、2、3 个时间步后重新拟合模型（`nyear` 以时间步计，季度数据四轮等于一年）。它读取输入列表，因此保存的设置对每一轮都生效；在回溯调用中设置 `ncores` 可以并行运行各轮。`rb$fit_diagnostics` 列出完整拟合（`Peel = 0`）和每一轮的数值检查，`rb$rho_by_peel` 给出每个量、每一轮的 Mohn's rho，`rb$rho_text$Rho` 只在完整拟合和所有轮次都通过检查时报告均值，否则为 `NA` 并警告。`plot_retro(rb)` 画出各轮的序列（[运行回溯分析](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#retrospective)）；`plot_fishing_mortality(b, type = "length")` 画出 ALSCL 估计的体长别捕捞死亡率。

The retrospective analysis refits a model after removing the last one, two and three time steps (`nyear` counts time steps, so four peels equal one year of quarterly data). It reads the bundle, so the stored settings apply to every peel; set `ncores` on the retrospective call to run peels in parallel. `rb$fit_diagnostics` lists the full fit (`Peel = 0`) and every peel with its numerical checks, `rb$rho_by_peel` gives Mohn's rho per quantity and peel, and `rb$rho_text$Rho` reports the mean only when the full fit and all peels pass the checks, otherwise `NA` with a warning. `plot_retro(rb)` draws the peeled series ([Run a retrospective analysis](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#retrospective)); `plot_fishing_mortality(b, type = "length")` draws the fishing mortality at length estimated by ALSCL.

<a id="case-fit-survey-next"></a>

### 下一步 / What next

| 想做什么 / What you want to do | 阅读 / Read |
|---|---|
| 修改检查指出的设置，或更换 F 结构 / Change a setting that a check pointed to, or the F structure | [选择拟合设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) / [Choose the fitting settings](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting) |
| 检查残差规律和对固定值的敏感性 / Examine residual patterns and the sensitivity to the fixed values | [判断拟合是否可用](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) / [Judge whether a fit can be used](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) |
| 用图比较两个拟合 / Compare the two fits with figures | [ACL 与 ALSCL 的评估结果有什么不同？](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md#case-compare-assessments) / [Do ACL and ALSCL give different answers?](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md#case-compare-assessments) |
| 运行回溯分析并读 Mohn's rho / Run a retrospective analysis and read Mohn's rho | [运行回溯分析](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#retrospective) / [Run a retrospective analysis](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#retrospective) |
| 做参数剖面或向前投影 / Profile a parameter or project the stock forward | [评估工作流](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ASSESSMENT_WORKFLOWS.md) / [Assessment workflows](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ASSESSMENT_WORKFLOWS.md) |
| 拟合季度调查 / Fit a quarterly survey | [年度与季度时间步](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASE_STUDIES.md) / [Annual and quarterly time steps](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASE_STUDIES.md) |
| 让拟合更快 / Make fits faster | [速度设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/SPEED_GUIDE.md) / [Speed settings](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/SPEED_GUIDE.md) |

<a id="case-compare-assessments"></a>
### ACL 与 ALSCL 的评估结果有什么不同？ / Do ACL and ALSCL give different answers?

本页带你对同一组模拟 YTF 观测拟合 ACL 和 ALSCL，看两种种群结构在哪些方面一致、在哪些方面不同。你需要已安装的软件包（[安装 ALSCL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#start)）；`YTF_example` 提供数据表、生物学设置和两个模型的固定参数，因此这一比较以这些教学数值为条件。结束时你会有比较表、四张图和一个保存文件夹。

On this page you fit ACL and ALSCL to the same synthetic YTF observations and see where the two population structures agree and where they differ. You need the package installed ([Install ALSCL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#start)); `YTF_example` supplies the tables, the biology and the fixed parameters of both models, so the comparison is conditional on those teaching values. At the end you have comparison tables, four figures and a saved folder.

<a id="case-compare-assessments-fit"></a>

#### 1. 对同一组观测拟合两个模型 / Fit both models to the same observations

```r
library(ALSCL)
data("YTF_example")
x <- YTF_example
inputs <- x[c("data.CatL", "data.wgt", "data.mat")]
a <- run_acl(x, train_times = 2, silent = TRUE)
b <- run_alscl(x, train_times = 2, silent = TRUE)
```

两次拟合都读取输入列表 `x`，因此共用数据表、`M`、调查可捕性和时间网格，每个模型从 `x$fit_config` 取自己的初值和 `map`；固定的生长和过程参数值对区间没有贡献不确定性。给两个模型相同的数据表和生物学设置，这样下面的每一处差异都来自模型结构。

Both fits read the input bundle `x`, so they share the tables, `M`, survey catchability and time grid, and each model takes its starting values and `map` from `x$fit_config`; the fixed growth and process values contribute no uncertainty to the intervals. Give both models the same tables and biology, so that every difference below comes from the model structure.

<a id="case-compare-assessments-checks"></a>

#### 2. 检查两次拟合并比较拟合统计量 / Check both fits and compare the fit statistics

```r
diagnose_model(x$data.CatL, a)
diagnose_model(x$data.CatL, b)
comparison <- compare_models(a, b, x$data.CatL)
comparison$summary
comparison$fit_diagnostics
comparison$comparison
plot_compare_residuals(a, b, x$data.CatL)
```

先读每次拟合的数值检查（[理解第一次拟合](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#first-model-checks)）。`compare_models()` 核对两次拟合使用了同一张调查表，再比较目标函数、AIC、BIC 和 `fit_metrics` 中的拟合统计量。`comparison$comparison` 记录 `data_verified`、`eligible`（两次拟合都通过检查）、`preferred`（AIC 较低者，仅在两者都合格时给出）和 `issues`。在记录运行（[comparison_summary.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/comparison_summary.csv)）中，两次拟合都通过检查；ACL 的 AIC 更低，调查指数 RMSE 也更小，为 2.5 对 4.7。AIC 较低只是这些数据上的统计支持；结构是否适合这个种群，要用生物学知识判断。

Read the numerical checks first ([Understand your first fit](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#first-model-checks)). `compare_models()` verifies that both fits used the same survey table, then compares the objective, AIC, BIC and the fit statistics in `fit_metrics`. `comparison$comparison` records `data_verified`, `eligible` (both fits passed the checks), `preferred` (the lower AIC, given only when both are eligible) and `issues`. In the recorded run ([comparison_summary.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/comparison_summary.csv)) both fits passed; ACL had the lower AIC and the smaller survey-index RMSE, 2.5 against 4.7. A lower AIC is statistical support on these data; whether the structure suits the stock is a biological decision.

![模拟 YTF：ACL 与 ALSCL 的残差比较 / Synthetic YTF: residual comparison for ACL and ALSCL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_residuals.png?raw=true&v=f97bb9ff3e81)

四个面板分别是残差直方图、QQ 图、逐年平均残差（误差线为一个标准差）和按体长组的绝对残差；[判断拟合是否可用](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics-residuals)解释这些规律。

The four panels show the residual histogram, the QQ plot, the mean residual by year (error bars: one standard deviation) and the absolute residual by length bin; [Judge whether a fit can be used](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics-residuals) explains the patterns.

<a id="case-compare-assessments-survey"></a>

#### 3. 比较对调查观测的拟合 / Compare the fit to the survey observations

```r
plot_compare_CatL(a, b, x$data.CatL,
                  years = c(2000, 2005, 2010, 2015), facet_ncol = 2)
```

![模拟 YTF：四个年份的调查观测及拟合中位数 / Synthetic YTF: observed survey indices and fitted medians in four years](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_CatL.png?raw=true&v=06278fecb8b7)

点是观测，曲线是选定四个年份的拟合中位数。读丰度差异之前，先比较拟合形状，特别是观测稀疏的较大体长组。

Points are the observations and curves the fitted medians in the four selected years. Compare the fitted shapes, in particular in the sparse larger length bins, before reading differences in abundance.

<a id="case-compare-assessments-estimates"></a>

#### 4. 比较种群估计 / Compare the population estimates

```r
plot_compare_ts(a, b, quantities = c("B", "SSB", "Rec"), se = TRUE)
```

![模拟 YTF 示例的条件种群估计 / Conditional population estimates from the synthetic YTF example](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_ts.png?raw=true&v=6e0c7883ce7f)

观察时间位置、趋势和尺度上的差异；`se = TRUE` 加上由标准误得到的区间。区间重叠说明两个条件估计在这组数据上相近；一组数据给不出两种结构的一般排序。

Look for differences in timing, trend and scale; `se = TRUE` adds the intervals from the standard errors. Overlapping intervals mean close conditional estimates on this dataset; one dataset gives no general ranking of the two structures.

<a id="case-compare-assessments-mortality"></a>

#### 5. 比较捕捞死亡率 / Compare fishing mortality

```r
plot_compare_F(a, b)
```

![模拟 YTF：年龄别与体长别捕捞死亡率 / Synthetic YTF: age-based and length-based fishing mortality](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/compare_F.png?raw=true&v=545b8b47191d)

ACL 按年龄估计捕捞死亡率，ALSCL 按体长估计，所以两个面板的单元格只在时间上对应。`plot_compare_F_ts()` 用最大值（`method = "apical"`，默认）或均值汇总每个时间步的各组；季度值仍按季度计。

ACL estimates fishing mortality by age and ALSCL by length, so the panels' cells match only in time. `plot_compare_F_ts()` summarizes the groups of each time step by their maximum (`method = "apical"`, the default) or mean; quarterly values stay per quarter.

<a id="case-compare-assessments-save"></a>

#### 6. 保存比较结果供复核 / Save the comparison for review

```r
dir.create("my_model_comparison", showWarnings = FALSE)
write.csv(comparison$summary, "my_model_comparison/summary.csv", row.names = FALSE)
write.csv(comparison$fit_metrics, "my_model_comparison/fit_metrics.csv", row.names = FALSE)
write.csv(comparison$fit_diagnostics, "my_model_comparison/fit_diagnostics.csv", row.names = FALSE)
p_population <- plot_compare_ts(a, b, quantities = c("B", "SSB", "Rec"), se = TRUE)
ggplot2::ggsave("my_model_comparison/population.png", p_population,
               width = 10, height = 7, dpi = 300)
saveRDS(list(inputs = inputs, fit_args = x$fit_args, fit_config = x$fit_config,
             comparison = comparison, ACL_report = a$report, ALSCL_report = b$report),
        "my_model_comparison/summary.rds")
writeLines(capture.output(sessionInfo()), "my_model_comparison/session.txt")
```

文件夹里有 CSV 表、种群图、装有输入、设置、比较结果和两个报告的 RDS 文件，以及会话信息。报告时一并写明时间窗、固定的生物学设置、零值的处理和对固定值的敏感性。

The folder holds the CSV tables, the population figure, an RDS with the inputs, settings, comparison and both reports, and the session information. Report with it the time window, fixed biology, zero treatment and sensitivity to the fixed values.

<a id="case-compare-assessments-next"></a>

#### 下一步 / What next

| 想做什么 / What you want to do | 阅读 / Read |
|---|---|
| 绘制其他比较图 / Draw the other comparison figures | [模型比较与真值](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md) / [Model comparisons](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/PLOT_GALLERY.md) |
| 检查单个拟合的残差规律 / Examine the residual patterns of one fit | [判断拟合是否可用](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) / [Judge whether a fit can be used](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) |
| 去掉近期时间步后重新拟合 / Remove recent time steps and refit | [移除近期数据后，估计结果会怎样变化？](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md#case-retrospective-bias) / [Do estimates change when recent data are removed?](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md#case-retrospective-bias) |
| 检验对 M 和 F 结构的敏感性 / Test the sensitivity to M and the F structure | [评估对假设有多敏感，未来 F 情景会怎样改变结果？](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md#case-sensitivity-projection) / [How sensitive is the assessment, and what happens under future F?](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md#case-sensitivity-projection) |
| 对自己的数据表拟合两个模型 / Fit both models to your own tables | [如何拟合自己的调查数据？](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md) / [How do I fit my own survey data?](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md) |

<a id="case-retrospective-bias"></a>
### 移除近期数据后，估计结果会怎样变化？ / Do estimates change when recent data are removed?

本页带你对模拟 YTF 示例运行 ACL 和 ALSCL 的回溯分析：每个模型在去掉最后 1、2、3 个时间步后重新拟合，每一轮与完整拟合比较，再用 Mohn's rho 汇总修订幅度。你需要已安装的软件包（[安装 ALSCL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#start)）；每次分析运行四次拟合，[运行回溯分析](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#retrospective)解释了函数及其返回表。结束时你会有两个结果、它们的图和一个保存文件夹。

On this page you run a retrospective analysis of ACL and ALSCL on the synthetic YTF example: each model is refitted after removing the last one, two and three time steps, each peel is compared with the full fit, and Mohn's rho summarizes the revisions. You need the package installed ([Install ALSCL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#start)); each analysis runs four fits, and [Run a retrospective analysis](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#retrospective) explains the function and its tables. At the end you have both results, their figures and a saved folder.

<a id="case-retrospective-bias-run"></a>

#### 1. 运行 ALSCL 回溯分析 / Run the ALSCL retrospective analysis

```r
library(ALSCL)
data("YTF_example")
x <- YTF_example
rb <- retro_alscl(x, nyear = 3, train_times = 2, silent = TRUE)
rb$fit_diagnostics
rb$rho_text
plot_retro(rb, facet_ncol = 2, rho_digits = 3)
```

`retro_alscl()` 像 `run_alscl(x)` 一样读取输入列表 `x`，先拟合完整序列，再做三轮：第 1 轮去掉最后一个时间步，第 2 轮去掉最后两个，第 3 轮去掉最后三个。`nyear` 以时间步计（季度数据就是季度），每一轮至少要保留两个。调用中的参数对每次拟合都生效，本次调用的 `ncores` 让各轮并行运行（[运行回溯分析](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#retrospectives-run)）。先读 `rb$fit_diagnostics`：每次拟合一行（`Peel` 为 0 是完整拟合），含数值检查和报错信息。只有完整拟合和所有轮次都通过检查、每个末端比较都有限且参考值非零时，`rb$rho_text$Rho` 才给出每个量的 Mohn's rho；否则为 `NA` 并警告，`rb$errors` 列出失败的拟合，`rb$raw_rho_text` 保留未经检查的均值供诊断。教学数据的四次拟合约需六分钟，全部通过（[retro_diagnostics_ALSCL.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/retro_diagnostics_ALSCL.csv)）。

`retro_alscl()` reads the input bundle `x` as `run_alscl(x)` does, fits the full series and then three peels: peel 1 removes the last time step, peel 2 the last two, peel 3 the last three. `nyear` counts time steps (quarters for quarterly data) and every peel must keep at least two. Arguments in the call reach every fit, and `ncores` on this call runs the peels in parallel ([Run a retrospective analysis](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#retrospectives-run)). Read `rb$fit_diagnostics` first: one row per fit (`Peel` 0 is the full fit) with the numerical checks and any error. `rb$rho_text$Rho` gives Mohn's rho per quantity only when the full fit and all peels passed the checks and every terminal comparison is finite with a nonzero reference; otherwise it is `NA` with a warning, `rb$errors` lists the failed fits and `rb$raw_rho_text` keeps the unchecked mean for diagnosis. With the teaching data the four fits take about six minutes and all pass ([retro_diagnostics_ALSCL.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/retro_diagnostics_ALSCL.csv)).

![仓库提供的 ALSCL 回溯示例 / Bundled ALSCL retrospective example](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ALSCL.png?raw=true&v=a15f447d44dc)

每条线是一次拟合，按其最后一个时间步着色；空心点标出末端估计，rho 把它与完整拟合在同一时间步的值比较。像这里一样，各轮的线在大部分序列上与完整拟合重合、只在最后几年分开，说明新观测只修订近期估计。在记录运行中，生物量的 rho 为 0.033，产卵生物量 0.017，丰度 0.027，补充量 0.0018（[rho_ALSCL.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/rho_ALSCL.csv)）；正值表示截短的拟合结束在完整拟合之上。符号相反的项在均值中会抵消，所以也要读 `rb$rho_by_peel`。若没有任何拟合给出估计，`plot_retro()` 会停止并提示你读 `fit_diagnostics` 和 `errors`。

Each line is one fit, coloured by its last time step; the open point marks the terminal estimate that rho compares with the full fit at the same time step. Lines on the full fit for most of the series that split only in the last years, as here, mean that new observations revise the recent estimates only. In the recorded run rho is 0.033 for biomass, 0.017 for spawning biomass, 0.027 for abundance and 0.0018 for recruitment ([rho_ALSCL.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/rho_ALSCL.csv)); a positive value means that the shorter fits ended above the full fit. Terms of opposite sign cancel in the mean, so read `rb$rho_by_peel` as well. If no fit produced estimates, `plot_retro()` stops and asks you to read `fit_diagnostics` and `errors`.

<a id="case-retrospective-bias-acl"></a>

#### 2. 运行 ACL 分析并比较两个模型 / Run the ACL analysis and compare the two models

```r
ra <- retro_acl(x, nyear = 3, train_times = 2, silent = TRUE)
ra$fit_diagnostics
ra$rho_text
plot_retro(ra, facet_ncol = 2, rho_digits = 3)
```

![模拟 YTF：ACL 回溯轨迹 / Synthetic YTF: ACL retrospective trajectories](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ACL.png?raw=true&v=a6c651d2e0de)

相同的观测和轮数，使用 `x$fit_config$acl` 中 ACL 自己的初值和 `map`。先比较每个模型内部的修订，再比较两个模型同一个量的 rho；纵轴尺度不同。在记录运行中 ACL 的数值更小：生物量 0.0069，产卵生物量 0.0079，补充量 -0.010，丰度 -0.00025（[rho_ACL.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/rho_ACL.csv)）。各轮和各模型同向的修订比其大小更重要；rho 本身说明不了原因，所以反复出现的同向修订需要检查输入、固定值和 F 结构（[判断拟合是否可用](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics)）。

The same observations and peel count, with ACL's starting values and `map` from `x$fit_config$acl`. Compare the revisions within each model first, then rho between models for the same quantity; the y scales differ. In the recorded run ACL's values are smaller: 0.0069 for biomass, 0.0079 for spawning biomass, -0.010 for recruitment and -0.00025 for abundance ([rho_ACL.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/rho_ACL.csv)). A revision with the same sign across peels and models matters more than its size; rho names no cause, so a repeated directional revision calls for checks of the inputs, fixed values and F structure ([Judge whether a fit can be used](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics)).

<a id="case-retrospective-bias-save"></a>

#### 3. 保存记录 / Save the record

```r
dir.create("my_retrospective", showWarnings = FALSE)
write.csv(rb$results, "my_retrospective/alscl_trajectories.csv", row.names = FALSE)
write.csv(rb$rho_text, "my_retrospective/alscl_rho.csv", row.names = FALSE)
write.csv(rb$fit_diagnostics, "my_retrospective/fit_diagnostics.csv", row.names = FALSE)
write.csv(rb$rho_by_peel, "my_retrospective/rho_by_peel.csv", row.names = FALSE)
write.csv(ra$rho_text, "my_retrospective/acl_rho.csv", row.names = FALSE)
p_retro <- plot_retro(rb, facet_ncol = 2, rho_digits = 3)
ggplot2::ggsave("my_retrospective/alscl.png", p_retro,
               width = 10, height = 7, dpi = 300)
saveRDS(list(ACL = ra, ALSCL = rb, fit_args = x$fit_args,
             fit_config = x$fit_config), "my_retrospective/results.rds")
writeLines(capture.output(sessionInfo()), "my_retrospective/session.txt")
```

结果是没有活动 TMB 对象的表，所以 `saveRDS()` 能完整保存，`plot_retro()` 在新会话中可以重画。文件夹记录每次拟合的序列、每个量和每一轮的 rho、数值检查、图、`x` 的设置和会话信息。对自己的评估，用你报告的那次拟合的设置运行分析，使各轮与完整拟合只差去掉的观测；季度数据用 `nyear = 4` 去掉一年。

The results are tables without a live TMB object, so `saveRDS()` keeps them whole and `plot_retro()` redraws them in a new session. The folder records every fit's series, rho per quantity and peel, the numerical checks, the figure, the settings of `x` and the session information. For your own assessment, run the analysis with the settings of the fit you report, so that the peels differ from the full fit only in the removed observations; with quarterly data `nyear = 4` removes one year.

<a id="case-retrospective-bias-next"></a>

#### 下一步 / What next

| 想做什么 / What you want to do | 阅读 / Read |
|---|---|
| 读每张返回表和 rho 的公式 / Read every returned table and the rho formula | [运行回溯分析](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#retrospective) / [Run a retrospective analysis](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#retrospective) |
| 修复未通过数值检查的一轮 / Repair a peel that failed the numerical checks | [判断拟合是否可用](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) / [Judge whether a fit can be used](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) |
| 给留出时间步的预测打分 / Score predictions of the withheld time steps | [模型能重现观测并预测留出时间步吗？](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md) / [Can the fitted model reproduce observations and predict withheld time steps?](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md) |
| 用更多核心运行各轮 / Run the peels on more cores | [速度设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/SPEED_GUIDE.md) / [Speed settings](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/SPEED_GUIDE.md) |

<a id="case-sensitivity-projection"></a>
### 评估对假设有多敏感，未来 F 情景会怎样改变结果？ / How sensitive is an assessment, and what happens under future F scenarios?

本页对同一个拟合好的评估（模拟 YTF 示例）提出三个问题：固定的自然死亡率或 F 结构改变时估计值移动多少，数据对一个被估计的参数能确定到什么程度，以及确定性的未来 F 情景意味着什么。你需要已安装的软件包（[安装 ALSCL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#start)）；代码从第 1 步的拟合开始按顺序运行，需要几分钟。结束时你会有情景表和图、一个参数剖面和两个投影，各自带有数值检查。

On this page you ask three questions of one fitted assessment, the synthetic YTF example: how much the estimates move when the fixed natural mortality or the F structure changes, how well the data determine an estimated parameter, and what deterministic future F scenarios imply. You need the package installed ([Install ALSCL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#start)); the code runs in order from the fits of step 1 and takes a few minutes. At the end you have a scenario table and figure, a parameter profile and two projections, each with its numerical checks.

<a id="case-sensitivity-projection-fit"></a>

#### 1. 拟合参考模型 / Fit the reference models

```r
library(ALSCL)
library(ggplot2)
data("YTF_example")
x <- YTF_example
acl_theme_set(palette = "npg", base_theme = "theme_bw")

check_alscl_data(x, "acl")$summary
check_alscl_data(x, "alscl")$summary
a <- run_acl(x, silent = TRUE)
b <- run_alscl(x, silent = TRUE)
summary(a)
summary(b)
```

ACL 拟合 `a` 用于情景和剖面，因为一次 ACL 重新拟合约需二十秒；ALSCL 拟合 `b` 用于投影。`summary()` 打印时间步、F 结构、数值检查（`numerical_ok` 应为 `TRUE`）和自然尺度上的标量参数。`YTF_example` 把生长、体长 CV、两个过程标准差和补充量相关系数固定在教学值上，`M` 为每个年度时间步 0.20，F 结构为默认的 `F_structure = "group_year"`；你自己的输入列表需要有依据的生物学设置（[选择拟合设置](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting)）。若检查未通过，先修好拟合再做任何情景（[判断拟合是否可用](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics)）。

The ACL fit `a` serves the scenarios and the profile, because an ACL refit takes about twenty seconds; the ALSCL fit `b` serves the projections. `summary()` prints the time steps, the F structure, the numerical checks (`numerical_ok` should be `TRUE`) and the scalar parameters on the natural scale. `YTF_example` fixes growth, the length CVs, two process standard deviations and the recruitment correlation at teaching values, with `M` = 0.20 per annual time step and the default `F_structure = "group_year"`; your own bundle needs supported biology ([Choose the fitting settings](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#fitting)). If a check fails, repair the fit before any scenario ([Judge whether a fit can be used](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics)).

<a id="case-sensitivity-projection-scenarios"></a>

#### 2. 拟合敏感性情景 / Fit the sensitivity scenarios

```r
scenarios <- fit_scenarios(x, list(
  reference = list(),
  low_M = list(M = 0.15),
  shared_F = list(F_structure = "year")
), model = "acl", ncores = 1, nstarts = 1,
   F_summary = "mean", silent = TRUE)
scenarios$status
head(scenarios$estimates)

scenario_ssb <- subset(scenarios$estimates, quantity == "SSB")
ggplot(scenario_ssb, aes(year, estimate, color = scenario)) +
  geom_line() + labs(x = "Year", y = "SSB") +
  theme_bw() + theme(panel.grid = element_blank())
```

`fit_scenarios()` 在模型照原样使用的输入发生具名改变时，重新拟合同样的三张表：每个情景是一个替换 `x` 设置的参数列表，空列表是参考情景，`map` 这样的列表会整体替换保存的列表。`low_M` 把每个时间步的自然死亡率从 0.20 降到 0.15；`shared_F` 设置 `F_structure = "year"`，每个时间步所有年龄共用一个 F（季度数据就是每季度一个），年龄间的相关系数随之变为 inactive。`ncores` 在独立的工作进程上运行各情景，每次拟合使用一个工作进程和输入列表或调用中的 `nstarts`（两者都未设置时用一个初值）；`F_summary = "mean"` 对每个时间步的各年龄取 F 的均值，`"apical"` 取最大值。先读 `scenarios$status`：每个情景一行，含耗时、警告、报错和数值检查。未通过检查的情景保留在 `scenarios$estimates` 中并标为 `numerical_ok = FALSE`，报错终止的情景没有估计值。

`fit_scenarios()` refits the same three tables under named changes of the inputs the model takes as given: each scenario is a list of arguments that replace the settings of `x`, an empty list is the reference, and a list such as `map` replaces the stored list completely. `low_M` lowers natural mortality from 0.20 to 0.15 per time step; `shared_F` sets `F_structure = "year"`, one F per time step shared by all ages (one per quarter for quarterly data), leaving the correlation across ages inactive. `ncores` runs scenarios on separate workers, each fit with one worker and the bundle's or the call's `nstarts` (one start when neither sets it); `F_summary = "mean"` averages F over the ages of each time step and `"apical"` takes the maximum. Read `scenarios$status` first: one row per scenario with time taken, warnings, errors and the numerical checks. A scenario that failed the checks stays in `scenarios$estimates` with `numerical_ok = FALSE`, and one that stopped with an error has no estimates.

![ACL 对输入 M 与共享 F 结构的敏感性 / ACL sensitivity to the supplied M and shared-F structure](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/workflows/scenario-SSB.png?raw=true&v=7ee6fd0e12d8)

在记录运行中三个拟合都通过检查（[scenario-status.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/workflows/scenario-status.csv)），最后一个时间步（2019 年）的结果如下（[scenario-estimates.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/workflows/scenario-estimates.csv)）：

In the recorded run all three fits passed ([scenario-status.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/workflows/scenario-status.csv)), and at the last time step, 2019 ([scenario-estimates.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/workflows/scenario-estimates.csv)):

| 情景 / Scenario | 2019 年产卵生物量 / Spawning biomass 2019 | 每时间步平均 F / Mean F per time step |
|---|---:|---:|
| `reference` | 75.7 | 0.318 |
| `low_M` | 75.6 | 0.369 |
| `shared_F` | 74.3 | 0.331 |

较低的 M 抬高了估计的 F，而末期产卵生物量几乎没变，三条曲线几乎重合；用你自己的数据时，曲线之间的差距就是要报告的敏感性。

The lower M raises the estimated F while terminal spawning biomass hardly moves, and the three curves nearly coincide; with your own data the spread between the curves is the sensitivity to report.

<a id="case-sensitivity-projection-profile"></a>

#### 3. 对一个被估计的参数做剖面 / Profile an estimated parameter

```r
profile_values <- exp(a$opt$par[["mean_log_F"]]) * c(0.9, 1, 1.1)
profile_F <- profile_model(a, "mean_log_F", profile_values,
                           scale = "natural", ncores = 1)
profile_F$grid
ggplot(profile_F$grid, aes(value, delta_nll)) +
  geom_line() + geom_point() +
  labs(x = "F process baseline", y = "Change in negative log likelihood") +
  theme_bw() + theme(panel.grid = element_blank())
```

`profile_model()` 把一个被估计的标量参数依次固定在网格值上，重新拟合其余标量参数和过程偏差；参数名必须在 `names(a$opt$par)` 中，所以 `YTF_example` 中固定的 `log_Linf` 会报错终止，而 `mean_log_F` 是被估计的。`scale = "natural"` 时网格在自然尺度上，这里是拟合基准值的 0.9、1 和 1.1 倍，并且必须在优化器边界之内。`profile_F$grid` 给出每个值及其目标函数、`delta_nll`（相对于原始拟合的负对数似然增量）和该次重新拟合的数值检查；失败的点保留可见。负的 `delta_nll` 会保留并触发警告，因为网格拟合找到了比原始拟合更好的最优点，原始拟合随后需要更多初值。`M` 和调查可捕性这类固定输入属于第 2 步。

`profile_model()` fixes one estimated scalar parameter at each grid value and refits the other scalar parameters and the process deviations; the name must be in `names(a$opt$par)`, so `log_Linf`, fixed in `YTF_example`, stops with an error, while `mean_log_F` is estimated. With `scale = "natural"` the grid is on the natural scale, here 0.9, 1 and 1.1 times the fitted baseline, and must lie within the optimizer bounds. `profile_F$grid` gives each value with its objective, `delta_nll` (the rise in negative log likelihood relative to the original fit) and the numerical checks of that refit; failed points stay visible. A negative `delta_nll` is kept and triggers a warning, because the grid refit found a better optimum than the original fit, which then needs more starts. Fixed inputs such as `M` and survey catchability belong in step 2.

![自由 F 过程基准水平的示例剖面 / Illustrative profile of the free F process baseline](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/workflows/profile-F.png?raw=true&v=cc2a75644194)

在记录运行（[profile-F.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/workflows/profile-F.csv)）中，0.281、0.312 和 0.344 三个点的增量分别为 0.93、约 0（-8e-11，舍入误差）和 0.76，全部通过检查：基准 F 改变 10% 要付出 0.8 到 0.9 个单位。三个点只演示方法；用于报告的剖面需要更密的网格，函数也不会由此推断置信区间。

In the recorded run ([profile-F.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/workflows/profile-F.csv)) the three points 0.281, 0.312 and 0.344 gave changes of 0.93, about 0 (-8e-11, rounding) and 0.76, all passing the checks: a 10% change of the baseline F costs 0.8 to 0.9 units. Three points show the method; a profile for a report needs a denser grid, and the function infers no confidence interval from it.

<a id="case-sensitivity-projection-project"></a>

#### 4. 投影未来 F 情景 / Project future F scenarios

```r
h <- 4L
w <- as.matrix(x$data.wgt[-1L])
mat <- as.matrix(x$data.mat[-1L])
future_w <- matrix(w[, ncol(w)], nrow(w), h)
future_mat <- matrix(mat[, ncol(mat)], nrow(mat), h)
future_rec <- rep(tail(b$report$Rec, 1), h)

low_F <- project_model(b, F = rep(0.10, h), recruitment = future_rec,
                       weight = future_w, maturity = future_mat)
higher_F <- project_model(b, F = rep(0.25, h), recruitment = future_rec,
                          weight = future_w, maturity = future_mat)
low_F$summary
higher_F$summary
low_F$assumptions
projection_ssb <- rbind(
  transform(low_F$summary, scenario = "F = 0.10"),
  transform(higher_F$summary, scenario = "F = 0.25"))
ggplot(projection_ssb, aes(year, SSB, color = scenario)) +
  geom_line() + geom_point() + labs(x = "Year", y = "Start-of-period SSB") +
  theme_bw() + theme(panel.grid = element_blank())
```

`project_model()` 在你提供的数值下把最后拟合的种群推进到未来时间步：`F`（每步一个值、所有组共用，或组 × 步矩阵）、`recruitment`（其长度决定投影期数），以及每个未来步一列的完整 `weight` 和 `maturity` 矩阵；`M` 保持拟合值，除非你另行传入。函数不会替你延续任何值：代码把最后观测的体重和成熟比例列以及末期拟合的补充量重复四步，这是要在报告中写明的选择。`summary` 的每一行描述一个时间步的期初：第一个未来状态是最后拟合的种群经过末期拟合的 F 和 M 存活后，加上第一个提供的补充量；未来的 `F[t]` 决定第 `t` 步的渔获和进入第 `t + 1` 步的存活，所以两个情景的第一个未来产卵生物量相同，从第二步起才分开，但第一步的渔获已经不同。投影是确定性的、以拟合为条件的，没有区间、亲体补充关系或参考点；`low_F$assumptions` 记录每一项选择。未通过数值检查的拟合会被拒绝，除非 `allow_failed_fit = TRUE`，此时会记录这一覆盖。

`project_model()` advances the last fitted population through future time steps under values you supply: `F` (one value per step shared by all groups, or a group by step matrix), `recruitment` (its length sets the horizon), and complete `weight` and `maturity` matrices with one column per future step; `M` stays at the fitted value unless you pass another. Nothing is carried forward for you: the code repeats the last observed weight and maturity columns and the last fitted recruitment for four steps, a choice to state in the report. Each row of `summary` describes the start of a time step: the first future state is the last fitted population survived through the last fitted F and M plus the first supplied recruitment, and a future `F[t]` sets the catch of step `t` and the survival into step `t + 1`, so the two scenarios share the first future spawning biomass and separate from the second step on, though their first catches differ. The projection is deterministic and conditional on the fit, without intervals, a stock-recruitment relationship or reference points; `low_F$assumptions` records every choice. A fit that failed the numerical checks is refused unless `allow_failed_fit = TRUE`, which records the override.

![显式保持未来生物学输入的 ALSCL 条件 SSB 情景 / Conditional ALSCL SSB scenarios with explicitly held future biology](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/workflows/projection-SSB.png?raw=true&v=a1acd1f6ce98)

在记录运行（[projections.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/workflows/projections.csv)）中，两个情景 2020 年都从产卵生物量 65.0 开始；2023 年在 F = 0.10 下为 115，在 F = 0.25 下为 73.3，单位由示例的体重决定，并以保持不变的补充量和生物学设置为条件。

In the recorded run ([projections.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/workflows/projections.csv)) both scenarios start at a spawning biomass of 65.0 in 2020; in 2023 it is 115 under F = 0.10 and 73.3 under F = 0.25, in the units implied by the example's weights and conditional on the held recruitment and biology.

<a id="case-sensitivity-projection-next"></a>

#### 下一步 / What next

| 想做什么 / What you want to do | 阅读 / Read |
|---|---|
| 把情景、剖面和投影记录与拟合一起保存 / Save the scenario, profile and projection record with the fit | [评估工作流](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ASSESSMENT_WORKFLOWS.md#assessment-workflows-save-workflow) / [Assessment workflows](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ASSESSMENT_WORKFLOWS.md#assessment-workflows-save-workflow) |
| 在相信投影之前检查残差规律 / Examine residual patterns before trusting a projection | [判断拟合是否可用](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) / [Judge whether a fit can be used](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#diagnostics) |
| 去掉近期时间步后重新拟合 / Refit after removing recent time steps | [移除近期数据后，估计结果会怎样变化？](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md#case-retrospective-bias) / [Do estimates change when recent data are removed?](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASES.md#case-retrospective-bias) |
| 从拟合模拟并给留出时间步的预测打分 / Simulate from the fit and score predictions of withheld time steps | [模型能重现观测并预测留出时间步吗？](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md) / [Can the fitted model reproduce observations and predict withheld time steps?](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md) |

<a id="case-simulate-survey"></a>
### 如何模拟调查数据？ / How do I simulate survey data?

本页带你从已知的种群生成调查表，对一次重复拟合 ACL 和 ALSCL，并把估计值与真值比较。你需要已安装的软件包（[安装 ALSCL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#start)）和一份仓库副本，并从仓库根目录运行 R，因为第 2 步要加载 `scripts/simulation_workflow.R`。结束时你会有这些表、一次重复及其真值、两个拟合，以及估计值与真值对照的图。本页配图是 flatfish 预设的第 4 次重复，由 [scripts/case_studies.R](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/scripts/case_studies.R) 绘制。

On this page you generate survey tables from a known population, fit ACL and ALSCL to one replicate and compare the estimates with the truth. You need the package installed ([Install ALSCL](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#start)) and a copy of the repository, with R running from its root because step 2 sources `scripts/simulation_workflow.R`. At the end you have the tables, one replicate with its truth, two fits and a figure of their estimates against the truth. The figures show the flatfish preset, replicate 4, drawn by [scripts/case_studies.R](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/scripts/case_studies.R).

<a id="case-simulate-survey-quick"></a>

#### 1. 用快速模拟器生成年度输入表 / Create annual input tables with the quick simulator

```r
library(ALSCL)
quick <- simulate_example_data(
  years = 2000:2019, seed = 42, bin_breaks = seq(5, 51, 2),
  Linf = 60, vbk = 0.2, t0 = 1/60, M = 0.2, nage = 15,
  L50_sel = 15, L95_sel = 20, L50_mat = 35, L95_mat = 40,
  wgt_a = exp(-12), wgt_b = 3, mean_F = 0.3,
  cv_catch = 0.2, rec_sigma = 0.3,
  save_csv = TRUE, output_dir = "my_annual_simulation")
str(quick, max.level = 1)
```

`simulate_example_data()` 是用来测试导入、拟合和绘图的快速模拟器：它返回三张表 `data.CatL`、`data.wgt`、`data.mat` 和生成值 `true_params`，`save_csv = TRUE` 还把三个 CSV 文件写入 `output_dir`。做实验要用第 2 步的操作模型。无效的设置，例如 `L95_sel` 小于 `L50_sel`，会在写出任何文件之前终止调用；[模拟调查数据](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#simulation-choose)列出了全部设置。

`simulate_example_data()` is the quick simulator for testing import, fitting and plotting: it returns the three tables `data.CatL`, `data.wgt` and `data.mat` and the generating values `true_params`, and `save_csv = TRUE` writes the three CSV files to `output_dir`. Experiments use the operating model of step 2. An invalid setting, such as `L95_sel` below `L50_sel`, stops the call before any file is written; [Simulate survey data](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#simulation-choose) lists every setting.

<a id="case-simulate-survey-replicate"></a>

#### 2. 用完整操作模型生成一次重复 / Generate one replicate with the full operating model

```r
source("scripts/simulation_workflow.R", encoding = "UTF-8")
pa <- initialize_params(species = "flatfish", first.year = 2000,
                        observation_error = "independent")
bio <- sim_cal(pa)
sm <- sim_data(bio, pa, iter_range = 4:5, return_iter = 4,
               output_dir = "my_full_simulation")
inputs <- simulation_to_tables(sm, pa)
saveRDS(list(parameters = pa, truth = sm, inputs = inputs),
        "my_full_simulation/truth_and_inputs.rds")
str(inputs)
```

`initialize_params()` 建立 flatfish 预设（年龄结构动态，80 年预热后保留 20 个年度时间步，标签 2000-2019），`sim_cal()` 推出生物学数组，`sim_data()` 运行种群：`iter_range` 给出重复编号，也是随机种子；每次重复用 `save()` 保存为 `sim_rep<编号>`（用 `load()` 读回）；`return_iter = 4` 把该次重复作为 `sm` 返回，其中有调查数量 `SN_at_len`、保留的 `years` 以及真值 `SSB`、`Rec` 和 `TB`（[模拟调查数据](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#simulation-generate)列出了每个元素）。`simulation_to_tables(sm, pa)` 返回三张表，行是体长组中点，列是 `sm$years`；`str(inputs)` 应显示三个 23 行 21 列的数据框。若转换器因 `len_mid` 与重复中记录的坐标不同而停止，请传入生成该文件的参数列表。

`initialize_params()` builds the flatfish preset (age-based dynamics, 20 annual time steps labelled 2000-2019 after an 80-year burn-in), `sim_cal()` derives the biological arrays and `sim_data()` runs the population: `iter_range` gives the replicate ids and seeds, each saved as `sim_rep<id>` with `save()` (read it back with `load()`), and `return_iter = 4` returns that replicate as `sm`, with the survey numbers `SN_at_len`, the retained `years` and the truth `SSB`, `Rec` and `TB` ([Simulate survey data](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#simulation-generate) lists every element). `simulation_to_tables(sm, pa)` returns the three tables with the length midpoints as rows and `sm$years` as columns; `str(inputs)` should show three 23-by-21 data frames. If the converter stops because `len_mid` differs from the replicate's recorded coordinates, pass the parameter list that generated the file.

<a id="case-simulate-survey-plot"></a>

#### 3. 绘制模拟观测 / Plot the simulated observations

```r
library(ggplot2)
years <- as.numeric(names(inputs$data.CatL)[-1])
observations <- data.frame(
  Year = rep(years, each = length(pa$len_mid)),
  Length = rep(pa$len_mid, length(years)),
  Index = as.vector(as.matrix(inputs$data.CatL[-1])))
p_data <- ggplot(observations, aes(Year, Length, fill = log10(Index))) +
  geom_tile() + scale_fill_gradient(low = "white", high = "steelblue") +
  labs(fill = "log10 index") + theme_bw() +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
p_data
ggsave("my_full_simulation/survey.png", p_data, width = 10, height = 4, dpi = 160)
```

热图显示按年份和体长组排列的 log10 调查指数，`pa$len_mid` 是 23 个体长组中点。

The heatmap shows the log10 survey index by year and length bin, with `pa$len_mid` as the 23 bin midpoints.

![完整 flatfish 模拟：体长与年份上的调查数量 / Full flatfish simulation: survey numbers by length and year](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/cases/flatfish_data.png?raw=true&v=ae2873a39574)

逐年穿过各体长组的条带是在调查中生长的世代。指数在 10 cm 以下很小（那里的可捕性低于 0.1），在 15-30 cm 最大；可捕性的变化会改变这个观测面，而种群本身不变。

Bands moving through the length bins from year to year are cohorts growing through the survey. The index is small below 10 cm, where catchability is under 0.1, and largest at 15-30 cm; a change in catchability changes this surface while the population stays the same.

![生成模型的生长曲线、成熟比例与调查可捕性 / Generating growth curve, maturity and survey catchability](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/cases/flatfish_biology.png?raw=true&v=b3efd0f2b715)

上图是生长曲线，从 1 龄 11 cm 到 15 龄 57 cm。下图是成熟比例（L50 为 35 cm，来自 `data.mat`）和调查可捕性（L50 为 15 cm，来自 `sel_L50` 和 `sel_L95`）；你的种群需要自己的数值。

The upper panel is the growth curve, 11 cm at age 1 to 57 cm at age 15. The lower curves are maturity (L50 35 cm, from `data.mat`) and survey catchability (L50 15 cm, from `sel_L50` and `sel_L95`); your stock needs its own values.

<a id="case-simulate-survey-fit"></a>

#### 4. 对这次重复拟合两个模型 / Fit both models to the replicate

```r
pA <- list(log_Linf = log(pa$Linf), log_vbk = log(pa$vbk), t0 = pa$t0,
           log_cv_len = log(pa$cv_L), log_std_log_F = log(pa$F_sd),
           log_std_log_N0 = log(pa$std_logN0), logit_log_R = qlogis(pa$R_ar))
pB <- list(log_Linf = log(pa$Linf), log_vbk = log(pa$vbk), log_t0 = log(pa$t0),
           log_cv_len = log(pa$cv_L), log_cv_grow = log(pa$cv_inc),
           log_sigma_log_F = log(pa$F_sd), log_sigma_log_N0 = log(pa$std_logN0),
           logit_log_R = qlogis(pa$R_ar))
mA <- lapply(pA, function(value) factor(NA))
mB <- lapply(pB, function(value) factor(NA))
mB$logit_log_F_l <- mB$logit_log_F_y <- factor(NA)
x <- prepare_alscl_data(inputs,
  fit_args = list(rec.age = pa$rec.age, nage = pa$nage, M = pa$M,
    sel_L50 = pa$q_surv_L50, sel_L95 = pa$q_surv_L95,
    len_mid = pa$len_mid, len_border = pa$len_border[-c(1, length(pa$len_border))],
    growth_step = pa$growth_step, train_times = 2, silent = TRUE),
  fit_config = list(acl = list(parameters = pA, map = mA),
                    alscl = list(parameters = pB, map = mB)))
for (model in c("acl", "alscl")) print(check_alscl_data(x, model)$summary)
a <- run_acl(x)
b <- run_alscl(x)
checks <- list(ACL = diagnose_model(x$data.CatL, a),
               ALSCL = diagnose_model(x$data.CatL, b))
c(a$diagnostics$numerical_ok, b$diagnostics$numerical_ok)
```

输入列表 `x` 在 `fit_args` 中装入生成模型的生物学设置，在 `fit_config` 中按各模型自己的参数名装入初值和 `map`。生长、体长 CV、过程标准差和补充量相关系数固定在生成值上，ALSCL 还固定两个 F 相关系数，因此每个模型估计 5 个标量参数，与[年度与季度时间步](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASE_STUDIES.md#case-studies-annual)相同。`pa$len_border` 从 `-Inf` 到 `Inf`，去掉首尾剩下 22 个内部边界。两个模型的 `check_alscl_data()` 都应报告 23 个体长组、20 个时间步、460 个正观测和 `free_fixed` 为 5；编译后 ACL 约需 20 秒，ALSCL 约需 90 秒，最后一行应打印 `TRUE TRUE`。若检查未通过，按[理解第一次拟合](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#first-model-checks)运行 `diagnose_model()`，并用 `nstarts` 增加初值。

The input bundle `x` carries the generating biology in `fit_args` and each model's starting values and `map`, under its own parameter names, in `fit_config`. Growth, the length CVs, the process standard deviations and the recruitment correlation are fixed at the generating values, plus the two F correlations in ALSCL, so each model estimates five scalar parameters, as in [Annual and quarterly time steps](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASE_STUDIES.md#case-studies-annual). `pa$len_border` runs from `-Inf` to `Inf`; dropping its ends leaves the 22 internal boundaries. `check_alscl_data()` should report 23 length bins, 20 time steps, 460 positive observations and `free_fixed` 5 for both models; ACL takes about 20 seconds and ALSCL about 90 after compilation, and the last line should print `TRUE TRUE`. If a check fails, run `diagnose_model()` as on [Understand your first fit](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#first-model-checks) and add starts with `nstarts`.

<a id="case-simulate-survey-truth"></a>

#### 5. 将估计值与生成真值比较 / Compare the estimates with the generating truth

```r
truth <- data.frame(Year = rep(years, 3),
  Quantity = rep(c("B", "SSB", "Rec"), each = length(years)),
  Truth = c(sm$TB, sm$SSB, sm$Rec))
estimates <- rbind(
  data.frame(Year = rep(years, 3), Quantity = truth$Quantity,
    Value = c(a$report$B, a$report$SSB, a$report$Rec), Model = "ACL"),
  data.frame(Year = rep(years, 3), Quantity = truth$Quantity,
    Value = c(b$report$B, b$report$SSB, b$report$Rec), Model = "ALSCL"))
p_truth <- ggplot(estimates, aes(Year, Value, color = Model)) + geom_line() +
  geom_line(data = truth, aes(Year, Truth), inherit.aes = FALSE, linetype = 2) +
  facet_wrap(~ Quantity, scales = "free_y", ncol = 1) + theme_bw() +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
p_truth
ggsave("my_full_simulation/truth_comparison.png", p_truth,
       width = 10, height = 6, dpi = 160)
saveRDS(list(parameters = pa, truth = sm, inputs = inputs, checks = checks,
             ACL_report = a$report, ALSCL_report = b$report),
        "my_full_simulation/assessment_summary.rds")
```

模拟器把总生物量叫 `TB`，拟合报告叫 `B`；代码先按年份和指标把两者对齐。

The simulator calls total biomass `TB` and the fitted report calls it `B`; the code lines them up by year and quantity.

![flatfish 第 4 次重复：生成真值与 ACL/ALSCL 条件估计 / Flatfish replicate 4: generating truth and conditional ACL/ALSCL estimates](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/cases/flatfish_truth.png?raw=true&v=c37a38eea1f3)

虚线是真值，实线是两个条件估计；各面板的纵轴自由缩放，所以在同一面板内比较。两个模型都跟上了 2010 年前的下降和之后的回升，ALSCL 在 2014 年后的生物量和产卵生物量低于真值。这里只展示年龄结构生成模型的一次重复；要给模型排序，需要很多次重复并保留失败的拟合，[模拟调查数据](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#simulation-fit)用 `summarize_simulations()` 做汇总。

Dashed lines are the truth, solid lines the two conditional estimates; the y scales are free, so compare within each panel. Both models follow the decline to 2010 and the rise after it, and ALSCL sits below the truth for biomass and spawning biomass after 2014. One replicate of an age-based generator is shown; ranking the models needs many replicates with the failed fits kept, which [Simulate survey data](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#simulation-fit) summarizes with `summarize_simulations()`.

<a id="case-simulate-survey-next"></a>

#### 下一步 / What next

| 想做什么 / What you want to do | 阅读 / Read |
|---|---|
| 拟合季度 tuna 重复 / Fit the quarterly tuna replicate | [年度与季度时间步](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASE_STUDIES.md) / [Annual and quarterly time steps](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/CASE_STUDIES.md) |
| 拟合多次重复并汇总偏差、RMSE 和覆盖率 / Fit many replicates and summarize bias, RMSE and coverage | [模拟调查数据](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#simulation-fit) / [Simulate survey data](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/USER_GUIDE.md#simulation-fit) |
| 从拟合模型模拟并重新拟合 / Simulate from a fitted model and refit the draws | [模型能重现观测并预测留出时间步吗？](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md) / [Can the fitted model reproduce observations and predict withheld time steps?](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/MODEL_VALIDATION.md) |
| 保存种子、设置和版本 / Keep seeds, settings and versions | [复现结果与排除故障](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ADVANCED_WORKFLOWS.md) / [Reproduce results and fix problems](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/ADVANCED_WORKFLOWS.md) |
