
### DEFINE MODULE ----

defineModule(sim, list(
  name = "CBM_dataPrep_RIA",
  description = "CBM data preparation module for the RIA study area",
  version = list(SpaDES.core = "1.0.2", CBM_dataPrep_RIA = "0.0.2"),
  authors = c(
    person("Céline",  "Boisvenue", email = "celine.boisvenue@nrcan-rncan.gc.ca", role = c("aut", "cre")),
    person("Susan",   "Murray",    email = "murray.e.susan@gmail.com",           role = c("ctb"))
  ),
  timeunit = "year",
  #documentation = list("CBM_dataPrep_RIA.Rmd"),
  reqdPkgs = list(
    "data.table", "sf", "terra",
    "PredictiveEcology/CBMutils@development (>=2.0.2.0002)"
  ),
  parameters = rbind(
    defineParameter("resampling", "character", default = "mode", NA, NA, "Raster resampling method"),
    defineParameter(".useCache", "character", c(".inputObjects", "Init"), NA, NA, "Cache module events")
  ),
  inputObjects = bindrows(
    expectsInput(
      objectName = "masterRaster", objectClass = "SpatRaster",
      desc = "Raster has NAs where there are no species and the pixel groupID where the pixels were simulated. It is used to map results",
      sourceURL = "https://drive.google.com/file/d/1h7gK44g64dwcoqhij24F2K54hs5e35Ci"),
    expectsInput(
      objectName = "masterRasterURL", objectClass = "character",
      desc = "URL for `masterRaster` - optional, need this or a `masterRaster` object."),
    expectsInput(
      objectName = "spuLocator", objectClass = "sf|SpatRaster",
      desc = paste(
        "Spatial data source from which spatial unit IDs can be extracted.",
        "An output of CBM_defaults.")),
    expectsInput(
      objectName = "ecoLocator", objectClass = "sf|SpatRaster",
      desc = paste(
        "Spatial data source from which ecozone IDs extracted.",
        "An output of CBM_defaults.")),
    expectsInput(
      objectName = "ageRaster", objectClass = "SpatRaster",
      sourceURL = c(
        `2015` = "https://pub.data.gov.bc.ca/datasets/02dba161-fdb7-48ae-a4bb-bd6ef017c36d/2015/VEG_COMP_LYR_L1_POLY_2015.gdb.zip",
        `2020` = "https://drive.google.com/file/d/1LXSX8M46EnsTCM3wGhkiMgqWcqTubC12"
      ),
      desc = paste(
        "Spatial data source from which stand ages can be extracted.",
        "The default is BC VRI data from 2015 or 2020"
      )),
    expectsInput(
      objectName = "ageRasterURL", objectClass = "character",
      desc = "URL for ageRaster"),
    expectsInput(
      objectName = "gcIndexRaster", objectClass = "SpatRaster",
      desc = "Raster giving the growth curve value for each pixel",
      sourceURL = "https://drive.google.com/file/d/1LXSX8M46EnsTCM3wGhkiMgqWcqTubC12"),
    expectsInput(
      objectName = "gcIndexRasterURL", objectClass = "character",
      desc = "URL for gcIndexRaster"),
    expectsInput(
      objectName = "gcMeta", objectClass = "data.frame",
      sourceURL = "https://drive.google.com/file/d/1YmQ6sNucpEmF8gYkRMocPoeKt2P26ZiX",
      desc = "Growth curve metadata"),
    expectsInput(
      objectName = "gcMetaURL", objectClass = "character",
      desc = "URL for gcMeta"),
    expectsInput(
      objectName = "canfi_species", objectClass = "data.frame",
      desc = "CanFI species",
      sourceURL = "https://drive.google.com/open?id=1l9b9V7czTZdiCIFX3dsvAsKpQxmN-Epo"),
    expectsInput(
      objectName = "userGcM3", objectClass = "data.frame",
      desc = "Growth curve volumes by age",
      sourceURL = "https://drive.google.com/file/d/1BYHhuuhSGIILV1gmoo9sNjAfMaxs7qAj"),
    expectsInput(
      objectName = "userGcM3URL", objectClass = "character",
      desc = "URL for userGcM3"),
    expectsInput(
      objectName = "disturbanceRasters", objectClass = "list",
      desc = paste(
        "One or more sets of rasters containing locations of disturbance events for each year.",
        "If the list is named with disturbance event IDs, all non-NA cells will be considered events.",
        "If the list is length 1 and unnamed, the disturbance rasters must have pixel values matching event IDs.",
        "Each set of disturbance rasters must be a list or SpatRaster stack named with 4 digit years",
        "such that a single raster layer can be accessed for each disturbance year",
        "(e.g.  `disturbanceRasters[[\"1\"]][[\"2025\"]]`).",
        "The default rasters were made from the Landsat-derived annual fire and harvest layers as described in: ",
        "Hermosilla, T., M.A. Wulder, J.C. White, N.C. Coops, G.W. Hobart, L.B. Campbell, (2016).",
        "Mass data processing of time series Landsat imagery: pixels to data products for forest monitoring. ",
        "International Journal of Digital Earth. 9(11), 1035-1054."
      )),
    expectsInput(
      objectName = "disturbanceRastersURL", objectClass = "character",
      desc = paste(
        "One or more URL for disturbanceRasters ",
        "If the vector is named, it must be named with the disturbance event IDs the raster includes events for.",
        "If the vector is not named, the raster values must be event IDs.")),
    expectsInput(
      objectName = "disturbanceMeta", objectClass = "data.table",
      desc = paste(
        "Table defining the disturbance event types.",
        "This associates CBM-CFS3 disturbances with the event IDs in the 'disturbanceEvents' table."),
      columns = c(
        eventID             = "Event type ID",
        disturbance_type_id = "Optional. CBM-CFS3 disturbance type ID. If not provided, the user will be prompted to choose IDs.",
        name                = "Optional. Disturbance name (e.g. 'Wildfire'). Required if 'disturbance_type_id' absent."
      )),
    expectsInput(
      objectName = "disturbanceMetaURL", objectClass = "character",
      desc = "URL for disturbanceMeta"),
    expectsInput(
      objectName = "dbPath", objectClass = "character",
      sourceURL = "https://raw.githubusercontent.com/cat-cfs/libcbm_py/main/libcbm/resources/cbm_defaults_db/cbm_defaults_v1.2.8340.362.db",
      desc = paste(
        "Path to the CBM-CBM3 defaults database. ",
        "Required if disturbanceMeta is missing the 'disturbance_type_id' column"))
  ),

  outputObjects = bindrows(
    createsOutput(
      objectName = "standDT", objectClass = "data.table",
      desc = paste(
        "Table summarizing raster input data with 1 row for every 'masterRaster' pixel that is not NA",
        "Required input to CBM_core."),
      columns = c(
        pixelIndex      = "'masterRaster' cell index",
        area            = "Stand area in meters",
        spatial_unit_id = "Spatial unit IDs extracted from input 'spuLocator'"
      )),
    createsOutput(
      objectName = "cohortDT", objectClass = "data.table",
      desc = paste(
        "Table summarizing raster input data with 1 row for every 'masterRaster' pixel that is not NA",
        "Required input to CBM_core."),
      columns = c(
        cohortID        = "Cohort ID",
        pixelIndex      = "'masterRaster' cell index",
        ages            = "Cohort ages extracted from input 'ageRaster'",
        ageSpinup       = "Cohort ages raised to minimum of age 2 to use in the spinup",
        gcids           = "Growth curve IDs extracted from input 'gcIndexRaster'"
      )),
    createsOutput(
      objectName = "spatialDT", objectClass = "data.table",
      desc = "Required by CBM_vol2biomass",
      columns = c(
        pixelIndex      = "'masterRaster' cell index",
        spatial_unit_id = "Spatial unit IDs extracted from input 'spuLocator'",
        ecozones        = "Ecozone IDs extracted from input 'ecoRaster'",
        gcids           = "Growth curve IDs extracted from input 'gcIndexRaster'"
      )),
    createsOutput(
      objectName = "curveID", objectClass = "character",
      desc = paste(
        "Column names in 'level3DT' that uniquely define each pixel group growth curve ID.",
        "Required input to CBM_vol2biomass")),
    createsOutput(
      objectName = "gcMeta", objectClass = "character",
      desc = "Growth curve metadata"),
    createsOutput(
      objectName = "userGcM3", objectClass = "character",
      desc = "Growth curve volumes by age"),
    createsOutput(
      objectName = "disturbanceEvents", objectClass = "data.table",
      desc = paste(
        "Table with disturbance events for each simulation year.",
        "The inputs 'disturbanceRasters' are aligned with the 'masterRaster'",
        "and the events are summarized into this table.",
        "Required input to CBM_core.")),
    createsOutput(
      objectName = "disturbanceMeta", objectClass = "data.frame",
      desc = "Table defining the disturbance event types. Required input to CBM_core.")
  )
))


