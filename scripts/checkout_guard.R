# Make the maintainer scripts use the ALSCL code of this checkout.
#
# Committed figures and tables must come from the code in the repository. A
# comparison of version numbers cannot guarantee that: an installation built
# from an earlier commit has the same version number as the checkout until the
# version is next changed.
#
#   source("scripts/checkout_guard.R")
#   use_checkout_alscl()       # attach the checkout (pkgload), or check the installation
#   require_checkout_alscl()   # check the namespace that is already loaded
#
# Run from the repository root.

# Differences between the loaded ALSCL namespace and the source files of the
# checkout: functions, TMB templates, bundled data and the version number.
# Returns character(0) when they agree.
alscl_checkout_differences <- function(root = ".") {
  if (!file.exists(file.path(root, "DESCRIPTION")) || !dir.exists(file.path(root, "R")))
    stop("Run this script from the root of the ALSCL repository.", call. = FALSE)
  ns <- asNamespace("ALSCL")
  differences <- character()
  checkout_version <- read.dcf(file.path(root, "DESCRIPTION"), "Version")[[1L]]
  loaded_version <- as.character(utils::packageVersion("ALSCL"))
  if (!identical(loaded_version, checkout_version))
    differences <- c(differences, sprintf("version: loaded %s, checkout %s",
                                          loaded_version, checkout_version))
  # Functions assigned at the top level of the R files, compared without source references.
  same_function <- function(loaded, expr) {
    if (!is.function(loaded)) return(FALSE)
    checkout <- eval(expr, baseenv())
    loaded <- utils::removeSource(loaded)
    identical(as.list(formals(loaded)), as.list(formals(checkout))) &&
      identical(body(loaded), body(checkout))
  }
  changed <- missing <- character()
  for (path in list.files(file.path(root, "R"), "[.][Rr]$", full.names = TRUE)) {
    for (expr in parse(path, keep.source = FALSE)) {
      if (!(is.call(expr) && is.symbol(expr[[1L]]) &&
            as.character(expr[[1L]]) %in% c("<-", "=") && is.symbol(expr[[2L]]) &&
            is.call(expr[[3L]]) && identical(expr[[3L]][[1L]], as.name("function")))) next
      name <- as.character(expr[[2L]])
      if (!exists(name, envir = ns, inherits = FALSE)) missing <- c(missing, name)
      else if (!same_function(get(name, envir = ns, inherits = FALSE), expr[[3L]]))
        changed <- c(changed, name)
    }
  }
  if (length(missing))
    differences <- c(differences, paste("functions absent from the loaded package:",
                                        paste(sort(unique(missing)), collapse = ", ")))
  if (length(changed))
    differences <- c(differences, paste("functions that differ:",
                                        paste(sort(unique(changed)), collapse = ", ")))
  # TMB templates and headers.
  templates <- list.files(file.path(root, "inst", "extdata"), full.names = TRUE)
  for (path in templates) {
    installed <- system.file("extdata", basename(path), package = "ALSCL")
    if (!nzchar(installed) ||
        !identical(unname(tools::md5sum(installed)), unname(tools::md5sum(path))))
      differences <- c(differences, paste("template differs:", basename(path)))
  }
  # Bundled data sets.
  for (path in list.files(file.path(root, "data"), "[.]rda$", full.names = TRUE)) {
    env <- new.env(parent = emptyenv())
    for (name in load(path, envir = env)) {
      loaded <- tryCatch(getExportedValue("ALSCL", name), error = function(e) NULL)
      if (!identical(loaded, env[[name]]))
        differences <- c(differences, paste("data set differs:", name))
    }
  }
  differences
}

# Stop unless the loaded ALSCL namespace has the code of this checkout.
require_checkout_alscl <- function(root = ".") {
  if (!"ALSCL" %in% loadedNamespaces())
    stop("ALSCL is not loaded; call use_checkout_alscl() first.", call. = FALSE)
  differences <- alscl_checkout_differences(root)
  if (length(differences))
    stop("The loaded ALSCL package (", getNamespaceInfo("ALSCL", "path"),
         ") does not match this checkout:\n  ", paste(differences, collapse = "\n  "),
         "\nInstall the checkout (R CMD INSTALL .) or load it with pkgload::load_all() ",
         "before regenerating committed figures or tables.", call. = FALSE)
  invisible(TRUE)
}

# Attach ALSCL with the code of this checkout. When no ALSCL namespace is loaded
# and pkgload is installed, the checkout is loaded directly and no installation
# is needed. Otherwise the installed or already loaded package is used after
# require_checkout_alscl() has confirmed that it matches the checkout.
# installed = TRUE always uses the installed package (for example for timings).
use_checkout_alscl <- function(root = ".", installed = FALSE) {
  if (!installed && !"ALSCL" %in% loadedNamespaces() &&
      requireNamespace("pkgload", quietly = TRUE)) {
    suppressMessages(pkgload::load_all(root, export_all = FALSE, helpers = FALSE,
                                       attach_testthat = FALSE, quiet = TRUE))
  } else {
    suppressPackageStartupMessages(library(ALSCL))
  }
  require_checkout_alscl(root)
}
