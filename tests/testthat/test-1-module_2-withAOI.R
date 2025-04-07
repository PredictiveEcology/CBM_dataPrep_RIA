
if (!testthat::is_testing()) source(testthat::test_path("setup.R"))

test_that("Module runs with study AOI", {

  ## Run simInit and spades ----

  # Set project path
  projectPath <- file.path(spadesTestPaths$temp$projects, "2-withAOI")
  dir.create(projectPath)
  withr::local_dir(projectPath)

  # Set master raster CRS
  masterRasterCRS <- terra::crs(
    paste(readLines(file.path(spadesTestPaths$testdata, "masterRasterCRS.prj")), collapse = "\n"))

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

      require = c("sf", "terra", "reproducible"),

      dbPath     = file.path(spadesTestPaths$temp$inputs, "cbm_defaults_v1.2.8340.362.db"),
      ecoLocator = sf::st_read(file.path(spadesTestPaths$testdata, "ecoLocator.shp"), quiet = TRUE),
      spuLocator = sf::st_read(file.path(spadesTestPaths$testdata, "spuLocator.shp"), quiet = TRUE),
      dMatrixAssociation = read.csv(file.path(spadesTestPaths$testdata, "disturbance_matrix_association.csv")),
      spinupSQL  = read.csv(file.path(spadesTestPaths$testdata, "spinupSQL.csv")),
      species_tr = read.csv(file.path(spadesTestPaths$testdata, "species_tr.csv")),

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


  ## Check output 'level3DT' ----

  expect_true(!is.null(simTest$level3DT))
  expect_true(inherits(simTest$level3DT, "data.table"))

  for (colName in c("pixelGroup", "ages", "spatial_unit_id", "gcids", "ecozones", "return_interval")){
    expect_true(colName %in% names(simTest$level3DT))
    expect_true(all(!is.na(simTest$level3DT[[colName]])))
  }

  expect_identical(data.table::key(simTest$level3DT), "pixelGroup")

  # Expect that there is 1 row for every unique combination of key attributes in 'spatialDT'
  expect_equal(
    nrow(simTest$level3DT),
    nrow(unique(simTest$spatialDT[, c("ages", "spatial_unit_id", "gcids", "ecozones")]))
  )

  # Expect that 'gcids' is a factor
  expect_true(is.factor(simTest$level3DT$gcids))


  ## Check output 'speciesPixelGroup' ----

  expect_true(!is.null(simTest$speciesPixelGroup))
  expect_true(inherits(simTest$speciesPixelGroup, "data.table"))

  for (colName in c("pixelGroup", "species_id")){
    expect_true(colName %in% names(simTest$speciesPixelGroup))
    expect_true(all(!is.na(simTest$speciesPixelGroup[[colName]])))
  }

  # Check that there is 1 for every pixel group
  expect_equal(nrow(simTest$speciesPixelGroup), nrow(simTest$level3DT))
  expect_equal(sort(simTest$speciesPixelGroup$pixelGroup), simTest$level3DT$pixelGroup)


  ## Check output 'curveID' ----

  expect_true(!is.null(simTest$curveID))
  expect_true(length(simTest$curveID) >= 1)
  expect_true("gcids" %in% simTest$curveID)
  expect_true(all(simTest$curveID %in% names(simTest$level3DT)))


  ## Check output 'ecozones' ----

  expect_true(!is.null(simTest$ecozones))
  expect_true(class(simTest$ecozones) %in% c("integer", "numeric"))

  # Check that there is 1 for every pixel group
  expect_equal(length(simTest$ecozones), nrow(simTest$level3DT))

  # Check that there are no NAs
  expect_true(all(!is.na(simTest$ecozones)))


  ## Check output 'spatialUnits' ----

  expect_true(!is.null(simTest$spatialUnits))
  expect_true(class(simTest$spatialUnits) %in% c("integer", "numeric"))

  # Check that there is 1 for every pixel group
  expect_equal(length(simTest$spatialUnits), nrow(simTest$level3DT))

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
  expect_equal(subset(distEventsSum, year == "2015" & eventID == 1)$count, 62)
  expect_equal(subset(distEventsSum, year == "2015" & eventID == 2)$count, 174)


  ## Check output 'disturbanceMeta' ----

  expect_true(!is.null(simTest$disturbanceMeta))
  expect_true(inherits(simTest$disturbanceMeta, "data.table"))


  ## Check output 'historicDMtype' ----

  expect_true(!is.null(simTest$historicDMtype))
  expect_true(class(simTest$historicDMtype) %in% c("integer", "numeric"))

  # Check that there is 1 for every pixel group
  expect_equal(length(simTest$historicDMtype), nrow(simTest$level3DT))

  # Check that there are no NAs
  expect_true(all(!is.na(simTest$historicDMtype)))


  ## Check output 'lastPassDMtype' ----

  expect_true(!is.null(simTest$lastPassDMtype))
  expect_true(class(simTest$lastPassDMtype) %in% c("integer", "numeric"))

  # Check that there is 1 for every pixel group
  expect_equal(length(simTest$lastPassDMtype), nrow(simTest$level3DT))

  # Check that there are no NAs
  expect_true(all(!is.na(simTest$lastPassDMtype)))

})

