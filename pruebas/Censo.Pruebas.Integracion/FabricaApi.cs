using Censo.Pruebas.BaseDatos.Ayudantes;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;

namespace Censo.Pruebas.Integracion;

/// <summary>
/// Arranca la API completa en memoria, conectada a la base CensoGT2018 del contenedor con el usuario de solo lectura CensoApi (como en produccion). Las variantes (otra configuracion o
/// servicios simulados) se obtienen con <c>WithWebHostBuilder</c>.
/// </summary>
public sealed class FabricaApi : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Development");
        builder.UseSetting("ConnectionStrings:CensoDb", ConexionPruebas.CadenaConexionApi);
        builder.UseSetting("LimiteSolicitudes:PorMinuto", "100000");
    }
}
