# Documentación técnica

Documento 3 de 5. Explica qué calcula cada parte del proyecto, con qué fórmula, en qué archivo y cómo se verifica. Los contratos de cada función pública (argumentos, tipos y columnas exactas) están en `docs/arquitectura.md`, que manda sobre este documento si difieren; la rúbrica en PDF manda sobre ambos.

## 1. Entorno y reglas de implementación

| Aspecto | Decisión |
|---|---|
| Lenguaje | GNU R base, sin paquetes de modelado (`caret`, `tidymodels`, etc.) |
| Versión de referencia | R 4.6.1, Windows 11 (`logs/sesion.txt` guarda `sessionInfo()`, `RNGkind()` y `EPS`) |
| Generador aleatorio | `set.seed(semilla, kind = "Mersenne-Twister", normal.kind = "Inversion", sample.kind = "Rejection")` dentro de `particionar()` |
| Semillas | $B = 200$; réplica $b$ usa `semilla_replica(b)` $= 20261021 + b - 1$ (de 20 261 021 a 20 261 220) |
| ε de máquina | `EPS <- .Machine[["double.eps"]]` $= 2^{-52} \approx 2{,}22 \times 10^{-16}$ |
| Estadísticos a mano | `media_manual`, `sd_manual` ($n - 1$), `percentil_tipo7` en `R/00_utilidades.R`; `log_densidad_normal` en `R/03_modelo.R`. `mean`, `sd`, `dnorm` y `quantile` aparecen solo dentro de `stopifnot()` |
| Escritura de tablas | `escribir_csv()` con 17 cifras significativas (`sprintf("%.17g")`), ida y vuelta exacta con `read.csv`. Nunca `write.csv()` directo |
| Datos crudos | `data/raw/` nunca se modifica |

## 2. Estructura y dependencias

```
run_all.R                 solo source() en orden
R/00_utilidades.R   nivel 0  estadísticos a mano, escribir_csv
R/00_config.R       nivel 0  constantes, rutas, niveles de factores, semilla_replica()
R/01_datos.R        nivel 1  data/raw → data/processed
R/02_particion.R    nivel 2  particionar()
R/03_modelo.R       nivel 2  ajustar_nb(), puntuar(), log_densidad_normal()
R/04_umbral_metricas.R nivel 2  candidatos, umbral, matrices, indicadores, resumir()
R/05_replicas.R     nivel 3  bucle b = 1..B → output/replicas/, logs/
R/06_resumen.R      nivel 4  distribución de τ_b e indicadores
R/07_grupos.R       nivel 4  errores por categoría conjunta
R/08_diagnosticos.R nivel 4  Q–Q, dependencias, verificaciones, duplicados
R/09_replica1.R     nivel 4  evidencias de la réplica 1
tests/test_NN_*.R   fuera de la jerarquía; los corre el desarrollador
```

Regla: un archivo solo usa niveles inferiores. Los tres módulos de nivel 2 no se llaman entre sí (`04` recibe $D$ como vector y no conoce el modelo). `05` es el único que combina partición, modelo y umbral. Los scripts de nivel 4 no reajustan: solo leen los `.rds` y la tabla analítica.

## 3. Datos (`R/01_datos.R`)

- Lectura: `read.csv(header = FALSE, col.names = COLUMNAS_ADULT, strip.white = TRUE, na.strings = c("?", ""))`.
- `id_original` = número de línea en `adult.data` (se cuentan las líneas no vacías con `readLines()` y se comprueba que coincidan con las filas leídas).
- Orden del registro: filas originales → excluidas por faltantes en `COLUMNAS_REQUERIDAS` → excluidas por `education_num < 9` → total final.
- Variables derivadas: `clase` (integer 0/1), `educacion` (factor con `NIVELES_E`, 8 niveles), `g` (factor `"Sexo/Raza"` con `NIVELES_G`, 10 niveles). Los niveles son fijos para que un conteo cero exista en toda réplica.
- Salidas: `data/processed/tabla_analitica.rds`, `tabla_analitica.csv` (28 308 × 19), `registro_exclusiones.csv`.

## 4. Partición por réplica (`R/02_particion.R`)

Dentro de cada clase $c$:

$$
N_c^{\text{disp}} = \lfloor 0{,}8 N_c \rfloor, \quad N_c^{\text{val}} = \lfloor 0{,}1 N_c \rfloor, \quad N_c^{\text{pru}} = N_c - N_c^{\text{disp}} - N_c^{\text{val}}, \quad n_* = \min(N_0^{\text{disp}}, N_1^{\text{disp}})
$$

Orden fijo de consumo del generador: `set.seed()`; permutación de clase 0 y de clase 1; sorteo de $n_*$ entre disponibles de clase 0 y de clase 1. Siempre `x[sample.int(length(x), n)]`.

