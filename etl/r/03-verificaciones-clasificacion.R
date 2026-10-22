# Verifica con los microdatos reales las hipotesis que sustentan la clasificacion
# de variables (etl/clasificacion-variables.md): redundancias entre columnas,
# atributos constantes por lugar poblado y catalogos geograficos de 362 categorias.
#
# Ejecutar con:
#   Rscript etl/r/03-verificaciones-clasificacion.R

library(haven)
library(dplyr)
library(jsonlite)

# Carpeta de los .sav del INE: CENSO_MICRODATOS (la define etl/ejecutar-etl.sh desde .env) o datos/microdatos.
ruta_base <- Sys.getenv("CENSO_MICRODATOS", "datos/microdatos")
dir_salidas <- "etl/r/salidas"
dir.create(dir_salidas, showWarnings = FALSE, recursive = TRUE)

leer_sav <- function(archivo, columnas) {
  cat(sprintf("Leyendo %s (%d columnas)...\n", archivo, length(columnas)))
  read_sav(file.path(ruta_base, archivo), col_select = all_of(columnas)) %>%
    mutate(across(everything(), ~ as.numeric(zap_labels(.))))
}

llave_vivienda <- c("DEPARTAMENTO", "MUNICIPIO", "LUGAR_POBLADO", "NUM_VIVIENDA")
llave_hogar    <- c(llave_vivienda, "NUM_HOGAR")
resultado <- list()

# ---- VIVIENDA y HOGAR ----
vivienda <- leer_sav("VIVIENDA_BDP.sav",
                     c(llave_vivienda, "COD_MUNICIPIO", "AREA", "ZONA", "Long", "Lat"))
hogar <- leer_sav("HOGAR_BDP.sav",
                  c(llave_hogar, "AREA", "ZONA", "Long", "Lat", "TOTAL_PERS"))

resultado$lugares_poblados <- n_distinct(vivienda$LUGAR_POBLADO)
resultado$lugares_con_mas_de_un_AREA <- vivienda %>%
  group_by(LUGAR_POBLADO) %>% summarise(n = n_distinct(AREA)) %>% filter(n > 1) %>% nrow()
resultado$lugares_con_mas_de_una_ZONA <- vivienda %>%
  group_by(LUGAR_POBLADO) %>% summarise(n = n_distinct(ZONA)) %>% filter(n > 1) %>% nrow()
resultado$COD_MUNICIPIO_distinto_de_MUNICIPIO_mod_100 <-
  sum(vivienda$COD_MUNICIPIO != vivienda$MUNICIPIO %% 100)
resultado$vivienda_ZONA_distinta_de_COD_MUNICIPIO_y_no_es_depto_guatemala <-
  sum(vivienda$DEPARTAMENTO != 1 & vivienda$ZONA != vivienda$COD_MUNICIPIO)

cmp <- inner_join(
  hogar %>% select(all_of(llave_vivienda), Long_h = Long, Lat_h = Lat, AREA_h = AREA) %>% distinct(),
  vivienda %>% select(all_of(llave_vivienda), Long_v = Long, Lat_v = Lat, AREA_v = AREA),
  by = llave_vivienda)
resultado$hogar_vivienda_coordenadas_distintas <-
  sum(!(is.na(cmp$Long_h) & is.na(cmp$Long_v)) &
      (is.na(cmp$Long_h) != is.na(cmp$Long_v) | abs(cmp$Long_h - cmp$Long_v) > 1e-9), na.rm = TRUE)
resultado$hogar_vivienda_AREA_distinta <- sum(cmp$AREA_h != cmp$AREA_v)
resultado$rango_Long <- range(vivienda$Long, na.rm = TRUE)
resultado$rango_Lat <- range(vivienda$Lat, na.rm = TRUE)
rm(cmp, vivienda)

# ---- PERSONA ----
geo <- c("VIVEHABGEO", "LUGNACGEO", "RESCINGEO", "ESTUDIAGEO", "TRABAJAGEO")
persona <- leer_sav("PERSONA - BDP.sav",
                    c(llave_hogar, geo, "PCP17_A", "PCP17_B", "NIVGRADO"))

resultado$persona_VIVEHABGEO_distinto_de_MUNICIPIO <-
  sum(persona$VIVEHABGEO != persona$MUNICIPIO)

# TOTAL_PERS de HOGAR contra el conteo real de personas por hogar
conteo <- persona %>% count(across(all_of(llave_hogar)), name = "n_personas")
tp <- inner_join(hogar %>% select(all_of(llave_hogar), TOTAL_PERS), conteo, by = llave_hogar)
resultado$hogares_con_personas <- nrow(tp)
resultado$hogares_TOTAL_PERS_distinto_del_conteo <- sum(tp$TOTAL_PERS != tp$n_personas)
resultado$hogares_sin_personas <- nrow(anti_join(hogar, conteo, by = llave_hogar))
rm(tp, conteo, hogar)

# Catalogos geograficos de 362 categorias: codigos que no son municipios
municipios <- unique(persona$MUNICIPIO)
resultado$municipios_en_persona <- length(municipios)
for (v in geo) {
  cods <- sort(unique(persona[[v]][!is.na(persona[[v]])]))
  fuera <- setdiff(cods, municipios)
  resultado[[paste0(v, "_codigos_distintos")]] <- length(cods)
  resultado[[paste0(v, "_codigos_no_municipio")]] <- fuera
}

# NIVGRADO frente a PCP17_A (nivel) y PCP17_B (grado)
resultado$NIVGRADO_categorias <- n_distinct(persona$NIVGRADO, na.rm = TRUE)
resultado$combinaciones_NIVGRADO_PCP17A_PCP17B <-
  nrow(distinct(persona, NIVGRADO, PCP17_A, PCP17_B))
resultado$combinaciones_PCP17A_PCP17B <- nrow(distinct(persona, PCP17_A, PCP17_B))
resultado$NIVGRADO_con_mas_de_un_PCP17A <- persona %>%
  group_by(NIVGRADO) %>% summarise(n = n_distinct(PCP17_A)) %>% filter(n > 1) %>% nrow()

print(resultado)
write_json(resultado, file.path(dir_salidas, "verificaciones_clasificacion.json"),
           auto_unbox = TRUE, pretty = TRUE, na = "null")
cat("\nListo. Resultado en etl/r/salidas/verificaciones_clasificacion.json\n")
