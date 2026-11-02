style_fixture_229 <- function() {
  years <- 2000:2003
  values <- matrix(seq_len(12L) + 10, 3L, 4L)
  report <- list(N = colSums(values), "NA" = values, NL = values,
    B = colSums(values * 2), BA = values * 2, BL = values * 2,
    SSB = colSums(values / 2), SBA = values / 2, SBL = values / 2,
    CN = colSums(values / 4), CNA = values / 4, CNL = values / 4,
    Rec = values[1L, ], F = values / 100,
    Elog_index = log(values * rep(c(.9, 1, 1.1), 4)),
    resid_index = -log(matrix(rep(c(.9, 1, 1.1), 4), 3, 4)),
    Linf = 70, vbk = .2, t0 = -.1)
  blocks <- lapply(report, function(x)
    cbind(Estimate = as.numeric(x), "Std. Error" = rep(.01, length(x))))
  errors <- do.call(rbind, blocks)
  rownames(errors) <- rep(names(blocks), vapply(blocks, nrow, integer(1)))
  covariance <- diag(c(.01, .02, .005))
  dimnames(covariance) <- list(c("log_Linf", "log_vbk", "t0"),
                              c("log_Linf", "log_vbk", "t0"))
  list(model_type = "ACL", report = report, year = years, age = 1:3,
       len_mid = c(10, 20, 30), len_label = c("10", "20", "30"),
       observations = values, est_std = errors, vcov = covariance, pdHess = TRUE,
       opt = list(par = c(a = 1, b = 2), objective = 10))
}

style_data_229 <- function(model) {
  d <- data.frame(LengthBin = model$len_label, model$observations,
                  check.names = FALSE)
  names(d)[-1L] <- as.character(model$year)
  d
}

style_panels_229 <- function(p) {
  panels <- if (length(p$layers)) list(p) else list()
  if (inherits(p, "patchwork"))
    for (child in p$patches$plots) panels <- c(panels, style_panels_229(child))
  panels
}

test_that("single-model widths and uncertainty alpha inherit global defaults", {
  old <- options(acl.theme = NULL); on.exit(options(old))
  m <- style_fixture_229()
  specs <- list(
    list(fun = plot_abundance, types = c("N", "NA", "NL")),
    list(fun = plot_biomass, types = c("B", "BA", "BL")),
    list(fun = plot_SSB, types = c("SSB", "SBA", "SBL")),
    list(fun = plot_catch, types = c("CN", "CNA", "CNL")),
    list(fun = plot_recruitment), list(fun = plot_VB),
    list(fun = plot_fishing_mortality, types = c("year", "age")))
  check <- function(p, width, alpha) {
    built <- ggplot2::ggplot_build(p)
    line <- which(vapply(p$layers, function(x) inherits(x$geom, "GeomLine"), logical(1)))
    ribbon <- which(vapply(p$layers, function(x) inherits(x$geom, "GeomRibbon"), logical(1)))
    expect_length(line, 1L)
    expect_length(ribbon, 1L)
    expect_true(all(built$data[[line]]$linewidth == width))
    expect_true(all(built$data[[ribbon]]$alpha == alpha))
  }
  for (spec in specs) {
    types <- if (is.null(spec$types)) list(NULL) else as.list(spec$types)
    for (type in types) {
      args <- list(model_result = m, se = TRUE)
      if (!is.null(type)) args$type <- type
      check(do.call(spec$fun, args), 1.5, .2)
      acl_theme_set(line_size = 4, se_alpha = .7)
      check(do.call(spec$fun, args), 4, .7)
      check(do.call(spec$fun, c(args, list(line_size = .8, se_alpha = .3))), .8, .3)
      acl_theme_reset()
    }
  }
  acl_theme_set(line_size = 4)
  p <- plot_residuals(m)
  built <- ggplot2::ggplot_build(p)
  for (i in seq_along(p$layers))
    if (inherits(p$layers[[i]]$geom, c("GeomLine", "GeomHline")))
      expect_true(all(built$data[[i]]$linewidth == 4))
  rd <- expand.grid(Year = 2000:2002, RetrospectiveYear = c("2003", "2002"),
                    Variable = "SSB")
  rd$Value <- seq_len(nrow(rd))
  retro <- list(results = rd, last_points = rd[rd$Year == 2002, ],
                rho_text = data.frame(Variable = "SSB", Rho = .01))
  for (width in c(4, .6)) {
    p <- if (width == 4) plot_retro(retro) else plot_retro(retro, line_size = width)
    built <- ggplot2::ggplot_build(p)
    i <- which(vapply(p$layers, function(x) inherits(x$geom, "GeomLine"), logical(1)))
    expect_true(all(built$data[[i]]$linewidth == width))
  }
})

