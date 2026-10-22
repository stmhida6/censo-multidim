namespace Censo.Pruebas.BaseDatos.Ayudantes;

/// <summary>
/// Valores de referencia obtenidos de forma independiente de la carga: conteos de los archivos .sav del INE
/// (etl/r/01-validacion-integridad.R), del diccionario de variables (etl/jsonl) y de las verificaciones de etl/r.
/// </summary>
public static class ValoresEsperados
{
    public const long Viviendas = 3_943_431;
    public const long Hogares = 3_275_931;
    public const long Personas = 14_901_286;
    public const long Emigrantes = 242_203;

    public const long PersonasSinHogar = 43_752;
    public const long ViviendasSinHogar = 763_836;
    public const int LlavesForaneas = 78;
    public const int RestriccionesUnicas = 42;

    public static readonly IReadOnlyDictionary<string, long> FilasPorHecho = new Dictionary<string, long>
    {
        ["CensoVivienda"] = Viviendas,
        ["CensoHogar"] = Hogares,
        ["CensoPoblacion"] = Personas,
        ["CensoMigracion"] = Emigrantes,
    };

    public static readonly IReadOnlyDictionary<string, long> MiembrosPorDimension = new Dictionary<string, long>
    {
        ["ActividadNoTrabajo"] = 9, ["ActividadSemana"] = 7, ["CategoriaOcupacional"] = 8, ["CausaNoAsistencia"] = 18,
        ["CombustibleCocina"] = 7, ["ComunidadLinguistica"] = 22, ["CondicionActividad"] = 5, ["CondicionDificultad"] = 3, ["CondicionVivienda"] = 4,
        ["Departamento"] = 22, ["DesagueAguasGrises"] = 2, ["Edad"] = 125, ["EliminacionBasura"] = 8,
        ["EstadoConyugal"] = 7, ["FuenteAgua"] = 10, ["GradoDificultad"] = 5, ["Idioma"] = 29,
        ["LugarPoblado"] = 20_254, ["MaterialPared"] = 11, ["MaterialPiso"] = 8, ["MaterialTecho"] = 8,
        ["Municipio"] = 362, ["NivelGrado"] = 23, ["Ocupacion"] = 44, ["Pais"] = 60,
        ["Parentesco"] = 15, ["Pueblo"] = 6, ["RamaActividad"] = 90, ["RespuestaSiNo"] = 3,
        ["Sexo"] = 2, ["SexoResponsable"] = 4, ["TenenciaVivienda"] = 6, ["TipoAlumbrado"] = 5,
        ["TipoEstablecimiento"] = 4, ["TipoHogar"] = 5, ["TipoLugar"] = 3, ["TipoResidencia2013"] = 4, ["TipoServicioSanitario"] = 5,
        ["TipoVivienda"] = 9, ["UsoServicioSanitario"] = 2,
    };

    public static IEnumerable<string> Dimensiones => MiembrosPorDimension.Keys;

    public static IEnumerable<string> Hechos => FilasPorHecho.Keys;

    public static string Mayuscula(string esquema) => char.ToUpperInvariant(esquema[0]) + esquema[1..];
}
