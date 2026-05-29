# =========================================================
# PRA2 - Visualización de Datos
# Deploy LIMPIO, seguro y con verificación de dependencias a shinyapps.io
#
# Ejecutar desde la carpeta raíz del proyecto:
#   source("deploy.R")
# =========================================================

if (!requireNamespace("rsconnect", quietly = TRUE)) {
  stop("Falta instalar rsconnect. Ejecutar install.packages('rsconnect').", call. = FALSE)
}

source("validate_runtime_files.R", encoding = "UTF-8")

runtime_files <- c(
  "app.R",
  "DESCRIPTION",
  "README.md",
  "validate_runtime_files.R",
  "R/00_config.R",
  "R/04_visualizaciones.R",
  "www/styles.css",
  "data_processed/kpis.csv",
  "data_processed/tabla_crecimiento.csv",
  "data_processed/tabla_estimulo.csv",
  "data_processed/tabla_iip.csv",
  "data_processed/tabla_iip_actividad.csv",
  "data_processed/calidad_variables.csv",
  "data_processed/decisiones_limpieza.csv",
  "data_processed/diccionario_variables.csv"
)

missing_files <- runtime_files[!file.exists(runtime_files)]
if (length(missing_files) > 0) {
  stop("Faltan archivos necesarios para publicar: ", paste(missing_files, collapse = ", "), call. = FALSE)
}

# Crear carpeta temporal limpia para deployment -------------------------
deploy_dir <- file.path(tempdir(), "PRA2_VisualizacionDeDatos_runtime_clean")
unlink(deploy_dir, recursive = TRUE, force = TRUE)
dir.create(deploy_dir, recursive = TRUE, showWarnings = FALSE)

for (f in runtime_files) {
  target <- file.path(deploy_dir, f)
  dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
  ok <- file.copy(f, target, overwrite = TRUE)
  if (!ok) stop("No se pudo copiar al bundle temporal: ", f, call. = FALSE)
}

# Defensa adicional: borrar cualquier lock/perfil que hubiera entrado por error
unlink(file.path(deploy_dir, "renv.lock"), force = TRUE)
unlink(file.path(deploy_dir, "renv"), recursive = TRUE, force = TRUE)
unlink(file.path(deploy_dir, ".Rprofile"), force = TRUE)
unlink(file.path(deploy_dir, ".Rproj.user"), recursive = TRUE, force = TRUE)

message("Bundle temporal limpio creado en: ", deploy_dir)
message("Archivos incluidos en deployment: ", length(runtime_files))

# Verificación crítica: rsconnect debe detectar shiny y sus dependencias
# Si no detecta shiny, shinyapps.io desplegará pero la app no arrancará.
deps <- rsconnect::appDependencies(appDir = deploy_dir, appFiles = runtime_files)
message("Dependencias detectadas por rsconnect:")
print(deps[, c("Package", "Version", "Source")], row.names = FALSE)

required_runtime_packages <- c("shiny", "ggplot2", "plotly", "DT", "dplyr", "scales", "htmltools", "htmlwidgets", "jsonlite")
missing_detected <- setdiff(required_runtime_packages, deps$Package)
if (length(missing_detected) > 0) {
  stop(
    "rsconnect NO detectó paquetes runtime críticos: ",
    paste(missing_detected, collapse = ", "),
    ". No se publica para evitar una app rota en shinyapps.io. ",
    "Revisar que app.R tenga library(...) explícitos al inicio.",
    call. = FALSE
  )
}

# Desplegar desde carpeta limpia ----------------------------------------
rsconnect::deployApp(
  appDir = deploy_dir,
  appFiles = runtime_files,
  appPrimaryDoc = "app.R",
  appName = "PRA2-VisualizacionDeDatos",
  forceUpdate = TRUE
)
