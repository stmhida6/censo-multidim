#!/usr/bin/env bash
# Resumen del despliegue: recursos, plan de la API, estado de la base, uso del cupo gratuito y costo del mes.
source "$(dirname "$0")/configuracion.sh"

paso "Recursos en $RG"
az resource list -g "$RG" --query "[].{recurso:name, tipo:type, region:location}" -o table

paso "Base de datos"
az sql db show -g "$RG" -s "$SQLSRV" -n "$BD" \
  --query "{estado:status, nivel:currentServiceObjectiveName, gratuita:useFreeLimit, al_agotar:freeLimitExhaustionBehavior}" -o table

paso "Cupo gratuito usado este mes (vCore-segundos; el limite es 100,000)"
SUB="$(az account show --query id -o tsv)"
DBID="/subscriptions/${SUB}/resourceGroups/${RG}/providers/Microsoft.Sql/servers/${SQLSRV}/databases/${BD}"
MSYS_NO_PATHCONV=1 az monitor metrics list --resource "$DBID" --metric free_amount_consumed free_amount_remaining \
  --interval PT1H --aggregation Maximum --query "value[].{metrica:name.value, ultimo:timeseries[0].data[-1].maximum}" -o table 2>/dev/null \
  || echo "(metricas de cupo no disponibles todavia)"

if [ -n "$APP" ]; then
  paso "API"
  az appservice plan show -g "$RG" -n "$PLAN" --query "{plan:name, sku:sku.name}" -o table
  URL="https://$(az webapp show -g "$RG" -n "$APP" --query defaultHostName -o tsv)"
  curl -s -o /dev/null -w "$URL/salud -> HTTP %{http_code} en %{time_total} s" "$URL/salud"; echo
fi

paso "Costo acumulado del mes en la suscripcion (USD)"
az rest --method post \
  --url "https://management.azure.com/subscriptions/${SUB}/providers/Microsoft.CostManagement/query?api-version=2023-03-01" \
  --body '{"type":"ActualCost","timeframe":"MonthToDate","dataset":{"granularity":"None","aggregation":{"total":{"name":"Cost","function":"Sum"}},"grouping":[{"type":"Dimension","name":"ServiceName"}]}}' \
  --query "properties.rows" -o tsv 2>/dev/null || echo "(Cost Management no respondio; puede limitar consultas seguidas. Reintentar o revisar el portal)"
