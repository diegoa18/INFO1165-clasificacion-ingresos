# Diagnosticos (nivel 4): supuestos, verificaciones y trazabilidad.
# Lee data/processed/tabla_analitica.rds y output/replicas/*.rds; no reajusta ni reparticiona.
# Graficos con la replica 1; verificaciones en todas. Escribe output/tablas/ y output/figuras/.
# Contrato: docs/arquitectura.md, seccion 3 (reglas comunes de nivel 4 y 08_diagnosticos.R).

if (!exists("media_manual")) source(file.path("R", "00_utilidades.R"))
if (!exists("RUTAS")) source(file.path("R", "00_config.R"))

# --- Lectura ------------------------------------------------------------------------
tabla <- readRDS(file.path(RUTAS[["processed"]], "tabla_analitica.rds"))
N     <- nrow(tabla)

archivos <- file.path(RUTAS[["replicas"]], sprintf("replica_%03d.rds", seq_len(B)))
faltan <- archivos[!file.exists(archivos)]
if (length(faltan) > 0L) stop("Faltan ", length(faltan), " replicas, p. ej. ", faltan[1L])
replicas <- lapply(archivos, readRDS)

r1   <- replicas[[1L]]
entr <- tabla[r1[["particion"]][["indices"]][["entrenamiento"]], ]

dir.create(RUTAS[["tablas"]], showWarnings = FALSE, recursive = TRUE)
dir.create(RUTAS[["figuras"]], showWarnings = FALSE, recursive = TRUE)
abrir_png <- function(archivo) {
  png(file.path(RUTAS[["figuras"]], archivo), width = 1600, height = 1000, res = 150)
}
VARIABLES_NUM <- c(edad = "age", horas = "hours_per_week")

# --- Q-Q de la replica 1 (entrenamiento) ---------------------------------------------
abrir_png("qq_replica1.png")
op <- par(mfrow = c(2, 2), mar = c(4.5, 4.5, 3, 1), oma = c(0, 0, 2, 0))
for (v in names(VARIABLES_NUM)) {
  for (k in 0:1) {
    z <- entr[[VARIABLES_NUM[[v]]]][entr$clase == k]
    qqnorm(z, pch = 19, cex = 0.4, col = rgb(0, 0, 0.5, alpha = 0.25),
           main = sprintf("%s, clase %d (n = %d)", v, k, length(z)),
           xlab = "Cuantiles teóricos N(0, 1)", ylab = sprintf("%s observada", v))
    qqline(z, col = "firebrick", lwd = 2)
  }
}
mtext("Q–Q normal: réplica 1, entrenamiento, escala original (años y horas por semana)",
      outer = TRUE, cex = 0.9)
par(op)
invisible(dev.off())

# --- Edad frente a horas por clase (entrenamiento de la replica 1) --------------------
# Pearson a mano: sum((x - mx)(y - my)) / ((n - 1) sx sy).
pearson_manual <- function(x, y) {
  sum((x - media_manual(x)) * (y - media_manual(y))) /
    ((length(x) - 1L) * sd_manual(x) * sd_manual(y))
}
correlaciones <- c("0" = NA_real_, "1" = NA_real_)
abrir_png("edad_horas_replica1.png")
op <- par(mfrow = c(1, 2), mar = c(5.5, 4.5, 3, 1), oma = c(0, 0, 2, 0))
for (k in 0:1) {
  sub <- entr[entr$clase == k, ]
  x <- as.numeric(sub$age); y <- as.numeric(sub$hours_per_week)
  correlaciones[[as.character(k)]] <- pearson_manual(x, y)
  plot(x, y, pch = 19, cex = 0.5, col = rgb(0, 0, 0.5, alpha = 0.08),
       xlim = range(entr$age), ylim = range(entr$hours_per_week),
       main = sprintf("Clase %d (n = %d)", k, nrow(sub)),
       xlab = "Edad (años)", ylab = "Horas por semana",
       sub = sprintf("Correlación de Pearson (a mano) = %.4f", correlaciones[[as.character(k)]]))
}
mtext("Edad frente a horas: réplica 1, entrenamiento, escala original", outer = TRUE, cex = 0.9)
par(op)
invisible(dev.off())

# --- Educacion x G por clase (entrenamiento de la replica 1) ---------------------------
# Formato largo, clase -> educacion -> g, con ceros incluidos (2 x 8 x 10 filas).
educacion_g <- expand.grid(g = factor(NIVELES_G, levels = NIVELES_G),
                           educacion = factor(NIVELES_E, levels = NIVELES_E),
                           clase = c(0L, 1L), KEEP.OUT.ATTRS = FALSE)[, c("clase", "educacion", "g")]
