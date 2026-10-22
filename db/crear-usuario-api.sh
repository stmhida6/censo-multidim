#!/usr/bin/env bash
# Crea (o actualiza la clave de) el usuario de solo lectura CensoApi en el contenedor censo-sqlserver.
# Requiere MSSQL_SA_PASSWORD y CLAVE_API en el .env de la raiz del repositorio.
set -euo pipefail
cd "$(dirname "$0")/.."
leer() { grep -E "^$1=" .env | head -1 | cut -d= -f2-; }
SA=$(leer MSSQL_SA_PASSWORD); CLAVE=$(leer CLAVE_API)
[ -n "$CLAVE" ] || { echo "Falta CLAVE_API en .env" >&2; exit 1; }
MSYS_NO_PATHCONV=1 docker exec -i censo-sqlserver /opt/mssql-tools18/bin/sqlcmd -C -b \
  -S localhost -U sa -P "$SA" -v CLAVE_API="$CLAVE" -i /dev/stdin < db/01-esquema/02-crear-usuario-api.sql
echo "Usuario CensoApi listo."
