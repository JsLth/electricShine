wd <- "~/golembusy"

conda <- file.path(tempdir(), "conda_dir")

if (!dir.exists(file.path(wd, "electron")))
  dir.create(file.path(wd, "electron"))

unlink(file.path(wd, "electron/golembusy"), recursive = TRUE)

options(electricShine_ask = FALSE)

electrify(
  app_name = "golembusy",
  pkg = wd,
  conda_dir = if (dir.exists(conda)) conda,
  product_name = "Golem Busy",
  nodejs_version = "14.17.1",
  python_version = "latest",
  function_name = "run_app",
  build_path = file.path(wd, "electron"),
  r_bitness = "x64",
  r_version = "4.1.3",
  cran_like_url = "https://cran.r-project.org"
)
