// UrlApi: direccion base de la API, terminada en "/".
// Crear en Power Query: Inicio > Administrar parametros > Nuevo parametro, nombre "UrlApi", tipo Texto, valor actual
// "http://localhost:5000/" (la API de docker-compose). Para usar el despliegue en Azure basta cambiar este valor.
// Equivale a esta consulta:
"http://localhost:5000/" meta [IsParameterQuery = true, Type = "Text", IsParameterQueryRequired = true]
