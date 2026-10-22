/*
    Hechos.CensoHogar: una fila por hogar (3,275,931).
    Origen: HOGAR_BDP.sav. El PK es NONCLUSTERED para permitir un indice columnstore agrupado en 03-indices.
    Convenciones: ver docs/convenciones.md. Las llaves foraneas y los indices van en db/03-indices.
*/

USE [CensoGT2018];
GO

IF OBJECT_ID(N'hechos.CensoHogar', N'U') IS NULL
BEGIN
    CREATE TABLE hechos.CensoHogar (
        HogarId                   INT IDENTITY(1,1) NOT NULL,  -- llave sustituta
        ViviendaId                INT NOT NULL,  -- hechos.CensoVivienda
        LugarPobladoId            SMALLINT NOT NULL,  -- copiado de la vivienda para consultar territorio sin unir
        NumeroHogar               TINYINT NOT NULL,  -- NUM_HOGAR (degenerada; 1 a 10)
        TenenciaViviendaId        SMALLINT NOT NULL,  -- PCH1 -> dim.TenenciaVivienda
        SexoPropietarioId         SMALLINT NULL,  -- PCH2; nulo si la vivienda no es propia -> dim.SexoResponsable
        SexoDecisionesId          SMALLINT NOT NULL,  -- PCH3 -> dim.SexoResponsable
        FuenteAguaId              SMALLINT NOT NULL,  -- PCH4 -> dim.FuenteAgua
        TipoServicioSanitarioId   SMALLINT NOT NULL,  -- PCH5 -> dim.TipoServicioSanitario
        UsoServicioSanitarioId    SMALLINT NULL,  -- PCH6; nulo si no tiene servicio sanitario -> dim.UsoServicioSanitario
        DesagueAguasGrisesId      SMALLINT NOT NULL,  -- PCH7 -> dim.DesagueAguasGrises
        TipoAlumbradoId           SMALLINT NOT NULL,  -- PCH8 -> dim.TipoAlumbrado
        TieneRadio                BIT NOT NULL,  -- PCH9_A
        TieneEstufa               BIT NOT NULL,  -- PCH9_B
        TieneTelevisor            BIT NOT NULL,  -- PCH9_C
        TieneCable                BIT NOT NULL,  -- PCH9_D
        TieneRefrigeradora        BIT NOT NULL,  -- PCH9_E
        TieneTanqueAgua           BIT NOT NULL,  -- PCH9_F
        TieneLavadora             BIT NOT NULL,  -- PCH9_G
        TieneComputadora          BIT NOT NULL,  -- PCH9_H
        TieneInternet             BIT NOT NULL,  -- PCH9_I
        TieneTemazcal             BIT NOT NULL,  -- PCH9_J
        TieneAguaCaliente         BIT NOT NULL,  -- PCH9_K
        TieneMoto                 BIT NOT NULL,  -- PCH9_L
        TieneCarro                BIT NOT NULL,  -- PCH9_M
        EliminacionBasuraId       SMALLINT NOT NULL,  -- PCH10 -> dim.EliminacionBasura
        TotalCuartos              TINYINT NOT NULL,  -- PCH11
        TotalDormitorios          TINYINT NOT NULL,  -- PCH12
        TieneCuartoCocina         BIT NOT NULL,  -- PCH13
        CombustibleCocinaId       SMALLINT NOT NULL,  -- PCH14 -> dim.CombustibleCocina
        TieneRemesas              BIT NOT NULL,  -- PCH15
        TieneEmigrantes           BIT NOT NULL,  -- PEI1
        TotalEmigrantes           TINYINT NULL,  -- PEI2; nulo si el hogar no tiene emigrantes
        TotalEmigrantesConDetalle TINYINT NULL,  -- PEI2_E
        TotalPersonas             TINYINT NOT NULL,  -- TOTAL_PERS; igual al conteo de personas del hogar (verificado)
        TipoHogarId               SMALLINT NOT NULL,  -- derivada del parentesco de los miembros (cuadro B8) -> dim.TipoHogar
        FechaCreacion DATETIME2(0) NOT NULL CONSTRAINT DF_Hechos_CensoHogar_FechaCreacion DEFAULT (SYSUTCDATETIME()),
        FechaModificacion DATETIME2(0) NULL,
        UsuarioCreacion VARCHAR(128) NOT NULL CONSTRAINT DF_Hechos_CensoHogar_UsuarioCreacion DEFAULT (SUSER_SNAME()),
        CONSTRAINT PK_Hechos_CensoHogar PRIMARY KEY NONCLUSTERED (HogarId)
    );
END
GO

