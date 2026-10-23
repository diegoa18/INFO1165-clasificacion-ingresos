# Test de 04_umbral_metricas.R: casos de juguete calculados a mano y replica 1 completa (02 + 03 + 04).
# Ejecutar desde la raiz: Rscript tests/test_04_umbral_metricas.R. No escribe archivos.

source(file.path("R", "00_utilidades.R"))
source(file.path("R", "00_config.R"))
source(file.path("R", "02_particion.R"))
source(file.path("R", "03_modelo.R"))
source(file.path("R", "04_umbral_metricas.R"))

tol <- function(ref, n = 1L) EPS * n * max(1, abs(ref))
iguales <- function(a, b) all((is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & abs(a - b) <= tol(1, 4L)))

# Identidades de los indicadores (solo donde son estimables), con la tolerancia del
# contrato para identidades entre indicadores: 4 * EPS.
TOL_IDENT <- 4 * EPS
identidades <- function(ind) {
  with(as.list(ind), all(c(
    is.na(TPR) || is.na(FNR) || abs(TPR + FNR - 1) <= TOL_IDENT,
    is.na(TNR) || is.na(FPR) || abs(TNR + FPR - 1) <= TOL_IDENT,
    is.na(BA)  || abs(BA - (TPR + TNR) / 2) <= TOL_IDENT,
    is.na(J)   || abs(J - (TPR + TNR - 1)) <= TOL_IDENT
  )))
}

# --- Juguete 1: candidatos y maximo unico ---------------------------------------
# D = -2 -1 0 1 2, clase = 0 0 1 0 1. Candidatos: -2, -1,5, -0,5, 0,5, 1,5, Inf.
# J a mano: 0, 1/3, 2/3, 1/6, 1/2, 0 -> tau = -0,5.
D1 <- c(-2, -1, 0, 1, 2); c1 <- c(0L, 0L, 1L, 0L, 1L)
e1 <- elegir_umbral(D1, c1)
stopifnot(
  identical(candidatos_umbral(D1), c(-2, -1.5, -0.5, 0.5, 1.5, Inf)),
  identical(candidatos_umbral(c(2, -2, 0, 1, -1, 2)), candidatos_umbral(D1)),   # orden y repetidos
  iguales(e1$candidatos$J, c(0, 1/3, 2/3, 1/6, 1/2, 0)),
  e1$tau == -0.5, abs(e1$J_max - 2/3) <= tol(1), sum(e1$candidatos$empatado) == 1L,
  identical(names(e1), c("tau", "J_max", "eps", "candidatos")), e1$eps == EPS,
  identical(names(e1$candidatos), c("tau", "TN", "FP", "FN", "TP", "TPR", "TNR", "J", "empatado")),
  identical(predecir(D1, -0.5), c(0L, 0L, 1L, 1L, 1L)),
  identical(predecir(D1, 0), c(0L, 0L, 1L, 1L, 1L)),                           # D >= tau es positivo
  identical(predecir(D1, Inf), rep(0L, 5L))
)

# --- Juguete 2: empate con igual |tau| -> menor tau ------------------------------
# D = -3 -1 1 3, clase = 0 1 0 1. Candidatos -3, -2, 0, 2, Inf con J = 0, 1/2, 0, 1/2, 0.
e2 <- elegir_umbral(c(-3, -1, 1, 3), c(0L, 1L, 0L, 1L))
stopifnot(
  identical(e2$candidatos$tau, c(-3, -2, 0, 2, Inf)),
  iguales(e2$candidatos$J, c(0, 0.5, 0, 0.5, 0)),
  identical(e2$candidatos$empatado, c(FALSE, TRUE, FALSE, TRUE, FALSE)),
  e2$tau == -2
)

# --- Juguete 3: empate a tres -> menor |tau| ------------------------------------
# D = -5 -3 1 3, clase = 1 0 1 0. Candidatos -5, -4, -1, 2, Inf con J = 0, -1/2, 0, -1/2, 0.
e3 <- elegir_umbral(c(-5, -3, 1, 3), c(1L, 0L, 1L, 0L))
stopifnot(
  iguales(e3$candidatos$J, c(0, -0.5, 0, -0.5, 0)),
  sum(e3$candidatos$empatado) == 3L,
  e3$tau == -1
)

