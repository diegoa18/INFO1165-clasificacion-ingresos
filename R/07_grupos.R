# Grupos (nivel 4): errores por categoria conjunta sexo/raza en prueba.
# Solo lee output/replicas/*.rds; no reajusta ni reparticiona. Escribe output/tablas/ y output/figuras/.
# Contrato: docs/arquitectura.md, seccion 3 (reglas comunes de nivel 4 y 07_grupos.R).

if (!exists("media_manual")) source(file.path("R", "00_utilidades.R"))
if (!exists("RUTAS")) source(file.path("R", "00_config.R"))
if (!exists("resumir")) source(file.path("R", "04_umbral_metricas.R"))

# --- Lectura de replicas ------------------------------------------------------
archivos <- file.path(RUTAS[["replicas"]], sprintf("replica_%03d.rds", seq_len(B)))
faltan <- archivos[!file.exists(archivos)]
if (length(faltan) > 0L) stop("Faltan ", length(faltan), " replicas, p. ej. ", faltan[1L])
replicas <- lapply(archivos, readRDS)

# Tasa con NA si el denominador es 0.
tasa <- function(num, den) ifelse(den == 0, NA_real_, num / den)

# --- Grupos apilados (10 B filas) -------------------------------------------------
grupos <- do.call(rbind, lapply(replicas, function(r) cbind(b = r[["b"]], r[["grupos_prueba"]])))
rownames(grupos) <- NULL
stopifnot(nrow(grupos) == 10L * B, identical(levels(grupos$g), NIVELES_G))

for (r in replicas) {
  gp <- r[["grupos_prueba"]]
  stopifnot(
    identical(c(TN = sum(gp$TN), FP = sum(gp$FP), FN = sum(gp$FN), TP = sum(gp$TP)),
              r[["matriz_prueba"]]),
    sum(gp$n) == nrow(r[["prueba"]])
  )
}

# --- Resumen por grupo e indicador (30 filas) ------------------------------------
INDICADORES_G <- c(TPR = "n_1", FPR = "n_0", FNR = "n_1")
resumen_grupos <- do.call(rbind, lapply(NIVELES_G, function(lv) {
  sub <- grupos[grupos$g == lv, ]
  do.call(rbind, lapply(names(INDICADORES_G), function(ind) {
    den <- sub[[INDICADORES_G[[ind]]]]
    s   <- resumir(sub[[ind]])
    data.frame(g = factor(lv, levels = NIVELES_G), indicador = ind,
               denominador = INDICADORES_G[[ind]],
               den_min = min(den), den_mediana = percentil_tipo7(den, 0.5), den_max = max(den),
               r = as.integer(s[["r"]]), mediana = s[["mediana"]],
               p2.5 = s[["p2.5"]], p97.5 = s[["p97.5"]])
  }))
}))
rownames(resumen_grupos) <- NULL

# --- Replica 1: grupos y marginales ------------------------------------------------
# Tabla por categoria a partir de conteos; las tasas se calculan despues de sumar.
tabla_conteos <- function(etiqueta, nombre, TN, FP, FN, TP) {
  n_1 <- TP + FN
  n_0 <- TN + FP
  n   <- n_1 + n_0
  out <- data.frame(etiqueta, n = n, n_1 = n_1, n_0 = n_0, prevalencia = tasa(n_1, n),
                    TN = TN, FP = FP, FN = FN, TP = TP,
                    TPR = tasa(TP, n_1), FPR = tasa(FP, n_0), FNR = tasa(FN, n_1))
  names(out)[1L] <- nombre
  out
}

g1 <- replicas[[1L]][["grupos_prueba"]]
grupos_replica1 <- tabla_conteos(g1$g, "g", g1$TN, g1$FP, g1$FN, g1$TP)

