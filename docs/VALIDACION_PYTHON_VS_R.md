# Validación cruzada Python vs R

Fecha: 2026-05-27

Se reprodujo en Python la lógica de transformación y agregación del pipeline R final usando el archivo `ch.sav` de MICS6 Argentina.

Resultado de ejecución:

```text
Usando ch.sav: /tmp/pra2_mics6_lrqaxn5e/ch.sav

Comparación Python vs R:
                tabla estado  filas_esperadas  filas_python  columnas_esperadas  columnas_python  max_abs_diff                              detalle
                 kpis     OK                1             1                   5                5           0.0 celdas distintas=0; max_abs_diff=0.0
    tabla_crecimiento     OK              344           344                   8                8           0.0 celdas distintas=0; max_abs_diff=0.0
       tabla_estimulo     OK              150           150                   7                7           0.0 celdas distintas=0; max_abs_diff=0.0
            tabla_iip     OK               91            91                   7                7           0.0 celdas distintas=0; max_abs_diff=0.0
  tabla_iip_actividad     OK              180           180                   6                6           0.0 celdas distintas=0; max_abs_diff=0.0
    calidad_variables     OK               14            14                   4                4           0.0 celdas distintas=0; max_abs_diff=0.0
  decisiones_limpieza     OK                7             7                   4                4           0.0   celdas distintas=0; max_abs_diff=0
diccionario_variables     OK               11            11                   3                3           0.0   celdas distintas=0; max_abs_diff=0

Resultado: OK. Python reproduce las tablas finales generadas por R.
```

Nota: el aviso de `Spreadsheet runtime warmup` mostrado en stderr corresponde al entorno interno de ejecución y no afecta al resultado del script Python.
