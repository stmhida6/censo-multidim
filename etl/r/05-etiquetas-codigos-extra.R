# Imprime las etiquetas oficiales de los codigos geograficos que no son municipios
# (199, 299, ..., 2299) en el catalogo de 362 categorias de LUGNACGEO, y las de
# las categorias de PCP10_B, para saber que representan.
#
# Ejecutar con:
#   Rscript etl/r/05-etiquetas-codigos-extra.R

library(haven)

ruta <- file.path(Sys.getenv("CENSO_MICRODATOS", "datos/microdatos"), "PERSONA - BDP.sav")
muestra <- read_sav(ruta, col_select = c("LUGNACGEO", "PCP10_C"), n_max = 1)

etiquetas <- attr(muestra$LUGNACGEO, "labels")
extra <- etiquetas[names(etiquetas) != "" & etiquetas %% 100 == 99]
cat("Codigos terminados en 99 en LUGNACGEO:", length(extra), "\n")
print(data.frame(codigo = unname(extra), etiqueta = names(extra)), row.names = FALSE)

cat("\nPrimeras 5 etiquetas de municipios (para comparar formato):\n")
print(head(data.frame(codigo = unname(etiquetas), etiqueta = names(etiquetas)), 5), row.names = FALSE)
