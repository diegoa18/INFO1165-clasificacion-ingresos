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
- **Funciones expuestas:** `media_manual(x)`, `sd_manual(x)` (denominador n − 1), `percentil_tipo7(x, p)`, `escribir_csv(df, ruta)` (movida desde `06`; double con `sprintf("%.17g")`, integer/logical/double sin comillas, character/factor entre comillas, `NA` sin comillas; devuelve `invisible(ruta)`).
- **Verificaciones:** `Rscript tests/test_00_utilidades.R` (OK). Frente a `mean`, `sd` y `quantile(type = 7)` en 7 casos (r = 1, 2, 5, con empates, constante, normal n = 1 000 y valores ~10⁸) con p ∈ {0; 0,025; 0,25; 0,5; 0,75; 0,975; 1}: diferencia máxima 4,4·10⁻¹⁶ (sd con empates), el resto 0. Casos exactos a mano: p = 0 → mínimo, p = 1 → máximo, mediana de {10, 20, 30, 40} = 25, Q(0,025) = 10,75, r = 1 devuelve el único valor, sd de una constante = 0. Fallan con `stop()`: vector vacío, `NA`, sd con n = 1, p fuera de [0, 1]. `escribir_csv`: ida y vuelta con `read.csv(ruta, stringsAsFactors = FALSE)` sobre un `data.frame` con double (0,1 + 0,2, 1/3, `Inf`, `-Inf`, `NaN`, `NA`, 10⁻³⁰⁰, −2,5·10¹⁷), integer (con `NA` y 2³¹ − 1), logical con `NA`, character con coma, comillas, vacío y espacios, y factor con `NA`: todas las columnas `identical()` (factor contra `as.character()`), `NaN` y `NA` se distinguen; las dos excepciones del contrato se comprueban (double entero vuelve integer, double todo `NA` vuelve logical); se verifican 5 líneas del archivo carácter a carácter.
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
- **Dudas abiertas:** los faltantes de `adult.data` están solo en `workclass` (1 408), `occupation` (1 411) y `native_country` (499) dentro de la tabla final, por eso ninguna fila se excluye por faltantes. El script no descarga los datos: si faltan, `leer_adult()` se detiene con un mensaje (se descargaron a mano desde UCI). Corrección 2026-10-22: los dos csv se escriben con `escribir_csv()` de `00_utilidades.R` en lugar de `write.csv()`; al regenerar `data/processed`, `tabla_analitica.rds`, `tabla_analitica.csv` (leído) y `registro_exclusiones.csv` son `identical()` a los anteriores, y los tests de 00 y de 02 a 07 pasan sin cambios.

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
- **Verificaciones:** `Rscript tests/test_03_modelo.R` (OK) con la réplica 1. Estructura del contrato; diferencia máxima frente a R base: `mean` 0, `sd` 1,8·10⁻¹⁵, `dnorm(log = TRUE)` 3,6·10⁻¹⁵ (tolerancia EPS·n·escala); `p_g` y `q_e` suman 1 por clase y siguen la fórmula exacta; previa = 0,5 con n = 6 077 por clase y `c_previa = 0`; `D == l1 - l0` y |Σ contribuciones − D| dentro de tolerancia; puntajes finitos. Tolerancias alineadas con el contrato (2026-10-22): log-densidad frente a `dnorm` 3·EPS·max(1, |ref|) elemento a elemento, sumas de probabilidades K·EPS, contribuciones 16·EPS·max(|ℓ₁|, |ℓ₀|, 1) persona a persona (máximo observado 1,44·EPS). Casos límite: nivel sin casos → α/(n_c + α·K); `stop()` con una clase de 1 persona y con σ = 0. Réplica 1: μ edad 36,88 / 44,14, μ horas 39,37 / 45,41, σ edad 13,35 / 10,50, σ horas 12,10 / 11,00 (clase 0 / 1). D en validación (n = 2 830): mín −5,93, mediana −0,37, máx 3,86; con corte 0, 592 de 759 positivos y 1 487 de 2 071 negativos quedan del lado correcto.
- **Dudas abiertas:** ninguna.

