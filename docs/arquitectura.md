# Naive Bayes mixto en R base: arquitectura y estructura del proyecto

Fuente normativa: la rúbrica en PDF del curso (INFO-1165, Prueba Práctica 2). Si este documento y la rúbrica difieren, manda la rúbrica. Los cambios a este documento se anotan como propuesta en `docs/bitacora.md`; no se editan de paso al implementar un módulo.

## 1. Arquitectura matemática (confirmada contra la rúbrica)

### Datos y población

Solo `adult.data` (sin encabezado, 15 columnas). Se recortan espacios en las etiquetas; `""` y `"?"` se tratan como `NA`.

Orden obligatorio y registrado:

1. filas originales;
2. exclusiones por faltantes **solo en las columnas requeridas** (age, hours-per-week, education, sex, race, education-num, ingreso);
3. exclusiones por $\text{education-num} < 9$;
4. total final.

Se agrega `id_original` = número de fila en el archivo. La clase es

$$
c_i = \begin{cases} 1, & \text{ingreso} > 50\text{K} \\ 0, & \text{ingreso} \le 50\text{K} \end{cases}
$$

### Factores fijos

$\mathcal{E}$ con 8 niveles (HS-grad, Some-college, Assoc-voc, Assoc-acdm, Bachelors, Masters, Prof-school, Doctorate) y $\mathcal{G} = \text{sex} \times \text{race}$ con 10 niveles ($2$ sexos $\times$ $5$ grupos), definidos con `factor(..., levels = ...)` una sola vez, para que un conteo cero siga existiendo en cada réplica. Así $K_E = 8$ y $K_G = 10$.

### Partición por réplica $b$

Semilla $20261021 + b - 1$, siempre desde la tabla analítica completa. Estratificada **dentro de cada clase** $c$:

$$
N_c^{\text{disp}} = \lfloor 0{,}80\, N_c \rfloor, \qquad
N_c^{\text{val}} = \lfloor 0{,}10\, N_c \rfloor, \qquad
N_c^{\text{pru}} = N_c - N_c^{\text{disp}} - N_c^{\text{val}}
$$

$$
n_* = \min\left(N_0^{\text{disp}},\, N_1^{\text{disp}}\right)
$$

Se sortean sin reemplazo $n_*$ personas de cada clase entre las disponibles, de modo que $n_0^{(b)} = n_1^{(b)} = n_*$. Los disponibles no elegidos se registran como cuarto destino ("sin seleccionar"). Validación y prueba **no se balancean**: conservan la prevalencia de la tabla.

### Estimación (solo con el entrenamiento $b$)

**Previa.**

$$
\hat\pi_c^{(b)} = \frac{n_c^{(b)}}{n_0^{(b)} + n_1^{(b)}} = 0{,}5
$$

Vale exactamente $0{,}5$ por construcción. Se calcula igual (no se fija a mano) y su logaritmo se incluye en el puntaje, aunque se cancele en $D_i^{(b)}$.

**Numéricas** ($j \in \{\text{edad}, \text{horas}\}$, con $T_c^{(b)}$ las personas de clase $c$ del entrenamiento):

$$
\hat\mu_{c,j}^{(b)} = \frac{1}{n_c^{(b)}} \sum_{i \in T_c^{(b)}} z_{i,j}, \qquad
\hat\sigma_{c,j}^{(b)} = \sqrt{\frac{\sum_{i \in T_c^{(b)}} \left(z_{i,j} - \hat\mu_{c,j}^{(b)}\right)^2}{n_c^{(b)} - 1}}
$$

La log-densidad se calcula directamente en escala logarítmica:

$$
\log f_{c,j}^{(b)}(z) = -\log \hat\sigma_{c,j}^{(b)} - \tfrac{1}{2}\log(2\pi) - \frac{\left(z - \hat\mu_{c,j}^{(b)}\right)^2}{2\left(\hat\sigma_{c,j}^{(b)}\right)^2}
$$

y se contrasta con `dnorm(log = TRUE)` solo como verificación.

**Categóricas** (Laplace, $\alpha = 1$):

$$
\hat p_{c,g}^{(b)} = \frac{n_{c,g}^{(b)} + \alpha}{n_c^{(b)} + \alpha K_G} = \frac{n_{c,g}^{(b)} + 1}{n_c^{(b)} + 10}, \qquad
\hat q_{c,e}^{(b)} = \frac{m_{c,e}^{(b)} + \alpha}{n_c^{(b)} + \alpha K_E} = \frac{m_{c,e}^{(b)} + 1}{n_c^{(b)} + 8}
$$

### Puntaje y regla de decisión

$$
\ell_c^{(b)}(x_i) = \log \hat\pi_c^{(b)} + \log f_{c,\text{edad}}^{(b)}(z_{i,\text{edad}}) + \log f_{c,\text{horas}}^{(b)}(z_{i,\text{horas}}) + \log \hat q_{c,e_i}^{(b)} + \log \hat p_{c,g_i}^{(b)}
$$

$$
D_i^{(b)} = \ell_1^{(b)}(x_i) - \ell_0^{(b)}(x_i), \qquad
\hat c_i^{(b)} = \begin{cases} 1, & D_i^{(b)} \ge \tau_b \\ 0, & D_i^{(b)} < \tau_b \end{cases}
$$

$D_i^{(b)}$ se guarda también como suma de sus 5 contribuciones (previa, edad, horas, educación, categoría conjunta).

### Umbral $\tau_b$ en validación

