# =========================================================
# PRA2 - Visualización de Datos
# Validación previa a ejecución/publicación en shinyapps.io
# Ejecutar desde la carpeta raíz del proyecto.
# =========================================================

required_files <- c(
  "app.R",
  "DESCRIPTION",
  "README.md",
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

missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files) > 0) {
  stop("Faltan archivos: ", paste(missing_files, collapse = ", "), call. = FALSE)
}

read_check_csv <- function(file) {
  df <- read.csv(file, stringsAsFactors = FALSE, check.names = FALSE, fileEncoding = "UTF-8-BOM")
  names(df) <- sub("^\ufeff", "", names(df))
  df
}

check_cols <- function(file, required_cols) {
  df <- read_check_csv(file)
  missing_cols <- setdiff(required_cols, names(df))
  if (length(missing_cols) > 0) {
    stop("Faltan columnas en ", file, ": ", paste(missing_cols, collapse = ", "), call. = FALSE)
  }
  if (nrow(df) == 0) {
    stop("El archivo no tiene filas: ", file, call. = FALSE)
  }
  invisible(TRUE)
}

check_cols("data_processed/kpis.csv", c("registros", "waz_medio", "prop_bajo_peso", "prop_tiene_libros", "iip_medio"))
check_cols("data_processed/tabla_crecimiento.csv", c("region", "sexo", "quintil_riqueza", "edad_grupo", "n", "peso_muestral", "waz_medio", "prop_bajo_peso"))
check_cols("data_processed/tabla_estimulo.csv", c("region", "quintil_riqueza", "n", "peso_muestral", "indicador", "valor", "indicador_label"))
check_cols("data_processed/tabla_iip.csv", c("region", "quintil_riqueza", "educ_madre", "n", "peso_muestral", "iip_medio", "iip_normalizado_medio"))
check_cols("data_processed/tabla_iip_actividad.csv", c("region", "quintil_riqueza", "actividad", "prop_actividad", "n", "peso_muestral"))
check_cols("data_processed/calidad_variables.csv", c("variable", "n", "faltantes", "pct_faltantes"))
check_cols("data_processed/decisiones_limpieza.csv", c("dimension", "problema_detectado", "decision_metodologica", "impacto_en_visualizacion"))
check_cols("data_processed/diccionario_variables.csv", c("variable", "descripcion", "uso"))

message("Validación correcta: la app tiene los archivos y columnas necesarios para ejecutarse/publicarse.")
message("Nota: deploy.R sube solo CSV agregados; no sube data_raw/ ni base_pra2.*.")
