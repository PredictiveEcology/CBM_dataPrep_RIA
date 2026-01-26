defineModule(sim, list(
  name = "CBM_dataPrep_RIA",
  description = paste(
    "A data preparation module to format and prepare user-provided input to the SpaDES forest-carbon modelling family",
    "in the BC RIA study area."),
  keywords = NA,
  authors = c(
    person("Céline",  "Boisvenue", email = "celine.boisvenue@nrcan-rncan.gc.ca", role = c("aut", "cre")),
    person("Susan",   "Murray",    email = "murray.e.susan@gmail.com",           role = c("ctb"))
  ),
  childModules = character(0),
  version = list(SpaDES.core = "1.0.2", CBM_dataPrep_RIA = "1.0.0", CBM_dataPrep = "1.0.0"),
  loadOrder = list(before = c("CBM_defaults", "CBM_dataPrep"), after = c("CBM_vol2biomass_RIA", "CBM_core")),
  timeunit = "year",
  timeframe = as.POSIXlt(c(NA, NA)),
  citation = list("citation.bib"),
  documentation = list("CBM_dataPrep_RIA.Rmd"),
  reqdPkgs = list(
    "reproducible (>=2.1.2)", "data.table", "terra", "sf",
    "googledrive", "httr2", "rvest"
  ),
  parameters = rbind(
    defineParameter(".useCache", "logical", TRUE, NA, NA, "Cache module events")
  ),
  inputObjects = bindrows(
    expectsInput(
      objectName = "masterRaster", objectClass = "SpatRaster",
      desc = "Raster template defining the study area. Default is the RIA study area."),
    expectsInput(
      objectName = "ageLocator", objectClass = "sf|SpatRaster",
      desc = "Spatial data source of stand ages. Default is BC VRI data from 2015 or 2020.",
      sourceURL = c(
        `2015` = "https://pub.data.gov.bc.ca/datasets/02dba161-fdb7-48ae-a4bb-bd6ef017c36d/2015/VEG_COMP_LYR_L1_POLY_2015.gdb.zip",
        `2020` = "https://drive.google.com/file/d/1LXSX8M46EnsTCM3wGhkiMgqWcqTubC12"
      )),
    expectsInput(
      objectName = "ageDataYear", objectClass = "numeric",
      desc = "Year that the ages in `ageLocator` represent."),
    expectsInput(
      objectName = "gcIndexLocator", objectClass = "sf|SpatRaster",
      desc = "Spatial data source of growth curve index locations.", #TODO: Define default data source
      sourceURL = "https://drive.google.com/file/d/1LXSX8M46EnsTCM3wGhkiMgqWcqTubC12"),
    expectsInput(
      objectName = "userGcMeta", objectClass = "data.table",
      desc = "Growth curve metadata.", #TODO: Define default data source
      sourceURL = "https://drive.google.com/file/d/1tTzW32U-1Dv43UpYe0EdlocvcrAzXecF/"),
    expectsInput(
      objectName = "userGcM3", objectClass = "data.table",
      desc = "Growth curve volumes by age.", #TODO: Define default data source
      sourceURL = "https://drive.google.com/file/d/1tTzW32U-1Dv43UpYe0EdlocvcrAzXecF"),
    expectsInput(
      objectName = "canfi_species", objectClass = "data.table",
      desc = "Table of CanFI species. Required to get species names for the default `userGcMeta`",
      sourceURL = "https://drive.google.com/open?id=1l9b9V7czTZdiCIFX3dsvAsKpQxmN-Epo")
  ),
  outputObjects = bindrows(
    createsOutput(
      objectName = "masterRaster", objectClass = "SpatRaster",
      desc = "Default `masterRaster` if not provided elsewhere by user."),
    createsOutput(
      objectName = "adminLocator", objectClass = "character",
      desc = "Administrative boundary name set to 'British Columbia'"),
    createsOutput(
      objectName = "ageLocator", objectClass = "sf",
      desc = "Default `ageLocator` if not provided elsewhere by user."),
    createsOutput(
      objectName = "ageDataYear", objectClass = "integer",
      desc = "Data year of default `ageLocator` if not provided elsewhere by user."),
    createsOutput(
      objectName = "gcIndexLocator", objectClass = "SpatRaster",
      desc = "Default `gcIndexLocator` if not provided elsewhere by user."),
    createsOutput(
      objectName = "userGcMeta", objectClass = "data.table",
      desc = "Default `userGcMeta` if not provided elsewhere by user."),
    createsOutput(
      objectName = "userGcM3", objectClass = "data.table",
      desc = "Default `userGcM3` if not provided elsewhere by user.")
  )
))


## MODULE EVENTS ----

doEvent.CBM_dataPrep_RIA <- function(sim, eventTime, eventType, debug = FALSE) {
  switch(
    eventType,
    init = {
      sim <- Init(sim)
    },
    warning(noEventWarning(sim))
  )
  return(invisible(sim))
}

Init <- function(sim){
  
  # Set admin boundary name
  sim$adminLocator <- "British Columbia"
  
  # Return simList
  return(invisible(sim))
}

