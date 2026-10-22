using System.Net;
using System.Text;
using System.Text.Json;
using Censo.Dominio.Consultas;
using Censo.Dominio.Contratos;
using Censo.Pruebas.BaseDatos.Ayudantes;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using static Censo.Pruebas.BaseDatos.Ayudantes.ConexionPruebas;

namespace Censo.Pruebas.Integracion;

/// <summary>Comportamiento HTTP de la API: catalogo, consultas, validacion y respuestas seguras ante errores.</summary>
[Trait("Categoria", "Api")]
public class ApiPruebas : IClassFixture<FabricaApi>
{
    private readonly FabricaApi _fabrica;

    public ApiPruebas(FabricaApi fabrica) => _fabrica = fabrica;

    private static StringContent Json(object cuerpo) => new(JsonSerializer.Serialize(cuerpo), Encoding.UTF8, "application/json");

    private static async Task<JsonElement> LeerAsync(HttpResponseMessage respuesta)
    {
        using var documento = JsonDocument.Parse(await respuesta.Content.ReadAsStringAsync());
        return documento.RootElement.Clone();
    }

    private async Task<(HttpStatusCode Estado, JsonElement Cuerpo)> ConsultarAsync(object solicitud, HttpClient? cliente = null)
    {
        using var respuesta = await (cliente ?? _fabrica.CreateClient()).PostAsync("/api/consultas", Json(solicitud));
        return (respuesta.StatusCode, await LeerAsync(respuesta));
    }

    private static long Personas(JsonElement resultado) =>
        resultado.GetProperty("filas").EnumerateArray().Sum(f => f.GetProperty("personas").GetInt64());

    // ------------------------------------------------------------------ salud y catalogo

    [Fact]
    public async Task La_salud_confirma_la_conexion_con_la_base_de_datos()
    {
        var respuesta = await _fabrica.CreateClient().GetAsync("/salud");
        Assert.Equal(HttpStatusCode.OK, respuesta.StatusCode);
        Assert.Equal("ok", (await LeerAsync(respuesta)).GetProperty("estado").GetString());
    }

    [Fact]
    public async Task El_catalogo_lista_los_cuatro_hechos()
    {
        var hechos = await LeerAsync(await _fabrica.CreateClient().GetAsync("/api/catalogo/hechos"));
        Assert.Equal(new[] { "hogar", "migracion", "poblacion", "vivienda" }, hechos.EnumerateArray().Select(h => h.GetProperty("clave").GetString()!).OrderBy(c => c));
    }

    [Fact]
    public async Task Las_dimensiones_se_pueden_filtrar_por_hecho()
    {
        var todas = await LeerAsync(await _fabrica.CreateClient().GetAsync("/api/catalogo/dimensiones"));
        var deEmigrantes = await LeerAsync(await _fabrica.CreateClient().GetAsync("/api/catalogo/dimensiones?hecho=migracion"));

        var clavesEmigrantes = deEmigrantes.EnumerateArray().Select(d => d.GetProperty("clave").GetString()).ToList();
        Assert.Contains("territorio", clavesEmigrantes);
        Assert.Contains("sexo", clavesEmigrantes);
        Assert.DoesNotContain("pueblo", clavesEmigrantes);
        Assert.True(todas.GetArrayLength() > deEmigrantes.GetArrayLength());
    }

    [Fact]
    public async Task El_catalogo_lista_medidas_indicadores_y_operadores()
    {
        var cliente = _fabrica.CreateClient();
        var medidas = await LeerAsync(await cliente.GetAsync("/api/catalogo/medidas?hecho=poblacion"));
        var indicadores = await LeerAsync(await cliente.GetAsync("/api/catalogo/indicadores?hecho=poblacion"));
        var operadores = await LeerAsync(await cliente.GetAsync("/api/catalogo/operadores"));

        Assert.Contains(medidas.EnumerateArray(), m => m.GetProperty("clave").GetString() == "personas");
        var masculinidad = Assert.Single(indicadores.EnumerateArray(), i => i.GetProperty("clave").GetString() == "indiceMasculinidad");
        Assert.Contains("100", masculinidad.GetProperty("formula").GetString());
        Assert.Equal(7, operadores.GetArrayLength());
        Assert.Empty((await LeerAsync(await cliente.GetAsync("/api/catalogo/medidas?hecho=noExiste"))).EnumerateArray());
    }

