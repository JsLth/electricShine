
#' Download miniconda install script
#'
#' @param os this development operating system ("win", "mac", or "lin")
#' @param minconda_version miniconda version
#' @param minconda_tempdir where should the install script be saved?
#'
#' @return
#' @export
#'
download_miniconda3 <- function(os, minconda_version ="latest", minconda_tempdir = NULL) {

  if (is.null(minconda_tempdir)) {
    minconda_tempdir <- tempdir()
  }

  os  <- switch(os,
                win = "Windows",
                mac = "MacOSX",
                unix = "Linux",
                stop('os must be "win", "mac", or "unix"'))

  if (minconda_version == "latest") {
    minconda_version <- "latest"
  } else if (numeric_version(minconda_version)) {
    minconda_version <- minconda_version
  } else {
    stop('minconda_version must be "latest" or semantic version')
  }

  ext <- if (os == "Windows") ".exe" else ".sh"

  miniconda_url <- paste0("https://repo.anaconda.com/miniconda/Miniconda3-",
                          minconda_version,
                          "-",
                          os,
                          "-x86_64",
                          ext)

  outpath <- file.path(minconda_tempdir,
                       "miniconda.sh")
  download.file(miniconda_url,
                outpath)
  message(paste0("Saved to: ",
                 outpath))
  outpath
}

#' Install miniconda3
#'
#' @param miniconda_install_script_path file path of the miniconda installer script
#' @param miniconda_installation_path directory path where conda will be installed
#'
#' @return
#' @export
#'
install_miniconda3 <- function(miniconda_install_script_path,
                               miniconda_installation_path = NULL){
  #TODO, path-exist checks and message
  if (!file.exists(miniconda_install_script_path)){
    stop(paste0("Couldn't find: ", miniconda_install_script_path))
  }

  if (is.null(miniconda_installation_path)){
    temp <- tempdir()
    temp <- file.path(temp, "conda_top_dir")
    temp <- normalizePath(temp,
                          winslash = "/",
                          mustWork = FALSE # previous command adds extra slash so not true path (at least on mac)
    )
    dir.create(temp)
    miniconda_installation_path <- temp
  }

  installation_command <- paste0("sh ",
                                 miniconda_install_script_path,
                                 " -bup",
                                 miniconda_installation_path)
  system(installation_command)

  miniconda_installation_path <- c("miniconda_top_directory" = miniconda_installation_path)
  miniconda_installation_path
}


#' Update conda version
#'
#' @inheritParams conda_params
#'
#' @return
#' @export
#'
conda_update <- function(conda_top_dir){

  conda_path <- find_conda_program(conda_top_dir)

  system2(conda_path,
          c("update -n base -c defaults conda -y"),
          stdout = "")
}
