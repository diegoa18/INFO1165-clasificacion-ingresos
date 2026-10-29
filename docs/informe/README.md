# Informe de resultados INFO-1165

- [Informe en PDF](Informe_INFO1165_Naive_Bayes_Mixto.pdf).
- [Fuente LaTeX editable](main.tex).

Documento en tercera persona, fechado el 28 de octubre de 2026, de 44 páginas, con 24 tablas y siete figuras.
Integrantes: Diego Alvarez, Vicente Matus, Esban Vejar, Daniela Romero y Franco Oyarzo.

## Compilar el informe

El archivo principal es `main.tex` y utiliza imágenes con rutas relativas a `images/`.
Para editar en Overleaf se debe subir esta carpeta completa.
Desde `docs/informe/`, ejecutar tres veces con pdfLaTeX:

```sh
pdflatex -interaction=nonstopmode -halt-on-error -jobname=Informe_INFO1165_Naive_Bayes_Mixto main.tex
```

La compilación del documento se verificó con pdfTeX 1.40.28 (MiKTeX 25.12).
Los archivos auxiliares de compilación están excluidos de Git en esta carpeta.

## Archivos de apoyo

- `images/`: las siete figuras originales utilizadas en el documento.
- `datos/originales/`: los 17 CSV de resultados utilizados como evidencia.
- `datos/complementarios/`: diagnósticos descriptivos y verificaciones adicionales del informe.
- `scripts/auditar_informe.R`: calcula esos diagnósticos desde los resultados RDS del proyecto.
- `manifiesto_sha256.json`: huellas de integridad de los archivos de esta carpeta.

Las tablas del PDF muestran cifras redondeadas; los CSV conservan su precisión original.
Se distingue la réplica 1 del resumen de las 200 réplicas y se identifican entrenamiento, validación y prueba.
Los percentiles entre réplicas se interpretan como rangos descriptivos de variación, sin atribuirles cobertura de confianza poblacional.

## Reproducir el análisis estadístico

Desde la raíz del repositorio:

```sh
Rscript --vanilla run_all.R
```

Se necesitan los originales `adult.data` y `adult.names` en `data/raw/`.
Esta carpeta documenta los resultados revisados y no contiene los datos crudos ni los 200 RDS.
Los CSV aquí incluidos son una copia fija de los utilizados en el informe: ejecutar el proyecto regenera `output/`, sin actualizar automáticamente este documento.

Para regenerar los diagnósticos complementarios, una vez disponibles los 200 RDS, desde la raíz del repositorio:

```sh
Rscript --vanilla docs/informe/scripts/auditar_informe.R "RUTA_ABSOLUTA_AL_REPOSITORIO" "RUTA_ABSOLUTA_A_LA_CARPETA_DE_SALIDA"
```

El script lee los resultados existentes y escribe únicamente en la carpeta de salida indicada.
La revisión de los nueve tests se realizó el 28 de octubre de 2026 con R 4.5.1 en Windows 11.
La corrida completa documentada para esta revisión corresponde al 25 de octubre de 2026.
El informe explicita la limitación documental sobre el historial de análisis exploratorios previos del equipo.
