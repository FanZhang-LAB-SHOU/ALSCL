# Choice arguments accept any letter case and resolve to the values that the
# functions use and store: plot_SSB(fit, type = "sbl") draws the same figure
# as plot_SSB(fit, type = "SBL"). One helper, .acl_match_choice(), does the
# matching; .acl_canonical() serves arguments that check their values with
# a message of their own.

# One small ACL fit and one small ALSCL fit for the whole file.
case_fit <- local({
  fits <- list()
  function(model = "ACL") {
    if (is.null(fits[[model]])) fits[[model]] <<- fit_fixture(model)
    fits[[model]]
  }
})

# Data of every layer of a plot, or of every plot of a patchwork, as drawn.
case_data <- function(p) {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  plots <- if (inherits(p, "patchwork")) ALSCL:::.acl_patches(p)$plots else list(p)
  lapply(plots, function(q) if (inherits(q, "ggplot") && length(q$layers)) ggplot2::ggplot_build(q)$data)
}

# The same figure: the same layer data, labels and facets.
expect_same_plot <- function(a, b) {
  expect_identical(case_data(a), case_data(b))
  expect_identical(a$labels, b$labels)
  expect_identical(a$facet$params$free, b$facet$params$free)
}

test_that("one helper matches choices in any letter case", {
  m <- ALSCL:::.acl_match_choice
  expect_identical(m("sbl", c("SSB", "SBL", "SBA")), "SBL")
  expect_identical(m("Sbl", c("SSB", "SBL", "SBA")), "SBL")
  expect_identical(m("na", c("N", "NA", "NL")), "NA")
  expect_identical(m("n", c("N", "NA", "NL")), "N")
  # A unique start of a choice matches where match.arg() allowed it, and only
  # there; a complete match comes first.
  expect_identical(m("ERR", c("ribbon", "errorbar"), partial = TRUE), "errorbar")
  expect_identical(m("N", c("N", "NA", "NL"), partial = TRUE), "N")
  expect_error(m("err", c("ribbon", "errorbar"), "se_type"), "se_type must be one of")
  expect_error(m("S", c("SSB", "SBL", "SBA"), "type", partial = TRUE),
               "type must be one of \"SSB\", \"SBL\", \"SBA\" in any letter case, not \"S\".", fixed = TRUE)
  # Several values, a default left as it is and NULL, as in match.arg().
  expect_identical(m(c("rec", "SSB"), c("SSB", "Rec"), several = TRUE), c("Rec", "SSB"))
  expect_identical(m(c("SSB", "Rec"), c("SSB", "Rec"), several = TRUE), c("SSB", "Rec"))
  expect_identical(m(c("SSB", "SBL", "SBA"), c("SSB", "SBL", "SBA")), "SSB")
  expect_identical(m(NULL, c("a", "b")), "a")
  expect_error(m(c("rec", "foo", "bar"), c("SSB", "Rec"), "quantities", several = TRUE),
               "quantities must be one or more of \"SSB\", \"Rec\" in any letter case, not \"foo\", \"bar\".",
               fixed = TRUE)
  # The choices of the calling function are its default.
  f <- function(type = c("SSB", "SBL")) ALSCL:::.acl_match_choice(type, partial = TRUE)
  expect_identical(f(), "SSB")
  expect_identical(f("sbl"), "SBL")
  expect_error(f("xyz"), "type must be one of \"SSB\", \"SBL\" in any letter case, not \"xyz\".", fixed = TRUE)
  for (bad in list(1, NA_character_, character(), c("SSB", "SBL", "SBL")))
    expect_error(f(bad), "type must be one of \"SSB\", \"SBL\"", fixed = TRUE)
  # Two choices that differ only by case are matched with case: no guess.
  expect_identical(m("f", c("F", "f")), "f")
  expect_identical(m("F", c("F", "f")), "F")
  expect_error(m("x", c("F", "f"), "z"), "z must be one of \"F\", \"f\", not \"x\".", fixed = TRUE)
  # .acl_canonical() keeps values that match no choice for the caller to check.
  canonical <- ALSCL:::.acl_canonical
  expect_identical(canonical(c("ssb", "foo", NA), c("SSB", "Rec")), c("SSB", "foo", NA))
  expect_identical(canonical(2, "auto"), 2)
  expect_identical(canonical("AUTO", "auto"), "auto")
})

