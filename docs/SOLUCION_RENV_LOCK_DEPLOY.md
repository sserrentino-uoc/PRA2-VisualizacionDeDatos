# Solución al problema `shiny package was not found in the library`

El log mostró que shinyapps.io seguía usando `renv.lock` y encontraba una sola dependencia, aunque `rsconnect::appDependencies()` detectara correctamente `shiny`, `ggplot2`, `plotly`, `DT`, `dplyr`, etc.

La causa operativa es que la sesión de RStudio estaba contaminada por un proyecto `renv` o por un `renv.lock` externo. Por eso, el deploy correcto debe ejecutarse desde una sesión R limpia.

El archivo `deploy.R` de esta versión:

1. Crea una carpeta temporal limpia.
2. Copia solo archivos runtime.
3. Borra cualquier `renv.lock`, `renv/`, `.Rprofile` o `.Rproj.user`.
4. Lanza un `Rscript --vanilla` nuevo desde esa carpeta.
5. Valida que `shiny` aparezca en las dependencias.
6. Despliega desde esa sesión limpia.

## Comando correcto

```r
source("deploy.R")
```

## Señal de que funcionó

En el log de deploy ya no debe aparecer:

```text
Capturing R dependencies from renv.lock
Found 1 dependency
shiny version: (none)
```

Debe aparecer una lista de dependencias que incluya `shiny`.
