using Censo.Aplicacion.Catalogo;
using Censo.Aplicacion.Consultas;
using Censo.Dominio.Consultas;
using Censo.Dominio.Contratos;

namespace Censo.Pruebas.Aplicacion;

/// <summary>Orquestacion completa con un repositorio simulado: no toca ninguna base de datos.</summary>
[Trait("Categoria", "Servicio")]
public class ServicioPruebas
{
    private static readonly CatalogoCenso Catalogo = new();

    private sealed class RepositorioSimulado : IRepositorioConsultas
    {
        private readonly TablaResultado _tabla;

        public RepositorioSimulado(TablaResultado tabla) => _tabla = tabla;

        public int Llamadas { get; private set; }

        public ConsultaSql? Ultima { get; private set; }

        public CancellationToken UltimaCancelacion { get; private set; }

        public Task<TablaResultado> EjecutarAsync(ConsultaSql consulta, CancellationToken cancelacion = default)
        {
            Llamadas++;
            Ultima = consulta;
            UltimaCancelacion = cancelacion;
            return Task.FromResult(_tabla);
        }
    }

    private static (ServicioConsultas Servicio, RepositorioSimulado Repositorio) Crear(TablaResultado tabla)
    {
        var repositorio = new RepositorioSimulado(tabla);
        return (new ServicioConsultas(new ValidadorSolicitud(Catalogo), new ConstructorConsultaSql(Catalogo), repositorio), repositorio);
    }

    private static TablaResultado Tabla(string[] columnas, params object?[][] filas) => new(columnas, filas);

    [Fact]
    public async Task Un_indicador_se_calcula_con_el_numerador_y_el_denominador_agregados_de_cada_grupo()
    {
        var (servicio, _) = Crear(Tabla(
            new[] { "departamento", "departamento_codigo", "hombres", "mujeres" },
            new object?[] { "Guatemala", 1, 1_460_000L, 1_555_081L },
            new object?[] { "El Progreso", 2, 86_000L, 90_632L }));

        var resultado = await servicio.ConsultarAsync(new SolicitudConsulta(null, new[] { "indiceMasculinidad" }, new[] { "departamento" }));

        Assert.Equal("poblacion", resultado.Hecho);
        Assert.Equal(2, resultado.Filas.Count);
        Assert.Equal(Math.Round(1_460_000m * 100 / 1_555_081m, 6), resultado.Filas[0]["indiceMasculinidad"]);
        Assert.Equal(1_460_000L, resultado.Filas[0]["indiceMasculinidad_numerador"]);
        Assert.Equal(1_555_081L, resultado.Filas[0]["indiceMasculinidad_denominador"]);
    }

    [Fact]
    public async Task Un_indicador_con_denominador_cero_devuelve_nulo_y_no_falla()
    {
        var (servicio, _) = Crear(Tabla(new[] { "hombres", "mujeres" }, new object?[] { 5L, 0L }));

        var resultado = await servicio.ConsultarAsync(new SolicitudConsulta(null, new[] { "indiceMasculinidad" }));

        Assert.Null(resultado.Filas[0]["indiceMasculinidad"]);
    }

    [Fact]
    public async Task Las_sumas_nulas_de_un_grupo_sin_filas_cuentan_como_cero()
    {
        var (servicio, _) = Crear(Tabla(new[] { "personas" }, new object?[] { DBNull.Value }));

        var resultado = await servicio.ConsultarAsync(new SolicitudConsulta(new[] { "personas" }));

        Assert.Equal(0L, resultado.Filas[0]["personas"]);
    }

    [Fact]
    public async Task Las_medidas_que_solo_usa_un_indicador_no_aparecen_en_el_resultado()
    {
        var (servicio, _) = Crear(Tabla(new[] { "pea", "pet" }, new object?[] { 50L, 100L }));

        var resultado = await servicio.ConsultarAsync(new SolicitudConsulta(null, new[] { "tasaGlobalParticipacion" }, null, null, IncluirComponentes: false));

        Assert.Equal(new[] { "tasaGlobalParticipacion" }, resultado.Columnas.Select(c => c.Clave));
        Assert.Equal(new[] { "tasaGlobalParticipacion" }, resultado.Filas[0].Keys);
        Assert.Equal(50m, resultado.Filas[0]["tasaGlobalParticipacion"]);
    }

