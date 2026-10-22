/*
    Valida la carga contra cifras independientes de la propia carga: los conteos de los .sav, las
    verificaciones de etl/r/01 a 06 y el diccionario de variables (etl/jsonl). Cada control compara un
    valor esperado con el obtenido; si alguno falla, el script termina con error.
    Controles descritos en docs/diagramas/flujo-etl.md (seccion 3).
*/

USE [CensoGT2018];
GO

SET NOCOUNT ON;

CREATE TABLE #Resultado (Orden INT IDENTITY(1,1), Grupo VARCHAR(30), Control VARCHAR(120), Esperado BIGINT, Obtenido BIGINT);

-- ---------------- Filas cargadas ----------------
INSERT #Resultado (Grupo, Control, Esperado, Obtenido) VALUES
 ('Filas', 'hechos.CensoVivienda', 3943431, (SELECT COUNT_BIG(*) FROM hechos.CensoVivienda)),
 ('Filas', 'hechos.CensoHogar', 3275931, (SELECT COUNT_BIG(*) FROM hechos.CensoHogar)),
 ('Filas', 'hechos.CensoPoblacion', 14901286, (SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion)),
 ('Filas', 'hechos.CensoMigracion', 242203, (SELECT COUNT_BIG(*) FROM hechos.CensoMigracion)),
 ('Filas', 'dim.Departamento', 22, (SELECT COUNT_BIG(*) FROM dim.Departamento)),
 ('Filas', 'dim.Municipio (340 + 22 no declarado)', 362, (SELECT COUNT_BIG(*) FROM dim.Municipio)),
 ('Filas', 'dim.Municipio marcados como no declarado', 22, (SELECT COUNT_BIG(*) FROM dim.Municipio WHERE EsMunicipioNoDeclarado = 1)),
 ('Filas', 'dim.LugarPoblado', 20254, (SELECT COUNT_BIG(*) FROM dim.LugarPoblado)),
 ('Filas', 'dim.Edad (0 a 124)', 125, (SELECT COUNT_BIG(*) FROM dim.Edad)),
 ('Filas', 'dim.CondicionActividad', 5, (SELECT COUNT_BIG(*) FROM dim.CondicionActividad)),
 ('Filas', 'Miembros agregados por codigo sin etiqueta en el origen (rama 54, una persona)', 1,
    (SELECT (SELECT COUNT_BIG(*) FROM dim.RamaActividad WHERE NombreRamaActividad LIKE '%sin etiqueta en el origen')
          + (SELECT COUNT_BIG(*) FROM dim.Ocupacion WHERE NombreOcupacion LIKE '%sin etiqueta en el origen')
          + (SELECT COUNT_BIG(*) FROM dim.NivelGrado WHERE NombreNivelGrado LIKE '%sin etiqueta en el origen'))),
 ('Filas', 'Personas con el codigo de rama 54 sin etiqueta', 1,
    (SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion p JOIN dim.RamaActividad r ON r.RamaActividadId = p.RamaActividadId WHERE r.CodigoRamaActividad = 54));

