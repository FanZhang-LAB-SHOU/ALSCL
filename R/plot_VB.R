#' Plot the Von Bertalanffy growth function
#'
#' This function takes Linf, k, and t0 as input, creates a sequence of ages, applies the VB function to each age, and then plots the result using ggplot2.
#' @param model_result A list that contains model output. The list should have a "report" component which contains "Linf", "vbk" and "t0" components.
#' @param age_range NULL or a finite increasing numeric pair in years. NULL
#'   uses the fitted age range in model_result$age, or c(1, 25) for older fits
#'   without age metadata; the automatic lower endpoint is at least t0. An
#'   explicit range must start at or after t0 to avoid negative-length extrapolation.
#' @param line_size Numeric or NULL. NULL inherits the global line_size setting (default 1.5).
#' @param line_color Character or NULL. NULL inherits the global line_color setting.
#' @param line_type Character. The type of the line in the plot. Default is "solid".
#' @param se_color Character or NULL. NULL inherits the global se_color setting.
#' @param se_alpha Numeric or NULL. NULL inherits the global se_alpha setting (default 0.2).
#' @param se_type Character. Type of CI display: "ribbon" (shaded area) or "errorbar" (error bars). Default is "ribbon".
#' @param se Logical. Whether to calculate and plot standard error as confidence intervals. Default is FALSE.
#' @param text_size Numeric. Size of the growth-parameter annotation in all
#'   display modes. Default is 5.
#' @param text_color Character. Color of the growth-parameter annotation in all
#'   display modes. Default is "black".
#' @param title Character or NULL. Custom plot title. If NULL, uses global theme setting. See \code{acl_theme_set()}.
#' @param xlab Character or NULL. Custom x-axis label. If NULL, uses global theme setting.
#' @param ylab Character or NULL. Custom y-axis label. If NULL, uses global theme setting.
#' @param font_family Character or NULL. Custom font family. If NULL, uses global theme setting (default "sans").
#' @param title_size Numeric or NULL. Plot title size in pt. If NULL, uses global theme (default 14).
#' @param axis_title_size Numeric or NULL. Axis title size in pt. If NULL, uses global theme (default 12).
#' @param axis_text_size Numeric or NULL. Axis tick label size in pt. If NULL, uses global theme (default 10).
#' @param strip_text_size Numeric or NULL. Facet label size in pt. If NULL, uses global theme (default 10).
#' @param legend_text_size Numeric or NULL. Legend text size in pt. If NULL, uses global theme (default 10).
#' @param x_breaks Numeric vector or NULL. Custom x-axis breaks (e.g. \code{seq(1, 20, by = 2)}). NULL = auto.
#' @param base_theme Character or NULL. Base ggplot2 theme name (e.g. "theme_bw"). NULL = global setting.
#' @param title_hjust Numeric or NULL. Title horizontal alignment: 0 = left, 0.5 = center, 1 = right. NULL = global setting.
#' @details If the growth covariance is unavailable or unusable, a request for
#'   confidence intervals warns and draws the estimate only, preserving all
#'   supplied labels, axis settings, text styles and theme options. The parameter
#'   annotation is retained with and without intervals and inherits font_family.
#'   The y-axis inherits the global growth label unless ylab is supplied.
#'   An automatic age range with no positive span at or above t0 is rejected;
#'   supply an explicit biologically meaningful age_range in that case.
#' @return A ggplot object representing the plot.
#' @export
#' @examples
#' \dontrun{
#' plot_VB(model_result, age_range = c(1, 25))
#' }
plot_VB <- function(model_result, age_range = NULL, line_size = NULL, line_color = NULL, line_type = "solid", se = FALSE, se_color = NULL, se_alpha = NULL, se_type = c("ribbon", "errorbar"),text_color="black",text_size=5, title = NULL, xlab = NULL, ylab = NULL, font_family = NULL, title_size = NULL, axis_title_size = NULL, axis_text_size = NULL, strip_text_size = NULL, legend_text_size = NULL, x_breaks = NULL, base_theme = NULL, title_hjust = NULL){
  # NULL 继承全局色板 / NULL inherits the global palette.
  if (is.null(line_size)) line_size <- acl_theme("line_size")
  if (is.null(line_color)) line_color <- acl_theme("line_color")
  if (is.null(se_color)) se_color <- acl_theme("se_color")
  if (is.null(se_alpha)) se_alpha <- acl_theme("se_alpha")

  if (!is.logical(se) || length(se) != 1L || is.na(se))
    stop("se must be TRUE or FALSE.", call. = FALSE)
  se_type <- match.arg(se_type)

  Linf <- model_result$report$Linf
  k <- model_result$report$vbk
  t0 <- model_result$report$t0
  valid_scalar <- function(x) is.numeric(x) && length(x) == 1L && is.finite(x)
  if (!valid_scalar(Linf) || Linf <= 0 || !valid_scalar(k) || k <= 0 || !valid_scalar(t0))
    stop("Growth parameters Linf and vbk must be finite positive scalars, and t0 must be finite.",
         call. = FALSE)

  automatic_range <- is.null(age_range)
  if (automatic_range) {
    fitted_ages <- model_result$age
    if (is.null(fitted_ages)) {
      age_range <- c(1, 25)
    } else {
      if (!is.numeric(fitted_ages) || !length(fitted_ages) || any(!is.finite(fitted_ages)))
        stop("model_result$age must contain finite numeric ages; supply age_range for older fits without usable age metadata.",
             call. = FALSE)
      age_range <- range(fitted_ages)
    }
    age_range[1L] <- max(age_range[1L], t0)
  }
  if (!is.numeric(age_range) || length(age_range) != 2L || any(!is.finite(age_range)) ||
      age_range[2L] <= age_range[1L])
    stop("age_range must be a finite increasing pair with a positive span; supply an explicit range at or above t0.",
         call. = FALSE)
  if (age_range[1L] < t0)
    stop("age_range must start at or after t0; earlier ages extrapolate to negative lengths.",
         call. = FALSE)

  # Include both requested endpoints, including ranges narrower than one grid step.
  ages <- seq(age_range[1L], age_range[2L], by = 0.1)
  if (tail(ages, 1L) < age_range[2L]) ages <- c(ages, age_range[2L])
  data <- data.frame(age = ages, length = Linf * (1 - exp(-k * (ages - t0))))

  # Resolve uncertainty before choosing the layers so that an estimate-only
  # fallback uses the same supplied styling arguments as a direct plain plot.
  interval <- if (se) .acl_growth_interval(model_result, data$age) else NULL
  if (se && is.null(interval)) {
    warning("Growth confidence interval requires a finite full parameter covariance matrix; drawing the estimate only.")
    se <- FALSE
  }

  p <- ggplot2::ggplot(data, ggplot2::aes(x = age, y = length))
  if (se) {
    data$lower <- interval$lower; data$upper <- interval$upper
    p <- ggplot2::ggplot(data, ggplot2::aes(x = age, y = length)) +
      {if (se_type == "ribbon")
        ggplot2::geom_ribbon(ggplot2::aes(ymin = lower, ymax = upper), alpha = se_alpha, fill = se_color)
       else ggplot2::geom_errorbar(ggplot2::aes(ymin = lower, ymax = upper), color = se_color, alpha = se_alpha, width = .1)}
  }
  annotation_font <- if (is.null(font_family)) acl_theme("font_family") else font_family
  p <- p +
    ggplot2::geom_line(linewidth = line_size, color = line_color, linetype = line_type) +
    ggplot2::labs(x = if (is.null(xlab)) .acl_lab("x", "age") else xlab,
                  y = if (is.null(ylab)) .acl_lab("y", "growth") else ylab,
                  title = if (is.null(title)) .acl_title("VB") else title) +
    ggplot2::annotate("text", x = -Inf, y = Inf,
      label = paste("Linf =", round(Linf, 2), "\nk =", round(k, 2)),
      hjust = -0.1, vjust = 1.5, size = text_size, color = text_color,
      family = annotation_font) +
    .acl_scale_x(x_breaks, n_breaks = 10) +
    .acl_base_theme(font_family, title_size, axis_title_size, axis_text_size,
                    strip_text_size, legend_text_size, base_theme = base_theme, title_hjust = title_hjust)

  return(p)
}

# Delta method using the full covariance, including correlations and t0.
.acl_growth_interval <- function(model_result, ages) {
  cov <- model_result$vcov
  if (is.null(cov) || is.null(rownames(cov)) || any(!is.finite(cov)) || identical(model_result$pdHess, FALSE)) return(NULL)
  r <- model_result$report; delta <- ages-r$t0; decay <- exp(-r$vbk*delta)
  mu <- r$Linf*(1-decay)
  jacobian <- cbind(log_Linf = mu, log_vbk = r$Linf*decay*r$vbk*delta,
                    t0 = -r$Linf*r$vbk*decay, log_t0 = -r$Linf*r$vbk*decay*r$t0)
  keys <- intersect(colnames(jacobian), rownames(cov))
  se <- rep(0, length(ages))
  if (length(keys)) {
    g <- jacobian[,keys,drop=FALSE]
    variance <- rowSums((g %*% cov[keys,keys,drop=FALSE])*g)
    if (any(variance < -1e-8)) return(NULL)
    se <- sqrt(pmax(0,variance))
  }
  data.frame(estimate=mu, se=se, lower=pmax(0,mu-1.96*se), upper=mu+1.96*se)
}
