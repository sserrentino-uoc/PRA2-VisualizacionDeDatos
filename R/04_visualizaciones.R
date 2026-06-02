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

  # Construido con plot_ly directo (no ggplotly) para que cada punto tenga
  # su propio hover. ggplotly + tooltip="text" asigna el texto por trace y
  # replica el primer punto en todos los puntos del trace (bug v3).
  sexos <- sort(unique(as.character(df$sexo)))
  quintiles_pres <- intersect(orden_quintiles, unique(as.character(df$quintil_riqueza)))

  build_subplot <- function(sexo_val, show_legend) {
    sub <- df[as.character(df$sexo) == sexo_val, , drop = FALSE]
    fig <- plotly::plot_ly()
    fig <- plotly::add_segments(
      fig,
      x = orden_edades[1], xend = orden_edades[length(orden_edades)],
      y = 0, yend = 0,
      line = list(color = "#333333", dash = "dash", width = 1),
      showlegend = FALSE, hoverinfo = "skip"
    )
    for (q in quintiles_pres) {
      sub_q <- sub[as.character(sub$quintil_riqueza) == q, , drop = FALSE]
      sub_q <- sub_q[order(match(as.character(sub_q$edad_grupo), orden_edades)), , drop = FALSE]
      if (nrow(sub_q) == 0) next
      hover <- paste0(
        "Sexo: ", sub_q$sexo,
        "<br>Quintil: ", sub_q$quintil_riqueza,
        "<br>Edad: ", sub_q$edad_grupo, " meses",
        "<br>WAZ medio: ", ifelse(is.na(sub_q$waz_medio_plot), "s/d (n < umbral)", num_fmt(sub_q$waz_medio_plot, 2)),
        "<br>Bajo peso: ", pct_fmt(sub_q$prop_bajo_peso, 2),
        "<br>n: ", int_fmt(sub_q$n)
      )
      fig <- plotly::add_trace(
        fig,
        x = as.character(sub_q$edad_grupo),
        y = sub_q$waz_medio_plot,
        text = hover,
        type = "scatter",
        mode = "lines+markers",
        name = q,
        legendgroup = q,
        showlegend = show_legend,
        hoverinfo = "text",
        line = list(color = pal_quintil[[q]], width = 2),
        marker = list(color = pal_quintil[[q]], size = 7)
      )
    }
    plotly::layout(
      fig,
      xaxis = list(title = "Edad en meses", type = "category", categoryorder = "array", categoryarray = orden_edades),
      annotations = list(
        list(text = sexo_val, xref = "paper", yref = "paper",
             x = 0.5, y = 1.02, showarrow = FALSE,
             font = list(size = 13, color = "#1f2933"))
      )
    )
  }

  subplots <- lapply(seq_along(sexos), function(i) build_subplot(sexos[i], show_legend = (i == 1L)))

  caption_text <- paste0(
    "Se ocultan celdas con n < ", n_min, " para evitar conclusiones sobre grupos con escasa muestra."
  )

  plotly::subplot(subplots, nrows = 1, shareY = TRUE, titleX = TRUE, margin = 0.04) |>
    plotly::layout(
      yaxis = list(title = "WAZ medio ponderado (referencia OMS = 0)"),
      legend = list(orientation = "h", y = -0.18, x = 0),
      margin = list(l = 70, r = 20, t = 40, b = 90),
      annotations = list(
        list(
          text = caption_text,
          xref = "paper", yref = "paper",
          x = 0, y = -0.30,
          xanchor = "left", yanchor = "top",
          showarrow = FALSE,
          font = list(size = 11, color = "#506070")
        )
      )
    ) |>
    plotly::config(displaylogo = FALSE)
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

  es_media_libros <- "tipo_indicador" %in% names(df) &&
    any(df$tipo_indicador == "media", na.rm = TRUE)

  valor_fmt <- function(x, digits = 2) {
    if (es_media_libros) {
      num_fmt(x, digits)
    } else {
      pct_fmt(x, digits)
    }
  }

  eje_y <- if (es_media_libros) "Media ponderada de libros" else "Proporción ponderada"
  titulo_leyenda <- if (es_media_libros) "Media de libros" else "Valor"

  if (!is.null(region_input) && region_input != "Todas") {
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
    # Heatmap con plot_ly directo. ggplotly+geom_tile colapsa text por celda (bug v3).
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

  # plot_ly directo. ggplotly+geom_col+dodge colapsa text por trace (bug v3).
  educs_pres <- intersect(names(pal_educ), unique(as.character(df$educ_madre)))
  quintiles_pres <- intersect(orden_quintiles, unique(as.character(df$quintil_riqueza)))

  fig <- plotly::plot_ly()
  for (e in educs_pres) {
    sub <- df[as.character(df$educ_madre) == e, , drop = FALSE]
    sub <- merge(
      data.frame(quintil_riqueza = quintiles_pres, stringsAsFactors = FALSE),
      sub, by = "quintil_riqueza", all.x = TRUE, sort = FALSE
    )
    sub <- sub[match(quintiles_pres, sub$quintil_riqueza), , drop = FALSE]
    hover <- paste0(
      "Quintil: ", sub$quintil_riqueza,
      "<br>Educación materna: ", e,
      "<br>IIP medio: ", ifelse(is.na(sub$iip_medio_plot), "s/d (n < umbral)", paste0(num_fmt(sub$iip_medio_plot, 2), " / 6")),
      "<br>IIP normalizado: ", ifelse(is.na(sub$iip_normalizado_medio), "s/d", pct_fmt(sub$iip_normalizado_medio, 2)),
      "<br>n: ", int_fmt(sub$n)
    )
    fig <- plotly::add_trace(
      fig,
      x = sub$quintil_riqueza,
      y = sub$iip_medio_plot,
      text = hover,
      type = "bar",
      name = e,
      hoverinfo = "text",
      marker = list(color = pal_educ[[e]])
    )
  }

  caption_text <- paste0(
    "Se ocultan celdas con n < ", n_min, " para evitar lecturas sobre subgrupos con escasa muestra."
  )

  plotly::layout(
    fig,
    barmode = "group",
    xaxis = list(title = "Quintil de riqueza", type = "category", categoryorder = "array", categoryarray = quintiles_pres),
    yaxis = list(title = "IIP medio ponderado (0 a 6)", range = c(0, 6)),
    legend = list(orientation = "h", y = -0.20, x = 0, title = list(text = "Educación materna: ")),
    margin = list(l = 70, r = 20, t = 20, b = 110),
    annotations = list(
      list(
        text = caption_text,
        xref = "paper", yref = "paper",
        x = 0, y = -0.36,
        xanchor = "left", yanchor = "top",
        showarrow = FALSE,
        font = list(size = 11, color = "#506070")
      )
    )
  ) |>
    plotly::config(displaylogo = FALSE)
}

