#!/usr/bin/env bash
# Crea en Azure SQL el usuario de solo lectura CensoApi como usuario contenido (vive dentro de la base; Azure SQL no
# usa logins de servidor para esto). Solo SELECT sobre dim y hechos, igual que en local (db/01-esquema/02-crear-usuario-api.sql).
# La clave se genera la primera vez y se guarda en .env como AZURE_CLAVE_API (no versionado).
source "$(dirname "$0")/configuracion.sh"

if [ -z "$CLAVE_API_AZURE" ]; then
  CLAVE_API_AZURE="$(clave_aleatoria)"
  guardar_en_env AZURE_CLAVE_API "$CLAVE_API_AZURE"
  echo "Clave de CensoApi generada y guardada en .env (AZURE_CLAVE_API)."
fi

paso "Usuario contenido CensoApi en $SQLSRV/$BD"
sql_azure "$BD" <<SQL
SET NOCOUNT ON;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'CensoApi')
    CREATE USER [CensoApi] WITH PASSWORD = N'${CLAVE_API_AZURE}';
ELSE
    ALTER USER [CensoApi] WITH PASSWORD = N'${CLAVE_API_AZURE}';
GRANT SELECT ON SCHEMA::dim TO [CensoApi];
GRANT SELECT ON SCHEMA::hechos TO [CensoApi];
SELECT p.name AS usuario, p.type_desc AS tipo, p.authentication_type_desc AS autenticacion FROM sys.database_principals p WHERE p.name = N'CensoApi';
SELECT permission_name AS permiso, SCHEMA_NAME(major_id) AS esquema FROM sys.database_permissions
WHERE grantee_principal_id = USER_ID(N'CensoApi') AND class_desc = 'SCHEMA';
SQL
