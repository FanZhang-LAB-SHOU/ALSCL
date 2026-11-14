# Plots of the outputs and inputs added with the North Sea changes: mean
# length at age (plot_VB(), plot_compare_growth(), plot_length_at_age()),
# relative catch (plot_relative_catch()), the natural mortality rate and
# survey catchability used in a fit (plot_natural_mortality(),
# plot_survey_catchability()) and SSB from maturity at age (plot_SSB()).

# An ACL fit and an ALSCL fit to the same survey table, and fits with the
# non-default forms of the natural mortality rate and of survey catchability.
ns_plot_fits <- local({
  cache <- NULL
  function() {
    if (!is.null(cache)) return(cache)
    f <- fixture_frames(); mid <- seq(15, 55, 5)
    f$data.CatL[[1]] <- f$data.wgt[[1]] <- f$data.mat[[1]] <- as.character(mid)
    f$data.wgt[-1] <- outer(1e-5 * mid^3, 1 + .02 * (0:4))
    f$data.mat[-1] <- stats::plogis((mid - 30) / 4)
    start <- function(model) {
      p <- create_parameters(model_type = tolower(model))$parameters
      p$log_Linf <- log(60); p$log_vbk <- log(.2); p$mean_log_R <- log(100); p$log_init_Z <- log(.5)
      sd_names <- if (model == "ACL") c("log_std_index", "log_std_log_N0", "log_std_log_R") else
        c("log_sigma_index", "log_sigma_log_N0", "log_sigma_log_R")
      p[sd_names] <- log(c(.2, .1, .1))
      p
    }
    p <- start("ALSCL")
    prep <- do.call(ALSCL:::.acl_prepare_data, f); d <- prep$data
    d$len_mid <- prep$bins$mid; d$len_lower <- prep$bins$lower; d$len_upper <- prep$bins$upper
    d$growth_step <- 1
    p$dev_log_R <- c(.3, -.2, .4, 0, -.3); p$dev_log_F <- array(0, c(d$L, d$Y)); p$dev_log_N0 <- rep(0, d$A - 1L)
    truth <- TMB::MakeADFun(d, p, DLL = ALSCL:::.acl_compile("ALSCL")$dll_name, silent = TRUE)
    f$data.CatL[-1] <- exp(truth$report(truth$par)$Elog_index)
    fit <- function(model, ...) {
      p <- start(model); mapping <- lapply(p, function(x) factor(NA)); mapping$mean_log_R <- NULL
      args <- c(f, list(parameters = p, map = mapping, silent = TRUE))
      changes <- list(...)
      args[names(changes)] <- changes
      args <- args[!vapply(args, is.null, logical(1)) | names(args) %in% names(changes)]
      do.call(if (model == "ACL") run_acl else run_alscl, args)
    }
    q <- stats::plogis(log(19) * (mid - f$sel_L50) / (f$sel_L95 - f$sel_L50))
    q_late <- stats::plogis(log(19) * (mid - 25) / 12)
    M_age <- matrix(c(.5, .3, .2, .2), 4, 5) * rep(c(1, 1, 1.2, 1.2, 1.5), each = 4)
    cache <<- list(acl = fit("ACL"), alscl = fit("ALSCL"), input = f, mid = mid, q = q, q_late = q_late,
      M_age = M_age, M_length = 0.2 * 35 / mid,
      acl_inputs = fit("ACL", M = M_age, survey_q = cbind(q, q, q_late, q_late, q_late),
                       sel_L50 = NULL, sel_L95 = NULL, survey_q_age = c(.4, .8, 1, 1)),
      alscl_length = fit("ALSCL", M = 0.2 * 35 / mid),
      alscl_age = fit("ALSCL", M = matrix(c(.5, .3, .2, .2), ncol = 1)))
    cache
  }
})

ns_layers <- function(p, geom) which(vapply(p$layers, function(z) inherits(z$geom, geom), logical(1)))
ns_legend <- function(p, aesthetic)
  as.character(ggplot2::ggplot_build(p)$plot$scales$get_scales(aesthetic)$get_labels())
ns_saved <- function(fit) {
  path <- tempfile(fileext = ".rds"); on.exit(unlink(path))
  save_assessment(fit, path)
  read_assessment(path)
}
ns_readings <- function(fit, basis = "survey") {
  la <- length_at_age(fit, basis)
  out <- stats::aggregate(mean_length ~ age, la, mean)
  out$mean_length <- out$mean_length + c(.5, -.5, .8, -.3)
  out$sd_length <- c(2, 2.5, 3, 3.5)
  out
}
ns_grid_free <- function(p) {
  theme <- ggplot2::ggplot_build(p)$plot$theme
  for (grid in c("panel.grid.major.x", "panel.grid.major.y", "panel.grid.minor.x", "panel.grid.minor.y"))
    expect_s3_class(ggplot2::calc_element(grid, theme), "element_blank")
}