-- ---------------- Integridad y jerarquia (etl/r/01) ----------------
INSERT #Resultado (Grupo, Control, Esperado, Obtenido) VALUES
 ('Integridad', 'Llaves foraneas del modelo', 78, (SELECT COUNT_BIG(*) FROM sys.foreign_keys)),
 ('Integridad', 'Llaves foraneas desactivadas o no confiables', 0, (SELECT COUNT_BIG(*) FROM sys.foreign_keys WHERE is_disabled = 1 OR is_not_trusted = 1)),
 ('Integridad', 'Personas sin hogar', 43752, (SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion WHERE HogarId IS NULL)),
 ('Integridad', 'Personas sin hogar en vivienda colectiva (PCV1 = 10)', 42536,
    (SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion p JOIN hechos.CensoVivienda v ON v.ViviendaId = p.ViviendaId
     JOIN dim.TipoVivienda t ON t.TipoViviendaId = v.TipoViviendaId WHERE p.HogarId IS NULL AND t.CodigoTipoVivienda = 10)),
 ('Integridad', 'Personas sin hogar sin vivienda (PCV1 = 11)', 1216,
    (SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion p JOIN hechos.CensoVivienda v ON v.ViviendaId = p.ViviendaId
     JOIN dim.TipoVivienda t ON t.TipoViviendaId = v.TipoViviendaId WHERE p.HogarId IS NULL AND t.CodigoTipoVivienda = 11)),
 ('Integridad', 'Viviendas sin hogar', 763836,
    (SELECT COUNT_BIG(*) FROM hechos.CensoVivienda v WHERE NOT EXISTS (SELECT 1 FROM hechos.CensoHogar h WHERE h.ViviendaId = v.ViviendaId))),
 ('Integridad', 'Hogares con TotalPersonas distinto del conteo de sus personas (etl/r/03)', 0,
    (SELECT COUNT_BIG(*) FROM hechos.CensoHogar h
     LEFT JOIN (SELECT HogarId, COUNT(*) AS n FROM hechos.CensoPoblacion WHERE HogarId IS NOT NULL GROUP BY HogarId) p ON p.HogarId = h.HogarId
     WHERE h.TotalPersonas <> ISNULL(p.n, 0))),
 ('Integridad', 'Jerarquias sin grupo: Ocupacion', 0, (SELECT COUNT_BIG(*) FROM dim.Ocupacion WHERE CodigoGrupoOcupacion IS NULL)),
 ('Integridad', 'Jerarquias sin grupo: RamaActividad', 0, (SELECT COUNT_BIG(*) FROM dim.RamaActividad WHERE CodigoGrupoRamaActividad IS NULL)),
 ('Integridad', 'Jerarquias sin nivel: NivelGrado', 0, (SELECT COUNT_BIG(*) FROM dim.NivelGrado WHERE CodigoNivelEducativo IS NULL));

-- ---------------- Cifras del diccionario de variables (etl/jsonl) ----------------
INSERT #Resultado (Grupo, Control, Esperado, Obtenido) VALUES
 ('Diccionario', 'Viviendas urbanas (AREA = 1)', 2213460, (SELECT COUNT_BIG(*) FROM hechos.CensoVivienda WHERE EsUrbano = 1)),
 ('Diccionario', 'Viviendas rurales (AREA = 2)', 1729971, (SELECT COUNT_BIG(*) FROM hechos.CensoVivienda WHERE EsUrbano = 0)),
 ('Diccionario', 'Viviendas tipo casa formal (PCV1 = 1)', 3709732,
    (SELECT COUNT_BIG(*) FROM hechos.CensoVivienda v JOIN dim.TipoVivienda t ON t.TipoViviendaId = v.TipoViviendaId WHERE t.CodigoTipoVivienda = 1)),
 ('Diccionario', 'Hogares con radio (PCH9_A = 1)', 2140443, (SELECT COUNT_BIG(*) FROM hechos.CensoHogar WHERE TieneRadio = 1)),
 ('Diccionario', 'Hogares con carro (PCH9_M = 1)', 779946, (SELECT COUNT_BIG(*) FROM hechos.CensoHogar WHERE TieneCarro = 1)),
 ('Diccionario', 'Hogares con propietario hombre (PCH2 = 1)', 1481440,
    (SELECT COUNT_BIG(*) FROM hechos.CensoHogar h JOIN dim.SexoResponsable s ON s.SexoResponsableId = h.SexoPropietarioId WHERE s.CodigoSexoResponsable = 1)),
 ('Diccionario', 'Personas mayas (PCP12 = 1)', 6207503,
    (SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion p JOIN dim.Pueblo d ON d.PuebloId = p.PuebloId WHERE d.CodigoPueblo = 1)),
 ('Diccionario', 'Personas ladinas (PCP12 = 5)', 8346120,
    (SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion p JOIN dim.Pueblo d ON d.PuebloId = p.PuebloId WHERE d.CodigoPueblo = 5)),
 ('Diccionario', 'Personas con inscripcion en RENAP (PCP9 = 1)', 14556418,
    (SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion p JOIN dim.RespuestaSiNo r ON r.RespuestaSiNoId = p.InscripcionRenapId WHERE r.CodigoRespuestaSiNo = 1)),
 ('Transformacion', 'PCP9 con codigo 9 (no declarado) conservado como miembro de la dimension', 241578,
    (SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion p JOIN dim.RespuestaSiNo r ON r.RespuestaSiNoId = p.InscripcionRenapId WHERE r.CodigoRespuestaSiNo = 9)),
 ('Transformacion', 'PCP14 con codigo 9 (no declarado) conservado como miembro de la dimension', 371419,
    (SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion p JOIN dim.RespuestaSiNo r ON r.RespuestaSiNoId = p.UsoTrajeTradicionalId WHERE r.CodigoRespuestaSiNo = 9)),
 ('Diccionario', 'Personas que asisten a un establecimiento (PCP18 = 1)', 4062290, (SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion WHERE EsEstudiante = 1)),
 ('Diccionario', 'Migrantes de toda la vida (MIGRA_VIDA = 2, etl/r/06)', 2598582, (SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion WHERE EsMigranteVida = 1)),
 ('Diccionario', 'Emigrantes hombres (PEI3 = 1)', 187756,
    (SELECT COUNT_BIG(*) FROM hechos.CensoMigracion m JOIN dim.Sexo s ON s.SexoId = m.SexoId WHERE s.CodigoSexo = 1)),
 ('Diccionario', 'Emigrantes mujeres (PEI3 = 2)', 54447,
    (SELECT COUNT_BIG(*) FROM hechos.CensoMigracion m JOIN dim.Sexo s ON s.SexoId = m.SexoId WHERE s.CodigoSexo = 2));

