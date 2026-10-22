# Test de 02_particion.R con la tabla analitica y semilla_replica(1).
# Ejecutar desde la raiz: Rscript tests/test_02_particion.R. No escribe archivos.

source(file.path("R", "00_config.R"))
source(file.path("R", "02_particion.R"))

tabla <- readRDS(file.path(RUTAS$processed, "tabla_analitica.rds"))
clase <- tabla$clase
N     <- length(clase)

p1  <- particionar(clase, semilla_replica(1L))
p1b <- particionar(clase, semilla_replica(1L))
p2  <- particionar(clase, semilla_replica(2L))
idx <- p1$indices

prevalencia <- function(i) sum(clase[i]) / length(i)
P     <- prevalencia(seq_len(N))
todos <- unlist(idx, use.names = FALSE)

cat("n* =", p1$n_estrella, "\n\n")
cat("== tamanos ==\n"); print(p1$tamanos)
cat("\n== destino x clase ==\n"); print(addmargins(table(destino = p1$destino, clase = clase)))
cat("\nprevalencia tabla:", round(P, 5), "\n")
print(round(vapply(idx, prevalencia, numeric(1)), 5))

stopifnot(
  # estructura del contrato
  identical(names(p1), c("semilla", "n_estrella", "tamanos", "indices", "destino")),
  identical(names(idx), DESTINOS),
  identical(levels(p1$destino), DESTINOS), length(p1$destino) == N,
  all(vapply(idx, is.integer, logical(1))),
  !any(vapply(idx, is.unsorted, logical(1))),
  # destinos disjuntos y union = total
  !anyDuplicated(todos), length(todos) == N, setequal(todos, seq_len(N)),
  all(table(p1$destino) == lengths(idx)),
  # entrenamiento balanceado con n* por clase
  p1$n_estrella == 6077L,
  sum(clase[idx$entrenamiento] == 0L) == p1$n_estrella,
  sum(clase[idx$entrenamiento] == 1L) == p1$n_estrella,
  # validacion y prueba conservan la prevalencia
  abs(prevalencia(idx$validacion) - P) <= 1 / length(idx$validacion),
  abs(prevalencia(idx$prueba) - P)     <= 1 / length(idx$prueba),
  # tamanos consistentes
  sum(p1$tamanos$N) == N,
  all(p1$tamanos$disp + p1$tamanos$val + p1$tamanos$pru == p1$tamanos$N),
  # reproducibilidad
  identical(p1, p1b),
  !identical(idx$entrenamiento, p2$indices$entrenamiento),
  !identical(idx$validacion, p2$indices$validacion),
  !identical(idx$prueba, p2$indices$prueba),
  identical(RNGkind(), c("Mersenne-Twister", "Inversion", "Rejection"))
)

cat("\ntest_02_particion: OK\n")
