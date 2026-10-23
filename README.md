# INFO1165 - Clasificacion de ingresos

## Objetivo
Clasificar el ingreso (conjunto Adult) con un clasificador Naive Bayes implementado en GNU R base (sin paquetes externos), evaluado mediante B replicas de particion, con eleccion de umbral, indicadores y analisis de errores por grupos (sex/race).

## Como ejecutar
Desde la raiz del proyecto (abrir el `.Rproj` o fijar el directorio de trabajo):

```r
source("run_all.R")
```

`run_all.R` solo ejecuta con `source()` los scripts de `R/` en orden. Coloca `adult.data` y `adult.names` (intactos) en `data/raw/`.

## Estructura
- `run_all.R`: orquestador.
- `R/00_config.R` ... `R/09_replica1.R`: scripts numerados (configuracion, datos, particion, modelo, umbral/metricas, replicas, resumen, grupos, diagnosticos, replica 1).
- `data/raw/`: datos originales; `data/processed/`: tabla analitica y registro de exclusiones.
- `output/replicas/`: un `.rds` por replica; `output/tablas/`: csv; `output/figuras/`: png.
- `logs/`: entorno, RNGkind, semillas, eps.
- `docs/`: documentacion y rubrica.