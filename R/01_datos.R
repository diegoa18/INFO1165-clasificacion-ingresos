# Datos (nivel 1): lectura, limpieza, filtro, registro de exclusiones y tabla analitica.
# Lee data/raw/ (sin modificarlo) y escribe data/processed/. Contrato: docs/arquitectura.md, seccion 3.

if (!exists("RUTAS")) source(file.path("R", "00_config.R"))

# --- Funciones ----------------------------------------------------------------

# Lee adult.data sin encabezado; recorta espacios y trata "" y "?" como NA.
leer_adult <- function(ruta) {
  if (!file.exists(ruta)) {
    stop("No existe ", ruta, ": descargar adult.data y adult.names desde UCI en ", RUTAS$raw)
  }
  crudo <- read.csv(ruta, header = FALSE, col.names = COLUMNAS_ADULT,
                    strip.white = TRUE, na.strings = c("?", ""),
                    stringsAsFactors = FALSE)
  # id_original = numero de fila en el archivo (solo se descarta la linea vacia final).
  lineas <- readLines(ruta)
  no_vacias <- which(nzchar(trimws(lineas)))
  stopifnot(length(no_vacias) == nrow(crudo))
  data.frame(id_original = as.integer(no_vacias), crudo, stringsAsFactors = FALSE)
}

# Excluye faltantes en columnas requeridas, luego education_num < EDUCACION_NUM_MIN;
# agrega clase, educacion y g. Devuelve list(tabla, registro).
construir_tabla_analitica <- function(crudo) {
  n_original <- nrow(crudo)

  completos <- stats::complete.cases(crudo[, COLUMNAS_REQUERIDAS])
  paso1 <- crudo[completos, ]

  con_educacion <- paso1$education_num >= EDUCACION_NUM_MIN
  tabla <- paso1[con_educacion, ]

  stopifnot(all(tabla$income %in% ETIQUETAS_INGRESO))
  tabla$clase     <- as.integer(tabla$income == ETIQUETAS_INGRESO[["1"]])
  tabla$educacion <- factor(tabla$education, levels = NIVELES_E)
  tabla$g         <- factor(paste(tabla$sex, tabla$race, sep = "/"), levels = NIVELES_G)

  tabla <- tabla[order(tabla$id_original), ]
  rownames(tabla) <- NULL

  registro <- data.frame(
    paso = c("filas_originales", "excluidas_faltantes", "excluidas_educacion", "total_final"),
    n    = c(n_original, sum(!completos), sum(!con_educacion), nrow(tabla))
  )
  list(tabla = tabla, registro = registro)
}

# --- Ejecucion ----------------------------------------------------------------

crudo     <- leer_adult(file.path(RUTAS$raw, "adult.data"))
resultado <- construir_tabla_analitica(crudo)
tabla     <- resultado$tabla
registro  <- resultado$registro

# --- Verificaciones -----------------------------------------------------------
stopifnot(
  identical(names(tabla), c("id_original", COLUMNAS_ADULT, "clase", "educacion", "g")),
  !anyNA(crudo$id_original), !anyDuplicated(crudo$id_original),
  !any(vapply(crudo[, COLUMNAS_ADULT], function(x) any(x %in% c("?", "")), logical(1))),
  !anyNA(tabla[, COLUMNAS_REQUERIDAS]),
  min(tabla$education_num) >= EDUCACION_NUM_MIN,
  !anyDuplicated(tabla$id_original), !is.unsorted(tabla$id_original),
  is.integer(tabla$clase), all(tabla$clase %in% c(0L, 1L)),
  identical(levels(tabla$educacion), NIVELES_E), !anyNA(tabla$educacion),
  identical(levels(tabla$g), NIVELES_G), !anyNA(tabla$g),
  # education_num 9..16 corresponde uno a uno con NIVELES_E
  all(tabla$education_num == as.integer(tabla$educacion) + EDUCACION_NUM_MIN - 1L),
  registro$n[1] == nrow(crudo),
  registro$n[1] - registro$n[2] - registro$n[3] == registro$n[4],
  registro$n[4] == nrow(tabla),
  sum(table(tabla$clase)) == nrow(tabla),
  sum(table(tabla$g)) == nrow(tabla)
)

# --- Escritura ----------------------------------------------------------------
dir.create(RUTAS$processed, showWarnings = FALSE, recursive = TRUE)
saveRDS(tabla, file.path(RUTAS$processed, "tabla_analitica.rds"))
write.csv(tabla, file.path(RUTAS$processed, "tabla_analitica.csv"), row.names = FALSE)
write.csv(registro, file.path(RUTAS$processed, "registro_exclusiones.csv"), row.names = FALSE)
