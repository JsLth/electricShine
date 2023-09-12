#' Install conda-pack
#'
#' @inheritParams conda_params
#'
#' @return
#' @export
#'
conda_install_pack <- function(conda_dir,
                               conda_env = NULL,
                               conda_repo = "conda-forge") {

  conda_install(
    conda_dir,
    conda_env = conda_env,
    conda_repo = conda_repo,
    conda_package = "conda-pack"
  )

  version <- processx::run(
    command = "conda-pack",
    args = "--version",
    echo_cmd = FALSE,
    wd = conda_dir
  )$stdout

  cat("Using", version, "\n")
}


#' Package a conda environment with conda-pack
#'
#' @inheritParams conda_params
#'
#' @param outdir directory path where conda-pack 'tar.gz' should be written to
#'
#' @return
#' @export
conda_pack <- function(outdir,
                       conda_dir,
                       conda_env = "eshine",
                       conda_pack_env = "conda-pack") {
  outpath <- file.path(outdir, paste0(conda_env, ".tar.gz"))
  script <- c(
    "activate", conda_env,
    "&&",
    c(
      "conda-pack", "-n", conda_env, "-o", outpath,
      "--dest-prefix", file.path(outdir, "pub_conda")
    )
  )

  run_conda(conda = conda_dir, args = script)
}

# https://gist.github.com/pmbaumgartner/2626ce24adb7f4030c0075d2b35dda32
conda_unpack <- function(conda_pack_dir) {
  is_windows <- identical(get_os(), "win")
  wd <- if (is_windows) {
    file.path(conda_pack_dir, "Scripts")
  } else {
    file.path(conda_pack_dir, "bin")
  }

  processx::run(
    command = paste0("activate", if (is_windows) ".bat"),
    args = "",
    wd = wd,
    echo_cmd = TRUE
  )
}
