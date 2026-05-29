# Instrucciones de subida a shinyapps.io - versión con deploy limpio

## Problema corregido

El log de shinyapps.io mostró:

```text
shiny version: (none)
Error in enforcePackage(name, curVersion): The shiny package was not found in the library.
```

La causa más probable no era la app, sino el despliegue: rsconnect estaba capturando dependencias desde un `renv.lock` local incompleto y solo detectó una dependencia. Por eso shinyapps.io no instaló `shiny`.

## Forma correcta de publicar esta versión

Abrir RStudio en la carpeta raíz del proyecto, donde está `app.R`, y ejecutar:

```r
install.packages(c("shiny", "ggplot2", "plotly", "DT", "dplyr", "scales", "rsconnect"))
source("validate_runtime_files.R")
source("deploy.R")
```

`deploy.R` crea una carpeta temporal limpia con solo los archivos necesarios para ejecutar la app y despliega desde allí. No sube `renv.lock`, no sube `renv/`, no sube `data_raw/` y no sube microdatos.

## No usar por ahora

No usar el botón **Publish** de RStudio hasta que la app ya haya quedado funcionando con `source("deploy.R")`. El botón Publish podría tomar archivos locales sobrantes, incluyendo `renv.lock`.

## Validación posterior

Luego abrir en incógnito:

https://sserrentino.shinyapps.io/PRA2-VisualizacionDeDatos/

Y revisar logs:

```r
rsconnect::showLogs(appName = "PRA2-VisualizacionDeDatos", account = "sserrentino", streaming = FALSE)
```

El log ya no debería mostrar `shiny version: (none)`.
