using Censo.Pruebas.BaseDatos.Ayudantes;
using static Censo.Pruebas.BaseDatos.Ayudantes.ConexionPruebas;
using static Censo.Pruebas.BaseDatos.Ayudantes.ValoresEsperados;

namespace Censo.Pruebas.BaseDatos;

/// <summary>
/// Propiedades del analisis multidimensional que el motor de consultas dara por supuestas: agrupar por cualquier
/// dimension reparte todas las filas exactamente una vez, y unir un hecho con sus dimensiones no duplica ni pierde filas.
/// </summary>
[Trait("Categoria", "Estrella")]
public class ConsultasEstrellaPruebas
{
    [Fact]
    public void Agrupar_cada_hecho_por_cualquiera_de_sus_dimensiones_suma_el_total_de_filas()
    {
        var totales = FilasPorHecho.ToDictionary(f => f.Key, f => f.Value);
        var fallos = new List<string>();

        foreach (var f in Metadatos.LlavesForaneas().Where(f => f.EsquemaHijo == "hechos"))
        {
            var suma = Escalar<long>(
                $@"SELECT ISNULL(SUM(n), 0) FROM (
                       SELECT COUNT_BIG(*) AS n
                       FROM [hechos].[{f.TablaHijo}] h
                       LEFT JOIN [{f.EsquemaPadre}].[{f.TablaPadre}] p ON p.[{f.ColumnaPadre}] = h.[{f.ColumnaHijo}]
                       GROUP BY p.[{f.ColumnaPadre}]) x");
            if (suma != totales[f.TablaHijo])
                fallos.Add($"{f.TablaHijo}.{f.ColumnaHijo}: suma {suma:N0} frente a {totales[f.TablaHijo]:N0}");
        }

        Assert.Empty(fallos);
    }

    [Fact]
    public void Unir_la_poblacion_con_su_vivienda_y_su_hogar_no_cambia_el_numero_de_personas()
    {
        var personas = Escalar<long>(
            @"SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion p
              JOIN hechos.CensoVivienda v ON v.ViviendaId = p.ViviendaId
              LEFT JOIN hechos.CensoHogar h ON h.HogarId = p.HogarId");
        Assert.Equal(Personas, personas);
    }

    [Fact]
    public void Unir_la_poblacion_con_todas_sus_dimensiones_de_rol_no_cambia_el_numero_de_personas()
    {
        var personas = Escalar<long>(
            @"SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion p
              JOIN dim.Sexo s ON s.SexoId = p.SexoId
              JOIN dim.Edad e ON e.EdadId = p.EdadId
              JOIN dim.LugarPoblado l ON l.LugarPobladoId = p.LugarPobladoId
              JOIN dim.Municipio m ON m.MunicipioId = l.MunicipioId
              JOIN dim.Departamento d ON d.DepartamentoId = m.DepartamentoId
              LEFT JOIN dim.Municipio mn ON mn.MunicipioId = p.MunicipioNacimientoId
              LEFT JOIN dim.Municipio mt ON mt.MunicipioId = p.MunicipioTrabajoId
              LEFT JOIN dim.Pais pn ON pn.PaisId = p.PaisNacimientoId
              LEFT JOIN dim.Idioma i ON i.IdiomaId = p.IdiomaMaternoId");
        Assert.Equal(Personas, personas);
    }

    [Fact]
    public void La_poblacion_por_grupo_quinquenal_y_sexo_suma_el_total_y_la_de_hombres_y_mujeres_es_la_esperada()
    {
        var grupos = Consultar<Grupo>(
            @"SELECT e.GrupoQuinquenal + '|' + s.NombreSexo AS Clave, COUNT_BIG(*) AS N
              FROM hechos.CensoPoblacion p
              JOIN dim.Edad e ON e.EdadId = p.EdadId
              JOIN dim.Sexo s ON s.SexoId = p.SexoId
              GROUP BY e.GrupoQuinquenal, s.NombreSexo");

        Assert.Equal(Personas, grupos.Sum(g => g.N));
        Assert.Equal(21 * 2, grupos.Count);   // 20 grupos quinquenales de 0 a 99 mas "100 y mas", por dos sexos
    }

    [Fact]
    public void El_indice_de_masculinidad_nacional_se_calcula_en_un_rango_razonable()
    {
        // Formula del glosario del INE: (total de hombres / total de mujeres) * 100.
        var indice = Escalar<double>(
            @"SELECT 100.0 * SUM(CASE WHEN s.CodigoSexo = 1 THEN 1 ELSE 0 END) / SUM(CASE WHEN s.CodigoSexo = 2 THEN 1 ELSE 0 END)
              FROM hechos.CensoPoblacion p JOIN dim.Sexo s ON s.SexoId = p.SexoId");
        Assert.InRange(indice, 85.0, 105.0);
    }

    [Fact]
    public void La_relacion_de_dependencia_nacional_se_calcula_con_los_grupos_amplios_de_edad()
    {
        // Formula del glosario del INE: ((poblacion de 0 a 14) + (65 y mas)) / (poblacion de 15 a 64) * 100.
        var relacion = Escalar<double>(
            @"SELECT 100.0 * SUM(CASE WHEN e.GrupoAmplio <> '15-64' THEN 1 ELSE 0 END) / SUM(CASE WHEN e.GrupoAmplio = '15-64' THEN 1 ELSE 0 END)
              FROM hechos.CensoPoblacion p JOIN dim.Edad e ON e.EdadId = p.EdadId");
        Assert.InRange(relacion, 50.0, 100.0);
    }
}
