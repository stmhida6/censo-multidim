using System.Text.Json;
using System.Text.Json.Serialization;
using Censo.Aplicacion.Catalogo;
using Censo.Aplicacion.Consultas;
using Censo.Dominio.Consultas;
using Censo.Infraestructura.Persistencia;
using Censo.Pruebas.BaseDatos.Ayudantes;
using Xunit.Abstractions;

namespace Censo.Pruebas.Integracion;

/// <summary>
/// Prueba de exactitud (tesis 2.10.3): reproduce con el motor de consultas los 25 cuadros oficiales publicados por el INE
/// y los compara celda por celda por municipio, por departamento y a nivel nacional. El oraculo son los cuadros
/// (validacion/cuadros-oficiales); la correspondencia de cada columna con el catalogo esta en validacion/mapeo-cuadros.json.
/// Las consultas pasan por el catalogo, el validador, el constructor de SQL y el repositorio, con el usuario de solo lectura.
/// </summary>
[Trait("Categoria", "Exactitud")]
public class ExactitudCuadrosPruebas
{
    private static readonly string Raiz = BuscarRaiz();
    private static readonly Lazy<MapeoCuadros> Mapeo = new(() => JsonSerializer.Deserialize<MapeoCuadros>(
        File.ReadAllText(Path.Combine(Raiz, "validacion", "mapeo-cuadros.json")), new JsonSerializerOptions { PropertyNameCaseInsensitive = true })!);

    // Niveles geograficos de los cuadros: municipio, departamento y total nacional (sin agrupar).
    private static readonly string?[] NivelesGeograficos = { "municipio", "departamento", null };

    private readonly ServicioConsultas _servicio;
    private readonly ITestOutputHelper _salida;

    public ExactitudCuadrosPruebas(ITestOutputHelper salida)
    {
        _salida = salida;
        var catalogo = new CatalogoCenso();
        var repositorio = new RepositorioConsultasSql(new OpcionesBaseDatos(ConexionPruebas.CadenaConexionApi, 600));
        _servicio = new ServicioConsultas(new ValidadorSolicitud(catalogo), new ConstructorConsultaSql(catalogo), repositorio);
    }

    public static IEnumerable<object[]> Cuadros() => Mapeo.Value.Cuadros.Select(c => new object[] { c.Cuadro });

    [Theory]
    [MemberData(nameof(Cuadros))]
    public async Task El_cuadro_oficial_se_reproduce_exactamente(string clave)
    {
        var cuadro = Mapeo.Value.Cuadros.Single(c => c.Cuadro == clave);
        var oficiales = LeerOficiales(cuadro);
        var diferencias = new List<string>();
        var celdas = 0;

        foreach (var columna in cuadro.Columnas)
        {
            foreach (var geografico in NivelesGeograficos)
            {
                var obtenidos = await ConsultarAsync(cuadro, columna, geografico);
                var nivelTexto = geografico ?? "pais";

                foreach (var registro in oficiales.Where(r => r.Nivel == nivelTexto))
                {
                    foreach (var (categoria, esperado) in ValoresOficiales(registro.Datos, columna))
                    {
                        IReadOnlyList<long?> codigos = categoria is null ? new long?[] { null } : columna.Categorias![categoria];
                        var obtenido = codigos.Sum(c => obtenidos.GetValueOrDefault((registro.Codigo, c)));
                        celdas++;
                        if (obtenido != esperado)
                            diferencias.Add($"{registro.Nombre} ({nivelTexto} {registro.Codigo}) {columna.Ruta}{(categoria is null ? "" : "." + categoria)}: oficial {esperado:N0}, sistema {obtenido:N0}");
                    }
                }
            }
        }

        _salida.WriteLine($"{clave}: {celdas:N0} celdas comparadas, {diferencias.Count:N0} diferencias.");
        GuardarResultado(clave, celdas, diferencias);
        Assert.True(diferencias.Count == 0,
            $"{diferencias.Count:N0} de {celdas:N0} celdas difieren del cuadro oficial {clave}:\n" + string.Join("\n", diferencias.Take(25)));
        Assert.True(celdas > 0, $"El cuadro {clave} no tiene celdas que comparar: revise las rutas del mapeo.");
    }

