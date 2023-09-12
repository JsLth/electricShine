#' Create an electron-builder release
#'
#' @param nodejs_path parent folder of node.exe (~nodejs_path/node.exe)
#' @param app_path path to new electron app top directory
#' @param nodejs_version for checking if nodejs is functional
#'
#' @return nothing, used for side-effects
#' @export
#'
run_build_release <- function(nodejs_path, app_path) {
  npm_path <- .check_npm_works(node_top_dir = nodejs_path)

  if (isFALSE(npm_path)) {
    stop("First point nodejs_path to a functional version of nodejs.")
  }

  cat("Creating app...\n")

  # electron-packager <sourcedir> <appname> --platform=<platform> --arch=<arch> [optional flags...]
  # npm start --prefix path/to/your/app
  cat(paste0(
    "Installing npm dependencies for the installation process.",
    "These are specfied in 'package.json'. Also this step can",
    "take a few minutes.\n"
  ))

  code <- processx::run(
    command = quoted_npm_path,
    args = c("install", "--scripts-prepend-node-path"),
    wd = quoted_app_path,
    echo = TRUE,
    echo_cmd = TRUE,
    spinner = TRUE
  )$status

  if (!identical(code, 0L)) {
    stop("Installation failed.")
  }

  cat("Building your Electron app.\n")

  code <- processx::run(
    command = quoted_npm_path,
    args = c("run", "release", "--scripts-prepend-node-path"),
    wd = quoted_app_path,
    echo = TRUE,
    echo_cmd = TRUE,
    spinner = TRUE
  )$status

  if (!identical(code, 0L)) {
    stop("Installation failed.")
  }
}