## 04_umbral_metricas.R

- **Estado:** cerrado (2026-10-22)
- **Implementado:** candidatos {u₁} ∪ puntos medios u_h/2 + u_{h+1}/2 ∪ {+∞} (si un punto medio redondea fuera de (u_h, u_{h+1}] se usa u_{h+1}); regla positivo si D ≥ τ; matriz (TN, FP, FN, TP); 9 indicadores con `NA` si el denominador es 0; τ que maximiza J en validación con empate |J − J_max| ≤ eps, desempate por menor |τ| y luego menor τ; matrices por categoría conjunta; resumen entre réplicas con `media_manual`, `sd_manual` y `percentil_tipo7` de `00_utilidades.R`. Recibe D y la clase como argumentos; no llama a 03 ni lee/escribe archivos.
- **Funciones expuestas:** `candidatos_umbral(D)`, `predecir(D, tau)`, `matriz_confusion(clase, pred)`, `indicadores(m)`, `elegir_umbral(D, clase, eps = EPS)` → `list(tau, J_max, eps, candidatos)`, `matrices_por_grupo(clase, pred, g)` (formato largo: 10 filas en orden de `NIVELES_G`, columnas `g`, `TN`, `FP`, `FN`, `TP`, `n`, `n_1`, `n_0`, `TPR`, `FPR`, `FNR`, sin nombres de fila), `resumir(x)`. Auxiliar interna: `cociente(num, den)`.
- **Verificaciones:** `Rscript tests/test_04_umbral_metricas.R` (OK). Juguetes a mano: candidatos y J de 5 puntos (τ = −0,5, J = 2/3); empate con igual |τ| → menor τ; empate a tres → menor |τ|; `eps` controla el empate; L = 1 → {u₁, +∞}; punto medio no representable entre 1 y 1 + EPS → se usa u_{h+1}; matriz e indicadores de 100 casos; denominador 0 → `NA` (y matriz vacía → todo `NA`); por grupo: columnas y tipos del contrato, `levels(g) == NIVELES_G`, 10 filas sin nombres, Σ (TN, FP, FN, TP) = `matriz_confusion()`, grupo sin casos → conteos 0 y tasas `NA`, `rbind` con columna `b`; `resumir` con `NA`, r = 1 (sd `NA`) y r = 0. Réplica 1 completa: 1 856 candidatos (1 855 valores distintos de D), un solo empatado, **τ₁ = 0,0991012**, **J_max = 0,5056** en validación. Prueba (n = 2 833): TN 1 552, FP 520, FN 186, TP 575; exactitud 0,7508, TPR 0,7556, TNR 0,7490, PPV 0,5251, F1 0,6196, FPR 0,2510, FNR 0,2444, BA 0,7523, J 0,5046. Identidades TPR + FNR = 1, TNR + FPR = 1, BA = (TPR + TNR)/2, J = TPR + TNR − 1 y Σ_g M_g = M se cumplen.
- **Dudas abiertas:** ninguna. Resuelta (2026-10-22): `matrices_por_grupo()` pasó a formato largo con columna `g` y sin nombres de fila, según el contrato actualizado, para que 07 apile las réplicas con `rbind`.

## 05_replicas.R

