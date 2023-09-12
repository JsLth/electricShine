#' Install a conda package
#'
#' @inheritParams conda_params
#'
#' @return
#' @export
#'
conda_install <- function(conda_dir,
                          conda_package,
                          conda_env = "eshine",
                          conda_repo = NULL) {
  if (!file.exists(conda_dir)) {
    stop(paste("Couldn't find:", conda_dir))
  }

  conda_options <- c("install", "-q", "-v", "-y", conda_package)

  if (!is.null(conda_repo)) {
    conda_options <- c(conda_options, "-c", conda_repo)
  }

  if (!is.null(conda_env)) {
    conda_options <- c(conda_options, "-n", conda_env)
  }

  cat(sprintf(
    "Installing %s from %s in environment %s\n",
    conda_package, conda_repo, conda_env
  ))

  run_conda(
    conda = conda_dir,
    args = conda_options,
    error_on_status = TRUE
  )
}


#' Install R from conda
#'
#' @inheritParams conda_params
#' @param r_version semantic version of R to install (e.g. "4.0")
#'
#' @return
#' @export
#'
conda_install_r <- function(conda_dir,
                            conda_env = "eshine",
                            conda_repo = "conda-forge",
                            r_version = NULL) {
  if (is.null(r_version)) {
    # Use the version of R used to build the app
    r_version <- paste0(R.Version()$major, "." , substr(R.version$minor, 1, 1))
  }

  cat("Install R into conda environment:", "\n")

  conda_install(
    conda_dir = conda_dir,
    conda_env = conda_env,
    conda_repo = conda_repo,
    conda_package = paste0("r-base=", r_version)
  )
}


#' Install Node.js from conda
#'
#' @inheritParams conda_params
#' @param nodejs_version semantic version of nodejs to install (e.g. :15.13.0")
#'
#' @return
#' @export
#'
conda_install_nodejs <- function(conda_dir,
                                 conda_repo = "conda-forge",
                                 conda_env = "eshine-nodejs",
                                 nodejs_version = "latest") {
  message("Install nodejs into conda environment:")
  conda_install(
    conda_dir = conda_dir,
    conda_env = conda_env,
    conda_repo = conda_repo,
    conda_package = paste0("nodejs=", nodejs_version)
  )
}
