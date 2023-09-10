install_rtools <- function(app_root_path, r_bitness){

  stopifnot("rtools is Windows-only, cannot install rtools" = R.version$os == "mingw32")
  stopifnot("installr package required to install rtools" = requireNamespace("installr", quietly = TRUE))

  rscript_path <- normalizePath(file.path(app_root_path, "app", "r_lang", "bin", r_bitness, "Rscript.exe"), mustWork = FALSE)
  # R version of the freshly downloaded R
  r_version <- system2(rscript_path, args = "-e cat(as.character(getRversion()))", stdout =  TRUE)

  # Get appropriate rtools url from installr
  rtools_version <- installr:::get_compatible_rtools_version(r_version)
  # To consider: copy relevant functions from installr, since these aren't exported
  download_path <- installr:::get_rtools_url(rtools_version, arch = "x86_64")

  tf <- tempfile(fileext = ".exe")
  # Increase timeout, rtools can be big
  old_timeout <- getOption("timeout")
  options(timeout = max(12000, getOption("timeout")))
  # Download rtools installer
  rtools_installer <- download.file(download_path, tf, mode = "wb")
  destination_path <- normalizePath(file.path(app_root_path, "app","Rtools"), mustWork = FALSE)
  installer_path <- normalizePath(tf, mustWork = FALSE)

  # Install Rtools
  system(glue::glue("{shQuote(installer_path)} /CURRENTUSER /DIR={shQuote(destination_path)} /SILENT /NOICONS"))

  unlink(tf)

  # reset timeout
  options(timeout = old_timeout)

  # Modify rprofile.site with rtools path
  rprofile_site <- file(file.path(app_root_path, "app", "r_lang", "etc", 'Rprofile.site'), open = "at")
  writeLines(
    "Sys.setenv(path = paste(normalizePath(file.path(R.home(), '..', 'Rtools', 'usr', 'bin')), Sys.getenv('PATH'), sep = ';'))",
    rprofile_site
  )
  if(package_version(rtools_version) > package_version("4.0")){
    writeLines(
      "Sys.setenv(path = paste(normalizePath(file.path(R.home(), '..', 'Rtools', 'x86_64-w64-mingw32.static.posix', 'bin')), Sys.getenv('PATH'), sep = ';'))",
      rprofile_site
    )
    # Remove a junction that causes trouble with electron-builder and pray it won't break stuff
    unlink(file.path(destination_path, "usr", "lib", "mxe", "usr", "x86_64-w64-mingw32.static.posix"))
  }else{
    writeLines(
      "Sys.setenv(path = paste(normalizePath(file.path(R.home(), '..', 'Rtools', 'mingw64', 'bin')), Sys.getenv('PATH'), sep = ';'))",
      rprofile_site
    )
  }
  close(rprofile_site)

}
