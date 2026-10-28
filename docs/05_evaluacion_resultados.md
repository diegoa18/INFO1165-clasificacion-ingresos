# Evaluación de resultados

Documento 5 de 5. Interpreta las cifras de `04_resultados.md`: qué dicen, qué no dicen y qué tan sólidas son. Cierra con una autoevaluación frente a la rúbrica y la lista de datos pendientes.

## 1. Desempeño global

**Nivel.** En la mediana de 200 réplicas, el clasificador acierta en el 73,6 % de las personas de prueba, detecta el 75,8 % de los ingresos altos (TPR) y clasifica bien el 72,8 % de los ingresos bajos (TNR). La exactitud balanceada es 0,742 y $J = 0{,}484$.

**Comparación de referencia.** Clasificar a todos como ingreso bajo da exactitud 0,732 en validación (corte $+\infty$) y $J = 0$. La exactitud del modelo (0,736) apenas supera esa referencia, pero el modelo sí discrimina: pasa de detectar 0 % a 76 % de los ingresos altos. Por eso la exactitud sola es engañosa con clases desbalanceadas, y por eso el umbral se elige con Youden.

**Precisión positiva baja.** La mediana del PPV es 0,506: de cada dos personas que el modelo marca como ingreso alto, una lo es. No es un error de cálculo, es efecto de la prevalencia. En la réplica 1 hay 2 072 negativos y 761 positivos en prueba; un FPR de 0,251 genera 520 falsos positivos, casi tantos como los 575 verdaderos positivos.

**Validación frente a prueba.** En la réplica 1, $J_{\max} = 0{,}5056$ en validación y $J = 0{,}5046$ en prueba. La diferencia es mínima, lo que indica que elegir el umbral en un conjunto separado no dejó un sesgo optimista apreciable en esa réplica.

## 2. Estabilidad del umbral y de los indicadores

- $\tau_b$ tiene mediana 0,068 y su 95 % central va de −0,216 a 0,265 (sd 0,131). El rango completo es −0,32 a 0,32. Ningún par de réplicas eligió el mismo umbral (200 valores distintos).
- La media (0,048) queda por debajo de la mediana (0,068): la distribución tiene más peso hacia valores negativos.
- La previa no influye: con entrenamiento equilibrado, $\log(\hat\pi_1/\hat\pi_0) = 0$ en todas las réplicas, así que la variación de $\tau_b$ viene solo del sorteo de entrenamiento y validación.
- Un umbral que cambia bastante no implica un desempeño que cambie igual. Al subir $\tau$ se gana TNR y se pierde TPR, así que BA y $J$ se mueven menos que cada tasa por separado. Con 759 positivos en validación, cada positivo vale 0,13 puntos porcentuales de TPR, así que diferencias pequeñas entre muestras de validación pueden mover el corte elegido.
  <!-- FALTA: con p2.5 y p97.5 de TPR, TNR y BA se puede cuantificar esta afirmación. -->
  [FALTA DATO: p2,5 y p97,5 de TPR, TNR y BA para cuantificar cuánto más varían las tasas por separado que BA.]

**Cómo leer los percentiles.** El intervalo p2,5–p97,5 es un **rango descriptivo de la variación frente al submuestreo sobre esta misma tabla**. No es un intervalo de confianza: las réplicas comparten personas (cada entrenamiento usa el 80 % de los positivos de la tabla), así que no son muestras independientes de una población, y el rango no mide la incertidumbre de generalizar a otras personas.

## 3. Errores por categoría conjunta

**Patrón principal: sexo.** En la réplica 1, el modelo detecta al 83,0 % de los hombres con ingreso alto, pero solo al 32,7 % de las mujeres con ingreso alto. A cambio, marca como ingreso alto al 38,5 % de los hombres con ingreso bajo y solo al 6,3 % de las mujeres. Es decir, a los hombres se les asigna «ingreso alto» con mucha más facilidad, tanto cuando acierta como cuando se equivoca.

**Por qué ocurre.** El término $\log(\hat p_{1,g}/\hat p_{0,g})$ suma o resta la misma cantidad a todas las personas de un grupo. Si una categoría es mucho más frecuente entre los ingresos altos del entrenamiento que entre los bajos, todas sus personas parten con $D$ más alto. Es lo que muestra la persona del ejemplo: Male/Black resta 0,352, lo que basta para dejar a un ingreso alto bajo el umbral. El modelo aplica un único umbral global; las diferencias por grupo vienen de los puntajes, no de la regla.

