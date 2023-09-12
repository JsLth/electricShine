run_conda <- function(conda = "conda",
                      bin = TRUE,
                      echo = TRUE,
                      echo_cmd = TRUE,
                      spinner = TRUE,
                      ...) {
  processx::run(
    command = conda_exec(bin = bin),
    wd = if (!conda %in% "conda" && file.exists(conda)) {
      append_dir(conda, bin = bin)
    },
    echo = echo,
    echo_cmd = echo_cmd,
    spinner = spinner,
    ...
  )
}


conda_exec <- function(bin = TRUE) {
  if (get_os() == "win") {
    if (bin) "conda.bat" else "_conda.exe"
  } else {
    "conda"
  }
}


append_dir <- function(conda_dir, bin = TRUE) {
  if (bin) {
    if (get_os() == "win") {
      conda_dir <- file.path(conda_dir, "condabin")
    } else {
      conda_dir <- file.path(conda_dir, "bin")
    }
  }

  conda_dir
}


#' Check that conda works
#'
#' @inheritParams conda_params
#'
#' @return
check_conda <- function(conda_dir){
  res <- run_conda(conda = conda_dir, args = "-V", echo = FALSE)
  res <- res$stdout

  if (grepl("conda", res)) {
    cat(paste0("Using: ", res, "\n"))
  } else {
    stop("Something went wrong detecting conda.")
  }
}


script_prefix <- function() {
  switch(get_os(),
    win = "cmd",
    mac = "source",
    unix = "",
    stop('os must be "win", "mac", or "unix"')
  )
}


.check_dep_version <- function(conda_dir, package, version) {
  if (is.null(version)) return(invisible())
  cat(sprintf("Searching for %s versions on conda-forge", package), "\n")
  search_r <- run_conda(
    conda = conda_dir,
    args = c("search", "-c", "conda-forge", package, "--json"),
    echo = FALSE
  )
  search_r <- jsonlite::fromJSON(search_r$stdout)
  r_ver <- search_r[[package]]$version

  if (identical(version, "latest")) {
    version <- r_ver[length(r_ver)]
  } else if (!version %in% r_ver) {
    stop(sprintf("%s version %s not found.", package, version))
  }

  cat(sprintf("Using %s version %s", package, version), "\n\n")

  version
}


conda_clean <- function(conda_dir) {
  info <- run_conda(conda_dir, args = c("clean", "--all", "--json", "-y"))
  info <- jsonlite::fromJSON(info$stdout)

  for (type in c("logfiles", "packages", "tarballs", "tempfiles")) {
    total <- info[[type]]$total_size
    quant <- info[[type]]
    if (length(quant) > 1)
      quant <- info[[1]]

    if (is.null(total) && !is.null(quant)) {
      cat(sprintf(
        "Removed %s %ss for a total size reduction of %s\n",
        quant, type, total
      ))
    }
  }
}


"%||%" <- function(x, y) {
  if (is.null(x)) y else x
}


pack_find_library_path <- function(app_root_path) {
  if (identical(get_os(), "win")) {
    file.path(
      app_root_path, "build", "pub_conda", "Library", "R", fsep = "/"
    )
  } else if (identical(get_os(), "mac")) {
    library_path <- file.path(
      app_root_path, "build", "pub_conda", "Library",
      "Frameworks", "R.framework", "Versions"
    )

    library_path <-  list.dirs(library_path, recursive = FALSE)
    library_path <- library_path[grep(
      "\\d+\\.(?:\\d+|x)(?:\\.\\d+|x){0,1}", library_path
    )][[1]]

    file.path(library_path, "Resources/library", fsep = "/")
  }
}
