/*
    Carga las 4 tablas de hechos desde stage, en el orden Vivienda, Hogar, Migracion y Poblacion.

    - Cada columna del hecho se define en la tabla #Mapa: una expresion sobre stage (alias s) o una
      dimension a la que se traduce el codigo del INE por su llave sustituta.
    - Antes de cargar se verifica que todo codigo presente en stage exista en su dimension; si falta
      alguno, se detiene y lista los codigos huerfanos (asi un codigo sin etiqueta no se pierde en silencio).
    - Despues de cada hecho se compara el numero de filas insertadas con el de stage.
    - Poblacion se carga por departamento (22 lotes) para acotar la memoria de las uniones.
    - La tipologia del hogar (cuadro B8) se deriva antes de cargar Hogar a partir del parentesco de sus miembros en
      stage.Persona (#TipologiaHogar); la condicion de dificultad (cuadro A8), de las 6 preguntas de dificultad.
    - Las llaves foraneas se desactivan durante la carga y se revalidan al final (WITH CHECK).
    - La base pasa a recuperacion SIMPLE para minimizar el registro de transacciones de la carga masiva.
*/

USE [CensoGT2018];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

IF EXISTS (SELECT 1 FROM hechos.CensoVivienda) OR EXISTS (SELECT 1 FROM hechos.CensoPoblacion)
    THROW 50004, 'Los hechos ya tienen datos. Ejecute etl/sql/00-vaciar-modelo.sql antes de recargar.', 1;
IF NOT EXISTS (SELECT 1 FROM dim.Edad)
    THROW 50005, 'Las dimensiones estan vacias. Ejecute etl/sql/03-cargar-dimensiones.sql antes de cargar los hechos.', 1;

ALTER DATABASE CensoGT2018 SET RECOVERY SIMPLE;
ALTER TABLE hechos.CensoVivienda NOCHECK CONSTRAINT ALL;
ALTER TABLE hechos.CensoHogar NOCHECK CONSTRAINT ALL;
ALTER TABLE hechos.CensoMigracion NOCHECK CONSTRAINT ALL;
ALTER TABLE hechos.CensoPoblacion NOCHECK CONSTRAINT ALL;

-- ---------------- Correspondencias columna destino <- expresion ----------------
-- Dimension NULL: la expresion se inserta tal cual. Dimension informada: la expresion produce el codigo del INE
-- y se traduce a la llave sustituta con LEFT JOIN a la dimension.
DECLARE @sn NVARCHAR(40) = N' WHEN 1 THEN 1 WHEN 2 THEN 0 END';   -- Si (1) -> 1, No (2) -> 0

CREATE TABLE #Mapa (Orden INT IDENTITY(1,1) NOT NULL, Hecho VARCHAR(20) NOT NULL, Destino SYSNAME NOT NULL,
                    Expresion NVARCHAR(500) NOT NULL, Dimension SYSNAME NULL);

