using Censo.Dominio.Catalogo;

namespace Censo.Aplicacion.Catalogo;

/// <summary>Definicion de los cuatro hechos del catalogo.</summary>
internal static class HechosCatalogo
{
    public static IReadOnlyList<Hecho> Crear() => new[]
    {
        new Hecho(ClavesHecho.Poblacion, "Poblacion", "Personas censadas con sus caracteristicas.", "hechos.CensoPoblacion", "una persona"),
        new Hecho(ClavesHecho.Hogar, "Hogares", "Hogares censados con las caracteristicas de su vivienda y su equipamiento.", "hechos.CensoHogar", "un hogar"),
        new Hecho(ClavesHecho.Vivienda, "Viviendas", "Viviendas censadas con sus materiales y condicion.", "hechos.CensoVivienda", "una vivienda"),
        new Hecho(ClavesHecho.Migracion, "Emigracion internacional", "Personas del hogar que se fueron a vivir a otro pais desde 2002.", "hechos.CensoMigracion", "un emigrante"),
    };
}

/// <summary>Definicion de las medidas: conteos y sumas, con las condiciones que las convierten en poblaciones de referencia.</summary>
internal static class MedidasCatalogo
{
    private const string Personas = "personas";
    private const string Hogares = "hogares";
    private const string Viviendas = "viviendas";

    public static IReadOnlyList<Medida> Crear() => new[]
    {
        // ---------- Poblacion ----------
        Conteo("personas", "Personas", "Total de personas censadas.", ClavesHecho.Poblacion, Personas),
        Conteo("hombres", "Hombres", "Personas de sexo masculino.", ClavesHecho.Poblacion, Personas, Cond("sexo", OperadorFiltro.Igual, 1)),
        Conteo("mujeres", "Mujeres", "Personas de sexo femenino.", ClavesHecho.Poblacion, Personas, Cond("sexo", OperadorFiltro.Igual, 2)),
        Conteo("poblacion15a64", "Poblacion de 15 a 64 anios", "Poblacion en edades teoricamente activas (denominador de la relacion de dependencia).", ClavesHecho.Poblacion, Personas,
            Cond("grupoAmplio", OperadorFiltro.Igual, "15-64")),
        Conteo("poblacionDependiente", "Poblacion dependiente", "Poblacion de 0 a 14 anios y de 65 anios o mas (numerador de la relacion de dependencia).", ClavesHecho.Poblacion, Personas,
            Cond("grupoAmplio", OperadorFiltro.En, "0-14", "65 y mas")),
        Conteo("pet", "Poblacion en edad de trabajar (PET)", "Personas de 15 anios o mas.", ClavesHecho.Poblacion, Personas,
            Cond("edad", OperadorFiltro.MayorOIgual, 15)),
        Conteo("pea", "Poblacion economicamente activa (PEA)", "Personas de 15 anios o mas ocupadas o desocupadas (aspirantes y cesantes).", ClavesHecho.Poblacion, Personas,
            Cond("edad", OperadorFiltro.MayorOIgual, 15), Cond("condicionActividad", OperadorFiltro.En, 1, 2, 3)),
        Conteo("ocupados", "Poblacion ocupada (PO)", "Personas de 15 anios o mas ocupadas.", ClavesHecho.Poblacion, Personas,
            Cond("edad", OperadorFiltro.MayorOIgual, 15), Cond("condicionActividad", OperadorFiltro.Igual, 1)),
        Conteo("desocupadosAbiertos", "Poblacion en desempleo abierto (PDA)", "Personas de 15 anios o mas desocupadas: aspirantes y cesantes.", ClavesHecho.Poblacion, Personas,
            Cond("edad", OperadorFiltro.MayorOIgual, 15), Cond("condicionActividad", OperadorFiltro.En, 2, 3)),
        Conteo("personas7oMas", "Personas de 7 anios o mas", "Poblacion a la que se pregunta si sabe leer y escribir.", ClavesHecho.Poblacion, Personas,
            Cond("edad", OperadorFiltro.MayorOIgual, 7)),
        Conteo("alfabetas", "Personas alfabetas de 7 anios o mas", "Personas de 7 anios o mas que saben leer y escribir en al menos un idioma.", ClavesHecho.Poblacion, Personas,
            Cond("edad", OperadorFiltro.MayorOIgual, 7), Cond("esAlfabeta", OperadorFiltro.Igual, 1)),
        Conteo("migrantesVida", "Migrantes de toda la vida", "Personas que residen en un municipio, departamento o pais distinto del de nacimiento.", ClavesHecho.Poblacion, Personas,
            Cond("esMigranteVida", OperadorFiltro.Igual, 1)),

        // ---------- Hogares ----------
        Conteo("hogares", "Hogares", "Total de hogares censados.", ClavesHecho.Hogar, Hogares),
        Suma("personasEnHogares", "Personas en hogares", "Suma de las personas de cada hogar.", ClavesHecho.Hogar, "{f}.TotalPersonas", Personas),
        Conteo("hogaresConInternet", "Hogares con internet", "Hogares con servicio de internet.", ClavesHecho.Hogar, Hogares, Cond("tieneInternet", OperadorFiltro.Igual, 1)),
        Conteo("hogaresConRemesas", "Hogares que reciben remesas", "Hogares que reciben remesas con regularidad.", ClavesHecho.Hogar, Hogares, Cond("tieneRemesas", OperadorFiltro.Igual, 1)),

        // ---------- Viviendas ----------
        Conteo("viviendas", "Viviendas", "Total de viviendas censadas.", ClavesHecho.Vivienda, Viviendas),
        Conteo("viviendasOcupadas", "Viviendas ocupadas", "Viviendas cuya condicion es ocupada.", ClavesHecho.Vivienda, Viviendas, Cond("condicionVivienda", OperadorFiltro.Igual, 1)),

        // ---------- Emigracion ----------
        Conteo("emigrantes", "Emigrantes internacionales", "Personas que se fueron a vivir a otro pais desde 2002.", ClavesHecho.Migracion, "emigrantes"),
        Conteo("emigrantesMujeres", "Emigrantes mujeres", "Emigrantes de sexo femenino.", ClavesHecho.Migracion, "emigrantes", Cond("sexo", OperadorFiltro.Igual, 2)),
    };

