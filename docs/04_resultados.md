# Resultados

Documento 4 de 5. Reúne las cifras del proyecto, cada una con su réplica o resumen, subconjunto, escala y denominador, como pide la rúbrica (sección 10). La interpretación está en `05_evaluacion_resultados.md`.

- **Origen:** ejecución completa del 2026-10-22 (R 4.6.1, Windows 11), registrada en `docs/bitacora.md`. Las tablas fuente están en `output/tablas/` con 17 cifras significativas; aquí se redondean.
- **Escalas:** las tasas son proporciones en $[0, 1]$; $J$ y $\tau$ están en su escala original.
- **Datos faltantes:** `[FALTA DATO: …]` indica una cifra que existe en el CSV señalado pero no está transcrita en la documentación versionada.

## 1. Datos y población

Fuente: `data/processed/registro_exclusiones.csv`.

| Paso | Filas |
|---|---|
| Filas originales de `adult.data` | 32 561 |
| Excluidas por faltantes en columnas requeridas | 0 |
| Excluidas por `education-num` < 9 | 4 253 |
| **Total final (tabla analítica)** | **28 308** |

| Clase | Personas | Proporción |
|---|---|---|
| 0 (≤ USD 50.000) | 20 711 | 0,7316 |
| 1 (> USD 50.000) | 7 597 | 0,2684 |

- Faltantes que quedan en la tabla, en columnas no usadas: `workclass` 1 408, `occupation` 1 411, `native_country` 499.
- Las 10 categorías conjuntas tienen casos; la más pequeña es Female/Other con 76 personas.
- [FALTA DATO: tamaño de cada una de las 10 categorías conjuntas en la tabla analítica (se obtiene con `table(tabla$g)` o sumando `n` de `grupos_replica1.csv` por grupo en los cuatro destinos).] <!-- FALTA: composición de G en la tabla completa -->
- MD5: `adult.data` 5d7c39d7b8804f071cdd1f2a7c460872; `adult.names` 1a7cdb3ff7a1b709968b1c7a11def63e.

## 2. Réplica 1 ($b = 1$, semilla 20 261 021)

### 2.1 Tamaños

Fuente: `output/tablas/tamanos_replica1.csv`. Iguales en las 200 réplicas.

| Clase | $N_c$ | Disponibles | Entrenamiento | Validación | Prueba | Sin seleccionar |
|---|---|---|---|---|---|---|
| 0 | 20 711 | 16 568 | 6 077 | 2 071 | 2 072 | 10 491 |
| 1 | 7 597 | 6 077 | 6 077 | 759 | 761 | 0 |
| Total | 28 308 | 22 645 | 12 154 | 2 830 | 2 833 | 10 491 |

$n_* = 6\,077$. Prevalencia de clase 1: validación 0,26820, prueba 0,26862, tabla 0,26837.

### 2.2 Parámetros (entrenamiento)

Fuente: `output/tablas/parametros_replica1.csv`.

| Clase | $n$ | Previa | $\hat\mu$ edad | $\hat\sigma$ edad | $\hat\mu$ horas | $\hat\sigma$ horas |
|---|---|---|---|---|---|---|
| 0 | 6 077 | 0,5 | 36,88 | 13,35 | 39,37 | 12,10 |
| 1 | 6 077 | 0,5 | 44,14 | 10,50 | 45,41 | 11,00 |

Unidades: años y horas por semana.

### 2.3 Densidad para una edad observada

Fuente: `output/tablas/densidad_ejemplo_replica1.csv`. Edad $z = 37$ (persona id 11).

| Clase | $\hat\mu$ | $\hat\sigma$ | $\log f(37)$ | $f(37)$ (por año) | $F(37)$ |
|---|---|---|---|---|---|
| 0 | 36,88 | 13,35 | ≈ −3,5105 | ≈ 0,0299 | ≈ 0,504 |
| 1 | 44,14 | 10,50 | ≈ −3,5015 | ≈ 0,0302 | ≈ 0,248 |

<!-- FALTA: reemplazar por los valores exactos del CSV. -->
[FALTA DATO: valores exactos; los de la tabla se recalcularon con los parámetros redondeados a 2 decimales y pueden diferir en el tercer decimal.]

### 2.4 Probabilidades categóricas con Laplace

