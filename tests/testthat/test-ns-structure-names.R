# Names of the structure sets ("original" and "von_bertalanffy"), their earlier
# names ("published" and "consistent"), and the message for a structure that
# changes only some of the four settings of the set "von_bertalanffy".

# A small ALSCL or ACL input with one free parameter, so a fit takes well
# under a second.
names_fit_args <- function(model = "ALSCL", ..., silent = FALSE) {
  f <- fixture_frames()
  f$data.CatL[[1]] <- as.character(seq(15, 55, 5)); f$data.wgt[[1]] <- f$data.mat[[1]] <- f$data.CatL[[1]]
  p <- create_parameters(model_type = tolower(model))$parameters
  prefix <- if (model == "ACL") "log_std_" else "log_sigma_"
  p[[paste0(prefix, "index")]] <- log(.2); p[[paste0(prefix, "log_N0")]] <- log(.1)
  p[[paste0(prefix, "log_R")]] <- log(.1)
  p$log_Linf <- log(60); p$log_vbk <- log(.4)
  mapping <- lapply(p, function(x) factor(NA)); mapping$mean_log_R <- NULL
  c(f, list(parameters = p, map = mapping, silent = silent), list(...))
}
names_count <- function(messages, pattern) sum(grepl(pattern, messages, fixed = TRUE))
names_note <- "These four settings were tested as a set, structure = \"von_bertalanffy\""
names_fit_messages <- function(structure, model = "ALSCL", ...) {
  args <- names_fit_args(model, structure = structure, ...)
  testthat::capture_messages(do.call(if (model == "ACL") run_acl else run_alscl, args))
}

test_that("the sets are named original and von_bertalanffy", {
  expect_identical(names(ALSCL:::.acl_structure_sets), c("original", "von_bertalanffy"))
  expect_identical(ALSCL:::.acl_structure_set_aliases, c(published = "original", consistent = "von_bertalanffy"))
  expect_identical(ALSCL:::.acl_structure_sets$original, list())
  expect_setequal(names(ALSCL:::.acl_structure_sets$von_bertalanffy),
                  c("initial_plus_group", "initial_length", "growth_increment", "growth_transition"))
  N <- ALSCL:::.acl_structure_set_name
  expect_identical(vapply(c("original", "von_bertalanffy", "published", "consistent"), N, character(1), USE.NAMES = FALSE),
                   c("original", "von_bertalanffy", "original", "von_bertalanffy"))
  expect_true(all(is.na(c(N("best"), N(NA_character_), N(c("original", "published")), N(1), N(NULL)))))
  # An unknown name is reported with the current names only.
  expect_error(ALSCL:::.acl_structure("best", "ALSCL"),
    paste0("A character structure must be \"original\" or \"von_bertalanffy\" (the name of a set); use a named list ",
           "for single settings, for example list(correlation_range = \"symmetric\")."), fixed = TRUE)
  expect_error(ALSCL:::.acl_structure(list(set = "Original"), "ALSCL"),
               "structure$set must be \"original\" or \"von_bertalanffy\"", fixed = TRUE)
  expect_error(ALSCL:::.acl_structure(list("original"), "ALSCL"),
    "structure must be \"original\", \"von_bertalanffy\" or a named list", fixed = TRUE)
  # The growth check names the set by its current name.
  expect_no_match(paste(deparse(body(ALSCL:::.acl_growth_check)), collapse = " "), "consistent|published")
})