Salida `list(semilla, n_estrella, tamanos, indices, destino)`. `destino` es un factor con 4 niveles (`entrenamiento`, `validacion`, `prueba`, `sin_seleccionar`). Se detiene si validación o prueba no tienen ambas clases.

## 5. Modelo (`R/03_modelo.R`)

Estimación solo con el entrenamiento $b$:

$$
\hat\pi_c = \frac{n_c}{n_0 + n_1}, \qquad
\hat\mu_{c,j} = \frac{1}{n_c}\sum_{i \in T_c} z_{i,j}, \qquad
\hat\sigma_{c,j} = \sqrt{\frac{\sum_{i \in T_c}(z_{i,j} - \hat\mu_{c,j})^2}{n_c - 1}}
$$

$$
\hat p_{c,g} = \frac{n_{c,g} + 1}{n_c + 10}, \qquad \hat q_{c,e} = \frac{m_{c,e} + 1}{n_c + 8}
$$

Log-densidad calculada directamente en escala log:

$$
\log f_{c,j}(z) = -\log\hat\sigma_{c,j} - \tfrac12\log(2\pi) - \frac{(z - \hat\mu_{c,j})^2}{2\hat\sigma_{c,j}^2}
$$

Puntaje, diferencia y regla:

$$
\ell_c(x_i) = \log\hat\pi_c + \log f_{c,\text{edad}}(z_{i,\text{edad}}) + \log f_{c,\text{horas}}(z_{i,\text{horas}}) + \log\hat q_{c,e_i} + \log\hat p_{c,g_i}
$$

$$
D_i = \ell_1(x_i) - \ell_0(x_i), \qquad \hat c_i = \mathbb{1}[D_i \ge \tau_b]
$$

`puntuar()` devuelve `l0`, `l1`, las cinco contribuciones (`c_previa`, `c_edad`, `c_horas`, `c_educacion`, `c_g`, cada una término de clase 1 menos término de clase 0) y `D`. `ajustar_nb()` se detiene con `stop()` si una clase tiene menos de 2 personas o alguna $\hat\sigma = 0$, como pide la rúbrica.

## 6. Umbral e indicadores (`R/04_umbral_metricas.R`)

- **Candidatos:** con $u_1 < \dots < u_L$ los valores distintos de $D$ en validación, $\{u_1\} \cup \{u_h/2 + u_{h+1}/2\} \cup \{+\infty\}$. Si el punto medio redondea fuera de $(u_h, u_{h+1}]$ se usa $u_{h+1}$. Con $L = 1$, solo $\{u_1, +\infty\}$.
- **Selección:** máximo de $J = \text{TPR} + \text{TNR} - 1$; empatados si $|J - J_{\max}| \le \varepsilon$; desempate por menor $|\tau|$ y luego menor $\tau$. Se guardan todos los candidatos, sus $J$, $J_{\max}$, $\varepsilon$ y el elegido.
- **Matriz:** $(TN, FP, FN, TP)$ con clase positiva 1.
- **Indicadores:** exactitud $(TP+TN)/n$; TPR $TP/(TP+FN)$; TNR $TN/(TN+FP)$; PPV $TP/(TP+FP)$; F1 $2TP/(2TP+FP+FN)$; FPR $FP/(TN+FP)$; FNR $FN/(TP+FN)$; BA $(\text{TPR}+\text{TNR})/2$; $J$. Denominador cero → `NA` (no estimable).
- **Por grupo:** `matrices_por_grupo()` devuelve 10 filas (orden `NIVELES_G`) con conteos, $n$, $n_1$, $n_0$, TPR, FPR, FNR. Las predicciones son las del clasificador global.
- **Resumen:** `resumir(x)` descarta `NA` y devuelve $r$, media, sd, mediana, p2,5, p97,5. Con $r = 1$ la sd es `NA`; con $r = 0$ todo `NA` salvo $r$.
- **Percentil tipo 7:** $h = 1 + (r-1)p$; $Q(p) = x_{(\lfloor h\rfloor)} + (h - \lfloor h\rfloor)(x_{(\lfloor h\rfloor+1)} - x_{(\lfloor h\rfloor)})$.

## 7. Réplicas (`R/05_replicas.R`)

Para $b = 1, \dots, 200$: `semilla_replica(b)` → `particionar()` → `ajustar_nb()` (entrenamiento) → `puntuar()` + `elegir_umbral()` (validación) → `puntuar()`, `predecir()`, `matriz_confusion()`, `indicadores()`, `matrices_por_grupo()` (prueba).

Cada réplica se guarda en `output/replicas/replica_XXX.rds` como `list(b, semilla, particion, modelo, umbral, prueba, matriz_prueba, indicadores_prueba, grupos_prueba)`. Así quedan guardados índices, parámetros, candidatos, umbral y resultados de prueba, como pide la rúbrica (sección 10). También escribe `logs/semillas.csv` y `logs/sesion.txt`.