test_that("plot_VB keeps the von Bertalanffy curve of an ACL fit and adds observed points", {
  withr::local_options(list(acl.theme = NULL))
  z <- ns_plot_fits(); fit <- z$acl
  p <- plot_VB(fit)
  expect_s3_class(p, "ggplot")
  expect_identical(p$labels$title, "Von Bertalanffy growth curve")
  expect_null(p$labels$subtitle)
  expect_equal(range(p$data$age), c(1, 4))
  expect_equal(p$data$length, 60 * (1 - exp(-.2 * (p$data$age - fit$report$t0))))
  expect_length(ns_layers(p, "GeomLine"), 1L)
  expect_match(ggplot2::ggplot_build(p)$data[[ns_layers(p, "GeomText")]]$label, "Linf = 60")
  expect_identical(ggplot2::ggplot_build(p)$plot$theme$legend.position %||% "right", "right")
  # years and parameter_curve do not change this curve.
  expect_equal(plot_VB(fit, years = 2001, parameter_curve = TRUE)$data, p$data)

  obs <- ns_readings(fit)
  q <- plot_VB(fit, observed = obs, ylab = "Length (cm)")
  expect_equal(q$data, p$data)
  points <- ns_layers(q, "GeomPoint"); bars <- ns_layers(q, "GeomErrorbar")
  expect_length(points, 1L); expect_length(bars, 1L)
  built <- ggplot2::ggplot_build(q)
  expect_equal(built$data[[points]]$x, obs$age)
  expect_equal(built$data[[points]]$y, obs$mean_length)
  expect_equal(built$data[[bars]]$ymin, obs$mean_length - obs$sd_length)
  expect_equal(built$data[[bars]]$ymax, obs$mean_length + obs$sd_length)
  expect_identical(ns_legend(q, "colour"),
                   c("Von Bertalanffy curve (model)", "Age readings"))
  expect_identical(built$plot$theme$legend.position, "bottom")
  expect_match(q$labels$caption, "one standard deviation")
  expect_identical(q$labels$y, "Length (cm)")
  ns_grid_free(q)

  # On the survey basis the values come from the age-length key.
  s <- plot_VB(fit, basis = "survey", parameter_curve = TRUE, observed = obs, observed_name = "Otoliths")
  seen <- fit$report$pla * z$q
  expect_equal(s$data$age, as.numeric(1:4))
  expect_equal(s$data$length, as.numeric(colSums(seen * z$mid) / colSums(seen)), tolerance = 1e-12)
  expect_identical(s$labels$title, "Mean length at age")
  expect_identical(s$labels$subtitle, "In the survey catch, mean of the time steps 2000-2004")
  expect_identical(ns_legend(s, "colour"),
                   c("Mean length at age (model)", "Von Bertalanffy curve (population)", "Otoliths"))
  curve <- s$layers[[ns_layers(s, "GeomLine")[2L]]]$data
  expect_equal(curve$length, 60 * (1 - exp(-.2 * (curve$age - fit$report$t0))))
})

test_that("plot_VB shows mean length at age from the fitted numbers of an ALSCL fit", {
  withr::local_options(list(acl.theme = NULL))
  z <- ns_plot_fits(); fit <- z$alscl
  la <- length_at_age(fit)
  mean_of <- function(basis, years = 2000:2004) as.numeric(tapply(
    la$mean_length[la$basis == basis & la$year %in% years], la$age[la$basis == basis & la$year %in% years], mean))
  p <- plot_VB(fit)
  expect_s3_class(p, "ggplot")
  expect_equal(p$data$age, as.numeric(1:4))
  expect_equal(p$data$length, mean_of("population"), tolerance = 1e-12)
  # Not the curve computed from Linf, k and t0.
  expect_gt(max(abs(p$data$length - 60 * (1 - exp(-.2 * (1:4 - fit$report$t0))))), .1)
  expect_identical(p$labels$title, "Mean length at age")
  expect_identical(p$labels$subtitle, "In the population, mean of the time steps 2000-2004")
  expect_identical(p$labels$x, "Age (years)"); expect_identical(p$labels$y, "Length")
  expect_null(p$labels$caption)
  expect_length(ns_layers(p, "GeomText"), 0L)
  expect_length(ns_layers(p, "GeomLine"), 1L)
  labels <- ggplot2::ggplot_build(p)$layout$panel_params[[1L]]$x$get_labels()
  expect_identical(labels[!is.na(labels)], c("1", "2", "3", "4+"))
  ns_grid_free(p)

  expect_equal(plot_VB(fit, basis = "survey")$data$length, mean_of("survey"), tolerance = 1e-12)
  one <- plot_VB(fit, years = 2003)
  expect_equal(one$data$length, mean_of("population", 2003), tolerance = 1e-12)
  expect_identical(one$labels$subtitle, "In the population, time step 2003")
  expect_identical(plot_VB(fit, years = c(2000, 2002, 2004))$labels$subtitle,
                   "In the population, mean of 3 selected time steps")
  expect_equal(plot_VB(fit, age_range = c(2, 3))$data$age, c(2, 3))
  expect_equal(plot_VB(fit, age_range = c(0, 2.5))$data$age, c(1, 2))

  # The curve from Linf, k and t0 is an option, drawn dashed and named.
  r <- plot_VB(fit, parameter_curve = TRUE)
  lines <- ns_layers(r, "GeomLine")
  expect_length(lines, 2L)
  curve <- r$layers[[lines[2L]]]$data
  expect_equal(curve$length, 60 * (1 - exp(-.2 * (curve$age - fit$report$t0))))
  built <- ggplot2::ggplot_build(r)
  expect_true(all(built$data[[lines[2L]]]$linetype == "dashed"))
  expect_identical(ns_legend(r, "colour"),
                   c("Mean length at age (model)", "Curve from Linf, k and t0"))
  expect_match(r$labels$caption, "mean length at age in the first time step")
  expect_match(built$data[[ns_layers(r, "GeomText")]]$label, "Curve from Linf, k and t0:\n  Linf = 60")
  growth <- fit; growth$structure$initial_length <- "growth"
  expect_match(plot_VB(growth, parameter_curve = TRUE)$labels$caption, "first age class is the mean length of recruits")
  # The interval belongs to the curve from the parameters.
  expect_warning(plot_VB(fit, se = TRUE), "no standard error for mean length at age")
  covariance <- diag(c(.001, .002, .0005)); dimnames(covariance) <- rep(list(c("log_Linf", "log_vbk", "log_t0")), 2L)
  with_cov <- fit; with_cov$vcov <- covariance; with_cov$pdHess <- TRUE
  expect_no_warning(i <- plot_VB(with_cov, parameter_curve = TRUE, se = TRUE))
  ribbon <- ggplot2::ggplot_build(i)$data[[ns_layers(i, "GeomRibbon")]]
  expected <- ALSCL:::.acl_growth_interval(with_cov, i$layers[[ns_layers(i, "GeomLine")[2L]]]$data$age)
  expect_equal(ribbon$ymin, expected$lower); expect_equal(ribbon$ymax, expected$upper)

  # Observed mean length at age: points, bars and a legend entry.
  obs <- ns_readings(fit)
  names(obs)[names(obs) == "sd_length"] <- "sd"
  o <- plot_VB(fit, observed = obs, basis = "survey")
  built <- ggplot2::ggplot_build(o)
  expect_equal(built$data[[ns_layers(o, "GeomPoint")]]$y, obs$mean_length)
  expect_equal(built$data[[ns_layers(o, "GeomErrorbar")]]$ymax, obs$mean_length + obs$sd)
  expect_identical(ns_legend(o, "colour"), c("Mean length at age (model)", "Age readings"))
  interval <- transform(obs, lower = mean_length - 1, upper = mean_length + 2)
  i <- plot_VB(fit, observed = interval)
  expect_equal(ggplot2::ggplot_build(i)$data[[ns_layers(i, "GeomErrorbar")]]$ymax, obs$mean_length + 2)
  expect_match(i$labels$caption, "supplied interval")
  plain <- plot_VB(fit, observed = obs[c("age", "mean_length")])
  expect_length(ns_layers(plain, "GeomErrorbar"), 0L)
  expect_null(plain$labels$caption)
  # Observations by time step: only the selected time steps are drawn.
  by_time <- rbind(transform(obs, year = 2001), transform(obs, year = 2003))
  expect_equal(nrow(ggplot2::ggplot_build(plot_VB(fit, observed = by_time))$data[[ns_layers(o, "GeomPoint")]]), 8L)
  sel <- plot_VB(fit, observed = by_time, years = 2003)
  expect_equal(nrow(ggplot2::ggplot_build(sel)$data[[ns_layers(sel, "GeomPoint")]]), 4L)

  # A saved assessment gives the same figure on both bases.
  saved <- ns_saved(fit)
  expect_equal(plot_VB(saved, basis = "survey")$data, plot_VB(fit, basis = "survey")$data, tolerance = 1e-12)
})