Sean $u_1 < \dots < u_L$ los valores distintos de $D^{(b)}$ en validación. Candidatos:

$$
\tau \in \left\{ u_1 \right\} \cup \left\{ \tfrac{u_h}{2} + \tfrac{u_{h+1}}{2} : h = 1, \dots, L-1 \right\} \cup \left\{ +\infty \right\}
$$

(si $L = 1$: solo $u_1$ y $+\infty$). Para cada candidato:

$$
J(\tau) = \text{TPR}(\tau) + \text{TNR}(\tau) - 1
$$

Empate: $\left| J(\tau) - J_{\max} \right| \le \varepsilon_{\text{mach}}$, con $\varepsilon_{\text{mach}}$ = `.Machine[["double.eps"]]`. Entre empatados se elige el menor $|\tau|$ y luego el menor $\tau$. Se guardan todos los candidatos, sus $J$, $J_{\max}$, $\varepsilon_{\text{mach}}$ y el elegido.

### Evaluación en prueba

Matriz $(TN, FP, FN, TP)$ y nueve indicadores:

| Indicador | Fórmula |
|---|---|
| Exactitud | $(TP + TN)/n_{\text{eval}}$ |
| TPR | $TP/(TP + FN)$ |
| TNR | $TN/(TN + FP)$ |
| PPV | $TP/(TP + FP)$ |
| F1 | $2TP/(2TP + FP + FN)$ |
| FPR | $FP/(TN + FP)$ |
| FNR | $FN/(TP + FN)$ |
| BA | $(\text{TPR} + \text{TNR})/2$ |
| Youden $J$ | $\text{TPR} + \text{TNR} - 1$ |

Denominador cero $\Rightarrow$ `NA` ("no estimable").

### Resumen entre réplicas

Para $\tau_b$ y cada indicador: número $r$ de valores estimables, media, desviación estándar, mediana y percentiles $2{,}5$ y $97{,}5$. Percentil tipo 7 implementado a mano: con los $r$ valores ordenados $x_{(1)} \le \dots \le x_{(r)}$,

$$
h = 1 + (r - 1)\,p, \qquad
Q(p) = x_{(\lfloor h \rfloor)} + \left(h - \lfloor h \rfloor\right)\left(x_{(\lfloor h \rfloor + 1)} - x_{(\lfloor h \rfloor)}\right)
$$

con $p \in \{0{,}025;\ 0{,}975\}$, contrastado con `quantile(type = 7)`.

### Por categoría conjunta

En cada prueba, matriz por $g \in \mathcal{G}$ con las predicciones globales; $\text{TPR}_g$, $\text{FPR}_g$, $\text{FNR}_g$ con sus denominadores; resumen entre réplicas (mediana, $p_{2,5}$, $p_{97,5}$, $r$ estimables). Verificar que $\sum_{g \in \mathcal{G}} M_g^{(b)} = M^{(b)}$. Réplica 1: además marginales por sexo y por raza sumando conteos antes de calcular tasas.

### Diagnósticos (réplica 1 salvo indicación)

4 Q–Q (edad/horas $\times$ clase), edad vs. horas, tabla educación $\times$ $\mathcal{G}$ por clase, sumas de probabilidades con su error absoluto

$$
\sum_{g \in \mathcal{G}} \hat p_{c,g}^{(b)} \approx 1, \qquad \left| \sum_{g \in \mathcal{G}} \hat p_{c,g}^{(b)} - 1 \right| \approx 0
$$

(igual para educación y previas), disjunción de destinos, $n_*$ por clase, puntajes finitos, suma de contribuciones $= D_i^{(b)}$, duplicados de perfil (15 columnas) y coincidencias de perfil prueba vs. entrenamiento/validación.

## 2. Estructura del repositorio

```
.
├── CLAUDE.md                 # contexto y reglas de trabajo
├── run_all.R                 # orquestador: solo source() en orden, sin lógica propia
├── R/
│   ├── 00_utilidades.R       # nivel 0: utilidades compartidas (estadísticos a mano, escribir_csv)
│   ├── 00_config.R           # nivel 0: constantes, rutas, niveles de factores
│   ├── 01_datos.R            # nivel 1: lectura, limpieza, filtro, tabla analítica
│   ├── 02_particion.R        # nivel 2: particionar()
│   ├── 03_modelo.R           # nivel 2: estimación y puntajes
│   ├── 04_umbral_metricas.R  # nivel 2: umbral, matrices, indicadores, resúmenes
│   ├── 05_replicas.R         # nivel 3: bucle b = 1..B, escribe output/replicas/
│   ├── 06_resumen.R          # nivel 4: distribución de tau_b e indicadores
│   ├── 07_grupos.R           # nivel 4: errores por categoría conjunta
│   ├── 08_diagnosticos.R     # nivel 4: Q–Q, dependencias, duplicados, verificaciones
│   └── 09_replica1.R         # nivel 4: evidencias específicas de b = 1
├── data/
│   ├── raw/                  # adult.data, adult.names (intactos, nunca se sobrescriben)
│   └── processed/            # tabla_analitica.rds, tabla_analitica.csv, registro_exclusiones.csv
├── output/
│   ├── replicas/             # replica_001.rds … replica_200.rds
│   ├── tablas/               # csv de resúmenes
│   └── figuras/              # png
├── logs/                     # sesion.txt (sessionInfo, RNGkind, eps), semillas.csv
├── tests/                    # test_NN_modulo.R: verificaciones por módulo, fuera de run_all.R
└── docs/
    ├── arquitectura.md       # este documento
    └── bitacora.md           # registro por módulo
```

