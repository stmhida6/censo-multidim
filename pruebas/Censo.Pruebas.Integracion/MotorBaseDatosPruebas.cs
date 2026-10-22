using Censo.Aplicacion.Catalogo;
using Censo.Aplicacion.Consultas;
using Censo.Dominio.Consultas;
using Censo.Infraestructura.Persistencia;
using Censo.Pruebas.BaseDatos.Ayudantes;
using static Censo.Pruebas.BaseDatos.Ayudantes.ConexionPruebas;

namespace Censo.Pruebas.Integracion;

/// <summary>
/// El motor de consultas completo (catalogo, validador, constructor de SQL y repositorio Dapper) contra la base real, sin la
/// capa HTTP. Los resultados se comparan con oraculos independientes: conteos de los .sav, calculos de R y SQL escrito a mano.
/// </summary>
[Trait("Categoria", "Motor")]
public class MotorBaseDatosPruebas
{
    private readonly CatalogoCenso _catalogo = new();
    private readonly ServicioConsultas _servicio;

    public MotorBaseDatosPruebas()
    {
        var constructor = new ConstructorConsultaSql(_catalogo);
        var validador = new ValidadorSolicitud(_catalogo);
        var repositorio = new RepositorioConsultasSql(new OpcionesBaseDatos(CadenaConexion, 120));
        _servicio = new ServicioConsultas(validador, constructor, repositorio);
    }

    private Task<ResultadoConsulta> Consultar(string[]? medidas = null, string[]? indicadores = null, string[]? dimensiones = null,
        FiltroSolicitud[]? filtros = null, int? limite = 100_000) =>
        _servicio.ConsultarAsync(new SolicitudConsulta(medidas, indicadores, dimensiones, filtros, limite));

    private static long Total(ResultadoConsulta r, string columna) => r.Filas.Sum(f => Convert.ToInt64(f[columna]));

    private static long Unico(ResultadoConsulta r, string columna) => Convert.ToInt64(Assert.Single(r.Filas)[columna]);

    private static FiltroSolicitud Filtro(string nivel, string operador, params object?[] valores) => new(nivel, operador, valores);

    // ------------------------------------------------------------------ propiedad: las partes suman el total

    public static IEnumerable<object[]> NivelesPorHecho()
    {
        var catalogo = new CatalogoCenso();
        var medidaBase = new Dictionary<string, string>
        {
            ["poblacion"] = "personas", ["hogar"] = "hogares", ["vivienda"] = "viviendas", ["migracion"] = "emigrantes",
        };
        foreach (var hecho in catalogo.Hechos)
            foreach (var dimension in catalogo.Dimensiones.Where(d => d.VinculoCon(hecho.Clave) is not null))
                foreach (var nivel in dimension.Niveles)
                    yield return new object[] { hecho.Clave, medidaBase[hecho.Clave], nivel.Clave };
    }

    private static readonly Dictionary<string, long> TotalPorHecho = new()
    {
        ["poblacion"] = ValoresEsperados.Personas,
        ["hogar"] = 3_275_931,
        ["vivienda"] = 3_943_431,
        ["migracion"] = 242_203,
    };

    [Theory]
    [MemberData(nameof(NivelesPorHecho))]
    public async Task Al_agrupar_por_cualquier_nivel_las_partes_suman_el_total_del_hecho(string hecho, string medida, string nivel)
    {
        var resultado = await Consultar(medidas: new[] { medida }, dimensiones: new[] { nivel });

        Assert.False(resultado.Truncado, $"{hecho} por {nivel} se trunco: aumente el limite de la prueba.");
        Assert.Equal(TotalPorHecho[hecho], Total(resultado, medida));
    }

    [Fact]
    public async Task Cada_hecho_devuelve_su_total_oficial_sin_agrupar()
    {
        Assert.Equal(14_901_286, Unico(await Consultar(medidas: new[] { "personas" }), "personas"));
        Assert.Equal(3_275_931, Unico(await Consultar(medidas: new[] { "hogares" }), "hogares"));
        Assert.Equal(3_943_431, Unico(await Consultar(medidas: new[] { "viviendas" }), "viviendas"));
        Assert.Equal(242_203, Unico(await Consultar(medidas: new[] { "emigrantes" }), "emigrantes"));
    }

    // ------------------------------------------------------------------ oraculos independientes (R sobre los .sav)

