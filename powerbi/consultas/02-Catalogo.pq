// Catalogo del sistema, leido de GET /api/catalogo/*. Son tres consultas separadas en Power BI; crear cada una como
// Consulta en blanco con el nombre indicado. Sirven para mostrar al usuario que puede consultar (pagina "Catalogo"),
// para dar nombre y formula a los indicadores (relacion con las tablas de resultados) y como lista de valores
// sugeridos de los parametros de la pagina "Consulta libre".

// ---------------------------------------------------------------- CatalogoIndicadores
let
    Fuente = Json.Document(Web.Contents(UrlApi, [RelativePath = "api/catalogo/indicadores"])),
    Tabla = Table.FromRecords(Fuente,
        {"clave", "nombre", "descripcion", "hecho", "formula", "fuente", "unidad", "multiplicador", "numerador", "denominador"},
        MissingField.UseNull),
    Tipos = Table.TransformColumnTypes(Tabla, {{"multiplicador", type number}})
in
    Tipos

// ---------------------------------------------------------------- CatalogoMedidas
let
    Fuente = Json.Document(Web.Contents(UrlApi, [RelativePath = "api/catalogo/medidas"])),
    Tabla = Table.FromRecords(Fuente, {"clave", "nombre", "descripcion", "hecho", "unidad"}, MissingField.UseNull)
in
    Tabla

// ---------------------------------------------------------------- CatalogoNiveles
// Un renglon por nivel (lo que se puede usar en "dimensiones" y "filtros"), con su dimension y los hechos en que aplica.
let
    Fuente = Json.Document(Web.Contents(UrlApi, [RelativePath = "api/catalogo/dimensiones"])),
    Dimensiones = Table.FromRecords(Fuente, {"clave", "nombre", "descripcion", "niveles", "hechos"}, MissingField.UseNull),
    PorNivel = Table.ExpandListColumn(Dimensiones, "niveles"),
    Niveles = Table.ExpandRecordColumn(PorNivel, "niveles", {"clave", "nombre", "tipoValor"}, {"nivel", "nombreNivel", "tipoValor"}),
    Hechos = Table.TransformColumns(Niveles, {{"hechos", each Text.Combine(_, ", "), type text}}),
    Renombrado = Table.RenameColumns(Hechos, {{"clave", "dimension"}, {"nombre", "nombreDimension"}})
in
    Renombrado

// ---------------------------------------------------------------- ListaNiveles y ListaValores (listas para los parametros)
// ListaNiveles:  = CatalogoNiveles[nivel]
// ListaValores:  = List.Combine({CatalogoMedidas[clave], CatalogoIndicadores[clave]})
