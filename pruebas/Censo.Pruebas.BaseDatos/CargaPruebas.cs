using Censo.Pruebas.BaseDatos.Ayudantes;
using static Censo.Pruebas.BaseDatos.Ayudantes.ConexionPruebas;
using static Censo.Pruebas.BaseDatos.Ayudantes.ValoresEsperados;

namespace Censo.Pruebas.BaseDatos;

/// <summary>Filas cargadas e integridad de la jerarquia vivienda, hogar, persona y emigrante.</summary>
[Trait("Categoria", "Carga")]
public class CargaPruebas
{
    public static IEnumerable<object[]> FilasDeLosHechos() => FilasPorHecho.Select(f => new object[] { f.Key, f.Value });

    public static IEnumerable<object[]> MiembrosDeLasDimensiones() => MiembrosPorDimension.Select(d => new object[] { d.Key, d.Value });

    [Theory]
    [MemberData(nameof(FilasDeLosHechos))]
    public void Cada_tabla_de_hechos_tiene_las_filas_de_su_archivo_del_INE(string tabla, long esperadas)
    {
        Assert.Equal(esperadas, Escalar<long>($"SELECT COUNT_BIG(*) FROM hechos.{tabla}"));
    }

    [Theory]
    [MemberData(nameof(MiembrosDeLasDimensiones))]
    public void Cada_dimension_tiene_el_numero_esperado_de_miembros(string dimension, long esperados)
    {
        Assert.Equal(esperados, Escalar<long>($"SELECT COUNT_BIG(*) FROM dim.{dimension}"));
    }