### SCHEDULE EVENTS ----

doEvent.CBM_dataPrep_RIA <- function(sim, eventTime, eventType, debug = FALSE){
  switch(
    eventType,

    init = {

      sim <- Init(sim)

      # Read annual disturbances
      sim <- scheduleEvent(sim, start(sim), "CBM_dataPrep_RIA", "readDisturbanceEvents")
    },

    readDisturbanceEvents = {

      if (!is.null(sim$disturbanceRasters)){

        # Align disturbances with masterRaster and summarize in table
        newEvents <-  mapply(
          CBMutils::dataPrep_disturbanceRasters,
          disturbanceRasters = sim$disturbanceRasters,
          eventID  = lapply(1:length(sim$disturbanceRasters), function(i) names(sim$disturbanceRasters)[i]),
          MoreArgs = list(
            templateRast = sim$masterRaster,
            year         = time(sim)
          ),
          SIMPLIFY = FALSE) |> Cache()

        sim$disturbanceEvents <- rbind(
          sim$disturbanceEvents,
          subset(do.call(rbind, newEvents), pixelIndex %in% sim$cohortDT$pixelIndex)
        )
      }

      # Schedule for next year
      sim <- scheduleEvent(sim, time(sim) + 1, "CBM_dataPrep_RIA", "readDisturbanceEvents")
    },

    warning(noEventWarning(sim))
  )
  return(invisible(sim))
}


