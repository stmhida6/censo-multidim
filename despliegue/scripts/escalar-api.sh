#!/usr/bin/env bash
# Cambia el plan de App Service (se cobra por hora; el cambio tarda segundos).
#   F1  gratuito: desarrollo, Power BI y demostraciones (60 min de CPU al dia, sin "Always On")
#   B1  USD 0.0187/h: ensayo y presentacion (siempre activo, sin arranques en frio)
#   B2  USD 0.0374/h: solo durante la prueba de carga (2 nucleos)
# Uso: bash despliegue/scripts/escalar-api.sh F1|B1|B2
source "$(dirname "$0")/configuracion.sh"

SKU="${1:?Indique F1, B1 o B2}"
paso "Plan $PLAN -> $SKU"
az appservice plan update -g "$RG" -n "$PLAN" --sku "$SKU" --query "{plan:name, sku:sku.name, trabajadores:sku.capacity}" -o table
if [ "$SKU" != "F1" ]; then
  az webapp config set -g "$RG" -n "$APP" --always-on true --query alwaysOn -o tsv
fi
