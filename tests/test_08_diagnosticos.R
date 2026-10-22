# Test de 08_diagnosticos.R: lee las tablas y figuras escritas por el script y las contrasta con los .rds.
# Requiere haber ejecutado R/05_replicas.R y R/08_diagnosticos.R.
# Ejecutar desde la raiz: Rscript tests/test_08_diagnosticos.R. No escribe archivos.

source(file.path("R", "00_utilidades.R"))
source(file.path("R", "00_config.R"))

leer <- function(archivo) read.csv(file.path(RUTAS$tablas, archivo), stringsAsFactors = FALSE)
verif <- leer("verificaciones_replicas.csv")
traz  <- leer("trazabilidad.csv")
edg   <- leer("educacion_g_replica1.csv")
tabla <- readRDS(file.path(RUTAS$processed, "tabla_analitica.rds"))
r1    <- readRDS(file.path(RUTAS$replicas, "replica_001.rds"))

# Tolerancias: sumas de a lo mas 10 probabilidades -> 16 EPS. Contribuciones: el error nace al
# restar l1 - l0, con |l_c| entre 12 y 20 (suma de 5 logaritmos), y l_c no se guarda en prueba;
# el maximo observado es 41 EPS, se exige < 128 EPS.
TOL_PROB    <- 16 * EPS
TOL_CONTRIB <- 128 * EPS

# --- verificaciones_replicas.csv ----------------------------------------------------
logicas <- c("n_estrella_ok", "destinos_disjuntos", "todos_con_destino", "puntajes_finitos",
             "matriz_suma_n", "grupos_suman_global")
errores <- c("err_previa", "err_p_g_0", "err_p_g_1", "err_q_e_0", "err_q_e_1")
stopifnot(
  identical(names(verif), c("b", errores[1:5], logicas[1:4], "max_err_contribuciones", logicas[5:6])),
  nrow(verif) == B, identical(verif$b, seq_len(B)),
  all(vapply(verif[logicas], is.logical, logical(1))),
  all(as.matrix(verif[logicas])),                           # todas TRUE
  all(as.matrix(verif[errores]) < TOL_PROB),
  all(verif$max_err_contribuciones < TOL_CONTRIB)
)

# Contraste independiente con los .rds en algunas replicas.
for (b in c(1L, 100L, B)) {
  r  <- readRDS(file.path(RUTAS$replicas, sprintf("replica_%03d.rds", b)))
  vb <- verif[verif$b == b, ]
  cc <- r$prueba[c("c_previa", "c_edad", "c_horas", "c_educacion", "c_g")]
  stopifnot(
    vb$err_p_g_1 == abs(sum(r$modelo$p_g["1", ]) - 1),
    vb$max_err_contribuciones == max(abs(rowSums(cc) - r$prueba$D)),
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
    "| max err contribuciones:", format(max(verif$max_err_contribuciones), digits = 3),
    sprintf("(%.0f EPS)", max(verif$max_err_contribuciones) / EPS), "\n")
print(traz, row.names = FALSE)
cat("\ntest_08_diagnosticos: OK\n")
