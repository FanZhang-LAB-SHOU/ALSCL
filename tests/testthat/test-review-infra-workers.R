review_random_fixture <- function(model) {
  x <- cpp_fixture(model)
  obj <- TMB::MakeADFun(x$data, x$parameters, random = c("dev_log_R", "dev_log_F", "dev_log_N0"),
                        DLL = x$info$dll_name, silent = TRUE)
  obj$fn(obj$par)  # sets last.par.best, as the final evaluation in .acl_fit() does
  obj
}
review_quiet_nan <- function(expr) withCallingHandlers(expr, warning = function(w)
  if (grepl("NaNs produced", conditionMessage(w), fixed = TRUE)) invokeRestart("muffleWarning"))

test_that("alscl_speed_info() explains the backend that fits will use (F63)", {
  reason <- ALSCL:::.acl_sd_reason
  ok <- ALSCL:::.acl_fork_ok
  gui <- ALSCL:::.acl_fork_reason("unix", "RStudio", c("", ""), "")
  expect_identical(reason(2L, "fork", "auto", TRUE, ok), ok)
  expect_identical(reason(2L, "socket", "auto", TRUE, gui), gui)
  # An override that changes the automatic choice is named, without the
  # contradictory "socket workers are used" of the automatic reason.
  forced <- reason(2L, "fork", "fork", TRUE, gui)
  expect_match(forced, "ALSCL.sd_backend = \"fork\"\\) is set, so forked processes are used")
  expect_match(forced, "GUI front-end")
  expect_false(grepl("so socket workers are used", forced, fixed = TRUE))
  socket <- reason(2L, "socket", "socket", TRUE, ok)
  expect_match(socket, "ALSCL.sd_backend = \"socket\"\\) is set, so socket workers are used")
  # An override that agrees with the automatic choice keeps the automatic reason.
  expect_identical(reason(2L, "fork", "fork", TRUE, ok), ok)
  expect_identical(reason(2L, "socket", "socket", TRUE, gui), gui)
  # One core, or a TMB version that was not checked, means no parallel workers.
  expect_match(reason(1L, "socket", "auto", TRUE, gui), "one core")
  expect_match(reason(2L, "fork", "auto", FALSE, ok), "TMB version was not checked")
  withr::with_options(list(ALSCL.sd_cores = 2L, ALSCL.sd_backend = "socket"), {
    info <- alscl_speed_info()
    value <- stats::setNames(info$value, info$item)
    if (ALSCL:::.acl_tmb_supported() && ALSCL:::.acl_cores() > 1L) {
      expect_match(value[["standard errors computed by"]], "socket workers")
      expect_match(value[["reason"]], "socket workers")
      expect_false(grepl("forked processes are safe here", value[["reason"]], fixed = TRUE))
    }
  })
})

test_that("fork safety recognises BLAS libraries that may run OpenMP threads (F64)", {
  safe <- function(blas, threads = rep("", 4))
    ALSCL:::.acl_fork_safe("unix", "X11", c("", ""), blas, threads)
  expect_true(safe("/usr/lib/R/lib/libRblas.so"))
  expect_true(safe("/usr/lib/x86_64-linux-gnu/blas/libblas.so.3.10.0"))
  expect_true(safe("/usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3"))
  expect_true(safe(""))
  for (blas in c("/usr/lib/x86_64-linux-gnu/openblas-openmp/libblas.so.3",
                 "/usr/lib64/libopenblaso.so.0", "/usr/lib64/libflexiblas.so.3",
                 "/opt/intel/mkl/lib/intel64/libmkl_rt.so", "/usr/lib/x86_64-linux-gnu/blis-openmp/libblas.so.3")) {
    expect_false(safe(blas), label = blas)
    expect_match(ALSCL:::.acl_fork_reason("unix", "X11", c("", ""), blas, rep("", 4)),
                 "OpenMP threads.*socket workers are used.*OMP_NUM_THREADS=1")
    # One thread makes forking safe again.
    expect_true(safe(blas, c("1", "", "", "")), label = blas)
    expect_true(safe(blas, c("", "", "1", "")), label = blas)
    expect_false(safe(blas, c("4", "", "", "")), label = blas)
  }
  # Earlier reasons keep their precedence and wording.
  expect_match(ALSCL:::.acl_fork_reason("windows", "Rgui", c("", ""), "libmkl_rt.dll"), "Windows")
  expect_match(ALSCL:::.acl_fork_reason("unix", "X11", c("", ""),
    "/System/Library/Frameworks/Accelerate.framework/libBLAS.dylib"), "Accelerate")
})

