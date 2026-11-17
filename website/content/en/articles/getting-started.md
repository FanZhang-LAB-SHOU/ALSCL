# Install ALSCL and run a first fit

On this page you install the package, confirm that it loads, fit one model to the bundled example, check the fit and plot one estimate. You need R 4.1 or later and an internet connection; the example data are included. Allow about fifteen minutes, including the one-time compilation in step 4.

| Step | What you will have afterwards |
|---|---|
| 1. Install the compiler | The tools that build the two models on your computer |
| 2. Install the package | ALSCL and its dependencies installed from GitHub |
| 3. Load and check | The package and the example data loaded in your session |
| 4. Fit the example | A fitted ACL model, its numerical checks and a plot of spawning stock biomass |

<h2 id="compiler">1. Install the compiler</h2>

The two models are written in C++ for Template Model Builder (TMB). The first fit compiles them on your computer; later fits reuse the compiled files. Install the compiler for your system before the first fit.

| System | What to install |
|---|---|
| Windows | [Rtools](https://cran.r-project.org/bin/windows/Rtools/) for your R version |
| macOS | The Xcode Command Line Tools (`xcode-select --install` in Terminal) |
| Linux | A C++ compiler and `make`, for example `build-essential` on Debian and Ubuntu |

If the compiler is missing, the first fit in step 4 stops with an error that mentions the compiler or `TMB::compile`. Install the tools, restart R and run the fit again.

<h2 id="install">2. Install the package</h2>

```r
install.packages("remotes")
remotes::install_github("FanZhang-LAB-SHOU/ALSCL")
```

ALSCL is published on GitHub, not on CRAN, so `remotes` installs it together with the packages it depends on, among them TMB 1.9.17 or later and ggplot2 4.0.0 or later. Run the same two lines again when a new release appears; the [changelog](../news/index.html) lists what changed.

On Windows and macOS, R installs ready-made binary packages where it can. If it asks whether to install packages from sources (`Do you want to install from sources the packages which need compilation?`), answer as the table says for your version of R:

| R version | What R installs | Answer |
|---|---|---|
| 4.4 or later | Every package as a binary | `no` |
| 4.3 | TMB as a binary; a few packages without compiled code, such as ggplot2 and patchwork, from source, which needs no compiler | `no` |
| 4.1 and 4.2 | TMB and other packages compiled from source with the compiler of step 1; on macOS, TMB also needs the GNU Fortran compiler from [CRAN's macOS tools page](https://mac.r-project.org/tools/) | `yes` |

On Windows with R 4.1 to 4.2.2, the compiler cannot build TMB 1.9.22 or later. Install TMB 1.9.21 first, then ALSCL without upgrading TMB:

```r
remotes::install_version("TMB", "1.9.21")
remotes::install_github("FanZhang-LAB-SHOU/ALSCL", upgrade = "never")
```

On Linux, R compiles every package from source; [Posit Package Manager](https://packagemanager.posit.co/) offers binary packages for R 4.1 and later.

If the installation stops on a dependency, install that package with `install.packages()` and run `remotes::install_github()` again. If it stops with a compiler message, go back to step 1.

Everything on this website works from an installed package. Only examples that call `source("scripts/...")` or read a `docs/data/...` path need a downloaded copy of the [repository](https://github.com/FanZhang-LAB-SHOU/ALSCL), opened as the R working directory.

<h2 id="load">3. Load the package and the example data</h2>

```r
library(ALSCL)
packageVersion("ALSCL")
data("YTF_example")
str(YTF_example[c("data.CatL", "data.wgt", "data.mat")])
```

Start every session with `library(ALSCL)`. `YTF_example` is a simulated teaching dataset generated with the biological settings of yellowtail flounder (*Limanda ferruginea*, [species page](https://www.fisheries.noaa.gov/species/yellowtail-flounder)) stored in `YTF`. It contains the survey index table `data.CatL`, the weight table `data.wgt` and the maturity table `data.mat`, with one row per length bin.

You should see version 2.5.2 or later, and `23 obs. of 21 variables` for each table, that is 23 length bins and 21 columns, the first for the length-bin labels and one for each year from 2000 to 2019. Nothing is compiled yet; this step only confirms that the installation works.

If loading the package gives a warning that TMB was built with another Matrix ABI version, the TMB binary does not match the installed Matrix package, and every fit can then fail with `All optimization starts failed` and `NA/NaN`. Run `install.packages(c("Matrix", "TMB"))` and restart R. If the warning remains, compile TMB with `install.packages("TMB", type = "source")` (on macOS this needs the GNU Fortran compiler named in step 2), restart R and load the package again.

<h2 id="first-fit">4. Fit the example</h2>

```r
x <- YTF_example
a <- run_acl(x, silent = TRUE)
diagnose_model(x$data.CatL, a)
plot_SSB(a, se = TRUE)
```

`x` is the input bundle, a list that holds the three tables and the settings. `run_acl()` fits the age-structured model, ACL, to the three tables with the biological settings and starting values stored in `x`. The first call compiles the model, which takes one to three minutes and prints the commands of the compiler; the fit itself takes about ten seconds. `silent = TRUE` hides the progress messages of the fit.

`diagnose_model()` prints the numerical checks and then a table of the fit statistics and the checks, with a short explanation of the statistics under it. For this fit the checks include `Optimizer convergence code: 0`, `Numerical checks: TRUE`, `Parameters at their limit in practice: 0` and `Plausibility notes: 0`. `Numerical checks: TRUE`, stored as `a$diagnostics$numerical_ok`, means that the gradient, Hessian, covariance and boundary criteria passed and that no parameter is at its limit in practice. The optimizer code and strong parameter correlations are reported separately, in `a$diagnostics$issues`. The fit statistics (errors of the fitted survey index, AIC and BIC) serve later to compare fits. When a check fails, [Understand your first fit](first-model.html#checks) says what to try.

`plot_SSB()` draws spawning stock biomass with its 95% interval. In this fit it falls to a low in 2010 and then rises until 2016.

<h2 id="next">What next</h2>

| What you want to do | Read |
|---|---|
| See what the fitted object contains and how to judge it | [Understand your first fit](first-model.html) |
| Fit your own survey tables | [Prepare your survey data](data-preparation.html) |
| Fix an installation or compilation problem | [Reproduce results and fix problems](reproducibility.html) |
