/*
    Indices columnstore agrupados en los hechos de mayor volumen (tesis 2.6.2).
    CensoMigracion (242,203 filas) queda como rowstore: por debajo del millon de filas el columnstore no llena grupos de filas.
    No se crean indices no agrupados sobre las FK: se agregan solo si los planes de ejecucion de la fase de pruebas los justifican.
    Convenciones: ver docs/convenciones.md. Scripts idempotentes; ejecutar despues de db/02-dimensiones.
*/

USE [CensoGT2018];
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Hechos_CensoVivienda_Columnstore' AND object_id = OBJECT_ID(N'hechos.CensoVivienda'))
    CREATE CLUSTERED COLUMNSTORE INDEX IX_Hechos_CensoVivienda_Columnstore ON hechos.CensoVivienda;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Hechos_CensoHogar_Columnstore' AND object_id = OBJECT_ID(N'hechos.CensoHogar'))
    CREATE CLUSTERED COLUMNSTORE INDEX IX_Hechos_CensoHogar_Columnstore ON hechos.CensoHogar;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_Hechos_CensoPoblacion_Columnstore' AND object_id = OBJECT_ID(N'hechos.CensoPoblacion'))
    CREATE CLUSTERED COLUMNSTORE INDEX IX_Hechos_CensoPoblacion_Columnstore ON hechos.CensoPoblacion;
GO
