# =========================================================
# PRA2 - Visualización de Datos
# Primera infancia, desigualdad y corresponsabilidad
# App final para shinyapps.io
# =========================================================


# Dependencias explícitas para que rsconnect/shinyapps.io las detecte en el manifest
library(shiny)
library(ggplot2)
library(plotly)
library(DT)
library(dplyr)
library(scales)
library(htmltools)
library(htmlwidgets)
library(jsonlite)

source("R/00_config.R", encoding = "UTF-8")
source("R/04_visualizaciones.R", encoding = "UTF-8")

# ------------------------------
# Carga de datos agregados
# ------------------------------
data_dir <- "data_processed"

runtime_csv <- c(
  "kpis.csv",
  "tabla_crecimiento.csv",
  "tabla_estimulo.csv",
  "tabla_iip.csv",
  "tabla_iip_actividad.csv",
  "calidad_variables.csv",
  "decisiones_limpieza.csv",
  "diccionario_variables.csv"
)
missing_runtime_csv <- runtime_csv[!file.exists(file.path(data_dir, runtime_csv))]
if (length(missing_runtime_csv) > 0) {
  stop(
    "Faltan archivos agregados en data_processed/: ",
    paste(missing_runtime_csv, collapse = ", "),
    ". Ejecutar el pipeline completo o copiar la carpeta data_processed incluida en la entrega.",
    call. = FALSE
  )
}

read_app_csv <- function(file) {
  df <- read.csv(
    file.path(data_dir, file),
    stringsAsFactors = FALSE,
    check.names = FALSE,
    fileEncoding = "UTF-8-BOM"
  )
  names(df) <- sub("^\ufeff", "", names(df))
  df
}

kpis <- read_app_csv("kpis.csv")
tabla_crecimiento <- read_app_csv("tabla_crecimiento.csv")
tabla_estimulo <- read_app_csv("tabla_estimulo.csv")
tabla_iip <- read_app_csv("tabla_iip.csv")
tabla_iip_actividad <- read_app_csv("tabla_iip_actividad.csv")
calidad_variables <- read_app_csv("calidad_variables.csv")
decisiones_limpieza <- read_app_csv("decisiones_limpieza.csv")
diccionario_variables <- read_app_csv("diccionario_variables.csv")

regiones <- c("Todas", sort(unique(tabla_crecimiento$region)))
quintiles <- c("Más pobre", "Segundo", "Medio", "Cuarto", "Más rico")
indicadores_estimulo <- unique(tabla_estimulo[, c("indicador", "indicador_label")])

# ------------------------------
# Agregaciones reactivas seguras
# ------------------------------
agregar_crecimiento <- function(df) {
  df |>
    dplyr::group_by(sexo, quintil_riqueza, edad_grupo) |>
    dplyr::summarise(
      n = sum(n, na.rm = TRUE),
      peso_muestral = sum(peso_muestral, na.rm = TRUE),
      waz_medio = weighted_avg(waz_medio, peso_muestral),
      prop_bajo_peso = weighted_avg(prop_bajo_peso, peso_muestral),
      .groups = "drop"
    )
}

agregar_estimulo <- function(df, region_input) {
  if (!is.null(region_input) && region_input != "Todas") return(df)
  df |>
    dplyr::group_by(region, quintil_riqueza, indicador, indicador_label) |>
    dplyr::summarise(
      n = sum(n, na.rm = TRUE),
      peso_muestral = sum(peso_muestral, na.rm = TRUE),
      valor = weighted_avg(valor, peso_muestral),
      .groups = "drop"
    )
}

agregar_iip <- function(df) {
  df |>
    dplyr::group_by(quintil_riqueza, educ_madre) |>
    dplyr::summarise(
      n = sum(n, na.rm = TRUE),
      peso_muestral = sum(peso_muestral, na.rm = TRUE),
      iip_medio = weighted_avg(iip_medio, peso_muestral),
      iip_normalizado_medio = weighted_avg(iip_normalizado_medio, peso_muestral),
      .groups = "drop"
    )
}

agregar_iip_actividad <- function(df) {
  df |>
    dplyr::group_by(quintil_riqueza, actividad) |>
    dplyr::summarise(
      n = sum(n, na.rm = TRUE),
      peso_muestral = sum(peso_muestral, na.rm = TRUE),
      prop_actividad = weighted_avg(prop_actividad, peso_muestral),
      .groups = "drop"
    )
}

