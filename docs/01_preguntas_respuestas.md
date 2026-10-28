# Preguntas y respuestas

Documento 1 de 5. Responde las diez preguntas oficiales de la rúbrica (sección 10) y las preguntas de seguimiento más probables. Cada respuesta indica **dónde está la evidencia** en el proyecto, porque el criterio 5 premia responder «con precisión» y «localizar las evidencias que respaldan los cálculos consultados».

Las cifras salen de `docs/bitacora.md` (ejecución completa del 2026-10-22, R 4.6.1, Windows 11) y de los CSV de `output/tablas/` que esa ejecución generó. Se redondean al presentar; los CSV tienen 17 cifras significativas.

Convención para datos faltantes: `[FALTA DATO: …]` marca una cifra que no está en la documentación versionada y que hay que leer del CSV indicado antes de la defensa.

Documentos relacionados: `02_documentacion_breve.md`, `03_documentacion_tecnica.md`, `04_resultados.md`, `05_evaluacion_resultados.md`.

---

## Parte A. Las diez preguntas oficiales

### 1. ¿Qué significan $c_i = 0$ y $c_i = 1$, y qué personas integran la población analizada?

- $c_i = 1$: ingreso anual **superior** a USD 50.000 (etiqueta `>50K`). Es la clase positiva.
- $c_i = 0$: ingreso anual **menor o igual** a USD 50.000 (etiqueta `<=50K`).
- **Población:** personas del archivo `adult.data` (Adult/Census Income, UCI, censo de EE. UU. de 1994) con `education-num` ≥ 9, es decir, secundaria completa o más. Se admiten 8 niveles: HS-grad, Some-college, Assoc-voc, Assoc-acdm, Bachelors, Masters, Prof-school y Doctorate. `12th` queda fuera.
- **Cómo se llegó a la tabla** (en este orden, como pide la rúbrica):

  | Paso | Filas |
  |---|---|
  | Filas originales | 32 561 |
  | Excluidas por faltantes en columnas requeridas | 0 |
  | Excluidas por educación (`education-num` < 9) | 4 253 |
  | **Total final** | **28 308** |

- Clases en la tabla: 20 711 con $c = 0$ y 7 597 con $c = 1$ (prevalencia 26,84 %).
- Por qué no se excluye nadie por faltantes: en `adult.data` los `?` están solo en `workclass` (1 408), `occupation` (1 411) y `native_country` (499) dentro de la tabla final, columnas que el modelo no usa. Solo se excluye por faltantes en las 7 columnas requeridas (age, hours-per-week, education, sex, race, education-num, ingreso).
- **Evidencia:** `data/processed/registro_exclusiones.csv`, `R/01_datos.R`, constantes `COLUMNAS_REQUERIDAS` y `EDUCACION_NUM_MIN` en `R/00_config.R`.

### 2. ¿Cómo se determina $n_*$ y cómo se forma el entrenamiento equilibrado de una réplica?

1. Con la semilla $20261021 + b - 1$, dentro de **cada clase** se permutan las personas y se reparten: $N_c^{\text{disp}} = \lfloor 0{,}8 N_c \rfloor$ disponibles para entrenar, $N_c^{\text{val}} = \lfloor 0{,}1 N_c \rfloor$ para validación y el resto para prueba.
2. $n_* = \min(N_0^{\text{disp}}, N_1^{\text{disp}})$.
3. Se sortean sin reemplazo $n_*$ personas de cada clase entre sus disponibles. El entrenamiento tiene $2 n_*$ personas.

Con los datos del proyecto (idéntico en las 200 réplicas, porque los tamaños solo dependen de $N_c$):

| Clase | $N_c$ | Disponibles | Entrenamiento | Validación | Prueba | Sin seleccionar |
|---|---|---|---|---|---|---|
| 0 | 20 711 | 16 568 | 6 077 | 2 071 | 2 072 | 10 491 |
| 1 | 7 597 | 6 077 | 6 077 | 759 | 761 | 0 |

