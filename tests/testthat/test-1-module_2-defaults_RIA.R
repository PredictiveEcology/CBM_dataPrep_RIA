
if (!testthat::is_testing()) source(testthat::test_path("setup.R"))

test_that("Module runs with defaults: All of RIA", {

  ## Run simInit and spades ----

  skip_if(is_testing()) # Test expensive: kept for interactive testing

  # Set up project
  simInitInput <- setupProjectTest(
    projectName = "1-module_2-defaults_RIA",
    times       = list(start = 2020, end = 2020)
  )

  # Run simInit
  simTestInit <- SpaDES.core::simInit2(simInitInput)
  expect_s4_class(simTestInit, "simList")

  # Run spades
  simTest <- SpaDES.core::spades(simTestInit)
  expect_s4_class(simTest, "simList")


  ## Check outputs ----

  # masterRaster
  expect_true(!is.null(simTest$masterRaster))
  expect_true(inherits(simTest$masterRaster, "SpatRaster"))

  # ageLocator
  expect_true(!is.null(simTest$ageLocator))
  expect_true(inherits(simTest$ageLocator, "sf"))

  # ageDataYear
  expect_true(!is.null(simTest$ageDataYear))
  expect_true(inherits(simTest$ageDataYear, "numeric"))

  # gcIndexLocator
  expect_true(!is.null(simTest$gcIndexLocator))
  expect_true(inherits(simTest$gcIndexLocator, "sf"))

  # userGcMeta
  expect_true(!is.null(simTest$userGcMeta))
  expect_true(inherits(simTest$userGcMeta, "data.table"))
  expect_true("curveID" %in% names(simTest$userGcMeta))

  # userGcM3
  expect_true(!is.null(simTest$userGcM3))
  expect_true(inherits(simTest$userGcM3, "data.table"))
  expect_true("curveID" %in% names(simTest$userGcM3))

})


