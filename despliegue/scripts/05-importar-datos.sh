#!/usr/bin/env bash
# Importa el BACPAC exportado de la base local (04-exportar-bacpac.sh) en la base gratuita ya creada (debe estar vacia).
# Tarda unos 55 minutos. Uso: bash despliegue/scripts/05-importar-datos.sh [ruta.bacpac]
source "$(dirname "$0")/configuracion.sh"

BACPAC="${1:-$RAIZ/datos/CensoGT2018.bacpac}"
[ -f "$BACPAC" ] || { echo "No existe $BACPAC: ejecute antes 04-exportar-bacpac.sh" >&2; exit 1; }
paso "Importar $BACPAC en $SQLSRV/$BD"
"$SQLPACKAGE" /Action:Import /SourceFile:"$BACPAC" /TargetConnectionString:"$CONEXION_ADMIN"
paso "Importacion terminada"
