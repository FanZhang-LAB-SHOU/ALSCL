# How do I simulate survey data?

On this page you generate survey tables from a known population, fit ACL and ALSCL to one replicate and compare the estimates with the truth. You need the package installed ([Install ALSCL](getting-started.html)). At the end you have the tables, one replicate with its truth, two fits and a figure of their estimates against the truth. The figures show the flatfish preset, replicate 4, drawn by [scripts/case_studies.R](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/scripts/case_studies.R).

<h2 id="quick">1. Create annual input tables with the quick simulator</h2>

```r
library(ALSCL)
quick <- simulate_example_data(
  years = 2000:2019, seed = 42, bin_breaks = seq(5, 51, 2),
  Linf = 60, vbk = 0.2, t0 = 1/60, M = 0.2, nage = 15,
  L50_sel = 15, L95_sel = 20, L50_mat = 35, L95_mat = 40,
  wgt_a = exp(-12), wgt_b = 3, mean_F = 0.3,
  cv_catch = 0.2, rec_sigma = 0.3,
  save_csv = TRUE, output_dir = "my_annual_simulation")
str(quick, max.level = 1)
```

`simulate_example_data()` is the quick simulator for testing import, fitting and plotting: it returns the three tables `data.CatL`, `data.wgt` and `data.mat` and the generating values `true_params`, and `save_csv = TRUE` writes the three CSV files to `output_dir`. Experiments use the operating model of step 2. An invalid setting, such as `L95_sel` below `L50_sel`, stops the call before any file is written; [Simulate survey data](simulation.html#choose) lists every setting.

<h2 id="replicate">2. Generate one replicate with the full operating model</h2>

```r
pa <- initialize_params(species = "flatfish", first.year = 2000,
                        observation_error = "independent")
bio <- sim_cal(pa)
sm <- sim_data(bio, pa, iter_range = 4:5, return_iter = 4,
               output_dir = "my_full_simulation")
inputs <- simulation_to_tables(sm, pa)
saveRDS(list(parameters = pa, truth = sm, inputs = inputs),
        "my_full_simulation/truth_and_inputs.rds")
str(inputs)
```

`initialize_params()` builds the flatfish preset (age-based dynamics, 20 annual time steps labelled 2000-2019 after an 80-year burn-in), `sim_cal()` derives the biological arrays and `sim_data()` runs the population: `iter_range` gives the replicate ids and seeds, each saved as `sim_rep<id>` with `save()` (read it back with `load()`), and `return_iter = 4` returns that replicate as `sm`, with the survey numbers `SN_at_len`, the retained `years` and the truth `SSB`, `Rec` and `TB` ([Simulate survey data](simulation.html#generate) lists every element). `simulation_to_tables(sm, pa)` returns the three tables with the length midpoints as rows and `sm$years` as columns; `str(inputs)` should show three 23-by-21 data frames. If the converter stops because `len_mid` differs from the replicate's recorded coordinates, pass the parameter list that generated the file.

<h2 id="plot">3. Plot the simulated observations</h2>

```r
library(ggplot2)
years <- as.numeric(names(inputs$data.CatL)[-1])
observations <- data.frame(
  Year = rep(years, each = length(pa$len_mid)),
  Length = rep(pa$len_mid, length(years)),
  Index = as.vector(as.matrix(inputs$data.CatL[-1])))
p_data <- ggplot(observations, aes(Year, Length, fill = log10(Index))) +
  geom_tile() + scale_fill_gradient(low = "white", high = "steelblue") +
  labs(fill = "log10 index") + theme_bw() +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
p_data
ggsave("my_full_simulation/survey.png", p_data, width = 10, height = 4, dpi = 160)
```

The heatmap shows the log10 survey index by year and length bin, with `pa$len_mid` as the 23 bin midpoints.

![Full flatfish simulation: survey numbers by length and year](../assets/manual/figures/cases/flatfish_data.png)

The figure shows how the survey index varies across lengths and years. Moving bands can reflect cohort growth, but several ages can contribute to one length bin; use the simulated age-specific states to track a cohort. The index is small below 10 cm, where catchability is under 0.1, and largest at 15-30 cm. Changing survey catchability changes the expected indices for a given population state.

![Generating growth curve, maturity and survey catchability](../assets/manual/figures/cases/flatfish_biology.png)

The upper panel is the growth curve, 11 cm at age 1 to 57 cm at age 15. The lower curves are maturity (L50 35 cm, from `data.mat`) and survey catchability (L50 15 cm, from `sel_L50` and `sel_L95`); your stock needs its own values.

<h2 id="fit">4. Fit both models to the replicate</h2>

```r
F_marginal_sd <- pa$F_sd / sqrt(1 - pa$F_ar^2)
pA <- list(log_Linf = log(pa$Linf), log_vbk = log(pa$vbk), t0 = pa$t0,
           log_cv_len = log(pa$cv_L), log_std_log_F = log(F_marginal_sd),
           log_std_log_N0 = log(pa$std_logN0), logit_log_R = qlogis(pa$R_ar))
pB <- list(log_Linf = log(pa$Linf), log_vbk = log(pa$vbk), log_t0 = log(pa$t0),
           log_cv_len = log(pa$cv_L), log_cv_grow = log(pa$cv_inc),
           log_sigma_log_F = log(F_marginal_sd), log_sigma_log_N0 = log(pa$std_logN0),
           logit_log_R = qlogis(pa$R_ar))
mA <- lapply(pA, function(value) factor(NA))
mB <- lapply(pB, function(value) factor(NA))
mB$logit_log_F_l <- mB$logit_log_F_y <- factor(NA)
x <- prepare_alscl_data(inputs,
  fit_args = list(rec.age = pa$rec.age, nage = pa$nage, M = pa$M,
    sel_L50 = pa$q_surv_L50, sel_L95 = pa$q_surv_L95,
    len_mid = pa$len_mid, len_border = pa$len_border[-c(1, length(pa$len_border))],
    growth_step = pa$growth_step, train_times = 2, ncores = 1, silent = TRUE),
  fit_config = list(acl = list(parameters = pA, map = mA),
                    alscl = list(parameters = pB, map = mB)))
for (model in c("acl", "alscl")) print(check_alscl_data(x, model)$summary)
a <- run_acl(x)
b <- run_alscl(x)
checks <- list(ACL = diagnose_model(x$data.CatL, a),
               ALSCL = diagnose_model(x$data.CatL, b))
c(a$diagnostics$numerical_ok, b$diagnostics$numerical_ok)
```

The input bundle `x` carries the generating biology in `fit_args` and each model's starting values and `map`, under its own parameter names, in `fit_config`. The mean growth parameters and CV of length at age are fixed to the preset values. ALSCL's growth-increment CV is fixed to its preset value, although this parameter is not used by the age-based flatfish generator. For F, `pa$F_sd` is an innovation SD, so the code converts it to the fitted models' marginal SD with `pa$F_sd / sqrt(1 - pa$F_ar^2)` (0.3023716 for this preset). The initial-abundance SD and recruitment correlation are fixed as specified fitting assumptions; both F correlations are fixed at 0.75. Each model estimates five scalar parameters.

The operating model combines a shared time series of F with selectivity. In this example the assessment models allow F to vary by group and time. Both the operating model and the assessments initialize numbers at age recursively with independent log-scale increments. The operating model is initialized before burn-in and the assessment at the start of the retained series. See [Annual and quarterly time steps](case-studies.html#annual).

`pa$len_border` runs from `-Inf` to `Inf`; dropping its ends leaves the 22 internal boundaries. `check_alscl_data()` should report 23 length bins, 20 time steps, 460 positive observations and `free_fixed` 5 for both models; the last line should print `TRUE TRUE`. Fitting time depends on the machine and optimization path; `a$elapsed` and `b$elapsed` record it for each fit. If a check fails, run `diagnose_model()` as on [Understand your first fit](first-model.html#checks) and add starts with `nstarts`.

<h2 id="truth">5. Compare the estimates with the generating truth</h2>

```r
truth <- data.frame(Year = rep(years, 3),
  Quantity = rep(c("B", "SSB", "Rec"), each = length(years)),
  Truth = c(sm$TB, sm$SSB, sm$Rec))
estimates <- rbind(
  data.frame(Year = rep(years, 3), Quantity = truth$Quantity,
    Value = c(a$report$B, a$report$SSB, a$report$Rec), Model = "ACL"),
  data.frame(Year = rep(years, 3), Quantity = truth$Quantity,
    Value = c(b$report$B, b$report$SSB, b$report$Rec), Model = "ALSCL"))
p_truth <- ggplot(estimates, aes(Year, Value, color = Model)) + geom_line() +
  geom_line(data = truth, aes(Year, Truth), inherit.aes = FALSE, linetype = 2) +
  facet_wrap(~ Quantity, scales = "free_y", ncol = 1) + theme_bw() +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
p_truth
ggsave("my_full_simulation/truth_comparison.png", p_truth,
       width = 10, height = 6, dpi = 160)
saveRDS(list(parameters = pa, truth = sm, inputs = inputs, checks = checks,
             ACL_report = a$report, ALSCL_report = b$report),
        "my_full_simulation/assessment_summary.rds")
```

The simulator calls total biomass `TB` and the fitted report calls it `B`; the code lines them up by year and quantity.

![Flatfish replicate 4: generating truth and conditional ACL/ALSCL estimates](../assets/manual/figures/cases/flatfish_truth.png)

Dashed lines are the truth, solid lines the two conditional estimates; the y scales are free, so compare within each panel. For biomass and spawning biomass, both models follow the decline to 2010 and the rise after it, and ALSCL sits below the truth for biomass and spawning biomass after 2014. One replicate of an age-based generator is shown; ranking the models needs many replicates with the failed fits kept, which [Simulate survey data](simulation.html#fit) summarizes with `summarize_simulations()`.

<h2 id="next">What next</h2>

| What you want to do | Read |
|---|---|
| Fit the quarterly tuna replicate | [Annual and quarterly time steps](case-studies.html) |
| Fit many replicates and summarize bias, RMSE and coverage | [Simulate survey data](simulation.html#fit) |
| Simulate from a fitted model and refit the draws | [Can the fitted model reproduce observations and predict withheld time steps?](case-model-validation.html) |
| Keep seeds, settings and versions | [Reproduce results and fix problems](reproducibility.html) |
