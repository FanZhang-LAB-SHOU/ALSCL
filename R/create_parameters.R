#' Create Parameter Bounds for ACL or ALSCL Models
#'
#' Generate initial values and lower and upper bounds for an ACL or ALSCL
#' fit. Select a built-in species preset and override individual values to
#' match the biological assumptions and units of the assessment.
#'
#' @param model_type Character. Either \code{"acl"} or \code{"alscl"}.
#'   Determines which TMB model parameter names and defaults to use.
#' @param species Character or NULL. Optional species preset:
#'   \code{"flatfish"} (M7 yellowtail flounder-like, annual, Linf=60),
#'   \code{"tuna"} (M6 tuna-like, quarterly, Linf=152), or
#'   \code{"krill"} (Antarctic krill-like, Linf=60-90).
#'   When NULL (default), generic wide-range defaults are used.
#'   Each preset supplies initial values and bounds; inspect these before
#'   fitting a different stock. See Details.
#' @param parameters A list of custom initial values (default NULL = use all defaults).
#'   Only the parameters you specify will be overridden; all others keep their
#'   default (or species-preset) values.
#' @param parameters.L A list of custom lower bounds (default NULL).
#' @param parameters.U A list of custom upper bounds (default NULL).
#' @param bounds Character. \code{"default"} keeps the bounds of earlier
#'   versions. \code{"wide"} gives ACL the bounds that ALSCL has for five
#'   parameters; see Details. It has no effect for \code{model_type = "alscl"}.
#'   Entries of \code{parameters.L} and \code{parameters.U} replace the bounds
#'   of either choice.
#'
#' @return A list with three elements: \code{parameters}, \code{parameters.L},
#'   and \code{parameters.U}. Each is a named list of parameter values with
#'   names matching the corresponding TMB model template.
#'
#' @details
#' \strong{Species presets:}
#'
#' A species preset returns the initial values and bounds listed below.
#' These are starting configurations; convergence depends on the data, model
#' assumptions and optimization, and must be checked for the fitted assessment.
#'
#' \tabular{lllllll}{
#'   \strong{Preset}  \tab \strong{Linf} \tab \strong{vbk} \tab \strong{nage} \tab \strong{M} \tab \strong{growth_step} \tab \strong{Notes} \cr
#'   flatfish \tab 60  \tab 0.2  \tab 15 \tab 0.2 \tab 1    \tab M7 operating model \cr
#'   tuna     \tab 152 \tab 0.38 \tab 20 \tab 0.2 \tab 0.25 \tab M6 operating model, quarterly \cr
#'   krill    \tab 90/60 \tab 0.3 \tab 5/7 \tab 0.3/0 \tab 1 \tab Starting Linf=90 (ACL) or 60 (ALSCL) \cr
#' }
#'
#' The nage, M and growth_step columns describe the source assessment workflows,
#' not arguments changed by this helper. Presets return only parameter starts
#' and bounds; supply biology separately to run_acl() or run_alscl(). The krill
#' ACL start is Linf=90, but Linf remains free unless an explicit
#' map = list(log_Linf = factor(NA)) fixes it. No preset creates a map.
#'
#' \strong{Parameter naming differences between ACL and ALSCL:}
#'
#' \tabular{lll}{
#'   \strong{Concept}            \tab \strong{ACL name}     \tab \strong{ALSCL name} \cr
#'   SD of N0 deviations         \tab log_std_log_N0        \tab log_sigma_log_N0 \cr
#'   SD of R deviations          \tab log_std_log_R         \tab log_sigma_log_R \cr
#'   SD of F deviations          \tab log_std_log_F         \tab log_sigma_log_F \cr
#'   F correlation (age/length)  \tab logit_log_F_a         \tab logit_log_F_l \cr
#'   t0 parameter                \tab t0 (raw scale)        \tab log_t0 (log scale) \cr
#'   Observation error SD        \tab log_std_index         \tab log_sigma_index \cr
#' }
#'
#' ALSCL has one additional parameter: \code{log_cv_grow} (CV of growth
#' increment controlling the transition matrix G variability).
#'
#' \strong{Wide bounds for ACL:}
#'
#' Without a species preset, the default upper bounds of ACL are lower than
#' those of ALSCL for five parameters, and ACL fits to other stocks than the
#' yellowtail flounder example often stop at them. \code{bounds = "wide"}
#' gives ACL the ALSCL bounds of these parameters (natural scale; rates are
#' per model time step, k is per year):
#'
#' \tabular{llll}{
#'   \strong{Parameter} \tab \strong{Quantity} \tab \strong{Default bounds} \tab \strong{Wide bounds} \cr
#'   log_init_Z     \tab initial total mortality rate \tab 0.01 to 1 \tab 0.01 to 10 \cr
#'   mean_log_F     \tab mean fishing mortality rate \tab 0.01 to 1 \tab 0.01 to 2 \cr
#'   log_std_log_N0 \tab standard deviation of the initial numbers at age (log scale) \tab 0 to 1 \tab 0 to 10 \cr
#'   log_std_log_R  \tab standard deviation of recruitment (log scale) \tab 0.01 to 1 \tab 0.01 to 10 \cr
#'   log_vbk        \tab von Bertalanffy growth rate k \tab 0.1 to 1 \tab 0.05 to 2 \cr
#' }
#'
#' With a species preset the ACL and ALSCL bounds of these parameters are
#' equal, so \code{bounds} changes nothing. Starting values are not changed.
#'
#' @examples
#' # Generic ACL defaults (wide bounds, suitable for exploration)
#' p <- create_parameters("acl")
#'
#' # Flatfish preset -- ready to use for M7-like species
#' p <- create_parameters("acl", species = "flatfish")
#'
#' # Tuna preset for ALSCL -- quarterly dynamics
#' p <- create_parameters("alscl", species = "tuna")
#'
#' # Krill ACL preset with custom Linf override
#' p <- create_parameters("acl", species = "krill",
#'   parameters = list(log_Linf = log(85)))
#'
#' # ACL with the bounds of ALSCL for five parameters
#' exp(unlist(create_parameters("acl", bounds = "wide")$parameters.U[
#'   c("log_init_Z", "mean_log_F", "log_std_log_N0", "log_std_log_R", "log_vbk")]))
#'
#' # List available presets
#' create_parameters("acl", species = "?")
#'
#' @export
create_parameters <- function(model_type = c("acl", "alscl"),
                              species      = NULL,
                              parameters   = NULL,
                              parameters.L = NULL,
                              parameters.U = NULL,
                              bounds       = c("default", "wide")) {

  if (is.null(model_type) || is.list(model_type)) {
    legacy <- list(parameters = model_type, lower = species, upper = parameters)
    model_type <- "acl"; species <- NULL
    parameters <- legacy$parameters; parameters.L <- legacy$lower; parameters.U <- legacy$upper
  }
  model_type <- match.arg(model_type)
  bounds <- match.arg(bounds)

  # =========================================================================
  # Backward compatibility: run_acl()/run_alscl() may call
  #   create_parameters("acl", params_list, params_L, params_U)
  # using the OLD positional signature (without species).
  # If species got a list, it's actually the parameters argument.
  # Shift all positional arguments back.
  # =========================================================================
  if (!is.null(species) && is.list(species)) {
    # species actually received 'parameters' (old 2nd positional arg)
    # parameters actually received 'parameters.L' (old 3rd)
    # parameters.L actually received 'parameters.U' (old 4th)
    old_params   <- species
    old_params_L <- parameters
    old_params_U <- parameters.L

    species      <- NULL
    parameters   <- old_params
    parameters.L <- old_params_L
    parameters.U <- old_params_U
  }

  # =========================================================================
  # Species presets -- biologically-calibrated starting values and bounds
  # sourced from actual assessment scripts:
  #   flatfish: A7.R (ACL) + M7 operating model (ALSCL)
  #   tuna:     ALSCL_simulation.R (both ACL & ALSCL)
  #   krill:    ACL_krill.R (ACL) + auto_alscl_2.R (ALSCL)
  # =========================================================================
  if (!is.null(species) && is.character(species)) {

    # Help: list available presets
    if (length(species) == 1 && species == "?") {
      message("Available species presets for create_parameters():\n",
              "  'flatfish' -- M7 yellowtail flounder (annual, Linf=60, nage=15)\n",
              "  'tuna'     -- M6 tuna (quarterly, Linf=152, nage=20)\n",
              "  'krill'    -- Antarctic krill (starting Linf: ACL=90; ALSCL=60; map controls fixes)\n",
              "Use species=NULL for generic wide-range defaults.")
      return(invisible(NULL))
    }

    species <- match.arg(species, c("flatfish", "tuna", "krill"))

    # -----------------------------------------------------------------------
    # FLATFISH (M7) -- annual, age-based, Linf=60, vbk=0.2
    # ACL source: A7.R   |  ALSCL: adapted from A7.R with ALSCL naming
    # -----------------------------------------------------------------------
    if (species == "flatfish") {
      if (model_type == "acl") {
        defaults <- list(
          log_init_Z     = log(0.5),
          log_std_log_N0 = log(0.5),
          mean_log_R     = 5,
          log_std_log_R  = log(0.2),
          logit_log_R    = log(0.75 / 0.25),
          mean_log_F     = log(0.3),
          log_std_log_F  = log(0.8),
          logit_log_F_y  = log(0.75 / 0.25),
          logit_log_F_a  = log(0.75 / 0.25),
          log_vbk        = log(0.2),
          log_Linf       = log(60),
          t0             = 1 / 60,
          log_cv_len     = log(0.3),
          log_std_index  = log(0.1)
        )
        defaults_L <- list(
          log_init_Z     = log(0.01),
          log_std_log_N0 = -Inf,
          mean_log_R     = log(10),
          log_std_log_R  = log(0.01),
          logit_log_R    = -30,
          mean_log_F     = log(0.01),
          log_vbk        = log(0.1),
          log_Linf       = log(10),
          log_cv_len     = log(0.01),
          log_std_index  = -20
        )
        defaults_U <- list(
          log_init_Z     = log(1),
          log_std_log_N0 = log(1),
          mean_log_R     = 10,
          log_std_log_R  = log(1),
          logit_log_R    = 20,
          mean_log_F     = log(1),
          log_vbk        = log(1),
          log_Linf       = log(100),
          log_cv_len     = log(1),
          log_std_index  = log(1)
        )
      } else {
        defaults <- list(
          log_init_Z       = log(0.5),
          log_sigma_log_N0 = log(0.5),
          mean_log_R       = 5,
          log_sigma_log_R  = log(0.2),
          logit_log_R      = log(0.75 / 0.25),
          mean_log_F       = log(0.3),
          log_sigma_log_F  = log(0.8),
          logit_log_F_y    = log(0.75 / 0.25),
          logit_log_F_l    = log(0.75 / 0.25),
          log_vbk          = log(0.2),
          log_Linf         = log(60),
          log_t0           = log(1 / 60),
          log_cv_len       = log(0.3),
          log_cv_grow      = log(0.2),
          log_sigma_index  = log(0.1)
        )
        defaults_L <- list(
          log_init_Z       = log(0.01),
          log_sigma_log_N0 = -Inf,
          mean_log_R       = log(10),
          log_sigma_log_R  = log(0.01),
          logit_log_R      = -30,
          mean_log_F       = log(0.01),
          log_vbk          = log(0.1),
          log_Linf         = log(10),
          log_cv_len       = log(0.01),
          log_cv_grow      = log(0.01),
          log_sigma_index  = -20
        )
        defaults_U <- list(
          log_init_Z       = log(1),
          log_sigma_log_N0 = log(1),
          mean_log_R       = 10,
          log_sigma_log_R  = log(1),
          logit_log_R      = 20,
          mean_log_F       = log(1),
          log_vbk          = log(1),
          log_Linf         = log(100),
          log_cv_len       = log(1),
          log_cv_grow      = log(1),
          log_sigma_index  = log(1)
        )
      }

    # -----------------------------------------------------------------------
    # TUNA (M6) -- quarterly, length-based dynamics, Linf=152, vbk=0.38
    # Source: ALSCL_simulation.R (both operating model & assessment)
    # -----------------------------------------------------------------------
    } else if (species == "tuna") {
      if (model_type == "acl") {
        defaults <- list(
          log_init_Z     = log(1),
          log_std_log_N0 = log(0.5),
          mean_log_R     = 5,
          log_std_log_R  = log(0.3),
          logit_log_R    = log(0.75 / 0.25),
          mean_log_F     = log(0.2),
          log_std_log_F  = log(0.5),
          logit_log_F_y  = log(0.75 / 0.25),
          logit_log_F_a  = log(0.75 / 0.25),
          log_vbk        = log(0.38),
          log_Linf       = log(152),
          t0             = 1 / 152,
          log_cv_len     = log(0.2),
          log_std_index  = log(0.1)
        )
        defaults_L <- list(
          log_init_Z     = log(0.1),
          log_std_log_N0 = log(0.01),
          mean_log_R     = 1,
          log_std_log_R  = log(0.01),
          logit_log_R    = -20,
          mean_log_F     = log(0.0001),
          log_vbk        = log(0.1),
          log_Linf       = log(100),
          log_cv_len     = log(0.01),
          log_std_index  = log(0.01)
        )
        defaults_U <- list(
          log_init_Z     = log(3),
          log_std_log_N0 = log(5),
          mean_log_R     = 10,
          log_std_log_R  = log(1),
          logit_log_R    = 10,
          mean_log_F     = log(1),
          log_vbk        = log(0.5),
          log_Linf       = log(200),
          log_cv_len     = log(1),
          log_std_index  = log(1)
        )
      } else {
        defaults <- list(
          log_init_Z       = log(1),
          log_sigma_log_N0 = log(0.5),
          mean_log_R       = 5,
          log_sigma_log_R  = log(0.3),
          logit_log_R      = log(0.75 / 0.25),
          mean_log_F       = log(0.2),
          log_sigma_log_F  = log(0.5),
          logit_log_F_y    = log(0.75 / 0.25),
          logit_log_F_l    = log(0.75 / 0.25),
          log_vbk          = log(0.38),
          log_Linf         = log(152),
          log_t0           = log(1 / 152),
          log_cv_len       = log(0.2),
          log_cv_grow      = log(0.2),
          log_sigma_index  = log(0.1)
        )
        defaults_L <- list(
          log_init_Z       = log(0.1),
          log_sigma_log_N0 = log(0.01),
          mean_log_R       = 1,
          log_sigma_log_R  = log(0.01),
          logit_log_R      = -20,
          mean_log_F       = log(0.0001),
          log_vbk          = log(0.1),
          log_Linf         = log(100),
          log_cv_len       = log(0.01),
          log_cv_grow      = log(0.01),
          log_sigma_index  = log(0.01)
        )
        defaults_U <- list(
          log_init_Z       = log(3),
          log_sigma_log_N0 = log(5),
          mean_log_R       = 10,
          log_sigma_log_R  = log(1),
          logit_log_R      = 10,
          mean_log_F       = log(1),
          log_vbk          = log(0.5),
          log_Linf         = log(200),
          log_cv_len       = log(1),
          log_cv_grow      = log(1),
          log_sigma_index  = log(1)
        )
      }

    # -----------------------------------------------------------------------
    # KRILL -- ACL: nage=5, M=0.3, Linf=90 (fixed via map)
    #         ALSCL: nage=7, M=0, Linf=60 (estimated, bounds 40-70)
    # ACL source: ACL_krill.R  |  ALSCL source: auto_alscl_2.R
    # -----------------------------------------------------------------------
    } else if (species == "krill") {
      if (model_type == "acl") {
        defaults <- list(
          log_init_Z     = log(0.5),
          log_std_log_N0 = log(1),
          mean_log_R     = 5,
          log_std_log_R  = log(1),
          logit_log_R    = log(0.01 / 0.99),
          mean_log_F     = log(0.3),
          log_std_log_F  = log(1),
          logit_log_F_y  = log(0.75 / 0.25),
          logit_log_F_a  = log(0.75 / 0.25),
          log_vbk        = log(0.3),
          log_Linf       = log(90),       # typically fixed via map for krill
          t0             = 1 / 60,
          log_cv_len     = log(0.3),
          log_std_index  = log(0.1)
        )
        defaults_L <- list(
          log_init_Z     = log(0.01),
          log_std_log_N0 = -Inf,
          mean_log_R     = log(10),
          log_std_log_R  = log(0.01),
          logit_log_R    = -30,
          mean_log_F     = log(0.01),
          log_vbk        = log(0.1),
          log_Linf       = log(50),
          log_cv_len     = log(0.01),
          log_std_index  = log(0.01)
        )
        defaults_U <- list(
          log_init_Z     = log(10),
          log_std_log_N0 = log(10),
          mean_log_R     = 20,
          log_std_log_R  = log(10),
          logit_log_R    = 20,
          mean_log_F     = log(2),
          log_vbk        = log(1),
          log_Linf       = log(100),
          log_cv_len     = log(1),
          log_std_index  = log(1)
        )
      } else {
        defaults <- list(
          log_init_Z       = log(0.5),
          log_sigma_log_N0 = log(1),
          mean_log_R       = 5,
          log_sigma_log_R  = log(1),
          logit_log_R      = log(0.01 / 0.99),
          mean_log_F       = log(0.3),
          log_sigma_log_F  = log(1),
          logit_log_F_y    = log(0.75 / 0.25),
          logit_log_F_l    = log(0.75 / 0.25),
          log_vbk          = log(0.3),
          log_Linf         = log(60),     # estimated (not fixed) for krill ALSCL
          log_t0           = log(1 / 60),
          log_cv_len       = log(0.3),
          log_cv_grow      = log(0.3),
          log_sigma_index  = log(0.1)
        )
        defaults_L <- list(
          log_init_Z       = log(0.01),
          log_sigma_log_N0 = -Inf,
          mean_log_R       = log(10),
          log_sigma_log_R  = log(0.01),
          logit_log_R      = -30,
          mean_log_F       = log(0.01),
          log_vbk          = log(0.1),
          log_Linf         = log(40),     # krill ALSCL: Linf bounds 40-70
          log_cv_len       = log(0.01),
          log_cv_grow      = log(0.01),
          log_sigma_index  = log(0.01)
        )
        defaults_U <- list(
          log_init_Z       = log(10),
          log_sigma_log_N0 = log(10),
          mean_log_R       = 20,
          log_sigma_log_R  = log(10),
          logit_log_R      = 20,
          mean_log_F       = log(2),
          log_vbk          = log(1),
          log_Linf         = log(70),     # krill ALSCL: Linf bounds 40-70
          log_cv_len       = log(1),
          log_cv_grow      = log(1),
          log_sigma_index  = log(1.5)
        )
      }
    }

  # =========================================================================
  # Generic defaults (no species preset) -- wide-range, conservative
  # =========================================================================
  } else {

    if (model_type == "acl") {

      defaults <- list(
        log_init_Z     = log(0.5),
        log_std_log_N0 = log(0.5),
        mean_log_R     = 5,
        log_std_log_R  = log(0.2),
        logit_log_R    = log(0.75 / 0.25),
        mean_log_F     = log(0.3),
        log_std_log_F  = log(0.8),
        logit_log_F_y  = log(0.75 / 0.25),
        logit_log_F_a  = log(0.75 / 0.25),
        log_vbk        = log(0.2),
        log_Linf       = log(60),
        t0             = 1 / 60,
        log_cv_len     = log(0.3),
        log_std_index  = log(0.1)
      )

      defaults_L <- list(
        log_init_Z     = log(0.01),
        log_std_log_N0 = -Inf,
        mean_log_R     = log(10),
        log_std_log_R  = log(0.01),
        logit_log_R    = -30,
        mean_log_F     = log(0.01),
        log_vbk        = log(0.1),
        log_Linf       = log(10),
        log_cv_len     = log(0.01),
        log_std_index  = -20
      )

      defaults_U <- list(
        log_init_Z     = log(1),
        log_std_log_N0 = log(1),
        mean_log_R     = 10,
        log_std_log_R  = log(1),
        logit_log_R    = 20,
        mean_log_F     = log(1),
        log_vbk        = log(1),
        log_Linf       = log(100),
        log_cv_len     = log(1),
        log_std_index  = log(1.5)
      )

    } else {

      defaults <- list(
        log_init_Z       = log(0.5),
        log_sigma_log_N0 = log(1),
        mean_log_R       = 5,
        log_sigma_log_R  = log(1),
        logit_log_R      = log(0.01 / 0.99),
        mean_log_F       = log(0.3),
        log_sigma_log_F  = log(1),
        logit_log_F_y    = log(0.75 / 0.25),
        logit_log_F_l    = log(0.75 / 0.25),
        log_vbk          = log(0.4),
        log_Linf         = log(60),
        log_t0           = log(1 / 60),
        log_cv_len       = log(0.3),
        log_cv_grow      = log(0.3),
        log_sigma_index  = log(0.1)
      )

      defaults_L <- list(
        log_init_Z       = log(0.01),
        log_sigma_log_N0 = -Inf,
        mean_log_R       = log(10),
        log_sigma_log_R  = log(0.01),
        logit_log_R      = -30,
        mean_log_F       = log(0.01),
        log_vbk          = log(0.05),
        log_Linf         = log(20),
        log_cv_len       = log(0.01),
        log_cv_grow      = log(0.01),
        log_sigma_index  = log(0.01)
      )

      defaults_U <- list(
        log_init_Z       = log(10),
        log_sigma_log_N0 = log(10),
        mean_log_R       = 20,
        log_sigma_log_R  = log(10),
        logit_log_R      = 20,
        mean_log_F       = log(2),
        log_vbk          = log(2),
        log_Linf         = log(200),
        log_cv_len       = log(1),
        log_cv_grow      = log(1),
        log_sigma_index  = log(1.5)
      )
    }
  }

  if (is.null(species)) {
    defaults_L$mean_log_R <- -20
    defaults_U$mean_log_R <- 30
  }
  # Bounds exist for every fixed parameter; maps determine which enter nlminb.
  missing_L <- setdiff(names(defaults), names(defaults_L))
  missing_U <- setdiff(names(defaults), names(defaults_U))
  defaults_L[missing_L] <- as.list(rep(-Inf, length(missing_L)))
  defaults_U[missing_U] <- as.list(rep(Inf, length(missing_U)))
  # The bounds of the F standard deviation, the F correlations and t0 are the
  # same for every model and preset and are set here only.
  for (nm in intersect(c("log_std_log_F", "log_sigma_log_F"), names(defaults))) {
    defaults_L[[nm]] <- log(.01); defaults_U[[nm]] <- log(5)
  }
  for (nm in intersect(c("logit_log_F_y", "logit_log_F_a", "logit_log_F_l"), names(defaults))) {
    defaults_L[[nm]] <- -20; defaults_U[[nm]] <- 20
  }
  if ("t0" %in% names(defaults)) {defaults_L$t0 <- -5; defaults_U$t0 <- 5}
  if ("log_t0" %in% names(defaults)) {defaults_L$log_t0 <- -20; defaults_U$log_t0 <- log(5)}
  # bounds = "wide": ACL takes the bounds that ALSCL has for the same request.
  if (bounds == "wide" && model_type == "acl") {
    wide <- .acl_wide_bounds(if (is.character(species)) species else NULL)
    defaults_L[names(wide$lower)] <- wide$lower
    defaults_U[names(wide$upper)] <- wide$upper
  }
  override_lists <- list(parameters = parameters, parameters.L = parameters.L, parameters.U = parameters.U)
  for (list_name in names(override_lists)) {
    overrides <- override_lists[[list_name]]
    if (is.null(overrides)) next
    if (!is.list(overrides) || (length(overrides) && (is.null(names(overrides)) || anyDuplicated(names(overrides)))))
      stop(list_name, " must be a named list with one entry per parameter.", call. = FALSE)
    unknown <- setdiff(names(overrides), names(defaults))
    if (length(unknown)) {
      # The two models name the same quantities differently; point to the equivalent name.
      other <- c(t0 = "log_t0", log_t0 = "t0", log_std_log_N0 = "log_sigma_log_N0",
        log_sigma_log_N0 = "log_std_log_N0", log_std_log_R = "log_sigma_log_R", log_sigma_log_R = "log_std_log_R",
        log_std_log_F = "log_sigma_log_F", log_sigma_log_F = "log_std_log_F", log_std_index = "log_sigma_index",
        log_sigma_index = "log_std_index", logit_log_F_a = "logit_log_F_l", logit_log_F_l = "logit_log_F_a")
      hint <- other[intersect(unknown, names(other))]
      hint <- hint[hint %in% names(defaults)]
      stop(list_name, " has parameter(s) that the ", toupper(model_type), " model does not have: ",
           paste(unknown, collapse = ", "), ". ",
           if (length(hint)) paste0("The ", toupper(model_type), " name is ",
             paste(sprintf("%s (not %s)", hint, names(hint)), collapse = ", "), ". ") else "",
           "Known parameters: ", paste(names(defaults), collapse = ", "), ".", call. = FALSE)
    }
    bad <- names(overrides)[!vapply(overrides, function(x) is.numeric(x) && length(x) == 1L && !is.na(x), logical(1))]
    if (length(bad))
      stop("Each entry of ", list_name, " must be one number; check ", paste(bad, collapse = ", "), ".", call. = FALSE)
  }

  # =========================================================================
  # Merge user overrides (partial updates supported via modifyList)
  # =========================================================================
  params   <- if (!is.null(parameters))   modifyList(defaults,   parameters)   else defaults
  params_L <- if (!is.null(parameters.L)) modifyList(defaults_L, parameters.L) else defaults_L
  params_U <- if (!is.null(parameters.U)) modifyList(defaults_U, parameters.U) else defaults_U

  list(parameters = params, parameters.L = params_L, parameters.U = params_U)
}


#' @rdname create_parameters
#' @usage create_parameters_alscl(species, parameters, parameters.L, parameters.U)
#' @details \code{create_parameters_alscl()} is a convenience wrapper that calls
#'   \code{create_parameters("alscl", ...)}.
#' @export
create_parameters_alscl <- function(species      = NULL,
                                    parameters   = NULL,
                                    parameters.L = NULL,
                                    parameters.U = NULL) {
  create_parameters("alscl", species, parameters, parameters.L, parameters.U)
}
