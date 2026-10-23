# Replica 1 (nivel 4): evidencias de b = 1 para el informe.
# Lee data/processed/tabla_analitica.rds y output/replicas/replica_001.rds; no reajusta ni reparticiona.
# Escribe output/tablas/ y output/figuras/.
# Contrato: docs/arquitectura.md, seccion 3 (reglas comunes de nivel 4 y 09_replica1.R).

if (!exists("media_manual")) source(file.path("R", "00_utilidades.R"))
if (!exists("RUTAS")) source(file.path("R", "00_config.R"))
if (!exists("puntuar")) source(file.path("R", "03_modelo.R"))
if (!exists("indicadores")) source(file.path("R", "04_umbral_metricas.R"))

# --- Lectura ------------------------------------------------------------------------
tabla <- readRDS(file.path(RUTAS[["processed"]], "tabla_analitica.rds"))
archivo_r1 <- file.path(RUTAS[["replicas"]], "replica_001.rds")
if (!file.exists(archivo_r1)) stop("Falta ", archivo_r1)
r1 <- readRDS(archivo_r1)

modelo <- r1[["modelo"]]
umbral <- r1[["umbral"]]
clases <- c("0", "1")
ruta_tabla <- function(archivo) file.path(RUTAS[["tablas"]], archivo)
dir.create(RUTAS[["tablas"]], showWarnings = FALSE, recursive = TRUE)
dir.create(RUTAS[["figuras"]], showWarnings = FALSE, recursive = TRUE)

# --- Tamanos y parametros ---------------------------------------------------------------
tamanos <- r1[["particion"]][["tamanos"]]
tamanos$n_estrella <- r1[["particion"]][["n_estrella"]]
rownames(tamanos) <- NULL

parametros <- data.frame(
  clase       = as.integer(clases),
  n           = as.integer(modelo[["n"]]),
  previa      = unname(modelo[["previa"]]),
  mu_edad     = unname(modelo[["mu"]][, "edad"]),
  sigma_edad  = unname(modelo[["sigma"]][, "edad"]),
  mu_horas    = unname(modelo[["mu"]][, "horas"]),
  sigma_horas = unname(modelo[["sigma"]][, "horas"])
)

# --- Probabilidades categoricas (formato largo) -------------------------------------------
largo <- function(conteos, probs, niveles, nombre, nombre_p) {
  out <- data.frame(clase = rep(as.integer(clases), each = length(niveles)),
                    nivel = factor(rep(niveles, times = 2L), levels = niveles),
                    conteo = as.integer(t(conteos)),
                    n_c = as.integer(rep(modelo[["n"]], each = length(niveles))),
                    p = as.vector(t(probs)))
  names(out)[c(2L, 5L)] <- c(nombre, nombre_p)
  out
}
prob_g <- largo(modelo[["conteos_g"]], modelo[["p_g"]], NIVELES_G, "g", "p")
prob_e <- largo(modelo[["conteos_e"]], modelo[["q_e"]], NIVELES_E, "educacion", "q")

# --- Persona de ejemplo: primera de prueba por id_original ---------------------------------
prueba <- r1[["prueba"]]
p1     <- prueba[order(prueba$id_original)[1L], ]
fila   <- tabla[match(p1$id_original, tabla$id_original), ]
punt1  <- puntuar(modelo, fila)              # l0 y l1 con el modelo guardado
persona <- data.frame(
  id_original = p1$id_original, age = fila$age, hours_per_week = fila$hours_per_week,
  educacion = fila$educacion, g = fila$g, clase = p1$clase,
  p1[c("c_previa", "c_edad", "c_horas", "c_educacion", "c_g", "D")],
  l0 = punt1$l0, l1 = punt1$l1, tau = umbral[["tau"]], pred = p1$pred,
  row.names = NULL
)

# Densidad normal de la edad observada en cada clase.
z <- as.numeric(fila$age)
densidad <- data.frame(clase = as.integer(clases), z = z,
                       mu = unname(modelo[["mu"]][, "edad"]),
                       sigma = unname(modelo[["sigma"]][, "edad"]))
densidad$log_f <- log_densidad_normal(densidad$z, densidad$mu, densidad$sigma)
densidad$f     <- exp(densidad$log_f)
densidad$F     <- pnorm(densidad$z, densidad$mu, densidad$sigma)   # solo para interpretar

# --- Candidatos del umbral con indicadores de validacion ----------------------------------
cand <- umbral[["candidatos"]]
ind_cand <- t(vapply(seq_len(nrow(cand)), function(i) {
  indicadores(c(TN = cand$TN[i], FP = cand$FP[i], FN = cand$FN[i], TP = cand$TP[i]))
}, numeric(length(INDICADORES))))
candidatos <- data.frame(cand, ind_cand[, c("exactitud", "PPV", "F1", "FPR")],
                         J_max = umbral[["J_max"]], eps = umbral[["eps"]],
                         elegido = cand$tau == umbral[["tau"]], row.names = NULL)

