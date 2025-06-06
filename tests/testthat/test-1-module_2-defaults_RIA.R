
if (!testthat::is_testing()) source(testthat::test_path("setup.R"))

test_that("Module runs with defaults: All of RIA", {

  ## Run simInit and spades ----

  ## Only run this test manually due to size
  testthat::skip_if(testthat::is_testing())
  testthat::skip_on_ci()

  # Set times
  times <- list(start = 2020, end = 2025)

  # Set project path
  projectPath <- file.path(spadesTestPaths$temp$projects, "1-module_2-defaults_RIA")
  dir.create(projectPath)
  withr::local_dir(projectPath)

  # Set up project
  simInitInput <- SpaDEStestMuffleOutput(

    SpaDES.project::setupProject(

      times = times,

      modules = "CBM_dataPrep_RIA",
      paths   = list(
        projectPath = projectPath,
        modulePath  = spadesTestPaths$modulePath,
        packagePath = spadesTestPaths$packagePath,
        inputPath   = spadesTestPaths$inputPath,
        cachePath   = spadesTestPaths$cachePath,
        outputPath  = file.path(projectPath, "outputs")
      ),
      options = list(
        reproducible.useMemoise = TRUE
      )
    )
  )

  # Run simInit
  simTestInit <- SpaDEStestMuffleOutput(
    SpaDES.core::simInit2(simInitInput)
  )

  expect_s4_class(simTestInit, "simList")

  # Run spades
  simTest <- SpaDEStestMuffleOutput(
    SpaDES.core::spades(simTestInit)
  )

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

  # ageSpinupMin
  expect_true(!is.null(simTest$ageSpinupMin))
  expect_true(inherits(simTest$ageSpinupMin, "numeric"))

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


