
if (!testthat::is_testing()) source(testthat::test_path("setup.R"))

test_that("Module runs with defaults: RIA-small", {

  ## Run simInit and spades ----

  # Set up project
  projectName <- "1-module_1-defaults"
  times       <- list(start = 2020, end = 2020)

  simInitInput <- SpaDEStestMuffleOutput(

    SpaDES.project::setupProject(

      modules = "CBM_dataPrep_RIA",
      times   = times,
      paths   = list(
        projectPath = spadesTestPaths$projectPath,
        modulePath  = spadesTestPaths$modulePath,
        packagePath = spadesTestPaths$packagePath,
        inputPath   = spadesTestPaths$inputPath,
        cachePath   = spadesTestPaths$cachePath,
        outputPath  = file.path(spadesTestPaths$temp$outputs, projectName)
      ),

      require = "terra",

      masterRaster = terra::rast(
        crs  = file.path("data", "masterRasterCRS.prj"),
        res  = 250,
        vals = 1L,
        xmin = -1653000,
        xmax = -1553000,
        ymin =  7765000,
        ymax =  7865000
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

