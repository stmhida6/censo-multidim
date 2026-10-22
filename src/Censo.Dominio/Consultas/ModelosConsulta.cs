namespace Censo.Dominio.Consultas;

/// <summary>Filtro de una solicitud: un nivel de dimension, un operador y sus valores.</summary>
/// <param name="Nivel">Clave de un nivel del catalogo.</param>
/// <param name="Operador">Nombre de un <see cref="Catalogo.OperadorFiltro"/> (sin distinguir mayusculas).</param>
/// <param name="Valores">Numeros enteros o textos, segun el tipo del nivel.</param>
public sealed record FiltroSolicitud(string Nivel, string Operador, IReadOnlyList<object?> Valores);

/// <summary>
/// Consulta multidimensional: que medir (medidas e indicadores), por que agrupar (niveles de dimension) y con
/// que filtros. Todo se refiere a claves del catalogo; nada de esto llega al SQL como texto.
/// </summary>
public sealed record SolicitudConsulta(
    IReadOnlyList<string>? Medidas = null,
    IReadOnlyList<string>? Indicadores = null,
    IReadOnlyList<string>? Dimensiones = null,
    IReadOnlyList<FiltroSolicitud>? Filtros = null,
    int? Limite = null,
    bool? IncluirComponentes = null);

/// <summary>Descripcion de una columna del resultado.</summary>
/// <param name="Rol">dimension, dimensionCodigo, medida, indicador, numerador o denominador.</param>
public sealed record ColumnaResultado(string Clave, string Nombre, string Rol, string Tipo);

/// <summary>Resultado agregado de una consulta.</summary>
public sealed record ResultadoConsulta(
    string Hecho,
    IReadOnlyList<ColumnaResultado> Columnas,
    IReadOnlyList<IReadOnlyDictionary<string, object?>> Filas,
    bool Truncado,
    long DuracionMs);

/// <summary>Instruccion SQL ya construida con sus parametros.</summary>
public sealed record ConsultaSql(string Texto, IReadOnlyDictionary<string, object?> Parametros);

/// <summary>Filas devueltas por la base de datos, sin interpretar.</summary>
public sealed record TablaResultado(IReadOnlyList<string> Columnas, IReadOnlyList<object?[]> Filas);

/// <summary>Un problema de una solicitud, referido al campo que lo causa.</summary>
public sealed record ErrorValidacion(string Campo, string Mensaje);

/// <summary>La solicitud no cumple las reglas del catalogo; no se ejecuto nada.</summary>
public sealed class SolicitudInvalidaException : Exception
{
    public SolicitudInvalidaException(IReadOnlyList<ErrorValidacion> errores)
        : base("La solicitud no es valida.")
    {
        Errores = errores;
    }

    public IReadOnlyList<ErrorValidacion> Errores { get; }
}

/// <summary>La base de datos no pudo ejecutar una consulta ya validada (por ejemplo, por tiempo de espera). El detalle queda en la excepcion interna y no se muestra al cliente.</summary>
public sealed class ConsultaFallidaException : Exception
{
    public ConsultaFallidaException(string mensaje, bool tiempoAgotado, Exception? interna = null)
        : base(mensaje, interna)
    {
        TiempoAgotado = tiempoAgotado;
    }

    public bool TiempoAgotado { get; }
}