### Jerarquía de dependencias

| Nivel | Archivos | Puede usar | Efectos en disco |
|---|---|---|---|
| 0 | `00_utilidades.R`, `00_config.R` | nada | ninguno |
| 1 | `01_datos.R` | nivel 0 | lee `data/raw/`, escribe `data/processed/` |
| 2 | `02_particion.R`, `03_modelo.R`, `04_umbral_metricas.R` | nivel 0 | ninguno (solo definen funciones) |
| 3 | `05_replicas.R` | niveles 0–2 y `data/processed/` | escribe `output/replicas/` y `logs/` |
| 4 | `06`–`09` | niveles 0–2, `data/processed/` y `output/replicas/` | escribe `output/tablas/` y `output/figuras/` |
| — | `tests/test_NN_*.R` | niveles 0–2 y `data/processed/` | ninguno (no escribe en `output/`) |

Un archivo solo depende de niveles inferiores. Los dos archivos de nivel 0 no dependen de nada, ni entre sí: `00_utilidades.R` solo contiene utilidades compartidas sin dependencias (estadísticos a mano y `escribir_csv()`) y `00_config.R` solo constantes. `run_all.R` carga `00_utilidades.R` antes que `00_config.R`. Los tres archivos de nivel 2 no se llaman entre sí: `04` recibe $D$ como vector numérico y no conoce el modelo. `05` es el único que combina partición, modelo y umbral. Los scripts de nivel 4 no vuelven a ajustar modelos: solo leen los `.rds`.

`tests/` queda fuera de la jerarquía: ningún archivo de `R/` lo usa y `run_all.R` no lo ejecuta. Lo corre el desarrollador al cerrar un módulo (`Rscript tests/test_02_particion.R` desde la raiz). Cada script hace `source()` de `00_utilidades.R`, `00_config.R` y del módulo que prueba, puede leer `data/processed/` y falla con `stopifnot()` si una verificación no se cumple.

## 3. Contratos de funciones públicas

Convenciones: la clase es `integer` con valores `0L`/`1L`; los índices son posiciones de fila en la tabla analítica (`integer`, ordenados de forma creciente); las matrices por clase tienen filas `"0"`, `"1"`.

### 00_utilidades.R (utilidades compartidas, sin dependencias)

Funciones que necesitan varios módulos que no pueden llamarse entre sí. No usa ningún objeto de `00_config.R`: todo lo que necesita lo recibe como argumento.

**Estadísticos a mano.** Reciben vectores numéricos sin `NA` (quien llama filtra los `NA` antes) y no tienen efectos secundarios.

`media_manual(x)`: `numeric` de longitud $n \ge 1$ $\to$ `numeric(1)`, $\sum x / n$.

`sd_manual(x)`: `numeric` de longitud $n \ge 2$ $\to$ `numeric(1)`, con denominador $n - 1$; usa `media_manual()`.

`percentil_tipo7(x, p)`: `numeric` de longitud $r \ge 1$, `numeric` con valores en $[0, 1]$ $\to$ `numeric` de la longitud de `p`. Ordena `x` y aplica $h = 1 + (r - 1)p$ con interpolación lineal (sección 1).

`log_densidad_normal()` se queda en `03_modelo.R`: es un componente del modelo (el término numérico del puntaje), no un estadístico de resumen, y solo lo usan `03` y los scripts que evalúan el modelo. Los tres estadísticos, en cambio, los necesitan a la vez la estimación (`03`) y los resúmenes (`04`).

**Escritura de tablas.**

`escribir_csv(df, ruta)`: `data.frame`, `character(1)` (ruta completa del archivo, que arma quien llama, p. ej. `file.path(RUTAS[["tablas"]], "resumen_replicas.csv")`) $\to$ `invisible(ruta)`. Único efecto: escribe el archivo.
- Reemplaza `write.csv()`, que solo escribe 15 cifras significativas.
- Las columnas `double` se escriben con `sprintf("%.17g", x)`. Así se recupera el valor exacto, y `Inf`, `-Inf` y `NaN` se escriben con esas etiquetas.
- Las columnas `integer` y `logical` se escriben sin comillas. Las columnas `character` y `factor` se escriben entre comillas; un factor se escribe con sus etiquetas.
- `NA` se escribe como `NA` sin comillas, sin nombres de fila, con separador `,` y punto decimal `.`.
- Ida y vuelta exacta: para `x <- read.csv(ruta, stringsAsFactors = FALSE)`, cada columna `double`, `integer`, `logical` o `character` de `df` es `identical()` a la de `x`, y un factor es `identical()` a `as.character()` de la suya.
- Excepción: una columna `double` que es entera en todas sus filas vuelve como `integer` y se compara con `as.numeric()`. Una columna `double` que es toda `NA` vuelve como `logical`.

### 00_config.R (objetos, sin funciones salvo una)

