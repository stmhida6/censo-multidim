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
