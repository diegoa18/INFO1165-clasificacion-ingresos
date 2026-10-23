# Test de 05_replicas.R: lee las B replicas guardadas y recalcula algunas desde cero.
# Requiere haber ejecutado R/05_replicas.R con B_EJECUCION = B.
# Ejecutar desde la raiz: Rscript tests/test_05_replicas.R. No escribe archivos.

source(file.path("R", "00_utilidades.R"))
source(file.path("R", "00_config.R"))
source(file.path("R", "02_particion.R"))
source(file.path("R", "03_modelo.R"))
source(file.path("R", "04_umbral_metricas.R"))

tabla <- readRDS(file.path(RUTAS$processed, "tabla_analitica.rds"))
N     <- nrow(tabla)

# --- Archivos -------------------------------------------------------------------
esperados <- sprintf("replica_%03d.rds", seq_len(B))
presentes <- list.files(RUTAS$replicas, pattern = "^replica_[0-9]{3}\\.rds$")
stopifnot(length(presentes) == B, setequal(presentes, esperados))

semillas <- read.csv(file.path(RUTAS$logs, "semillas.csv"))
stopifnot(nrow(semillas) == B, identical(semillas$b, seq_len(B)),
          identical(semillas$semilla, semilla_replica(seq_len(B))),
          file.exists(file.path(RUTAS$logs, "sesion.txt")))

# --- Cada replica ---------------------------------------------------------------
campos <- c("b", "semilla", "particion", "modelo", "umbral", "prueba",
            "matriz_prueba", "indicadores_prueba", "grupos_prueba")
taus <- numeric(B)

for (b in seq_len(B)) {
  r   <- readRDS(file.path(RUTAS$replicas, esperados[b]))
  idx <- r$particion$indices
  todos <- unlist(idx, use.names = FALSE)
  ent_clase <- tabla$clase[idx$entrenamiento]
  stopifnot(
    identical(names(r), campos),
    identical(r$b, b), identical(r$semilla, semilla_replica(b)),
    identical(r$particion$semilla, semilla_replica(b)),
    # destinos disjuntos y union = total
    identical(names(idx), DESTINOS), !anyDuplicated(todos), length(todos) == N,
    # n_estrella por clase en entrenamiento
    sum(ent_clase == 0L) == r$particion$n_estrella,
    sum(ent_clase == 1L) == r$particion$n_estrella,
    semillas$n_estrella[b] == r$particion$n_estrella,
    # prueba coherente con la particion
    identical(r$prueba$id_original, tabla$id_original[idx$prueba]),
    identical(r$prueba$pred, predecir(r$prueba$D, r$umbral$tau)),
    identical(r$matriz_prueba, matriz_confusion(r$prueba$clase, r$prueba$pred)),
    nrow(r$grupos_prueba) == 10L,
    sum(r$grupos_prueba$TP) == r$matriz_prueba[["TP"]]
  )
  taus[b] <- r$umbral$tau
}

# --- Recalculo desde cero: identical() al .rds --------------------------------------
recalcular <- function(b) {
  semilla <- semilla_replica(b)
  particion <- particionar(tabla$clase, semilla)
  entr <- tabla[particion$indices$entrenamiento, ]
  val  <- tabla[particion$indices$validacion, ]
  pru  <- tabla[particion$indices$prueba, ]
  modelo <- ajustar_nb(entr)
  umbral <- elegir_umbral(puntuar(modelo, val)$D, val$clase)
  pp     <- puntuar(modelo, pru)
  pred   <- predecir(pp$D, umbral$tau)
  m      <- matriz_confusion(pru$clase, pred)
  list(b = b, semilla = semilla, particion = particion, modelo = modelo, umbral = umbral,
       prueba = data.frame(id_original = pru$id_original, clase = pru$clase, g = pru$g,
                           pp[, c("c_previa", "c_edad", "c_horas", "c_educacion", "c_g", "D")],
                           pred = pred, row.names = NULL),
       matriz_prueba = m, indicadores_prueba = indicadores(m),
       grupos_prueba = matrices_por_grupo(pru$clase, pred, pru$g))
}

for (b in c(1L, 100L, B)) {
  guardada <- readRDS(file.path(RUTAS$replicas, esperados[b]))
  stopifnot(identical(recalcular(b), guardada))
  cat(sprintf("replica %3d recalculada: identical() = TRUE\n", b))
}

# --- Valor de referencia de la bitacora ------------------------------------------
r1 <- readRDS(file.path(RUTAS$replicas, esperados[1]))
cat("\ntau_1 =", format(r1$umbral$tau, digits = 10), "\n")
stopifnot(abs(r1$umbral$tau - 0.0991012) < 5e-8)

cat("tau_b en", B, "replicas: min", format(min(taus), digits = 5), "| max", format(max(taus), digits = 5),
    "| distintos", length(unique(taus)), "\n")
cat("\ntest_05_replicas: OK\n")
