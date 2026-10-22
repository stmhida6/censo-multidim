/*
    Carga los CSV de /datos/csv (carpeta datos/ del repositorio montada en el contenedor) a stage.
    Requiere haber ejecutado antes etl/r/10-exportar-catalogos.R y etl/r/11-exportar-microdatos.R.
    FORMAT = 'CSV' interpreta el encabezado (FIRSTROW = 2) y los campos entre comillas; los campos vacios
    quedan como NULL (KEEPNULLS). En Linux no existe CODEPAGE y los archivos de caracteres se leen con la
    pagina de codigos OEM 437 (sin Á, Í, Ó, Ú): los CSV con texto (catalogo y lugarpoblado) los exporta R en
    UTF-16LE con BOM y se cargan con DATAFILETYPE = 'widechar'; los numericos se cargan como caracteres.
*/

USE [CensoGT2018];
GO

SET NOCOUNT ON;
DECLARE @inicio DATETIME2 = SYSUTCDATETIME(), @n BIGINT;

TRUNCATE TABLE stage.Catalogo;
BULK INSERT stage.Catalogo FROM '/datos/csv/catalogo.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, DATAFILETYPE = 'widechar', FIELDTERMINATOR = ',', ROWTERMINATOR = '\r\n',
      KEEPNULLS, BATCHSIZE = 1000000, TABLOCK);
SELECT @n = COUNT_BIG(*) FROM stage.Catalogo;
PRINT 'stage.Catalogo: ' + FORMAT(@n, 'N0') + ' filas, ' + CAST(DATEDIFF(SECOND, @inicio, SYSUTCDATETIME()) AS VARCHAR(10)) + ' s acumulados';

TRUNCATE TABLE stage.Jerarquia;
BULK INSERT stage.Jerarquia FROM '/datos/csv/jerarquias.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0d0a',
      KEEPNULLS, BATCHSIZE = 1000000, TABLOCK);
SELECT @n = COUNT_BIG(*) FROM stage.Jerarquia;
PRINT 'stage.Jerarquia: ' + FORMAT(@n, 'N0') + ' filas, ' + CAST(DATEDIFF(SECOND, @inicio, SYSUTCDATETIME()) AS VARCHAR(10)) + ' s acumulados';

TRUNCATE TABLE stage.LugarPoblado;
BULK INSERT stage.LugarPoblado FROM '/datos/csv/lugarpoblado.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, DATAFILETYPE = 'widechar', FIELDTERMINATOR = ',', ROWTERMINATOR = '\r\n',
      KEEPNULLS, BATCHSIZE = 1000000, TABLOCK);
SELECT @n = COUNT_BIG(*) FROM stage.LugarPoblado;
PRINT 'stage.LugarPoblado: ' + FORMAT(@n, 'N0') + ' filas, ' + CAST(DATEDIFF(SECOND, @inicio, SYSUTCDATETIME()) AS VARCHAR(10)) + ' s acumulados';

TRUNCATE TABLE stage.Vivienda;
BULK INSERT stage.Vivienda FROM '/datos/csv/vivienda.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0d0a',
      KEEPNULLS, BATCHSIZE = 1000000, TABLOCK);
SELECT @n = COUNT_BIG(*) FROM stage.Vivienda;
PRINT 'stage.Vivienda: ' + FORMAT(@n, 'N0') + ' filas, ' + CAST(DATEDIFF(SECOND, @inicio, SYSUTCDATETIME()) AS VARCHAR(10)) + ' s acumulados';

TRUNCATE TABLE stage.Hogar;
BULK INSERT stage.Hogar FROM '/datos/csv/hogar.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0d0a',
      KEEPNULLS, BATCHSIZE = 1000000, TABLOCK);
SELECT @n = COUNT_BIG(*) FROM stage.Hogar;
PRINT 'stage.Hogar: ' + FORMAT(@n, 'N0') + ' filas, ' + CAST(DATEDIFF(SECOND, @inicio, SYSUTCDATETIME()) AS VARCHAR(10)) + ' s acumulados';

TRUNCATE TABLE stage.Migracion;
BULK INSERT stage.Migracion FROM '/datos/csv/migracion.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0d0a',
      KEEPNULLS, BATCHSIZE = 1000000, TABLOCK);
SELECT @n = COUNT_BIG(*) FROM stage.Migracion;
PRINT 'stage.Migracion: ' + FORMAT(@n, 'N0') + ' filas, ' + CAST(DATEDIFF(SECOND, @inicio, SYSUTCDATETIME()) AS VARCHAR(10)) + ' s acumulados';

TRUNCATE TABLE stage.Persona;
BULK INSERT stage.Persona FROM '/datos/csv/persona.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '0x0d0a',
      KEEPNULLS, BATCHSIZE = 1000000, TABLOCK);
SELECT @n = COUNT_BIG(*) FROM stage.Persona;
PRINT 'stage.Persona: ' + FORMAT(@n, 'N0') + ' filas, ' + CAST(DATEDIFF(SECOND, @inicio, SYSUTCDATETIME()) AS VARCHAR(10)) + ' s acumulados';

GO
