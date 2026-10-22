// ConsultaLibre: la pagina que demuestra la propuesta de la tesis. La combinacion de variables no esta fijada en el
// tablero: se elige al momento con parametros y se envia a la API como una solicitud nueva.
//
// Parametros (Inicio > Administrar parametros > Nuevo parametro):
//   Valor        Texto, requerido. Clave de una medida o un indicador (valores sugeridos: consulta ListaValores).
//   EsIndicador  Verdadero/Falso, requerido. true si Valor es un indicador.
//   Dimension1   Texto, requerido. Nivel por el que se agrupa (valores sugeridos: consulta ListaNiveles).
//   Dimension2   Texto, opcional (desmarcar "Requerido"). Segundo nivel; vacio si no se usa.
//   FiltroNivel  Texto, opcional. Nivel por el que se filtra; vacio si no se filtra.
//   FiltroValor  Texto, opcional. Codigo (o texto) del miembro; se envia como numero si es numerico.
//
// Para cambiar la consulta: Inicio > Transformar datos > Editar parametros, elegir los valores y Aplicar cambios.
// Las columnas de salida tienen siempre el mismo nombre (Categoria 1, Categoria 2, Valor, ...) para que las
// visualizaciones no se rompan al cambiar los niveles.
let
    Vacio = (texto) => texto = null or Text.Trim(texto) = "",
    Dimensiones = List.Select({Dimension1, Dimension2}, each not Vacio(_)),
    Filtros =
        if Vacio(FiltroNivel) then {}
        else {[nivel = FiltroNivel, operador = "Igual",
               valores = {try Number.From(FiltroValor) otherwise FiltroValor}]},
    Solicitud = [
        medidas = if EsIndicador then {} else {Valor},
        indicadores = if EsIndicador then {Valor} else {},
        dimensiones = Dimensiones,
        filtros = Filtros,
        limite = 10000],
    Resultado = ConsultarCenso(Solicitud),

    // Nombres fijos: cada columna de la API se renombra segun su papel en la solicitud.
    Nombres = List.Select({
        {if List.Count(Dimensiones) > 0 then Dimensiones{0} else null, "Categoria 1"},
        {if List.Count(Dimensiones) > 0 then Dimensiones{0} & "_codigo" else null, "Codigo 1"},
        {if List.Count(Dimensiones) > 1 then Dimensiones{1} else null, "Categoria 2"},
        {if List.Count(Dimensiones) > 1 then Dimensiones{1} & "_codigo" else null, "Codigo 2"},
        {Valor, "Valor"},
        {Valor & "_numerador", "Numerador"},
        {Valor & "_denominador", "Denominador"}}, each _{0} <> null),
    Renombrado = Table.RenameColumns(Resultado, Nombres, MissingField.Ignore),
    Fijo = Table.SelectColumns(Renombrado,
        {"Categoria 1", "Codigo 1", "Categoria 2", "Codigo 2", "Valor", "Numerador", "Denominador"}, MissingField.UseNull),
    Tipado = Table.TransformColumnTypes(Fijo, {
        {"Categoria 1", type text}, {"Codigo 1", Int64.Type}, {"Categoria 2", type text}, {"Codigo 2", Int64.Type},
        {"Valor", type number}, {"Numerador", Int64.Type}, {"Denominador", Int64.Type}}),
    ConClave = Table.AddColumn(Tipado, "Clave", each Valor, type text),
    ConDescripcion = Table.AddColumn(ConClave, "Solicitud",
        each Text.FromBinary(Json.FromValue(Solicitud)), type text)
in
    ConDescripcion
