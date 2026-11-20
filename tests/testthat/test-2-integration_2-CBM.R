
if (!testthat::is_testing()) source(testthat::test_path("setup.R"))

test_that("Integration: CBM: RIA-small", {

  ## Run simInit and spades ----

  skip_if(as.logical(Sys.getenv("CI", FALSE)) & !"main" %in% Sys.getenv(c("GITHUB_BASE_REF", "GITHUB_REF_NAME")))

  # Set up project
  simInitInput <- setupProjectTest(
    projectName = "intg_2-CBM",
    times       = list(start = 2020, end = 2020),
    modules     = c(
      paste0("PredictiveEcology/CBM_defaults@",    ifelse("main" %in% Sys.getenv(c("GITHUB_BASE_REF", "GITHUB_REF_NAME")), "main", "development")),
      "CBM_dataPrep_RIA",
      paste0("PredictiveEcology/CBM_dataPrep@",    ifelse("main" %in% Sys.getenv(c("GITHUB_BASE_REF", "GITHUB_REF_NAME")), "main", "development")),
      paste0("PredictiveEcology/CBM_vol2biomass@", ifelse("main" %in% Sys.getenv(c("GITHUB_BASE_REF", "GITHUB_REF_NAME")), "main", "development")),
      paste0("PredictiveEcology/CBM_core@",        ifelse("main" %in% Sys.getenv(c("GITHUB_BASE_REF", "GITHUB_REF_NAME")), "main", "development"))
    ),

    # Set study area
    masterRaster = terra::rast(
      crs  = file.path(test_path("testdata"), "masterRasterCRS.prj"),
      res  = 250,
      vals = 1L,
      xmin = -1653000,
      xmax = -1553000,
      ymin =  7765000,
      ymax =  7865000
    )
  )

  # Run simInit
  simTestInit <- SpaDES.core::simInit2(simInitInput)
  expect_s4_class(simTestInit, "simList")

  # Run spades
  simTest <- SpaDES.core::spades(simTestInit)
  expect_s4_class(simTest, "simList")

  # Check outputs
  expect_true(!is.null(simTest$emissionsProducts))

})


