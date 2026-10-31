utils::globalVariables(c("AgeGroup", "LengthGroup", "CNL", "CNA"))
#' Plot Catch Number (CN), Catch by Age (CNA), or Catch by Length (CNL) Over Years
#'
#' Visualizes catch data from ACL or ALSCL model outputs.
#' Supports total catch ("CN"), catch at age ("CNA"), and catch at length ("CNL").
#'
#' @param model_result A list from \code{run_acl} or \code{run_alscl}.
#' @param line_size Numeric or NULL. NULL inherits the global line_size setting (default 1.5).
#' @param line_color Character or NULL. NULL inherits the global line_color setting.
#' @param line_type Character. Line type. Default is "solid".
#' @param se Logical. Whether to plot confidence intervals. Default is FALSE.
#' @param se_color Character or NULL. NULL inherits the global se_color setting.
#' @param se_alpha Numeric or NULL. NULL inherits the global se_alpha setting (default 0.2).
#' @param facet_ncol Numeric. Columns in facet wrap. Default is NULL.
#' @param facet_scales Character. Scales for facet wrap. Default is "free".
#' @param type Character. "CN" (total), "CNA" (at age), or "CNL" (at length). Default is "CN".
#' @param return_data Logical. Whether to return processed data. Default is FALSE.
#'
#' @details ALSCL reports CN, CNA and CNL with standard errors. ACL reports CN
#'   with standard errors and CNA estimates only; CNL is unavailable. A missing
#'   quantity or requested standard error produces an explicit error. With
#'   \code{se = TRUE}, intervals are the estimate plus or minus 1.96 standard errors
#'   on the reported scale. They are not truncated at zero. Inspect fit
#'   diagnostics before using uncertainty intervals.
#'
#' @details Titles, axis labels, time-axis breaks and expansion inherit
#'   \code{acl_theme_set()}. Title keys are CN, CNA and CNL;
#'   append \code{_se} for interval plots.
#'   Axis labels use \code{xlab$year} and \code{ylab$catch}.
#'
#' @return A ggplot object or a list with plot and data.
#' @export
plot_catch <- function(model_result, line_size = NULL, line_color = NULL, line_type = "solid",
                       se = FALSE, se_color = NULL, se_alpha = NULL,
                       facet_ncol = NULL, facet_scales = "free",
                       type = c("CN", "CNA", "CNL"), return_data = FALSE) {
  # NULL 继承全局色板 / NULL inherits the global palette.
  if (is.null(line_size)) line_size <- acl_theme("line_size")
  if (is.null(line_color)) line_color <- acl_theme("line_color")
  if (is.null(se_color)) se_color <- acl_theme("se_color")
  if (is.null(se_alpha)) se_alpha <- acl_theme("se_alpha")


  type <- match.arg(type)
  quantity <- .acl_plot_population_data(model_result, type, c("CN", "CNA", "CNL"), se)
  Year <- model_result[["year"]]
  len_label <- model_result[["len_label"]]
  current_theme <- .acl_plot_theme()

  # ==========================
  # Type = "CN": Total catch
  # ==========================
  if (type == "CN") {
    CN <- quantity$value
    if (!is.data.frame(CN)) CN <- as.data.frame(CN)
    CN$Year <- Year

    if (!se) {
      p <- ggplot2::ggplot(CN, ggplot2::aes(x = Year, y = CN)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type)
      data_out <- CN
    } else {
      # Use exact match ^CN$ to avoid matching CNA, CNL
      ss_CN <- quantity$se
      ci <- data.frame(
        Year     = Year,
        estimate = ss_CN[, "Estimate"],
        lower    = ss_CN[, "Estimate"] - 1.96 * ss_CN[, "Std. Error"],
        upper    = ss_CN[, "Estimate"] + 1.96 * ss_CN[, "Std. Error"]
      )
      p <- ggplot2::ggplot(ci, ggplot2::aes(x = Year, y = estimate)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha)
      data_out <- ci
    }
  }

  # ==========================
  # Type = "CNA": Catch at age
  # ==========================
  if (type == "CNA") {
    CNA <- quantity$value

    AgeLabels <- factor(paste("Age bin", seq_len(nrow(CNA))),
                        levels = paste("Age bin", seq_len(nrow(CNA))))

    CNA_long <- reshape2::melt(CNA)
    colnames(CNA_long) <- c("AgeGroup", "Year", "CNA")
    CNA_long$Year <- Year[as.numeric(CNA_long$Year)]
    CNA_long$AgeGroup <- AgeLabels[as.numeric(CNA_long$AgeGroup)]

    if (!se) {
      p <- ggplot2::ggplot(CNA_long, ggplot2::aes(x = Year, y = CNA)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::facet_wrap(~AgeGroup, ncol = facet_ncol, scales = facet_scales)
      data_out <- CNA_long
    } else {
      ss_cna <- quantity$se
      ss_cna <- as.data.frame(ss_cna)
      ci <- data.frame(
        AgeGroup = rep(AgeLabels, times = ncol(CNA)),
        Year     = rep(Year, each = nrow(CNA)),
        estimate = ss_cna[, "Estimate"],
        lower    = ss_cna[, "Estimate"] - 1.96 * ss_cna[, "Std. Error"],
        upper    = ss_cna[, "Estimate"] + 1.96 * ss_cna[, "Std. Error"]
      )
      p <- ggplot2::ggplot(ci, ggplot2::aes(x = Year, y = estimate)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha) +
        ggplot2::facet_wrap(~AgeGroup, ncol = facet_ncol, scales = facet_scales)
      data_out <- ci
    }
  }

  # ==========================
  # Type = "CNL": Catch at length
  # ==========================
  if (type == "CNL") {
    CNL <- quantity$value
    if (!is.matrix(CNL)) CNL <- as.matrix(CNL)

    LengthLabels <- .acl_fix_len_labels(len_label)

    CNL_long <- reshape2::melt(CNL)
    colnames(CNL_long) <- c("LengthGroup", "Year", "CNL")
    CNL_long$Year <- Year[as.numeric(CNL_long$Year)]
    CNL_long$LengthGroup <- factor(LengthLabels[as.numeric(CNL_long$LengthGroup)],
                                   levels = LengthLabels)

    if (!se) {
      p <- ggplot2::ggplot(CNL_long, ggplot2::aes(x = Year, y = CNL)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::facet_wrap(~LengthGroup, ncol = facet_ncol, scales = facet_scales)
      data_out <- CNL_long
    } else {
      ss_cnl <- quantity$se
      ss_cnl <- as.data.frame(ss_cnl)
      ci <- data.frame(
        LengthGroup = factor(rep(LengthLabels, times = ncol(CNL)), levels = LengthLabels),
        Year        = rep(Year, each = nrow(CNL)),
        estimate    = ss_cnl[, "Estimate"],
        lower       = ss_cnl[, "Estimate"] - 1.96 * ss_cnl[, "Std. Error"],
        upper       = ss_cnl[, "Estimate"] + 1.96 * ss_cnl[, "Std. Error"]
      )
      p <- ggplot2::ggplot(ci, ggplot2::aes(x = Year, y = estimate)) +
        ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
        ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha) +
        ggplot2::facet_wrap(~LengthGroup, ncol = facet_ncol, scales = facet_scales)
      data_out <- ci
    }
  }

  title_key <- if (se) paste0(type, "_se") else type
  p <- p + ggplot2::labs(x = .acl_lab("x", "year"),
                         y = .acl_lab("y", "catch"), title = .acl_title(title_key)) +
    .acl_scale_x(n_breaks = 5) + current_theme

  if (return_data) {
    return(list(plot = p, data = data_out))
  } else {
    return(p)
  }
}
