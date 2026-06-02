# PRA2 — Visualización de Datos · UOC

> **Visualización de los estándares de crecimiento y el involucramiento paterno en la primera infancia.**
> Integración de microdatos MICS6 Argentina 2019–2020, indicadores antropométricos provistos por la encuesta y corresponsabilidad paterna declarada.

<p align="center">
  <a href="https://sserrentino.shinyapps.io/PRA2-VisualizacionDeDatos/">
    <img src="https://img.shields.io/badge/App-shinyapps.io-2aa198?style=flat-square&logo=rstudioide&logoColor=white" alt="App pública" />
  </a>
  <img src="https://img.shields.io/badge/R-4.3+-276DC3?style=flat-square&logo=r&logoColor=white" alt="R 4.3+" />
  <img src="https://img.shields.io/badge/Shiny-1.10+-1a5cba?style=flat-square&logo=rstudioide&logoColor=white" alt="Shiny" />
  <img src="https://img.shields.io/badge/Plotly-2.x-3f4f75?style=flat-square&logo=plotly&logoColor=white" alt="Plotly" />
  <img src="https://img.shields.io/badge/ggplot2-3.5+-1f77b4?style=flat-square" alt="ggplot2" />
  <img src="https://img.shields.io/badge/Licencia-MIT-blue?style=flat-square" alt="MIT" />
</p>

---

## Tabla de contenidos