$n_* = \lfloor 0{,}8 \cdot 7\,597 \rfloor = 6\,077$. El entrenamiento tiene 12 154 personas.

- **Evidencia:** `output/tablas/tamanos_replica1.csv`, `logs/semillas.csv` (200 filas con semilla, $n_*$ y tamaños de los 4 destinos), función `particionar()` en `R/02_particion.R`.
- **Para mostrar en consola:** `particionar(tabla$clase, semilla_replica(1))`.

### 3. ¿Qué función cumplen validación, prueba y los disponibles sin seleccionar?

- **Entrenamiento:** estima los parámetros (previas, medias, desviaciones y probabilidades con Laplace). Nada más.
- **Validación** (2 830 personas en cada réplica): con los parámetros ya estimados, calcula $D_i$ y elige el umbral $\tau_b$ que maximiza Youden. No se balancea: conserva la prevalencia real (≈ 26,8 %).
- **Prueba** (2 833 personas): evalúa la regla ya fijada (parámetros + $\tau_b$). Como no participó en ninguna decisión, sus indicadores no son optimistas.
- **Sin seleccionar** (10 491 personas de clase 0): disponibles que no entraron al sorteo equilibrado. Quedan registradas con un destino explícito y fuera de todos los cálculos de esa réplica.
- Los cuatro destinos son disjuntos y su unión es la tabla completa (28 308). En la réplica siguiente se vuelve a sortear desde cero, así que una persona puede cambiar de destino.
- **Evidencia:** columna `destino` de `particion` en cada `output/replicas/replica_XXX.rds`; columnas `destinos_disjuntos` y `todos_con_destino` de `output/tablas/verificaciones_replicas.csv` (TRUE en las 200).

### 4. ¿Cómo se estiman las previas, medias y desviaciones a partir del entrenamiento?

- **Previa:** $\hat\pi_c = n_c / (n_0 + n_1) = 6\,077 / 12\,154 = 0{,}5$. Se calcula (no se fija a mano) y se incluye en el puntaje, aunque se cancele en $D$.
- **Media:** $\hat\mu_{c,j} = \frac{1}{n_c} \sum_{i \in T_c} z_{i,j}$.
- **Desviación estándar:** $\hat\sigma_{c,j} = \sqrt{\sum (z_{i,j} - \hat\mu_{c,j})^2 / (n_c - 1)}$, con denominador $n_c - 1$.
- Todo con funciones propias (`media_manual`, `sd_manual` en `R/00_utilidades.R`); `mean` y `sd` solo dentro de `stopifnot()` como comprobación.

Réplica 1 (entrenamiento, $n = 6\,077$ por clase):

| Clase | Previa | $\hat\mu$ edad | $\hat\sigma$ edad | $\hat\mu$ horas | $\hat\sigma$ horas |
|---|---|---|---|---|---|
| 0 | 0,5 | 36,88 | 13,35 | 39,37 | 12,10 |
| 1 | 0,5 | 44,14 | 10,50 | 45,41 | 11,00 |

- **Evidencia:** `output/tablas/parametros_replica1.csv`, `ajustar_nb()` en `R/03_modelo.R`.

### 5. ¿Qué representa la densidad de una edad y qué expresa su probabilidad acumulada?

