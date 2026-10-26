population_plot_fixture_225 <- function() {
  values <- matrix(c(10, 20, 30, 12, 23, 34, 15, 27, 39), 3L, 3L,
    dimnames = list(c("large", "small", "medium"), c("2020", "2021", "2022")))
  errors <- seq_len(9L) / 10
  list(model_type = "ALSCL", year = c(2000, 2000.25, 2000.5),
    len_label = c("10", "20", "30"),
    report = list(BL = values, SBL = values / 2),
    est_std = rbind(
      matrix(c(as.numeric(values), errors), 9L, 2L,
        dimnames = list(rep("BL", 9L), c("Estimate", "Std. Error"))),
      matrix(c(as.numeric(values / 2), errors / 2), 9L, 2L,
        dimnames = list(rep("SBL", 9L), c("Estimate", "Std. Error"))),
      matrix(c(999, 999), 1L, 2L,
        dimnames = list("BLA", c("Estimate", "Std. Error")))))
}

test_that("length biomass and SSB intervals use available SEs and actual coordinates", {
  model <- population_plot_fixture_225()
  for (type in c("BL", "SBL")) {
    fun <- if (type == "BL") plot_biomass else plot_SSB
    plain <- fun(model, type = type, se = FALSE, return_data = TRUE)
    out <- fun(model, type = type, se = TRUE, return_data = TRUE,
      line_color = "navy", se_color = "orange", se_alpha = .3)
    expected <- as.numeric(model$report[[type]])
    errors <- (seq_len(9L) / 10) / if (type == "BL") 1 else 2
    expect_named(plain$data, c("LengthGroup", "Year", "Count"))
    expect_equal(plain$data$Count, expected)
    expect_length(plain$plot$layers, 1L)
    expect_named(out$data, c("LengthGroup", "Year", "estimate", "lower", "upper"))
    expect_equal(out$data$Year, rep(model$year, each = 3L))
    expect_equal(as.character(out$data$LengthGroup), rep(paste("Length bin", c(10, 20, 30)), 3L))
    expect_equal(out$data$estimate, expected, ignore_attr = TRUE)
    expect_equal(out$data$lower, expected - 1.96 * errors, ignore_attr = TRUE)
    expect_equal(out$data$upper, expected + 1.96 * errors, ignore_attr = TRUE)
    expect_length(out$plot$layers, 2L)
    built <- ggplot2::ggplot_build(out$plot)
    sorted <- order(out$data$LengthGroup, out$data$Year)
    expect_equal(built$data[[2L]]$x, out$data$Year[sorted])
    expect_equal(built$data[[2L]]$ymin, out$data$lower[sorted], ignore_attr = TRUE)
    expect_equal(built$data[[2L]]$ymax, out$data$upper[sorted], ignore_attr = TRUE)
    expect_true(all(built$data[[2L]]$fill == "orange"))
    expect_true(all(built$data[[2L]]$alpha == .3))
  }
})

test_that("population plots explain missing quantities and unavailable uncertainty", {
  model <- population_plot_fixture_225()
  for (type in c("BL", "SBL")) {
    fun <- if (type == "BL") plot_biomass else plot_SSB
    changed <- model
    changed$est_std <- NULL
    expect_error(fun(changed, type = type, se = TRUE),
      paste0("Standard errors for '", type, "'.*Use se = FALSE"))
    expect_no_error(fun(changed, type = type, se = FALSE))
    changed <- model
    index <- which(rownames(changed$est_std) == type)
    changed$est_std <- changed$est_std[-index[1L], , drop = FALSE]
    expect_error(fun(changed, type = type, se = TRUE), "unavailable or incomplete")
    changed <- model
    changed$est_std[index[1L], "Std. Error"] <- NA_real_
    expect_error(fun(changed, type = type, se = TRUE), "finite and nonnegative")
    changed$est_std[index[1L], "Std. Error"] <- -1
    expect_error(fun(changed, type = type, se = TRUE), "finite and nonnegative")
  }
  expect_error(plot_biomass(model, type = "BA"), "Quantity 'BA'.*Available types: BL")
  expect_error(plot_SSB(model, type = "SBA"), "Quantity 'SBA'.*Available types: SBL")
  expect_error(plot_catch(model, type = "CNL"), "Quantity 'CNL'.*not available")
  expect_error(plot_biomass(model, type = "BL", se = NA), "se must be TRUE or FALSE")
  changed <- model; changed$year <- changed$year[-1L]
  expect_error(plot_biomass(changed, type = "BL"), "group-by-time matrix")
  changed <- model; changed$len_label <- changed$len_label[-1L]
  expect_error(plot_SSB(changed, type = "SBL"), "every length group uniquely")
})

test_that("real ACL and ALSCL outputs follow the documented plot support matrix", {
  specifications <- list(
    list(fun = plot_biomass, types = c("B", "BL", "BA")),
    list(fun = plot_SSB, types = c("SSB", "SBL", "SBA")),
    list(fun = plot_catch, types = c("CN", "CNA", "CNL")))
  for (model_type in c("ACL", "ALSCL")) {
    fit <- fit_fixture(model_type)$result
    for (spec in specifications) for (type in spec$types) for (se in c(FALSE, TRUE)) {
      if (model_type == "ACL" && type %in% c("BA", "SBA", "CNL")) {
        expect_error(spec$fun(fit, type = type, se = se),
          paste0("Quantity '", type, "' is not available"))
      } else if (model_type == "ACL" && se && type %in% c("BL", "SBL", "CNA")) {
        expect_error(spec$fun(fit, type = type, se = se),
          paste0("Standard errors for '", type, "'.*Use se = FALSE"))
      } else {
        out <- spec$fun(fit, type = type, se = se, return_data = TRUE)
        expect_s3_class(ggplot2::ggplot_build(out$plot), "ggplot_built")
        expect_length(out$plot$layers, if (se) 2L else 1L)
        if (se) {
          errors <- fit$est_std[rownames(fit$est_std) == type, "Std. Error"]
          expect_equal(out$data$upper - out$data$lower, 3.92 * errors,
            ignore_attr = TRUE)
        }
      }
    }
  }
})

test_that("single-period stored results retain their SE matrix dimensions", {
  model <- list(year = 2000, report = list(B = 10, SSB = 5, CN = 2),
    est_std = matrix(c(10, 5, 2, .5, .25, .1), 3L, 2L,
      dimnames = list(c("B", "SSB", "CN"), c("Estimate", "Std. Error"))))
  for (fun in list(plot_biomass, plot_SSB, plot_catch)) {
    out <- fun(model, se = TRUE, return_data = TRUE)
    expect_equal(nrow(out$data), 1L)
    expect_true(all(is.finite(out$data$lower)))
    expect_true(all(is.finite(out$data$upper)))
  }
})
