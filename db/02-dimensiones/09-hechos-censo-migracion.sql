/*
    Hechos.CensoMigracion: una fila por emigrante internacional (242,203).
    Origen: MIGRACION_BDP.sav.
    Convenciones: ver docs/convenciones.md. Las llaves foraneas y los indices van en db/03-indices.
*/

USE [CensoGT2018];
GO

IF OBJECT_ID(N'hechos.CensoMigracion', N'U') IS NULL
BEGIN
    CREATE TABLE hechos.CensoMigracion (
        MigracionId     INT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        HogarId         INT NOT NULL,  -- hechos.CensoHogar
        LugarPobladoId  SMALLINT NOT NULL,  -- copiado del hogar para consultar territorio sin unir
        NumeroEmigrante TINYINT NOT NULL,  -- ID_EMIGRACION (degenerada; 1 a 5)
        SexoId          SMALLINT NOT NULL,  -- PEI3 -> dim.Sexo
        EdadId          TINYINT NOT NULL,  -- PEI4 -> dim.Edad (edad al irse)
        AnioSalida      SMALLINT NULL,  -- PEI5; 9999 (no declarado) se guarda como NULL
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Hechos_CensoMigracion_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Hechos_CensoMigracion_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Hechos_CensoMigracion PRIMARY KEY NONCLUSTERED (MigracionId)
    );
END
GO

