
#' Install from isolated lib
#'
#' @importFrom utils getFromNamespace
#' @return na
#' @export
#'

install_package <- function(){
  passthr <-  Sys.getenv(c("ESHINE_PASSTHRUPATH"))
  pak_code <-  Sys.getenv(c("ESHINE_pak_code"))
  return_file_path <-  Sys.getenv(c("ESHINE_package_return"))

  if (!nchar(passthr) > 0 ) {
    stop("Empty path")
  }
  passthr <- normalizePath(passthr, winslash = "/")

  load(passthr)

  pak_code <- getFromNamespace(pak_code, ns = "pak")


  z <- do.call(pak_code, passthr)
  # the pak package returns the name of the installed package
  # but when called from system2, at least on mac,
  # this results in a lot of kerfuffle so here we return
  # a string that will we can regex for
  writeLines(z, con = return_file_path)

}