Fuentes: `output/tablas/probabilidades_g_replica1.csv` (20 filas), `probabilidades_e_replica1.csv` (16 filas). Denominadores: $6\,077 + 10 = 6\,087$ para $\hat p_{c,g}$ y $6\,077 + 8 = 6\,085$ para $\hat q_{c,e}$.

<!-- FALTA: transcribir las dos tablas (conteo y probabilidad por clase). -->
[FALTA DATO: conteos $n_{c,g}$ y $m_{c,e}$ y probabilidades $\hat p_{c,g}$, $\hat q_{c,e}$ de la réplica 1. Sugerencia de formato:]

| $g$ | $n_{0,g}$ | $\hat p_{0,g}$ | $n_{1,g}$ | $\hat p_{1,g}$ |
|---|---|---|---|---|
| Female/White | [FALTA] | [FALTA] | [FALTA] | [FALTA] |
| … (10 filas) | | | | |

| $e$ | $m_{0,e}$ | $\hat q_{0,e}$ | $m_{1,e}$ | $\hat q_{1,e}$ |
|---|---|---|---|---|
| HS-grad | [FALTA] | [FALTA] | [FALTA] | [FALTA] |
| … (8 filas) | | | | |

### 2.5 Persona descompuesta

Fuente: `output/tablas/persona_replica1.csv`. Primera persona de prueba por `id_original`.

| Campo | Valor |
|---|---|
| `id_original` | 11 |
| Edad, horas | 37 años, 80 h/semana |
| Educación, categoría conjunta | Some-college, Male/Black |
| Clase observada | 1 |
| Contribución previa | 0 |
| Contribución edad | ≈ +0,009 |
| Contribución horas | +0,787 |
| Contribución educación | −0,472 |
| Contribución categoría conjunta | −0,352 |
| $D_{11}^{(1)}$ | −0,0277 |
| $\tau_1$ | 0,0991 |
| Predicción | 0 (falso negativo) |

<!-- FALTA: c_edad exacto y l0, l1. -->
[FALTA DATO: `c_edad`, `l0` y `l1` exactos. El valor de edad se obtuvo como $D$ menos las otras contribuciones redondeadas, y coincide con $\log f_1(37) - \log f_0(37) \approx 0{,}0090$ de la sección 2.3.]

### 2.6 Distribución de $D$ en validación

$n = 2\,830$. Mínimo −5,93, mediana −0,37, máximo 3,86. Con corte 0: 592 de 759 positivos y 1 487 de 2 071 negativos quedan bien clasificados (TPR 0,780, TNR 0,718 en validación, calculados de esos conteos).

### 2.7 Elección del umbral (validación)

Fuente: `output/tablas/candidatos_replica1.csv`, figura `output/figuras/curvas_validacion_replica1.png`.

| Cantidad | Valor |
|---|---|
| Valores distintos de $D$ ($L$) | 1 855 |
| Candidatos evaluados | 1 856 |
| Candidatos empatados en $J_{\max}$ | 1 |
| $J_{\max}$ (validación) | 0,5056 |
| $\varepsilon_{\text{mach}}$ | $2{,}220446 \times 10^{-16}$ |
| **$\tau_1$** | **0,0991012** |

En el corte $+\infty$ (todos negativos): exactitud 0,732, TNR 1, TPR 0, F1 0, FPR 0, PPV no estimable.

[FALTA DATO: TPR, TNR, PPV y exactitud de validación en $\tau_1$ (fila `elegido = TRUE` del CSV).] <!-- FALTA: indicadores de validación en tau_1 -->

### 2.8 Evaluación en prueba

$n_{\text{eval}} = 2\,833$.

| | Predicción 0 | Predicción 1 | Total |
|---|---|---|---|
| Clase 0 | TN = 1 552 | FP = 520 | 2 072 |
| Clase 1 | FN = 186 | TP = 575 | 761 |

| Exactitud | TPR | TNR | PPV | F1 | FPR | FNR | BA | J |
|---|---|---|---|---|---|---|---|---|
| 0,7508 | 0,7556 | 0,7490 | 0,5251 | 0,6196 | 0,2510 | 0,2444 | 0,7523 | 0,5046 |

## 3. Distribución entre las 200 réplicas (prueba)

