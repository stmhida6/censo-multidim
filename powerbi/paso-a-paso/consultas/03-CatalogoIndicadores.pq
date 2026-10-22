let
    Fuente = Json.Document(Web.Contents(UrlApi, [RelativePath = "api/catalogo/indicadores"])),
    Tabla = Table.FromRecords(Fuente,
        {"clave", "nombre", "descripcion", "hecho", "formula", "fuente", "unidad", "multiplicador", "numerador", "denominador"},
        MissingField.UseNull),
    Tipos = Table.TransformColumnTypes(Tabla, {{"multiplicador", type number}})
in
    Tipos
