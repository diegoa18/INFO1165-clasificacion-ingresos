# Replicas (nivel 3): bucle b = 1..B que combina particion, modelo y umbral.
# Lee data/processed/tabla_analitica.rds; escribe output/replicas/replica_XXX.rds,
# logs/semillas.csv y logs/sesion.txt. Contrato: docs/arquitectura.md, seccion 3.

if (!exists("media_manual")) source(file.path("R", "00_utilidades.R"))
if (!exists("RUTAS")) source(file.path("R", "00_config.R"))
if (!exists("particionar")) source(file.path("R", "02_particion.R"))
if (!exists("ajustar_nb")) source(file.path("R", "03_modelo.R"))
if (!exists("elegir_umbral")) source(file.path("R", "04_umbral_metricas.R"))

# Numero de replicas de esta ejecucion; se puede fijar antes de source() para pruebas.
if (!exists("B_EJECUCION")) B_EJECUCION <- B
stopifnot(is.numeric(B_EJECUCION), B_EJECUCION >= 1, B_EJECUCION <= B)

tabla <- readRDS(file.path(RUTAS$processed, "tabla_analitica.rds"))
dir.create(RUTAS$replicas, showWarnings = FALSE, recursive = TRUE)
dir.create(RUTAS$logs, showWarnings = FALSE, recursive = TRUE)

CONTRIBUCIONES <- c("c_previa", "c_edad", "c_horas", "c_educacion", "c_g")
semillas <- vector("list", B_EJECUCION)

for (b in seq_len(B_EJECUCION)) {
  semilla <- semilla_replica(b)

  particion <- particionar(tabla$clase, semilla)
  entr <- tabla[particion$indices$entrenamiento, ]
  val  <- tabla[particion$indices$validacion, ]
  pru  <- tabla[particion$indices$prueba, ]

  modelo <- ajustar_nb(entr)
  umbral <- elegir_umbral(puntuar(modelo, val)$D, val$clase)

  punt_pru <- puntuar(modelo, pru)
  pred     <- predecir(punt_pru$D, umbral$tau)

  prueba <- data.frame(id_original = pru$id_original, clase = pru$clase, g = pru$g,
                       punt_pru[, c(CONTRIBUCIONES, "D")], pred = pred, row.names = NULL)
  matriz_prueba <- matriz_confusion(pru$clase, pred)

  replica <- list(
    b                  = b,
    semilla            = semilla,
    particion          = particion,
    modelo             = modelo,
    umbral             = umbral,
    prueba             = prueba,
    matriz_prueba      = matriz_prueba,
    indicadores_prueba = indicadores(matriz_prueba),
    grupos_prueba      = matrices_por_grupo(pru$clase, pred, pru$g)
  )
  saveRDS(replica, file.path(RUTAS$replicas, sprintf("replica_%03d.rds", b)))

  semillas[[b]] <- data.frame(b = b, semilla = semilla, n_estrella = particion$n_estrella,
                              n_entrenamiento   = length(particion$indices$entrenamiento),
                              n_validacion      = length(particion$indices$validacion),
                              n_prueba          = length(particion$indices$prueba),
                              n_sin_seleccionar = length(particion$indices$sin_seleccionar))
}

semillas <- do.call(rbind, semillas)
stopifnot(identical(semillas$semilla, semilla_replica(seq_len(B_EJECUCION))),
          all(semillas$n_entrenamiento + semillas$n_validacion + semillas$n_prueba +
              semillas$n_sin_seleccionar == nrow(tabla)))
write.csv(semillas, file.path(RUTAS$logs, "semillas.csv"), row.names = FALSE)

writeLines(c(
  "== sessionInfo() ==", capture.output(sessionInfo()), "",
  "== RNGkind() ==", capture.output(RNGkind()), "",
  "== EPS ==", format(EPS, digits = 17), "",
  "== Replicas ==", paste("B_EJECUCION =", B_EJECUCION)
), file.path(RUTAS$logs, "sesion.txt"))
