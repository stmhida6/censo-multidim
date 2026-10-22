// Consultas de las paginas fijas del tablero. Cada bloque es una consulta en blanco con el nombre indicado.
// Todas pasan por ConsultarCenso: el tablero no calcula indicadores, solo presenta lo que devuelve la API.

// ================================================================ Pagina 1: Panorama nacional

// ---------------------------------------------------------------- Totales
// Totales de cada hecho. Las viviendas excluyen los 346 registros "Sin vivienda" (tipo 11), como el cuadro C1 del INE.
let
    Personas = ConsultarCenso([medidas = {"personas"}]){0}[personas],
    Hogares = ConsultarCenso([medidas = {"hogares"}]){0}[hogares],
    Viviendas = ConsultarCenso([medidas = {"viviendas"},
        filtros = {[nivel = "tipoVivienda", operador = "Distinto", valores = {11}]}]){0}[viviendas],
    Emigrantes = ConsultarCenso([medidas = {"emigrantes"}]){0}[emigrantes],
    Tabla = #table(type table [Concepto = text, Valor = Int64.Type, Orden = Int64.Type], {
        {"Personas", Personas, 1},
        {"Hogares", Hogares, 2},
        {"Viviendas", Viviendas, 3},
        {"Emigrantes internacionales", Emigrantes, 4}})
in
    Tabla

// ---------------------------------------------------------------- IndicadoresNacionales
// Un renglon por indicador (clave, valor). El nombre, la formula y la fuente vienen de CatalogoIndicadores mediante una
// relacion del modelo por "clave".
let
    Poblacion = ConsultarCenso([incluirComponentes = false, indicadores = {
        "indiceMasculinidad", "relacionDependencia", "tasaGlobalParticipacion", "tasaDesempleoAbierto",
        "tasaAlfabetismo", "porcentajeMigrantesVida"}]),
    Hogar = ConsultarCenso([incluirComponentes = false, indicadores = {
        "tamanioPromedioHogar", "porcentajeHogaresConInternet", "porcentajeHogaresConRemesas"}]),
    Vivienda = ConsultarCenso([incluirComponentes = false, indicadores = {"porcentajeViviendasOcupadas"},
        filtros = {[nivel = "tipoVivienda", operador = "Distinto", valores = {11}]}]),
    Largas = List.Transform({Poblacion, Hogar, Vivienda}, each Record.ToTable(_{0})),
    Combinada = Table.Combine(Largas),
    Renombrada = Table.RenameColumns(Combinada, {{"Name", "clave"}, {"Value", "valor"}}),
    Tipada = Table.TransformColumnTypes(Renombrada, {{"clave", type text}, {"valor", type number}})
in
    Tipada

// ================================================================ Pagina 2: Territorio

// ---------------------------------------------------------------- IndicadoresPorMunicipio
// Indicadores laborales, de alfabetismo y de masculinidad por municipio (340 renglones), con numerador y denominador
// para que las tarjetas y totales se re-agreguen correctamente (medidas DAX en medidas.dax).
let
    Resultado = ConsultarCenso([
        indicadores = {"tasaGlobalParticipacion", "tasaDesempleoAbierto", "tasaAlfabetismo", "indiceMasculinidad"},
        dimensiones = {"departamento", "municipio"},
        limite = 1000]),
    ConUbicacion = Table.AddColumn(Resultado, "Ubicacion",
        each [municipio] & ", " & [departamento] & ", Guatemala", type text)
in
    ConUbicacion

// ================================================================ Pagina 3: Poblacion

// ---------------------------------------------------------------- Piramide
// Personas por departamento, grupo quinquenal y sexo (924 renglones). OrdenGrupo permite ordenar los grupos por edad.
let
    Resultado = ConsultarCenso([medidas = {"personas"}, dimensiones = {"departamento", "grupoQuinquenal", "sexo"}]),
    ConOrden = Table.AddColumn(Resultado, "OrdenGrupo",
        each try Number.From(Text.BeforeDelimiter([grupoQuinquenal], "-")) otherwise 100, Int64.Type)
in
    ConOrden

// ---------------------------------------------------------------- PoblacionPorPueblo
let
    Resultado = ConsultarCenso([medidas = {"personas"}, dimensiones = {"departamento", "pueblo"}])
in
    Resultado

// ================================================================ Pagina 4: Hogar y vivienda

// ---------------------------------------------------------------- HogaresPorFuenteAgua
let
    Resultado = ConsultarCenso([medidas = {"hogares"}, dimensiones = {"departamento", "esUrbano", "fuenteAgua"}]),
    ConArea = Table.AddColumn(Resultado, "Area", each if [esUrbano_codigo] = 1 then "Urbana" else "Rural", type text)
in
    ConArea

// ---------------------------------------------------------------- IndicadoresHogarPorDepartamento
let
    Resultado = ConsultarCenso([
        indicadores = {"tamanioPromedioHogar", "porcentajeHogaresConInternet", "porcentajeHogaresConRemesas"},
        dimensiones = {"departamento"}])
in
    Resultado