    [Fact]
    public async Task Las_medidas_de_actividad_economica_coinciden_con_los_calculos_de_R()
    {
        var r = await Consultar(medidas: new[] { "pet", "pea", "ocupados", "desocupadosAbiertos" });

        Assert.Equal(9_928_561, Unico(r, "pet"));
        Assert.Equal(5_020_548, Unico(r, "pea"));
        Assert.Equal(4_884_838, Unico(r, "ocupados"));
        Assert.Equal(135_710, Unico(r, "desocupadosAbiertos"));
    }

    [Fact]
    public async Task El_filtro_de_edad_de_7_anios_o_mas_coincide_con_el_conteo_de_R()
    {
        var r = await Consultar(medidas: new[] { "personas" }, filtros: new[] { Filtro("edad", "MayorOIgual", 7L) });
        Assert.Equal(12_528_937, Unico(r, "personas"));
    }

    [Fact]
    public async Task Hombres_y_mujeres_suman_las_personas_y_coinciden_con_el_stage()
    {
        var r = await Consultar(medidas: new[] { "personas", "hombres", "mujeres" });
        Assert.Equal(Unico(r, "personas"), Unico(r, "hombres") + Unico(r, "mujeres"));
        Assert.Equal(Escalar<long>("SELECT COUNT_BIG(*) FROM stage.Persona WHERE PCP6 = 1"), Unico(r, "hombres"));
    }

    // ------------------------------------------------------------------ equivalencia con SQL escrito a mano