- $f_{c,\text{edad}}(z)$ es la **densidad normal** estimada para la clase $c$ evaluada en la edad $z$. Tiene unidades «por año» y **no es una probabilidad**: es el valor que entra al puntaje (como $\log f$).
- $F_{c,\text{edad}}(z)$ es la **probabilidad acumulada**: proporción de la distribución modelada con edad ≤ $z$. Se usa solo para interpretar.
- Ejemplo de la rúbrica: $\mu = 44$, $\sigma = 10$ dan $f(54) \approx 0{,}0242$ por año y $F(54) \approx 0{,}8413$.
- Ejemplo del proyecto (réplica 1, edad 37 de la persona del ejemplo de la pregunta 7):

  | Clase | $\hat\mu$ | $\hat\sigma$ | $\log f(37)$ | $f(37)$ | $F(37)$ |
  |---|---|---|---|---|---|
  | 0 | 36,88 | 13,35 | ≈ −3,5105 | ≈ 0,0299 | ≈ 0,504 |
  | 1 | 44,14 | 10,50 | ≈ −3,5015 | ≈ 0,0302 | ≈ 0,248 |

  <!-- FALTA: los valores de la tabla se calcularon con los parámetros redondeados a 2 decimales. Copiar los exactos de output/tablas/densidad_ejemplo_replica1.csv. -->
  [FALTA DATO: valores exactos de `log_f`, `f` y `F` en `output/tablas/densidad_ejemplo_replica1.csv`; los de la tabla son aproximados con parámetros redondeados.]

- Lectura: a los 37 años la densidad es casi igual en ambas clases, por eso la contribución de la edad es casi cero (≈ +0,009). En cambio, $F_1(37) \approx 0{,}25$ dice que solo un cuarto de la distribución modelada de la clase 1 tiene 37 años o menos.
- **Evidencia:** `output/tablas/densidad_ejemplo_replica1.csv`, `log_densidad_normal()` en `R/03_modelo.R` (contrastada con `dnorm(log = TRUE)` con tolerancia $3\varepsilon \max(1, |\text{ref}|)$).

### 6. ¿Cómo se obtienen $n_{c,g}$, $m_{c,e}$ y sus probabilidades con Laplace?

- $n_{c,g}$: personas del entrenamiento con clase $c$ y categoría conjunta $g$ (sexo/raza, 10 niveles).
- $m_{c,e}$: personas del entrenamiento con clase $c$ y nivel educativo $e$ (8 niveles).
- Laplace con $\alpha = 1$:

$$
\hat p_{c,g} = \frac{n_{c,g} + 1}{n_c + 10}, \qquad \hat q_{c,e} = \frac{m_{c,e} + 1}{n_c + 8}
$$

- Con $n_c = 6\,077$, los denominadores son 6 087 (categoría conjunta) y 6 085 (educación).
- Los niveles son factores fijos (`NIVELES_G`, `NIVELES_E` en `R/00_config.R`), así que un nivel con 0 casos sigue existiendo y recibe $1/(n_c + K)$. Sin Laplace, $\log 0 = -\infty$ anularía a los otros predictores.
- Por qué una sola variable sexo/raza: captura la combinación (por ejemplo, Female/Black) sin suponer independencia entre sexo y raza dada la clase.
- Ejemplo numérico de la réplica 1: <!-- FALTA: elegir una fila de probabilidades_g_replica1.csv (p. ej. clase 1, Female/White) y escribir conteo, n_c y p para recalcularlo en vivo. -->
  [FALTA DATO: conteo $n_{1,\text{Female/White}}$ y $\hat p_{1,\text{Female/White}}$ de `output/tablas/probabilidades_g_replica1.csv`, para mostrar el cálculo $(conteo + 1)/6\,087$.]
- **Evidencia:** `output/tablas/probabilidades_g_replica1.csv` (20 filas) y `probabilidades_e_replica1.csv` (16 filas), con conteo, $n_c$ y probabilidad; `ajustar_nb()` en `R/03_modelo.R`.

### 7. ¿Cómo se reconstruye una predicción desde sus cinco contribuciones?

$$
D_i = \ell_1(x_i) - \ell_0(x_i) = \underbrace{\log\tfrac{\hat\pi_1}{\hat\pi_0}}_{\text{previa}} + \underbrace{\log\tfrac{f_{1,\text{edad}}}{f_{0,\text{edad}}}}_{\text{edad}} + \underbrace{\log\tfrac{f_{1,\text{horas}}}{f_{0,\text{horas}}}}_{\text{horas}} + \underbrace{\log\tfrac{\hat q_{1,e}}{\hat q_{0,e}}}_{\text{educación}} + \underbrace{\log\tfrac{\hat p_{1,g}}{\hat p_{0,g}}}_{\text{categoría conjunta}}
$$

