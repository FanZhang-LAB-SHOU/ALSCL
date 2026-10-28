plot_data_fixture_227 <- function(periods = 3L, groups = 3L, model = "ALSCL", shared = FALSE) {
  value <- matrix(seq_len(groups * periods) + 10, groups, periods,
    dimnames = list(rev(paste0("group", seq_len(groups))), as.character(2020 + seq_len(periods))))
  dev <- if (shared) matrix(seq_len(periods) / 10, 1L, periods) else value / 100
  report <- list(N = colSums(value), Rec = seq_len(periods) + 5,
                 "NA" = value, NL = value * 2,
                 dev_log_R = seq_len(periods) / 20, dev_log_F = dev)
  report[[if (model == "ALSCL") "FL" else "F"]] <- value / 30
  blocks <- lapply(c("N", "Rec", "NA", "NL", "dev_log_R", "dev_log_F"), function(name) {
    x <- as.numeric(report[[name]])
    cbind(Estimate = x, "Std. Error" = seq_along(x) / 100)
  })
  se <- do.call(rbind, blocks)
  rownames(se) <- rep(c("N", "Rec", "NA", "NL", "dev_log_R", "dev_log_F"),
                      vapply(blocks, nrow, integer(1)))
  # Similar prefixes must not be mistaken for the requested quantity.
  se <- rbind(se, c(999, 999), c(999, 999))
  rownames(se)[(nrow(se) - 1L):nrow(se)] <- c("NLA", "dev_log_R_extra")
  list(model_type = model, F_structure = if (shared) "year" else "group_year",
       year = 2000 + seq_len(periods) / 4, len_label = as.character(seq_len(groups) * 10),
       report = report, est_std = se)
}

plot_calls_227 <- function(m) list(
  N = function(se) plot_abundance(m, type = "N", se = se),
  "NA" = function(se) plot_abundance(m, type = "NA", se = se),
  NL = function(se) plot_abundance(m, type = "NL", se = se),
  Rec = function(se) plot_recruitment(m, se = se),
  dev_log_R = function(se) plot_deviance(m, type = "R", se = se),
  dev_log_F = function(se) plot_deviance(m, type = "F", se = se))

test_that("named abundance matrices use fit coordinates without reordering values", {
  m <- plot_data_fixture_227()
  for (type in c("NA", "NL")) for (se in c(FALSE, TRUE)) {
    out <- plot_abundance(m, type = type, se = se, return_data = TRUE)
    expect_equal(out$data$Year, rep(m$year, each = 3L))
    groups <- if (type == "NA") out$data$AgeGroup else out$data$LengthGroup
    expect_equal(as.character(groups), rep(paste(if (type == "NA") "Age bin" else "Length bin",
      if (type == "NA") 1:3 else c(10, 20, 30)), 3L))
    values <- if (se) out$data$estimate else if (type == "NA") out$data$number.age else out$data$Count
    expect_equal(values, as.numeric(m$report[[type]]))
    expect_s3_class(ggplot2::ggplot_build(out$plot), "ggplot_built")
  }
})

test_that("requested uncertainty rejects incomplete or invalid standard errors", {
  base <- plot_data_fixture_227()
  for (name in names(plot_calls_227(base))) {
    for (bad in c(NA_real_, Inf, -1)) {
      m <- base
      m$est_std[rownames(m$est_std) == name, "Std. Error"] <- bad
      expect_error(plot_calls_227(m)[[name]](TRUE), "finite and nonnegative", info = name)
      expect_no_error(plot_calls_227(m)[[name]](FALSE))
    }
    m <- base; m$est_std <- NULL
    expect_error(plot_calls_227(m)[[name]](TRUE), "unavailable or incomplete", info = name)
    expect_no_error(plot_calls_227(m)[[name]](FALSE))
    m <- base; row <- which(rownames(m$est_std) == name)[1L]
    m$est_std <- m$est_std[-row, , drop = FALSE]
    expect_error(plot_calls_227(m)[[name]](TRUE), "unavailable or incomplete", info = name)
    m <- base; m$est_std[row, "Estimate"] <- NA_real_
    expect_error(plot_calls_227(m)[[name]](TRUE), "finite and nonnegative", info = name)
  }
})