<!-- FALTA: para respaldar este mecanismo con cifras, citar p_1,g y p_0,g de Female/White y Male/White desde probabilidades_g_replica1.csv. -->
[FALTA DATO: $\hat p_{1,g}$ y $\hat p_{0,g}$ de Female/White y Male/White en la réplica 1, para mostrar con cifras el signo de la contribución de cada sexo.]

**Distinguir dos cantidades.** $\hat p_{c,g}$ responde «entre las personas de clase $c$ del entrenamiento, ¿qué proporción pertenece a $g$?» (denominador $n_c + 10$). La prevalencia de prueba responde «dentro del grupo $g$, ¿qué proporción tiene ingreso alto?» (denominador $n_g$). La rúbrica las pide separadas porque es fácil confundirlas.

**Grupos grandes frente a pequeños.**

- Con denominadores grandes (Male/White, $n_1 \approx 590$, $n_0 \approx 1\,078$), las medianas son estables y la comparación es informativa.
- Con denominadores pequeños, las tasas son muy inestables. Female/Black tiene $n_1 \approx 8$: un acierto mueve la TPR unos 12 puntos. Male/Asian-Pac-Islander tiene la TPR mediana más alta (0,893), pero con solo unos 23 positivos.
- Female/Other no tiene positivos en prueba en 107 de 200 réplicas; su TPR solo es estimable en 93 y su mediana de $n_1$ es 0. Sus intervalos cubren casi todo $[0, 1]$, así que no permiten conclusiones.
- Conclusión: la disparidad por sexo es robusta (aparece en los grupos grandes); las diferencias entre grupos raciales pequeños no se pueden afirmar con estos datos.

**Lo que no dice este análisis.** Describe cómo se reparten los errores de este clasificador en estos datos. No prueba discriminación, no identifica causas y no evalúa equidad con un criterio formal.

## 4. Supuestos del modelo

| Supuesto | Evidencia | Evaluación |
|---|---|---|
| Edad normal dentro de cada clase | Q–Q réplica 1 | Aproximado. Asimetría a la derecha en clase 0 (piso en 17–20 años); buen centro en clase 1 |
| Horas normales dentro de cada clase | Q–Q réplica 1 | Débil. Valores discretos, masa en 40, topes en 1 y 99 |
| Independencia edad–horas dada la clase | Pearson 0,024 y −0,122 | Razonable en lo lineal; la correlación no descarta dependencias no lineales |
| Independencia educación–categoría conjunta dada la clase | `educacion_g_replica1.csv`, 32 de 160 celdas en cero | Dudosa. Los ceros se concentran en grupos pequeños con educación alta; el modelo puede contar dos veces información que comparten |

**Consecuencia.** Con las horas lejos de la normal, la contribución de las horas puede ser extrema para valores raros (por ejemplo, 80 h aporta +0,787 en la persona del ejemplo). Las alternativas (discretizar, kernel, transformar) quedan fuera porque la rúbrica fija la normal; el diagnóstico deja el costo documentado.

## 5. Solidez numérica y reproducibilidad

- Todas las verificaciones pasan en las 200 réplicas, con errores del orden de ε: sumas de probabilidades ≤ 1,1·10⁻¹⁶; contribuciones ≤ 2,10·ε relativo, frente a un límite de 16·ε.
- La réplica 1, 100 y 200 recalculadas desde cero coinciden bit a bit (`identical()`) con sus archivos guardados.
- Una segunda ejecución completa desde cero produjo resultados idénticos.
- Riesgo pendiente: la reproducibilidad entre versiones de R o sistemas operativos no se probó. La ejecución de referencia es R 4.6.1 en Windows 11; el generador está fijado de forma explícita, lo que reduce ese riesgo.

## 6. Alcance de las conclusiones

- **Población:** solo personas con secundaria completa o más (`education-num` ≥ 9). No vale para quienes tienen menos educación, que se excluyeron.
- **Origen histórico:** censo de EE. UU. de 1994. USD 50.000 de 1994 no equivalen a USD 50.000 actuales, y la estructura del mercado laboral cambió.
- **Categorías:** sexo binario y cinco grupos raciales tal como los registró el censo. «Other» y «Amer-Indian-Eskimo» son grupos pequeños y heterogéneos.
- **Balanceo:** el entrenamiento equilibrado cambia los parámetros respecto de la población; Youden compensa en parte con el umbral.
- **Sin ponderación:** no se usa `fnlwgt`, así que las tasas describen la muestra, no la población de EE. UU.
- **Duplicados:** 19 duplicados excedentes; en la réplica 1, 4 personas de prueba (0,14 %) comparten perfil con alguien de entrenamiento o validación. El efecto en los indicadores es despreciable.
- **Antecedentes:** [FALTA DATO: declarar si algún análisis previo del archivo orientó decisiones (rúbrica 9.1).] <!-- FALTA: declaración del equipo -->