- **Estado:** cerrado (2026-10-22)
- **Implementado:** bucle b = 1..`B_EJECUCION` (por defecto `B`; se puede fijar antes de `source()` para pruebas sin tocar `00_config.R`): `semilla_replica(b)` → `particionar()` → `ajustar_nb()` en entrenamiento → `elegir_umbral()` con D de validación → `puntuar()`, `predecir()`, `matriz_confusion()`, `indicadores()` y `matrices_por_grupo()` en prueba. Guarda `output/replicas/replica_XXX.rds` con `list(b, semilla, particion, modelo, umbral, prueba, matriz_prueba, indicadores_prueba, grupos_prueba)`, `logs/semillas.csv` (b, semilla, n_estrella y tamaños de los 4 destinos) y `logs/sesion.txt` (`sessionInfo()`, `RNGkind()`, `EPS`, `B_EJECUCION`).
- **Funciones expuestas:** ninguna (script).
- **Verificaciones:** prueba con `B_EJECUCION = 2` (1,2 s), luego las 200 réplicas: **88,9 s** (≈ 0,44 s por réplica), 200 archivos, 33,9 MB. `Rscript tests/test_05_replicas.R` (OK, 3,3 s): existen exactamente los 200 `.rds` y `semillas.csv` con 200 filas; en cada réplica la semilla es `semilla_replica(b)`, los destinos son disjuntos con unión = 28 308, cada clase tiene n_estrella = 6 077 en entrenamiento, `prueba` coincide con la partición y `pred`/`matriz_prueba` son coherentes con τ_b; las réplicas 1, 100 y 200 recalculadas desde cero son `identical()` a su `.rds`; τ₁ = 0,0991012 como en 04. τ_b en las 200 réplicas: mínimo −0,3231, máximo 0,3195, 200 valores distintos.
- **Dudas abiertas:** ninguna. Si se corre con `B_EJECUCION < B` después de una corrida completa, quedan `.rds` de corridas anteriores; `test_05_replicas.R` exige exactamente `B`.

## 06_resumen.R

- **Estado:** cerrado (2026-10-22)
- **Implementado:** lee los `B` `.rds` con la regla común (falla si falta alguno) y escribe `tablas/replicas_indicadores.csv` (200 filas: `b`, `semilla`, `tau` y los 9 indicadores de prueba), `tablas/resumen_replicas.csv` (10 filas con `resumir()`: `variable`, `escala`, `r`, `media`, `sd`, `mediana`, `p2.5`, `p97.5`), `figuras/hist_tau.png`, `figuras/paneles_indicadores.png` (2×4, mediana e intervalo p2.5–p97.5 sombreado, `r` y escala en el subtítulo) y `figuras/boxplot_indicadores.png` (8 indicadores de proporción, eje [0, 1]). R base, 1600×1000 a 150 ppp, sin funciones que consuman el generador. Tarda ~1,7 s.
- **Funciones expuestas:** ninguna (script). Auxiliar interna: `abrir_png()`. Las tablas se escriben con `escribir_csv()` de `00_utilidades.R`.
- **Verificaciones:** `stopifnot` final sobre los 5 archivos. `Rscript tests/test_06_resumen.R` (OK): 200 filas con `b = 1:B` y `semilla == semilla_replica(b)`; cada fila del resumen es `identical()` a `resumir()` sobre la columna leída del csv; diferencia máxima frente a `mean`/`sd`/`median`/`quantile(type = 7)` de 1,1·10⁻¹⁶; `p2.5 <= mediana <= p97.5`; `BA`, `J`, TPR + FNR y TNR + FPR cumplen sus identidades fila a fila con 4·EPS, y la comparación con R base usa n·EPS·max(1, |ref|) con n = r (tolerancias del contrato, 2026-10-22); τ₁ del csv es `identical()` al del `.rds`; existen los 3 png. Resultados (B = 200, r = 200 en todas las variables, sin `NA`): **τ_b** media 0,0482, mediana 0,0681, p2.5 −0,2156, p97.5 0,2650 (sd 0,1314); medianas en prueba: **exactitud 0,7363**, **TPR 0,7582**, **TNR 0,7283**, **BA 0,7418** (J 0,4837, PPV 0,5063, F1 0,6062).
- **Dudas abiertas:** ninguna. Resuelta (2026-10-22): `escribir_csv()` se movió a `00_utilidades.R` (la versión local además convertía `NaN` en `NA`; la nueva los distingue). El pendiente de `01_datos.R` (usaba `write.csv()`) quedó resuelto el 2026-10-22, ver su sección.

## 07_grupos.R

