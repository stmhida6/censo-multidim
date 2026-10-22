# Determina el significado de los codigos 1 y 2 de MIGRA_VIDA y MIGRA_REC (sin
# etiqueta en el .sav) cruzandolos con las preguntas de origen PCP10 y PCP11, y
# cuenta las combinaciones de las banderas PEA, POCUPA, PDESOC y PEI para definir
# la dimension derivada Dim.CondicionActividad.
#
# Ejecutar con:
#   Rscript etl/r/06-verificacion-migracion-actividad.R

library(haven)
library(dplyr)
library(jsonlite)

cols <- c("PCP7", "PCP10", "PCP11", "MIGRA_VIDA", "MIGRA_REC", "PEA", "POCUPA", "PDESOC", "PEI")
p <- read_sav(file.path(Sys.getenv("CENSO_MICRODATOS", "datos/microdatos"), "PERSONA - BDP.sav"), col_select = all_of(cols)) %>%
  mutate(across(everything(), ~ as.numeric(zap_labels(.))))

tabla <- function(...) {
  t <- p %>% count(..., name = "personas")
  split(t, seq_len(nrow(t))) %>% lapply(as.list)
}

resultado <- list(
  MIGRA_VIDA_por_PCP10 = tabla(PCP10, MIGRA_VIDA),
  MIGRA_REC_por_PCP11 = tabla(PCP11, MIGRA_REC),
  actividad_combinaciones = p %>%
    mutate(edad = case_when(PCP7 < 7 ~ "menor_7", PCP7 < 15 ~ "7_a_14", TRUE ~ "15_o_mas")) %>%
    count(edad, PEA, POCUPA, PDESOC, PEI, name = "personas") %>%
    split(seq_len(nrow(.))) %>% lapply(as.list)
)

print(resultado$MIGRA_VIDA_por_PCP10)
print(resultado$MIGRA_REC_por_PCP11)
write_json(resultado, "etl/r/salidas/verificacion_migracion_actividad.json",
           auto_unbox = TRUE, pretty = TRUE, na = "null")
cat("\nListo. Resultado en etl/r/salidas/verificacion_migracion_actividad.json\n")