-- ---------------- Condicion de actividad derivada (etl/r/06) ----------------
INSERT #Resultado (Grupo, Control, Esperado, Obtenido) VALUES
 ('Actividad', 'Ocupadas (POCUPA = 1)', 4968542,
    (SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion p JOIN dim.CondicionActividad c ON c.CondicionActividadId = p.CondicionActividadId WHERE c.CodigoCondicionActividad = 1)),
 ('Actividad', 'Desocupadas aspirantes (PDESOC = 1)', 53516,
    (SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion p JOIN dim.CondicionActividad c ON c.CondicionActividadId = p.CondicionActividadId WHERE c.CodigoCondicionActividad = 2)),
 ('Actividad', 'Desocupadas cesantes (PDESOC = 2)', 87952,
    (SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion p JOIN dim.CondicionActividad c ON c.CondicionActividadId = p.CondicionActividadId WHERE c.CodigoCondicionActividad = 3)),
 ('Actividad', 'Inactivas (PEI = 1)', 7249485,
    (SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion p JOIN dim.CondicionActividad c ON c.CondicionActividadId = p.CondicionActividadId WHERE c.CodigoCondicionActividad = 4)),
 ('Actividad', 'No declaradas (7 anios o mas sin bandera, coincide con PCP29 = 9)', 169442,
    (SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion p JOIN dim.CondicionActividad c ON c.CondicionActividadId = p.CondicionActividadId WHERE c.CodigoCondicionActividad = 5)),
 ('Actividad', 'Menores de 7 anios sin condicion de actividad', 2372349, (SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion WHERE CondicionActividadId IS NULL));

-- ---------------- Clasificaciones derivadas contra los cuadros publicados por el INE (validacion/cuadros-oficiales) ----------------
INSERT #Resultado (Grupo, Control, Esperado, Obtenido)
SELECT 'Derivadas', 'Hogares ' + t.NombreTipoHogar + ' (cuadro B8)', o.Esperado, COUNT_BIG(h.HogarId)
FROM (VALUES (1, 199200), (2, 2026420), (3, 960860), (4, 79606), (5, 9845)) o (Codigo, Esperado)
JOIN dim.TipoHogar t ON t.CodigoTipoHogar = o.Codigo
LEFT JOIN hechos.CensoHogar h ON h.TipoHogarId = t.TipoHogarId
GROUP BY t.CodigoTipoHogar, t.NombreTipoHogar, o.Esperado
ORDER BY t.CodigoTipoHogar;

