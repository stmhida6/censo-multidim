# Comprueba con los microdatos la causa de los porcentajes de nulos del
# diccionario (etl/clasificacion-variables.md, seccion 5): para cada variable con
# muchos nulos, cruza su nulidad con la variable "disparadora" y con la edad,
# segun los saltos de la boleta censal.
#
# Ejecutar con:
#   Rscript etl/r/04-verificacion-nulos.R

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

# Devuelve, para una variable "objetivo", cuantos nulos y no nulos hay dentro y
# fuera de la condicion "disparadora" (TRUE = la boleta dice que la pregunta aplica).
cruce <- function(datos, objetivo, aplica, descripcion) {
  tabla <- datos %>%
    mutate(aplica = aplica, responde = !is.na(.data[[objetivo]])) %>%
    count(aplica, responde) %>%
    mutate(aplica = ifelse(aplica, "aplica", "no_aplica"),
           responde = ifelse(responde, "con_valor", "nulo"))
  list(variable = objetivo, regla = descripcion,
       conteos = setNames(as.list(tabla$n), paste(tabla$aplica, tabla$responde, sep = "__")))
}

resultado <- list()

# ---- VIVIENDA ----
v <- leer_sav("VIVIENDA_BDP.sav", c("PCV4", "PCV5"))
resultado$PCV5 <- cruce(v, "PCV5", v$PCV4 == 1, "aplica si PCV4 = 1 (ocupada)")
resultado$PCV4_distribucion <- as.list(table(v$PCV4, useNA = "ifany"))
rm(v)

# ---- HOGAR ----
h <- leer_sav("HOGAR_BDP.sav", c("PCH1", "PCH2", "PCH5", "PCH6", "PEI1", "PEI2"))
resultado$PCH2 <- cruce(h, "PCH2", h$PCH1 %in% c(1, 2), "aplica si PCH1 = 1 o 2 (propia)")
resultado$PCH6 <- cruce(h, "PCH6", h$PCH5 %in% 1:4, "aplica si PCH5 = 1 a 4 (tiene servicio)")
resultado$PEI2 <- cruce(h, "PEI2", h$PEI1 == 1, "aplica si PEI1 = 1 (hay emigrantes)")
rm(h)

# ---- PERSONA ----
cols <- c("PCP7", "PCP6", "PCP12", "PCP13", "PCP14", "PCP15", "PCP16_A", "PCP17_A",
          "PCP18", "PCP19", "PCP21", "PCP22", "PCP27", "PCP28", "PCP29", "PCP30_1D",
          "PCP34", "PCP35_A", "PCP36_A", "PCP39", "PEA", "PDESOC")
p <- leer_sav("PERSONA - BDP.sav", cols)

resultado$edad_distribucion <- list(min = min(p$PCP7), max = max(p$PCP7),
                                    menores_4 = sum(p$PCP7 < 4), menores_7 = sum(p$PCP7 < 7),
                                    menores_10 = sum(p$PCP7 < 10), menores_15 = sum(p$PCP7 < 15))

# Edad minima observada con valor, por variable (define la edad de aplicacion real)
edad_min_con_valor <- function(var) {
  x <- p$PCP7[!is.na(p[[var]])]
  if (length(x) == 0) NA else min(x)
}
resultado$edad_minima_con_valor <- sapply(
  c("PCP15", "PCP16_A", "PCP17_A", "PCP18", "PCP22", "PCP27", "PCP28", "PCP29",
    "PCP30_1D", "PCP34", "PCP35_A", "PEA"), edad_min_con_valor, USE.NAMES = TRUE)

resultado$PCP13 <- cruce(p, "PCP13", p$PCP12 == 1, "aplica si PCP12 = 1 (maya)")
resultado$PCP14 <- cruce(p, "PCP14", p$PCP12 %in% 1:4, "aplica si PCP12 = 1 a 4")
resultado$PCP19 <- cruce(p, "PCP19", p$PCP18 == 1, "aplica si PCP18 = 1 (asiste)")
resultado$PCP21 <- cruce(p, "PCP21", p$PCP18 == 2, "aplica si PCP18 = 2 (no asiste)")
resultado$PCP21_por_PCP18 <- as.list(table(PCP18 = p$PCP18, PCP21_con_valor = !is.na(p$PCP21),
                                            useNA = "ifany"))
# PCP21 solo tiene valor en una parte de quienes no asisten: se busca el patron por edad
no_asiste <- p %>% filter(PCP18 == 2) %>%
  mutate(tramo = cut(PCP7, c(-1, 3, 6, 12, 17, 24, 34, 49, 64, 200)),
         con_valor = !is.na(PCP21))
resultado$PCP21_por_tramo_de_edad_entre_quienes_no_asisten <- no_asiste %>%
  count(tramo, con_valor) %>% split(.$tramo) %>%
  lapply(function(d) setNames(as.list(d$n), ifelse(d$con_valor, "con_valor", "nulo")))
resultado$PCP21_por_PCP17A_entre_quienes_no_asisten <- no_asiste %>%
  count(PCP17_A, con_valor) %>% split(.$PCP17_A) %>%
  lapply(function(d) setNames(as.list(d$n), ifelse(d$con_valor, "con_valor", "nulo")))
rm(no_asiste)

resultado$PCP28 <- cruce(p, "PCP28", p$PCP27 == 2, "aplica si PCP27 = 2 (no trabajo)")
resultado$PCP29 <- cruce(p, "PCP29", p$PCP28 == 7, "aplica si PCP28 = 7 (no trabajo)")
resultado$PCP30_1D <- cruce(p, "PCP30_1D", p$PCP27 == 1 | p$PCP28 %in% 1:6,
                            "aplica si PCP27 = 1 o PCP28 = 1 a 6 (trabajo)")
resultado$PCP35_A <- cruce(p, "PCP35_A", p$PCP6 == 2 & p$PCP7 >= 10, "aplica a mujeres de 10 anios o mas")
resultado$PCP36_A <- cruce(p, "PCP36_A", p$PCP6 == 2 & p$PCP7 >= 10 & p$PCP35_A > 0,
                           "aplica a mujeres de 10+ con hijos nacidos vivos")
resultado$PCP39 <- cruce(p, "PCP39", p$PCP6 == 2 & p$PCP7 >= 10 & p$PCP35_A > 0,
                         "aplica a mujeres de 10+ con hijos nacidos vivos")
resultado$PCP34 <- cruce(p, "PCP34", p$PCP7 >= 10, "aplica a personas de 10 anios o mas")
resultado$PCP22 <- cruce(p, "PCP22", p$PCP7 >= 7, "aplica a personas de 7 anios o mas")
resultado$PEA <- cruce(p, "PEA", p$PCP7 >= 15, "aplica a personas de 15 anios o mas")
resultado$PDESOC <- cruce(p, "PDESOC", p$PCP29 %in% 1:2, "aplica si PCP29 = 1 o 2 (busco trabajo)")

print(resultado)
write_json(resultado, file.path(dir_salidas, "verificacion_nulos.json"),
           auto_unbox = TRUE, pretty = TRUE, na = "null")
cat("\nListo. Resultado en etl/r/salidas/verificacion_nulos.json\n")
