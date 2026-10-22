# Bitácora de módulos

Se completa una sección al cerrar el PR de cada módulo. Los contratos de referencia están en `docs/arquitectura.md`.

<!-- Plantilla por módulo:

## NN_nombre.R

- **Estado:** pendiente | en curso | cerrado (PR #, fecha)
- **Implementado:**
- **Funciones expuestas:**
- **Verificaciones:**
- **Dudas abiertas:**
-->

## 00_config.R

- **Estado:** en curso (rama `feat/00-config`, PR pendiente, 2026-10-22)
- **Implementado:** rutas (`RUTAS`), `B`, `SEMILLA_BASE`, `ALPHA`, `EPS`, `P_PERCENTILES`, `PROPORCIONES` (0,8 / 0,1 / 0,1), `COLUMNAS_ADULT`, `COLUMNAS_REQUERIDAS`, `ETIQUETAS_INGRESO`, `EDUCACION_NUM_MIN`, `NIVELES_E`, `NIVELES_SEXO`, `NIVELES_RAZA`, `NIVELES_G`, `K_E`, `K_G`, `INDICADORES`. Sin lógica de cómputo ni efectos en disco.
- **Funciones expuestas:** `semilla_replica(b)` (contrato) y su alias `semilla(b)`; ambas devuelven `SEMILLA_BASE + b - 1L`.
- **Verificaciones:** `stopifnot` al final del archivo (tipos de `B` y `SEMILLA_BASE`, `semilla(1) == 20261021`, `semilla(B) == 20261220`, `sum(PROPORCIONES) == 1` con tolerancia `EPS`, 15 columnas, 8 niveles de E, 10 niveles de G sin duplicados y en orden sexo/raza, 9 indicadores, 6 rutas). `Rscript` con `source("R/00_config.R")` termina sin errores.
- **Dudas abiertas:** `PROPORCIONES`, `COLUMNAS_REQUERIDAS`, `ETIQUETAS_INGRESO`, `EDUCACION_NUM_MIN` y el alias `semilla` no figuran en la tabla de objetos de `arquitectura.md`; proponer su inclusión en la descripción del PR.

## 01_datos.R

- **Estado:** en curso (rama `feat/01-datos`, apilada sobre `feat/00-config`; PR pendiente, 2026-10-22)
- **Implementado:** lectura de `adult.data` con `read.csv` (sin encabezado, `strip.white = TRUE`, `"?"` y `""` como `NA`), `id_original` = número de fila en el archivo, exclusión por faltantes solo en `COLUMNAS_REQUERIDAS`, filtro `education_num >= 9`, `clase` 0/1, `educacion` (factor `NIVELES_E`) y `g` (factor `NIVELES_G`). Escribe `tabla_analitica.rds`, `tabla_analitica.csv` (28 308 × 19) y `registro_exclusiones.csv`.
- **Funciones expuestas:** `leer_adult(ruta)`, `construir_tabla_analitica(crudo)` → `list(tabla, registro)`.
- **Verificaciones:** `stopifnot` sobre columnas y orden, ausencia de `"?"`/`""` tras la lectura, sin `NA` en requeridas, `min(education_num) >= 9`, `id_original` único y creciente, `clase` integer 0/1, niveles exactos de `educacion` y `g` sin `NA`, correspondencia `education_num` ↔ `educacion`, consistencia del registro. Resultado: 32 561 originales, 0 excluidas por faltantes, 4 253 por educación, 28 308 finales; `clase`: 20 711 (0) / 7 597 (1); los 10 niveles de G tienen casos (mínimo Female/Other = 76). MD5 de los crudos: `adult.data` 5d7c39d7b8804f071cdd1f2a7c460872, `adult.names` 1a7cdb3ff7a1b709968b1c7a11def63e.
- **Dudas abiertas:** los faltantes de `adult.data` están solo en `workclass` (1 408), `occupation` (1 411) y `native_country` (499) dentro de la tabla final, por eso ninguna fila se excluye por faltantes. El script no descarga los datos: si faltan, `leer_adult()` se detiene con un mensaje (se descargaron a mano desde UCI).

## 02_particion.R

- **Estado:** implementado (rama `feat/01-datos`, 2026-10-22)
- **Implementado:** partición estratificada por clase (⌊0,8·N_c⌋ disponibles, ⌊0,1·N_c⌋ validación, resto prueba), `n*` = mínimo de disponibles, entrenamiento balanceado por sorteo sin reemplazo y cuarto destino `sin_seleccionar`. `set.seed(semilla)` dentro de la función (con `kind` explícito Mersenne-Twister / Inversion / Rejection), orden de consumo del contrato y siempre `x[sample.int(length(x), n)]`. No lee ni escribe archivos. Constante local `DESTINOS` con los 4 nombres.
- **Funciones expuestas:** `particionar(clase, semilla)` → `list(semilla, n_estrella, tamanos, indices, destino)`; `indices` = posiciones de fila (integer, crecientes) en la tabla analítica.
- **Verificaciones:** script aparte (no versionado) con la tabla analítica y `semilla_replica(1)`: destinos disjuntos con unión = 28 308, `n* = 6077` (= ⌊0,8 · 7 597⌋), entrenamiento 6 077 / 6 077, prevalencia de validación 0,26820 y de prueba 0,26862 frente a 0,26837 en la tabla (diferencia ≤ 1/n del destino), misma semilla ⇒ resultado idéntico, semilla 2 ⇒ índices distintos en entrenamiento, validación y prueba. Tamaños b = 1: clase 0 → 6 077 / 2 071 / 2 072 / 10 491; clase 1 → 6 077 / 759 / 761 / 0.
- **Dudas abiertas:** el contrato usa `particionar(clase, semilla)` con índices como posiciones de fila y el destino `sin_seleccionar`; se siguió el contrato en vez de `particionar(datos, semilla)` con `id_original` y `no_usados` (conversión: `tabla$id_original[idx]`). Propuesta: mover `DESTINOS` a `00_config.R` y decidir si el script de verificación se versiona (p. ej. en `tests/`).

## 03_modelo.R

- **Estado:** pendiente
- **Implementado:**
- **Funciones expuestas:**
- **Verificaciones:**
- **Dudas abiertas:**

## 04_umbral_metricas.R

- **Estado:** pendiente
- **Implementado:**
- **Funciones expuestas:**
- **Verificaciones:**
- **Dudas abiertas:**

## 05_replicas.R

- **Estado:** pendiente
- **Implementado:**
- **Funciones expuestas:**
- **Verificaciones:**
- **Dudas abiertas:**

## 06_resumen.R

- **Estado:** pendiente
- **Implementado:**
- **Funciones expuestas:**
- **Verificaciones:**
- **Dudas abiertas:**

## 07_grupos.R

- **Estado:** pendiente
- **Implementado:**
- **Funciones expuestas:**
- **Verificaciones:**
- **Dudas abiertas:**

## 08_diagnosticos.R

- **Estado:** pendiente
- **Implementado:**
- **Funciones expuestas:**
- **Verificaciones:**
- **Dudas abiertas:**

## 09_replica1.R

- **Estado:** pendiente
- **Implementado:**
- **Funciones expuestas:**
- **Verificaciones:**
- **Dudas abiertas:**