# ------------------------------
# UI
# ------------------------------
ui <- navbarPage(
  title = "Primera infancia, desigualdad y corresponsabilidad",
  id = "main_navbar",
  inverse = TRUE,
  header = tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css"),
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1")
  ),
  
  tabPanel(
    "Inicio",
    fluidPage(
      fluidRow(
        column(
          width = 8,
          card_text(
            "Preguntas guía",
            p(tags$strong("Pregunta general:"), " ¿cómo se combinan la desigualdad socioeconómica, el territorio y la corresponsabilidad paterna en los primeros años de vida infantil en Argentina?"),
            p("La visualización integra microdatos MICS6 Argentina 2019–2020 para niños/as menores de cinco años, indicadores antropométricos WAZ provistos por MICS6 (z-score basado en estándares OMS) y variables de estimulación temprana."),
            tags$p(tags$strong("Tres preguntas específicas mapeadas a las pestañas:")),
            tags$ol(
              tags$li(tags$strong("P1 (pestaña Crecimiento):"), " ¿cómo se combinan la edad, el sexo y la desigualdad socioeconómica en la lectura del crecimiento infantil?"),
              tags$li(tags$strong("P2 (pestaña Estimulación):"), " ¿qué diferencias territoriales y socioeconómicas aparecen en el acceso a materiales de aprendizaje como libros infantiles?"),
              tags$li(tags$strong("P3 (pestaña Involucramiento paterno):"), " ¿cómo varía el involucramiento paterno declarado según quintil de riqueza, región y educación materna?")
            ),
            p("El objetivo no es establecer causalidad, sino facilitar una lectura exploratoria, comparativa y comunicativa de patrones relevantes para primera infancia.")
          )
        ),
        column(
          width = 4,
          card_text(
            "Indicadores generales",
            tags$div(class = "kpi", tags$strong(int_fmt(kpis$registros[1])), " registros"),
            tags$div(class = "kpi", tags$strong(num_fmt(kpis$waz_medio[1], 2)), " WAZ medio"),
            tags$div(class = "kpi", tags$strong(pct_fmt(kpis$prop_bajo_peso[1], 2)), " bajo peso"),
            tags$div(class = "kpi", tags$strong(pct_fmt(kpis$prop_tiene_libros[1], 2)), " con libros"),
            tags$div(class = "kpi", tags$strong(num_fmt(kpis$iip_medio[1], 2)), " IIP medio / 6")
          )
        )
      ),
      fluidRow(
        column(
          width = 12,
          lectura_guiada(
            "Lectura sugerida",
            "La aplicación está organizada como una lectura progresiva: primero crecimiento, luego entorno de estimulación y finalmente involucramiento paterno.",
            c(
              "Observá el crecimiento infantil por edad, sexo y quintil de riqueza.",
              "Compará el acceso a libros y materiales de juego por región y quintil.",
              "Analizá el IIP y sus actividades específicas como indicador exploratorio de corresponsabilidad paterna.",
              "Usá los filtros para comparar grupos, manteniendo una lectura descriptiva y no causal."
            )
          )
        )
      )
    )
  ),
  
  tabPanel(
    "Crecimiento",
    sidebarLayout(
      sidebarPanel(
        width = 3,
        selectInput("region_crecimiento", "Región", choices = regiones, selected = "Todas"),
        checkboxGroupInput("quintil_crecimiento", "Quintil de riqueza", choices = quintiles, selected = quintiles),
        helpText("WAZ = z-score OMS de peso para la edad. Se excluyen registros con bandera antropométrica inválida."),
        helpText("La línea horizontal marca el valor 0 de referencia OMS."),
        helpText("Las celdas con n < 25 se ocultan para evitar conclusiones sobre grupos con muestra muy pequeña.")
      ),
      mainPanel(
        width = 9,
        card_text("Crecimiento infantil y desigualdad socioeconómica", plotlyOutput("plot_crecimiento", height = "560px")),
        lectura_guiada(
          "Lectura guiada",
          "El WAZ representa el z-score de peso para la edad según referencia OMS. Un valor cercano a 0 indica proximidad al patrón de referencia; valores negativos sugieren menor peso relativo para la edad.",
          c(
            "Compará primero las diferencias entre quintiles de riqueza.",
            "Luego observá si el patrón cambia entre varones y mujeres.",
            "Usá el filtro de región para identificar si las diferencias se mantienen territorialmente.",
            "La lectura es descriptiva y no debe interpretarse como causalidad."
          )
        )
      )
    )
  ),
  
  tabPanel(
    "Estimulación",
    sidebarLayout(
      sidebarPanel(
        width = 3,
        selectInput("region_estimulo", "Región", choices = regiones, selected = "Todas"),
        selectInput("indicador_estimulo", "Indicador", choices = setNames(indicadores_estimulo$indicador, indicadores_estimulo$indicador_label), selected = "prop_tiene_libros"),
        helpText("Los indicadores describen disponibilidad de recursos y materiales de estimulación temprana en el entorno infantil."),
        helpText("\"Media de libros\" se expresa como número medio ponderado; el resto de indicadores como porcentaje. La escala del gráfico se ajusta automáticamente al tipo seleccionado.")
      ),
      mainPanel(
        width = 9,
        card_text("Entorno de estimulación temprana", plotlyOutput("plot_estimulo", height = "560px")),
        lectura_guiada(
          "Lectura guiada",
          "Esta sección compara el entorno de estimulación temprana según región y quintil de riqueza. Los indicadores seleccionables muestran disponibilidad de libros, juguetes y objetos usados para jugar.",
          c(
            "Observá si los indicadores aumentan a medida que mejora el quintil de riqueza.",
            "Compará si las brechas son similares en todas las regiones.",
            "Prestá atención a los contrastes entre acceso material y contexto territorial.",
            "Estos indicadores describen condiciones del entorno infantil, no calidad educativa ni prácticas familiares completas."
          )
        )
      )
    )
  ),
  
  tabPanel(
    "Involucramiento paterno",
    sidebarLayout(
      sidebarPanel(
        width = 3,
        selectInput("region_iip", "Región", choices = regiones, selected = "Todas"),
        checkboxGroupInput("quintil_iip", "Quintil de riqueza", choices = quintiles, selected = quintiles),
        helpText("IIP = suma de seis actividades paternas: leer, contar cuentos, cantar, llevar fuera, jugar y nombrar/contar/dibujar."),
        helpText("Las celdas con n < 25 se ocultan para evitar lecturas sobre subgrupos con muestra muy pequeña (por ejemplo, 'No sabe / no responde' en quintiles extremos).")
      ),
      mainPanel(
        width = 9,
        card_text("Índice de involucramiento paterno", plotlyOutput("plot_iip", height = "520px")),
        card_text("Actividades paternas específicas", plotlyOutput("plot_iip_actividad", height = "520px")),
        lectura_guiada(
          "Lectura guiada",
          "El Índice de Involucramiento Paterno resume la participación declarada del padre en seis actividades de estimulación temprana: lectura, narración, canto, salidas, juego y actividades de nombrar, contar o dibujar.",
          c(
            "Compará el IIP medio entre quintiles de riqueza.",
            "Observá si la educación materna aparece asociada a diferencias en la participación paterna declarada.",
            "Analizá las actividades específicas para identificar cuáles concentran mayor o menor participación.",
            "El índice es exploratorio: resume prácticas reportadas, pero no mide calidad del vínculo ni intensidad del cuidado.",
            "Las respuestas son declaradas y pueden estar sujetas a sesgo de memoria, deseabilidad social o no respuesta.",
            "La pregunta MICS6 sobre actividades paternas captura corresponsabilidad declarada en familias heteroparentales y no agota la diversidad de formas familiares; el IIP debe leerse en esa clave."
          )
        )
      )
    )
  ),
  
  tabPanel(
    "Metodología",
    fluidPage(
      fluidRow(
        column(width = 6, card_text("Calidad de variables clave", plotlyOutput("plot_calidad", height = "420px"))),
        column(width = 6, card_text("Decisiones de limpieza y visualización", DTOutput("tabla_decisiones")))
      ),
      fluidRow(
        column(
          width = 12,
          lectura_guiada(
            "Cómo interpretar esta visualización",
            "La aplicación fue diseñada como una herramienta exploratoria y comunicativa. Su objetivo es facilitar comparaciones entre grupos, no establecer efectos causales.",
            c(
              "Los resultados se presentan de forma agregada para mejorar rendimiento y reducir exposición innecesaria de microdatos.",
              "Las estimaciones usan ponderadores muestrales cuando corresponde.",
              "Los indicadores antropométricos se filtran para evitar valores inválidos.",
              "Las diferencias observadas deben leerse como asociaciones descriptivas."
            )
          )
        )
      ),
      fluidRow(
        column(
          width = 12,
          card_text(
            "Nota metodológica",
            p("La app utiliza tablas agregadas generadas previamente con scripts reproducibles en R. Esto mejora el rendimiento, evita exponer microdatos individuales y permite documentar el tratamiento de datos faltantes, códigos especiales y filtros antropométricos."),
            p("Las estimaciones son descriptivas y usan el ponderador muestral cuando corresponde. No deben interpretarse como efectos causales."),
            p("El IIP es un indicador exploratorio construido como suma de seis actividades declaradas de participación paterna. Su función es comparativa y descriptiva; no mide intensidad, calidad del vínculo ni tiempo de cuidado.")
          )
        )
      ),
      fluidRow(
        column(width = 12, card_text("Diccionario sintético de variables", DTOutput("tabla_diccionario")))
      ),
      fluidRow(
        column(
          width = 12,
          card_text(
            "Fuentes, créditos y reproducibilidad",
            p("Fuente principal: Encuesta Nacional de Niños, Niñas y Adolescentes MICS6 Argentina 2019–2020, UNICEF / Consejo Nacional de Coordinación de Políticas Sociales."),
            p("La visualización utiliza microdatos del módulo de niños/as menores de cinco años y variables vinculadas a crecimiento infantil, entorno de estimulación temprana, región, quintil de riqueza y participación paterna declarada."),
            p("Indicador antropométrico principal: WAZ, z-score OMS de peso para la edad, filtrado según criterios de validez antropométrica disponibles en la base."),
            p("Aplicación desarrollada en R/Shiny para la asignatura Visualización de Datos del Máster Universitario en Ciencia de Datos de la UOC."),
            p("Finalidad: exploratoria y comunicativa. Los resultados describen asociaciones observadas en la encuesta y no deben interpretarse como relaciones causales."),
            p("Reproducibilidad: el código fuente, los scripts de preparación de datos y las tablas agregadas de visualización se documentan junto con instrucciones de ejecución local.")
          )
        )
      ),
      fluidRow(
        column(
          width = 12,
          card_text(
            "Declaración de uso de inteligencia artificial",
            p("Durante el desarrollo del proyecto se utilizó ChatGPT como herramienta de apoyo para estructurar el proyecto, revisar la consigna, proponer mejoras de diseño, documentar decisiones metodológicas y asistir en la generación inicial de código R/Shiny."),
            p("Todas las salidas generadas por IA fueron revisadas, adaptadas y validadas por el autor. La selección del enfoque, la interpretación de resultados, la depuración del código y la versión final de la visualización son responsabilidad del autor."),
            p("No se introdujeron datos personales, confidenciales ni protegidos en la herramienta de IA. El uso de IA se declara siguiendo los criterios de integridad académica indicados por la UOC.")
          )
        )
      )
    )
  )
)

