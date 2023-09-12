#' Remove html and pdf files from R installation
#'
#' @param app_root_path path to the copied R installation

#'
#' @return nothing
#' @export
#'
trim_r <- function(app_root_path){
  r_lang_path <- file.path(
    app_root_path,
    "build", "pub_conda", "Lib", "R",
    fsep = "/"
  )

  a <- list.files(r_lang_path, recursive = TRUE, full.names = TRUE)
  pre <- sum(file.size(a))

  # Remove .html
  temp <- list.files(
    path = r_lang_path,
    recursive = TRUE,
    pattern = ".html",
    full.names = TRUE
  )

  removed <- base::file.remove(temp)
  cat(sprintf("Removed %s HTML files from R installation", length(temp)), "\n")

  # Remove .pdf
  temp <- base::list.files(
    r_lang_path,
    recursive = TRUE,
    pattern = ".pdf",
    full.names = TRUE
  )

  removed <- base::file.remove(temp)
  cat(sprintf("Removed %s HTML files from R installation", length(temp)), "\n")

  # Remove .mo
  temp <- base::list.files(
    r_lang_path,
    recursive = TRUE,
    pattern = ".mo",
    full.names = TRUE
  )

  removed <- base::file.remove(temp)
  cat(sprintf("Removed %s translation files from R installation", length(temp)), "\n")
}
