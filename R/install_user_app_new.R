#' Install shiny app package and dependencies
#'
#' @param library_path path to the new Electron app's R's library folder
#' @param repo_location {remotes} package function, one of c("github", "gitlab", "bitbucket", "local")
#' @param repo e.g. if repo_location is github: "chasemc/demoApp" ; if repo_location is local: "C:/Users/chase/demoApp"
#' @param repos cran like repository package dependencies will be retrieved from
#' @param package_install_opts further arguments to remotes::install_github, install_gitlab, install_bitbucket, or install_local
#' @param dependency_install_opts optional arguments to remotes::install_deps, if NULL then remotes will not pre-install dependencies
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
install_user_app_new <- function(library_path = NULL,
                             repo_location = "github",
                             repo = "chasemc/IDBacApp",
                             repos = cran_like_url,
                             package_install_opts = NULL,
                             dependency_install_opts = NULL,
                             r_bitness = "x64",
                             include_remotes = FALSE,
                             remotes_opts = NULL){

  accepted_sites <- c("github", "gitlab", "bitbucket", "local")

  if (is.null(library_path)) {
    stop("install_user_app() requires library_path to be set.")
  }

  if (!dir.exists(library_path)) {
    stop("install_user_app() library_path wasn't found.")
  }

  if (length(repo_location) != 1L) {
    stop(glue::glue("install_user_app(repo_location) must be character vector of length 1"))
  }

  if (!repo_location %in% accepted_sites) {
    stop(glue::glue("install_user_app(repo_location) must be one of: {accepted_sites}"))
  }

  if (!nchar(repo) > 0) {
    # TODO: Maybe make this a regex?
    stop("install_user_app(repo) must be character with > 0 characters")
  }
  if(!is.null(dependency_install_opts) & repo_location != "local"){
    stop("Remotes only offers separate dependency install for local packages!")
  }
  if (!is.null(package_install_opts)) {
    if (!is.list(package_install_opts)) {
      stop("package_install_opts  must be a list of arguments.")
    }
  }
  remotes_code <- as.character(glue::glue("install_{repo_location}"))



  repo <- as.list(repo)

  passthr <- c(repo, repos = repos,
               c(package_install_opts,
                 list(force = TRUE,
                      lib = library_path)
               )
  )
  if(!is.null(dependency_install_opts)){
    dependency_install_opts <- c(repo, repos = repos,
                                 c(dependency_install_opts,
                                   list(force = TRUE,
                                        lib = library_path)
                                 )
    )
  }
  
  
  os <- electricShine::get_os()

  if (identical(os, "win")) {
    rscript_path <- file.path(dirname(library_path),
                              "bin",
                              r_bitness,
                              "Rscript.exe")
  }

  if (identical(os, "mac")) {
    rscript_path <- file.path(dirname(library_path),
                              "bin",
                              "R")
  }

  if (identical(os, "unix")) {
    stop("electricShine is still under development for linux systems")

  }


  if(include_remotes){
    remotes_location <- library_path
  }else{
    remotes_location <- file.path(tempdir(),
                                    "electricShine",
                                    "templib")
  }
   
  remotes_library <- copy_remotes_package(remotes_location)

  electricshine_library <- installed.packages()["electricShine", "LibPath"]
  # We're not using copy_electricshine_package() since that isn't necessary
  
  # Don't mess about with the environment
  # This causes bugs when you're running 32-bits R but installing on 64-bits R or the opposite
  
  tmp_file2 <- tempfile()
  file.create(tmp_file2)
  Sys.setenv(ESHINE_package_return=tmp_file2)
  
  arguments <- list(
    libpaths = c(library_path, remotes_library),
    electricshine_library = electricshine_library,
    passthr = passthr,
    ESHINE_remotes_code=remotes_code,
    ESHINE_package_return=tmp_file2,
    dependency_install_opts = dependency_install_opts,
    remotes_location = remotes_location
  )
  
  message("Installing your Shiny package into electricShine framework.")

  system_install_pkgs_new(rscript_path, arguments)

  message("Finshed: Installing your Shiny package into electricShine framework")

  # TODO: break into unit-testable function
  user_pkg <- readLines(tmp_file2)

  return(user_pkg)
}




#' Copy {remotes} package to an isolated folder.
#'    This is necessary to avoid dependency-install issues
#'
#' @return path of new {remotes}-only library
copy_remotes_package <- function(new_path = file.path(tempdir(), "electricShine", "templib")){
  remotes_path <- system.file(package = "remotes")

  if(!file.exists(new_path)) dir.create(new_path, recursive = T)

  file.copy(remotes_path,
            new_path,
            recursive = TRUE,
            copy.mode = F)

  test <- file.path(new_path,
                    "remotes")
  if (!file.exists(test)) {
    stop("Wasn't able to copy remotes package.")
  }
  normalizePath(new_path,
                winslash = "/")
}


#' Copy {electricShine} package to an isolated folder.
#'    This is necessary to avoid dependency-install issues
#'
#' @return path of new {electricShine}-only library
copy_electricshine_package <- function(){
  remotes_path <- system.file(package = "electricShine")

  new_path <- file.path(tempdir(),
                        "electricShine")
  dir.create(new_path)

  new_path <- file.path(tempdir(),
                        "electricShine",
                        "templib")
  dir.create(new_path)

  file.copy(remotes_path,
            new_path,
            recursive = TRUE,
            copy.mode = F)

  test <- file.path(new_path,
                    "electricShine")
  if (!file.exists(test)) {
    stop("Wasn't able to copy electricShine package.")
  }
  invisible(normalizePath(new_path,
                          winslash = "/"))
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
