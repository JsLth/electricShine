#' Meta-function
#'
#' @param build_path Path where the build files will be created, preferably points to an empty directory.
#'     Must not contain a folder with the name as what you put for electrify(app_name).
#' @param app_name This will be the name of the executable. It's a uniform type identifier (UTI)
#'    that contains only alphanumeric (A-Z,a-z,0-9), hyphen (-), and period (.) characters.
#'    see https://www.electron.build/configuration/configuration
#'    and https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html#//apple_ref/doc/uid/20001431-102070
#' @param product_name String - allows you to specify a product name for your executable which
#'    contains spaces and other special characters not allowed in the name property.
#'    https://www.electron.build/configuration/configuration
#' @param semantic_version semantic version of your app, as character (not numeric!);
#'     See https://semver.org/ for more info on semantic versioning.
#' @param mran_date MRAN snapshot date, formatted as 'YYYY-MM-DD'
#' @param git_host one of c("github", "gitlab", "bitbucket")
#' @param git_repo GitHub/Bitbucket/GitLab username/repo of your the shiny-app package (e.g. 'chasemc/demoAPP').
#'     Can also use notation for commits/branch (i.e. "chasemc/demoapp@@d81fff0).
#' @param local_package_path path to local shiny-app package, if 'git_package' isn't used
#' @param package_install_opts optional arguments passed to remotes::install_github, install_gitlab, install_bitbucket, or install_local
#' @param dependency_install_opts optional arguments to remotes::install_deps, if NULL then remotes will not pre-install dependencies
#' @param include_remotes Whether or not to copy remotes to the local package path
#' @param function_name the function name in your package that starts the shiny app
#' @param run_build logical, whether to start the build process, helpful if you want to modify anthying before building
#' @param short_description short app description
#' @param cran_like_url url to cran-like repository
#' @param nodejs_path path to nodejs
#' @param nodejs_version nodejs version to install
#' @param permission automatically grant permission to install nodejs and R
#' @param mac_url url to mac OS tar.gz
#' @param r_bitness The bitness of the R installation you want to use (i386 or x64)
#' @param app_args Quoted arguments to the Shiny app, for example `"options = list(port = 1010)"` to set a fixed port.
#'                 These are inserted into a JS string then quoted and executed through shell, so keep in mind complex quoting
#' @param pandoc_version pandoc version to install, as in `as.character(rmarkdown::pandoc_version())`. If null, pandoc won't be installed
#' @param r_version R version to install. If set to 'latest', the latest version will be installed
#' @param author author of the app
#' @param website website of app or company
#' @param license license of the App. Not the full license, only the title (e.g. MIT, or GPLv3)
#' @param keywords Keywords describing the app
#' @param include_rtools Whether or not to include RTools. Requires installr to install. Will increase app size substantially
#' @param conda_env miniconda environment to install
#' @param conda_force Force miniconda to install even if a prior installation is found.
#' @param platforms Named list containing build instructions for `win`, `mac` and `linux`
#' @param deps Named list containing Node.js dependencies
#' @param ... Further arguments for miniconda installation
#'
#' @export
#'
electrify <- function(pkg,
                      app_name = NULL,
                      product_name = NULL,
                      description = NULL,
                      version = NULL,
                      build_path = NULL,
                      function_name = NULL,
                      include_pak = FALSE,
                      app_args = "",
                      do_build = TRUE,
                      permission = FALSE,
                      r_mac_url = NULL,
                      r_bitness = c("x64", "i386"),
                      r_version = NULL,
                      conda_version = NULL,
                      pandoc_version = NULL,
                      python_version = NULL,
                      nodejs_version = NULL,
                      include_rtools = FALSE,
                      copyright = "",
                      author = NULL,
                      website = NULL,
                      license = NULL,
                      keywords = "electron-app",
                      conda_dir = NULL,
                      conda_env = "eshine",
                      conda_yml = NULL,
                      deps = NULL,
                      ...) {



  # Pull from description
  app_name <- app_name %||% pull_from_description("Package")
  product_name <- product_name %||% pull_from_description("Title")
  description <- description %||% pull_from_description(
    "Description",
    postprocessing_function = multiline_indented_to_single_line
  )
  version <- version %||% pull_from_description(
    "Version",
    postprocessing_function =  r_ver_to_semver
  )
  author <- author %||% pull_from_description(
    "Authors@R",
    postprocessing_function = r_authors_string_to_node_first_author
  )
  website <- website %||% pull_from_description(
    "URL",
    postprocessing_function =  function(x) sub(",.*", "", x)
  )
  licence <- licence %||% pull_from_description("License")
  r_mac_url <- r_mac_url %||% "https://mac.r-project.org/el-capitan/R-3.6-branch/R-3.6-branch-el-capitan-sa-x86_64.tar.gz"


  # Fail fast
  .check_build_path_exists(build_path = build_path)
  if (is.null(function_name)) {
    stop("electricShine::electrify() requires you to specify a 'function_name' argument.
         function_name should be the name of the function that starts your package's shiny app.
         e.g. is you have the function myPackage::start_shiny(), provide 'start_shiny'")
  }


  # Copy Electron template into app_root_path
  app_root_path <- file.path(build_path, app_name)
  create_folder(app_root_path)
  copy_template(app_root_path)

  # Install miniconda
  conda_dir <- conda_dir %||% install_miniconda3(version = conda_version)

  check_conda(conda_dir)

  # create new environment
  conda_jumpstart_env(
    conda_dir = conda_dir,
    pkg = pkg,
    conda_env = conda_env,
    r_version = r_version,
    python_version = python_version,
    nodejs_version = nodejs_version,
    pandoc_version = pandoc_version,
    conda_yml = conda_yml
  )

  install_shiny_app(pkg, conda_dir = conda_dir, conda_env = conda_env)

  conda_empty_env(conda_dir = conda_dir, conda_env = "conda-pack")
  conda_pack_dir <- normalizePath(tempdir())

  # Reduce size of conda before packing
  conda_clean(conda_dir)

  conda_pack(
    outdir = conda_pack_dir,
    conda_dir = conda_dir,
    conda_env = conda_env,
    conda_pack_env = "conda-pack"
  )

  conda_pack_gz <- file.path(conda_pack_dir, paste0(conda_env, ".tar.gz"))
  conda_pack_gz <- normalizePath(conda_pack_gz, mustWork = FALSE)

  conda_build_pack <- file.path(build_path, app_name, "build", "pub_conda")
  conda_build_pack <- normalizePath(conda_build_pack, "/")
  if (!dir.exists(conda_build_pack))
    dir.create(conda_build_pack, recursive = TRUE)

  untar(tarfile = conda_pack_gz, exdir = conda_build_pack)
  unlink(conda_pack_gz)

  #conda_unpack(conda_build_pack)

  # Trim R's size
  trim_r(app_root_path = app_root_path)


  # Find Electron app's R's library folder
  libary_path <- pack_find_library_path(app_root_path)

  #
  # # Install pandoc -----
  # if (!is.null(pandoc_version)) {
  #   get_Pandoc(app_root_path, pandoc_version)
  #   add_rstudio_pandoc_to_rprofile_site(app_root_path)
  # }
  #
  # # Install rtools -----
  # if (include_rtools) install_rtools(app_root_path, r_bitness)

  # Install shiny app
  pkg_name <- install_user_app_new(
    pkg = pkg,
    app_root_path = app_root_path,
    include_pak = include_pak
  )


  # Fill in arguments from DESCRIPTION
  formal_names <- names(formals())
  descobj <- NULL
  for (n in formal_names) {
    if (exists(n, inherits = FALSE)) {
      v <- get(n, inherits = FALSE)
      if (inherits(v, "to_pull_from_description")) {
        if (is.null(descobj))
          descobj <- desc::desc(file.path(
            library_path, pkg_name, "DESCRIPTION"
          ))
        assign(n, process_pull_from_description(v, descobj))
      }
    }
  }

  # Transfer icons if present -----------------------------------------------
  electron_build_resources <- system.file(
    "extdata", "icon", package = pkg_name, lib.loc = library_path
  )

  if (nchar(electron_build_resources) != 0) {
    electron_build_resources <- list.files(
      electron_build_resources, full.names = TRUE
    )
    resources <- file.path(app_root_path, "resources")
    dir.create(resources)
    file.copy(from = electron_build_resources, to = resources)
  }


  # Create package.json
  create_package_json(
    app_name = app_name,
    version = version,
    app_root_path = app_root_path,
    description = description,
    product_name = product_name,
    author = author,
    copyright = copyright,
    website = website,
    keywords = keywords,
    license = license,
    deps = deps
  )


  # Add function that runs the shiny app to description.js
  modify_background_js(
    background_js_path = file.path(app_root_path, "src", "background.js"),
    my_package_name = my_package_name,
    function_name = function_name,
    r_path = dirname(library_path),
    app_args = app_args
  )


  # Build the electron app
  if (run_build) {
    run_build_release(
      nodejs_path = paste0(
        conda_build_pack,
        "node", if (identical(get_os(), "win")) ".exe"
      ),
      app_path = app_root_path,
      nodejs_version = nodejs_version
    )

    cat(
      "You should now have both a transferable and",
      "distributable installer Electron app.", "\n"
    )
  } else {
    cat(
      "Build step was skipped. When you are ready to build the",
      "distributable run 'electricShine::runBuild(...)'", "\n"
    )
  }
}
