using Censo.Dominio.Catalogo;
using Censo.Dominio.Contratos;

namespace Censo.Aplicacion.Catalogo;

/// <summary>
/// Catalogo centralizado del Censo 2018: define una sola vez que se puede consultar y con que reglas. Se construye al
/// iniciar y es inmutable; si una clave se repite, el arranque falla en lugar de dar resultados ambiguos.
/// </summary>
public sealed class CatalogoCenso : ICatalogo
{
    private readonly Dictionary<string, Hecho> _hechos;
    private readonly Dictionary<string, Medida> _medidas;
    private readonly Dictionary<string, Indicador> _indicadores;
    private readonly Dictionary<string, (Dimension, NivelDimension)> _niveles;

    public CatalogoCenso()
    {
        Hechos = HechosCatalogo.Crear();
        Dimensiones = DimensionesCatalogo.Crear();
        Medidas = MedidasCatalogo.Crear();
        Indicadores = IndicadoresCatalogo.Crear();

        _hechos = Indexar(Hechos, h => h.Clave, "hecho");
        _medidas = Indexar(Medidas, m => m.Clave, "medida");
        _indicadores = Indexar(Indicadores, i => i.Clave, "indicador");
        _niveles = Indexar(Dimensiones.SelectMany(d => d.Niveles.Select(n => (Dimension: d, Nivel: n))), x => x.Nivel.Clave, "nivel")
            .ToDictionary(p => p.Key, p => p.Value);

        var repetidas = _medidas.Keys.Concat(_indicadores.Keys).Concat(_niveles.Keys)
            .GroupBy(k => k, StringComparer.OrdinalIgnoreCase).Where(g => g.Count() > 1).Select(g => g.Key).ToList();
        if (repetidas.Count > 0)
            throw new InvalidOperationException($"Claves repetidas entre medidas, indicadores y niveles: {string.Join(", ", repetidas)}.");
    }

    public IReadOnlyList<Hecho> Hechos { get; }

    public IReadOnlyList<Dimension> Dimensiones { get; }

    public IReadOnlyList<Medida> Medidas { get; }

    public IReadOnlyList<Indicador> Indicadores { get; }

    public Hecho? BuscarHecho(string clave) => _hechos.GetValueOrDefault(clave);

    public Medida? BuscarMedida(string clave) => _medidas.GetValueOrDefault(clave);

    public Indicador? BuscarIndicador(string clave) => _indicadores.GetValueOrDefault(clave);

    public (Dimension Dimension, NivelDimension Nivel)? BuscarNivel(string clave) =>
        _niveles.TryGetValue(clave, out var encontrado) ? encontrado : null;

    private static Dictionary<string, T> Indexar<T>(IEnumerable<T> elementos, Func<T, string> clave, string tipo)
    {
        var indice = new Dictionary<string, T>(StringComparer.Ordinal);
        foreach (var elemento in elementos)
        {
            if (!indice.TryAdd(clave(elemento), elemento))
                throw new InvalidOperationException($"El catalogo repite la clave de {tipo} '{clave(elemento)}'.");
        }

        return indice;
    }
}
