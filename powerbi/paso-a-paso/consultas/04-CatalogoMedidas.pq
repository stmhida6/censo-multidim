let
    Fuente = Json.Document(Web.Contents(UrlApi, [RelativePath = "api/catalogo/medidas"])),
    Tabla = Table.FromRecords(Fuente, {"clave", "nombre", "descripcion", "hecho", "unidad"}, MissingField.UseNull)
in
    Tabla
