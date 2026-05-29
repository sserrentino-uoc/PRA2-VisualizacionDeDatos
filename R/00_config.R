
# =========================================================
# PRA2 - Visualización de Datos
# 00_config.R
# Configuración, paquetes, rutas y funciones auxiliares
# =========================================================

required_packages <- c("shiny", "ggplot2", "plotly", "DT", "dplyr", "scales")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  stop(
    "Faltan paquetes requeridos para ejecutar la app: ",
    paste(missing_packages, collapse = ", "),
    ". Instalarlos con install.packages(c(",
    paste(sprintf('"%s"', missing_packages), collapse = ", "),
    ")).",
    call. = FALSE
  )
}

library(shiny)
library(ggplot2)
library(plotly)
library(DT)
library(dplyr)
library(scales)

# Rutas del proyecto -----------------------------------------------------
DATA_RAW_DIR <- "data_raw"
DATA_PROCESSED_DIR <- "data_processed"
WWW_DIR <- "www"
DOCS_DIR <- "docs"

# Órdenes de categorías --------------------------------------------------
orden_quintiles <- c("Más pobre", "Segundo", "Medio", "Cuarto", "Más rico")
orden_edades <- c("0-5", "6-11", "12-23", "24-35", "36-47", "48-59")
orden_sexo <- c("Varón", "Mujer")

# Paletas consistentes y suficientemente contrastadas --------------------
# Paleta Okabe-Ito (validada para daltonismo). Se reemplaza el gris "#999999"
# original del quintil "Más rico" por "#D55E00" (bermellón) para evitar que
# el extremo superior se lea como ausencia de dato y para reforzar el orden
# perceptual del gradiente socioeconómico.
pal_quintil <- c(
  "Más pobre" = "#E69F00",   # naranja
  "Segundo"   = "#009E73",   # verde azulado
  "Medio"     = "#0072B2",   # azul
  "Cuarto"    = "#CC79A7",   # rosa-violeta
  "Más rico"  = "#D55E00"    # bermellón (sustituye #999999 para WCAG/Okabe-Ito)
)

pal_educ <- c(
  "Hasta Secundario incompleto" = "#E69F00",
  "Secundario completo / Terciario o Universitario incompleto" = "#009E73",
  "Terciario completo" = "#0072B2",
  "No sabe / no responde" = "#CC79A7"
)

# Formato numérico solicitado: sin separador de miles y coma decimal ------
num_fmt <- function(x, digits = 2) {
  if (length(x) == 0 || all(is.na(x))) return("s/d")
  out <- format(
    round(as.numeric(x)[1], digits),
    nsmall = digits,
    scientific = FALSE,
    trim = TRUE,
    big.mark = ""
  )
  gsub("\\.", ",", out)
}

pct_fmt <- function(x, digits = 2) {
  if (length(x) == 0 || all(is.na(x))) return("s/d")
  paste0(num_fmt(as.numeric(x)[1] * 100, digits), " %")
}

int_fmt <- function(x) {
  if (length(x) == 0 || all(is.na(x))) return("s/d")
  as.character(as.integer(round(as.numeric(x)[1], 0)))
}

# weighted_avg: media ponderada robusta y defensiva.
# - Si value y weight tienen distinta longitud, se intenta reciclar el peso
#   (caso comun: peso constante o mal pasado como escalar). Solo se recicla
#   si la longitud del peso es 1; en cualquier otro mismatch se devuelve NA
#   para no producir resultados silenciosamente incorrectos.
# - Filtra NAs en value y weight de forma alineada antes de delegar en
#   stats::weighted.mean.
weighted_avg <- function(value, weight) {
  if (length(weight) == 1L && length(value) > 1L) {
    weight <- rep(weight, length(value))
  }
  if (length(value) != length(weight)) {
    return(NA_real_)
  }
  ok <- !is.na(value) & !is.na(weight) & weight > 0
  if (!any(ok)) return(NA_real_)
  stats::weighted.mean(value[ok], weight[ok], na.rm = TRUE)
}

# Tarjetas narrativas ----------------------------------------------------
card_text <- function(title, ...) {
  shiny::div(
    class = "info-card narrative-card",
    shiny::h3(title),
    ...
  )
}

lectura_guiada <- function(title, intro, bullets) {
  card_text(
    title,
    shiny::p(intro),
    shiny::tags$ul(lapply(bullets, shiny::tags$li))
  )
}

filter_by_region_quintil <- function(df, region = "Todas", quintiles = NULL) {
  out <- df
  if (!is.null(region) && region != "Todas" && "region" %in% names(out)) {
    out <- out[out$region == region, , drop = FALSE]
  }
  if (!is.null(quintiles) && "quintil_riqueza" %in% names(out)) {
    if (length(quintiles) == 0) {
      return(out[FALSE, , drop = FALSE])
    }
    out <- out[out$quintil_riqueza %in% quintiles, , drop = FALSE]
  }
  out
}

safe_levels <- function(x, ordered_values) {
  factor(x, levels = ordered_values[ordered_values %in% unique(x)], ordered = TRUE)
}

write_utf8_csv <- function(df, file) {
  utils::write.csv(df, file = file, row.names = FALSE, fileEncoding = "UTF-8")
}
