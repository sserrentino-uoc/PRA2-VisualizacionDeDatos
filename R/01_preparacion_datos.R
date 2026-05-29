
# =========================================================
# PRA2 - Visualización de Datos
# 01_preparacion_datos.R
# Lectura de microdatos MICS6 y creación de base analítica
# =========================================================

source("R/00_config.R", encoding = "UTF-8")

extra_packages <- c("haven")
missing_extra <- extra_packages[!vapply(extra_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_extra) > 0) {
  stop(
    "Para regenerar la base desde los .sav falta instalar: ",
    paste(missing_extra, collapse = ", "),
    ". Ejecutar install.packages(c(\"haven\")).",
    call. = FALSE
  )
}

ch_path <- file.path(DATA_RAW_DIR, "ch.sav")
if (!file.exists(ch_path)) {
  stop(
    "No se encontró data_raw/ch.sav. Para publicar la app no es necesario; ",
    "solo hace falta si se desea regenerar data_processed desde cero.",
    call. = FALSE
  )
}

ch <- haven::read_sav(ch_path)

as_label <- function(x) {
  as.character(haven::as_factor(x, levels = "default"))
}

clean_numeric <- function(x, invalid = c(98, 99, 999, 999.9, 99.9)) {
  out <- suppressWarnings(as.numeric(x))
  out[out %in% invalid] <- NA_real_
  out
}

yes_no_1 <- function(x) {
  out <- suppressWarnings(as.numeric(x))
  dplyr::case_when(
    is.na(out) ~ NA_real_,
    out == 1 ~ 1,
    out == 2 ~ 0,
    TRUE ~ NA_real_
  )
}

father_activity <- function(x, code = "B") {
  raw <- trimws(as.character(x))
  dplyr::case_when(
    is.na(raw) ~ NA_real_,
    raw == "?" ~ NA_real_,
    raw == code ~ 1,
    TRUE ~ 0
  )
}

base_pra2 <- ch |>
  dplyr::transmute(
    id_nino = paste(HH1, HH2, LN, sep = "-"),
    region = as_label(stratum),
    sexo = dplyr::recode(as_label(HL4), "VARÓN" = "Varón", "MUJER" = "Mujer", .default = as_label(HL4)),
    quintil_riqueza = as_label(windex5),
    educ_madre = dplyr::recode(as_label(melevel), "No sabe o no responde" = "No sabe / no responde", .default = as_label(melevel)),
    edad_meses = clean_numeric(dplyr::coalesce(CAGE_AN, CAGE), invalid = c(98, 99, 999)),
    edad_grupo = cut(
      edad_meses,
      breaks = c(-Inf, 5, 11, 23, 35, 47, 59),
      labels = orden_edades,
      right = TRUE
    ),
    chweight = suppressWarnings(as.numeric(chweight)),
    peso_muestral = clean_numeric(chweight, invalid = c(0, 98, 99, 999, 999.9)),
    peso_kg = clean_numeric(AN8, invalid = c(99.9, 99, 999, 999.9)),
    talla_cm = clean_numeric(AN11, invalid = c(99.9, 99, 999, 999.9)),
    wazflag = suppressWarnings(as.numeric(WAZFLAG)),
    waz_oms = dplyr::if_else(wazflag == 0 & suppressWarnings(as.numeric(WAZ2)) < 90, suppressWarnings(as.numeric(WAZ2)), NA_real_),
    bajo_peso = dplyr::if_else(!is.na(waz_oms), as.numeric(waz_oms < -2), NA_real_),
    libros_n = clean_numeric(EC1, invalid = c(98, 99)),
    tiene_libros = dplyr::if_else(!is.na(libros_n), as.numeric(libros_n > 0), NA_real_),
    juguete_casero = yes_no_1(EC2A),
    juguete_comprado = yes_no_1(EC2B),
    objeto_hogar_juego = yes_no_1(EC2C),
    padre_leyo = father_activity(EC5AB, "B"),
    padre_conto_cuentos = father_activity(EC5BB, "B"),
    padre_canto = father_activity(EC5CB, "B"),
    padre_llevo_fuera = father_activity(EC5DB, "B"),
    padre_jugo = father_activity(EC5EB, "B"),
    padre_nombro_conto_dibujo = father_activity(EC5FB, "B")
  ) |>
  dplyr::mutate(
    iip = rowSums(dplyr::across(dplyr::starts_with("padre_")), na.rm = TRUE),
    iip = dplyr::if_else(rowSums(!is.na(dplyr::across(dplyr::starts_with("padre_")))) == 0, NA_real_, as.numeric(iip)),
    iip_normalizado = iip / 6,
    region = factor(region),
    sexo = factor(sexo, levels = orden_sexo),
    quintil_riqueza = factor(quintil_riqueza, levels = orden_quintiles, ordered = TRUE),
    edad_grupo = factor(edad_grupo, levels = orden_edades, ordered = TRUE)
  )

if (!dir.exists(DATA_PROCESSED_DIR)) dir.create(DATA_PROCESSED_DIR, recursive = TRUE)
saveRDS(base_pra2, file.path(DATA_PROCESSED_DIR, "base_pra2.rds"))
write_utf8_csv(base_pra2, file.path(DATA_PROCESSED_DIR, "base_pra2.csv"))

message("Base analítica creada: ", nrow(base_pra2), " registros.")
