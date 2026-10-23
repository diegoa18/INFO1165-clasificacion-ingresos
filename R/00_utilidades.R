# Utilidades (nivel 0): utilidades compartidas sin dependencias.
# No usa ningun objeto de 00_config.R: todo lo recibe como argumento.
# Contrato: docs/arquitectura.md, seccion 3.

# --- Estadisticos a mano (entradas sin NA; quien llama los filtra) -------------

media_manual <- function(x) {
  stopifnot(is.numeric(x), length(x) >= 1L, !anyNA(x))
  sum(x) / length(x)
}

# Denominador n - 1.
sd_manual <- function(x) {
  stopifnot(length(x) >= 2L)
  m <- media_manual(x)
  sqrt(sum((x - m)^2) / (length(x) - 1L))
}

# Percentil tipo 7: h = 1 + (r - 1) p, Q(p) = x_(floor h) + (h - floor h) (x_(floor h + 1) - x_(floor h)).
percentil_tipo7 <- function(x, p) {
  stopifnot(is.numeric(x), length(x) >= 1L, !anyNA(x),
            is.numeric(p), !anyNA(p), all(p >= 0 & p <= 1))
  x  <- sort(x)
  r  <- length(x)
  h  <- 1 + (r - 1) * p
  lo <- floor(h)
  hi <- pmin(lo + 1, r)
  x[lo] + (h - lo) * (x[hi] - x[lo])
}

# --- Escritura de tablas -------------------------------------------------------

# Reemplaza write.csv (15 cifras): double con 17 cifras significativas (Inf, -Inf, NaN
# con su etiqueta), integer/logical/double sin comillas, character/factor entre comillas,
# NA sin comillas, sin nombres de fila. Devuelve la ruta de forma invisible.
escribir_csv <- function(df, ruta) {
  stopifnot(is.data.frame(df), is.character(ruta), length(ruta) == 1L)
  con_comillas <- vapply(df, function(x) is.character(x) || is.factor(x), logical(1))
  dbl <- vapply(df, is.double, logical(1))
  df[dbl] <- lapply(df[dbl], function(x) {
    s <- sprintf("%.17g", x)
    s[is.na(x) & !is.nan(x)] <- NA
    s
  })
  write.csv(df, ruta, row.names = FALSE, quote = which(con_comillas), na = "NA")
  invisible(ruta)
}
