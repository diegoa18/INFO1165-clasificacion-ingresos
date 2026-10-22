# Resumen (nivel 4): distribucion de tau_b e indicadores de prueba entre replicas.
# Solo lee output/replicas/*.rds; no reajusta ni reparticiona. Escribe output/tablas/ y output/figuras/.
# Contrato: docs/arquitectura.md, seccion 3 (reglas comunes de nivel 4 y 06_resumen.R).

if (!exists("media_manual")) source(file.path("R", "00_utilidades.R"))
if (!exists("RUTAS")) source(file.path("R", "00_config.R"))
if (!exists("resumir")) source(file.path("R", "04_umbral_metricas.R"))

# --- Lectura de replicas ------------------------------------------------------
archivos <- file.path(RUTAS[["replicas"]], sprintf("replica_%03d.rds", seq_len(B)))
faltan <- archivos[!file.exists(archivos)]
if (length(faltan) > 0L) stop("Faltan ", length(faltan), " replicas, p. ej. ", faltan[1L])
replicas <- lapply(archivos, readRDS)

# write.csv con precision completa: los numericos se escriben con 17 cifras significativas.
escribir_csv <- function(df, archivo) {
  num <- vapply(df, is.double, logical(1))
  df[num] <- lapply(df[num], function(x) ifelse(is.na(x), NA, sprintf("%.17g", x)))
  write.csv(df, file.path(RUTAS[["tablas"]], archivo), row.names = FALSE,
            quote = which(!num & !vapply(df, is.integer, logical(1))), na = "NA")
}

# --- Tabla por replica --------------------------------------------------------
por_replica <- do.call(rbind, lapply(replicas, function(r) {
  data.frame(b = r[["b"]], semilla = r[["semilla"]], tau = r[["umbral"]][["tau"]],
             as.list(r[["indicadores_prueba"]][INDICADORES]))
}))
stopifnot(identical(names(por_replica), c("b", "semilla", "tau", INDICADORES)),
          identical(por_replica$b, seq_len(B)))

# --- Cuadro resumen -----------------------------------------------------------
VARIABLES <- c("tau", INDICADORES)
resumen <- data.frame(
  variable = VARIABLES,
  escala   = ifelse(VARIABLES %in% c("tau", "J"), "original", "proporcion"),
  do.call(rbind, lapply(VARIABLES, function(v) resumir(por_replica[[v]]))),
  check.names = FALSE
)
resumen$r <- as.integer(resumen$r)

dir.create(RUTAS[["tablas"]], showWarnings = FALSE, recursive = TRUE)
dir.create(RUTAS[["figuras"]], showWarnings = FALSE, recursive = TRUE)
escribir_csv(por_replica, "replicas_indicadores.csv")
escribir_csv(resumen, "resumen_replicas.csv")

# --- Figuras ------------------------------------------------------------------
abrir_png <- function(archivo) {
  png(file.path(RUTAS[["figuras"]], archivo), width = 1600, height = 1000, res = 150)
}
fila_resumen <- function(v) resumen[resumen$variable == v, ]
subtitulo <- sprintf("Resumen de B = %d réplicas", B)

# Histograma de tau_b con media, mediana y percentiles.
abrir_png("hist_tau.png")
s <- fila_resumen("tau")
h <- hist(por_replica$tau, breaks = 20, plot = FALSE)
plot(h, col = "grey85", border = "white", ylim = c(0, 1.35 * max(h$counts)),
     main = "Umbral τ_b elegido en validación (escala original de D)",
     sub = paste0(subtitulo, "; r = ", s$r), xlab = "τ_b", ylab = "Frecuencia")
lineas <- c(s$media, s$mediana, s$p2.5, s$p97.5)
abline(v = lineas, col = c("firebrick", "navy", "darkorange", "darkorange"),
       lty = c(1, 2, 3, 3), lwd = 2)
legend("topleft", bg = "white", box.col = "white", lwd = 2,
       col = c("firebrick", "navy", "darkorange"), lty = c(1, 2, 3),
       legend = c(sprintf("media = %.4f", s$media), sprintf("mediana = %.4f", s$mediana),
                  sprintf("p2.5 = %.4f / p97.5 = %.4f", s$p2.5, s$p97.5)))
invisible(dev.off())

# Panel 2 x 4: mediana (linea continua) e intervalo p2.5-p97.5 (sombreado).
abrir_png("paneles_indicadores.png")
op <- par(mfrow = c(2, 4), mar = c(5.5, 4, 3, 1), oma = c(0, 0, 2, 0))
for (v in c("tau", "exactitud", "TPR", "TNR", "PPV", "F1", "BA", "J")) {
  s <- fila_resumen(v)
  x <- por_replica[[v]]
  h <- hist(x[!is.na(x)], breaks = 15, plot = FALSE)
  plot(h, col = "grey85", border = "white", xlab = "", ylab = "Frecuencia",
       main = if (v == "tau") "τ_b (validación)" else paste(v, "(prueba)"))
  rect(s$p2.5, 0, s$p97.5, max(h$counts), col = rgb(1, 0.55, 0, alpha = 0.25), border = NA)
  plot(h, col = "grey70", border = "white", add = TRUE)
  abline(v = s$mediana, col = "navy", lwd = 2)
  mtext(v, side = 1, line = 2.5, cex = 0.75)
  mtext(sprintf("r = %d; escala %s", s$r, s$escala), side = 1, line = 3.7, cex = 0.7)
}
mtext(paste0(subtitulo, ": mediana (línea) e intervalo p2.5–p97.5 (sombreado)"),
      outer = TRUE, cex = 0.9)
par(op)
invisible(dev.off())

# Boxplot de los indicadores en escala de proporcion (J queda fuera).
abrir_png("boxplot_indicadores.png")
prop <- c("exactitud", "TPR", "TNR", "PPV", "F1", "FPR", "FNR", "BA")
boxplot(por_replica[prop], ylim = c(0, 1), col = "grey85", las = 1,
        main = "Indicadores en prueba entre réplicas (escala de proporción)",
        sub = paste0(subtitulo, "; J se muestra en paneles_indicadores.png"),
        ylab = "Proporción")
invisible(dev.off())

# --- Verificaciones -----------------------------------------------------------
stopifnot(
  file.exists(file.path(RUTAS[["tablas"]], c("replicas_indicadores.csv", "resumen_replicas.csv"))),
  file.exists(file.path(RUTAS[["figuras"]],
                        c("hist_tau.png", "paneles_indicadores.png", "boxplot_indicadores.png")))
)
