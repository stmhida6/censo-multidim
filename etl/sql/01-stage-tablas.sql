/*
    Tablas de la zona de preparacion (stage): copia de los CSV exportados desde R, sin transformar.
    Conservan los nombres de las variables del INE para poder rastrear cada columna hasta el .sav.
    Se recrean en cada corrida. Las tablas grandes usan columnstore agrupado, que comprime la carga
    (BULK INSERT con lotes de 1,000,000 filas escribe directamente grupos de filas comprimidos).
    Los textos (etiquetas y nombres de lugares poblados) se cargan como NVARCHAR desde archivos UTF-16.
    Ver etl/plan-etl.md y docs/diagramas/flujo-etl.md.
*/

USE [CensoGT2018];
GO

IF OBJECT_ID(N'stage.Catalogo', N'U') IS NOT NULL DROP TABLE stage.Catalogo;
GO
CREATE TABLE stage.Catalogo (
    Archivo  VARCHAR(20) NULL,
    Variable VARCHAR(40) NULL,
    Codigo   INT NULL,
    Etiqueta NVARCHAR(300) NULL
);
GO

IF OBJECT_ID(N'stage.Jerarquia', N'U') IS NOT NULL DROP TABLE stage.Jerarquia;
GO
CREATE TABLE stage.Jerarquia (
    Jerarquia VARCHAR(40) NULL,
    Hijo      INT NULL,
    Padre     INT NULL,
    N         BIGINT NULL
);
GO

IF OBJECT_ID(N'stage.LugarPoblado', N'U') IS NOT NULL DROP TABLE stage.LugarPoblado;
GO
CREATE TABLE stage.LugarPoblado (
    LUGAR_POBLADO        INT NULL,
    DEPARTAMENTO         INT NULL,
    MUNICIPIO            INT NULL,
    ZONA                 INT NULL,
    NOMBRE_LUGAR_POBLADO NVARCHAR(200) NULL
);
GO

IF OBJECT_ID(N'stage.Vivienda', N'U') IS NOT NULL DROP TABLE stage.Vivienda;
GO
CREATE TABLE stage.Vivienda (
    LUGAR_POBLADO INT NULL,
    NUM_VIVIENDA  INT NULL,
    AREA          INT NULL,
    PCV1          INT NULL,
    PCV2          INT NULL,
    PCV3          INT NULL,
    PCV4          INT NULL,
    PCV5          INT NULL,
    Long          FLOAT NULL,
    Lat           FLOAT NULL
);
GO
CREATE CLUSTERED COLUMNSTORE INDEX IX_Stage_Vivienda_Columnstore ON stage.Vivienda;
GO

IF OBJECT_ID(N'stage.Hogar', N'U') IS NOT NULL DROP TABLE stage.Hogar;
GO
CREATE TABLE stage.Hogar (
    LUGAR_POBLADO INT NULL,
    NUM_VIVIENDA  INT NULL,
    NUM_HOGAR     INT NULL,
    PCH1          INT NULL,
    PCH2          INT NULL,
    PCH3          INT NULL,
    PCH4          INT NULL,
    PCH5          INT NULL,
    PCH6          INT NULL,
    PCH7          INT NULL,
    PCH8          INT NULL,
    PCH9_A        INT NULL,
    PCH9_B        INT NULL,
    PCH9_C        INT NULL,
    PCH9_D        INT NULL,
    PCH9_E        INT NULL,
    PCH9_F        INT NULL,
    PCH9_G        INT NULL,
    PCH9_H        INT NULL,
    PCH9_I        INT NULL,
    PCH9_J        INT NULL,
    PCH9_K        INT NULL,
    PCH9_L        INT NULL,
    PCH9_M        INT NULL,
    PCH10         INT NULL,
    PCH11         INT NULL,
    PCH12         INT NULL,
    PCH13         INT NULL,
    PCH14         INT NULL,
    PCH15         INT NULL,
    PEI1          INT NULL,
    PEI2          INT NULL,
    PEI2_E        INT NULL,
    TOTAL_PERS    INT NULL
);
GO
CREATE CLUSTERED COLUMNSTORE INDEX IX_Stage_Hogar_Columnstore ON stage.Hogar;
GO