INSERT #Resultado (Grupo, Control, Esperado, Obtenido)
SELECT 'Derivadas', 'Personas de 4 anios o mas: ' + c.NombreCondicionDificultad + ' (cuadro A8)', o.Esperado, COUNT_BIG(p.PersonaId)
FROM (VALUES (1, 11843957), (2, 1408736), (9, 314204)) o (Codigo, Esperado)
JOIN dim.CondicionDificultad c ON c.CodigoCondicionDificultad = o.Codigo
LEFT JOIN hechos.CensoPoblacion p ON p.CondicionDificultadId = c.CondicionDificultadId
GROUP BY c.CodigoCondicionDificultad, c.NombreCondicionDificultad, o.Esperado
ORDER BY c.CodigoCondicionDificultad;

INSERT #Resultado (Grupo, Control, Esperado, Obtenido) VALUES
 ('Derivadas', 'Menores de 4 anios sin condicion de dificultad', 1334389, (SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion WHERE CondicionDificultadId IS NULL));

-- ---------------- Valores centinela y codificacion de texto ----------------
INSERT #Resultado (Grupo, Control, Esperado, Obtenido) VALUES
 ('Transformacion', 'Hijos nacidos vivos nulos (8,884,245 no aplica + 476,501 codigo 99)', 9360746, (SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion WHERE HijosNacidosVivos IS NULL)),
 ('Transformacion', 'Valores 99 o 9999 restantes en columnas con centinela', 0,
    (SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion WHERE HijosNacidosVivos = 99 OR EdadPrimerHijo = 99 OR DiaUltimoHijo = 99 OR MesUltimoHijo = 99 OR AnioUltimoHijo = 9999 OR AnioLlegadaPais = 9999)),
 ('Transformacion', 'Anios de salida 9999 restantes en migracion', 0, (SELECT COUNT_BIG(*) FROM hechos.CensoMigracion WHERE AnioSalida = 9999)),
 ('Texto', 'Departamento "Quiche" con e acentuada (cp1252 = 233)', 1,
    (SELECT COUNT_BIG(*) FROM dim.Departamento WHERE NombreDepartamento LIKE 'Quich_' AND UNICODE(SUBSTRING(NombreDepartamento, 6, 1)) = 233)),
 ('Texto', 'Nombres con caracteres corruptos en Departamento y Municipio', 0,
    (SELECT (SELECT COUNT_BIG(*) FROM dim.Departamento WHERE NombreDepartamento LIKE '%' + NCHAR(195) + '%' OR NombreDepartamento LIKE '%?%')
          + (SELECT COUNT_BIG(*) FROM dim.Municipio WHERE NombreMunicipio LIKE '%' + NCHAR(195) + '%' OR NombreMunicipio LIKE '%?%'))),
 -- Defecto del origen, no de la carga (etl/r/07-verificacion-nombres-lugares.R): 3 nombres con el caracter de control U+0081
 -- tras la 'a con tilde' y 1 con un signo de interrogacion literal (Ca?averal Del Lago).
 ('Texto', 'Nombres de lugares poblados con defectos de codificacion ya presentes en el .sav', 4,
    (SELECT COUNT_BIG(*) FROM dim.LugarPoblado WHERE NombreLugarPoblado LIKE '%' + NCHAR(195) + '%' OR NombreLugarPoblado LIKE '%?%')),
 ('Texto', 'Etiquetas con espacios al inicio o al final en dimensiones', 0,
    (SELECT COUNT_BIG(*) FROM dim.Municipio WHERE NombreMunicipio <> LTRIM(RTRIM(NombreMunicipio))));

SELECT Grupo, Control, Esperado, Obtenido, CASE WHEN Esperado = Obtenido THEN 'OK' ELSE 'FALLO' END AS Resultado
FROM #Resultado ORDER BY Orden;

DECLARE @fallos INT = (SELECT COUNT(*) FROM #Resultado WHERE Esperado <> Obtenido);
DECLARE @total INT = (SELECT COUNT(*) FROM #Resultado);
PRINT CAST(@total - @fallos AS VARCHAR(10)) + ' de ' + CAST(@total AS VARCHAR(10)) + ' controles correctos.';
IF @fallos > 0 THROW 50010, 'La validacion de la carga encontro diferencias: revise los controles con Resultado = FALLO.', 1;
GO
