# Documentación breve

Documento 2 de 5. Resumen del proyecto en una lectura de cinco minutos. El detalle está en `03_documentacion_tecnica.md` (cómo funciona) y `04_resultados.md` (cifras).

## Qué hace

Clasificador **Naive Bayes mixto** programado en **GNU R base** que predice si el ingreso anual de una persona supera USD 50.000. Usa el archivo `adult.data` (Adult/Census Income, UCI, censo de EE. UU. de 1994) y repite el procedimiento en **200 réplicas de submuestreo equilibrado** para estudiar:

1. cuánto cambia el umbral de decisión $\tau_b$ entre réplicas;
2. cuánto cambian los indicadores de desempeño en prueba;
3. cómo se reparten los errores entre las 10 categorías conjuntas sexo/raza.

Curso INFO-1165, Prueba Práctica 2 (Universidad Católica de Temuco, 2026).

Equipo: [FALTA DATO: nombres de los tres integrantes.] <!-- FALTA: nombres del equipo -->

## Problema

| Elemento | Definición |
|---|---|
| Población | Personas de `adult.data` con `education-num` ≥ 9 (secundaria completa o más): 28 308 personas |
| Clase | $c = 1$ si ingreso > USD 50.000 (7 597 personas, 26,8 %); $c = 0$ si ≤ USD 50.000 (20 711) |
| Predictores | Edad y horas semanales (normales por clase); educación (8 niveles) y categoría conjunta sexo/raza (10 niveles), con Laplace $\alpha = 1$ |
| Alcance | Descriptivo, sobre esta tabla. No se pondera con `fnlwgt` ni se generaliza a la población actual |

## Cómo se hace, en seis pasos

1. **Datos** (`R/01_datos.R`): se leen los datos, se marcan `?` y vacíos como faltantes, se excluyen faltantes en las columnas usadas (0 filas) y luego `education-num` < 9 (4 253 filas).
2. **Partición** (`R/02_particion.R`): con semilla $20261021 + b - 1$, dentro de cada clase 80 % disponible, 10 % validación y 10 % prueba. Se sortean $n_* = 6\,077$ personas por clase para entrenar (entrenamiento equilibrado). Validación y prueba conservan la prevalencia real.
3. **Modelo** (`R/03_modelo.R`): previas, medias, desviaciones y probabilidades con Laplace, solo con el entrenamiento. Puntaje en escala logarítmica y $D = \ell_1 - \ell_0$, descompuesto en cinco contribuciones.
4. **Umbral** (`R/04_umbral_metricas.R`): en validación se prueban todos los cortes posibles de $D$ y se elige el que maximiza Youden ($J = \text{TPR} + \text{TNR} - 1$), con empates a ε de máquina resueltos por menor $|\tau|$.
5. **Réplicas** (`R/05_replicas.R`): pasos 2 a 4 y evaluación en prueba, 200 veces. Cada réplica queda guardada en un `.rds`.
6. **Análisis** (`R/06`–`R/09`): resumen entre réplicas, errores por grupo, diagnósticos de supuestos y evidencias de la réplica 1.

Media, desviación estándar, log-densidad normal y percentil tipo 7 están programados a mano; las funciones de R base equivalentes se usan solo para comprobar.

## Resultados clave

| Qué | Resultado |
|---|---|
| Umbral $\tau_b$ (200 réplicas) | mediana 0,068; 95 % central de −0,216 a 0,265; rango −0,32 a 0,32 |
| Exactitud en prueba (mediana) | 0,736 |
| Sensibilidad TPR (mediana) | 0,758 |
| Especificidad TNR (mediana) | 0,728 |
| Precisión positiva PPV (mediana) | 0,506 |
| Exactitud balanceada BA (mediana) | 0,742 |
| Réplica 1 | $\tau_1 = 0{,}0991$; en prueba exactitud 0,751, TPR 0,756, TNR 0,749 |
| Sexo (réplica 1) | Hombres: TPR 0,830, FPR 0,385. Mujeres: TPR 0,327, FPR 0,063 |
| Verificaciones | Todas correctas en las 200 réplicas |

En pocas palabras: el clasificador detecta cerca de 3 de cada 4 ingresos altos, pero la mitad de sus predicciones positivas son falsas, porque los ingresos altos son minoría. El umbral cambia bastante entre réplicas sin que el desempeño global cambie mucho. Los errores se reparten de forma muy desigual por sexo, y en los grupos pequeños las tasas son tan inestables que no permiten conclusiones.

## Cómo ejecutar

1. Copiar `adult.data` y `adult.names` sin modificar en `data/raw/` (descarga: <https://archive.ics.uci.edu/dataset/2/adult>). MD5 esperados: `adult.data` 5d7c39d7b8804f071cdd1f2a7c460872, `adult.names` 1a7cdb3ff7a1b709968b1c7a11def63e.
2. Desde la raíz del proyecto:

   ```r
   source("run_all.R")
   ```

   o `Rscript run_all.R`. Tarda unos 2,3 minutos (137,5 s en la ejecución de referencia), casi todo en las 200 réplicas.
3. Salidas: `data/processed/` (tabla analítica), `output/replicas/` (200 `.rds`), `output/tablas/` (17 CSV), `output/figuras/` (7 PNG), `logs/` (semillas y sesión).
4. Verificaciones opcionales por módulo: `Rscript tests/test_NN_modulo.R` (9 scripts, unos 12 s en total).

Requisitos: R base (la ejecución de referencia usó R 4.6.1 en Windows 11). No usa paquetes externos.

## Dónde está cada cosa

| Necesito… | Documento |
|---|---|
| Responder las preguntas de la defensa | `01_preguntas_respuestas.md` |
| Fórmulas, módulos, archivos y verificaciones | `03_documentacion_tecnica.md` y `arquitectura.md` (contratos) |
| Todas las cifras | `04_resultados.md` |
| Interpretación, límites y autoevaluación | `05_evaluacion_resultados.md` |
| Historia de cada módulo | `bitacora.md` |