# --- Juguete 4: el criterio de empate usa eps -------------------------------------
# Con los datos del juguete 1, eps = 0,2 empata J = 2/3 (tau = -0,5) y J = 1/2 (tau = 1,5),
# porque 2/3 - 1/2 = 1/6 <= 0,2; gana el menor |tau|. Con eps = 0 no hay empate.
e4 <- elegir_umbral(D1, c1, eps = 0.2)
stopifnot(
  identical(e4$candidatos$empatado, c(FALSE, FALSE, TRUE, FALSE, TRUE, FALSE)),
  e4$tau == -0.5, e4$eps == 0.2,
  sum(elegir_umbral(D1, c1, eps = 0)$candidatos$empatado) == 1L,
  sum(elegir_umbral(c(-1, 1), c(0L, 1L))$candidatos$empatado) == 1L
)

# --- Juguete 5: L = 1 y punto medio que redondea fuera de (u_h, u_{h+1}] -----------
u_sig <- 1 + EPS                                          # siguiente double despues de 1
stopifnot(
  identical(candidatos_umbral(c(2, 2, 2)), c(2, Inf)),
  1 / 2 + u_sig / 2 == 1,                                 # el punto medio exacto no es representable
  identical(candidatos_umbral(c(1, u_sig)), c(1, u_sig, Inf)),
  !is.unsorted(candidatos_umbral(c(1, u_sig, 3)), strictly = TRUE)
)

# --- Juguete 6: matriz e indicadores a mano ------------------------------------
cl6 <- c(rep(0L, 60), rep(1L, 40))
pr6 <- c(rep(0L, 50), rep(1L, 10), rep(0L, 5), rep(1L, 35))
m6  <- matriz_confusion(cl6, pr6)
i6  <- indicadores(m6)
stopifnot(
  identical(m6, c(TN = 50L, FP = 10L, FN = 5L, TP = 35L)),
  identical(names(i6), INDICADORES),
  iguales(unname(i6), c(85/100, 35/40, 50/60, 35/45, 70/85, 10/60, 5/40,
                        (35/40 + 50/60) / 2, 35/40 + 50/60 - 1)),
  identidades(i6)
)

# --- Juguete 7: denominador 0 -> NA ---------------------------------------------
i7 <- indicadores(c(TN = 5L, FP = 0L, FN = 0L, TP = 0L))   # sin positivos reales ni predichos
stopifnot(
  iguales(unname(i7), c(1, NA, 1, NA, NA, 0, NA, NA, NA)),
  all(is.na(indicadores(c(TN = 0L, FP = 0L, FN = 0L, TP = 0L)))),
  identidades(i7)
)

# --- Juguete 8: por grupo y resumir ---------------------------------------------
g8  <- factor(c("Female/White", "Female/White", "Male/White", "Male/White", "Male/Black"),
              levels = NIVELES_G)
cl8 <- c(0L, 1L, 1L, 0L, 1L); pr8 <- c(0L, 1L, 0L, 1L, 1L)
mg8 <- matrices_por_grupo(cl8, pr8, g8)
fila <- function(nivel) mg8[mg8$g == nivel, ]
stopifnot(
  # estructura del contrato (formato largo)
  is.data.frame(mg8), nrow(mg8) == 10L,
  identical(names(mg8), c("g", "TN", "FP", "FN", "TP", "n", "n_1", "n_0", "TPR", "FPR", "FNR")),
  is.factor(mg8$g), identical(levels(mg8$g), NIVELES_G),
  identical(as.character(mg8$g), NIVELES_G),               # orden de NIVELES_G
  identical(rownames(mg8), as.character(1:10)),            # sin nombres de fila
  all(vapply(mg8[c("TN", "FP", "FN", "TP", "n", "n_1", "n_0")], is.integer, logical(1))),
  all(vapply(mg8[c("TPR", "FPR", "FNR")], is.double, logical(1))),
  all(mg8$n_1 == mg8$TP + mg8$FN), all(mg8$n_0 == mg8$TN + mg8$FP), all(mg8$n == mg8$n_1 + mg8$n_0),
  # suma de M_g = M
  identical(c(TN = sum(mg8$TN), FP = sum(mg8$FP), FN = sum(mg8$FN), TP = sum(mg8$TP)),
            matriz_confusion(cl8, pr8)),
  # valores a mano
  fila("Female/White")$TPR == 1, fila("Female/White")$FPR == 0,
  fila("Male/White")$FNR == 1, fila("Male/White")$FPR == 1,
  is.na(fila("Male/Black")$FPR),                           # sin negativos reales
  fila("Female/Black")$n == 0L,                            # grupo sin personas: conteos 0, tasas NA
  all(fila("Female/Black")[c("TN", "FP", "FN", "TP")] == 0L),
  all(is.na(fila("Female/Black")[c("TPR", "FPR", "FNR")])),
  # rbind de dos replicas con columna b (uso de 07)
  nrow(rbind(cbind(b = 1L, mg8), cbind(b = 2L, mg8))) == 20L
)

