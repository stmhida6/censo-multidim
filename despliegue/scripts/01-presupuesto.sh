#!/usr/bin/env bash
# Crea una alerta de presupuesto mensual en la suscripcion: avisos por correo al 50 % (USD 15) y al 100 % (USD 30)
# del gasto real. Uso: bash despliegue/scripts/01-presupuesto.sh <correo>
source "$(dirname "$0")/configuracion.sh"

CORREO="${1:?Indique el correo que recibira las alertas}"
SUB="$(az account show --query id -o tsv)"
INICIO="$(date +%Y-%m-01)"

paso "Alerta de presupuesto de USD 30 mensuales para $CORREO"
cat > /tmp/presupuesto.json <<JSON
{
  "properties": {
    "category": "Cost",
    "amount": 30,
    "timeGrain": "Monthly",
    "timePeriod": { "startDate": "${INICIO}T00:00:00Z", "endDate": "2027-03-31T00:00:00Z" },
    "notifications": {
      "Real50": { "enabled": true, "operator": "GreaterThanOrEqualTo", "threshold": 50, "thresholdType": "Actual", "contactEmails": ["$CORREO"] },
      "Real100": { "enabled": true, "operator": "GreaterThanOrEqualTo", "threshold": 100, "thresholdType": "Actual", "contactEmails": ["$CORREO"] },
      "Pronostico100": { "enabled": true, "operator": "GreaterThanOrEqualTo", "threshold": 100, "thresholdType": "Forecasted", "contactEmails": ["$CORREO"] }
    }
  }
}
JSON
az rest --method put \
  --url "https://management.azure.com/subscriptions/${SUB}/providers/Microsoft.Consumption/budgets/presupuesto-censo2018?api-version=2023-05-01" \
  --body @/tmp/presupuesto.json --query "{nombre:name, monto:properties.amount, periodo:properties.timeGrain}" -o table
rm -f /tmp/presupuesto.json