    [Fact]
    public void Ninguna_llave_foranea_deja_filas_huerfanas()
    {
        var huerfanas = new List<string>();
        foreach (var f in Metadatos.LlavesForaneas())
        {
            var n = Escalar<long>(
                $@"SELECT COUNT_BIG(*) FROM [{f.EsquemaHijo}].[{f.TablaHijo}] h
                   WHERE h.[{f.ColumnaHijo}] IS NOT NULL
                     AND NOT EXISTS (SELECT 1 FROM [{f.EsquemaPadre}].[{f.TablaPadre}] p WHERE p.[{f.ColumnaPadre}] = h.[{f.ColumnaHijo}])");
            if (n > 0)
                huerfanas.Add($"{f.Nombre}: {n:N0} filas");
        }
        Assert.Empty(huerfanas);
    }

    [Fact]
    public void Las_personas_sin_hogar_son_43752()
    {
        Assert.Equal(PersonasSinHogar, Escalar<long>("SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion WHERE HogarId IS NULL"));
    }

    [Fact]
    public void Toda_persona_sin_hogar_vive_en_vivienda_colectiva_o_sin_vivienda()
    {
        var otras = Escalar<long>(
            @"SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion p
              JOIN hechos.CensoVivienda v ON v.ViviendaId = p.ViviendaId
              JOIN dim.TipoVivienda t ON t.TipoViviendaId = v.TipoViviendaId
              WHERE p.HogarId IS NULL AND t.CodigoTipoVivienda NOT IN (10, 11)");
        Assert.Equal(0, otras);
    }

    [Fact]
    public void Ninguna_persona_con_hogar_vive_en_vivienda_colectiva_o_sin_vivienda()
    {
        var colectivas = Escalar<long>(
            @"SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion p
              JOIN hechos.CensoVivienda v ON v.ViviendaId = p.ViviendaId
              JOIN dim.TipoVivienda t ON t.TipoViviendaId = v.TipoViviendaId
              WHERE p.HogarId IS NOT NULL AND t.CodigoTipoVivienda IN (10, 11)");
        Assert.Equal(0, colectivas);
    }

    [Fact]
    public void Las_viviendas_sin_hogar_son_763836_las_no_ocupadas_mas_las_colectivas_o_sin_vivienda()
    {
        const string sinHogar = "NOT EXISTS (SELECT 1 FROM hechos.CensoHogar h WHERE h.ViviendaId = v.ViviendaId)";

        Assert.Equal(ViviendasSinHogar, Escalar<long>($"SELECT COUNT_BIG(*) FROM hechos.CensoVivienda v WHERE {sinHogar}"));

        var noOcupadas = Escalar<long>(
            $@"SELECT COUNT_BIG(*) FROM hechos.CensoVivienda v
               JOIN dim.CondicionVivienda c ON c.CondicionViviendaId = v.CondicionViviendaId
               WHERE c.CodigoCondicionVivienda IN (2, 3, 4) AND {sinHogar}");
        var colectivasOSinVivienda = Escalar<long>(
            $@"SELECT COUNT_BIG(*) FROM hechos.CensoVivienda v
               JOIN dim.TipoVivienda t ON t.TipoViviendaId = v.TipoViviendaId
               WHERE t.CodigoTipoVivienda IN (10, 11) AND {sinHogar}");
        var ocupadasSinHogar = Escalar<long>(
            $@"SELECT COUNT_BIG(*) FROM hechos.CensoVivienda v
               JOIN dim.CondicionVivienda c ON c.CondicionViviendaId = v.CondicionViviendaId
               WHERE c.CodigoCondicionVivienda = 1 AND {sinHogar}");

        Assert.Equal(762_447, noOcupadas);
        Assert.Equal(1_389, colectivasOSinVivienda);
        Assert.Equal(0, ocupadasSinHogar);
    }

    [Fact]
    public void El_lugar_poblado_copiado_a_hogar_y_persona_coincide_con_el_de_su_vivienda()
    {
        var hogares = Escalar<long>(
            @"SELECT COUNT_BIG(*) FROM hechos.CensoHogar h
              JOIN hechos.CensoVivienda v ON v.ViviendaId = h.ViviendaId WHERE h.LugarPobladoId <> v.LugarPobladoId");
        var personas = Escalar<long>(
            @"SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion p
              JOIN hechos.CensoVivienda v ON v.ViviendaId = p.ViviendaId WHERE p.LugarPobladoId <> v.LugarPobladoId");
        var emigrantes = Escalar<long>(
            @"SELECT COUNT_BIG(*) FROM hechos.CensoMigracion m
              JOIN hechos.CensoHogar h ON h.HogarId = m.HogarId WHERE m.LugarPobladoId <> h.LugarPobladoId");

        Assert.Equal(0, hogares);
        Assert.Equal(0, personas);
        Assert.Equal(0, emigrantes);
    }

    [Fact]
    public void El_hogar_de_cada_persona_pertenece_a_la_misma_vivienda_que_la_persona()
    {
        var distintas = Escalar<long>(
            @"SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion p
              JOIN hechos.CensoHogar h ON h.HogarId = p.HogarId WHERE h.ViviendaId <> p.ViviendaId");
        Assert.Equal(0, distintas);
    }

    [Fact]
    public void El_total_de_personas_de_cada_hogar_coincide_con_el_conteo_de_sus_personas()
    {
        var diferencias = Escalar<long>(
            @"SELECT COUNT_BIG(*) FROM hechos.CensoHogar h
              LEFT JOIN (SELECT HogarId, COUNT(*) AS n FROM hechos.CensoPoblacion WHERE HogarId IS NOT NULL GROUP BY HogarId) p
                     ON p.HogarId = h.HogarId
              WHERE h.TotalPersonas <> ISNULL(p.n, 0)");
        Assert.Equal(0, diferencias);
    }

    [Fact]
    public void Los_emigrantes_con_detalle_de_los_hogares_suman_los_registros_de_migracion()
    {
        var conDetalle = Escalar<long>("SELECT ISNULL(SUM(CAST(TotalEmigrantesConDetalle AS BIGINT)), 0) FROM hechos.CensoHogar");
        Assert.Equal(Emigrantes, conDetalle);
    }

    [Fact]
    public void Cada_hogar_con_emigrantes_con_detalle_tiene_esa_cantidad_de_registros_de_migracion()
    {
        var diferencias = Escalar<long>(
            @"SELECT COUNT_BIG(*) FROM hechos.CensoHogar h
              LEFT JOIN (SELECT HogarId, COUNT(*) AS n FROM hechos.CensoMigracion GROUP BY HogarId) m ON m.HogarId = h.HogarId
              WHERE ISNULL(h.TotalEmigrantesConDetalle, 0) <> ISNULL(m.n, 0)");
        Assert.Equal(0, diferencias);
    }
}
