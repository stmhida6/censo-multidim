using Censo.Pruebas.BaseDatos.Ayudantes;
using static Censo.Pruebas.BaseDatos.Ayudantes.ConexionPruebas;

namespace Censo.Pruebas.BaseDatos;

/// <summary>
/// Compara el mismo agregado calculado sobre la copia cruda de los microdatos (stage) y sobre el modelo en estrella,
/// para demostrar que la transformacion no perdio, duplico ni reasigno registros.
/// </summary>
[Trait("Categoria", "Consistencia")]
public class ConsistenciaStagePruebas
{
    private static void Iguales(string sqlStage, string sqlModelo)
    {
        var stage = Consultar<Grupo>(sqlStage).ToDictionary(g => g.Clave, g => g.N);
        var modelo = Consultar<Grupo>(sqlModelo).ToDictionary(g => g.Clave, g => g.N);

        var diferencias = stage.Keys.Union(modelo.Keys)
            .Where(k => stage.GetValueOrDefault(k) != modelo.GetValueOrDefault(k))
            .OrderBy(k => k, StringComparer.Ordinal)
            .Select(k => $"{k}: stage={stage.GetValueOrDefault(k):N0}, modelo={modelo.GetValueOrDefault(k):N0}")
            .Take(10)
            .ToList();

        Assert.True(stage.Count > 0, "La consulta sobre stage no devolvio grupos: verifique que stage este cargada.");
        Assert.Empty(diferencias);
    }

