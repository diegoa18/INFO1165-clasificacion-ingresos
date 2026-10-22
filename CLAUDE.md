# INFO-1165: clasificación de ingresos con Naive Bayes mixto

Proyecto del curso INFO-1165 (Prueba Práctica 2). Clasificador Naive Bayes mixto programado en GNU R base que predice si el ingreso anual supera USD 50.000 (Adult/Census Income, UCI, solo `adult.data`). Usa $B = 200$ réplicas de submuestreo equilibrado y la semilla $20261021 + b - 1$. Estudia la estabilidad del umbral $\tau_b$ y los errores por categoría conjunta sexo/raza.

## Jerarquía de autoridad

Ante un conflicto, manda el primero de esta lista:

1. La rúbrica en PDF del curso.
2. `docs/arquitectura.md`.
3. `R/00_config.R`.
4. El resto del código.

## Jerarquía de dependencias

| Nivel | Archivos | Rol |
|---|---|---|
| 0 | `R/00_utilidades.R` | Funciones estadísticas puras a mano (`media_manual`, `sd_manual`, `percentil_tipo7`), sin dependencias, ni siquiera de la config |
| 0 | `R/00_config.R` | Constantes, rutas y niveles de factores |
| 1 | `R/01_datos.R` | Pasa de `data/raw/` a `data/processed/` |
| 2 | `R/02_particion.R`, `R/03_modelo.R`, `R/04_umbral_metricas.R` | Funciones puras que solo usan el nivel 0. `04` recibe `D` como argumento y no conoce el modelo |
| 3 | `R/05_replicas.R` | Único que combina 02–04; escribe `output/replicas/` |
| 4 | `R/06`–`R/09` | Solo leen los `.rds` y la tabla procesada |
| — | `tests/test_NN_*.R` | Verificaciones por módulo para el desarrollador. Usan niveles 0–2 y `data/processed/`, no escriben en `output/` y `run_all.R` no las ejecuta |

`run_all.R` solo hace `source()` en orden, empezando por `00_utilidades.R` y `00_config.R`. **Regla: un archivo solo depende de niveles inferiores.**

## Reglas de trabajo

- Solo R base: nada de `caret`, `tidymodels` ni otros paquetes de modelado.
- La media, la desviación estándar, la log-densidad normal y el percentil tipo 7 se implementan a mano. `mean`, `sd`, `dnorm` y `quantile` aparecen solo dentro de `stopifnot()` como comprobación.
- El épsilon de máquina se escribe `.Machine[["double.eps"]]` (constante `EPS`).
- Todo se desarrolla en una sola rama de trabajo: un commit por módulo (o por avance verificable) y push después de cada commit, para poder volver a un punto anterior si algo falla. No se abren PR ni se hace merge hasta que el equipo lo decida al final.
- `docs/arquitectura.md` no se edita al implementar: si hace falta un cambio, se anota como propuesta en "Dudas abiertas" de `docs/bitacora.md`.
- Al cerrar cada módulo se escribe o actualiza `tests/test_NN_modulo.R` (para las utilidades, `tests/test_00_utilidades.R`), se ejecuta y se actualiza `docs/bitacora.md`.
- `data/raw/` nunca se modifica.

## Documentación

- `docs/arquitectura.md`: fórmulas, estructura del repositorio y contratos de cada función pública.
- `docs/bitacora.md`: estado de cada módulo, verificaciones y dudas abiertas.