## 7. Autoevaluación frente a la rúbrica

| Criterio | Peso | Evidencia disponible | Riesgo |
|---|---|---|---|
| 1. Planteamiento | 5 % | Población, clases, predictores y alcance definidos (doc. 02, sección 6 de este documento) | Bajo |
| 2. Cálculos y metodología | 25 % | Todas las etapas implementadas a mano, un $\tau_b$ por réplica con validación y ε de máquina, verificaciones completas | Bajo |
| 3. Análisis de resultados | 25 % | Interpretación de nivel, variación, denominadores y diagnósticos (este documento) | Medio: faltan transcribir los percentiles de los indicadores y las tablas de grupos (sección 8) |
| 4. Código reproducible | 10 % | 200 réplicas reproducibles, semillas y versiones registradas, tests | Medio: `.gitignore` excluye `data/`, `output/` y `logs/`; hay que incluirlos en la entrega |
| 5. Respuestas a preguntas | 25 % | Las 10 preguntas respondidas con su evidencia (doc. 01) | Depende del ensayo; tener abiertos los CSV y figuras |
| 6. Expresión oral | 5 % | Figuras con réplica, subconjunto y escala en el título | Depende del ensayo |
| 7. Manejo del tiempo | 5 % | Exposición de 10 a 15 minutos | [FALTA DATO: duración del ensayo cronometrado] <!-- FALTA --> |

**Requisitos de entrega (rúbrica, sección 10).**

| Requisito | Estado |
|---|---|
| Archivo fuente de datos conservado y diccionario | En `data/raw/` local; excluido del repositorio por `.gitignore` |
| Tabla analítica con identificadores | En `data/processed/` local; excluida del repositorio |
| Proyecto ejecutable | `run_all.R` |
| Registro de semillas y versiones | `logs/semillas.csv`, `logs/sesion.txt`; excluidos del repositorio |
| Índices, parámetros, candidatos, umbral y resultados por réplica | `output/replicas/replica_XXX.rds`; excluidos del repositorio |
| Informe con cuadros y figuras identificados | [FALTA DATO: formato y ubicación del informe final; las figuras no están en el repositorio y no se pueden enlazar desde estos documentos.] <!-- FALTA --> |
| Respuestas a las 10 preguntas | `docs/01_preguntas_respuestas.md` |

## 8. Datos pendientes en esta documentación

Todos están marcados en los documentos con `[FALTA DATO: …]` y un comentario `<!-- FALTA: … -->`. Salvo los que son decisiones del equipo, se completan copiando de los CSV que genera `run_all.R`.

| # | Dato | Dónde obtenerlo | Documentos |
|---|---|---|---|
| 1 | Nombres de los tres integrantes | Equipo | 02 |
| 2 | Media, sd, p2,5 y p97,5 de los nueve indicadores | `output/tablas/resumen_replicas.csv` | 01, 04, 05 |
| 3 | Valores exactos de $\log f$, $f$ y $F$ para la edad 37 | `output/tablas/densidad_ejemplo_replica1.csv` | 01, 04 |
| 4 | Conteos y probabilidades con Laplace de la réplica 1 (36 filas) | `probabilidades_g_replica1.csv`, `probabilidades_e_replica1.csv` | 01, 04, 05 |
| 5 | `c_edad`, `l0` y `l1` exactos de la persona id 11 | `output/tablas/persona_replica1.csv` | 01, 04 |
| 6 | Indicadores de validación en $\tau_1$ | `output/tablas/candidatos_replica1.csv`, fila `elegido` | 04 |
| 7 | Tablas completas por grupo (30 filas del resumen; réplica 1 por grupo y por raza; $n$ y matriz por sexo) | `resumen_grupos.csv`, `grupos_replica1.csv`, `marginales_*_replica1.csv` | 04, 05 |
| 8 | Tamaño de las 10 categorías conjuntas en la tabla analítica | `table(tabla$g)` sobre `tabla_analitica.rds` | 04 |
| 9 | Indicadores con $\tau = 0$ fijo, si se quiere comparar | No se calcula en el proyecto | 01 |
| 10 | Declaración de antecedentes (rúbrica 9.1) | Equipo | 01, 05 |
| 11 | Forma de entrega de `data/`, `output/` y `logs/` | Equipo | 03, 05 |
| 12 | Formato del informe final y figuras incrustadas | Equipo | 05 |
| 13 | Duración del ensayo de la exposición | Equipo | 05 |
