using System.Text.RegularExpressions;
using Censo.Aplicacion.Catalogo;
using Censo.Aplicacion.Consultas;
using Censo.Dominio.Consultas;

namespace Censo.Pruebas.Aplicacion;

/// <summary>Etapa de construccion: el SQL sale solo del catalogo y los valores viajan como parametros.</summary>
[Trait("Categoria", "Constructor")]
public class ConstructorPruebas
{
    private static readonly CatalogoCenso Catalogo = new();
    private static readonly ValidadorSolicitud Validador = new(Catalogo);
    private static readonly ConstructorConsultaSql Constructor = new(Catalogo);

    private static ConsultaConstruida Construir(SolicitudConsulta solicitud) => Constructor.Construir(Validador.Validar(solicitud));

    private static int Ocurrencias(string texto, string buscado) => Regex.Matches(texto, Regex.Escape(buscado)).Count;

    [Fact]
    public void Una_agregacion_por_departamento_une_la_jerarquia_territorial_agrupa_y_ordena()
    {
        var sql = Construir(new SolicitudConsulta(new[] { "personas" }, null, new[] { "departamento" })).Sql.Texto;

        Assert.StartsWith("SELECT TOP (@limite)", sql);
        Assert.Contains("FROM hechos.CensoPoblacion AS f", sql);
        Assert.Contains("LEFT JOIN dim.LugarPoblado AS j0 ON j0.LugarPobladoId = f.LugarPobladoId", sql);
        Assert.Contains("LEFT JOIN dim.Municipio AS j1 ON j1.MunicipioId = j0.MunicipioId", sql);
        Assert.Contains("LEFT JOIN dim.Departamento AS j2 ON j2.DepartamentoId = j1.DepartamentoId", sql);
        Assert.Contains("COUNT_BIG(*) AS [personas]", sql);
        Assert.Contains("GROUP BY j2.NombreDepartamento, j2.CodigoDepartamento", sql);
        Assert.Contains("ORDER BY j2.CodigoDepartamento", sql);
    }

    [Fact]
    public void Agrupar_por_municipio_no_une_la_tabla_de_departamentos()
    {
        var sql = Construir(new SolicitudConsulta(new[] { "personas" }, null, new[] { "municipio" })).Sql.Texto;
        Assert.Contains("dim.Municipio", sql);
        Assert.DoesNotContain("dim.Departamento", sql);
    }

    [Fact]
    public void Las_columnas_salen_en_el_orden_dimensiones_con_su_codigo_y_luego_medidas()
    {
        var columnas = Construir(new SolicitudConsulta(new[] { "hombres", "mujeres" }, null, new[] { "departamento", "grupoQuinquenal" })).Columnas;

        Assert.Equal(new[] { "departamento", "departamento_codigo", "grupoQuinquenal", "hombres", "mujeres" }, columnas.Select(c => c.Alias));
        Assert.Equal(new[] { "dimension", "dimensionCodigo", "dimension", "medida", "medida" }, columnas.Select(c => c.Rol));
    }

    [Fact]
    public void Una_agregacion_sin_dimensiones_no_agrupa_ni_ordena()
    {
        var sql = Construir(new SolicitudConsulta(new[] { "personas" })).Sql.Texto;
        Assert.DoesNotContain("GROUP BY", sql);
        Assert.DoesNotContain("ORDER BY", sql);
    }

    [Fact]
    public void El_limite_se_envia_como_parametro_con_una_fila_mas_para_detectar_el_truncamiento()
    {
        var consulta = Construir(new SolicitudConsulta(new[] { "personas" }, Limite: 50)).Sql;
        Assert.Equal(51L, consulta.Parametros["limite"]);
    }

    [Fact]
    public void Las_medidas_con_condiciones_agregan_las_uniones_que_necesitan()
    {
        var sql = Construir(new SolicitudConsulta(new[] { "pea" })).Sql.Texto;

        Assert.Contains("SUM(CASE WHEN", sql);
        Assert.Contains("dim.Edad", sql);
        Assert.Contains("dim.CondicionActividad", sql);
        Assert.Equal(1, Ocurrencias(sql, "LEFT JOIN dim.Edad"));
    }

    [Fact]
    public void Una_dimension_usada_para_agrupar_y_para_una_condicion_se_une_una_sola_vez()
    {
        var sql = Construir(new SolicitudConsulta(new[] { "hombres" }, null, new[] { "sexo" })).Sql.Texto;
        Assert.Equal(1, Ocurrencias(sql, "LEFT JOIN dim.Sexo"));
    }

    [Fact]
    public void Las_dimensiones_del_hogar_consultadas_desde_la_persona_comparten_una_sola_union_con_el_hogar()
    {
        var sql = Construir(new SolicitudConsulta(new[] { "personas" }, null, new[] { "fuenteAgua", "tenenciaVivienda", "tieneInternet" })).Sql.Texto;

        Assert.Equal(1, Ocurrencias(sql, "LEFT JOIN hechos.CensoHogar"));
        Assert.Contains("dim.FuenteAgua", sql);
        Assert.Contains("dim.TenenciaVivienda", sql);
    }

    [Fact]
    public void El_area_urbana_llega_desde_la_persona_por_la_vivienda_y_desde_el_emigrante_por_el_hogar_y_la_vivienda()
    {
        var persona = Construir(new SolicitudConsulta(new[] { "personas" }, null, new[] { "esUrbano" })).Sql.Texto;
        Assert.Equal(1, Ocurrencias(persona, "LEFT JOIN hechos.CensoVivienda"));
        Assert.DoesNotContain("CensoHogar", persona);

        var emigrante = Construir(new SolicitudConsulta(new[] { "emigrantes" }, null, new[] { "esUrbano" })).Sql.Texto;
        Assert.Contains("LEFT JOIN hechos.CensoHogar", emigrante);
        Assert.Contains("LEFT JOIN hechos.CensoVivienda", emigrante);
    }

