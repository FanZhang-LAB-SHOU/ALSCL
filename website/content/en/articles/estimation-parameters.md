# Estimation parameter lists

On this page you see every scalar parameter of both models, its transformation to the natural scale, and the starts and bounds of a preset. The keys are the entries of `parameters`, `parameters.L` and `parameters.U`, on the optimizer scale.

| ACL key | ALSCL key | Transform to natural scale | Meaning |
|---|---|---|---|
| `log_init_Z` | `log_init_Z` | exp |Initial equilibrium total mortality|
| `log_std_log_N0` | `log_sigma_log_N0` | exp |Initial log-number deviation SD|
| `mean_log_R` | `mean_log_R` | exp |Location of the log recruitment process|
| `log_std_log_R` | `log_sigma_log_R` | exp |Log recruitment process SD scale|
| `logit_log_R` | `logit_log_R` | plogis |Recruitment correlation restricted to (0,1)|
| `mean_log_F` | `mean_log_F` | exp |Location of the log F process|
| `log_std_log_F` | `log_sigma_log_F` | exp |F deviation SD scale|
| `logit_log_F_y` | `logit_log_F_y` | plogis |Temporal F correlation|
| `logit_log_F_a` | `logit_log_F_l` | plogis |Age/length F correlation|
| `log_vbk` | `log_vbk` | exp |Annual VB k|
| `log_Linf` | `log_Linf` | exp |Asymptotic length|
| `t0` | `log_t0` |Identity (ACL); exp (ALSCL)|VB t0; ALSCL restricts it to positive values|
| `log_cv_len` | `log_cv_len` | exp |Length-at-age CV|
| none | `log_cv_grow` | exp |Growth-increment CV|
| `log_std_index` | `log_sigma_index` | exp |Log survey observation SD|

<h2 id="inspect">1. Inspect a preset</h2>

```r
p <- create_parameters(model_type = "alscl", species = "flatfish")
keys <- names(p$parameters)
parameter_table <- data.frame(
  Parameter = keys,
  Start = unlist(p$parameters[keys]),
  Lower = unlist(p$parameters.L[keys]),
  Upper = unlist(p$parameters.U[keys]))
parameter_table
p$parameters$log_sigma_index <- log(0.15)
p$parameters.U$log_sigma_index <- log(0.5)
fixed_index <- list(log_sigma_index = factor(NA))
```

`create_parameters()` returns the three lists for the model and preset. A changed start or bound leaves the parameter free; only a `map` entry such as `fixed_index` fixes it. The random effects `dev_log_R`, `dev_log_F` and `dev_log_N0` have no key above.

<h2 id="next">What next</h2>

| What you want to do | Read |
|---|---|
| Fix or release parameters in the bundle | [Choose the fitting settings](fitting-controls.html) |
| See the default fixes and releases in a complete script | [How do I fit my own survey data?](case-fit-survey.html) |
