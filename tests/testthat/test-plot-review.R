plot_review_fixture <- function(model = "ACL", groups = 15L, periods = 3L) {
  values <- matrix(seq_len(groups * periods) / 100, groups, periods,
    dimnames = list(paste0("group", rev(seq_len(groups))),
                    as.character(2000 + seq_len(periods))))
  report <- list(SSB = seq_len(periods) * 10, Rec = seq_len(periods) * 2,
    BA = values * 10, SBA = values * 5, CNA = values * 3)
  report[[if (model == "ACL") "F" else "FL"]] <- values
  if (model == "ALSCL" && periods > 1L)
    report$FA <- values[seq_len(max(1L, groups - 1L)), seq_len(periods - 1L), drop = FALSE]
  blocks <- lapply(report, function(x)
    cbind(Estimate = as.numeric(x), "Std. Error" = rep(.01, length(x))))
  est_std <- do.call(rbind, blocks)
  rownames(est_std) <- rep(names(blocks), vapply(blocks, nrow, integer(1)))
  list(model_type = model, report = report, year = 1990 + (seq_len(periods) - 1) / 4,
       age = seq_len(groups), len_label = as.character(seq_len(groups) * 5),
       len_mid = seq_len(groups) * 5, est_std = est_std)
}

test_that("all fishing mortality layouts use positions rather than matrix dimnames", {
  for (model in c("ACL", "ALSCL")) {
    m <- plot_review_fixture(model)
    unnamed <- m
    for (name in c("F", "FL", "FA"))
      if (!is.null(unnamed$report[[name]])) dimnames(unnamed$report[[name]]) <- NULL
    types <- if (model == "ACL") c("year", "age") else c("year", "length", "age")
    for (type in types) for (se in c(FALSE, TRUE)) {
      result <- plot_fishing_mortality(m, type = type, se = se, return_data = TRUE)
      expected <- plot_fishing_mortality(unnamed, type = type, se = se, return_data = TRUE)
      expect_equal(result$data, expected$data, info = paste(model, type, se))
      expect_true(all(is.finite(result$data$Year)))
      field <- if (model == "ACL") "F" else if (type == "age") "FA" else "FL"
      expected_years <- if (field == "FA") head(m$year, -1L) else m$year
      expect_equal(result$data$Year, rep(expected_years, each = nrow(m$report[[field]])))
      expect_equal(if (se) result$data$estimate else result$data$F,
                   as.numeric(m$report[[field]]))
      if (type == "length") expect_equal(result$data$Length, rep(m$len_mid, length(m$year)))
      expect_s3_class(ggplot2::ggplot_build(result$plot), "ggplot_built")
    }
  }
})

test_that("F and comparison intervals reject missing, recycled and invalid errors", {
  cases <- list(list(model = "ACL", type = "year", field = "F"),
                list(model = "ACL", type = "age", field = "F"),
                list(model = "ALSCL", type = "year", field = "FL"),
                list(model = "ALSCL", type = "length", field = "FL"),
                list(model = "ALSCL", type = "age", field = "FA"))
  for (case in cases) {
    original <- plot_review_fixture(case$model)
    rows <- which(rownames(original$est_std) == case$field)
    for (bad in c(NA_real_, NaN, Inf, -1)) {
      m <- original; m$est_std[rows[1L], "Std. Error"] <- bad
      expect_error(plot_fishing_mortality(m, type = case$type, se = TRUE),
                   "finite and nonnegative")
      expect_no_error(plot_fishing_mortality(m, type = case$type, se = FALSE))
    }
    m <- original; m$est_std <- m$est_std[-rows[seq.int(1L, length(rows), by = 2L)], , drop = FALSE]
    expect_error(plot_fishing_mortality(m, type = case$type, se = TRUE),
                 "unavailable or incomplete|one FL estimate")
    m <- original; m$est_std <- NULL
    expect_error(plot_fishing_mortality(m, type = case$type, se = TRUE),
                 "unavailable or incomplete|one FL estimate")
    m <- original; m$est_std[rows[1L], "Estimate"] <- Inf
    expect_error(plot_fishing_mortality(m, type = case$type, se = TRUE), "finite")
  }
  original <- plot_review_fixture()
  for (model_index in 1:2) {
    for (bad in c(NA_real_, NaN, Inf, -1)) {
      models <- list(original, original)
      rows <- which(rownames(original$est_std) == "SSB")
      models[[model_index]]$est_std[rows[1L], "Std. Error"] <- bad
      expect_error(plot_compare_ts(models[[1]], models[[2]], quantities = "SSB", se = TRUE),
                   "finite and nonnegative")
    }
    models <- list(original, original); models[[model_index]]$est_std <- NULL
    expect_error(plot_compare_ts(models[[1]], models[[2]], quantities = "SSB", se = TRUE),
                 "unavailable or incomplete")
    expect_no_error(plot_compare_ts(models[[1]], models[[2]], quantities = "SSB", se = FALSE))
  }
})