| Objeto | Tipo | Valor |
|---|---|---|
| `B` | integer | `200L` |
| `SEMILLA_BASE` | integer | `20261021L` |
| `ALPHA` | numeric | `1` |
| `EPS` | numeric | `.Machine[["double.eps"]]` |
| `P_PERCENTILES` | numeric | `c(0.025, 0.975)` |
| `PROPORCIONES` | numeric(3) | `c(disp = 0.8, val = 0.1, pru = 0.1)`, reparto dentro de cada clase |
| `COLUMNAS_ADULT` | character(15) | nombres de `adult.names`, con `_` en lugar de `-` |
| `COLUMNAS_REQUERIDAS` | character(7) | age, hours_per_week, education, sex, race, education_num, income: un faltante en ellas excluye la fila |
| `ETIQUETAS_INGRESO` | character(2) | `c("0" = "<=50K", "1" = ">50K")` |
| `EDUCACION_NUM_MIN` | integer | `9L` |
| `NIVELES_E` | character(8) | HS-grad, Some-college, Assoc-voc, Assoc-acdm, Bachelors, Masters, Prof-school, Doctorate |
| `NIVELES_SEXO` | character(2) | Female, Male |
| `NIVELES_RAZA` | character(5) | White, Black, Asian-Pac-Islander, Amer-Indian-Eskimo, Other |
| `NIVELES_G` | character(10) | `"Female/White"`, …, `"Male/Other"` (sexo externo, raza interno) |
| `K_E`, `K_G` | integer | `length(NIVELES_E)`, `length(NIVELES_G)` |
| `INDICADORES` | character(9) | exactitud, TPR, TNR, PPV, F1, FPR, FNR, BA, J |
| `DESTINOS` | character(4) | entrenamiento, validacion, prueba, sin_seleccionar |
| `RUTAS` | list | `raw`, `processed`, `replicas`, `tablas`, `figuras`, `logs` |

`semilla_replica(b)`: `integer` $\to$ `integer`, devuelve `SEMILLA_BASE + b - 1L`.

### 01_datos.R

`leer_adult(ruta)`
- Entrada: `ruta` (character), ruta a `adult.data`.
- Salida: `data.frame` con `id_original` (integer, número de fila en el archivo) y las 15 columnas de `COLUMNAS_ADULT`; etiquetas sin espacios al inicio ni al final; `""` y `"?"` como `NA`.

`construir_tabla_analitica(crudo)`
- Entrada: salida de `leer_adult()`.
- Salida: `list(tabla, registro)`.
  - `tabla`: `data.frame` con `id_original`, las 15 columnas originales y las derivadas `clase` (integer 0/1), `educacion` (factor, `levels = NIVELES_E`), `g` (factor, `levels = NIVELES_G`). Filas ordenadas por `id_original`.
  - `registro`: `data.frame(paso, n)` con los pasos `filas_originales`, `excluidas_faltantes`, `excluidas_educacion`, `total_final`, en ese orden.

Al ejecutarse, el script escribe `tabla_analitica.rds`, `tabla_analitica.csv` y `registro_exclusiones.csv`.

### 02_particion.R

`particionar(clase, semilla)`
- Entrada: `clase` (integer 0/1, longitud $N$), `semilla` (integer).
- Salida: `list(semilla, n_estrella, tamanos, indices, destino)`.
  - `tamanos`: `data.frame` por clase con `N`, `disp`, `val`, `pru`, `entrenamiento`, `sin_seleccionar`.
  - `indices`: `list(entrenamiento, validacion, prueba, sin_seleccionar)` de vectores integer.
  - `destino`: factor de longitud $N$ con `levels = DESTINOS`.
- Orden fijo de consumo del generador, para reproducibilidad: `set.seed(semilla)`; para $c = 0$ y luego $c = 1$, una permutación de los índices de la clase (los primeros $N_c^{\text{disp}}$ son disponibles, los siguientes $N_c^{\text{val}}$ validación, el resto prueba); después, para $c = 0$ y luego $c = 1$, un sorteo de $n_*$ entre los disponibles. Se usa `x[sample.int(length(x), n)]`, nunca `sample(x, n)`.
- Falla con `stop()` si validación o prueba no contienen ambas clases.

### 03_modelo.R

Usa `media_manual()` y `sd_manual()` de `00_utilidades.R` para $\hat\mu_{c,j}$ y $\hat\sigma_{c,j}$.

`log_densidad_normal(z, mu, sigma)`: `numeric` $\to$ `numeric` de la misma longitud que `z`.

`ajustar_nb(entrenamiento)`
- Entrada: `data.frame` con `age`, `hours_per_week`, `educacion`, `g`, `clase`.
- Salida: `list(n, previa, mu, sigma, conteos_g, p_g, conteos_e, q_e)`.
  - `n`, `previa`: numeric(2) con nombres `"0"`, `"1"`.
  - `mu`, `sigma`: matriz 2×2, filas = clase, columnas = `edad`, `horas`.
  - `conteos_g`, `p_g`: matriz 2×10, columnas = `NIVELES_G`.
  - `conteos_e`, `q_e`: matriz 2×8, columnas = `NIVELES_E`.
- Falla con `stop()` si alguna clase tiene menos de 2 personas o alguna $\hat\sigma = 0$ (la rúbrica pide consultar al docente).

`puntuar(modelo, datos)`
- Entrada: salida de `ajustar_nb()` y `data.frame` con las mismas columnas predictoras.
- Salida: `data.frame` de `nrow(datos)` filas con `l0`, `l1`, las cinco contribuciones a la diferencia (`c_previa`, `c_edad`, `c_horas`, `c_educacion`, `c_g`, cada una como término de clase 1 menos término de clase 0) y `D`.

### 04_umbral_metricas.R

`candidatos_umbral(D)`: `numeric` $\to$ `numeric` creciente, terminado en `Inf`. Si un punto medio queda fuera de $(u_h, u_{h+1}]$ por redondeo, se usa $u_{h+1}$.

`predecir(D, tau)`: `numeric`, `numeric(1)` $\to$ integer 0/1 (`D >= tau`).