plot_iip_region <- function(df, n_min = N_MIN_IIP) {
  # IIP medio ponderado por región. Contrastar dato regional discutido en
  # "Lectura del autor" sin depender solo de texto.
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

  # plot_ly directo (mismo patrón que heatmap).
  hover_text <- paste0(
    "Región: ", df_region$region,
    "<br>IIP medio: ", num_fmt(df_region$iip_medio, 2), " / 6",
    "<br>n: ", int_fmt(df_region$n)
  )

  caption_text <- paste0(
    "Vista comparativa entre regiones: se muestran siempre todas las regiones (el filtro 'Región' no se aplica aquí; sí responde al filtro de Quintil de riqueza). ",
    "Agregación ponderada. Se ocultan regiones con n < ", n_min, "."
  )

  plotly::plot_ly(
    y = df_region$region,
    x = df_region$iip_medio,
    text = hover_text,
    type = "bar",
    orientation = "h",
    hoverinfo = "text",
    marker = list(color = "#2c7fb8")
  ) |>
    plotly::layout(
      xaxis = list(title = "IIP medio ponderado (0 a 6)"),
      yaxis = list(title = "", categoryorder = "array", categoryarray = df_region$region),
      margin = list(l = 80, r = 20, t = 20, b = 90),
      annotations = list(
        list(
          text = caption_text,
          xref = "paper", yref = "paper",
          x = 0, y = -0.22,
          xanchor = "left", yanchor = "top",
          showarrow = FALSE,
          font = list(size = 11, color = "#506070"),
          align = "left"
        )
      )
    ) |>
    plotly::config(displaylogo = FALSE)
}

plot_iip_actividad <- function(df) {
  if (nrow(df) == 0) return(ggplot2::ggplot() + ggplot2::labs(title = "Sin datos para los filtros seleccionados"))

  df$quintil_riqueza <- safe_levels(df$quintil_riqueza, orden_quintiles)

  # plot_ly directo. ggplotly+coord_flip+dodge colapsa text por trace (bug v3).
  quintiles_pres <- intersect(orden_quintiles, unique(as.character(df$quintil_riqueza)))
  ref_q <- if ("Más rico" %in% quintiles_pres) "Más rico" else quintiles_pres[length(quintiles_pres)]
  ref_df <- df[as.character(df$quintil_riqueza) == ref_q, , drop = FALSE]
  ref_df <- ref_df[order(ref_df$prop_actividad, decreasing = FALSE), , drop = FALSE]
  actividad_order <- unique(as.character(ref_df$actividad))
  if (length(actividad_order) == 0) {
    actividad_order <- sort(unique(as.character(df$actividad)))
  }

  fig <- plotly::plot_ly()
  for (q in quintiles_pres) {
    sub <- df[as.character(df$quintil_riqueza) == q, , drop = FALSE]
    sub <- merge(
      data.frame(actividad = actividad_order, stringsAsFactors = FALSE),
      sub, by = "actividad", all.x = TRUE, sort = FALSE
    )
    sub <- sub[match(actividad_order, sub$actividad), , drop = FALSE]
    hover <- paste0(
      "Actividad: ", sub$actividad,
      "<br>Quintil: ", q,
      "<br>Proporción: ", ifelse(is.na(sub$prop_actividad), "s/d", pct_fmt(sub$prop_actividad, 2)),
      "<br>n: ", int_fmt(sub$n)
    )
    fig <- plotly::add_trace(
      fig,
      y = sub$actividad,
      x = sub$prop_actividad,
      text = hover,
      type = "bar",
      orientation = "h",
      name = q,
      hoverinfo = "text",
      marker = list(color = pal_quintil[[q]])
    )
  }

  plotly::layout(
    fig,
    barmode = "group",
    xaxis = list(title = "Proporción ponderada", range = c(0, 1), tickformat = ".0%"),
    yaxis = list(title = "", type = "category", categoryorder = "array", categoryarray = actividad_order),
    legend = list(orientation = "h", y = -0.15, x = 0, title = list(text = "Quintil: ")),
    margin = list(l = 160, r = 20, t = 20, b = 70)
  ) |>
    plotly::config(displaylogo = FALSE)
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
