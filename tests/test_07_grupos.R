# Test de 07_grupos.R: lee las tablas y la figura escritas por el script y las contrasta con los .rds.
# Requiere haber ejecutado R/05_replicas.R y R/07_grupos.R.
# Ejecutar desde la raiz: Rscript tests/test_07_grupos.R. No escribe archivos.

source(file.path("R", "00_utilidades.R"))
source(file.path("R", "00_config.R"))
source(file.path("R", "04_umbral_metricas.R"))

leer <- function(archivo) read.csv(file.path(RUTAS$tablas, archivo), stringsAsFactors = FALSE)
grupos   <- leer("grupos_replicas.csv")
resumen  <- leer("resumen_grupos.csv")
replica1 <- leer("grupos_replica1.csv")
m_sexo   <- leer("marginales_sexo_replica1.csv")
m_raza   <- leer("marginales_raza_replica1.csv")

suma_matriz <- function(d) c(TN = sum(d$TN), FP = sum(d$FP), FN = sum(d$FN), TP = sum(d$TP))

# --- grupos_replicas.csv: 10 B filas, cada replica suma su matriz global -------------
stopifnot(
  nrow(grupos) == 10L * B,
  identical(names(grupos), c("b", "g", "TN", "FP", "FN", "TP", "n", "n_1", "n_0", "TPR", "FPR", "FNR")),
  identical(grupos$b, rep(seq_len(B), each = 10L)),
  identical(grupos$g, rep(NIVELES_G, times = B))
)
for (b in seq_len(B)) {
  r  <- readRDS(file.path(RUTAS$replicas, sprintf("replica_%03d.rds", b)))
  gb <- grupos[grupos$b == b, ]
  stopifnot(
    identical(suma_matriz(gb), r$matriz_prueba),
    sum(gb$n) == nrow(r$prueba),
    identical(gb$TP, r$grupos_prueba$TP), identical(gb$FP, r$grupos_prueba$FP)
  )
}

# --- Grupos sin positivos: TPR y FNR NA, y no cuentan en r ------------------------
sin_pos <- grupos$n_1 == 0L
stopifnot(
  sum(sin_pos) > 0L,                                       # existen en los datos
  all(is.na(grupos$TPR[sin_pos])), all(is.na(grupos$FNR[sin_pos])),
  !anyNA(grupos$TPR[!sin_pos]), !anyNA(grupos$FNR[!sin_pos]),
  all(grupos$n_0 > 0L), !anyNA(grupos$FPR)
)
cat("filas grupo-replica sin positivos:", sum(sin_pos), "\n")
print(table(g = grupos$g[sin_pos]))

# --- resumen_grupos.csv: 30 filas con resumir() --------------------------------------
INDICADORES_G <- c(TPR = "n_1", FPR = "n_0", FNR = "n_1")
stopifnot(
  nrow(resumen) == 30L,
  identical(names(resumen), c("g", "indicador", "denominador", "den_min", "den_mediana", "den_max",
                              "r", "mediana", "p2.5", "p97.5")),
  identical(resumen$g, rep(NIVELES_G, each = 3L)),
  identical(resumen$indicador, rep(names(INDICADORES_G), times = 10L)),
  identical(resumen$denominador, unname(INDICADORES_G[resumen$indicador])),
  all(resumen$p2.5 <= resumen$mediana), all(resumen$mediana <= resumen$p97.5)
)
for (i in seq_len(nrow(resumen))) {
  fila <- resumen[i, ]
  sub  <- grupos[grupos$g == fila$g, ]
  x    <- sub[[fila$indicador]]
  den  <- sub[[fila$denominador]]
  s    <- resumir(x)
  stopifnot(
    fila$r == s[["r"]], fila$r == sum(den > 0L),           # sin positivos no cuenta en r
    identical(fila$mediana, s[["mediana"]]),
    identical(fila$p2.5, s[["p2.5"]]), identical(fila$p97.5, s[["p97.5"]]),
    fila$den_min == min(den), fila$den_max == max(den),
    fila$den_mediana == percentil_tipo7(den, 0.5)
  )
}

# --- Replica 1: grupos y marginales ---------------------------------------------------
r1 <- readRDS(file.path(RUTAS$replicas, "replica_001.rds"))
cols <- c("n", "n_1", "n_0", "prevalencia", "TN", "FP", "FN", "TP", "TPR", "FPR", "FNR")
tasa <- function(num, den) ifelse(den == 0, NA_real_, num / den)
stopifnot(
  identical(names(replica1), c("g", cols)),
  identical(names(m_sexo), c("sexo", cols)), identical(names(m_raza), c("raza", cols)),
  identical(replica1$g, NIVELES_G), identical(m_sexo$sexo, NIVELES_SEXO), identical(m_raza$raza, NIVELES_RAZA),
  identical(suma_matriz(replica1), r1$matriz_prueba),
  identical(suma_matriz(m_sexo), r1$matriz_prueba),        # marginales suman la matriz global
  identical(suma_matriz(m_raza), r1$matriz_prueba),
  sum(m_sexo$n) == nrow(r1$prueba), sum(m_raza$n) == nrow(r1$prueba),
  identical(replica1$prevalencia, tasa(replica1$n_1, replica1$n)),
  # las tasas marginales se calculan despues de sumar conteos
  identical(m_sexo$TPR, tasa(m_sexo$TP, m_sexo$n_1)), identical(m_sexo$FPR, tasa(m_sexo$FP, m_sexo$n_0)),
  identical(m_raza$TPR, tasa(m_raza$TP, m_raza$n_1)), identical(m_raza$FNR, tasa(m_raza$FN, m_raza$n_1)),
  m_sexo$TP[1] == sum(replica1$TP[startsWith(replica1$g, "Female/")])
)

# --- Figura ------------------------------------------------------------------------
png_07 <- file.path(RUTAS$figuras, "tasas_grupos.png")
stopifnot(file.exists(png_07), file.size(png_07) > 0)

cat("\ntest_07_grupos: OK\n")
