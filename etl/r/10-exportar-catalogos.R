# Exporta a CSV las etiquetas de valor (catalogos) de las 4 bases del censo, para
# poblar las dimensiones desde SQL Server. Genera datos/csv/catalogo.csv con las
# columnas: archivo, variable, codigo, etiqueta (UTF-16LE con BOM, ver utilidades-exportacion.R).
#
# Ejecutar con:
#   Rscript etl/r/10-exportar-catalogos.R

library(haven)
library(data.table)
source("etl/r/utilidades-exportacion.R")

# Carpeta de los .sav del INE: CENSO_MICRODATOS (la define etl/ejecutar-etl.sh desde .env) o datos/microdatos.
ruta_base <- Sys.getenv("CENSO_MICRODATOS", "datos/microdatos")
dir_csv <- "datos/csv"
dir.create(dir_csv, recursive = TRUE, showWarnings = FALSE)

archivos <- c(VIVIENDA = "VIVIENDA_BDP.sav", HOGAR = "HOGAR_BDP.sav",
              MIGRACION = "MIGRACION_BDP.sav", PERSONA = "PERSONA - BDP.sav")

filas <- list()
for (a in names(archivos)) {
  cat(sprintf("%s: leyendo etiquetas de %s...\n", format(Sys.time(), "%H:%M:%S"), archivos[[a]]))
  muestra <- read_sav(file.path(ruta_base, archivos[[a]]), n_max = 1)
  for (v in names(muestra)) {
    et <- attr(muestra[[v]], "labels")
    if (is.null(et) || length(et) == 0) next
    filas[[length(filas) + 1]] <- data.table(archivo = a, variable = v,
                                             codigo = as.numeric(et), etiqueta = names(et))
  }
}

catalogo <- rbindlist(filas)
escribir_csv_utf16(catalogo, file.path(dir_csv, "catalogo.csv"))

cat(sprintf("\nCatalogo: %d filas, %d variables con etiquetas.\n", nrow(catalogo),
            uniqueN(catalogo[, .(archivo, variable)])))
print(catalogo[, .(categorias = .N), by = .(archivo, variable)][order(archivo, -categorias)][1:15])
