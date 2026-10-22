let
    Fuente = Json.Document(Web.Contents(UrlApi, [RelativePath = "api/catalogo/dimensiones"])),
    Dimensiones = Table.FromRecords(Fuente, {"clave", "nombre", "descripcion", "niveles", "hechos"}, MissingField.UseNull),
    PorNivel = Table.ExpandListColumn(Dimensiones, "niveles"),
    Niveles = Table.ExpandRecordColumn(PorNivel, "niveles", {"clave", "nombre", "tipoValor"}, {"nivel", "nombreNivel", "tipoValor"}),
    Hechos = Table.TransformColumns(Niveles, {{"hechos", each Text.Combine(_, ", "), type text}}),
    Renombrado = Table.RenameColumns(Hechos, {{"clave", "dimension"}, {"nombre", "nombreDimension"}})
in
    Renombrado
