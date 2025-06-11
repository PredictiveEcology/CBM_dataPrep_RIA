
if (!testthat::is_testing()) source(testthat::test_path("setup.R"))

test_that("Integration: CBM_dataPrep", {

  ## Run simInit and spades ----

  # Set times
  times <- list(start = 2020, end = 2025)

  # Set project path
  projectPath <- file.path(spadesTestPaths$temp$projects, "1-intg-1-dataPrep_defaults")
  dir.create(projectPath)
  withr::local_dir(projectPath)

  # Set master raster CRS
  masterRasterCRS <- terra::crs(
    paste(readLines(file.path(spadesTestPaths$testdata, "masterRasterCRS.prj")), collapse = "\n"))

  # Set Github repo branch
  if (!nzchar(Sys.getenv("BRANCH_NAME"))) withr::local_envvar(BRANCH_NAME = "development")

  # Set up project
  simInitInput <- SpaDEStestMuffleOutput(

    SpaDES.project::setupProject(

      times = times,

      modules = c(
        "CBM_dataPrep_RIA",
        paste0("PredictiveEcology/CBM_dataPrep@", Sys.getenv("BRANCH_NAME"))
      ),
      paths   = list(
        projectPath = projectPath,
        modulePath  = spadesTestPaths$temp$modules,
        packagePath = spadesTestPaths$packagePath,
        inputPath   = spadesTestPaths$inputPath,
        cachePath   = spadesTestPaths$cachePath,
        outputPath  = file.path(projectPath, "outputs")
      ),

      require = "terra",

      masterRaster = terra::rast(
        vals = 1L,
        res  = 250,
        ext  = c(xmin = -1653000, xmax = -1553000, ymin = 7765000, ymax = 7865000),
        crs  = masterRasterCRS
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


  ## Check output 'userGcM3' ----

  expect_true(!is.null(simTest$userGcM3))
  expect_true(inherits(simTest$userGcM3, "data.table"))

  for (colName in c(simTest$curveID, "Age", "MerchVolume")){
    expect_true(colName %in% names(simTest$userGcM3))
    expect_true(all(!is.na(simTest$userGcM3[[colName]])))
  }

})

