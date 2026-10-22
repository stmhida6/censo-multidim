/*
    Dimensiones de las caracteristicas de la persona (Capitulo VII de la boleta) y derivadas.

    Convenciones: ver docs/convenciones.md. Las llaves foraneas y los indices van en db/03-indices.
*/

USE [CensoGT2018];
GO

-- PCP5
IF OBJECT_ID(N'dim.Parentesco', N'U') IS NULL
BEGIN
    CREATE TABLE dim.Parentesco (
        ParentescoId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoParentesco SMALLINT NOT NULL,  -- codigo original del INE
        NombreParentesco VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_Parentesco_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_Parentesco_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_Parentesco PRIMARY KEY CLUSTERED (ParentescoId)
    );
END
GO

-- PCP11
IF OBJECT_ID(N'dim.TipoResidencia2013', N'U') IS NULL
BEGIN
    CREATE TABLE dim.TipoResidencia2013 (
        TipoResidencia2013Id     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoTipoResidencia2013 SMALLINT NOT NULL,  -- codigo original del INE
        NombreTipoResidencia2013 VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_TipoResidencia2013_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_TipoResidencia2013_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_TipoResidencia2013 PRIMARY KEY CLUSTERED (TipoResidencia2013Id)
    );
END
GO

-- PCP12
IF OBJECT_ID(N'dim.Pueblo', N'U') IS NULL
BEGIN
    CREATE TABLE dim.Pueblo (
        PuebloId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoPueblo SMALLINT NOT NULL,  -- codigo original del INE
        NombrePueblo VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_Pueblo_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_Pueblo_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_Pueblo PRIMARY KEY CLUSTERED (PuebloId)
    );
END
GO

-- PCP13
IF OBJECT_ID(N'dim.ComunidadLinguistica', N'U') IS NULL
BEGIN
    CREATE TABLE dim.ComunidadLinguistica (
        ComunidadLinguisticaId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoComunidadLinguistica SMALLINT NOT NULL,  -- codigo original del INE
        NombreComunidadLinguistica VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_ComunidadLinguistica_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_ComunidadLinguistica_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_ComunidadLinguistica PRIMARY KEY CLUSTERED (ComunidadLinguisticaId)
    );
END
GO

-- PCP16_A a PCP16_F
IF OBJECT_ID(N'dim.GradoDificultad', N'U') IS NULL
BEGIN
    CREATE TABLE dim.GradoDificultad (
        GradoDificultadId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoGradoDificultad SMALLINT NOT NULL,  -- codigo original del INE
        NombreGradoDificultad VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_GradoDificultad_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_GradoDificultad_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_GradoDificultad PRIMARY KEY CLUSTERED (GradoDificultadId)
    );
END
GO

-- NIVGRADO (nivel y grado, derivada por el INE)
IF OBJECT_ID(N'dim.NivelGrado', N'U') IS NULL
BEGIN
    CREATE TABLE dim.NivelGrado (
        NivelGradoId         SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoNivelGrado     SMALLINT NOT NULL,  -- codigo original del INE
        NombreNivelGrado     VARCHAR(200) NOT NULL,
        CodigoNivelEducativo SMALLINT NULL,  -- PCP17_A; se obtiene de NIVGRADO (verificado)
        NombreNivelEducativo VARCHAR(100) NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_NivelGrado_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_NivelGrado_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_NivelGrado PRIMARY KEY CLUSTERED (NivelGradoId)
    );
END
GO

-- PCP19
IF OBJECT_ID(N'dim.TipoEstablecimiento', N'U') IS NULL
BEGIN
    CREATE TABLE dim.TipoEstablecimiento (
        TipoEstablecimientoId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoTipoEstablecimiento SMALLINT NOT NULL,  -- codigo original del INE
        NombreTipoEstablecimiento VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_TipoEstablecimiento_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_TipoEstablecimiento_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_TipoEstablecimiento PRIMARY KEY CLUSTERED (TipoEstablecimientoId)
    );
END
GO

-- PCP21
IF OBJECT_ID(N'dim.CausaNoAsistencia', N'U') IS NULL
BEGIN
    CREATE TABLE dim.CausaNoAsistencia (
        CausaNoAsistenciaId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoCausaNoAsistencia SMALLINT NOT NULL,  -- codigo original del INE
        NombreCausaNoAsistencia VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_CausaNoAsistencia_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_CausaNoAsistencia_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_CausaNoAsistencia PRIMARY KEY CLUSTERED (CausaNoAsistenciaId)
    );
END
GO

