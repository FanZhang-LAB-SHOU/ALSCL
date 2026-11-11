# Install ALSCL and run a first fit

On this page you install the package, confirm that it loads, and fit one model to the bundled example. You need R 4.1 or later and an internet connection; the example data are included. Allow about fifteen minutes, most of it for the one-time compilation in step 4.

| Step | What you will have afterwards |
|---|---|
| 1. Install the compiler | The tools that build the two models on your computer |
| 2. Install the package | ALSCL and its dependencies installed from GitHub |
| 3. Load and check | The package and the example data loaded in your session |
| 4. Fit the example | A fitted ACL model and its numerical checks |

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

ALSCL is published on GitHub, not on CRAN, so `remotes` installs it together with the packages it depends on (TMB, ggplot2 and others). Run the same two lines again when a new release appears; the [changelog](../news/index.html) lists what changed.

If the installation stops on a dependency, install that package with `install.packages()` and run the second line again. If it stops with a compiler message, go back to step 1.

<h2 id="load">3. Load the package and the example data</h2>

```r
library(ALSCL)
packageVersion("ALSCL")
data("YTF_example")
str(YTF_example[c("data.CatL", "data.wgt", "data.mat")])
```

Start every session with `library(ALSCL)`. `YTF_example` is a simulated teaching dataset generated using the yellowtail flounder (*Limanda ferruginea*) biological settings in `YTF`. It contains a survey-index table `data.CatL`, a weight table `data.wgt` and a maturity table `data.mat`, each with 23 length-bin rows and 20 year columns. The first column contains length-bin labels; the remaining columns contain years. [Species identity](https://www.fisheries.noaa.gov/species/yellowtail-flounder).

You should see version 2.4.0 or later and three data frames of the same size. Nothing is compiled yet; this step only confirms that the installation works.

<h2 id="first-fit">4. Fit the example</h2>

```r
x <- YTF_example
a <- run_acl(x, silent = TRUE)
diagnose_model(x$data.CatL, a)
```

`run_acl()` fits the age-structured model, ACL, to the three tables using the biological settings and starting values stored in `x`. The first call compiles the model, which takes one to three minutes; the fit itself takes about twenty seconds. `silent = TRUE` hides the progress messages.

`diagnose_model()` prints the raw optimizer code, maximum absolute gradient, Hessian status and parameter-boundary checks. `Numerical checks: TRUE`, stored as `a$diagnostics$numerical_ok`, means the gradient, Hessian, covariance and boundary criteria passed. The raw optimizer code and strong parameter correlations require separate review. Read `a$diagnostics$issues` even when this screen passes; [Understand your first fit](first-model.html) explains the checks and how to investigate a flagged result.

Everything on this website works from an installed package. Only examples that call `source("scripts/...")` or read a `docs/data/...` path need a downloaded copy of the [repository](https://github.com/FanZhang-LAB-SHOU/ALSCL), opened as the R working directory.

<h2 id="next">What next</h2>

| What you want to do | Read |
|---|---|
| See what the fitted object contains and how to judge it | [Understand your first fit](first-model.html) |
| Fit your own survey tables | [Prepare your survey data](data-preparation.html) |
| Fix an installation or compilation problem | [Reproducibility and troubleshooting](reproducibility.html) |
