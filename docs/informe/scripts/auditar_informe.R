args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 2L)
setwd(args[1L])
out <- args[2L]
dir.create(out, recursive = TRUE, showWarnings = FALSE)
source('R/00_utilidades.R')
source('R/00_config.R')
source('R/03_modelo.R')
source('R/04_umbral_metricas.R')
tabla <- readRDS('data/processed/tabla_analitica.rds')
reps <- lapply(file.path('output/replicas', sprintf('replica_%03d.rds', 1:200)), readRDS)
r1 <- reps[[1L]]
entr <- tabla[r1$particion$indices$entrenamiento, ]
desc <- do.call(rbind, lapply(0:1, function(c) {
  x <- entr[entr$clase == c, ]
  data.frame(clase=c, n=nrow(x),
    pearson=sum((x$age-media_manual(x$age))*(x$hours_per_week-media_manual(x$hours_per_week))) /
      ((nrow(x)-1)*sd_manual(x$age)*sd_manual(x$hours_per_week)),
    horas_40=sum(x$hours_per_week==40), proporcion_40=sum(x$hours_per_week==40)/nrow(x),
    edad_min=min(x$age), edad_max=max(x$age), horas_min=min(x$hours_per_week), horas_max=max(x$hours_per_week))
}))
escribir_csv(desc, file.path(out, 'diagnostico_numerico.csv'))
dependencia <- do.call(rbind, lapply(0:1, function(c) {
  x <- entr[entr$clase == c, ]
  tab <- table(x$educacion,x$g)
  esperado <- outer(rowSums(tab),colSums(tab))/sum(tab)
  ok <- esperado>0
  chi <- sum((tab[ok]-esperado[ok])^2/esperado[ok])
  data.frame(clase=c,n=sum(tab),chi2_descriptivo=chi,
    V_Cramer=sqrt(chi/(sum(tab)*min(nrow(tab)-1,ncol(tab)-1))),
    celdas=nrow(tab)*ncol(tab),celdas_cero=sum(tab==0),esperadas_menor5=sum(esperado<5))
}))
escribir_csv(dependencia,file.path(out,'dependencia_educacion_g.csv'))
prop <- do.call(rbind,lapply(0:1,function(c) {
  x <- entr[entr$clase==c,]
  do.call(rbind,lapply(NIVELES_G,function(g) {
    xg <- x[x$g==g,]
    data.frame(clase=c,g=g,n_grupo=nrow(xg),HS_grad=sum(xg$education=='HS-grad')/nrow(xg),
      Bachelors=sum(xg$education=='Bachelors')/nrow(xg),
      Masters=sum(xg$education=='Masters')/nrow(xg),
      Doctorate=sum(xg$education=='Doctorate')/nrow(xg))
  }))
}))
escribir_csv(prop,file.path(out,'proporciones_educacion_g.csv'))
umbral <- do.call(rbind,lapply(reps,function(r) data.frame(b=r$b,tau=r$umbral$tau,
  candidatos=nrow(r$umbral$candidatos),empatados=sum(r$umbral$candidatos$empatado),
  J_val=r$umbral$J_max,J_prueba=r$indicadores_prueba[['J']],
  eps=r$umbral$eps)))
escribir_csv(umbral,file.path(out,'auditoria_umbrales.csv'))
ind <- read.csv('output/tablas/replicas_indicadores.csv')
base <- do.call(rbind,lapply(reps,function(r) {
  cl <- r$prueba$clase
  m <- matriz_confusion(cl,rep(0L,length(cl)))
  data.frame(b=r$b,exactitud_base=indicadores(m)[['exactitud']],
    BA_base=indicadores(m)[['BA']],exactitud_NB=r$indicadores_prueba[['exactitud']],
    BA_NB=r$indicadores_prueba[['BA']])
}))
escribir_csv(base,file.path(out,'referencia_clase0.csv'))
ver <- read.csv('output/tablas/verificaciones_replicas.csv')
resver <- data.frame(comprobacion=names(ver)[-1L],
  tipo=vapply(ver[-1L],function(x)if(is.logical(x))'logica' else 'error',character(1)),
  resultado=vapply(ver[-1L],function(x)if(is.logical(x)) as.character(sum(x)) else sprintf('%.17g',max(x)),character(1)))
write.csv(resver,file.path(out,'resumen_verificaciones.csv'),row.names=FALSE)
write.csv(data.frame(TN=r1$matriz_prueba[['TN']],FP=r1$matriz_prueba[['FP']],
  FN=r1$matriz_prueba[['FN']],TP=r1$matriz_prueba[['TP']]),file.path(out,'matriz_prueba_replica1.csv'),row.names=FALSE)
escribir_csv(data.frame(indicador=names(r1$indicadores_prueba),valor=as.numeric(r1$indicadores_prueba)),
  file.path(out,'indicadores_prueba_replica1.csv'))
writeLines(c(paste('Verificacion para informe: 2026-10-28'),capture.output(sessionInfo()),
  'Diagnosticos complementarios calculados desde el entrenamiento guardado de replica 1.',
  'El indice V de Cramer se presenta descriptivamente, sin prueba inferencial ni valor p.'),file.path(out,'entorno_auditoria.txt'))
cat('Diagnosticos numericos:\n');print(desc)
cat('Dependencia descriptiva:\n');print(dependencia)
cat('Todas las verificaciones logicas: ',all(as.matrix(ver[vapply(ver,is.logical,logical(1))])),'\n')
cat('Umbral min y max: ',range(umbral$tau),'\n')
cat('Exactitud base min/max: ',range(base$exactitud_base),'\n')
