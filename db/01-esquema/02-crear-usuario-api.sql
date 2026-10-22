/*
    Usuario de solo lectura para la API (privilegios minimos, tesis 2.9).

    La API solo ejecuta SELECT sobre las dimensiones y los hechos: no puede leer stage
    ni seg, ni modificar datos ni objetos. Si la API se vulnerara, el dano queda limitado
    a leer datos agregables del censo (ya anonimizados).

    La clave no se guarda en el repositorio: se pasa como variable de sqlcmd.
        sqlcmd -v CLAVE_API="<clave>" -i 02-crear-usuario-api.sql
    Es idempotente: si el login ya existe, solo actualiza la clave.
*/

USE [CensoGT2018];
GO

DECLARE @clave NVARCHAR(128) = N'$(CLAVE_API)';
DECLARE @literal NVARCHAR(300) = REPLACE(@clave, N'''', N'''''');

IF LEN(@clave) < 12
    THROW 50001, 'Defina la variable CLAVE_API (minimo 12 caracteres).', 1;

IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = N'CensoApi')
    EXEC(N'CREATE LOGIN [CensoApi] WITH PASSWORD = N''' + @literal + N''', DEFAULT_DATABASE = [CensoGT2018], CHECK_POLICY = ON');
ELSE
    EXEC(N'ALTER LOGIN [CensoApi] WITH PASSWORD = N''' + @literal + N'''');
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'CensoApi')
    CREATE USER [CensoApi] FOR LOGIN [CensoApi] WITH DEFAULT_SCHEMA = [dim];
GO

GRANT SELECT ON SCHEMA::dim TO [CensoApi];
GRANT SELECT ON SCHEMA::hechos TO [CensoApi];
GO
