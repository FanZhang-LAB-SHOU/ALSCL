# Check scripts/checkout_guard.R without fitting models. Run from the repository root:
#   Rscript scripts/test_checkout_guard.R
# The guard must accept the checkout itself and name every kind of difference
# between the loaded package and a source tree: version, functions, templates and data.
local({
  source("scripts/checkout_guard.R", local = TRUE)
  use_checkout_alscl()
  stopifnot(identical(alscl_checkout_differences(), character(0)),
            isTRUE(require_checkout_alscl()))
  # A changed copy of the sources stands in for a checkout that has moved on
  # from the loaded package, which is what a stale installation looks like.
  other <- tempfile("alscl-other-checkout-")
  on.exit(unlink(other, recursive = TRUE), add = TRUE)
  dir.create(file.path(other, "inst"), recursive = TRUE)
  stopifnot(file.copy(c("DESCRIPTION", "R", "data"), other, recursive = TRUE),
            file.copy("inst/extdata", file.path(other, "inst"), recursive = TRUE))
  description <- readLines(file.path(other, "DESCRIPTION"))
  writeLines(sub("^Version: .*", "Version: 0.0.1", description), file.path(other, "DESCRIPTION"))
  cat("\nVB_func <- function(Linf, k, t0, age) Linf\nguard_test_new_function <- function() NULL\n",
      file = file.path(other, "R", "VB_func.R"), append = TRUE)
  cat("\n// changed\n", file = file.path(other, "inst", "extdata", "ACL.cpp"), append = TRUE)
  YTF <- list(changed = TRUE)
  save(YTF, file = file.path(other, "data", "YTF.rda"))
  found <- alscl_checkout_differences(other)
  expected <- c("version: loaded ", "functions absent from the loaded package: guard_test_new_function",
                "functions that differ: VB_func", "template differs: ACL.cpp", "data set differs: YTF")
  for (text in expected) if (!any(startsWith(found, text)))
    stop("The checkout guard did not report: ", text, call. = FALSE)
  stopifnot(length(found) == length(expected))
  error <- tryCatch(require_checkout_alscl(other), error = identity)
  stopifnot(inherits(error, "error"),
            grepl("does not match this checkout", conditionMessage(error), fixed = TRUE))
  cat("PASS: the checkout guard accepts this checkout and reports a changed version, function, template and data set.\n")
})
