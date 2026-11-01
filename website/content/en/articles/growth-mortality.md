# Growth, mortality and residuals

First complete the [worked YTF example](first-model.html) to create `a`, `b`, `x` and `inputs`. Define `dat <- x$data.CatL` and load ggplot2 and patchwork. The [retrospective guide](retrospectives.html) creates `ra` and `rb`.

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

The von Bertalanffy curve of length against age from the fitted `Linf`, `k` and `t0` (printed in the corner); `se = TRUE` adds a 95% band from the parameter covariance. Growth is fixed in this example, so the band has zero width; with estimated growth the band is parameter uncertainty about the mean length at age, not the spread of individual lengths, and a wide band at old ages means `Linf` is poorly determined.

`age_range = NULL` draws the fitted age range, starting no earlier than `t0`; an explicit `age_range` must be two increasing finite ages at or after `t0`. If `se = TRUE` but the parameter covariance is unavailable, the function warns and draws the curve alone, keeping the labels, text sizes, breaks and theme you passed.

[Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_VB)

## Age length conversion

```r
# Draw this figure
plot_pla(b) + scale_x_discrete(labels = as.character(1:15))
```

[![Age length conversion](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/pla.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/pla.png?raw=true)

A heat map of the age length probability matrix `pla`: one column per age class, one row per length bin, and the fill is the probability that a fish of that age falls in that bin, so each column sums to one; the code relabels the age axis with the class index 1 to 15. Use it to see how well length identifies age; the diagonal band widens with age because growth slows and lengths overlap, and the dark cells in the largest bin at old ages are the plus group collecting all old fish.

[Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_pla)

## ACL fishing mortality year

`plot_fishing_mortality()` takes its title, axis labels, `x_breaks` and `x_expand` from `acl_theme_set()`: title keys `F_year`, `F_age` and `F_length`, with `_se` added for interval plots, and labels `xlab$year`, `xlab$age` or `xlab$length` and `ylab$F`. In age mode the horizontal coordinate is the position of the age class, so the default label reads Age Group unless you set `xlab$age`; labels and breaks given in the call take precedence. `base_theme` accepts a theme name such as `"theme_bw"` or `"bw"`, a ggplot2 theme object, or `NULL` for the global setting, and gridlines stay hidden in every case.

```r
# Draw this figure
plot_fishing_mortality(a, type = "year",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ACL fishing mortality year](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ACL_year.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ACL_year.png?raw=true)

Fishing mortality `F` of the ACL fit, one panel per age class, time on the horizontal axis and the 95% band (`se = TRUE`); `F` is an instantaneous rate per time step, so a quarterly fit shows quarterly rates. Use it to see when fishing pressure changed: the 2008 peak here appears in most age classes, and the wide bands at ages 13 to 15 show how little the survey says about old fish.

[Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)

## ACL fishing mortality age

```r
# Draw this figure
plot_fishing_mortality(a, type = "age",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ACL fishing mortality age](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ACL_age.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ACL_age.png?raw=true)

The same `F` values arranged by age: one panel per time step, the age class index on the horizontal axis (labelled Age group because the coordinate is the class position), with the 95% band. Use it to read the selection pattern of the fishery at each time step; a flat line, as here, means the ACL fit applies similar mortality to all ages, and a dome or ramp would show which ages the gear takes.

[Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)

## ALSCL fishing mortality year

```r
# Draw this figure
plot_fishing_mortality(b, type = "year",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ALSCL fishing mortality year](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_year.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_year.png?raw=true)

Fishing mortality at length `FL` of the ALSCL fit, one panel per length bin, time on the horizontal axis and the 95% band. Use it to see when pressure changed in each length bin; the 2008 peak is strongest in bins 20 to 34 here, and the bins above 44 have the lowest F because few fish of that size are taken.

[Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)

## ALSCL fishing mortality age

```r
# Draw this figure
plot_fishing_mortality(b, type = "age",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ALSCL fishing mortality age](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_age.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_age.png?raw=true)

Fishing mortality at age `FA` of the ALSCL fit, derived from `FL` through the age length matrix: one panel per time step, the age class index on the horizontal axis, with the 95% band; there is one time step and one age fewer than in the length figures because `FA` is computed between consecutive steps. Use it to compare the ALSCL selection with the ACL age figure; the dome peaking at age 3 here is the length-based F mapped onto the ages that have those lengths.

[Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)

## ALSCL fishing mortality length

```r
# Draw this figure
plot_fishing_mortality(b, type = "length",
  se = TRUE, facet_ncol = 4, line_size = 0.6)
```

[![ALSCL fishing mortality length](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_length.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/F_ALSCL_length.png?raw=true)

The same `FL` values arranged by length: one panel per time step, the length bin midpoints `len_mid` on the horizontal axis (unequal bins show as unequal spacing), with the 95% band. Use it to read the length selection of the fishery at each time step; the dome between lengths 20 and 35 here is the size the gear takes, and its height from panel to panel is the time effect.

[Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_fishing_mortality)

## Log residuals length

```r
# Draw this figure
plot_residuals(b, facet_by = "length", facet_ncol = 4, line_size = 0.6,
  x_breaks = c(2000, 2010, 2015))
```

[![Log residuals length](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/residuals_length.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/residuals_length.png?raw=true)

Log residuals, the observed minus the fitted log survey index, one panel per length bin with time on the horizontal axis: the navy line joins the residuals, the grey line is zero and the dashed teal curve is a smoother (linear with fewer than six observed time steps, loess otherwise). Use it to find bins the model misfits (zero and missing observations have no residual); residuals of one sign over many years, as in bins 16 (positive) and 20 (negative) here, mean a systematic misfit, and a trend at the end of the series, as in bin 50, points to a change the model misses.

[Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_residuals)

## Log residuals year

```r
# Draw this figure
plot_residuals(b, facet_by = "year", facet_ncol = 4, line_size = 0.6,
  x_breaks = c(10, 30, 50))
```

[![Log residuals year](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/residuals_year.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/residuals_year.png?raw=true)

The same residuals arranged by length: one panel per time step, length on the horizontal axis, with the zero line and the smoother. Use it to see whether misfit has a length pattern within a time step; the positive spike at the largest bin from 2015 on here means the survey saw more large fish than the fit in those years, and a smoother that crosses zero at the same length every year marks a length the model systematically misplaces.

[Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_residuals)

## Log process deviations R

```r
# Draw this figure
plot_deviance(b, type = "R", log = TRUE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![Log process deviations R](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_R_TRUE.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_R_TRUE.png?raw=true)

Log process deviations of recruitment (the random effects of the model, not a likelihood deviance) by time step: points are the estimates, the error bars their 95% intervals, and zero is mean recruitment. Use it to see the year-class signal the survey supports; the negative run from 2000 to 2008 here is below-average recruitment, and error bars that all cross zero would mean the survey carries little recruitment information.

[Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_deviance)

## Process multipliers R

```r
# Draw this figure
plot_deviance(b, type = "R", log = FALSE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![Process multipliers R](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_R_FALSE.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_R_FALSE.png?raw=true)

The same deviations exponentiated (`log = FALSE`): the vertical axis is the recruitment multiplier, one is the mean, and the intervals are asymmetric because they are exponentiated log intervals. Use it to read a deviation as a factor; the 2012 value of about 1.7 here means recruitment 70% above the mean, and it is the same fitted process as the log figure, so choose the scale by what the reader needs to read off.

[Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_deviance)

## Log process deviations F

```r
# Draw this figure
plot_deviance(b, type = "F", log = TRUE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![Log process deviations F](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_F_TRUE.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_F_TRUE.png?raw=true)

Log process deviations of fishing mortality, one panel per length bin (per age class for ACL, a single panel for a shared F), with points, 95% error bars and zero as the mean. Use it to see how the fitted F departs from its mean in each bin and time step; here the deviations are positive in the small and middle bins and negative above length 40, so the model raises F below 40 and lowers it above, and the dip around 2012 in bins 36 to 50 matches the low F there in the F figures.

[Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_deviance)

## Process multipliers F

```r
# Draw this figure
plot_deviance(b, type = "F", log = FALSE, se = TRUE,
  facet_ncol = 3, point_size = 1.2, line_size = 0.5) +
  scale_x_continuous(breaks = c(2000, 2010, 2019), expand = expansion(mult = 0.04))
```

[![Process multipliers F](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_F_FALSE.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/deviation_F_FALSE.png?raw=true)

The same F deviations as multipliers (`log = FALSE`), with one as the mean and asymmetric intervals. Use it to read the departure as a factor on F; a value of 0.5 in bin 48 around 2012 here means F at half its mean, and the interval widths carry over from the log scale, so the two figures agree on which cells are uncertain.

[Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_deviance)

## Length composition ridges

```r
# Draw this figure
plot_ridges(b) # Default viridis gradient
```

[![Length composition ridges](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/ridges.png?raw=true)](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/figures/ytf/ridges.png?raw=true)

Length compositions of the survey index, one ridge per time step (earliest at the bottom, colour by time step from the viridis gradient) with length on the horizontal axis: the left panel is observed, the right panel fitted, and each ridge is normalized to sum to one, so ridge height compares shape only. Use it to check that the fit reproduces the mode and spread of each time step; the mode moving from length 20 toward 25 after 2012 here is the strong cohort growing, a time step without survey data has no observed ridge, and a partly observed time step is normalized over the observed bins only.

[Arguments and defaults](https://github.com/FanZhang-LAB-SHOU/ALSCL/blob/main/docs/FUNCTION_REFERENCE.md#plot_ridges)