Fuente: `output/tablas/resumen_replicas.csv` (con `replicas_indicadores.csv` de 200 filas). Figuras: `hist_tau.png`, `paneles_indicadores.png`, `boxplot_indicadores.png`. $r = 200$ en todas las variables (ningún indicador fue no estimable).

| Variable | Escala | $r$ | Media | sd | Mediana | p2,5 | p97,5 |
|---|---|---|---|---|---|---|---|
| $\tau_b$ | original | 200 | 0,0482 | 0,1314 | 0,0681 | −0,2156 | 0,2650 |
| Exactitud | proporción | 200 | [FALTA] | [FALTA] | 0,7363 | [FALTA] | [FALTA] |
| TPR | proporción | 200 | [FALTA] | [FALTA] | 0,7582 | [FALTA] | [FALTA] |
| TNR | proporción | 200 | [FALTA] | [FALTA] | 0,7283 | [FALTA] | [FALTA] |
| PPV | proporción | 200 | [FALTA] | [FALTA] | 0,5063 | [FALTA] | [FALTA] |
| F1 | proporción | 200 | [FALTA] | [FALTA] | 0,6062 | [FALTA] | [FALTA] |
| FPR | proporción | 200 | [FALTA] | [FALTA] | 0,2717* | [FALTA] | [FALTA] |
| FNR | proporción | 200 | [FALTA] | [FALTA] | 0,2418* | [FALTA] | [FALTA] |
| BA | proporción | 200 | [FALTA] | [FALTA] | 0,7418 | [FALTA] | [FALTA] |
| J | original | 200 | [FALTA] | [FALTA] | 0,4837 | [FALTA] | [FALTA] |

\* Derivadas: en cada réplica FPR = 1 − TNR y FNR = 1 − TPR, y la mediana tipo 7 respeta esa transformación, así que la mediana de FPR es 1 − 0,7283 y la de FNR es 1 − 0,7582. Confirmar en el CSV.

<!-- FALTA: completar media, sd, p2.5 y p97.5 de los 9 indicadores desde resumen_replicas.csv. -->
[FALTA DATO: media, sd, p2,5 y p97,5 de los nueve indicadores.]

Rango completo de $\tau_b$: mínimo −0,3231, máximo 0,3195; 200 valores distintos.

## 4. Errores por categoría conjunta

Fuentes: `output/tablas/resumen_grupos.csv` (30 filas), `grupos_replicas.csv` (2 000 filas), `grupos_replica1.csv`, `marginales_sexo_replica1.csv`, `marginales_raza_replica1.csv`; figura `output/figuras/tasas_grupos.png`.

### 4.1 Medianas entre réplicas (prueba)

TPR y FNR tienen denominador $n_1$ (positivos reales del grupo); FPR, $n_0$ (negativos reales). Entre paréntesis, la mediana del denominador.

| Categoría | TPR mediana ($n_1$) | FPR mediana ($n_0$) | $r$ TPR |
|---|---|---|---|
| Male/Asian-Pac-Islander | 0,893 (23) | 0,474 (42) | 200 |
| Male/White | 0,860 (590) | 0,438 (1 078) | 200 |
| Female/White | 0,321 (102) | [FALTA] | 200 |
| Female/Black | 0,125 (8) | 0,008 (120) | 200 |
| Female/Amer-Indian-Eskimo | [FALTA] | 0,000 (9) | 156 |
| Female/Other | 0,000 (0) | 0,000 (7) | 93 |
| Male/Black | [FALTA] | [FALTA] | 200 |
| Male/Amer-Indian-Eskimo | [FALTA] | [FALTA] | 182 |
| Male/Other | [FALTA] | [FALTA] | 170 |
| Female/Asian-Pac-Islander | [FALTA] | [FALTA] | 198 |

Los $r$ de TPR se obtienen como 200 menos las réplicas sin positivos en prueba (Female/Other 107, Female/Amer-Indian-Eskimo 44, Male/Other 30, Male/Amer-Indian-Eskimo 18, Female/Asian-Pac-Islander 2; 201 en total).

<!-- FALTA: completar las 30 filas (mediana, p2.5, p97.5, denominador mín/mediano/máx, r) desde resumen_grupos.csv. -->
[FALTA DATO: celdas marcadas, más p2,5, p97,5, FNR y los denominadores mínimo y máximo de todos los grupos.]

