#!/usr/bin/env bash
# Ejecuta la carga completa del censo: exportacion desde R, stage, dimensiones, hechos y validaciones.
#
# Uso (desde la raiz del repositorio, con Docker Desktop en marcha):
#   bash etl/ejecutar-etl.sh            # carga completa (exporta CSV solo si faltan)
#   bash etl/ejecutar-etl.sh --recargar # vacia dimensiones y hechos y vuelve a cargar
#   bash etl/ejecutar-etl.sh --exportar # fuerza volver a exportar los CSV desde los .sav
#
# Requisitos: R 4.5 con haven, data.table, dplyr y jsonlite; el contenedor censo-sqlserver (docker compose up -d sqlserver);
# los cuatro .sav del INE en MICRODATOS_DIR (por defecto datos/microdatos) y el esquema creado con bash db/crear-esquema.sh.
# Variables opcionales en .env: MICRODATOS_DIR (carpeta de los .sav) y RSCRIPT (ruta de Rscript si no esta en el PATH).

set -euo pipefail
cd "$(dirname "$0")/.."

leer() { grep -E "^$1=" .env 2>/dev/null | head -1 | cut -d= -f2- || true; }

# Rscript: el de .env, el del PATH o el de la instalacion habitual de Windows
RSCRIPT="$(leer RSCRIPT)"
[ -n "$RSCRIPT" ] || RSCRIPT="$(command -v Rscript || true)"
if [ -z "$RSCRIPT" ]; then
  RSCRIPT="$(ls -d "/c/Program Files/R"/R-*/bin/Rscript.exe 2>/dev/null | sort -V | tail -1 || true)"
fi
export CENSO_MICRODATOS="$(leer MICRODATOS_DIR)"
[ -n "$CENSO_MICRODATOS" ] || CENSO_MICRODATOS="datos/microdatos"
CONTENEDOR="censo-sqlserver"
RECARGAR=0
EXPORTAR=0
for arg in "$@"; do
  case "$arg" in
    --recargar) RECARGAR=1 ;;
    --exportar) EXPORTAR=1 ;;
    *) echo "Argumento desconocido: $arg" >&2; exit 2 ;;
  esac
done

[ -f .env ] || { echo "Falta .env: copie .env.example a .env y defina las claves" >&2; exit 1; }
SA_PASSWORD="$(leer MSSQL_SA_PASSWORD)"

sql() {  # ejecuta un archivo .sql dentro del contenedor y se detiene ante el primer error
  MSYS_NO_PATHCONV=1 docker exec -i "$CONTENEDOR" /opt/mssql-tools18/bin/sqlcmd \
    -C -b -S localhost -U sa -P "$SA_PASSWORD" -W -i /dev/stdin < "$1"
}

paso() { printf '\n== %s (%s)\n' "$1" "$(date +%H:%M:%S)"; }

if [ "$EXPORTAR" = 1 ] || [ ! -f datos/csv/persona.csv ] || [ ! -f datos/csv/catalogo.csv ]; then
  paso "Exportar catalogos y microdatos desde los .sav ($CENSO_MICRODATOS)"
  [ -n "$RSCRIPT" ] || { echo "No se encontro Rscript: instale R 4.5 o defina RSCRIPT en .env" >&2; exit 1; }
  for sav in "VIVIENDA_BDP.sav" "HOGAR_BDP.sav" "PERSONA - BDP.sav" "MIGRACION_BDP.sav"; do
    [ -f "$CENSO_MICRODATOS/$sav" ] || { echo "Falta $CENSO_MICRODATOS/$sav (microdatos del INE; ver README)" >&2; exit 1; }
  done
  "$RSCRIPT" -e 'p <- c("haven","data.table","dplyr","jsonlite"); f <- p[!sapply(p, requireNamespace, quietly = TRUE)]; if (length(f)) stop("Instale los paquetes de R: ", paste(f, collapse = ", "))'
  "$RSCRIPT" etl/r/10-exportar-catalogos.R
  "$RSCRIPT" etl/r/11-exportar-microdatos.R
else
  paso "CSV ya exportados en datos/csv (use --exportar para regenerarlos)"
fi

paso "Verificar el contenedor"
docker inspect -f '{{.State.Health.Status}}' "$CONTENEDOR" | grep -q healthy || { echo "El contenedor $CONTENEDOR no esta healthy" >&2; exit 1; }

if [ "$RECARGAR" = 1 ]; then paso "Vaciar dimensiones y hechos"; sql etl/sql/00-vaciar-modelo.sql; fi
paso "Crear las tablas de stage";        sql etl/sql/01-stage-tablas.sql
paso "Cargar los CSV a stage";           sql etl/sql/02-cargar-stage.sql
paso "Cargar las dimensiones";           sql etl/sql/03-cargar-dimensiones.sql
paso "Cargar los hechos";                sql etl/sql/04-cargar-hechos.sql
paso "Validar la carga";                 sql etl/sql/05-validaciones.sql
paso "ETL terminado"
