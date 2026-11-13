# 模型原理与时间尺度

本页带你阅读 ACL 和 ALSCL 背后的方程（采用本包的时间单位和随机效应参数化）、检查一次拟合中的两种概率矩阵，并把年率换算到模型时间步。第 1 步需要[理解第一次拟合](first-model.html)中的 ALSCL 拟合 `b`；方程采用 [Zhang & Cadigan (2022)](https://doi.org/10.1111/faf.12673) 的模型框架。

<h2 id="equations">方程</h2>

<h3 id="dynamics">种群动态</h3>

令 $`i=1,\ldots,A`$ 为年龄组索引，$`a_i=a_{rec}+(i-1)\Delta t`$ 为实际年龄，$`t`$ 为时间步。ACL 将补充量计入最小年龄组，并将存活个体推进至下一年龄组。最高年龄组（plus group）包括达到或超过该组起始年龄的个体。

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

<h3 id="fishing">捕捞死亡率</h3>

ACL 按年龄估计 F，ALSCL 按体长估计 F。以 $`s`$ 表示相应的年龄或体长组，两个模型均使用可分离的 AR(1) × AR(1) 对数 F 偏差：

```math
F_{s,t}=\exp(\mu_F+d_{s,t}),\qquad
\mathrm{Cov}(d_{s,t},d_{s-h,t-j})=\sigma_F^2\phi_S^{|h|}\phi_T^{|j|}.
```

这里 $`\sigma_F`$ 是 TMB 可分离 AR(1) 密度经缩放后的边际标准差；相关参数描述组间和时间上的相关性。该式已经包含边际方差，无需再除以 $`1-\phi^2`$ 因子，那是创新方差参数化的写法。自然死亡率 M 作为已知输入。

<h3 id="recruitment">补充量</h3>

拟合模型用 AR(1) 对数偏差描述补充量。与边际标准差 $`\sigma_R`$ 一致的平稳形式为：

```math
R_t=\exp(\mu_R+r_t),\qquad
r_1\sim N(0,\sigma_R^2),\qquad
r_{t+1}=\phi_R r_t+\eta_t,\quad
\eta_t\sim N\!\left(0,\sigma_R^2(1-\phi_R^2)\right).
```

$`\exp(\mu_R)`$ 是补充量的中位数；算术均值还包含 $`r_t`$ 的方差。完整模拟器 `sim_data()` 使用 Beverton-Holt 亲体补充关系及随机偏差，是另一套补充过程。

<h3 id="initial">初始条件</h3>

第一期最小年龄组由 $`R_1`$ 给定，其余年龄组按初始死亡率与逐组扰动递推：

```math
\log N_{1,1}=\log R_1,\qquad
\log N_{i,1}=\log N_{i-1,1}-Z_{init}+u_{i-1},\quad
u_{i-1}\sim N(0,\sigma_{N0}^2).
```

因此 $`\log N_{i,1}=\log R_1-(i-1)Z_{init}+\sum_{j=1}^{i-1}u_j`$：扰动沿年龄组累积，相邻年龄组的总扰动相互相关。ALSCL 再用初始年龄-体长概率分配这些个体。

<h3 id="pla">年龄-体长转换（ACL）</h3>

给定年龄的长度服从均值由 von Bertalanffy 曲线决定的正态分布：

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

<h3 id="growth">生长转移矩阵（ALSCL）</h3>

ALSCL 保留 $`N_{l,i,t}`$ 的体长、年龄、时间三个维度。$`G_{j,l}`$ 表示从源体长组 $`l`$ 转入目的体长组 $`j`$ 的概率。普通年龄组的存活与增长为：

```math
N_{j,i+1,t+1}=\sum_l G_{j,l}N_{l,i,t}\exp[-(M+F_{l,t})].
```

最高年龄组同时接收前一年龄组新进入的存活个体和本组继续存活的个体，两者均按生长矩阵在体长组间转移。补充个体按最小年龄的体长分布进入第一年龄组。G 的各列和为 1，不允许缩短，最大体长组吸收右尾概率。

生长增量使用下面的平滑下降函数，标准差为 $`CV_G\mu_{\Delta L}`$：

```math
\mu_{\Delta L}(L)=\frac{\Delta t(1-e^{-k})L_\infty}
{1+\exp\!\left(-\log(19)\frac{L-0.5L_\infty}{0.05L_\infty-0.5L_\infty}\right)}.
```

此函数与精确的任意时间步 VB 增量 $`(L_\infty-L)(1-e^{-k\Delta t})`$ 不同。`pla` 是给定年龄的长度分布，G 是给定源长度的一步转移概率，各模型使用各自的矩阵。`FL` 是长度别 F，`FA` 则由同一世代在相应时间步的存活比例推导。

<h3 id="derived">派生量</h3>

输入的平均个体重量 $`w_{l,t}`$ 和成熟比例 $`m_{l,t}`$ 用于计算体长别生物量、成熟生物量及总量：

```math
b_{l,t}=N_{l,t}w_{l,t},\qquad sb_{l,t}=b_{l,t}m_{l,t},\qquad
B_t=\sum_l b_{l,t},\qquad SSB_t=\sum_l sb_{l,t}.
```

`CN`、`CB` 是模型推算的渔业捕获尾数与重量，区别于输入的调查数量指数。生物量单位由个体重量单位和丰度尺度共同决定。丰度尺度就是调查指数的尺度，因为调查可捕性的最大值固定为 1（见下一节）。只有当指数是绝对丰度估计时，丰度、生物量、产卵生物量、补充量、`CN` 和 `CB` 才是绝对量；使用相对指数时，它们是相对值。

<h3 id="survey">调查观测</h3>

令 $`I_{l,t}`$ 为调查数量指数，$`N_{l,t}`$ 为种群尾数。调查观测使用对数正态模型：

```math
\log I_{l,t}=\log q_l+\log N_{l,t}+\epsilon_{l,t},\qquad
\epsilon_{l,t}\sim N(0,\sigma_I^2),
```

```math
q_l=\left[1+\exp\!\left(-\log(19)\frac{L_l-L_{50}}{L_{95}-L_{50}}\right)\right]^{-1}.
```

`sel_L50`、`sel_L95` 固定调查可捕性 q，在两个指定体长处分别取 0.5 和 0.95，对大个体 q 趋近于 1；它们描述的是调查，渔业选择性是另一个量。模型不估计可捕性的比例系数：把指数乘以一个常数，丰度、生物量、补充量和捕获量的估计也乘以同一常数，捕捞死亡率不变。`exp(report$Elog_index)` 给出原尺度的中位数，算术均值还需乘以 $`\exp(\sigma_I^2/2)`$。

<h3 id="estimation">估计与区间</h3>

TMB 用自动微分计算目标函数及导数，对随机效应采用 Laplace 近似；R 的 `nlminb()` 优化固定效应。`sdreport()` 使用局部曲率及 delta 方法给出近似标准误。绘图中的 95% 区间是逐点区间，只有被估计的参数对它有贡献：`YTF_example` 固定了生长和部分过程参数，因此生长区间退化为一条线，其余区间以这些固定值为条件。生长区间描述平均曲线的不确定性，单尾鱼按 $`CV_L`$ 散布在曲线周围。解读任何区间之前，先读 Hessian、边界和梯度检查。

<h2 id="matrices">1. 检查两种概率矩阵</h2>

```r
# b 为 ALSCL 拟合对象
G <- b$report$G
range(colSums(G))
stopifnot(all(G >= 0), max(abs(colSums(G) - 1)) < 1e-8)
```

|矩阵|含义|检查|
|---|---|---|
| `pla` |给定年龄的长度分布；模拟器中的方向随模型而异|先检查方向|
| `G` |给定源长度列的目的长度行|非负、列和为 1、不缩短|

`range(colSums(G))` 应打印两个在舍入误差内等于 1 的值，`stopifnot()` 静默返回。若它停止，说明保存的矩阵不满足这些性质；使用 `b` 之前先读它的数值检查。`plot_pla()` 画的是年龄-体长概率。下面是 tuna 条件 ALSCL 拟合的生长转移矩阵，显示留在原组和进入较大组的概率：

![tuna 生长转移矩阵](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/cases/tuna_growth_transition.png?raw=true)

生长可以留在同一组内：鱼长大了，而分组是离散的。最后一组承接右尾概率。改变体长组边界会改变两个矩阵和状态的含义。

<h2 id="units">2. 把年率换算到模型时间步</h2>

```r
rec.age <- .25; nage <- 20; growth_step <- .25
ages <- rec.age + (seq_len(nage) - 1) * growth_step
range(ages) # 年
M_quarter <- .8 * growth_step
# 四个季度的累计瞬时率
F_quarter <- c(.1, .15, .2, .15)
F_annual <- sum(F_quarter)
```

年龄按设定的步长排列。生长参数 k 按年；M 和 F 是每个时间步的瞬时率，所以年 M = 0.8 对应季度 M = 0.2，一个时间步内的存活概率是 $`\exp[-(M+F)]`$。`range(ages)` 打印 0.25 和 5。`plot_compare_F_ts()` 不会把季度值年化；`method = "apical"` 是每个时间步的组间最大值，`"mean"` 是非加权平均，两个模型的原生 F 维度不同。

<h2 id="next">下一步</h2>

| 想做什么 | 阅读 |
|---|---|
| 查看各模型估计哪些参数及其变换 | [估计参数清单](estimation-parameters.html) |
| 固定或释放参数，选择 F 结构 | [选择拟合设置](fitting-controls.html) |
| 拟合季度调查 | [年度与季度时间步](case-studies.html) |
