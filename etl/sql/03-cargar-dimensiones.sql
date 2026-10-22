/*
    Carga las 38 dimensiones a partir de stage (etl/sql/02-cargar-stage.sql).

    - Territorio: Departamento y Municipio salen de los catalogos del .sav; LugarPoblado, de stage.LugarPoblado (una fila por lugar).
    - Catalogos: cada dimension se puebla con las etiquetas de valor de una o mas variables del .sav
      (tabla #Fuente). Si un mismo codigo aparece en varias variables, gana la de menor prioridad.
    - Jerarquias: el grupo de Ocupacion y RamaActividad y el nivel educativo de NivelGrado salen de stage.Jerarquia
      (grupo mas frecuente de cada codigo; las excepciones del origen se reportan al final). Los codigos de
      esas variables presentes en los datos pero sin etiqueta en el .sav se agregan con un nombre explicito.
    - Generadas por regla: Dim.Edad (0 a 124), Dim.CondicionActividad (5 miembros del proyecto) y las clasificaciones
      que publica el INE en sus cuadros: Dim.TipoHogar (B8, 5 miembros) y Dim.CondicionDificultad (A8, 3 miembros).
    - Las etiquetas se limpian con LTRIM/RTRIM. Todo ocurre en una transaccion.
*/

USE [CensoGT2018];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

IF EXISTS (SELECT 1 FROM dim.Departamento) OR EXISTS (SELECT 1 FROM dim.Sexo)
    THROW 50001, 'Las dimensiones ya tienen datos. Ejecute etl/sql/00-vaciar-modelo.sql antes de recargar.', 1;

IF NOT EXISTS (SELECT 1 FROM stage.Catalogo) OR NOT EXISTS (SELECT 1 FROM stage.LugarPoblado) OR NOT EXISTS (SELECT 1 FROM stage.Jerarquia)
    THROW 50002, 'stage esta vacia. Ejecute etl/sql/02-cargar-stage.sql antes de cargar las dimensiones.', 1;

IF (SELECT COUNT(*) FROM stage.LugarPoblado) <> (SELECT COUNT(DISTINCT LUGAR_POBLADO) FROM stage.LugarPoblado)
    THROW 50008, 'Un lugar poblado tiene mas de un nombre, municipio o zona en el origen: revise stage.LugarPoblado.', 1;

BEGIN TRANSACTION;

-- ---------------- Territorio ----------------
INSERT dim.Departamento (CodigoDepartamento, NombreDepartamento)
SELECT Codigo, LTRIM(RTRIM(Etiqueta))
FROM stage.Catalogo
WHERE Archivo = 'VIVIENDA' AND Variable = 'DEPARTAMENTO'
ORDER BY Codigo;

-- 340 municipios + 22 "municipio no declarado" (codigos terminados en 99), del catalogo de lugar de nacimiento
INSERT dim.Municipio (CodigoMunicipio, NombreMunicipio, DepartamentoId, EsMunicipioNoDeclarado)
SELECT c.Codigo, LTRIM(RTRIM(c.Etiqueta)), d.DepartamentoId, CASE WHEN c.Codigo % 100 = 99 THEN 1 ELSE 0 END
FROM stage.Catalogo c
JOIN dim.Departamento d ON d.CodigoDepartamento = c.Codigo / 100
WHERE c.Archivo = 'PERSONA' AND c.Variable = 'LUGNACGEO'
ORDER BY c.Codigo;

INSERT dim.LugarPoblado (CodigoLugarPoblado, NombreLugarPoblado, MunicipioId, Zona)
SELECT l.LUGAR_POBLADO, LTRIM(RTRIM(l.NOMBRE_LUGAR_POBLADO)), m.MunicipioId, l.ZONA
FROM stage.LugarPoblado l
JOIN dim.Municipio m ON m.CodigoMunicipio = l.MUNICIPIO
ORDER BY l.LUGAR_POBLADO;

