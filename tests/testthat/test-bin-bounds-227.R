test_that("explicit finite outer bounds cannot silently become open bins", {
  labels <- c("10", "20", "30")
  lower <- c(-Inf, 15, 25)
  upper <- c(15, 25, Inf)
  finite_lower <- replace(lower, 1L, 0)
  finite_upper <- replace(upper, 3L, 40)
  for (bounds in list(list(len_lower = finite_lower),
                      list(len_upper = finite_upper),
                      list(len_lower = finite_lower, len_upper = finite_upper))) {
    expect_error(do.call(ALSCL:::.acl_length_bins, c(list(labels = labels), bounds)),
      "Finite outer length bounds are not supported.*absorb the distribution tails")
  }
  expect_error(ALSCL:::.acl_length_bins(labels, len_lower = finite_lower),
    "len_lower\\[1\\] = -Inf.*NULL")
  expect_error(ALSCL:::.acl_length_bins(labels, len_upper = finite_upper),
    "len_upper\\[length\\(len_upper\\)\\] = Inf")
})

test_that("open bounds retain defaults and finite labels remain descriptive", {
  labels <- c("0-15", "15-25", "25-40")
  default <- ALSCL:::.acl_length_bins(labels)
  lower <- c(-Inf, 15, 25)
  upper <- c(15, 25, Inf)
  expect_equal(default$mid, c(7.5, 20, 32.5))
  expect_equal(default$lower, lower)
  expect_equal(default$upper, upper)
  for (bounds in list(list(len_lower = lower), list(len_upper = upper),
                      list(len_lower = lower, len_upper = upper),
                      list(len_lower = setNames(lower, letters[1:3]),
                           len_upper = setNames(upper, letters[1:3])))) {
    expect_identical(do.call(ALSCL:::.acl_length_bins,
                            c(list(labels = labels), bounds)), default)
  }
  # Open-ended textual labels, unequal widths and explicit midpoints still work.
  explicit <- ALSCL:::.acl_length_bins(c("<15", "15-25", ">25"),
    len_mid = c(7.5, 20, 32.5), len_lower = lower, len_upper = upper)
  expect_identical(explicit[c("mid", "border", "lower", "upper")],
                   default[c("mid", "border", "lower", "upper")])
  expect_error(ALSCL:::.acl_length_bins(labels, len_lower = c(-Inf, 16, 25)),
    "agree with len_border")
  expect_error(ALSCL:::.acl_length_bins(labels, len_upper = c(15, 24, Inf)),
    "agree with len_border")
  expect_error(ALSCL:::.acl_length_bins(labels, len_lower = c(NA, 15, 25)),
    "Length bounds")
  expect_error(ALSCL:::.acl_length_bins(labels, len_upper = c(15, 25)),
    "Length bounds")
})

test_that("the public ALSCL entry rejects finite truncation before compilation", {
  input <- fixture_frames()
  bins <- do.call(ALSCL:::.acl_prepare_data, input)$bins
  compiled <- FALSE
  local_mocked_bindings(.acl_compile = function(...) {
    compiled <<- TRUE
    stop("Compilation must not be reached")
  }, .package = "ALSCL")
  input$len_lower <- replace(bins$lower, 1L, 0)
  input$len_upper <- bins$upper
  expect_error(run_alscl(input), "Finite outer length bounds are not supported")
  expect_false(compiled)
  input$len_lower <- bins$lower
  input$len_upper <- replace(bins$upper, length(bins$upper), 60)
  expect_error(do.call(run_alscl, input), "Finite outer length bounds are not supported")
  expect_false(compiled)
  # Preparing explicitly open inputs and the unchanged legacy finite labels
  # must produce exactly the same data passed to the model.
  input$len_lower <- bins$lower
  input$len_upper <- bins$upper
  prepared <- do.call(ALSCL:::.acl_prepare_data, input)
  input$len_lower <- input$len_upper <- NULL
  expect_identical(prepared, do.call(ALSCL:::.acl_prepare_data, input))
})
