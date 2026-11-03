<p align="right"><strong>English</strong> | <a href="README.zh-CN.md">简体中文</a></p>

# ALSCL <img src="ALSCLlogo.png" align="right" height="140" alt="ALSCL logo" />

> Age-structured and age- and length-structured statistical catch-at-length models for stock assessment from survey length data

<!-- badges: start -->
[![R-CMD-check](https://github.com/FanZhang-LAB-SHOU/ALSCL/actions/workflows/R-CMD-check.yaml/badge.svg?branch=main)](https://github.com/FanZhang-LAB-SHOU/ALSCL/actions/workflows/R-CMD-check.yaml)
[![Documentation](https://github.com/FanZhang-LAB-SHOU/ALSCL/actions/workflows/documentation.yaml/badge.svg?branch=main)](https://fanzhang-lab-shou.github.io/ALSCL/)
[![Latest release](https://img.shields.io/github/v/release/FanZhang-LAB-SHOU/ALSCL?label=release&color=1f6feb)](https://github.com/FanZhang-LAB-SHOU/ALSCL/releases/latest)
[![License: GPL-3](https://img.shields.io/badge/license-GPL--3-blue.svg)](LICENSE.md)
[![Model paper](https://img.shields.io/badge/paper-Fish%20and%20Fisheries%202022-6f42c1.svg)](https://doi.org/10.1111/faf.12673)
<!-- badges: end -->

ALSCL is an R package for stock assessment from fishery-independent survey data at length. It fits two population models written in [TMB](https://github.com/kaskr/adcomp): the age-structured catch-at-length model **ACL** and the age- and length-structured statistical catch-at-length model **ALSCL** of [Zhang and Cadigan (2022)](https://doi.org/10.1111/faf.12673). Neither model needs age data, so both suit stocks whose ages are unavailable or unreliable, such as Antarctic krill.

Around the two models the package provides data preparation and checks, multistart fitting on parallel workers, diagnostics, model comparison, retrospective analysis, sensitivity scenarios, likelihood profiles, projections, fitted-model simulation, hindcast validation, portable assessment archives and 22 plotting functions.

**Latest release: 2.4.1** · [What changed](NEWS.md) · [Website](https://fanzhang-lab-shou.github.io/ALSCL/) · [Wiki](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [Function reference](docs/FUNCTION_REFERENCE.md) · [Plot gallery](docs/PLOT_GALLERY.md)

## What you can do

- **Prepare and check the data.** Read the three survey tables from Excel or CSV with `read_survey_excel()` or `read_survey_csv()`, combine them with the biological settings into one input bundle with `prepare_alscl_data()`, and confirm with `check_alscl_data()` and `inspect_parameters()` that the bundle can be fitted and which parameters will be estimated. Annual and quarterly time steps are supported.
- **Fit two model structures to the same tables.** `run_acl()` tracks numbers at age and converts them to numbers at length with an age-length probability matrix. `run_alscl()` tracks numbers by length and age, with length-specific mortality and a growth transition matrix. Both can run independent optimizer starts on parallel workers (`nstarts`, `ncores`) and finish the best start with checked Newton steps (`polish`).
- **Judge the fit.** `diagnose_model()` reports the convergence code, the gradient, the Hessian and parameters at their bounds. `check_fit()` adds residual heat maps, lag correlations and QQ plots. `compare_models()` compares two fits of the same data by AIC, BIC and fit statistics.
- **Test the assessment.** Retrospective peels with Mohn's rho (`retro_model()`), sensitivity scenarios (`fit_scenarios()`), likelihood profiles (`profile_model()`), deterministic projections (`project_model()`), simulation from the fitted model (`simulate_fit()`) and hindcast validation on withheld time steps (`hindcast_model()`).
- **Keep and share the results.** `save_assessment()` stores a fit with its complete recipe, `read_assessment()` and `refit_model()` bring it back and refit it, and `extract_estimates()` returns the estimates with their standard errors.
- **Plot everything with one argument set.** The 22 plotting functions share their argument names and one theme, `acl_theme_set()`, with five colour palettes. The [gallery](docs/PLOT_GALLERY.md) shows all 44 figures with their code.

## Installation

```r
install.packages("remotes")
remotes::install_github("FanZhang-LAB-SHOU/ALSCL")          # development version (main)
remotes::install_github("FanZhang-LAB-SHOU/ALSCL@v2.4.1")   # a specific release
```

ALSCL needs R 4.1 or later and a C++ compiler that matches R: Rtools on Windows, the Xcode Command Line Tools on macOS, and a C++ compiler and make on Linux. The first fit of each model in an R session compiles it; `options(ALSCL.tmb.cache = "~/ALSCL-cache")` keeps the compiled code between sessions. See [Install ALSCL and run a first fit](https://fanzhang-lab-shou.github.io/ALSCL/articles/getting-started.html).

## Quick start

```r
library(ALSCL)
data("YTF_example")               # bundled synthetic example: three tables plus settings
x <- YTF_example
a <- run_acl(x, silent = TRUE)    # age-structured model
b <- run_alscl(x, silent = TRUE)  # age- and length-structured model
diagnose_model(x$data.CatL, a)    # numerical checks before reading any estimate
extract_estimates(a)              # estimates with standard errors
plot_compare_ts(a, b, quantities = c("B", "SSB", "Rec"), se = TRUE)
save_assessment(a, "ytf_acl.rds")
```

![ACL and ALSCL biomass, spawning biomass and recruitment](docs/figures/ytf/compare_ts.png)

`YTF_example` is a synthetic data set with known simulation truth, made for teaching; it is not the empirical data set of the paper. To fit your own survey, start with [Prepare your survey data](https://fanzhang-lab-shou.github.io/ALSCL/articles/data-preparation.html).

<p align="center">
  <a href="docs/PLOT_GALLERY.md"><img src="docs/figures/ytf/CatL_length_TRUE.png" width="32%" alt="Fitted and observed survey indices by length bin"></a>
  <a href="docs/PLOT_GALLERY.md"><img src="docs/figures/ytf/residuals_year.png" width="32%" alt="Log residuals by year"></a>
  <a href="docs/PLOT_GALLERY.md"><img src="docs/figures/ytf/ridges.png" width="32%" alt="Observed and fitted length composition by year"></a>
</p>

Survey fit by length bin, residuals by year, and observed and fitted length composition by year: three of the figures in the [plot gallery](docs/PLOT_GALLERY.md).

## Two models, one input format

| | ACL | ALSCL |
|---|---|---|
| Population state | Numbers by age and time | Numbers by length, age and time |
| Length and growth | Age-length probability matrix | Probability matrix for recruits and initial numbers; growth transition matrix for survivors |
| Fishing mortality | Estimated by age | Estimated by length; F at age is derived |
| Fitting function | `run_acl()` | `run_alscl()` |

Both models read the same three tables, by year or by quarter: survey numbers at length, mean weight at length and maturity at length. Natural mortality and survey catchability are supplied as settings. The [example workbook](docs/data/ALSCL_Data_Entry_Example.xlsx) shows the layout.

## Documentation

Where to start:

1. [Install ALSCL and run a first fit](https://fanzhang-lab-shou.github.io/ALSCL/articles/getting-started.html): install the package, fit the bundled example and check the result.
2. [Prepare your survey data](https://fanzhang-lab-shou.github.io/ALSCL/articles/data-preparation.html): lay out the three tables, choose the biological settings and see which parameters will be estimated.
3. [Can the fitted model reproduce observations and predict withheld time steps?](https://fanzhang-lab-shou.github.io/ALSCL/articles/case-model-validation.html): simulation and hindcast validation.

Every page states its purpose, the code to run, what to expect and what to do when it fails.

| Entry | Contents |
|---|---|
| **[Website](https://fanzhang-lab-shou.github.io/ALSCL/)** (English) · **[中文网站](https://fanzhang-lab-shou.github.io/ALSCL/zh/)** | Installation, first fit, data preparation, fitting settings, diagnostics, plots, simulation, reproducibility, six worked cases and the reference of all 65 functions |
| [Wiki](https://github.com/FanZhang-LAB-SHOU/ALSCL/wiki) · [Single-page book](docs/BOOK.md) | The same content with Chinese and English side by side, 18 chapters |
| [User guide](docs/USER_GUIDE.md) | From installation to retrospectives |
| [Assessment workflows](docs/ASSESSMENT_WORKFLOWS.md) · [Model validation](docs/MODEL_VALIDATION.md) · [Worked cases](docs/CASES.md) | Result extraction and archives, sensitivity, profiles, projections, simulation, hindcast validation |
| [Function reference](docs/FUNCTION_REFERENCE.md) · [Plot gallery](docs/PLOT_GALLERY.md) | Every argument and default; 44 figures with their code |
| [Speed guide](docs/SPEED_GUIDE.md) | Standard errors on parallel workers and the TMBad option with `alscl_speed()` |

## Getting help

Report problems in the [issue tracker](https://github.com/FanZhang-LAB-SHOU/ALSCL/issues) with a small reproducible example, the package version, the input dimensions and the output of `sessionInfo()`. Common problems are covered in [Reproduce results and fix problems](https://fanzhang-lab-shou.github.io/ALSCL/articles/reproducibility.html).

## Citation

Cite the model paper, and the package with `citation("ALSCL")`:

Zhang, F. and Cadigan, N. G. (2022). An age- and length-structured statistical catch-at-length model for hard-to-age fisheries stocks. *Fish and Fisheries*, 23(5), 1121-1135. [doi:10.1111/faf.12673](https://doi.org/10.1111/faf.12673)

Application to Antarctic krill, where length-dependent growth and mortality within cohorts change the assessment results:

Dong, S., Zhang, F. and Zhu, G. (2025). Length-dependent growth and mortality within each cohort cannot be ignored in stock assessment: a case study of Antarctic krill *Euphausia superba*. *Marine Ecology Progress Series*, 769, 1-22. [doi:10.3354/meps14923](https://doi.org/10.3354/meps14923)

<details>
<summary>BibTeX</summary>

```bibtex
@article{zhang2022age,
  title={An age-and length-structured statistical catch-at-length model for hard-to-age fisheries stocks},
  author={Zhang, Fan and Cadigan, Noel G},
  journal={Fish and Fisheries}, volume={23}, number={5},
  pages={1121--1135}, year={2022}, doi={10.1111/faf.12673}
}

@article{dong2025length,
  title={Length-dependent growth and mortality within each cohort cannot be ignored in stock assessment: a case study of Antarctic krill Euphausia superba},
  author={Dong, Sisong and Zhang, Fan and Zhu, Guoping},
  journal={Marine Ecology Progress Series}, volume={769},
  pages={1--22}, year={2025}, doi={10.3354/meps14923}
}
```

</details>

## Authors

ALSCL is developed at the [Oceanic Fisheries Ecosystem Laboratory](https://github.com/FanZhang-LAB-SHOU), Shanghai Ocean University, by Hongyu Lin ([ORCID 0000-0001-6226-179X](https://orcid.org/0000-0001-6226-179X)), Fan Zhang ([ORCID 0000-0003-0214-1790](https://orcid.org/0000-0003-0214-1790)) and Sisong Dong. Record the package version (`packageVersion("ALSCL")`) and the Git commit with every analysis.

## License

[GPL-3](LICENSE.md)
