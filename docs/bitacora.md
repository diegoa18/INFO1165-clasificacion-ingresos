# Bitácora de módulos

Se completa una sección al cerrar cada módulo (commit en la rama de trabajo). Los contratos de referencia están en `docs/arquitectura.md`.

<!-- Plantilla por módulo:

## NN_nombre.R

- **Estado:** pendiente | en curso | cerrado (commit, fecha)
- **Implementado:**
- **Funciones expuestas:**
- **Verificaciones:**
- **Dudas abiertas:**
-->

## 00_utilidades.R

- **Estado:** cerrado (2026-10-22)
- **Implementado:** estadísticos a mano, funciones puras sin dependencias (no usa `00_config.R`). Validan la entrada con `stopifnot` (sin `NA`, longitudes mínimas, `p` en [0, 1]). Las dos primeras se movieron desde `03_modelo.R`; `run_all.R` carga este archivo antes que `00_config.R`.
- **Funciones expuestas:** `media_manual(x)`, `sd_manual(x)` (denominador n − 1), `percentil_tipo7(x, p)`.
- **Verificaciones:** `Rscript tests/test_00_utilidades.R` (OK). Frente a `mean`, `sd` y `quantile(type = 7)` en 7 casos (r = 1, 2, 5, con empates, constante, normal n = 1 000 y valores ~10⁸) con p ∈ {0; 0,025; 0,25; 0,5; 0,75; 0,975; 1}: diferencia máxima 4,4·10⁻¹⁶ (sd con empates), el resto 0. Casos exactos a mano: p = 0 → mínimo, p = 1 → máximo, mediana de {10, 20, 30, 40} = 25, Q(0,025) = 10,75, r = 1 devuelve el único valor, sd de una constante = 0. Fallan con `stop()`: vector vacío, `NA`, sd con n = 1, p fuera de [0, 1].
- **Dudas abiertas:** ninguna.

## 00_config.R

- **Estado:** cerrado (2026-10-22)
- **Implementado:** rutas (`RUTAS`), `B`, `SEMILLA_BASE`, `ALPHA`, `EPS`, `P_PERCENTILES`, `PROPORCIONES` (0,8 / 0,1 / 0,1), `COLUMNAS_ADULT`, `COLUMNAS_REQUERIDAS`, `ETIQUETAS_INGRESO`, `EDUCACION_NUM_MIN`, `NIVELES_E`, `NIVELES_SEXO`, `NIVELES_RAZA`, `NIVELES_G`, `K_E`, `K_G`, `INDICADORES`, `DESTINOS` (movido desde `02`). Sin lógica de cómputo ni efectos en disco.
- **Funciones expuestas:** `semilla_replica(b)`, devuelve `SEMILLA_BASE + b - 1L` (se eliminó el alias `semilla`).
- **Verificaciones:** `stopifnot` al final del archivo (tipos de `B` y `SEMILLA_BASE`, `semilla_replica(1) == 20261021`, `semilla_replica(B) == 20261220`, `sum(PROPORCIONES) == 1` con tolerancia `EPS`, 15 columnas, 8 niveles de E, 10 niveles de G sin duplicados y en orden sexo/raza, 9 indicadores, 4 destinos, 6 rutas). `Rscript` con `source("R/00_config.R")` termina sin errores.
- **Dudas abiertas:** ninguna; los objetos agregados quedaron documentados en `arquitectura.md`.

## 01_datos.R

- **Estado:** cerrado (2026-10-22)
- **Implementado:** lectura de `adult.data` con `read.csv` (sin encabezado, `strip.white = TRUE`, `"?"` y `""` como `NA`), `id_original` = número de fila en el archivo, exclusión por faltantes solo en `COLUMNAS_REQUERIDAS`, filtro `education_num >= 9`, `clase` 0/1, `educacion` (factor `NIVELES_E`) y `g` (factor `NIVELES_G`). Escribe `tabla_analitica.rds`, `tabla_analitica.csv` (28 308 × 19) y `registro_exclusiones.csv`.
- **Funciones expuestas:** `leer_adult(ruta)`, `construir_tabla_analitica(crudo)` → `list(tabla, registro)`.
- **Verificaciones:** `stopifnot` sobre columnas y orden, ausencia de `"?"`/`""` tras la lectura, sin `NA` en requeridas, `min(education_num) >= 9`, `id_original` único y creciente, `clase` integer 0/1, niveles exactos de `educacion` y `g` sin `NA`, correspondencia `education_num` ↔ `educacion`, consistencia del registro. Resultado: 32 561 originales, 0 excluidas por faltantes, 4 253 por educación, 28 308 finales; `clase`: 20 711 (0) / 7 597 (1); los 10 niveles de G tienen casos (mínimo Female/Other = 76). MD5 de los crudos: `adult.data` 5d7c39d7b8804f071cdd1f2a7c460872, `adult.names` 1a7cdb3ff7a1b709968b1c7a11def63e.
- **Dudas abiertas:** los faltantes de `adult.data` están solo en `workclass` (1 408), `occupation` (1 411) y `native_country` (499) dentro de la tabla final, por eso ninguna fila se excluye por faltantes. El script no descarga los datos: si faltan, `leer_adult()` se detiene con un mensaje (se descargaron a mano desde UCI).

