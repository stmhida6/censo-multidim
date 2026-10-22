/*
    Dimensiones de territorio: Departamento -> Municipio -> LugarPoblado.
    Ver etl/plan-etl.md y etl/clasificacion-variables.md.
    Convenciones: ver docs/convenciones.md. Las llaves foraneas y los indices van en db/03-indices.
*/

USE [CensoGT2018];
GO

-- 22 departamentos (DEPARTAMENTO)
IF OBJECT_ID(N'dim.Departamento', N'U') IS NULL
BEGIN
    CREATE TABLE dim.Departamento (
        DepartamentoId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoDepartamento SMALLINT NOT NULL,  -- codigo original del INE
        NombreDepartamento VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_Departamento_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_Departamento_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_Departamento PRIMARY KEY CLUSTERED (DepartamentoId)
    );
END
GO

-- 340 municipios + 22 miembros 'municipio no declarado' (MUNICIPIO, LUGNACGEO, RESCINGEO, ESTUDIAGEO, TRABAJAGEO)
IF OBJECT_ID(N'dim.Municipio', N'U') IS NULL
BEGIN
    CREATE TABLE dim.Municipio (
        MunicipioId            SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoMunicipio        SMALLINT NOT NULL,  -- codigo original del INE
        NombreMunicipio        VARCHAR(200) NOT NULL,
        DepartamentoId         SMALLINT NOT NULL,  -- jerarquia Departamento -> Municipio
        EsMunicipioNoDeclarado BIT NOT NULL,  -- 1 para los codigos 199, 299, ..., 2299
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_Municipio_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_Municipio_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_Municipio PRIMARY KEY CLUSTERED (MunicipioId)
    );
END
GO

-- 20,254 lugares poblados (LUGAR_POBLADO)
IF OBJECT_ID(N'dim.LugarPoblado', N'U') IS NULL
BEGIN
    CREATE TABLE dim.LugarPoblado (
        LugarPobladoId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoLugarPoblado INT NOT NULL,  -- LUGAR_POBLADO; unico a nivel nacional
        NombreLugarPoblado VARCHAR(200) NOT NULL,  -- NOMBRE_LUGAR_POBLADO
        MunicipioId        SMALLINT NOT NULL,  -- jerarquia Municipio -> LugarPoblado
        Zona               SMALLINT NOT NULL,  -- ZONA; constante por lugar poblado
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_LugarPoblado_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_LugarPoblado_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_LugarPoblado PRIMARY KEY CLUSTERED (LugarPobladoId)
    );
END
GO

