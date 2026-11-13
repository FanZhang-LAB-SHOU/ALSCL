# Run a retrospective analysis

At the end of this page you have, for each model, Mohn's rho for biomass, spawning biomass, recruitment and abundance, a plot of the refitted series and the numerical checks of every refit. You need the input bundle `x` and the ALSCL fit `b` from [Understand your first fit](first-model.html).

A retrospective analysis removes the last time step from the three tables, refits the model, removes one more, refits again, and so on; each refit is a peel. Comparing the peels with the full fit shows how much the recent estimates change when later observations are added; revisions in the same direction across peels indicate a retrospective pattern whose causes warrant investigation.

<h2 id="run">1. Run the analysis</h2>

```r
ra <- retro_acl(x, nyear = 3, silent = TRUE)
rb <- retro_alscl(x, nyear = 3, silent = TRUE)
```

`retro_acl()` uses the ACL model and `retro_alscl()` the ALSCL model. Each call fits the model to the full tables, then runs `nyear` peels: peel 1 drops the last time step and refits, peel 2 drops the last two, and so on. `nyear` is the number of peels. Each peel removes `peel_step` further time steps (default 1), so one peel of quarterly data removes one quarter; step 5 shows annual peels of a quarterly model.

Every fit uses the settings stored in the bundle, as `run_acl(x)` does, with the bundle's explicit `nstarts` starts or one start when it stores none; arguments in the call override them for every fit. `ncores` runs the full fit and the peels on worker processes; a fitting `ncores` stored in the bundle is ignored, and the starts inside one fit run one after another. With `silent = FALSE` the console prints one line per fit.

Two errors stop the call before any fit: the time columns of the survey index table must carry increasing numeric labels ([Prepare your survey data](data-preparation.html)), and every peel must keep at least two time steps, so `nyear * peel_step` is at most the number of time steps minus two. A peel that fails inside the optimizer is recorded in the next step's tables while the analysis continues.

<h2 id="tables">2. Read the returned tables</h2>

```r
rb$fit_diagnostics
rb$rho_by_peel
rb$rho_text
rb$raw_rho_text
rb$errors
```

The result is a list of tables, and `ra` has the same elements as `rb`:

| Element | One row per | Contents |
|---|---|---|
| `fit_diagnostics` | fit | `Peel` (0 is the full fit), `RetrospectiveYear` (last time step kept), `elapsed`, the numerical checks with their summary `numerical_ok` and failed items `issues`, the message of a fit that stopped in `error`, and the warnings raised by the fit in `warnings` |
| `rho_by_peel` | peel and quantity | `RawRho`, the relative difference between the peel's terminal estimate and the full fit's estimate for that time step; `Rho`, the same when both fits passed the numerical checks and the reference is finite and nonzero, otherwise `NA`; `Valid` |
| `rho_text` | quantity | Mohn's rho, the mean of `Rho` over the peels, with `Valid`, `ValidPeels` and `RequestedPeels`; `Year` is only a label position |
| `raw_rho_text` | quantity | the mean of `RawRho` without the checks, for diagnosis only; `NA` when any comparison is missing |
| `errors` | failed fit | `Peel`, `RetrospectiveYear` and the message; zero rows when every fit ran |

The quantities are total biomass `B`, recruitment `Rec`, spawning biomass `SSB` and abundance `N`; the full series are in `rb$results`. `rho_text$Rho` is `NA`, with a warning, when the full fit or any peel failed the numerical checks or a terminal comparison is missing, so the reported mean uses only comparisons for which both fits passed the numerical checks. Find the failed fit in `fit_diagnostics$issues` and `errors`, repair it as on [Judge whether a fit can be used](diagnostics.html) and rerun; `raw_rho_text` only shows the size of the available differences.

<h2 id="plot">3. Plot the refitted series</h2>

```r
plot_retro(rb, facet_ncol = 2, rho_digits = 3)
```

![ALSCL retrospective analysis of the example](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ALSCL.png?raw=true)

`plot_retro()` draws the stored series without refitting, one panel per quantity in the two columns set by `facet_ncol = 2`. Each line is one fit, colored by its last time step: the full fit ends in 2019, the peels in 2018, 2017 and 2016. The legend is titled "Terminal year" for annual time steps and "Terminal period" for shorter ones, where quarters are labelled as in "2019 Q4", also when `peel_step` is above 1. A fit that failed the numerical checks is drawn with a dashed line, and a fit without estimates stays in the legend marked "(no estimates)". The open point marks each fit's terminal estimate, the value rho compares with the full fit, and the panel label gives Mohn's rho with `rho_digits` decimals. The figures on this page add `rho_size = 3`, `point_size = 1` and `line_size = 0.6`.

![ACL retrospective analysis of the example](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/retro_ACL.png?raw=true)