y se predice $\hat c_i = 1$ si $D_i \ge \tau_b$.

Persona de la rúbrica: la primera persona de prueba de la réplica 1 ordenada por `id_original`. Es el **id 11**: 37 años, 80 h/semana, Some-college, Male/Black, clase observada 1.

| Contribución | Valor |
|---|---|
| Previa | 0 (exacto: previas 0,5 y 0,5) |
| Edad | ≈ +0,009 |
| Horas | +0,787 |
| Educación | −0,472 |
| Categoría conjunta | −0,352 |
| **$D_{11}^{(1)}$** | **−0,0277** |
| $\tau_1$ | 0,0991 |
| Predicción | 0 (**falso negativo**) |

<!-- FALTA: c_edad exacto, l0 y l1 de la persona. El ≈ +0,009 sale de restar los valores redondeados y coincide con log f1(37) − log f0(37) ≈ 0,0090. -->
[FALTA DATO: `c_edad`, `l0` y `l1` exactos de `output/tablas/persona_replica1.csv`.]

- Lectura: trabajar 80 horas empuja hacia la clase 1, pero el nivel Some-college y la categoría Male/Black pesan más hacia la clase 0. Queda bajo el umbral por 0,127.
- Verificaciones: la suma de las cinco contribuciones reproduce $D$ con error relativo de 0,11·ε (límite 16·ε); `D == l1 - l0`; `pred == (D >= tau)`.
- **Evidencia:** `output/tablas/persona_replica1.csv`, `puntuar()` en `R/03_modelo.R`, `R/09_replica1.R`.

### 8. ¿Cómo se elige $\tau_b$ con validación y se aplica después a prueba?

1. Se calcula $D$ en validación con los parámetros del entrenamiento $b$.
2. Candidatos: con $u_1 < \dots < u_L$ los valores distintos de $D$, se evalúan $u_1$, los puntos medios $u_h/2 + u_{h+1}/2$ y $+\infty$. Entre dos valores consecutivos la matriz no cambia, así que basta un punto por intervalo. $u_1$ es «todos positivos» y $+\infty$ «todos negativos». Se escribe $u_h/2 + u_{h+1}/2$ (y no $(u_h + u_{h+1})/2$) para evitar desbordamiento; si el redondeo deja el corte fuera de $(u_h, u_{h+1}]$ se usa $u_{h+1}$.
3. Para cada candidato, $J = \text{TPR} + \text{TNR} - 1$. Maximizar $J$ equivale a maximizar BA, porque $\text{BA} = (J + 1)/2$.
4. Empate: $|J(\tau) - J_{\max}| \le \varepsilon_{\text{mach}}$, con $\varepsilon_{\text{mach}} = 2^{-52} \approx 2{,}22 \times 10^{-16}$ leído del entorno (`.Machine[["double.eps"]]`). Entre empatados, menor $|\tau|$ y luego menor $\tau$.
5. Ese $\tau_b$ y los mismos parámetros se aplican a prueba: $\hat c_i = 1$ si $D_i \ge \tau_b$.

Réplica 1:

- 1 856 candidatos (1 855 valores distintos de $D$ más $+\infty$); un solo candidato en el máximo.
- **$\tau_1 = 0{,}0991012$**, $J_{\max} = 0{,}5056$ en validación.
- En $+\infty$ (todos negativos): exactitud 0,732, TNR 1, TPR = F1 = FPR = 0, PPV no estimable. Por eso no se usa la exactitud para elegir: clasificar a todos como 0 ya da 73 %.
- En prueba ($n = 2\,833$): TN 1 552, FP 520, FN 186, TP 575; exactitud 0,7508, TPR 0,7556, TNR 0,7490, PPV 0,5251, F1 0,6196, BA 0,7523, J 0,5046.
- **Evidencia:** `output/tablas/candidatos_replica1.csv` (columnas `J`, `J_max`, `eps`, `empatado`, `elegido`), `output/figuras/curvas_validacion_replica1.png`, `elegir_umbral()` en `R/04_umbral_metricas.R`.