`B_EJECUCION` permite correr menos réplicas para pruebas sin tocar `00_config.R`.

## 8. Análisis (nivel 4)

| Script | Tablas (`output/tablas/`) | Figuras (`output/figuras/`) |
|---|---|---|
| `06_resumen.R` | `replicas_indicadores.csv` (200 filas), `resumen_replicas.csv` (10 filas) | `hist_tau.png`, `paneles_indicadores.png` (2×4), `boxplot_indicadores.png` |
| `07_grupos.R` | `grupos_replicas.csv` (2 000 filas), `resumen_grupos.csv` (30 filas), `grupos_replica1.csv`, `marginales_sexo_replica1.csv`, `marginales_raza_replica1.csv` | `tasas_grupos.png` |
| `08_diagnosticos.R` | `educacion_g_replica1.csv` (160 filas), `verificaciones_replicas.csv` (200 filas), `trazabilidad.csv` | `qq_replica1.png`, `edad_horas_replica1.png` |
| `09_replica1.R` | `tamanos_replica1.csv`, `parametros_replica1.csv`, `densidad_ejemplo_replica1.csv`, `probabilidades_g_replica1.csv`, `probabilidades_e_replica1.csv`, `persona_replica1.csv`, `candidatos_replica1.csv` | `curvas_validacion_replica1.png` |

Total: 17 tablas y 7 figuras. Todas las figuras son R base, 1600×1000 a 150 ppp, e indican réplica o resumen, subconjunto y escala. Las tasas se guardan como proporciones en $[0, 1]$ y $J$ en $[-1, 1]$. Ninguna figura consume el generador aleatorio (sin `jitter()`; se usa transparencia).

Las marginales por sexo y raza **suman conteos antes de calcular tasas**, como pide la rúbrica.

## 9. Verificaciones

### Tolerancias

| Comparación | Tolerancia |
|---|---|
| Suma de $K$ probabilidades frente a 1 | $\lvert\sum - 1\rvert \le K\varepsilon$ ($K = 2$, 8 o 10) |
| Suma de las 5 contribuciones frente a $D_i$ | $16\,\varepsilon \max(\lvert\ell_1\rvert, \lvert\ell_0\rvert, 1)$, persona a persona |
| Identidades entre indicadores | $4\varepsilon$ |
| Función a mano frente a R base | $n\,\varepsilon \max(1, \lvert\text{ref}\rvert)$ |
| Valores deterministas (recalcular una réplica) | `identical()` |

La tolerancia de las contribuciones es relativa porque el error depende del tamaño de los puntajes que se restan, no de $D$, que puede ser casi cero. Unas 14 operaciones encadenadas dan una cota de unos $7\varepsilon\max\lvert\ell_c\rvert$; $k = 16$ deja un margen de más de 2.

### Qué se verifica en las 200 réplicas (`verificaciones_replicas.csv`)

Previas, $\hat p_{c,g}$ y $\hat q_{c,e}$ suman 1; $n_*$ por clase en entrenamiento; destinos disjuntos; todas las personas con destino; puntajes de prueba finitos; $D$ recalculado con el modelo guardado `identical()` al guardado; contribuciones suman $D$; la matriz suma el tamaño de prueba; las 10 matrices de grupo suman la global.

### Tests por módulo (`tests/`)

9 scripts (00, 02–09), fuera de `run_all.R`, que fallan con `stopifnot()`. Incluyen casos a mano (candidatos de 5 puntos, empates, $L = 1$, punto medio no representable, denominadores cero), comparaciones con R base, y la reproducción desde cero de las réplicas 1, 100 y 200 con resultado `identical()` a sus `.rds`.

## 10. Reproducibilidad

- Ejecución de referencia desde cero (2026-10-22): `Rscript run_all.R` en 137,5 s sin errores; 05 es el 89 % del tiempo.
- Una segunda ejecución desde cero dio `tabla_analitica.rds` y los 200 `.rds` `identical()` a los anteriores, y los 17 CSV idénticos línea a línea.
- Se conservan: archivo fuente y diccionario (`data/raw/`), tabla analítica con `id_original` (`data/processed/`), índices, parámetros, candidatos, umbral y resultados por réplica (`output/replicas/`), semillas (`logs/semillas.csv`) y versiones (`logs/sesion.txt`).

<!-- FALTA: confirmar cómo se entregan data/raw, data/processed, output y logs, porque .gitignore los excluye del repositorio. -->
**[FALTA DATO: forma de entrega de `data/raw/`, `data/processed/`, `output/` y `logs/`.]** El `.gitignore` los excluye del repositorio. La rúbrica pide entregar el archivo fuente, el diccionario, la tabla analítica y el registro de semillas y versiones, así que hay que incluirlos en la entrega (por ejemplo, un `.zip` con la carpeta completa tras correr `run_all.R`, o quitar esas líneas del `.gitignore` como indica su comentario).
