/*
    Llaves foraneas de las dimensiones y las tablas de hechos.
    Las columnas de rol (mas de una FK hacia la misma dimension) agregan el nombre de la columna al de la restriccion.
    Para cargas masivas: ALTER TABLE <tabla> NOCHECK CONSTRAINT ALL, y al terminar WITH CHECK CHECK CONSTRAINT ALL.
    Convenciones: ver docs/convenciones.md. Scripts idempotentes; ejecutar despues de db/02-dimensiones.
*/

USE [CensoGT2018];
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Dim_Municipio_Dim_Departamento')
    ALTER TABLE dim.Municipio WITH CHECK ADD CONSTRAINT FK_Dim_Municipio_Dim_Departamento
        FOREIGN KEY (DepartamentoId) REFERENCES dim.Departamento (DepartamentoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Dim_LugarPoblado_Dim_Municipio')
    ALTER TABLE dim.LugarPoblado WITH CHECK ADD CONSTRAINT FK_Dim_LugarPoblado_Dim_Municipio
        FOREIGN KEY (MunicipioId) REFERENCES dim.Municipio (MunicipioId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoVivienda_Dim_LugarPoblado')
    ALTER TABLE hechos.CensoVivienda WITH CHECK ADD CONSTRAINT FK_Hechos_CensoVivienda_Dim_LugarPoblado
        FOREIGN KEY (LugarPobladoId) REFERENCES dim.LugarPoblado (LugarPobladoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoVivienda_Dim_TipoVivienda')
    ALTER TABLE hechos.CensoVivienda WITH CHECK ADD CONSTRAINT FK_Hechos_CensoVivienda_Dim_TipoVivienda
        FOREIGN KEY (TipoViviendaId) REFERENCES dim.TipoVivienda (TipoViviendaId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoVivienda_Dim_MaterialPared')
    ALTER TABLE hechos.CensoVivienda WITH CHECK ADD CONSTRAINT FK_Hechos_CensoVivienda_Dim_MaterialPared
        FOREIGN KEY (MaterialParedId) REFERENCES dim.MaterialPared (MaterialParedId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoVivienda_Dim_MaterialTecho')
    ALTER TABLE hechos.CensoVivienda WITH CHECK ADD CONSTRAINT FK_Hechos_CensoVivienda_Dim_MaterialTecho
        FOREIGN KEY (MaterialTechoId) REFERENCES dim.MaterialTecho (MaterialTechoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoVivienda_Dim_CondicionVivienda')
    ALTER TABLE hechos.CensoVivienda WITH CHECK ADD CONSTRAINT FK_Hechos_CensoVivienda_Dim_CondicionVivienda
        FOREIGN KEY (CondicionViviendaId) REFERENCES dim.CondicionVivienda (CondicionViviendaId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoVivienda_Dim_MaterialPiso')
    ALTER TABLE hechos.CensoVivienda WITH CHECK ADD CONSTRAINT FK_Hechos_CensoVivienda_Dim_MaterialPiso
        FOREIGN KEY (MaterialPisoId) REFERENCES dim.MaterialPiso (MaterialPisoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoHogar_Hechos_CensoVivienda')
    ALTER TABLE hechos.CensoHogar WITH CHECK ADD CONSTRAINT FK_Hechos_CensoHogar_Hechos_CensoVivienda
        FOREIGN KEY (ViviendaId) REFERENCES hechos.CensoVivienda (ViviendaId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoHogar_Dim_LugarPoblado')
    ALTER TABLE hechos.CensoHogar WITH CHECK ADD CONSTRAINT FK_Hechos_CensoHogar_Dim_LugarPoblado
        FOREIGN KEY (LugarPobladoId) REFERENCES dim.LugarPoblado (LugarPobladoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoHogar_Dim_TenenciaVivienda')
    ALTER TABLE hechos.CensoHogar WITH CHECK ADD CONSTRAINT FK_Hechos_CensoHogar_Dim_TenenciaVivienda
        FOREIGN KEY (TenenciaViviendaId) REFERENCES dim.TenenciaVivienda (TenenciaViviendaId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoHogar_Dim_SexoResponsable_SexoPropietarioId')
    ALTER TABLE hechos.CensoHogar WITH CHECK ADD CONSTRAINT FK_Hechos_CensoHogar_Dim_SexoResponsable_SexoPropietarioId
        FOREIGN KEY (SexoPropietarioId) REFERENCES dim.SexoResponsable (SexoResponsableId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoHogar_Dim_SexoResponsable_SexoDecisionesId')
    ALTER TABLE hechos.CensoHogar WITH CHECK ADD CONSTRAINT FK_Hechos_CensoHogar_Dim_SexoResponsable_SexoDecisionesId
        FOREIGN KEY (SexoDecisionesId) REFERENCES dim.SexoResponsable (SexoResponsableId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoHogar_Dim_FuenteAgua')
    ALTER TABLE hechos.CensoHogar WITH CHECK ADD CONSTRAINT FK_Hechos_CensoHogar_Dim_FuenteAgua
        FOREIGN KEY (FuenteAguaId) REFERENCES dim.FuenteAgua (FuenteAguaId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoHogar_Dim_TipoServicioSanitario')
    ALTER TABLE hechos.CensoHogar WITH CHECK ADD CONSTRAINT FK_Hechos_CensoHogar_Dim_TipoServicioSanitario
        FOREIGN KEY (TipoServicioSanitarioId) REFERENCES dim.TipoServicioSanitario (TipoServicioSanitarioId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoHogar_Dim_UsoServicioSanitario')
    ALTER TABLE hechos.CensoHogar WITH CHECK ADD CONSTRAINT FK_Hechos_CensoHogar_Dim_UsoServicioSanitario
        FOREIGN KEY (UsoServicioSanitarioId) REFERENCES dim.UsoServicioSanitario (UsoServicioSanitarioId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoHogar_Dim_DesagueAguasGrises')
    ALTER TABLE hechos.CensoHogar WITH CHECK ADD CONSTRAINT FK_Hechos_CensoHogar_Dim_DesagueAguasGrises
        FOREIGN KEY (DesagueAguasGrisesId) REFERENCES dim.DesagueAguasGrises (DesagueAguasGrisesId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoHogar_Dim_TipoAlumbrado')
    ALTER TABLE hechos.CensoHogar WITH CHECK ADD CONSTRAINT FK_Hechos_CensoHogar_Dim_TipoAlumbrado
        FOREIGN KEY (TipoAlumbradoId) REFERENCES dim.TipoAlumbrado (TipoAlumbradoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoHogar_Dim_EliminacionBasura')
    ALTER TABLE hechos.CensoHogar WITH CHECK ADD CONSTRAINT FK_Hechos_CensoHogar_Dim_EliminacionBasura
        FOREIGN KEY (EliminacionBasuraId) REFERENCES dim.EliminacionBasura (EliminacionBasuraId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoHogar_Dim_CombustibleCocina')
    ALTER TABLE hechos.CensoHogar WITH CHECK ADD CONSTRAINT FK_Hechos_CensoHogar_Dim_CombustibleCocina
        FOREIGN KEY (CombustibleCocinaId) REFERENCES dim.CombustibleCocina (CombustibleCocinaId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Hechos_CensoVivienda')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Hechos_CensoVivienda
        FOREIGN KEY (ViviendaId) REFERENCES hechos.CensoVivienda (ViviendaId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Hechos_CensoHogar')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Hechos_CensoHogar
        FOREIGN KEY (HogarId) REFERENCES hechos.CensoHogar (HogarId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_LugarPoblado')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_LugarPoblado
        FOREIGN KEY (LugarPobladoId) REFERENCES dim.LugarPoblado (LugarPobladoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_Parentesco')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_Parentesco
        FOREIGN KEY (ParentescoId) REFERENCES dim.Parentesco (ParentescoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_Sexo')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_Sexo
        FOREIGN KEY (SexoId) REFERENCES dim.Sexo (SexoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_Edad')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_Edad
        FOREIGN KEY (EdadId) REFERENCES dim.Edad (EdadId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_RespuestaSiNo_InscripcionRenapId')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_RespuestaSiNo_InscripcionRenapId
        FOREIGN KEY (InscripcionRenapId) REFERENCES dim.RespuestaSiNo (RespuestaSiNoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_TipoLugar_TipoLugarNacimientoId')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_TipoLugar_TipoLugarNacimientoId
        FOREIGN KEY (TipoLugarNacimientoId) REFERENCES dim.TipoLugar (TipoLugarId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_Departamento_DepartamentoNacimientoId')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_Departamento_DepartamentoNacimientoId
        FOREIGN KEY (DepartamentoNacimientoId) REFERENCES dim.Departamento (DepartamentoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_Municipio_MunicipioNacimientoId')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_Municipio_MunicipioNacimientoId
        FOREIGN KEY (MunicipioNacimientoId) REFERENCES dim.Municipio (MunicipioId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_Pais_PaisNacimientoId')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_Pais_PaisNacimientoId
        FOREIGN KEY (PaisNacimientoId) REFERENCES dim.Pais (PaisId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_TipoResidencia2013')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_TipoResidencia2013
        FOREIGN KEY (TipoResidencia2013Id) REFERENCES dim.TipoResidencia2013 (TipoResidencia2013Id);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_Departamento_DepartamentoResidencia2013Id')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_Departamento_DepartamentoResidencia2013Id
        FOREIGN KEY (DepartamentoResidencia2013Id) REFERENCES dim.Departamento (DepartamentoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_Municipio_MunicipioResidencia2013Id')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_Municipio_MunicipioResidencia2013Id
        FOREIGN KEY (MunicipioResidencia2013Id) REFERENCES dim.Municipio (MunicipioId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_Pais_PaisResidencia2013Id')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_Pais_PaisResidencia2013Id
        FOREIGN KEY (PaisResidencia2013Id) REFERENCES dim.Pais (PaisId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_Pueblo')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_Pueblo
        FOREIGN KEY (PuebloId) REFERENCES dim.Pueblo (PuebloId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_ComunidadLinguistica')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_ComunidadLinguistica
        FOREIGN KEY (ComunidadLinguisticaId) REFERENCES dim.ComunidadLinguistica (ComunidadLinguisticaId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_RespuestaSiNo_UsoTrajeTradicionalId')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_RespuestaSiNo_UsoTrajeTradicionalId
        FOREIGN KEY (UsoTrajeTradicionalId) REFERENCES dim.RespuestaSiNo (RespuestaSiNoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_Idioma_IdiomaMaternoId')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_Idioma_IdiomaMaternoId
        FOREIGN KEY (IdiomaMaternoId) REFERENCES dim.Idioma (IdiomaId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_GradoDificultad_DificultadVerId')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_GradoDificultad_DificultadVerId
        FOREIGN KEY (DificultadVerId) REFERENCES dim.GradoDificultad (GradoDificultadId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_GradoDificultad_DificultadOirId')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_GradoDificultad_DificultadOirId
        FOREIGN KEY (DificultadOirId) REFERENCES dim.GradoDificultad (GradoDificultadId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_GradoDificultad_DificultadCaminarId')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_GradoDificultad_DificultadCaminarId
        FOREIGN KEY (DificultadCaminarId) REFERENCES dim.GradoDificultad (GradoDificultadId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_GradoDificultad_DificultadRecordarId')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_GradoDificultad_DificultadRecordarId
        FOREIGN KEY (DificultadRecordarId) REFERENCES dim.GradoDificultad (GradoDificultadId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_GradoDificultad_DificultadCuidadoPersonalId')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_GradoDificultad_DificultadCuidadoPersonalId
        FOREIGN KEY (DificultadCuidadoPersonalId) REFERENCES dim.GradoDificultad (GradoDificultadId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_GradoDificultad_DificultadComunicarseId')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_GradoDificultad_DificultadComunicarseId
        FOREIGN KEY (DificultadComunicarseId) REFERENCES dim.GradoDificultad (GradoDificultadId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_NivelGrado')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_NivelGrado
        FOREIGN KEY (NivelGradoId) REFERENCES dim.NivelGrado (NivelGradoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_TipoEstablecimiento')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_TipoEstablecimiento
        FOREIGN KEY (TipoEstablecimientoId) REFERENCES dim.TipoEstablecimiento (TipoEstablecimientoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_TipoLugar_TipoLugarEstudioId')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_TipoLugar_TipoLugarEstudioId
        FOREIGN KEY (TipoLugarEstudioId) REFERENCES dim.TipoLugar (TipoLugarId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_Departamento_DepartamentoEstudioId')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_Departamento_DepartamentoEstudioId
        FOREIGN KEY (DepartamentoEstudioId) REFERENCES dim.Departamento (DepartamentoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_Municipio_MunicipioEstudioId')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_Municipio_MunicipioEstudioId
        FOREIGN KEY (MunicipioEstudioId) REFERENCES dim.Municipio (MunicipioId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_Pais_PaisEstudioId')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_Pais_PaisEstudioId
        FOREIGN KEY (PaisEstudioId) REFERENCES dim.Pais (PaisId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_CausaNoAsistencia')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_CausaNoAsistencia
        FOREIGN KEY (CausaNoAsistenciaId) REFERENCES dim.CausaNoAsistencia (CausaNoAsistenciaId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_Idioma_IdiomaLecturaEscritura1Id')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_Idioma_IdiomaLecturaEscritura1Id
        FOREIGN KEY (IdiomaLecturaEscritura1Id) REFERENCES dim.Idioma (IdiomaId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_Idioma_IdiomaLecturaEscritura2Id')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_Idioma_IdiomaLecturaEscritura2Id
        FOREIGN KEY (IdiomaLecturaEscritura2Id) REFERENCES dim.Idioma (IdiomaId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_Idioma_IdiomaLecturaEscritura3Id')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_Idioma_IdiomaLecturaEscritura3Id
        FOREIGN KEY (IdiomaLecturaEscritura3Id) REFERENCES dim.Idioma (IdiomaId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_Idioma_OtroIdioma1Id')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_Idioma_OtroIdioma1Id
        FOREIGN KEY (OtroIdioma1Id) REFERENCES dim.Idioma (IdiomaId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_Idioma_OtroIdioma2Id')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_Idioma_OtroIdioma2Id
        FOREIGN KEY (OtroIdioma2Id) REFERENCES dim.Idioma (IdiomaId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_Idioma_OtroIdioma3Id')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_Idioma_OtroIdioma3Id
        FOREIGN KEY (OtroIdioma3Id) REFERENCES dim.Idioma (IdiomaId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_RespuestaSiNo_UsoCelularId')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_RespuestaSiNo_UsoCelularId
        FOREIGN KEY (UsoCelularId) REFERENCES dim.RespuestaSiNo (RespuestaSiNoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_RespuestaSiNo_UsoComputadoraId')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_RespuestaSiNo_UsoComputadoraId
        FOREIGN KEY (UsoComputadoraId) REFERENCES dim.RespuestaSiNo (RespuestaSiNoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_RespuestaSiNo_UsoInternetId')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_RespuestaSiNo_UsoInternetId
        FOREIGN KEY (UsoInternetId) REFERENCES dim.RespuestaSiNo (RespuestaSiNoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_ActividadSemana')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_ActividadSemana
        FOREIGN KEY (ActividadSemanaId) REFERENCES dim.ActividadSemana (ActividadSemanaId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_ActividadNoTrabajo')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_ActividadNoTrabajo
        FOREIGN KEY (ActividadNoTrabajoId) REFERENCES dim.ActividadNoTrabajo (ActividadNoTrabajoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_Ocupacion')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_Ocupacion
        FOREIGN KEY (OcupacionId) REFERENCES dim.Ocupacion (OcupacionId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_CategoriaOcupacional')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_CategoriaOcupacional
        FOREIGN KEY (CategoriaOcupacionalId) REFERENCES dim.CategoriaOcupacional (CategoriaOcupacionalId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_RamaActividad')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_RamaActividad
        FOREIGN KEY (RamaActividadId) REFERENCES dim.RamaActividad (RamaActividadId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_TipoLugar_TipoLugarTrabajoId')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_TipoLugar_TipoLugarTrabajoId
        FOREIGN KEY (TipoLugarTrabajoId) REFERENCES dim.TipoLugar (TipoLugarId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_Departamento_DepartamentoTrabajoId')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_Departamento_DepartamentoTrabajoId
        FOREIGN KEY (DepartamentoTrabajoId) REFERENCES dim.Departamento (DepartamentoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_Municipio_MunicipioTrabajoId')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_Municipio_MunicipioTrabajoId
        FOREIGN KEY (MunicipioTrabajoId) REFERENCES dim.Municipio (MunicipioId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_Pais_PaisTrabajoId')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_Pais_PaisTrabajoId
        FOREIGN KEY (PaisTrabajoId) REFERENCES dim.Pais (PaisId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_EstadoConyugal')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_EstadoConyugal
        FOREIGN KEY (EstadoConyugalId) REFERENCES dim.EstadoConyugal (EstadoConyugalId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_CondicionActividad')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_CondicionActividad
        FOREIGN KEY (CondicionActividadId) REFERENCES dim.CondicionActividad (CondicionActividadId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoMigracion_Hechos_CensoHogar')
    ALTER TABLE hechos.CensoMigracion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoMigracion_Hechos_CensoHogar
        FOREIGN KEY (HogarId) REFERENCES hechos.CensoHogar (HogarId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoMigracion_Dim_LugarPoblado')
    ALTER TABLE hechos.CensoMigracion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoMigracion_Dim_LugarPoblado
        FOREIGN KEY (LugarPobladoId) REFERENCES dim.LugarPoblado (LugarPobladoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoMigracion_Dim_Sexo')
    ALTER TABLE hechos.CensoMigracion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoMigracion_Dim_Sexo
        FOREIGN KEY (SexoId) REFERENCES dim.Sexo (SexoId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoMigracion_Dim_Edad')
    ALTER TABLE hechos.CensoMigracion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoMigracion_Dim_Edad
        FOREIGN KEY (EdadId) REFERENCES dim.Edad (EdadId);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoHogar_Dim_TipoHogar')
    ALTER TABLE hechos.CensoHogar WITH CHECK ADD CONSTRAINT FK_Hechos_CensoHogar_Dim_TipoHogar
        FOREIGN KEY (TipoHogarId) REFERENCES dim.TipoHogar (TipoHogarId);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_Hechos_CensoPoblacion_Dim_CondicionDificultad')
    ALTER TABLE hechos.CensoPoblacion WITH CHECK ADD CONSTRAINT FK_Hechos_CensoPoblacion_Dim_CondicionDificultad
        FOREIGN KEY (CondicionDificultadId) REFERENCES dim.CondicionDificultad (CondicionDificultadId);
GO
