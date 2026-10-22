using System.Diagnostics;
using Censo.Pruebas.BaseDatos.Ayudantes;
using Xunit.Abstractions;
using static Censo.Pruebas.BaseDatos.Ayudantes.ConexionPruebas;

namespace Censo.Pruebas.BaseDatos;

/// <summary>
/// Linea base de rendimiento de consultas analiticas tipicas sobre el modelo (14.9 millones de personas). Los tiempos
/// se registran en la salida de cada prueba; el umbral es deliberadamente amplio y sirve como alarma, no como objetivo.
/// La prueba de carga con solicitudes simultaneas corresponde a la fase de evaluacion de la API (objetivo especifico 4).
/// </summary>
[Trait("Categoria", "Rendimiento")]
public class RendimientoPruebas
{
    private const int UmbralSegundos = 30;

    private readonly ITestOutputHelper _salida;

    public RendimientoPruebas(ITestOutputHelper salida) => _salida = salida;

    public static IEnumerable<object[]> Consultas() => new[]
    {
        new object[]
        {
            "Poblacion por departamento",
            @"SELECT d.NombreDepartamento, COUNT_BIG(*) AS personas
              FROM hechos.CensoPoblacion p
              JOIN dim.LugarPoblado l ON l.LugarPobladoId = p.LugarPobladoId
              JOIN dim.Municipio m ON m.MunicipioId = l.MunicipioId
              JOIN dim.Departamento d ON d.DepartamentoId = m.DepartamentoId
              GROUP BY d.NombreDepartamento",
        },
        new object[]
        {
            "Poblacion por sexo y grupo quinquenal de edad",
            @"SELECT e.GrupoQuinquenal, s.NombreSexo, COUNT_BIG(*) AS personas
              FROM hechos.CensoPoblacion p
              JOIN dim.Edad e ON e.EdadId = p.EdadId
              JOIN dim.Sexo s ON s.SexoId = p.SexoId
              GROUP BY e.GrupoQuinquenal, s.NombreSexo",
        },
        new object[]
        {
            "Poblacion por pueblo, sexo y grupo amplio de edad",
            @"SELECT pu.NombrePueblo, s.NombreSexo, e.GrupoAmplio, COUNT_BIG(*) AS personas
              FROM hechos.CensoPoblacion p
              JOIN dim.Pueblo pu ON pu.PuebloId = p.PuebloId
              JOIN dim.Sexo s ON s.SexoId = p.SexoId
              JOIN dim.Edad e ON e.EdadId = p.EdadId
              GROUP BY pu.NombrePueblo, s.NombreSexo, e.GrupoAmplio",
        },
        new object[]
        {
            "Personas ocupadas por rama de actividad y sexo",
            @"SELECT r.NombreRamaActividad, s.NombreSexo, COUNT_BIG(*) AS personas
              FROM hechos.CensoPoblacion p
              JOIN dim.CondicionActividad c ON c.CondicionActividadId = p.CondicionActividadId
              JOIN dim.RamaActividad r ON r.RamaActividadId = p.RamaActividadId
              JOIN dim.Sexo s ON s.SexoId = p.SexoId
              WHERE c.CodigoCondicionActividad = 1
              GROUP BY r.NombreRamaActividad, s.NombreSexo",
        },
        new object[]
        {
            "Poblacion por lugar poblado (mas de 20,000 grupos)",
            @"SELECT l.NombreLugarPoblado, COUNT_BIG(*) AS personas
              FROM hechos.CensoPoblacion p
              JOIN dim.LugarPoblado l ON l.LugarPobladoId = p.LugarPobladoId
              GROUP BY l.LugarPobladoId, l.NombreLugarPoblado",
        },
        new object[]
        {
            "Personas por fuente de agua del hogar y area urbana o rural (poblacion, hogar y vivienda)",
            @"SELECT a.NombreFuenteAgua, v.EsUrbano, COUNT_BIG(*) AS personas
              FROM hechos.CensoPoblacion p
              JOIN hechos.CensoHogar h ON h.HogarId = p.HogarId
              JOIN hechos.CensoVivienda v ON v.ViviendaId = p.ViviendaId
              JOIN dim.FuenteAgua a ON a.FuenteAguaId = h.FuenteAguaId
              GROUP BY a.NombreFuenteAgua, v.EsUrbano",
        },
        new object[]
        {
            "Hogares por tenencia, con internet y con remesas",
            @"SELECT t.NombreTenenciaVivienda, h.TieneInternet, h.TieneRemesas, COUNT_BIG(*) AS hogares
              FROM hechos.CensoHogar h
              JOIN dim.TenenciaVivienda t ON t.TenenciaViviendaId = h.TenenciaViviendaId
              GROUP BY t.NombreTenenciaVivienda, h.TieneInternet, h.TieneRemesas",
        },
        new object[]
        {
            "Poblacion de un solo lugar poblado (consulta puntual con filtro)",
            @"SELECT s.NombreSexo, e.GrupoQuinquenal, COUNT_BIG(*) AS personas
              FROM hechos.CensoPoblacion p
              JOIN dim.LugarPoblado l ON l.LugarPobladoId = p.LugarPobladoId
              JOIN dim.Sexo s ON s.SexoId = p.SexoId
              JOIN dim.Edad e ON e.EdadId = p.EdadId
              WHERE l.CodigoLugarPoblado = 101001
              GROUP BY s.NombreSexo, e.GrupoQuinquenal",
        },
    };

    [Theory]
    [MemberData(nameof(Consultas))]
    public void La_consulta_analitica_responde_dentro_del_umbral(string nombre, string sql)
    {
        // Primera ejecucion: incluye compilacion y lectura en frio; segunda: con datos en memoria.
        var frio = Medir(sql);
        var caliente = Medir(sql);

        _salida.WriteLine($"{nombre}: frio {frio.Tiempo.TotalSeconds:F2} s, caliente {caliente.Tiempo.TotalSeconds:F2} s, {caliente.Filas:N0} filas de resultado");

        Assert.True(caliente.Filas > 0, "La consulta no devolvio filas.");
        Assert.True(frio.Tiempo < TimeSpan.FromSeconds(UmbralSegundos), $"'{nombre}' tardo {frio.Tiempo.TotalSeconds:F1} s en la primera ejecucion.");
        Assert.True(caliente.Tiempo < TimeSpan.FromSeconds(UmbralSegundos), $"'{nombre}' tardo {caliente.Tiempo.TotalSeconds:F1} s.");
    }

    private static (TimeSpan Tiempo, int Filas) Medir(string sql)
    {
        var cronometro = Stopwatch.StartNew();
        var filas = Consultar<dynamic>(sql).Count;
        cronometro.Stop();
        return (cronometro.Elapsed, filas);
    }
}
