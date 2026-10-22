#!/usr/bin/env bash
# Vuelve a poner en servicio el despliegue (antes de la prueba de carga, el ensayo o la presentacion):
#  1. Abre el firewall de la base para la IP actual del equipo y para los servicios de Azure (la API).
#  2. Inicia la API y despierta la base con una consulta.
source "$(dirname "$0")/configuracion.sh"

paso "Abrir el firewall de $SQLSRV"
IP="$(curl -s https://api.ipify.org)"
az sql server firewall-rule create -g "$RG" -s "$SQLSRV" -n EquipoDesarrollo --start-ip-address "$IP" --end-ip-address "$IP" --query name -o tsv
az sql server firewall-rule create -g "$RG" -s "$SQLSRV" -n ServiciosAzure --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0 --query name -o tsv

paso "Iniciar la API $APP"
az webapp start -g "$RG" -n "$APP"
az webapp show -g "$RG" -n "$APP" --query "{api:name, estado:state}" -o table

bash "$(dirname "$0")/despertar-base.sh"
