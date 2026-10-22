# Configuracion (nivel 0): constantes, rutas y niveles de factores.
# Sin logica de computo ni efectos en disco. Contrato: docs/arquitectura.md, seccion 3.

# --- Rutas (relativas a la raiz del proyecto) ---------------------------------
RUTAS <- list(
  raw       = file.path("data", "raw"),
  processed = file.path("data", "processed"),
  replicas  = file.path("output", "replicas"),
  tablas    = file.path("output", "tablas"),
  figuras   = file.path("output", "figuras"),
  logs      = "logs"
)

# --- Replicas y semilla -------------------------------------------------------
B            <- 200L
SEMILLA_BASE <- 20261021L

# Semilla de la replica b: SEMILLA_BASE + b - 1.
semilla_replica <- function(b) SEMILLA_BASE + b - 1L

# --- Parametros numericos -----------------------------------------------------
ALPHA         <- 1
EPS           <- .Machine[["double.eps"]]
P_PERCENTILES <- c(0.025, 0.975)

# Particion: disponibles / validacion / prueba (dentro de cada clase).
PROPORCIONES <- c(disp = 0.8, val = 0.1, pru = 0.1)

# --- Columnas -----------------------------------------------------------------
# Nombres de adult.names con "_" en lugar de "-"; la columna 15 es el ingreso.
COLUMNAS_ADULT <- c(
  "age", "workclass", "fnlwgt", "education", "education_num",
  "marital_status", "occupation", "relationship", "race", "sex",
  "capital_gain", "capital_loss", "hours_per_week", "native_country",
  "income"
)

# Columnas cuyo faltante excluye a la persona.
COLUMNAS_REQUERIDAS <- c(
  "age", "hours_per_week", "education", "sex", "race", "education_num", "income"
)

# --- Clase --------------------------------------------------------------------
# Etiquetas de income en adult.data, indexadas por la clase 0/1.
ETIQUETAS_INGRESO <- c("0" = "<=50K", "1" = ">50K")

# --- Niveles de factores ------------------------------------------------------
# Filtro de poblacion: education-num >= EDUCACION_NUM_MIN.
EDUCACION_NUM_MIN <- 9L

# Orden de education-num (9 a 16).
NIVELES_E <- c(
  "HS-grad", "Some-college", "Assoc-voc", "Assoc-acdm",
  "Bachelors", "Masters", "Prof-school", "Doctorate"
)
NIVELES_SEXO <- c("Female", "Male")
NIVELES_RAZA <- c("White", "Black", "Asian-Pac-Islander", "Amer-Indian-Eskimo", "Other")

# Sexo externo, raza interno: "Female/White", ..., "Male/Other".
NIVELES_G <- paste(
  rep(NIVELES_SEXO, each = length(NIVELES_RAZA)),
  rep(NIVELES_RAZA, times = length(NIVELES_SEXO)),
  sep = "/"
)

K_E <- length(NIVELES_E)
K_G <- length(NIVELES_G)

# --- Indicadores --------------------------------------------------------------
INDICADORES <- c("exactitud", "TPR", "TNR", "PPV", "F1", "FPR", "FNR", "BA", "J")

# --- Destinos de la particion -------------------------------------------------
DESTINOS <- c("entrenamiento", "validacion", "prueba", "sin_seleccionar")

# --- Verificaciones -----------------------------------------------------------
stopifnot(
  is.integer(B), B == 200L,
  is.integer(SEMILLA_BASE), SEMILLA_BASE == 20261021L,
  semilla_replica(1L) == 20261021L,
  semilla_replica(B) == 20261220L,
  is.integer(semilla_replica(1L)),
  ALPHA == 1,
  EPS == 2^-52,
  abs(sum(PROPORCIONES) - 1) <= EPS,
  identical(names(PROPORCIONES), c("disp", "val", "pru")),
  length(COLUMNAS_ADULT) == 15L, !anyDuplicated(COLUMNAS_ADULT),
  all(COLUMNAS_REQUERIDAS %in% COLUMNAS_ADULT),
  identical(unname(ETIQUETAS_INGRESO), c("<=50K", ">50K")),
  length(NIVELES_E) == 8L, K_E == 8L, !anyDuplicated(NIVELES_E),
  length(NIVELES_SEXO) == 2L, length(NIVELES_RAZA) == 5L,
  length(NIVELES_G) == 10L, K_G == 10L, !anyDuplicated(NIVELES_G),
  identical(NIVELES_G[c(1L, 5L, 6L, 10L)],
            c("Female/White", "Female/Other", "Male/White", "Male/Other")),
  length(INDICADORES) == 9L,
  identical(DESTINOS, c("entrenamiento", "validacion", "prueba", "sin_seleccionar")),
  setequal(names(RUTAS), c("raw", "processed", "replicas", "tablas", "figuras", "logs"))
)
