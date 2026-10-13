test_that("a single remaining delta quantity is computed without starting a worker", {
  local_mocked_bindings(.acl_delta_one = function(i, s) s$phi[i]^2)
  local_mocked_bindings(makePSOCKcluster = function(...) stop("unnecessary worker"),
                       .package = "parallel")
  result <- .acl_delta_socket(list(), list(phi = 3), ncores = 2L, min_seconds = 0)
  expect_identical(result$variances, list(9))
  expect_identical(result$method, "sequential")
  expect_identical(result$cores, 1L)
})
