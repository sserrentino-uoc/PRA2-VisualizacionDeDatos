# Solución definitiva: `The shiny package was not found in the library`

El problema observado en shinyapps.io no era de la lógica de la app sino de detección de dependencias durante el despliegue.

Esta versión fuerza la detección de dependencias de dos formas:

1. `app.R` declara explícitamente al inicio: `library(shiny)`, `library(ggplot2)`, `library(plotly)`, `library(DT)`, `library(dplyr`, `library(scales)`, `library(htmltools)`, `library(htmlwidgets)` y `library(jsonlite)`.
2. `deploy.R` crea un bundle temporal limpio y ejecuta `rsconnect::appDependencies()` antes de publicar. Si `shiny` no aparece en las dependencias detectadas, el script se detiene y no publica una app rota.

Flujo recomendado:

```r
source("validate_runtime_files.R")
shiny::runApp()
source("deploy.R")
```

No usar el botón Publish si hay carpetas viejas, `renv.lock`, `.Rprofile` o archivos de otro proyecto en el directorio.
