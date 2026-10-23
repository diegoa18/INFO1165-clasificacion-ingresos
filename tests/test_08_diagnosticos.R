# Test de 08_diagnosticos.R: lee las tablas y figuras escritas por el script y las contrasta con los .rds.
# Requiere haber ejecutado R/05_replicas.R y R/08_diagnosticos.R.
# Ejecutar desde la raiz: Rscript tests/test_08_diagnosticos.R. No escribe archivos.

source(file.path("R", "00_utilidades.R"))
source(file.path("R", "00_config.R"))
source(file.path("R", "03_modelo.R"))

leer <- function(archivo) read.csv(file.path(RUTAS$tablas, archivo), stringsAsFactors = FALSE)
verif <- leer("verificaciones_replicas.csv")
traz  <- leer("trazabilidad.csv")
edg   <- leer("educacion_g_replica1.csv")
tabla <- readRDS(file.path(RUTAS$processed, "tabla_analitica.rds"))
r1    <- readRDS(file.path(RUTAS$replicas, "replica_001.rds"))

# Tolerancias del contrato ("Tolerancias numericas"): suma de K probabilidades <= K * EPS;
# contribuciones frente a D <= 16 * EPS * max(|l1|, |l0|, 1), persona a persona.
tol_prob    <- c(err_previa = 2, err_p_g_0 = K_G, err_p_g_1 = K_G, err_q_e_0 = K_E, err_q_e_1 = K_E) * EPS
tol_contrib <- function(l1, l0) 16 * EPS * pmax(abs(l1), abs(l0), 1)

# --- verificaciones_replicas.csv ----------------------------------------------------
logicas <- c("n_estrella_ok", "destinos_disjuntos", "todos_con_destino", "puntajes_finitos",
             "D_recalculado_identico", "contribuciones_ok", "matriz_suma_n", "grupos_suman_global")
errores <- names(tol_prob)
stopifnot(
  identical(names(verif), c("b", errores, "n_estrella_ok", "destinos_disjuntos", "todos_con_destino",
                            "puntajes_finitos", "D_recalculado_identico", "max_err_contribuciones",
                            "max_err_contribuciones_rel", "contribuciones_ok", "matriz_suma_n",
                            "grupos_suman_global")),
  nrow(verif) == B, identical(verif$b, seq_len(B)),
  all(vapply(verif[logicas], is.logical, logical(1))),
  all(as.matrix(verif[logicas])),                           # todas TRUE
  all(vapply(errores, function(e) all(verif[[e]] <= tol_prob[[e]]), logical(1))),
  all(verif$max_err_contribuciones_rel <= 16 * EPS)
)

# Contraste independiente con los .rds en algunas replicas: l0 y l1 recalculados con el
# modelo guardado y la tolerancia relativa persona a persona.
CONTRIB <- c("c_previa", "c_edad", "c_horas", "c_educacion", "c_g")
for (b in c(1L, 100L, B)) {
  r  <- readRDS(file.path(RUTAS$replicas, sprintf("replica_%03d.rds", b)))
  vb <- verif[verif$b == b, ]
  pr <- r$prueba
  pt <- puntuar(r$modelo, tabla[match(pr$id_original, tabla$id_original), ])
  err <- abs(rowSums(pr[CONTRIB]) - pr$D)
  stopifnot(
    identical(pt$D, pr$D),
    all(err <= tol_contrib(pt$l1, pt$l0)),
    vb$max_err_contribuciones == max(err),
    vb$max_err_contribuciones_rel == max(err / pmax(abs(pt$l1), abs(pt$l0), 1)),
    vb$err_p_g_1 == abs(sum(r$modelo$p_g["1", ]) - 1),
    sum(tabla$clase[r$particion$indices$entrenamiento] == 1L) == r$particion$n_estrella
  )
}

# --- educacion_g_replica1.csv ----------------------------------------------------------
entr <- tabla[r1$particion$indices$entrenamiento, ]
stopifnot(
  identical(names(edg), c("clase", "educacion", "g", "n")),
  nrow(edg) == 2L * K_E * K_G,
  identical(edg$clase, rep(0:1, each = K_E * K_G)),
  identical(edg$educacion, rep(rep(NIVELES_E, each = K_G), times = 2L)),
  identical(edg$g, rep(NIVELES_G, times = 2L * K_E)),
  sum(edg$n) == nrow(entr), any(edg$n == 0L),                # ceros incluidos
  # coincide con los conteos del modelo de la replica 1 al marginalizar
  all(tapply(edg$n, list(edg$clase, edg$g), sum)[, NIVELES_G] == r1$modelo$conteos_g),
  all(tapply(edg$n, list(edg$clase, edg$educacion), sum)[, NIVELES_E] == r1$modelo$conteos_e)
)

# --- trazabilidad.csv ------------------------------------------------------------------
v <- setNames(traz$valor, traz$indicador)
perfiles <- tabla[COLUMNAS_ADULT]
stopifnot(
  identical(traz$indicador, c("filas_tabla_analitica", "perfiles_distintos", "duplicados_excedentes",
                              "n_prueba", "prueba_coincide_entrenamiento", "prueba_coincide_validacion",
                              "prueba_coincide_alguno")),
  v[["filas_tabla_analitica"]] == nrow(tabla),
  v[["duplicados_excedentes"]] == sum(duplicated(perfiles)),   # contraste con duplicated()
  v[["perfiles_distintos"]] == nrow(unique(perfiles)),
  v[["filas_tabla_analitica"]] - v[["perfiles_distintos"]] == v[["duplicados_excedentes"]],
  v[["n_prueba"]] == length(r1$particion$indices$prueba),
  v[["prueba_coincide_alguno"]] <= v[["prueba_coincide_entrenamiento"]] + v[["prueba_coincide_validacion"]],
  v[["prueba_coincide_alguno"]] >= max(v[["prueba_coincide_entrenamiento"]], v[["prueba_coincide_validacion"]])
)

# --- Figuras ---------------------------------------------------------------------------
png_08 <- file.path(RUTAS$figuras, c("qq_replica1.png", "edad_horas_replica1.png"))
stopifnot(all(file.exists(png_08)), all(file.size(png_08) > 0))

cat("max err probabilidades:", format(max(as.matrix(verif[errores])), digits = 3),
    "| max err contribuciones: absoluto", format(max(verif$max_err_contribuciones), digits = 3),
    sprintf("; relativo %.2f EPS (limite 16 EPS)", max(verif$max_err_contribuciones_rel) / EPS), "\n")
print(traz, row.names = FALSE)
cat("\ntest_08_diagnosticos: OK\n")