    /// <summary>Valor del sistema por (codigo geografico, codigo de la categoria); 0 es el codigo del total nacional.</summary>
    private async Task<Dictionary<(long, long?), long>> ConsultarAsync(MapeoCuadro cuadro, MapeoColumna columna, string? geografico)
    {
        var dimensiones = new List<string>();
        if (geografico is not null)
            dimensiones.Add(geografico);
        if (columna.Nivel is not null)
            dimensiones.Add(columna.Nivel);

        var filtros = (cuadro.Filtros ?? new()).Concat(columna.Filtros ?? new())
            .Select(f => new FiltroSolicitud(f.Nivel, f.Operador, f.Valores.Select(v => (object?)v).ToList()))
            .ToList();
        var medida = columna.Medida ?? cuadro.Medida;

        var resultado = await _servicio.ConsultarAsync(new SolicitudConsulta(new[] { medida }, null, dimensiones, filtros, 100_000));
        Assert.False(resultado.Truncado, $"La consulta de {cuadro.Cuadro}.{columna.Ruta} se trunco.");

        var valores = new Dictionary<(long, long?), long>();
        foreach (var fila in resultado.Filas)
        {
            var codigoGeografico = geografico is null ? 0 : Convert.ToInt64(fila[$"{geografico}_codigo"]);
            long? categoria = columna.Nivel is null || fila[$"{columna.Nivel}_codigo"] is null ? null : Convert.ToInt64(fila[$"{columna.Nivel}_codigo"]);
            valores[(codigoGeografico, categoria)] = valores.GetValueOrDefault((codigoGeografico, categoria)) + Convert.ToInt64(fila[medida]);
        }
        return valores;
    }

    /// <summary>Celdas oficiales de una columna: su valor, o el de cada categoria del mapeo.</summary>
    private static IEnumerable<(string? Categoria, long Valor)> ValoresOficiales(JsonElement datos, MapeoColumna columna)
    {
        var nodo = datos;
        foreach (var parte in columna.Ruta.Split('.'))
            nodo = nodo.GetProperty(parte);

        if (columna.Categorias is null)
        {
            yield return (null, nodo.GetInt64());
            yield break;
        }

        foreach (var categoria in columna.Categorias.Keys)
            yield return (categoria, nodo.GetProperty(categoria).GetInt64());
    }

    private sealed record RegistroOficial(string Nivel, long Codigo, string Nombre, JsonElement Datos);

    private static List<RegistroOficial> LeerOficiales(MapeoCuadro cuadro)
    {
        var registros = new List<RegistroOficial>();
        foreach (var linea in File.ReadLines(Path.Combine(Raiz, "validacion", "cuadros-oficiales", cuadro.Archivo)))
        {
            using var documento = JsonDocument.Parse(linea);
            var r = documento.RootElement;
            if (r.GetProperty("tipo_registro").GetString() == "metadata")
                continue;

            var nivel = r.GetProperty("nivel_geografico").GetString()!;
            var (codigo, nombre) = nivel switch
            {
                "pais" => (0L, "Guatemala"),
                "departamento" => (long.Parse(r.GetProperty("codigo_departamento").GetString()!), r.GetProperty("departamento").GetString()!),
                _ => (long.Parse(r.GetProperty("codigo_municipio").GetString()!), r.GetProperty("municipio").GetString()!),
            };
            var datos = r.TryGetProperty("datos", out var d) ? d : r.GetProperty("indicadores");
            registros.Add(new RegistroOficial(nivel, codigo, nombre, datos.Clone()));
        }

        Assert.Equal(363, registros.Count);
        return registros;
    }

    /// <summary>Con CENSO_EXACTITUD_SALIDA definida, guarda el resultado de cada cuadro (evidencia para la tesis).</summary>
    private static void GuardarResultado(string cuadro, int celdas, List<string> diferencias)
    {
        var carpeta = Environment.GetEnvironmentVariable("CENSO_EXACTITUD_SALIDA");
        if (string.IsNullOrWhiteSpace(carpeta))
            return;

        Directory.CreateDirectory(carpeta);
        File.WriteAllText(Path.Combine(carpeta, $"{cuadro}.json"),
            JsonSerializer.Serialize(new { cuadro, celdas, diferencias = diferencias.Count, detalle = diferencias }, new JsonSerializerOptions { WriteIndented = true }));
    }

    private static string BuscarRaiz()
    {
        var directorio = new DirectoryInfo(AppContext.BaseDirectory);
        while (directorio is not null && !File.Exists(Path.Combine(directorio.FullName, "CensoMultidim.slnx")))
            directorio = directorio.Parent;
        return directorio?.FullName ?? throw new InvalidOperationException("No se encontro la raiz del repositorio.");
    }

    // ------------------------------------------------------------------ modelo del mapeo

    private sealed record MapeoCuadros(string Descripcion, List<MapeoCuadro> Cuadros);

    private sealed record MapeoCuadro(string Cuadro, string Archivo, string Medida, List<MapeoFiltro>? Filtros, List<MapeoColumna> Columnas);

    private sealed record MapeoColumna(string Ruta, string? Medida, string? Nivel, List<MapeoFiltro>? Filtros, Dictionary<string, List<long?>>? Categorias);

    private sealed record MapeoFiltro(string Nivel, string Operador, List<long> Valores);
}
