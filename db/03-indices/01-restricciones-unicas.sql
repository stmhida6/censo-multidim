/*
    Restricciones unicas: codigo del INE en cada dimension y llave natural en los hechos.
    Las llaves naturales de los hechos (vivienda, hogar, emigrante) permiten al ETL traducir el codigo del INE a la llave sustituta.
    CensoPoblacion no lleva restriccion unica: su llave natural (hogar + PCP1) es unica en el origen y no se consulta por ella.
    Convenciones: ver docs/convenciones.md. Scripts idempotentes; ejecutar despues de db/02-dimensiones.
*/

USE [CensoGT2018];
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_Departamento_CodigoDepartamento' AND object_id = OBJECT_ID(N'dim.Departamento'))
    ALTER TABLE dim.Departamento ADD CONSTRAINT UQ_Dim_Departamento_CodigoDepartamento UNIQUE (CodigoDepartamento);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_Municipio_CodigoMunicipio' AND object_id = OBJECT_ID(N'dim.Municipio'))
    ALTER TABLE dim.Municipio ADD CONSTRAINT UQ_Dim_Municipio_CodigoMunicipio UNIQUE (CodigoMunicipio);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_LugarPoblado_CodigoLugarPoblado' AND object_id = OBJECT_ID(N'dim.LugarPoblado'))
    ALTER TABLE dim.LugarPoblado ADD CONSTRAINT UQ_Dim_LugarPoblado_CodigoLugarPoblado UNIQUE (CodigoLugarPoblado);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_Sexo_CodigoSexo' AND object_id = OBJECT_ID(N'dim.Sexo'))
    ALTER TABLE dim.Sexo ADD CONSTRAINT UQ_Dim_Sexo_CodigoSexo UNIQUE (CodigoSexo);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_RespuestaSiNo_CodigoRespuestaSiNo' AND object_id = OBJECT_ID(N'dim.RespuestaSiNo'))
    ALTER TABLE dim.RespuestaSiNo ADD CONSTRAINT UQ_Dim_RespuestaSiNo_CodigoRespuestaSiNo UNIQUE (CodigoRespuestaSiNo);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_Pais_CodigoPais' AND object_id = OBJECT_ID(N'dim.Pais'))
    ALTER TABLE dim.Pais ADD CONSTRAINT UQ_Dim_Pais_CodigoPais UNIQUE (CodigoPais);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_Idioma_CodigoIdioma' AND object_id = OBJECT_ID(N'dim.Idioma'))
    ALTER TABLE dim.Idioma ADD CONSTRAINT UQ_Dim_Idioma_CodigoIdioma UNIQUE (CodigoIdioma);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_TipoLugar_CodigoTipoLugar' AND object_id = OBJECT_ID(N'dim.TipoLugar'))
    ALTER TABLE dim.TipoLugar ADD CONSTRAINT UQ_Dim_TipoLugar_CodigoTipoLugar UNIQUE (CodigoTipoLugar);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_SexoResponsable_CodigoSexoResponsable' AND object_id = OBJECT_ID(N'dim.SexoResponsable'))
    ALTER TABLE dim.SexoResponsable ADD CONSTRAINT UQ_Dim_SexoResponsable_CodigoSexoResponsable UNIQUE (CodigoSexoResponsable);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_TipoVivienda_CodigoTipoVivienda' AND object_id = OBJECT_ID(N'dim.TipoVivienda'))
    ALTER TABLE dim.TipoVivienda ADD CONSTRAINT UQ_Dim_TipoVivienda_CodigoTipoVivienda UNIQUE (CodigoTipoVivienda);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_MaterialPared_CodigoMaterialPared' AND object_id = OBJECT_ID(N'dim.MaterialPared'))
    ALTER TABLE dim.MaterialPared ADD CONSTRAINT UQ_Dim_MaterialPared_CodigoMaterialPared UNIQUE (CodigoMaterialPared);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_MaterialTecho_CodigoMaterialTecho' AND object_id = OBJECT_ID(N'dim.MaterialTecho'))
    ALTER TABLE dim.MaterialTecho ADD CONSTRAINT UQ_Dim_MaterialTecho_CodigoMaterialTecho UNIQUE (CodigoMaterialTecho);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_CondicionVivienda_CodigoCondicionVivienda' AND object_id = OBJECT_ID(N'dim.CondicionVivienda'))
    ALTER TABLE dim.CondicionVivienda ADD CONSTRAINT UQ_Dim_CondicionVivienda_CodigoCondicionVivienda UNIQUE (CodigoCondicionVivienda);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_MaterialPiso_CodigoMaterialPiso' AND object_id = OBJECT_ID(N'dim.MaterialPiso'))
    ALTER TABLE dim.MaterialPiso ADD CONSTRAINT UQ_Dim_MaterialPiso_CodigoMaterialPiso UNIQUE (CodigoMaterialPiso);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_TenenciaVivienda_CodigoTenenciaVivienda' AND object_id = OBJECT_ID(N'dim.TenenciaVivienda'))
    ALTER TABLE dim.TenenciaVivienda ADD CONSTRAINT UQ_Dim_TenenciaVivienda_CodigoTenenciaVivienda UNIQUE (CodigoTenenciaVivienda);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_FuenteAgua_CodigoFuenteAgua' AND object_id = OBJECT_ID(N'dim.FuenteAgua'))
    ALTER TABLE dim.FuenteAgua ADD CONSTRAINT UQ_Dim_FuenteAgua_CodigoFuenteAgua UNIQUE (CodigoFuenteAgua);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_TipoServicioSanitario_CodigoTipoServicioSanitario' AND object_id = OBJECT_ID(N'dim.TipoServicioSanitario'))
    ALTER TABLE dim.TipoServicioSanitario ADD CONSTRAINT UQ_Dim_TipoServicioSanitario_CodigoTipoServicioSanitario UNIQUE (CodigoTipoServicioSanitario);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_UsoServicioSanitario_CodigoUsoServicioSanitario' AND object_id = OBJECT_ID(N'dim.UsoServicioSanitario'))
    ALTER TABLE dim.UsoServicioSanitario ADD CONSTRAINT UQ_Dim_UsoServicioSanitario_CodigoUsoServicioSanitario UNIQUE (CodigoUsoServicioSanitario);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_DesagueAguasGrises_CodigoDesagueAguasGrises' AND object_id = OBJECT_ID(N'dim.DesagueAguasGrises'))
    ALTER TABLE dim.DesagueAguasGrises ADD CONSTRAINT UQ_Dim_DesagueAguasGrises_CodigoDesagueAguasGrises UNIQUE (CodigoDesagueAguasGrises);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_TipoAlumbrado_CodigoTipoAlumbrado' AND object_id = OBJECT_ID(N'dim.TipoAlumbrado'))
    ALTER TABLE dim.TipoAlumbrado ADD CONSTRAINT UQ_Dim_TipoAlumbrado_CodigoTipoAlumbrado UNIQUE (CodigoTipoAlumbrado);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_EliminacionBasura_CodigoEliminacionBasura' AND object_id = OBJECT_ID(N'dim.EliminacionBasura'))
    ALTER TABLE dim.EliminacionBasura ADD CONSTRAINT UQ_Dim_EliminacionBasura_CodigoEliminacionBasura UNIQUE (CodigoEliminacionBasura);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_CombustibleCocina_CodigoCombustibleCocina' AND object_id = OBJECT_ID(N'dim.CombustibleCocina'))
    ALTER TABLE dim.CombustibleCocina ADD CONSTRAINT UQ_Dim_CombustibleCocina_CodigoCombustibleCocina UNIQUE (CodigoCombustibleCocina);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_Parentesco_CodigoParentesco' AND object_id = OBJECT_ID(N'dim.Parentesco'))
    ALTER TABLE dim.Parentesco ADD CONSTRAINT UQ_Dim_Parentesco_CodigoParentesco UNIQUE (CodigoParentesco);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_TipoResidencia2013_CodigoTipoResidencia2013' AND object_id = OBJECT_ID(N'dim.TipoResidencia2013'))
    ALTER TABLE dim.TipoResidencia2013 ADD CONSTRAINT UQ_Dim_TipoResidencia2013_CodigoTipoResidencia2013 UNIQUE (CodigoTipoResidencia2013);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_Pueblo_CodigoPueblo' AND object_id = OBJECT_ID(N'dim.Pueblo'))
    ALTER TABLE dim.Pueblo ADD CONSTRAINT UQ_Dim_Pueblo_CodigoPueblo UNIQUE (CodigoPueblo);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_ComunidadLinguistica_CodigoComunidadLinguistica' AND object_id = OBJECT_ID(N'dim.ComunidadLinguistica'))
    ALTER TABLE dim.ComunidadLinguistica ADD CONSTRAINT UQ_Dim_ComunidadLinguistica_CodigoComunidadLinguistica UNIQUE (CodigoComunidadLinguistica);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_GradoDificultad_CodigoGradoDificultad' AND object_id = OBJECT_ID(N'dim.GradoDificultad'))
    ALTER TABLE dim.GradoDificultad ADD CONSTRAINT UQ_Dim_GradoDificultad_CodigoGradoDificultad UNIQUE (CodigoGradoDificultad);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_NivelGrado_CodigoNivelGrado' AND object_id = OBJECT_ID(N'dim.NivelGrado'))
    ALTER TABLE dim.NivelGrado ADD CONSTRAINT UQ_Dim_NivelGrado_CodigoNivelGrado UNIQUE (CodigoNivelGrado);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_TipoEstablecimiento_CodigoTipoEstablecimiento' AND object_id = OBJECT_ID(N'dim.TipoEstablecimiento'))
    ALTER TABLE dim.TipoEstablecimiento ADD CONSTRAINT UQ_Dim_TipoEstablecimiento_CodigoTipoEstablecimiento UNIQUE (CodigoTipoEstablecimiento);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_CausaNoAsistencia_CodigoCausaNoAsistencia' AND object_id = OBJECT_ID(N'dim.CausaNoAsistencia'))
    ALTER TABLE dim.CausaNoAsistencia ADD CONSTRAINT UQ_Dim_CausaNoAsistencia_CodigoCausaNoAsistencia UNIQUE (CodigoCausaNoAsistencia);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_ActividadSemana_CodigoActividadSemana' AND object_id = OBJECT_ID(N'dim.ActividadSemana'))
    ALTER TABLE dim.ActividadSemana ADD CONSTRAINT UQ_Dim_ActividadSemana_CodigoActividadSemana UNIQUE (CodigoActividadSemana);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_ActividadNoTrabajo_CodigoActividadNoTrabajo' AND object_id = OBJECT_ID(N'dim.ActividadNoTrabajo'))
    ALTER TABLE dim.ActividadNoTrabajo ADD CONSTRAINT UQ_Dim_ActividadNoTrabajo_CodigoActividadNoTrabajo UNIQUE (CodigoActividadNoTrabajo);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_Ocupacion_CodigoOcupacion' AND object_id = OBJECT_ID(N'dim.Ocupacion'))
    ALTER TABLE dim.Ocupacion ADD CONSTRAINT UQ_Dim_Ocupacion_CodigoOcupacion UNIQUE (CodigoOcupacion);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_RamaActividad_CodigoRamaActividad' AND object_id = OBJECT_ID(N'dim.RamaActividad'))
    ALTER TABLE dim.RamaActividad ADD CONSTRAINT UQ_Dim_RamaActividad_CodigoRamaActividad UNIQUE (CodigoRamaActividad);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_CategoriaOcupacional_CodigoCategoriaOcupacional' AND object_id = OBJECT_ID(N'dim.CategoriaOcupacional'))
    ALTER TABLE dim.CategoriaOcupacional ADD CONSTRAINT UQ_Dim_CategoriaOcupacional_CodigoCategoriaOcupacional UNIQUE (CodigoCategoriaOcupacional);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_EstadoConyugal_CodigoEstadoConyugal' AND object_id = OBJECT_ID(N'dim.EstadoConyugal'))
    ALTER TABLE dim.EstadoConyugal ADD CONSTRAINT UQ_Dim_EstadoConyugal_CodigoEstadoConyugal UNIQUE (CodigoEstadoConyugal);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_CondicionActividad_CodigoCondicionActividad' AND object_id = OBJECT_ID(N'dim.CondicionActividad'))
    ALTER TABLE dim.CondicionActividad ADD CONSTRAINT UQ_Dim_CondicionActividad_CodigoCondicionActividad UNIQUE (CodigoCondicionActividad);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Hechos_CensoVivienda_LugarPobladoId_NumeroVivienda' AND object_id = OBJECT_ID(N'hechos.CensoVivienda'))
    ALTER TABLE hechos.CensoVivienda ADD CONSTRAINT UQ_Hechos_CensoVivienda_LugarPobladoId_NumeroVivienda UNIQUE (LugarPobladoId, NumeroVivienda);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Hechos_CensoHogar_ViviendaId_NumeroHogar' AND object_id = OBJECT_ID(N'hechos.CensoHogar'))
    ALTER TABLE hechos.CensoHogar ADD CONSTRAINT UQ_Hechos_CensoHogar_ViviendaId_NumeroHogar UNIQUE (ViviendaId, NumeroHogar);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Hechos_CensoMigracion_HogarId_NumeroEmigrante' AND object_id = OBJECT_ID(N'hechos.CensoMigracion'))
    ALTER TABLE hechos.CensoMigracion ADD CONSTRAINT UQ_Hechos_CensoMigracion_HogarId_NumeroEmigrante UNIQUE (HogarId, NumeroEmigrante);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_TipoHogar_CodigoTipoHogar' AND object_id = OBJECT_ID(N'dim.TipoHogar'))
    ALTER TABLE dim.TipoHogar ADD CONSTRAINT UQ_Dim_TipoHogar_CodigoTipoHogar UNIQUE (CodigoTipoHogar);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UQ_Dim_CondicionDificultad_CodigoCondicionDificultad' AND object_id = OBJECT_ID(N'dim.CondicionDificultad'))
    ALTER TABLE dim.CondicionDificultad ADD CONSTRAINT UQ_Dim_CondicionDificultad_CodigoCondicionDificultad UNIQUE (CodigoCondicionDificultad);
GO
