# Modelo (nivel 2): Naive Bayes mixto, estimacion y puntajes.
# Solo depende de 00_config; no lee ni escribe archivos. Contrato: docs/arquitectura.md, seccion 3.

if (!exists("media_manual")) source(file.path("R", "00_utilidades.R"))
if (!exists("RUTAS")) source(file.path("R", "00_config.R"))

# --- Log-densidad -------------------------------------------------------------

# log f(z) = -log(sigma) - log(2 pi)/2 - (z - mu)^2 / (2 sigma^2), en escala logaritmica.
log_densidad_normal <- function(z, mu, sigma) {
  -log(sigma) - 0.5 * log(2 * pi) - (z - mu)^2 / (2 * sigma^2)
}

# --- Ajuste -------------------------------------------------------------------

ajustar_nb <- function(entrenamiento) {
  stopifnot(
    all(c("age", "hours_per_week", "educacion", "g", "clase") %in% names(entrenamiento)),
    identical(levels(entrenamiento$educacion), NIVELES_E),
    identical(levels(entrenamiento$g), NIVELES_G),
    all(entrenamiento$clase %in% c(0L, 1L))
  )
  clases <- c("0", "1")

  n <- setNames(numeric(2L), clases)
  for (k in clases) n[k] <- sum(entrenamiento$clase == as.integer(k))
  if (any(n < 2)) stop("Cada clase necesita al menos 2 personas en entrenamiento")

  previa <- n / sum(n)

  mu <- sigma <- matrix(NA_real_, 2L, 2L, dimnames = list(clases, c("edad", "horas")))
  conteos_g <- matrix(0, 2L, K_G, dimnames = list(clases, NIVELES_G))
  conteos_e <- matrix(0, 2L, K_E, dimnames = list(clases, NIVELES_E))

  for (k in clases) {
    sub <- entrenamiento[entrenamiento$clase == as.integer(k), ]
    edad  <- as.numeric(sub$age)
    horas <- as.numeric(sub$hours_per_week)
    mu[k, ]    <- c(media_manual(edad), media_manual(horas))
    sigma[k, ] <- c(sd_manual(edad), sd_manual(horas))
    # table() sobre el factor conserva los niveles con 0 casos.
    conteos_g[k, ] <- as.vector(table(sub$g))
    conteos_e[k, ] <- as.vector(table(sub$educacion))
  }
  if (any(sigma == 0)) stop("Desviacion estandar igual a 0 en entrenamiento (consultar al docente)")

  # Laplace: (conteo + alpha) / (n_c + alpha K).
  p_g <- (conteos_g + ALPHA) / (n + ALPHA * K_G)
  q_e <- (conteos_e + ALPHA) / (n + ALPHA * K_E)

  list(n = n, previa = previa, mu = mu, sigma = sigma,
       conteos_g = conteos_g, p_g = p_g, conteos_e = conteos_e, q_e = q_e)
}

# --- Puntajes -----------------------------------------------------------------

# l_c = log previa + log f_edad + log f_horas + log q_e + log p_g;
# cada contribucion c_* es termino de clase 1 menos termino de clase 0; D = l1 - l0.
puntuar <- function(modelo, datos) {
  stopifnot(
    identical(levels(datos$educacion), NIVELES_E),
    identical(levels(datos$g), NIVELES_G)
  )
  edad  <- as.numeric(datos$age)
  horas <- as.numeric(datos$hours_per_week)
  ie    <- as.integer(datos$educacion)
  ig    <- as.integer(datos$g)

  termino <- function(k) {
    list(
      previa    = rep(log(modelo$previa[[k]]), nrow(datos)),
      edad      = log_densidad_normal(edad,  modelo$mu[k, "edad"],  modelo$sigma[k, "edad"]),
      horas     = log_densidad_normal(horas, modelo$mu[k, "horas"], modelo$sigma[k, "horas"]),
      educacion = log(modelo$q_e[k, ie]),
      g         = log(modelo$p_g[k, ig])
    )
  }
  t0 <- termino("0")
  t1 <- termino("1")

  l0 <- t0$previa + t0$edad + t0$horas + t0$educacion + t0$g
  l1 <- t1$previa + t1$edad + t1$horas + t1$educacion + t1$g

  data.frame(
    l0          = l0,
    l1          = l1,
    c_previa    = t1$previa    - t0$previa,
    c_edad      = t1$edad      - t0$edad,
    c_horas     = t1$horas     - t0$horas,
    c_educacion = t1$educacion - t0$educacion,
    c_g         = t1$g         - t0$g,
    D           = l1 - l0
  )
}
