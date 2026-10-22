#!/usr/bin/env bash
# Elimina el grupo de recursos completo (base, servidor, plan y API). No se puede deshacer.
# Antes: conservar el BACPAC local (datos/CensoGT2018.bacpac) si se quiere volver a importar.
# Uso: bash despliegue/scripts/eliminar-todo.sh --confirmar
source "$(dirname "$0")/configuracion.sh"

[ "${1:-}" = "--confirmar" ] || { echo "Para eliminar $RG ejecute: bash $0 --confirmar" >&2; exit 1; }
paso "Eliminando el grupo de recursos $RG"
az group delete -n "$RG" --yes
echo "Grupo eliminado. La alerta de presupuesto (presupuesto-censo2018) sigue en la suscripcion."