test_that("no choice set of the package holds two choices that differ only by case", {
  ns <- asNamespace("ALSCL")
  sets <- list()
  for (f in getNamespaceExports("ALSCL")) {
    defaults <- formals(get(f, envir = ns))
    for (a in names(defaults)) {
      if (identical(defaults[[a]], quote(expr = ))) next
      d <- defaults[[a]]
      if (is.call(d) && identical(d[[1L]], as.name("c"))) {
        value <- eval(d)
        if (is.character(value)) sets[[paste(f, a)]] <- value
      }
    }
  }
  sets <- c(sets, ALSCL:::.acl_structure_choices, list(
    palette = ALSCL:::.acl_palette_names, base_theme = ALSCL:::.acl_theme_names,
    role = names(ALSCL:::.acl_role_keys), legend = ALSCL:::.acl_legend_positions,
    facet_scales = ALSCL:::.acl_facet_scale_names, style = names(ALSCL:::.acl_style_presets),
    structure_sets = c(names(ALSCL:::.acl_structure_sets), names(ALSCL:::.acl_structure_set_aliases)),
    estimates = c("SSB", "Rec", "B", "N", "CN", "CB", "NA", "BA", "SBA", "CNA", "CBA", "F", "FA",
                  "NL", "BL", "SBL", "CNL", "CBL", "FL", "NLA", "BLA", "SBLA", "CNLA", "CBLA", "N_at_age"),
    compare_ts = c("SSB", "R", "Rec", "B", "biomass", "N", "abundance", "CN", "catch", "CB"),
    metrics = c("error", "R2", "MAPE", "IC", "npar"), settings = names(acl_theme()),
    acl_parameters = names(create_parameters("acl")$parameters),
    alscl_parameters = names(create_parameters("alscl")$parameters)))
  expect_gt(length(sets), 40L)
  for (nm in names(sets)) expect_false(anyDuplicated(tolower(sets[[nm]])) > 0L, info = nm)
})

