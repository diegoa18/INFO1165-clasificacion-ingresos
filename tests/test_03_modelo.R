# Test de 03_modelo.R con el entrenamiento y la validacion de la replica 1.
# Ejecutar desde la raiz: Rscript tests/test_03_modelo.R. No escribe archivos.

source(file.path("R", "00_utilidades.R"))
source(file.path("R", "00_config.R"))
source(file.path("R", "02_particion.R"))
source(file.path("R", "03_modelo.R"))

tabla <- readRDS(file.path(RUTAS$processed, "tabla_analitica.rds"))
part  <- particionar(tabla$clase, semilla_replica(1L))
entr  <- tabla[part$indices$entrenamiento, ]
val   <- tabla[part$indices$validacion, ]

modelo <- ajustar_nb(entr)
punt   <- puntuar(modelo, val)

# Tolerancias del contrato ("Tolerancias numericas"):
# - a mano frente a R base: n * EPS * max(1, |referencia|), n = terminos sumados (elemento a elemento);
# - suma de K probabilidades: K * EPS;
# - contribuciones frente a D: 16 * EPS * max(|l1|, |l0|, 1), persona a persona.
tol         <- function(ref, n = 1L) EPS * n * pmax(1, abs(ref))
tol_contrib <- function(l1, l0) 16 * EPS * pmax(abs(l1), abs(l0), 1)
N_TERM_LOGDENS <- 3L   # -log(sigma), -log(2 pi)/2, -(z - mu)^2 / (2 sigma^2)

# --- Parametros estimados -----------------------------------------------------
cat("== n y previa ==\n"); print(rbind(n = modelo$n, previa = modelo$previa))
cat("\n== mu ==\n"); print(modelo$mu)
cat("\n== sigma ==\n"); print(modelo$sigma)
cat("\n== conteos_e / q_e ==\n"); print(modelo$conteos_e); print(round(modelo$q_e, 5))
cat("\n== conteos_g / p_g ==\n"); print(t(modelo$conteos_g)); print(round(t(modelo$p_g), 5))
cat("\n== D en validacion (n =", nrow(punt), ") ==\n"); print(summary(punt$D))
cat("\nD >= 0 por clase real (validacion):\n")
print(table(clase = val$clase, D_no_negativo = punt$D >= 0))
cat("\nmedia de cada contribucion en validacion:\n")
print(round(colMeans(punt[, c("c_previa", "c_edad", "c_horas", "c_educacion", "c_g")]), 4))

# --- Diferencias observadas frente a R base -----------------------------------
dif <- c(media = 0, sd = 0, logdens = 0)
for (k in c("0", "1")) {
  sub <- entr[entr$clase == as.integer(k), ]
  for (j in c("age", "hours_per_week")) {
    x <- as.numeric(sub[[j]])
    dif["media"] <- max(dif["media"], abs(media_manual(x) - mean(x)))
    dif["sd"]    <- max(dif["sd"], abs(sd_manual(x) - sd(x)))
  }
  for (v in list(c("age", "edad"), c("hours_per_week", "horas"))) {
    z  <- as.numeric(val[[v[1]]])
    mu <- modelo$mu[k, v[2]]; s <- modelo$sigma[k, v[2]]
    dif["logdens"] <- max(dif["logdens"],
                          abs(log_densidad_normal(z, mu, s) - dnorm(z, mu, s, log = TRUE)))
  }
}
cat("\nmaxima diferencia absoluta frente a mean / sd / dnorm(log = TRUE):\n"); print(dif)

# --- Verificaciones -----------------------------------------------------------
n_c <- modelo$n
suma_contrib <- rowSums(punt[, c("c_previa", "c_edad", "c_horas", "c_educacion", "c_g")])