`matriz_confusion(clase, pred)`: integer, integer $\to$ integer(4) con nombres `TN`, `FP`, `FN`, `TP`.

`indicadores(m)`: salida de `matriz_confusion()` $\to$ numeric(9) con nombres `INDICADORES`; `NA` si el denominador es cero.

`elegir_umbral(D, clase, eps = EPS)`
- Salida: `list(tau, J_max, eps, candidatos)`, con `candidatos` un `data.frame(tau, TN, FP, FN, TP, TPR, TNR, J, empatado)` que incluye todos los cortes evaluados.

`matrices_por_grupo(clase, pred, g)`: integer, integer, factor (`levels = NIVELES_G`) $\to$ `data.frame` en formato largo de 10 filas, una por nivel y en el orden de `NIVELES_G`, sin nombres de fila (`row.names` por defecto `1:10`). Columnas, en este orden: `g` (factor, `levels = NIVELES_G`), `TN`, `FP`, `FN`, `TP` (integer), `n`, `n_1`, `n_0` (integer, con $n_1 = TP + FN$ y $n_0 = TN + FP$) y `TPR`, `FPR`, `FNR` (numeric, `NA` si el denominador es cero). Un grupo sin personas aparece igual, con conteos 0 y tasas `NA`.

`resumir(x)`: numeric (con posibles `NA`) $\to$ numeric con nombres `r`, `media`, `sd`, `mediana`, `p2.5`, `p97.5`; con $r = 1$ la `sd` es `NA` y con $r = 0$ todo es `NA` salvo `r`. Descarta los `NA` y usa `media_manual()`, `sd_manual()` y `percentil_tipo7()` de `00_utilidades.R` (la mediana es `percentil_tipo7(x, 0.5)`).

### 05_replicas.R (script, sin funciones públicas)

Para cada $b = 1, \dots, B$ escribe `output/replicas/replica_XXX.rds` (`XXX` = `b` con tres dígitos) con

`list(b, semilla, particion, modelo, umbral, prueba, matriz_prueba, indicadores_prueba, grupos_prueba)`

- `b` (integer) y `semilla` (integer, `semilla_replica(b)`).
- `particion`: salida de `particionar()`.
- `modelo`: salida de `ajustar_nb()`.
- `umbral`: salida de `elegir_umbral()` sobre validación.
- `prueba`: `data.frame` con `id_original`, `clase`, `g`, `c_previa`, `c_edad`, `c_horas`, `c_educacion`, `c_g`, `D` y `pred`.
- `matriz_prueba`: salida de `matriz_confusion()`; `indicadores_prueba`: salida de `indicadores()`.
- `grupos_prueba`: salida de `matrices_por_grupo()` tal cual, sin columna `b`.

También escribe `logs/semillas.csv` (`b`, `semilla`, `n_estrella`, tamaños de los 4 destinos) y `logs/sesion.txt` (`sessionInfo()`, `RNGkind()`, `EPS`).

### Tolerancias numéricas (todas las verificaciones)

Toda comparación entre valores calculados por caminos distintos usa una de estas tolerancias, en los scripts y en `tests/`. Nunca se usa una tolerancia absoluta fija para cantidades cuya magnitud varía.

| Comparación | Tolerancia | Dónde |
|---|---|---|
| Suma de $K$ probabilidades frente a 1 (previas $K = 2$, educación $K = K_E$, categoría conjunta $K = K_G$) | $\lvert \sum - 1 \rvert \le K \cdot \varepsilon_{\text{mach}}$ | `03`, `08`, `09`, tests |
| Suma de las cinco contribuciones frente a $D_i$ | $\lvert \sum_k c_{k,i} - D_i \rvert \le 16 \cdot \varepsilon_{\text{mach}} \cdot \max\left(\lvert \ell_1(x_i) \rvert, \lvert \ell_0(x_i) \rvert, 1\right)$, persona a persona | `03` (test), `08`, `09` |
| Identidades entre indicadores ($\text{BA} = (\text{TPR}+\text{TNR})/2$, $J = \text{TPR}+\text{TNR}-1$, $\text{TPR}+\text{FNR} = 1$, $\text{TNR}+\text{FPR} = 1$) | $4 \cdot \varepsilon_{\text{mach}}$ (los valores están en $[-1, 1]$) | `04`, `06`, tests |
| Función a mano frente a R base (`mean`, `sd`, `dnorm`, `quantile`) | $n \cdot \varepsilon_{\text{mach}} \cdot \max(1, \lvert \text{referencia} \rvert)$, con $n$ el número de términos sumados | tests de `00_utilidades` y `03` |
| Valores que deben ser deterministas (recalcular una réplica, `D` guardado frente a `D` recalculado) | `identical()`, sin tolerancia | `05`, `08` |

**Por qué $k = 16$ y escala $\max(\lvert\ell_1\rvert, \lvert\ell_0\rvert, 1)$ para las contribuciones.** El error no depende de $D$, que puede ser casi cero, sino del tamaño de los puntajes que se restan. Los cinco términos de $\ell_c$ son negativos: son logaritmos de probabilidades menores que 1 y de densidades con $\hat\sigma > 1/\sqrt{2\pi}$. Por eso cada término cumple $\lvert \text{término} \rvert \le \lvert \ell_c \rvert$.

Cada cálculo encadena unas 14 operaciones de punto flotante, cada una con error de a lo más $\varepsilon_{\text{mach}}/2$ relativo a $\max\lvert\ell_c\rvert$:

- 4 sumas por clase para formar $\ell_c$;
- la resta $\ell_1 - \ell_0$;
- 5 restas para las contribuciones;
- 4 sumas de las contribuciones.

Eso da una cota de unos $7\,\varepsilon_{\text{mach}} \max\lvert\ell_c\rvert$, más unos pocos ulps de `log()` en cada término. Con $k = 16$ queda un margen de algo más de 2 sobre esa cota.

En las 200 réplicas el máximo observado fue $41\,\varepsilon_{\text{mach}}$ absoluto con $\lvert\ell_c\rvert$ entre 12 y 20. Eso equivale a menos de $3{,}5\,\varepsilon_{\text{mach}}$ relativo, un margen de unas 4,6 veces frente a $k = 16$. La tolerancia fija de $128\,\varepsilon_{\text{mach}}$ que se usaba sería demasiado holgada con puntajes pequeños y demasiado estricta si los puntajes crecieran.

`prueba` no guarda $\ell_0$ ni $\ell_1$. Por eso, quien necesite esta tolerancia (`08`, `09`) los recalcula con `puntuar(modelo, datos)` de `03` usando el `modelo` guardado. Eso no vuelve a ajustar el modelo. Las filas de prueba se toman de la tabla analítica uniendo por `id_original`, y se verifica que el `D` recalculado sea `identical()` al guardado.

### Nivel 4: reglas comunes a 06–09

- Cada script hace `source()` de `00_utilidades.R`, `00_config.R` y de los módulos de nivel 2 que use (`03` para `log_densidad_normal()`, `04` para `indicadores()` y `resumir()`). No vuelve a ajustar modelos ni a particionar: solo lee `output/replicas/replica_XXX.rds` y `data/processed/tabla_analitica.rds`.
- Lectura de réplicas: `lapply(sprintf("replica_%03d.rds", seq_len(B)), ...)` sobre `RUTAS[["replicas"]]`; falla con `stop()` si falta alguno de los `B` archivos. Los scripts de nivel 4 no se llaman entre sí, así que cada uno repite esta lectura.
- Para cruzar con los predictores se une por `id_original` con la tabla analítica. Los índices de `particion[["indices"]]` son posiciones de fila de esa misma tabla.
- Tablas: `escribir_csv(df, file.path(RUTAS[["tablas"]], archivo))` de `00_utilidades.R`, nunca `write.csv()` directamente, para conservar la precisión completa (se redondea solo al presentar en el informe). Las tasas van como proporciones en $[0, 1]$ y Youden en su escala, de $-1$ a $1$. Un indicador no estimable queda como `NA`.
- Figuras: gráficos de R base (`plot`, `hist`, `boxplot`, `qqnorm`, `segments`, `abline`), con `png(..., width = 1600, height = 1000, res = 150)` en `RUTAS[["figuras"]]`. Cada figura indica en el título o subtítulo la réplica o el resumen, el subconjunto (validación o prueba) y la escala.
- Ninguna figura usa `jitter()` ni otra función que consuma el generador aleatorio. Si hace falta mostrar puntos superpuestos se usa transparencia con `rgb(..., alpha = )`.
- Al final, cada script verifica con `stopifnot()` que escribió todos los archivos de su contrato.

### 06_resumen.R (distribución de $\tau_b$ e indicadores de prueba)

Lee: los $B$ `.rds` (`b`, `semilla`, `umbral[["tau"]]`, `indicadores_prueba`). Escribe las dos tablas con `escribir_csv()`.

| Archivo | Contenido |
|---|---|
| `tablas/replicas_indicadores.csv` | $B$ filas. Columnas `b`, `semilla`, `tau`, `exactitud`, `TPR`, `TNR`, `PPV`, `F1`, `FPR`, `FNR`, `BA`, `J` |
| `tablas/resumen_replicas.csv` | 10 filas (`tau` y los 9 `INDICADORES`, en ese orden). Columnas `variable`, `escala` (`"original"` para `tau` y `J`, `"proporcion"` para el resto), `r`, `media`, `sd`, `mediana`, `p2.5`, `p97.5`, obtenidas con `resumir()` |
| `figuras/hist_tau.png` | Histograma de los $\tau_b$ con líneas verticales en media, mediana, p2.5 y p97.5, y leyenda |
| `figuras/paneles_indicadores.png` | Panel 2×4 de histogramas: `tau`, `exactitud`, `TPR`, `TNR`, `PPV`, `F1`, `BA`, `J`. Cada uno marca la mediana y el intervalo p2.5–p97.5, e indica `r` en el subtítulo |
| `figuras/boxplot_indicadores.png` | Un boxplot por indicador en escala de proporción (`exactitud`, `TPR`, `TNR`, `PPV`, `F1`, `FPR`, `FNR`, `BA`), con eje $[0, 1]$. `J` queda fuera porque su escala es distinta y ya aparece en los paneles |

Verificaciones: 200 filas con `b` = `1:B` y `semilla == semilla_replica(b)`; `resumen_replicas.csv` coincide con `resumir()` aplicado a cada columna de `replicas_indicadores.csv`; `p2.5 <= mediana <= p97.5`; `BA == (TPR + TNR)/2` y `J == TPR + TNR - 1` fila a fila, con la tolerancia de identidades entre indicadores ($4 \cdot \varepsilon_{\text{mach}}$).

### 07_grupos.R (errores por categoría conjunta)

Lee: los $B$ `.rds` (`grupos_prueba`, `matriz_prueba`, `prueba`).