r_n <- resumir(c(1, 2, 3, NA, 4, 10))
stopifnot(
  identical(names(r_n), c("r", "media", "sd", "mediana", "p2.5", "p97.5")),
  r_n[["r"]] == 5, r_n[["media"]] == 4, r_n[["mediana"]] == 3,
  abs(r_n[["sd"]] - sd(c(1, 2, 3, 4, 10))) <= tol(4, 5L),
  iguales(unname(r_n[c("p2.5", "p97.5")]), unname(quantile(c(1, 2, 3, 4, 10), P_PERCENTILES, type = 7))),
  identical(unname(resumir(c(NA, 5))), c(1, 5, NA, 5, 5, 5)),         # r = 1: sd NA
  identical(unname(resumir(c(NA_real_, NA_real_))), c(0, NA, NA, NA, NA, NA))  # r = 0
)

# --- Replica 1 completa ----------------------------------------------------------
tabla <- readRDS(file.path(RUTAS$processed, "tabla_analitica.rds"))
part  <- particionar(tabla$clase, semilla_replica(1L))
entr  <- tabla[part$indices$entrenamiento, ]
val   <- tabla[part$indices$validacion, ]
pru   <- tabla[part$indices$prueba, ]

modelo <- ajustar_nb(entr)
D_val  <- puntuar(modelo, val)$D
D_pru  <- puntuar(modelo, pru)$D

umbral <- elegir_umbral(D_val, val$clase)
pred   <- predecir(D_pru, umbral$tau)
m_pru  <- matriz_confusion(pru$clase, pred)
i_pru  <- indicadores(m_pru)
grupos <- matrices_por_grupo(pru$clase, pred, pru$g)
cand   <- umbral$candidatos

cat("== Replica 1: umbral en validacion ==\n")
cat("candidatos:", nrow(cand), " | valores distintos de D:", length(unique(D_val)),
    " | empatados:", sum(cand$empatado), "\n")
cat("tau_1 =", format(umbral$tau, digits = 10), "  J_max (validacion) =", format(umbral$J_max, digits = 10), "\n")
print(cand[cand$empatado, ], row.names = FALSE)

cat("\n== Matriz de confusion en prueba (n =", length(pred), ") ==\n"); print(m_pru)
cat("\n== Indicadores en prueba ==\n"); print(round(i_pru, 4))
cat("\n== Por categoria conjunta (prueba) ==\n"); print(cbind(grupos[, 1:8], round(grupos[, 9:11], 4)))

stopifnot(
  nrow(cand) == length(unique(D_val)) + 1L,
  !is.unsorted(cand$tau, strictly = TRUE), is.infinite(cand$tau[nrow(cand)]),
  cand$tau[1L] == min(D_val),
  all(cand$TN + cand$FP + cand$FN + cand$TP == length(D_val)),
  umbral$J_max == max(cand$J), umbral$tau %in% cand$tau[cand$empatado],
  abs(cand$J[cand$tau == umbral$tau] - umbral$J_max) <= EPS,
  sum(m_pru) == nrow(pru),
  m_pru[["TP"]] + m_pru[["FN"]] == sum(pru$clase == 1L),
  m_pru[["TN"]] + m_pru[["FP"]] == sum(pru$clase == 0L),
  identidades(i_pru), !anyNA(i_pru),
  # por grupo: 10 filas, niveles exactos y suma de M_g = M
  nrow(grupos) == 10L, identical(levels(grupos$g), NIVELES_G),
  identical(c(TN = sum(grupos$TN), FP = sum(grupos$FP), FN = sum(grupos$FN), TP = sum(grupos$TP)),
            m_pru),
  sum(grupos$n) == nrow(pru)
)

cat("\ntest_04_umbral_metricas: OK\n")