test_that("type and the other choice arguments of the plots accept any letter case", {
  withr::local_options(list(acl.theme = NULL))
  acl <- case_fit("ACL")$result
  alscl <- case_fit("ALSCL")$result
  data <- function(p) p$data
  same_data <- function(f, fit, low, canonical, ...)
    expect_identical(f(fit, type = low, return_data = TRUE, ...), f(fit, type = canonical, return_data = TRUE, ...))
  for (pair in list(c("sbl", "SBL"), c("Sba", "SBA"), c("ssb", "SSB")))
    same_data(plot_SSB, alscl, pair[1L], pair[2L])
  for (pair in list(c("bl", "BL"), c("bA", "BA"), c("b", "B")))
    same_data(plot_biomass, alscl, pair[1L], pair[2L])
  # "na" gives abundance at age and "n" total abundance.
  for (pair in list(c("na", "NA"), c("n", "N"), c("Nl", "NL")))
    same_data(plot_abundance, alscl, pair[1L], pair[2L])
  for (pair in list(c("cna", "CNA"), c("CnL", "CNL"), c("cn", "CN")))
    same_data(plot_catch, alscl, pair[1L], pair[2L])
  expect_same_plot(plot_SSB(alscl, type = "sbl"), plot_SSB(alscl, type = "SBL"))
  expect_same_plot(plot_abundance(acl, type = "na"), plot_abundance(acl, type = "NA"))
  expect_same_plot(plot_SSB(acl, se = TRUE, interval = "Wald"), plot_SSB(acl, se = TRUE, interval = "wald"))
  expect_same_plot(plot_catch(acl, geom = "LINE"), plot_catch(acl, geom = "line"))
  expect_same_plot(plot_recruitment(acl, geom = "Bar", se = TRUE, se_type = "RIBBON"),
                   plot_recruitment(acl, geom = "bar", se = TRUE, se_type = "ribbon"))
  for (pair in list(c("AGE", "age"), c("Year", "year")))
    same_data(plot_fishing_mortality, acl, pair[1L], pair[2L])
  expect_same_plot(plot_fishing_mortality(alscl, type = "Length", se = TRUE, se_type = "ErrorBar"),
                   plot_fishing_mortality(alscl, type = "length", se = TRUE, se_type = "errorbar"))
  expect_same_plot(plot_deviance(acl, type = "f"), plot_deviance(acl, type = "F"))
  expect_same_plot(plot_deviance(acl, type = "r"), plot_deviance(acl, type = "R"))
  expect_identical(plot_CatL(acl, facet_by = "Year", return_data = TRUE)$data,
                   plot_CatL(acl, facet_by = "year", return_data = TRUE)$data)
  expect_identical(plot_residuals(acl, facet_by = "YEAR", return_data = TRUE)$data,
                   plot_residuals(acl, facet_by = "year", return_data = TRUE)$data)
  expect_identical(plot_length_at_age(alscl, basis = "Survey", facet_by = "NONE", return_data = TRUE)$data,
                   plot_length_at_age(alscl, basis = "survey", facet_by = "none", return_data = TRUE)$data)
  expect_identical(plot_relative_catch(acl, type = "Weight", return_data = TRUE)$data,
                   plot_relative_catch(acl, type = "weight", return_data = TRUE)$data)
  expect_identical(plot_survey_catchability(acl, type = "LENGTH", return_data = TRUE)$data,
                   plot_survey_catchability(acl, type = "length", return_data = TRUE)$data)
  # Linf, k and t0 are fixed in the fixture; a covariance of the three gives
  # the curve an interval.
  growth <- acl
  growth$vcov <- diag(c(.001, .002, .0005))
  dimnames(growth$vcov) <- rep(list(c("log_Linf", "log_vbk", "t0")), 2L)
  expect_same_plot(plot_VB(growth, se = TRUE, se_type = "Errorbar", basis = "Population"),
                   plot_VB(growth, se = TRUE, se_type = "errorbar", basis = "population"))
  # Facet scales, base themes and palettes.
  free <- plot_catch(acl, type = "CNA", facet_scales = "Free_Y")
  expect_identical(free$facet$params$free, plot_catch(acl, type = "CNA", facet_scales = "free_y")$facet$params$free)
  expect_identical(free$facet$params$free, list(x = FALSE, y = TRUE))
  expect_equal(plot_SSB(acl, base_theme = "Minimal")$theme, plot_SSB(acl, base_theme = "minimal")$theme)
  expect_equal(plot_SSB(acl, base_theme = "THEME_CLASSIC")$theme, plot_SSB(acl, base_theme = "theme_classic")$theme)
  expect_same_plot(plot_ridges(acl, palette = "NPG"), plot_ridges(acl, palette = "npg"))
  # Comparison plots; the plots with survey indices compare two fits to the
  # same data.
  d <- case_fit("ACL")$input$data.CatL
  expect_identical(plot_compare_ts(acl, alscl, quantities = c("ssb", "r", "Rec"), return_data = TRUE)$data,
                   plot_compare_ts(acl, alscl, quantities = c("SSB", "R", "Rec"), return_data = TRUE)$data)
  expect_same_plot(plot_compare_ts(acl, alscl, quantities = "ssb", se = TRUE, interval = "WALD"),
                   plot_compare_ts(acl, alscl, quantities = "SSB", se = TRUE, interval = "wald"))
  expect_same_plot(plot_compare_F_ts(acl, alscl, method = "MEAN", basis = "Age"),
                   plot_compare_F_ts(acl, alscl, method = "mean", basis = "age"))
  expect_same_plot(plot_compare_growth(acl, alscl, basis = "Survey"),
                   plot_compare_growth(acl, alscl, basis = "survey"))
  expect_same_plot(plot_compare_metrics(acl, acl, d, metrics = c("r2", "Ic")),
                   plot_compare_metrics(acl, acl, d, metrics = c("R2", "IC")))
  expect_same_plot(plot_compare_F(acl, alscl, palette = "NPG"), plot_compare_F(acl, alscl, palette = "npg"))
  top <- plot_compare_residuals(acl, acl, d, legend_pos = "Top")
  expect_identical(top$theme$legend.position, plot_compare_residuals(acl, acl, d, legend_pos = "top")$theme$legend.position)
  expect_identical(plot_compare_CatL(acl, acl, d, facet_scales = "FREE")$facet$params$free, list(x = TRUE, y = TRUE))
  # The retrospective plot.
  r <- expand.grid(Year = 2000:2002, RetrospectiveYear = c("2004", "2003"), Variable = "SSB")
  r$Value <- seq_len(nrow(r))
  retro <- list(results = r, last_points = r[r$Year == 2002, ], rho_text = data.frame(Variable = "SSB", Rho = .01))
  expect_same_plot(plot_retro(retro, rho_position = "Top_Left", facet_scales = "Free"),
                   plot_retro(retro, rho_position = "top_left", facet_scales = "free"))
  # An unknown value is an error that lists the choices.
  expect_error(plot_SSB(acl, type = "sbx"),
               "type must be one of \"SSB\", \"SBL\", \"SBA\" in any letter case, not \"sbx\".", fixed = TRUE)
  expect_error(plot_catch(acl, geom = "area"), "geom must be one of \"bar\", \"line\" in any letter case",
               fixed = TRUE)
  expect_error(plot_catch(acl, type = "CNA", facet_scales = "loose"),
               "facet_scales must be one of \"fixed\", \"free_x\", \"free_y\", \"free\"", fixed = TRUE)
  expect_error(plot_compare_ts(acl, alscl, quantities = c("ssb", "Z")), "Unknown quantities: Z")
})

