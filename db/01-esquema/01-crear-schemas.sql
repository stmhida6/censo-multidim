/*
    Creacion de los schemas de SQL Server para el modelo multidimensional
    del Censo de Poblacion y Vivienda 2018 de Guatemala.

    Orden de ejecucion: 01-esquema -> 02-dimensiones -> 03-indices
*/

USE [CensoGT2018];
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'dim')
BEGIN
    EXEC('CREATE SCHEMA dim');
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'hechos')
BEGIN
    EXEC('CREATE SCHEMA hechos');
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'stage')
BEGIN
    EXEC('CREATE SCHEMA stage');
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'seg')
BEGIN
    EXEC('CREATE SCHEMA seg');
END
GO
