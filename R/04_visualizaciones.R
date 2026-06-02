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

# Mismo umbral de incertidumbre que en IIP. Aplicado al heatmap de
# Estimulación para evitar lecturas sobre celdas con muestra muy
# pequeña (ej. NEA quintil Más rico con n = 1 en "Tiene al menos un
# libro" muestra 100 % pero no es interpretable).
N_MIN_ESTIMULO <- 25

plot_estimulo <- function(df, region_input = "Todas", n_min = N_MIN_ESTIMULO) {
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
    # Misma política de incertidumbre que el heatmap: si n < umbral,
    # ocultamos el valor (NA) para no comunicar lecturas sobre celdas
    # con muestra muy pequeña al filtrar por una region.
    df$valor_plot <- ifelse(is.na(df$n) | df$n < n_min, NA_real_, df$valor)
    n_oculto_bar <- sum(is.na(df$valor_plot))

    p <- ggplot2::ggplot(
      df,
      ggplot2::aes(
        x = quintil_riqueza,
        y = valor_plot,
        fill = quintil_riqueza,
        text = paste0(
          "Región: ", region,
          "<br>Quintil: ", quintil_riqueza,
          "<br>Indicador: ", indicador_label,
          "<br>Valor: ", ifelse(is.na(valor_plot), paste0("s/d (n < ", n_min, ")"), valor_fmt(valor, 2)),
          "<br>n: ", int_fmt(n)
        )
      )
    ) +
      ggplot2::geom_col(width = 0.65, na.rm = TRUE) +
      ggplot2::scale_fill_manual(values = pal_quintil, drop = FALSE) +
      ggplot2::labs(
        x = "Quintil de riqueza",
        y = eje_y,
        fill = "Quintil",
        caption = if (n_oculto_bar > 0)
          paste0("Se ocultan ", n_oculto_bar, " quintil(es) con n < ", n_min, ".")
        else
          paste0("Se aplica umbral n >= ", n_min, " para evitar lecturas sobre subgrupos con escasa muestra.")
      ) +
      ggplot2::theme_minimal(base_size = 12) +
      ggplot2::theme(
        legend.position = "none",
        panel.grid.minor = ggplot2::element_blank(),
        plot.caption = ggplot2::element_text(size = 9, color = "#506070", hjust = 0)
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

    plotly::ggplotly(p, tooltip = "text")

  } else {
    # Construimos el heatmap directamente con plot_ly() en vez de
    # ggplot2::geom_tile + ggplotly. Razón: ggplotly() colapsa el
    # aes(text=...) de geom_tile y replica el texto de la primera fila
    # en todas las celdas (bug detectado en deploy v3 sobre shinyapps.io,
    # tooltip mostraba el mismo Valor/n para cada celda).
    # Con plot_ly heatmap pasamos matrices z y text por celda y el
    # tooltip queda correcto.
    region_order <- sort(unique(as.character(df$region)))
    quintil_order <- levels(df$quintil_riqueza)
    if (is.null(quintil_order)) {
      quintil_order <- sort(unique(as.character(df$quintil_riqueza)))
    }

    df$region <- factor(df$region, levels = region_order)
    df$quintil_riqueza <- factor(df$quintil_riqueza, levels = quintil_order)

    z_mat <- matrix(NA_real_, nrow = length(region_order), ncol = length(quintil_order),
                    dimnames = list(region_order, quintil_order))
    text_mat <- matrix("", nrow = length(region_order), ncol = length(quintil_order),
                       dimnames = list(region_order, quintil_order))

    n_oculto <- 0L
    for (i in seq_len(nrow(df))) {
      r <- as.character(df$region[i])
      q <- as.character(df$quintil_riqueza[i])
      n_i <- df$n[i]
      bajo_umbral <- is.na(n_i) || n_i < n_min

      if (bajo_umbral) {
        n_oculto <- n_oculto + 1L
        z_mat[r, q] <- NA_real_
        text_mat[r, q] <- paste0(
          "Región: ", r,
          "<br>Quintil: ", q,
          "<br>Indicador: ", df$indicador_label[i],
          "<br>Valor: s/d (n < ", n_min, ")",
          "<br>n: ", int_fmt(n_i)
        )
      } else {
        z_mat[r, q] <- df$valor[i]
        text_mat[r, q] <- paste0(
          "Región: ", r,
          "<br>Quintil: ", q,
          "<br>Indicador: ", df$indicador_label[i],
          "<br>Valor: ", valor_fmt(df$valor[i], 2),
          "<br>n: ", int_fmt(n_i)
        )
      }
    }

    if (all(is.na(z_mat))) {
      return(
        ggplot2::ggplot() +
          ggplot2::annotate("text", x = 1, y = 1,
                            label = paste0(
                              "Ninguna celda alcanza el umbral minimo (n >= ",
                              n_min, ") para mostrar el indicador seleccionado."
                            ),
                            color = "#506070", size = 4.2) +
          ggplot2::theme_void()
      )
    }

    colorbar_ticks <- pretty(range(z_mat, na.rm = TRUE), n = 5)
    colorbar_text <- vapply(colorbar_ticks, valor_fmt, character(1),
                            digits = if (es_media_libros) 1 else 0)

    caption_text <- paste0(
      "Se ocultan celdas con n < ", n_min, " para evitar lecturas sobre subgrupos con escasa muestra."
    )
    if (n_oculto > 0L) {
      caption_text <- paste0(caption_text, " Celdas ocultas en esta vista: ", n_oculto, ".")
    }

    plotly::plot_ly(
      x = quintil_order,
      y = region_order,
      z = z_mat,
      text = text_mat,
      type = "heatmap",
      hoverinfo = "text",
      xgap = 2,
      ygap = 2,
      colorscale = list(c(0, "#f7fbff"), c(1, "#084081")),
      colorbar = list(
        title = titulo_leyenda,
        tickmode = "array",
        tickvals = colorbar_ticks,
        ticktext = colorbar_text
      )
    ) |>
      plotly::layout(
        xaxis = list(title = "Quintil de riqueza", type = "category"),
        yaxis = list(title = "Región", type = "category", autorange = "reversed"),
        margin = list(l = 80, r = 20, t = 40, b = 80),
        annotations = list(
          list(
            text = caption_text,
            xref = "paper", yref = "paper",
            x = 0, y = -0.18,
            xanchor = "left", yanchor = "top",
            showarrow = FALSE,
            font = list(size = 11, color = "#506070")
          )
        )
      ) |>
      plotly::config(displaylogo = FALSE)
  }
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

plot_iip_region <- function(df, n_min = N_MIN_IIP) {
  # IIP medio ponderado por región. Permite contrastar el dato regional
  # (Cuyo 1,45 / Patagonia 1,07) que se discute en la "Lectura del autor"
  # y que de otro modo solo aparece como texto.
  if (is.null(df) || nrow(df) == 0) {
    return(
      ggplot2::ggplot() +
        ggplot2::annotate("text", x = 1, y = 1,
                          label = "Sin datos para los filtros seleccionados.",
                          color = "#506070", size = 4.5) +
        ggplot2::theme_void()
    )
  }

  df_region <- df |>
    dplyr::group_by(region) |>
    dplyr::summarise(
      n = sum(n, na.rm = TRUE),
      iip_medio = weighted_avg(iip_medio, peso_muestral),
      .groups = "drop"
    ) |>
    dplyr::mutate(iip_medio = ifelse(is.na(n) | n < n_min, NA_real_, iip_medio)) |>
    dplyr::filter(!is.na(region))

  if (nrow(df_region) == 0 || all(is.na(df_region$iip_medio))) {
    return(
      ggplot2::ggplot() +
        ggplot2::annotate("text", x = 1, y = 1,
                          label = paste0(
                            "Los filtros seleccionados no alcanzan el umbral minimo (n >= ",
                            n_min, ") para mostrar el IIP regional."
                          ),
                          color = "#506070", size = 4.2) +
        ggplot2::theme_void()
    )
  }

  df_region <- df_region[order(df_region$iip_medio, decreasing = FALSE), , drop = FALSE]
  df_region$region <- factor(df_region$region, levels = df_region$region)

  p <- ggplot2::ggplot(
    df_region,
    ggplot2::aes(
      x = region,
      y = iip_medio,
      text = paste0(
        "Región: ", region,
        "<br>IIP medio: ", num_fmt(iip_medio, 2), " / 6",
        "<br>n: ", int_fmt(n)
      )
    )
  ) +
    ggplot2::geom_col(fill = "#2c7fb8", width = 0.65) +
    ggplot2::coord_flip() +
    ggplot2::scale_y_continuous(limits = c(0, NA)) +
    ggplot2::labs(
      x = NULL,
      y = "IIP medio ponderado (0 a 6)",
      caption = paste0(
        "Vista comparativa entre regiones: se muestran siempre todas las regiones (el filtro 'Región' no se aplica aquí; sí responde al filtro de Quintil de riqueza). ",
        "Agregación ponderada. Se ocultan regiones con n < ", n_min, "."
      )
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      plot.caption = ggplot2::element_text(size = 9, color = "#506070", hjust = 0)
    )

  plotly::ggplotly(p, tooltip = "text")
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
