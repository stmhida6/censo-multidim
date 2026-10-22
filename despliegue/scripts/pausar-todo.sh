#!/usr/bin/env bash
# Deja el despliegue sin consumo mientras no se use:
#  1. Detiene la API: nadie puede despertar la base a traves de ella (el plan F1 es gratuito).
#  2. Elimina las reglas del firewall de la base: ninguna conexion (ni intentos externos) llega a ella, asi que la base
#     serverless se queda pausada (se pausa sola tras 60 min sin conexiones) y no consume cupo ni credito.
# Nota: Azure no permite volver de BillOverUsage a AutoPause; por eso se cierra el acceso en lugar de cambiar ese ajuste.
# Para volver a usarlo: bash despliegue/scripts/reanudar.sh
source "$(dirname "$0")/configuracion.sh"

paso "Detener la API $APP"
az webapp stop -g "$RG" -n "$APP"
az webapp show -g "$RG" -n "$APP" --query "{api:name, estado:state}" -o table

paso "Cerrar el firewall de $SQLSRV"
for regla in $(az sql server firewall-rule list -g "$RG" -s "$SQLSRV" --query "[].name" -o tsv | tr -d '\r'); do
  az sql server firewall-rule delete -g "$RG" -s "$SQLSRV" -n "$regla" && echo "Regla eliminada: $regla"
done
echo "Reglas restantes: $(az sql server firewall-rule list -g "$RG" -s "$SQLSRV" --query "length(@)" -o tsv)"

paso "Estado de la base (pasa a Paused tras 60 min sin conexiones)"
az sql db show -g "$RG" -s "$SQLSRV" -n "$BD" --query "{base:name, estado:status}" -o table
