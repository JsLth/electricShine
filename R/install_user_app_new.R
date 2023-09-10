#' Install shiny app package and dependencies
#'
#' @param library_path path to the new Electron app's R's library folder
#' @param repo e.g. if repo_location is github: "chasemc/demoApp" ; if repo_location is local: "C:/Users/chase/demoApp"s
#' @param r_bitness The bitness of the R installation you want to use (i386 or x64)
#' @importFrom utils installed.packages
#'
#' @return App name

#' @export
#'
#' @examples
#'
#'\dontrun{
#'
#' install_user_app(repo_location = "github",
#'                  repo = "chasemc/demoApp@@d81fff0")
#'
#' install_user_app(repo_location = "github",
#'                  repo = "chasemc/demoApp@@d81fff0",
#'                  auth_token = "my_secret_token")
#'
#' install_user_app(repo_location = "bitbucket",
#'                  repo = "chasemc/demoApp",
#'                  auth_user = bitbucket_user(),
#'                  password = bitbucket_password())
#'
#' install_user_app(repo_location = "gitlab",
#'                  repo = "chasemc/demoApp",
#'                  auth_token = "my_secret_token")

#' install_user_app(repo_location = "local",
#'                  repo = "C:/Users/chase/demoApp",
#'                  build_vignettes = TRUE)
#' }
#'
install_user_app_new <- function(repo = ".",
                                 library_path = NULL,
                                 r_bitness = "x64",
                                 include_pak = FALSE){

  accepted_sites <- c("github", "gitlab", "bitbucket", "local")

  if (is.null(library_path)) {
    stop("install_user_app() requires library_path to be set.")
  }

  if (!dir.exists(library_path)) {
    stop("install_user_app() library_path wasn't found.")
  }

  if (!nchar(repo) > 0) {
    stop("install_user_app(repo) must be character with > 0 characters")
  }

  passthr <- list(
    pkg = repo,
    lib = library_path,
    upgrade = FALSE,
    ask = FALSE,
    dependencies = "hard"
  )

  os <- electricShine::get_os()

  if (identical(os, "win")) {
    rscript_path <- file.path(
      dirname(library_path),
      "bin",
      r_bitness,
      "Rscript.exe"
    )
  }

  if (identical(os, "mac")) {
    rscript_path <- file.path(dirname(library_path), "bin", "R")
  }

  if (identical(os, "unix")) {
    stop("electricShine is still under development for linux systems")

  }


  if (include_pak) {
    pak_location <- library_path
  } else{
    pak_location <- file.path(tempdir(), "electricShine", "templib")
  }

  pak_library <- copy_pak_package(pak_location)

  electricshine_library <- installed.packages()["electricShine", "LibPath"]
  # We're not using copy_electricshine_package() since that isn't necessary

  # Don't mess about with the environment
  # This causes bugs when you're running 32-bits R but installing on 64-bits R or the opposite

  tmp_file2 <- tempfile()
  file.create(tmp_file2)
  Sys.setenv(ESHINE_package_return = tmp_file2)

  arguments <- list(
    libpaths = c(library_path, pak_library),
    electricshine_library = electricshine_library,
    passthr = passthr,
    ESHINE_package_return = tmp_file2,
    pak_location = pak_location
  )

  message("Installing your Shiny package into electricShine framework.")

  system_install_pkgs_new(rscript_path, arguments)

  message("Finshed: Installing your Shiny package into electricShine framework")

  # TODO: break into unit-testable function
  user_pkg <- readLines(tmp_file2)

  return(user_pkg)
}




#' Copy {pak} package to an isolated folder.
#'    This is necessary to avoid dependency-install issues
#'
#' @return path of new {pak}-only library
copy_pak_package <- function(new_path = file.path(tempdir(), "electricShine", "templib")){
  pak_path <- system.file(package = "pak")

  if (!file.exists(new_path)) dir.create(new_path, recursive = TRUE)

  file.copy(pak_path,
            new_path,
            recursive = TRUE,
            copy.mode = F)

  test <- file.path(new_path, "pak")
  if (!file.exists(test)) {
    stop("Wasn't able to copy pak package.")
  }
  normalizePath(new_path, winslash = "/")
}


#' Copy {electricShine} package to an isolated folder.
#'    This is necessary to avoid dependency-install issues
#'
#' @return path of new {electricShine}-only library
copy_electricshine_package <- function(){
  es_path <- system.file(package = "electricShine")

  new_path <- file.path(tempdir(), "electricShine")
  dir.create(new_path)

  new_path <- file.path(tempdir(), "electricShine", "templib")
  dir.create(new_path)

  file.copy(es_path,
            new_path,
            recursive = TRUE,
            copy.mode = FALSE)

  test <- file.path(new_path, "electricShine")
  if (!file.exists(test)) {
    stop("Wasn't able to copy electricShine package.")
  }
  invisible(normalizePath(new_path, winslash = "/"))
}



#' Run package installation using the newly-installed R
#'
#' @param rscript_path path to newly-installed R's executable
#' @param arguments arguments to the install script
#'
#' @return nothing
#'
system_install_pkgs_new <- function(rscript_path, arguments){
  arg_file <- tempfile()
  save(arguments, file = arg_file)
  r_file <- tempfile()
  cat(file = r_file, # To consider: make this a separate file
      "args = commandArgs(trailingOnly=TRUE)\n",
      "load(args[1])\n",
      "library(electricShine, lib.loc = arguments$electricshine_library)\n",
      ".libPaths(arguments$libpaths)\n",
      "electricShine::install_package_new(arguments)"
      )
  system2(rscript_path,
            shQuote(c(r_file, arg_file)),
          wait = TRUE,
          stdout = "")
  unlink(r_file)
  unlink(arg_file)
}
