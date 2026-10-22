/*
    Hechos.CensoVivienda: una fila por vivienda (3,943,431).
    Origen: VIVIENDA_BDP.sav. El PK es NONCLUSTERED para permitir un indice columnstore agrupado en 03-indices.
    Convenciones: ver docs/convenciones.md. Las llaves foraneas y los indices van en db/03-indices.
*/

USE [CensoGT2018];
GO

IF OBJECT_ID(N'hechos.CensoVivienda', N'U') IS NULL
BEGIN
    CREATE TABLE hechos.CensoVivienda (
        ViviendaId          INT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        LugarPobladoId      SMALLINT NOT NULL,  -- LUGAR_POBLADO -> dim.LugarPoblado
        NumeroVivienda      INT NOT NULL,  -- NUM_VIVIENDA (degenerada); con LugarPobladoId identifica la vivienda
        TipoViviendaId      SMALLINT NOT NULL,  -- PCV1 -> dim.TipoVivienda
        MaterialParedId     SMALLINT NULL,  -- PCV2 -> dim.MaterialPared
        MaterialTechoId     SMALLINT NULL,  -- PCV3 -> dim.MaterialTecho
        CondicionViviendaId SMALLINT NULL,  -- PCV4; nulo en vivienda colectiva y sin vivienda -> dim.CondicionVivienda
        MaterialPisoId      SMALLINT NULL,  -- PCV5; nulo si la vivienda no esta ocupada -> dim.MaterialPiso
        EsUrbano            BIT NOT NULL,  -- AREA (no es constante por lugar poblado)
        Longitud            DECIMAL(9,6) NULL,  -- Long
        Latitud             DECIMAL(9,6) NULL,  -- Lat
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Hechos_CensoVivienda_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Hechos_CensoVivienda_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Hechos_CensoVivienda PRIMARY KEY NONCLUSTERED (ViviendaId)
    );
END
GO

