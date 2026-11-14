# Build data/whiting_example.rda from the input files in data-raw/whiting_example/.
# Run from the repository root: Rscript data-raw/whiting_example.R
#
# The input files are derived from public ICES data (DATRAS, the Stock
# Assessment Database and a working group report);
# data-raw/whiting_example/SOURCE.txt gives their origin, the rules used to
# build them, the citations and the licence. This script adds the model
# settings of the North Sea test and the provenance record. It needs no ALSCL
# installation.

build_whiting_example <- function(dir = file.path("data-raw", "whiting_example")) {
  read <- function(name) utils::read.csv(file.path(dir, name), check.names = FALSE)
  table_csv <- function(name) {
    x <- read(name)
    x$LengthBin <- as.character(x$LengthBin)
    x
  }
  data.CatL <- table_csv("data.CatL.csv")
  data.wgt <- table_csv("data.wgt.csv")
  data.mat <- table_csv("data.mat.csv")
  years <- as.integer(names(data.CatL)[-1L])
  stopifnot(identical(years, 1983:2026), identical(names(data.wgt), names(data.CatL)),
            identical(names(data.mat), names(data.CatL)),
            identical(data.wgt$LengthBin, data.CatL$LengthBin),
            identical(data.mat$LengthBin, data.CatL$LengthBin))

  # Length bins of 2 cm with even lower borders: the bin labelled 11 holds
  # 10 cm to below 12 cm. The first bin holds all fish below 10 cm and the
  # last bin all fish of 42 cm and longer.
  len_mid <- as.numeric(data.CatL$LengthBin)
  stopifnot(identical(len_mid, seq(9, 43, 2)))
  len_border <- len_mid[-1L] - 1

  # Starting values of the growth parameters. They are starts, not fixed
  # values: Linf, k and t0 are estimated in both models.
  # ACL: von Bertalanffy curve through the mean lengths at age from the age
  # readings (35.0 cm, 0.438 per year, -0.51 years).
  # ALSCL: Linf and k of the growth increment function that reproduce those
  # mean lengths at ages 1 to 9 when no fish dies (38.56 cm, 0.3523 per year;
  # script 16_calibrate_growth.R of the North Sea test), and the t0 at which
  # the mean length of recruits is 16.9 cm.
  # cv_len is fixed at 0.15, the mean coefficient of variation of length at
  # ages 1 to 3 in the age readings (0.148).
  # ALSCL uses t0 = t0_lower + exp(log_t0); t0_lower = -2 lets t0 be negative.
  t0_lower <- -2
  alscl_start <- c(Linf = 38.56, k = 0.3523)
  alscl_start[["t0"]] <- 1 + log(1 - 16.9 / alscl_start[["Linf"]]) / alscl_start[["k"]]
  p_acl <- list(log_Linf = log(35.0), log_vbk = log(0.438), t0 = -0.51, log_cv_len = log(0.15))
  p_alscl <- list(log_Linf = log(alscl_start[["Linf"]]), log_vbk = log(alscl_start[["k"]]),
                  log_t0 = log(alscl_start[["t0"]] - t0_lower),
                  log_cv_len = log(0.15), log_cv_grow = log(0.2))

  length_at_age <- read("age_readings_length_at_age.csv")
  index <- read("age_readings_index_at_age.csv")
  index_at_age <- as.matrix(index[-1L])
  dimnames(index_at_age) <- list(year = index$year, age = 1:10)
  stopifnot(identical(index$year, years), all(length_at_age$age %in% 1:10))

  by_age <- function(name) {
    x <- read(name)
    m <- t(as.matrix(x[-1L]))
    dimnames(m) <- list(age = c(1:5, "6+"), year = x$year)
    m
  }
  ices_M <- by_age("ices_M_at_age.csv")
  ices_maturity <- by_age("ices_maturity_at_age.csv")
  assessment <- read("ices_assessment.csv")
  stopifnot(identical(colnames(ices_M), as.character(1983:2022)),
            identical(colnames(ices_maturity), as.character(1991:2021)),
            identical(assessment$year, 1982:2026))

  coverage <- read("survey_coverage.csv")
  stopifnot(identical(coverage$year, years))

  datras <- paste0("ICES Database of Trawl Surveys (DATRAS), extraction 12 November 2026 of the ",
                   "North Sea International Bottom Trawl Survey (NS-IBTS), quarter 1. ICES, ",
                   "Copenhagen, Denmark. https://datras.ices.dk")
  sag <- paste0("ICES Stock Assessment Database. Copenhagen, Denmark. ICES. Accessed 13 November ",
                "2026. https://standardgraphs.ices.dk")
  wgnssk <- paste0("ICES. 2026. Working Group on the Assessment of Demersal Stocks in the North Sea ",
                   "and Skagerrak (WGNSSK). ICES Scientific Reports. 08:43. 1647 pp. ",
                   "https://doi.org/10.17895/ices.pub.32676345")

  list(
    data.CatL = data.CatL, data.wgt = data.wgt, data.mat = data.mat,
    fit_args = list(rec.age = 1, nage = 10, M = 0.5, sel_L50 = 10, sel_L95 = 14,
                    len_mid = len_mid, len_border = len_border, growth_step = 1),
    fit_config = list(
      acl = list(parameters = p_acl, map = list(t0 = NULL, log_cv_len = factor(NA))),
      alscl = list(parameters = p_alscl, map = list(log_t0 = NULL, log_cv_len = factor(NA)),
                   t0_lower = t0_lower)),
    age_readings = list(length_at_age = length_at_age, index_at_age = index_at_age),
    ices = list(M = ices_M, maturity = ices_maturity, assessment = assessment),
    survey_coverage = coverage,
    provenance = list(
      kind = "Survey observations; an index derived from public ICES data, not an ICES product",
      species = "Whiting (Merlangius merlangus), North Sea",
      survey = "North Sea International Bottom Trawl Survey (NS-IBTS), quarter 1",
      years = years,
      areas = "IBTS roundfish areas 1 to 7",
      gear = paste0("GOV (Grande Ouverture Verticale) bottom trawl. Hauls recorded with another ",
                    "gear are excluded: 59 in 1983, 4 in 1984, 8 in 1985 and 15 in 2026. The survey ",
                    "started to change to a new trawl in 2025; the record of the North Sea test ",
                    "states that about a quarter of the hauls of 2025 and of 2026 were made with ",
                    "it and that the index does not separate them"),
      index = paste0("Catch per unit effort (number per hour of trawling) by 1-cm length class for ",
                     "each haul, with zero for hauls without whiting, averaged within each ICES ",
                     "statistical rectangle and then across rectangles, and summed over the ",
                     "length classes of each length bin"),
      length_bins = paste0("2 cm, the smallest of 1, 2 and 5 cm for which the central 98% of the ",
                           "index spans at most 24 bins. Lengths are rounded down to the cm. The ",
                           "bin labelled 11 holds 10 cm to below 12 cm. The end bins were merged ",
                           "inwards until fish of those lengths were caught in at least 5 hauls in ",
                           "every year: the bin labelled 9 holds all fish below 10 cm and the bin ",
                           "labelled 43 all fish of 42 cm and longer"),
      weight_maturity = paste0("From the individual records of the survey, the same in every year: ",
                               "weight (g) = 0.00440 * length (cm)^3.183 (85896 records, 1997 to ",
                               "2026), stored in kg; logistic maturity at length with 50% mature at ",
                               "19.4 cm and 95% at 27.7 cm (145828 records, 1983 to 2026)"),
      incomplete_years = paste0("The DATRAS product of catch per unit effort by length lacks 63 of ",
                                "the 398 valid hauls of 2009 (63 of the 72 German hauls) and 56 of ",
                                "the 389 valid hauls of 2012 (all Scottish hauls). The index of ",
                                "these two years is built from the remaining hauls. Seven other ",
                                "years lack 1 or 2 hauls (survey_coverage$hauls_missing)"),
      age_readings = paste0("Not used in a fit. Otoliths are sampled by length class, so a plain ",
                            "mean over the aged fish is biased. For each year the proportion at age ",
                            "among the fish aged in each 1-cm class (age-length key) is multiplied ",
                            "by the survey index of that class, which gives the index at age and, ",
                            "over the class midpoints, the mean and standard deviation of length ",
                            "at age as the survey sees it. length_at_age holds the unweighted mean ",
                            "of the annual values over the years of each period with at least 5 ",
                            "aged fish of the age (fish recorded as a plus group excluded); ",
                            "index_at_age holds the index by year and age for ages 1 to 10. ",
                            "205030 age readings, 1983 to 2026. Age 1 is the first quarter 1 after ",
                            "the year of hatching"),
      settings = c(
        rec.age = "1: the youngest age in the quarter 1 index (ICES age 1)",
        nage = paste0("10 age classes, the last a plus group: the smallest number, between 4 and ",
                      "12, with which the plus group holds at most about 1% of a cohort under M ",
                      "alone, ceiling(log(100) / M)"),
        M = paste0("0.50 per year, constant: 4.899 * tmax^-0.916 (Then et al. 2015) with tmax = 12 ",
                   "years, the oldest age read at least 3 times"),
        survey_catchability = paste0("Logistic, 50% at 10 cm and 95% at 14 cm; an assumption of the ",
                                     "North Sea test. No study gives the ascending part for whiting ",
                                     "in quarter 1"),
        cv_len = paste0("Fixed at 0.15: the mean coefficient of variation of length at ages 1 to 3 ",
                        "in the age readings is 0.148"),
        growth_starts = paste0("ACL: von Bertalanffy curve through the mean lengths at age from ",
                               "the age readings (Linf 35.0 cm, k 0.438 per year, t0 -0.51 years). ",
                               "ALSCL: Linf 38.56 cm and k 0.3523 per year of the growth increment ",
                               "function that reproduce those mean lengths without mortality, and ",
                               "the t0 that gives recruits a mean length of 16.9 cm. Starting ",
                               "values only"),
        t0 = paste0("Estimated in both models. ALSCL uses t0_lower = -2, which is the same model ",
                    "as the age labels shifted by 2 years in the North Sea test")),
      ices = paste0("M: natural mortality rate by age and year, Table 22.15 of the whiting section ",
                    "of WGNSSK 2026 (input values from the multispecies model, 1983 to 2022). ",
                    "maturity: proportion mature by age and year, Table 22.14 (1991 to 2021). Both ",
                    "as transcribed by the test team, for ages 1 to 5 and a plus group of ages 6 ",
                    "and older. assessment: spawning stock biomass (t), recruitment at age 0 ",
                    "(in the unit of the database), mean fishing mortality rate at ages 2 to 5 and catch (t) of ",
                    "whiting in Subarea 4 and Division 7.d (whg.27.47d), assessment of 2026, ",
                    "assessment key 22488 of the ICES Stock Assessment Database"),
      download = paste0("DATRAS web services getCPUELength (catch per unit effort per length per ",
                        "haul per hour) and getCAdata (individual length, weight, maturity and age ",
                        "records), 12 November 2026. Stock Assessment Database summary table, 13 ",
                        "November 2026"),
      citation = c(datras = datras, sag = sag, wgnssk = wgnssk),
      licence = paste0("Creative Commons Attribution 4.0 International (CC BY 4.0), ",
                       "https://creativecommons.org/licenses/by/4.0/, under the ICES Data Policy ",
                       "(https://doi.org/10.17895/ices.pub.8883). The tables are aggregated or ",
                       "transcribed from the ICES sources and are not ICES products; results ",
                       "derived from them do not imply endorsement by ICES"),
      built_by = paste0("Scripts 04b_build_inputs_multi.R, 16_calibrate_growth.R and ",
                        "17_fit_settings.R of the North Sea test, November 2026")))
}

# Sourcing this file defines the function only; running it as a script saves
# the data set.
if (sys.nframe() == 0L) {
  whiting_example <- build_whiting_example()
  dir.create("data", showWarnings = FALSE)
  save(whiting_example, file = "data/whiting_example.rda", compress = "xz", version = 2)
  message("Saved data/whiting_example.rda: 18 length bins x 44 annual observations")
}
