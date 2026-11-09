## Unreleased

- Revised wording in the documentation for greater precision.
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