test_that("age facets retain numeric order when confidence intervals are added", {
  m <- plot_review_fixture()
  specs <- list(list(fun = plot_biomass, type = "BA"),
                list(fun = plot_SSB, type = "SBA"),
                list(fun = plot_catch, type = "CNA"),
                list(fun = plot_fishing_mortality, type = "year"))
  for (spec in specs) {
    plain <- spec$fun(m, type = spec$type, se = FALSE, return_data = TRUE)
    interval <- spec$fun(m, type = spec$type, se = TRUE, return_data = TRUE)
    expect_identical(plain$data$AgeGroup, interval$data$AgeGroup)
    panels <- ggplot2::ggplot_build(interval$plot)$layout$layout$AgeGroup
    expect_equal(as.character(panels), paste("Age bin", seq_len(15)))
  }
})

test_that("stored singleton F results retain dimensions and validate plot inputs", {
  for (model in c("ACL", "ALSCL")) {
    m <- plot_review_fixture(model, groups = 1L, periods = 1L)
    types <- if (model == "ACL") c("year", "age") else c("year", "length")
    for (type in types) {
      result <- plot_fishing_mortality(m, type = type, se = TRUE, return_data = TRUE)
      expect_equal(nrow(result$data), 1L)
      expect_equal(result$data$upper - result$data$lower, .0392)
    }
    expect_error(plot_fishing_mortality(m, se = NA), "se must be TRUE or FALSE")
    m$year <- NA_real_
    expect_error(plot_fishing_mortality(m), "finite, increasing year")
  }
  m <- plot_review_fixture("ALSCL", groups = 2L, periods = 2L)
  out <- plot_fishing_mortality(m, type = "age", se = TRUE, return_data = TRUE)
  expect_equal(nrow(out$data), 1L)
  expect_equal(out$data$Year, m$year[1L])
  m$report$FA[1L] <- Inf
  expect_error(plot_fishing_mortality(m, type = "age"), "finite numeric group-by-time")
})

test_that("comparison requests cannot silently lose quantities or F panels", {
  m <- plot_review_fixture()
  for (quantities in list("F", c("SSB", "F"), "f"))
    expect_error(plot_compare_ts(m, m, quantities = quantities), "plot_compare_annual_F")
  for (quantities in list(character(), NA_character_, 1, c("SSB", "typo")))
    expect_error(plot_compare_ts(m, m, quantities = quantities), "quantities")
  expect_error(plot_compare_ts(m, m, quantities = "B"), "Quantity 'B'.*unavailable")
  bad <- m; bad$report$SSB <- bad$report$SSB[-1L]
  expect_error(plot_compare_ts(m, bad, quantities = "SSB"), "one finite numeric estimate per time step")
  bad <- m; bad$report$SSB[1L] <- Inf
  expect_error(plot_compare_ts(m, bad, quantities = "SSB"), "one finite numeric estimate per time step")
  expect_error(plot_compare_ts(m, m, quantities = "SSB", se = NA), "se must be TRUE or FALSE")
  out <- plot_compare_ts(m, m, quantities = c("R", "Rec", "SSB"), se = TRUE, return_data = TRUE)
  expect_equal(nrow(out$data), length(m$year) * 4L)
  expect_equal(nrow(out$plot$layers[[2L]]$data), nrow(out$data))
  expect_s3_class(ggplot2::ggplot_build(out$plot), "ggplot_built")
})

test_that("residual plot labels and title alignment honor explicit and global settings", {
  old <- options(acl.theme = NULL); on.exit(options(old))
  m <- list(year = 2001:2003, len_mid = c(5, 10, 15), len_label = c("5", "10", "15"),
            observations = matrix(10, 3L, 3L), report = list(resid_index = matrix((1:9) / 100, 3L)))
  for (type in c("length", "year")) {
    p <- plot_residuals(m, type = type, title = "Study title", xlab = "Study x",
                        ylab = "Study y", title_hjust = 0)
    expect_equal(p$labels$title, "Study title")
    expect_equal(p$labels$x, "Study x")
    expect_equal(p$labels$y, "Study y")
    theme <- ggplot2::ggplot_build(p)$plot$theme
    expect_equal(ggplot2::calc_element("plot.title", theme)$hjust, 0)
    expect_s3_class(ggplot2::calc_element("panel.grid.major.x", theme), "element_blank")
  }
  acl_theme_set(title_hjust = 1)
  p <- plot_residuals(m)
  expect_equal(ggplot2::calc_element("plot.title", ggplot2::ggplot_build(p)$plot$theme)$hjust, 1)
})

