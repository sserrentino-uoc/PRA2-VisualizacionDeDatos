# =========================================================
# PRA2 - Visualización de Datos
# DEPLOY ULTRA LIMPIO a shinyapps.io evitando renv.lock
#
# Ejecutar desde la carpeta raíz del proyecto:
#   source("deploy.R")
#
# Este script NO despliega desde la sesión RStudio actual.
# Crea una carpeta runtime limpia y lanza un Rscript --vanilla
# desde esa carpeta, sin .Rprofile ni renv.lock.
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
  "data_processed/diccionario_variables.csv",
  "docs/DECLARACION_USO_IA.md",
  "docs/INSTRUCCIONES_SUBIDA_SHINYAPPS.md",
  "docs/GUION_VIDEO_4_6_MIN.md",
  "docs/REVISION_CODIGO_FINAL.md",
  "docs/VALIDACION_PYTHON_VS_R.md",
  "docs/RESULTADOS_Y_CONCLUSIONES.md",
  "docs/ANEXO_METODOLOGICO_APA7.md",
  "docs/CHECKLIST_ENTREGA.md"
)

missing_files <- runtime_files[!file.exists(runtime_files)]
if (length(missing_files) > 0) {
  stop("Faltan archivos necesarios para publicar: ", paste(missing_files, collapse = ", "), call. = FALSE)
}

deploy_dir <- file.path(tempdir(), "PRA2_VisualizacionDeDatos_runtime_sin_renv")
unlink(deploy_dir, recursive = TRUE, force = TRUE)
dir.create(deploy_dir, recursive = TRUE, showWarnings = FALSE)

for (f in runtime_files) {
  target <- file.path(deploy_dir, f)
  dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
  ok <- file.copy(f, target, overwrite = TRUE)
  if (!ok) stop("No se pudo copiar al bundle temporal: ", f, call. = FALSE)
}

# Defensa explícita: no debe existir renv ni perfiles en runtime.
unlink(file.path(deploy_dir, "renv.lock"), force = TRUE)
unlink(file.path(deploy_dir, "renv"), recursive = TRUE, force = TRUE)
unlink(file.path(deploy_dir, ".Rprofile"), force = TRUE)
unlink(file.path(deploy_dir, ".Rproj.user"), recursive = TRUE, force = TRUE)

# Script que se ejecutará en una sesión R completamente nueva.
child_script <- file.path(deploy_dir, "_deploy_child_no_renv.R")
writeLines(c(
  "Sys.setenv(RENV_CONFIG_AUTOLOADER_ENABLED = 'FALSE')",
  "Sys.unsetenv('RENV_PROJECT')",
  "Sys.unsetenv('RENV_PROFILE')",
  "options(renv.config.autoloader.enabled = FALSE)",
  "if (!requireNamespace('rsconnect', quietly = TRUE)) stop('Falta rsconnect en esta instalación de R.')",
  "source('validate_runtime_files.R', encoding = 'UTF-8')",
  "deps <- rsconnect::appDependencies(appDir = getwd())",
  "cat('Dependencias detectadas en sesión limpia:\n')",
  "print(deps[, c('Package', 'Version', 'Source')], row.names = FALSE)",
  "required <- c('shiny','ggplot2','plotly','DT','dplyr','scales','htmltools','htmlwidgets','jsonlite')",
  "missing <- setdiff(required, deps$Package)",
  "if (length(missing) > 0) stop(paste('rsconnect NO detectó:', paste(missing, collapse = ', ')))",
  "rsconnect::deployApp(appDir = getwd(), appPrimaryDoc = 'app.R', appName = 'PRA2-VisualizacionDeDatos', forceUpdate = TRUE)"
), con = child_script, useBytes = TRUE)

message("Runtime limpio creado en: ", deploy_dir)
message("Archivos runtime incluidos: ", length(runtime_files))
message("IMPORTANTE: el deploy se lanzará en Rscript --vanilla desde la carpeta runtime, para evitar renv.lock.")

rscript <- file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
if (!file.exists(rscript)) {
  stop("No se encontró Rscript en: ", rscript, call. = FALSE)
}

old_wd <- getwd()
on.exit(setwd(old_wd), add = TRUE)
setwd(deploy_dir)

status <- system2(
  rscript,
  args = c("--vanilla", shQuote(child_script)),
  stdout = "",
  stderr = ""
)

if (!identical(status, 0L)) {
  stop(
    "El deploy en sesión limpia falló. Revisar mensajes anteriores. ",
    "Si vuelve a aparecer 'Capturing R dependencies from renv.lock', no se está ejecutando este deploy.R.",
    call. = FALSE
  )
}

message("Deploy finalizado desde sesión limpia.")