## 02_particion.R

- **Estado:** cerrado (2026-10-22)
- **Implementado:** partición estratificada por clase (⌊0,8·N_c⌋ disponibles, ⌊0,1·N_c⌋ validación, resto prueba), `n*` = mínimo de disponibles, entrenamiento balanceado por sorteo sin reemplazo y cuarto destino `sin_seleccionar`. `set.seed(semilla)` dentro de la función (con `kind` explícito Mersenne-Twister / Inversion / Rejection), orden de consumo del contrato y siempre `x[sample.int(length(x), n)]`. No lee ni escribe archivos. `destino` es factor con `levels = DESTINOS` (de `00_config.R`).
- **Funciones expuestas:** `particionar(clase, semilla)` → `list(semilla, n_estrella, tamanos, indices, destino)`; `indices` = posiciones de fila (integer, crecientes) en la tabla analítica.
- **Verificaciones:** `Rscript tests/test_02_particion.R` (OK) con la tabla analítica y `semilla_replica(1)`: estructura del contrato, destinos disjuntos con unión = 28 308, `n* = 6077` (= ⌊0,8 · 7 597⌋), entrenamiento 6 077 / 6 077, prevalencia de validación 0,26820 y de prueba 0,26862 frente a 0,26837 en la tabla (diferencia ≤ 1/n del destino), misma semilla ⇒ resultado idéntico, semilla 2 ⇒ índices distintos en entrenamiento, validación y prueba. Tamaños b = 1: clase 0 → 6 077 / 2 071 / 2 072 / 10 491; clase 1 → 6 077 / 759 / 761 / 0.
- **Dudas abiertas:** el contrato usa `particionar(clase, semilla)` con índices como posiciones de fila y el destino `sin_seleccionar`; se siguió el contrato en vez de `particionar(datos, semilla)` con `id_original` y `no_usados` (conversión: `tabla$id_original[idx]`). Resuelto: `DESTINOS` está en `00_config.R` y la verificación se versiona en `tests/`.

## 03_modelo.R

- **Estado:** cerrado (2026-10-22)
- **Implementado:** Naive Bayes mixto a mano: media y desviación estándar (denominador n − 1) de `age` y `hours_per_week` por clase, log-densidad normal en escala logarítmica, probabilidades de `educacion` y `g` con Laplace (`ALPHA`) sobre los niveles fijos (los niveles con 0 casos reciben α/(n_c + α·K)), previa estimada como n_c / (n_0 + n_1). Puntaje ℓ_c = log π_c + log f_edad + log f_horas + log q_e + log p_g; `D = l1 - l0`. Sin `mean`/`sd`/`dnorm`; no lee ni escribe archivos ni llama a 02/04. Media y sd vienen de `00_utilidades.R` (refactor 2026-10-22; `test_03_modelo.R` sigue pasando con los mismos resultados).
- **Funciones expuestas:** `log_densidad_normal(z, mu, sigma)`, `ajustar_nb(entrenamiento)` → `list(n, previa, mu, sigma, conteos_g, p_g, conteos_e, q_e)`, `puntuar(modelo, datos)` → `data.frame(l0, l1, c_previa, c_edad, c_horas, c_educacion, c_g, D)`.
- **Verificaciones:** `Rscript tests/test_03_modelo.R` (OK) con la réplica 1. Estructura del contrato; diferencia máxima frente a R base: `mean` 0, `sd` 1,8·10⁻¹⁵, `dnorm(log = TRUE)` 3,6·10⁻¹⁵ (tolerancia EPS·n·escala); `p_g` y `q_e` suman 1 por clase y siguen la fórmula exacta; previa = 0,5 con n = 6 077 por clase y `c_previa = 0`; `D == l1 - l0` y |Σ contribuciones − D| dentro de tolerancia; puntajes finitos. Casos límite: nivel sin casos → α/(n_c + α·K); `stop()` con una clase de 1 persona y con σ = 0. Réplica 1: μ edad 36,88 / 44,14, μ horas 39,37 / 45,41, σ edad 13,35 / 10,50, σ horas 12,10 / 11,00 (clase 0 / 1). D en validación (n = 2 830): mín −5,93, mediana −0,37, máx 3,86; con corte 0, 592 de 759 positivos y 1 487 de 2 071 negativos quedan del lado correcto.
- **Dudas abiertas:** ninguna.

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
