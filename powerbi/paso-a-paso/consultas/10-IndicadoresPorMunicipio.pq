let
    Resultado = ConsultarCenso([
        indicadores = {"tasaGlobalParticipacion", "tasaDesempleoAbierto", "tasaAlfabetismo", "indiceMasculinidad"},
        dimensiones = {"departamento", "municipio"},
        limite = 1000]),
    ConUbicacion = Table.AddColumn(Resultado, "Ubicacion",
        each [municipio] & ", " & [departamento] & ", Guatemala", type text)
in
    ConUbicacion