### 9. ¿Qué describen la distribución de umbrales, las de indicadores y sus percentiles?

- Cada réplica da un $\tau_b$ y nueve indicadores de prueba. Las 200 réplicas forman una distribución que muestra **cuánto cambian el umbral y el desempeño cuando cambia el sorteo**.
- Se informa $r$ (valores estimables), media (nivel promedio), desviación estándar (dispersión), mediana (centro) y percentiles 2,5 y 97,5 (95 % central).
- **Los percentiles no son un intervalo de confianza.** Son un rango descriptivo de la variación frente al submuestreo, sobre esta misma tabla, y las réplicas comparten personas. No dicen nada sobre la población de EE. UU. ni sobre otros datos.
- Percentil tipo 7 a mano: con los $r$ valores ordenados, posición $h = 1 + (r - 1)p$; si $h$ cae entre dos valores, se interpola linealmente. Con $r = 200$ y $p = 0{,}025$, $h = 5{,}975$.
- Resultados ($B = 200$, $r = 200$ en todas las variables):
  - $\tau_b$: media 0,0482, sd 0,1314, mediana 0,0681, p2,5 −0,2156, p97,5 0,2650; mínimo −0,3231, máximo 0,3195.
  - Medianas en prueba: exactitud 0,7363, TPR 0,7582, TNR 0,7283, PPV 0,5063, F1 0,6062, BA 0,7418, J 0,4837.
  - [FALTA DATO: media, sd, p2,5 y p97,5 de los nueve indicadores, en `output/tablas/resumen_replicas.csv`.] <!-- FALTA: completar desde resumen_replicas.csv -->
- Lectura: el umbral varía bastante (de −0,32 a 0,32), pero los indicadores se mantienen en un rango acotado. Lo que cambia es el reparto entre TPR y TNR.
- **Evidencia:** `output/tablas/resumen_replicas.csv`, `output/tablas/replicas_indicadores.csv`, `output/figuras/hist_tau.png`, `paneles_indicadores.png`, `boxplot_indicadores.png`; `resumir()` en `R/04_umbral_metricas.R`, `percentil_tipo7()` en `R/00_utilidades.R`.

### 10. ¿Qué explican los denominadores por grupo y las verificaciones de sumas próximas a uno?

**Denominadores por grupo.**

- TPR y FNR usan los positivos reales del grupo ($n_{g,1}$); FPR usa los negativos reales ($n_{g,0}$). Con pocos casos, un solo acierto mueve mucho la tasa: Female/Black tiene $n_1 \approx 8$ en prueba, así que un acierto cambia la TPR en unos 12 puntos.
- Si un grupo no tiene positivos en una prueba, TPR y FNR quedan `NA` y no cuentan en $r$. Hubo 201 combinaciones grupo-réplica sin positivos: Female/Other 107, Female/Amer-Indian-Eskimo 44, Male/Other 30, Male/Amer-Indian-Eskimo 18, Female/Asian-Pac-Islander 2. Por eso Female/Other tiene $r = 93$ en TPR.
- No confundir $\hat p_{c,g}$ (proporción del grupo **dentro de una clase del entrenamiento**, denominador $n_c + 10$) con la prevalencia de prueba del grupo (ingresos altos **dentro del grupo**, denominador $n_g$). Responden preguntas distintas.
- Las 10 matrices por grupo suman la matriz global de la misma réplica (verificado en las 200).

**Sumas próximas a uno.**