-- ---------------- Catalogos desde las etiquetas del .sav ----------------
CREATE TABLE #Fuente (Dimension SYSNAME NOT NULL, Archivo VARCHAR(20) NOT NULL, Variable VARCHAR(40) NOT NULL, Prioridad INT NOT NULL);
INSERT #Fuente (Dimension, Archivo, Variable, Prioridad) VALUES
 ('Sexo', 'PERSONA', 'PCP6', 1), ('Sexo', 'MIGRACION', 'PEI3', 2),
 ('RespuestaSiNo', 'PERSONA', 'PCP26_A', 1), ('RespuestaSiNo', 'PERSONA', 'PCP26_B', 2), ('RespuestaSiNo', 'PERSONA', 'PCP26_C', 3),
 ('RespuestaSiNo', 'PERSONA', 'PCP9', 4), ('RespuestaSiNo', 'PERSONA', 'PCP14', 5),
 ('Pais', 'PERSONA', 'PCP10_C', 1), ('Pais', 'PERSONA', 'PCP11_C', 2), ('Pais', 'PERSONA', 'PCP20_C', 3), ('Pais', 'PERSONA', 'PCP33_C', 4),
 ('Idioma', 'PERSONA', 'PCP15', 1), ('Idioma', 'PERSONA', 'PCP23_A', 2), ('Idioma', 'PERSONA', 'PCP23_B', 3), ('Idioma', 'PERSONA', 'PCP23_C', 4),
 ('Idioma', 'PERSONA', 'PCP25_A', 5), ('Idioma', 'PERSONA', 'PCP25_B', 6), ('Idioma', 'PERSONA', 'PCP25_C', 7),
 ('TipoLugar', 'PERSONA', 'PCP10', 1), ('TipoLugar', 'PERSONA', 'PCP20', 2), ('TipoLugar', 'PERSONA', 'PCP33', 3),
 ('SexoResponsable', 'HOGAR', 'PCH2', 1), ('SexoResponsable', 'HOGAR', 'PCH3', 2),
 ('TipoVivienda', 'VIVIENDA', 'PCV1', 1), ('MaterialPared', 'VIVIENDA', 'PCV2', 1), ('MaterialTecho', 'VIVIENDA', 'PCV3', 1),
 ('CondicionVivienda', 'VIVIENDA', 'PCV4', 1), ('MaterialPiso', 'VIVIENDA', 'PCV5', 1),
 ('TenenciaVivienda', 'HOGAR', 'PCH1', 1), ('FuenteAgua', 'HOGAR', 'PCH4', 1), ('TipoServicioSanitario', 'HOGAR', 'PCH5', 1),
 ('UsoServicioSanitario', 'HOGAR', 'PCH6', 1), ('DesagueAguasGrises', 'HOGAR', 'PCH7', 1), ('TipoAlumbrado', 'HOGAR', 'PCH8', 1),
 ('EliminacionBasura', 'HOGAR', 'PCH10', 1), ('CombustibleCocina', 'HOGAR', 'PCH14', 1),
 ('Parentesco', 'PERSONA', 'PCP5', 1), ('TipoResidencia2013', 'PERSONA', 'PCP11', 1), ('Pueblo', 'PERSONA', 'PCP12', 1),
 ('ComunidadLinguistica', 'PERSONA', 'PCP13', 1),
 ('GradoDificultad', 'PERSONA', 'PCP16_A', 1), ('GradoDificultad', 'PERSONA', 'PCP16_B', 2), ('GradoDificultad', 'PERSONA', 'PCP16_C', 3),
 ('GradoDificultad', 'PERSONA', 'PCP16_D', 4), ('GradoDificultad', 'PERSONA', 'PCP16_E', 5), ('GradoDificultad', 'PERSONA', 'PCP16_F', 6),
 ('NivelGrado', 'PERSONA', 'NIVGRADO', 1), ('TipoEstablecimiento', 'PERSONA', 'PCP19', 1), ('CausaNoAsistencia', 'PERSONA', 'PCP21', 1),
 ('ActividadSemana', 'PERSONA', 'PCP28', 1), ('ActividadNoTrabajo', 'PERSONA', 'PCP29', 1),
 ('Ocupacion', 'PERSONA', 'PCP30_2D', 1), ('RamaActividad', 'PERSONA', 'PCP32_2D', 1),
 ('CategoriaOcupacional', 'PERSONA', 'PCP31_D', 1), ('EstadoConyugal', 'PERSONA', 'PCP34', 1);

