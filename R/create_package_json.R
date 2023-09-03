
#' Create the package.json file for npm
#'
#' @param app_name name of your app. This is what end-users will see/call an app
#' @param description short description of app
#' @param app_root_path app_root_path to where package.json will be written
#' @param repository purely for info- does the shiny app live in a repository (e.g. GitHub)
#' @param author author of the app
#' @param license license of the App. Not the full license, only the title (e.g. MIT, or GPLv3)
#' @param semantic_version semantic version of app see https://semver.org/ for more information on versioning
#' @param copyright_year year of copyright
#' @param copyright_name copyright-holder's name
#' @param deps is to allow testing with testthat
#' @param website website of app or company
#' @param product_name The product name, often identical to the app name, but with spaces and some special characters allowed
#'
#' @return outputs package.json file with user-input modifications
#' @export
#'
create_package_json <- function(app_name = "MyApp",
                                description = "description",
                                semantic_version = "0.0.0",
                                app_root_path = NULL,
                                repository = "",
                                author = "",
                                copyright = "",
                                website = "",
                                license = "",
                                keywords = "",
                                platforms = list(),
                                deps = NULL,
                                product_name = app_name){



  # null is to allow for testing
  if (is.null(deps)) {
  # get package.json dependencies
    # [-1] remove open { necessary for automated dependency checker
    deps = jsonlite::read_json(system.file("template/package.json", package = "electricShine"))
  }

  opts <- list(
    name = app_name,
    productName = product_name,
    description = description,
    version = semantic_version,
    private = TRUE,
    author = author,
    copyright = copyright,
    license = license,
    homepage = website,
    main = "app/background.js",
    keywords = keywords,
    build = list(
      appId = paste0("com.", app_name),
      files = c("app/**/*", "node_modules/**/*", "package.json"),
      directories = list(buildResources = "resources"),
      publish = NULL,
      asar = FALSE,
      win = platforms$win,
      mac = platforms$mac,
      linux = platforms$linux
    ),
    scripts = list(
      postinstall = "electron-builder install-app-deps",
      preunit = "webpack --config=build/webpack.unit.config.js --env=test",
      unit = "electron-mocha temp/specs.js --renderer --require source-map-support/register",
      pree2e = "webpack --config=build/webpack.app.config.js --env=test && webpack --config=build/webpack.e2e.config.js --env=test",
      e2e = "mocha temp/e2e.js --require source-map-support/register",
      test = "npm run unit && npm run e2e",
      start = "node build/start.js",
      `build:macos` = "electron-builder --macos --dir && npm run build:mac", # force mac
      release = "npm test && webpack --config=build/webpack.app.config.js --env=production && electron-builder -wl"
    )
  )

  opts <- c(opts, deps)

  if (!"win" %in% names(platforms)) {
    opts$build$win <- NULL
  }

  if (!"mac" %in% names(platforms)) {
    opts$build$mac <- NULL
    opts$scripts$`build:macos` <- NULL
  }

  if (!"linux" %in% names(platforms)) {
    opts$build$linux <- NULL
  }

  file_name <- file.path(app_root_path, "package.json")

  jsonlite::write_json(
    opts,
    path = file_name,
    null = "null",
    auto_unbox = TRUE,
    pretty = TRUE
  )
}
