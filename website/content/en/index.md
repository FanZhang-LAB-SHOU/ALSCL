> Age-structured and age- and length-structured statistical catch-at-length models for fisheries stock assessment

**ALSCL** is an R package for fitting population models to fishery-independent survey length data using [Template Model Builder (TMB)](https://github.com/kaskr/adcomp). It provides the age-structured catch-at-length model (**ACL**) and the age- and length-structured statistical catch-at-length model (**ALSCL**), together with simulation, diagnostics, model comparison and plotting tools.

The model framework is based on [Zhang & Cadigan (2022)](https://doi.org/10.1111/faf.12673). Choose a starting point below; the Contents lists all basic guides, and Articles contains worked cases.

<div class="reading-paths">
<p>Where would you like to start?</p>
<ol>
<li><a href="articles/getting-started.html">Try ALSCL for the first time</a><br>Install the package, fit the bundled example, and check the result.</li>
<li><a href="articles/data-preparation.html">Fit your own survey data</a><br>Prepare three aligned tables, choose biological inputs and inspect which parameters will be estimated.</li>
<li><a href="articles/case-model-validation.html">Check a model with simulation or future observations</a><br>Generate repeat datasets, or assess predictions for periods left out of fitting.</li>
</ol>
</div>

<h2 id="contents">Contents</h2>

- [Installation](#installation)
- [Two model structures](#models)
- [Basic use](#basic-use)
- [Check and interpret the fit](#check-fit)
<!-- ARTICLE_CONTENTS -->
- [Getting help](#help)
- [Citation](#citation)

<h2 id="installation">Installation</h2>

Install ALSCL <span class="current-version">{{VERSION}}</span> from GitHub:

```r
install.packages("remotes")
remotes::install_github("FanZhang-LAB-SHOU/ALSCL")
library(ALSCL)
```

Fitting compiles the bundled TMB models, so an R-compatible C++ toolchain is required. See [installation and compilation](articles/getting-started.html) for platform-specific guidance.

The website describes ALSCL 2.3.0; see [News](news/index.html) for the changes in each release.

<h2 id="models">Two model structures</h2>

| | ACL | ALSCL |
|---|---|---|
| Population state | Numbers by age and time | Numbers by length, age and time |
| Length and growth representation | Age-length probability matrix | Age-length probability matrix for recruitment and initialization; growth transition matrix for survivors |
| Fishing mortality | Estimated by age | Estimated by length; age-specific F is derived |
| Fitting function | `run_acl()` | `run_alscl()` |

Both models use three aligned input tables: survey numbers-at-length, mean individual weight-at-length, and maturity-at-length. Natural mortality and survey catchability settings are supplied. Their assumptions affect the scale and interpretation of the estimates; see the [model framework](articles/model-theory.html).

<h2 id="basic-use">Basic use</h2>

The bundled `YTF_example` contains synthetic yellowtail-flounder-style data, biological settings and known simulation truth. It is a teaching dataset, not the empirical dataset from the paper.

```r
data("YTF_example")
x <- YTF_example
a <- run_acl(x, silent = TRUE)    # age-structured model
b <- run_alscl(x, silent = TRUE)  # age- and length-structured model
diagnose_model(x$data.CatL, a)    # numerical checks, before reading any estimate
diagnose_model(x$data.CatL, b)
plot_compare_ts(a, b, quantities = c("B", "SSB", "Rec"), se = TRUE)
```

`run_acl(x)` and `run_alscl(x)` read the same input bundle `x` (three tables plus settings) and each selects its own stored configuration. [Understand your first fit](articles/first-model.html) explains the fitted object, the checks and the estimates step by step; [Choose the fitting settings](articles/fitting-controls.html) explains what you can change, and [Speed settings](articles/speed.html) how to use several cores.

![ACL and ALSCL biomass, spawning biomass and recruitment estimates from the synthetic YTF example](assets/manual/figures/ytf/compare_ts.png)

The example fixes selected biological and process parameters. Its uncertainty intervals are conditional on those settings. The [worked example](articles/first-model.html) explains the inputs, fitted objects and data provenance.

<h2 id="check-fit">Check and interpret the fit</h2>

```r
diagnose_model(x$data.CatL, b)
plot_residuals(b, type = "year")
comparison <- compare_models(a, b, x$data.CatL)
comparison$summary
```

Read the numerical checks first (convergence code, gradient, Hessian, bounds), then the residual patterns, then the sensitivity to the fixed values such as natural mortality. [Judge whether a fit can be used](articles/diagnostics.html) walks through these checks and [Model comparison plots](articles/model-comparison.html) shows the comparison figures.

<h2 id="learn-more">Basic functions</h2>

<!-- ARTICLE_GUIDE -->

<h2 id="help">Getting help</h2>

Use the [GitHub issue tracker](https://github.com/FanZhang-LAB-SHOU/ALSCL/issues) for bugs and feature requests. Include a small reproducible example, the package version, input dimensions and the output of `sessionInfo()`. Check [troubleshooting](articles/reproducibility.html) for common data and compilation problems.

<h2 id="citation">Citation</h2>

Zhang, F. & Cadigan, N. G. (2022). An age- and length-structured statistical catch-at-length model for hard-to-age fisheries stocks. *Fish and Fisheries*, **23**(5), 1121-1135. [doi:10.1111/faf.12673](https://doi.org/10.1111/faf.12673).

<h3 id="krill-paper">Related application: Antarctic krill</h3>

Dong, S., Zhang, F. & Zhu, G. (2025). Length-dependent growth and mortality within each cohort cannot be ignored in stock assessment: a case study of Antarctic krill *Euphausia superba*. *Marine Ecology Progress Series*, **769**, 1-22. [doi:10.3354/meps14923](https://doi.org/10.3354/meps14923).

This study applies ACL and ALSCL to Antarctic krill to examine how length-dependent growth and mortality within cohorts affect assessment results.

When reporting analyses, also record the ALSCL version, code revision, data source and fitted assumptions.
