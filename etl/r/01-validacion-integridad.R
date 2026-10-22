# Valida la jerarquia Vivienda -> Hogar -> Persona y el enlace de Migracion
# en los microdatos oficiales del Censo 2018 (XII Censo Nacional de Poblacion
# y VII de Vivienda), como insumo para el plan de ETL (etl/plan-etl.md).
#
# Ademas de la integridad referencial, explica los casos de Persona sin Hogar
# a partir de PCV1 (tipo de vivienda): determinan si el FK Hogar en
# Hechos.CensoPoblacion debe ser nullable.
#
# No carga los ~85 campos de PERSONA: solo lee las columnas llave (mas PCV1
# de Vivienda), para que el proceso sea viable en una laptop de 16 GB
# compartida con Docker/SQL Server.
#
# Ejecutar con:
#   Rscript etl/r/01-validacion-integridad.R

library(haven)
library(dplyr)
library(jsonlite)

# Carpeta de los .sav del INE: CENSO_MICRODATOS (la define etl/ejecutar-etl.sh desde .env) o datos/microdatos.
ruta_base <- Sys.getenv("CENSO_MICRODATOS", "datos/microdatos")
dir_salidas <- "etl/r/salidas"
dir.create(dir_salidas, showWarnings = FALSE, recursive = TRUE)

leer_sav <- function(archivo, columnas) {
  ruta <- file.path(ruta_base, archivo)
  cat(sprintf("Leyendo %s (columnas: %s)...\n", archivo, paste(columnas, collapse = ", ")))
  read_sav(ruta, col_select = all_of(columnas))
}

llave_vivienda        <- c("DEPARTAMENTO", "MUNICIPIO", "LUGAR_POBLADO", "NUM_VIVIENDA")
llave_hogar           <- c(llave_vivienda, "NUM_HOGAR")
llave_hogar_sin_lugar <- c("DEPARTAMENTO", "MUNICIPIO", "NUM_VIVIENDA", "NUM_HOGAR")

vivienda <- leer_sav("VIVIENDA_BDP.sav", c(llave_vivienda, "PCV1")) %>%
  mutate(PCV1_ETIQUETA = as_factor(PCV1)) %>%
  mutate(across(all_of(c(llave_vivienda, "PCV1")), ~ as.numeric(zap_labels(.))))

hogar <- leer_sav("HOGAR_BDP.sav", llave_hogar) %>%
  mutate(across(everything(), ~ as.numeric(zap_labels(.))))

persona <- leer_sav("PERSONA - BDP.sav", c(llave_hogar, "PCP1")) %>%
  mutate(across(everything(), ~ as.numeric(zap_labels(.))))

migracion <- leer_sav("MIGRACION_BDP.sav", c(llave_hogar_sin_lugar, "ID_EMIGRACION")) %>%
  mutate(across(everything(), ~ as.numeric(zap_labels(.))))

# Personas sin hogar asociado, y a que tipo de vivienda pertenecen (PCV1).
huerfanos_persona <- anti_join(persona, hogar, by = llave_hogar)

viviendas_huerfanas_por_tipo <- huerfanos_persona %>%
  distinct(across(all_of(llave_vivienda))) %>%
  inner_join(vivienda, by = llave_vivienda) %>%
  count(PCV1_ETIQUETA, name = "viviendas")

personas_huerfanas_por_tipo <- huerfanos_persona %>%
  inner_join(vivienda, by = llave_vivienda) %>%
  count(PCV1_ETIQUETA, name = "personas")

resultado <- list(
  vivienda_filas = nrow(vivienda),
  vivienda_llaves_unicas = nrow(distinct(vivienda, across(all_of(llave_vivienda)))),

  hogar_filas = nrow(hogar),
  hogar_llaves_unicas = nrow(distinct(hogar, across(all_of(llave_hogar)))),

  persona_filas = nrow(persona),
  persona_llaves_unicas = nrow(distinct(persona, across(all_of(c(llave_hogar, "PCP1"))))),

  migracion_filas = nrow(migracion),
  migracion_llaves_unicas = nrow(distinct(migracion, across(all_of(c(llave_hogar_sin_lugar, "ID_EMIGRACION"))))),

  # Integridad referencial hacia el nivel superior
  hogar_sin_vivienda = nrow(anti_join(hogar, vivienda, by = llave_vivienda)),
  persona_sin_hogar = nrow(huerfanos_persona),
  persona_sin_hogar_viviendas_por_tipo = viviendas_huerfanas_por_tipo,
  persona_sin_hogar_personas_por_tipo = personas_huerfanas_por_tipo,
  migracion_sin_hogar = nrow(anti_join(migracion, hogar, by = llave_hogar_sin_lugar)),

  # Viviendas sin hogar (posibles viviendas vacantes o desocupadas)
  vivienda_sin_hogar = nrow(anti_join(vivienda, hogar, by = llave_vivienda))
)

print(resultado)

write_json(resultado, file.path(dir_salidas, "validacion_integridad.json"),
           auto_unbox = TRUE, pretty = TRUE)

saveRDS(list(vivienda = vivienda, hogar = hogar, persona = persona, migracion = migracion),
        file.path(dir_salidas, "llaves_censo2018.rds"))

cat("\nListo. Resultado en etl/r/salidas/validacion_integridad.json\n")
