# Test de 06_resumen.R: lee las tablas y figuras escritas por el script.
# Requiere haber ejecutado R/05_replicas.R y R/06_resumen.R.
# Ejecutar desde la raiz: Rscript tests/test_06_resumen.R. No escribe archivos.

source(file.path("R", "00_utilidades.R"))
source(file.path("R", "00_config.R"))
source(file.path("R", "04_umbral_metricas.R"))

# Tolerancias del contrato ("Tolerancias numericas"): identidades entre indicadores 4 * EPS;
# a mano frente a R base n * EPS * max(1, |referencia|), con n = valores sumados (r).
TOL_IDENT <- 4 * EPS
tol <- function(ref, n) EPS * n * max(1, abs(ref))

por_replica <- read.csv(file.path(RUTAS$tablas, "replicas_indicadores.csv"))
resumen     <- read.csv(file.path(RUTAS$tablas, "resumen_replicas.csv"))
VARIABLES   <- c("tau", INDICADORES)

# --- Tabla por replica ----------------------------------------------------------
stopifnot(
  identical(names(por_replica), c("b", "semilla", "tau", INDICADORES)),
  nrow(por_replica) == B,
  identical(por_replica$b, seq_len(B)),                       # sin faltantes ni duplicados
  identical(por_replica$semilla, semilla_replica(seq_len(B))),
  # identidades fila a fila
  all(abs(por_replica$BA - (por_replica$TPR + por_replica$TNR) / 2) <= TOL_IDENT),
  all(abs(por_replica$J - (por_replica$TPR + por_replica$TNR - 1)) <= TOL_IDENT),
  all(abs(por_replica$TPR + por_replica$FNR - 1) <= TOL_IDENT),
  all(abs(por_replica$TNR + por_replica$FPR - 1) <= TOL_IDENT),
  # precision completa: tau_1 igual al .rds
  identical(por_replica$tau[1], readRDS(file.path(RUTAS$replicas, "replica_001.rds"))$umbral$tau),
  abs(por_replica$tau[1] - 0.0991012) < 5e-8
)

# --- Cuadro resumen -------------------------------------------------------------
cols <- c("r", "media", "sd", "mediana", "p2.5", "p97.5")
stopifnot(
  identical(names(resumen), c("variable", "escala", cols)),
  identical(resumen$variable, VARIABLES),
  identical(resumen$escala, ifelse(VARIABLES %in% c("tau", "J"), "original", "proporcion")),
  all(resumen$p2.5 <= resumen$mediana), all(resumen$mediana <= resumen$p97.5)
)

dif_base <- 0
for (i in seq_along(VARIABLES)) {
  x  <- por_replica[[VARIABLES[i]]]
  fi <- unlist(resumen[i, cols])
  # coincide con resumir() aplicado a la columna
  stopifnot(identical(unname(fi), unname(resumir(x))))
  # y con R base sobre la misma columna
  xe <- x[!is.na(x)]
  base <- c(length(xe), mean(xe), sd(xe), median(xe), quantile(xe, P_PERCENTILES, type = 7))
  d <- abs(unname(fi) - unname(base))
  stopifnot(fi[["r"]] == length(xe), all(d <= vapply(base, tol, numeric(1), n = length(xe))))
  dif_base <- max(dif_base, d)
}

# --- Figuras ----------------------------------------------------------------------
png_esperados <- file.path(RUTAS$figuras, c("hist_tau.png", "paneles_indicadores.png",
                                            "boxplot_indicadores.png"))
stopifnot(all(file.exists(png_esperados)), all(file.size(png_esperados) > 0))

cat("== resumen_replicas.csv ==\n")
print(cbind(resumen[1:3], round(resumen[cols[-1]], 4)), row.names = FALSE)
cat("\nmaxima diferencia frente a mean / sd / median / quantile(type = 7):", format(dif_base, digits = 3), "\n")
cat("\ntest_06_resumen: OK\n")
