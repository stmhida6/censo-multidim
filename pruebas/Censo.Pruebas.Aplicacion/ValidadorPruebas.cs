using System.Text.Json;
using Censo.Aplicacion.Catalogo;
using Censo.Aplicacion.Consultas;
using Censo.Dominio.Catalogo;
using Censo.Dominio.Consultas;

namespace Censo.Pruebas.Aplicacion;

/// <summary>Etapa de validacion: toda solicitud se comprueba contra el catalogo antes de construir nada.</summary>
[Trait("Categoria", "Validacion")]
public class ValidadorPruebas
{
    private static readonly ValidadorSolicitud Validador = new(new CatalogoCenso());

    private static IReadOnlyList<ErrorValidacion> Errores(SolicitudConsulta? solicitud) =>
        Assert.Throws<SolicitudInvalidaException>(() => Validador.Validar(solicitud)).Errores;

    private static SolicitudConsulta Con(params FiltroSolicitud[] filtros) =>
        new(Medidas: new[] { "personas" }, Filtros: filtros);

    [Fact]
    public void Una_solicitud_correcta_produce_un_plan_con_el_hecho_las_agrupaciones_y_los_limites_por_defecto()
    {
        var plan = Validador.Validar(new SolicitudConsulta(new[] { "personas" }, null, new[] { "departamento", "sexo" }));

        Assert.Equal("poblacion", plan.Hecho.Clave);
        Assert.Equal(new[] { "departamento", "sexo" }, plan.Agrupaciones.Select(a => a.Nivel.Clave));
        Assert.Equal(ValidadorSolicitud.LimiteDefecto, plan.Limite);
        Assert.True(plan.IncluirComponentes);
    }

    [Fact]
    public void Un_indicador_agrega_a_las_medidas_consultadas_su_numerador_y_su_denominador()
    {
        var plan = Validador.Validar(new SolicitudConsulta(null, new[] { "tasaGlobalParticipacion" }));

        Assert.Empty(plan.MedidasSolicitadas);
        Assert.Equal(new[] { "pea", "pet" }, plan.MedidasConsultadas.Select(m => m.Clave).OrderBy(c => c));
    }

    [Fact]
    public void Una_medida_pedida_y_usada_por_un_indicador_se_calcula_una_sola_vez()
    {
        var plan = Validador.Validar(new SolicitudConsulta(new[] { "pea" }, new[] { "tasaGlobalParticipacion" }));
        Assert.Equal(2, plan.MedidasConsultadas.Count);
    }

    [Fact]
    public void Sin_medidas_ni_indicadores_se_rechaza()
    {
        Assert.Contains(Errores(new SolicitudConsulta()), e => e.Campo == "medidas");
    }

    [Fact]
    public void Una_solicitud_nula_se_rechaza()
    {
        Assert.Single(Errores(null));
    }

    [Theory]
    [InlineData("medidaInventada")]
    [InlineData("PERSONAS")]
    [InlineData("")]
    [InlineData("personas; DROP TABLE hechos.CensoPoblacion")]
    public void Una_medida_que_no_esta_en_el_catalogo_se_rechaza(string clave)
    {
        Assert.Contains(Errores(new SolicitudConsulta(new[] { clave })), e => e.Campo == "medidas[0]");
    }

    [Fact]
    public void Una_medida_o_un_indicador_repetido_se_rechaza()
    {
        Assert.Contains(Errores(new SolicitudConsulta(new[] { "personas", "personas" })), e => e.Campo == "medidas[1]");
        Assert.Contains(Errores(new SolicitudConsulta(null, new[] { "indiceMasculinidad", "indiceMasculinidad" })), e => e.Campo == "indicadores[1]");
    }

    [Fact]
    public void No_se_pueden_mezclar_medidas_de_hechos_distintos()
    {
        var errores = Errores(new SolicitudConsulta(new[] { "personas", "hogares" }));
        Assert.Contains(errores, e => e.Mensaje.Contains("mismo hecho"));
    }

