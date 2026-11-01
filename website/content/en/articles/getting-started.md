# Getting started

Set up R, install ALSCL, then run the bundled example. You do not need your own survey files for the first fit.

| Step | What you will have |
|---|---|
| Prepare the compiler | The tools needed to compile the models on your computer |
| Install and check the package | ALSCL loaded in R and the example data available |
| Run the first example | A fitted model, numerical diagnostics and a plot |

<h2 id="section-2">1. Prepare the compiler</h2>

Model fitting requires an R-compatible C++ toolchain. Install the tools for your platform before the first fit.

| Platform | Requirement |
|---|---|
| Windows | Install [Rtools](https://cran.r-project.org/bin/windows/Rtools/) matching your R version. |
| macOS | Install the Xcode Command Line Tools; use the R distribution's recommended compiler configuration. |
| Linux | Install a C++ compiler, make and the development tools required by your R distribution. |

The fitting functions compile the bundled C++ templates into a writable session cache. They manage compilation automatically. The first fit may take longer than later fits.

<h2 id="section-1">2. Install from GitHub</h2>

Run the installation commands once, and repeat them when you want to update. This installs the current `main` source, including additions listed under **Unreleased** in the [changelog](../news/index.html). An earlier release tag may not contain those functions.

```r
install.packages("remotes")
remotes::install_github("FanZhang-LAB-SHOU/ALSCL")
```

<h2 id="check-installation">3. Check that the package and data load</h2>

Start each new analysis session by loading the package. The following check reads the bundled data without compiling or fitting a model.

```r
library(ALSCL)
packageVersion("ALSCL")
data("YTF_example")
str(YTF_example[c("data.CatL", "data.wgt", "data.mat")])
```

You should see the installed version and three tables with matching length bins and time columns. Package dependencies are installed automatically. Excel import additionally requires `readxl`; install it when you reach the [data preparation guide](data-preparation.html).

<h2 id="section-4">4. Run your first analysis</h2>

Continue to the [first fit with the bundled YTF example](first-model.html). It creates the `x`, `a` and `b` objects used throughout the tutorials, then shows what to check before interpreting the plots.

Once that example works, follow [data preparation](data-preparation.html) to organize your own observations. Use the [function reference](../reference/index.html) when you need a complete argument list. Installation or compilation problems are covered in [troubleshooting](reproducibility.html).

<h2 id="section-3">When do I need the repository files?</h2>

Ordinary package calls, such as `run_acl()` and `plot_SSB()`, work after `library(ALSCL)`. The first-fit tutorial uses only bundled data.

Examples containing `source("scripts/...")` or a `docs/data/...` path also need a downloaded copy of the [repository](https://github.com/FanZhang-LAB-SHOU/ALSCL). Open its root directory as your R working directory before running those examples. The [Excel workbook](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/data/ALSCL_Data_Entry_Example.xlsx) can also be downloaded separately.