test_that("plot_VB rejects unusable input", {
  z <- ns_plot_fits(); fit <- z$alscl
  obs <- ns_readings(fit)
  expect_error(plot_VB(fit, basis = "catch"), "should be")
  expect_error(plot_VB(fit, years = 1990), "years must be time steps of fit")
  expect_error(plot_VB(fit, years = "2001"), "finite numeric time steps")
  expect_error(plot_VB(fit, age_range = c(10, 12)), "contains no age class")
  expect_error(plot_VB(fit, age_range = c(3, 2)), "finite increasing pair")
  expect_error(plot_VB(fit, parameter_curve = NA), "parameter_curve must be TRUE or FALSE")
  expect_error(plot_VB(fit, observed = as.matrix(obs)), "data frame with the numeric columns age and mean_length")
  expect_error(plot_VB(fit, observed = obs["age"]), "data frame with the numeric columns age and mean_length")
  expect_error(plot_VB(fit, observed = obs[0, ]), "data frame with the numeric columns age and mean_length")
  expect_error(plot_VB(fit, observed = transform(obs, mean_length = as.character(mean_length))), "must be numeric")
  expect_error(plot_VB(fit, observed = transform(obs, age = c(1, NA, 3, 4))), "numeric and finite")
  expect_error(plot_VB(fit, observed = transform(obs, sd_length = -1)), "must be nonnegative")
  expect_error(plot_VB(fit, observed = transform(obs, lower = 1)), "both lower and upper")
  expect_error(plot_VB(fit, observed = transform(obs, lower = mean_length + 1, upper = mean_length + 2)),
               "lower must not exceed mean_length")
  expect_error(plot_VB(fit, observed = obs, observed_name = ""), "observed_name must be a nonempty character string")
  expect_error(plot_VB(fit, observed = obs, observed_name = "Mean length at age (model)"), "observed_name must differ")
  # Legacy and failed results give the errors of length_at_age().
  failed <- list(model_type = "ALSCL", converge = "FAILED", error = "t0 must be below the recruitment age.")
  expect_error(plot_VB(failed), "model_result is a failed fit without estimates.*t0 must be below")
  legacy <- fit; legacy$age <- NULL
  expect_error(plot_VB(legacy), "model_result must contain finite age metadata")
  legacy <- fit; legacy$report$NLA <- NULL
  expect_error(plot_VB(legacy), "numbers by length, age and time step")
  bare <- fit; bare$obj <- NULL; bare$recipe <- NULL
  expect_no_error(plot_VB(bare))
  expect_error(plot_VB(bare, basis = "survey"), "Survey catchability at length is unavailable")
  # An ACL result with growth parameters only still gives its curve.
  expect_s3_class(plot_VB(list(report = list(Linf = 70, vbk = .2, t0 = -.1))), "ggplot")
  expect_error(plot_VB(list(report = list(Linf = 70, vbk = .2, t0 = -.1)), basis = "survey"),
               "model_result must be an ACL or ALSCL result")
})

