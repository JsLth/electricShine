#' Install R package within conda
#'
#' @inheritParams conda_params
#'
#' @param r_package_name name of package to install
#'
#' @return
#' @export
#'
install_r_packages <- function(r_package_name,
                               r_package_repo="https://cran.r-project.org",
                               conda_dir,
                               conda_env = "eshine"){

  #Issue with conda:  https://github.com/conda/conda/issues/9959

  script <- sprintf(
    "install.packages('%s', repos = '%s'",
    r_package_name, r_package_repo
  )

  script <- c(
    "Rscript", "-e", script,
    file.path(conda_dir, "bin", "activate"),
    file.path(conda_dir, "envs", conda_env),
    " && ", script, " && ",
    file.path(conda_dir, "bin", "deactivate")
  )

  processx::run(
    command = script_prefix(),
    args = script,
    error_on_status = TRUE,
    spinner = TRUE,
    echo_cmd = TRUE
  )
}


#' Currently broken, installs to local r need to fix env-vars like in previous release
#'
#' @inheritParams conda_params
#' @param repo_location {remotes} package function, one of c("github", "gitlab", "bitbucket", "local")
#' @param repo e.g. if repo_location is github: "chasemc/demoApp" ; if repo_location is local: "C:/Users/chase/demoApp"
#' @param dependencies_repo cran-like repo to install R package dependencies from
#' @param package_install_opts optional arguments passed to remotes::install_github, install_gitlab, install_bitbucket, or install_local
#'
#' @return
#' @export
install_shiny_app <- function(package, conda_dir, conda_env = "eshine") {
  script <- deparse(quote(pak::pkg_install(package)))
  script <- gsub("package", paste0('"', package, '"'), script, fixed = TRUE)
  script <- c("Rscript",  "-e", script)
  script <- c(
    "activate", conda_env, # activate environment
    "&&", script, "&&", # install shiny app
    conda_exec(), "deactivate" # deactivate environment
  )

  run_conda(conda = conda_dir, args = script)
}

