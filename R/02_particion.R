# Particion (nivel 2): particionar(clase, semilla) -> indices por destino.
# Solo depende de 00_config; no lee ni escribe archivos. Contrato: docs/arquitectura.md, seccion 3.

if (!exists("RUTAS")) source(file.path("R", "00_config.R"))

DESTINOS <- c("entrenamiento", "validacion", "prueba", "sin_seleccionar")

# Particion estratificada por clase con entrenamiento balanceado (n* por clase).
# Indices = posiciones de fila en la tabla analitica (integer, crecientes).
# Orden de consumo del generador: permutacion de c = 0 y luego c = 1;
# despues sorteo de n* entre disponibles de c = 0 y luego c = 1.
particionar <- function(clase, semilla) {
  stopifnot(is.integer(clase), all(clase %in% c(0L, 1L)), length(semilla) == 1L)
  set.seed(semilla, kind = "Mersenne-Twister", normal.kind = "Inversion",
           sample.kind = "Rejection")

  clases <- c("0", "1")
  disp <- val <- pru <- entr <- sin_sel <- setNames(vector("list", 2L), clases)
  N <- n_disp <- n_val <- setNames(integer(2L), clases)

  for (k in clases) {
    x <- which(clase == as.integer(k))
    N[k]     <- length(x)
    n_disp[k] <- as.integer(floor(PROPORCIONES[["disp"]] * N[k]))
    n_val[k]  <- as.integer(floor(PROPORCIONES[["val"]] * N[k]))
    perm <- x[sample.int(length(x), length(x))]
    disp[[k]] <- perm[seq_len(n_disp[k])]
    val[[k]]  <- perm[n_disp[k] + seq_len(n_val[k])]
    pru[[k]]  <- perm[-seq_len(n_disp[k] + n_val[k])]
  }

  n_estrella <- min(n_disp)

  for (k in clases) {
    elegidos     <- disp[[k]][sample.int(length(disp[[k]]), n_estrella)]
    entr[[k]]    <- elegidos
    sin_sel[[k]] <- setdiff(disp[[k]], elegidos)
  }

  indices <- list(
    entrenamiento   = sort(c(entr[["0"]], entr[["1"]])),
    validacion      = sort(c(val[["0"]], val[["1"]])),
    prueba          = sort(c(pru[["0"]], pru[["1"]])),
    sin_seleccionar = sort(c(sin_sel[["0"]], sin_sel[["1"]]))
  )

  for (d in c("validacion", "prueba")) {
    if (!all(c(0L, 1L) %in% clase[indices[[d]]])) stop("El destino ", d, " no contiene ambas clases")
  }

  destino <- character(length(clase))
  for (d in DESTINOS) destino[indices[[d]]] <- d
  destino <- factor(destino, levels = DESTINOS)

  tamanos <- data.frame(
    clase           = as.integer(clases),
    N               = unname(N),
    disp            = unname(n_disp),
    val             = unname(n_val),
    pru             = unname(N - n_disp - n_val),
    entrenamiento   = n_estrella,
    sin_seleccionar = unname(n_disp) - n_estrella,
    row.names       = clases
  )

  list(semilla = semilla, n_estrella = n_estrella, tamanos = tamanos,
       indices = indices, destino = destino)
}
