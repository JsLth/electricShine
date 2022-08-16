#' Transforms an R development version (4 dots) to a semver development version (3 dots and a dash)
#'
#' This function does not validate the version, be sure to make sure it's valid
#' The version is expected to be formatted as recommended in [R packages](https://r-pkgs.org/lifecycle.html#version) and as created by `usethis::use_version()`
#'
#' @param r_ver A string containing an R package version, possibly a development version
#'
#' @return A semver version
#' @export
#'
#' @examples
#' r_ver_to_semver("1.0.0") # returns unmodified
#' r_ver_to_semver("0.0.1.9001") # dev version dashed
#' r_ver_to_semver("1") # Not an appropriate R version, no dots added, doesn't result in a valid semver
r_ver_to_semver <- function(r_ver){
  gsub("(^([^\\.]*)\\.([^\\.]*)(\\.)([^\\.]*))\\.(.*)", "\\1-\\6", r_ver)
}

#' Tells electricShine to pull an item from the description, and possibly run through a post processing function
#' This usually isn't done immediately, to use the exact package version that will be provided with the app
#' If you want the result returned immediately (or use a different DESCRIPTION file), you can specify `description_object`, which should be the return of [desc::desc]
#'
#' @param fieldname The field to pull from the description 
#' @param default The default value, if the entry is missing from description
#' @param postprocessing_function A function that takes the description output and returns a string to put in package.json
#' @param description_object An option
#' 
#' @export
#'
#' @examples
#' \dontrun{
#' electrify(
#'    app_name = pull_from_description("Package"),
#'    semantic_version = pull_from_description("Version", r_ver_to_semver),
#'    short_description = pull_from_description("Description")
#' )
#' }
pull_from_description <- function(fieldname, default = "", postprocessing_function = NULL, description_object){
  out <- list(fieldname = fieldname, postprocessing_function = postprocessing_function, default = default)
  class(out) <- "to_pull_from_description"
  if(!missing(description_object)) out <- process_pull_from_description(command = out, description_object = description_object)
  return(out)
}

#' Process a request to pull from description
#' 
#' @param command A command created using [pull_from_description] 
#' @param description_object A package description object created with [desc::desc]
#' @keywords internal
#' @noRd
process_pull_from_description <- function(command, description_object){
  if(!inherits(command, "to_pull_from_description")) return(command)
  value <- description_object$get_field(command$fieldname, default = command$default)
  if(!is.null(command$postprocessing_function)) return(command$postprocessing_function(value))
  return(value)
}

multiline_indented_to_single_line <- function(multiline_string){
  gsub(" (?= )","", gsub("\n ", "", multiline_string, fixed = T), perl = T)
}


#' Parse an R authors string to something fit for package.json
#' npm only does one author, and rest in AUHORS.md or contributor, we only do author here
#' 
#' 
#' @param r_authors_string A scalar R author string. This should contain valid R code and will be evaluated as such.
#'
#' @return A package.json author string
#' @export
#'
#' @examples
#' \dontrun{
#' r_authors_string_to_node_first_author(desc::desc(package = "electricShine")$get_field("Authors@R"))
#' r_authors_string_to_node_first_author(desc::desc(package = "desc")$get_field("Authors@R"))
#' }
r_authors_string_to_node_first_author <- function(r_authors_string){
  authors_obj <- eval(str2expression(r_authors_string))
  first_author <- authors_obj[[1]]
  out <- format(first_author, include = c("given", "family", "email"),
         braces = list(given = "", family = "", email = c("<", ">"),
                       comment = c("(", ")")))
  if("ORCID" %in% names(first_author$comment)){
    out <- glue::glue("{out} (https://orcid.org/{first_author$comment[which.min(names(first_author$comment) == 'ORCID')]})")
  }
  out
}