test_that("plot_compare_growth compares mean length at age on one basis", {
  skip_if_not_installed("patchwork")
  withr::local_options(list(acl.theme = NULL))
  grDevices::pdf(NULL); on.exit(grDevices::dev.off(), add = TRUE)
  z <- ns_plot_fits(); acl <- z$acl; alscl <- z$alscl
  for (basis in c("population", "survey")) {
    p <- plot_compare_growth(acl, alscl, basis = basis)
    left <- p[[1L]]; right <- p[[2L]]
    expect_s3_class(left, "ggplot")
    for (name in c("ACL", "ALSCL")) {
      fit <- if (name == "ACL") acl else alscl
      expected <- ALSCL:::.acl_mean_length_at_age(fit, basis)
      expect_equal(left$data$Age[left$data$Model == name], expected$age)
      expect_equal(left$data$Length[left$data$Model == name], expected$mean_length, tolerance = 1e-12)
    }
    expect_identical(left$labels$title, "Mean length at age")
    expect_identical(left$labels$subtitle, paste0(if (basis == "survey") "In the survey catch" else
      "In the population", ", mean of the time steps 2000-2004"))
    expect_false(grepl("Linf", left$labels$subtitle))
    # Right panel: the same basis; ALSCL from the fitted numbers.
    numbers <- alscl$report$NLA
    if (basis == "survey") numbers <- sweep(numbers, 1L, z$q, "*")
    share <- apply(apply(numbers, c(2L, 3L), function(x) x / sum(x)), c(1L, 2L), mean)
    expect_equal(right$data$Probability[right$data$Model == "ALSCL"], as.numeric(share), tolerance = 1e-12)
    key <- if (basis == "survey") sweep(acl$report$pla * z$q, 2L, colSums(acl$report$pla * z$q), "/") else
      acl$report$pla
    expect_equal(right$data$Probability[right$data$Model == "ACL"], as.numeric(key), tolerance = 1e-12)
    expect_silent(patchwork::patchworkGrob(p))
  }
  # The realized length distribution at age differs from report$pla of ALSCL.
  right <- plot_compare_growth(acl, alscl)[[2L]]
  expect_gt(max(abs(right$data$Probability[right$data$Model == "ALSCL"] - as.numeric(alscl$report$pla))), .01)

  expect_equal(unique(plot_compare_growth(acl, alscl, years = 2002)[[1L]]$labels$subtitle),
               "In the population, time step 2002")
  expect_equal(sort(unique(plot_compare_growth(acl, alscl, age_range = c(2, 3))[[1L]]$data$Age)), c(2, 3))

  obs <- ns_readings(alscl)
  o <- plot_compare_growth(acl, alscl, observed = obs, basis = "survey")[[1L]]
  built <- ggplot2::ggplot_build(o)
  points <- ns_layers(o, "GeomPoint"); bars <- ns_layers(o, "GeomErrorbar")
  expect_equal(built$data[[points]]$y, obs$mean_length)
  expect_equal(built$data[[bars]]$ymin, obs$mean_length - obs$sd_length)
  expect_identical(ns_legend(o, "shape"), "Age readings")
  expect_match(o$labels$caption, "one standard deviation")
  expect_error(plot_compare_growth(acl, alscl, observed = obs, observed_name = "ACL"), "observed_name must be distinct")
  expect_error(plot_compare_growth(acl, alscl, observed = obs["age"]), "numeric columns age and mean_length")
  expect_error(plot_compare_growth(acl, alscl, years = 1990), "years must be time steps of fit")
  expect_error(plot_compare_growth(acl, alscl, basis = "catch"), "should be")
  # Saved assessments compare in the same way.
  saved <- plot_compare_growth(ns_saved(acl), ns_saved(alscl), basis = "survey")[[1L]]
  expect_equal(saved$data, plot_compare_growth(acl, alscl, basis = "survey")[[1L]]$data, tolerance = 1e-12)
})