- Previas, las 10 $\hat p_{c,g}$ y las 8 $\hat q_{c,e}$ deben sumar 1 por clase. En punto flotante la suma puede diferir en el último bit, por eso se registra el error absoluto $|\sum - 1|$ y se compara con $K \cdot \varepsilon_{\text{mach}}$.
- Error máximo observado en las 200 réplicas: 1,1·10⁻¹⁶ (media unidad de ε).
- Esas comprobaciones localizan errores de denominador (por ejemplo, olvidar $+\alpha K$) o niveles perdidos.
- **Evidencia:** `output/tablas/resumen_grupos.csv` (denominador mínimo, mediano y máximo, $r$), `grupos_replicas.csv`, `grupos_replica1.csv`, `output/figuras/tasas_grupos.png`; `output/tablas/verificaciones_replicas.csv` (columnas `err_previa`, `err_p_g_0`, `err_p_g_1`, `err_q_e_0`, `err_q_e_1`, `grupos_suman_global`).

---

## Parte B. Preguntas de seguimiento probables

### Decisiones de diseño

- **¿Por qué balancear solo el entrenamiento?** Para que el modelo no favorezca a la clase mayoritaria. Validación y prueba conservan la prevalencia real para evaluar la regla en la composición de la tabla.
- **¿Qué cambia con previas reales en vez de 0,5?** $D$ se desplazaría en la constante $\log(0{,}268/0{,}732) \approx -1{,}0$. No cambia el orden de las personas, así que el $\tau_b$ elegido por Youden absorbe el desplazamiento.
- **¿Por qué Youden y no exactitud?** Con 73 % de clase 0, «todos negativos» ya da exactitud 0,732. Youden pesa igual TPR y TNR.
- **¿Por qué un conjunto de validación separado?** Si el umbral se eligiera en prueba, las métricas de prueba serían optimistas.
- **¿Por qué ε de máquina y menor $|\tau|$?** Dos $J$ que deberían ser iguales pueden diferir en el último bit. El menor $|\tau|$ es lo más cercano a la regla de Bayes ($D \ge 0$); lo fija la rúbrica.
- **¿Por qué logaritmos?** El producto de densidades y probabilidades pequeñas puede dar underflow. La suma de logaritmos es estable y conserva el orden.
- **¿Por qué $n - 1$?** Estimador insesgado de la varianza. Con $n_c = 6\,077$ la diferencia con $n$ es despreciable (factor $\sqrt{6077/6076}$).
- **¿Por qué `sample.int` y no `sample`?** `sample(x, n)` con `length(x) == 1` sortea de `1:x`. Se usa `x[sample.int(length(x), n)]`.

### Supuestos y diagnósticos

- **Normalidad:** la edad es aproximada (en la clase 0 hay piso en 17–20 años y cola derecha larga). Las horas están lejos de la normal: valores discretos, gran masa en 40, topes en 1 y 99. Evidencia: `output/figuras/qq_replica1.png`.
- **Independencia condicional:** Pearson edad–horas = 0,024 (clase 0) y −0,122 (clase 1), dependencia lineal débil. Educación y grupo pueden no ser independientes: `output/tablas/educacion_g_replica1.csv` tiene 32 de 160 celdas en cero, concentradas en grupos pequeños con educación alta. Evidencia: `output/figuras/edad_horas_replica1.png`.
- **Alternativas:** discretizar las horas, densidad kernel o transformar variables. La rúbrica fija la normal; el diagnóstico documenta el costo.

### Interpretación

