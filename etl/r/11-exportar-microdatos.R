# Exporta los microdatos del censo a CSV (UTF-8) para cargarlos a la zona de
# preparacion (stage) de SQL Server con BULK INSERT.
#
# - Solo se exportan las columnas necesarias: se omiten las que
#   etl/clasificacion-variables.md documenta como redundantes (COD_MUNICIPIO,
#   VIVEHABGEO, PCP17_A, coordenadas de Hogar, etc.).
# - Los valores se escriben como numeros (sin etiquetas); los nulos, como campo vacio.
# - PERSONA (14.9 millones de filas) se lee y escribe por bloques para no agotar la memoria.
# - Los datos de cada lugar poblado (nombre, municipio, zona) se exportan aparte en lugarpoblado.csv.
# - Tambien genera datos/csv/jerarquias.csv (hijo, padre, personas) para NIVGRADO -> PCP17_A,
#   PCP30_2D -> PCP30_1D y PCP32_2D -> PCP32_1D.
#
# Ejecutar con:
#   Rscript etl/r/11-exportar-microdatos.R

library(haven)
library(data.table)
source("etl/r/utilidades-exportacion.R")

# Carpeta de los .sav del INE: CENSO_MICRODATOS (la define etl/ejecutar-etl.sh desde .env) o datos/microdatos.
ruta_base <- Sys.getenv("CENSO_MICRODATOS", "datos/microdatos")
dir_csv <- "datos/csv"
dir.create(dir_csv, recursive = TRUE, showWarnings = FALSE)
tamano_bloque <- 2e6

marca <- function(...) cat(format(Sys.time(), "%H:%M:%S"), sprintf(...), "\n")

a_numerico <- function(d) {
  setDT(d)
  for (j in names(d)) {
    if (!is.character(d[[j]])) set(d, j = j, value = as.numeric(zap_labels(d[[j]])))
  }
  d
}

exportar_completo <- function(archivo, columnas, salida) {
  marca("Leyendo %s...", archivo)
  d <- a_numerico(read_sav(file.path(ruta_base, archivo), col_select = all_of(columnas)))
  setcolorder(d, columnas)
  fwrite(d, file.path(dir_csv, salida), na = "")
  marca("%s: %s filas, %d columnas", salida, format(nrow(d), big.mark = ","), ncol(d))
  nrow(d)
}

conteos <- list()

# VIVIENDA: los datos del lugar poblado (nombre, municipio, zona) van en su propio CSV, una fila por
# lugar; como lleva texto con acentos se escribe en UTF-16LE (ver utilidades-exportacion.R).
marca("Leyendo VIVIENDA_BDP.sav...")
viv <- a_numerico(read_sav(file.path(ruta_base, "VIVIENDA_BDP.sav"),
  col_select = all_of(c("DEPARTAMENTO", "MUNICIPIO", "LUGAR_POBLADO", "NOMBRE_LUGAR_POBLADO",
                        "NUM_VIVIENDA", "ZONA", "AREA", "PCV1", "PCV2", "PCV3", "PCV4", "PCV5", "Long", "Lat"))))
lugares <- unique(viv[, .(LUGAR_POBLADO, DEPARTAMENTO, MUNICIPIO, ZONA, NOMBRE_LUGAR_POBLADO)])
escribir_csv_utf16(lugares, file.path(dir_csv, "lugarpoblado.csv"))
marca("lugarpoblado.csv: %s filas", format(nrow(lugares), big.mark = ","))
viv[, c("DEPARTAMENTO", "MUNICIPIO", "NOMBRE_LUGAR_POBLADO", "ZONA") := NULL]
setcolorder(viv, c("LUGAR_POBLADO", "NUM_VIVIENDA", "AREA", "PCV1", "PCV2", "PCV3", "PCV4", "PCV5", "Long", "Lat"))
fwrite(viv, file.path(dir_csv, "vivienda.csv"), na = "")
conteos$vivienda <- nrow(viv)
marca("vivienda.csv: %s filas, %d columnas", format(nrow(viv), big.mark = ","), ncol(viv))
rm(viv)

conteos$hogar <- exportar_completo("HOGAR_BDP.sav",
  c("LUGAR_POBLADO", "NUM_VIVIENDA", "NUM_HOGAR", "PCH1", "PCH2", "PCH3", "PCH4", "PCH5",
    "PCH6", "PCH7", "PCH8", paste0("PCH9_", LETTERS[1:13]), "PCH10", "PCH11", "PCH12",
    "PCH13", "PCH14", "PCH15", "PEI1", "PEI2", "PEI2_E", "TOTAL_PERS"),
  "hogar.csv")