Agrega la columna `b` a cada `grupos_prueba` y apila las $B$ réplicas con `rbind`, lo que da $10B$ filas.

| Archivo | Contenido |
|---|---|
| `tablas/grupos_replicas.csv` | $10B$ filas: `b` más las columnas de `matrices_por_grupo()` |
| `tablas/resumen_grupos.csv` | 30 filas (10 `g` × `TPR`, `FPR`, `FNR`). Columnas `g`, `indicador`, `denominador` (`"n_1"` para TPR y FNR, `"n_0"` para FPR), `den_min`, `den_mediana`, `den_max`, `r`, `mediana`, `p2.5`, `p97.5` (con `resumir()`) |
| `tablas/grupos_replica1.csv` | Réplica 1: `g`, `n`, `n_1`, `n_0`, `prevalencia` ($n_1/n$), `TN`, `FP`, `FN`, `TP`, `TPR`, `FPR`, `FNR` |
| `tablas/marginales_sexo_replica1.csv` | Réplica 1, 2 filas (`NIVELES_SEXO`). Se suman los conteos de las 5 categorías de cada sexo y después se calculan las tasas. Mismas columnas que `grupos_replica1.csv`, con `sexo` en lugar de `g` |
| `tablas/marginales_raza_replica1.csv` | Igual, 5 filas (`NIVELES_RAZA`), con `raza` en lugar de `g` |
| `figuras/tasas_grupos.png` | Tres paneles (`TPR`, `FPR`, `FNR`). En cada uno, una fila por `g` con un punto en la mediana y un segmento p2.5–p97.5 entre réplicas, eje $[0, 1]$, y la mediana de su denominador anotada junto a la etiqueta |

Verificaciones: en cada réplica, la suma de `TN`, `FP`, `FN`, `TP` de las 10 filas es igual a `matriz_prueba`, y la suma de `n` es igual a `nrow(prueba)`. Las marginales por sexo y por raza suman la matriz global de la réplica 1. Los grupos sin positivos tienen `TPR` y `FNR` `NA` y no cuentan en `r`.

### 08_diagnosticos.R (supuestos, verificaciones y trazabilidad)

Lee: tabla analítica y los $B$ `.rds`. La réplica 1 se usa para los gráficos; las verificaciones recorren todas.

| Archivo | Contenido |
|---|---|
| `figuras/qq_replica1.png` | Panel 2×2 con `qqnorm()` y `qqline()`: edad y horas × clase 0 y 1, del entrenamiento de la réplica 1. El título de cada panel indica la variable, la clase y $n$ |
| `figuras/edad_horas_replica1.png` | Dos paneles (clase 0 y 1), dispersión de edad frente a horas en el entrenamiento de la réplica 1, con transparencia. El subtítulo indica la correlación de Pearson calculada a mano |
| `tablas/educacion_g_replica1.csv` | Entrenamiento de la réplica 1 en formato largo: `clase`, `educacion`, `g`, `n` ($2 \times 8 \times 10 = 160$ filas, con ceros incluidos). Orden: `clase` (0, 1), dentro de ella `educacion` en el orden de `NIVELES_E`, y dentro de esta `g` en el orden de `NIVELES_G`; `g` varía más rápido |
| `tablas/verificaciones_replicas.csv` | $B$ filas. Columnas `b`; `err_previa` ($\lvert\sum_c \hat\pi_c - 1\rvert$); `err_p_g_0`, `err_p_g_1` ($\lvert\sum_g \hat p_{c,g} - 1\rvert$); `err_q_e_0`, `err_q_e_1`; `n_estrella_ok`; `destinos_disjuntos`; `todos_con_destino`; `puntajes_finitos` (todos los `D` de prueba); `D_recalculado_identico` (el `D` de `puntuar()` con el `modelo` guardado es `identical()` al de `prueba`); `max_err_contribuciones` (máximo absoluto de $\lvert\sum \text{contribuciones} - D\rvert$); `max_err_contribuciones_rel` (máximo de ese error dividido por $\max(\lvert\ell_1\rvert, \lvert\ell_0\rvert, 1)$ de cada persona); `contribuciones_ok` (`max_err_contribuciones_rel` $\le 16 \cdot \varepsilon_{\text{mach}}$); `matriz_suma_n` (la matriz de prueba suma `nrow(prueba)`); `grupos_suman_global` |
| `tablas/trazabilidad.csv` | Pares `indicador`, `valor`: `filas_tabla_analitica`, `perfiles_distintos`, `duplicados_excedentes` (con las 15 columnas originales y sin `id_original`; un perfil repetido 3 veces aporta 2) y, para la réplica 1, `n_prueba`, `prueba_coincide_entrenamiento`, `prueba_coincide_validacion`, `prueba_coincide_alguno`. Estos tres cuentan **personas de prueba**, no perfiles distintos: el número de personas de prueba cuyo perfil (15 columnas) aparece al menos una vez en entrenamiento, al menos una vez en validación, o en cualquiera de los dos. `prueba_coincide_alguno` puede ser menor que la suma de los otros dos. `NA` cuenta como un valor más al comparar perfiles |

Verificaciones: todas las columnas lógicas de `verificaciones_replicas.csv` son `TRUE`; los errores de suma de probabilidades cumplen la tolerancia $K \cdot \varepsilon_{\text{mach}}$ y las contribuciones la tolerancia relativa (sección "Tolerancias numéricas"). Las diferencias observadas se guardan tal cual, porque la rúbrica pide registrarlas, no solo aprobarlas.

