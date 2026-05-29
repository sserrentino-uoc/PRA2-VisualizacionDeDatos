# =========================================================
# PRA2 - Visualización de Datos
# Funciones de visualización
# =========================================================

# Paleta Okabe-Ito sincronizada con pal_quintil de R/00_config.R.
# Accesible para personas con visión de color reducida.
pal_quintil <- c(
  "Más pobre" = "#E69F00",
  "Segundo"   = "#009E73",
  "Medio"     = "#0072B2",
  "Cuarto"    = "#CC79A7",
  "Más rico"  = "#D55E00"
)

pal_educ <- c(
  "Hasta Secundario incompleto" = "#E69F00",
  "Secundario completo / Terciario o Universitario incompleto" = "#009E73",
  "Terciario completo" = "#0072B2",
  "No sabe / no responde" = "#CC79A7"
)

orden_quintiles <- c("Más pobre", "Segundo", "Medio", "Cuarto", "Más rico")
orden_edades <- c("0-5", "6-11", "12-23", "24-35", "36-47", "48-59")

# Política de incertidumbre para el grafico de crecimiento: las celdas con
# menos observaciones que el umbral se ocultan visualmente, pero las lineas
# se preservan uniendo los puntos validos contiguos. Si todas las celdas
# quedan vacias, se muestra un placeholder explicito.
N_MIN_CRECIMIENTO <- 25

plot_crecimiento <- function(df, n_min = N_MIN_CRECIMIENTO) {
  if (is.null(df) || nrow(df) == 0) {
    return(
      ggplot2::ggplot() +
        ggplot2::annotate("text", x = 1, y = 1,
                          label = "Sin datos suficientes para los filtros seleccionados.",
                          color = "#506070", size = 4.5) +
        ggplot2::theme_void()
    )
  }

  df$quintil_riqueza <- safe_levels(df$quintil_riqueza, orden_quintiles)
  df$edad_grupo <- safe_levels(df$edad_grupo, orden_edades)

  # Marcado de incertidumbre: ocultar valores con n < umbral o con WAZ NA
  # para evitar conclusiones sobre celdas estadísticamente débiles.
  df$waz_medio_plot <- ifelse(is.na(df$n) | df$n < n_min, NA_real_, df$waz_medio)

  if (all(is.na(df$waz_medio_plot))) {
    return(
      ggplot2::ggplot() +
        ggplot2::annotate("text", x = 1, y = 1,
                          label = paste0(
                            "Los filtros seleccionados no alcanzan el umbral mínimo (n >= ",
                            n_min, ") para mostrar el WAZ medio."
                          ),
                          color = "#506070", size = 4.2) +
        ggplot2::theme_void()
    )
  }

  p <- ggplot2::ggplot(
    df,
    ggplot2::aes(
      x = edad_grupo,
      y = waz_medio_plot,
      group = quintil_riqueza,
      color = quintil_riqueza,
      text = paste0(
        "Sexo: ", sexo,
        "<br>Quintil: ", quintil_riqueza,
        "<br>Edad: ", edad_grupo, " meses",
        "<br>WAZ medio: ", ifelse(is.na(waz_medio_plot), "s/d (n < umbral)", num_fmt(waz_medio_plot, 2)),
        "<br>Bajo peso: ", pct_fmt(prop_bajo_peso, 2),
        "<br>n: ", int_fmt(n)
      )
    )
  ) +
    ggplot2::geom_hline(yintercept = 0, linetype = "dashed", linewidth = 0.4, color = "#333333") +
    # na.rm = TRUE evita warnings y preserva la línea uniendo puntos válidos.
    ggplot2::geom_line(linewidth = 0.75, alpha = 0.85, na.rm = TRUE) +
    ggplot2::geom_point(size = 2.2, alpha = 0.95, na.rm = TRUE) +
    ggplot2::facet_wrap(~sexo, nrow = 1) +
    ggplot2::scale_color_manual(values = pal_quintil, drop = FALSE) +
    ggplot2::labs(
      x = "Edad en meses",
      y = "WAZ medio ponderado (referencia OMS = 0)",
      color = "Quintil",
      caption = paste0("Se ocultan celdas con n < ", n_min,
                       " para evitar conclusiones sobre grupos con escasa muestra."),
      title = NULL
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      legend.position = "bottom",
      panel.grid.minor = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(face = "bold"),
      axis.text.x = ggplot2::element_text(angle = 0, hjust = 0.5),
      plot.caption = ggplot2::element_text(size = 9, color = "#506070", hjust = 0)
    )

  plotly::ggplotly(p, tooltip = "text") |> plotly::layout(legend = list(orientation = "h", y = -0.2))
}