    [Fact]
    public void La_poblacion_por_departamento_coincide()
    {
        Iguales(
            @"SELECT CAST(LUGAR_POBLADO / 100000 AS VARCHAR(10)) AS Clave, COUNT_BIG(*) AS N
              FROM stage.Persona GROUP BY LUGAR_POBLADO / 100000",
            @"SELECT CAST(d.CodigoDepartamento AS VARCHAR(10)) AS Clave, COUNT_BIG(*) AS N
              FROM hechos.CensoPoblacion p
              JOIN dim.LugarPoblado l ON l.LugarPobladoId = p.LugarPobladoId
              JOIN dim.Municipio m ON m.MunicipioId = l.MunicipioId
              JOIN dim.Departamento d ON d.DepartamentoId = m.DepartamentoId
              GROUP BY d.CodigoDepartamento");
    }

    [Fact]
    public void La_poblacion_por_municipio_de_residencia_coincide()
    {
        Iguales(
            @"SELECT CAST(LUGAR_POBLADO / 1000 AS VARCHAR(10)) AS Clave, COUNT_BIG(*) AS N
              FROM stage.Persona GROUP BY LUGAR_POBLADO / 1000",
            @"SELECT CAST(m.CodigoMunicipio AS VARCHAR(10)) AS Clave, COUNT_BIG(*) AS N
              FROM hechos.CensoPoblacion p
              JOIN dim.LugarPoblado l ON l.LugarPobladoId = p.LugarPobladoId
              JOIN dim.Municipio m ON m.MunicipioId = l.MunicipioId
              GROUP BY m.CodigoMunicipio");
    }

    [Fact]
    public void La_poblacion_por_sexo_y_edad_coincide()
    {
        Iguales(
            "SELECT CONCAT(PCP6, '|', PCP7) AS Clave, COUNT_BIG(*) AS N FROM stage.Persona GROUP BY PCP6, PCP7",
            @"SELECT CONCAT(s.CodigoSexo, '|', p.EdadId) AS Clave, COUNT_BIG(*) AS N
              FROM hechos.CensoPoblacion p JOIN dim.Sexo s ON s.SexoId = p.SexoId GROUP BY s.CodigoSexo, p.EdadId");
    }

    [Fact]
    public void La_poblacion_por_pueblo_y_nivel_de_estudios_coincide()
    {
        Iguales(
            "SELECT CONCAT(PCP12, '|', ISNULL(CAST(NIVGRADO AS VARCHAR(10)), 'nulo')) AS Clave, COUNT_BIG(*) AS N FROM stage.Persona GROUP BY PCP12, NIVGRADO",
            @"SELECT CONCAT(d.CodigoPueblo, '|', ISNULL(CAST(n.CodigoNivelGrado AS VARCHAR(10)), 'nulo')) AS Clave, COUNT_BIG(*) AS N
              FROM hechos.CensoPoblacion p
              JOIN dim.Pueblo d ON d.PuebloId = p.PuebloId
              LEFT JOIN dim.NivelGrado n ON n.NivelGradoId = p.NivelGradoId
              GROUP BY d.CodigoPueblo, n.CodigoNivelGrado");
    }

    [Fact]
    public void La_poblacion_por_municipio_de_nacimiento_coincide()
    {
        Iguales(
            "SELECT ISNULL(CAST(LUGNACGEO AS VARCHAR(10)), 'nulo') AS Clave, COUNT_BIG(*) AS N FROM stage.Persona GROUP BY LUGNACGEO",
            @"SELECT ISNULL(CAST(m.CodigoMunicipio AS VARCHAR(10)), 'nulo') AS Clave, COUNT_BIG(*) AS N
              FROM hechos.CensoPoblacion p LEFT JOIN dim.Municipio m ON m.MunicipioId = p.MunicipioNacimientoId GROUP BY m.CodigoMunicipio");
    }

    [Fact]
    public void Las_personas_por_ocupacion_y_rama_de_actividad_coinciden()
    {
        Iguales(
            @"SELECT CONCAT(ISNULL(CAST(PCP30_2D AS VARCHAR(10)), 'nulo'), '|', ISNULL(CAST(PCP32_2D AS VARCHAR(10)), 'nulo')) AS Clave, COUNT_BIG(*) AS N
              FROM stage.Persona GROUP BY PCP30_2D, PCP32_2D",
            @"SELECT CONCAT(ISNULL(CAST(o.CodigoOcupacion AS VARCHAR(10)), 'nulo'), '|', ISNULL(CAST(r.CodigoRamaActividad AS VARCHAR(10)), 'nulo')) AS Clave, COUNT_BIG(*) AS N
              FROM hechos.CensoPoblacion p
              LEFT JOIN dim.Ocupacion o ON o.OcupacionId = p.OcupacionId
              LEFT JOIN dim.RamaActividad r ON r.RamaActividadId = p.RamaActividadId
              GROUP BY o.CodigoOcupacion, r.CodigoRamaActividad");
    }

    [Fact]
    public void Los_hijos_nacidos_vivos_coinciden_tras_convertir_el_codigo_99_a_nulo()
    {
        Iguales(
            "SELECT ISNULL(CAST(NULLIF(PCP35_A, 99) AS VARCHAR(10)), 'nulo') AS Clave, COUNT_BIG(*) AS N FROM stage.Persona GROUP BY NULLIF(PCP35_A, 99)",
            "SELECT ISNULL(CAST(HijosNacidosVivos AS VARCHAR(10)), 'nulo') AS Clave, COUNT_BIG(*) AS N FROM hechos.CensoPoblacion GROUP BY HijosNacidosVivos");
    }

    [Fact]
    public void Las_respuestas_Si_No_se_convirtieron_a_bit_sin_perder_filas()
    {
        Iguales(
            "SELECT CONCAT(ISNULL(CAST(PCP18 AS VARCHAR(10)), 'nulo'), '|', ISNULL(CAST(PCP22 AS VARCHAR(10)), 'nulo')) AS Clave, COUNT_BIG(*) AS N FROM stage.Persona GROUP BY PCP18, PCP22",
            @"SELECT CONCAT(ISNULL(CAST(CASE EsEstudiante WHEN 1 THEN 1 WHEN 0 THEN 2 END AS VARCHAR(10)), 'nulo'), '|',
                            ISNULL(CAST(CASE EsAlfabeta WHEN 1 THEN 1 WHEN 0 THEN 2 END AS VARCHAR(10)), 'nulo')) AS Clave, COUNT_BIG(*) AS N
              FROM hechos.CensoPoblacion GROUP BY EsEstudiante, EsAlfabeta");
    }

    [Fact]
    public void Las_viviendas_por_tipo_y_area_coinciden()
    {
        Iguales(
            "SELECT CONCAT(PCV1, '|', AREA) AS Clave, COUNT_BIG(*) AS N FROM stage.Vivienda GROUP BY PCV1, AREA",
            @"SELECT CONCAT(t.CodigoTipoVivienda, '|', CASE v.EsUrbano WHEN 1 THEN 1 ELSE 2 END) AS Clave, COUNT_BIG(*) AS N
              FROM hechos.CensoVivienda v JOIN dim.TipoVivienda t ON t.TipoViviendaId = v.TipoViviendaId GROUP BY t.CodigoTipoVivienda, v.EsUrbano");
    }

    [Fact]
    public void Las_viviendas_sin_coordenadas_coinciden()
    {
        Iguales(
            "SELECT CASE WHEN Long IS NULL THEN 'sin' ELSE 'con' END AS Clave, COUNT_BIG(*) AS N FROM stage.Vivienda GROUP BY CASE WHEN Long IS NULL THEN 'sin' ELSE 'con' END",
            "SELECT CASE WHEN Longitud IS NULL THEN 'sin' ELSE 'con' END AS Clave, COUNT_BIG(*) AS N FROM hechos.CensoVivienda GROUP BY CASE WHEN Longitud IS NULL THEN 'sin' ELSE 'con' END");
    }

    [Fact]
    public void Los_hogares_por_fuente_de_agua_y_tenencia_coinciden()
    {
        Iguales(
            "SELECT CONCAT(PCH4, '|', PCH1) AS Clave, COUNT_BIG(*) AS N FROM stage.Hogar GROUP BY PCH4, PCH1",
            @"SELECT CONCAT(a.CodigoFuenteAgua, '|', t.CodigoTenenciaVivienda) AS Clave, COUNT_BIG(*) AS N
              FROM hechos.CensoHogar h
              JOIN dim.FuenteAgua a ON a.FuenteAguaId = h.FuenteAguaId
              JOIN dim.TenenciaVivienda t ON t.TenenciaViviendaId = h.TenenciaViviendaId
              GROUP BY a.CodigoFuenteAgua, t.CodigoTenenciaVivienda");
    }

    [Fact]
    public void Los_hogares_con_internet_y_remesas_coinciden()
    {
        Iguales(
            "SELECT CONCAT(PCH9_I, '|', PCH15) AS Clave, COUNT_BIG(*) AS N FROM stage.Hogar GROUP BY PCH9_I, PCH15",
            @"SELECT CONCAT(CASE TieneInternet WHEN 1 THEN 1 ELSE 2 END, '|', CASE TieneRemesas WHEN 1 THEN 1 ELSE 2 END) AS Clave, COUNT_BIG(*) AS N
              FROM hechos.CensoHogar GROUP BY TieneInternet, TieneRemesas");
    }

    [Fact]
    public void Los_emigrantes_por_sexo_edad_y_anio_de_salida_coinciden()
    {
        Iguales(
            "SELECT CONCAT(PEI3, '|', PEI4, '|', ISNULL(CAST(NULLIF(PEI5, 9999) AS VARCHAR(10)), 'nulo')) AS Clave, COUNT_BIG(*) AS N FROM stage.Migracion GROUP BY PEI3, PEI4, NULLIF(PEI5, 9999)",
            @"SELECT CONCAT(s.CodigoSexo, '|', m.EdadId, '|', ISNULL(CAST(m.AnioSalida AS VARCHAR(10)), 'nulo')) AS Clave, COUNT_BIG(*) AS N
              FROM hechos.CensoMigracion m JOIN dim.Sexo s ON s.SexoId = m.SexoId GROUP BY s.CodigoSexo, m.EdadId, m.AnioSalida");
    }
}
