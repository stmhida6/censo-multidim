using System.Text.RegularExpressions;
using Censo.Pruebas.BaseDatos.Ayudantes;
using static Censo.Pruebas.BaseDatos.Ayudantes.ConexionPruebas;
using static Censo.Pruebas.BaseDatos.Ayudantes.ValoresEsperados;

namespace Censo.Pruebas.BaseDatos;

/// <summary>Estructura del modelo y cumplimiento de las convenciones de nombres de docs/convenciones.md.</summary>
[Trait("Categoria", "Esquema")]
public class EsquemaPruebas
{
    private static readonly Regex PascalCase = new("^[A-Z][A-Za-z0-9]*$", RegexOptions.Compiled);

    [Fact]
    public void Existen_los_cuatro_esquemas_del_modelo()
    {
        var reales = Consultar<string>("SELECT name FROM sys.schemas WHERE name IN ('dim', 'hechos', 'stage', 'seg') ORDER BY name");
        Assert.Equal(new[] { "dim", "hechos", "seg", "stage" }, reales);
    }

    [Fact]
    public void Existen_exactamente_las_38_dimensiones_previstas()
    {
        var reales = Metadatos.Tablas().Where(t => t.Esquema == "dim").Select(t => t.Nombre).OrderBy(n => n).ToList();
        Assert.Equal(Dimensiones.OrderBy(n => n).ToList(), reales);
    }

    [Fact]
    public void Existen_exactamente_las_4_tablas_de_hechos_previstas()
    {
        var reales = Metadatos.Tablas().Where(t => t.Esquema == "hechos").Select(t => t.Nombre).OrderBy(n => n).ToList();
        Assert.Equal(Hechos.OrderBy(n => n).ToList(), reales);
    }

    [Fact]
    public void Toda_tabla_tiene_clave_primaria_con_el_nombre_convenido()
    {
        var claves = Metadatos.ClavesPrimarias().ToDictionary(k => (k.Esquema, k.Tabla), k => k.Nombre);
        var incorrectas = Metadatos.Tablas()
            .Where(t => !claves.TryGetValue((t.Esquema, t.Nombre), out var nombre) || nombre != $"PK_{Mayuscula(t.Esquema)}_{t.Nombre}")
            .Select(t => $"{t.Esquema}.{t.Nombre}")
            .ToList();
        Assert.Empty(incorrectas);
    }

    [Fact]
    public void Las_claves_primarias_de_los_hechos_son_no_agrupadas_para_permitir_el_columnstore()
    {
        var agrupadas = Metadatos.ClavesPrimarias().Where(k => k.Esquema == "hechos" && k.Tipo != "NONCLUSTERED").ToList();
        Assert.Empty(agrupadas);
    }

    [Fact]
    public void Toda_tabla_tiene_las_tres_columnas_de_auditoria()
    {
        var requeridas = new[] { "FechaCreacion", "FechaModificacion", "UsuarioCreacion" };
        var faltantes = Metadatos.Columnas()
            .GroupBy(c => $"{c.Esquema}.{c.Tabla}")
            .Where(g => requeridas.Any(r => g.All(c => c.Columna != r)))
            .Select(g => g.Key)
            .ToList();
        Assert.Empty(faltantes);
    }

    [Fact]
    public void Tablas_y_columnas_usan_PascalCase_sin_guiones_bajos_ni_tildes()
    {
        var incorrectos = Metadatos.Tablas().Select(t => $"{t.Esquema}.{t.Nombre}").Where(n => !PascalCase.IsMatch(n[(n.IndexOf('.') + 1)..]))
            .Concat(Metadatos.Columnas().Where(c => !PascalCase.IsMatch(c.Columna)).Select(c => $"{c.Esquema}.{c.Tabla}.{c.Columna}"))
            .ToList();
        Assert.Empty(incorrectos);
    }

    [Fact]
    public void Las_columnas_booleanas_llevan_el_prefijo_Es_o_Tiene()
    {
        var incorrectas = Metadatos.Columnas()
            .Where(c => c.Tipo == "bit" && !c.Columna.StartsWith("Es") && !c.Columna.StartsWith("Tiene"))
            .Select(c => $"{c.Esquema}.{c.Tabla}.{c.Columna}")
            .ToList();
        Assert.Empty(incorrectas);
    }