    [Fact]
    public async Task Los_componentes_de_los_indicadores_se_incluyen_por_defecto()
    {
        var (servicio, _) = Crear(Tabla(new[] { "pea", "pet" }, new object?[] { 50L, 100L }));

        var resultado = await servicio.ConsultarAsync(new SolicitudConsulta(null, new[] { "tasaGlobalParticipacion" }));

        Assert.Equal(new[] { "tasaGlobalParticipacion", "tasaGlobalParticipacion_numerador", "tasaGlobalParticipacion_denominador" },
            resultado.Columnas.Select(c => c.Clave));
        Assert.Equal(new[] { "indicador", "numerador", "denominador" }, resultado.Columnas.Select(c => c.Rol));
    }

    [Fact]
    public async Task Una_medida_pedida_y_usada_por_un_indicador_aparece_una_vez()
    {
        var (servicio, _) = Crear(Tabla(new[] { "pea", "pet" }, new object?[] { 50L, 100L }));

        var resultado = await servicio.ConsultarAsync(new SolicitudConsulta(new[] { "pea" }, new[] { "tasaGlobalParticipacion" }));

        Assert.Equal(1, resultado.Columnas.Count(c => c.Clave == "pea"));
        Assert.Equal(50L, resultado.Filas[0]["pea"]);
    }

    [Fact]
    public async Task Si_la_base_devuelve_mas_filas_que_el_limite_el_resultado_se_trunca_y_se_avisa()
    {
        var filas = Enumerable.Range(1, 4).Select(i => new object?[] { $"D{i}", i, 10L }).ToArray();
        var (servicio, repositorio) = Crear(Tabla(new[] { "departamento", "departamento_codigo", "personas" }, filas));

        var resultado = await servicio.ConsultarAsync(new SolicitudConsulta(new[] { "personas" }, null, new[] { "departamento" }, Limite: 3));

        Assert.True(resultado.Truncado);
        Assert.Equal(3, resultado.Filas.Count);
        Assert.Equal(4L, repositorio.Ultima!.Parametros["limite"]);
    }

    [Fact]
    public async Task Si_las_filas_no_superan_el_limite_el_resultado_no_se_trunca()
    {
        var (servicio, _) = Crear(Tabla(new[] { "personas" }, new object?[] { 10L }));
        var resultado = await servicio.ConsultarAsync(new SolicitudConsulta(new[] { "personas" }, Limite: 5));
        Assert.False(resultado.Truncado);
    }

    [Fact]
    public async Task Una_solicitud_invalida_no_llega_a_la_base_de_datos()
    {
        var (servicio, repositorio) = Crear(Tabla(new[] { "personas" }));

        await Assert.ThrowsAsync<SolicitudInvalidaException>(() => servicio.ConsultarAsync(new SolicitudConsulta(new[] { "noExiste" })));

        Assert.Equal(0, repositorio.Llamadas);
    }

    [Fact]
    public async Task La_cancelacion_llega_al_repositorio()
    {
        var (servicio, repositorio) = Crear(Tabla(new[] { "personas" }, new object?[] { 1L }));
        using var origen = new CancellationTokenSource();

        await servicio.ConsultarAsync(new SolicitudConsulta(new[] { "personas" }), origen.Token);

        Assert.Equal(origen.Token, repositorio.UltimaCancelacion);
    }

    [Fact]
    public async Task El_resultado_describe_cada_columna_con_su_rol_y_tipo()
    {
        var (servicio, _) = Crear(Tabla(new[] { "departamento", "departamento_codigo", "personas" }, new object?[] { "Guatemala", 1, 100L }));

        var resultado = await servicio.ConsultarAsync(new SolicitudConsulta(new[] { "personas" }, null, new[] { "departamento" }));

        Assert.Equal(new[] { "dimension", "dimensionCodigo", "medida" }, resultado.Columnas.Select(c => c.Rol));
        Assert.Equal(new[] { "texto", "entero", "entero" }, resultado.Columnas.Select(c => c.Tipo));
        Assert.Equal("Guatemala", resultado.Filas[0]["departamento"]);
        Assert.Equal(1, resultado.Filas[0]["departamento_codigo"]);
    }
}