    [Fact]
    public async Task El_catalogo_no_expone_sql_tablas_ni_expresiones_internas()
    {
        var cliente = _fabrica.CreateClient();
        foreach (var ruta in new[] { "hechos", "dimensiones", "medidas", "indicadores", "operadores" })
        {
            var texto = await (await cliente.GetAsync($"/api/catalogo/{ruta}")).Content.ReadAsStringAsync();
            Assert.DoesNotContain("hechos.", texto);
            Assert.DoesNotContain("dim.", texto);
            Assert.DoesNotContain("{a}", texto);
            Assert.DoesNotContain("CASE ", texto);
            Assert.DoesNotContain("Censo", texto.Replace("Censo 2018", string.Empty));
        }
    }

    [Fact]
    public async Task Swagger_genera_la_documentacion_de_la_api()
    {
        var respuesta = await _fabrica.CreateClient().GetAsync("/swagger/v1/swagger.json");
        Assert.Equal(HttpStatusCode.OK, respuesta.StatusCode);
        var texto = await respuesta.Content.ReadAsStringAsync();
        Assert.Contains("/api/consultas", texto);
        Assert.Contains("/api/catalogo/hechos", texto);
    }

    // ------------------------------------------------------------------ consultas

    [Fact]
    public async Task Una_consulta_devuelve_el_total_de_personas_del_censo()
    {
        var (estado, cuerpo) = await ConsultarAsync(new { medidas = new[] { "personas" } });

        Assert.Equal(HttpStatusCode.OK, estado);
        Assert.Equal(ValoresEsperados.Personas, Personas(cuerpo));
        Assert.Equal("poblacion", cuerpo.GetProperty("hecho").GetString());
        Assert.False(cuerpo.GetProperty("truncado").GetBoolean());
    }

    [Fact]
    public async Task Una_consulta_por_departamento_devuelve_22_grupos_que_suman_el_total()
    {
        var (estado, cuerpo) = await ConsultarAsync(new { medidas = new[] { "personas" }, dimensiones = new[] { "departamento" } });

        Assert.Equal(HttpStatusCode.OK, estado);
        Assert.Equal(22, cuerpo.GetProperty("filas").GetArrayLength());
        Assert.Equal(ValoresEsperados.Personas, Personas(cuerpo));
    }

    [Fact]
    public async Task Un_indicador_devuelve_su_valor_con_el_numerador_y_el_denominador()
    {
        var (estado, cuerpo) = await ConsultarAsync(new { indicadores = new[] { "indiceMasculinidad" } });

        Assert.Equal(HttpStatusCode.OK, estado);
        var fila = cuerpo.GetProperty("filas")[0];
        var hombres = fila.GetProperty("indiceMasculinidad_numerador").GetInt64();
        var mujeres = fila.GetProperty("indiceMasculinidad_denominador").GetInt64();
        Assert.Equal(Math.Round(hombres * 100m / mujeres, 6), fila.GetProperty("indiceMasculinidad").GetDecimal());
        Assert.Equal(ValoresEsperados.Personas, hombres + mujeres);
    }

    [Fact]
    public async Task Los_nombres_con_acentos_viajan_bien_en_la_respuesta()
    {
        var (_, cuerpo) = await ConsultarAsync(new { medidas = new[] { "personas" }, dimensiones = new[] { "departamento" } });
        var nombres = cuerpo.GetProperty("filas").EnumerateArray().Select(f => f.GetProperty("departamento").GetString()).ToList();
        Assert.Contains("Sacatepéquez", nombres);
        Assert.Contains("Quiché", nombres);
    }

    // ------------------------------------------------------------------ validacion y seguridad

    [Fact]
    public async Task Una_solicitud_invalida_devuelve_400_con_la_lista_de_errores()
    {
        var (estado, cuerpo) = await ConsultarAsync(new
        {
            medidas = new[] { "personas" },
            dimensiones = new[] { "nivelInventado" },
            filtros = new[] { new { nivel = "edad", operador = "Como", valores = new[] { 1 } } },
        });

        Assert.Equal(HttpStatusCode.BadRequest, estado);
        Assert.Equal(400, cuerpo.GetProperty("status").GetInt32());
        var campos = cuerpo.GetProperty("errores").EnumerateArray().Select(e => e.GetProperty("campo").GetString()).ToList();
        Assert.Contains("dimensiones[0]", campos);
        Assert.Contains("filtros[0].operador", campos);
    }

    [Fact]
    public async Task Una_medida_desconocida_devuelve_400_indicando_la_posicion()
    {
        var (estado, cuerpo) = await ConsultarAsync(new { medidas = new[] { "medidaInventada" } });

        Assert.Equal(HttpStatusCode.BadRequest, estado);
        Assert.Equal("medidas[0]", cuerpo.GetProperty("errores")[0].GetProperty("campo").GetString());
    }

