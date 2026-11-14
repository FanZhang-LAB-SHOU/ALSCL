# Where the tests are

Test files in `tests/testthat/` are named by the release or review in which they were added,
not by feature. This table says which files to read or run for each part of the package.
Run one group with, for example, `devtools::test(filter = "retro")`.

| Part of the package | Test files (`test-*.R`) |
|:--|:--|
| Model equations of the TMB templates, checked against independent R code | `model-core`, `review-tests-reference-likelihood`, `review-tests-growth-matrix`, `review-tests-stationarity`, `review-core-structure`, `review-core-structure-sets`, `review-core-options` |
| Fitting: starts, bounds, maps, refinement, multistart, parallel starts | `fit`, `review-core-fitting`, `map-controls-followup`, `refinement`, `parallel`, `parallel-refinement`, `fit-state-review`, `core-225`, `core-performance`, `review-tests-estimation` |
| Standard errors, speed settings, compile cache, workers | `speed`, `speed-single-quantity`, `review-infra-speed`, `review-infra-compile`, `review-infra-workers`, `review-infra-diagnostics` |
| Input reading and checks (tables, CSV, Excel, bundles, length bins) | `input`, `input-precision`, `input-workflow`, `bin-bounds-227`, `fit-bundle`, `review-workflows-bundle`, `review-workflows-excel` |
| Results: summaries, parameter and estimate tables, archives, S3 methods | `result-workflow`, `assessment-provenance`, `assessment-regression`, `review-workflows-archive`, `review-workflows-s3-methods`, `ytf-example` |
| Diagnostics, residuals and model comparison | `diagnostics`, `diagnostics-225`, `review-workflows-check-fit`, `comparison-review`, `comparison-screen`, `review-workflows-compare`, `survey-comparison-archive` |
| Retrospectives, Mohn's rho, hindcasts, profiles, projections, scenarios | `retro-workflow`, `data-retro-review`, `review-workflows-retro`, `review-workflows-plot-retro`, `review-tests-mohn-rho`, `hindcast-model`, `batch-profile-api`, `projection-fit-status`, `scientific-workflows`, `workflow-release229` |
| Operating models and simulation studies | `simulation`, `simulation-224`, `simulation-release228`, `simulation-review`, `simulation-consistency-review`, `simulation-provenance-243`, `simulation-summary-api`, `sim-model-api`, `sim-multistart`, `sim-tails-selectivity`, `simulate-fit`, `review-core-simulation`, `review-infra-sim`, `review-infra-summary`, `review-infra-tables`, `review-tests-operating-model`, `theme-simulation-contracts-242` |
| Plots of fitted quantities (data, intervals, axes, facets) | `plot-review`, `plot-data-227`, `plot-workflow`, `plots-225`, `plot-release228`, `plot-semantics-release229`, `plot-arguments-240`, `plot-labels-review`, `plot-facets-reference-review`, `plot-archive-domain-review`, `singleton-plot-rendering`, `missing-lag-224`, `catchability-plot`, `survey-axis-label`, `survey-plot-gaps`, `survey-runs-and-axis-labels`, `review-plots-intervals`, `review-plots-axes` |
| Comparison plots and growth plots | `comparison-plots-224`, `review-plots-compare-theme`, `vb-domain-theme-review`, `vb-style-227` |
| Theme, palettes and plot style | `theme-225`, `theme-226`, `palettes`, `plot-style-243`, `style-release229`, `fishing-theme-followup`, `population-theme-inheritance` |

Shared helpers:

- `helper-fixtures.R`: small inputs and fast fits (`fixture_frames()`, `cpp_fixture()`, `fit_fixture()`).
- `helper-review-reference.R`: independent R implementations of the length-at-age key, the growth
  transition matrix, the population dynamics and the joint negative log-likelihood of both models
  (original structure). Use these when a change to the templates must be checked against something
  that is not the template itself.

Notes for new tests:

- The suite runs with `stop_on_warning = TRUE`.
- Set `ALSCL_TEST_CACHE` to a folder to reuse compiled templates between runs.
- Tests that fit a model call `skip_on_cran()`.
- Add a test to an existing file for the same part of the package where one exists; name a new file
  by feature (for example `test-retro-peel-step.R`).
