using System.Data;
using System.Data.Common;
using Censo.Dominio.Consultas;
using Censo.Dominio.Contratos;
using Dapper;
using Microsoft.Data.SqlClient;

namespace Censo.Infraestructura.Persistencia;

/// <summary>Configuracion de la conexion a SQL Server.</summary>
public sealed record OpcionesBaseDatos(string CadenaConexion, int TiempoEsperaSegundos = 60);

/// <summary>
/// Ejecuta en SQL Server las consultas ya validadas y construidas por la capa de aplicacion. Usa Dapper para enviar el
/// SQL con sus parametros (los valores nunca se concatenan) y devuelve las filas sin interpretar.
/// </summary>
public sealed class RepositorioConsultasSql : IRepositorioConsultas
{
    private const int CodigoTiempoAgotado = -2;

    private readonly OpcionesBaseDatos _opciones;

    public RepositorioConsultasSql(OpcionesBaseDatos opciones) => _opciones = opciones;

    public async Task<TablaResultado> EjecutarAsync(ConsultaSql consulta, CancellationToken cancelacion = default)
    {
        var conectada = false;
        try
        {
            await using var conexion = new SqlConnection(_opciones.CadenaConexion);
            await conexion.OpenAsync(cancelacion);
            conectada = true;

            var parametros = new DynamicParameters();
            foreach (var (nombre, valor) in consulta.Parametros)
                parametros.Add(nombre, valor);

            var comando = new CommandDefinition(consulta.Texto, parametros, commandTimeout: _opciones.TiempoEsperaSegundos, cancellationToken: cancelacion);
            using var lector = await conexion.ExecuteReaderAsync(comando);
            return await LeerAsync(lector, cancelacion);
        }
        catch (SqlException ex)
        {
            // Solo es "tiempo agotado" si la consulta ya estaba en ejecucion; un tiempo agotado al conectar es una base inaccesible.
            throw new ConsultaFallidaException("La base de datos no pudo ejecutar la consulta.", conectada && ex.Number == CodigoTiempoAgotado, ex);
        }
    }

    private static async Task<TablaResultado> LeerAsync(IDataReader lector, CancellationToken cancelacion)
    {
        var columnas = Enumerable.Range(0, lector.FieldCount).Select(lector.GetName).ToList();
        var filas = new List<object?[]>();

        while (lector is DbDataReader asincrono ? await asincrono.ReadAsync(cancelacion) : lector.Read())
        {
            var fila = new object?[columnas.Count];
            for (var i = 0; i < fila.Length; i++)
                fila[i] = lector.IsDBNull(i) ? null : lector.GetValue(i);
            filas.Add(fila);
        }

        return new TablaResultado(columnas, filas);
    }
}
