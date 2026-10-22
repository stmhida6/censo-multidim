#!/usr/bin/env bash
# Exporta la base local CensoGT2018 (ya cargada con el ETL y verificada) a un BACPAC para importarlo en Azure.
# El usuario CensoApi depende de un login del servidor local que no existe en Azure y haria fallar la importacion:
# se retira antes de exportar y se vuelve a crear al terminar (en Azure se crea como usuario contenido, paso 06).
# Requiere SqlPackage (dotnet tool install -g microsoft.sqlpackage) y el contenedor censo-sqlserver en marcha.
# Tarda unos 12 minutos y genera un archivo de unos 650 MB en datos/ (no se versiona).
# Uso: bash despliegue/scripts/04-exportar-bacpac.sh [ruta.bacpac]
source "$(dirname "$0")/configuracion.sh"

BACPAC="${1:-$RAIZ/datos/CensoGT2018.bacpac}"
SA="$(leer MSSQL_SA_PASSWORD)"
PUERTO="$(con_defecto SQLSERVER_PORT 1433)"
mkdir -p "$(dirname "$BACPAC")"

sql_local() {
  MSYS_NO_PATHCONV=1 docker exec -i censo-sqlserver /opt/mssql-tools18/bin/sqlcmd -C -b -S localhost -U sa -P "$SA" -d "$BD" "$@"
}
restaurar_usuario() { paso "Restaurar el usuario local CensoApi"; bash "$RAIZ/db/crear-usuario-api.sh"; }

paso "Retirar temporalmente el usuario CensoApi de la base local"
sql_local -Q "IF USER_ID('CensoApi') IS NOT NULL DROP USER [CensoApi];"
trap restaurar_usuario EXIT

paso "Exportar $BD a $BACPAC"
"$SQLPACKAGE" /Action:Export /TargetFile:"$BACPAC" \
  /SourceConnectionString:"Server=localhost,$PUERTO;Database=$BD;User Id=sa;Password=$SA;TrustServerCertificate=True"
ls -lh "$BACPAC"