- [Demostración en vivo](#demostración-en-vivo)
- [Resumen del proyecto](#resumen-del-proyecto)
- [Preguntas guía](#preguntas-guía)
- [Indicadores generales](#indicadores-generales)
- [Stack y arquitectura](#stack-y-arquitectura)
- [Cómo ejecutar la app localmente](#cómo-ejecutar-la-app-localmente)
- [Cómo redesplegar a shinyapps.io](#cómo-redesplegar-a-shinyappsio)
- [Estructura del repositorio](#estructura-del-repositorio)
- [Decisiones metodológicas clave](#decisiones-metodológicas-clave)
- [Reproducibilidad](#reproducibilidad)
- [Limitaciones declaradas](#limitaciones-declaradas)
- [Uso de inteligencia artificial](#uso-de-inteligencia-artificial)
- [Autor y contexto académico](#autor-y-contexto-académico)
- [Licencia](#licencia)
- [Referencias](#referencias)

---

## Demostración en vivo

🔗 **App pública (sin login):** https://sserrentino.shinyapps.io/PRA2-VisualizacionDeDatos/

La aplicación se compone de cinco pestañas en secuencia narrativa **contexto → atención → conclusión**:

| Pestaña | Pregunta que responde |
|---|---|
| **Inicio** | KPIs generales, tres preguntas guía y hallazgos principales |
| **Crecimiento** | ¿Cómo varía el WAZ por edad, sexo y quintil de riqueza? |
| **Estimulación** | ¿Qué brechas territoriales y socioeconómicas hay en el acceso a libros infantiles? |
| **Involucramiento paterno** | ¿Cómo varía el IIP por quintil de riqueza, educación materna y región (incluye gráfico agregado de IIP medio por región)? |
| **Metodología** | Calidad de datos, decisiones de limpieza, diccionario y declaración de uso de IA |

---

## Resumen del proyecto

Este proyecto académico de la asignatura **Visualización de Datos** del **Máster Universitario en Ciencia de Datos** de la **Universitat Oberta de Catalunya (UOC)** desarrolla una visualización interactiva, pública, reproducible y académicamente defendible sobre primera infancia en Argentina. La pieza integra crecimiento infantil, desigualdad socioeconómica, territorio y corresponsabilidad paterna a partir de microdatos MICS6 Argentina 2019–2020 (UNICEF) y se concibe como una visualización exploratoria y comunicativa, **no causal**.

**Audiencias destinatarias:** academia (visualización + salud infantil), salud pública y primera infancia (Ministerio de Salud, UNICEF Argentina, Plan Nacional de Primera Infancia), políticas de corresponsabilidad y género, y público no especialista con interés social.

---

## Preguntas guía

1. **P1 (Crecimiento):** ¿Cómo se combinan la edad, el sexo y la desigualdad socioeconómica en la lectura del crecimiento infantil?
2. **P2 (Estimulación):** ¿Qué diferencias territoriales y socioeconómicas aparecen en el acceso a materiales de aprendizaje como libros infantiles?
3. **P3 (Involucramiento paterno):** ¿Cómo varía el involucramiento paterno declarado según quintil de riqueza, región y educación materna?

---

## Indicadores generales

| Indicador | Valor |
|---|---:|
| Registros con peso muestral válido | **6157** |
| WAZ medio ponderado (z-score OMS de peso para la edad) | **0,19** |
| Proporción ponderada de bajo peso (WAZ < −2) | **3,76 %** |
| Proporción con al menos un libro infantil | **63,11 %** |
| IIP medio ponderado (escala 0 a 6) | **1,26** |

> Brecha de libros: **46,22 %** en quintil más pobre vs **86,31 %** en quintil más rico.
> Brecha de IIP: **0,96** en quintil más pobre vs **1,84** en quintil más rico.

---

## Stack y arquitectura

- **Lenguaje:** R 4.3+
- **Framework:** Shiny + navbarPage (cinco pestañas)
- **Visualización:** ggplot2 + Plotly (interactividad: tooltips, zoom, filtros DOM)
- **Tablas:** DT (DataTables)
- **Manejo de datos:** dplyr, scales
- **Paleta accesible:** Okabe-Ito (validada para personas con visión de color reducida)
- **Despliegue:** shinyapps.io vía `rsconnect::deployApp()`

### Patrón de diseño

La app sigue la **taxonomía de Shneiderman (1996)**: *Overview first* (KPIs + 3 preguntas guía + hallazgos principales en Inicio) → *Zoom & Filter* (filtros región / quintil / indicador) → *Details on Demand* (tooltips con n y valor por celda).

---

## Cómo ejecutar la app localmente

### Requisitos previos

- **R ≥ 4.3** y **RStudio**
- Paquetes: `shiny`, `ggplot2`, `plotly`, `DT`, `dplyr`, `scales`, `htmltools`, `htmlwidgets`, `jsonlite`, `rsconnect`

### Pasos

```r
# 1. Instalar dependencias
source("dependencias.R")

# 2. (Opcional) regenerar las tablas agregadas desde data_processed/
source("R/03_tablas_visualizacion.R")

# 3. Lanzar la app
source("run_app_local.R")
```

> La app **no requiere los microdatos crudos** (`data_raw/*.sav`) para funcionar. Consume directamente los CSV agregados de `data_processed/`. Estos están versionados.

### Regenerar el pipeline completo desde microdatos

Si querés reproducir el pipeline desde cero, descargá los microdatos MICS6 Argentina 2019–2020 desde el [repositorio oficial de UNICEF MICS](https://mics.unicef.org/surveys) (requiere registro académico), colocá `ch.sav`, `hh.sav` y `hl.sav` en `data_raw/` y ejecutá:

```r
source("run_pipeline_completo.R")
```

---

## Cómo redesplegar a shinyapps.io

```r
# Una sola vez por máquina: configurar credenciales rsconnect
rsconnect::setAccountInfo(name = "<tu_usuario>", token = "<TU_TOKEN>", secret = "<TU_SECRET>")

# Cada redespliegue
source("R/03_tablas_visualizacion.R")   # regenera .rds consistentes con CSVs
source("deploy_limpio_shinyapps.R")     # bundle limpio + verificación + push
```

El script `deploy_limpio_shinyapps.R` aplica defensa en profundidad: copia los archivos runtime a un bundle temporal, elimina `renv.lock` y `.Rprofile`, verifica que `rsconnect` detecte todas las dependencias y aborta si falta alguna crítica antes de publicar.

---

## Estructura del repositorio

```
PRA2-VisualizacionDeDatos/
├── app.R                          # Aplicación Shiny (5 pestañas + 3 preguntas guía + hallazgos en Inicio)
├── R/
│   ├── 00_config.R                # Paletas Okabe-Ito, helpers, weighted_avg
│   ├── 01_preparacion_datos.R     # Lectura de microdatos y limpieza
│   ├── 02_exploracion_calidad.R   # Calidad de datos y faltantes
│   ├── 03_tablas_visualizacion.R  # Agregaciones ponderadas (con política n ≥ 25)
│   └── 04_visualizaciones.R       # Funciones plot_* con política de NA (plot_estimulo construido con plot_ly heatmap; plot_iip_region nuevo)
├── data_raw/                      # Microdatos (ignorado por git, solo README)
│   └── README.md                  # Instrucciones para obtener los microdatos
├── data_processed/                # Tablas agregadas consumidas por la app
│   ├── kpis.csv
│   ├── tabla_crecimiento.csv
│   ├── tabla_estimulo.csv
│   ├── tabla_iip.csv              # filtrada con n ≥ 25
│   ├── tabla_iip_actividad.csv
│   ├── calidad_variables.csv
│   ├── decisiones_limpieza.csv
│   └── diccionario_variables.csv
├── metadata/
│   └── diccionario_variables_pra2.csv  # Diccionario extendido del proyecto
├── www/
│   └── styles.css                 # CSS de la app
├── renv/                          # Configuración renv (activate.R, settings.json)
├── dependencias.R                 # Instalación de paquetes
├── run_app_local.R                # Driver local
├── run_pipeline_completo.R        # Driver del pipeline completo
├── deploy.R                       # Despliegue estándar
├── deploy_limpio_shinyapps.R      # Despliegue defensivo (recomendado)
├── validate_runtime_files.R       # Verificación previa al deploy
├── DESCRIPTION                    # Metadata R
├── PRA2.Rproj                     # Proyecto RStudio
├── renv.lock                      # Lockfile de dependencias
├── LICENSE                        # MIT
└── README.md                      # Este archivo
```

---

## Decisiones metodológicas clave

| # | Decisión | Justificación |
|---|---|---|
| 1 | Indicadores antropométricos **provistos por MICS6** (`WAZ2`, `WAZFLAG`), no recalculados contra tablas OMS externas | Evita reimplementación divergente del cálculo oficial documentado en el manual MICS |
| 2 | Ponderador muestral `chweight` aplicado en **todos** los agregados | Coherente con el diseño muestral complejo de la encuesta |
| 3 | Política de incertidumbre con umbral **n ≥ 25** | Evita conclusiones sobre subgrupos con muestra insuficiente. Aplicada en pipeline (`tabla_iip` se entrega con celdas n < 25 anuladas) y en cuatro funciones de visualización: `plot_crecimiento`, `plot_estimulo` (heatmap y vista por región específica), `plot_iip` y `plot_iip_region` ocultan celdas/quintiles por debajo del umbral. |
| 4 | Publicación de **tablas agregadas** (no microdatos) en la app | Reduce exposición individual y mejora rendimiento |
| 5 | Paleta **Okabe-Ito** sincronizada (quintil "Más rico" = `#D55E00`, no gris) | Accesibilidad cromática para personas con visión de color reducida |
| 6 | Honestidad gráfica: escalas distintas para proporciones (0–1, %) y media de libros (escala libre) | Evita representar cantidades absolutas como porcentajes |
| 7 | Lecturas guiadas en cada pestaña con disclaimer **no causal** | Comunicación responsable; evita sobreinterpretación |

---

## Reproducibilidad

El pipeline R es enteramente scriptado y reproducible. Cada etapa (`R/01_*` a `R/03_*`) genera artefactos verificables en `data_processed/`. Los KPIs reportados (6157 registros con peso muestral válido, WAZ medio ponderado 0,19, proporción de bajo peso 3,76 %, proporción con al menos un libro 63,11 % e IIP medio 1,26 sobre 6) se calculan directamente desde la base procesada y pueden recalcularse ejecutando `source("run_pipeline_completo.R")` en RStudio. El despliegue defensivo (`deploy_limpio_shinyapps.R`) verifica que `rsconnect` detecte todas las dependencias antes de publicar.

---

## Limitaciones declaradas

- **No causalidad**: las diferencias entre grupos describen asociaciones observadas en datos ponderados, no efectos causales.
- **Sesgo de declaración** en el IIP: las actividades paternas son reportadas por el cuidador y pueden estar sujetas a sesgo de memoria, deseabilidad social o no respuesta.
- **Diversidad familiar**: la pregunta MICS6 sobre actividades paternas captura corresponsabilidad declarada en familias heteroparentales y no agota la diversidad de formas familiares.
- **Sin auditoría WCAG AA formal**: la accesibilidad cromática se aborda con la paleta Okabe-Ito, pero no se realizó auditoría con axe / WAVE; queda recomendada como mejora futura.

---

## Uso de inteligencia artificial

Durante el desarrollo se utilizó **ChatGPT (OpenAI, 2026)** como herramienta de apoyo limitada, conforme a la guía UOC sobre citación de IA y a los criterios fijados por la consigna. El detalle por apartado se documenta en el informe final entregado a la asignatura. Todas las salidas generadas por IA fueron revisadas, adaptadas y validadas por el autor. **No se introdujeron datos personales, confidenciales ni protegidos en la herramienta de IA.**

---

## Autor y contexto académico

**Sebastián Serrentino Mangino**
Máster Universitario en Ciencia de Datos · Universitat Oberta de Catalunya
Asignatura: Visualización de Datos · Curso 2025/2026 — Semestre 2

---

## Licencia

Distribuido bajo licencia **MIT**. Ver [LICENSE](LICENSE) para más detalles.

Los datos originales MICS6 son propiedad de UNICEF y del Consejo Nacional de Coordinación de Políticas Sociales (Argentina). Su uso se rige por las condiciones del programa MICS.

---

## Referencias

- Alcalde, I., y Minguillón, J. (2020). *Introducción a la visualización de la información.* Fundació Universitat Oberta de Catalunya.
- Few, S. (2011). *Data visualization for human perception.* En M. Soegaard y R. F. Dam (Eds.), *The Encyclopedia of Human-Computer Interaction* (2.ª ed.). Interaction Design Foundation.
- Giménez, X. (s. f.). *Aspectos a tener en cuenta para la práctica de visualización de datos* (J. Minguillón Alfonso, Coord.). Universitat Oberta de Catalunya.
- Lumley, T. (2010). *Complex surveys: A guide to analysis using R.* Wiley. [DOI](https://doi.org/10.1002/9780470580066)
- Minguillón Alfonso, J. (2021). *Guía de lecturas en el ámbito de la visualización de datos.* Fundació Universitat Oberta de Catalunya.
- Minguillón Alfonso, J. (2024). *Introducción a la preparación de datos.* Universitat Oberta de Catalunya.
- OpenAI (2026). *ChatGPT* [Modelo de lenguaje grande]. https://chat.openai.com
- Shneiderman, B. (1996). The eyes have it: A task by data type taxonomy for information visualizations. *Proceedings of the IEEE Symposium on Visual Languages*, 336–343. [DOI](https://doi.org/10.1109/VL.1996.545307)
- Tufte, E. R. (1983). *The visual display of quantitative information.* Graphics Press.
- UNICEF (2020). *Encuesta Nacional de Niñas, Niños y Adolescentes 2019–2020 (MICS6 Argentina)* [Conjunto de datos]. Fondo de las Naciones Unidas para la Infancia y Consejo Nacional de Coordinación de Políticas Sociales. https://mics.unicef.org/surveys
- UNICEF (2023). *Estado mundial de la infancia 2023: Para cada niño, vacunación.* https://www.unicef.org/es/informes/estado-mundial-infancia-2023
- World Health Organization (2006). *WHO Child Growth Standards: Length/height-for-age, weight-for-age, weight-for-length, weight-for-height and body mass index-for-age: Methods and development.* WHO. https://www.who.int/toolkits/child-growth-standards
- World Wide Web Consortium (2024). *Web Content Accessibility Guidelines (WCAG) 2.2.* W3C Recommendation. https://www.w3.org/TR/WCAG22/

---

<p align="center">
  <sub>Construido en R · Publicado en shinyapps.io · Hecho para la UOC</sub>
</p>
