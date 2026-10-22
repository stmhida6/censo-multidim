/*
    Vacia las dimensiones y los hechos para poder repetir la carga completa (los scripts 03 y 04 se
    niegan a cargar sobre tablas con datos). No toca stage ni la estructura del modelo.
    Orden: hechos de abajo hacia arriba en la jerarquia, luego dimensiones de las hojas hacia el territorio.
*/

USE [CensoGT2018];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

-- Sin referencias entrantes: se pueden truncar
TRUNCATE TABLE hechos.CensoPoblacion;
TRUNCATE TABLE hechos.CensoMigracion;
-- Referenciadas por otras tablas: DELETE y reinicio de la identidad
DELETE FROM hechos.CensoHogar;
DELETE FROM hechos.CensoVivienda;
DBCC CHECKIDENT ('hechos.CensoHogar', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('hechos.CensoVivienda', RESEED, 0) WITH NO_INFOMSGS;

DELETE FROM dim.LugarPoblado;
DELETE FROM dim.Municipio;

DECLARE @sql NVARCHAR(MAX) = N'';
SELECT @sql += N'DELETE FROM dim.' + QUOTENAME(t.name) + N'; '
FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name = 'dim' AND t.name NOT IN ('LugarPoblado', 'Municipio');
EXEC sp_executesql @sql;

SET @sql = N'';
SELECT @sql += N'DBCC CHECKIDENT (''dim.' + t.name + N''', RESEED, 0) WITH NO_INFOMSGS; '
FROM sys.tables t JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.identity_columns ic ON ic.object_id = t.object_id
WHERE s.name = 'dim';
EXEC sp_executesql @sql;

PRINT 'Modelo vaciado: dimensiones y hechos sin filas, identidades reiniciadas.';
GO