### EVENT FUNCTION: INIT ----

Init <- function(sim) {

  ## Read growth curve data; set sim$curveID ----

  # Create sim$curveID
  sim$curveID <- "gcids"

  gcMeta <- sim$gcMeta
  if (is.null(gcMeta)) stop("'gcMeta' not found")
  if (!inherits(gcMeta, "data.table")){
    gcMeta <- tryCatch(
      data.table::as.data.table(gcMeta),
      error = function(e) stop(
        "'gcMeta' could not be converted to data.table: ", e$message, call. = FALSE))
  }
  if (!sim$curveID %in% names(gcMeta)) stop("gcMeta requires the 'gcids' column")
  if (!"au_id"     %in% names(gcMeta)) stop("gcMeta requires the 'au_id' column")
  if (!"ecozone"   %in% names(gcMeta)) stop("gcMeta requires the 'ecozone' column")


  ## Create sim$standDT and sim$cohortDT ----

  # Set which pixel group columns are assigned from which spatial inputs
  pgCols <- c(
    spatial_unit_id = "spuLocator",
    ecozones        = "ecoLocator",
    au_id           = "gcIndexRaster",
    ages            = "ageRaster"
  )

  # Read spatial inputs
  inRast <- list()
  for (rName in c("masterRaster", pgCols)){
    inRast[[rName]] <- sim[[rName]]
    if (is.null(inRast[[rName]])) stop(shQuote(rName), " input not found")
  }

  ## Convert masterRaster to SpatRaster
  for (rName in "masterRaster"){
    if (!inherits(inRast[[rName]], "SpatRaster")){
      inRast[[rName]] <- tryCatch(
        terra::rast(inRast[[rName]]),
        error = function(e) stop(
          shQuote(rName), " could not be converted to SpatRaster: ", e$message,
          call. = FALSE))
    }
  }

  ## Convert spatial inputs to SpatRaster and align with masterRaster
  for (rName in pgCols){

    if (inherits(inRast[[rName]], "sf")){

      rasCrop <- postProcess(
        inRast[[rName]],
        cropTo    = inRast$masterRaster,
        projectTo = inRast$masterRaster
      ) |> Cache()

      inRast[[rName]] <- terra::rasterize(
        terra::vect(rasCrop),
        inRast$masterRaster,
        fun   = "min", ## TODO: best method?
        field = names(inRast[[rName]])[[1]]
      ) |> Cache()

      rm(rasCrop)

    }else{

      inRast[[rName]] <- postProcess(
        inRast[[rName]],
        to     = inRast$masterRaster,
        method = P(sim)$resampling
      ) |> Cache()
    }
  }

  # Create sim$allPixDT: Summarize input values into table
  allPixDT <- data.table::data.table(
    pixelIndex = 1:terra::ncell(inRast$masterRaster),
    area       = terra::values(terra::cellSize(inRast$masterRaster, unit = "m", mask = TRUE, transform = FALSE))[,1]
  )
  for (i in 1:length(pgCols)){
    allPixDT[[names(pgCols)[[i]]]] <- terra::values(inRast[[pgCols[[i]]]])[,1]
  }
  data.table::setkey(allPixDT, pixelIndex)

  # Filter by NA master raster values
  allPixDT <- subset(allPixDT, !is.na(area))

  # Join with growth curve IDs
  allPixDT <- merge(
    allPixDT, gcMeta[, .(au_id, ecozones = ecozone, gcids)],
    by = c("au_id", "ecozones"), all.x = TRUE)

  # For CBM_vol2biomass
  sim$spatialDT <- allPixDT[, .SD, .SDcols = c("pixelIndex", "spatial_unit_id", "ecozones", "gcids")]

  # For CBM_core
  sim$standDT   <- allPixDT[, .SD, .SDcols = c("pixelIndex", "area", "spatial_unit_id")]
  data.table::setkey(sim$standDT, pixelIndex)

  sim$cohortDT  <- cbind(cohortID = allPixDT$pixelIndex,
                         allPixDT[, .SD, .SDcols = c("pixelIndex", "gcids", "ages")])
  data.table::setkey(sim$cohortDT, cohortID)

  # Alter ages for the spinup
  ## Temporary fix to CBM_core issue: https://github.com/PredictiveEcology/CBM_core/issues/1
  sim$cohortDT[, ageSpinup := ages]
  sim$cohortDT[ageSpinup < 2, ageSpinup := 2]

  rm(allPixDT)


  ## Prepare sim$gcMeta ----

  if (any(!c("species_id", "sw_hw", "canfi_species", "genus") %in% names(sim$gcMeta))){

    if (!"species" %in% names(sim$gcMeta)) stop(
      "gcMeta requires the 'species' column to retrieve species data with CBMutils::sppMatch")

    if (!inherits(sim$gcMeta, "data.table")){
      sim$gcMeta <- tryCatch(
        data.table::as.data.table(sim$gcMeta),
        error = function(e) stop(
          "gcMeta could not be converted to data.table: ", e$message, call. = FALSE))
    }

    # TODO: consider adding this species to LandR:sppEquivalencies_CA
    ##subset(LandR::sppEquivalencies_CA, CanfiCode == 1211 & CBM_speciesID == 177) ## not found
    nm177 <- "Balsam poplar, largetooth aspen and eastern cottonwood"
    is177 <- sim$gcMeta$species == nm177

    sppMatchTable <- CBMutils::sppMatch(
      sim$gcMeta$species[!is177],
      return     = c("CBM_speciesID", "Broadleaf", "CanfiCode", "NFI"),
      otherNames = list(
        "White birch" = "Paper birch"
      ))[, .(
        species_id    = CBM_speciesID,
        sw_hw         = data.table::fifelse(Broadleaf, "hw", "sw"),
        canfi_species = CanfiCode,
        genus         = sapply(strsplit(NFI, "_"), `[[`, 1)
      )]

    if (any(is177)){

      sppMatchTable <- data.table::data.table(
        species    = sim$gcMeta$species,
        species_id = sppMatchTable$species_id[match(1:nrow(sim$gcMeta), which(!is177))],
        sw_hw      = sppMatchTable$sw_hw[     match(1:nrow(sim$gcMeta), which(!is177))]
      )
      sppMatchTable[sppMatchTable$species == nm177, species_id    := 177]
      sppMatchTable[sppMatchTable$species == nm177, sw_hw         := "hw"]
      sppMatchTable[sppMatchTable$species == nm177, canfi_species := 1211]
      sppMatchTable[sppMatchTable$species == nm177, genus         := "POPU"]
    }

    sim$gcMeta <- cbind(
      sim$gcMeta[, .SD, .SDcols = setdiff(names(sim$gcMeta), names(sppMatchTable))],
      sppMatchTable)
    rm(sppMatchTable)
  }


  ## Prepare sim$disturbanceMeta ----

  if (!is.null(sim$disturbanceMeta) && !"disturbance_type_id" %in% names(sim$disturbanceMeta)){

    if (is.null(sim$dbPath)) stop("'dbPath' input required to set disturbanceMeta 'disturbance_type_id'")

    if (!inherits(sim$disturbanceMeta, "data.table")){
      sim$disturbanceMeta <- tryCatch(
        data.table::as.data.table(sim$disturbanceMeta),
        error = function(e) stop(
          "'disturbanceMeta' could not be converted to data.table: ", e$message, call. = FALSE))
    }

    # Match user disturbances with CBM-CFS3 disturbance type IDs
    askUser <- interactive() & !identical(Sys.getenv("TESTTHAT"), "true")
    if (askUser) message(
      "Prompting user to match input disturbances with CBM-CFS3 disturbances:")

    data.table::setnames(
      sim$disturbanceMeta, c("name", "description"), c("nameUser", "descUser"),
      skip_absent = TRUE)

    sim$disturbanceMeta <- cbind(
      sim$disturbanceMeta, CBMutils::distMatch(
        sim$disturbanceMeta$nameUser,
        dbPath = sim$dbPath,
        ask    = askUser
      ) |> Cache()
    )
  }


  ## Return simList ----

  return(invisible(sim))
}


