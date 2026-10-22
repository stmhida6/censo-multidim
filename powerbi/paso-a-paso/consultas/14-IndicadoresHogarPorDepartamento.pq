let
    Resultado = ConsultarCenso([
        indicadores = {"tamanioPromedioHogar", "porcentajeHogaresConInternet", "porcentajeHogaresConRemesas"},
        dimensiones = {"departamento"}])
in
    Resultado
