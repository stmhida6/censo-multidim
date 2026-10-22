/*
    Hechos.CensoPoblacion: una fila por persona (14,901,286).
    Origen: PERSONA - BDP.sav. El PK es NONCLUSTERED para permitir un indice columnstore agrupado en 03-indices.
    Convenciones: ver docs/convenciones.md. Las llaves foraneas y los indices van en db/03-indices.
*/

USE [CensoGT2018];
GO

IF OBJECT_ID(N'hechos.CensoPoblacion', N'U') IS NULL
BEGIN
    CREATE TABLE hechos.CensoPoblacion (
        PersonaId                    INT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        ViviendaId                   INT NOT NULL,  -- hechos.CensoVivienda
        HogarId                      INT NULL,  -- hechos.CensoHogar; nulo en vivienda colectiva y sin vivienda (43,752 personas)
        LugarPobladoId               SMALLINT NOT NULL,  -- copiado de la vivienda para consultar territorio sin unir
        NumeroPersona                SMALLINT NOT NULL,  -- PCP1 (degenerada; hasta 4,842 en viviendas colectivas)
        ParentescoId                 SMALLINT NOT NULL,  -- PCP5 -> dim.Parentesco
        SexoId                       SMALLINT NOT NULL,  -- PCP6 -> dim.Sexo
        EdadId                       TINYINT NOT NULL,  -- PCP7 -> dim.Edad
        InscripcionRenapId           SMALLINT NOT NULL,  -- PCP9; incluye el codigo 9 (no declarado), 241,578 personas -> dim.RespuestaSiNo
        TipoLugarNacimientoId        SMALLINT NOT NULL,  -- PCP10 -> dim.TipoLugar
        DepartamentoNacimientoId     SMALLINT NULL,  -- PCP10_B -> dim.Departamento
        MunicipioNacimientoId        SMALLINT NULL,  -- LUGNACGEO -> dim.Municipio
        PaisNacimientoId             SMALLINT NULL,  -- PCP10_C -> dim.Pais
        AnioLlegadaPais              SMALLINT NULL,  -- PCP10_D; 9999 (no declarado) se guarda como NULL
        TipoResidencia2013Id         SMALLINT NOT NULL,  -- PCP11 -> dim.TipoResidencia2013
        DepartamentoResidencia2013Id SMALLINT NULL,  -- PCP11_B -> dim.Departamento
        MunicipioResidencia2013Id    SMALLINT NULL,  -- RESCINGEO -> dim.Municipio
        PaisResidencia2013Id         SMALLINT NULL,  -- PCP11_C -> dim.Pais
        PuebloId                     SMALLINT NOT NULL,  -- PCP12 -> dim.Pueblo
        ComunidadLinguisticaId       SMALLINT NULL,  -- PCP13; solo si PCP12 = 1 -> dim.ComunidadLinguistica
        UsoTrajeTradicionalId        SMALLINT NULL,  -- PCP14; solo si PCP12 = 1 a 4; incluye el codigo 9 (no declarado), 371,419 personas -> dim.RespuestaSiNo
        IdiomaMaternoId              SMALLINT NULL,  -- PCP15 -> dim.Idioma
        DificultadVerId              SMALLINT NULL,  -- PCP16_A -> dim.GradoDificultad
        DificultadOirId              SMALLINT NULL,  -- PCP16_B -> dim.GradoDificultad
        DificultadCaminarId          SMALLINT NULL,  -- PCP16_C -> dim.GradoDificultad
        DificultadRecordarId         SMALLINT NULL,  -- PCP16_D -> dim.GradoDificultad
        DificultadCuidadoPersonalId  SMALLINT NULL,  -- PCP16_E -> dim.GradoDificultad
        DificultadComunicarseId      SMALLINT NULL,  -- PCP16_F -> dim.GradoDificultad
        CondicionDificultadId        SMALLINT NULL,  -- derivada de PCP16_A a PCP16_F (cuadro A8); nulo si tiene menos de 4 anios -> dim.CondicionDificultad
        NivelGradoId                 SMALLINT NULL,  -- NIVGRADO -> dim.NivelGrado
        GradoMasAltoAprobado         TINYINT NULL,  -- PCP17_B
        AniosEstudio                 TINYINT NULL,  -- ANEDUCA
        EsEstudiante                 BIT NULL,  -- PCP18
        TipoEstablecimientoId        SMALLINT NULL,  -- PCP19 -> dim.TipoEstablecimiento
        TipoLugarEstudioId           SMALLINT NULL,  -- PCP20 -> dim.TipoLugar
        DepartamentoEstudioId        SMALLINT NULL,  -- PCP20_B -> dim.Departamento
        MunicipioEstudioId           SMALLINT NULL,  -- ESTUDIAGEO -> dim.Municipio
        PaisEstudioId                SMALLINT NULL,  -- PCP20_C -> dim.Pais
        CausaNoAsistenciaId          SMALLINT NULL,  -- PCP21 -> dim.CausaNoAsistencia
        EsAlfabeta                   BIT NULL,  -- PCP22
        IdiomaLecturaEscritura1Id    SMALLINT NULL,  -- PCP23_A -> dim.Idioma
        IdiomaLecturaEscritura2Id    SMALLINT NULL,  -- PCP23_B -> dim.Idioma
        IdiomaLecturaEscritura3Id    SMALLINT NULL,  -- PCP23_C -> dim.Idioma
        TieneOtroIdioma              BIT NULL,  -- PCP24
        OtroIdioma1Id                SMALLINT NULL,  -- PCP25_A -> dim.Idioma
        OtroIdioma2Id                SMALLINT NULL,  -- PCP25_B -> dim.Idioma
        OtroIdioma3Id                SMALLINT NULL,  -- PCP25_C -> dim.Idioma
        UsoCelularId                 SMALLINT NULL,  -- PCP26_A -> dim.RespuestaSiNo
        UsoComputadoraId             SMALLINT NULL,  -- PCP26_B -> dim.RespuestaSiNo
        UsoInternetId                SMALLINT NULL,  -- PCP26_C -> dim.RespuestaSiNo
        EsTrabajadorSemanaPasada     BIT NULL,  -- PCP27
        ActividadSemanaId            SMALLINT NULL,  -- PCP28 -> dim.ActividadSemana
        ActividadNoTrabajoId         SMALLINT NULL,  -- PCP29 -> dim.ActividadNoTrabajo
        OcupacionId                  SMALLINT NULL,  -- PCP30_2D -> dim.Ocupacion
        CategoriaOcupacionalId       SMALLINT NULL,  -- PCP31_D -> dim.CategoriaOcupacional
        RamaActividadId              SMALLINT NULL,  -- PCP32_2D -> dim.RamaActividad
        TipoLugarTrabajoId           SMALLINT NULL,  -- PCP33 -> dim.TipoLugar
        DepartamentoTrabajoId        SMALLINT NULL,  -- PCP33_B -> dim.Departamento
        MunicipioTrabajoId           SMALLINT NULL,  -- TRABAJAGEO -> dim.Municipio
        PaisTrabajoId                SMALLINT NULL,  -- PCP33_C -> dim.Pais
        EstadoConyugalId             SMALLINT NULL,  -- PCP34 -> dim.EstadoConyugal
        HijosNacidosVivos            TINYINT NULL,  -- PCP35_A; 99 (no declarado) se guarda como NULL
        HijosNacidosVivosMujeres     TINYINT NULL,  -- PCP35_B
        HijosNacidosVivosHombres     TINYINT NULL,  -- PCP35_C
        HijosSobrevivientes          TINYINT NULL,  -- PCP36_A
        HijosSobrevivientesMujeres   TINYINT NULL,  -- PCP36_B
        HijosSobrevivientesHombres   TINYINT NULL,  -- PCP36_C
        EdadPrimerHijo               TINYINT NULL,  -- PCP37; 99 se guarda como NULL
        DiaUltimoHijo                TINYINT NULL,  -- PCP38_A; 99 se guarda como NULL
        MesUltimoHijo                TINYINT NULL,  -- PCP38_B; 99 se guarda como NULL
        AnioUltimoHijo               SMALLINT NULL,  -- PCP38_C; 9999 se guarda como NULL
        EsVivoUltimoHijo             BIT NULL,  -- PCP39
        CondicionActividadId         SMALLINT NULL,  -- derivada de PEA, POCUPA, PDESOC y PEI; nulo si tiene menos de 7 anios -> dim.CondicionActividad
        EsMigranteVida               BIT NULL,  -- MIGRA_VIDA = 2 (1 = no migrante); nulo si PCP10 = no declarado
        EsMigranteReciente           BIT NULL,  -- MIGRA_REC = 2 (1 = no migrante); nulo si PCP11 = no declarado
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Hechos_CensoPoblacion_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Hechos_CensoPoblacion_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Hechos_CensoPoblacion PRIMARY KEY NONCLUSTERED (PersonaId)
    );
END
GO

