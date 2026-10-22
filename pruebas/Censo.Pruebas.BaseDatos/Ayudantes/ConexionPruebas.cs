using Dapper;
using Microsoft.Data.SqlClient;

namespace Censo.Pruebas.BaseDatos.Ayudantes;

/// <summary>
/// Acceso a la base CensoGT2018 del contenedor local. La cadena de conexion sale de la variable de entorno
/// CENSO_PRUEBAS_CONEXION o, si no existe, del archivo .env de la raiz del repositorio (nunca se escribe en el codigo).
/// </summary>
public static class ConexionPruebas
{
    private static readonly Lazy<string> Cadena = new(Construir);
    private static readonly Lazy<string> CadenaApi = new(ConstruirApi);

    public static string CadenaConexion => Cadena.Value;

    /// <summary>Conexion con el usuario de solo lectura de la API (CensoApi), tal como se conecta la API en produccion.</summary>
    public static string CadenaConexionApi => CadenaApi.Value;

    public static SqlConnection Abrir()
    {
        var conexion = new SqlConnection(CadenaConexion);
        conexion.Open();
        return conexion;
    }

    public static T Escalar<T>(string sql, object? parametros = null)
    {
        using var conexion = Abrir();
        return conexion.ExecuteScalar<T>(sql, parametros, commandTimeout: 900)!;
    }

    public static List<T> Consultar<T>(string sql, object? parametros = null)
    {
        using var conexion = Abrir();
        return conexion.Query<T>(sql, parametros, commandTimeout: 900).ToList();
    }

    /// <summary>Resultado de una agrupacion: una clave y su numero de filas.</summary>
    public sealed record Grupo(string Clave, long N);

    private static string Construir()
    {
        var variable = Environment.GetEnvironmentVariable("CENSO_PRUEBAS_CONEXION");
        if (!string.IsNullOrWhiteSpace(variable))
            return variable;

        var valores = LeerEnv();
        var clave = valores["MSSQL_SA_PASSWORD"];
        var baseDatos = valores.GetValueOrDefault("DB_NAME", "CensoGT2018");
        var puerto = valores.GetValueOrDefault("SQLSERVER_PORT", "1433");
        return $"Server=localhost,{puerto};Database={baseDatos};User Id=sa;Password={clave};TrustServerCertificate=True;Connect Timeout=30";
    }

    private static string ConstruirApi()
    {
        var variable = Environment.GetEnvironmentVariable("CENSO_PRUEBAS_CONEXION_API");
        if (!string.IsNullOrWhiteSpace(variable))
            return variable;

        var valores = LeerEnv();
        var baseDatos = valores.GetValueOrDefault("DB_NAME", "CensoGT2018");
        var puerto = valores.GetValueOrDefault("SQLSERVER_PORT", "1433");
        return $"Server=localhost,{puerto};Database={baseDatos};User Id=CensoApi;Password={valores["CLAVE_API"]};TrustServerCertificate=True;Connect Timeout=30";
    }

    private static Dictionary<string, string> LeerEnv() =>
        File.ReadAllLines(Path.Combine(BuscarRaiz(), ".env"))
            .Where(l => l.Contains('=') && !l.TrimStart().StartsWith('#'))
            .Select(l => l.Split('=', 2))
            .ToDictionary(p => p[0].Trim(), p => p[1].Trim());

    private static string BuscarRaiz()
    {
        var directorio = new DirectoryInfo(AppContext.BaseDirectory);
        while (directorio is not null && !File.Exists(Path.Combine(directorio.FullName, "CensoMultidim.slnx")))
            directorio = directorio.Parent;

        return directorio?.FullName
            ?? throw new InvalidOperationException("No se encontro la raiz del repositorio (CensoMultidim.slnx).");
    }
}