test_that("theme settings accept any letter case and are stored as the package names them", {
  withr::local_options(list(acl.theme = NULL))
  acl_theme_set(style = "Classic")
  expect_identical(acl_theme("style"), "classic")
  acl_theme_set(style = "DEFAULT", palette = "NPG", grid = "Y", title_face = "Bold.Italic", strip = "BOX",
                legend_position = "Top", interval = "Wald", compare_legend_pos = "Right",
                compare_facet_scales = "FREE", base_theme = "Minimal", title_color = "Quantity")
  keys <- c("style", "palette", "grid", "title_face", "strip", "legend_position", "interval",
            "compare_legend_pos", "compare_facet_scales", "base_theme", "title_color")
  expect_identical(acl_theme()[keys],
                   list(style = "default", palette = "npg", grid = "y", title_face = "bold.italic", strip = "box",
                        legend_position = "top", interval = "wald", compare_legend_pos = "right",
                        compare_facet_scales = "free", base_theme = "minimal", title_color = "quantity"))
  acl_theme_set(base_theme = "Theme_BW")
  expect_identical(acl_theme("base_theme"), "theme_bw")
  # Setting names, quantities and color roles.
  expect_identical(acl_theme("Style"), "default")
  expect_identical(acl_theme("f_color"), acl_theme("F_color"))
  expect_null(acl_theme("no_such_setting"))
  expect_equal(theme_acl(quantity = "f"), theme_acl(quantity = "F"))
  expect_identical(acl_palette(role = c("Stock", "f", "PRIMARY")), acl_palette(role = c("stock", "F", "primary")))
  expect_identical(acl_palette(3, palette = "Lancet"), acl_palette(3, palette = "lancet"))
  expect_error(acl_palette(role = "SSB"), "role must name color roles")
  expect_error(acl_theme_set(grid = "x"), "grid must be one of \"none\", \"y\" in any letter case, not \"x\".",
               fixed = TRUE)
  expect_error(acl_theme_set(compare_facet_scales = "loose"), "compare_facet_scales must be one of")
  expect_error(acl_theme_set(base_theme = "Economist"), "not a supported theme name")
})