    [Fact]
    public void Un_nivel_inexistente_o_no_disponible_para_el_hecho_se_rechaza()
    {
        Assert.Contains(Errores(new SolicitudConsulta(new[] { "personas" }, null, new[] { "nivelInventado" })), e => e.Campo == "dimensiones[0]");
        // 'tenenciaVivienda' es del hogar; el emigrante solo llega al hogar por 'via hogar' y esta dimension si lo permite,
        // pero 'esAlfabeta' solo existe para personas.
        Assert.Contains(Errores(new SolicitudConsulta(new[] { "emigrantes" }, null, new[] { "esAlfabeta" })), e => e.Mensaje.Contains("no esta disponible"));
    }

    [Fact]
    public void Un_nivel_repetido_se_rechaza()
    {
        Assert.Contains(Errores(new SolicitudConsulta(new[] { "personas" }, null, new[] { "sexo", "sexo" })), e => e.Campo == "dimensiones[1]");
    }

    [Fact]
    public void Se_puede_agrupar_por_varios_niveles_de_la_misma_jerarquia()
    {
        var plan = Validador.Validar(new SolicitudConsulta(new[] { "personas" }, null, new[] { "departamento", "municipio" }));
        Assert.Equal(2, plan.Agrupaciones.Count);
    }

    [Fact]
    public void Los_limites_de_tamano_se_hacen_cumplir()
    {
        var muchos = Enumerable.Range(0, ValidadorSolicitud.MaxDimensiones + 1).Select(i => "sexo").ToArray();
        Assert.Contains(Errores(new SolicitudConsulta(new[] { "personas" }, null, muchos)), e => e.Campo == "dimensiones");

        var filtros = Enumerable.Range(0, ValidadorSolicitud.MaxFiltros + 1).Select(_ => new FiltroSolicitud("sexo", "Igual", new object?[] { 1 })).ToArray();
        Assert.Contains(Errores(new SolicitudConsulta(new[] { "personas" }, Filtros: filtros)), e => e.Campo == "filtros");

        var medidas = Enumerable.Range(0, ValidadorSolicitud.MaxMedidasEIndicadores + 1).Select(i => $"m{i}").ToArray();
        Assert.Contains(Errores(new SolicitudConsulta(medidas)), e => e.Campo == "medidas");
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-5)]
    [InlineData(ValidadorSolicitud.LimiteMaximo + 1)]
    public void Un_limite_fuera_de_rango_se_rechaza(int limite)
    {
        Assert.Contains(Errores(new SolicitudConsulta(new[] { "personas" }, Limite: limite)), e => e.Campo == "limite");
    }

    [Fact]
    public void Un_filtro_valido_normaliza_los_valores_segun_el_tipo_del_nivel()
    {
        var plan = Validador.Validar(Con(new FiltroSolicitud("departamento", "en", new object?[] { 1, 2L })));
        var filtro = Assert.Single(plan.Filtros);
        Assert.Equal(OperadorFiltro.En, filtro.Operador);
        Assert.All(filtro.Valores, v => Assert.IsType<long>(v));
    }

    [Fact]
    public void Los_valores_que_llegan_como_json_se_normalizan()
    {
        using var documento = JsonDocument.Parse("""{"n": 5, "t": "0-14"}""");
        var numero = documento.RootElement.GetProperty("n").Clone();
        var texto = documento.RootElement.GetProperty("t").Clone();

        var plan = Validador.Validar(new SolicitudConsulta(new[] { "personas" }, Filtros: new[]
        {
            new FiltroSolicitud("edad", "Igual", new object?[] { numero }),
            new FiltroSolicitud("grupoAmplio", "Igual", new object?[] { texto }),
        }));

        Assert.Equal(5L, plan.Filtros[0].Valores[0]);
        Assert.Equal("0-14", plan.Filtros[1].Valores[0]);
    }

    [Theory]
    [InlineData("Igual", new object[] { 1, 2 })]
    [InlineData("Entre", new object[] { 1 })]
    [InlineData("En", new object[0])]
    [InlineData("MayorOIgual", new object[] { 1, 2 })]
    public void La_cantidad_de_valores_debe_corresponder_al_operador(string operador, object[] valores)
    {
        Assert.Contains(Errores(Con(new FiltroSolicitud("edad", operador, valores.Cast<object?>().ToArray()))), e => e.Campo.EndsWith("valores"));
    }

    [Fact]
    public void Un_filtro_numerico_rechaza_texto_y_un_filtro_de_texto_rechaza_numeros()
    {
        Assert.Contains(Errores(Con(new FiltroSolicitud("edad", "Igual", new object?[] { "15" }))), e => e.Campo == "filtros[0].valores[0]");
        Assert.Contains(Errores(Con(new FiltroSolicitud("grupoAmplio", "Igual", new object?[] { 15 }))), e => e.Campo == "filtros[0].valores[0]");
    }

    [Fact]
    public void Un_filtro_de_texto_no_admite_operadores_de_orden()
    {
        Assert.Contains(Errores(Con(new FiltroSolicitud("grupoAmplio", "MayorOIgual", new object?[] { "15-64" }))), e => e.Campo == "filtros[0].operador");
    }

    [Fact]
    public void En_el_operador_Entre_el_primer_valor_no_puede_superar_al_segundo()
    {
        Assert.Contains(Errores(Con(new FiltroSolicitud("edad", "Entre", new object?[] { 30, 10 }))), e => e.Campo == "filtros[0].valores");
    }

    [Theory]
    [InlineData("1")]
    [InlineData("Como")]
    [InlineData("Igual; DROP TABLE")]
    [InlineData("")]
    [InlineData("   ")]
    public void Un_operador_desconocido_o_numerico_se_rechaza(string operador)
    {
        Assert.Contains(Errores(Con(new FiltroSolicitud("edad", operador, new object?[] { 1 }))), e => e.Campo == "filtros[0].operador");
    }

    [Fact]
    public void Un_texto_de_filtro_demasiado_largo_o_con_caracteres_de_control_se_rechaza()
    {
        var largo = new string('a', ValidadorSolicitud.MaxLongitudTexto + 1);
        Assert.Contains(Errores(Con(new FiltroSolicitud("grupoAmplio", "Igual", new object?[] { largo }))), e => e.Campo.StartsWith("filtros[0].valores"));
        Assert.Contains(Errores(Con(new FiltroSolicitud("grupoAmplio", "Igual", new object?[] { "0-14\u0000" }))), e => e.Campo.StartsWith("filtros[0].valores"));
    }

    [Fact]
    public void Demasiados_valores_en_un_filtro_En_se_rechazan()
    {
        var valores = Enumerable.Range(0, ValidadorSolicitud.MaxValoresPorFiltro + 1).Select(i => (object?)i).ToArray();
        Assert.Contains(Errores(Con(new FiltroSolicitud("edad", "En", valores))), e => e.Campo == "filtros[0].valores");
    }

    [Fact]
    public void Los_mensajes_de_error_no_repiten_texto_de_usuario_sin_recortar_ni_limpiar()
    {
        var hostil = new string('x', 500) + "\r\n<script>";
        var errores = Errores(new SolicitudConsulta(new[] { hostil }));
        Assert.All(errores, e =>
        {
            Assert.True(e.Mensaje.Length < 200);
            Assert.DoesNotContain('\n', e.Mensaje);
            Assert.DoesNotContain("<script>", e.Mensaje);
        });
    }

    [Fact]
    public void Un_filtro_nulo_dentro_de_la_lista_se_rechaza_sin_fallar()
    {
        Assert.Contains(Errores(new SolicitudConsulta(new[] { "personas" }, Filtros: new FiltroSolicitud[] { null! })), e => e.Campo == "filtros[0]");
    }

    [Fact]
    public void Se_acumulan_todos_los_errores_de_una_solicitud()
    {
        var errores = Errores(new SolicitudConsulta(new[] { "personas" }, null, new[] { "x" }, new[] { new FiltroSolicitud("y", "Igual", new object?[] { 1 }) }, Limite: 0));
        Assert.True(errores.Count >= 3);
    }
}