- **¿Por qué el PPV es bajo (≈ 0,51–0,53)?** Con 27 % de positivos, un FPR de 0,25 sobre 2 072 negativos produce 520 falsos positivos frente a 575 verdaderos positivos (réplica 1).
- **¿Por qué los hombres tienen más TPR y más FPR?** Marginal réplica 1: hombres TPR 0,830 y FPR 0,385; mujeres TPR 0,327 y FPR 0,063. $\hat p_{c,g}$ actúa como factor de verosimilitud: un grupo con alta $P(G = g \mid C = 1)$ relativa a $P(G = g \mid C = 0)$ empuja $D$ hacia la clase 1 para todas sus personas.
- **¿Prueba esto discriminación?** No. Describe el comportamiento del clasificador en estos datos; no identifica causas.

### Preguntas hipotéticas

- **$\alpha$ distinto de 1:** mayor $\alpha$ acerca las probabilidades a la uniforme; menor, a las frecuencias observadas.
- **Sin balancear:** la previa no se cancela y los parámetros de la clase 0 se estiman con más datos; Youden compensaría parte en el umbral.
- **$\tau = 0$ fijo:** es la regla de Bayes con previas 0,5. [FALTA DATO: indicadores con $\tau = 0$ para comparar; no se calcularon en el proyecto. En validación de la réplica 1 se sabe que con corte 0 quedan bien clasificados 592 de 759 positivos y 1 487 de 2 071 negativos.] <!-- FALTA: no existe tabla con tau = 0 en prueba -->
- **$\hat\sigma = 0$ o menos de 2 personas en una clase:** `ajustar_nb()` se detiene con `stop()`, como pide la rúbrica.
- **Validación sin ambas clases o $L = 1$:** `particionar()` se detiene si falta una clase; `candidatos_umbral()` usa $\{u_1, +\infty\}$ si $L = 1$.
- **Usar `adult.test`:** la rúbrica pide solo `adult.data`; cambiaría la población.
- **Otra semilla u otro $B$:** las cifras puntuales cambian, pero las distribuciones deberían parecerse. Es justamente lo que estudia el submuestreo.

### Datos y alcance

- **Sin ponderación:** no se usa `fnlwgt`, así que las tasas son de la muestra, no de la población de EE. UU.
- **Duplicados:** 28 308 filas, 28 289 perfiles distintos, 19 duplicados excedentes. En la réplica 1, 4 personas de prueba (0,14 % de 2 833) tienen un perfil idéntico a alguien de entrenamiento (3) o validación (1). Evidencia: `output/tablas/trazabilidad.csv`.
- **Antecedentes (rúbrica 9.1):** [FALTA DATO: declarar si algún análisis previo del archivo orientó decisiones del equipo.] <!-- FALTA: decisión del equipo -->

---

## Parte C. Mapa rápido «muéstramelo»

| Si preguntan por… | Abrir |
|---|---|
| Registro de exclusiones | `data/processed/registro_exclusiones.csv` |
| $n_*$ y tamaños | `output/tablas/tamanos_replica1.csv`, `logs/semillas.csv` |
| Parámetros réplica 1 | `output/tablas/parametros_replica1.csv` |
| Densidad de una edad | `output/tablas/densidad_ejemplo_replica1.csv` |
| Laplace | `output/tablas/probabilidades_g_replica1.csv`, `probabilidades_e_replica1.csv` |
| Persona descompuesta | `output/tablas/persona_replica1.csv` |
| Elección de $\tau_1$ | `output/tablas/candidatos_replica1.csv`, `output/figuras/curvas_validacion_replica1.png` |
| Distribuciones | `output/tablas/resumen_replicas.csv`, `output/figuras/paneles_indicadores.png` |
| Grupos | `output/tablas/resumen_grupos.csv`, `grupos_replica1.csv`, `marginales_*_replica1.csv`, `output/figuras/tasas_grupos.png` |
| Q–Q y dependencias | `output/figuras/qq_replica1.png`, `edad_horas_replica1.png`, `output/tablas/educacion_g_replica1.csv` |
| Verificaciones | `output/tablas/verificaciones_replicas.csv` |
| Duplicados | `output/tablas/trazabilidad.csv` |
| Semillas y versiones | `logs/semillas.csv`, `logs/sesion.txt` |