test_that("comparison line types reach data layers and displayed legends", {
  old <- options(acl.theme = NULL); on.exit(options(old))
  m <- style_fixture_229(); d <- style_data_229(m)
  grDevices::pdf(tempfile(fileext = ".pdf")); on.exit(grDevices::dev.off(), add = TRUE)
  acl_theme_set(compare_linetypes = c("dotted", "longdash"))
  for (explicit in c(FALSE, TRUE)) {
    wanted <- if (explicit) c("twodash", "dotdash") else c("dotted", "longdash")
    extra <- if (explicit) list(linetypes = wanted) else list()
    p <- do.call(plot_compare_CatL, c(list(m, m, d,
      model1_name = "First", model2_name = "Second"), extra))
    built <- ggplot2::ggplot_build(p)
    expect_setequal(unique(built$data[[2L]]$linetype), wanted)
    expect_no_warning(ggplot2::ggplotGrob(p))
    override <- p$guides$guides$colour$params$override.aes
    expect_equal(override$linetype, c(wanted, "blank"))
    expect_equal(override$shape, c(NA, NA, 16))
    p <- do.call(plot_compare_residuals, c(list(m, m, d,
      model1_name = "First", model2_name = "Second"), extra))
    panels <- style_panels_229(p)
    panels <- panels[vapply(panels, function(x)
      x$labels$title %in% c("QQ plot", "Mean residual by year"), logical(1))]
    expect_length(panels, 2L)
    for (panel in panels) {
      layer <- ggplot2::ggplot_build(panel)$data[[2L]]
      expect_setequal(unique(layer$linetype), wanted)
    }
    expect_no_warning(grob <- patchwork::patchworkGrob(p))
    expect_equal(sum(grob$layout$name == "guide-box"), 1L)
  }
})

test_that("comparison outer titles and facets inherit global typography", {
  old <- options(acl.theme = NULL); on.exit(options(old))
  grDevices::pdf(tempfile(fileext = ".pdf")); on.exit(grDevices::dev.off(), add = TRUE)
  m <- style_fixture_229(); d <- style_data_229(m)
  acl_theme_set(title_size = 32, title_hjust = 1, font_family = "mono", strip_text_size = 24)
  for (fun in list(plot_compare_residuals, plot_compare_metrics)) {
    p <- fun(m, m, d)
    grob <- patchwork::patchworkGrob(p)
    title <- grob$grobs[[which(grob$layout$name == "title")]]$children[[1L]]
    expect_equal(title$gp$fontsize, 32)
    expect_equal(title$gp$fontfamily, "mono")
    expect_equal(title$hjust, 1)
    for (pos in c("top", "none")) {
      q <- fun(m, m, d, legend_pos = pos)
      g <- patchwork::patchworkGrob(q)
      expect_equal(sum(g$layout$name == "guide-box"), if (pos == "none") 0L else 1L)
    }
  }
  p <- plot_compare_F(m, m)
  th <- ggplot2::ggplot_build(p)$plot$theme
  expect_equal(ggplot2::calc_element("strip.text", th)$size, 24)
})