    [Fact]
    public async Task Personas_por_departamento_coincide_con_la_consulta_manual()
    {
        var motor = await Consultar(medidas: new[] { "personas" }, dimensiones: new[] { "departamento" });
        var manual = Escalar<long>(@"SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion f
            JOIN dim.LugarPoblado l ON l.LugarPobladoId = f.LugarPobladoId
            JOIN dim.Municipio m ON m.MunicipioId = l.MunicipioId
            JOIN dim.Departamento d ON d.DepartamentoId = m.DepartamentoId
            WHERE d.CodigoDepartamento = 1");

        var guatemala = motor.Filas.Single(f => Convert.ToInt32(f["departamento_codigo"]) == 1);
        Assert.Equal(manual, Convert.ToInt64(guatemala["personas"]));
    }

    [Fact]
    public async Task Filtrar_por_departamento_es_igual_a_tomar_esa_fila_de_la_agrupacion()
    {
        var agrupado = await Consultar(medidas: new[] { "personas" }, dimensiones: new[] { "departamento" });
        var filtrado = await Consultar(medidas: new[] { "personas" }, filtros: new[] { Filtro("departamento", "Igual", 1L) });

        var esperado = agrupado.Filas.Single(f => Convert.ToInt32(f["departamento_codigo"]) == 1)["personas"];
        Assert.Equal(Convert.ToInt64(esperado), Unico(filtrado, "personas"));
    }

    [Fact]
    public async Task Los_filtros_En_y_Entre_son_consistentes_con_Igual()
    {
        var uno = await Consultar(medidas: new[] { "personas" }, filtros: new[] { Filtro("departamento", "Igual", 1L) });
        var dos = await Consultar(medidas: new[] { "personas" }, filtros: new[] { Filtro("departamento", "Igual", 2L) });
        var union = await Consultar(medidas: new[] { "personas" }, filtros: new[] { Filtro("departamento", "En", 1L, 2L) });
        var rango = await Consultar(medidas: new[] { "personas" }, filtros: new[] { Filtro("departamento", "Entre", 1L, 2L) });

        Assert.Equal(Unico(uno, "personas") + Unico(dos, "personas"), Unico(union, "personas"));
        Assert.Equal(Unico(union, "personas"), Unico(rango, "personas"));
    }

    [Fact]
    public async Task Un_filtro_excluyente_devuelve_el_complemento()
    {
        var igual = await Consultar(medidas: new[] { "personas" }, filtros: new[] { Filtro("sexo", "Igual", 1L) });
        var distinto = await Consultar(medidas: new[] { "personas" }, filtros: new[] { Filtro("sexo", "Distinto", 1L) });

        Assert.Equal(ValoresEsperados.Personas, Unico(igual, "personas") + Unico(distinto, "personas"));
    }

    [Fact]
    public async Task Una_consulta_con_varios_niveles_conserva_el_total()
    {
        var r = await Consultar(medidas: new[] { "personas" }, dimensiones: new[] { "departamento", "sexo", "grupoQuinquenal" });
        Assert.Equal(ValoresEsperados.Personas, Total(r, "personas"));
    }

    [Fact]
    public async Task El_limite_trunca_e_indica_que_hay_mas_filas()
    {
        var r = await Consultar(medidas: new[] { "personas" }, dimensiones: new[] { "municipio" }, limite: 10);

        Assert.True(r.Truncado);
        Assert.Equal(10, r.Filas.Count);
    }

    [Fact]
    public async Task Los_miembros_no_aplica_se_conservan_como_grupo_propio()
    {
        // Personas que viven en viviendas colectivas u otras sin fuente de agua declarada: NULL en la dimension.
        var r = await Consultar(medidas: new[] { "personas" }, dimensiones: new[] { "fuenteAgua" });
        Assert.Equal(ValoresEsperados.Personas, Total(r, "personas"));
        Assert.Contains(r.Filas, f => string.Equals(f["fuenteAgua"] as string, "No aplica", StringComparison.Ordinal));
    }

    // ------------------------------------------------------------------ indicadores

    [Fact]
    public async Task Un_indicador_se_recalcula_desde_los_totales_y_no_promediando_los_grupos()
    {
        var nacional = await Consultar(indicadores: new[] { "tasaGlobalParticipacion" });
        var porDepartamento = await Consultar(indicadores: new[] { "tasaGlobalParticipacion" }, dimensiones: new[] { "departamento" });

        var numerador = Total(porDepartamento, "tasaGlobalParticipacion_numerador");
        var denominador = Total(porDepartamento, "tasaGlobalParticipacion_denominador");

        Assert.Equal(Unico(nacional, "tasaGlobalParticipacion_numerador"), numerador);
        Assert.Equal(Unico(nacional, "tasaGlobalParticipacion_denominador"), denominador);
        Assert.Equal(5_020_548, numerador);
        Assert.Equal(9_928_561, denominador);
        Assert.Equal(Math.Round(5_020_548m * 100 / 9_928_561m, 4), Math.Round(Convert.ToDecimal(Assert.Single(nacional.Filas)["tasaGlobalParticipacion"]), 4));
    }

    [Fact]
    public async Task La_tasa_de_desempleo_abierto_se_calcula_sobre_la_poblacion_economicamente_activa()
    {
        var r = await Consultar(indicadores: new[] { "tasaDesempleoAbierto" });
        Assert.Equal(Math.Round(135_710m * 100 / 5_020_548m, 4), Math.Round(Convert.ToDecimal(Assert.Single(r.Filas)["tasaDesempleoAbierto"]), 4));
    }

    [Fact]
    public async Task El_tamanio_promedio_del_hogar_es_personas_en_hogares_entre_hogares()
    {
        var r = await Consultar(indicadores: new[] { "tamanioPromedioHogar" });
        var fila = Assert.Single(r.Filas);

        var personasEnHogares = Escalar<long>("SELECT SUM(CAST(TotalPersonas AS BIGINT)) FROM hechos.CensoHogar");
        Assert.Equal(personasEnHogares, Convert.ToInt64(fila["tamanioPromedioHogar_numerador"]));
        Assert.Equal(3_275_931, Convert.ToInt64(fila["tamanioPromedioHogar_denominador"]));
    }

    [Fact]
    public async Task El_porcentaje_de_viviendas_ocupadas_coincide_con_el_conteo_directo()
    {
        var r = await Consultar(indicadores: new[] { "porcentajeViviendasOcupadas" });
        var fila = Assert.Single(r.Filas);

        var ocupadas = Escalar<long>(@"SELECT COUNT_BIG(*) FROM hechos.CensoVivienda v
            JOIN dim.CondicionVivienda c ON c.CondicionViviendaId = v.CondicionViviendaId WHERE c.CodigoCondicionVivienda = 1");
        Assert.Equal(ocupadas, Convert.ToInt64(fila["porcentajeViviendasOcupadas_numerador"]));
        Assert.Equal(3_943_431, Convert.ToInt64(fila["porcentajeViviendasOcupadas_denominador"]));
    }

    [Fact]
    public async Task Todos_los_indicadores_se_pueden_consultar_por_departamento_sin_error()
    {
        foreach (var indicador in _catalogo.Indicadores)
        {
            var r = await Consultar(indicadores: new[] { indicador.Clave }, dimensiones: new[] { "departamento" });
            Assert.Equal(22, r.Filas.Count);
        }
    }

    [Fact]
    public async Task Todas_las_medidas_se_pueden_consultar_sin_error()
    {
        foreach (var medida in _catalogo.Medidas)
        {
            var r = await Consultar(medidas: new[] { medida.Clave });
            Assert.Single(r.Filas);
        }
    }
}
