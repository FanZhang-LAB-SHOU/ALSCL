test_that("simulation_to_tables() gives the tables that the fitting functions take (F57)", {
  directory <- tempfile("review-tables-")
  on.exit(unlink(directory, recursive = TRUE), add = TRUE)
  p <- initialize_params(nyear = 3, burn_in = 1, nage = 4)
  capture.output(sm <- sim_data(sim_cal(p), p, iter_range = 1, output_dir = directory))
  convert <- ALSCL:::simulation_to_tables
  tables <- convert(sm, p)
  expect_identical(tables, ALSCL:::.acl_simulation_to_tables(sm, p))
  expect_identical(convert(sm), tables)
  expect_named(tables, c("data.CatL", "data.wgt", "data.mat"))
  expect_identical(names(tables$data.CatL), c("LengthBin", as.character(sm$years)))
  expect_equal(unname(as.matrix(tables$data.CatL[-1])), unname(t(sm$SN_at_len)))
  expect_identical(names(convert(sm, first_year = 1990)$data.CatL)[2], "1990")
  wrong <- p; wrong$len_mid <- wrong$len_mid + 1
  expect_error(convert(sm, wrong), "len_mid must match")
  expect_error(convert(1), "must be lists")
})