plot_estimulo <- function(df, region_input = "Todas") {
  if (nrow(df) == 0) {
    return(
      ggplot2::ggplot() +
        ggplot2::labs(title = "Sin datos para los filtros seleccionados")
    )
  }
  
  df$quintil_riqueza <- safe_levels(df$quintil_riqueza, orden_quintiles)
  
  # Detecta si el indicador seleccionado es "Media de libros".
  # Se controla tanto por el nombre técnico como por la etiqueta visible.
  # Detecta si el indicador seleccionado es una media numérica y no una proporción.
  # Esta metadata se genera en R/03_tablas_visualizacion.R.
  es_media_libros <- "tipo_indicador" %in% names(df) &&
    any(df$tipo_indicador == "media", na.rm = TRUE)
  
  # Formato correcto según tipo de indicador:
  # - media_libros: número medio de libros
  # - resto: porcentaje/proporción
  valor_fmt <- function(x, digits = 2) {
    if (es_media_libros) {
      num_fmt(x, digits)
    } else {
      pct_fmt(x, digits)
    }
  }
  
  eje_y <- if (es_media_libros) {
    "Media ponderada de libros"
  } else {
    "Proporción ponderada"
  }
  
  titulo_leyenda <- if (es_media_libros) {
    "Media de libros"
  } else {
    "Valor"
  }
  
  if (!is.null(region_input) && region_input != "Todas") {
    p <- ggplot2::ggplot(
      df,
      ggplot2::aes(
        x = quintil_riqueza,
        y = valor,
        fill = quintil_riqueza,
        text = paste0(
          "Región: ", region,
          "<br>Quintil: ", quintil_riqueza,
          "<br>Indicador: ", indicador_label,
          "<br>Valor: ", valor_fmt(valor, 2),
          "<br>n: ", int_fmt(n)
        )
      )
    ) +
      ggplot2::geom_col(width = 0.65) +
      ggplot2::scale_fill_manual(values = pal_quintil, drop = FALSE) +
      ggplot2::labs(
        x = "Quintil de riqueza",
        y = eje_y,
        fill = "Quintil"
      ) +
      ggplot2::theme_minimal(base_size = 12) +
      ggplot2::theme(
        legend.position = "none",
        panel.grid.minor = ggplot2::element_blank()
      )
    
    if (es_media_libros) {
      p <- p +
        ggplot2::scale_y_continuous(
          labels = function(x) vapply(x, valor_fmt, character(1), digits = 1),
          limits = c(0, NA)
        )
    } else {
      p <- p +
        ggplot2::scale_y_continuous(
          labels = function(x) vapply(x, pct_fmt, character(1), digits = 0),
          limits = c(0, 1)
        )
    }
    
  } else {
    p <- ggplot2::ggplot(
      df,
      ggplot2::aes(
        x = quintil_riqueza,
        y = region,
        fill = valor,
        text = paste0(
          "Región: ", region,
          "<br>Quintil: ", quintil_riqueza,
          "<br>Indicador: ", indicador_label,
          "<br>Valor: ", valor_fmt(valor, 2),
          "<br>n: ", int_fmt(n)
        )
      )
    ) +
      ggplot2::geom_tile(color = "white", linewidth = 0.7) +
      ggplot2::scale_fill_gradient(
        low = "#f7fbff",
        high = "#084081",
        labels = function(x) vapply(x, valor_fmt, character(1), digits = if (es_media_libros) 1 else 0)
      ) +
      ggplot2::labs(
        x = "Quintil de riqueza",
        y = "Región",
        fill = titulo_leyenda
      ) +
      ggplot2::theme_minimal(base_size = 12) +
      ggplot2::theme(
        panel.grid = ggplot2::element_blank(),
        legend.position = "right"
      )
  }
  
  plotly::ggplotly(p, tooltip = "text")
}

# Mismo umbral que en R/03_tablas_visualizacion.R: el grafico aplica la
# politica de incertidumbre incluso si la tabla llegara sin filtrar.
N_MIN_IIP <- 25

