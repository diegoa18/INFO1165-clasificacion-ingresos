# Test de 09_replica1.R: lee las tablas y la figura escritas por el script y las contrasta con replica_001.rds.
# Requiere haber ejecutado R/05_replicas.R y R/09_replica1.R.
# Ejecutar desde la raiz: Rscript tests/test_09_replica1.R. No escribe archivos.

source(file.path("R", "00_utilidades.R"))
source(file.path("R", "00_config.R"))
source(file.path("R", "03_modelo.R"))
source(file.path("R", "04_umbral_metricas.R"))

leer <- function(archivo) read.csv(file.path(RUTAS$tablas, archivo), stringsAsFactors = FALSE)
tamanos <- leer("tamanos_replica1.csv")
param   <- leer("parametros_replica1.csv")
dens    <- leer("densidad_ejemplo_replica1.csv")
prob_g  <- leer("probabilidades_g_replica1.csv")
prob_e  <- leer("probabilidades_e_replica1.csv")
persona <- leer("persona_replica1.csv")
cand    <- leer("candidatos_replica1.csv")

tabla <- readRDS(file.path(RUTAS$processed, "tabla_analitica.rds"))
r1    <- readRDS(file.path(RUTAS$replicas, "replica_001.rds"))
CONTRIB <- c("c_previa", "c_edad", "c_horas", "c_educacion", "c_g")

# --- Estructura del contrato ------------------------------------------------------------
stopifnot(
  identical(names(tamanos), c("clase", "N", "disp", "val", "pru", "entrenamiento", "sin_seleccionar", "n_estrella")),
  identical(names(param), c("clase", "n", "previa", "mu_edad", "sigma_edad", "mu_horas", "sigma_horas")),
  identical(names(dens), c("clase", "z", "mu", "sigma", "log_f", "f", "F")),
  identical(names(prob_g), c("clase", "g", "conteo", "n_c", "p")), nrow(prob_g) == 20L,
  identical(names(prob_e), c("clase", "educacion", "conteo", "n_c", "q")), nrow(prob_e) == 16L,
  identical(names(persona), c("id_original", "age", "hours_per_week", "educacion", "g", "clase",
                              CONTRIB, "D", "l0", "l1", "tau", "pred")), nrow(persona) == 1L,
  identical(names(cand), c("tau", "TN", "FP", "FN", "TP", "TPR", "TNR", "J", "empatado",
                           "exactitud", "PPV", "F1", "FPR", "J_max", "eps", "elegido")),
  identical(prob_g$g, rep(NIVELES_G, 2L)), identical(prob_e$educacion, rep(NIVELES_E, 2L))
)

# --- Coincidencia con el .rds ---------------------------------------------------------------
m <- r1$modelo
stopifnot(
  all(tamanos$n_estrella == r1$particion$n_estrella),
  identical(as.numeric(param$mu_edad), unname(m$mu[, "edad"])),
  identical(as.numeric(param$sigma_horas), unname(m$sigma[, "horas"])),
  identical(prob_g$p, as.vector(t(m$p_g))), identical(prob_e$q, as.vector(t(m$q_e))),
  identical(prob_g$conteo, as.integer(t(m$conteos_g))),
  persona$id_original == min(r1$prueba$id_original),
  identical(cand$tau, r1$umbral$candidatos$tau), nrow(cand) == nrow(r1$umbral$candidatos)
)

# --- Las sumas de probabilidades dan 1 (K * EPS) ---------------------------------------------
stopifnot(
  abs(sum(param$previa) - 1) <= 2 * EPS,
  all(abs(tapply(prob_g$p, prob_g$clase, sum) - 1) <= K_G * EPS),
  all(abs(tapply(prob_e$q, prob_e$clase, sum) - 1) <= K_E * EPS),
  all(prob_g$p == (prob_g$conteo + ALPHA) / (prob_g$n_c + ALPHA * K_G))
)

# --- Persona: contribuciones, D = l1 - l0 y regla de decision ----------------------------------
fila <- tabla[match(persona$id_original, tabla$id_original), ]
pt   <- puntuar(m, fila)
suma <- sum(unlist(persona[CONTRIB]))
stopifnot(
  abs(suma - persona$D) <= 16 * EPS * max(abs(persona$l1), abs(persona$l0), 1),
  persona$D == persona$l1 - persona$l0,
  persona$pred == as.integer(persona$D >= persona$tau),
  identical(pt$l0, persona$l0), identical(pt$l1, persona$l1), identical(pt$D, persona$D),
  persona$tau == r1$umbral$tau
)

# --- Candidatos: un unico elegido con tau = umbral[["tau"]] -------------------------------------
stopifnot(
  is.logical(cand$elegido), sum(cand$elegido) == 1L,
  cand$tau[cand$elegido] == r1$umbral$tau,
  cand$empatado[cand$elegido],
  all(cand$J_max == r1$umbral$J_max), all(cand$eps == EPS),
  is.infinite(cand$tau[nrow(cand)]), is.na(cand$PPV[nrow(cand)])      # +Inf: PPV no estimable
)
i_el <- indicadores(unlist(cand[cand$elegido, c("TN", "FP", "FN", "TP")]))
stopifnot(identical(unname(i_el[c("exactitud", "PPV", "F1", "FPR")]),
                    unname(unlist(cand[cand$elegido, c("exactitud", "PPV", "F1", "FPR")]))))

# --- Densidad: log_f frente a dnorm(log = TRUE) (3 terminos) ----------------------------------
ref <- dnorm(dens$z, dens$mu, dens$sigma, log = TRUE)
stopifnot(
  all(dens$z == persona$age),
  all(abs(dens$log_f - ref) <= 3 * EPS * pmax(1, abs(ref))),
  identical(dens$f, exp(dens$log_f)),
  identical(dens$log_f, log_densidad_normal(dens$z, dens$mu, dens$sigma)),
  identical(dens$log_f[2] - dens$log_f[1], persona$c_edad)
)

# --- Figura -----------------------------------------------------------------------------------
png_09 <- file.path(RUTAS$figuras, "curvas_validacion_replica1.png")
stopifnot(file.exists(png_09), file.size(png_09) > 0)

cat(sprintf("persona id %d: D = %.6f, tau = %.6f, pred = %d, clase = %d\n",
            persona$id_original, persona$D, persona$tau, persona$pred, persona$clase))
cat(sprintf("|suma contribuciones - D| = %.2f EPS relativo (limite 16)\n",
            abs(suma - persona$D) / max(abs(persona$l1), abs(persona$l0), 1) / EPS))
cat("\ntest_09_replica1: OK\n")
