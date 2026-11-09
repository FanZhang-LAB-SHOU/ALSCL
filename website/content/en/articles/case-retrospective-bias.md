# Do estimates change when recent data are removed?

On this page you run a retrospective analysis of ACL and ALSCL on the synthetic YTF example: each model is refitted after removing the last one, two and three time steps, each peel is compared with the full fit, and Mohn's rho summarizes the revisions. You need the package installed ([Install ALSCL](getting-started.html)); each analysis runs four fits, and [Run a retrospective analysis](retrospectives.html) explains the function and its tables. At the end you have both results, their figures and a saved folder.

<h2 id="run">1. Run the ALSCL retrospective analysis</h2>

```r
library(ALSCL)
data("YTF_example")
x <- YTF_example
rb <- retro_alscl(x, nyear = 3, train_times = 2, silent = TRUE)
rb$fit_diagnostics
rb$rho_text
plot_retro(rb, facet_ncol = 2, rho_digits = 3)
```

`retro_alscl()` reads the input bundle `x` as `run_alscl(x)` does, fits the full series and then three peels: peel 1 removes the last time step, peel 2 the last two, peel 3 the last three. `nyear` counts time steps (quarters for quarterly data) and every peel must keep at least two. Arguments in the call reach every fit, and `ncores` on this call runs the peels in parallel ([Run a retrospective analysis](retrospectives.html#run)). Read `rb$fit_diagnostics` first: one row per fit (`Peel` 0 is the full fit) with the numerical checks and any error. `rb$rho_text$Rho` gives Mohn's rho per quantity only when the full fit and all peels passed the checks and every terminal comparison is finite with a nonzero reference; otherwise it is `NA` with a warning, `rb$errors` lists the failed fits and `rb$raw_rho_text` keeps the unchecked mean for diagnosis. With the teaching data the four fits take about six minutes and all pass ([retro_diagnostics_ALSCL.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/retro_diagnostics_ALSCL.csv)).

![Bundled ALSCL retrospective example](../assets/manual/figures/ytf/retro_ALSCL.png)

Each line is one fit, coloured by its last time step; the open point marks the terminal estimate that rho compares with the full fit at the same time step. Lines on the full fit for most of the series that split only in the last years, as here, show that the largest visible revisions are near the end of the series. In the recorded run rho is 0.033 for biomass, 0.017 for spawning biomass, 0.027 for abundance and 0.0018 for recruitment ([rho_ALSCL.csv](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/rho_ALSCL.csv)); a positive value means the shorter fits gave higher terminal estimates on average. Terms of opposite sign cancel in the mean, so read `rb$rho_by_peel` as well. If no fit produced estimates, `plot_retro()` stops and asks you to read `fit_diagnostics` and `errors`.

<h2 id="acl">2. Run the ACL analysis and compare the two models</h2>

```r
ra <- retro_acl(x, nyear = 3, train_times = 2, silent = TRUE)
ra$fit_diagnostics
ra$rho_text
plot_retro(ra, facet_ncol = 2, rho_digits = 3)
```

![Synthetic YTF: ACL retrospective trajectories](../assets/manual/figures/ytf/retro_ACL.png)

Both models use the same observations and three peels. For biomass, spawning biomass and total abundance, ACL has the smaller absolute Mohn’s rho (the signed ACL values are 0.0069, 0.0079 and −0.00025, respectively). For recruitment, rho is −0.0104 for ACL and +0.0018 for ALSCL. Recruitment revisions therefore differ in direction on average and have a larger absolute rho for ACL. Inspect the individual terminal comparisons in `rho_by_peel` for their signs and magnitudes. [ACL results](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/rho_ACL.csv) · [ALSCL results](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/results/rho_ALSCL.csv).

<h2 id="save">3. Save the record</h2>

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

The results are tables without a live TMB object, so `saveRDS()` keeps them whole and `plot_retro()` redraws them in a new session. The folder records every fit's series, rho per quantity and peel, the numerical checks, the figure, the settings of `x` and the session information. For your own assessment, run the analysis with the settings of the fit you report, so that the peels differ from the full fit only in the removed observations; with quarterly data `nyear = 4` removes one year.

<h2 id="next">What next</h2>

| What you want to do | Read |
|---|---|
| Read every returned table and the rho formula | [Run a retrospective analysis](retrospectives.html) |
| Repair a peel that failed the numerical checks | [Judge whether a fit can be used](diagnostics.html) |
| Score predictions of the withheld time steps | [Can the fitted model reproduce observations and predict withheld time steps?](case-model-validation.html) |
| Run the peels on more cores | [Speed settings](speed.html) |
