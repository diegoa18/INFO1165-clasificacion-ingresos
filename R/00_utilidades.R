# Utilidades (nivel 0): estadisticos a mano, funciones puras sin dependencias.
# No usa ningun objeto de 00_config.R. Entradas sin NA (quien llama los filtra).
# Contrato: docs/arquitectura.md, seccion 3.

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