stopifnot(
  # estructura del contrato
  identical(names(modelo), c("n", "previa", "mu", "sigma", "conteos_g", "p_g", "conteos_e", "q_e")),
  identical(names(modelo$n), c("0", "1")), identical(names(modelo$previa), c("0", "1")),
  identical(dimnames(modelo$mu), list(c("0", "1"), c("edad", "horas"))),
  identical(dimnames(modelo$sigma), dimnames(modelo$mu)),
  identical(dimnames(modelo$p_g), list(c("0", "1"), NIVELES_G)),
  identical(dimnames(modelo$q_e), list(c("0", "1"), NIVELES_E)),
  identical(names(punt), c("l0", "l1", "c_previa", "c_edad", "c_horas", "c_educacion", "c_g", "D")),
  nrow(punt) == nrow(val),
  # media, sd y log-densidad frente a R base
  all(vapply(c("0", "1"), function(k) {
    sub <- entr[entr$clase == as.integer(k), ]
    ok <- TRUE
    for (j in c("age", "hours_per_week")) {
      x <- as.numeric(sub[[j]])
      ok <- ok && abs(media_manual(x) - mean(x)) <= tol(mean(x), length(x)) &&
                  abs(sd_manual(x) - sd(x))     <= tol(sd(x), length(x))
    }
    ok
  }, logical(1))),
  all(vapply(c("0", "1"), function(k) {
    all(vapply(list(c("age", "edad"), c("hours_per_week", "horas")), function(v) {
      z   <- as.numeric(val[[v[1]]])
      ref <- dnorm(z, modelo$mu[k, v[2]], modelo$sigma[k, v[2]], log = TRUE)
      all(abs(log_densidad_normal(z, modelo$mu[k, v[2]], modelo$sigma[k, v[2]]) - ref) <=
            tol(ref, N_TERM_LOGDENS))
    }, logical(1)))
  }, logical(1))),
  # Laplace: suma 1 por clase y formula exacta
  all(abs(rowSums(modelo$p_g) - 1) <= K_G * EPS),
  all(abs(rowSums(modelo$q_e) - 1) <= K_E * EPS),
  all(modelo$p_g == (modelo$conteos_g + ALPHA) / (n_c + ALPHA * K_G)),
  all(modelo$q_e == (modelo$conteos_e + ALPHA) / (n_c + ALPHA * K_E)),
  all(rowSums(modelo$conteos_g) == n_c), all(rowSums(modelo$conteos_e) == n_c),
  # previa de la replica 1
  all(modelo$n == part$n_estrella),
  all(modelo$previa == 0.5), abs(sum(modelo$previa) - 1) <= 2 * EPS,
  all(punt$c_previa == 0),
  # D = l1 - l0 = suma de las contribuciones
  all(is.finite(punt$l0)), all(is.finite(punt$l1)), all(is.finite(punt$D)),
  all(punt$D == punt$l1 - punt$l0),
  all(abs(suma_contrib - punt$D) <= tol_contrib(punt$l1, punt$l0))
)
cat("max |suma contribuciones - D| relativo:",
    sprintf("%.2f EPS (limite 16 EPS)\n",
            max(abs(suma_contrib - punt$D) / pmax(abs(punt$l1), abs(punt$l0), 1)) / EPS))

# --- Casos limite -------------------------------------------------------------
# Un nivel con 0 casos recibe alpha / (n_c + alpha K).
sin_nivel <- entr[entr$g != "Female/Other" & entr$educacion != "Doctorate", ]
m0 <- ajustar_nb(sin_nivel)
stopifnot(
  all(m0$conteos_g[, "Female/Other"] == 0),
  all(m0$p_g[, "Female/Other"] == ALPHA / (m0$n + ALPHA * K_G)),
  all(m0$q_e[, "Doctorate"] == ALPHA / (m0$n + ALPHA * K_E)),
  all(abs(rowSums(m0$p_g) - 1) <= K_G * EPS)
)

# Fallas esperadas: clase con menos de 2 personas y sigma = 0.
falla <- function(expr) inherits(tryCatch(expr, error = function(e) e), "error")
una_clase1 <- rbind(entr[entr$clase == 0L, ], entr[entr$clase == 1L, ][1L, ])
sigma_cero <- entr; sigma_cero$age[sigma_cero$clase == 1L] <- 40L
stopifnot(falla(ajustar_nb(una_clase1)), falla(ajustar_nb(sigma_cero)))

cat("\ntest_03_modelo: OK\n")