### INPUT OBJECTS ----

.inputObjects <- function(sim) {

  ## Data table inputs ----

  # 1. Growth and yield
  ## TODO add a data manipulation to adjust if the m3 are not given on a yearly basis.
  if (!suppliedElsewhere("userGcM3", sim)){

    if (suppliedElsewhere("userGcM3URL", sim) &
        !identical(sim$userGcM3URL, extractURL("userGcM3"))){

      sim$userGcM3 <- prepInputs(
        destinationPath = inputPath(sim),
        url = sim$userGcM3URL,
        fun = data.table::fread
      )

    }else{

      if (!suppliedElsewhere("userGcM3URL", sim, where = "user")) message(
        "User has not supplied growth curves ('userGcM3' or 'userGcM3URL'). ",
        "Default for RIA will be used.")

      sim$userGcM3 <- prepInputs(
        destinationPath = inputPath(sim),
        url        = extractURL("userGcM3"),
        targetFile = "curve_points_table.csv",
        fun        = data.table::fread
      )[, V1 := NULL]

      names(sim$userGcM3) <- c("au_id", "Age", "MerchVolume")

      # Set a unique ID for each RIA ecozone
      ecozonesRIA <- c(4, 9, 12, 14)
      sim$userGcM3 <- do.call(rbind, lapply(ecozonesRIA, function(ecozoneID){
        cbind(ecozone = ecozoneID, sim$userGcM3)
      }))
      sim$userGcM3 <- cbind(
        gcids = CBMutils::gcidsCreate(sim$userGcM3[, .(au_id, ecozone)]),
        sim$userGcM3)
      data.table::setkey(sim$userGcM3, gcids)
    }
  }

  # 2. Growth and yield metadata
  if (!suppliedElsewhere("gcMeta", sim)) {

    if (suppliedElsewhere("gcMetaURL", sim) &
        !identical(sim$gcMetaURL, extractURL("gcMeta"))){

      sim$gcMeta <- prepInputs(
        destinationPath = inputPath(sim),
        url = sim$gcMetaURL,
        fun = data.table::fread
      )

    }else{

      if (!suppliedElsewhere("gcMetaURL", sim, where = "user")) message(
        "User has not supplied growth curve metadata ('gcMeta' or 'gcMetaURL'). ",
        "Default for RIA will be used.")

      sim$gcMeta <- prepInputs(
        destinationPath = inputPath(sim),
        url        = extractURL("gcMeta"),
        targetFile = "au_table.csv",
        fun        = data.table::fread
      )[, V1 := NULL]

      # Get species names
      if (!suppliedElsewhere("canfi_species", sim)) {
        sim$canfi_species <- prepInputs(
          destinationPath = inputPath(sim),
          url        = extractURL("canfi_species"),
          targetFile = "canfi_species.csv",
          fun        = data.table::fread
        )
      }
      sim$gcMeta <- merge(
        sim$gcMeta,
        sim$canfi_species[, .(canfi_species, species = name)],
        by = "canfi_species", all.x = TRUE)

      # Set a unique ID for each RIA ecozone
      ecozonesRIA <- c(4, 9, 12, 14)
      sim$gcMeta <- do.call(rbind, lapply(ecozonesRIA, function(ecozoneID){
        cbind(ecozone = ecozoneID, sim$gcMeta)
      }))
      sim$gcMeta <- cbind(
        gcids = CBMutils::gcidsCreate(sim$gcMeta[, .(au_id, ecozone)]),
        sim$gcMeta)
      data.table::setkey(sim$gcMeta, gcids)
    }
  }

  # 3. Disturbance information
  if (!suppliedElsewhere("disturbanceMeta", sim) & suppliedElsewhere("disturbanceMetaURL", sim)){

    sim$disturbanceMeta <- prepInputs(
      destinationPath = inputPath(sim),
      url = sim$disturbanceMetaURL,
      fun = data.table::fread
    )
  }


  ## Spatial inputs ----

  # Master raster
  if (!suppliedElsewhere("masterRaster", sim)){

    if (suppliedElsewhere("masterRasterURL", sim) &
        !identical(sim$masterRasterURL, extractURL("masterRaster"))){

      sim$masterRaster <- prepInputs(
        destinationPath = inputPath(sim),
        url = sim$masterRasterURL
      )

    }else{

      if (!suppliedElsewhere("masterRasterURL", sim, where = "user")) message(
        "User has not supplied a master raster ('masterRaster' or 'masterRasterURL'). ",
        "Default for RIA will be used.")

      sim$masterRaster <- prepInputs(
        destinationPath = inputPath(sim),
        url        = extractURL("masterRaster"),
        targetFile = "RIA_rtm.tif",
        fun        = terra::rast
      )
    }
  }

  # Stand ages
  if (!suppliedElsewhere("ageRaster", sim)){

    if (suppliedElsewhere("ageRasterURL", sim) &
        !identical(sim$ageRasterURL, extractURL("ageRaster"))){

      sim$ageRaster <- prepInputs(
        destinationPath = inputPath(sim),
        url = sim$ageRasterURL
      )

    }else{

      if (!suppliedElsewhere("ageRasterURL", sim, where = "user")) message(
        "User has not supplied an age raster ('ageRaster' or 'ageRasterURL'). ",
        "Default for RIA will be used.")

      if (start(sim) >= 2020){

        #sim$ageRasterYear <- 2020
        if (start(sim) != 2020) warning("Default `ageRaster` for RIA represents stand ages at year 2020", call. = FALSE)

        vri3ColsPath <- prepInputs(
          destinationPath = inputPath(sim),
          url         = extractURL("ageRaster")[[2]],
          filename1   = "VRI_3Cols.zip",
          targetFile  = "VRI_3Cols.shp",
          alsoExtract = "similar",
          fun         = NA
        ) |> Cache()

        sim$ageRaster <- st_read_extent(
          vri3ColsPath,
          layer  = "VRI_3Cols",
          query  = "SELECT CAST(PROJ_AGE_1 AS smallint) AS age FROM VRI_3Cols WHERE PROJ_AGE_1 IS NOT NULL",
          extent = sim$masterRaster,
          buffer = if (!is.null(sim$masterRaster)) max(terra::res(sim$masterRaster)),
          agr    = "constant"
        ) |> Cache()

      }else{

        #sim$ageRasterYear <- 2015
        if (start(sim) != 2015) warning("Default `ageRaster` for RIA represents stand ages at year 2015", call. = FALSE)

        ageRasterPath <- prepInputs(
          destinationPath = inputPath(sim),
          url         = extractURL("ageRaster")[[1]],
          targetFile  = "VEG_COMP_LYR_L1_POLY_2015.gdb.zip",
          archive     = NA,
          fun         = NA
        ) |> Cache()

        sim$ageRaster <- st_read_extent(
          ageRasterPath,
          layer  = "VEG_COMP_LYR_L1_POLY",
          query  = "SELECT CAST(PROJ_AGE_1 AS smallint) AS age FROM VEG_COMP_LYR_L1_POLY WHERE PROJ_AGE_1 IS NOT NULL",
          extent = sim$masterRaster,
          buffer = if (!is.null(sim$masterRaster)) max(terra::res(sim$masterRaster)),
          agr    = "constant"
        ) |> Cache()
      }
    }
  }

  # Growth curves
  if (!suppliedElsewhere("gcIndexRaster", sim)){

    if (suppliedElsewhere("gcIndexRasterURL", sim) &
        !identical(sim$gcIndexRasterURL, extractURL("gcIndexRaster"))){

      sim$gcIndexRaster <- prepInputs(
        destinationPath = inputPath(sim),
        url = sim$gcIndexRasterURL
      )

    }else{

      if (!suppliedElsewhere("gcIndexRasterURL", sim, where = "user")) message(
        "User has not supplied a growth curve raster ('gcIndexRaster' or 'gcIndexRasterURL'). ",
        "Default for RIA will be used.")

      vri3ColsPath <- prepInputs(
        destinationPath = inputPath(sim),
        url         = extractURL("gcIndexRaster"),
        filename1   = "VRI_3Cols.zip",
        targetFile  = "VRI_3Cols.shp",
        alsoExtract = "similar",
        fun         = NA
      ) |> Cache()

      sim$gcIndexRaster <- st_read_extent(
        vri3ColsPath,
        layer  = "VRI_3Cols",
        query  = "SELECT CAST(curve2 AS integer) AS gcid FROM VRI_3Cols WHERE curve2 IS NOT NULL",
        extent = sim$masterRaster,
        buffer = if (!is.null(sim$masterRaster)) max(terra::res(sim$masterRaster)),
        agr    = "constant"
      ) |> Cache()
    }
  }


  ## Return simList ----

  return(invisible(sim))

}


# Helper function: read vector data source with extent filter
st_read_extent <- function(dsn, layer = NULL, extent = NULL, buffer = NULL, ...){

  if (!is.null(extent)){

    if (is.null(layer)){
      layer <- tools::file_path_sans_ext(tools::file_path_sans_ext(basename(dsn)))
    }

    targetCRS <- sf::st_crs(
      sf::st_read(
        dsn,
        query = sprintf("SELECT * FROM \"%s\" LIMIT 0", layer),
        quiet = TRUE
      ))

    extent <- sf::st_as_sfc(sf::st_bbox(extent))
    if (!is.null(buffer)){
      extent <- sf::st_buffer(extent, buffer, joinStyle = "MITRE", mitreLimit = 5)
    }
    wkt_filter <- sf::st_as_text(
      sf::st_transform(extent, crs = targetCRS))

  }else wkt_filter <- character(0)

  sf::st_read(
    dsn, wkt_filter = wkt_filter,
    quiet = TRUE,
    ...)
}