plot_iip <- function(df, n_min = N_MIN_IIP) {
  if (is.null(df) || nrow(df) == 0) {
    return(
      ggplot2::ggplot() +
        ggplot2::annotate("text", x = 1, y = 1,
                          label = "Sin datos para los filtros seleccionados.",
                          color = "#506070", size = 4.5) +
        ggplot2::theme_void()
    )
  }

  df$quintil_riqueza <- safe_levels(df$quintil_riqueza, orden_quintiles)
  # Oculta visualmente celdas con n por debajo del umbral.
  df$iip_medio_plot <- ifelse(is.na(df$n) | df$n < n_min, NA_real_, df$iip_medio)

  if (all(is.na(df$iip_medio_plot))) {
    return(
      ggplot2::ggplot() +
        ggplot2::annotate("text", x = 1, y = 1,
                          label = paste0(
                            "Los filtros seleccionados no alcanzan el umbral minimo (n >= ",
                            n_min, ") para mostrar el IIP."
                          ),
                          color = "#506070", size = 4.2) +
        ggplot2::theme_void()
    )
  }

  p <- ggplot2::ggplot(
    df,
    ggplot2::aes(
      x = quintil_riqueza,
      y = iip_medio_plot,
      fill = educ_madre,
      text = paste0(
        "Quintil: ", quintil_riqueza,
        "<br>Educación materna: ", educ_madre,
        "<br>IIP medio: ", ifelse(is.na(iip_medio_plot), "s/d (n < umbral)", paste0(num_fmt(iip_medio_plot, 2), " / 6")),
        "<br>IIP normalizado: ", ifelse(is.na(iip_normalizado_medio), "s/d", pct_fmt(iip_normalizado_medio, 2)),
        "<br>n: ", int_fmt(n)
      )
    )
  ) +
    ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.75), width = 0.68, na.rm = TRUE) +
    ggplot2::scale_fill_manual(values = pal_educ, drop = FALSE) +
    ggplot2::scale_y_continuous(limits = c(0, 6)) +
    ggplot2::labs(
      x = "Quintil de riqueza",
      y = "IIP medio ponderado (0 a 6)",
      fill = "Educación materna",
      caption = paste0("Se ocultan celdas con n < ", n_min,
                       " para evitar lecturas sobre subgrupos con escasa muestra.")
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      legend.position = "bottom",
      panel.grid.minor = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(angle = 0, hjust = 0.5),
      plot.caption = ggplot2::element_text(size = 9, color = "#506070", hjust = 0)
    )

  plotly::ggplotly(p, tooltip = "text") |> plotly::layout(legend = list(orientation = "h", y = -0.28))
}

plot_iip_actividad <- function(df) {
  if (nrow(df) == 0) return(ggplot2::ggplot() + ggplot2::labs(title = "Sin datos para los filtros seleccionados"))
  
  df$quintil_riqueza <- safe_levels(df$quintil_riqueza, orden_quintiles)
  
  p <- ggplot2::ggplot(
    df,
    ggplot2::aes(
      x = actividad,
      y = prop_actividad,
      fill = quintil_riqueza,
      text = paste0(
        "Actividad: ", actividad,
        "<br>Quintil: ", quintil_riqueza,
        "<br>Proporción: ", pct_fmt(prop_actividad, 2),
        "<br>n: ", int_fmt(n)
      )
    )
  ) +
    ggplot2::geom_col(position = ggplot2::position_dodge(width = 0.75), width = 0.68) +
    ggplot2::coord_flip() +
    ggplot2::scale_fill_manual(values = pal_quintil, drop = FALSE) +
    ggplot2::scale_y_continuous(labels = function(x) vapply(x, pct_fmt, character(1), digits = 0), limits = c(0, 1)) +
    ggplot2::labs(x = NULL, y = "Proporción ponderada", fill = "Quintil") +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      legend.position = "bottom",
      panel.grid.minor = ggplot2::element_blank()
    )
  
  plotly::ggplotly(p, tooltip = "text") |> plotly::layout(legend = list(orientation = "h", y = -0.18))
}

plot_calidad <- function(df) {
  df <- df[order(df$pct_faltantes, decreasing = TRUE), , drop = FALSE]
  df$variable <- factor(df$variable, levels = rev(df$variable))
  
  p <- ggplot2::ggplot(
    df,
    ggplot2::aes(
      x = variable,
      y = pct_faltantes,
      text = paste0(
        "Variable: ", variable,
        "<br>Faltantes: ", int_fmt(faltantes),
        "<br>% faltantes: ", pct_fmt(pct_faltantes, 2)
      )
    )
  ) +
    ggplot2::geom_col(fill = "#5f6a70", width = 0.65) +
    ggplot2::coord_flip() +
    ggplot2::scale_y_continuous(labels = function(x) vapply(x, pct_fmt, character(1), digits = 0)) +
    ggplot2::labs(x = NULL, y = "% de faltantes") +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank())
  
  plotly::ggplotly(p, tooltip = "text")
}
