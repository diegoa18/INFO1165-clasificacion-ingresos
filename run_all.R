# Orquestador: ejecuta con source() los scripts de R/ en orden, sin logica propia.
# Ejecutar desde la raiz del proyecto.

source(file.path("R", "00_utilidades.R"))
source(file.path("R", "00_config.R"))
source(file.path("R", "01_datos.R"))
source(file.path("R", "02_particion.R"))
source(file.path("R", "03_modelo.R"))
source(file.path("R", "04_umbral_metricas.R"))
source(file.path("R", "05_replicas.R"))
source(file.path("R", "06_resumen.R"))
source(file.path("R", "07_grupos.R"))
source(file.path("R", "08_diagnosticos.R"))
source(file.path("R", "09_replica1.R"))
