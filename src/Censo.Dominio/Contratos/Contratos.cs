using Censo.Dominio.Catalogo;
using Censo.Dominio.Consultas;

namespace Censo.Dominio.Contratos;

/// <summary>Catalogo centralizado de hechos, dimensiones, medidas e indicadores: la unica fuente de lo que se puede consultar.</summary>
public interface ICatalogo
{
    IReadOnlyList<Hecho> Hechos { get; }

    IReadOnlyList<Dimension> Dimensiones { get; }

    IReadOnlyList<Medida> Medidas { get; }

    IReadOnlyList<Indicador> Indicadores { get; }

    Hecho? BuscarHecho(string clave);

    Medida? BuscarMedida(string clave);

    Indicador? BuscarIndicador(string clave);

    /// <summary>Busca un nivel por su clave publica y devuelve tambien la dimension que lo contiene.</summary>
    (Dimension Dimension, NivelDimension Nivel)? BuscarNivel(string clave);
}

/// <summary>Ejecuta una consulta ya construida y devuelve las filas sin interpretar.</summary>
public interface IRepositorioConsultas
{
    Task<TablaResultado> EjecutarAsync(ConsultaSql consulta, CancellationToken cancelacion = default);
}
