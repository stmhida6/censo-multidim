using System.Text.RegularExpressions;
using Censo.Aplicacion.Catalogo;
using Censo.Dominio.Catalogo;

namespace Censo.Pruebas.Aplicacion;

/// <summary>
/// Integridad del catalogo: todo lo que llega al SQL sale de aqui, asi que estas pruebas garantizan que sea coherente y
/// que no contenga nada que pueda interpretarse como una instruccion adicional.
/// </summary>
[Trait("Categoria", "Catalogo")]
public class CatalogoPruebas
{
    private static readonly CatalogoCenso Catalogo = new();
    private static readonly Regex ClaveSegura = new("^[a-z][A-Za-z0-9]*$", RegexOptions.Compiled);
    private static readonly Regex TablaSegura = new(@"^(dim|hechos)\.[A-Za-z0-9]+$", RegexOptions.Compiled);
    private static readonly string[] Prohibidos = { ";", "--", "/*", "*/", "EXEC", "DROP", "INSERT", "UPDATE", "DELETE", "xp_", "sp_", "GO\n" };

    private static IEnumerable<string> PlantillasSql()
    {
        foreach (var d in Catalogo.Dimensiones)
        {
            foreach (var n in d.Niveles)
            {
                if (n.ExpresionCodigo is not null) yield return n.ExpresionCodigo;
                yield return n.ExpresionEtiqueta;
                if (n.ExpresionOrden is not null) yield return n.ExpresionOrden;
            }

            foreach (var p in d.PasosJerarquia) { yield return p.Tabla; yield return p.Condicion; }
            foreach (var v in d.Vinculos)
                foreach (var p in v.Pasos) { yield return p.Tabla; yield return p.Condicion; }
        }

        foreach (var m in Catalogo.Medidas.Where(m => m.ExpresionValor is not null))
            yield return m.ExpresionValor!;
        foreach (var h in Catalogo.Hechos)
            yield return h.Tabla;
    }

    [Fact]
    public void El_catalogo_se_construye_sin_claves_repetidas()
    {
        Assert.Equal(4, Catalogo.Hechos.Count);
        Assert.NotEmpty(Catalogo.Dimensiones);
        Assert.NotEmpty(Catalogo.Medidas);
        Assert.NotEmpty(Catalogo.Indicadores);
    }

    [Fact]
    public void Las_claves_publicas_son_identificadores_seguros()
    {
        var todas = Catalogo.Hechos.Select(h => h.Clave)
            .Concat(Catalogo.Dimensiones.Select(d => d.Clave))
            .Concat(Catalogo.Dimensiones.SelectMany(d => d.Niveles).Select(n => n.Clave))
            .Concat(Catalogo.Medidas.Select(m => m.Clave))
            .Concat(Catalogo.Indicadores.Select(i => i.Clave));

        Assert.Empty(todas.Where(c => !ClaveSegura.IsMatch(c)));
    }

    [Fact]
    public void Las_tablas_del_catalogo_son_de_los_esquemas_dim_o_hechos()
    {
        var tablas = Catalogo.Hechos.Select(h => h.Tabla)
            .Concat(Catalogo.Dimensiones.SelectMany(d => d.PasosJerarquia.Concat(d.Vinculos.SelectMany(v => v.Pasos))).Select(p => p.Tabla));
        Assert.Empty(tablas.Where(t => !TablaSegura.IsMatch(t)));
    }

    [Fact]
    public void Las_plantillas_de_sql_no_contienen_instrucciones_ni_comentarios()
    {
        var sospechosas = PlantillasSql().Where(p => Prohibidos.Any(x => p.Contains(x, StringComparison.OrdinalIgnoreCase))).ToList();
        Assert.Empty(sospechosas);
    }

    [Fact]
    public void Las_plantillas_de_sql_solo_usan_los_marcadores_conocidos()
    {
        var conMarcadorDesconocido = PlantillasSql()
            .Where(p => Regex.Matches(p, @"\{[^}]*\}").Any(m => m.Value is not ("{a}" or "{f}" or "{p}")))
            .ToList();
        Assert.Empty(conMarcadorDesconocido);
    }

    [Fact]
    public void Toda_dimension_tiene_niveles_y_vinculos_a_hechos_existentes()
    {
        foreach (var d in Catalogo.Dimensiones)
        {
            Assert.NotEmpty(d.Niveles);
            Assert.NotEmpty(d.Vinculos);
            Assert.All(d.Vinculos, v => Assert.NotNull(Catalogo.BuscarHecho(v.HechoClave)));
            Assert.Equal(d.Vinculos.Count, d.Vinculos.Select(v => v.HechoClave).Distinct().Count());
        }
    }

