/*
    Dimensiones de las caracteristicas del hogar (Capitulo IV de la boleta).

    Convenciones: ver docs/convenciones.md. Las llaves foraneas y los indices van en db/03-indices.
*/

USE [CensoGT2018];
GO

-- PCH1
IF OBJECT_ID(N'dim.TenenciaVivienda', N'U') IS NULL
BEGIN
    CREATE TABLE dim.TenenciaVivienda (
        TenenciaViviendaId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoTenenciaVivienda SMALLINT NOT NULL,  -- codigo original del INE
        NombreTenenciaVivienda VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_TenenciaVivienda_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_TenenciaVivienda_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_TenenciaVivienda PRIMARY KEY CLUSTERED (TenenciaViviendaId)
    );
END
GO

-- PCH4
IF OBJECT_ID(N'dim.FuenteAgua', N'U') IS NULL
BEGIN
    CREATE TABLE dim.FuenteAgua (
        FuenteAguaId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoFuenteAgua SMALLINT NOT NULL,  -- codigo original del INE
        NombreFuenteAgua VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_FuenteAgua_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_FuenteAgua_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_FuenteAgua PRIMARY KEY CLUSTERED (FuenteAguaId)
    );
END
GO

-- PCH5
IF OBJECT_ID(N'dim.TipoServicioSanitario', N'U') IS NULL
BEGIN
    CREATE TABLE dim.TipoServicioSanitario (
        TipoServicioSanitarioId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoTipoServicioSanitario SMALLINT NOT NULL,  -- codigo original del INE
        NombreTipoServicioSanitario VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_TipoServicioSanitario_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_TipoServicioSanitario_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_TipoServicioSanitario PRIMARY KEY CLUSTERED (TipoServicioSanitarioId)
    );
END
GO

-- PCH6
IF OBJECT_ID(N'dim.UsoServicioSanitario', N'U') IS NULL
BEGIN
    CREATE TABLE dim.UsoServicioSanitario (
        UsoServicioSanitarioId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoUsoServicioSanitario SMALLINT NOT NULL,  -- codigo original del INE
        NombreUsoServicioSanitario VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_UsoServicioSanitario_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_UsoServicioSanitario_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_UsoServicioSanitario PRIMARY KEY CLUSTERED (UsoServicioSanitarioId)
    );
END
GO

-- PCH7
IF OBJECT_ID(N'dim.DesagueAguasGrises', N'U') IS NULL
BEGIN
    CREATE TABLE dim.DesagueAguasGrises (
        DesagueAguasGrisesId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoDesagueAguasGrises SMALLINT NOT NULL,  -- codigo original del INE
        NombreDesagueAguasGrises VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_DesagueAguasGrises_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_DesagueAguasGrises_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_DesagueAguasGrises PRIMARY KEY CLUSTERED (DesagueAguasGrisesId)
    );
END
GO

-- PCH8
IF OBJECT_ID(N'dim.TipoAlumbrado', N'U') IS NULL
BEGIN
    CREATE TABLE dim.TipoAlumbrado (
        TipoAlumbradoId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoTipoAlumbrado SMALLINT NOT NULL,  -- codigo original del INE
        NombreTipoAlumbrado VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_TipoAlumbrado_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_TipoAlumbrado_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_TipoAlumbrado PRIMARY KEY CLUSTERED (TipoAlumbradoId)
    );
END
GO

-- PCH10
IF OBJECT_ID(N'dim.EliminacionBasura', N'U') IS NULL
BEGIN
    CREATE TABLE dim.EliminacionBasura (
        EliminacionBasuraId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoEliminacionBasura SMALLINT NOT NULL,  -- codigo original del INE
        NombreEliminacionBasura VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_EliminacionBasura_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_EliminacionBasura_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_EliminacionBasura PRIMARY KEY CLUSTERED (EliminacionBasuraId)
    );
END
GO

-- PCH14
IF OBJECT_ID(N'dim.CombustibleCocina', N'U') IS NULL
BEGIN
    CREATE TABLE dim.CombustibleCocina (
        CombustibleCocinaId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoCombustibleCocina SMALLINT NOT NULL,  -- codigo original del INE
        NombreCombustibleCocina VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_CombustibleCocina_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_CombustibleCocina_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_CombustibleCocina PRIMARY KEY CLUSTERED (CombustibleCocinaId)
    );
END
GO

-- Derivada en el ETL del parentesco (PCP5) de los miembros del hogar; tipologia del cuadro B8 del INE: 1 unipersonal, 2 nuclear, 3 extendido, 4 compuesto, 5 co-residentes
IF OBJECT_ID(N'dim.TipoHogar', N'U') IS NULL
BEGIN
    CREATE TABLE dim.TipoHogar (
        TipoHogarId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoTipoHogar SMALLINT NOT NULL,  -- codigo del proyecto (clasificacion publicada por el INE)
        NombreTipoHogar VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_TipoHogar_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_TipoHogar_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_TipoHogar PRIMARY KEY CLUSTERED (TipoHogarId)
    );
END
GO
