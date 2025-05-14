
## OPTIONS ----

  # Suppress warnings from calls to setupProject, simInit, and spades
  options("spades.test.suppressWarnings" = TRUE)

  # Set custom directory paths
  ## Speed up tests by allowing inputs, cache, and R packages to persist between runs
  options("spades.test.paths.inputs"   = NULL) # inputPath
  options("spades.test.paths.cache"    = NULL) # cachePath
  options("spades.test.paths.packages" = NULL) # packagePath


## RUN ALL TESTS ----

  # Run all tests
  testthat::test_dir("tests/testthat")

  # Run all tests with different reporters
  testthat::test_dir("tests/testthat", reporter = testthat::LocationReporter)
  testthat::test_dir("tests/testthat", reporter = testthat::SummaryReporter)


## RUN INDIVIDUAL TESTS ----

  ## Run module test: FRI
  testthat::test_file("tests/testthat/test-1-module_1-RIA-small_FRI.R")

  ## Run module test: harvest1
  testthat::test_file("tests/testthat/test-1-module_1-RIA-small_harvest1.R")

  ## Run module test: harvest2
  testthat::test_file("tests/testthat/test-1-module_1-RIA-small_harvest2.R")

  ## Run module test: presentDay
  testthat::test_file("tests/testthat/test-1-module_1-RIA-small_presentDay.R")


  ## Run integration test: presentDay
  testthat::test_file("tests/testthat/test-2-integration_RIA-small_presentDay.R")


