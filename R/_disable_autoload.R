# Presencia de este archivo desactiva el auto-source de Shiny sobre R/.
# Motivo: la carpeta R/ contiene scripts de preparación de datos
# (01_preparacion_datos.R, 02_exploracion_calidad.R, 03_tablas_visualizacion.R)
# que NO deben ejecutarse al arrancar la app. app.R sourcea explícitamente
# solo R/00_config.R y R/04_visualizaciones.R.