DECLARE @dimension SYSNAME, @sql NVARCHAR(MAX);
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT DISTINCT Dimension FROM #Fuente ORDER BY Dimension;
OPEN cur;
FETCH NEXT FROM cur INTO @dimension;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'INSERT dim.' + QUOTENAME(@dimension) + N' (Codigo' + @dimension + N', Nombre' + @dimension + N')
        SELECT Codigo, Etiqueta FROM (
            SELECT c.Codigo, LTRIM(RTRIM(c.Etiqueta)) AS Etiqueta,
                   ROW_NUMBER() OVER (PARTITION BY c.Codigo ORDER BY f.Prioridad) AS rn
            FROM stage.Catalogo c
            JOIN #Fuente f ON f.Archivo = c.Archivo AND f.Variable = c.Variable
            WHERE f.Dimension = @d) x
        WHERE rn = 1 ORDER BY Codigo;';
    EXEC sp_executesql @sql, N'@d SYSNAME', @d = @dimension;
    FETCH NEXT FROM cur INTO @dimension;
END
CLOSE cur; DEALLOCATE cur;

-- ---------------- Jerarquias ----------------
-- En el origen algunos codigos de 2 digitos aparecen con mas de un grupo de 1 digito (por ejemplo la rama 36 con
-- los grupos 5 y 20). Cada codigo se asigna a su grupo mas frecuente; las excepciones se cuantifican al final.
SELECT Jerarquia, Hijo, Padre
INTO #Jer
FROM (SELECT Jerarquia, Hijo, Padre, ROW_NUMBER() OVER (PARTITION BY Jerarquia, Hijo ORDER BY N DESC, Padre) AS rn
      FROM stage.Jerarquia) x
WHERE rn = 1;

-- Codigos presentes en los datos que no tienen etiqueta en el .sav (por ejemplo la rama 54, de una sola persona).
-- Se agregan con un nombre que lo deja explicito, para no perder ni reasignar el registro.
INSERT dim.NivelGrado (CodigoNivelGrado, NombreNivelGrado)
SELECT j.Hijo, CONCAT('Codigo ', j.Hijo, ' sin etiqueta en el origen') FROM #Jer j
WHERE j.Jerarquia = 'NIVGRADO_NIVEL' AND NOT EXISTS (SELECT 1 FROM dim.NivelGrado d WHERE d.CodigoNivelGrado = j.Hijo);
INSERT dim.Ocupacion (CodigoOcupacion, NombreOcupacion)
SELECT j.Hijo, CONCAT('Codigo ', j.Hijo, ' sin etiqueta en el origen') FROM #Jer j
WHERE j.Jerarquia = 'OCUPACION_GRUPO' AND NOT EXISTS (SELECT 1 FROM dim.Ocupacion d WHERE d.CodigoOcupacion = j.Hijo);
INSERT dim.RamaActividad (CodigoRamaActividad, NombreRamaActividad)
SELECT j.Hijo, CONCAT('Codigo ', j.Hijo, ' sin etiqueta en el origen') FROM #Jer j
WHERE j.Jerarquia = 'RAMA_GRUPO' AND NOT EXISTS (SELECT 1 FROM dim.RamaActividad d WHERE d.CodigoRamaActividad = j.Hijo);

