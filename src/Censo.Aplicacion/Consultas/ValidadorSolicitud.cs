using System.Text.Json;
using Censo.Dominio.Catalogo;
using Censo.Dominio.Consultas;
using Censo.Dominio.Contratos;

namespace Censo.Aplicacion.Consultas;

/// <summary>
/// Etapa de validacion de una consulta dinamica (tesis 2.4.5): comprueba que cada elemento de la solicitud exista en el
/// catalogo, que sea compatible con el hecho consultado y que los valores de los filtros tengan el tipo y el tamano
/// esperados. Si algo no cumple, no se construye ni se ejecuta nada.
/// </summary>
public sealed class ValidadorSolicitud
{
    public const int MaxDimensiones = 6;
    public const int MaxMedidasEIndicadores = 12;
    public const int MaxFiltros = 20;
    public const int MaxValoresPorFiltro = 500;
    public const int MaxLongitudTexto = 100;
    public const int LimiteDefecto = 10_000;
    public const int LimiteMaximo = 100_000;

    private readonly ICatalogo _catalogo;

    public ValidadorSolicitud(ICatalogo catalogo) => _catalogo = catalogo;

    /// <exception cref="SolicitudInvalidaException">La solicitud no cumple las reglas del catalogo.</exception>
    public PlanConsulta Validar(SolicitudConsulta? solicitud)
    {
        if (solicitud is null)
            throw new SolicitudInvalidaException(new[] { new ErrorValidacion("solicitud", "Debe enviar una solicitud.") });

        var errores = new List<ErrorValidacion>();
        var claveMedidas = solicitud.Medidas ?? Array.Empty<string>();
        var claveIndicadores = solicitud.Indicadores ?? Array.Empty<string>();
        var claveNiveles = solicitud.Dimensiones ?? Array.Empty<string>();
        var filtros = solicitud.Filtros ?? Array.Empty<FiltroSolicitud>();

        // Limites de tamano antes de recorrer nada: una lista enorme se rechaza sin procesarla.
        if (claveMedidas.Count + claveIndicadores.Count == 0)
            errores.Add(new("medidas", "Debe indicar al menos una medida o un indicador."));
        if (claveMedidas.Count + claveIndicadores.Count > MaxMedidasEIndicadores)
            errores.Add(new("medidas", $"Puede pedir como maximo {MaxMedidasEIndicadores} medidas e indicadores por consulta."));
        if (claveNiveles.Count > MaxDimensiones)
            errores.Add(new("dimensiones", $"Puede agrupar por {MaxDimensiones} niveles como maximo."));
        if (filtros.Count > MaxFiltros)
            errores.Add(new("filtros", $"Puede aplicar {MaxFiltros} filtros como maximo."));
        if (errores.Count > 0)
            throw new SolicitudInvalidaException(errores);

        var (medidas, indicadores) = ResolverMedidasEIndicadores(claveMedidas, claveIndicadores, errores);
        var hechoClave = DeterminarHecho(medidas, indicadores, errores);
        var hecho = hechoClave is null ? null : _catalogo.BuscarHecho(hechoClave);

        var agrupaciones = new List<AgrupacionPlan>();
        var filtrosPlan = new List<FiltroPlan>();
        if (hecho is not null)
        {
            agrupaciones = ResolverDimensiones(claveNiveles, hecho, errores);
            filtrosPlan = ResolverFiltros(filtros, hecho, errores);
        }

        var limite = solicitud.Limite ?? LimiteDefecto;
        if (limite < 1 || limite > LimiteMaximo)
            errores.Add(new("limite", $"El limite debe estar entre 1 y {LimiteMaximo:N0} filas."));

        if (errores.Count > 0 || hecho is null)
            throw new SolicitudInvalidaException(errores);

        var consultadas = new List<Medida>(medidas);
        foreach (var indicador in indicadores)
        {
            foreach (var clave in new[] { indicador.NumeradorClave, indicador.DenominadorClave })
            {
                var medida = _catalogo.BuscarMedida(clave)
                    ?? throw new InvalidOperationException($"El indicador '{indicador.Clave}' usa la medida '{clave}', que no existe en el catalogo.");
                if (consultadas.All(m => m.Clave != medida.Clave))
                    consultadas.Add(medida);
            }
        }

        return new PlanConsulta(hecho, agrupaciones, medidas, consultadas, indicadores, filtrosPlan, limite, solicitud.IncluirComponentes ?? true);
    }

