#!/usr/bin/env bash
# Configuracion comun del despliegue en Azure. Los demas scripts la cargan con: source "$(dirname "$0")/configuracion.sh"
# Los nombres de los recursos y las claves salen del .env de la raiz del repositorio (no versionado). Variables:
#   AZURE_RESOURCE_GROUP (por defecto rg-censo2018), AZURE_LOCATION (por defecto westus), AZURE_SQL_ADMIN (censoadmin),
#   AZURE_APP_PLAN (plan-censo2018). AZURE_SQL_SERVER, AZURE_SQL_ADMIN_PASSWORD, AZURE_CLAVE_API y AZURE_APP_NAME los
#   generan los scripts la primera vez y los guardan en .env.

set -euo pipefail
RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$RAIZ"

# Azure CLI en Windows (Git Bash): llamarlo por el PATH evita problemas de comillas con la ruta completa.
export PATH="/c/Program Files/Microsoft SDKs/Azure/CLI2/wbin:$PATH"
SQLPACKAGE="${SQLPACKAGE:-$HOME/.dotnet/tools/sqlpackage}"

[ -f .env ] || { echo "Falta .env: copie .env.example a .env" >&2; exit 1; }
leer() { grep -E "^$1=" .env | head -1 | cut -d= -f2- || true; }
con_defecto() { local v; v="$(leer "$1")"; printf '%s' "${v:-$2}"; }

RG="$(con_defecto AZURE_RESOURCE_GROUP rg-censo2018)"
LOC="$(con_defecto AZURE_LOCATION westus)"
SQLSRV="$(leer AZURE_SQL_SERVER)"
SQLADMIN="$(con_defecto AZURE_SQL_ADMIN censoadmin)"
SQLADMIN_CLAVE="$(leer AZURE_SQL_ADMIN_PASSWORD)"
BD="CensoGT2018"
PLAN="$(con_defecto AZURE_APP_PLAN plan-censo2018)"
APP="$(leer AZURE_APP_NAME)"
CLAVE_API_AZURE="$(leer AZURE_CLAVE_API)"

SQLHOST="tcp:${SQLSRV}.database.windows.net,1433"
CONEXION_ADMIN="Server=${SQLHOST};Database=${BD};User Id=${SQLADMIN};Password=${SQLADMIN_CLAVE};Encrypt=True;TrustServerCertificate=False;Connection Timeout=60"
CONEXION_API="Server=${SQLHOST};Database=${BD};User Id=CensoApi;Password=${CLAVE_API_AZURE};Encrypt=True;TrustServerCertificate=False;Connection Timeout=60"

# sqlcmd contra Azure SQL usando las herramientas del contenedor local (no requiere instalar sqlcmd)
sql_azure() {  # sql_azure <base> < archivo.sql   |   sql_azure <base> -Q "consulta"
  local base="$1"; shift
  MSYS_NO_PATHCONV=1 docker exec -i censo-sqlserver /opt/mssql-tools18/bin/sqlcmd \
    -S "${SQLSRV}.database.windows.net" -d "$base" -U "$SQLADMIN" -P "$SQLADMIN_CLAVE" -b -W "$@"
}

paso() { printf '\n== %s (%s)\n' "$1" "$(date +%H:%M:%S)"; }

# Genera una clave aleatoria fuerte (mayusculas, minusculas, digitos y simbolo)
clave_aleatoria() { LC_ALL=C tr -dc 'A-HJ-NP-Za-km-z2-9' </dev/urandom | head -c 20; printf '#7aK'; }

# Agrega una variable al .env si no existe
guardar_en_env() { grep -qE "^$1=" .env || printf '%s=%s\n' "$1" "$2" >> .env; }
