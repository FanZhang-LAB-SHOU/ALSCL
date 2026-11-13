retro_plot_fixture <- function(times = 2000:2004, peels = 3L) {
  Y <- length(times)
  d <- expand.grid(step = seq_len(Y), Peel = 0:peels, Variable = c("B", "Rec", "SSB", "N"),
                   stringsAsFactors = FALSE)
  d <- d[d$step <= Y - d$Peel, ]
  d$Year <- times[d$step]
  terminal <- times[Y - d$Peel]
  d$Value <- 100 + d$step + d$Peel
  d$NumericalOK <- TRUE
  d$RetrospectiveYear <- factor(terminal, levels = rev(times[seq.int(Y - peels, Y)]))
  d$step <- NULL
  diagnostics <- data.frame(Peel = 0:peels, RetrospectiveYear = times[Y - 0:peels],
                            error = "", numerical_ok = TRUE)
  list(results = d, last_points = d[d$Year == terminal, ],
       rho_text = data.frame(Variable = c("B", "Rec", "SSB", "N"), Rho = .01, Year = times[2L],
                             Valid = TRUE, ValidPeels = peels, RequestedPeels = peels),
       model_type = "acl", fit_diagnostics = diagnostics)
}
retro_color_scale <- function(plot) ggplot2::ggplot_build(plot)$plot$scales$get_scales("colour")

test_that("a complete annual retrospective plot keeps its appearance", {
  r <- retro_plot_fixture()
  p <- plot_retro(r)
  built <- ggplot2::ggplot_build(p)
  expect_identical(p$labels$colour, "Terminal year")
  expect_identical(retro_color_scale(p)$get_labels(), c("2004", "2003", "2002", "2001"))
  expect_equal(retro_color_scale(p)$map(c("2004", "2003", "2002", "2001")), ggsci::pal_npg()(4))
  expect_equal(unique(built$data[[1L]]$linetype), 1)
  expect_null(p$labels$subtitle)
  expect_null(built$plot$scales$get_scales("linetype"))
  expect_true(all(grepl("^rho = 0.0100$", built$data[[3L]]$label)))
})

test_that("a peel that failed the numerical screen is dashed and named (GS4)", {
  r <- retro_plot_fixture()
  r$results$NumericalOK[r$results$Peel == 2L] <- FALSE
  r$rho_text$Rho <- NA_real_
  r$rho_text$ValidPeels <- 2L
  p <- plot_retro(r)
  built <- ggplot2::ggplot_build(p)
  lines <- built$data[[1L]]
  failed_group <- which(levels(r$results$RetrospectiveYear) == "2002")
  expect_identical(unique(lines$linetype[lines$group == failed_group]), "dashed")
  expect_identical(unique(lines$linetype[lines$group != failed_group]), "solid")
  expect_identical(built$plot$scales$get_scales("linetype")$name, "Numerical screen")
  expect_match(p$labels$subtitle, "numerical checks")
  expect_match(p$labels$subtitle, "Failed the numerical screen: terminal year 2002.", fixed = TRUE)
  expect_true(all(built$data[[3L]]$label == "rho unavailable (2 of 3 peels valid): check diagnostics"))
  expect_no_warning(ggplot2::ggplotGrob(p))
})

test_that("a peel without estimates stays in the legend and colors stay with the peel (GS4)", {
  r <- retro_plot_fixture()
  reference <- retro_color_scale(plot_retro(r))$map(c("2004", "2003", "2002", "2001"))
  r$results <- r$results[r$results$Peel != 1L, ]
  r$last_points <- r$last_points[r$last_points$Peel != 1L, ]
  r$rho_text$Rho <- NA_real_
  p <- plot_retro(r)
  scale <- retro_color_scale(p)
  expect_identical(scale$map(c("2004", "2003", "2002", "2001")), reference)
  expect_identical(scale$get_labels(), c("2004", "2003 (no estimates)", "2002", "2001"))
  expect_match(p$labels$subtitle, "No estimates: terminal year 2003.", fixed = TRUE)
  expect_no_warning(ggplot2::ggplotGrob(p))

  # Without the diagnostics table the recorded peel index still fixes the colors.
  r$fit_diagnostics <- NULL
  scale <- retro_color_scale(plot_retro(r))
  expect_identical(scale$map(c("2004", "2002", "2001")), reference[c(1L, 3L, 4L)])

  # A full fit without estimates is listed as well.
  r <- retro_plot_fixture()
  r$results <- r$results[r$results$Peel != 0L, ]
  r$last_points <- r$last_points[r$last_points$Peel != 0L, ]
  scale <- retro_color_scale(plot_retro(r))
  expect_identical(scale$get_labels()[1L], "2004 (no estimates)")
  expect_identical(scale$map(c("2003", "2002", "2001")), reference[2:4])

  # Named colors still refer to the numeric terminal periods.
  p <- plot_retro(retro_plot_fixture(),
    colors = c("2004" = "black", "2003" = "red", "2002" = "blue", "2001" = "green"))
  expect_identical(retro_color_scale(p)$map(c("2003", "2001")), c("red", "green"))
})

test_that("quarterly peels are labelled by quarter under 'Terminal period' (GS7)", {
  times <- 2000 + (0:7) / 4
  r <- retro_plot_fixture(times)
  p <- plot_retro(r)
  expect_identical(p$labels$colour, "Terminal period")
  expect_identical(retro_color_scale(p)$get_labels(),
                   c("2001 Q4", "2001 Q3", "2001 Q2", "2001 Q1"))
  expect_identical(retro_color_scale(p)$get_labels(),
                   ALSCL:::.acl_time_labels(rev(times[5:8])))
  # Colors remain keyed by the numeric period.
  expect_equal(retro_color_scale(p)$map(c("2001.75", "2001.5")), ggsci::pal_npg()(4)[1:2])
  r$results$NumericalOK[r$results$Peel == 1L] <- FALSE
  expect_match(plot_retro(r)$labels$subtitle, "terminal period 2001 Q3", fixed = TRUE)
})