    private static Medida Conteo(string clave, string nombre, string descripcion, string hecho, string unidad, params CondicionMedida[] condiciones) =>
        new(clave, nombre, descripcion, hecho, null, condiciones, unidad);

    private static Medida Suma(string clave, string nombre, string descripcion, string hecho, string expresion, string unidad, params CondicionMedida[] condiciones) =>
        new(clave, nombre, descripcion, hecho, expresion, condiciones, unidad);

    private static CondicionMedida Cond(string nivel, OperadorFiltro operador, params object[] valores) => new(nivel, operador, valores);
}

/// <summary>
/// Definicion de los indicadores: razones con la formula oficial del glosario del INE. Cada uno guarda su numerador y su
/// denominador para que un cliente pueda reagregar sin recalcular.
/// </summary>
internal static class IndicadoresCatalogo
{
    private const string Glosario = "Glosario de definiciones del Censo 2018 (INE)";

    public static IReadOnlyList<Indicador> Crear() => new[]
    {
        new Indicador("indiceMasculinidad", "Indice de masculinidad", "Hombres por cada 100 mujeres.", ClavesHecho.Poblacion,
            "hombres", "mujeres", 100m, "(total de hombres / total de mujeres) * 100", Glosario, "hombres por cada 100 mujeres"),
        new Indicador("relacionDependencia", "Relacion de dependencia", "Poblacion en edades teoricamente inactivas en relacion a la poblacion en edades teoricamente activas.", ClavesHecho.Poblacion,
            "poblacionDependiente", "poblacion15a64", 100m, "((poblacion de 0 a 14 + poblacion de 65 y mas) / poblacion de 15 a 64) * 100", Glosario, "por cada 100 personas de 15 a 64 anios"),
        new Indicador("tasaGlobalParticipacion", "Tasa global de participacion", "Poblacion economicamente activa como proporcion de la poblacion en edad de trabajar.", ClavesHecho.Poblacion,
            "pea", "pet", 100m, "(PEA / PET) * 100", Glosario, "porcentaje"),
        new Indicador("tasaBrutaOcupacion", "Tasa bruta de ocupacion", "Poblacion ocupada como proporcion de la poblacion en edad de trabajar.", ClavesHecho.Poblacion,
            "ocupados", "pet", 100m, "(PO / PET) * 100", Glosario, "porcentaje"),
        new Indicador("tasaEspecificaOcupacion", "Tasa especifica de ocupacion", "Poblacion ocupada como proporcion de la poblacion economicamente activa.", ClavesHecho.Poblacion,
            "ocupados", "pea", 100m, "(PO / PEA) * 100", Glosario, "porcentaje"),
        new Indicador("tasaDesempleoAbierto", "Tasa de desempleo abierto", "Poblacion desempleada abierta como proporcion de la poblacion economicamente activa.", ClavesHecho.Poblacion,
            "desocupadosAbiertos", "pea", 100m, "(PDA / PEA) * 100", Glosario, "porcentaje"),
        new Indicador("tasaAlfabetismo", "Tasa de alfabetismo", "Personas de 7 anios o mas que saben leer y escribir, como proporcion de las personas de 7 anios o mas.", ClavesHecho.Poblacion,
            "alfabetas", "personas7oMas", 100m, "(alfabetas de 7 anios o mas / personas de 7 anios o mas) * 100", Glosario, "porcentaje"),
        new Indicador("porcentajeMigrantesVida", "Porcentaje de migrantes de toda la vida", "Migrantes de toda la vida como proporcion del total de personas.", ClavesHecho.Poblacion,
            "migrantesVida", "personas", 100m, "(migrantes de toda la vida / total de personas) * 100", Glosario, "porcentaje"),

        new Indicador("tamanioPromedioHogar", "Tamanio promedio del hogar", "Personas por hogar.", ClavesHecho.Hogar,
            "personasEnHogares", "hogares", 1m, "personas en hogares / hogares", Glosario, "personas por hogar"),
        new Indicador("porcentajeHogaresConInternet", "Porcentaje de hogares con internet", "Hogares con servicio de internet como proporcion del total de hogares.", ClavesHecho.Hogar,
            "hogaresConInternet", "hogares", 100m, "(hogares con internet / hogares) * 100", Glosario, "porcentaje"),
        new Indicador("porcentajeHogaresConRemesas", "Porcentaje de hogares que reciben remesas", "Hogares que reciben remesas como proporcion del total de hogares.", ClavesHecho.Hogar,
            "hogaresConRemesas", "hogares", 100m, "(hogares que reciben remesas / hogares) * 100", Glosario, "porcentaje"),

        new Indicador("porcentajeViviendasOcupadas", "Porcentaje de viviendas ocupadas", "Viviendas ocupadas como proporcion del total de viviendas.", ClavesHecho.Vivienda,
            "viviendasOcupadas", "viviendas", 100m, "(viviendas ocupadas / viviendas) * 100", Glosario, "porcentaje"),

        new Indicador("porcentajeEmigrantesMujeres", "Porcentaje de emigrantes mujeres", "Mujeres emigrantes como proporcion del total de emigrantes.", ClavesHecho.Migracion,
            "emigrantesMujeres", "emigrantes", 100m, "(emigrantes mujeres / emigrantes) * 100", Glosario, "porcentaje"),
    };
}