- **Estado:** cerrado (2026-10-22)
- **Implementado:** lee los `B` `.rds` con la regla común, apila `grupos_prueba` con columna `b` (2 000 filas) y verifica en cada réplica que las 10 matrices suman `matriz_prueba` y `n` suma `nrow(prueba)`. Escribe con `escribir_csv()`: `tablas/grupos_replicas.csv`, `tablas/resumen_grupos.csv` (30 filas, orden `NIVELES_G` × TPR, FPR, FNR; denominador, su mínimo/mediana/máximo y `resumir()`), `tablas/grupos_replica1.csv` y las marginales por sexo y por raza de la réplica 1 (suma de conteos antes de calcular tasas). Figura `figuras/tasas_grupos.png`: tres paneles con mediana y segmento p2.5–p97.5 por grupo, eje [0, 1], mediana del denominador y `r` junto a la etiqueta. Tarda ~2 s.
- **Funciones expuestas:** ninguna (script). Auxiliares internas: `tasa()`, `tabla_conteos()`, `marginal()`.
- **Verificaciones:** `stopifnot` en el script (sumas por réplica, marginales = matriz global de la réplica 1, 5 tablas y png escritos). `Rscript tests/test_07_grupos.R` (OK, 1,4 s): 10·B filas en orden; en cada réplica Σ M_g = `matriz_prueba` y Σ n = `nrow(prueba)`, contrastado contra los `.rds`; 201 filas grupo-réplica sin positivos en prueba (Female/Other 107, Female/Amer-Indian-Eskimo 44, Male/Other 30, Male/Amer-Indian-Eskimo 18, Female/Asian-Pac-Islander 2) con `TPR` y `FNR` en `NA`, y `r = #(n_1 > 0)` (p. ej. Female/Other: r = 93 en TPR y FNR); cada fila del resumen es `identical()` a `resumir()` y a los estadísticos del denominador; marginales por sexo y por raza suman la matriz global de la réplica 1 y sus tasas salen de los conteos sumados; existe el png.
- **Resultados (medianas entre réplicas, prueba):**
  - **TPR mayor:** Male/Asian-Pac-Islander 0,893 (mediana n_1 = 23) y Male/White 0,860 (n_1 = 590). **TPR menor:** Female/Other 0,000 (n_1 mediano 0; r = 93) y, entre grupos con r = 200, Female/Black 0,125 (n_1 = 8) y Female/White 0,321 (n_1 = 102).
  - **FPR mayor:** Male/Asian-Pac-Islander 0,474 (n_0 = 42) y Male/White 0,438 (n_0 = 1 078). **FPR menor:** Female/Amer-Indian-Eskimo y Female/Other 0,000 (n_0 = 9 y 7), y Female/Black 0,008 (n_0 = 120).
  - Patrón: el modelo detecta mucho más a los hombres (marginal réplica 1: TPR 0,830 vs 0,327) a costa de más falsos positivos (FPR 0,385 vs 0,063). Los grupos pequeños tienen intervalos p2.5–p97.5 que cubren casi todo [0, 1], por lo que sus medianas no son informativas.
- **Dudas abiertas:** el contrato no fija el orden de las 30 filas de `resumen_grupos.csv`; se usó `NIVELES_G` y, dentro de cada grupo, TPR, FPR, FNR.

## 08_diagnosticos.R

