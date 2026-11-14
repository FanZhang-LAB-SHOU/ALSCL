# Growth, mortality and residuals

First complete the [worked YTF example](first-model.html) to create the input bundle `x` and the fits `a` and `b`. Define `dat <- x$data.CatL` and load ggplot2 and patchwork. The [retrospective guide](retrospectives.html) creates `ra` and `rb`.

```r
library(ggplot2)
library(patchwork)
acl_theme_set(palette="npg", base_theme="theme_bw")
```

## Growth curve and interval

```r
# Draw this figure
plot_VB(b, se = TRUE)
```

[![Growth curve and interval](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/VB.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/VB.png?raw=true)

The von Bertalanffy curve is a reference calculated from the displayed `Linf`, `k` and `t0`. With `se = TRUE`, the 95% band reflects uncertainty in those parameters. All three are fixed in this example, so the band has zero width. In ALSCL, the realized mean length at age also depends on growth transitions and length-specific mortality; this reference curve does not summarize the evolving population. For the mean length at age of the fitted population, and for a comparison with age readings, use `length_at_age()`.

`age_range = NULL` draws the fitted age range, starting no earlier than `t0`; an explicit `age_range` must be two increasing finite ages at or after `t0`. If `se = TRUE` but the parameter covariance is unavailable, the function warns and draws the curve alone, keeping the labels, text sizes, breaks and theme you passed.

[Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_VB)

## Distribution of length at age

```r
# Draw this figure
plot_pla(b)
```

[![Distribution of length at age](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/pla.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/pla.png?raw=true)

Each column of the static `pla` matrix gives length-bin probabilities for one age class and sums to one. ACL uses this matrix to convert numbers at age to numbers at length in every time step. ALSCL uses it to initialize the population and assign lengths to recruits; subsequent length distributions follow growth and survival. To obtain the realized distribution at a given age and time in ALSCL, normalize the corresponding length vector in `NLA`. The colour shows the probability in each bin, and the last bin includes the upper tail. The horizontal axis shows the fitted ages, and the oldest age, a plus group, is marked "15+". A result saved without age metadata is plotted against the position of the age class, and its axis label reads Age group.

[Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_pla)

A panel or model group containing only one estimate is shown as a point. With `se = TRUE`, an error bar shows the 95% interval (lognormal by default; see the `interval` argument) because a one-point ribbon has no visible width. This applies to population and fishing-mortality plots and to each model separately in `plot_compare_ts()`. Point size follows `point_size`; single-model points retain `line_color` and intervals retain `se_color`. Panels remain free of gridlines.

## ACL fishing mortality over time by age class

`plot_fishing_mortality()` takes its title, axis labels, `x_breaks` and `x_expand` from `acl_theme_set()`: title keys `F_year`, `F_age` and `F_length`, with `_se` added for interval plots, and labels `xlab$year`, `xlab$age` or `xlab$length` and `ylab$F`. In age mode the horizontal axis shows the fitted ages, and the plus group is marked as in "15+"; an ALSCL plot with intervals (`se = TRUE`) shows the ages before the plus group. A result saved without age metadata is plotted against the position of the age class, and its default label reads Age group unless you set `xlab$age`. The default `ylab$F` label states the time basis of the rate, for example "Fishing mortality rate (per year)"; labels and breaks given in the call take precedence. `base_theme` accepts a theme name such as `"theme_bw"` or `"bw"`, a ggplot2 theme object, or `NULL` for the global setting, and gridlines stay hidden in every case.

```r
# Draw this figure
plot_fishing_mortality(a, type = "year",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ACL fishing mortality over time by age class](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ACL_year.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ACL_year.png?raw=true)

Each panel shows the estimated instantaneous fishing mortality rate (`F`) for one ACL age class, with its approximate 95% interval. F is expressed per model time step. The time step is one year here and one quarter in a quarterly fit.

[Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)

## ACL fishing mortality at age by time step

```r
# Draw this figure
plot_fishing_mortality(a, type = "age",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ACL fishing mortality at age by time step](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ACL_age.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ACL_age.png?raw=true)

Each panel shows the same ACL estimates for one time step, with the fitted ages on the horizontal axis (the plus group is marked "15+") and approximate 95% intervals. In most years of this example the profiles are nearly flat, which indicates similar estimated fishing mortality across ages; from 2007 to 2010 the estimates are higher at the younger ages.

[Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)

## ALSCL fishing mortality over time by length bin

```r
# Draw this figure
plot_fishing_mortality(b, type = "year",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ALSCL fishing mortality over time by length bin](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_year.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_year.png?raw=true)

Each panel shows how fishing mortality at length (`FL`) changes over time for one length bin, with an approximate 95% interval. The estimated peak around 2008 is most pronounced at intermediate lengths.

[Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)

## ALSCL fishing mortality at age by time step

```r
# Draw this figure
plot_fishing_mortality(b, type = "age",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ALSCL fishing mortality at age by time step](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_age.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_age.png?raw=true)

For each age class, ALSCL sums the numbers surviving across length bins and divides by the number present at the start of the step. Fishing mortality at age is `FA = -log(survival proportion) - M`. Each panel shows the estimates and approximate 95% intervals for one time step. The figure is drawn with `se = TRUE`, so it shows the cells that have standard errors: the ages before the plus group (ages 1 to 14) and the time steps before the last (2000 to 2018). These are the cells of `report$FA`, and `report$ZA` holds the matching total mortality at age. Without intervals (`se = FALSE`) the function also draws the plus group ("15+") and the last time step, which it computes from the reported numbers at length and age (`report$NLA`) and total mortality at length (`report$ZL`) with the same formula. F in the last time step is predicted by the F process; no observation informs it. `extract_estimates(b, "FA")` returns F at age for every age and time step; its standard errors are `NA` for the plus group and the last time step.

[Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)

## ALSCL fishing mortality at length by time step

```r
# Draw this figure
plot_fishing_mortality(b, type = "length",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ALSCL fishing mortality at length by time step](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_length.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_length.png?raw=true)

Each panel shows fishing mortality at length for one time step, with an approximate 95% interval. Length-bin midpoints (`len_mid`) are plotted at their actual spacing. In this example, estimated fishing mortality is higher at intermediate lengths, around 20 to 35.

[Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)

## Log residuals by length bin

```r
# Draw this figure
plot_residuals(b, facet_by = "length", facet_ncol = 4, line_size = 0.6,
  x_breaks = c(2000, 2010, 2015))
```

[![Log residuals by length bin](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/residuals_length.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/residuals_length.png?raw=true)

Log residuals, the observed minus the fitted log survey index, one panel per length bin with time on the horizontal axis: the navy line joins the residuals, the grey line is zero and the dashed teal curve is a smoother. Use it to find bins the model misfits (zero and missing observations have no residual); residuals of one sign over many years, as in bins 16 (positive) and 20 (negative) here, mean a systematic misfit, and a trend at the end of the series, as in bin 50, points to a change the model misses.

Within each facet, a missing or excluded observation breaks the residual line and its trend. A single observed value is drawn as a point. Each consecutive run of 2–5 observations has a linear trend, and a run of 6 or more uses loess.

[Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_residuals)

## Log residuals by time step

```r
# Draw this figure
plot_residuals(b, facet_by = "year", facet_ncol = 4, line_size = 0.6,
  x_breaks = c(10, 30, 50))
```

[![Log residuals by time step](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/residuals_year.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/residuals_year.png?raw=true)

The same residuals arranged by length: one panel per time step, with length on the horizontal axis, a zero line and a smoother. Look for length ranges with residuals persistently above or below zero. The positive spikes in the largest bin from 2015 onward indicate observed indices above the fitted values in those years. Repeated changes in sign can suggest length-dependent misfit; the smoother crossing zero at a particular length is not itself evidence of bias at that length.

[Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_residuals)

## Log recruitment deviations

```r
# Draw this figure
plot_deviance(b, type = "R", log = TRUE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![Log recruitment deviations](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_R_TRUE.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_R_TRUE.png?raw=true)

The points are estimated log recruitment deviations and the bars are approximate 95% intervals. Zero corresponds to the median recruitment of the fitted process, `exp(mean_log_R)`. A negative estimate indicates recruitment below that median.

[Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_deviance)

## Recruitment relative to the process median

```r
# Draw this figure
plot_deviance(b, type = "R", log = FALSE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![Recruitment relative to the process median](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_R_FALSE.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_R_FALSE.png?raw=true)

With `log = FALSE`, each point is recruitment divided by the process median. A ratio of 1.77, as in 2012, means that estimated recruitment was 77% above that median. The interval endpoints are exponentiated from the log scale.

[Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_deviance)

## Log fishing mortality deviations

```r
# Draw this figure
plot_deviance(b, type = "F", log = TRUE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![Log fishing mortality deviations](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_F_TRUE.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_F_TRUE.png?raw=true)

Points and approximate 95% intervals show log fishing mortality deviations over time. Zero corresponds to the process median, `exp(mean_log_F)`, on the original scale. ALSCL shows one panel per length bin, ACL one per age class. A fit with shared F has one panel.

[Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_deviance)

## Fishing mortality relative to the process median

```r
# Draw this figure
plot_deviance(b, type = "F", log = FALSE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![Fishing mortality relative to the process median](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_F_FALSE.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_F_FALSE.png?raw=true)

Each point is the fitted fishing mortality rate divided by the process median. A ratio of 0.5 means fishing mortality was half that median. The error bars show the approximate 95% intervals after exponentiation.

[Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_deviance)

## Length composition ridges

```r
# Draw this figure
plot_ridges(b) # Default viridis gradient
```

[![Length composition ridges](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/ridges.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/ridges.png?raw=true)

Each ridge shows the relative survey index across lengths in one time step, with observations on the left and the fit on the right. `plot_ridges()` returns a patchwork object with one figure title and a title on each panel; `p[[1]]` and `p[[2]]` extract the observed and the fitted panel. The time axis shows years for annual fits and quarters, as in "2000 Q2", for quarterly fits. The peak shifts toward larger lengths after 2012. Compare the position and spread of the distributions. A step with no observations has no observed ridge, and a partially observed step is normalized over the observed bins only.

Missing or excluded length bins break the observed outline and fill. An isolated observed bin is drawn as a point at its scaled composition height; normalization still uses all positive observations in that period. Both panels keep the same time positions, vertical range and time colors, including periods without observations. Brewer palettes such as `spectral` also support two-period results.

[Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_ridges)

Both ridge panels retain the full model length range, even when the shortest or longest bins are unobserved or all observations are missing. Custom `x_breaks` and global `x_expand` apply to both panels. `ridges_scale` must be `NULL` (automatic height) or one finite positive number; zero, negative values, missing values, infinity and vectors are rejected.

## Missing boundary length bins

This synthetic illustration has no observations in the two smallest or two largest length bins, and no observations in the first period. Both panels still span 10–90 length units and keep all four time positions. The observed composition uses the remaining bins; the fitted composition uses all bins, so their normalizing totals differ. Blank areas are not zero observations.

```r
# Synthetic display example with missing boundary length bins.
lengths <- seq(10, 90, 10)
years <- 2000:2003
log_index <- outer(lengths, seq(35, 50, 5),
  function(length, center) -((length - center) / 18)^2)
ridge_example <- list(year = years, len_mid = lengths,
  observations = exp(log_index), report = list(Elog_index = log_index))
ridge_example$observations[c(1, 2, 8, 9), ] <- NA_real_
ridge_example$observations[, 1L] <- NA_real_
plot_ridges(ridge_example, ridges_scale = 1,
  x_breaks = seq(10, 90, 20))
```

![Missing boundary length bins](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/sparse-panels/ridges-missing-edges.png?raw=true)