-- PCP28
IF OBJECT_ID(N'dim.ActividadSemana', N'U') IS NULL
BEGIN
    CREATE TABLE dim.ActividadSemana (
        ActividadSemanaId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoActividadSemana SMALLINT NOT NULL,  -- codigo original del INE
        NombreActividadSemana VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_ActividadSemana_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_ActividadSemana_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_ActividadSemana PRIMARY KEY CLUSTERED (ActividadSemanaId)
    );
END
GO

-- PCP29
IF OBJECT_ID(N'dim.ActividadNoTrabajo', N'U') IS NULL
BEGIN
    CREATE TABLE dim.ActividadNoTrabajo (
        ActividadNoTrabajoId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoActividadNoTrabajo SMALLINT NOT NULL,  -- codigo original del INE
        NombreActividadNoTrabajo VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_ActividadNoTrabajo_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_ActividadNoTrabajo_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_ActividadNoTrabajo PRIMARY KEY CLUSTERED (ActividadNoTrabajoId)
    );
END
GO

-- PCP30_2D (grano de 2 digitos); PCP30_1D es el grupo
IF OBJECT_ID(N'dim.Ocupacion', N'U') IS NULL
BEGIN
    CREATE TABLE dim.Ocupacion (
        OcupacionId          SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoOcupacion      SMALLINT NOT NULL,  -- codigo original del INE
        NombreOcupacion      VARCHAR(200) NOT NULL,
        CodigoGrupoOcupacion SMALLINT NULL,  -- PCP30_1D
        NombreGrupoOcupacion VARCHAR(200) NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_Ocupacion_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_Ocupacion_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_Ocupacion PRIMARY KEY CLUSTERED (OcupacionId)
    );
END
GO

-- PCP32_2D (grano de 2 digitos); PCP32_1D es el grupo
IF OBJECT_ID(N'dim.RamaActividad', N'U') IS NULL
BEGIN
    CREATE TABLE dim.RamaActividad (
        RamaActividadId          SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoRamaActividad      SMALLINT NOT NULL,  -- codigo original del INE
        NombreRamaActividad      VARCHAR(200) NOT NULL,
        CodigoGrupoRamaActividad SMALLINT NULL,  -- PCP32_1D
        NombreGrupoRamaActividad VARCHAR(200) NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_RamaActividad_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_RamaActividad_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_RamaActividad PRIMARY KEY CLUSTERED (RamaActividadId)
    );
END
GO

-- PCP31_D
IF OBJECT_ID(N'dim.CategoriaOcupacional', N'U') IS NULL
BEGIN
    CREATE TABLE dim.CategoriaOcupacional (
        CategoriaOcupacionalId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoCategoriaOcupacional SMALLINT NOT NULL,  -- codigo original del INE
        NombreCategoriaOcupacional VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_CategoriaOcupacional_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_CategoriaOcupacional_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_CategoriaOcupacional PRIMARY KEY CLUSTERED (CategoriaOcupacionalId)
    );
END
GO

-- PCP34
IF OBJECT_ID(N'dim.EstadoConyugal', N'U') IS NULL
BEGIN
    CREATE TABLE dim.EstadoConyugal (
        EstadoConyugalId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoEstadoConyugal SMALLINT NOT NULL,  -- codigo original del INE
        NombreEstadoConyugal VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_EstadoConyugal_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_EstadoConyugal_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_EstadoConyugal PRIMARY KEY CLUSTERED (EstadoConyugalId)
    );
END
GO

-- Derivada en el ETL desde PEA, POCUPA, PDESOC y PEI. Codigos del proyecto: 1 ocupada, 2 desocupada aspirante, 3 desocupada cesante, 4 inactiva, 5 no declarada
IF OBJECT_ID(N'dim.CondicionActividad', N'U') IS NULL
BEGIN
    CREATE TABLE dim.CondicionActividad (
        CondicionActividadId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoCondicionActividad SMALLINT NOT NULL,  -- codigo original del INE
        NombreCondicionActividad VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_CondicionActividad_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_CondicionActividad_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_CondicionActividad PRIMARY KEY CLUSTERED (CondicionActividadId)
    );
END
GO

-- Derivada en el ETL de las 6 preguntas de dificultad (PCP16_A a PCP16_F); clasificacion del cuadro A8 del INE: 1 sin dificultad, 2 con al menos una dificultad, 9 no declarado
IF OBJECT_ID(N'dim.CondicionDificultad', N'U') IS NULL
BEGIN
    CREATE TABLE dim.CondicionDificultad (
        CondicionDificultadId     SMALLINT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        CodigoCondicionDificultad SMALLINT NOT NULL,  -- codigo del proyecto (clasificacion publicada por el INE)
        NombreCondicionDificultad VARCHAR(200) NOT NULL,
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Dim_CondicionDificultad_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Dim_CondicionDificultad_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Dim_CondicionDificultad PRIMARY KEY CLUSTERED (CondicionDificultadId)
    );
END
GO