    [Fact]
    public void Cada_nivel_alcanza_un_paso_que_existe_en_todos_los_vinculos_de_su_dimension()
    {
        var invalidos = new List<string>();
        foreach (var d in Catalogo.Dimensiones)
        {
            foreach (var v in d.Vinculos)
            {
                var total = v.Pasos.Count + d.PasosJerarquia.Count;
                foreach (var n in d.Niveles)
                {
                    var indice = v.Pasos.Count - 1 + n.Paso;
                    if (indice >= total || (indice < 0 && n.Paso != 0))
                        invalidos.Add($"{d.Clave}/{n.Clave}/{v.HechoClave}");
                }
            }
        }

        Assert.Empty(invalidos);
    }

    [Fact]
    public void Los_pasos_con_el_mismo_id_se_definen_igual_en_todo_el_catalogo()
    {
        var pasos = Catalogo.Dimensiones
            .SelectMany(d => d.PasosJerarquia.Concat(d.Vinculos.SelectMany(v => v.Pasos)))
            .GroupBy(p => p.Id)
            .Where(g => g.Distinct().Count() > 1)
            .Select(g => g.Key)
            .ToList();
        Assert.Empty(pasos);
    }

    [Fact]
    public void Toda_medida_pertenece_a_un_hecho_y_sus_condiciones_usan_niveles_disponibles_para_ese_hecho_con_valores_del_tipo_correcto()
    {
        var problemas = new List<string>();
        foreach (var m in Catalogo.Medidas)
        {
            if (Catalogo.BuscarHecho(m.HechoClave) is null)
                problemas.Add($"{m.Clave}: hecho '{m.HechoClave}' inexistente");

            foreach (var c in m.Condiciones)
            {
                var encontrado = Catalogo.BuscarNivel(c.NivelClave);
                if (encontrado is null) { problemas.Add($"{m.Clave}: nivel '{c.NivelClave}' inexistente"); continue; }

                var (dimension, nivel) = encontrado.Value;
                if (dimension.VinculoCon(m.HechoClave) is null)
                    problemas.Add($"{m.Clave}: el nivel '{c.NivelClave}' no esta disponible para el hecho '{m.HechoClave}'");
                foreach (var v in c.Valores)
                {
                    var correcto = nivel.TipoValor == TipoValor.Entero ? v is int or long : v is string;
                    if (!correcto) problemas.Add($"{m.Clave}: valor '{v}' del nivel '{c.NivelClave}' con tipo incorrecto");
                }
            }
        }

        Assert.Empty(problemas);
    }

    [Fact]
    public void Todo_indicador_es_una_razon_entre_dos_medidas_del_mismo_hecho()
    {
        var problemas = new List<string>();
        foreach (var i in Catalogo.Indicadores)
        {
            var numerador = Catalogo.BuscarMedida(i.NumeradorClave);
            var denominador = Catalogo.BuscarMedida(i.DenominadorClave);
            if (numerador is null || denominador is null) { problemas.Add($"{i.Clave}: medida inexistente"); continue; }
            if (numerador.HechoClave != i.HechoClave || denominador.HechoClave != i.HechoClave)
                problemas.Add($"{i.Clave}: las medidas no son del hecho '{i.HechoClave}'");
            if (i.Multiplicador <= 0)
                problemas.Add($"{i.Clave}: multiplicador no positivo");
            if (string.IsNullOrWhiteSpace(i.Formula) || string.IsNullOrWhiteSpace(i.Fuente))
                problemas.Add($"{i.Clave}: falta la formula o la fuente");
        }

        Assert.Empty(problemas);
    }

    [Fact]
    public void Todo_elemento_del_catalogo_tiene_nombre_y_descripcion()
    {
        var sinTexto = Catalogo.Dimensiones.Where(d => string.IsNullOrWhiteSpace(d.Nombre) || string.IsNullOrWhiteSpace(d.Descripcion)).Select(d => d.Clave)
            .Concat(Catalogo.Medidas.Where(m => string.IsNullOrWhiteSpace(m.Nombre) || string.IsNullOrWhiteSpace(m.Descripcion)).Select(m => m.Clave))
            .Concat(Catalogo.Indicadores.Where(i => string.IsNullOrWhiteSpace(i.Nombre) || string.IsNullOrWhiteSpace(i.Descripcion)).Select(i => i.Clave));
        Assert.Empty(sinTexto);
    }

    [Fact]
    public void Las_cuatro_tablas_de_hechos_tienen_al_menos_una_medida_y_la_dimension_territorio()
    {
        foreach (var h in Catalogo.Hechos)
        {
            Assert.Contains(Catalogo.Medidas, m => m.HechoClave == h.Clave);
            Assert.NotNull(Catalogo.BuscarNivel("departamento")!.Value.Dimension.VinculoCon(h.Clave));
        }
    }
}