test_that("the earlier set names give the same settings, prepared inputs and model setup", {
  pairs <- list(c("published", "original"), c("consistent", "von_bertalanffy"))
  f <- fixture_frames()
  for (pair in pairs) for (model in c("ALSCL", "ACL")) {
    old <- pair[1L]; new <- pair[2L]
    expect_identical(ALSCL:::.acl_structure(old, model), ALSCL:::.acl_structure(new, model))
    expect_identical(ALSCL:::.acl_structure_expand(old, model), ALSCL:::.acl_structure_expand(new, model))
    # A list that names the set, with and without further settings.
    expect_identical(ALSCL:::.acl_structure(list(set = old), model), ALSCL:::.acl_structure(new, model))
    expect_identical(ALSCL:::.acl_structure(list(set = old, correlation_range = "symmetric"), model),
                     ALSCL:::.acl_structure(list(set = new, correlation_range = "symmetric"), model))
    expect_identical(ALSCL:::.acl_scale_settings(list(structure = list(set = old, correlation_range = "symmetric"))),
                     ALSCL:::.acl_scale_settings(list(structure = list(set = new, correlation_range = "symmetric"))))
    # The prepared input stores the argument as given; everything else is the same.
    prepared_old <- do.call(ALSCL:::.acl_prepare_data, c(f, list(structure = old)))
    prepared_new <- do.call(ALSCL:::.acl_prepare_data, c(f, list(structure = new)))
    expect_identical(prepared_old$structure, old)
    expect_identical(prepared_old[names(prepared_old) != "structure"], prepared_new[names(prepared_new) != "structure"])
    # Data, starting values, bounds, maps and settings passed to the template.
    expect_identical(ALSCL:::.acl_model_setup(model, prepared_old), ALSCL:::.acl_model_setup(model, prepared_new))
  }
  expect_identical(ALSCL:::.acl_structure(list(set = "consistent", growth_transition = "midpoint"), "ALSCL"),
                   ALSCL:::.acl_structure(list(set = "von_bertalanffy", growth_transition = "midpoint"), "ALSCL"))
  expect_identical(ALSCL:::.acl_structure(list(set = "published", growth_transition = "bin"), "ALSCL"),
                   ALSCL:::.acl_structure(list(set = "original", growth_transition = "bin"), "ALSCL"))
  # "published" is the default structure and "consistent" passes the four settings.
  expect_length(ALSCL:::.acl_structure("published", "ALSCL")$data, 0L)
  expect_identical(ALSCL:::.acl_structure("consistent", "ALSCL")$data,
    list(initial_plus_group = 1L, initial_length = 1L, growth_increment = 1L, growth_transition = 1L))
  # The operating model reads the earlier names as well.
  params <- initialize_params(species = "tuna", nyear = 30, burn_in = 20)
  by_name <- lapply(c("published", "original", "consistent", "von_bertalanffy"), function(name) {
    params$structure <- name
    sim_cal(params)
  })
  expect_identical(by_name[[1L]], by_name[[2L]])
  expect_identical(by_name[[3L]], by_name[[4L]])
  expect_false(identical(by_name[[1L]], by_name[[3L]]))
})

test_that("fits with the earlier set names are the fits with the current names, without a message", {
  skip_on_cran()
  keep <- c("report", "est_std", "vcov", "gradient", "structure", "par_low_up", "growth_check", "diagnostics")
  for (model in c("ALSCL", "ACL")) {
    fit_fun <- if (model == "ACL") run_acl else run_alscl
    for (pair in list(c("published", "original"), c("consistent", "von_bertalanffy"))) {
      old_messages <- testthat::capture_messages(old <- do.call(fit_fun, names_fit_args(model, structure = pair[1L])))
      new_messages <- testthat::capture_messages(new <- do.call(fit_fun, names_fit_args(model, structure = pair[2L])))
      expect_identical(old$opt$par, new$opt$par)
      expect_identical(old$opt$objective, new$opt$objective)
      expect_identical(old[keep], new[keep])
      # The fit stores setting values; the recipe keeps the argument as given.
      expect_false(any(c("published", "consistent", "original") %in% unlist(old$structure)))
      expect_identical(old$recipe$args$structure, pair[1L])
      # No message about the name, and no message on a part of the set.
      expect_identical(length(old_messages), length(new_messages))
      expect_identical(names_count(old_messages, pair[1L]), 0L)
      expect_identical(names_count(old_messages, "earlier"), 0L)
      expect_identical(names_count(old_messages, names_note), 0L)
    }
  }
  # The default fit is the fit with structure = "original".
  default <- do.call(run_alscl, names_fit_args("ALSCL", silent = TRUE))
  named <- do.call(run_alscl, names_fit_args("ALSCL", structure = "original", silent = TRUE))
  expect_identical(default[keep], named[keep])
  full <- do.call(run_alscl, names_fit_args("ALSCL", structure = "consistent", silent = TRUE))
  expect_identical(full$structure[c("initial_plus_group", "initial_length", "growth_increment", "growth_transition")],
    list(initial_plus_group = "equilibrium", initial_length = "growth",
         growth_increment = "von_bertalanffy", growth_transition = "bin"))
})

