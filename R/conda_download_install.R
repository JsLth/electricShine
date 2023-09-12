
#' Download miniconda install script
#'
#' @param os this development operating system ("win", "mac", or "lin")
#' @param minconda_version miniconda version
#' @param minconda_tempdir where should the install script be saved?
#'
#' @return
#' @export
#'
download_miniconda3 <- function(version = "latest", dir = NULL) {
  dir <- dir %||% tempdir()

  os  <- switch(get_os(),
    win = "Windows",
    mac = "MacOSX",
    unix = "Linux",
    stop('os must be "win", "mac", or "unix"')
  )

  if (!identical(version, "latest")) {
    version <- numeric_version(version, strict = FALSE)
    if (is.na(version)) {
      stop('minconda_version must be "latest" or semantic version')
    }
  }

  ext <- if (identical(os, "Windows")) ".exe" else ".sh"

  url <- sprintf(
    "https://repo.anaconda.com/miniconda/Miniconda3-%s-%s-x86_64%s",
    version, os, ext
  )

  outpath <- file.path(dir, paste0("miniconda", ext))
  download.file(url, outpath, mode = "wb")
  cat(paste0("Saved to: ", outpath, "\n"))
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
install_miniconda3 <- function(path = NULL, version = NULL) {
  version <- version %||% "latest"
  installer <- download_miniconda3(version = version)

  if (is.null(path)) {
    path <- tempdir()
    path <- file.path(path, "conda_dir")
    path <- normalizePath(path, winslash = "/", mustWork = FALSE)
    if (!dir.exists(path)) dir.create(path)
  }

  args <- if (identical(get_os(), "win")) {
    if (dir.exists(path))
      unlink(path, recursive = TRUE)
    c("/InstallationType=JustMe", "/AddToPath=0", "/RegisterPython=0",
      "/NoRegistry=1", "/S", paste("/D", utils::shortPathName(path), sep = "="))
  } else if (get_os() %in% c("mac", "unix")) {
    c("-b", if (update) "-u", "-p", shQuote(path))
  } else {
    stopf("unsupported platform %s", shQuote(Sys.info()[["sysname"]]))
  }
  Sys.chmod(installer, mode = "0755")

  if (identical(get_os(), "mac")) {
    old <- Sys.getenv("DYLD_FALLBACK_LIBRARY_PATH")
    new <- if (nzchar(old))
      paste(old, "/usr/lib", sep = ":")
    else "/usr/lib"
    Sys.setenv(DYLD_FALLBACK_LIBRARY_PATH = new)
    on.exit(Sys.setenv(DYLD_FALLBACK_LIBRARY_PATH = old),
            add = TRUE)
  }

  if (identical(get_os(), "win")) {
    installer <- normalizePath(installer)
    status <- processx::run(
      command = basename(installer),
      args = args,
      wd = dirname(installer),
      spinner = TRUE,
      echo = TRUE,
      echo_cmd = TRUE
    )
  }

  if (identical(get_os(), "unix")) {
    bash_path <- Sys.which("bash")
    if (bash_path[1] == "")
      stopf("The miniconda installer requires bash.")
    status <- processx::run(
      command = basename(bash_path[1]),
      args = args,
      wd = dirname(bash_path[1]),
      spinner = TRUE,
      echo = TRUE,
      echo_cmd = TRUE
    )
  }

  conda_update(path)

  path
}


#' Update conda version
#'
#' @inheritParams conda_params
#'
#' @return
#' @export
#'
conda_update <- function(conda_dir) {
  processx::run(
    command = conda_exec(),
    args = c("update", "-n", "base", "-c", "defaults", "conda", "-y"),
    wd = append_dir(conda_dir),
    spinner = TRUE,
    error_on_status = TRUE,
    echo_cmd = TRUE
  )
}
