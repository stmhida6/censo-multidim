#!/usr/bin/env bash
# La base serverless se pausa sola tras 1 hora sin uso; la primera consulta despues de una pausa tarda en responder
# (unos 30 a 60 s). Ejecutar antes de una demostracion, de la prueba de carga o de la presentacion.
source "$(dirname "$0")/configuracion.sh"

if ! docker info >/dev/null 2>&1; then
  echo "Docker Desktop no esta en marcha: la consulta usa el sqlcmd del contenedor censo-sqlserver. Abralo y repita." >&2
  exit 1
fi

paso "Estado de la base antes"
az sql db show -g "$RG" -s "$SQLSRV" -n "$BD" --query "{base:name, estado:status}" -o table
paso "Consulta para despertarla"
inicio=$(date +%s)
# Mientras despierta, Azure rechaza la conexion ("is not currently available"): se reintenta cada 15 s hasta 5 min.
for intento in $(seq 1 20); do
  if sql_azure "$BD" -l 60 -Q "SET NOCOUNT ON; SELECT COUNT_BIG(*) AS personas FROM hechos.CensoPoblacion;" 2>/dev/null; then
    break
  fi
  echo "  intento $intento: la base aun despierta; nuevo intento en 15 s"
  sleep 15
done
echo "Respondio en $(( $(date +%s) - inicio )) s"
if [ -n "$APP" ]; then
  URL="https://$(az webapp show -g "$RG" -n "$APP" --query defaultHostName -o tsv)"
  curl -s -o /dev/null -w "API /salud: HTTP %{http_code} en %{time_total} s\n" "$URL/salud"
fi
