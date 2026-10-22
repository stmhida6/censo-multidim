library(dplyr)

cache <- readRDS("etl/r/salidas/llaves_censo2018.rds")
v <- cache$vivienda

cat("Lugares poblados distintos (global):", length(unique(v$LUGAR_POBLADO)), "\n")
cat("Combinaciones Departamento+Municipio+LugarPoblado distintas:",
    nrow(distinct(v, DEPARTAMENTO, MUNICIPIO, LUGAR_POBLADO)), "\n")
cat("Municipios distintos:", nrow(distinct(v, DEPARTAMENTO, MUNICIPIO)), "\n")
