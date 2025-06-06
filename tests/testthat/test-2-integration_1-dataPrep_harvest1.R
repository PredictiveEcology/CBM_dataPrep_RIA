
if (!testthat::is_testing()) source(testthat::test_path("setup.R"))

test_that("Integration: CBM_dataPrep - harvest1", {

  ## Run simInit and spades ----

  # Set times
  times <- list(start = 2020, end = 2025) # Time span: 2020 - 2099

  # Set project path
  projectPath <- file.path(spadesTestPaths$temp$projects, "1-intg-1-dataPrep_harvest1")
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
      options = list(
        reproducible.useMemoise = TRUE
      ),

      # Set required packages for project set up
      require = c("terra", "reproducible"),

      # Set study area
      masterRaster = terra::rast(
        vals = 1L,
        res  = 250,
        ext  = c(xmin = -1653000, xmax = -1553000, ymin = 7765000, ymax = 7865000),
        crs  = masterRasterCRS
      ),

      # Set disturbances
      disturbanceMeta = data.table(
        eventID = c(1, 2),
        name    = c("Wildfire", "Clearcut harvesting without salvage")
      ),
      disturbanceRasters = {

        tsas <- c(16, 40)

        reproducible::prepInputs(
          destinationPath = file.path(spadesTestPaths$inputPath, "harvest1"),
          url        = "https://drive.google.com/file/d/1JpdB9CKpHga55jBmOlATkVyemqbUjtv5",
          targetFile = "tif_scenrio-carbon-base_20210622.tar.gz",
          fun        = utils::untar
        )

        list(
          `1` = lapply(setNames(times$start:times$end, times$start:times$end), function(year){
            file.path(spadesTestPaths$inputPath, "harvest1", "tif", paste0("tsa", tsas), paste0("projected_fire_",    year, ".tif"))
          }),
          `2` = lapply(setNames(times$start:times$end, times$start:times$end), function(year){
            file.path(spadesTestPaths$inputPath, "harvest1", "tif", paste0("tsa", tsas), paste0("projected_harvest_", year, ".tif"))
          })
        )
      }
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


  ## Check output 'disturbanceEvents' -----

  expect_true(!is.null(simTest$disturbanceEvents))
  expect_true(inherits(simTest$disturbanceEvents, "data.table"))

  for (colName in c("pixelIndex", "year", "eventID")){
    expect_true(colName %in% names(simTest$disturbanceEvents))
    expect_true(is.integer(simTest$disturbanceEvents[[colName]]))
    expect_true(all(!is.na(simTest$disturbanceEvents[[colName]])))
  }

  expect_true(all(simTest$disturbanceEvents$year %in% start(simTest):end(simTest)))
  expect_equal(nrow(simTest$disturbanceEvents), 2397)


  ## Check output 'disturbanceMeta' ----

  expect_true(!is.null(simTest$disturbanceMeta))
  expect_true(inherits(simTest$disturbanceMeta, "data.table"))
  expect_equal(simTest$disturbanceMeta$disturbance_type_id, c(1, 204))

})