test_that("choice arguments of the model and workflow functions accept any letter case", {
  z <- case_fit("ACL")
  fit <- z$result
  expect_identical(extract_estimates(fit, c("ssb", "REC", "n_at_age", "f"), interval = "Wald"),
                   extract_estimates(fit, c("SSB", "Rec", "N_at_age", "F"), interval = "wald"))
  expect_identical(unique(extract_estimates(case_fit("ALSCL")$result, c("cnl", "sbl"))$quantity), c("CNL", "SBL"))
  expect_error(extract_estimates(fit, c("ssb", "SSB")), "quantities must be distinct")
  expect_error(extract_estimates(fit, "ZZ"), "Unsupported population quantity: ZZ")
  expect_identical(extract_parameters(fit, scale = "Internal"), extract_parameters(fit, scale = "internal"))
  expect_identical(length_at_age(fit, basis = c("POPULATION", "Survey")), length_at_age(fit, basis = c("population", "survey")))
  expect_identical(residuals(fit, type = "Standardized"), residuals(fit, type = "standardized"))
  expect_identical(create_parameters("ALSCL", species = "Tuna", bounds = "Wide"),
                   create_parameters("alscl", species = "tuna", bounds = "wide"))
  expect_identical(initialize_params(species = "KRILL", random_numbers = "By_Process", observation_error = "Shared_Time"),
                   initialize_params(species = "krill", random_numbers = "by_process", observation_error = "shared_time"))
  mid <- seq(12.5, 57.5, 5)
  expect_identical(survey_catchability(mid, "Dome", 20, 30, 50, 45), survey_catchability(mid, "dome", 20, 30, 50, 45))
  expect_identical(check_alscl_data(YTF_example, "ACL"), check_alscl_data(YTF_example, "acl"))
  expect_identical(inspect_parameters(YTF_example, "Alscl"), inspect_parameters(YTF_example, "alscl"))
  tables <- YTF_example[c("data.CatL", "data.wgt", "data.mat")]
  expect_identical(prepare_alscl_data(tables, format = "Tables"), prepare_alscl_data(tables, format = "tables"))
  expect_identical(simulate_fit(fit, seed = 1, process = "Resample")$simulations,
                   simulate_fit(fit, seed = 1, process = "resample")$simulations)
  # Time series of a simulation study.
  one <- list(year = c(2000, 2001), report = list(SSB = c(11, 18)),
    est_std = cbind(Estimate = c(11, 18), `Std. Error` = c(1, 1)),
    opt = list(par = c(mean_log_R = 1), objective = 1), elapsed = 2,
    convergence_code = 0L, pdHess = TRUE, bound_hit = FALSE, max_abs_gradient = 0,
    diagnostics = list(numerical_ok = TRUE, natural_boundary = FALSE))
  rownames(one$est_std) <- c("SSB", "SSB")
  target <- list(year = c(2000, 2001), SSB = c(10, 20))
  expect_identical(summarize_simulations(list(a = one), list(a = target), quantities = "ssb", interval = "WALD"),
                   summarize_simulations(list(a = one), list(a = target), quantities = "SSB", interval = "wald"))
  expect_error(summarize_simulations(list(a = one), list(a = target), quantities = "F"), "time-series names")
  # Speed settings.
  old <- options(ALSCL.sd_cores = NULL, ALSCL.framework = NULL)
  on.exit(options(old), add = TRUE)
  alscl_speed(sd_cores = "AUTO", framework = "tmbad")
  expect_identical(getOption("ALSCL.sd_cores"), "auto")
  expect_identical(getOption("ALSCL.framework"), "TMBad")
  alscl_speed(framework = "cppad")
  expect_identical(getOption("ALSCL.framework"), "CppAD")
  expect_error(alscl_speed(framework = "other"), "framework must be one of \"CppAD\", \"TMBad\"")
})

