
if (!testthat::is_testing()) source(testthat::test_path("setup.R"))

test_that("Module runs with defaults", {

  ## Run simInit and spades ----

  ## Only run this test manually
  testthat::skip_if(testthat::is_testing())

  # Set project path
  projectPath <- file.path(spadesTestPaths$temp$projects, "1-defaults")
  dir.create(projectPath)
  withr::local_dir(projectPath)

  # Set up project
  simInitInput <- SpaDEStestMuffleOutput(

    SpaDES.project::setupProject(

      times = list(start = 2015, end = 2015),

      modules = "CBM_dataPrep_RIA",
      paths   = list(
        projectPath = projectPath,
        modulePath  = spadesTestPaths$temp$modules,
        packagePath = spadesTestPaths$temp$packages,
        inputPath   = spadesTestPaths$temp$inputs,
        cachePath   = spadesTestPaths$temp$cache,
        outputPath  = file.path(projectPath, "outputs")
      ),

      require = "sf",

      dbPath     = file.path(spadesTestPaths$temp$inputs, "cbm_defaults_v1.2.8340.362.db"),
      ecoLocator = sf::st_read(file.path(spadesTestPaths$testdata, "ecoLocator.shp"), quiet = TRUE),
      spuLocator = sf::st_read(file.path(spadesTestPaths$testdata, "spuLocator.shp"), quiet = TRUE),
      CBMspecies = read.csv(file.path(spadesTestPaths$testdata, "CBMspecies.csv")),
      disturbanceMatrix = read.csv(file.path(spadesTestPaths$testdata, "disturbance_matrix_association.csv"))
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


  ## Check output 'spatialDT' ----

  expect_true(!is.null(simTest$spatialDT))
  expect_true(inherits(simTest$spatialDT, "data.table"))

  for (colName in c("pixelIndex", "pixelGroup", "ages", "spatial_unit_id", "gcids", "ecozones")){
    expect_true(colName %in% names(simTest$spatialDT))
    expect_true(all(!is.na(simTest$spatialDT[[colName]])))
  }

  expect_identical(data.table::key(simTest$spatialDT), "pixelIndex")

  # Check spinup ages are all >= 2
  expect_true("ageSpinup" %in% names(simTest$spatialDT))
  expect_equal(simTest$spatialDT$ageSpinup[simTest$spatialDT$ages >= 2],
               simTest$spatialDT$ages[simTest$spatialDT$ages >= 2])
  expect_true(all(simTest$ageSpinup[simTest$spatialDT$ages < 2] == 2))


  ## Check output 'gcMeta' ----

  expect_true(!is.null(simTest$gcMeta))
  expect_true(inherits(simTest$gcMeta, "data.table"))

  for (colName in c("gcids", "species_id", "sw_hw")){
    expect_true(colName %in% names(simTest$gcMeta))
    expect_true(all(!is.na(simTest$gcMeta[[colName]])))
  }


  ## Check output 'curveID' ----

  expect_true(!is.null(simTest$curveID))
  expect_true(length(simTest$curveID) >= 1)
  expect_true("gcids" %in% simTest$curveID)
  expect_true(all(simTest$curveID %in% names(simTest$spatialDT)))


  ## Check output 'ecozones' ----

  expect_true(!is.null(simTest$ecozones))
  expect_true(class(simTest$ecozones) %in% c("integer", "numeric"))

  # Check that there are no NAs
  expect_true(all(!is.na(simTest$ecozones)))


  ## Check output 'spatialUnits' ----

  expect_true(!is.null(simTest$spatialUnits))
  expect_true(class(simTest$spatialUnits) %in% c("integer", "numeric"))

  # Check that there are no NAs
  expect_true(all(!is.na(simTest$spatialUnits)))


  ## Check output 'disturbanceEvents' -----

  expect_true(!is.null(simTest$disturbanceEvents))
  expect_true(inherits(simTest$disturbanceEvents, "data.table"))

  for (colName in c("pixelIndex", "year", "eventID")){
    expect_true(colName %in% names(simTest$disturbanceEvents))
    expect_true(is.integer(simTest$disturbanceEvents[[colName]]))
    expect_true(all(!is.na(simTest$disturbanceEvents[[colName]])))
  }

  expect_true(all(simTest$disturbanceEvents$pixelIndex %in% simTest$allPixDT$pixelIndex))
  expect_true(all(simTest$disturbanceEvents$year       %in% start(simTest):end(simTest)))

  distEventsSum <- Copy(simTest$disturbanceEvents)[, .(count = .N), by = c("year", "eventID")]
  expect_equal(subset(distEventsSum, year == "2015" & eventID == 1)$count, 27716)
  expect_equal(subset(distEventsSum, year == "2015" & eventID == 2)$count, 7293)


  ## Check output 'disturbanceMeta' ----

  expect_true(!is.null(simTest$disturbanceMeta))
  expect_true(inherits(simTest$disturbanceMeta, "data.table"))

})


