let
    Resultado = ConsultarCenso([medidas = {"personas"}, dimensiones = {"departamento", "grupoQuinquenal", "sexo"}]),
    ConOrden = Table.AddColumn(Resultado, "OrdenGrupo",
        each try Number.From(Text.BeforeDelimiter([grupoQuinquenal], "-")) otherwise 100, Int64.Type)
in
    ConOrden