test_that("plot_length_at_age draws mean length at age by time step", {
  withr::local_options(list(acl.theme = NULL))
  z <- ns_plot_fits(); fit <- z$alscl
  la <- length_at_age(fit, "population")
  out <- plot_length_at_age(fit, return_data = TRUE)
  p <- out$plot
  expect_s3_class(p, "ggplot")
  expect_named(out$data, c("Year", "Age", "AgeClass", "mean_length", "sd_length"))
  expect_equal(out$data$Year, la$year); expect_equal(out$data$Age, la$age)
  expect_equal(out$data$mean_length, la$mean_length); expect_equal(out$data$sd_length, la$sd_length)
  expect_identical(levels(out$data$AgeClass), c("Age 1", "Age 2", "Age 3", "Age 4+"))
  expect_identical(names(p$facet$params$facets), "AgeClass")
  expect_identical(p$labels$title, "Mean length at age by time step")
  expect_identical(p$labels$subtitle, "In the population")
  expect_identical(p$labels$x, "Year"); expect_identical(p$labels$y, "Length")
  expect_length(ns_layers(p, "GeomLine"), 1L)
  ns_grid_free(p)
  expect_s3_class(ggplot2::ggplot_build(p), "ggplot_built")

  survey <- plot_length_at_age(fit, basis = "survey", years = 2001:2003, ages = c(2, 4), return_data = TRUE)
  expected <- subset(length_at_age(fit, "survey"), year %in% 2001:2003 & age %in% c(2, 4))
  expect_equal(survey$data$mean_length, expected$mean_length)
  expect_identical(levels(survey$data$AgeClass), c("Age 2", "Age 4+"))
  expect_identical(survey$plot$labels$subtitle, "In the survey catch")

  # Age readings by time step: points in the panel of their age class.
  obs <- subset(length_at_age(fit, "survey"), age %in% c(2, 3) & year != 2002)[c("year", "age", "mean_length", "sd_length")]
  obs$mean_length <- obs$mean_length + .4
  o <- plot_length_at_age(fit, observed = obs, basis = "survey")
  built <- ggplot2::ggplot_build(o)
  points <- built$data[[ns_layers(o, "GeomPoint")]]
  expect_equal(points$x, obs$year); expect_equal(points$y, obs$mean_length)
  expect_setequal(as.integer(points$PANEL), 2:3)
  expect_equal(built$data[[ns_layers(o, "GeomErrorbar")]]$ymax, obs$mean_length + obs$sd_length)
  expect_identical(ns_legend(o, "colour"), c("Model", "Age readings"))
  expect_identical(built$plot$theme$legend.position, "bottom")
  expect_match(o$labels$caption, "one standard deviation")
  shown <- plot_length_at_age(fit, observed = obs, ages = 3, years = 2003:2004)
  expect_equal(ggplot2::ggplot_build(shown)$data[[ns_layers(shown, "GeomPoint")]]$x, c(2003, 2004))

  # One panel with a line per age class.
  n <- plot_length_at_age(fit, facet_by = "none", observed = obs)
  expect_null(n$facet$params$facets)
  expect_identical(n$scales$get_scales("colour")$name, "Age class")
  expect_identical(ns_legend(n, "colour"), c("1", "2", "3", "4+"))
  expect_length(unique(ggplot2::ggplot_build(n)$data[[1L]]$group), 4L)
  expect_match(n$labels$caption, "Lines: model. Points: Age readings.")

  # ACL uses one age-length key: mean length at age does not change with time.
  a <- plot_length_at_age(z$acl, return_data = TRUE)$data
  expect_true(all(tapply(a$mean_length, a$Age, function(x) diff(range(x))) < 1e-12))
  expect_gt(max(tapply(out$data$mean_length, out$data$Age, function(x) diff(range(x)))), .1)
  expect_equal(plot_length_at_age(ns_saved(fit), basis = "survey", return_data = TRUE)$data,
               plot_length_at_age(fit, basis = "survey", return_data = TRUE)$data, tolerance = 1e-12)

  expect_error(plot_length_at_age(fit, observed = obs[c("age", "mean_length")]), "must have the column year")
  expect_error(plot_length_at_age(fit, observed = transform(obs, age = age + .5)), "not age classes of fit.*2.5, 3.5")
  expect_error(plot_length_at_age(fit, ages = 9), "ages must be age classes of fit")
  expect_error(plot_length_at_age(fit, ages = "2"), "finite numeric age classes")
  expect_error(plot_length_at_age(fit, years = 1990), "years must be time steps of fit")
  expect_error(plot_length_at_age(fit, facet_by = "year"), "should be")
  expect_error(plot_length_at_age(fit, observed = obs, observed_name = "Model"), "must differ from")
  expect_error(plot_length_at_age(list(converge = "FAILED", error = "no data")), "fit is a failed fit without estimates")
  legacy <- fit; legacy$age <- NULL
  expect_error(plot_length_at_age(legacy), "finite age metadata")
})