test_that("a structure is recognised as a part of the von_bertalanffy set", {
  P <- ALSCL:::.acl_partial_set
  four <- c("initial_plus_group", "initial_length", "growth_increment", "growth_transition")
  full <- list(initial_plus_group = "equilibrium", initial_length = "growth",
               growth_increment = "von_bertalanffy", growth_transition = "bin")
  # None or all four of the settings changed.
  for (structure in list(list(), NULL, "original", "published", "von_bertalanffy", "consistent", full, rev(full),
                         list(correlation_range = "symmetric"), c(full, list(correlation_range = "symmetric")),
                         list(set = "von_bertalanffy", correlation_range = "symmetric"),
                         list(growth_increment = "logistic", growth_transition = "midpoint")))
    expect_identical(P(structure), character())
  # One, two or three changed: the settings that keep their original values, in a fixed order.
  expect_identical(P(list(growth_increment = "von_bertalanffy")), four[c(1, 2, 4)])
  expect_identical(P(list(growth_transition = "bin", growth_increment = "von_bertalanffy")), four[1:2])
  expect_identical(P(full[c(4, 1, 2)]), "growth_increment")
  expect_identical(P(list(initial_plus_group = "equilibrium", correlation_range = "symmetric")), four[2:4])
  for (i in 1:14) {
    changed <- as.logical(bitwAnd(i, c(1L, 2L, 4L, 8L)))
    expect_identical(P(full[changed]), four[!changed])
  }
  # A setting written with its original value is not a change.
  expect_identical(P(c(full[1:3], list(growth_transition = "midpoint"))), "growth_transition")
  expect_identical(P(list(set = "original", growth_increment = "von_bertalanffy")), four[c(1, 2, 4)])
  expect_identical(P(list(set = "published", growth_transition = "bin")), four[1:3])
  # A list that names the set and replaces single settings is a deliberate choice.
  expect_identical(P(list(set = "von_bertalanffy", growth_transition = "midpoint")), character())
  expect_identical(P(list(set = "consistent", initial_length = "length_at_age", growth_increment = "logistic")),
                   character())
  # ACL has one of the four settings, and an invalid structure is left to the fit.
  expect_identical(P(list(initial_plus_group = "equilibrium"), "ACL"), character())
  expect_identical(P(list(initial_plus_group = "equilibrium"), "acl"), character())
  expect_identical(P(list(growth_increment = "von_bertalanffy"), "alscl"), four[c(1, 2, 4)])
  expect_identical(P(list(growth = "vb")), character())
  expect_identical(P("best"), character())
  expect_identical(ALSCL:::.acl_word_list(four[1]), four[1])
  expect_identical(ALSCL:::.acl_word_list(four[1:2]), "initial_plus_group and initial_length")
  expect_identical(ALSCL:::.acl_word_list(four[1:3]), "initial_plus_group, initial_length and growth_increment")
})

