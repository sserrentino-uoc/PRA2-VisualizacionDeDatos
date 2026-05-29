# =========================================================
# PRA2 - Visualización de Datos
# 03_tablas_visualizacion.R
# Tablas agregadas para consumo de la app Shiny
# =========================================================

source("R/00_config.R", encoding = "UTF-8")

base_path <- file.path(DATA_PROCESSED_DIR, "base_pra2.rds")
if (!file.exists(base_path)) {
  stop("No existe data_processed/base_pra2.rds. Ejecutar antes R/01_preparacion_datos.R.", call. = FALSE)
}

base_pra2 <- readRDS(base_path)

# La versión final usa n y peso_muestral como tamaño de base válida ponderada
# del grupo, mientras que las métricas analíticas ignoran NA en cada variable.
base_valid_weight <- base_pra2 |>
  dplyr::filter(!is.na(peso_muestral), peso_muestral > 0)

# IMPORTANTE: el orden importa. peso_muestral debe sobrescribirse DESPUES
# de calcular las metricas ponderadas; en caso contrario dplyr reemplaza
# el vector de pesos por un escalar (sum) antes de pasarlo a weighted_avg,
# que entonces recicla mal y devuelve NA para casi todas las celdas.
tabla_crecimiento <- base_valid_weight |>
  dplyr::group_by(region, sexo, quintil_riqueza, edad_grupo) |>
  dplyr::summarise(
    n = dplyr::n(),
    waz_medio = weighted_avg(waz_oms, peso_muestral),
    prop_bajo_peso = weighted_avg(bajo_peso, peso_muestral),
    peso_muestral = sum(peso_muestral, na.rm = TRUE),
    .groups = "drop"
  ) |>
  dplyr::select(region, sexo, quintil_riqueza, edad_grupo, n, peso_muestral, waz_medio, prop_bajo_peso) |>
  dplyr::filter(!is.na(region), !is.na(sexo), !is.na(quintil_riqueza), !is.na(edad_grupo))

estimulo_summary <- function(data, var, indicador, label, tipo_indicador = "proporcion", unidad = "porcentaje") {
  data |>
    dplyr::group_by(region, quintil_riqueza) |>
    dplyr::summarise(
      n = sum(!is.na(.data[[var]]) & !is.na(.data[["peso_muestral"]]) & .data[["peso_muestral"]] > 0),
      valor = weighted_avg(.data[[var]], .data[["peso_muestral"]]),
      peso_muestral = sum(
        .data[["peso_muestral"]][!is.na(.data[[var]]) & !is.na(.data[["peso_muestral"]]) & .data[["peso_muestral"]] > 0],
        na.rm = TRUE
      ),
      indicador = indicador,
      indicador_label = label,
      tipo_indicador = tipo_indicador,
      unidad = unidad,
      .groups = "drop"
    )
}

tabla_estimulo <- dplyr::bind_rows(
  estimulo_summary(
    base_valid_weight,
    "tiene_libros",
    "prop_tiene_libros",
    "Tiene al menos un libro",
    tipo_indicador = "proporcion",
    unidad = "porcentaje"
  ),
  estimulo_summary(
    base_valid_weight,
    "libros_n",
    "media_libros",
    "Media de libros",
    tipo_indicador = "media",
    unidad = "libros"
  ),
  estimulo_summary(
    base_valid_weight,
    "juguete_casero",
    "prop_juguetes_caseros",
    "Juguetes caseros",
    tipo_indicador = "proporcion",
    unidad = "porcentaje"
  ),
  estimulo_summary(
    base_valid_weight,
    "juguete_comprado",
    "prop_juguetes_comprados",
    "Juguetes comprados",
    tipo_indicador = "proporcion",
    unidad = "porcentaje"
  ),
  estimulo_summary(
    base_valid_weight,
    "objeto_hogar_juego",
    "prop_objetos_hogar",
    "Objetos del hogar/exterior",
    tipo_indicador = "proporcion",
    unidad = "porcentaje"
  )
) |>
  dplyr::filter(!is.na(region), !is.na(quintil_riqueza))