# ------------------------------
# Server
# ------------------------------
server <- function(input, output, session) {
  
  crecimiento_filtrado <- reactive({
    df <- filter_by_region_quintil(tabla_crecimiento, input$region_crecimiento, input$quintil_crecimiento)
    if (is.null(input$region_crecimiento) || input$region_crecimiento == "Todas") {
      agregar_crecimiento(df)
    } else {
      df
    }
  })
  
  estimulo_filtrado <- reactive({
    df <- tabla_estimulo
    df <- df[df$indicador == input$indicador_estimulo, , drop = FALSE]
    df <- filter_by_region_quintil(df, input$region_estimulo, quintiles)
    agregar_estimulo(df, input$region_estimulo)
  })
  
  iip_filtrado <- reactive({
    df <- filter_by_region_quintil(tabla_iip, input$region_iip, input$quintil_iip)
    if (is.null(input$region_iip) || input$region_iip == "Todas") {
      agregar_iip(df)
    } else {
      df
    }
  })
  
  iip_actividad_filtrado <- reactive({
    df <- filter_by_region_quintil(tabla_iip_actividad, input$region_iip, input$quintil_iip)
    if (is.null(input$region_iip) || input$region_iip == "Todas") {
      agregar_iip_actividad(df)
    } else {
      df
    }
  })
  
  output$plot_crecimiento <- renderPlotly({
    plot_crecimiento(crecimiento_filtrado())
  })
  
  output$plot_estimulo <- renderPlotly({
    plot_estimulo(estimulo_filtrado(), input$region_estimulo)
  })
  
  output$plot_iip <- renderPlotly({
    plot_iip(iip_filtrado())
  })
  
  output$plot_iip_actividad <- renderPlotly({
    plot_iip_actividad(iip_actividad_filtrado())
  })
  
  output$plot_calidad <- renderPlotly({
    plot_calidad(calidad_variables)
  })
  
  output$tabla_decisiones <- renderDT({
    DT::datatable(
      decisiones_limpieza,
      rownames = FALSE,
      options = list(pageLength = 7, autoWidth = TRUE, scrollX = TRUE, dom = "tip"),
      class = "compact stripe hover"
    )
  })
  
  output$tabla_diccionario <- renderDT({
    DT::datatable(
      diccionario_variables,
      rownames = FALSE,
      options = list(pageLength = 10, autoWidth = TRUE, scrollX = TRUE),
      class = "compact stripe hover"
    )
  })
}

shinyApp(ui, server)
