
if (!testthat::is_testing()) source(testthat::test_path("setup.R"))

test_that("Multi module: RIA-small 2015", {

  ## Run simInit and spades ----

  # Set times
  times <- list(start = 2015, end = 2015)

  # Set project path
  projectPath <- file.path(spadesTestPaths$temp$projects, "multiModule_RIA-small_2015")
  dir.create(projectPath)
  withr::local_dir(projectPath)

  # Set master raster CRS
  masterRasterCRS <- terra::crs(
    paste(readLines(file.path(spadesTestPaths$testdata, "masterRasterCRS.prj")), collapse = "\n"))

  # Set up project
  simInitInput <- SpaDEStestMuffleOutput(

    SpaDES.project::setupProject(

      modules = c(
        getOption("spades.test.modules", c(
          CBM_defaults        = "PredictiveEcology/CBM_defaults@development",
          CBM_vol2biomass_RIA = "PredictiveEcology/CBM_vol2biomass_RIA@development",
          CBM_core            = "PredictiveEcology/CBM_core@development"
        )),
        CBM_dataPrep_RIA = "CBM_dataPrep_RIA"
      )[c("CBM_defaults", "CBM_dataPrep_RIA", "CBM_vol2biomass_RIA", "CBM_core")],

      times   = times,
      paths   = list(
        projectPath = projectPath,
        modulePath  = spadesTestPaths$temp$modules,
        packagePath = spadesTestPaths$temp$packages,
        inputPath   = spadesTestPaths$temp$inputs,
        cachePath   = spadesTestPaths$temp$cache,
        outputPath  = file.path(projectPath, "outputs")
      ),

      require = "terra",

      masterRaster = terra::rast(
        vals = 1L,
        res  = 250,
        ext  = c(xmin = -1653000, xmax = -1553000, ymin = 7765000, ymax = 7865000),
        crs  = masterRasterCRS
      ),

      outputs = as.data.frame(expand.grid(
        objectName = c("cbmPools", "NPP"),
        saveTime   = sort(c(times$start, times$start + c(1:(times$end - times$start))))
      ))
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


  ## Check completed events ----

  # Check that all modules initiated in the correct order
  expect_identical(tail(completed(simTest)[eventType == "init",]$moduleName, 4),
                   c("CBM_defaults", "CBM_dataPrep_RIA", "CBM_vol2biomass_RIA", "CBM_core"))

  # CBM_core module: Check events completed in expected order
  with(
    list(
      moduleTest  = "CBM_core",
      eventExpect = c(
        "init"              = times$start,
        "spinup"            = times$start,
        setNames(times$start:times$end, rep("annual", length(times$star:times$end))),
        "accumulateResults" = times$end
      )),
    expect_equal(
      completed(simTest)[moduleName == moduleTest, .(eventTime, eventType)],
      data.table::data.table(
        eventTime = data.table::setattr(eventExpect, "unit", "year"),
        eventType = names(eventExpect)
      ))
  )


  ## Check outputs ----

  expect_true(!is.null(simTest$spinupResult))

  expect_true(!is.null(simTest$cbmPools))

  expect_true(!is.null(simTest$NPP))

  expect_true(!is.null(simTest$emissionsProducts))

})


