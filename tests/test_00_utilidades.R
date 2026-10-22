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

# --- escribir_csv: ida y vuelta (archivo temporal, fuera del proyecto) ---------
df <- data.frame(
  dbl     = c(0.1 + 0.2, 1/3, Inf, -Inf, NaN, NA, 1e-300, -2.5e17),
  int     = c(1L, NA, 3L, -4L, 0L, 2147483647L, 7L, 8L),
  lgl     = c(TRUE, FALSE, NA, TRUE, FALSE, TRUE, NA, FALSE),
  chr     = c("a,b", "c", NA, "comilla \"doble\"", "", "f", "Male/White", "  espacios "),
  fac     = factor(c("x", "y", "x", NA, "z", "y", "x", "z")),
  entero  = c(1, 2, 3, -4, 0, 10, 100, 1e6),          # excepcion: vuelve integer
  todo_na = rep(NA_real_, 8),                          # excepcion: vuelve logical
  stringsAsFactors = FALSE
)
ruta <- tempfile(fileext = ".csv")
stopifnot(identical(escribir_csv(df, ruta), ruta))
x <- read.csv(ruta, stringsAsFactors = FALSE)
lineas <- readLines(ruta)
unlink(ruta)

stopifnot(
  identical(names(x), names(df)), nrow(x) == nrow(df),
  identical(x$dbl, df$dbl),                            # incluye 0.1 + 0.2, Inf, -Inf, NaN y NA
  is.nan(x$dbl[5]), is.na(x$dbl[6]) && !is.nan(x$dbl[6]),
  identical(x$int, df$int),
  identical(x$lgl, df$lgl),
  identical(x$chr, df$chr),
  identical(x$fac, as.character(df$fac)),
  is.integer(x$entero), identical(as.numeric(x$entero), df$entero),
  is.logical(x$todo_na), all(is.na(x$todo_na)),
  # formato: encabezado, NA sin comillas, numericos y logicos sin comillas
  lineas[1] == "\"dbl\",\"int\",\"lgl\",\"chr\",\"fac\",\"entero\",\"todo_na\"",
  lineas[2] == "0.30000000000000004,1,TRUE,\"a,b\",\"x\",1,NA",
  lineas[4] == "Inf,3,NA,NA,\"x\",3,NA",               # character NA sin comillas
  lineas[5] == "-Inf,-4,TRUE,\"comilla \"\"doble\"\"\",NA,-4,NA",   # factor NA sin comillas
  lineas[6] == "NaN,0,FALSE,\"\",\"z\",0,NA",
  lineas[7] == "NA,2147483647,TRUE,\"f\",\"y\",10,NA"
)
cat("escribir_csv: ida y vuelta identical() OK\n")

cat("\ntest_00_utilidades: OK\n")
