#' Install from isolated lib
#'
#' @return na
#' @export
#'
install_package_new <- function(arguments) {
  return_file_path <-  arguments$ESHINE_package_return
  is_local <- arguments$is_local
  passthr <- arguments$passthr
  requireNamespace("pak", lib.loc = arguments$pak_location)

  fun <- if (is_local) pak::local_install else pak::pkg_install

  z <- do.call(fun, passthr)$package[1]

  # the remotes package returns the name of the installed package
  # but when called from system2, at least on mac,
  # this results in a lot of kerfuffle so here we return
  # a string that will we can regex for
  writeLines(z, con = return_file_path)
}
