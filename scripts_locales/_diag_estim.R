# Diagnóstico temporal: reproducir el render del panel Estimulación
source("R/00_config.R")
source("R/04_visualizaciones.R")
te <- readRDS("data_processed/tabla_estimulo.rds")
cat("dim tabla_estimulo:", dim(te), "\n")
cat("columnas:", paste(names(te), collapse = ", "), "\n")
for (m in c("prop_con_libros", "media_libros", "prop_juguete_casero",
            "prop_juguete_comprado", "prop_objeto_hogar_exterior")) {
  res <- tryCatch({
    g <- grafico_estimulo(te, m)
    invisible(plotly::plotly_build(g))
    paste0("OK: ", m)
  }, error = function(e) paste0("ERROR en '", m, "': ", conditionMessage(e)))
  cat(res, "\n")
}