    [Fact]
    public void Las_dimensiones_booleanas_del_propio_hecho_no_agregan_uniones()
    {
        var sql = Construir(new SolicitudConsulta(new[] { "personas" }, null, new[] { "esAlfabeta" })).Sql.Texto;
        Assert.DoesNotContain("JOIN", sql);
        Assert.Contains("f.EsAlfabeta", sql);
    }

    [Fact]
    public void Un_nivel_con_orden_propio_lo_agrega_al_group_by_y_al_order_by()
    {
        var sql = Construir(new SolicitudConsulta(new[] { "personas" }, null, new[] { "grupoQuinquenal" })).Sql.Texto;
        Assert.Contains("GROUP BY j0.GrupoQuinquenal, j0.OrdenGrupoQuinquenal", sql);
        Assert.Contains("ORDER BY j0.OrdenGrupoQuinquenal", sql);
    }

    [Fact]
    public void Los_valores_de_los_filtros_viajan_como_parametros_y_nunca_dentro_del_sql()
    {
        var construida = Construir(new SolicitudConsulta(new[] { "personas" }, Filtros: new[]
        {
            new FiltroSolicitud("sexo", "Igual", new object?[] { 2 }),
            new FiltroSolicitud("pueblo", "En", new object?[] { 1, 5 }),
            new FiltroSolicitud("edad", "Entre", new object?[] { 15, 64 }),
            new FiltroSolicitud("grupoAmplio", "Distinto", new object?[] { "65 y mas" }),
        }));

        Assert.Contains("= @p0", construida.Sql.Texto);
        Assert.Contains("IN (@p1, @p2)", construida.Sql.Texto);
        Assert.Contains("BETWEEN @p3 AND @p4", construida.Sql.Texto);
        Assert.Contains("<> @p5", construida.Sql.Texto);
        Assert.DoesNotContain("65 y mas", construida.Sql.Texto);
        Assert.Equal(new object?[] { 2L, 1L, 5L, 15L, 64L, "65 y mas" }, new object?[]
        {
            construida.Sql.Parametros["p0"], construida.Sql.Parametros["p1"], construida.Sql.Parametros["p2"],
            construida.Sql.Parametros["p3"], construida.Sql.Parametros["p4"], construida.Sql.Parametros["p5"],
        });
    }

    [Theory]
    [InlineData("'; DROP TABLE hechos.CensoPoblacion; --")]
    [InlineData("0-14' OR '1'='1")]
    [InlineData("1; EXEC xp_cmdshell 'dir'")]
    [InlineData("\" OR 1=1 --")]
    [InlineData("N'x'); DELETE FROM dim.Sexo; --")]
    public void Un_texto_hostil_en_un_filtro_queda_como_parametro_y_no_altera_el_sql(string hostil)
    {
        var construida = Construir(new SolicitudConsulta(new[] { "personas" }, Filtros: new[]
        {
            new FiltroSolicitud("grupoAmplio", "Igual", new object?[] { hostil }),
        }));

        Assert.DoesNotContain(hostil, construida.Sql.Texto);
        Assert.DoesNotContain("DROP", construida.Sql.Texto);
        Assert.DoesNotContain("DELETE", construida.Sql.Texto);
        Assert.DoesNotContain("xp_cmdshell", construida.Sql.Texto);
        Assert.Equal(hostil, construida.Sql.Parametros["p0"]);
    }

    [Fact]
    public void Un_nombre_de_nivel_hostil_no_llega_nunca_al_sql_porque_el_validador_lo_rechaza()
    {
        var hostil = "sexo]; DROP TABLE dim.Sexo; --";
        Assert.Throws<SolicitudInvalidaException>(() => Construir(new SolicitudConsulta(new[] { "personas" }, null, new[] { hostil })));
        Assert.Throws<SolicitudInvalidaException>(() => Construir(new SolicitudConsulta(new[] { "personas" }, Filtros: new[] { new FiltroSolicitud(hostil, "Igual", new object?[] { 1 }) })));
    }

    [Fact]
    public void Todo_nivel_del_catalogo_genera_un_sql_sin_instrucciones_adicionales_ni_valores_incrustados()
    {
        var permitido = new Regex(@"^[A-Za-z0-9_\.\[\]\(\)\s,@=<>'\*\-]+$");
        foreach (var hecho in Catalogo.Hechos)
        {
            var medida = Catalogo.Medidas.First(m => m.HechoClave == hecho.Clave).Clave;
            foreach (var dimension in Catalogo.Dimensiones.Where(d => d.VinculoCon(hecho.Clave) is not null))
            {
                foreach (var nivel in dimension.Niveles)
                {
                    var sql = Construir(new SolicitudConsulta(new[] { medida }, null, new[] { nivel.Clave })).Sql.Texto;
                    Assert.Matches(permitido, sql);
                    Assert.DoesNotContain(";", sql);
                    Assert.DoesNotContain("--", sql);
                }
            }
        }
    }

    [Fact]
    public void Todo_indicador_del_catalogo_genera_su_numerador_y_su_denominador()
    {
        foreach (var indicador in Catalogo.Indicadores)
        {
            var columnas = Construir(new SolicitudConsulta(null, new[] { indicador.Clave })).Columnas.Select(c => c.Alias).ToList();
            Assert.Contains(indicador.NumeradorClave, columnas);
            Assert.Contains(indicador.DenominadorClave, columnas);
        }
    }
}
