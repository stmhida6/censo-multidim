#!/usr/bin/env bash
# Crea (si no existe) el plan de App Service Linux y la aplicacion web, configura la conexion y publica la API.
# Uso: bash despliegue/scripts/08-publicar-api.sh [F1|B1|B2]   (por defecto F1, gratuito)
# El nombre de la aplicacion se genera la primera vez y se guarda en .env (AZURE_APP_NAME).
source "$(dirname "$0")/configuracion.sh"

SKU="${1:-F1}"
if [ -z "$APP" ]; then
  APP="app-censo2018-${SQLSRV##*-}"
  guardar_en_env AZURE_APP_NAME "$APP"
fi
[ -n "$CLAVE_API_AZURE" ] || { echo "Falta AZURE_CLAVE_API: ejecute antes 06-crear-usuario-api.sh" >&2; exit 1; }

paso "Plan $PLAN ($SKU, Linux) y aplicacion $APP en $LOC"
az appservice plan show -g "$RG" -n "$PLAN" >/dev/null 2>&1 \
  || az appservice plan create -g "$RG" -n "$PLAN" -l "$LOC" --is-linux --sku "$SKU" --query "{plan:name, sku:sku.name}" -o table
az webapp show -g "$RG" -n "$APP" >/dev/null 2>&1 \
  || az webapp create -g "$RG" -p "$PLAN" -n "$APP" --runtime "DOTNETCORE:8.0" --query "{app:name, url:defaultHostName}" -o table
az webapp update -g "$RG" -n "$APP" --https-only true --query httpsOnly -o tsv >/dev/null

paso "Configuracion (cadena de conexion con el usuario de solo lectura y variables)"
# App Service entrega la cadena de tipo SQLAzure como SQLAZURECONNSTR_CensoDb, que ASP.NET Core lee como ConnectionStrings:CensoDb.
az webapp config connection-string set -g "$RG" -n "$APP" -t SQLAzure \
  --settings CensoDb="$CONEXION_API" --query "keys(@)" -o tsv >/dev/null
# ASPNETCORE_FORWARDEDHEADERS_ENABLED: la API ve la IP real del cliente detras del balanceador (limite por cliente).
az webapp config appsettings set -g "$RG" -n "$APP" --settings \
  ASPNETCORE_ENVIRONMENT=Production \
  LimiteSolicitudes__PorMinuto=120 \
  BaseDatos__TiempoEsperaSegundos=90 \
  ASPNETCORE_FORWARDEDHEADERS_ENABLED=true \
  --query "[].name" -o tsv

paso "Compilar y publicar"
rm -rf "$RAIZ/datos/publicar" "$RAIZ/datos/censo-api.zip"
dotnet publish src/Censo.Api -c Release -o "$RAIZ/datos/publicar" --nologo -v q
python "$(cygpath -w "$RAIZ/despliegue/scripts/empaquetar.py")" "$(cygpath -w "$RAIZ/datos/publicar")" "$(cygpath -w "$RAIZ/datos/censo-api.zip")"
az webapp deploy -g "$RG" -n "$APP" --src-path "$RAIZ/datos/censo-api.zip" --type zip --query "{estado:provisioningState}" -o table

paso "Verificacion"
URL="https://$(az webapp show -g "$RG" -n "$APP" --query defaultHostName -o tsv)"
echo "URL: $URL"
for i in $(seq 1 20); do curl -sf "$URL/salud" && break; sleep 10; done; echo
