# Diagnóstico temporal: reproducir el error de grafico_crecimiento
source("R/00_config.R")
source("R/04_visualizaciones.R")
d <- readRDS("data_processed/tabla_crecimiento.rds")
cat("class(edad_grupo):", class(d$edad_grupo), "\n")
g <- grafico_crecimiento(d)
res <- tryCatch({
  print(g)
  "PLOT_OK"
}, error = function(e) paste("PLOT_ERROR:", conditionMessage(e)))
cat(res, "\n")