test_that("an ALSCL fit with a part of the von_bertalanffy set gives one message that names the settings left", {
  skip_on_cran()
  one <- names_fit_messages(list(growth_increment = "von_bertalanffy"))
  expect_identical(names_count(one, names_note), 1L)
  expect_identical(names_count(one, paste0("The structure changes growth_increment and leaves initial_plus_group, ",
    "initial_length and growth_transition at their original values.")), 1L)
  expect_identical(names_count(one, "can fail when the growth increment in one time step is small"), 1L)
  expect_identical(names_count(one, paste0("The value growth_increment = \"von_bertalanffy\" is one setting of the set ",
    "and does not select the other three.")), 1L)
  expect_identical(names_count(one, "See ?run_alscl."), 1L)
  # The note comes before the fit starts.
  expect_lt(which(grepl(names_note, one, fixed = TRUE)), which(grepl("Fitting ALSCL with", one, fixed = TRUE)))
  three <- names_fit_messages(list(initial_plus_group = "equilibrium", initial_length = "growth", growth_transition = "bin"))
  expect_identical(names_count(three, names_note), 1L)
  expect_identical(names_count(three, paste0("The structure changes initial_plus_group, initial_length and ",
    "growth_transition and leaves growth_increment at its original value.")), 1L)
  expect_identical(names_count(three, "The value growth_increment"), 0L)
  two <- names_fit_messages(list(initial_plus_group = "equilibrium", initial_length = "growth",
                                 correlation_range = "symmetric"))
  expect_identical(names_count(two, paste0("The structure changes initial_plus_group and initial_length and leaves ",
    "growth_increment and growth_transition at their original values.")), 1L)
  # The original set with one setting changed is a part of the set as well.
  expect_identical(names_count(names_fit_messages(list(set = "original", growth_transition = "bin")), names_note), 1L)
  # Several starts, a bundle and a refit are one fit each.
  expect_identical(names_count(names_fit_messages(list(growth_transition = "bin"), nstarts = 2), names_note), 1L)
  args <- names_fit_args("ALSCL", structure = list(growth_transition = "bin"))
  expect_identical(names_count(testthat::capture_messages(fit <- run_alscl(args)), names_note), 1L)
  expect_identical(names_count(testthat::capture_messages(refit_model(fit)), names_note), 1L)
  # The fit itself is the fit of the settings given; the note changes no result.
  quiet <- do.call(run_alscl, names_fit_args("ALSCL", structure = list(growth_transition = "bin"), silent = TRUE))
  expect_identical(quiet$opt$par, fit$opt$par)
  expect_identical(quiet$structure, fit$structure)
  expect_identical(quiet$diagnostics, fit$diagnostics)
})

test_that("the message is not given for the sets, for correlation_range, for ACL or for a silent fit", {
  skip_on_cran()
  full <- list(initial_plus_group = "equilibrium", initial_length = "growth",
               growth_increment = "von_bertalanffy", growth_transition = "bin")
  for (structure in list(list(), "original", "von_bertalanffy", "published", "consistent", full,
                         list(correlation_range = "symmetric"),
                         list(set = "von_bertalanffy", correlation_range = "symmetric"),
                         # Naming the set and replacing one of its settings is a deliberate choice.
                         list(set = "von_bertalanffy", growth_transition = "midpoint")))
    expect_identical(names_count(names_fit_messages(structure), names_note), 0L)
  for (structure in list(list(initial_plus_group = "equilibrium"), "von_bertalanffy",
                         list(set = "original", initial_plus_group = "equilibrium")))
    expect_identical(names_count(names_fit_messages(structure, "ACL"), names_note), 0L)
  # silent = TRUE gives no message at all.
  expect_no_message(do.call(run_alscl, names_fit_args("ALSCL", structure = list(growth_increment = "von_bertalanffy"),
                                                      silent = TRUE)))
  expect_false(ALSCL:::.acl_partial_set_note(list(growth_increment = "von_bertalanffy"), "ALSCL", TRUE))
  expect_no_message(ALSCL:::.acl_partial_set_note(list(growth_increment = "von_bertalanffy"), "ALSCL", TRUE))
  expect_message(shown <- ALSCL:::.acl_partial_set_note(list(growth_increment = "von_bertalanffy"), "ALSCL", FALSE),
                 names_note, fixed = TRUE)
  expect_true(shown)
})