test_that("plot_relative_catch draws catch divided by its mean and scales reported catch the same way", {
  withr::local_options(list(acl.theme = NULL))
  z <- ns_plot_fits()
  for (fit in list(z$acl, z$alscl)) {
    rel <- relative_catch(fit)
    out <- plot_relative_catch(fit, return_data = TRUE)
    p <- out$plot
    expect_s3_class(p, "ggplot")
    expect_equal(out$data$relative, rel$catch_number)
    expect_identical(out$data$extrapolated, rel$extrapolated)
    expect_null(out$observed)
    expect_identical(p$labels$y, "Catch in numbers divided by its mean")
    expect_identical(p$labels$title, "Relative catch")
    expect_identical(p$labels$subtitle, "Divided by the mean of the time steps 2000-2004")
    expect_length(ns_layers(p, "GeomLine"), 1L)
    expect_equal(ggplot2::ggplot_build(p)$data[[ns_layers(p, "GeomHline")]]$yintercept, 1)
    ns_grid_free(p)
    w <- plot_relative_catch(fit, type = "weight", return_data = TRUE)
    expect_equal(w$data$relative, rel$catch_weight)
    expect_identical(w$plot$labels$y, "Catch in weight divided by its mean")
    expect_equal(plot_relative_catch(fit, years = 2001:2002, return_data = TRUE)$data$relative,
                 relative_catch(fit, years = 2001:2002)$catch_number)

    # Reported catch in another unit, for three of the five time steps and
    # two time steps outside the fit.
    reported <- data.frame(year = c(1998, 1999, 2001, 2002, 2003), catch = c(50, 60, 4000, 5500, 3000))
    o <- plot_relative_catch(fit, observed = reported, type = "weight", return_data = TRUE)
    expect_equal(o$observed$Year, 2001:2003)
    expect_equal(o$observed$relative, c(4000, 5500, 3000) / mean(c(4000, 5500, 3000)))
    expect_equal(o$data$relative, relative_catch(fit, years = 2001:2003)$catch_weight)
    # Both series have mean one over the same time steps.
    expect_equal(mean(o$observed$relative), 1)
    expect_equal(mean(o$data$relative[o$data$Year %in% 2001:2003]), 1)
    expect_identical(o$plot$labels$subtitle, "Divided by the mean of the time steps 2001-2003")
    built <- ggplot2::ggplot_build(o$plot)
    expect_equal(built$data[[ns_layers(o$plot, "GeomPoint")]]$y, o$observed$relative)
    expect_identical(ns_legend(o$plot, "colour"), c("Model", "Reported catch"))
    expect_identical(built$plot$theme$legend.position, "bottom")
    # years restricts the reference time steps further.
    y <- plot_relative_catch(fit, observed = reported, years = c(2002, 2003), return_data = TRUE)
    expect_equal(y$observed$relative, c(4000, 5500, 3000) / mean(c(5500, 3000)))
    expect_equal(y$data$relative, relative_catch(fit, years = 2002:2003)$catch_number)
    gap <- plot_relative_catch(fit, observed = reported[c(3, 5), ])
    expect_identical(gap$labels$subtitle, "Divided by the mean of 2 time steps between 2001 and 2003")
  }
  fit <- z$alscl
  reported <- data.frame(year = 2000:2004, catch = c(4, 5, NA, 3, 6))
  expect_equal(plot_relative_catch(fit, observed = reported, return_data = TRUE)$observed$Year, c(2000, 2001, 2003, 2004))
  expect_error(plot_relative_catch(fit, observed = data.frame(year = 1990:1992, catch = 1:3)),
               "no reported catch in the time steps of fit")
  expect_error(plot_relative_catch(fit, observed = reported, years = 2002), "selected by years")
  expect_error(plot_relative_catch(fit, observed = data.frame(time = 2000, catch = 1)), "numeric columns year")
  expect_error(plot_relative_catch(fit, observed = c(1, 2)), "numeric columns year")
  expect_error(plot_relative_catch(fit, observed = transform(reported, catch = -1)), "nonnegative")
  expect_error(plot_relative_catch(fit, observed = rbind(reported, reported)), "one reported catch per time step")
  expect_error(plot_relative_catch(fit, observed = transform(reported, catch = 0)), "must be positive")
  expect_error(plot_relative_catch(fit, observed = reported, observed_name = "Model"), "must differ from")
  expect_error(plot_relative_catch(fit, type = "biomass"), "should be")
  expect_error(plot_relative_catch(fit, years = 1990), "years must be time steps of fit")
  expect_error(plot_relative_catch(list(converge = "FAILED", error = "no data")), "failed fit without estimates")
  # A saved assessment keeps both types; a bare ACL result has no weights.
  expect_equal(plot_relative_catch(ns_saved(z$acl), type = "weight", return_data = TRUE)$data,
               plot_relative_catch(z$acl, type = "weight", return_data = TRUE)$data, tolerance = 1e-12)
  bare <- z$acl; bare$obj <- NULL; bare$recipe <- NULL
  expect_s3_class(plot_relative_catch(bare), "ggplot")
  expect_error(plot_relative_catch(bare, type = "weight"), "Catch in weight of this ACL fit is unavailable")
})

test_that("plot_natural_mortality follows the form of the input", {
  withr::local_options(list(acl.theme = NULL))
  z <- ns_plot_fits()
  for (fit in list(z$acl, z$alscl)) {
    out <- plot_natural_mortality(fit, return_data = TRUE)
    expect_s3_class(out$plot, "ggplot")
    expect_equal(out$data$Year, 2000:2004); expect_equal(out$data$Value, rep(.2, 5L))
    expect_identical(out$plot$labels$title, "Natural mortality rate (M) used in the fit")
    expect_identical(out$plot$labels$subtitle, "One value for all age classes and time steps")
    expect_identical(out$plot$labels$y, "Natural mortality rate (per year)")
    expect_identical(out$plot$labels$x, "Year")
    ns_grid_free(out$plot)
  }
  # By age class and time step: one panel per age class.
  out <- plot_natural_mortality(z$acl_inputs, return_data = TRUE)
  expect_equal(out$data$Value, as.numeric(z$M_age))
  expect_equal(out$data$Year, rep(2000:2004, each = 4L))
  expect_identical(levels(out$data$AgeClass), c("Age 1", "Age 2", "Age 3", "Age 4+"))
  expect_identical(names(out$plot$facet$params$facets), "AgeClass")
  expect_identical(out$plot$labels$subtitle, "By age class and time step")
  # By age class, constant over time: against age.
  out <- plot_natural_mortality(z$alscl_age, return_data = TRUE)
  expect_equal(out$data$Age, 1:4); expect_equal(out$data$Value, c(.5, .3, .2, .2))
  expect_identical(out$plot$labels$subtitle, "By age class, the same in every time step")
  expect_identical(out$plot$labels$x, "Age (years)")
  expect_length(ns_layers(out$plot, "GeomPoint"), 1L)
  labels <- ggplot2::ggplot_build(out$plot)$layout$panel_params[[1L]]$x$get_labels()
  expect_identical(labels[!is.na(labels)], c("1", "2", "3", "4+"))
  # By length (ALSCL).
  out <- plot_natural_mortality(z$alscl_length, return_data = TRUE)
  expect_equal(out$data$Length, z$mid); expect_equal(out$data$Value, z$M_length)
  expect_identical(out$plot$labels$subtitle, "By length, the same in every time step")
  expect_identical(out$plot$labels$x, "Length")

  # The same figure from a saved assessment and from a result without a recipe.
  for (fit in list(z$acl_inputs, z$alscl_age, z$alscl_length, z$alscl)) {
    expected <- plot_natural_mortality(fit, return_data = TRUE)$data
    expect_equal(plot_natural_mortality(ns_saved(fit), return_data = TRUE)$data, expected)
    live <- fit; live$recipe <- NULL
    expect_equal(plot_natural_mortality(live, return_data = TRUE)$data, expected)
  }
  bare <- z$alscl; bare$obj <- NULL; bare$recipe <- NULL
  expect_error(plot_natural_mortality(bare), "natural mortality rate of fit is unavailable")
  expect_error(plot_natural_mortality(list(converge = "FAILED", error = "no data")), "failed fit without estimates")
  # The label follows the time step, and a customized label is used verbatim.
  quarterly <- z$alscl; quarterly$growth_step <- .25
  expect_identical(plot_natural_mortality(quarterly)$labels$y, "Natural mortality rate (per quarter)")
  acl_theme_set(ylab = list(M = "M"))
  expect_identical(plot_natural_mortality(z$acl)$labels$y, "M")
})

