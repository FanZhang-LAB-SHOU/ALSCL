# North Sea whiting case study: numbers and figures of the article
# website/content/{en,zh}/articles/case-north-sea-whiting.md, computed from
# the fits saved by scripts/whiting_case.R.
# Run from the repository root: Rscript scripts/whiting_case.R report
# Every number that the article quotes is written to
# docs/results/whiting-case/numbers.csv; the other tables in that folder hold
# the values behind the figures.

if (!exists("whiting_case_inputs")) source("scripts/whiting_case.R", encoding = "UTF-8")
library(ggplot2)
library(patchwork)
source("scripts/plot_helpers.R")

report_whiting_case <- function(dir = whiting_case_dir(), out = "docs") {
  # Committed figures and tables must come from the code of this checkout.
  if (grepl("^(\\./)?docs(/|$)", out)) require_checkout_alscl()
  inputs <- whiting_case_inputs()
  x <- inputs$x
  years <- x$provenance$years
  mid <- x$fit_args$len_mid
  names_fit <- c("quick", "alscl", "acl", "acl_fixed", "alscl_M", "alscl_q")
  fit <- lapply(stats::setNames(names_fit, names_fit),
                function(n) read_assessment(file.path(dir, paste0(n, ".rds"))))
  label <- c(quick = "ALSCL, 1983-2002", alscl = "ALSCL", acl = "ACL", acl_fixed = "ACL, standard deviation of initial numbers fixed",
             alscl_M = "ALSCL, M by age and year", alscl_q = "ALSCL, catchability declining with length")
  res <- file.path(out, "results", "whiting-case")
  fig <- file.path(out, "figures", "whiting-case")
  dir.create(res, recursive = TRUE, showWarnings = FALSE)
  dir.create(fig, recursive = TRUE, showWarnings = FALSE)
  old <- acl_theme(); on.exit(do.call(acl_theme_set, old), add = TRUE)
  acl_theme_set(palette = "npg", base_theme = "theme_bw")
  plain <- theme_bw() + theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank())
  save_plot <- function(id, p, width = 9, height = 5)
    save_grid_free_plot(file.path(fig, paste0(id, ".png")), p, width = width, height = height,
                        dpi = 160, bg = "white")
  numbers <- list()
  num <- function(id, value, description) {
    numbers[[length(numbers) + 1L]] <<- data.frame(id = id, value = signif(value, 6),
                                                    description = description)
    invisible(value)
  }
  lcor <- function(a, b) { ok <- is.finite(a) & is.finite(b) & a > 0 & b > 0; stats::cor(log(a[ok]), log(b[ok])) }
  periods <- list("1983-1999" = 1983:1999, "2000-2012" = 2000:2012, "2013-2025" = 2013:2025)
  by_period <- function(v, y = years) vapply(periods, function(p) mean(v[y %in% p], na.rm = TRUE), 1)
  # Fishing or total mortality rate by age and year: FA and ZA in an ALSCL report, F and Z in an ACL report.
  # ALSCL gives the rates from one year to the next, so it has none for the last year.
  at_age <- function(r, what) {
    m <- if (is.null(r[[paste0(what, "A")]])) r[[what]] else r[[paste0(what, "A")]]
    if (ncol(m) < length(years)) cbind(m, NA) else m
  }

  # ---- data -------------------------------------------------------------------
  index <- as.matrix(x$data.CatL[-1L])
  cover <- x$survey_coverage
  num("data_bins", nrow(index), "Number of length bins")
  num("data_years", ncol(index), "Number of years")
  num("data_hauls_min", min(cover$hauls), "Smallest number of hauls in a year")
  num("data_hauls_min_year", cover$year[which.min(cover$hauls)], "Year with the smallest number of hauls")
  num("data_hauls_max", max(cover$hauls), "Largest number of hauls in a year")
  num("data_missing_2009", cover$hauls_missing[cover$year == 2009], "Valid hauls of 2009 absent from the DATRAS product")
  num("data_missing_2012", cover$hauls_missing[cover$year == 2012], "Valid hauls of 2012 absent from the DATRAS product")
  total <- colSums(index)
  num("data_index_min", min(total), "Smallest annual index summed over length (number per hour)")
  num("data_index_min_year", years[which.min(total)], "Year of the smallest annual index")
  num("data_index_max", max(total), "Largest annual index summed over length (number per hour)")
  num("data_index_max_year", years[which.max(total)], "Year of the largest annual index")
  obs <- data.frame(Year = rep(years, each = length(mid)), Length = rep(mid, length(years)),
                    Value = as.vector(index))
  save_plot("index", ggplot(obs, aes(Year, Length, fill = log10(Value))) + geom_tile() +
    scale_fill_gradient(low = acl_theme("low_col"), high = acl_theme("high_col")) +
    labs(x = "Year", y = "Length (cm)", fill = "log10 of the survey index\n(number per hour)") + plain,
    height = 4)

  # ---- numerical checks and starts ---------------------------------------------
  at_bound <- function(f) {
    p <- f$par_low_up
    hit <- abs(p[, "estimate"] - p[, "lower"]) < 1e-4 | abs(p[, "estimate"] - p[, "upper"]) < 1e-4
    paste(rownames(p)[hit], collapse = " ")
  }
  checks <- do.call(rbind, lapply(names_fit, function(n) {
    f <- fit[[n]]; d <- f$diagnostics; s <- f$start_summary
    data.frame(fit = n, label = label[[n]], objective = f$opt$objective, parameters = length(f$opt$par),
      convergence_code = f$convergence_code, max_gradient = f$max_abs_gradient,
      pdHess = isTRUE(f$pdHess), numerical_ok = isTRUE(d$numerical_ok),
      starts = s$nstarts, starts_converged = s$converged, starts_agree = s$agree_with_best,
      objective_range = s$objective_range, elapsed_seconds = round(f$case_elapsed),
      at_bound = at_bound(f), issues = paste(d$issues, collapse = "; "),
      advice = paste(d$advice, collapse = " | "),
      notes = paste(d$plausibility$note, collapse = " | "))
  }))
  utils::write.csv(checks, file.path(res, "checks.csv"), row.names = FALSE)
  starts <- do.call(rbind, lapply(names_fit, function(n) {
    s <- fit[[n]]$start_diagnostics
    data.frame(fit = n, start = s$start_id, objective = s$objective, convergence = s$convergence,
               elapsed_seconds = round(s$elapsed))
  }))
  utils::write.csv(starts, file.path(res, "starts.csv"), row.names = FALSE)
  for (n in names_fit) {
    f <- fit[[n]]
    num(paste0(n, "_objective"), f$opt$objective, paste("Objective (negative log-likelihood),", label[[n]]))
    num(paste0(n, "_numerical_ok"), as.numeric(isTRUE(f$diagnostics$numerical_ok)),
        paste("Numerical checks passed (1) or failed (0),", label[[n]]))
    num(paste0(n, "_starts_agree"), f$start_summary$agree_with_best,
        paste("Starts that reached the lowest objective,", label[[n]]))
    num(paste0(n, "_minutes"), f$case_elapsed / 60, paste("Wall-clock time of the fit in minutes,", label[[n]]))
    num(paste0(n, "_minutes_per_start"), mean(f$start_diagnostics$elapsed) / 60,
        paste("Mean time per start in minutes,", label[[n]]))
    num(paste0(n, "_max_gradient"), f$max_abs_gradient, paste("Largest absolute gradient,", label[[n]]))
    num(paste0(n, "_parameters"), length(f$opt$par), paste("Number of estimated scalar parameters,", label[[n]]))
    num(paste0(n, "_worst_start"), max(f$start_diagnostics$objective), paste("Highest objective among the starts,", label[[n]]))
  }
  # The start of the main fit that stopped at the highest objective.
  worst <- fit$alscl$starts[[which.max(fit$alscl$start_diagnostics$objective)]]$par
  num("alscl_worst_start_cv_grow", exp(worst[["log_cv_grow"]]), "cv_grow at the start of the main fit with the highest objective")
  num("alscl_worst_start_Linf", exp(worst[["log_Linf"]]), "Linf (cm) at the start of the main fit with the highest objective")
  num("alscl_worst_start_k", exp(worst[["log_vbk"]]), "k (per year) at the start of the main fit with the highest objective")
  num("acl_sd_initial_numbers", exp(fit$acl$par_low_up["log_std_log_N0", "estimate"]),
      "Standard deviation of the initial numbers at age estimated by the first ACL fit")
  num("acl_fixed_objective_change", fit$acl_fixed$opt$objective - fit$acl$opt$objective,
      "Objective of the ACL fit with that standard deviation fixed at 0.05 minus the objective of the first ACL fit")
  num("acl_fixed_correlation_k_t0", max(abs(fit$acl_fixed$diagnostics$high_correlations$correlation)),
      "Largest absolute correlation between two parameter estimates, ACL with the standard deviation fixed")
  estimates <- do.call(rbind, lapply(names_fit, function(n) {
    r <- fit[[n]]$report
    data.frame(fit = n, Linf = r$Linf, k = r$vbk, t0 = r$t0, cv_len = r$cv_len,
      cv_grow = if (is.null(r$cv_grow)) NA else r$cv_grow,
      sd_index = if (is.null(r$sigma_index)) r$std_index else r$sigma_index,
      init_Z = exp(fit[[n]]$par_low_up["log_init_Z", "estimate"]))
  }))
  utils::write.csv(estimates, file.path(res, "estimates.csv"), row.names = FALSE)
  for (n in names_fit) for (v in c("Linf", "k", "t0", "cv_grow", "sd_index", "init_Z"))
    if (is.finite(estimates[estimates$fit == n, v]))
      num(paste0(n, "_", v), estimates[estimates$fit == n, v], paste("Estimate of", v, "-", label[[n]]))

  # ---- mean length at age against age readings ---------------------------------
  full <- c("alscl", "acl_fixed", "alscl_M", "alscl_q")
  read <- x$age_readings$length_at_age
  read_all <- read[read$period == "1983-2026" & read$age <= 9, ]
  model_length <- function(n, basis = "survey") {
    tab <- length_at_age(fit[[n]], basis)
    as.numeric(tapply(tab$mean_length, tab$age, mean))[1:9]
  }
  lengths <- data.frame(age = 1:9, age_readings = read_all$mean_length, age_readings_sd = read_all$sd_length,
                        sapply(stats::setNames(full, full), model_length))
  utils::write.csv(lengths, file.path(res, "length_at_age.csv"), row.names = FALSE)
  for (a in 1:9) {
    num(paste0("length_readings_age", a), lengths$age_readings[a], paste("Mean length at age", a, "from age readings, 1983-2026 (cm)"))
    for (n in full)
      num(paste0("length_", n, "_age", a), lengths[[n]][a],
          paste0("Mean length at age ", a, " as the survey sees it, mean of 1983-2026 (cm), ", label[[n]]))
  }
  for (n in full) {
    d <- lengths[[n]] - lengths$age_readings
    num(paste0("length_", n, "_maxdiff_1_4"), max(abs(d[1:4])), paste("Largest absolute difference from age readings at ages 1 to 4 (cm),", label[[n]]))
    num(paste0("length_", n, "_mindiff_1_9"), min(d), paste("Smallest difference (model minus age readings) at ages 1 to 9 (cm),", label[[n]]))
    num(paste0("length_", n, "_maxdiff_1_9"), max(d), paste("Largest difference (model minus age readings) at ages 1 to 9 (cm),", label[[n]]))
    for (a in c(1, 5, 7, 9)) num(paste0("length_", n, "_diff_", a), d[a], paste0("Model minus age readings at age ", a, " (cm), ", label[[n]]))
  }
  decade <- read[read$period != "1983-2026" & read$age == 5, ]
  num("length_readings_age5_min", min(decade$mean_length), "Smallest mean length at age 5 among the decades, age readings (cm)")
  num("length_readings_age5_max", max(decade$mean_length), "Largest mean length at age 5 among the decades, age readings (cm)")
  cv <- read_all$sd_length / read_all$mean_length
  num("cv_readings_ages_1_3", mean(cv[1:3]), "Mean coefficient of variation of length at ages 1 to 3, age readings")
  long <- rbind(
    data.frame(Age = 1:9, Length = lengths$alscl, Source = "ALSCL"),
    data.frame(Age = 1:9, Length = lengths$acl_fixed, Source = "ACL"))
  cols <- stats::setNames(acl_theme("compare_colors"), c("ACL", "ALSCL"))
  save_plot("length_at_age", ggplot(long, aes(Age, Length)) +
    geom_line(aes(colour = Source)) +
    geom_pointrange(data = lengths, aes(age, age_readings, ymin = age_readings - age_readings_sd,
                                        ymax = age_readings + age_readings_sd), size = 0.3) +
    scale_colour_manual(values = cols) + scale_x_continuous(breaks = 1:9) +
    labs(x = "Age (years)", y = "Mean length at age in the survey catch (cm)", colour = NULL,
         subtitle = "Points: age readings, mean and one standard deviation; lines: fitted models") + plain,
    width = 7, height = 4.5)

  # ---- index at age and apparent total mortality -------------------------------
  # The index at age that a fit implies: numbers by length and age times survey
  # catchability at length, summed over length.
  q_logistic <- survey_catchability(mid, "logistic", L50 = x$fit_args$sel_L50, L95 = x$fit_args$sel_L95)
  q_used <- list(alscl = q_logistic, alscl_M = q_logistic, alscl_q = inputs$q_dome)
  seen <- lapply(stats::setNames(names(q_used), names(q_used)), function(n)
    apply(sweep(fit[[n]]$report$NLA, 1, q_used[[n]], "*"), c(2, 3), sum))
  key <- fit$acl_fixed$report$pla
  seen$acl_fixed <- fit$acl_fixed$report[["NA"]] * colSums(key * q_logistic)
  ia <- t(x$age_readings$index_at_age)                       # age x year
  decline <- function(m, yrs = years[-length(years)], ages = 2:5) {
    y <- match(yrs, years)
    mean(unlist(lapply(ages, function(a) log(m[a, y] / m[a + 1, y + 1]))))
  }
  z_rows <- do.call(rbind, lapply(names(periods), function(p) {
    yrs <- periods[[p]]
    data.frame(period = p, age_readings = decline(ia, yrs),
      sapply(seen, decline, yrs = yrs, simplify = FALSE),
      Z_alscl = mean(at_age(fit$alscl$report, "Z")[2:5, years %in% yrs]),
      Z_ices = mean(x$ices$assessment$f_ages_2_5[x$ices$assessment$year %in% yrs]) +
        mean(x$ices$M[2:5, colnames(x$ices$M) %in% yrs]))
  }))
  utils::write.csv(z_rows, file.path(res, "apparent_Z.csv"), row.names = FALSE)
  for (i in seq_len(nrow(z_rows))) {
    p <- gsub("-", "_", z_rows$period[i])
    num(paste0("Z_readings_", p), z_rows$age_readings[i], paste("Decline of the log index of a cohort per year, ages 2 to 5, age readings,", z_rows$period[i]))
    num(paste0("Z_seen_alscl_", p), z_rows$alscl[i], paste("Same decline in the index at age implied by ALSCL,", z_rows$period[i]))
    num(paste0("Z_seen_acl_", p), z_rows$acl_fixed[i], paste("Same decline in the index at age implied by ACL,", z_rows$period[i]))
    num(paste0("Z_ices_", p), z_rows$Z_ices[i], paste("ICES mean F at ages 2 to 5 plus mean ICES M at ages 2 to 5,", z_rows$period[i]))
  }
  num("Z_readings_all", decline(ia), "Decline of the log index of a cohort per year, ages 2 to 5, age readings, 1983-2025")
  num("Z_seen_alscl_all", decline(seen$alscl), "Same decline in the index at age implied by ALSCL, 1983-2025")
  for (a in 1:2) for (n in c("alscl", "acl_fixed"))
    num(paste0("cor_index_age", a, "_", n), lcor(ia[a, ], seen[[n]][a, ]),
        paste0("Correlation of the log index at age ", a, " between age readings and the fit, ", label[[n]]))

  # ---- comparison with the ICES assessment --------------------------------------
  ices <- x$ices$assessment
  at <- function(v, lag = 0) v[match(years - lag, ices$year)]
  ices_ssb <- at(ices$ssb); ices_f <- at(ices$f_ages_2_5); ices_catch <- at(ices$catch)
  ices_rec <- at(ices$recruitment_age0, lag = 1)     # age 0 in year y - 1 is age 1 in quarter 1 of year y
  # Maturity at age of the assessment for the ages and years of the model: ages
  # 6 to 10 take the plus group, years outside 1991-2021 the nearest year.
  mat_year <- pmin(pmax(years, 1991), 2021)
  maturity <- x$ices$maturity[c(1:6, 6, 6, 6, 6), as.character(mat_year)]
  series <- do.call(rbind, lapply(full, function(n) {
    f <- fit[[n]]; r <- f$report
    catch <- relative_catch(f, years = 1983:2025)
    data.frame(fit = n, year = years, SSB = as.numeric(r$SSB), SSB_maturity_at_age = ssb_at_age(f, maturity)$SSB,
      recruitment = as.numeric(r$Rec), F_ages_2_5 = colMeans(at_age(r, "F")[2:5, ]),
      Z_ages_2_5 = colMeans(at_age(r, "Z")[2:5, ]),
      relative_catch_weight = catch$catch_weight, catch_extrapolated = catch$extrapolated)
  }))
  series <- rbind(series, data.frame(fit = "ices", year = years, SSB = ices_ssb, SSB_maturity_at_age = NA,
    recruitment = ices_rec, F_ages_2_5 = ices_f, Z_ages_2_5 = NA,
    relative_catch_weight = ices_catch / mean(ices_catch, na.rm = TRUE), catch_extrapolated = FALSE))
  utils::write.csv(series, file.path(res, "series.csv"), row.names = FALSE)
  compare <- do.call(rbind, lapply(full, function(n) {
    s <- series[series$fit == n, ]
    f_period <- by_period(replace(s$F_ages_2_5, s$year == max(years), NA))
    data.frame(fit = n, cor_log_SSB = lcor(s$SSB, ices_ssb),
      cor_log_SSB_maturity_at_age = lcor(s$SSB_maturity_at_age, ices_ssb),
      cor_log_recruitment = lcor(s$recruitment, ices_rec),
      cor_log_catch = lcor(replace(s$relative_catch_weight, s$catch_extrapolated, NA), ices_catch),
      rank_cor_F = stats::cor(s$F_ages_2_5, ices_f, method = "spearman", use = "complete.obs"),
      F_1983_1999 = f_period[[1]], F_2000_2012 = f_period[[2]], F_2013_2025 = f_period[[3]])
  }))
  ices_f_period <- by_period(ices_f)
  compare <- rbind(compare, data.frame(fit = "ices", cor_log_SSB = NA, cor_log_SSB_maturity_at_age = NA,
    cor_log_recruitment = NA, cor_log_catch = NA, rank_cor_F = NA, F_1983_1999 = ices_f_period[[1]],
    F_2000_2012 = ices_f_period[[2]], F_2013_2025 = ices_f_period[[3]]))
  utils::write.csv(compare, file.path(res, "comparison_ices.csv"), row.names = FALSE)
  for (n in c(full, "ices")) {
    row <- compare[compare$fit == n, ]
    who <- if (n == "ices") "ICES assessment" else label[[n]]
    for (v in setdiff(names(compare), "fit")) if (is.finite(row[[v]]))
      num(paste0(v, "_", n), row[[v]], paste0(gsub("_", " ", v), ", ", who))
  }
  ices_M_adult <- mean(x$ices$M[2:5, ])
  num("ices_M_ages_2_5", ices_M_adult, "Mean ICES natural mortality rate at ages 2 to 5, 1983-2022 (per year)")
  for (a in 1:6) num(paste0("ices_M_age", a), mean(x$ices$M[a, ]),
                     paste("Mean ICES natural mortality rate, 1983-2022, age", rownames(x$ices$M)[a], "(per year)"))
  ratio <- function(v) mean(utils::tail(v, 10)) / mean(utils::head(v, 10))
  num("SSB_last10_over_first10_alscl", ratio(series$SSB[series$fit == "alscl"]), "Mean SSB of 2017-2026 divided by the mean of 1983-1992, ALSCL")
  num("SSB_last10_over_first10_acl_fixed", ratio(series$SSB[series$fit == "acl_fixed"]), "Mean SSB of 2017-2026 divided by the mean of 1983-1992, ACL")
  num("SSB_last10_over_first10_ices", ratio(ices_ssb), "Mean SSB of 2017-2026 divided by the mean of 1983-1992, ICES assessment")
  num("SSB_lowest_year_alscl", years[which.min(series$SSB[series$fit == "alscl"])], "Year of the lowest SSB, ALSCL")
  num("SSB_lowest_year_ices", years[which.min(ices_ssb)], "Year of the lowest SSB, ICES assessment")
  ssb <- series[series$fit == "alscl", ]
  num("cor_SSB_two_maturities", lcor(ssb$SSB, ssb$SSB_maturity_at_age),
      "Correlation of log SSB from maturity at length and from ICES maturity at age, ALSCL")
  standard <- function(v) { w <- log(v); (w - mean(w, na.rm = TRUE)) / stats::sd(w, na.rm = TRUE) }
  trend <- function(quantity, column) rbind(
    data.frame(Year = years, Quantity = quantity, Source = "ALSCL", Value = standard(series[series$fit == "alscl", column])),
    data.frame(Year = years, Quantity = quantity, Source = "ICES assessment", Value = standard(series[series$fit == "ices", column])))
  panels <- rbind(trend("Spawning biomass (log, standardized)", "SSB"),
                  trend("Recruitment at age 1 (log, standardized)", "recruitment"),
                  data.frame(Year = years, Quantity = "Mean fishing mortality rate, ages 2 to 5 (per year)",
                             Source = rep(c("ALSCL", "ICES assessment"), each = length(years)),
                             Value = c(replace(series$F_ages_2_5[series$fit == "alscl"], length(years), NA), ices_f)))
  panels$Quantity <- factor(panels$Quantity, unique(panels$Quantity))
  two <- stats::setNames(acl_theme("compare_colors")[2:1], c("ALSCL", "ICES assessment"))
  save_plot("ices_comparison", ggplot(panels[is.finite(panels$Value), ], aes(Year, Value, colour = Source)) +
    geom_line() + facet_wrap(~Quantity, ncol = 1, scales = "free_y") + scale_colour_manual(values = two) +
    labs(x = "Year", y = NULL, colour = NULL) + plain + theme(legend.position = "top"), width = 8, height = 7.5)

  # ---- sensitivity fits -----------------------------------------------------------
  M_mean <- rowMeans(inputs$M_ices)
  in_cols <- stats::setNames(acl_theme("compare_colors"), c("Main fit", "Sensitivity fit"))
  q_curves <- rbind(data.frame(Length = mid, Value = q_logistic, Input = "Main fit"),
                    data.frame(Length = mid, Value = inputs$q_dome, Input = "Sensitivity fit"))
  M_curves <- rbind(data.frame(Age = 1:10, Value = x$fit_args$M, Input = "Main fit"),
                    data.frame(Age = 1:10, Value = M_mean, Input = "Sensitivity fit"))
  M_range <- data.frame(Age = 1:10, low = apply(inputs$M_ices, 1, min), high = apply(inputs$M_ices, 1, max))
  p_q <- ggplot(q_curves, aes(Length, Value, colour = Input)) + geom_line() + geom_point(size = 1) +
    scale_colour_manual(values = in_cols) + expand_limits(y = 0) +
    labs(x = "Length (cm)", y = "Survey catchability", colour = NULL) + plain
  p_M <- ggplot(M_curves, aes(Age, Value, colour = Input)) +
    geom_linerange(data = M_range, aes(x = Age, ymin = low, ymax = high), inherit.aes = FALSE,
                   colour = in_cols[["Sensitivity fit"]], alpha = 0.4) +
    geom_line() + geom_point(size = 1) + scale_colour_manual(values = in_cols) +
    scale_x_continuous(breaks = 1:10) + expand_limits(y = 0) +
    labs(x = "Age (years)", y = "Natural mortality rate (per year)", colour = NULL,
         subtitle = "Bars: range over the years") + plain
  save_plot("sensitivity_inputs", (p_q | p_M) + plot_layout(guides = "collect") &
    theme(legend.position = "top"), width = 9, height = 4.2)
  num("q_dome_at_30", inputs$q_dome[mid == 31], "Survey catchability of the sensitivity fit in the bin labelled 31 cm")
  num("q_dome_at_43", inputs$q_dome[mid == 43], "Survey catchability of the sensitivity fit in the last length bin")
  num("q_dome_max", max(inputs$q_dome), "Largest survey catchability of the sensitivity fit")
  base <- series[series$fit == "alscl", ]
  sens <- do.call(rbind, lapply(c("alscl_M", "alscl_q"), function(n) {
    s <- series[series$fit == n, ]
    data.frame(fit = n, objective_change = fit[[n]]$opt$objective - fit$alscl$opt$objective,
      cor_log_SSB_with_main = lcor(s$SSB, base$SSB), cor_log_recruitment_with_main = lcor(s$recruitment, base$recruitment),
      SSB_ratio_to_main = mean(s$SSB) / mean(base$SSB), recruitment_ratio_to_main = mean(s$recruitment) / mean(base$recruitment),
      F_ratio_to_main = mean(s$F_ages_2_5[-length(years)]) / mean(base$F_ages_2_5[-length(years)]))
  }))
  utils::write.csv(sens, file.path(res, "sensitivity.csv"), row.names = FALSE)
  for (i in seq_len(nrow(sens))) for (v in setdiff(names(sens), "fit"))
    num(paste0(v, "_", sens$fit[i]), sens[[v]][i], paste0(gsub("_", " ", v), ", ", label[[sens$fit[i]]]))
  relative <- function(v) v / mean(v)
  three <- c(alscl = "Main fit", alscl_M = "M by age and year", alscl_q = "Catchability declining with length")
  lines <- do.call(rbind, lapply(names(three), function(n) {
    s <- series[series$fit == n, ]
    rbind(data.frame(Year = years, Quantity = "Spawning biomass divided by its mean", Fit = three[[n]], Value = relative(s$SSB)),
          data.frame(Year = years, Quantity = "Recruitment divided by its mean", Fit = three[[n]], Value = relative(s$recruitment)),
          data.frame(Year = years, Quantity = "Mean fishing mortality rate, ages 2 to 5 (per year)", Fit = three[[n]],
                     Value = replace(s$F_ages_2_5, length(years), NA)))
  }))
  lines <- rbind(lines, data.frame(Year = years, Quantity = "Mean fishing mortality rate, ages 2 to 5 (per year)",
                                   Fit = "ICES assessment", Value = ices_f))
  lines$Quantity <- factor(lines$Quantity, unique(lines$Quantity)); lines$Fit <- factor(lines$Fit, c(three, "ICES assessment"))
  save_plot("sensitivity_results", ggplot(lines[is.finite(lines$Value), ], aes(Year, Value, colour = Fit, linetype = Fit)) +
    geom_line() + facet_wrap(~Quantity, ncol = 1, scales = "free_y") +
    scale_colour_manual(values = c(unname(two[1]), "grey35", "grey35", unname(two[2]))) +
    scale_linetype_manual(values = c("solid", "dashed", "dotted", "solid")) + expand_limits(y = 0) +
    labs(x = "Year", y = NULL, colour = NULL, linetype = NULL) + plain + theme(legend.position = "top"),
    width = 8, height = 7.5)

  # ---- residuals of the main fit ---------------------------------------------------
  save_plot("residuals", plot_residuals(fit$alscl, facet_by = "length", facet_ncol = 6, title = "") +
    labs(x = "Year", y = "Residual of the log survey index"), width = 11, height = 6)
  r <- fit$alscl$report$resid_index
  mean_resid <- rowMeans(r)
  utils::write.csv(data.frame(length_bin = mid, mean_residual = mean_resid,
                              years_positive = rowSums(r > 0)), file.path(res, "residuals_by_length.csv"), row.names = FALSE)
  num("residual_mean_bin_9", mean_resid[mid == 9], "Mean residual of the log index in the bin labelled 9 cm, ALSCL")
  num("residual_mean_bins_13_17", mean(mean_resid[mid %in% 13:17]), "Mean residual of the log index in the bins labelled 13 to 17 cm, ALSCL")
  num("residual_mean_bins_23_29", mean(mean_resid[mid %in% 23:29]), "Mean residual of the log index in the bins labelled 23 to 29 cm, ALSCL")
  num("residual_lag1_length", mean(vapply(seq_len(ncol(r)), function(y) stats::cor(r[-1, y], r[-nrow(r), y]), 1)),
      "Mean correlation between residuals of neighbouring length bins within a year, ALSCL")

  numbers <- do.call(rbind, numbers)
  utils::write.csv(numbers, file.path(res, "numbers.csv"), row.names = FALSE)
  writeLines(utils::capture.output(utils::sessionInfo()), file.path(res, "sessionInfo.txt"))
  invisible(list(numbers = numbers, checks = checks, starts = starts, lengths = lengths,
                 compare = compare, apparent_Z = z_rows, sensitivity = sens))
}
