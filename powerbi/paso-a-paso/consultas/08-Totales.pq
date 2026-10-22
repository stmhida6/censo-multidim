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
