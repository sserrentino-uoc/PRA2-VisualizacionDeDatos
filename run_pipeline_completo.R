# =========================================================
# PRA2 - Pipeline completo desde microdatos MICS6
# Ejecutar solo para regenerar data_processed desde data_raw/ch.sav.
# No es necesario para publicar la app en shinyapps.io.
# =========================================================

source("R/00_config.R", encoding = "UTF-8")
source("R/01_preparacion_datos.R", encoding = "UTF-8")
source("R/02_exploracion_calidad.R", encoding = "UTF-8")
source("R/03_tablas_visualizacion.R", encoding = "UTF-8")

message("Pipeline completo ejecutado.")
message("Recordatorio: deploy.R sube solo tablas agregadas runtime; no sube base_pra2.* ni data_raw/.")