    private (List<Medida> Medidas, List<Indicador> Indicadores) ResolverMedidasEIndicadores(
        IReadOnlyList<string> claveMedidas, IReadOnlyList<string> claveIndicadores, List<ErrorValidacion> errores)
    {
        var medidas = new List<Medida>();
        var indicadores = new List<Indicador>();

        for (var i = 0; i < claveMedidas.Count; i++)
        {
            var medida = claveMedidas[i] is { } clave ? _catalogo.BuscarMedida(clave.Trim()) : null;
            if (medida is null)
                errores.Add(new($"medidas[{i}]", $"La medida '{Segura(claveMedidas[i])}' no existe en el catalogo."));
            else if (medidas.Any(m => m.Clave == medida.Clave))
                errores.Add(new($"medidas[{i}]", $"La medida '{medida.Clave}' esta repetida."));
            else
                medidas.Add(medida);
        }

        for (var i = 0; i < claveIndicadores.Count; i++)
        {
            var indicador = claveIndicadores[i] is { } clave ? _catalogo.BuscarIndicador(clave.Trim()) : null;
            if (indicador is null)
                errores.Add(new($"indicadores[{i}]", $"El indicador '{Segura(claveIndicadores[i])}' no existe en el catalogo."));
            else if (indicadores.Any(x => x.Clave == indicador.Clave))
                errores.Add(new($"indicadores[{i}]", $"El indicador '{indicador.Clave}' esta repetido."));
            else
                indicadores.Add(indicador);
        }

        return (medidas, indicadores);
    }

    private string? DeterminarHecho(List<Medida> medidas, List<Indicador> indicadores, List<ErrorValidacion> errores)
    {
        var hechos = medidas.Select(m => m.HechoClave).Concat(indicadores.Select(i => i.HechoClave)).Distinct().ToList();
        if (hechos.Count > 1)
        {
            errores.Add(new("medidas", "Las medidas e indicadores de una consulta deben pertenecer al mismo hecho; los pedidos son de: "
                + string.Join(", ", hechos) + "."));
            return null;
        }

        return hechos.Count == 1 ? hechos[0] : null;
    }

    private List<AgrupacionPlan> ResolverDimensiones(IReadOnlyList<string> claveNiveles, Hecho hecho, List<ErrorValidacion> errores)
    {
        var agrupaciones = new List<AgrupacionPlan>();
        for (var i = 0; i < claveNiveles.Count; i++)
        {
            var campo = $"dimensiones[{i}]";
            var encontrado = claveNiveles[i] is { } clave ? _catalogo.BuscarNivel(clave.Trim()) : null;
            if (encontrado is null)
            {
                errores.Add(new(campo, $"El nivel '{Segura(claveNiveles[i])}' no existe en el catalogo."));
                continue;
            }

            var (dimension, nivel) = encontrado.Value;
            if (dimension.VinculoCon(hecho.Clave) is null)
                errores.Add(new(campo, $"El nivel '{nivel.Clave}' no esta disponible para el hecho '{hecho.Clave}'."));
            else if (agrupaciones.Any(a => a.Nivel.Clave == nivel.Clave))
                errores.Add(new(campo, $"El nivel '{nivel.Clave}' esta repetido."));
            else
                agrupaciones.Add(new AgrupacionPlan(dimension, nivel));
        }

        return agrupaciones;
    }

    private List<FiltroPlan> ResolverFiltros(IReadOnlyList<FiltroSolicitud> filtros, Hecho hecho, List<ErrorValidacion> errores)
    {
        var resueltos = new List<FiltroPlan>();
        for (var i = 0; i < filtros.Count; i++)
        {
            var campo = $"filtros[{i}]";
            var filtro = filtros[i];
            if (filtro is null)
            {
                errores.Add(new(campo, "El filtro esta vacio."));
                continue;
            }

            var encontrado = filtro.Nivel is { } clave ? _catalogo.BuscarNivel(clave.Trim()) : null;
            if (encontrado is null)
            {
                errores.Add(new($"{campo}.nivel", $"El nivel '{Segura(filtro.Nivel)}' no existe en el catalogo."));
                continue;
            }

            var (dimension, nivel) = encontrado.Value;
            if (dimension.VinculoCon(hecho.Clave) is null)
            {
                errores.Add(new($"{campo}.nivel", $"El nivel '{nivel.Clave}' no esta disponible para el hecho '{hecho.Clave}'."));
                continue;
            }

            if (!TryLeerOperador(filtro.Operador, out var operador))
            {
                errores.Add(new($"{campo}.operador", $"El operador '{Segura(filtro.Operador)}' no es valido. Use: {string.Join(", ", Enum.GetNames<OperadorFiltro>())}."));
                continue;
            }

            var valores = NormalizarValores(filtro.Valores, nivel, operador, campo, errores);
            if (valores is not null)
                resueltos.Add(new FiltroPlan(dimension, nivel, operador, valores));
        }

        return resueltos;
    }

