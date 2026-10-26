utils::globalVariables(c("Biomass", "AgeGroup", "LengthGroup", "Count", "SBA"))
#' @title Plot Biomass Over Years from ACL or ALSCL Model
#'
#' @description Plots biomass over years. Supports total biomass ("B"),
#' biomass at length ("BL"), and biomass at age ("BA").
#'
#' @param model_result A list from \code{run_acl} or \code{run_alscl}.
#' @param line_size Numeric. Line thickness. Default is 1.2.
#' @param line_color Character or NULL. NULL inherits the global line_color setting.
#' @param line_type Character. Line type. Default is "solid".
#' @param se Logical. Whether to plot confidence intervals. Default is FALSE.
#' @param se_color Character or NULL. NULL inherits the global se_color setting.
#' @param se_alpha Numeric. CI ribbon transparency. Default is 0.2.
#' @param type Character. "B" (total), "BL" (at length), or "BA" (at age). Default is "B".
#' @param facet_ncol Integer. Columns in facet_wrap. Default is NULL.
#' @param facet_scales Character. Scales for facet_wrap. Default is "free".
#' @param return_data Logical. Whether to return processed data. Default is FALSE.
#'
#' @details ALSCL reports B, BL and BA with standard errors. ACL reports B with
#'   standard errors and BL estimates only; BA is unavailable. A missing quantity
#'   or requested standard error produces an explicit error. With \code{se = TRUE},
#'   intervals are the estimate plus or minus 1.96 standard errors on the reported
#'   scale. They are not truncated at zero. Inspect fit diagnostics before using
#'   uncertainty intervals.
#'
#' @return A ggplot object or a list with plot and data.
#' @export
plot_biomass <- function(model_result, line_size = 1.2, line_color = NULL, line_type = "solid",
                         se = FALSE, se_color = NULL, se_alpha = 0.2,
                         type = c("B", "BL", "BA"), facet_ncol = NULL, facet_scales = "free",
                         return_data = FALSE) {
  # NULL 继承全局色板 / NULL inherits the global palette.
  if (is.null(line_color)) line_color <- acl_theme("line_color")
  if (is.null(se_color)) se_color <- acl_theme("se_color")


  type <- match.arg(type)
  quantity <- .acl_plot_population_data(model_result, type, c("B", "BL", "BA"), se)
  len_label <- model_result[["len_label"]]
  Year <- model_result[["year"]]
  current_theme <- tryCatch(get("acl_get_theme", envir = asNamespace("ALSCL"))(), error = function(e) ggplot2::theme_minimal())

  # ==========================
  # Type = "B": Total biomass
  # ==========================
  if (type == "B") {
    biomass <- quantity$value
    if (!is.data.frame(biomass)) biomass <- as.data.frame(biomass)
    biomass$Year <- Year

    if (!se) {
      p <- ggplot2::ggplot(biomass, ggplot2::aes(x = Year, y = biomass)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::labs(x = "Year", y = "Relative biomass", title = "Total Biomass Over Years") +
        current_theme
      data_out <- biomass
    } else {
      # Use exact match ^B$ to avoid matching BA, BL, BLA
      ss_bio <- quantity$se
      ci <- data.frame(
        Year     = Year,
        estimate = ss_bio[, "Estimate"],
        lower    = ss_bio[, "Estimate"] - 1.96 * ss_bio[, "Std. Error"],
        upper    = ss_bio[, "Estimate"] + 1.96 * ss_bio[, "Std. Error"]
      )
      p <- ggplot2::ggplot(ci, ggplot2::aes(x = Year, y = estimate)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha) +
        ggplot2::labs(y = "Relative biomass", x = "Year", title = "Total Biomass Over Years") +
        current_theme
      data_out <- ci
    }
  }

  # ==========================
  # Type = "BL": Biomass at length
  # ==========================
  if (type == "BL") {
    BL <- quantity$value
    if (!is.matrix(BL)) BL <- as.matrix(BL)

    LengthLabels <- .acl_fix_len_labels(len_label)

    BL_long <- reshape2::melt(BL)
    colnames(BL_long) <- c("LengthGroup", "Year", "Count")
    BL_long$Year <- Year[as.numeric(BL_long$Year)]
    BL_long$LengthGroup <- factor(LengthLabels[as.numeric(BL_long$LengthGroup)],
                                  levels = LengthLabels)

    if (!se) {
      p <- ggplot2::ggplot(BL_long, ggplot2::aes(x = Year, y = Count)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type)
      data_out <- BL_long
    } else {
      ss_bl <- quantity$se
      ci <- data.frame(
        LengthGroup = BL_long$LengthGroup,
        Year = BL_long$Year,
        estimate = ss_bl[, "Estimate"],
        lower = ss_bl[, "Estimate"] - 1.96 * ss_bl[, "Std. Error"],
        upper = ss_bl[, "Estimate"] + 1.96 * ss_bl[, "Std. Error"]
      )
      p <- ggplot2::ggplot(ci, ggplot2::aes(x = Year, y = estimate)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha)
      data_out <- ci
    }
    p <- p + ggplot2::facet_wrap(~LengthGroup, ncol = facet_ncol, scales = facet_scales) +
      ggplot2::labs(x = "Year", y = "Relative biomass", title = "Biomass at Length Over Years") +
      current_theme
  }

  # ==========================
  # Type = "BA": Biomass at age
  # ==========================
  if (type == "BA") {
    BA <- quantity$value
    if (!is.matrix(BA)) BA <- as.matrix(BA)

    AgeLabels <- factor(paste("Age bin", seq_len(nrow(BA))),
                        levels = paste("Age bin", seq_len(nrow(BA))))

    BA_long <- reshape2::melt(BA)
    colnames(BA_long) <- c("AgeGroup", "Year", "Biomass")
    BA_long$Year <- Year[as.numeric(BA_long$Year)]
    BA_long$AgeGroup <- AgeLabels[as.numeric(BA_long$AgeGroup)]

    if (!se) {
      p <- ggplot2::ggplot(BA_long, ggplot2::aes(x = Year, y = Biomass)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::facet_wrap(~AgeGroup, ncol = facet_ncol, scales = facet_scales) +
        ggplot2::labs(x = "Year", y = "Relative biomass", title = "Biomass at Age Over Years") +
        current_theme
      data_out <- BA_long
    } else {
      ss_ba <- quantity$se
      ss_ba <- as.data.frame(ss_ba)
      ci <- data.frame(
        AgeGroup = rep(levels(AgeLabels), times = ncol(BA)),
        Year     = rep(Year, each = nrow(BA)),
        estimate = ss_ba[, "Estimate"],
        lower    = ss_ba[, "Estimate"] - 1.96 * ss_ba[, "Std. Error"],
        upper    = ss_ba[, "Estimate"] + 1.96 * ss_ba[, "Std. Error"]
      )
      p <- ggplot2::ggplot(ci, ggplot2::aes(x = Year, y = estimate)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha) +
        ggplot2::facet_wrap(~AgeGroup, ncol = facet_ncol, scales = facet_scales) +
        ggplot2::labs(x = "Year", y = "Relative biomass", title = "Biomass at Age Over Years") +
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