INSERT #Mapa (Hecho, Destino, Expresion, Dimension) VALUES
 -- Vivienda (base: lp = dim.LugarPoblado)
 ('Vivienda', 'LugarPobladoId', N'lp.LugarPobladoId', NULL),
 ('Vivienda', 'NumeroVivienda', N's.NUM_VIVIENDA', NULL),
 ('Vivienda', 'TipoViviendaId', N's.PCV1', 'TipoVivienda'),
 ('Vivienda', 'MaterialParedId', N's.PCV2', 'MaterialPared'),
 ('Vivienda', 'MaterialTechoId', N's.PCV3', 'MaterialTecho'),
 ('Vivienda', 'CondicionViviendaId', N's.PCV4', 'CondicionVivienda'),
 ('Vivienda', 'MaterialPisoId', N's.PCV5', 'MaterialPiso'),
 ('Vivienda', 'EsUrbano', N'CASE s.AREA WHEN 1 THEN 1 WHEN 2 THEN 0 END', NULL),
 ('Vivienda', 'Longitud', N'CAST(s.Long AS DECIMAL(9,6))', NULL),
 ('Vivienda', 'Latitud', N'CAST(s.Lat AS DECIMAL(9,6))', NULL),
 -- Hogar (base: lp, v = hechos.CensoVivienda)
 ('Hogar', 'ViviendaId', N'v.ViviendaId', NULL),
 ('Hogar', 'LugarPobladoId', N'lp.LugarPobladoId', NULL),
 ('Hogar', 'NumeroHogar', N's.NUM_HOGAR', NULL),
 ('Hogar', 'TenenciaViviendaId', N's.PCH1', 'TenenciaVivienda'),
 ('Hogar', 'SexoPropietarioId', N's.PCH2', 'SexoResponsable'),
 ('Hogar', 'SexoDecisionesId', N's.PCH3', 'SexoResponsable'),
 ('Hogar', 'FuenteAguaId', N's.PCH4', 'FuenteAgua'),
 ('Hogar', 'TipoServicioSanitarioId', N's.PCH5', 'TipoServicioSanitario'),
 ('Hogar', 'UsoServicioSanitarioId', N's.PCH6', 'UsoServicioSanitario'),
 ('Hogar', 'DesagueAguasGrisesId', N's.PCH7', 'DesagueAguasGrises'),
 ('Hogar', 'TipoAlumbradoId', N's.PCH8', 'TipoAlumbrado'),
 ('Hogar', 'TieneRadio', N'CASE s.PCH9_A' + @sn, NULL),
 ('Hogar', 'TieneEstufa', N'CASE s.PCH9_B' + @sn, NULL),
 ('Hogar', 'TieneTelevisor', N'CASE s.PCH9_C' + @sn, NULL),
 ('Hogar', 'TieneCable', N'CASE s.PCH9_D' + @sn, NULL),
 ('Hogar', 'TieneRefrigeradora', N'CASE s.PCH9_E' + @sn, NULL),
 ('Hogar', 'TieneTanqueAgua', N'CASE s.PCH9_F' + @sn, NULL),
 ('Hogar', 'TieneLavadora', N'CASE s.PCH9_G' + @sn, NULL),
 ('Hogar', 'TieneComputadora', N'CASE s.PCH9_H' + @sn, NULL),
 ('Hogar', 'TieneInternet', N'CASE s.PCH9_I' + @sn, NULL),
 ('Hogar', 'TieneTemazcal', N'CASE s.PCH9_J' + @sn, NULL),
 ('Hogar', 'TieneAguaCaliente', N'CASE s.PCH9_K' + @sn, NULL),
 ('Hogar', 'TieneMoto', N'CASE s.PCH9_L' + @sn, NULL),
 ('Hogar', 'TieneCarro', N'CASE s.PCH9_M' + @sn, NULL),
 ('Hogar', 'EliminacionBasuraId', N's.PCH10', 'EliminacionBasura'),
 ('Hogar', 'TotalCuartos', N's.PCH11', NULL),
 ('Hogar', 'TotalDormitorios', N's.PCH12', NULL),
 ('Hogar', 'TieneCuartoCocina', N'CASE s.PCH13' + @sn, NULL),
 ('Hogar', 'CombustibleCocinaId', N's.PCH14', 'CombustibleCocina'),
 ('Hogar', 'TieneRemesas', N'CASE s.PCH15' + @sn, NULL),
 ('Hogar', 'TieneEmigrantes', N'CASE s.PEI1' + @sn, NULL),
 ('Hogar', 'TotalEmigrantes', N's.PEI2', NULL),
 ('Hogar', 'TotalEmigrantesConDetalle', N's.PEI2_E', NULL),
 ('Hogar', 'TotalPersonas', N's.TOTAL_PERS', NULL),
 ('Hogar', 'TipoHogarId', N'th.CodigoTipoHogar', 'TipoHogar'),
 -- Migracion (base: lp, v, h = hechos.CensoHogar)
 ('Migracion', 'HogarId', N'h.HogarId', NULL),
 ('Migracion', 'LugarPobladoId', N'lp.LugarPobladoId', NULL),
 ('Migracion', 'NumeroEmigrante', N's.ID_EMIGRACION', NULL),
 ('Migracion', 'SexoId', N's.PEI3', 'Sexo'),
 ('Migracion', 'EdadId', N's.PEI4', 'Edad'),
 ('Migracion', 'AnioSalida', N'NULLIF(s.PEI5, 9999)', NULL),
 -- Poblacion (base: lp, v, h)
 ('Poblacion', 'ViviendaId', N'v.ViviendaId', NULL),
 ('Poblacion', 'HogarId', N'h.HogarId', NULL),
 ('Poblacion', 'LugarPobladoId', N'lp.LugarPobladoId', NULL),
 ('Poblacion', 'NumeroPersona', N's.PCP1', NULL),
 ('Poblacion', 'ParentescoId', N's.PCP5', 'Parentesco'),
 ('Poblacion', 'SexoId', N's.PCP6', 'Sexo'),
 ('Poblacion', 'EdadId', N's.PCP7', 'Edad'),
 ('Poblacion', 'InscripcionRenapId', N's.PCP9', 'RespuestaSiNo'),
 ('Poblacion', 'TipoLugarNacimientoId', N's.PCP10', 'TipoLugar'),
 ('Poblacion', 'DepartamentoNacimientoId', N's.PCP10_B', 'Departamento'),
 ('Poblacion', 'MunicipioNacimientoId', N's.LUGNACGEO', 'Municipio'),
 ('Poblacion', 'PaisNacimientoId', N's.PCP10_C', 'Pais'),
 ('Poblacion', 'AnioLlegadaPais', N'NULLIF(s.PCP10_D, 9999)', NULL),
 ('Poblacion', 'TipoResidencia2013Id', N's.PCP11', 'TipoResidencia2013'),
 ('Poblacion', 'DepartamentoResidencia2013Id', N's.PCP11_B', 'Departamento'),
 ('Poblacion', 'MunicipioResidencia2013Id', N's.RESCINGEO', 'Municipio'),
 ('Poblacion', 'PaisResidencia2013Id', N's.PCP11_C', 'Pais'),
 ('Poblacion', 'PuebloId', N's.PCP12', 'Pueblo'),
 ('Poblacion', 'ComunidadLinguisticaId', N's.PCP13', 'ComunidadLinguistica'),
 ('Poblacion', 'UsoTrajeTradicionalId', N's.PCP14', 'RespuestaSiNo'),
 ('Poblacion', 'IdiomaMaternoId', N's.PCP15', 'Idioma'),
 ('Poblacion', 'DificultadVerId', N's.PCP16_A', 'GradoDificultad'),
 ('Poblacion', 'DificultadOirId', N's.PCP16_B', 'GradoDificultad'),
 ('Poblacion', 'DificultadCaminarId', N's.PCP16_C', 'GradoDificultad'),
 ('Poblacion', 'DificultadRecordarId', N's.PCP16_D', 'GradoDificultad'),
 ('Poblacion', 'DificultadCuidadoPersonalId', N's.PCP16_E', 'GradoDificultad'),
 ('Poblacion', 'DificultadComunicarseId', N's.PCP16_F', 'GradoDificultad'),
 -- Condicion de dificultad (cuadro A8): 2 si alguna respuesta es 2, 3 o 4 (algo, mucha o no puede); 1 si las 6 son 1
 -- (sin dificultad); 9 en otro caso (alguna no declarada); sin valor si no se pregunto (menores de 4 anios)
 ('Poblacion', 'CondicionDificultadId',
  N'CASE WHEN s.PCP16_A IS NULL THEN NULL WHEN 2 IN (s.PCP16_A, s.PCP16_B, s.PCP16_C, s.PCP16_D, s.PCP16_E, s.PCP16_F) '
  + N'OR 3 IN (s.PCP16_A, s.PCP16_B, s.PCP16_C, s.PCP16_D, s.PCP16_E, s.PCP16_F) '
  + N'OR 4 IN (s.PCP16_A, s.PCP16_B, s.PCP16_C, s.PCP16_D, s.PCP16_E, s.PCP16_F) THEN 2 '
  + N'WHEN s.PCP16_A = 1 AND s.PCP16_B = 1 AND s.PCP16_C = 1 AND s.PCP16_D = 1 AND s.PCP16_E = 1 AND s.PCP16_F = 1 THEN 1 ELSE 9 END',
  'CondicionDificultad'),
 ('Poblacion', 'NivelGradoId', N's.NIVGRADO', 'NivelGrado'),
 ('Poblacion', 'GradoMasAltoAprobado', N's.PCP17_B', NULL),
 ('Poblacion', 'AniosEstudio', N's.ANEDUCA', NULL),
 ('Poblacion', 'EsEstudiante', N'CASE s.PCP18' + @sn, NULL),
 ('Poblacion', 'TipoEstablecimientoId', N's.PCP19', 'TipoEstablecimiento'),
 ('Poblacion', 'TipoLugarEstudioId', N's.PCP20', 'TipoLugar'),
 ('Poblacion', 'DepartamentoEstudioId', N's.PCP20_B', 'Departamento'),
 ('Poblacion', 'MunicipioEstudioId', N's.ESTUDIAGEO', 'Municipio'),
 ('Poblacion', 'PaisEstudioId', N's.PCP20_C', 'Pais'),
 ('Poblacion', 'CausaNoAsistenciaId', N's.PCP21', 'CausaNoAsistencia'),
 ('Poblacion', 'EsAlfabeta', N'CASE s.PCP22' + @sn, NULL),
 ('Poblacion', 'IdiomaLecturaEscritura1Id', N's.PCP23_A', 'Idioma'),
 ('Poblacion', 'IdiomaLecturaEscritura2Id', N's.PCP23_B', 'Idioma'),
 ('Poblacion', 'IdiomaLecturaEscritura3Id', N's.PCP23_C', 'Idioma'),
 ('Poblacion', 'TieneOtroIdioma', N'CASE s.PCP24' + @sn, NULL),
 ('Poblacion', 'OtroIdioma1Id', N's.PCP25_A', 'Idioma'),
 ('Poblacion', 'OtroIdioma2Id', N's.PCP25_B', 'Idioma'),
 ('Poblacion', 'OtroIdioma3Id', N's.PCP25_C', 'Idioma'),
 ('Poblacion', 'UsoCelularId', N's.PCP26_A', 'RespuestaSiNo'),
 ('Poblacion', 'UsoComputadoraId', N's.PCP26_B', 'RespuestaSiNo'),
 ('Poblacion', 'UsoInternetId', N's.PCP26_C', 'RespuestaSiNo'),
 ('Poblacion', 'EsTrabajadorSemanaPasada', N'CASE s.PCP27' + @sn, NULL),
 ('Poblacion', 'ActividadSemanaId', N's.PCP28', 'ActividadSemana'),
 ('Poblacion', 'ActividadNoTrabajoId', N's.PCP29', 'ActividadNoTrabajo'),
 ('Poblacion', 'OcupacionId', N's.PCP30_2D', 'Ocupacion'),
 ('Poblacion', 'CategoriaOcupacionalId', N's.PCP31_D', 'CategoriaOcupacional'),
 ('Poblacion', 'RamaActividadId', N's.PCP32_2D', 'RamaActividad'),
 ('Poblacion', 'TipoLugarTrabajoId', N's.PCP33', 'TipoLugar'),
 ('Poblacion', 'DepartamentoTrabajoId', N's.PCP33_B', 'Departamento'),
 ('Poblacion', 'MunicipioTrabajoId', N's.TRABAJAGEO', 'Municipio'),
 ('Poblacion', 'PaisTrabajoId', N's.PCP33_C', 'Pais'),
 ('Poblacion', 'EstadoConyugalId', N's.PCP34', 'EstadoConyugal'),
 ('Poblacion', 'HijosNacidosVivos', N'NULLIF(s.PCP35_A, 99)', NULL),
 ('Poblacion', 'HijosNacidosVivosMujeres', N'NULLIF(s.PCP35_B, 99)', NULL),
 ('Poblacion', 'HijosNacidosVivosHombres', N'NULLIF(s.PCP35_C, 99)', NULL),
 ('Poblacion', 'HijosSobrevivientes', N's.PCP36_A', NULL),
 ('Poblacion', 'HijosSobrevivientesMujeres', N's.PCP36_B', NULL),
 ('Poblacion', 'HijosSobrevivientesHombres', N's.PCP36_C', NULL),
 ('Poblacion', 'EdadPrimerHijo', N'NULLIF(s.PCP37, 99)', NULL),
 ('Poblacion', 'DiaUltimoHijo', N'NULLIF(s.PCP38_A, 99)', NULL),
 ('Poblacion', 'MesUltimoHijo', N'NULLIF(s.PCP38_B, 99)', NULL),
 ('Poblacion', 'AnioUltimoHijo', N'NULLIF(s.PCP38_C, 9999)', NULL),
 ('Poblacion', 'EsVivoUltimoHijo', N'CASE s.PCP39' + @sn, NULL),
 -- Condicion de actividad: 1 ocupada, 2 desocupada aspirante, 3 desocupada cesante, 4 inactiva, 5 no declarada; menores de 7 anios: sin valor
 ('Poblacion', 'CondicionActividadId',
  N'CASE WHEN s.PCP7 < 7 THEN NULL WHEN s.POCUPA = 1 THEN 1 WHEN s.PDESOC = 1 THEN 2 WHEN s.PDESOC = 2 THEN 3 WHEN s.PEI = 1 THEN 4 ELSE 5 END',
  'CondicionActividad'),
 -- En MIGRA_VIDA y MIGRA_REC el codigo 2 es migrante y el 1 no migrante (etl/r/06-verificacion-migracion-actividad.R)
 ('Poblacion', 'EsMigranteVida', N'CASE s.MIGRA_VIDA WHEN 2 THEN 1 WHEN 1 THEN 0 END', NULL),
 ('Poblacion', 'EsMigranteReciente', N'CASE s.MIGRA_REC WHEN 2 THEN 1 WHEN 1 THEN 0 END', NULL);

