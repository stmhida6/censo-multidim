using Censo.Pruebas.BaseDatos.Ayudantes;
using static Censo.Pruebas.BaseDatos.Ayudantes.ConexionPruebas;
using static Censo.Pruebas.BaseDatos.Ayudantes.ValoresEsperados;

namespace Censo.Pruebas.BaseDatos;

/// <summary>Coherencia de los valores cargados: jerarquias, rangos y reglas del cuestionario.</summary>
[Trait("Categoria", "Calidad")]
public class CalidadDatosPruebas
{
    public static IEnumerable<object[]> NombresDeLasDimensiones() =>
        Dimensiones.Where(d => d != "Edad").Select(d => new object[] { d });

    [Fact]
    public void El_codigo_de_cada_municipio_empieza_con_el_codigo_de_su_departamento()
    {
        var incoherentes = Escalar<long>(
            @"SELECT COUNT_BIG(*) FROM dim.Municipio m
              JOIN dim.Departamento d ON d.DepartamentoId = m.DepartamentoId
              WHERE m.CodigoMunicipio / 100 <> d.CodigoDepartamento");
        Assert.Equal(0, incoherentes);
    }

    [Fact]
    public void El_codigo_de_cada_lugar_poblado_empieza_con_el_codigo_de_su_municipio()
    {
        var incoherentes = Escalar<long>(
            @"SELECT COUNT_BIG(*) FROM dim.LugarPoblado l
              JOIN dim.Municipio m ON m.MunicipioId = l.MunicipioId
              WHERE l.CodigoLugarPoblado / 1000 <> m.CodigoMunicipio");
        Assert.Equal(0, incoherentes);
    }

    [Fact]
    public void Los_lugares_poblados_solo_pertenecen_a_municipios_reales()
    {
        var enNoDeclarados = Escalar<long>(
            @"SELECT COUNT_BIG(*) FROM dim.LugarPoblado l
              JOIN dim.Municipio m ON m.MunicipioId = l.MunicipioId WHERE m.EsMunicipioNoDeclarado = 1");
        Assert.Equal(0, enNoDeclarados);
    }

    [Fact]
    public void La_dimension_de_edad_cubre_de_0_a_124_sin_huecos_y_con_grupos_completos()
    {
        Assert.Equal(0, Escalar<int>("SELECT MIN(CAST(EdadId AS INT)) FROM dim.Edad"));
        Assert.Equal(124, Escalar<int>("SELECT MAX(CAST(EdadId AS INT)) FROM dim.Edad"));
        Assert.Equal(125, Escalar<int>("SELECT COUNT(*) FROM dim.Edad"));

        var gruposIncompletos = Escalar<int>(
            @"SELECT COUNT(*) FROM (SELECT GrupoQuinquenal FROM dim.Edad WHERE GrupoQuinquenal <> '100 y mas'
                                    GROUP BY GrupoQuinquenal HAVING COUNT(*) <> 5) x");
        Assert.Equal(0, gruposIncompletos);
        Assert.Equal(25, Escalar<int>("SELECT COUNT(*) FROM dim.Edad WHERE GrupoQuinquenal = '100 y mas'"));

        var amplios = Consultar<Grupo>("SELECT GrupoAmplio AS Clave, COUNT_BIG(*) AS N FROM dim.Edad GROUP BY GrupoAmplio")
            .ToDictionary(g => g.Clave, g => g.N);
        Assert.Equal(15, amplios["0-14"]);
        Assert.Equal(50, amplios["15-64"]);
        Assert.Equal(60, amplios["65 y mas"]);
    }

    [Fact]
    public void La_edad_de_trabajar_empieza_a_los_15_anios()
    {
        var incorrectas = Escalar<int>("SELECT COUNT(*) FROM dim.Edad WHERE EsEdadTrabajar <> CASE WHEN EdadId >= 15 THEN 1 ELSE 0 END");
        Assert.Equal(0, incorrectas);
    }

    [Fact]
    public void Las_coordenadas_de_las_viviendas_estan_dentro_de_Guatemala_y_vienen_completas()
    {
        var fuera = Escalar<long>(
            @"SELECT COUNT_BIG(*) FROM hechos.CensoVivienda
              WHERE Latitud NOT BETWEEN 13.5 AND 18.0 OR Longitud NOT BETWEEN -92.5 AND -88.0");
        var incompletas = Escalar<long>("SELECT COUNT_BIG(*) FROM hechos.CensoVivienda WHERE (CASE WHEN Latitud IS NULL THEN 1 ELSE 0 END) <> (CASE WHEN Longitud IS NULL THEN 1 ELSE 0 END)");
        Assert.Equal(0, fuera);
        Assert.Equal(0, incompletas);
    }

    [Fact]
    public void El_anio_de_salida_de_los_emigrantes_esta_entre_2002_y_2018()
    {
        var fuera = Escalar<long>("SELECT COUNT_BIG(*) FROM hechos.CensoMigracion WHERE AnioSalida NOT BETWEEN 2002 AND 2018");
        Assert.Equal(0, fuera);
    }

    [Fact]
    public void El_anio_de_llegada_al_pais_no_supera_el_del_censo()
    {
        var posteriores = Escalar<long>("SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion WHERE AnioLlegadaPais > 2018");
        Assert.Equal(0, posteriores);
    }

    [Fact]
    public void Solo_las_mujeres_de_10_anios_o_mas_declaran_hijos()
    {
        var incoherentes = Escalar<long>(
            @"SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion p
              JOIN dim.Sexo s ON s.SexoId = p.SexoId
              WHERE (p.HijosNacidosVivos IS NOT NULL OR p.HijosSobrevivientes IS NOT NULL OR p.EdadPrimerHijo IS NOT NULL)
                AND (s.CodigoSexo <> 2 OR p.EdadId < 10)");
        Assert.Equal(0, incoherentes);
    }

    [Fact]
    public void Los_hijos_sobrevivientes_no_superan_a_los_nacidos_vivos()
    {
        var incoherentes = Escalar<long>(
            @"SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion
              WHERE HijosSobrevivientes > HijosNacidosVivos OR HijosSobrevivientesMujeres > HijosNacidosVivosMujeres
                 OR HijosSobrevivientesHombres > HijosNacidosVivosHombres");
        Assert.Equal(0, incoherentes);
    }

    [Fact]
    public void Ser_migrante_de_toda_la_vida_equivale_a_haber_nacido_en_otro_lugar()
    {
        var incoherentes = Escalar<long>(
            @"SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion p
              JOIN dim.TipoLugar t ON t.TipoLugarId = p.TipoLugarNacimientoId
              WHERE (p.EsMigranteVida = 1 AND t.CodigoTipoLugar <> 2)
                 OR (p.EsMigranteVida = 0 AND t.CodigoTipoLugar <> 1)
                 OR (p.EsMigranteVida IS NULL AND t.CodigoTipoLugar <> 9)");
        Assert.Equal(0, incoherentes);
    }

    [Fact]
    public void La_condicion_de_actividad_falta_solo_en_los_menores_de_7_anios()
    {
        var incoherentes = Escalar<long>(
            "SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion WHERE (CASE WHEN CondicionActividadId IS NULL THEN 1 ELSE 0 END) <> (CASE WHEN EdadId < 7 THEN 1 ELSE 0 END)");
        Assert.Equal(0, incoherentes);
    }

    [Fact]
    public void Toda_persona_ocupada_tiene_ocupacion_rama_y_categoria_ocupacional()
    {
        var incompletas = Escalar<long>(
            @"SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion p
              JOIN dim.CondicionActividad c ON c.CondicionActividadId = p.CondicionActividadId
              WHERE c.CodigoCondicionActividad = 1
                AND (p.OcupacionId IS NULL OR p.RamaActividadId IS NULL OR p.CategoriaOcupacionalId IS NULL)");
        Assert.Equal(0, incompletas);
    }

    [Fact]
    public void Los_valores_centinela_99_y_9999_no_quedan_en_los_hechos()
    {
        var restantes = Escalar<long>(
            @"SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion
              WHERE HijosNacidosVivos = 99 OR HijosNacidosVivosMujeres = 99 OR HijosNacidosVivosHombres = 99
                 OR EdadPrimerHijo = 99 OR DiaUltimoHijo = 99 OR MesUltimoHijo = 99
                 OR AnioUltimoHijo = 9999 OR AnioLlegadaPais = 9999");
        Assert.Equal(0, restantes);
    }

    [Theory]
    [MemberData(nameof(NombresDeLasDimensiones))]
    public void Los_nombres_de_cada_dimension_no_estan_vacios_ni_tienen_espacios_sobrantes(string dimension)
    {
        var incorrectos = Escalar<long>(
            $@"SELECT COUNT_BIG(*) FROM dim.{dimension}
               WHERE LEN(Nombre{dimension}) = 0 OR Nombre{dimension} <> LTRIM(RTRIM(Nombre{dimension}))");
        Assert.Equal(0, incorrectos);
    }

    [Fact]
    public void Solo_4_nombres_de_lugares_poblados_traen_defectos_de_codificacion_que_ya_vienen_en_el_origen()
    {
        var defectuosos = Escalar<long>(
            "SELECT COUNT_BIG(*) FROM dim.LugarPoblado WHERE NombreLugarPoblado LIKE '%' + NCHAR(195) + '%' OR NombreLugarPoblado LIKE '%?%'");
        var enDepartamentosYMunicipios = Escalar<long>(
            @"SELECT (SELECT COUNT_BIG(*) FROM dim.Departamento WHERE NombreDepartamento LIKE '%' + NCHAR(195) + '%' OR NombreDepartamento LIKE '%?%')
                   + (SELECT COUNT_BIG(*) FROM dim.Municipio WHERE NombreMunicipio LIKE '%' + NCHAR(195) + '%' OR NombreMunicipio LIKE '%?%')");
        Assert.Equal(4, defectuosos);
        Assert.Equal(0, enDepartamentosYMunicipios);
    }

    [Fact]
    public void Los_acentos_de_las_etiquetas_se_cargaron_como_unicode_correcto()
    {
        var quiche = Escalar<long>(
            "SELECT COUNT_BIG(*) FROM dim.Departamento WHERE NombreDepartamento LIKE 'Quich_' AND UNICODE(SUBSTRING(NombreDepartamento, 6, 1)) = 233");
        var petenYSacatepequez = Escalar<long>(
            @"SELECT COUNT_BIG(*) FROM dim.Departamento
              WHERE (NombreDepartamento LIKE 'Pet_n' AND UNICODE(SUBSTRING(NombreDepartamento, 4, 1)) = 233)
                 OR (NombreDepartamento LIKE 'Sacatep_quez' AND UNICODE(SUBSTRING(NombreDepartamento, 8, 1)) = 233)");
        Assert.Equal(1, quiche);
        Assert.Equal(2, petenYSacatepequez);
    }
}
