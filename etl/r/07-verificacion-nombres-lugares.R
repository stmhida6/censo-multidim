# Comprueba directamente en VIVIENDA_BDP.sav (sin pasar por la exportacion) los nombres de lugares
# poblados que el control de textos de etl/sql/05-validaciones.sql marca como corruptos, para
# establecer si el defecto viene del origen o de la carga. Resultado: viene del origen.
#
# Ejecutar con:
#   Rscript etl/r/07-verificacion-nombres-lugares.R

library(haven)

lugares <- c(116027, 1609128, 1609359, 1615118)
d <- read_sav(file.path(Sys.getenv("CENSO_MICRODATOS", "datos/microdatos"), "VIVIENDA_BDP.sav"), col_select = c("LUGAR_POBLADO", "NOMBRE_LUGAR_POBLADO"))
d <- unique(d[d$LUGAR_POBLADO %in% lugares, ])

for (i in seq_len(nrow(d))) {
  x <- d$NOMBRE_LUGAR_POBLADO[i]
  cat(d$LUGAR_POBLADO[i], "| texto:", x, "| bytes UTF-8:",
      paste(sprintf("%02X", as.integer(charToRaw(enc2utf8(x)))), collapse = " "), "\n")
}
cat("\nEn 1609128, 1609359 y 1615118 la 'a con tilde' esta seguida del caracter de control U+0081 (C2 81);\n",
    "en 116027 el origen trae un signo de interrogacion literal (0x3F) donde iria la 'n con tilde'.\n", sep = "")
