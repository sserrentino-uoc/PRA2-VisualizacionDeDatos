# Anexo metodológico y referencias APA 7

## Diseño metodológico

La aplicación Shiny fue diseñada como una visualización interactiva y comunicativa. El objetivo es facilitar la exploración de patrones descriptivos entre crecimiento infantil, desigualdad socioeconómica, territorio y corresponsabilidad paterna en la primera infancia argentina.

El enfoque sigue la lógica de visualización como herramienta para transformar datos en información comprensible, favorecer comparación entre grupos y permitir exploración mediante filtros y detalle bajo demanda.

## Datos

Fuente principal: Encuesta Nacional de Niños, Niñas y Adolescentes MICS6 Argentina 2019–2020, módulo de niños y niñas menores de cinco años (`ch.sav`).

Unidad de análisis: niño/a menor de cinco años.

## Indicadores principales

- **WAZ**: z-score de peso para la edad según referencia OMS, usando `WAZ2` cuando `WAZFLAG == 0`.
- **Bajo peso**: indicador binario `WAZ < -2`.
- **Estimulación temprana**: disponibilidad de libros, juguetes caseros, juguetes comprados y objetos del hogar/exterior para juego.
- **IIP**: Índice de Involucramiento Paterno, construido como suma de seis actividades declaradas del padre: leer, contar cuentos, cantar, llevar fuera, jugar y nombrar/contar/dibujar.
- **Ponderación**: uso del ponderador `chweight` cuando corresponde.

## Limitaciones

1. El análisis es descriptivo y no causal.
2. El IIP resume actividades declaradas, pero no mide intensidad, frecuencia exacta, calidad del vínculo ni distribución total del cuidado.
3. Los indicadores antropométricos dependen de la calidad de medición y de las banderas de validez incluidas en la base.
4. La publicación usa tablas agregadas para evitar exposición innecesaria de microdatos.

## Referencias APA 7 sugeridas

Alcalde, I., & Minguillón, J. (s. f.). *Introducción a la visualización de la información*. Fundació Universitat Oberta de Catalunya.

Minguillón Alfonso, J. (2021). *Guía de lecturas en el ámbito de la visualización de datos* (3.ª ed.). Fundació Universitat Oberta de Catalunya.

UNICEF, & Consejo Nacional de Coordinación de Políticas Sociales. (2021). *Encuesta Nacional de Niños, Niñas y Adolescentes MICS Argentina 2019–2020*. UNICEF.

World Health Organization. (2006). *WHO child growth standards: Length/height-for-age, weight-for-age, weight-for-length, weight-for-height and body mass index-for-age: Methods and development*. World Health Organization.

OpenAI. (2026). *ChatGPT* [Modelo de lenguaje grande]. https://chat.openai.com/

## Declaración de uso de IA

ChatGPT fue utilizado como apoyo para estructuración del proyecto, revisión de consigna, generación y depuración de código, documentación metodológica y validación cruzada conceptual. Todas las salidas fueron revisadas, adaptadas y validadas por el autor antes de incorporarse a la entrega final.
