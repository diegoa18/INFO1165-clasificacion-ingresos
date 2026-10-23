# Umbral y metricas (nivel 2): candidatos, matriz de confusion, indicadores, eleccion de tau y resumenes.
# Solo depende del nivel 0; recibe D y la clase como argumentos y no conoce el modelo.
# No lee ni escribe archivos. Contrato: docs/arquitectura.md, seccion 3.

if (!exists("media_manual")) source(file.path("R", "00_utilidades.R"))
if (!exists("RUTAS")) source(file.path("R", "00_config.R"))

# --- Umbral -------------------------------------------------------------------

# {u_1} U {u_h/2 + u_{h+1}/2} U {+Inf}, con u los valores distintos de D ordenados.
# Si un punto medio queda fuera de (u_h, u_{h+1}] por redondeo, se usa u_{h+1}.
candidatos_umbral <- function(D) {
  stopifnot(is.numeric(D), length(D) >= 1L, all(is.finite(D)))
  u <- sort(unique(D))
  L <- length(u)
  if (L == 1L) return(c(u, Inf))
  medios <- u[-L] / 2 + u[-1L] / 2
  fuera  <- !(medios > u[-L] & medios <= u[-1L])
  medios[fuera] <- u[-1L][fuera]
  c(u[1L], medios, Inf)
}

# Positivo si D >= tau.
predecir <- function(D, tau) as.integer(D >= tau)

# --- Matriz e indicadores -----------------------------------------------------

matriz_confusion <- function(clase, pred) {
  stopifnot(length(clase) == length(pred),
            all(clase %in% c(0L, 1L)), all(pred %in% c(0L, 1L)))
  c(TN = sum(clase == 0L & pred == 0L),
    FP = sum(clase == 0L & pred == 1L),
    FN = sum(clase == 1L & pred == 0L),
    TP = sum(clase == 1L & pred == 1L))
}

# Cociente con NA si el denominador es 0.
cociente <- function(num, den) if (den == 0) NA_real_ else num / den

indicadores <- function(m) {
  TN <- m[["TN"]]; FP <- m[["FP"]]; FN <- m[["FN"]]; TP <- m[["TP"]]
  tpr <- cociente(TP, TP + FN)
  tnr <- cociente(TN, TN + FP)
  setNames(c(
    cociente(TP + TN, TN + FP + FN + TP),
    tpr,
    tnr,
    cociente(TP, TP + FP),
    cociente(2 * TP, 2 * TP + FP + FN),
    cociente(FP, TN + FP),
    cociente(FN, TP + FN),
    (tpr + tnr) / 2,
    tpr + tnr - 1
  ), INDICADORES)
}

# --- Eleccion del umbral ------------------------------------------------------

# Maximiza J = TPR + TNR - 1. Empate si |J - J_max| <= eps; gana el menor |tau| y luego el menor tau.
elegir_umbral <- function(D, clase, eps = EPS) {
  stopifnot(length(D) == length(clase), all(c(0L, 1L) %in% clase))
  tau <- candidatos_umbral(D)
  m <- t(vapply(tau, function(t) matriz_confusion(clase, predecir(D, t)),
                integer(4L)))
  TPR <- m[, "TP"] / (m[, "TP"] + m[, "FN"])
  TNR <- m[, "TN"] / (m[, "TN"] + m[, "FP"])
  J   <- TPR + TNR - 1
  J_max    <- max(J)
  empatado <- abs(J - J_max) <= eps

  emp     <- which(empatado)
  elegido <- emp[order(abs(tau[emp]), tau[emp])[1L]]

  candidatos <- data.frame(tau = tau, TN = m[, "TN"], FP = m[, "FP"], FN = m[, "FN"],
                           TP = m[, "TP"], TPR = TPR, TNR = TNR, J = J,
                           empatado = empatado, row.names = NULL)
  list(tau = tau[elegido], J_max = J_max, eps = eps, candidatos = candidatos)
}

# --- Por categoria conjunta ---------------------------------------------------

# Formato largo: una fila por nivel de NIVELES_G, en ese orden, sin nombres de fila.
# Un grupo sin personas aparece con conteos 0 y tasas NA.
matrices_por_grupo <- function(clase, pred, g) {
  stopifnot(length(clase) == length(pred), length(g) == length(clase),
            is.factor(g), identical(levels(g), NIVELES_G))
  m <- t(vapply(NIVELES_G, function(lv) {
    en <- !is.na(g) & g == lv
    matriz_confusion(clase[en], pred[en])
  }, integer(4L)))
  TN <- unname(m[, "TN"]); FP <- unname(m[, "FP"])
  FN <- unname(m[, "FN"]); TP <- unname(m[, "TP"])
  n_1 <- TP + FN
  n_0 <- TN + FP
  data.frame(
    g   = factor(NIVELES_G, levels = NIVELES_G),
    TN  = TN, FP = FP, FN = FN, TP = TP,
    n   = n_1 + n_0, n_1 = n_1, n_0 = n_0,
    TPR = mapply(cociente, TP, n_1),
    FPR = mapply(cociente, FP, n_0),
    FNR = mapply(cociente, FN, n_1)
  )
}

# --- Resumen entre replicas ---------------------------------------------------

# r estimables, media, sd, mediana y percentiles P_PERCENTILES (tipo 7); descarta NA.
resumir <- function(x) {
  x <- x[!is.na(x)]
  r <- length(x)
  out <- c(r = r, media = NA_real_, sd = NA_real_, mediana = NA_real_,
           p2.5 = NA_real_, p97.5 = NA_real_)
  if (r == 0L) return(out)
  out[["media"]]   <- media_manual(x)
  if (r >= 2L) out[["sd"]] <- sd_manual(x)
  out[["mediana"]] <- percentil_tipo7(x, 0.5)
  out[c("p2.5", "p97.5")] <- percentil_tipo7(x, P_PERCENTILES)
  out
}