In both figures, the largest visible differences between the peeled and full fits occur near the end of the series. Compare the stored estimates to quantify revisions at other time steps. When rho is `NA` the panel reads `rho unavailable: check diagnostics`; if no fit produced estimates, `plot_retro()` stops and asks you to read `fit_diagnostics` and `errors`. Titles, labels, font sizes and the colors of the fits (`palette`, `colors`) follow [Colors and export](plot-customization.html); every argument is in the [plot_retro reference](../reference/plot_retro.html).

`plot` and `silent` must each be a single `TRUE` or `FALSE`; invalid values stop before any fitting. If no stored row has both a finite time and a finite estimate, `plot_retro()` stops with a diagnostic message. With some valid estimates, missing interior values stay as gaps rather than being joined across.

<h2 id="rho">4. Interpret Mohn's rho</h2>

Mohn's rho averages, over the peels, the relative difference between the terminal estimate of each peel and the full fit's estimate for the same time step:

```math
\rho=\frac{1}{K}\sum_{k=1}^{K}\frac{\hat\theta^{(-k)}_{T-k}-\hat\theta^{(0)}_{T-k}}{\hat\theta^{(0)}_{T-k}}.
```

`K` is `nyear` and `T` the last time step of the full fit; peel `k` ends at `T-k` with the default `peel_step = 1`, and at `T` minus `k` times `peel_step` otherwise. A rho of +0.03 means that the terminal estimates from shorter fits were on average 3% above the corresponding full-fit estimates. A negative rho means they were lower on average. Terms of opposite sign cancel, so read `rho_by_peel` as well; a full-fit estimate of zero leaves its term undefined. Mohn's rho measures the revision of terminal estimates when later observations are added; forecast accuracy is the question of [hindcast validation](case-model-validation.html). Report the direction and magnitude of the revisions for each quantity.

<h2 id="adapt">5. Adapt the analysis to your assessment</h2>

```r
rb2 <- retro_alscl(x, nyear = 3, nstarts = 2, ncores = 3, silent = TRUE)
rb2$fit_diagnostics
```

Run the analysis with the settings of the fit you report, so that differences between peels come from the removed observations only. Arguments in the call reach every fit: `nstarts = 2` runs two starts per fit and keeps the lower objective, `ncores = 3` runs the full fit and the three peels on three worker processes (at most `nyear + 1` workers), and a `map`, `parameters` or `control` argument replaces the whole stored list ([Choose the fitting settings](fitting-controls.html)). An optional model structure, `start_spread` and the ALSCL `t0_lower` stored in the bundle or given in the call also reach every fit. Four rules apply to your own bundle:

- Maps for `dev_log_R` and `dev_log_F`, the process deviations of recruitment and fishing mortality, must cover the complete time grid of the full tables, all groups of one time step before the next (one group when `F_structure = "year"`); each peel keeps the map entries of its retained time steps, and a map of another length stops the analysis. The restriction on fixed or repeated entries in [Choose the fitting settings](fitting-controls.html#map) applies to every peel.
- Use the same F structure as the main fit: the stored `F_structure` is used, and an explicit one in the call applies to every fit.
- Keep at least two observed time steps in the shortest peel, and more when the series is short, because a short peel estimates the same parameters from fewer observations.
- Choose the length of a peel with `peel_step`: with quarterly data the default removes one quarter per peel, and `retro_alscl(x, nyear = 3, peel_step = 4)` removes one year per peel, so that peel `k` ends `k` years before the last time step and Mohn's rho is a mean over annual peels. `RetrospectiveYear` shows the last time step kept.

<h2 id="record">6. Record the result</h2>

```r
save_assessment(b, "ytf_alscl.rds")
saveRDS(rb, "ytf_alscl_retro.rds")
plot_retro(readRDS("ytf_alscl_retro.rds"), facet_ncol = 2, rho_digits = 3)
```

The retrospective result holds tables only, with no live TMB object, so `saveRDS()` keeps all of it and `plot_retro()` draws the reloaded object in a new session. `save_assessment()` is for fits: it stores `b` as a saved fit with its recipe for `refit_model()` and stops with `A complete fit recipe is required` when given the retrospective result. Keep the two files together; [Reproducibility](reproducibility.html) shows how to record the package versions and the session.

<h2 id="next">What next</h2>

| What you want to do | Read |
|---|---|
| Work through the case | [Do estimates change when recent data are removed?](case-retrospective-bias.html) |
| Repair a failed peel | [Judge whether a fit can be used](diagnostics.html) |
| Change the map, F structure or starts | [Choose the fitting settings](fitting-controls.html) |
| Test predictions of later time steps | [Model validation](case-model-validation.html) |
| Run the peels on more cores | [Speed settings](speed.html) |
| Change colors and labels | [Colors and export](plot-customization.html) |
| Read every argument | [retro_model](../reference/retro_model.html), [retro_acl](../reference/retro_acl.html), [retro_alscl](../reference/retro_alscl.html), [plot_retro](../reference/plot_retro.html) |