# --- Escritura de tablas ------------------------------------------------------------------
escribir_csv(tamanos,    ruta_tabla("tamanos_replica1.csv"))
escribir_csv(parametros, ruta_tabla("parametros_replica1.csv"))
escribir_csv(densidad,   ruta_tabla("densidad_ejemplo_replica1.csv"))
escribir_csv(prob_g,     ruta_tabla("probabilidades_g_replica1.csv"))
escribir_csv(prob_e,     ruta_tabla("probabilidades_e_replica1.csv"))
escribir_csv(persona,    ruta_tabla("persona_replica1.csv"))
escribir_csv(candidatos, ruta_tabla("candidatos_replica1.csv"))

# --- Figura: curvas de validacion y corte +Inf aparte --------------------------------------
CURVAS <- c(exactitud = "black", TPR = "firebrick", TNR = "navy", PPV = "darkgreen",
            F1 = "darkorange", FPR = "purple")
fin <- is.finite(candidatos$tau)
inf <- candidatos[!fin, ]
png(file.path(RUTAS[["figuras"]], "curvas_validacion_replica1.png"), width = 1600, height = 1000, res = 150)
layout(matrix(1:2, nrow = 1L), widths = c(3.6, 1.4))
op <- par(mar = c(4.5, 4.5, 3, 1), oma = c(0, 0, 2, 0))
plot(NA, xlim = range(candidatos$tau[fin]), ylim = c(0, 1),
     xlab = "Corte τ (escala de D)", ylab = "Proporción", main = "Cortes finitos")
for (ind in names(CURVAS)) {
  lines(candidatos$tau[fin], candidatos[[ind]][fin], col = CURVAS[[ind]], lwd = 1.6)
}
abline(v = umbral[["tau"]], lty = 2, lwd = 1.5)
legend("topleft", inset = c(0.01, 0.07), bg = "white", box.col = "grey80", lwd = 2,
       col = c(CURVAS, "black"), cex = 0.85,
       legend = c(names(CURVAS), sprintf("τ_1 = %.4f", umbral[["tau"]])),
       lty = c(rep(1, length(CURVAS)), 2))

# Corte +Inf: los indicadores con el mismo valor se etiquetan juntos; PPV no es estimable.
par(mar = c(4.5, 1, 3, 1))
y_inf <- unlist(inf[names(CURVAS)])
est   <- !is.na(y_inf)
plot(rep(1, sum(est)), y_inf[est], xlim = c(0.7, 2.6), ylim = c(0, 1), pch = 19,
     col = CURVAS[est], cex = 1.4, xaxt = "n", yaxt = "n", xlab = "", ylab = "",
     main = "Corte +∞")
axis(1, at = 1, labels = "+∞")
for (v in unique(y_inf[est])) {
  text(1.1, v, sprintf("%s = %.3f", paste(names(y_inf)[est & y_inf == v], collapse = ", "), v),
       pos = 4, cex = 0.7, xpd = NA)
}
points(1, 0.5, pch = 4, cex = 1.4, col = CURVAS[["PPV"]])
text(1.1, 0.5, "PPV = NA\n(0 positivos predichos)", pos = 4, cex = 0.7, col = CURVAS[["PPV"]])
mtext("Indicadores en validación por corte: réplica 1, escala de proporción", outer = TRUE, cex = 0.9)
par(op)
invisible(dev.off())

# --- Verificaciones -----------------------------------------------------------------------
suma_g <- tapply(prob_g$p, prob_g$clase, sum)
suma_e <- tapply(prob_e$q, prob_e$clase, sum)
suma_c <- sum(unlist(persona[c("c_previa", "c_edad", "c_horas", "c_educacion", "c_g")]))
stopifnot(
  abs(sum(parametros$previa) - 1) <= 2 * EPS,
  all(abs(suma_g - 1) <= K_G * EPS), all(abs(suma_e - 1) <= K_E * EPS),
  identical(punt1$D, p1$D),
  abs(suma_c - persona$D) <= 16 * EPS * max(abs(persona$l1), abs(persona$l0), 1),
  persona$D == persona$l1 - persona$l0,
  persona$pred == as.integer(persona$D >= persona$tau),
  sum(candidatos$elegido) == 1L, candidatos$tau[candidatos$elegido] == umbral[["tau"]],
  all(abs(densidad$log_f - dnorm(densidad$z, densidad$mu, densidad$sigma, log = TRUE)) <=
        3 * EPS * pmax(1, abs(dnorm(densidad$z, densidad$mu, densidad$sigma, log = TRUE)))),
  file.exists(ruta_tabla(c("tamanos_replica1.csv", "parametros_replica1.csv",
                           "densidad_ejemplo_replica1.csv", "probabilidades_g_replica1.csv",
                           "probabilidades_e_replica1.csv", "persona_replica1.csv",
                           "candidatos_replica1.csv"))),
  file.exists(file.path(RUTAS[["figuras"]], "curvas_validacion_replica1.png"))
)