### 09_replica1.R (evidencias de la réplica 1 para el informe)

Lee: tabla analítica y `replica_001.rds`.

| Archivo | Contenido |
|---|---|
| `tablas/tamanos_replica1.csv` | `particion[["tamanos"]]`: por clase `N`, `disp`, `val`, `pru`, `entrenamiento`, `sin_seleccionar`, más `n_estrella` |
| `tablas/parametros_replica1.csv` | Por clase: `clase`, `n`, `previa`, `mu_edad`, `sigma_edad`, `mu_horas`, `sigma_horas` |
| `tablas/densidad_ejemplo_replica1.csv` | Para la edad observada de la persona de `persona_replica1.csv` y cada clase: `clase`, `z`, `mu`, `sigma`, `log_f` (con `log_densidad_normal()`), `f` (`exp(log_f)`), `F` (`pnorm()`, solo para interpretar). Se verifica `log_f` contra `dnorm(log = TRUE)` |
| `tablas/probabilidades_g_replica1.csv` | Formato largo: `clase`, `g`, `conteo` ($n_{c,g}$), `n_c`, `p` ($\hat p_{c,g}$). 20 filas |
| `tablas/probabilidades_e_replica1.csv` | Igual para educación: `clase`, `educacion`, `conteo` ($m_{c,e}$), `n_c`, `q`. 16 filas |
| `tablas/persona_replica1.csv` | Primera persona de prueba ordenada por `id_original`: `id_original`, `age`, `hours_per_week`, `educacion`, `g`, `clase`, `c_previa`, `c_edad`, `c_horas`, `c_educacion`, `c_g`, `D`, `l0`, `l1` (recalculados con `puntuar()`), `tau`, `pred` |
| `tablas/candidatos_replica1.csv` | `umbral[["candidatos"]]` más las columnas `exactitud`, `PPV`, `F1`, `FPR` obtenidas con `indicadores()` sobre sus conteos; se agregan `J_max`, `eps` y `elegido` (lógica) |
| `figuras/curvas_validacion_replica1.png` | Panel izquierdo: `exactitud`, `TPR`, `TNR`, `PPV`, `F1` y `FPR` en validación frente a los cortes finitos, con una línea vertical en $\tau_1$ y leyenda. Panel derecho, aparte: los mismos indicadores en el corte $+\infty$ (puntos; `PPV` es `NA` allí y se indica) |

Verificaciones: las previas suman 1 y las probabilidades de `g` y de educación suman 1 por clase; en `persona_replica1.csv`, la suma de las cinco contribuciones es igual a `D` con la tolerancia relativa, `D == l1 - l0` y `pred == (D >= tau)`; `candidatos_replica1.csv` tiene un único `elegido` y su `tau` es igual a `umbral[["tau"]]`.

## 4. Decisiones tomadas

- 2026-10-22: media, desviación estándar (denominador $n_c - 1$), log-densidad normal y percentiles tipo 7 se implementan a mano. `mean`, `sd`, `dnorm` y `quantile(type = 7)` se usan solo como comprobación, con `stopifnot(abs(manual - base) < tolerancia)`.
- 2026-10-22: el épsilon de máquina se escribe `.Machine[["double.eps"]]`.
- 2026-10-22: `DESTINOS` pasa de `02_particion.R` a `00_config.R`, porque lo usan también `05` y los scripts de nivel 4.
- 2026-10-22: se agrega `tests/` con un script de verificación por módulo, fuera de la jerarquía y de `run_all.R`.
- 2026-10-22: `PROPORCIONES`, `COLUMNAS_REQUERIDAS`, `ETIQUETAS_INGRESO` y `EDUCACION_NUM_MIN` quedan documentados en la tabla de `00_config.R`. La semilla de la réplica se obtiene solo con `semilla_replica(b)`, sin alias.
- 2026-10-22: se crea `00_utilidades.R` en el nivel 0 con `media_manual()`, `sd_manual()` y `percentil_tipo7()`, porque `03` y `04` las necesitan y no pueden llamarse entre sí. `log_densidad_normal()` se queda en `03`.
- 2026-10-22: `matrices_por_grupo()` devuelve formato largo con columna `g` (factor) y sin nombres de fila, para que `05` la guarde tal cual y `07` apile las réplicas con `rbind` agregando `b`.
- 2026-10-22: contratos de 06–09 con nombres de archivo, columnas y figuras. Las evidencias que la rúbrica pide para la réplica 1 se reparten así: tamaños, parámetros, densidad, probabilidades, persona y curvas de validación en `09`; composición y marginales por grupo en `07`; Q–Q, dependencias, verificaciones y duplicados en `08`.
- 2026-10-22: `escribir_csv()` pasa de `06_resumen.R` a `00_utilidades.R`, porque la usan 06–09 y no pueden llamarse entre sí. Recibe la ruta completa para no depender de `RUTAS`. `00_utilidades.R` pasa a reunir utilidades compartidas, no solo estadísticos.
- 2026-10-22: tolerancias explícitas (sección "Tolerancias numéricas"). Las contribuciones usan $16 \cdot \varepsilon_{\text{mach}} \cdot \max(\lvert\ell_1\rvert, \lvert\ell_0\rvert, 1)$ en lugar de $128 \cdot \varepsilon_{\text{mach}}$ fijo. `08` y `09` recalculan $\ell_c$ con `puntuar()`. `prueba_coincide_*` cuenta personas de prueba. `educacion_g_replica1.csv` se ordena por clase, educación y g.
