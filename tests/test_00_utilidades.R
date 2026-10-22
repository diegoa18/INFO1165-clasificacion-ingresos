# Test de 00_utilidades.R frente a mean, sd y quantile(type = 7).
# Ejecutar desde la raiz: Rscript tests/test_00_utilidades.R. No escribe archivos.

source(file.path("R", "00_utilidades.R"))
source(file.path("R", "00_config.R"))

# Tolerancia EPS * escala, con escala = n * max|valor de referencia|.
tol <- function(ref, n = 1L) EPS * n * max(1, abs(ref))

set.seed(1L)
casos <- list(
  uno       = 7.25,                                  # r = 1
  dos       = c(3, -1),
  enteros   = c(5L, 1L, 4L, 2L, 3L),
  empates   = c(2, 2, 2, 5, 5, 9),
  constante = rep(4.5, 10),
  normal    = rnorm(1000, mean = 40, sd = 12),
  grande    = 1e8 + runif(500)
)
p <- c(0, 0.025, 0.25, 0.5, 0.75, 0.975, 1)

for (nm in names(casos)) {
  x <- casos[[nm]]
  n <- length(x)
  stopifnot(abs(media_manual(x) - mean(x)) <= tol(mean(x), n))
  if (n >= 2L) stopifnot(abs(sd_manual(x) - sd(x)) <= tol(sd(x), n) * max(1, abs(mean(x))))
  ref <- unname(quantile(x, p, type = 7))
  stopifnot(length(percentil_tipo7(x, p)) == length(p),
            all(abs(percentil_tipo7(x, p) - ref) <= tol(max(abs(x)), 4L)))
  cat(sprintf("%-9s r = %4d  media dif = %.1e  sd dif = %s  p7 dif max = %.1e\n", nm, n,
              abs(media_manual(x) - mean(x)),
              if (n >= 2L) sprintf("%.1e", abs(sd_manual(x) - sd(x))) else "  (n<2)",
              max(abs(percentil_tipo7(x, p) - ref))))
}

# Casos exactos calculados a mano.
x <- c(10, 40, 20, 30)                                 # ordenado: 10 20 30 40
stopifnot(
  media_manual(x) == 25,
  sd_manual(c(1, 2, 3, 4, 5)) == sqrt(2.5),
  percentil_tipo7(x, 0)   == 10,                       # p = 0 -> minimo
  percentil_tipo7(x, 1)   == 40,                       # p = 1 -> maximo
  percentil_tipo7(x, 0.5) == 25,                       # h = 2,5 -> 20 + 0,5 * 10
  abs(percentil_tipo7(x, 0.025) - 10.75) <= tol(40),   # h = 1,075 -> 10 + 0,075 * 10
  identical(percentil_tipo7(7.25, c(0, 0.5, 1)), c(7.25, 7.25, 7.25)),  # r = 1
  sd_manual(rep(4.5, 10)) == 0
)

# Entradas invalidas segun el contrato.
falla <- function(expr) inherits(tryCatch(expr, error = function(e) e), "error")
stopifnot(
  falla(media_manual(numeric(0))), falla(media_manual(c(1, NA))),
  falla(sd_manual(1)),
  falla(percentil_tipo7(numeric(0), 0.5)), falla(percentil_tipo7(c(1, NA), 0.5)),
  falla(percentil_tipo7(1:3, 1.1)), falla(percentil_tipo7(1:3, -0.1))
)

cat("\ntest_00_utilidades: OK\n")
