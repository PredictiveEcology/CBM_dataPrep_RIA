
if (!testthat::is_testing()) source(testthat::test_path("setup.R"))

test_that("Module: RIA - no disturbances", {

  ## Run simInit and spades ----

  ## Only run this test manually due to size
  testthat::skip_if(testthat::is_testing())
  testthat::skip_on_ci()

  # Set times
  times <- list(start = 2020, end = 2099)

  # Set project path
  projectPath <- file.path(spadesTestPaths$temp$projects, "1-RIA_disturbanceFree")
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

      require = "sf",

      ecoLocator = sf::st_read(file.path(spadesTestPaths$testdata, "ecoLocator.shp"), quiet = TRUE),
      spuLocator = sf::st_read(file.path(spadesTestPaths$testdata, "spuLocator.shp"), quiet = TRUE)
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


  ## Check output 'standDT' ----

  expect_true(!is.null(simTest$standDT))
  expect_true(inherits(simTest$standDT, "data.table"))

  for (colName in c("pixelIndex", "area", "spatial_unit_id")){
    expect_true(colName %in% names(simTest$standDT))
    expect_true(all(!is.na(simTest$standDT[[colName]])))
  }

  expect_identical(data.table::key(simTest$standDT), "pixelIndex")


  ## Check output 'cohortDT' ----

  expect_true(!is.null(simTest$cohortDT))
  expect_true(inherits(simTest$cohortDT, "data.table"))

  for (colName in c("cohortID", "pixelIndex", "gcids", "ages")){
    expect_true(colName %in% names(simTest$cohortDT))
  }

  expect_identical(data.table::key(simTest$cohortDT), "cohortID")

  # Check spinup ages are all >= 2
  expect_true("ageSpinup" %in% names(simTest$cohortDT))
  expect_equal(simTest$cohortDT$ageSpinup[simTest$cohortDT$ages >= 2],
               simTest$cohortDT$ages[simTest$cohortDT$ages >= 2])
  expect_true(all(simTest$ageSpinup[simTest$cohortDT$ages < 2] == 2))


  ## Check output 'curveID' ----

  expect_true(!is.null(simTest$curveID))
  expect_true(length(simTest$curveID) >= 1)
  expect_true("gcids" %in% simTest$curveID)
  expect_true(all(simTest$curveID %in% names(simTest$cohortDT)))


  ## Check output 'gcMeta' ----

  expect_true(!is.null(simTest$gcMeta))
  expect_true(inherits(simTest$gcMeta, "data.table"))

  for (colName in c("gcids", "species_id", "sw_hw")){
    expect_true(colName %in% names(simTest$gcMeta))
    expect_true(all(!is.na(simTest$gcMeta[[colName]])))
  }


  ## Check output 'userGcM3' ----

  expect_true(!is.null(simTest$userGcM3))
  expect_true(inherits(simTest$userGcM3, "data.table"))

  for (colName in c("gcids", "Age", "MerchVolume")){
    expect_true(colName %in% names(simTest$userGcM3))
    expect_true(all(!is.na(simTest$userGcM3[[colName]])))
  }


  ## Check output 'disturbanceEvents' -----

  expect_true(is.null(simTest$disturbanceEvents))


  ## Check output 'disturbanceMeta' ----

  expect_true(is.null(simTest$disturbanceMeta))

})


