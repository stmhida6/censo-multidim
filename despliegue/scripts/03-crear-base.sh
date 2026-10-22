#!/usr/bin/env bash
# Crea la base CensoGT2018 vacia en Azure SQL con la oferta gratuita (serverless General Purpose, 2 vCore).
# Tamano maximo de 10 GB (la base ocupa 2.5 GB): Azure factura el maximo configurado mas un 30 % de registro, y la
# oferta cubre 32 GB; con el maximo de 32 GB por defecto se cobraban 9.6 GB (unos USD 0.04 al dia, aun en pausa).
# Si se agota el cupo gratuito mensual (100,000 vCore-segundos), sigue funcionando y cobra al credito
# (BillOverUsage), para que no se pause antes de la presentacion.
# La oferta gratuita no esta disponible en mexicocentral ("ProvisioningDisabled"); se usa westus, una de las regiones
# permitidas por la suscripcion de estudiante (el servidor debe estar en esa region: ver AZURE_LOCATION en .env).
# Requiere el servidor creado con 02-crear-servidor.sh.
source "$(dirname "$0")/configuracion.sh"

paso "Base $BD en $SQLSRV (oferta gratuita, serverless 2 vCore)"
if az sql db show -g "$RG" -s "$SQLSRV" -n "$BD" >/dev/null 2>&1; then
  echo "La base ya existe; no se crea de nuevo."
else
  az sql db create -g "$RG" -s "$SQLSRV" -n "$BD" \
    --edition GeneralPurpose --family Gen5 --capacity 2 --compute-model Serverless \
    --use-free-limit true --free-limit-exhaustion-behavior BillOverUsage --max-size 10GB \
    --query "{base:name, nivel:currentServiceObjectiveName}" -o table
fi

az sql db show -g "$RG" -s "$SQLSRV" -n "$BD" \
  --query "{base:name, estado:status, nivel:currentServiceObjectiveName, gratuita:useFreeLimit, al_agotar:freeLimitExhaustionBehavior, pausa_automatica_min:autoPauseDelay, vcore_min:minCapacity, max_gb:maxSizeBytes}" -o table
