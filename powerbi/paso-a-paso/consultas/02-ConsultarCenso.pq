// ConsultarCenso: envia una solicitud a POST /api/consultas y devuelve el resultado como tabla con sus tipos.
// Es la unica pieza que habla con la API: todas las consultas del tablero la usan, de modo que Power BI solo
// presenta opciones, envia solicitudes y representa resultados; las reglas de calculo viven en la API (tesis 2.7.1).
//
// Uso:  ConsultarCenso([indicadores = {"tasaGlobalParticipacion"}, dimensiones = {"departamento"}])
//       ConsultarCenso([medidas = {"personas"}, filtros = {[nivel = "sexo", operador = "Igual", valores = {2}]}])
//
// Crear en Power Query: Inicio > Nueva fuente > Consulta en blanco > Editor avanzado, pegar este texto y nombrar la
// consulta "ConsultarCenso". Requiere el parametro UrlApi (ver 00-UrlApi.pq).
let
    ConsultarCenso = (solicitud as record) as table =>
    let
        // RelativePath mantiene fija la URL base: es lo que permite actualizar el informe en el servicio de Power BI.
        Datos = Web.Contents(UrlApi, [
            RelativePath = "api/consultas",
            Headers = [#"Content-Type" = "application/json"],
            Content = Json.FromValue(solicitud),
            ManualStatusHandling = {400, 413, 415, 429, 500, 503, 504},
            Timeout = #duration(0, 0, 2, 0)
        ]),
        Estado = Value.Metadata(Datos)[Response.Status],
        Cuerpo = Json.Document(Datos),

        // Si la API rechaza la solicitud (por ejemplo, una clave que no esta en el catalogo), el error muestra su
        // titulo y la lista de problemas que devolvio.
        Verificado =
            if Estado = 200 then Cuerpo
            else error Error.Record(
                "La API rechazo la consulta (HTTP " & Text.From(Estado) & ")",
                if Record.HasFields(Cuerpo, "title") then Cuerpo[title] else "",
                if Record.HasFields(Cuerpo, "errores") then Cuerpo[errores] else null),

        Claves = List.Transform(Verificado[columnas], each [clave]),
        Tabla = Table.FromRecords(Verificado[filas], Claves, MissingField.UseNull),
        Tipos = List.Transform(Verificado[columnas], each {[clave],
            if [tipo] = "entero" then Int64.Type
            else if [tipo] = "decimal" then type number
            else type text}),
        Resultado = Table.TransformColumnTypes(Tabla, Tipos)
    in
        Resultado
in
    ConsultarCenso