conteos$migracion <- exportar_completo("MIGRACION_BDP.sav",
  c("DEPARTAMENTO", "MUNICIPIO", "NUM_VIVIENDA", "NUM_HOGAR", "ID_EMIGRACION",
    "PEI3", "PEI4", "PEI5"),
  "migracion.csv")

# ---- PERSONA por bloques ----
cols_persona <- c(
  "LUGAR_POBLADO", "NUM_VIVIENDA", "NUM_HOGAR", "PCP1", "PCP5", "PCP6", "PCP7", "PCP9",
  "PCP10", "PCP10_B", "LUGNACGEO", "PCP10_C", "PCP10_D", "PCP11", "PCP11_B", "RESCINGEO",
  "PCP11_C", "PCP12", "PCP13", "PCP14", "PCP15", paste0("PCP16_", LETTERS[1:6]), "PCP17_B",
  "PCP18", "PCP19", "PCP20", "PCP20_B", "ESTUDIAGEO", "PCP20_C", "PCP21", "PCP22",
  paste0("PCP23_", LETTERS[1:3]), "PCP24", paste0("PCP25_", LETTERS[1:3]),
  paste0("PCP26_", LETTERS[1:3]), "PCP27", "PCP28", "PCP29", "PCP30_2D", "PCP31_D",
  "PCP32_2D", "PCP33", "PCP33_B", "TRABAJAGEO", "PCP33_C", "PCP34",
  paste0("PCP35_", LETTERS[1:3]), paste0("PCP36_", LETTERS[1:3]), "PCP37",
  paste0("PCP38_", LETTERS[1:3]), "PCP39", "NIVGRADO", "ANEDUCA", "PEA", "POCUPA",
  "PDESOC", "PEI", "MIGRA_VIDA", "MIGRA_REC")
cols_extra <- c("PCP17_A", "PCP30_1D", "PCP32_1D")   # solo para las jerarquias

archivo_persona <- file.path(ruta_base, "PERSONA - BDP.sav")
salida_persona <- file.path(dir_csv, "persona.csv")
if (file.exists(salida_persona)) file.remove(salida_persona)

marca("PERSONA: %d columnas exportadas, bloques de %s filas", length(cols_persona),
      format(tamano_bloque, big.mark = ",", scientific = FALSE))
pares <- list()
leidas <- 0
repeat {
  d <- read_sav(archivo_persona, col_select = all_of(c(cols_persona, cols_extra)),
                skip = leidas, n_max = tamano_bloque)
  if (nrow(d) == 0) break
  d <- a_numerico(d)
  pares[[length(pares) + 1]] <- rbindlist(list(
    d[, .(jerarquia = "NIVGRADO_NIVEL", n = .N), by = .(hijo = NIVGRADO, padre = PCP17_A)],
    d[, .(jerarquia = "OCUPACION_GRUPO", n = .N), by = .(hijo = PCP30_2D, padre = PCP30_1D)],
    d[, .(jerarquia = "RAMA_GRUPO", n = .N), by = .(hijo = PCP32_2D, padre = PCP32_1D)]))
  d[, (cols_extra) := NULL]
  setcolorder(d, cols_persona)
  fwrite(d, salida_persona, append = leidas > 0, col.names = leidas == 0, na = "")
  leidas <- leidas + nrow(d)
  marca("PERSONA: %s filas escritas", format(leidas, big.mark = ","))
  rm(d); gc(verbose = FALSE)
  if (leidas %% tamano_bloque != 0) break
}
conteos$persona <- leidas

# Un codigo de 2 digitos puede aparecer con mas de un grupo de 1 digito en el origen; se exporta el
# numero de personas de cada combinacion para que la carga asigne el grupo mas frecuente.
jerarquias <- rbindlist(pares)[!is.na(hijo) & !is.na(padre), .(n = sum(n)), by = .(jerarquia, hijo, padre)][
  order(jerarquia, hijo, padre)]
fwrite(jerarquias, file.path(dir_csv, "jerarquias.csv"), na = "")
marca("jerarquias.csv: %d filas", nrow(jerarquias))

esperado <- c(vivienda = 3943431, hogar = 3275931, migracion = 242203, persona = 14901286)
resumen <- data.frame(archivo = names(esperado), exportadas = unlist(conteos[names(esperado)]),
                      esperadas = esperado, coincide = unlist(conteos[names(esperado)]) == esperado)
print(resumen, row.names = FALSE)
if (!all(resumen$coincide)) stop("Los conteos exportados no coinciden con los esperados")
marca("Exportacion terminada correctamente")