    [Fact]
    public async Task Un_json_mal_formado_devuelve_400()
    {
        using var respuesta = await _fabrica.CreateClient().PostAsync("/api/consultas", new StringContent("{\"medidas\": ", Encoding.UTF8, "application/json"));
        Assert.Equal(HttpStatusCode.BadRequest, respuesta.StatusCode);
    }

    [Fact]
    public async Task Un_cuerpo_que_no_es_json_devuelve_415()
    {
        using var respuesta = await _fabrica.CreateClient().PostAsync("/api/consultas", new StringContent("medidas=personas", Encoding.UTF8, "text/plain"));
        Assert.Equal(HttpStatusCode.UnsupportedMediaType, respuesta.StatusCode);
    }

    [Fact]
    public void El_endpoint_de_consultas_limita_el_tamano_del_cuerpo()
    {
        // TestServer no aplica el limite de Kestrel: aqui se comprueba que esta declarado; el 413 real se verifico
        // contra Kestrel con un cuerpo de 70 KB (ver docs/manual-tecnico.md, solución de problemas).
        var metodo = typeof(Censo.Api.Controllers.ConsultasController).GetMethod("Consultar")!;
        var atributo = (Microsoft.AspNetCore.Mvc.RequestSizeLimitAttribute?)Attribute.GetCustomAttribute(metodo, typeof(Microsoft.AspNetCore.Mvc.RequestSizeLimitAttribute));
        Assert.NotNull(atributo);
    }

    [Theory]
    [InlineData("0-14'; DROP TABLE dim.Sexo; --")]
    [InlineData("0-14' OR '1'='1")]
    [InlineData("1; DELETE FROM hechos.CensoPoblacion")]
    public async Task Un_texto_hostil_en_un_filtro_no_altera_ni_borra_datos(string hostil)
    {
        var personasAntes = Escalar<long>("SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion");
        var sexosAntes = Escalar<long>("SELECT COUNT_BIG(*) FROM dim.Sexo");

        var (estado, cuerpo) = await ConsultarAsync(new
        {
            medidas = new[] { "personas" },
            filtros = new[] { new { nivel = "grupoAmplio", operador = "Igual", valores = new[] { hostil } } },
        });

        Assert.Equal(HttpStatusCode.OK, estado);
        Assert.Equal(0, Personas(cuerpo));   // ningun grupo se llama asi: el texto se comparo como dato
        Assert.Equal(personasAntes, Escalar<long>("SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion"));
        Assert.Equal(sexosAntes, Escalar<long>("SELECT COUNT_BIG(*) FROM dim.Sexo"));
    }

    [Theory]
    [InlineData("sexo]; DROP TABLE dim.Sexo; --")]
    [InlineData("sexo UNION SELECT name FROM sys.tables")]
    [InlineData("1=1")]
    public async Task Un_nivel_o_una_medida_hostil_devuelve_400_y_no_llega_a_la_base(string hostil)
    {
        var (estadoNivel, _) = await ConsultarAsync(new { medidas = new[] { "personas" }, dimensiones = new[] { hostil } });
        var (estadoMedida, _) = await ConsultarAsync(new { medidas = new[] { hostil } });

        Assert.Equal(HttpStatusCode.BadRequest, estadoNivel);
        Assert.Equal(HttpStatusCode.BadRequest, estadoMedida);
        Assert.Equal(2, Escalar<long>("SELECT COUNT_BIG(*) FROM dim.Sexo"));
    }

    [Fact]
    public async Task Superado_el_limite_de_solicitudes_la_api_responde_429()
    {
        using var fabrica = _fabrica.WithWebHostBuilder(b => b.UseSetting("LimiteSolicitudes:PorMinuto", "3"));
        var cliente = fabrica.CreateClient();

        var estados = new List<HttpStatusCode>();
        for (var i = 0; i < 5; i++)
        {
            using var respuesta = await cliente.PostAsync("/api/consultas", Json(new { medidas = new[] { "viviendas" } }));
            estados.Add(respuesta.StatusCode);
        }

        Assert.Equal(3, estados.Count(e => e == HttpStatusCode.OK));
        Assert.Equal(2, estados.Count(e => e == HttpStatusCode.TooManyRequests));
    }

    // ------------------------------------------------------------------ errores del servidor

    private sealed class RepositorioQueFalla : IRepositorioConsultas
    {
        private readonly Exception _error;