test_that("plot_survey_catchability draws the catchability used in the fit", {
  withr::local_options(list(acl.theme = NULL))
  z <- ns_plot_fits()
  for (fit in list(z$acl, z$alscl, ns_saved(z$alscl))) {
    out <- plot_survey_catchability(fit, return_data = TRUE)
    expect_s3_class(out$plot, "ggplot")
    expect_equal(out$data$Length, z$mid); expect_equal(out$data$Value, z$q, tolerance = 1e-12)
    expect_identical(out$plot$labels$title, "Survey catchability at length used in the fit")
    expect_identical(out$plot$labels$y, "Survey catchability (q)")
    expect_identical(out$plot$labels$x, "Length")
    expect_null(out$plot$labels$subtitle)
    expect_error(plot_survey_catchability(fit, type = "age"), "no survey catchability multiplier by age")
    ns_grid_free(out$plot)
  }
  # By length and time step: one line for each distinct curve, named by its time steps.
  for (fit in list(z$acl_inputs, ns_saved(z$acl_inputs))) {
    out <- plot_survey_catchability(fit, return_data = TRUE)
    expect_identical(levels(out$data$Curve), c("2000-2001", "2002-2004"))
    expect_equal(out$data$Value, c(z$q, z$q_late))
    expect_identical(out$plot$scales$get_scales("colour")$name, "Time steps")
    expect_identical(out$plot$labels$subtitle, "By length and time step: one line for each distinct curve")
    expect_identical(ggplot2::ggplot_build(out$plot)$plot$theme$legend.position, "bottom")
    age <- plot_survey_catchability(fit, type = "age", return_data = TRUE)
    expect_equal(age$data$Age, 1:4); expect_equal(age$data$Value, c(.4, .8, 1, 1))
    expect_identical(age$plot$labels$title, "Survey catchability multiplier by age used in the fit")
    expect_identical(age$plot$labels$y, "Survey catchability multiplier")
    expect_identical(age$plot$labels$x, "Age (years)")
  }
  # The values are those of plot_compare_selectivity(), which shares the accessor.
  both <- plot_compare_selectivity(z$acl_inputs, z$alscl)
  expect_equal(both$data$Selectivity[both$data$Model == "ACL"], c(z$q, z$q_late))
  expect_equal(both$data$Selectivity[both$data$Model == "ALSCL"], z$q, tolerance = 1e-12)
  expect_identical(both$labels$y, "Survey catchability (q)")
  # Non-adjacent time steps with the same curve are listed as ranges.
  expect_identical(ALSCL:::.acl_time_ranges(c(2000, 2001, 2004, 2006, 2007)), "2000-2001, 2004, 2006-2007")
  expect_identical(ALSCL:::.acl_time_ranges(2000 + c(0, 1, 2) / 4, .25), "2000 Q1-2000 Q3")
  # A result without a recipe is read from its TMB object; nothing else is an error.
  live <- z$acl_inputs; live$recipe <- NULL
  expect_equal(plot_survey_catchability(live, type = "age", return_data = TRUE)$data$Value, c(.4, .8, 1, 1))
  bare <- z$alscl; bare$obj <- NULL; bare$recipe <- NULL
  expect_error(plot_survey_catchability(bare), "complete saved recipe or fitted log_q")
  expect_error(plot_survey_catchability(1), "fitted ACL or ALSCL result")
  expect_error(plot_survey_catchability(z$acl, type = "time"), "should be")
})

