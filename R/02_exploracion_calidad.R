# =========================================================
# PRA2 - Visualización de Datos
# 02_exploracion_calidad.R
# Tablas de calidad, diccionario y decisiones metodológicas
# =========================================================

source("R/00_config.R", encoding = "UTF-8")

base_path <- file.path(DATA_PROCESSED_DIR, "base_pra2.rds")
if (!file.exists(base_path)) {
  stop("No existe data_processed/base_pra2.rds. Ejecutar antes R/01_preparacion_datos.R.", call. = FALSE)
}

base_pra2 <- readRDS(base_path)

vars_calidad <- c(
  "bajo_peso", "waz_oms", "talla_cm", "peso_kg", "libros_n",
  "tiene_libros", "quintil_riqueza", "edad_meses", "educ_madre",
  "sexo", "iip", "iip_normalizado", "chweight", "region"
)
vars_calidad <- vars_calidad[vars_calidad %in% names(base_pra2)]

calidad_variables <- data.frame(
  variable = vars_calidad,
  n = nrow(base_pra2),
  faltantes = vapply(vars_calidad, function(v) sum(is.na(base_pra2[[v]])), integer(1)),
  stringsAsFactors = FALSE
) |>
  dplyr::mutate(pct_faltantes = faltantes / n)

decisiones_limpieza <- data.frame(
  dimension = c(
    "Antropometría", "Peso/talla", "Estimulación", "IIP", "Privacidad",
    "Ponderación", "Interpretación"
  ),
  problema_detectado = c(
    "WAZ2 contiene valores fuera de rango y WAZFLAG marca errores",
    "Códigos especiales como 99/999 representan no respuesta o medición no válida",
    "Variables EC5 son de selección múltiple con códigos A/B/X/Y y ?",
    "La participación paterna no es una medida directa de calidad del vínculo",
    "Los microdatos contienen información individual anonimizada",
    "MICS6 es una encuesta compleja con ponderadores",
    "Las asociaciones pueden confundirse con causalidad"
  ),
  decision_metodologica = c(
    "Usar solo WAZ2 cuando WAZFLAG == 0 y WAZ2 < 90",
    "Convertir códigos especiales a NA",
    "Construir indicadores binarios específicos para padre y madre",
    "Definir IIP como suma exploratoria de seis actividades declaradas",
    "Publicar la app usando tablas agregadas y no microdatos crudos",
    "Calcular promedios y proporciones usando chweight",
    "Agregar notas metodológicas y lecturas guiadas en la app"
  ),
  impacto_en_visualizacion = c(
    "Evita conclusiones basadas en mediciones inválidas",
    "Evita distorsionar medias y distribuciones",
    "Permite medir involucramiento paterno de forma trazable",
    "Mantiene una interpretación descriptiva, no causal",
    "Reduce exposición innecesaria y mejora rendimiento",
    "Mejora la representatividad descriptiva de los indicadores",
    "Evita sobreinterpretación de diferencias entre grupos"
  ),
  stringsAsFactors = FALSE
)

diccionario_variables <- data.frame(
  variable = c(
    "HH1/HH2/LN", "CAGE_AN / CAGE", "HL4", "stratum", "windex5", "melevel",
    "AN8 / AN11", "WAZ2 / WAZFLAG", "EC1 / EC2A-C",
    "EC5AB, EC5BB, EC5CB, EC5DB, EC5EB, EC5FB", "chweight"
  ),
  descripcion = c(
    "Claves de identificación de conglomerado, hogar y línea de niño/a",
    "Edad en meses al momento de la medición / entrevista",
    "Sexo del niño/a",
    "Región",
    "Quintil del índice de riqueza",
    "Máximo nivel educativo de la madre",
    "Peso y talla medidos",
    "Z-score OMS de peso para la edad y bandera de validez",
    "Libros y materiales de juego disponibles",
    "Actividades de estimulación realizadas por el padre",
    "Ponderador de niños/as de 0 a 4 años"
  ),
  uso = c(
    "Trazabilidad interna",
    "Control por edad y grupos etarios",
    "Estratificación antropométrica",
    "Comparación territorial",
    "Desigualdad socioeconómica",
    "Comparación en involucramiento paterno",
    "Calidad de datos antropométricos",
    "Indicador principal de crecimiento",
    "Entorno de estimulación temprana",
    "Construcción del IIP",
    "Promedios y proporciones ponderadas"
  ),
  stringsAsFactors = FALSE
)

saveRDS(calidad_variables, file.path(DATA_PROCESSED_DIR, "calidad_variables.rds"))
saveRDS(decisiones_limpieza, file.path(DATA_PROCESSED_DIR, "decisiones_limpieza.rds"))
saveRDS(diccionario_variables, file.path(DATA_PROCESSED_DIR, "diccionario_variables.rds"))
write_utf8_csv(calidad_variables, file.path(DATA_PROCESSED_DIR, "calidad_variables.csv"))
write_utf8_csv(decisiones_limpieza, file.path(DATA_PROCESSED_DIR, "decisiones_limpieza.csv"))
write_utf8_csv(diccionario_variables, file.path(DATA_PROCESSED_DIR, "diccionario_variables.csv"))

message("Tablas de calidad y documentación metodológica generadas.")
