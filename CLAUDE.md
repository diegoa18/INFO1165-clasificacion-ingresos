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
| 0 | `R/00_config.R` | Constantes, rutas y niveles de factores |
| 1 | `R/01_datos.R` | Pasa de `data/raw/` a `data/processed/` |
| 2 | `R/02_particion.R`, `R/03_modelo.R`, `R/04_umbral_metricas.R` | Funciones puras que solo usan la config. `04` recibe `D` como argumento y no conoce el modelo |
| 3 | `R/05_replicas.R` | Único que combina 02–04; escribe `output/replicas/` |
| 4 | `R/06`–`R/09` | Solo leen los `.rds` y la tabla procesada |

`run_all.R` solo hace `source()` en orden. **Regla: un archivo solo depende de niveles inferiores.**

## Reglas de trabajo

- Solo R base: nada de `caret`, `tidymodels` ni otros paquetes de modelado.
- La media, la desviación estándar, la log-densidad normal y el percentil tipo 7 se implementan a mano. `mean`, `sd`, `dnorm` y `quantile` aparecen solo dentro de `stopifnot()` como comprobación.
- El épsilon de máquina se escribe `.Machine[["double.eps"]]` (constante `EPS`).
- Cada módulo va en su propia rama y su propio PR.
- `docs/arquitectura.md` no se edita al implementar: si hace falta un cambio, se propone en la descripción del PR.
- Al cerrar cada módulo se actualiza `docs/bitacora.md`.
- `data/raw/` nunca se modifica.

## Documentación

- `docs/arquitectura.md`: fórmulas, estructura del repositorio y contratos de cada función pública.
- `docs/bitacora.md`: estado de cada módulo, verificaciones y dudas abiertas.
