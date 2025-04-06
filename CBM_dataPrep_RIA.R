
### DEFINE MODULE ----

defineModule(sim, list(
  name = "CBM_dataPrep_RIA",
  description = "CBM data preparation module for the RIA study area",
  version = list(SpaDES.core = "1.0.2", CBM_dataPrep_RIA = "0.0.2"),
  authors = c(
    person("Celine", "Boisvenue", email = "Celine.Boisvenue@nrcan-rncan.gc.ca", role = c("aut", "cre")),
    person("Susan",  "Murray",    email = "susan.murray@nrcan-rncan.gc.ca",     role = "ctb")
  ),
  timeunit = "year",
  #documentation = list("CBM_dataPrep_RIA.Rmd"),
  reqdPkgs = list(
    "data.table", "sf", "terra",
    "reproducible (>=2.1.2)" ,
    "PredictiveEcology/CBMutils@development (>=2.0.1)",
    "PredictiveEcology/LandR@development"
  ),
  parameters = rbind(
    defineParameter(".useCache", "logical", TRUE, NA, NA,
                    "Should caching of events or module be used?"),
    defineParameter("resampling", "character", default = "mode", NA, NA,
                    desc = "Raster resampling method")
  ),
  inputObjects = bindrows(
    expectsInput(
      objectName = "dbPath", objectClass = "character", desc = NA, sourceURL = NA), # FROM DEFAULTS
    expectsInput(
      objectName = "dMatrixAssociation", objectClass = "data.frame", desc = NA, sourceURL = NA), # FROM DEFAULTS
    expectsInput(
      objectName = "spinupSQL", objectClass = "dataset", desc = NA, sourceURL = NA), # FROM DEFAULTS
    expectsInput(
      objectName = "species_tr", objectClass = "dataset", desc = NA, sourceURL = NA), # FROM DEFAULTS
    expectsInput(
      objectName = "canfi_species", objectClass = "data.frame",
      desc = paste("File containing the possible species in the Boudewyn table.",
                   "Note that if Boudewyn et al. added species, this should be updated.",
                   "Also note that such an update is very unlikely."),
      sourceURL = "https://docs.google.com/spreadsheets/d/1YpJ9MyETyt1LBFO81xTrIdbhjO7GoK3K/"),
    expectsInput(
      objectName = "canfi_speciesURL", objectClass = "character",
      desc = "URL for canfi_species"),
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
      sourceURL = "https://pub.data.gov.bc.ca/datasets/02dba161-fdb7-48ae-a4bb-bd6ef017c36d/2015/VEG_COMP_LYR_L1_POLY_2015.gdb.zip",
      desc = paste(
        "Spatial data source from which stand ages can be extracted.",
        "The default is BC VRI data from 2015"
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
      objectName = "userGcM3", objectClass = "data.frame",
      desc = "Growth curve volumes by age",
      sourceURL = "https://drive.google.com/file/d/1u7o2BzPZ2Bo7hNcC8nEctNpDmp7ce84m"),
    expectsInput(
      objectName = "userGcM3URL", objectClass = "character",
      desc = "URL for userGcM3"),
    expectsInput(
      objectName = "disturbanceRasters", objectClass = "list",
      sourceURL = list(
        `1` = "https://drive.google.com/file/d/1kxCL-i311yd3cS7QDQ2GwHHtyQFiiXoo", # fire
        `2` = "https://drive.google.com/file/d/1m7mjcx5Sz--RB7x4N3cPYpGkfmxX8KPB"  # harvest
      ),
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
      objectName = "userDist", objectClass = "data.table",
      sourceURL = "https://drive.google.com/file/d/1Gr_oIfxR11G1ahynZ5LhjVekOIr2uH8X",
      desc = paste(
        "Table defines the values present in the user provided disturbance rasters.",
        "The user will be prompted to match these with CBM-CFS3 disturbances",
        "to create the 'disturbanceMeta' table input to CBM_core.",
        "The default is a table defining the values in the default 'disturbanceRasters'."),
      columns = c(
        eventID    = "Event type ID",
        wholeStand = "Specifies if the whole stand is disturbed (1 = TRUE; 0 = FALSE)",
        name       = "Disturbance name (e.g. 'Wildfire')"
      )),
    expectsInput(
      objectName = "userDistURL", objectClass = "character",
      desc = "URL for userDist"),
  ),

  outputObjects = bindrows(
    createsOutput(
      objectName = "allPixDT", objectClass = "data.table",
      desc = "Table summarizing raster input data with 1 row for every 'masterRaster' pixel (including NAs)",
      columns = c(
        pixelIndex      = "'masterRaster' cell index",
        ages            = "Stand ages extracted from input 'ageRaster'",
        spatial_unit_id = "Spatial unit IDs extracted from input 'spuLocator'",
        gcids           = "Growth curve IDs extracted from input 'gcIndexRaster'",
        ecozones        = "Ecozone IDs extracted from input 'ecoRaster'"
      )),
    createsOutput(
      objectName = "spatialDT", objectClass = "data.table",
      desc = paste(
        "Table summarizing raster input data with 1 row for every 'masterRaster' pixel that is not NA",
        "Required input to CBM_vol2biomass and CBM_core."),
      columns = c(
        pixelIndex      = "'masterRaster' cell index",
        pixelGroup      = "Pixel group ID",
        ages            = "Stand ages extracted from input 'ageRaster'",
        spatial_unit_id = "Spatial unit IDs extracted from input 'spuLocator'",
        gcids           = "Growth curve IDs extracted from input 'gcIndexRaster'",
        ecozones        = "Ecozone IDs extracted from input 'ecoRaster'"
      )),
    createsOutput(
      objectName = "level3DT", objectClass = "data.table",
      desc = paste(
        "Table associating pixel groups with their key attributes.",
        "Required input to CBM_vol2biomass and CBM_core."),
      columns = c(
        pixelGroup      = "Pixel group ID",
        ages            = "Stand ages extracted from input 'ageRaster' modified such that all ages are >=3",
        spatial_unit_id = "Spatial unit IDs extracted from input 'spuLocator'",
        gcids           = "Factor of growth curve IDs extracted from input 'gcIndexRaster'",
        ecozones        = "Ecozone IDs extracted from input 'ecoRaster'"
      )),
    createsOutput(
      objectName = "speciesPixelGroup", objectClass = "data.frame",
      desc = paste(
        "Table connecting pixel groups to species IDs.",
        "Required input to CBM_core."),
      columns = c(
        pixelGroup = "Pixel group ID",
        species_id = "Species ID"
      )),
    createsOutput(
      objectName = "curveID", objectClass = "character",
      desc = paste(
        "Column names in 'level3DT' that uniquely define each pixel group growth curve ID.",
        "Required input to CBM_vol2biomass")),
    createsOutput(
      objectName = "userGcM3", objectClass = "character",
      desc = "Growth curve volumes by age"),
    createsOutput(
      objectName = "gcMeta", objectClass = "character",
      desc = "Growth curve metadata"),
    createsOutput(
      objectName = "ecozones", objectClass = "numeric",
      desc = paste(
        "Ecozone IDs extracted from input 'ecoRaster' for each pixel group.",
        "Required input to CBM_vol2biomass")),
    createsOutput(
      objectName = "spatialUnits", objectClass = "numeric",
      desc = paste(
        "Spatial unit IDs extracted from input 'spuRaster' for each pixel group.",
        "Required input to CBM_vol2biomass")),
    createsOutput(
      objectName = "realAges", objectClass = "numeric",
      desc = paste(
        "Stand ages extracted from input 'ageRaster' for each pixel group.",
        "Required input to CBM_core.")),
    createsOutput(
      objectName = "disturbanceEvents", objectClass = "data.table",
      desc = paste(
        "Table with disturbance events for each simulation year.",
        "The inputs 'disturbanceRasters' are aligned with the 'masterRaster'",
        "and the events are summarized into this table.",
        "Required input to CBM_core.")),
    createsOutput(
      objectName = "disturbanceMeta", objectClass = "data.frame",
      desc = paste(
        "Table defining the disturbance event types.",
        "This is created by matching the input 'userDist' table with CBM-CFS3 disturbance types.",
        "Required input to CBM_core."),
      columns = c(
        eventID               = "Event type ID from 'userDist'",
        wholeStand            = "wholeStand flag from 'userDist'",
        spatial_unit_id       = "Spatial unit ID",
        disturbance_type_id   = "Disturbance type ID",
        disturbance_matrix_id = "Disturbance matrix ID",
        name                  = "Disturbance name",
        description           = "Disturbance description"
      )),
    createsOutput(
      objectName = "historicDMtype", objectClass = "numeric",
      desc = paste(
        "Historical disturbance type for each pixel group.",
        "Examples: 1 = wildfire; 2 = clearcut.",
        "Required input to CBM_core.")),
    createsOutput(
      objectName = "lastPassDMtype", objectClass = "numeric",
      desc = paste(
        "Last pass disturbance type for each pixel group.",
        "Examples: 1 = wildfire; 2 = clearcut.",
        "Required input to CBM_core."))
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

        sim$disturbanceEvents <- do.call(rbind, c(
          if (!is.null(sim$disturbanceEvents)) list(sim$disturbanceEvents),
          newEvents
        ))
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


  ## Create sim$allPixDT ----

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
  sim$allPixDT <- data.table::data.table(
    pixelIndex = 1:terra::ncell(inRast$masterRaster)
  )
  for (i in 1:length(pgCols)){
    sim$allPixDT[[names(pgCols)[[i]]]] <- terra::values(inRast[[pgCols[[i]]]])[,1]
  }

  # Join with growth curve IDs
  sim$allPixDT <- merge(
    sim$allPixDT, gcMeta[, .(au_id, ecozones = ecozone, gcids)],
    by = c("au_id", "ecozones"), all.x = TRUE)

  # Keep only essential onlys
  sim$allPixDT <- sim$allPixDT[, .(pixelIndex, spatial_unit_id, ecozones, gcids, ages)]

  # Set key
  data.table::setkey(sim$allPixDT, pixelIndex)


  ## Create sim$spatialDT ----

  # Create sim$spatialDT: Summarize input raster values where masterRaster is not NA
  sim$spatialDT <- sim$allPixDT[!is.na(terra::values(inRast$masterRaster)[,1]),]

  spatialDT_isNA <- is.na(sim$spatialDT)
  if (any(spatialDT_isNA)){
    sim$spatialDT <- sim$spatialDT[!apply(spatialDT_isNA, 1, any),]
  }

  # Create pixel groups: groups of pixels with the same attributes
  sim$spatialDT$pixelGroup <- LandR::generatePixelGroups(
    sim$spatialDT, maxPixelGroup = 0, columns = setdiff(names(sim$spatialDT), "pixelIndex")
  )

  # Keep only essential columns
  sim$spatialDT <- sim$spatialDT[, c(names(sim$allPixDT), "pixelGroup"), with = FALSE]

  # Set key
  data.table::setkey(sim$spatialDT, pixelIndex)


  ## Create sim$level3DT, sim$realAges, and sim$curveID ----

  level3DT <- unique(sim$spatialDT[, -("pixelIndex")])
  setkeyv(level3DT, "pixelGroup")

  # Set sim$level3DT$gcids to be a factor
  set(level3DT, j = "gcids",
      value = factor(CBMutils::gcidsCreate(level3DT[, sim$curveID, with = FALSE])))

  # Create 'realAges' output object and set ages to be >= 2
  ## Temporary fix to CBM_core issue: https://github.com/PredictiveEcology/CBM_core/issues/1
  sim$realAges <- level3DT[, ages]
  level3DT[ages <= 2, ages := 2]
  setorderv(level3DT, "pixelGroup")

  # Join with spinup parameters
  setkeyv(level3DT, "spatial_unit_id")
  spinupParameters <- as.data.table(sim$spinupSQL[, c(1, 7)])

  setkeyv(spinupParameters,"id")
  spinupParameters <- setNames(spinupParameters, replace(names(spinupParameters), names(spinupParameters) == 'id', 'spatial_unit_id'))
  retInt <- merge.data.table(level3DT, spinupParameters,
                             by = "spatial_unit_id", all.x = TRUE)
  setkeyv(retInt, "pixelGroup")
  setkeyv(level3DT, "pixelGroup")
  sim$level3DT <- retInt


  ## Create sim$ecozones and sim$spatialUnits ----

  # create sim$ecozones and sim$spatialUnits to subset vol2biomass growth curves
  sim$ecozones <- sim$level3DT$ecozones
  sim$spatialUnits <- sim$level3DT$spatial_unit_id


  ## Create sim$speciesPixelGroup ----

  ## TODO:
  ## - Simplify this process to not require 2 extra input tables
  ## - Make this more generic to user input (this works only with the defaults)


  # Get species_id
  gcMeta <- gcMeta |>
    merge(data.table::as.data.table(sim$canfi_species)[
      , .(canfi_species, name)], by = "canfi_species", all.x = TRUE) |>
    merge(data.table::as.data.table(sim$species_tr)[
      , .(species_id, name)], by = "name", all.x = TRUE)

  sim$speciesPixelGroup <- merge(
    unique(sim$spatialDT[, .(pixelGroup, gcids)]),
    gcMeta, all.x = TRUE)
  setkey(sim$speciesPixelGroup, "pixelGroup")

  unknownSpecies <- unique(subset(sim$speciesPixelGroup, is.na(species_id))$name)
  if (length(unknownSpecies) > 0) warning(
    "species_id could not be determined for specie(s): ",
    paste(shQuote(unknownSpecies), collapse = ", "))


  ## Create sim$disturbanceMeta, sim$historicDMtype, and sim$lastPassDMtype ----

  # List disturbances possible within in each spatial unit
  spuIDs <- sort(unique(sim$level3DT$spatial_unit_id))
  listDist <- CBMutils::spuDist(
    spuIDs = spuIDs,
    dbPath = sim$dbPath,
    disturbance_matrix_association = sim$dMatrixAssociation
  )

  # Check if userDist already has all the required IDs
  if (all(c("spatial_unit_id", "disturbance_type_id", "disturbance_matrix_id") %in% names(sim$userDist))){
    sim$disturbanceMeta <- sim$userDist
  }

  if (!suppliedElsewhere("disturbanceMeta", sim)){

    # Read user disturbances
    userDist <- sim$userDist

    if (!inherits(userDist, "data.table")){
      userDist <- tryCatch(
        data.table::as.data.table(userDist),
        error = function(e) stop(
          "'userDist' could not be converted to data.table: ", e$message, call. = FALSE))
    }

    # Match user disturbances with CBM-CFS3 disturbance matrices
    userDistSpu <- userDist
    if (!"spatial_unit_id" %in% names(userDist)){
      userDistSpu <- do.call(rbind, lapply(spuIDs, function(spuID){
        cbind(spatial_unit_id = spuID, userDist)
      }))
    }else{
      distCols <- intersect(names(userDist), c("distName", "name", "eventID", "wholeStand"))
      userDistSpu <- do.call(rbind, lapply(spuIDs, function(spuID){
        cbind(spatial_unit_id = spuID, unique(userDist[, distCols, with = FALSE]))
      }))
      userDistSpu <- merge(userDistSpu, userDist, by = c(distCols, "spatial_unit_id"), all.x = TRUE)
    }

    askUser <- interactive() & !identical(Sys.getenv("TESTTHAT"), "true")
    if (askUser) message(
      "Prompting user to match input disturbances with CBM-CFS3 disturbances:")

    sim$disturbanceMeta <- do.call(rbind, lapply(1:nrow(userDistSpu), function(i){

      if ("disturbance_type_id" %in% names(userDistSpu)){
        userDistMatch <- subset(
          listDist, spatial_unit_id == userDistSpu[i,]$spatial_unit_id &
            disturbance_type_id == userDistSpu[i,]$disturbance_type_id)

      }else{

        userDistMatch <- CBMutils::spuDistMatch(
          userDistSpu[i,], listDist = listDist,
          ask = askUser
        ) |> Cache()
      }

      cbind(
        userDistSpu[i, setdiff(names(userDist), names(userDistMatch)), with = FALSE],
        userDistMatch)
    }))
  }

  # Set sim$historicDMtype to be wildfire
  sim$historicDMtype <- data.table::merge.data.table(
    sim$level3DT,
    unique(subset(listDist[, .(spatial_unit_id, disturbance_type_id, name)], tolower(name) == "wildfire")),
    by = "spatial_unit_id"
  )$disturbance_type_id

  # Set sim$lastPassDMtype to be wildfire
  ## TODO: this is where it could be something else then fire
  sim$lastPassDMtype <- sim$historicDMtype


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

  # 2. Meta info about growth and yield curves
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
  if (!suppliedElsewhere("userDist", sim) & !suppliedElsewhere("disturbanceMeta", sim)  &
      suppliedElsewhere("userDistURL", sim)){

    sim$userDist <- prepInputs(
      destinationPath = inputPath(sim),
      url = sim$userDistURL,
      fun = data.table::fread
    )
  }

  # 4. Canfi species
  if (!suppliedElsewhere("canfi_species", sim)) {
    if (suppliedElsewhere("canfi_speciesURL", sim)){

      sim$canfi_species <- prepInputs(
        destinationPath = inputPath(sim),
        url        = sim$canfi_speciesURL,
        targetFile = "canfi_species.csv",
        fun        = fread)

    }else{
      sim$canfi_species <- prepInputs(
        destinationPath = inputPath(sim),
        url        = extractURL("canfi_species"),
        targetFile = "canfi_species.csv",
        fun        = fread)
    }
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

      if (start(sim) != 2015) warning("Default `ageRaster` for RIA represents stand ages at year 2015", call. = FALSE)

      VRI2015 <- prepInputs(
        destinationPath = inputPath(sim),
        url         = extractURL("ageRaster"),
        targetFile  = "VEG_COMP_LYR_L1_POLY_2015.gdb.zip",
        archive     = NA,
        fun         = NA
      )

      sim$ageRaster <- sf::st_read(
        VRI2015,
        query = "SELECT CAST(PROJ_AGE_1 AS smallint) AS age FROM VEG_COMP_LYR_L1_POLY WHERE PROJ_AGE_1 IS NOT NULL",
        agr   = "constant",
        wkt_filter = if (any(sapply(c("masterRaster", "masterRasterURL"), suppliedElsewhere, sim, where = "user"))){
          sf::st_as_text(
            sf::st_transform(
              sf::st_buffer(
                sf::st_as_sfc(sf::st_bbox(sim$masterRaster)),
                max(terra::res(sim$masterRaster)),
                joinStyle = "MITRE", mitreLimit = 5
              ),
              crs = sf::st_crs(
                sf::st_read(VRI2015, query = "SELECT FID FROM VEG_COMP_LYR_L1_POLY LIMIT 1", quiet = TRUE)
              )))
          }else character(0),
        quiet = TRUE
      ) |> Cache()
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

      VRI2020 <- prepInputs(
        destinationPath = inputPath(sim),
        url         = extractURL("gcIndexRaster"),
        filename1   = "VRI_3Cols.zip",
        targetFile  = "VRI_3Cols.shp",
        alsoExtract = "similar",
        fun         = NA,
        archive = NA
      )

      sim$gcIndexRaster <- sf::st_read(
        VRI2020,
        query = "SELECT CAST(curve2 AS integer) AS gcid FROM VRI_3Cols WHERE curve2 IS NOT NULL",
        agr   = "constant",
        wkt_filter = if (any(sapply(c("masterRaster", "masterRasterURL"), suppliedElsewhere, sim, where = "user"))){
          sf::st_as_text(
            sf::st_transform(
              sf::st_buffer(
                sf::st_as_sfc(sf::st_bbox(sim$masterRaster)),
                max(terra::res(sim$masterRaster)),
                joinStyle = "MITRE", mitreLimit = 5
              ),
              crs = sf::st_crs(
                sf::st_read(VRI2020, query = "SELECT FID FROM VRI_3Cols LIMIT 1", quiet = TRUE)
              )))
        }else character(0),
        quiet = TRUE
      ) |> Cache()
    }
  }

  # Disturbances
  if (!suppliedElsewhere("disturbanceRasters", sim)){

    if (suppliedElsewhere("disturbanceRastersURL", sim) &
        !identical(sim$disturbanceRastersURL, extractURL("disturbanceRasters"))){

      sim$disturbanceRasters <- lapply(
        sim$disturbanceRastersURL,
        CBMutils::dataPrep_disturbanceRastersURL,
        destinationPath = inputPath(sim)
      )

    }else{

      if (!suppliedElsewhere("disturbanceRastersURL", sim, where = "user")) message(
        "User has not supplied disturbance rasters ('disturbanceRasters' or 'disturbanceRastersURL'). ",
        "Default for RIA will be used.")

      sim$disturbanceRasters <- list(
        `1` = CBMutils::dataPrep_disturbanceRastersURL(
          destinationPath       = inputPath(sim),
          disturbanceRastersURL = extractURL("disturbanceRasters")[[1]],
          archive               = "historicalFire_1985-2015.zip",
          targetFile            = "historicalFire_1985-2015.tif",
          bandYears             = 1985:2015
        ),
        `2` = CBMutils::dataPrep_disturbanceRastersURL(
          destinationPath       = inputPath(sim),
          disturbanceRastersURL = extractURL("disturbanceRasters")[[2]],
          archive               = "historicalHarvest_1985-2015.zip",
          targetFile            = "historicalHarvest_1985-2015.tif",
          bandYears             = 1985:2015
        )
      )

      # Disturbance information
      if (!suppliedElsewhere("userDist", sim) & !suppliedElsewhere("userDistURL", sim) &
          !suppliedElsewhere("disturbanceMeta", sim)){

        mySpuDmidsCSV <- prepInputs(
          destinationPath = inputPath(sim),
          url        = extractURL("userDist"),
          targetFile = "mySpuDmids.csv",
          fun        = data.table::fread
        )

        # Strip matrix IDs
        if (all(c("rasterID", "eventID") %in% names(mySpuDmidsCSV) == c(TRUE, FALSE))){
          mySpuDmidsCSV[, eventID := rasterID]
        }
        sim$userDist <- mySpuDmidsCSV[, .(eventID, wholeStand, spatial_unit_id)]
        sim$userDist$disturbance_type_id <- sapply(mySpuDmidsCSV$eventID, switch, `1` = 1, `2` = 204)
        # sim$userDist$distDesc <- mySpuDmidsCSV$distName
        # sim$userDist$disturbance_type_id   <- sapply(mySpuDmidsCSV$eventID, switch, `1` = 1, `2` = 4)
        # sim$userDist$disturbance_matrix_id <- mySpuDmidsCSV$disturbance_matrix_id
      }
    }
  }


  ## Return simList ----

  return(invisible(sim))

}