partes  <- strsplit(as.character(g1$g), "/", fixed = TRUE)
sexo_g  <- vapply(partes, `[`, character(1), 1L)
raza_g  <- vapply(partes, `[`, character(1), 2L)
marginal <- function(clave, niveles, nombre) {
  suma <- function(col) vapply(niveles, function(v) sum(g1[[col]][clave == v]), integer(1))
  tabla_conteos(factor(niveles, levels = niveles), nombre,
                unname(suma("TN")), unname(suma("FP")), unname(suma("FN")), unname(suma("TP")))
}
marginales_sexo <- marginal(sexo_g, NIVELES_SEXO, "sexo")
marginales_raza <- marginal(raza_g, NIVELES_RAZA, "raza")

m1 <- replicas[[1L]][["matriz_prueba"]]
for (mg in list(marginales_sexo, marginales_raza)) {
  stopifnot(identical(c(TN = sum(mg$TN), FP = sum(mg$FP), FN = sum(mg$FN), TP = sum(mg$TP)), m1))
}

# --- Escritura de tablas ------------------------------------------------------------
dir.create(RUTAS[["tablas"]], showWarnings = FALSE, recursive = TRUE)
dir.create(RUTAS[["figuras"]], showWarnings = FALSE, recursive = TRUE)
TABLAS_07 <- c(grupos = "grupos_replicas.csv", resumen = "resumen_grupos.csv",
               replica1 = "grupos_replica1.csv", sexo = "marginales_sexo_replica1.csv",
               raza = "marginales_raza_replica1.csv")
escribir_csv(grupos,          file.path(RUTAS[["tablas"]], TABLAS_07[["grupos"]]))
escribir_csv(resumen_grupos,  file.path(RUTAS[["tablas"]], TABLAS_07[["resumen"]]))
escribir_csv(grupos_replica1, file.path(RUTAS[["tablas"]], TABLAS_07[["replica1"]]))
escribir_csv(marginales_sexo, file.path(RUTAS[["tablas"]], TABLAS_07[["sexo"]]))
escribir_csv(marginales_raza, file.path(RUTAS[["tablas"]], TABLAS_07[["raza"]]))

# --- Figura: mediana e intervalo p2.5-p97.5 por grupo ---------------------------------
png(file.path(RUTAS[["figuras"]], "tasas_grupos.png"), width = 1600, height = 1000, res = 150)
op <- par(mfrow = c(1, 3), mar = c(4.5, 14.5, 3, 0.8), oma = c(0, 0, 2.5, 0))
y <- rev(seq_along(NIVELES_G))                       # Female/White arriba
for (ind in names(INDICADORES_G)) {
  s <- resumen_grupos[resumen_grupos$indicador == ind, ]
  s <- s[match(NIVELES_G, as.character(s$g)), ]
  plot(NA, xlim = c(0, 1), ylim = c(0.5, length(NIVELES_G) + 0.5), yaxt = "n",
       xlab = paste(ind, "(proporción)"), ylab = "", main = ind)
  abline(v = seq(0, 1, 0.2), col = "grey90")
  segments(s$p2.5, y, s$p97.5, y, lwd = 2, col = "grey40")
  points(s$mediana, y, pch = 19, col = "navy")
  etiquetas <- sprintf("%s [%s = %g; r = %d]", NIVELES_G, INDICADORES_G[[ind]],
                       s$den_mediana, s$r)
  axis(2, at = y, labels = etiquetas, las = 1, cex.axis = 0.7, tick = FALSE)
}
mtext(sprintf(paste0("Tasas por categoría conjunta en prueba, resumen de B = %d réplicas: ",
                     "mediana (punto) e intervalo p2.5–p97.5 (segmento); ",
                     "entre corchetes, mediana del denominador y r estimables"), B),
      outer = TRUE, cex = 0.75, line = 0.8)
par(op)
invisible(dev.off())

# --- Verificaciones -----------------------------------------------------------------
stopifnot(
  file.exists(file.path(RUTAS[["tablas"]], TABLAS_07)),
  file.exists(file.path(RUTAS[["figuras"]], "tasas_grupos.png")),
  nrow(resumen_grupos) == 30L
)
