
#' Modify background.js to include the call to the shiny app
#'
#' @param background_js_path path to the final background.js, not the one in inst/...
#' @param my_package_name package name, will be used for namespacing- (e.g. 'dplyr' in 'dplyr::filter()')
#' @param function_name function that runs your shiny app - (e.g. 'filter' in 'dplyr::filter()')
#' @param r_path path from "r_lang" folder to the R/Rscript executable
#' @param r_bitness bitness of R installation, only applicable before R 4.2.0
#' @param app_args arguments to the function that runs your shiny app
#'
#' @return none, side effect
#' @export
#'
modify_background_js <- function(background_js_path,
                                 my_package_name,
                                 function_name,
                                 r_path,
                                 r_bitness = "x64",
                                 python_path = NULL,
                                 app_args){
  if (!file.exists(background_js_path)) {
    stop("modify_background_js() failed because background_js_path didn't point to an existing file.")
  }

  background_js_contents <- readLines(background_js_path)

  if (!is.null(python_path)) {
    PYTHON_PATH <- "python.exe"
  } else {
    PYTHON_PATH <- "null"
  }

  R_SHINY_FUNCTION <- paste0(my_package_name, "::", function_name)
  R_BITNESS <- force(r_bitness)
  APP_ARGS <- force(app_args)
  background_js_contents <- vapply(background_js_contents, function(x) {
    glue::glue(x, .open = "<?<", .close = ">?>")
  }, FUN.VALUE = character(1))

  writeLines(background_js_contents, background_js_path)
}