test_that("automatic cores stay within the cores given to the job (F64)", {
  allocation <- ALSCL:::.acl_core_allocation
  expect_identical(allocation("", NULL), NA_integer_)
  expect_identical(allocation("2", NULL), 2L)
  expect_identical(allocation("", 3), 3L)
  expect_identical(allocation("8", 2L), 2L)
  expect_identical(allocation("not a number", NULL), NA_integer_)
  expect_identical(allocation("0", -1), NA_integer_)
  cores <- function(allocation, detected) withr::with_envvar(c(`_R_CHECK_LIMIT_CORES_` = ""),
    ALSCL:::.acl_cores("auto", allocation = allocation, detected = detected))
  expect_identical(cores(NA_integer_, 16L), 4L)   # up to four
  expect_identical(cores(NA_integer_, 3L), 2L)    # one detected core stays free
  expect_identical(cores(1L, 64L), 1L)            # srun -c 1 on a large node
  expect_identical(cores(2L, 64L), 2L)
  expect_identical(cores(32L, 64L), 4L)
  expect_identical(cores(8L, 3L), 2L)
  expect_identical(cores(NA_integer_, 1L), 1L)
  # An explicit request is not changed by the allocation.
  expect_identical(withr::with_envvar(c(`_R_CHECK_LIMIT_CORES_` = ""),
    ALSCL:::.acl_cores(3, allocation = 1L, detected = 64L)), 3L)
  withr::with_envvar(c(SLURM_CPUS_PER_TASK = "1"),
    withr::with_options(list(ALSCL.sd_cores = "auto"), expect_identical(ALSCL:::.acl_cores(), 1L)))
  withr::with_options(list(mc.cores = 1L, ALSCL.sd_cores = "auto"),
    expect_identical(ALSCL:::.acl_cores(), 1L))
})

test_that("delta-method socket workers must run the TMB and Matrix of the main process (GI2)", {
  skip_on_cran()
  paths <- ALSCL:::.acl_dependency_paths(paths = "/not/a/library")
  expect_identical(utils::tail(paths, 1L), "/not/a/library")
  tmb_library <- dirname(getNamespaceInfo(asNamespace("TMB"), "path"))
  expect_true(tmb_library %in% paths)
  # Libraries already on the path keep their order.
  expect_identical(ALSCL:::.acl_dependency_paths(paths = .libPaths()), .libPaths())
  versions <- ALSCL:::.acl_dependency_versions()
  expect_identical(versions$TMB, as.character(utils::packageVersion("TMB")))
  expect_named(versions, c("TMB", "Matrix"))

  withr::local_options(list(ALSCL.sd_socket_min_seconds = 0))
  local_mocked_bindings(.acl_dependency_versions = function(...) list(TMB = "0.0.1", Matrix = versions$Matrix),
                        .package = "ALSCL")
  obj <- review_random_fixture("ACL")
  expect_error(review_quiet_nan(ALSCL:::.acl_sdreport(obj, obj$par, ncores = 2L, check_version = FALSE,
    fallback = FALSE, backend = "socket")), "socket worker loaded TMB .* but the main process uses 0.0.1")
  # In a fit the difference gives a warning and sequential standard errors.
  obj <- review_random_fixture("ACL")
  reference <- review_quiet_nan(TMB::sdreport(obj, par.fixed = obj$par, getReportCovariance = FALSE))
  obj <- review_random_fixture("ACL")
  expect_warning(fallback <- review_quiet_nan(ALSCL:::.acl_sdreport(obj, obj$par, ncores = 2L,
    check_version = FALSE, backend = "socket")), "Parallel standard errors failed.*socket worker loaded TMB")
  expect_identical(fallback$sd, reference$sd)
  expect_identical(attr(fallback, "acl_sd_info")$method, "sequential")
})

test_that("batch workers check the TMB version and source checkouts add no library path (GI2, GI3)", {
  skip_on_cran()
  package_path <- normalizePath(getNamespaceInfo(asNamespace("ALSCL"), "path"), winslash = "/")
  source_mode <- !file.exists(file.path(package_path, "Meta", "package.rds"))
  cl <- parallel::makeCluster(1L)
  on.exit(parallel::stopCluster(cl), add = TRUE)
  expect_error(ALSCL:::.acl_initialize_workers(cl, tmb_version = "0.0.1"),
               "Socket worker loaded TMB .* but the main process uses TMB 0.0.1")
  ALSCL:::.acl_initialize_workers(cl)
  worker <- parallel::clusterCall(cl, function() list(
    paths = normalizePath(.libPaths(), winslash = "/"),
    package = normalizePath(getNamespaceInfo(asNamespace("ALSCL"), "path"), winslash = "/"),
    tmb = as.character(utils::packageVersion("TMB"))))[[1]]
  expect_identical(worker$package, package_path)
  expect_identical(worker$tmb, as.character(utils::packageVersion("TMB")))
  parent <- normalizePath(dirname(package_path), winslash = "/")
  # The folder that holds a source checkout is not a library. The library of
  # an installed package still comes first.
  if (source_mode) expect_false(parent %in% worker$paths)
  else expect_identical(worker$paths[1], parent)
})
