let
    Resultado = ConsultarCenso([medidas = {"hogares"}, dimensiones = {"departamento", "esUrbano", "fuenteAgua"}]),
    ConArea = Table.AddColumn(Resultado, "Area", each if [esUrbano_codigo] = 1 then "Urbana" else "Rural", type text)
in
    ConArea
