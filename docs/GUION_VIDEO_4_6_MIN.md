# Guion para el video (4 a 6 minutos)

Versión alineada con el guion final `Entrega/Guion/Guion_Video_PRA2_v4.docx`. Duración objetivo: 5:00 (rango admisible 4–6 min). La estructura está mapeada a los pesos de la rúbrica oficial.

Recursos públicos:

- App pública (sin login): https://sserrentino.shinyapps.io/PRA2-VisualizacionDeDatos/
- Repositorio Git: https://github.com/sserrentino-uoc/PRA2-VisualizacionDeDatos (licencia MIT)

## 0:00–0:20 · Presentación
Autoría, asignatura, título del proyecto y las dos URLs públicas (app en shinyapps.io y repositorio en GitHub con licencia MIT).

## Proceso de creación (20 %)
De PRA1 a PRA2: ampliación del diccionario de variables, controles por edad, sexo y quintil de riqueza, uso de los z-scores antropométricos WAZ2/WAZFLAG provistos por MICS6 (sin recálculo OMS externo), ponderación con `chweight`, validación cruzada R↔Python y corrección del orden de `summarise()` detectada en la auditoría (documentada en la sección 4.2 del informe).

## Conjunto de datos (15 %)
MICS6 Argentina 2019–2020, módulo `ch.sav`, unidad niño/a menor de cinco años, 6.157 registros con peso muestral válido. Mostrar la pestaña Inicio con las tres preguntas guía y los KPIs.

## Presentación en vivo de la app (20 %)
Recorrer Crecimiento → Estimulación → Involucramiento paterno, una pregunta guía por pestaña. Cambiar al menos dos filtros (región NEA y quintil Más pobre), mostrar un tooltip y la lectura guiada.

## Preguntas clave (20 %)
- **P1 (crecimiento):** WAZ medio 0,19; bajo peso 3,76 %; el grupo 0-5 meses muestra el WAZ medio más negativo.
- **P2 (estimulación):** proporción con al menos un libro de 46,22 % en el quintil más pobre a 86,31 % en el más rico (63,11 % nacional); NEA con menor acceso.
- **P3 (involucramiento):** IIP medio 1,26 sobre 6; crece de 0,96 (quintil más pobre) a 1,84 (más rico); actividad más frecuente llevar al niño fuera (30,78 %), menos frecuente contar cuentos (14,70 %).

## Interactividad y accesibilidad (15 %)
Filtros al servicio del análisis (sin controles decorativos), política de incertidumbre n ≥ 25 explicitada en los `helpText`, y paleta Okabe-Ito (sustitución del gris `#999999` por `#D55E00` para el quintil "Más rico"). Limitación declarada: aún sin auditoría WCAG AA formal con axe/WAVE; queda como mejora futura.

## Reflexión final y declaración de IA (10 %)
Qué enseñaron los datos, limitaciones (sesgo de declaración del IIP, no causalidad, diversidad familiar no agotada por MICS6), uso de ChatGPT con revisión humana completa por apartado y mejoras futuras (paquete `survey` de Lumley 2010, auditoría WCAG, comparación regional MICS6). Cerrar con créditos, declaración de IA y enlace al repositorio.
