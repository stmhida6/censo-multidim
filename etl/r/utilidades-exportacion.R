# Funciones compartidas por los scripts de exportacion (10 y 11).
#
# BULK INSERT en SQL Server para Linux no admite CODEPAGE y lee los archivos de caracteres con la
# pagina de codigos OEM 437, que no tiene Á, Í, Ó ni Ú. Los CSV con texto (etiquetas y nombres de
# lugares poblados) se escriben por eso en UTF-16LE con marca de orden de bytes (BOM), que
# BULK INSERT ... DATAFILETYPE = 'widechar' carga sin conversion. Los CSV numericos no lo necesitan.

library(data.table)

# Sin esto fwrite escribe numeros redondos como 1e+05, que BULK INSERT no convierte a entero.
options(scipen = 999)

escribir_csv_utf16 <- function(datos, ruta) {
  temporal <- tempfile(fileext = ".csv")
  on.exit(unlink(temporal))
  fwrite(datos, temporal, na = "", eol = "\r\n")
  texto <- readChar(temporal, file.size(temporal), useBytes = TRUE)
  Encoding(texto) <- "UTF-8"
  bytes <- iconv(texto, "UTF-8", "UTF-16LE", toRaw = TRUE)[[1]]
  writeBin(c(as.raw(c(0xff, 0xfe)), bytes), ruta)
  invisible(ruta)
}