### 4.2 Marginales por sexo (réplica 1, prueba)

Conteos sumados por sexo antes de calcular las tasas.

| Sexo | TPR | FNR | FPR |
|---|---|---|---|
| Female | 0,327 | 0,673 | 0,063 |
| Male | 0,830 | 0,170 | 0,385 |

FNR = 1 − TPR. [FALTA DATO: $n$, $n_1$, $n_0$ y la matriz por sexo, en `marginales_sexo_replica1.csv`.] <!-- FALTA -->

### 4.3 Marginales por raza y composición por grupo (réplica 1)

<!-- FALTA: transcribir marginales_raza_replica1.csv y grupos_replica1.csv. -->
[FALTA DATO: tabla de 5 filas por raza y tabla de 10 filas por categoría conjunta, con $n$, $n_1$, $n_0$, prevalencia, matriz y tasas.]

### 4.4 Comprobación de agregación

En las 200 réplicas, las 10 matrices por grupo suman la matriz global y $\sum_g n_g$ es igual al tamaño de prueba. Las marginales por sexo y por raza de la réplica 1 suman la matriz global.

## 5. Diagnósticos (réplica 1, entrenamiento)

Fuentes: `output/figuras/qq_replica1.png`, `edad_horas_replica1.png`, `output/tablas/educacion_g_replica1.csv`.

| Diagnóstico | Resultado |
|---|---|
| Q–Q edad, clase 0 | Piso en 17–20 años y cola superior larga (asimetría a la derecha) |
| Q–Q edad, clase 1 | Buen ajuste en el centro, cola inferior más corta |
| Q–Q horas, ambas clases | Valores discretos, gran masa en 40 (en clase 0 el rango intercuartílico es casi nulo), topes en 1 y 99 |
| Pearson edad–horas | 0,024 (clase 0), −0,122 (clase 1) |
| Educación × categoría conjunta | 32 de 160 celdas en cero, concentradas en grupos pequeños con educación alta |

## 6. Verificaciones numéricas (200 réplicas)

Fuente: `output/tablas/verificaciones_replicas.csv`.

| Verificación | Resultado |
|---|---|
| Previas, $\hat p_{c,g}$, $\hat q_{c,e}$ suman 1 | Sí; error máximo 1,1·10⁻¹⁶ |
| $n_*$ por clase en entrenamiento | Sí, 6 077 en todas |
| Destinos disjuntos y completos | Sí |
| Puntajes finitos | Sí |
| $D$ recalculado `identical()` al guardado | Sí |
| Contribuciones suman $D$ | Sí; máximo relativo 2,10·ε (límite 16·ε), máximo absoluto 9,1·10⁻¹⁵ |
| Matriz de prueba suma $n$ | Sí |
| Grupos suman la matriz global | Sí |
| Funciones a mano frente a R base | Diferencia máxima 4,4·10⁻¹⁶ (sd con empates); `dnorm` 3,6·10⁻¹⁵; percentiles 1,1·10⁻¹⁶ |

## 7. Trazabilidad y duplicados

Fuente: `output/tablas/trazabilidad.csv`. Perfil = las 15 columnas originales, sin `id_original`.

| Indicador | Valor |
|---|---|
| Filas de la tabla analítica | 28 308 |
| Perfiles distintos | 28 289 |
| Duplicados excedentes | 19 |
| Personas de prueba (réplica 1) | 2 833 |
| Con perfil igual a alguien de entrenamiento | 3 |
| Con perfil igual a alguien de validación | 1 |
| Con perfil igual a alguien de cualquiera de los dos | 4 (0,14 %) |

## 8. Ejecución y reproducibilidad

| Concepto | Valor |
|---|---|
| Fecha, entorno | 2026-10-22, R 4.6.1, Windows 11 |
| `Rscript run_all.R` desde cero | 137,5 s, sin errores |
| De ellos, 200 réplicas (`05`) | 123,2 s (89 %) |
| Archivos generados | 200 `.rds` (33,9 MB), 17 tablas, 7 figuras |
| Segunda ejecución desde cero | `.rds` `identical()` y CSV idénticos línea a línea |
| Tests (`tests/`, 9 scripts) | Todos pasan, unos 12 s |
