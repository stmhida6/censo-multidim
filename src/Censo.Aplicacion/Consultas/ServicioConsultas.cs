using System.Diagnostics;
using Censo.Dominio.Catalogo;
using Censo.Dominio.Consultas;
using Censo.Dominio.Contratos;

namespace Censo.Aplicacion.Consultas;

/// <summary>Punto de entrada de la capa de aplicacion para consultar los datos del censo.</summary>
public interface IServicioConsultas
{
    /// <exception cref="SolicitudInvalidaException">La solicitud no cumple las reglas del catalogo.</exception>
    Task<ResultadoConsulta> ConsultarAsync(SolicitudConsulta solicitud, CancellationToken cancelacion = default);
}

/// <summary>
/// Orquesta las cuatro etapas de una consulta dinamica (tesis 2.4.5): recibe la solicitud, la valida contra el catalogo,
/// construye el SQL con elementos reconocidos y parametros, lo ejecuta y devuelve los resultados agregados. Los
/// indicadores se calculan aqui con el numerador y el denominador ya agregados.
/// </summary>
public sealed class ServicioConsultas : IServicioConsultas
{
    private const int DecimalesIndicador = 6;

    private readonly ValidadorSolicitud _validador;
    private readonly ConstructorConsultaSql _constructor;
    private readonly IRepositorioConsultas _repositorio;

    public ServicioConsultas(ValidadorSolicitud validador, ConstructorConsultaSql constructor, IRepositorioConsultas repositorio)
    {
        _validador = validador;
        _constructor = constructor;
        _repositorio = repositorio;
    }

    public async Task<ResultadoConsulta> ConsultarAsync(SolicitudConsulta solicitud, CancellationToken cancelacion = default)
    {
        var plan = _validador.Validar(solicitud);
        var construida = _constructor.Construir(plan);

        var reloj = Stopwatch.StartNew();
        var tabla = await _repositorio.EjecutarAsync(construida.Sql, cancelacion);
        reloj.Stop();

        return Ensamblar(plan, construida, tabla, reloj.ElapsedMilliseconds);
    }

    private static ResultadoConsulta Ensamblar(PlanConsulta plan, ConsultaConstruida construida, TablaResultado tabla, long duracionMs)
    {
        var posicion = tabla.Columnas.Select((alias, i) => (alias, i)).ToDictionary(x => x.alias, x => x.i);
        var truncado = tabla.Filas.Count > plan.Limite;
        var filasOrigen = truncado ? tabla.Filas.Take(plan.Limite).ToList() : tabla.Filas;

        var columnas = new List<ColumnaResultado>();
        foreach (var c in construida.Columnas.Where(c => c.Rol != "medida"))
            columnas.Add(new ColumnaResultado(c.Alias, c.Nombre, c.Rol, c.Tipo));
        foreach (var medida in plan.MedidasSolicitadas)
            columnas.Add(new ColumnaResultado(medida.Clave, medida.Nombre, "medida", "entero"));
        foreach (var indicador in plan.Indicadores)
        {
            columnas.Add(new ColumnaResultado(indicador.Clave, indicador.Nombre, "indicador", "decimal"));
            if (plan.IncluirComponentes)
            {
                columnas.Add(new ColumnaResultado($"{indicador.Clave}_numerador", $"{indicador.Nombre} (numerador)", "numerador", "entero"));
                columnas.Add(new ColumnaResultado($"{indicador.Clave}_denominador", $"{indicador.Nombre} (denominador)", "denominador", "entero"));
            }
        }

        var filas = new List<IReadOnlyDictionary<string, object?>>(filasOrigen.Count);
        foreach (var origen in filasOrigen)
        {
            var fila = new Dictionary<string, object?>();
            foreach (var c in construida.Columnas.Where(c => c.Rol != "medida"))
                fila[c.Alias] = origen[posicion[c.Alias]];
            foreach (var medida in plan.MedidasSolicitadas)
                fila[medida.Clave] = Entero(origen[posicion[medida.Clave]]);

            foreach (var indicador in plan.Indicadores)
            {
                var numerador = Entero(origen[posicion[indicador.NumeradorClave]]);
                var denominador = Entero(origen[posicion[indicador.DenominadorClave]]);
                fila[indicador.Clave] = denominador == 0
                    ? null
                    : Math.Round((decimal)numerador * indicador.Multiplicador / denominador, DecimalesIndicador);
                if (plan.IncluirComponentes)
                {
                    fila[$"{indicador.Clave}_numerador"] = numerador;
                    fila[$"{indicador.Clave}_denominador"] = denominador;
                }
            }

            filas.Add(fila);
        }

        return new ResultadoConsulta(plan.Hecho.Clave, columnas, filas, truncado, duracionMs);
    }

    /// <summary>Una suma sin filas devuelve NULL: para una medida aditiva equivale a cero.</summary>
    private static long Entero(object? valor) => valor is null or DBNull ? 0 : Convert.ToInt64(valor);
}