test_that("plot_SSB adds the SSB from maturity at age only on request", {
  withr::local_options(list(acl.theme = NULL))
  z <- ns_plot_fits()
  ogive <- c(0, .5, 1, 1)
  for (fit in list(z$acl, z$alscl)) {
    plain <- plot_SSB(fit)
    expect_length(plain$layers, 1L)
    expect_null(plain$scales$get_scales("linetype"))
    out <- plot_SSB(fit, maturity_at_age = ogive, return_data = TRUE)
    p <- out$plot
    expected <- ssb_at_age(fit, ogive)
    expect_equal(out$data$SSB_at_age, expected$SSB)
    lines <- ns_layers(p, "GeomLine")
    expect_length(lines, 2L)
    built <- ggplot2::ggplot_build(p)
    expect_equal(built$data[[lines[1L]]]$y, as.numeric(fit$report$SSB))
    expect_equal(built$data[[lines[2L]]]$y, expected$SSB)
    expect_true(all(built$data[[lines[1L]]]$linetype == "solid"))
    expect_true(all(built$data[[lines[2L]]]$linetype == "dashed"))
    expect_identical(ns_legend(p, "linetype"), c("Maturity at length (model)", "Maturity at age"))
    expect_identical(built$plot$theme$legend.position, "bottom")
    expect_identical(p$labels$title, plain$labels$title)
    with_se <- plot_SSB(fit, maturity_at_age = ogive, se = TRUE)
    expect_length(ns_layers(with_se, "GeomRibbon"), 1L)
    expect_length(ns_layers(with_se, "GeomLine"), 2L)
  }
  weights <- c(.1, .3, .6, 1)
  expect_equal(plot_SSB(z$alscl, maturity_at_age = ogive, weight_at_age = weights, return_data = TRUE)$data$SSB_at_age,
               ssb_at_age(z$alscl, ogive, weights)$SSB)
  expect_error(plot_SSB(z$alscl, type = "SBL", maturity_at_age = ogive), "apply to type = \"SSB\" only")
  expect_error(plot_SSB(z$alscl, weight_at_age = weights), "supply both")
  expect_error(plot_SSB(z$alscl, maturity_at_age = c(0, 1)), "maturity must be a numeric vector")
})

test_that("the new plots take the label and typography arguments and the theme keys", {
  withr::local_options(list(acl.theme = NULL))
  z <- ns_plot_fits(); fit <- z$alscl
  style_args <- c("title", "xlab", "ylab", "font_family", "title_size", "axis_title_size", "axis_text_size",
                  "strip_text_size", "legend_text_size", "x_breaks", "base_theme", "title_hjust")
  draw <- list(plot_length_at_age = function(...) plot_length_at_age(fit, ...),
               plot_relative_catch = function(...) plot_relative_catch(fit, ...),
               plot_natural_mortality = function(...) plot_natural_mortality(fit, ...),
               plot_survey_catchability = function(...) plot_survey_catchability(fit, ...),
               plot_VB = function(...) plot_VB(fit, ...))
  for (name in names(draw)) {
    expect_true(all(style_args %in% names(formals(get(name, asNamespace("ALSCL"))))), label = name)
    p <- draw[[name]](title = "Custom title", xlab = "Custom x", ylab = "Custom y", title_size = 21,
                      title_hjust = 0, axis_text_size = 7, base_theme = "minimal", font_family = "mono")
    expect_s3_class(p, "ggplot")
    expect_identical(p$labels$title, "Custom title", label = name)
    expect_identical(p$labels$x, "Custom x", label = name)
    expect_identical(p$labels$y, "Custom y", label = name)
    theme <- ggplot2::ggplot_build(p)$plot$theme
    expect_equal(ggplot2::calc_element("plot.title", theme)$size, 21, label = name)
    expect_equal(ggplot2::calc_element("plot.title", theme)$hjust, 0, label = name)
    expect_equal(ggplot2::calc_element("axis.text", theme)$size, 7, label = name)
    expect_identical(ggplot2::calc_element("axis.text.x", theme)$family, "mono", label = name)
    ns_grid_free(p)
  }
  # New arguments of the changed functions come after the existing ones.
  expect_identical(utils::tail(names(formals(plot_VB)), 7L),
    c("observed", "basis", "years", "parameter_curve", "point_size", "observed_color", "observed_name"))
  expect_identical(utils::tail(names(formals(plot_compare_growth)), 5L),
    c("...", "observed", "basis", "years", "observed_name"))
  expect_identical(utils::tail(names(formals(plot_SSB)), 3L), c("interval", "maturity_at_age", "weight_at_age"))
  # Titles, labels and colours come from the theme.
  acl_theme_set(titles = list(length_at_age = "Growth", length_at_age_time = "Growth by year",
                              relative_catch = "Catch trend", natural_mortality = "M", survey_q = "q"),
                ylab = list(growth = "Length (cm)", relative_catch_number = "Relative catch", survey_q = "q"),
                line_color = "navy", observed_color = "orange")
  expect_identical(plot_VB(fit)$labels$title, "Growth")
  expect_identical(plot_VB(fit)$labels$y, "Length (cm)")
  expect_identical(plot_length_at_age(fit)$labels$title, "Growth by year")
  expect_identical(plot_relative_catch(fit)$labels$title, "Catch trend")
  expect_identical(plot_relative_catch(fit)$labels$y, "Relative catch")
  expect_identical(plot_natural_mortality(fit)$labels$title, "M")
  expect_identical(plot_survey_catchability(fit)$labels$title, "q")
  expect_identical(plot_survey_catchability(fit)$labels$y, "q")
  built <- ggplot2::ggplot_build(plot_VB(fit, observed = ns_readings(fit)))
  expect_true(all(built$data[[1L]]$colour == "navy"))
  expect_true(all(built$data[[3L]]$colour == "orange"))
  # Every new title and label is plain text without dashes used as punctuation.
  text <- unlist(c(ALSCL:::.acl_defaults$titles[c("length_at_age", "length_at_age_time", "relative_catch",
    "natural_mortality", "survey_q", "survey_q_age")], ALSCL:::.acl_defaults$ylab[c("M", "survey_q",
    "survey_q_age", "relative_catch_number", "relative_catch_weight")]))
  expect_false(any(grepl("–|—", text)))
})
