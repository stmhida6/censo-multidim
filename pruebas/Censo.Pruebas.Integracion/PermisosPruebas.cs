using Dapper;
using Microsoft.Data.SqlClient;
using static Censo.Pruebas.BaseDatos.Ayudantes.ConexionPruebas;

namespace Censo.Pruebas.Integracion;

/// <summary>
/// Privilegios minimos (tesis 2.9): el usuario con el que se conecta la API solo puede leer las dimensiones y los hechos.
/// Cada prueba de rechazo confirma un error de permiso denegado (229, 262, 297) o de objeto no visible para el usuario (208, 1088, 3701).
/// En Azure SQL Database algunos objetos de servidor ni siquiera existen dentro de la base (xp_cmdshell y sp_configure dan 2812;
/// sys.sql_logins da 208): tambien es un rechazo valido, porque el usuario no puede ejecutarlos.
/// </summary>
[Trait("Categoria", "Seguridad")]
public class PermisosPruebas
{
    private static SqlConnection AbrirComoApi()
    {
        var conexion = new SqlConnection(CadenaConexionApi);
        conexion.Open();
        return conexion;
    }

    private static int? NumeroError(string sql)
    {
        using var conexion = AbrirComoApi();
        try
        {
            conexion.Execute(sql);
            return null;
        }
        catch (SqlException ex)
        {
            return ex.Number;
        }
    }

    [Fact]
    public void El_usuario_de_la_api_es_CensoApi_y_no_es_administrador()
    {
        using var conexion = AbrirComoApi();
        Assert.Equal("CensoApi", conexion.ExecuteScalar<string>("SELECT SUSER_NAME()"));
        Assert.Equal(0, conexion.ExecuteScalar<int>("SELECT IS_SRVROLEMEMBER('sysadmin')"));
        Assert.Equal(0, conexion.ExecuteScalar<int>("SELECT IS_MEMBER('db_owner')"));
    }

    [Theory]
    [InlineData("SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion")]
    [InlineData("SELECT COUNT_BIG(*) FROM hechos.CensoMigracion")]
    [InlineData("SELECT COUNT_BIG(*) FROM dim.Departamento")]
    public void Puede_leer_dimensiones_y_hechos(string sql)
    {
        using var conexion = AbrirComoApi();
        Assert.True(conexion.ExecuteScalar<long>(sql) > 0);
    }

    [Theory]
    [InlineData("SELECT TOP 1 * FROM stage.Persona")]
    public void No_puede_leer_stage(string sql) => Assert.Contains(NumeroError(sql), new int?[] { 229, 297, 208 });

    [Fact]
    public void No_ve_las_credenciales_de_otros_usuarios()
    {
        // En local la vista existe pero el usuario no ve ningun hash; en Azure SQL Database no existe dentro de la base (208).
        using var conexion = AbrirComoApi();
        try
        {
            Assert.Equal(0, conexion.ExecuteScalar<int>("SELECT COUNT(*) FROM sys.sql_logins WHERE password_hash IS NOT NULL"));
        }
        catch (SqlException ex) when (ex.Number == 208)
        {
            // La vista no esta disponible para el usuario: tampoco puede ver credenciales.
        }
    }

    [Theory]
    [InlineData("INSERT INTO dim.Sexo (CodigoSexo, NombreSexo) VALUES (99, N'x')")]
    [InlineData("UPDATE dim.Sexo SET NombreSexo = N'x'")]
    [InlineData("DELETE FROM hechos.CensoMigracion")]
    [InlineData("TRUNCATE TABLE hechos.CensoMigracion")]
    [InlineData("DROP TABLE dim.Sexo")]
    [InlineData("CREATE TABLE dim.Intruso (Id INT)")]
    [InlineData("ALTER TABLE dim.Sexo ADD Intruso INT NULL")]
    [InlineData("EXEC sp_configure 'show advanced options', 1")]
    [InlineData("EXEC xp_cmdshell 'dir'")]
    public void No_puede_modificar_datos_ni_objetos_ni_ejecutar_comandos(string sql)
    {
        var numero = NumeroError(sql);
        Assert.NotNull(numero);
        Assert.Contains(numero, new int?[] { 229, 262, 297, 15247, 2760, 208, 1088, 3701, 2812 });
    }

    [Fact]
    public void Tras_los_intentos_hostiles_los_datos_siguen_intactos()
    {
        Assert.Equal(242_203, Escalar<long>("SELECT COUNT_BIG(*) FROM hechos.CensoMigracion"));
        Assert.Equal(2, Escalar<long>("SELECT COUNT_BIG(*) FROM dim.Sexo"));
    }
}