conteo <- table(factor(entr$clase, levels = 0:1), entr$educacion, entr$g)
educacion_g$n <- as.integer(conteo[cbind(educacion_g$clase + 1L,
                                         as.integer(educacion_g$educacion),
                                         as.integer(educacion_g$g))])

# --- Verificaciones en todas las replicas ----------------------------------------------
CONTRIBUCIONES <- c("c_previa", "c_edad", "c_horas", "c_educacion", "c_g")
verificaciones <- do.call(rbind, lapply(replicas, function(r) {
  m   <- r[["modelo"]]
  idx <- r[["particion"]][["indices"]]
  todos <- unlist(idx, use.names = FALSE)
  pr  <- r[["prueba"]]
  gp  <- r[["grupos_prueba"]]
  ns  <- r[["particion"]][["n_estrella"]]
  ent_clase <- tabla$clase[idx[["entrenamiento"]]]
  data.frame(
    b                      = r[["b"]],
    err_previa             = abs(sum(m[["previa"]]) - 1),
    err_p_g_0              = abs(sum(m[["p_g"]]["0", ]) - 1),
    err_p_g_1              = abs(sum(m[["p_g"]]["1", ]) - 1),
    err_q_e_0              = abs(sum(m[["q_e"]]["0", ]) - 1),
    err_q_e_1              = abs(sum(m[["q_e"]]["1", ]) - 1),
    n_estrella_ok          = sum(ent_clase == 0L) == ns && sum(ent_clase == 1L) == ns &&
                             all(m[["n"]] == ns),
    destinos_disjuntos     = !anyDuplicated(todos),
    todos_con_destino      = length(todos) == N && setequal(todos, seq_len(N)) &&
                             !anyNA(r[["particion"]][["destino"]]),
    puntajes_finitos       = all(is.finite(pr$D)),
    max_err_contribuciones = max(abs(rowSums(pr[CONTRIBUCIONES]) - pr$D)),
    matriz_suma_n          = sum(r[["matriz_prueba"]]) == nrow(pr),
    grupos_suman_global    = identical(c(TN = sum(gp$TN), FP = sum(gp$FP), FN = sum(gp$FN),
                                         TP = sum(gp$TP)), r[["matriz_prueba"]])
  )
}))

# --- Trazabilidad: duplicados de perfil y coincidencias prueba vs. entrenamiento/validacion
# Perfil = las 15 columnas originales (sin id_original); NA cuenta como un valor mas.
clave_perfil <- function(d) do.call(paste, c(lapply(d[COLUMNAS_ADULT], as.character), sep = "\r"))
claves <- clave_perfil(tabla)
idx1   <- r1[["particion"]][["indices"]]
k_pru  <- claves[idx1[["prueba"]]]
en_ent <- k_pru %in% claves[idx1[["entrenamiento"]]]
en_val <- k_pru %in% claves[idx1[["validacion"]]]
perfiles_distintos <- length(unique(claves))

trazabilidad <- data.frame(
  indicador = c("filas_tabla_analitica", "perfiles_distintos", "duplicados_excedentes",
                "n_prueba", "prueba_coincide_entrenamiento", "prueba_coincide_validacion",
                "prueba_coincide_alguno"),
  valor = c(N, perfiles_distintos, N - perfiles_distintos,
            length(k_pru), sum(en_ent), sum(en_val), sum(en_ent | en_val))
)
trazabilidad$valor <- as.integer(trazabilidad$valor)

# --- Escritura y verificaciones -------------------------------------------------------
TABLAS_08 <- c("educacion_g_replica1.csv", "verificaciones_replicas.csv", "trazabilidad.csv")
escribir_csv(educacion_g,    file.path(RUTAS[["tablas"]], TABLAS_08[1L]))
escribir_csv(verificaciones, file.path(RUTAS[["tablas"]], TABLAS_08[2L]))
escribir_csv(trazabilidad,   file.path(RUTAS[["tablas"]], TABLAS_08[3L]))

stopifnot(
  nrow(educacion_g) == 2L * K_E * K_G, sum(educacion_g$n) == nrow(entr),
  nrow(verificaciones) == B, identical(verificaciones$b, seq_len(B)),
  all(as.matrix(verificaciones[vapply(verificaciones, is.logical, logical(1))])),
  file.exists(file.path(RUTAS[["tablas"]], TABLAS_08)),
  file.exists(file.path(RUTAS[["figuras"]], c("qq_replica1.png", "edad_horas_replica1.png")))
)
