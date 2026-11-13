## Unreleased

- Fixes from a full code review. Default fits keep their estimates; changes that alter results are listed first. Changed results: (1) `sim_model()`, `sim_acl()` and `sim_alscl()` fit each replicate with the natural mortality rate recorded in its file (the default was `M = 0.2`); a supplied `M` that differs is an error unless `allow_M_mismatch = TRUE`. (2) In `retro_model()`, a `mean_log_R` fixed through `map` without a value uses the full-data value in every peel. (3) Interval plots draw lognormal intervals by default (see below). (4) `plot_SSB_Rec()` pairs SSB with recruitment at the youngest fitted age, so quarterly fits with `rec.age = 0.25` use a lag of one quarter, not four, and annual fits with a recruitment age other than 1 use that age. (5) `run_acl()` uses data-based Linf start and bounds when its defaults do not suit the length bins, and for M above 0.7 its default init_Z start is no longer moved onto the upper bound.
- New `structure` argument of `run_acl()`, `run_alscl()` and `retro_model()` selects optional model structures; the default is the published structure. `initial_plus_group = "equilibrium"` makes the first-period plus group the sum of all older cohorts at init_Z. For ALSCL, `initial_length = "growth"` builds the first-period lengths at age from the growth transition, `growth_increment = "von_bertalanffy"` uses the von Bertalanffy increment over the time step, and `growth_transition = "bin"` integrates the transition over the source length bin. With the consistent initial state, a population with constant recruitment and no fishing stays constant; with the published structure it does not. `sim_cal()` and `sim_data()` take the same list as `params$structure`.
- A map that ties or fixes entries of dev_log_R, dev_log_F or dev_log_N0 is rejected when the matching standard deviation or correlation is estimated, because those estimates were biased (the standard deviation could run to its bound). With these parameters fixed the map is accepted, and the fit lists the arrays in `restricted_random`. Use `F_structure = "year"` for one F deviation per time step.
- The ACL defaults for Linf (start 60, bounds 10 to 100) are replaced by data-based values when they do not suit the length bins, for example tuna lengths in cm: the start is 1.1 times the length below which 99 percent of the summed survey index lies, the upper bound is twice the largest bin midpoint, and the lower bound is not raised above the default. Starting values moved into their bounds are reported (a warning for supplied starts, a message for default starts) and listed in `clamped_starts`. The default init_Z start no longer sits on its upper bound for large M.
- New `start_spread` argument sets the spread of the second and later starts. Fits record `start_summary`; converged starts that differ by more than 2 objective units are added to `diagnostics$issues`. The help pages explain that a single start can stop at a local optimum that passes every numerical check. Sequential multistart fits reuse one TMB object with identical results.
- Fits report the number of zero survey observations treated as missing. Numeric length labels with unequal spacing and no `len_border` give a warning. Logical survey, weight or maturity columns are rejected. `create_parameters()` errors name the unknown parameter and its name in the other model. `read_survey_excel()` stops on Excel error cells (#DIV/0!, #N/A) and names the sheet and cells. `len_lower` and `len_upper` are deprecated in `prepare_alscl_data()`, `retro_model()` and bundles fitted with ACL (they cannot change a fit); `run_alscl()` still accepts them without a warning.
- `sim_data()` and `simulate_example_data(seed = )` no longer change the caller's random-number stream. Replicates record their seed, generator settings and package version, and a replicate ID gives the same data under any session generator. Replicate files are written only after every replicate is valid, with integer names (`sim_rep100000`). A zero AR(1) coefficient no longer warns, `initialize_params()$years` ends at the last observation period, and a discontinuous dome selectivity gives a warning. `simulate_example_data()` reports with `message()`.
- Results of `sim_model()`, `sim_acl()` and `sim_alscl()` no longer hold the TMB object (about 0.9 GiB per ALSCL replicate); use `refit_model()` when one is needed. New `simulation_to_tables()` converts a `sim_data()` replicate to fitting tables. `summarize_simulations()` also returns `summary_converged` and `failures`. Failure records of batch fits have class `alscl_fit_error` with print, summary, coef and vcov methods.
- `print()`, `summary()`, `extract_parameters()` and `refit_model()` work again on assessments saved by 2.4.3. A fit has one numerical-screen verdict in all summaries. `save_assessment(x = )` keeps the observations and time metadata of an older fit; archives use RDS version 3. `vcov()` returns NULL when the covariance is not finite or not positive definite. New `fitted()`, `logLik()` (so `AIC()` and `BIC()`) and `nobs()` methods. `extract_estimates()` has a new last column `extrapolated` for terminal-period F and catch, which no observation informs.
- `retro_model()`: new `peel_step` (for example 4 for annual peels of a quarterly model); per-fit warnings in `fit_diagnostics$warnings`; `retro_acl(x, 3)` is accepted; the full fit runs in the same batch as the peels; delta-method standard errors that the retrospective does not use are skipped (also in `hindcast_model()` without `save_fits`). `plot_retro()` draws fits that failed the numerical screen with dashed lines, keeps fits without estimates in the legend, keeps colours with the peel and labels quarterly peels as "2001 Q4".
- `compare_models()` records `delta_aic`, `aic_threshold` and `reason`, and reports a failed fit as such. A bundle whose `fit_config` has an entry for one model can be fitted with the other; misplaced top-level fitting arguments give a warning. `check_fit()` describes the QQ reference correctly: standardized conditional residuals have a standard deviation below 1 under a correct model.
- Plots: intervals of abundance, biomass, SSB, recruitment, catch and fishing mortality are lognormal by default, `exp(log(estimate) +/- 1.96 * SE / estimate)`, and cannot fall below zero; use `interval = "wald"` or `acl_theme_set(interval = "wald")` for the previous interval. Age panels and axes show fitted ages and mark the plus group ("Age 15+"). `plot_compare_F_ts()` gains `basis = "age"` for a common age basis. A global `x_breaks` applies only to axes it lies on. Faceted survey plots no longer overprint year labels. Error bars are opaque by default. `plot_ridges()` has one figure title and quarter labels. Shared F is drawn as one panel. Labels state the time basis of F and spell out SSB. `acl_theme_set()` rejects unsupported settings.
- Speed and infrastructure: the compile cache key includes the platform and C++ settings and builds are installed atomically (existing persistent caches are rebuilt once). `sd_cores = "auto"` respects `SLURM_CPUS_PER_TASK` and `options(mc.cores)` and avoids forking with a threaded BLAS. Sequential batch fits use the session's `sd_cores`. A malformed speed option stops the fit with a message that names it. Diagnostics report unfinished refinement and standard deviations close to zero. Socket workers stop when they load a different TMB version. Internal options `ALSCL.se_level` and `ALSCL.delta_method` are available.
- The development version is 2.4.3.9000. `reshape2` and `cowplot` are no longer required. The built package no longer contains unused figures. Documentation states that outputs are on the scale of the survey index unless the index is absolute, corrects the `growth_step` default and the description of process maps, and maintainer scripts check that the loaded package has the code of the checkout.
- Tests compare the joint likelihood, the growth transition matrix, the population dynamics and Mohn's rho with independent R implementations, check that the operating models reproduce the templates, and fit `YTF_example` to check recovery of the simulated truth.
- `structure` has a fifth setting, `correlation_range`, for ACL and ALSCL. `"positive"` (default) keeps the AR(1) correlations of recruitment and F between 0 and 1, the logistic transform of the `logit_*` parameters. `"symmetric"` lets them lie between -1 and 1 (2 * logistic - 1), so a correlation of zero is no longer a boundary in the numerical checks and a negative correlation can be estimated. Under `"symmetric"` a correlation rho is `qlogis((rho + 1) / 2)` on the optimizer scale; default starts keep their natural value, and `inspect_parameters()`, `extract_parameters()`, `profile_model()` and `simulate_fit()` use the same transform. Use it when recruitment has no or negative autocorrelation: with the default range such a fit runs to the lower boundary and fails the numerical checks.
- New argument `t0_lower` (default 0) of `run_alscl()` and `retro_model()`. ALSCL uses t0 = t0_lower + exp(log_t0), so a negative t0 can be fixed or estimated, for example with `t0_lower = -1` and `parameters = list(log_t0 = log(t0 + 1))`. Reported t0 values are on the natural scale. In an input bundle, store it under `fit_config$alscl`.
- Changed output: ALSCL reports F at age (`report$FA`) and total mortality at age (`report$ZA`) for every age, including the plus group, and for every period (A x Y; earlier versions reported (A-1) x (Y-1)). The values of the cells that existed before are unchanged. Plots and `extract_estimates()` accept fits of both forms. `extract_estimates()` marks the terminal-period rows of FA as `extrapolated`. When the last periods have no positive survey observation, it also marks F and catch from the last period with an observation onwards.
- `extract_estimates()` accepts `N_at_age` as an alias of `NA` (numbers at age), because a table labelled "NA" loses the label when it is written to a CSV file and read back with the defaults of `read.csv()`.
- New argument `random_numbers` of `initialize_params()`. With `"by_process"`, `sim_data()` draws recruitment, F, initial numbers and survey errors from separate streams with a fixed number of draws each, so scenarios that differ in one process share the random numbers of the others. `"sequential"` (default) draws as before. The two settings give different data for the same replicate ID, and each replicate records the setting in `provenance$random_numbers`.
- Changed results: `YTF_example$fit_config` fixes the standard deviation of log F at the marginal SD of the generating AR(1) process, F_sd / sqrt(1 - F_ar^2) = 0.302, for both models; it was the innovation SD 0.2. The data tables are unchanged. Fits of `YTF_example` with its stored configuration change: the ACL and ALSCL objectives are -335.14 and -28.59 (were -335.69 and 22.29) and the AIC difference is 613.09 (was 715.96). The tables and figures of the documentation were regenerated, and the articles quote the new values.
- `plot_retro()` labels quarterly terminal periods ("2004 Q4") also when `peel_step` is above 1. The lower bound of a lognormal interval never falls below zero for a nonnegative estimate. `plot_compare_F_ts(basis = "age")` stops when the two fits have different time steps. `plot_pla()` labels the axis "Age group" for a result without age metadata. `sim_model()`, `sim_acl()` and `sim_alscl()` read replicate files written under their earlier names (`sim_rep1e+05`). `profile_model()` reports the same numerical verdict as `summary()` for older fits. Help pages of the exported functions have examples that run in the package checks.
- Draw single estimates as points with error bars when intervals are requested. Keep the full length range in ridge panels and the full time range in mean-residual comparisons when boundary observations are missing. Validate ridge-height multipliers; add rendering regression tests and bilingual examples without gridlines.
- Keep gaps in mean-residual comparison lines and observed ridge polygons, show isolated observations, and align ridge panels and time colors. Support Brewer palettes for two-period results; add rendering regression tests and refresh affected figures without gridlines.
- Use the checked parallel Hessian during optimizer refinement where forked processes are selected, with sequential fallback and per-step method records. Simulate fitted processes without constructing unused derivative tapes; fitting interfaces and model equations are unchanged.
- Revised some wording to make the documentation more precise.
- Compare positive survey observations cell by cell before reporting fit metrics or choosing a model by AIC. Protect archives from overlapping writes to the same path.
- Check every map name, including named NULL releases, and normalize unused factor levels before fitting. Preflight and fitting now validate the same optimizer controls.
- Preserve small positive probabilities in the simulated age–length key and growth transitions. In age-based simulations, average dome-shaped fishery selectivity over length at each age.
- Show isolated survey observations and residuals as points and keep gaps in observed lines and trends. Preserve scientific-notation length labels and use the fitted ages on ACL fishing mortality heatmaps.
- Preserve an actually converged optimization pass when a numerically equivalent restart reports false convergence; retain all original pass records and still select materially lower objectives.
- Retain optimizer messages, selected passes and refinement evidence in retrospective diagnostics; missing legacy records remain missing.
- Preserve native numeric precision when survey, weight or maturity tables mix numeric, text and factor columns; use the same conversion in diagnostics and reject complex cells.
- Require one-dimensional real numeric time coordinates and quantity vectors in simulation summaries; reject matrices and arrays before they can be recycled into misleading statistics.
- Validate retrospective plot/silent flags before fitting. Reject plots without any finite time/estimate pair while retaining gaps in partially observed series.

## ALSCL 2.4.3

- Check that simulation biology matches the supplied parameters and arrays before drawing data or writing files. Reject inconsistent saved survey catchability before fitting; matching legacy simulation objects remain supported.
- Correct the worked simulation cases to use the marginal F standard deviation implied by the operating model's innovation SD and temporal correlation. Regenerate the data, fitted results and figures, and explain the remaining differences between generating and fitted process assumptions.
- Make the growth comparison reference example self-contained, with its reference data defined in the example. Execute the English and Chinese website examples in isolated environments.
- Preserve the `alscl_fit` class when the own-data example saves results without the live TMB object, so `summary()` retains its diagnostic output after reading the file.
- Apply the global comparison legend position to F heatmaps and growth probability panels, and the global point size to lag and QQ diagnostics. Refresh affected figures without gridlines.
- Clarify that process resampling recomputes survey predictions from the new population states, and that shared F is one time series across groups. Add regression checks and execute the complete fitting and validation examples.


## ALSCL 2.4.2

- Allow `plot_compare_selectivity()` to use saved assessments without refitting, recovering fixed survey catchability from the retained input recipe.
- Restore nullable theme settings, including automatic axis breaks and survey labels, when a saved `acl_theme()` snapshot is applied. Retrospective rho and comparison metric labels inherit the chosen font.
- Use fitted ages for comparative growth plots and reject explicit ranges before either model's `t0`, preventing negative-length extrapolation. Existing valid explicit ranges remain supported.
- Accept replicate ID 0 consistently in simulation generation and fitting; require distinct nonnegative integer IDs.
- Execute the current plotting tutorial blocks and check the `facet_by` examples, with grid-free checks included in the automated workflow.
- Preserve every executable line when merging bilingual code examples with different comment or blank-line counts; add generator regression checks.


## ALSCL 2.4.1

- The README now provides an English entry page and a separate Simplified Chinese version, with installation, examples and links to the task guides.
- Preserve effective fixed scalar values in each `simulate_fit()` input bundle, including a data-derived `mean_log_R` that was fixed without an explicit value. Refit the simulated data under the same fixed assumptions while retaining the original starting-value strategy for free parameters.
- Record `dev_log_N0` in new ALSCL reports so conditional simulations retain all three process-deviation arrays, including after saving and reading an assessment. Older saved reports with missing deviations remain readable.
- Complete `point_size` support in comparison plots. Unset point sizes inherit the global value (2.5); explicit legacy `obs_size` and `compare_point_size` settings remain supported, and a per-call `point_size` takes priority. Refresh affected figures without gridlines.
- Preserve positional `base_theme` calls to `plot_fishing_mortality()` by appending new typography arguments after the existing arguments.
- Stop the own-data example before fitting when ALSCL is older than 2.4.0. Align the declared minimum R version and installation instructions at R 4.1.
- Explain that process deviations are estimated by default but may be fixed or tied through `map`; document the restrictions for process resampling and hindcast validation.
- Separate data loading from source-model fitting in the validation tutorial, so the hindcast-only route needs `x` and no full-data fit. Add regression checks for the tutorial route and early version gate.


## ALSCL 2.4.0

- Plot functions share one set of argument names: `facet_ncol`, `facet_nrow` and `facet_scales` for the facet layout, `line_size` for the line width (the theme key `compare_linewidth` is now `compare_line_size`), `point_size = NULL` inheriting the new theme key `point_size` (2.5), and `se = FALSE` as the default everywhere, including `plot_deviance()`. `plot_CatL()` and `plot_residuals()` choose their layout with `facet_by` ("length" or "year") instead of `type`. The former names still work and warn once per session.
- The population plots `plot_SSB()`, `plot_biomass()`, `plot_abundance()`, `plot_catch()` and `plot_deviance()` take the same `title`, `xlab`, `ylab` and typography arguments as the other single-model plots, and `plot_fishing_mortality()` gains the five typography arguments it lacked. A value given in the call replaces the theme setting.
- `plot_compare_annual_F()` is renamed `plot_compare_F_ts()`: it summarizes F per model time step and never annualized quarterly values.
- Plot titles use sentence case. The title keys `CatL_by_length` and `CatL_by_year` replace `CatL_year` and `CatL_year_dist`; `compare_F_ts` replaces `compare_annualF`; `plot_retro()` uses the `retro` key; `plot_pla()` uses the new `ylab$length`. Time-step panels are labelled "Year 2000" in every plot, or "2000 Q2" for quarterly fits, and age panels "Age bin".
- The tutorials are rewritten as task pages: each page states its goal, then numbered steps with the code to run, why, what to expect and what to do when it fails, and a closing table of next steps. Version history stays on this page.
- Example figures: every plotting function's reference page, and the reference entries of `check_fit()`, `fit_scenarios()`, `profile_model()`, `project_model()`, `hindcast_model()`, `simulate_fit()`, `sim_data()` and the retrospective functions, show the figure their example produces. `acl_theme_set()` shows the five palettes with the role of each colour (`docs/figures/palettes/`, drawn by `scripts/palette_swatches.R`), and the colours page shows the same plot under every palette.
- Plot labels name each quantity the same way everywhere: "Spawning biomass (SSB)", "Catch numbers (CN)", "Abundance"; `plot_recruitment()` labels its axis "Recruitment". The gallery figures are regenerated with these labels and every figure description says what the figure shows, when to use it and what a pattern means.
- The bilingual manuals, the book and the Wiki are generated from the article pairs with `scripts/build_manual.py`, so each tutorial is written once per language.

## ALSCL 2.3.0

- Release the nineteen assessment-workflow functions added since 2.2.9 (data preparation and checks, result extraction and archives, sensitivity scenarios, profiles, projections, fitted-model simulation and hindcast validation): 64 exported functions.
- `run_alscl()` and `retro_alscl()` infer `growth_step` like `run_acl()`: NULL uses rec.age when it is below one, otherwise one. Pass `growth_step = 1` explicitly for annual ALSCL data with rec.age below one.
- `fit_scenarios()` defaults to `model = "acl"` and uses one start per scenario unless the bundle or the call sets `nstarts`, the rule of `hindcast_model()` and `retro_model()`. `retro_model()` accepts `model` as well as `model_type`.
- Simulated bundles from `simulate_fit()` no longer carry the source fit's `output`, `ncores` and `silent` settings.
- Every worker count respects the two-process limit of `R CMD check`.
- The example script uses the exported `read_survey_csv()`, `prepare_alscl_data()` and `check_alscl_data()`; the legacy helper script calls the exported readers. The gallery lists 44 figures; stale statements in the speed documents, guide values, the function reference and four website pages are corrected.

- Add `simulate_fit()` for observations conditional on fitted states or resampled stationary processes, and `hindcast_model()` for expanding-window survey prediction checks with paired persistence baselines. Retain truth, failure diagnostics, actual scoring denominators and grid-free worked figures.
- Guard projections against known failed fits; add `nstarts` to simulation batches; record available source revisions, core/R hashes and runtime metadata in assessment recipes, with change warnings during refitting.

- Align model names and descriptions with the implemented population, observation and growth processes. Clarify survey catchability, simulation F baselines and innovation standard deviations, natural parameter scales and nominal confidence levels without changing existing argument names or calculations.
- Correct residual facet documentation, document the shared ACL/ALSCL simulation entry points, complete Chinese return-value descriptions, remove escaped paragraph artifacts and organize current tutorials by task. Probability-matrix and survey-catchability plot titles use the same terminology as the manuals.

- Add public CSV/Excel preparation and compilation-free data/parameter checks, using the same effective starts, bounds and maps as fitting; preserve original numeric precision and validate scalar logical controls consistently.
- Add fitted-result summaries and extraction, portable assessment archives and recipe-based refitting; retain legacy list access and fitting syntax.
- Add standardized conditional residual tables and grid-free heatmap, actual-time lag and QQ diagnostics, without claiming calibrated tests.
- Add named sensitivity batches and free-scalar parameter profiles with per-fit numerical status, warnings and errors; parallelize independent fits without nested workers.
- Add deterministic ACL/ALSCL projections with explicit future F, recruitment and biology, correct terminal-mortality timing and no implied uncertainty, MSY or TAC calculation.
- Add shared ACL/ALSCL simulation fitting and bias/RMSE/coverage summaries with aligned truth, failure rates and explicit denominators. Document all six workflows in English, Simplified Chinese, the website and Wiki chapter 16, with six new grid-free figures.

- Growth plots default to fitted ages and reject explicit pre-t0 ranges, preventing negative-length extrapolations and reversed intervals. Parameter annotations, fonts and growth-axis labels are consistent with and without intervals.
- Fishing-mortality plots inherit global titles, axis labels, breaks and expansion. Theme names and existing theme objects are both supported with grid-free panels.
- Survey comparison axes use survey-index labels independently of fishery catch; the new survey label takes precedence while preserving legacy custom abundance labels.
- Retrospective tutorials correctly show that saved observations and reports support ridge plots without a live TMB object.
- Growth-reference labels must be nonempty and distinct from both model labels, preventing unrelated curves from being connected.
- Residual smoothers choose their method and span independently in each facet; a sparse group no longer removes or changes trends in other groups.
- All SSB, biomass, abundance and catch plot modes inherit global titles, axis labels, breaks and expansion, including interval variants.
- Process-deviation labels distinguish log deviations from multiplicative factors; survey-index and composition titles describe the plotted quantities.
- Bilingual examples define the retrospective result before use and use the effective year-profile line-width arguments. Manual figures are regenerated with no gridlines.

## ALSCL 2.2.9

- In 2.2.9, omitted generic `line_size` and `se_alpha` inherit `acl_theme_set()` (defaults 1.5 and 0.2); explicit function arguments take priority. Comparison curves honor `linetypes` and `compare_linetypes`. Combined residual/metric titles and F facet labels inherit the global typography. Grid lines remain absent by default. ACL F-deviation age panels use numeric order. `plot_pla(x_breaks = c(1, 5, 10, 15))` selects age-bin ticks without removing heatmap cells.
- The default `plot_CatL(exp_transform = FALSE)` displays natural-log survey indices and labels that scale explicitly. `exp_transform = TRUE` displays original-scale survey indices; curves are fitted medians. An explicit `ylab` overrides the automatic label. Ridge compositions are normalized stably on the log scale, including very large or small finite log predictions; nonfinite predictions are rejected.
- `sim_acl()` saves the status of every replicate, including failures, to `result_rep_<iter>`. Reusing an output directory replaces an earlier success with the current failure record; inspect `converge` and `error` before summarizing results. Output write failures are reported and must not be treated as saved results. `simulation_to_tables(sm, pa)` uses the simulation length coordinates and rejects conflicting parameter coordinates instead of relabeling observations; legacy simulations without coordinates can use matching parameter metadata.
- `create_parameters(species = "krill", model_type = "acl")` supplies a Linf start of 90 and bounds, but does not fix Linf or change M, nage or the time step. To fix it, explicitly pass `map = list(log_Linf = factor(NA))` with the chosen starting value. Biological settings still belong in the fitting arguments.
- Both compiled models evaluate the Baranov catch fraction stably for very small total mortality, consistently with the simulator. This prevents cancellation to zero at extreme values; ordinary-scale results may differ only at floating-point precision.

- After standard-error calculation, the returned live TMB objective is restored to the final fitted parameters. In the fitting R session, `fit$obj$report()` therefore describes the same fitted state as `fit$report`, including sequential standard errors and a fallback from parallel calculation. This does not change the saved estimates or standard errors. Serialized fits still require refitting before using a live TMB objective.
- `plot_compare_residuals()` and `plot_compare_CatL()` verify known observations and their positive-observation mask as well as time and length metadata. Pass the original fitting table; changing its values or turning a missing cell into an observation is an error. Older fits without stored observations remain usable, but their observation alignment cannot be fully verified. Zero and NA observations are omitted from the comparison points, consistently with fitting; prediction curves remain available at those positions.
- Full simulations retain genuine zero and very small positive survey observations; they no longer replace values below `1e-6` with `1e-6`. Survey biomass equals survey abundance times weight, including extinction scenarios. This changes only newly generated data that previously hit that floor; saved datasets are not rewritten. The fitting convention is unchanged: zero observations are missing with `zero_action = "missing"` and rejected with `"error"`; an entirely zero survey contains no positive observations and cannot be fitted by the current lognormal model.
- Simulation length midpoints must lie within their corresponding bins, using the same containment rules as fitting. The first and last bins absorb the tails. Invalid bin geometry is rejected during parameter preparation and rechecked before biological calculations or simulation, including manually modified inputs, before random draws or output files.
- The checked TMB versions are 1.9.21 and 1.9.25. TMB 1.9.25 passed the strict, no-fallback parallel-equivalence tests for both models and both AD frameworks in the existing Windows, macOS and Linux checks; Windows uses socket workers and skips Unix-fork tests. Other TMB versions retain the sequential safety fallback. This extends eligibility for acceleration, without promising a speed-up for small fits; inspect `fit$sd_info` for the actual method.

## ALSCL 2.2.8

- Align survey observations and predictions independently of matrix names; validate residual caps and full-simulator process inputs before random draws or file writes.
- Match quick-simulation tail probabilities to the model core; validate biological inputs, generated outputs and full-simulator probability sums before saving.
- Normalize tibble and factor survey inputs consistently across fitting, diagnostics and comparison; slice time-dependent maps for retrospective peels.
- Validate all requested F/comparison uncertainty, retain numeric age ordering and matrix-position coordinates, and honor residual labels and title alignment.
- Direct F time-series comparisons to the explicit apical/mean helper instead of silently omitting F. Keep grid-free defaults and refresh affected manual figures.
- Load the same source checkout on development socket workers; check source and installed workflows in CI.

## ALSCL 2.2.7

- Reject explicitly finite outer length bounds with an actionable message; the model retains tail-absorbing first/last bins, existing interval labels and default inputs.
- Align abundance plots by matrix positions and fitted time/length metadata, independent of matrix dimnames.
- Validate complete, finite, nonnegative standard errors for abundance, recruitment and deviation intervals. Estimate-only deviation plots use reported estimates without requiring a standard-error table.
- Honor ylab in every growth-plot mode and retain text sizes, breaks, themes and annotations when covariance is unavailable. Synchronize bilingual documentation, website, Wiki and help pages; retain grid-free defaults.

## ALSCL 2.2.6

- Version 2.2.6 also keeps SSB, abundance, biomass, catch, deviation and fishing-mortality plots grid-free if theme loading fails. Explicit theme choices remain available. Manual ggplot exports check major and minor grids in every panel; a visible grid stops export without replacing an existing file. The 2.2.6 release archive includes the refreshed help images.

## ALSCL 2.2.5

- Refresh all manual figures, including legacy help assets, case studies, own-data and benchmark plots. Figure URLs now track image content to avoid stale cached images.

- All package plots now omit major and minor gridlines by default; explicit theme overrides remain available.
- Use the same package installation on socket workers, validate fitted-data alignment in diagnostics, share robust comparison metrics, stabilize steep logistic curves and zero-mortality simulations, honor available biomass intervals and explain unsupported plots. Synchronize bilingual guides and executable help examples; homepage installation versions follow DESCRIPTION.

## ALSCL 2.2.4

- Resolve path and parameter variables before socket batch fitting; retain diagnostics when all retrospective fits fail, including with plotting requested.
- Give same-model configurations distinct comparison labels, preserve each trajectory's calendar and validate metadata for observation-paired plots.
- Preserve missing/zero observation masks in ridges and residual plots, including portable saved results; convert recruitment ages in years to the correct model-step lag.
- Make quick-simulator mean_F match the actual trajectory mean and allow zero F. Newly generated examples change; previously bundled data retain their original truth.
- Validate burn-in and simulation durations against the time step, preserve one-period matrix dimensions and carry first.year through simulation, tables and batch fitting.
- Update English and Simplified Chinese documentation, reference pages, book and Wiki.

## ALSCL 2.2.3

- Check regular time labels against `growth_step` in both fitting functions; preserve wholly missing survey periods as `NA` columns with complete weight and maturity inputs.
- Verify observations and metadata before model comparison. Return numerical diagnostics and comparison eligibility; withhold automatic preferences when a fit fails screening or an older result lacks verifiable data metadata.
- Accept `retro_acl(x)` and `retro_alscl(x)` with explicit overrides. Return full-fit and peel diagnostics, errors and screened/unscreened rho tables; do not report a screened rho when a required fit fails.
- Use consistent missing-data calculations for metric plots. Plot ALSCL F against numeric length-bin midpoints with aligned intervals; retain the ACL length alias with a warning.
- Update the English and Simplified Chinese workflows while retaining existing separate-argument calls, optional F structures and acceleration settings.

## ALSCL 2.2.2

- Add safeguarded Newton refinement (`polish = TRUE`) and preserve every raw optimizer pass. An unchanged failed restart no longer replaces an earlier successful result. Raw convergence codes remain available.
- Add `F_structure = "year"` to both fitting functions, retrospectives and simulation fitting: one shared F per time step with a correctly normalized 1D AR(1) likelihood. The default remains the original group-by-time field; legacy calls and speed settings remain supported.
- Add natural-scale boundaries, covariance conditioning, high parameter correlations and an independent numerical screen. Shared-F deviation plots use one series. See the [complete survey example](../articles/case-fit-survey.html).
- Update English and Simplified Chinese documentation, website and Wiki. Refinement can change estimates at numerical precision; the old speed benchmark is not a promise of cross-version identity.

## ALSCL 2.2.1

- Clarify required inputs versus estimable parameters and all map rules. The own-data script uses model-default maps (10 ACL / 13 ALSCL free scalars), with fresh diagnostics and plots; a more flexible t0-only map is documented separately.
- Add a complete executable CSV/Excel-to-input-bundle workflow, fitting both `run_acl(x)` and `run_alscl(x)`, checking diagnostics, exporting PNG figures and saving reusable inputs and portable results.
- Expand the English and Simplified Chinese [own-data case](../articles/case-fit-survey.html), with the full script, input formats, model-specific configuration, unit conversion, fixed-parameter guidance and plots generated by the example.
- Synchronize the README, Wiki and book. The model likelihood, fitting interfaces and acceleration defaults are unchanged.

## ALSCL 2.2.0

- Both `run_acl(x)` and `run_alscl(x)` accept input bundles or flat named argument lists. Explicit arguments override stored values; model-specific fit settings are selected automatically from `YTF_example`.
- Existing positional calls, named arguments and `do.call()` remain supported. The new interface uses the same optimization and standard-error acceleration, with CppAD still the default.
- Validate bundle names, required inputs and model configurations before fitting. Preserve explicit `NULL` overrides and keep simulation parameters separate from fitting settings.
- Update English and Simplified Chinese examples, R help, reference pages and workflow scripts. See [input lists and overrides](../articles/first-model.html).

- Compute a single remaining delta-method quantity sequentially, avoiding an unnecessary socket worker and a one-chunk splitting error.

## ALSCL 2.1.0

### Speed settings on every system

Standard errors now also use several cores on Windows and in RStudio, R.app and Positron: socket workers compute the delta method when it would take more than about 3 seconds, with identical results. Each fit records how its standard errors were computed in `fit$sd_info`, and `alscl_speed_info()` shows what the settings mean on your computer. The new [speed settings](../articles/speed.html) article explains every setting.

### Speed settings

The new `alscl_speed()` sets how fits compute standard errors. By default they are computed on several cores within one fit, with results identical to ALSCL 2.0.0; in the benchmark, fits were 1.13-1.24 times faster. `alscl_speed(framework = "TMBad")` compiles the models with TMB's TMBad library and made fits 1.25-1.68 times faster, but estimates differ slightly from the default. See the [`alscl_speed()` reference](../reference/alscl_speed.html).

### Parallel fitting update

`run_acl()` and `run_alscl()` now accept `nstarts` separately from `ncores`, with the previous default behavior preserved. Returned diagnostics record actual worker PIDs and CPU time. See [measured parallel performance](../articles/reproducibility.html) for equal-work timings and reproducible evidence.

## ALSCL 2.0.0

- Two survey catch-at-length models, ACL and ALSCL, with annual or quarterly time steps.
- Built-in YTF teaching data, full simulation workflows, Excel templates and guidance for importing observations.
- Fit diagnostics, model comparisons and retrospective analyses.
- Customizable ggsci palettes, with sequential viridis colors for time-ordered ridge plots.

## Documentation website

The documentation is available in English and Simplified Chinese. Use the language link in the navigation bar to switch the current page. The website includes task-based articles, the existing worked figures, and a reference page for every exported function.

Function signatures and defaults are extracted from the R source during each build. Purpose, arguments, return values and usage notes are maintained alongside the package documentation.