- **Estado:** cerrado (2026-10-22)
- **Implementado:** lee la tabla analítica y los `B` `.rds` (regla común). Réplica 1, entrenamiento: `figuras/qq_replica1.png` (2×2 `qqnorm`/`qqline`, edad y horas × clase, n en el título), `figuras/edad_horas_replica1.png` (dispersión por clase con transparencia, ejes comunes, Pearson a mano en el subtítulo), `tablas/educacion_g_replica1.csv` (160 filas en orden clase → educación → g, con ceros). Todas las réplicas: `tablas/verificaciones_replicas.csv` (200 filas, columnas del contrato; ℓ₀ y ℓ₁ se recalculan con `puntuar()` y el `modelo` guardado, uniendo las filas de prueba por `id_original`, para `D_recalculado_identico`, `max_err_contribuciones_rel` y `contribuciones_ok`). `tablas/trazabilidad.csv` (perfil = 15 columnas originales sin `id_original`, `NA` cuenta como valor). Tarda ~7 s.
- **Funciones expuestas:** ninguna (script). Auxiliares internas: `abrir_png()`, `pearson_manual()` (usa `media_manual`/`sd_manual`), `clave_perfil()`.
- **Verificaciones:** `stopifnot` en el script (160 filas que suman el entrenamiento, 200 filas, todas las columnas lógicas `TRUE`, archivos escritos). `Rscript tests/test_08_diagnosticos.R` (OK), con las tolerancias del contrato ("Tolerancias numéricas"): columnas y orden del contrato; las 8 columnas lógicas son `TRUE` en las 200 réplicas (incluye `D_recalculado_identico` y `contribuciones_ok`); errores de suma de probabilidades ≤ K·EPS (K = 2, K_E, K_G; máximo observado 1,1·10⁻¹⁶); contribuciones frente a D ≤ 16·EPS·max(|ℓ₁|, |ℓ₀|, 1) persona a persona (máximo relativo observado 2,10·EPS; el máximo absoluto, 9,1·10⁻¹⁵, se sigue registrando); contraste independiente con los `.rds` de las réplicas 1, 100 y 200 recalculando ℓ₀ y ℓ₁; `educacion_g` marginaliza exactamente a `conteos_g` y `conteos_e` del modelo de la réplica 1; `duplicados_excedentes` coincide con `sum(duplicated())` y `perfiles_distintos` con `nrow(unique())`; existen los 2 png.
- **Hallazgos:**
  - **Q–Q (réplica 1):** la edad no es normal: en clase 0 hay un piso en 17–20 años y cola superior larga (asimetría a la derecha); en clase 1 se ajusta bien en el centro, con cola inferior más corta. Las horas se alejan mucho de la normal: valores discretos con gran masa en 40 (en clase 0 el rango intercuartílico es casi nulo y `qqline` queda casi plana) y topes en 1 y 99. El supuesto gaussiano es aproximado para edad y débil para horas.
  - **Dependencias:** Pearson edad–horas = 0,024 (clase 0) y −0,122 (clase 1): dependencia lineal débil dentro de cada clase, compatible con el supuesto de independencia condicional de Naive Bayes en ese par. `educacion_g_replica1.csv`: 32 de 160 celdas en cero, concentradas en grupos pequeños con educación alta (p. ej. Prof-school y Doctorate en clase 0); la tabla queda para evaluar la independencia educación–g por clase en el informe.
  - **Duplicados:** 28 308 filas, 28 289 perfiles distintos, 19 duplicados excedentes. En la réplica 1, 3 personas de prueba tienen un perfil idéntico a alguien de entrenamiento, 1 a alguien de validación, 4 en total (0,14 % de 2 833).
  - **Verificaciones en las 200 réplicas:** previas y probabilidades de g y educación suman 1 (error ≤ 1,1·10⁻¹⁶), n* correcto, destinos disjuntos y completos, puntajes finitos, contribuciones suman D, la matriz de prueba suma n y los grupos suman la matriz global.
- **Dudas abiertas:** ninguna. Resueltas (2026-10-22) por el contrato actualizado: `prueba_coincide_*` cuenta personas de prueba; `educacion_g_replica1.csv` se ordena por clase, educación y g (`g` varía más rápido), como ya estaba; la tolerancia de las contribuciones es relativa, 16·EPS·max(|ℓ₁|, |ℓ₀|, 1), en lugar del 128·EPS absoluto que se usaba en el test.

## 09_replica1.R

