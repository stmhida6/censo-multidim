#!/usr/bin/env bash
# Crea la base CensoGT2018 y el modelo en estrella vacio en el contenedor censo-sqlserver:
#   01-esquema (base y esquemas dim, hechos, stage, seg) -> 02-dimensiones (tablas con sus PK) -> 03-indices (UQ, FK, columnstore).
# El usuario de solo lectura de la API se crea aparte con: bash db/crear-usuario-api.sh
# Uso (desde la raiz del repositorio, con docker compose up -d sqlserver en estado healthy):
#   bash db/crear-esquema.sh
set -euo pipefail
cd "$(dirname "$0")/.."

leer() { grep -E "^$1=" .env 2>/dev/null | head -1 | cut -d= -f2- || true; }
[ -f .env ] || { echo "Falta .env: copie .env.example a .env y defina las claves" >&2; exit 1; }
SA="$(leer MSSQL_SA_PASSWORD)"
docker inspect -f '{{.State.Health.Status}}' censo-sqlserver 2>/dev/null | grep -q healthy \
  || { echo "El contenedor censo-sqlserver no esta en marcha (docker compose up -d sqlserver)" >&2; exit 1; }

for archivo in db/01-esquema/00-*.sql db/01-esquema/01-*.sql db/02-dimensiones/*.sql db/03-indices/*.sql; do
  printf '== %s\n' "$archivo"
  MSYS_NO_PATHCONV=1 docker exec -i censo-sqlserver /opt/mssql-tools18/bin/sqlcmd \
    -C -b -S localhost -U sa -P "$SA" -i /dev/stdin < "$archivo"
done

echo
echo "Esquema creado. Comprobacion:"
MSYS_NO_PATHCONV=1 docker exec censo-sqlserver /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P "$SA" -d CensoGT2018 -W -Q \
  "SET NOCOUNT ON; SELECT
     (SELECT COUNT(*) FROM sys.tables WHERE SCHEMA_NAME(schema_id) = 'dim')    AS dimensiones,
     (SELECT COUNT(*) FROM sys.tables WHERE SCHEMA_NAME(schema_id) = 'hechos') AS hechos,
     (SELECT COUNT(*) FROM sys.foreign_keys)                                   AS llaves_foraneas;"
echo "Esperado: 40 dimensiones, 4 hechos y 78 llaves foraneas."