    private static List<object>? NormalizarValores(
        IReadOnlyList<object?>? crudos, NivelDimension nivel, OperadorFiltro operador, string campo, List<ErrorValidacion> errores)
    {
        var campoValores = $"{campo}.valores";
        if (crudos is null || crudos.Count == 0)
        {
            errores.Add(new(campoValores, "Debe indicar al menos un valor."));
            return null;
        }

        var (minimo, maximo) = operador switch
        {
            OperadorFiltro.Entre => (2, 2),
            OperadorFiltro.En or OperadorFiltro.NoEn => (1, MaxValoresPorFiltro),
            _ => (1, 1),
        };
        if (crudos.Count < minimo || crudos.Count > maximo)
        {
            errores.Add(new(campoValores, minimo == maximo
                ? $"El operador {operador} requiere exactamente {minimo} valor(es)."
                : $"El operador {operador} admite entre {minimo} y {maximo} valores."));
            return null;
        }

        if (nivel.TipoValor == TipoValor.Texto && operador is OperadorFiltro.Entre or OperadorFiltro.MayorOIgual or OperadorFiltro.MenorOIgual)
        {
            errores.Add(new($"{campo}.operador", $"El nivel '{nivel.Clave}' se filtra por texto y no admite el operador {operador}."));
            return null;
        }

        var normalizados = new List<object>();
        for (var i = 0; i < crudos.Count; i++)
        {
            object? valor = nivel.TipoValor == TipoValor.Entero ? LeerEntero(crudos[i]) : LeerTexto(crudos[i]);
            if (valor is null)
            {
                errores.Add(new($"{campoValores}[{i}]", nivel.TipoValor == TipoValor.Entero
                    ? $"El nivel '{nivel.Clave}' se filtra con numeros enteros."
                    : $"El nivel '{nivel.Clave}' se filtra con texto de 1 a {MaxLongitudTexto} caracteres, sin caracteres de control."));
                return null;
            }

            normalizados.Add(valor);
        }

        if (operador == OperadorFiltro.Entre && (long)normalizados[0] > (long)normalizados[1])
        {
            errores.Add(new(campoValores, "En el operador Entre, el primer valor no puede ser mayor que el segundo."));
            return null;
        }

        return normalizados;
    }

    private static long? LeerEntero(object? valor) => valor switch
    {
        long l => l,
        int i => i,
        short s => s,
        byte b => b,
        JsonElement { ValueKind: JsonValueKind.Number } e when e.TryGetInt64(out var l) => l,
        _ => null,
    };

    private static string? LeerTexto(object? valor)
    {
        var texto = valor switch
        {
            string s => s,
            JsonElement { ValueKind: JsonValueKind.String } e => e.GetString(),
            _ => null,
        };
        return texto is { Length: > 0 and <= MaxLongitudTexto } && !texto.Any(char.IsControl) ? texto : null;
    }

    private static bool TryLeerOperador(string? texto, out OperadorFiltro operador)
    {
        operador = default;
        var limpio = texto?.Trim();
        return limpio is { Length: > 0 and <= 20 }
            && !char.IsDigit(limpio[0])
            && Enum.TryParse(limpio, ignoreCase: true, out operador)
            && Enum.IsDefined(operador);
    }

    /// <summary>Texto de usuario apto para repetirlo en un mensaje: recortado y sin caracteres de control.</summary>
    private static string Segura(string? texto)
    {
        if (texto is null)
            return string.Empty;
        var limpio = new string(texto.Where(c => !char.IsControl(c)).ToArray());
        return limpio.Length <= 40 ? limpio : limpio[..40] + "...";
    }
}