test_that("functions that run several fits give the message once per call", {
  skip_on_cran()
  partial <- list(growth_increment = "von_bertalanffy", growth_transition = "bin")
  args <- names_fit_args("ALSCL", structure = partial)
  scenarios <- list(base = list(), high_M = list(M = .25), low_M = list(M = .15))
  messages <- testthat::capture_messages(fit_scenarios(args, scenarios, model = "alscl"))
  expect_identical(names_count(messages, "Fitting ALSCL with 1 start(s)"), 3L)
  expect_identical(names_count(messages, names_note), 1L)
  # The next call gives it again, and so does a single fit after a batch.
  expect_identical(names_count(testthat::capture_messages(fit_scenarios(args, scenarios[1:2], model = "alscl")),
                               names_note), 1L)
  expect_identical(names_count(testthat::capture_messages(do.call(run_alscl, args)), names_note), 1L)
  # A scenario that changes the structure to a part of the set, among scenarios that do not.
  whole <- names_fit_args("ALSCL", structure = "von_bertalanffy")
  mixed <- testthat::capture_messages(fit_scenarios(whole, list(base = list(),
    midpoint = list(structure = list(initial_plus_group = "equilibrium", initial_length = "growth",
                                     growth_increment = "von_bertalanffy")),
    logistic = list(structure = list(growth_transition = "bin"))), model = "alscl"))
  expect_identical(names_count(mixed, names_note), 1L)
  expect_identical(names_count(mixed, "leaves growth_transition at its original value"), 1L)
  expect_identical(names_count(testthat::capture_messages(fit_scenarios(whole, scenarios[1:2], model = "alscl")),
                               names_note), 0L)
  # Silent scenarios give no message.
  expect_identical(names_count(testthat::capture_messages(fit_scenarios(args, scenarios[1:2], model = "alscl",
                                                                         silent = TRUE)), names_note), 0L)
  # Hindcast folds: once when not silent, never when silent (the default).
  hind <- testthat::capture_messages(hindcast_model(args, model = "alscl", nfolds = 2, min_train = 3, silent = FALSE))
  expect_identical(names_count(hind, "Fitting ALSCL with 1 start(s)"), 2L)
  expect_identical(names_count(hind, names_note), 1L)
  expect_identical(names_count(testthat::capture_messages(hindcast_model(args, model = "alscl", nfolds = 2,
                                                                          min_train = 3)), names_note), 0L)
  # Retrospective fits are silent fits: the call gives the message once, and not when silent.
  retro_args <- c(list(nyear = 2, model_type = "alscl"), args[setdiff(names(args), "silent")])
  retro <- testthat::capture_messages(do.call(retro_model, retro_args))
  expect_identical(names_count(retro, "Peel"), 2L)
  expect_identical(names_count(retro, names_note), 1L)
  expect_identical(names_count(testthat::capture_messages(do.call(retro_model, c(retro_args, list(silent = TRUE)))),
                               names_note), 0L)
  retro_args$structure <- "von_bertalanffy"
  expect_identical(names_count(testthat::capture_messages(do.call(retro_model, retro_args)), names_note), 0L)
  # A batch that stops with an error closes itself: the next fit gives the message.
  expect_error(ALSCL:::.acl_cluster_lapply(1:2, function(i) stop("stopped"), 1L, "alscl"), "stopped")
  expect_identical(ALSCL:::.acl_notes$depth, 0L)
  expect_false(ALSCL:::.acl_notes$partial_set)
  expect_identical(names_count(testthat::capture_messages(do.call(run_alscl, args)), names_note), 1L)
})

test_that("the message reaches the user once when scenarios run on socket workers", {
  partial <- list(growth_increment = "von_bertalanffy")
  settings <- list(list(silent = FALSE, nstarts = 3L, structure = partial),
                   list(silent = FALSE, nstarts = 3L, structure = list(growth_transition = "bin")))
  # The decision is made before any worker starts; a stub replaces the fits.
  testthat::local_mocked_bindings(
    .acl_cluster_lapply = function(X, FUN, ncores, model, ...) vector("list", length(X)),
    .acl_workers = function(n) as.integer(n), .package = "ALSCL")
  apply_messages <- function(settings, model = "alscl", ncores = 2L)
    testthat::capture_messages(ALSCL:::.acl_batch_apply(settings, model, ncores))
  shown <- apply_messages(settings)
  expect_identical(names_count(shown, names_note), 1L)
  expect_identical(names_count(shown, "The structure changes growth_increment and leaves"), 1L)
  # One worker: the fits give the message themselves.
  expect_identical(names_count(apply_messages(settings, ncores = 1L), names_note), 0L)
  # Silent fits, complete sets and ACL give none.
  quiet <- list(list(silent = TRUE, structure = partial), list(silent = FALSE, structure = "von_bertalanffy"),
                list(silent = FALSE), list(silent = FALSE, structure = list(correlation_range = "symmetric")))
  expect_identical(names_count(apply_messages(quiet), names_note), 0L)
  expect_identical(names_count(apply_messages(list(list(silent = FALSE, structure = list(initial_plus_group = "equilibrium")),
                                                   list(silent = FALSE)), model = "acl"), names_note), 0L)
  # A silent fit before a fit that is not silent does not hide the message.
  expect_identical(names_count(apply_messages(list(list(silent = TRUE, structure = partial),
                                                   list(silent = FALSE, structure = partial))), names_note), 1L)
})
