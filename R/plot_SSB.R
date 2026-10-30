utils::globalVariables(c("LengthGroup", "Count"))
#' @title Plot Spawning Stock Biomass (SSB), SBL, or SBA Over Years
#'
#' @description Plots SSB, spawning biomass at length (SBL), or spawning biomass
#' at age (SBA) from ACL or ALSCL model results.
#'
#' @param model_result A list from \code{run_acl} or \code{run_alscl}.
#' @param line_size Numeric. Line thickness. Default is 1.2.
#' @param line_color Character or NULL. NULL inherits the global line_color setting.
#' @param line_type Character. Line type. Default is "solid".
#' @param se Logical. Whether to plot confidence intervals. Default is FALSE.
#' @param se_color Character or NULL. NULL inherits the global se_color setting.
#' @param se_alpha Numeric. CI ribbon transparency. Default is 0.2.
#' @param type Character. "SSB" (total), "SBL" (at length), or "SBA" (at age). Default is "SSB".
#' @param facet_ncol Numeric. Columns in facet wrap. Default is NULL.
#' @param facet_scales Character. Scales for facet wrap. Default is "free".
#' @param return_data Logical. Whether to return processed data. Default is FALSE.
#'
#' @details ALSCL reports SSB, SBL and SBA with standard errors. ACL reports SSB
#'   with standard errors and SBL estimates only; SBA is unavailable. A missing
#'   quantity or requested standard error produces an explicit error. With
#'   \code{se = TRUE}, intervals are the estimate plus or minus 1.96 standard errors
#'   on the reported scale. They are not truncated at zero. Inspect fit
#'   diagnostics before using uncertainty intervals.
#'
#' @return A ggplot object or a list with plot and data.
#' @export
plot_SSB <- function(model_result, line_size = 1.2, line_color = NULL, line_type = "solid",
                     se = FALSE, se_color = NULL, se_alpha = 0.2,
                     type = c("SSB", "SBL", "SBA"), facet_ncol = NULL, facet_scales = "free",
                     return_data = FALSE) {
  # NULL 继承全局色板 / NULL inherits the global palette.
  if (is.null(line_color)) line_color <- acl_theme("line_color")
  if (is.null(se_color)) se_color <- acl_theme("se_color")


  type <- match.arg(type)
  quantity <- .acl_plot_population_data(model_result, type, c("SSB", "SBL", "SBA"), se)
  len_label <- model_result[["len_label"]]
  Year <- model_result[["year"]]
  current_theme <- .acl_plot_theme()

  # ==========================
  # Type = "SSB": Total SSB
  # ==========================
  if (type == "SSB") {
    SSB <- quantity$value
    if (!is.data.frame(SSB)) SSB <- as.data.frame(SSB)
    SSB$Year <- Year

    if (!se) {
      p <- ggplot2::ggplot(SSB, ggplot2::aes(x = Year, y = SSB)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::labs(x = "Year", y = "Relative biomass", title = "SSB Over Years") +
        current_theme
      data_out <- SSB
    } else {
      ss_ssb <- quantity$se
      ci <- data.frame(
        Year     = Year,
        estimate = ss_ssb[, "Estimate"],
        lower    = ss_ssb[, "Estimate"] - 1.96 * ss_ssb[, "Std. Error"],
        upper    = ss_ssb[, "Estimate"] + 1.96 * ss_ssb[, "Std. Error"]
      )
      p <- ggplot2::ggplot(ci, ggplot2::aes(x = Year, y = estimate)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha) +
        ggplot2::labs(y = "Relative biomass", x = "Year", title = "SSB Over Years") +
        current_theme
      data_out <- ci
    }
  }

  # ==========================
  # Type = "SBL": SSB at length
  # ==========================
  if (type == "SBL") {
    SBL <- quantity$value
    if (!is.matrix(SBL)) SBL <- as.matrix(SBL)

    LengthLabels <- .acl_fix_len_labels(len_label)

    SBL_long <- reshape2::melt(SBL)
    colnames(SBL_long) <- c("LengthGroup", "Year", "Count")
    SBL_long$Year <- Year[as.numeric(SBL_long$Year)]
    SBL_long$LengthGroup <- factor(LengthLabels[as.numeric(SBL_long$LengthGroup)],
                                   levels = LengthLabels)

    if (!se) {
      p <- ggplot2::ggplot(SBL_long, ggplot2::aes(x = Year, y = Count)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type)
      data_out <- SBL_long
    } else {
      ss_sbl <- quantity$se
      ci <- data.frame(
        LengthGroup = SBL_long$LengthGroup,
        Year = SBL_long$Year,
        estimate = ss_sbl[, "Estimate"],
        lower = ss_sbl[, "Estimate"] - 1.96 * ss_sbl[, "Std. Error"],
        upper = ss_sbl[, "Estimate"] + 1.96 * ss_sbl[, "Std. Error"]
      )
      p <- ggplot2::ggplot(ci, ggplot2::aes(x = Year, y = estimate)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha)
      data_out <- ci
    }
    p <- p + ggplot2::facet_wrap(~LengthGroup, ncol = facet_ncol, scales = facet_scales) +
      ggplot2::labs(x = "Year", y = "Relative biomass", title = "Spawning Biomass at Length Over Years") +
      current_theme
  }

  # ==========================
  # Type = "SBA": SSB at age
  # ==========================
  if (type == "SBA") {
    SBA <- quantity$value
    if (!is.matrix(SBA)) SBA <- as.matrix(SBA)

    AgeLabels <- factor(paste("Age bin", seq_len(nrow(SBA))),
                        levels = paste("Age bin", seq_len(nrow(SBA))))

    SBA_long <- reshape2::melt(SBA)
    colnames(SBA_long) <- c("AgeGroup", "Year", "SBA")
    SBA_long$Year <- Year[as.numeric(SBA_long$Year)]
    SBA_long$AgeGroup <- AgeLabels[as.numeric(SBA_long$AgeGroup)]

    if (!se) {
      p <- ggplot2::ggplot(SBA_long, ggplot2::aes(x = Year, y = SBA)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::facet_wrap(~AgeGroup, ncol = facet_ncol, scales = facet_scales) +
        ggplot2::labs(x = "Year", y = "Relative biomass", title = "Spawning Biomass at Age Over Years") +
        current_theme
      data_out <- SBA_long
    } else {
      ss_sba <- quantity$se
      ss_sba <- as.data.frame(ss_sba)
      ci <- data.frame(
        AgeGroup = rep(AgeLabels, times = ncol(SBA)),
        Year     = rep(Year, each = nrow(SBA)),
        estimate = ss_sba[, "Estimate"],
        lower    = ss_sba[, "Estimate"] - 1.96 * ss_sba[, "Std. Error"],
        upper    = ss_sba[, "Estimate"] + 1.96 * ss_sba[, "Std. Error"]
      )
      p <- ggplot2::ggplot(ci, ggplot2::aes(x = Year, y = estimate)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha) +
        ggplot2::facet_wrap(~AgeGroup, ncol = facet_ncol, scales = facet_scales) +
        ggplot2::labs(x = "Year", y = "Relative biomass", title = "Spawning Biomass at Age Over Years") +
        current_theme
      data_out <- ci
    }
  }

  if (return_data) {
    return(list(plot = p, data = data_out))
  } else {
    return(p)
  }
}
