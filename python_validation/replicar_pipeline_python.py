#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Validación independiente en Python del pipeline R de PRA2.

Objetivo:
- Reproducir la lógica de:
  R/01_preparacion_datos.R
  R/02_exploracion_calidad.R
  R/03_tablas_visualizacion.R
- Generar las mismas tablas agregadas que consume la Shiny app.
- Compararlas con data_processed/*.csv.

Uso desde la raíz del proyecto:
  python python_validation/replicar_pipeline_python.py --raw-zip "../drive-download-20260527T092605Z-3-001.zip"
o:
  python python_validation/replicar_pipeline_python.py --ch-sav "data_raw/ch.sav"

Requisitos:
  pip install pandas numpy pyreadstat
"""

from __future__ import annotations

import argparse
import os
import shutil
import tempfile
import zipfile
from pathlib import Path
from typing import Iterable, Optional

import numpy as np
import pandas as pd
import pyreadstat


ORDEN_QUINTILES = ["Más pobre", "Segundo", "Medio", "Cuarto", "Más rico"]
ORDEN_EDADES = ["0-5", "6-11", "12-23", "24-35", "36-47", "48-59"]
ORDEN_SEXO = ["Varón", "Mujer"]

USECOLS = [
    "HH1", "HH2", "LN", "stratum", "HL4", "windex5", "melevel",
    "CAGE_AN", "CAGE", "chweight", "AN8", "AN11", "WAZFLAG", "WAZ2",
    "EC1", "EC2A", "EC2B", "EC2C",
    "EC5AB", "EC5BB", "EC5CB", "EC5DB", "EC5EB", "EC5FB",
]

PROJECT_ROOT = Path(__file__).resolve().parents[1]

def project_path(path: Path) -> Path:
    """Devuelve una ruta absoluta, relativa a la raíz del proyecto si es relativa."""
    return path if path.is_absolute() else PROJECT_ROOT / path


def find_ch_sav_from_zip(raw_zip: Path) -> Path:
    """Extrae un ZIP temporalmente y devuelve una ruta a ch.sav."""
    if not raw_zip.exists():
        raise FileNotFoundError(f"No existe el ZIP: {raw_zip}")

    tmp = Path(tempfile.mkdtemp(prefix="pra2_mics6_"))
    with zipfile.ZipFile(raw_zip, "r") as z:
        z.extractall(tmp)

    # Caso 1: ch.sav directamente dentro del ZIP.
    candidates = list(tmp.rglob("ch.sav"))

    # Caso 2: ZIP interno con datasets MICS6.
    for inner_zip in tmp.rglob("*.zip"):
        if inner_zip.name == raw_zip.name:
            continue
        inner_dir = tmp / f"_inner_{inner_zip.stem}"
        inner_dir.mkdir(exist_ok=True)
        try:
            with zipfile.ZipFile(inner_zip, "r") as z2:
                z2.extractall(inner_dir)
            candidates.extend(inner_dir.rglob("ch.sav"))
        except zipfile.BadZipFile:
            pass

    if not candidates:
        raise FileNotFoundError(f"No se encontró ch.sav dentro de {raw_zip}")

    # Preferir el ch.sav más cercano a raíz si existe.
    return sorted(candidates, key=lambda p: len(p.parts))[0]


def weighted_avg(value: Iterable, weight: Iterable) -> float:
    v = pd.to_numeric(pd.Series(value), errors="coerce")
    w = pd.to_numeric(pd.Series(weight), errors="coerce")
    ok = v.notna() & w.notna() & (w > 0)
    if not ok.any():
        return np.nan
    return float(np.average(v[ok], weights=w[ok]))


def clean_numeric(x: pd.Series, invalid=(98, 99, 999, 999.9, 99.9)) -> pd.Series:
    out = pd.to_numeric(x, errors="coerce")
    return out.mask(out.isin(invalid), np.nan)


def yes_no_1(x: pd.Series) -> pd.Series:
    out = pd.to_numeric(x, errors="coerce")
    return pd.Series(np.select([out.isna(), out == 1, out == 2], [np.nan, 1.0, 0.0], default=np.nan), index=x.index)


def father_activity(x: pd.Series, code: str = "B") -> pd.Series:
    raw = x.astype("string").str.strip()
    # Mantener NA reales como NA. StringDtype convierte NaN a <NA>, no a "nan".
    out = pd.Series(np.where(raw == code, 1.0, 0.0), index=x.index, dtype="float64")
    out = out.mask(raw.isna(), np.nan)
    out = out.mask(raw == "?", np.nan)
    return out


def format_label_series(s: pd.Series) -> pd.Series:
    """Convierte categorías/objetos pyreadstat a string, manteniendo faltantes como NaN."""
    out = s.astype("object")
    return out.where(pd.notna(out), np.nan)


def recode_sexo(s: pd.Series) -> pd.Series:
    return format_label_series(s).replace({"VARÓN": "Varón", "MUJER": "Mujer"})


def recode_educ_madre(s: pd.Series) -> pd.Series:
    return format_label_series(s).replace({"No sabe o no responde": "No sabe / no responde"})


def coalesce(a: pd.Series, b: pd.Series) -> pd.Series:
    return a.combine_first(b)


def build_base(ch_sav: Path) -> pd.DataFrame:
    raw, _ = pyreadstat.read_sav(str(ch_sav), usecols=USECOLS, apply_value_formats=False)
    fmt, _ = pyreadstat.read_sav(str(ch_sav), usecols=USECOLS, apply_value_formats=True)

    edad_meses = clean_numeric(coalesce(raw["CAGE_AN"], raw["CAGE"]), invalid=(98, 99, 999))
    edad_grupo = pd.cut(
        edad_meses,
        bins=[-np.inf, 5, 11, 23, 35, 47, 59],
        labels=ORDEN_EDADES,
        right=True,
    )

    wazflag = pd.to_numeric(raw["WAZFLAG"], errors="coerce")
    waz2 = pd.to_numeric(raw["WAZ2"], errors="coerce")
    waz_oms = waz2.where((wazflag == 0) & (waz2 < 90), np.nan)

    base = pd.DataFrame({
        "id_nino": raw["HH1"].astype(int).astype(str) + "-" + raw["HH2"].astype(int).astype(str) + "-" + raw["LN"].astype(int).astype(str),
        "region": format_label_series(fmt["stratum"]),
        "sexo": recode_sexo(fmt["HL4"]),
        "quintil_riqueza": format_label_series(fmt["windex5"]),
        "educ_madre": recode_educ_madre(fmt["melevel"]),
        "edad_meses": edad_meses,
        "edad_grupo": edad_grupo.astype("object"),
        "chweight": pd.to_numeric(raw["chweight"], errors="coerce"),
        "peso_muestral": clean_numeric(raw["chweight"], invalid=(0, 98, 99, 999, 999.9)),
        "peso_kg": clean_numeric(raw["AN8"], invalid=(99.9, 99, 999, 999.9)),
        "talla_cm": clean_numeric(raw["AN11"], invalid=(99.9, 99, 999, 999.9)),
        "wazflag": wazflag,
        "waz_oms": waz_oms,
        "bajo_peso": (waz_oms < -2).astype(float).where(waz_oms.notna(), np.nan),
        "libros_n": clean_numeric(raw["EC1"], invalid=(98, 99)),
        "juguete_casero": yes_no_1(raw["EC2A"]),
        "juguete_comprado": yes_no_1(raw["EC2B"]),
        "objeto_hogar_juego": yes_no_1(raw["EC2C"]),
        "padre_leyo": father_activity(raw["EC5AB"], "B"),
        "padre_conto_cuentos": father_activity(raw["EC5BB"], "B"),
        "padre_canto": father_activity(raw["EC5CB"], "B"),
        "padre_llevo_fuera": father_activity(raw["EC5DB"], "B"),
        "padre_jugo": father_activity(raw["EC5EB"], "B"),
        "padre_nombro_conto_dibujo": father_activity(raw["EC5FB"], "B"),
    })

    base["tiene_libros"] = (base["libros_n"] > 0).astype(float).where(base["libros_n"].notna(), np.nan)

    padre_cols = [c for c in base.columns if c.startswith("padre_")]
    valid_counts = base[padre_cols].notna().sum(axis=1)
    base["iip"] = base[padre_cols].sum(axis=1, skipna=True).astype(float)
    base.loc[valid_counts == 0, "iip"] = np.nan
    base["iip_normalizado"] = base["iip"] / 6.0

    # Emular factor(..., levels=...): valores no contemplados pasan a NA.
    base["sexo"] = base["sexo"].where(base["sexo"].isin(ORDEN_SEXO), np.nan)
    base["quintil_riqueza"] = base["quintil_riqueza"].where(base["quintil_riqueza"].isin(ORDEN_QUINTILES), np.nan)
    base["edad_grupo"] = base["edad_grupo"].where(base["edad_grupo"].isin(ORDEN_EDADES), np.nan)

    return base


def calidad_y_documentacion(base: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    # Orden y variables equivalentes al archivo R final.
    # "chweight" se reporta como nombre original de la variable,
    # pero se calcula sobre la columna procesada peso_muestral.
    vars_calidad = [
        "bajo_peso", "waz_oms", "talla_cm", "peso_kg", "libros_n",
        "tiene_libros", "quintil_riqueza", "edad_meses", "educ_madre",
        "sexo", "iip", "iip_normalizado", "chweight", "region"
    ]
    calidad_rows = []
    for v in vars_calidad:
        col = v
        if col not in base.columns:
            continue
        calidad_rows.append({
            "variable": v,
            "n": len(base),
            "faltantes": int(base[col].isna().sum())
        })
    calidad = pd.DataFrame(calidad_rows)
    calidad["pct_faltantes"] = calidad["faltantes"] / calidad["n"]
    # Mantener el orden esperado por la app/informe, no ordenar alfabéticamente.
    calidad = calidad.reset_index(drop=True)

    decisiones = pd.DataFrame({
        "dimension": [
            "Antropometría", "Peso/talla", "Estimulación", "IIP", "Privacidad",
            "Ponderación", "Interpretación"
        ],
        "problema_detectado": [
            "WAZ2 contiene valores fuera de rango y WAZFLAG marca errores",
            "Códigos especiales como 99/999 representan no respuesta o medición no válida",
            "Variables EC5 son de selección múltiple con códigos A/B/X/Y y ?",
            "La participación paterna no es una medida directa de calidad del vínculo",
            "Los microdatos contienen información individual anonimizada",
            "MICS6 es una encuesta compleja con ponderadores",
            "Las asociaciones pueden confundirse con causalidad",
        ],
        "decision_metodologica": [
            "Usar solo WAZ2 cuando WAZFLAG == 0 y WAZ2 < 90",
            "Convertir códigos especiales a NA",
            "Construir indicadores binarios específicos para padre y madre",
            "Definir IIP como suma exploratoria de seis actividades declaradas",
            "Publicar la app usando tablas agregadas y no microdatos crudos",
            "Calcular promedios y proporciones usando chweight",
            "Agregar notas metodológicas y lecturas guiadas en la app",
        ],
        "impacto_en_visualizacion": [
            "Evita conclusiones basadas en mediciones inválidas",
            "Evita distorsionar medias y distribuciones",
            "Permite medir involucramiento paterno de forma trazable",
            "Mantiene una interpretación descriptiva, no causal",
            "Reduce exposición innecesaria y mejora rendimiento",
            "Mejora la representatividad descriptiva de los indicadores",
            "Evita sobreinterpretación de diferencias entre grupos",
        ],
    })

    diccionario = pd.DataFrame({
        "variable": [
            "HH1/HH2/LN", "CAGE_AN / CAGE", "HL4", "stratum", "windex5", "melevel",
            "AN8 / AN11", "WAZ2 / WAZFLAG", "EC1 / EC2A-C",
            "EC5AB, EC5BB, EC5CB, EC5DB, EC5EB, EC5FB", "chweight"
        ],
        "descripcion": [
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
            "Ponderador de niños/as de 0 a 4 años",
        ],
        "uso": [
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
            "Promedios y proporciones ponderadas",
        ],
    })

    return calidad, decisiones, diccionario


def group_weighted(df: pd.DataFrame, by: list[str], value: str, extra_aggs: Optional[dict] = None) -> pd.DataFrame:
    records = []
    for keys, g in df.groupby(by, dropna=False, sort=True):
        if not isinstance(keys, tuple):
            keys = (keys,)
        rec = dict(zip(by, keys))
        rec["n"] = len(g)
        rec["peso_muestral"] = g["peso_muestral"].sum(skipna=True)
        rec[value] = weighted_avg(g[value], g["peso_muestral"])
        if extra_aggs:
            for out_col, val_col in extra_aggs.items():
                rec[out_col] = weighted_avg(g[val_col], g["peso_muestral"])
        records.append(rec)
    return pd.DataFrame.from_records(records)


def build_tables(base: pd.DataFrame) -> dict[str, pd.DataFrame]:
    # Importante: se usa la misma lógica que la versión final de R.
    # n y peso_muestral describen la base válida ponderada del grupo.
    # Las medias/proporciones se calculan ignorando NA en la variable analítica.
    base_valid_weight = base.loc[
        base["peso_muestral"].notna() & (base["peso_muestral"] > 0)
    ].copy()

    # Crecimiento
    records = []
    for keys, g in base_valid_weight.groupby(["region", "sexo", "quintil_riqueza", "edad_grupo"], dropna=False, sort=True):
        rec = dict(zip(["region", "sexo", "quintil_riqueza", "edad_grupo"], keys))
        rec["n"] = len(g)
        rec["peso_muestral"] = g["peso_muestral"].sum(skipna=True)
        rec["waz_medio"] = weighted_avg(g["waz_oms"], g["peso_muestral"])
        rec["prop_bajo_peso"] = weighted_avg(g["bajo_peso"], g["peso_muestral"])
        records.append(rec)
    tabla_crecimiento = pd.DataFrame(records)
    tabla_crecimiento = tabla_crecimiento.dropna(subset=["region", "sexo", "quintil_riqueza", "edad_grupo"]).reset_index(drop=True)

    # Estimulación
    stim_specs = [
        ("tiene_libros", "prop_tiene_libros", "Tiene al menos un libro"),
        ("libros_n", "media_libros", "Media de libros"),
        ("juguete_casero", "prop_juguetes_caseros", "Juguetes caseros"),
        ("juguete_comprado", "prop_juguetes_comprados", "Juguetes comprados"),
        ("objeto_hogar_juego", "prop_objetos_hogar", "Objetos del hogar/exterior"),
    ]
    stim_frames = []
    for var, indicador, label in stim_specs:
        recs = []
        for keys, g in base_valid_weight.groupby(["region", "quintil_riqueza"], dropna=False, sort=True):
            rec = dict(zip(["region", "quintil_riqueza"], keys))
            rec["n"] = len(g)
            rec["peso_muestral"] = g["peso_muestral"].sum(skipna=True)
            rec["indicador"] = indicador
            rec["valor"] = weighted_avg(g[var], g["peso_muestral"])
            rec["indicador_label"] = label
            recs.append(rec)
        stim_frames.append(pd.DataFrame(recs))
    tabla_estimulo = pd.concat(stim_frames, ignore_index=True)
    tabla_estimulo = tabla_estimulo.dropna(subset=["region", "quintil_riqueza"]).reset_index(drop=True)

    # IIP
    recs = []
    for keys, g in base_valid_weight.groupby(["region", "quintil_riqueza", "educ_madre"], dropna=False, sort=True):
        rec = dict(zip(["region", "quintil_riqueza", "educ_madre"], keys))
        rec["n"] = len(g)
        rec["peso_muestral"] = g["peso_muestral"].sum(skipna=True)
        rec["iip_medio"] = weighted_avg(g["iip"], g["peso_muestral"])
        rec["iip_normalizado_medio"] = weighted_avg(g["iip_normalizado"], g["peso_muestral"])
        recs.append(rec)
    tabla_iip = pd.DataFrame(recs).dropna(subset=["region", "quintil_riqueza", "educ_madre"]).reset_index(drop=True)

    # Actividades IIP
    act_specs = [
        ("padre_leyo", "Leyó libros"),
        ("padre_conto_cuentos", "Contó cuentos"),
        ("padre_canto", "Cantó canciones"),
        ("padre_llevo_fuera", "Llevó fuera"),
        ("padre_jugo", "Jugó"),
        ("padre_nombro_conto_dibujo", "Nombró/contó/dibujó"),
    ]
    act_frames = []
    for var, label in act_specs:
        recs = []
        for keys, g in base_valid_weight.groupby(["region", "quintil_riqueza"], dropna=False, sort=True):
            rec = dict(zip(["region", "quintil_riqueza"], keys))
            rec["actividad"] = label
            rec["prop_actividad"] = weighted_avg(g[var], g["peso_muestral"])
            rec["n"] = len(g)
            rec["peso_muestral"] = g["peso_muestral"].sum(skipna=True)
            recs.append(rec)
        act_frames.append(pd.DataFrame(recs))
    tabla_iip_actividad = pd.concat(act_frames, ignore_index=True)
    tabla_iip_actividad = tabla_iip_actividad.dropna(subset=["region", "quintil_riqueza"]).reset_index(drop=True)

    # KPIs
    kpis = pd.DataFrame({
        "registros": [len(base_valid_weight)],
        "waz_medio": [weighted_avg(base["waz_oms"], base["peso_muestral"])],
        "prop_bajo_peso": [weighted_avg(base["bajo_peso"], base["peso_muestral"])],
        "prop_tiene_libros": [weighted_avg(base["tiene_libros"], base["peso_muestral"])],
        "iip_medio": [weighted_avg(base["iip"], base["peso_muestral"])],
    })

    return {
        "tabla_crecimiento": tabla_crecimiento,
        "tabla_estimulo": tabla_estimulo,
        "tabla_iip": tabla_iip,
        "tabla_iip_actividad": tabla_iip_actividad,
        "kpis": kpis,
    }

def write_csvs(objects: dict[str, pd.DataFrame], out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    for name, df in objects.items():
        df.to_csv(out_dir / f"{name}.csv", index=False, encoding="utf-8")


def norm_for_compare(df: pd.DataFrame) -> pd.DataFrame:
    out = df.copy()
    # Normalizar columnas string: vacíos -> NaN no debería afectar, pero se preserva.
    for col in out.select_dtypes(include=["object"]).columns:
        out[col] = out[col].astype("string")
    return out


def compare_csvs(expected_dir: Path, actual_dir: Path, names: list[str], tol: float = 1e-10) -> pd.DataFrame:
    rows = []
    for name in names:
        exp_path = expected_dir / f"{name}.csv"
        act_path = actual_dir / f"{name}.csv"
        if not exp_path.exists():
            rows.append({"tabla": name, "estado": "ERROR", "detalle": f"No existe esperada: {exp_path}"})
            continue
        exp = pd.read_csv(exp_path, encoding="utf-8")
        act = pd.read_csv(act_path, encoding="utf-8")

        same_shape = exp.shape == act.shape
        same_cols = list(exp.columns) == list(act.columns)

        detail = []
        max_abs_diff = np.nan
        mismatches = 0

        if same_shape and same_cols:
            # Ordenar por todas las columnas no numéricas y luego numéricas para neutralizar diferencias de orden.
            sort_cols = [c for c in exp.columns if exp[c].dtype == "object"] + [c for c in exp.columns if exp[c].dtype != "object"]
            try:
                exp2 = exp.sort_values(sort_cols, na_position="last").reset_index(drop=True)
                act2 = act.sort_values(sort_cols, na_position="last").reset_index(drop=True)
            except Exception:
                exp2 = exp.reset_index(drop=True)
                act2 = act.reset_index(drop=True)

            for c in exp.columns:
                if pd.api.types.is_numeric_dtype(exp2[c]) and pd.api.types.is_numeric_dtype(act2[c]):
                    diff = (pd.to_numeric(exp2[c], errors="coerce") - pd.to_numeric(act2[c], errors="coerce")).abs()
                    col_max = diff.max(skipna=True)
                    if not pd.isna(col_max):
                        max_abs_diff = np.nanmax([max_abs_diff, col_max]) if not pd.isna(max_abs_diff) else col_max
                    mismatches += int((diff > tol).fillna(False).sum())
                else:
                    e = exp2[c].astype("string").fillna("<NA>")
                    a = act2[c].astype("string").fillna("<NA>")
                    mismatches += int((e != a).sum())

        estado = "OK" if same_shape and same_cols and mismatches == 0 else "DIFERENCIAS"
        if not same_shape:
            detail.append(f"shape esperado={exp.shape}, actual={act.shape}")
        if not same_cols:
            detail.append("columnas distintas")
        if same_shape and same_cols:
            detail.append(f"celdas distintas={mismatches}")
            detail.append(f"max_abs_diff={max_abs_diff if not pd.isna(max_abs_diff) else 0}")
        rows.append({
            "tabla": name,
            "estado": estado,
            "filas_esperadas": exp.shape[0],
            "filas_python": act.shape[0],
            "columnas_esperadas": exp.shape[1],
            "columnas_python": act.shape[1],
            "max_abs_diff": max_abs_diff if not pd.isna(max_abs_diff) else 0.0,
            "detalle": "; ".join(detail),
        })

    return pd.DataFrame(rows)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--ch-sav", type=Path, default=None, help="Ruta directa a ch.sav")
    parser.add_argument("--raw-zip", type=Path, default=None, help="ZIP que contiene ch.sav o Argentina MICS6 Datasets.zip")
    parser.add_argument("--expected-dir", type=Path, default=Path("data_processed"), help="Carpeta data_processed generada por R")
    parser.add_argument("--out-dir", type=Path, default=Path("python_validation/out"), help="Carpeta de salida Python")
    args = parser.parse_args()

    args.expected_dir = project_path(args.expected_dir)
    args.out_dir = project_path(args.out_dir)
    if args.ch_sav is not None:
        args.ch_sav = project_path(args.ch_sav)
    if args.raw_zip is not None:
        args.raw_zip = project_path(args.raw_zip)

    if args.ch_sav is None and args.raw_zip is None:
        default_ch = PROJECT_ROOT / "data_raw" / "ch.sav"
        if default_ch.exists():
            args.ch_sav = default_ch
        else:
            raise SystemExit("Debe indicarse --ch-sav o --raw-zip, o existir data_raw/ch.sav")

    ch_sav = args.ch_sav if args.ch_sav else find_ch_sav_from_zip(args.raw_zip)
    print(f"Usando ch.sav: {ch_sav}")

    base = build_base(ch_sav)
    objects = build_tables(base)
    calidad, decisiones, diccionario = calidad_y_documentacion(base)
    objects.update({
        "calidad_variables": calidad,
        "decisiones_limpieza": decisiones,
        "diccionario_variables": diccionario,
    })

    args.out_dir.mkdir(parents=True, exist_ok=True)
    base.to_csv(args.out_dir / "base_pra2_python.csv", index=False, encoding="utf-8")
    write_csvs(objects, args.out_dir)

    names = [
        "kpis",
        "tabla_crecimiento",
        "tabla_estimulo",
        "tabla_iip",
        "tabla_iip_actividad",
        "calidad_variables",
        "decisiones_limpieza",
        "diccionario_variables",
    ]
    comparison = compare_csvs(args.expected_dir, args.out_dir, names)
    comparison.to_csv(args.out_dir / "comparacion_python_vs_r.csv", index=False, encoding="utf-8")

    print("\nComparación Python vs R:")
    print(comparison.to_string(index=False))
    if (comparison["estado"] == "OK").all():
        print("\nResultado: OK. Python reproduce las tablas finales generadas por R.")
    else:
        print("\nResultado: hay diferencias. Revisar python_validation/out/comparacion_python_vs_r.csv")


if __name__ == "__main__":
    main()