UPDATE n
SET CodigoNivelEducativo = j.Padre, NombreNivelEducativo = LTRIM(RTRIM(c.Etiqueta))
FROM dim.NivelGrado n
JOIN #Jer j ON j.Jerarquia = 'NIVGRADO_NIVEL' AND j.Hijo = n.CodigoNivelGrado
JOIN stage.Catalogo c ON c.Archivo = 'PERSONA' AND c.Variable = 'PCP17_A' AND c.Codigo = j.Padre;

UPDATE o
SET CodigoGrupoOcupacion = j.Padre, NombreGrupoOcupacion = LTRIM(RTRIM(c.Etiqueta))
FROM dim.Ocupacion o
JOIN #Jer j ON j.Jerarquia = 'OCUPACION_GRUPO' AND j.Hijo = o.CodigoOcupacion
JOIN stage.Catalogo c ON c.Archivo = 'PERSONA' AND c.Variable = 'PCP30_1D' AND c.Codigo = j.Padre;

UPDATE r
SET CodigoGrupoRamaActividad = j.Padre, NombreGrupoRamaActividad = LTRIM(RTRIM(c.Etiqueta))
FROM dim.RamaActividad r
JOIN #Jer j ON j.Jerarquia = 'RAMA_GRUPO' AND j.Hijo = r.CodigoRamaActividad
JOIN stage.Catalogo c ON c.Archivo = 'PERSONA' AND c.Variable = 'PCP32_1D' AND c.Codigo = j.Padre;

-- ---------------- Dimensiones generadas por regla ----------------
INSERT dim.Edad (EdadId, GrupoQuinquenal, OrdenGrupoQuinquenal, GrupoAmplio, EsEdadTrabajar)
SELECT n,
       CASE WHEN n >= 100 THEN '100 y mas' ELSE CONCAT(n / 5 * 5, '-', n / 5 * 5 + 4) END,
       CASE WHEN n >= 100 THEN 20 ELSE n / 5 END,
       CASE WHEN n < 15 THEN '0-14' WHEN n < 65 THEN '15-64' ELSE '65 y mas' END,
       CASE WHEN n >= 15 THEN 1 ELSE 0 END
FROM (SELECT TOP (125) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
      FROM sys.all_objects a CROSS JOIN sys.all_objects b) t;

INSERT dim.CondicionActividad (CodigoCondicionActividad, NombreCondicionActividad) VALUES
 (1, 'Ocupada'), (2, 'Desocupada aspirante'), (3, 'Desocupada cesante'), (4, 'Inactiva'), (5, 'No declarada');

INSERT dim.TipoHogar (CodigoTipoHogar, NombreTipoHogar) VALUES
 (1, 'Unipersonal'), (2, 'Nuclear'), (3, 'Extendido'), (4, 'Compuesto'), (5, 'Co-residentes');

INSERT dim.CondicionDificultad (CodigoCondicionDificultad, NombreCondicionDificultad) VALUES
 (1, 'Sin dificultad'), (2, 'Con al menos una dificultad'), (9, 'No declarado');

COMMIT TRANSACTION;

-- ---------------- Excepciones de las jerarquias en el origen ----------------
SELECT s.Jerarquia, COUNT(DISTINCT s.Hijo) AS codigos_con_varios_grupos, SUM(s.N) AS personas_fuera_del_grupo_asignado,
       (SELECT SUM(N) FROM stage.Jerarquia k WHERE k.Jerarquia = s.Jerarquia) AS personas_con_codigo
FROM stage.Jerarquia s
JOIN #Jer j ON j.Jerarquia = s.Jerarquia AND j.Hijo = s.Hijo AND s.Padre <> j.Padre
GROUP BY s.Jerarquia;

-- ---------------- Resumen ----------------
SELECT s.name + '.' + t.name AS dimension, SUM(p.rows) AS miembros
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.partitions p ON p.object_id = t.object_id AND p.index_id IN (0, 1)
WHERE s.name = 'dim'
GROUP BY s.name, t.name
ORDER BY t.name;
GO