-- ---------------- Definicion de cada hecho ----------------
DECLARE @Hechos TABLE (Orden INT, Hecho VARCHAR(20), Destino NVARCHAR(100), Stage NVARCHAR(100), Base NVARCHAR(MAX), Ordenar NVARCHAR(200));
INSERT @Hechos (Orden, Hecho, Destino, Stage, Base, Ordenar) VALUES
 (1, 'Vivienda', N'hechos.CensoVivienda', N'stage.Vivienda',
  N'FROM stage.Vivienda s JOIN dim.LugarPoblado lp ON lp.CodigoLugarPoblado = s.LUGAR_POBLADO', N's.LUGAR_POBLADO, s.NUM_VIVIENDA'),
 (2, 'Hogar', N'hechos.CensoHogar', N'stage.Hogar',
  N'FROM stage.Hogar s JOIN dim.LugarPoblado lp ON lp.CodigoLugarPoblado = s.LUGAR_POBLADO
    JOIN hechos.CensoVivienda v ON v.LugarPobladoId = lp.LugarPobladoId AND v.NumeroVivienda = s.NUM_VIVIENDA
    LEFT JOIN #TipologiaHogar th ON th.LUGAR_POBLADO = s.LUGAR_POBLADO AND th.NUM_VIVIENDA = s.NUM_VIVIENDA AND th.NUM_HOGAR = s.NUM_HOGAR', N's.LUGAR_POBLADO, s.NUM_VIVIENDA, s.NUM_HOGAR'),
 (3, 'Migracion', N'hechos.CensoMigracion', N'stage.Migracion',
  N'FROM stage.Migracion s JOIN dim.Municipio mu ON mu.CodigoMunicipio = s.MUNICIPIO
    JOIN dim.LugarPoblado lp ON lp.MunicipioId = mu.MunicipioId
    JOIN hechos.CensoVivienda v ON v.LugarPobladoId = lp.LugarPobladoId AND v.NumeroVivienda = s.NUM_VIVIENDA
    JOIN hechos.CensoHogar h ON h.ViviendaId = v.ViviendaId AND h.NumeroHogar = s.NUM_HOGAR', NULL),
 (4, 'Poblacion', N'hechos.CensoPoblacion', N'stage.Persona',
  N'FROM stage.Persona s JOIN dim.LugarPoblado lp ON lp.CodigoLugarPoblado = s.LUGAR_POBLADO
    JOIN hechos.CensoVivienda v ON v.LugarPobladoId = lp.LugarPobladoId AND v.NumeroVivienda = s.NUM_VIVIENDA
    LEFT JOIN hechos.CensoHogar h ON h.ViviendaId = v.ViviendaId AND h.NumeroHogar = s.NUM_HOGAR', NULL);

-- ---------------- Tipologia del hogar (cuadro B8) ----------------
-- Parentesco (PCP5): 1 jefe, 2 conyuge, 3 hija o hijo, 4 hijastra(o), 5 a 11 otros parientes, 12 a 14 no parientes.
-- Nucleo: jefe, conyuge e hijos. El INE cuenta al hijastro como otro pariente (un hogar con hijastros es extendido):
-- asi se reproduce exactamente el cuadro B8 (verificado contra las cifras publicadas).
SELECT LUGAR_POBLADO, NUM_VIVIENDA, NUM_HOGAR,
       CASE WHEN COUNT(*) = 1 THEN 1
            WHEN SUM(CASE WHEN PCP5 BETWEEN 12 AND 14 THEN 1 ELSE 0 END) > 0
                 AND SUM(CASE WHEN PCP5 BETWEEN 2 AND 11 THEN 1 ELSE 0 END) = 0 THEN 5
            WHEN SUM(CASE WHEN PCP5 BETWEEN 12 AND 14 THEN 1 ELSE 0 END) > 0 THEN 4
            WHEN SUM(CASE WHEN PCP5 BETWEEN 4 AND 11 THEN 1 ELSE 0 END) > 0 THEN 3
            ELSE 2 END AS CodigoTipoHogar
INTO #TipologiaHogar
FROM stage.Persona
WHERE NUM_HOGAR IS NOT NULL AND PCP5 BETWEEN 1 AND 14
GROUP BY LUGAR_POBLADO, NUM_VIVIENDA, NUM_HOGAR;
PRINT 'Tipologia derivada para ' + FORMAT(@@ROWCOUNT, 'N0') + ' hogares.';
CREATE UNIQUE CLUSTERED INDEX IX_TipologiaHogar ON #TipologiaHogar (LUGAR_POBLADO, NUM_VIVIENDA, NUM_HOGAR);

-- ---------------- 1. Codigos de stage sin miembro en su dimension ----------------
CREATE TABLE #Huerfanos (Columna SYSNAME, Codigo INT);
DECLARE @sql NVARCHAR(MAX), @h VARCHAR(20), @stage NVARCHAR(100);

DECLARE ch CURSOR LOCAL FAST_FORWARD FOR SELECT m.Hecho, hh.Stage,
    N'INSERT #Huerfanos SELECT ''' + m.Hecho + N'.' + m.Destino + N''', x.cod FROM (SELECT DISTINCT ' + m.Expresion + N' AS cod FROM ' + hh.Stage +
    N' s WHERE ' + m.Expresion + N' IS NOT NULL) x WHERE NOT EXISTS (SELECT 1 FROM dim.' + m.Dimension + N' d WHERE d.' +
    CASE WHEN m.Dimension = 'Edad' THEN N'EdadId' ELSE N'Codigo' + m.Dimension END + N' = x.cod);'
  FROM #Mapa m JOIN @Hechos hh ON hh.Hecho = m.Hecho
  -- TipoHogar sale de #TipologiaHogar (no de stage) y sus codigos los genera la regla: siempre 1 a 5
  WHERE m.Dimension IS NOT NULL AND m.Dimension <> 'TipoHogar' ORDER BY m.Orden;
OPEN ch;
FETCH NEXT FROM ch INTO @h, @stage, @sql;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC sp_executesql @sql;
    FETCH NEXT FROM ch INTO @h, @stage, @sql;
END
CLOSE ch; DEALLOCATE ch;

IF EXISTS (SELECT 1 FROM #Huerfanos)
BEGIN
    SELECT Columna, Codigo, COUNT(*) OVER (PARTITION BY Columna) AS codigos_de_la_columna FROM #Huerfanos ORDER BY Columna, Codigo;
    THROW 50006, 'Hay codigos en stage que no existen en su dimension (ver lista). Corrija el catalogo antes de cargar los hechos.', 1;
END
PRINT 'Verificacion de codigos: todos los codigos de stage existen en su dimension.';

-- ---------------- 2. Carga ----------------
DECLARE @destino NVARCHAR(100), @base NVARCHAR(MAX), @orden NVARCHAR(200), @cols NVARCHAR(MAX), @sel NVARCHAR(MAX), @joins NVARCHAR(MAX);
DECLARE @esperadas BIGINT, @insertadas BIGINT, @lote BIGINT, @dep INT, @inicio DATETIME2;

DECLARE cf CURSOR LOCAL FAST_FORWARD FOR SELECT Hecho, Destino, Stage, Base, Ordenar FROM @Hechos ORDER BY Orden;
OPEN cf;
FETCH NEXT FROM cf INTO @h, @destino, @stage, @base, @orden;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @inicio = SYSUTCDATETIME();
    SELECT @cols = STRING_AGG(CAST(Destino AS NVARCHAR(MAX)), N', ') WITHIN GROUP (ORDER BY Orden),
           @sel  = STRING_AGG(CAST(CASE WHEN Dimension IS NULL THEN Expresion ELSE N'd' + CAST(Orden AS NVARCHAR(10)) + N'.' + Dimension + N'Id' END AS NVARCHAR(MAX)), N', ') WITHIN GROUP (ORDER BY Orden),
           @joins = STRING_AGG(CAST(CASE WHEN Dimension IS NULL THEN NULL ELSE
                    N' LEFT JOIN dim.' + Dimension + N' d' + CAST(Orden AS NVARCHAR(10)) + N' ON d' + CAST(Orden AS NVARCHAR(10)) + N'.' +
                    CASE WHEN Dimension = 'Edad' THEN N'EdadId' ELSE N'Codigo' + Dimension END + N' = ' + Expresion END AS NVARCHAR(MAX)), N'') WITHIN GROUP (ORDER BY Orden)
    FROM #Mapa WHERE Hecho = @h;

    SET @sql = N'SELECT @n = COUNT_BIG(*) FROM ' + @stage;
    EXEC sp_executesql @sql, N'@n BIGINT OUTPUT', @n = @esperadas OUTPUT;

    IF @h <> 'Poblacion'
    BEGIN
        SET @sql = N'INSERT INTO ' + @destino + N' WITH (TABLOCK) (' + @cols + N') SELECT ' + @sel + N' ' + @base + @joins +
                   ISNULL(N' ORDER BY ' + @orden, N'');
        EXEC sp_executesql @sql;
        SET @insertadas = @@ROWCOUNT;
    END
    ELSE
    BEGIN
        SET @insertadas = 0;
        SET @sql = N'INSERT INTO ' + @destino + N' WITH (TABLOCK) (' + @cols + N') SELECT ' + @sel + N' ' + @base + @joins +
                   N' WHERE s.LUGAR_POBLADO / 100000 = @dep';
        -- Los departamentos salen de la dimension: T-SQL no permite cursores sobre tablas con columnstore agrupado.
        DECLARE cd CURSOR LOCAL FAST_FORWARD FOR SELECT CodigoDepartamento FROM dim.Departamento ORDER BY CodigoDepartamento;
        OPEN cd;
        FETCH NEXT FROM cd INTO @dep;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            EXEC sp_executesql @sql, N'@dep INT', @dep = @dep;
            SET @lote = @@ROWCOUNT;
            SET @insertadas += @lote;
            PRINT '  departamento ' + CAST(@dep AS VARCHAR(3)) + ': ' + FORMAT(@lote, 'N0') + ' personas';
            FETCH NEXT FROM cd INTO @dep;
        END
        CLOSE cd; DEALLOCATE cd;
    END

    PRINT @destino + ': ' + FORMAT(@insertadas, 'N0') + ' filas (stage: ' + FORMAT(@esperadas, 'N0') + ') en ' +
          CAST(DATEDIFF(SECOND, @inicio, SYSUTCDATETIME()) AS VARCHAR(10)) + ' s';
    IF @insertadas <> @esperadas
        THROW 50007, 'El numero de filas insertadas no coincide con stage: una union perdio o duplico filas.', 1;

    FETCH NEXT FROM cf INTO @h, @destino, @stage, @base, @orden;
END
CLOSE cf; DEALLOCATE cf;
GO

-- ---------------- 3. Revalidar llaves foraneas, comprimir y actualizar estadisticas ----------------
ALTER TABLE hechos.CensoVivienda WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE hechos.CensoHogar WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE hechos.CensoMigracion WITH CHECK CHECK CONSTRAINT ALL;
ALTER TABLE hechos.CensoPoblacion WITH CHECK CHECK CONSTRAINT ALL;
ALTER INDEX IX_Hechos_CensoVivienda_Columnstore ON hechos.CensoVivienda REORGANIZE WITH (COMPRESS_ALL_ROW_GROUPS = ON);
ALTER INDEX IX_Hechos_CensoHogar_Columnstore ON hechos.CensoHogar REORGANIZE WITH (COMPRESS_ALL_ROW_GROUPS = ON);
ALTER INDEX IX_Hechos_CensoPoblacion_Columnstore ON hechos.CensoPoblacion REORGANIZE WITH (COMPRESS_ALL_ROW_GROUPS = ON);
UPDATE STATISTICS hechos.CensoVivienda;
UPDATE STATISTICS hechos.CensoHogar;
UPDATE STATISTICS hechos.CensoMigracion;
UPDATE STATISTICS hechos.CensoPoblacion;
PRINT 'Llaves foraneas revalidadas, columnstore comprimido y estadisticas actualizadas.';
GO