# IMPORTANTE: idem comentario de tabla_crecimiento. peso_muestral se
# sobrescribe al final del summarise para que weighted_avg reciba el
# vector original de pesos en cada grupo.
#
# Política de incertidumbre (alineada con §4.3 del informe):
# - Las celdas con n < N_MIN_IIP se conservan estructuralmente, pero
#   los valores agregados se devuelven como NA para evitar lecturas
#   sobre subgrupos minoritarios (caso tipico: "No sabe / no responde"
#   en quintiles extremos que arrojaba un IIP saturado por outliers).
# - La capa de visualizacion (plot_iip) reaplica el mismo umbral por
#   robustez, de modo que el filtro funciona incluso si la tabla se
#   recalcula manualmente sin el umbral.
N_MIN_IIP <- 25

tabla_iip <- base_valid_weight |>
  dplyr::group_by(region, quintil_riqueza, educ_madre) |>
  dplyr::summarise(
    n = dplyr::n(),
    iip_medio = weighted_avg(iip, peso_muestral),
    iip_normalizado_medio = weighted_avg(iip_normalizado, peso_muestral),
    peso_muestral = sum(peso_muestral, na.rm = TRUE),
    .groups = "drop"
  ) |>
  dplyr::mutate(
    iip_medio = ifelse(n < N_MIN_IIP, NA_real_, iip_medio),
    iip_normalizado_medio = ifelse(n < N_MIN_IIP, NA_real_, iip_normalizado_medio)
  ) |>
  dplyr::select(region, quintil_riqueza, educ_madre, n, peso_muestral, iip_medio, iip_normalizado_medio) |>
  dplyr::filter(!is.na(region), !is.na(quintil_riqueza), !is.na(educ_madre))

actividad_summary <- function(data, var, label) {
  data |>
    dplyr::group_by(region, quintil_riqueza) |>
    dplyr::summarise(
      actividad = label,
      prop_actividad = weighted_avg(.data[[var]], peso_muestral),
      n = dplyr::n(),
      peso_muestral = sum(peso_muestral, na.rm = TRUE),
      .groups = "drop"
    )
}

tabla_iip_actividad <- dplyr::bind_rows(
  actividad_summary(base_valid_weight, "padre_leyo", "Leyó libros"),
  actividad_summary(base_valid_weight, "padre_conto_cuentos", "Contó cuentos"),
  actividad_summary(base_valid_weight, "padre_canto", "Cantó canciones"),
  actividad_summary(base_valid_weight, "padre_llevo_fuera", "Llevó fuera"),
  actividad_summary(base_valid_weight, "padre_jugo", "Jugó"),
  actividad_summary(base_valid_weight, "padre_nombro_conto_dibujo", "Nombró/contó/dibujó")
) |>
  dplyr::filter(!is.na(region), !is.na(quintil_riqueza))

kpis <- data.frame(
  registros = nrow(base_valid_weight),
  waz_medio = weighted_avg(base_valid_weight$waz_oms, base_valid_weight$peso_muestral),
  prop_bajo_peso = weighted_avg(base_valid_weight$bajo_peso, base_valid_weight$peso_muestral),
  prop_tiene_libros = weighted_avg(base_valid_weight$tiene_libros, base_valid_weight$peso_muestral),
  iip_medio = weighted_avg(base_valid_weight$iip, base_valid_weight$peso_muestral)
)

objects <- list(
  tabla_crecimiento = tabla_crecimiento,
  tabla_estimulo = tabla_estimulo,
  tabla_iip = tabla_iip,
  tabla_iip_actividad = tabla_iip_actividad,
  kpis = kpis
)

for (nm in names(objects)) {
  saveRDS(objects[[nm]], file.path(DATA_PROCESSED_DIR, paste0(nm, ".rds")))
  write_utf8_csv(objects[[nm]], file.path(DATA_PROCESSED_DIR, paste0(nm, ".csv")))
}

message("Tablas agregadas para la visualización generadas.")