test_that("single-period and single-group plots retain SE dimensions", {
  for (model in c("ACL", "ALSCL")) for (shared in c(FALSE, TRUE)) {
    m <- plot_data_fixture_227(periods = 1L, groups = 1L, model = model, shared = shared)
    for (name in names(plot_calls_227(m))) {
      p <- plot_calls_227(m)[[name]](TRUE)
      expect_equal(nrow(p$data), 1L, info = paste(model, name))
      expect_equal(p$data$upper - p$data$lower, .0392, ignore_attr = TRUE)
    }
    expect_equal(as.character(plot_deviance(m, type = "F")$data$Group),
      if (shared) "Shared F" else if (model == "ALSCL") "Length 10" else "Age group 1")
  }
})

test_that("deviation estimates survive absent sdreport and support legacy tables", {
  for (model in c("ACL", "ALSCL")) for (shared in c(FALSE, TRUE)) {
    m <- plot_data_fixture_227(model = model, shared = shared)
    for (type in c("R", "F")) {
      name <- paste0("dev_log_", type)
      no_se <- m; no_se$est_std <- NULL
      p <- plot_deviance(no_se, type = type, se = FALSE)
      expect_equal(p$data$estimate, as.numeric(m$report[[name]]))
      expect_equal(p$data$Year, rep(m$year, each = if (type == "R" || shared) 1L else 3L))
      expect_length(p$layers, 2L)
      expect_true(all(is.na(p$data$lower)))
      exponentiated <- plot_deviance(no_se, type = type, se = FALSE, log = FALSE)
      expect_equal(exponentiated$data$estimate, exp(p$data$estimate))
      legacy <- m; legacy$report[[name]] <- NULL
      legacy$est_std <- legacy$est_std[, "Estimate", drop = FALSE]
      expect_equal(plot_deviance(legacy, type = type, se = FALSE)$data$estimate, p$data$estimate)
      expect_error(plot_deviance(legacy, type = type, se = TRUE), "unavailable or incomplete")
      legacy$est_std <- NULL
      expect_error(plot_deviance(legacy, type = type, se = FALSE), "Estimates.*unavailable or incomplete")
    }
  }
})

test_that("plot data validation rejects dimension recycling and invalid controls", {
  m <- plot_data_fixture_227()
  bad <- m; bad$report$N <- 1
  expect_error(plot_abundance(bad), "one estimate per time step")
  bad <- m; bad$report$Rec <- 1
  expect_error(plot_recruitment(bad), "one estimate per time step")
  bad <- m; bad$report$NL <- bad$report$NL[, 1:2]
  expect_error(plot_abundance(bad, type = "NL"), "group-by-time")
  bad <- m; bad$len_label <- bad$len_label[1:2]
  expect_error(plot_abundance(bad, type = "NL"), "every length group uniquely")
  expect_error(plot_deviance(bad, type = "F"), "every length group uniquely")
  bad <- m; bad$report$dev_log_F <- t(bad$report$dev_log_F[, 1:2])
  expect_error(plot_deviance(bad, type = "F", se = FALSE), "matching the model groups")
  for (fun in plot_calls_227(m)) expect_error(fun(NA), "se must be TRUE or FALSE")
  expect_error(plot_deviance(m, log = NA), "log must be TRUE or FALSE")
})

test_that("real models retain reported deviation modes without uncertainty tables", {
  for (model in c("ACL", "ALSCL")) {
    fixture <- fit_fixture(model)
    for (structure in c("group_year", "year")) {
      fit <- if (structure == "group_year") fixture$result else do.call(
        if (model == "ACL") run_acl else run_alscl,
        c(fixture$input, list(parameters = fixture$parameters, map = fixture$map,
                             F_structure = "year", silent = TRUE)))
      fit$est_std <- NULL
      for (type in c("R", "F")) {
        p <- plot_deviance(fit, type = type, se = FALSE)
        expect_equal(p$data$estimate, as.numeric(fit$report[[paste0("dev_log_", type)]]))
        expect_s3_class(ggplot2::ggplot_build(p), "ggplot_built")
      }
    }
  }
})


test_that("age facets keep numeric group order when confidence intervals are enabled", {
  m <- plot_data_fixture_227(groups = 15L)
  plain <- plot_abundance(m, type = "NA", se = FALSE)
  interval <- plot_abundance(m, type = "NA", se = TRUE)
  plain_layout <- ggplot2::ggplot_build(plain)$layout$layout
  interval_layout <- ggplot2::ggplot_build(interval)$layout$layout
  expected <- paste("Age bin", 1:15)
  expect_equal(levels(interval$data$AgeGroup), expected)
  expect_equal(as.character(plain_layout$AgeGroup), expected)
  expect_equal(as.character(interval_layout$AgeGroup), expected)
  expect_equal(interval_layout[c("ROW", "COL", "AgeGroup")],
               plain_layout[c("ROW", "COL", "AgeGroup")])
})
