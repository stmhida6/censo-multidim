/*
    Dimensiones transversales compartidas por varios hechos (role-playing).
    Dim.Edad usa la edad en anios como llave; las demas usan llave sustituta.
    Convenciones: ver docs/convenciones.md. Las llaves foraneas y los indices van en db/03-indices.
*/

USE [CensoGT2018];
GO

-- PCP6, PEI3
IF OBJECT_ID(N'dim.Sexo', N'U') IS NULL
BEGIN
    CREATE TABLE dim.Sexo (
        SexoId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoSexo SMALLINT NOT NULL,  -- codigo original del INE
        NombreSexo VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_Sexo_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_Sexo_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_Sexo PRIMARY KEY CLUSTERED (SexoId)
    );
END
GO

-- PCP7, PEI4
IF OBJECT_ID(N'dim.Edad', N'U') IS NULL
BEGIN
    CREATE TABLE dim.Edad (
        EdadId               TINYINT NOT NULL,  -- edad en anios cumplidos (0 a 124); llave natural, sin IDENTITY
        GrupoQuinquenal      VARCHAR(12) NOT NULL,  -- 0-4, 5-9, ..., 100 y mas
        OrdenGrupoQuinquenal TINYINT NOT NULL,  -- orden de presentacion del grupo
        GrupoAmplio          VARCHAR(12) NOT NULL,  -- 0-14, 15-64, 65 y mas (relacion de dependencia)
        EsEdadTrabajar       BIT NOT NULL,  -- 1 si tiene 15 anios o mas (PET del glosario)
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_Edad_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_Edad_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_Edad PRIMARY KEY CLUSTERED (EdadId)
    );
END
GO

-- PCP9, PCP14, PCP26_A, PCP26_B, PCP26_C (Si, No y No declarado)
IF OBJECT_ID(N'dim.RespuestaSiNo', N'U') IS NULL
BEGIN
    CREATE TABLE dim.RespuestaSiNo (
        RespuestaSiNoId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoRespuestaSiNo SMALLINT NOT NULL,  -- codigo original del INE
        NombreRespuestaSiNo VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_RespuestaSiNo_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_RespuestaSiNo_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_RespuestaSiNo PRIMARY KEY CLUSTERED (RespuestaSiNoId)
    );
END
GO

-- PCP10_C, PCP11_C, PCP20_C, PCP33_C
IF OBJECT_ID(N'dim.Pais', N'U') IS NULL
BEGIN
    CREATE TABLE dim.Pais (
        PaisId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoPais SMALLINT NOT NULL,  -- codigo original del INE
        NombrePais VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_Pais_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_Pais_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_Pais PRIMARY KEY CLUSTERED (PaisId)
    );
END
GO

-- PCP15, PCP23_A/B/C, PCP25_A/B/C
IF OBJECT_ID(N'dim.Idioma', N'U') IS NULL
BEGIN
    CREATE TABLE dim.Idioma (
        IdiomaId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoIdioma SMALLINT NOT NULL,  -- codigo original del INE
        NombreIdioma VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_Idioma_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_Idioma_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_Idioma PRIMARY KEY CLUSTERED (IdiomaId)
    );
END
GO

-- PCP10, PCP20, PCP33 (aqui / otro municipio, departamento o pais / no declarado)
IF OBJECT_ID(N'dim.TipoLugar', N'U') IS NULL
BEGIN
    CREATE TABLE dim.TipoLugar (
        TipoLugarId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoTipoLugar SMALLINT NOT NULL,  -- codigo original del INE
        NombreTipoLugar VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_TipoLugar_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_TipoLugar_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_TipoLugar PRIMARY KEY CLUSTERED (TipoLugarId)
    );
END
GO

-- PCH2, PCH3 (hombre / mujer / ambos / no declarado)
IF OBJECT_ID(N'dim.SexoResponsable', N'U') IS NULL
BEGIN
    CREATE TABLE dim.SexoResponsable (
        SexoResponsableId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoSexoResponsable SMALLINT NOT NULL,  -- codigo original del INE
        NombreSexoResponsable VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_SexoResponsable_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_SexoResponsable_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_SexoResponsable PRIMARY KEY CLUSTERED (SexoResponsableId)
    );
END
GO