.inputObjects <- function(sim) {
  
  # Master raster
  if (!any(sapply(c("masterRaster", "masterRasterURL"), suppliedElsewhere, sim))){
    
    message("User has not supplied a master raster ('masterRaster' or 'masterRasterURL'). ",
            "Default for RIA will be used.")
    
    sim$masterRaster <- terra::rast(
      crs  = file.path(dataPath(sim), "masterRasterCRS.prj"),
      res  = 250,
      vals = 1L,
      xmin = -1963750,
      xmax = -1321250,
      ymin =  7407500,
      ymax =  8239000
    )
  }
  
  # Stand ages
  if (!any(sapply(c("ageLocator", "ageLocatorURL"), suppliedElsewhere, sim))){
    
    message("User has not supplied stand age locations ('ageLocator' or 'ageRasterURL'). ",
            "Default for RIA will be used.")
    
    if (!isTRUE(sim$ageDataYear == 2015)){
      
      vri3ColsPath <- prepInputs(
        destinationPath = inputPath(sim),
        url         = extractURL("ageLocator")[[2]],
        filename1   = "VRI_3Cols.zip",
        targetFile  = "VRI_3Cols.shp",
        alsoExtract = "similar",
        fun         = NA
      ) |> Cache()
      
      sim$ageLocator <- st_read_extent(
        vri3ColsPath,
        layer  = "VRI_3Cols",
        query  = "SELECT CAST(PROJ_AGE_1 AS smallint) AS age FROM VRI_3Cols WHERE PROJ_AGE_1 IS NOT NULL",
        extent = if (suppliedElsewhere("masterRaster", sim, where = "user")) sim$masterRaster,
        buffer = if (suppliedElsewhere("masterRaster", sim, where = "user")) max(terra::res(sim$masterRaster)),
        agr    = "constant"
      ) |> Cache()
      
      sim$ageDataYear <- 2020
      
    }else{
      
      ageLocatorPath <- prepInputs(
        destinationPath = inputPath(sim),
        url         = extractURL("ageLocator")[[1]],
        targetFile  = "VEG_COMP_LYR_L1_POLY_2015.gdb.zip",
        archive     = NA,
        fun         = NA
      ) |> Cache()
      
      sim$ageLocator <- st_read_extent(
        ageLocatorPath,
        layer  = "VEG_COMP_LYR_L1_POLY",
        query  = "SELECT CAST(PROJ_AGE_1 AS smallint) AS age FROM VEG_COMP_LYR_L1_POLY WHERE PROJ_AGE_1 IS NOT NULL",
        extent = if (suppliedElsewhere("masterRaster", sim, where = "user")) sim$masterRaster,
        buffer = if (suppliedElsewhere("masterRaster", sim, where = "user"))  max(terra::res(sim$masterRaster)),
        agr    = "constant"
      ) |> Cache()
      
      sim$ageDataYear <- 2015
    }
  }
  
  # Growth curve locations
  if (!any(sapply(c("gcIndexLocator", "gcIndexLocatorURL"), suppliedElsewhere, sim))){
    
    message("User has not supplied growth curve locations ('gcIndexLocator' or 'gcIndexLocatorURL'). ",
            "Default for RIA will be used.")
    
    vri3ColsPath <- prepInputs(
      destinationPath = inputPath(sim),
      url         = extractURL("gcIndexLocator"),
      filename1   = "VRI_3Cols.zip",
      targetFile  = "VRI_3Cols.shp",
      alsoExtract = "similar",
      fun         = NA
    ) |> Cache()
    
    sim$gcIndexLocator <- st_read_extent(
      vri3ColsPath,
      layer  = "VRI_3Cols",
      query  = "SELECT CAST(curve2 AS integer) AS \"curveID\" FROM VRI_3Cols WHERE curve2 IS NOT NULL",
      extent = if (suppliedElsewhere("masterRaster", sim, where = "user")) sim$masterRaster,
      buffer = if (suppliedElsewhere("masterRaster", sim, where = "user"))  max(terra::res(sim$masterRaster)),
      agr    = "constant"
    ) 
    
    sim$gcIndexLocator$curveID[
      sim$gcIndexLocator$curveID %in% c(4102001L, 4103001L)
    ] <- 4101001L
  }
  
  # Growth curve metadata
  if (!any(sapply(c("userGcMeta", "userGcMetaURL"), suppliedElsewhere, sim))){
    
    message("User has not supplied growth curve metadata ('userGcMeta' or 'gcMetaURL'). ",
            "Default for RIA will be used.")
    
    sim$userGcMeta <- prepInputs(
      destinationPath = inputPath(sim),
      url        = extractURL("userGcMeta"),
      targetFile = "au_table_fix.csv",
      fun        = data.table::fread
    )[, V1 := NULL]
    data.table::setnames(sim$userGcMeta, "au_id", "curveID", skip_absent = TRUE)
    data.table::setkey(sim$userGcMeta, curveID)
    
    # Get species names
    if (!suppliedElsewhere("canfi_species", sim)) {
      sim$canfi_species <- prepInputs(
        destinationPath = inputPath(sim),
        url        = extractURL("canfi_species"),
        targetFile = "canfi_species.csv",
        fun        = data.table::fread
      )
    }
    sim$userGcMeta <- merge(
      sim$userGcMeta,
      sim$canfi_species[, .(canfi_species, species = name)],
      by = "canfi_species", all.x = TRUE)
  }
  
  # Growth curve volumes
  if (!any(sapply(c("userGcM3", "userGcM3URL"), suppliedElsewhere, sim))){
    
    message("User has not supplied growth curve volumes ('userGcM3' or 'userGcM3URL'). ",
            "Default for RIA will be used.")
    
    sim$userGcM3 <- prepInputs(
      destinationPath = inputPath(sim),
      url        = extractURL("userGcM3"),
      targetFile = "curve_points_table.csv",
      fun        = data.table::fread
    )[, V1 := NULL]
    data.table::setnames(sim$userGcM3, names(sim$userGcM3), c("curveID", "Age", "MerchVolume"))
    data.table::setkey(sim$userGcM3, curveID, Age)
  }
  
  # Return simList
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