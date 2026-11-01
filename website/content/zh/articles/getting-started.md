# 开始使用

先准备 R 环境并安装 ALSCL，再运行内置示例。第一次拟合不需要准备自己的调查文件。

| 步骤 | 完成后得到什么 |
|---|---|
| 准备编译工具 | 在本机编译模型所需的工具 |
| 安装并检查软件包 | 可加载的 ALSCL 和内置示例数据 |
| 运行首个示例 | 拟合结果、数值诊断和图形 |

<h2 id="section-2">1. 准备编译工具</h2>

模型拟合需要与 R 匹配的 C++ 工具链。首次拟合前，先按所用系统安装工具。

| 系统 | 要求 |
|---|---|
| Windows | 安装与 R 版本对应的 [Rtools](https://cran.r-project.org/bin/windows/Rtools/)。 |
| macOS | 安装 Xcode Command Line Tools，使用所安装 R 版本推荐的编译器设置。 |
| Linux | 安装 C++ 编译器、make 及 R 发行版所需的开发工具。 |

拟合函数会自动将包内 C++ 模板编译到可写的会话缓存，无需手动编译。首次拟合可能比之后的拟合耗时更长。

<h2 id="section-1">2. 从 GitHub 安装</h2>

安装命令运行一次即可；需要更新时再运行。下面安装当前 `main` 源码，包含[更新日志](../news/index.html)中“未发布”的新增功能。较早的发布标签可能不含这些接口。

```r
install.packages("remotes")
remotes::install_github("FanZhang-LAB-SHOU/ALSCL")
```

<h2 id="check-installation">3. 确认软件包与数据可以加载</h2>

每次开始新的分析会话时加载软件包。以下检查只读取内置数据，不会编译或拟合模型。

```r
library(ALSCL)
packageVersion("ALSCL")
data("YTF_example")
str(YTF_example[c("data.CatL", "data.wgt", "data.mat")])
```

输出应显示已安装的版本，以及体长组和时间列相互对应的三张表。安装程序自动处理包依赖；导入 Excel 另需 `readxl`，到[数据准备](data-preparation.html)时再安装即可。

<h2 id="section-4">4. 运行第一个分析</h2>

接着阅读[内置 YTF 数据的首个拟合](first-model.html)。该页创建后续教程会用到的 `x`、`a` 和 `b`，并说明解释图形前应先检查什么。

示例运行成功后，再按[数据准备](data-preparation.html)整理自己的调查数据。需要完整参数列表时查阅[函数参考](../reference/index.html)；安装或编译报错可查看[故障处理](reproducibility.html)。

<h2 id="section-3">什么时候需要下载仓库？</h2>

`run_acl()`、`plot_SSB()` 等普通包函数在 `library(ALSCL)` 后即可使用。首个拟合教程只用内置数据。

包含 `source("scripts/...")` 或 `docs/data/...` 路径的示例，还需要下载[仓库](https://github.com/FanZhang-LAB-SHOU/ALSCL)，并将仓库根目录设为 R 工作目录。[Excel 工作簿](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/data/ALSCL_Data_Entry_Example.xlsx)也可以单独下载。
