# Extracted from test-plot-review.R:219

# prequel ----------------------------------------------------------------------
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

# test -------------------------------------------------------------------------
acl <- fit_fixture("ACL")$result
alscl <- fit_fixture("ALSCL")$result
expect_identical(eval(formals(plot_compare_ts)$quantities), c("SSB", "R", "B", "N", "CN"))
labels <- c("Spawning biomass", "Recruitment", "Total biomass",
              "Total abundance", "Catch numbers")
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
