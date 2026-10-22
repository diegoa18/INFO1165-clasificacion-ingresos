# Bitácora de módulos

Se completa una sección al cerrar el PR de cada módulo. Los contratos de referencia están en `docs/arquitectura.md`.

<!-- Plantilla por módulo:

## NN_nombre.R

- **Estado:** pendiente | en curso | cerrado (PR #, fecha)
- **Implementado:**
- **Funciones expuestas:**
- **Verificaciones:**
- **Dudas abiertas:**
-->

## 00_config.R

- **Estado:** en curso (rama `feat/00-config`, PR pendiente, 2026-10-22)
- **Implementado:** rutas (`RUTAS`), `B`, `SEMILLA_BASE`, `ALPHA`, `EPS`, `P_PERCENTILES`, `PROPORCIONES` (0,8 / 0,1 / 0,1), `COLUMNAS_ADULT`, `COLUMNAS_REQUERIDAS`, `ETIQUETAS_INGRESO`, `EDUCACION_NUM_MIN`, `NIVELES_E`, `NIVELES_SEXO`, `NIVELES_RAZA`, `NIVELES_G`, `K_E`, `K_G`, `INDICADORES`. Sin lógica de cómputo ni efectos en disco.
- **Funciones expuestas:** `semilla_replica(b)` (contrato) y su alias `semilla(b)`; ambas devuelven `SEMILLA_BASE + b - 1L`.
- **Verificaciones:** `stopifnot` al final del archivo (tipos de `B` y `SEMILLA_BASE`, `semilla(1) == 20261021`, `semilla(B) == 20261220`, `sum(PROPORCIONES) == 1` con tolerancia `EPS`, 15 columnas, 8 niveles de E, 10 niveles de G sin duplicados y en orden sexo/raza, 9 indicadores, 6 rutas). `Rscript` con `source("R/00_config.R")` termina sin errores.
- **Dudas abiertas:** `PROPORCIONES`, `COLUMNAS_REQUERIDAS`, `ETIQUETAS_INGRESO`, `EDUCACION_NUM_MIN` y el alias `semilla` no figuran en la tabla de objetos de `arquitectura.md`; proponer su inclusión en la descripción del PR.

## 01_datos.R

- **Estado:** pendiente
- **Implementado:**
- **Funciones expuestas:**
- **Verificaciones:**
- **Dudas abiertas:**

## 02_particion.R

- **Estado:** pendiente
- **Implementado:**
- **Funciones expuestas:**
- **Verificaciones:**
- **Dudas abiertas:**

## 03_modelo.R

- **Estado:** pendiente
- **Implementado:**
- **Funciones expuestas:**
- **Verificaciones:**
- **Dudas abiertas:**

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
