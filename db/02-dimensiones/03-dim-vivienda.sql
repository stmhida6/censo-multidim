/*
    Dimensiones de las caracteristicas de la vivienda (Capitulo II de la boleta).

    Convenciones: ver docs/convenciones.md. Las llaves foraneas y los indices van en db/03-indices.
*/

USE [CensoGT2018];
GO

-- PCV1
IF OBJECT_ID(N'dim.TipoVivienda', N'U') IS NULL
BEGIN
    CREATE TABLE dim.TipoVivienda (
        TipoViviendaId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoTipoVivienda SMALLINT NOT NULL,  -- codigo original del INE
        NombreTipoVivienda VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_TipoVivienda_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_TipoVivienda_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_TipoVivienda PRIMARY KEY CLUSTERED (TipoViviendaId)
    );
END
GO

-- PCV2
IF OBJECT_ID(N'dim.MaterialPared', N'U') IS NULL
BEGIN
    CREATE TABLE dim.MaterialPared (
        MaterialParedId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoMaterialPared SMALLINT NOT NULL,  -- codigo original del INE
        NombreMaterialPared VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_MaterialPared_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_MaterialPared_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_MaterialPared PRIMARY KEY CLUSTERED (MaterialParedId)
    );
END
GO

-- PCV3
IF OBJECT_ID(N'dim.MaterialTecho', N'U') IS NULL
BEGIN
    CREATE TABLE dim.MaterialTecho (
        MaterialTechoId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoMaterialTecho SMALLINT NOT NULL,  -- codigo original del INE
        NombreMaterialTecho VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_MaterialTecho_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_MaterialTecho_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_MaterialTecho PRIMARY KEY CLUSTERED (MaterialTechoId)
    );
END
GO

-- PCV4 (incluye el codigo 4, moradores ausentes o rechazo total)
IF OBJECT_ID(N'dim.CondicionVivienda', N'U') IS NULL
BEGIN
    CREATE TABLE dim.CondicionVivienda (
        CondicionViviendaId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoCondicionVivienda SMALLINT NOT NULL,  -- codigo original del INE
        NombreCondicionVivienda VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_CondicionVivienda_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_CondicionVivienda_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_CondicionVivienda PRIMARY KEY CLUSTERED (CondicionViviendaId)
    );
END
GO

-- PCV5
IF OBJECT_ID(N'dim.MaterialPiso', N'U') IS NULL
BEGIN
    CREATE TABLE dim.MaterialPiso (
        MaterialPisoId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoMaterialPiso SMALLINT NOT NULL,  -- codigo original del INE
        NombreMaterialPiso VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_MaterialPiso_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_MaterialPiso_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_MaterialPiso PRIMARY KEY CLUSTERED (MaterialPisoId)
    );
END
GO