- **Estado:** cerrado (2026-10-22)
- **Implementado:** lee la tabla analítica y `replica_001.rds`; no reajusta. Escribe con `escribir_csv()` las 7 tablas del contrato: `tamanos_replica1.csv` (tamaños por clase + `n_estrella`), `parametros_replica1.csv`, `densidad_ejemplo_replica1.csv` (edad 37 de la persona, `log_f` con `log_densidad_normal()`, `f`, `F` con `pnorm()`), `probabilidades_g_replica1.csv` (20 filas) y `probabilidades_e_replica1.csv` (16 filas), `persona_replica1.csv` (con `l0` y `l1` recalculados con `puntuar()` y el modelo guardado) y `candidatos_replica1.csv` (1 856 cortes + `exactitud`, `PPV`, `F1`, `FPR` con `indicadores()`, `J_max`, `eps`, `elegido`). Figura `curvas_validacion_replica1.png`: indicadores de validación frente a los cortes finitos con línea en τ₁, y el corte +∞ en un panel aparte (TNR = 1, exactitud = 0,732, TPR = F1 = FPR = 0, PPV = `NA` marcado). Tarda ~0,6–1,2 s.
- **Funciones expuestas:** ninguna (script). Auxiliares internas: `ruta_tabla()`, `largo()`.
- **Verificaciones:** `stopifnot` en el script y `Rscript tests/test_09_replica1.R` (OK): columnas del contrato y coincidencia con el `.rds`; previas, p_g y q_e suman 1 con K·EPS; persona: |Σ contribuciones − D| = 0,11·EPS relativo (límite 16·EPS), `D == l1 - l0`, `pred == (D >= tau)`, `l0`, `l1` y `D` `identical()` al recálculo; un único `elegido`, con `tau` = `umbral[["tau"]]` = 0,0991012, empatado y con indicadores `identical()` a `indicadores()`; en +∞ el `PPV` es `NA`; `log_f` frente a `dnorm(log = TRUE)` ≤ 3·EPS·max(1, |ref|) y la diferencia de `log_f` entre clases es `identical()` a `c_edad` de la persona; existe el png.
- **Resultados:** la persona de ejemplo (id 11; 37 años, 80 h, Some-college, Male/Black, clase real 1) tiene D = −0,0277 < τ₁ = 0,0991, así que es un **falso negativo**: las horas suman a favor de la clase 1 (c_horas = +0,787) pero educación (−0,472) y categoría conjunta (−0,352) pesan más.
- **Dudas abiertas:** ninguna.

## Ejecución completa (`run_all.R`)

- **Fecha:** 2026-10-22, R 4.6.1, Windows 11.
- **Desde cero:** se retiraron todas las salidas generadas (`data/processed`, `output/replicas`, `output/tablas`, `output/figuras`, `logs/semillas.csv`, `logs/sesion.txt`), quedando solo `data/raw/adult.data` y `adult.names`. `run_all.R` ejecutado por expresiones (`parse()` + `eval()`, mismo orden y sesión) para cronometrar cada `source()`:

  | Script | Segundos |
  |---|---|
  | 00_utilidades.R | 0,00 |
  | 00_config.R | 0,02 |
  | 01_datos.R | 1,44 |
  | 02_particion.R | 0,00 |
  | 03_modelo.R | 0,00 |
  | 04_umbral_metricas.R | 0,02 |
  | 05_replicas.R | 123,17 |
  | 06_resumen.R | 1,81 |
  | 07_grupos.R | 1,92 |
  | 08_diagnosticos.R | 9,02 |
  | 09_replica1.R | 0,59 |
  | **Total** | **138,6** |

  Luego `Rscript run_all.R` tal cual: 137,5 s, sin errores. 05 representa el 89 % del tiempo (antes había tardado 88,9 s; la diferencia es de la máquina, no del código).
- **Reproducibilidad:** tras la corrida desde cero, `tabla_analitica.rds` y los 200 `replica_XXX.rds` son `identical()` a los de la corrida anterior, y los 17 csv de `output/tablas/` son idénticos línea a línea. Se generan 200 `.rds`, 17 tablas y 7 figuras.
- **Tests:** los 9 `tests/test_*.R` (00, 02–09) pasan; ~12 s en total.