test_that("fits, refits and studies store the values of the package for choices in any letter case", {
  skip_on_cran()
  z <- case_fit("ACL")
  args <- c(z$input, list(parameters = z$parameters, map = z$map, silent = TRUE))
  fit <- function(...) do.call(run_acl, c(args, list(...)))
  a <- fit(F_structure = "Year", zero_action = "MISSING", bounds = "Wide",
           structure = list(correlation_range = "Symmetric"))
  b <- fit(F_structure = "year", zero_action = "missing", bounds = "wide",
           structure = list(correlation_range = "symmetric"))
  expect_identical(a$F_structure, "year")
  expect_identical(a$structure, b$structure)
  expect_identical(a$structure$correlation_range, "symmetric")
  expect_equal(a$opt$par, b$opt$par)
  expect_equal(a$report$SSB, b$report$SSB)
  # Names of structure sets and values of settings.
  expect_identical(ALSCL:::.acl_structure("Von_Bertalanffy", "ALSCL"), ALSCL:::.acl_structure("von_bertalanffy", "ALSCL"))
  expect_identical(ALSCL:::.acl_structure(list(set = "ORIGINAL", initial_deviations = "Independent"), "ACL"),
                   ALSCL:::.acl_structure(list(set = "original", initial_deviations = "independent"), "ACL"))
  expect_true(ALSCL:::.acl_scale_settings(list(structure = list(correlation_range = "SYMMETRIC")))$symmetric)
  expect_error(ALSCL:::.acl_structure(list(correlation_range = "wide"), "ACL"),
               "structure\\$correlation_range must be one of")
  # Retrospective analysis, hindcast, scenarios, self-test and profile.
  retro_upper <- retro_model(args, nyear = 1, model_type = "ACL")
  retro_lower <- retro_model(args, nyear = 1, model_type = "acl")
  expect_identical(retro_upper$model_type, "acl")
  expect_equal(retro_upper$results, retro_lower$results)
  expect_identical(retro_model(args, nyear = 1, model = "Acl")$model_type, "acl")
  hind_upper <- hindcast_model(args, model = "ACL", nfolds = 1)
  hind_lower <- hindcast_model(args, model = "acl", nfolds = 1)
  expect_equal(hind_upper$predictions, hind_lower$predictions)
  scen_upper <- fit_scenarios(args, list(reference = list()), model = "ACL", F_summary = "Apical")
  scen_lower <- fit_scenarios(args, list(reference = list()), model = "acl", F_summary = "apical")
  expect_equal(scen_upper$estimates, scen_lower$estimates)
  self_upper <- self_test(z$result, nsim = 1, seed = 3, process = "Resample", start = "ORIGINAL",
                          quantities = c("ssb", "REC", "f"), F_summary = "Apical", interval = "Wald")
  self_lower <- self_test(z$result, nsim = 1, seed = 3, process = "resample", start = "original",
                          quantities = c("SSB", "Rec", "F"), F_summary = "apical", interval = "wald")
  expect_identical(self_upper$settings$quantities, c("SSB", "Rec", "F"))
  expect_equal(self_upper$series, self_lower$series)
  expect_equal(self_upper$parameters, self_lower$parameters)
  expect_same_plot(plot_self_test(self_upper, what = "Series"), plot_self_test(self_lower, what = "series"))
  expect_error(self_test(z$result, nsim = 1, quantities = "Z"), "quantities must contain")
  # A profile needs two free parameters; the name of the parameter is matched
  # in any letter case.
  args$map["log_Linf"] <- list(NULL)
  two <- do.call(run_acl, args)
  values <- exp(two$opt$par[["mean_log_R"]]) * c(0.95, 1.05)
  grid <- function(p) p$grid[setdiff(names(p$grid), "elapsed")]
  expect_equal(grid(profile_model(two, "MEAN_LOG_R", values, scale = "Natural")),
               grid(profile_model(two, "mean_log_R", values, scale = "natural")))
  expect_error(profile_model(two, "mean_log_Z", values), "parameter must name one free scalar")
  # Simulation studies: the model is resolved before the simulated data are read.
  expect_error(sim_model(model = "ACL", t0_lower = 0), "t0_lower applies to ALSCL only")
})
