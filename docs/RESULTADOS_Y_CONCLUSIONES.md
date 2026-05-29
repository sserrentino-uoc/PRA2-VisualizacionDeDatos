# Resultados, indicadores y conclusiones finales

## Indicadores generales validados

La validación independiente Python vs. R confirmó que las tablas finales de la app se reproducen exactamente a partir del pipeline corregido.

| Indicador | Valor final |
|---|---:|
| Registros con ponderador válido | 6157 |
| WAZ medio ponderado | 0,19 |
| Proporción de bajo peso | 3,76 % |
| Proporción con al menos un libro | 63,11 % |
| IIP medio ponderado | 1,26 / 6 |

## Conclusiones sustantivas

Las conclusiones conceptuales no cambiaron respecto de la narrativa definida para la PRA2. La validación en Python no contradijo la interpretación general; sirvió para corregir la trazabilidad entre scripts, tablas agregadas y app publicada.

1. La visualización sigue mostrando un enfoque descriptivo sobre desigualdad, territorio y corresponsabilidad paterna en primera infancia.
2. Los indicadores de estimulación temprana continúan mostrando diferencias comparables por quintil de riqueza y región.
3. El IIP mantiene su carácter exploratorio: resume seis actividades declaradas del padre y no mide calidad del vínculo, intensidad del cuidado ni causalidad.
4. El WAZ se mantiene como indicador antropométrico principal filtrado por validez, usando WAZ2 y WAZFLAG.
5. La app debe interpretarse como una herramienta de exploración y comunicación, no como un modelo explicativo causal.

## Qué sí cambió tras la validación Python

La narrativa no cambió, pero sí se corrigieron aspectos técnicos relevantes:

- `R/03_tablas_visualizacion.R` ahora genera las mismas tablas que consume la app.
- `tabla_estimulo.csv` incluye explícitamente `media_libros`, además de las proporciones de disponibilidad de materiales.
- `kpis.csv` usa como base de registros los casos con ponderador válido.
- Se preserva `chweight` y se distingue de `peso_muestral` limpio.
- `deploy.R` fue corregido para no subir microdatos ni bases individuales si el pipeline completo fue regenerado.

## Resultado de validación cruzada

Todas las tablas finales comparadas entre Python y R presentaron igualdad exacta en estructura y valores numéricos:

- `kpis`: OK
- `tabla_crecimiento`: OK
- `tabla_estimulo`: OK
- `tabla_iip`: OK
- `tabla_iip_actividad`: OK
- `calidad_variables`: OK
- `decisiones_limpieza`: OK
- `diccionario_variables`: OK

Resultado: el análisis final es el mismo; las correcciones mejoran reproducibilidad, trazabilidad y defensa académica.