        public RepositorioQueFalla(Exception error) => _error = error;

        public Task<TablaResultado> EjecutarAsync(ConsultaSql consulta, CancellationToken cancelacion = default) => throw _error;
    }

    private HttpClient ClienteConFalla(Exception error) =>
        _fabrica.WithWebHostBuilder(b => b.ConfigureTestServices(s =>
        {
            s.RemoveAll<IRepositorioConsultas>();
            s.AddSingleton<IRepositorioConsultas>(new RepositorioQueFalla(error));
        })).CreateClient();

    [Fact]
    public async Task Un_tiempo_de_espera_agotado_devuelve_504_con_un_mensaje_generico()
    {
        var cliente = ClienteConFalla(new ConsultaFallidaException("detalle interno secreto", tiempoAgotado: true));

        var (estado, cuerpo) = await ConsultarAsync(new { medidas = new[] { "personas" } }, cliente);

        Assert.Equal(HttpStatusCode.GatewayTimeout, estado);
        Assert.DoesNotContain("secreto", cuerpo.GetRawText());
    }

    [Fact]
    public async Task Un_error_de_la_base_de_datos_devuelve_500_sin_detalles_internos()
    {
        var cliente = ClienteConFalla(new ConsultaFallidaException("detalle interno secreto", tiempoAgotado: false, new InvalidOperationException("servidor sql-interno")));

        var (estado, cuerpo) = await ConsultarAsync(new { medidas = new[] { "personas" } }, cliente);

        Assert.Equal(HttpStatusCode.InternalServerError, estado);
        Assert.DoesNotContain("secreto", cuerpo.GetRawText());
        Assert.DoesNotContain("sql-interno", cuerpo.GetRawText());
    }

    [Fact]
    public async Task Una_excepcion_inesperada_devuelve_500_sin_traza_ni_mensaje_interno()
    {
        var cliente = ClienteConFalla(new InvalidOperationException("clave de conexion secreta"));

        using var respuesta = await cliente.PostAsync("/api/consultas", Json(new { medidas = new[] { "personas" } }));
        var texto = await respuesta.Content.ReadAsStringAsync();

        Assert.Equal(HttpStatusCode.InternalServerError, respuesta.StatusCode);
        Assert.DoesNotContain("secreta", texto);
        Assert.DoesNotContain("at Censo", texto);
    }

    [Fact]
    public async Task Sin_conexion_con_la_base_de_datos_la_salud_responde_503()
    {
        var cliente = ClienteConFalla(new ConsultaFallidaException("no hay conexion", tiempoAgotado: false));
        Assert.Equal(HttpStatusCode.ServiceUnavailable, (await cliente.GetAsync("/salud")).StatusCode);
    }

    [Fact]
    public async Task Con_una_base_de_datos_inalcanzable_de_verdad_la_respuesta_es_500_y_no_revela_el_servidor()
    {
        using var fabrica = _fabrica.WithWebHostBuilder(b => b.UseSetting(
            "ConnectionStrings:CensoDb", "Server=localhost,1;Database=servidorSecreto;User Id=sa;Password=x;TrustServerCertificate=True;Connect Timeout=2"));
        var cliente = fabrica.CreateClient();

        using var respuesta = await cliente.PostAsync("/api/consultas", Json(new { medidas = new[] { "personas" } }));
        var texto = await respuesta.Content.ReadAsStringAsync();

        Assert.Equal(HttpStatusCode.InternalServerError, respuesta.StatusCode);
        Assert.DoesNotContain("servidorSecreto", texto);
        Assert.DoesNotContain("localhost", texto);
    }

    // ------------------------------------------------------------------ concurrencia

    [Fact]
    public async Task Veinte_consultas_simultaneas_se_resuelven_correctamente()
    {
        var cliente = _fabrica.CreateClient();
        var tareas = Enumerable.Range(0, 20).Select(async i =>
        {
            var nivel = new[] { "departamento", "sexo", "grupoQuinquenal", "pueblo" }[i % 4];
            using var respuesta = await cliente.PostAsync("/api/consultas", Json(new { medidas = new[] { "personas" }, dimensiones = new[] { nivel } }));
            return (respuesta.StatusCode, Total: Personas(await LeerAsync(respuesta)));
        }).ToArray();

        var resultados = await Task.WhenAll(tareas);

        Assert.All(resultados, r => Assert.Equal(HttpStatusCode.OK, r.StatusCode));
        Assert.All(resultados, r => Assert.Equal(ValoresEsperados.Personas, r.Total));
    }
}
