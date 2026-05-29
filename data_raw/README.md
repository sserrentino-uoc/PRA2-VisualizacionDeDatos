# data_raw

Esta carpeta se usa solo para regenerar el pipeline completo desde microdatos.

Para reproducibilidad académica, copiar aquí:

```text
ch.sav
```

Luego ejecutar desde la raíz del proyecto:

```r
source("run_pipeline_completo.R")
```

No subir esta carpeta a shinyapps.io ni versionarla en GitHub si contiene microdatos. `deploy.R` no incluye `data_raw/` en la publicación.
