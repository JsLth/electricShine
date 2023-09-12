#' Check internet connection
#'
#' @param url url to check
#'
.ping_url <- function(url){

  if (capabilities("libcurl")) {

    a <- curlGetHeaders(url)

    if (attributes(a)$status != 200L) {
      cat(a)
      stop("provided url was unable to resolve host ")

    }
    cat("----------\n")
    cat(paste0("Connection to: ", url, "\n"))
    cat(a[1:10], "\n")
    cat("----------\n")
  } else {
    warning("libcurl unavailable to check internet.")
  }

}


#' Check if compatible architecture
#'
#' @param arch only used for unit testing
#'
#' @return Stops if unsupported architecture
.check_arch <- function(arch = base::version$arch[[1]]){

  if (arch != "x86_64") {
    base::stop("Unfortunately 32 bit operating system builds are unsupported, if you would like to contribute to support this, that would be cool")
  }

}


#' Check whether build path exists
#'
#' @param build_path build_path
#'
#' @return stops
.check_build_path_exists <- function(build_path){
  if (is.null(build_path)) {
    bstop("'build_path' not provided")
  }

  if (!is.character(build_path)) {
    stop("'build_path' should be character type.")
  }

  if (!dir.exists(build_path)) {
    stop("'build_path' provided, but path wasn't found.")
  }
}

