#!/usr/bin/env bash
# Crea el grupo de recursos y el servidor logico de Azure SQL, con reglas de firewall para este equipo y para los
# servicios de Azure (las necesita App Service). El nombre del servidor (unico en todo Azure) y la clave del
# administrador se generan la primera vez y se guardan en .env (AZURE_SQL_SERVER y AZURE_SQL_ADMIN_PASSWORD).
# Uso: bash despliegue/scripts/02-crear-servidor.sh
source "$(dirname "$0")/configuracion.sh"

if [ -z "$SQLSRV" ]; then
  SQLSRV="sql-censo2018-$(LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c 5)"
  guardar_en_env AZURE_SQL_SERVER "$SQLSRV"
fi
if [ -z "$SQLADMIN_CLAVE" ]; then
  SQLADMIN_CLAVE="$(clave_aleatoria)"
  guardar_en_env AZURE_SQL_ADMIN_PASSWORD "$SQLADMIN_CLAVE"
  echo "Clave del administrador generada y guardada en .env (AZURE_SQL_ADMIN_PASSWORD)."
fi

paso "Grupo de recursos $RG en $LOC"
az group create -n "$RG" -l "$LOC" --query "{grupo:name, region:location}" -o table

paso "Servidor $SQLSRV (administrador $SQLADMIN)"
if az sql server show -g "$RG" -n "$SQLSRV" >/dev/null 2>&1; then
  echo "El servidor ya existe; no se crea de nuevo."
else
  az sql server create -g "$RG" -n "$SQLSRV" -l "$LOC" -u "$SQLADMIN" -p "$SQLADMIN_CLAVE" \
    --minimal-tls-version 1.2 --query "{servidor:name, region:location}" -o table
fi

paso "Firewall: este equipo y los servicios de Azure"
IP="$(curl -s https://api.ipify.org)"
az sql server firewall-rule create -g "$RG" -s "$SQLSRV" -n EquipoDesarrollo --start-ip-address "$IP" --end-ip-address "$IP" --query name -o tsv
az sql server firewall-rule create -g "$RG" -s "$SQLSRV" -n ServiciosAzure --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0 --query name -o tsv
