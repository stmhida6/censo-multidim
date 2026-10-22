namespace Censo.Dominio.Catalogo;

/// <summary>Tipo de los valores con los que se puede filtrar un nivel de una dimension.</summary>
public enum TipoValor
{
    Entero,
    Texto,
}

/// <summary>Operadores de comparacion permitidos en un filtro.</summary>
public enum OperadorFiltro
{
    Igual,
    Distinto,
    En,
    NoEn,
    Entre,
    MayorOIgual,
    MenorOIgual,
}

/// <summary>Tabla de hechos sobre la que se agregan las medidas (una persona, un hogar, una vivienda o un emigrante por fila).</summary>
public sealed record Hecho(string Clave, string Nombre, string Descripcion, string Tabla, string Grano);

/// <summary>
/// Union (LEFT JOIN) que lleva del hecho a la tabla de una dimension. La condicion se escribe con tres marcadores:
/// {f} es el hecho, {p} el paso anterior de la ruta y {a} la tabla de este paso. Son constantes del catalogo, nunca
/// texto de una solicitud. Los pasos con el mismo Id se unen una sola vez en una consulta.
/// </summary>
public sealed record PasoUnion(string Id, string Tabla, string Condicion);

/// <summary>Forma en que un hecho llega a una dimension: la ruta de uniones desde el hecho hasta la tabla base de la dimension.</summary>
/// <param name="HechoClave">Hecho que puede consultarse por esta dimension.</param>
/// <param name="Pasos">Uniones desde el hecho; la ultima es la tabla base de la dimension. Vacia si la dimension es una columna del propio hecho.</param>
public sealed record VinculoDimension(string HechoClave, IReadOnlyList<PasoUnion> Pasos);

/// <summary>
/// Nivel de una dimension por el que se puede agrupar o filtrar (por ejemplo departamento, municipio o grupo quinquenal).
/// Las expresiones usan el marcador {a} para la tabla del paso que las contiene.
/// </summary>
/// <param name="Clave">Identificador publico del nivel, unico en todo el catalogo.</param>
/// <param name="Paso">0 es la tabla base de la dimension; 1 en adelante, los pasos de su jerarquia.</param>
/// <param name="ExpresionCodigo">Codigo del INE del miembro (permite filtrar por codigo); nulo si el nivel solo tiene etiqueta.</param>
/// <param name="ExpresionEtiqueta">Nombre del miembro.</param>
/// <param name="TipoValor">Tipo de los valores de filtro: el del codigo si existe; si no, texto sobre la etiqueta.</param>
/// <param name="ExpresionOrden">Orden de presentacion cuando no es el del codigo o la etiqueta.</param>
public sealed record NivelDimension(
    string Clave,
    string Nombre,
    int Paso,
    string? ExpresionCodigo,
    string ExpresionEtiqueta,
    TipoValor TipoValor,
    string? ExpresionOrden = null);

/// <summary>Dimension de analisis con sus niveles y las formas en que cada hecho llega a ella.</summary>
public sealed record Dimension(
    string Clave,
    string Nombre,
    string Descripcion,
    IReadOnlyList<NivelDimension> Niveles,
    IReadOnlyList<PasoUnion> PasosJerarquia,
    IReadOnlyList<VinculoDimension> Vinculos)
{
    public VinculoDimension? VinculoCon(string hechoClave) => Vinculos.FirstOrDefault(v => v.HechoClave == hechoClave);
}

/// <summary>Condicion fija que restringe las filas que cuenta o suma una medida (por ejemplo, sexo igual a 1).</summary>
public sealed record CondicionMedida(string NivelClave, OperadorFiltro Operador, IReadOnlyList<object> Valores);

/// <summary>Valor aditivo sobre un hecho: un conteo de filas o la suma de una columna, con condiciones opcionales.</summary>
/// <param name="ExpresionValor">Columna del hecho que se suma ({f}.Columna); nula para contar filas.</param>
public sealed record Medida(
    string Clave,
    string Nombre,
    string Descripcion,
    string HechoClave,
    string? ExpresionValor,
    IReadOnlyList<CondicionMedida> Condiciones,
    string Unidad);

/// <summary>
/// Razon entre dos medidas del mismo hecho, con la formula oficial. Se calcula con el numerador y el denominador ya
/// agregados, de modo que es correcta en cualquier nivel de agregacion (tesis 2.2.7).
/// </summary>
public sealed record Indicador(
    string Clave,
    string Nombre,
    string Descripcion,
    string HechoClave,
    string NumeradorClave,
    string DenominadorClave,
    decimal Multiplicador,
    string Formula,
    string Fuente,
    string Unidad);