IF OBJECT_ID(N'stage.Migracion', N'U') IS NOT NULL DROP TABLE stage.Migracion;
GO
CREATE TABLE stage.Migracion (
    DEPARTAMENTO  INT NULL,
    MUNICIPIO     INT NULL,
    NUM_VIVIENDA  INT NULL,
    NUM_HOGAR     INT NULL,
    ID_EMIGRACION INT NULL,
    PEI3          INT NULL,
    PEI4          INT NULL,
    PEI5          INT NULL
);
GO

IF OBJECT_ID(N'stage.Persona', N'U') IS NOT NULL DROP TABLE stage.Persona;
GO
CREATE TABLE stage.Persona (
    LUGAR_POBLADO INT NULL,
    NUM_VIVIENDA  INT NULL,
    NUM_HOGAR     INT NULL,
    PCP1          INT NULL,
    PCP5          INT NULL,
    PCP6          INT NULL,
    PCP7          INT NULL,
    PCP9          INT NULL,
    PCP10         INT NULL,
    PCP10_B       INT NULL,
    LUGNACGEO     INT NULL,
    PCP10_C       INT NULL,
    PCP10_D       INT NULL,
    PCP11         INT NULL,
    PCP11_B       INT NULL,
    RESCINGEO     INT NULL,
    PCP11_C       INT NULL,
    PCP12         INT NULL,
    PCP13         INT NULL,
    PCP14         INT NULL,
    PCP15         INT NULL,
    PCP16_A       INT NULL,
    PCP16_B       INT NULL,
    PCP16_C       INT NULL,
    PCP16_D       INT NULL,
    PCP16_E       INT NULL,
    PCP16_F       INT NULL,
    PCP17_B       INT NULL,
    PCP18         INT NULL,
    PCP19         INT NULL,
    PCP20         INT NULL,
    PCP20_B       INT NULL,
    ESTUDIAGEO    INT NULL,
    PCP20_C       INT NULL,
    PCP21         INT NULL,
    PCP22         INT NULL,
    PCP23_A       INT NULL,
    PCP23_B       INT NULL,
    PCP23_C       INT NULL,
    PCP24         INT NULL,
    PCP25_A       INT NULL,
    PCP25_B       INT NULL,
    PCP25_C       INT NULL,
    PCP26_A       INT NULL,
    PCP26_B       INT NULL,
    PCP26_C       INT NULL,
    PCP27         INT NULL,
    PCP28         INT NULL,
    PCP29         INT NULL,
    PCP30_2D      INT NULL,
    PCP31_D       INT NULL,
    PCP32_2D      INT NULL,
    PCP33         INT NULL,
    PCP33_B       INT NULL,
    TRABAJAGEO    INT NULL,
    PCP33_C       INT NULL,
    PCP34         INT NULL,
    PCP35_A       INT NULL,
    PCP35_B       INT NULL,
    PCP35_C       INT NULL,
    PCP36_A       INT NULL,
    PCP36_B       INT NULL,
    PCP36_C       INT NULL,
    PCP37         INT NULL,
    PCP38_A       INT NULL,
    PCP38_B       INT NULL,
    PCP38_C       INT NULL,
    PCP39         INT NULL,
    NIVGRADO      INT NULL,
    ANEDUCA       INT NULL,
    PEA           INT NULL,
    POCUPA        INT NULL,
    PDESOC        INT NULL,
    PEI           INT NULL,
    MIGRA_VIDA    INT NULL,
    MIGRA_REC     INT NULL
);
GO
CREATE CLUSTERED COLUMNSTORE INDEX IX_Stage_Persona_Columnstore ON stage.Persona;
GO

