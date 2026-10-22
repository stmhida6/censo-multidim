/*
    Creacion de la base de datos del sistema de consulta multidimensional
    sobre el Censo de Poblacion y Vivienda 2018 de Guatemala.

    Orden de ejecucion: 01-esquema -> 02-dimensiones -> 03-indices
*/

IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = 'CensoGT2018')
BEGIN
    CREATE DATABASE [CensoGT2018];
END
GO
