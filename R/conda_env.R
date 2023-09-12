
conda_empty_env <- function(conda_dir, conda_env = "eshine") {
  run_conda(
    conda = conda_dir,
    args = c("create", "-n", conda_env, "-y")
  )
}

conda_jumpstart_env <- function(conda_dir,
                                pkg,
                                conda_env = "eshine",
                                r_version = NULL,
                                python_version = NULL,
                                nodejs_version = "latest",
                                pandoc_version = NULL,
                                conda_yml = NULL) {
  if (is.null(conda_yml)) {
    r_version <- r_version %||% sprintf(
      "%s.%s", R.version$major, substr(R.version$minor)
    )

    r_version <- .check_dep_version(conda_dir, "r-base", r_version)
    nodejs_version <- .check_dep_version(conda_dir, "nodejs", nodejs_version)
    python_version <- .check_dep_version(conda_dir, "python", python_version)

    args <- list(
      name = conda_env,
      channels = c("conda-forge", "bioconda", "javascript", "nodefaults"),
      dependencies = c(
        paste0("r-base=", r_version),
        paste0("nodejs=", nodejs_version),
        if (!is.null(python_version)) paste0("python=", python_version),
        "r-pak",
        "conda-pack"
      )
    )

    conda_yml <- tempfile(fileext = ".yml")
    yaml::write_yaml(args, conda_yml)
  }

  run_conda(
    conda_dir,
    args = c("env", "create", "-n", conda_env, "-f", conda_yml, "-y", "-q", "-v")
  )
}