test_that("real ACL and ALSCL F outputs remain drawable after naming matrices", {
  for (model in c("ACL", "ALSCL")) {
    fit <- fit_fixture(model)$result
    fields <- if (model == "ACL") "F" else c("FL", "FA")
    named <- fit
    for (field in fields) dimnames(named$report[[field]]) <- list(
      paste0("group", seq_len(nrow(named$report[[field]]))),
      as.character(head(fit$year, ncol(named$report[[field]]))))
    for (type in if (model == "ACL") c("year", "age") else c("year", "age", "length")) {
      plain <- plot_fishing_mortality(fit, type = type, return_data = TRUE)
      result <- plot_fishing_mortality(named, type = type, return_data = TRUE)
      expect_equal(result$data, plain$data)
      for (se_type in c("ribbon", "errorbar")) {
        ci <- plot_fishing_mortality(named, type = type, se = TRUE,
                                    se_type = se_type, return_data = TRUE)
        expect_true(all(is.finite(ci$data$lower) & ci$data$lower <= ci$data$upper))
        expect_s3_class(ggplot2::ggplot_build(ci$plot), "ggplot_built")
      }
    }
  }
})

test_that("comparison grids accept equivalent tibble and factor survey tables", {
  m <- plot_review_fixture(groups = 3L)
  observed <- matrix(seq_len(9L) + 10, 3L, 3L)
  m$report$Elog_index <- log(observed * 1.1)
  data <- data.frame(LengthBin = m$len_label, observed, check.names = FALSE)
  names(data)[-1L] <- as.character(m$year)
  original <- plot_compare_CatL(m, m, data)
  text <- data
  text[-1L] <- lapply(text[-1L], function(x) factor(as.character(x)))
  for (input in list(dplyr::as_tibble(data), text, dplyr::as_tibble(text))) {
    p <- plot_compare_CatL(m, m, input)
    expect_equal(p$data, original$data)
    expect_s3_class(ggplot2::ggplot_build(p), "ggplot_built")
  }
})

test_that("default time-series comparison works for both real models with uncertainty", {
  acl <- fit_fixture("ACL")$result
  alscl <- fit_fixture("ALSCL")$result
  expect_identical(eval(formals(plot_compare_ts)$quantities), c("SSB", "R", "B", "N", "CN"))
  labels <- c("Spawning Stock Biomass", "Recruitment", "Total Biomass",
              "Total Abundance", "Catch Numbers")
  for (models in list(list(acl, alscl), list(acl, acl), list(alscl, alscl))) {
    for (se in c(FALSE, TRUE)) {
      out <- plot_compare_ts(models[[1L]], models[[2L]], se = se, return_data = TRUE)
      expect_identical(levels(out$data$Quantity), labels)
      expect_equal(nrow(out$data), 5L * (length(models[[1L]]$year) + length(models[[2L]]$year)))
      expect_length(out$plot$layers, if (se) 2L else 1L)
      if (se) expect_equal(nrow(out$plot$layers[[2L]]$data), nrow(out$data))
      expect_s3_class(ggplot2::ggplot_build(out$plot), "ggplot_built")
    }
  }
  expect_error(plot_compare_ts(acl, alscl, quantities = "CB"), "Quantity 'CB'.*unavailable")
  # CB remains an explicit opt-in for results that actually provide it.
  supplied <- plot_review_fixture()
  supplied$report$CB <- c(3, 4, 5)
  supplied$est_std <- rbind(supplied$est_std,
    matrix(c(3, 4, 5, .1, .2, .3), 3L, 2L,
      dimnames = list(rep("CB", 3L), c("Estimate", "Std. Error"))))
  for (se in c(FALSE, TRUE)) {
    out <- plot_compare_ts(supplied, supplied, quantities = "CB", se = se, return_data = TRUE)
    expect_equal(out$data$Value, rep(c(3, 4, 5), 2L))
    expect_identical(levels(out$data$Quantity), "Catch Biomass")
  }
})
