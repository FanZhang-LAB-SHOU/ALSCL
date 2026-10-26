#' @title Plot Fishing Mortality from ACL or ALSCL Model
#'
#' @description This function takes the output from \code{run_acl} or \code{run_alscl}
#' and plots fishing mortality over years, ages, or length-bin midpoints using ggplot2.
#' For ACL models, F is at the age level (A x Y).
#' For ALSCL models, F is at the length level (FL: L x Y) and
#' F-at-age (FA: (A-1) x (Y-1)) is an emergent property.
#'
#' @param model_result A list obtained from \code{run_acl} or \code{run_alscl}.
#' @param line_size Numeric. The thickness of the line. Default is 1.
#' @param line_color Character or NULL. NULL inherits the global line_color setting.
#' @param line_type Character. The type of the line. Default is "solid".
#' @param se Logical. Whether to plot confidence intervals. Default is FALSE.
#' @param se_color Character or NULL. NULL inherits the global se_color setting.
#' @param se_alpha Numeric. The transparency of the ribbon. Default is 0.2.
#' @param se_type Character. "ribbon" or "errorbar". Default is "ribbon".
#' @param facet_ncol Integer. The number of columns in facet_wrap.
#' @param facet_scales Character. Scales for facet_wrap. Default is "free".
#' @param type Character. "year" (faceted by group), "age" (faceted by year),
#'   or "length" (ALSCL: faceted by year showing F vs numeric length-bin
#'   midpoints in \code{model_result$len_mid}; ACL: legacy alias for "age", with
#'   a warning). Default is "year".
#' @param return_data Logical. Whether to return data alongside the plot. Default is FALSE.
#' @param x_breaks Numeric vector. Custom x-axis breaks.
#' @param title Character. Custom plot title.
#' @param xlab Character. Custom x-axis label.
#' @param ylab Character. Custom y-axis label.
#' @param font_family Character. Font family for text elements.
#' @param title_size Numeric. Title text size.
#' @param base_theme A ggplot2 theme object.
#'
#' @return A ggplot object, or a list with plot and data if return_data = TRUE.
#'
#' @export
plot_fishing_mortality <- function(model_result, line_size = 1, line_color = NULL, line_type = "solid", facet_ncol = NULL,
                                   facet_scales = "free", se = FALSE, se_color = NULL, se_alpha = 0.2, se_type = "ribbon",
                                   type = c("year", "age", "length"), return_data = FALSE,
                                   x_breaks = NULL, title = NULL, xlab = NULL, ylab = NULL,
                                   font_family = NULL, title_size = NULL, base_theme = NULL) {
  # NULL 继承全局色板 / NULL inherits the global palette.
  if (is.null(line_color)) line_color <- acl_theme("line_color")
  if (is.null(se_color)) se_color <- acl_theme("se_color")


  type <- match.arg(type)
  se_type <- match.arg(se_type, c("ribbon", "errorbar"))

  # Detect model type: ACL has report$F, ALSCL has report$FL
  is_alscl <- is.null(model_result[["report"]][["F"]]) && !is.null(model_result[["report"]][["FL"]])
  if (!is_alscl && type == "length") {
    warning("ACL has no length-specific F; type = 'length' is a legacy alias for 'age'.",
            call. = FALSE)
    type <- "age"
  }

  Year <- model_result[["year"]]

  # Get theme
  current_theme <- if (!is.null(base_theme)) {
    base_theme
  } else {
    .acl_plot_theme()
  }

  # ===================================================================
  # ALSCL model: FL (L x Y) and FA ((A-1) x (Y-1))
  # ===================================================================
  if (is_alscl) {

    if (type == "year" || type == "length") {
      # --- F at length, faceted by length bin or year ---
      FL <- model_result[["report"]][["FL"]]
      if (!is.matrix(FL) || ncol(FL) != length(Year)) {
        stop("report$FL must be a length-by-time matrix with one column per year value.")
      }
      len_label <- model_result[["len_label"]]
      if (is.null(len_label)) len_label <- paste0("L", seq_len(nrow(FL)))
      if (length(len_label) != nrow(FL)) stop("len_label must match the rows of report$FL.")

      if (type == "length") {
        len_mid <- model_result[["len_mid"]]
        if (!is.numeric(len_mid) || length(len_mid) != nrow(FL) || any(!is.finite(len_mid))) {
          stop("type = 'length' requires finite numeric len_mid values matching the rows of report$FL.")
        }
      }

      GroupLabels <- .acl_fix_len_labels(len_label, prefix = "Length")
      GroupLabels <- factor(GroupLabels, levels = GroupLabels)

      FL_long <- reshape2::melt(FL)
      colnames(FL_long) <- c("Group", "YearIdx", "F")
      FL_long$Year <- Year[FL_long$YearIdx]
      if (type == "length") FL_long$Length <- len_mid[FL_long$Group]
      FL_long$Group <- GroupLabels[FL_long$Group]

      default_title <- if (type == "length") "Fishing Mortality at Length (ALSCL)" else "Fishing Mortality at Length Over Years (ALSCL)"
      default_xlab <- if (type == "length") "Length" else "Year"
      default_ylab <- "Fishing Mortality"
      facet_by <- if (type == "length") ~Year else ~Group

      if (!se) {
        mapping <- if (type == "length") ggplot2::aes(x = Length, y = F) else ggplot2::aes(x = Year, y = F)
        p <- ggplot2::ggplot(FL_long, mapping) +
          ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
          ggplot2::facet_wrap(facet_by, ncol = facet_ncol, scales = facet_scales)
        data_out <- FL_long
      } else {
        est_std <- model_result[["est_std"]]
        rows <- which(rownames(est_std) == "FL")
        if (length(rows) != length(FL) || !all(c("Estimate", "Std. Error") %in% colnames(est_std))) {
          stop("se = TRUE requires one FL estimate and standard error for every length-by-time cell in est_std.")
        }
        ss_fl <- est_std[rows, , drop = FALSE]
        ss_fl <- as.data.frame(ss_fl)

        ci <- data.frame(
          Group    = rep(GroupLabels, times = ncol(FL)),
          Year     = rep(Year, each = nrow(FL)),
          estimate = ss_fl[, "Estimate"],
          lower    = ss_fl[, "Estimate"] - 1.96 * ss_fl[, "Std. Error"],
          upper    = ss_fl[, "Estimate"] + 1.96 * ss_fl[, "Std. Error"]
        )
        if (type == "length") ci$Length <- rep(len_mid, times = ncol(FL))

        mapping <- if (type == "length") ggplot2::aes(x = Length, y = estimate) else ggplot2::aes(x = Year, y = estimate)
        p <- ggplot2::ggplot(ci, mapping) +
          ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type)

        if (se_type == "ribbon") {
          p <- p + ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha)
        } else {
          p <- p + ggplot2::geom_errorbar(ggplot2::aes(ymin = lower, ymax = upper), color = se_color, alpha = se_alpha, width = 0.3)
        }
        p <- p + ggplot2::facet_wrap(facet_by, ncol = facet_ncol, scales = facet_scales)
        data_out <- ci
      }

    } else if (type == "age") {
      # --- Emergent F at age (FA), faceted by year ---
      FA <- model_result[["report"]][["FA"]]
      fa_years <- Year[1:(length(Year) - 1)]

      FA_long <- reshape2::melt(FA)
      colnames(FA_long) <- c("AgeGroup", "YearIdx", "F")
      FA_long$Year <- fa_years[FA_long$YearIdx]

      default_title <- "Emergent F-at-Age (ALSCL)"
      default_xlab <- "Age Group"
      default_ylab <- "Fishing Mortality"

      if (!se) {
        p <- ggplot2::ggplot(FA_long, ggplot2::aes(x = AgeGroup, y = F)) +
          ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
          ggplot2::facet_wrap(~Year, ncol = facet_ncol, scales = facet_scales)
        data_out <- FA_long
      } else {
        ss_fa <- model_result[["est_std"]][grep("^FA$", rownames(model_result[["est_std"]])), ]
        ss_fa <- as.data.frame(ss_fa)

        ci <- data.frame(
          AgeGroup = rep(seq_len(nrow(FA)), times = ncol(FA)),
          Year     = rep(fa_years, each = nrow(FA)),
          estimate = ss_fa[, "Estimate"],
          lower    = ss_fa[, "Estimate"] - 1.96 * ss_fa[, "Std. Error"],
          upper    = ss_fa[, "Estimate"] + 1.96 * ss_fa[, "Std. Error"]
        )
        ci$AgeGroup <- as.numeric(ci$AgeGroup)

        p <- ggplot2::ggplot(ci, ggplot2::aes(x = AgeGroup, y = estimate)) +
          ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type)

        if (se_type == "ribbon") {
          p <- p + ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha)
        } else {
          p <- p + ggplot2::geom_errorbar(ggplot2::aes(ymin = lower, ymax = upper), color = se_color, alpha = se_alpha, width = 0.3)
        }
        p <- p + ggplot2::facet_wrap(~Year, ncol = facet_ncol, scales = facet_scales)
        data_out <- ci
      }
    }

  # ===================================================================
  # ACL model: F (A x Y)
  # ===================================================================
  } else {

    Fmat <- model_result[["report"]][["F"]]

    if (type == "year") {
      AgeGroup <- factor(paste("Age bin", seq_len(nrow(Fmat))), levels = paste("Age bin", seq_len(nrow(Fmat))))

      F_long <- reshape2::melt(Fmat)
      colnames(F_long) <- c("AgeGroup", "Year", "F")
      F_long$Year <- Year[as.numeric(F_long$Year)]
      F_long$AgeGroup <- AgeGroup[as.numeric(F_long$AgeGroup)]

      default_title <- "Fishing Mortality Over Years"
      default_xlab <- "Year"
      default_ylab <- "Fishing Mortality"

      if (!se) {
        p <- ggplot2::ggplot(F_long, ggplot2::aes(x = Year, y = F)) +
          ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
          ggplot2::facet_wrap(~AgeGroup, ncol = facet_ncol, scales = facet_scales)
        data_out <- F_long
      } else {
        ss_f <- model_result[["est_std"]][grep("^F$", rownames(model_result[["est_std"]])), ]
        ss_f <- as.data.frame(ss_f)

        ci <- data.frame(
          AgeGroup = rep(paste0("Age group ", seq_len(nrow(Fmat))), times = ncol(Fmat)),
          Year     = rep(Year, each = nrow(Fmat)),
          estimate = ss_f[, "Estimate"],
          lower    = ss_f[, "Estimate"] - 1.96 * ss_f[, "Std. Error"],
          upper    = ss_f[, "Estimate"] + 1.96 * ss_f[, "Std. Error"]
        )

        p <- ggplot2::ggplot(ci, ggplot2::aes(x = Year, y = estimate)) +
          ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type)

        if (se_type == "ribbon") {
          p <- p + ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha)
        } else {
          p <- p + ggplot2::geom_errorbar(ggplot2::aes(ymin = lower, ymax = upper), color = se_color, alpha = se_alpha, width = 0.3)
        }
        p <- p + ggplot2::facet_wrap(~AgeGroup, ncol = facet_ncol, scales = facet_scales)
        data_out <- ci
      }

    } else {
      # type == "age" for ACL: faceted by year
      F_long <- reshape2::melt(Fmat)
      colnames(F_long) <- c("AgeGroup", "Year", "F")
      F_long$Year <- Year[as.numeric(F_long$Year)]

      default_title <- "Fishing Mortality Over Age Groups"
      default_xlab <- "Age Group"
      default_ylab <- "Fishing Mortality"

      if (!se) {
        p <- ggplot2::ggplot(F_long, ggplot2::aes(x = AgeGroup, y = F)) +
          ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
          ggplot2::facet_wrap(~Year, ncol = facet_ncol, scales = facet_scales)
        data_out <- F_long
      } else {
        ss_f <- model_result[["est_std"]][grep("^F$", rownames(model_result[["est_std"]])), ]
        ss_f <- as.data.frame(ss_f)

        ci <- data.frame(
          AgeGroup = rep(seq_len(nrow(Fmat)), times = ncol(Fmat)),
          Year     = rep(Year, each = nrow(Fmat)),
          estimate = ss_f[, "Estimate"],
          lower    = ss_f[, "Estimate"] - 1.96 * ss_f[, "Std. Error"],
          upper    = ss_f[, "Estimate"] + 1.96 * ss_f[, "Std. Error"]
        )
        ci$AgeGroup <- as.numeric(ci$AgeGroup)

        p <- ggplot2::ggplot(ci, ggplot2::aes(x = AgeGroup, y = estimate)) +
          ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type)

        if (se_type == "ribbon") {
          p <- p + ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), fill = se_color, alpha = se_alpha)
        } else {
          p <- p + ggplot2::geom_errorbar(ggplot2::aes(ymin = lower, ymax = upper), color = se_color, alpha = se_alpha, width = 0.3)
        }
        p <- p + ggplot2::facet_wrap(~Year, ncol = facet_ncol, scales = facet_scales)
        data_out <- ci
      }
    }
  }

  # ===== Apply labels and theme =====
  p <- p +
    ggplot2::labs(
      title = if (!is.null(title)) title else default_title,
      x     = if (!is.null(xlab)) xlab else default_xlab,
      y     = if (!is.null(ylab)) ylab else default_ylab
    ) +
    current_theme

  if (!is.null(x_breaks)) {
    p <- p + ggplot2::scale_x_continuous(breaks = x_breaks)
  }

  if (!is.null(font_family) || !is.null(title_size)) {
    theme_args <- list()
    if (!is.null(font_family)) theme_args$text <- ggplot2::element_text(family = font_family)
    if (!is.null(title_size))  theme_args$plot.title <- ggplot2::element_text(size = title_size)
    p <- p + do.call(ggplot2::theme, theme_args)
  }

  if (return_data) {
    return(list(plot = p, data = data_out))
  } else {
    return(p)
  }
}