    [Fact]
    public void Las_columnas_con_llave_foranea_terminan_en_Id()
    {
        var incorrectas = Metadatos.LlavesForaneas().Where(f => !f.ColumnaHijo.EndsWith("Id")).Select(f => $"{f.TablaHijo}.{f.ColumnaHijo}").ToList();
        Assert.Empty(incorrectas);
    }

    [Fact]
    public void Toda_dimension_tiene_columnas_de_llave_codigo_y_nombre_con_el_nombre_de_la_tabla()
    {
        var columnas = Metadatos.Columnas().Where(c => c.Esquema == "dim").GroupBy(c => c.Tabla).ToDictionary(g => g.Key, g => g.Select(c => c.Columna).ToHashSet());
        var faltantes = new List<string>();
        foreach (var dimension in Dimensiones)
        {
            var esperadas = dimension == "Edad" ? new[] { "EdadId" } : new[] { $"{dimension}Id", $"Codigo{dimension}", $"Nombre{dimension}" };
            faltantes.AddRange(esperadas.Where(e => !columnas[dimension].Contains(e)).Select(e => $"dim.{dimension}.{e}"));
        }
        Assert.Empty(faltantes);
    }

    [Fact]
    public void El_modelo_tiene_las_76_llaves_foraneas_habilitadas_y_de_confianza()
    {
        Assert.Equal(LlavesForaneas, Escalar<int>("SELECT COUNT(*) FROM sys.foreign_keys"));
        Assert.Equal(0, Escalar<int>("SELECT COUNT(*) FROM sys.foreign_keys WHERE is_disabled = 1 OR is_not_trusted = 1"));
    }

    [Fact]
    public void Las_llaves_foraneas_siguen_la_convencion_de_nombres_y_las_de_rol_agregan_la_columna()
    {
        var llaves = Metadatos.LlavesForaneas();
        var incorrectas = new List<string>();
        foreach (var f in llaves)
        {
            var basico = $"FK_{Mayuscula(f.EsquemaHijo)}_{f.TablaHijo}_{Mayuscula(f.EsquemaPadre)}_{f.TablaPadre}";
            var repetida = llaves.Count(o => o.EsquemaHijo == f.EsquemaHijo && o.TablaHijo == f.TablaHijo
                                             && o.EsquemaPadre == f.EsquemaPadre && o.TablaPadre == f.TablaPadre) > 1;
            var esperado = repetida ? $"{basico}_{f.ColumnaHijo}" : basico;
            if (f.Nombre != esperado)
                incorrectas.Add($"{f.Nombre} (esperado {esperado})");
        }
        Assert.Empty(incorrectas);
    }

    [Fact]
    public void Las_restricciones_unicas_son_el_codigo_del_INE_de_cada_dimension_y_la_llave_natural_de_los_hechos()
    {
        var esperadas = Dimensiones.Where(d => d != "Edad").Select(d => $"UQ_Dim_{d}_Codigo{d}")
            .Concat(new[]
            {
                "UQ_Hechos_CensoVivienda_LugarPobladoId_NumeroVivienda",
                "UQ_Hechos_CensoHogar_ViviendaId_NumeroHogar",
                "UQ_Hechos_CensoMigracion_HogarId_NumeroEmigrante",
            })
            .OrderBy(n => n, StringComparer.Ordinal).ToList();

        Assert.Equal(RestriccionesUnicas, esperadas.Count);
        Assert.Equal(esperadas, Metadatos.RestriccionesUnicas().OrderBy(n => n, StringComparer.Ordinal).ToList());
    }

    [Fact]
    public void Solo_vivienda_hogar_y_poblacion_tienen_columnstore_agrupado()
    {
        var reales = Metadatos.Columnstore().Select(i => $"{i.Tabla}:{i.Nombre}").OrderBy(n => n).ToList();
        Assert.Equal(new[]
        {
            "CensoHogar:IX_Hechos_CensoHogar_Columnstore",
            "CensoPoblacion:IX_Hechos_CensoPoblacion_Columnstore",
            "CensoVivienda:IX_Hechos_CensoVivienda_Columnstore",
        }, reales);
    }
}
