using System.Threading.RateLimiting;
using Censo.Aplicacion.Catalogo;
using Censo.Aplicacion.Consultas;
using Censo.Dominio.Contratos;
using Censo.Infraestructura.Persistencia;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

var builder = WebApplication.CreateBuilder(args);

var cadenaConexion = builder.Configuration.GetConnectionString("CensoDb")
    ?? throw new InvalidOperationException(
        "Falta la cadena de conexion 'ConnectionStrings:CensoDb'. Definala con la variable de entorno " +
        "ConnectionStrings__CensoDb (docker-compose ya lo hace) o con los secretos de usuario en desarrollo.");

builder.Services.AddControllers();
builder.Services.AddProblemDetails();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Composicion: el catalogo y el motor de consultas son sin estado; el repositorio abre una conexion por consulta.
builder.Services.AddSingleton<ICatalogo, CatalogoCenso>();
builder.Services.AddSingleton<ValidadorSolicitud>();
builder.Services.AddSingleton<ConstructorConsultaSql>();
builder.Services.AddSingleton<IRepositorioConsultas>(_ => new RepositorioConsultasSql(
    new OpcionesBaseDatos(cadenaConexion, builder.Configuration.GetValue("BaseDatos:TiempoEsperaSegundos", 60))));
builder.Services.AddSingleton<IServicioConsultas, ServicioConsultas>();

// Limitacion de solicitudes por cliente para proteger la disponibilidad (tesis 2.9, Tabla 13).
builder.Services.AddRateLimiter(opciones =>
{
    opciones.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    opciones.AddPolicy(PoliticasLimite.Consultas, contexto => RateLimitPartition.GetFixedWindowLimiter(
        contexto.Connection.RemoteIpAddress?.ToString() ?? "desconocido",
        _ => new FixedWindowRateLimiterOptions
        {
            PermitLimit = builder.Configuration.GetValue("LimiteSolicitudes:PorMinuto", 120),
            Window = TimeSpan.FromMinutes(1),
            QueueLimit = 0,
        }));
    opciones.OnRejected = async (contexto, cancelacion) =>
    {
        contexto.HttpContext.Response.StatusCode = StatusCodes.Status429TooManyRequests;
        await contexto.HttpContext.Response.WriteAsJsonAsync(new
        {
            status = 429,
            title = "Demasiadas solicitudes.",
            detail = "Espere un momento antes de volver a consultar.",
        }, cancelacion);
    };
});

var app = builder.Build();

// Errores no controlados: respuesta generica, sin trazas ni mensajes internos. Las solicitudes mal formadas o demasiado
// grandes conservan su codigo de estado (400 o 413); cualquier otra excepcion es un 500.
app.UseExceptionHandler(rama => rama.Run(async contexto =>
{
    var error = contexto.Features.Get<IExceptionHandlerFeature>()?.Error;
    var (estado, titulo) = error is BadHttpRequestException solicitud
        ? (solicitud.StatusCode, solicitud.StatusCode == StatusCodes.Status413PayloadTooLarge
            ? "El cuerpo de la solicitud es demasiado grande."
            : "La solicitud no se pudo leer.")
        : (StatusCodes.Status500InternalServerError, "Ocurrio un error al procesar la solicitud.");

    contexto.Response.StatusCode = estado;
    await contexto.Response.WriteAsJsonAsync(new ProblemDetails { Status = estado, Title = titulo }, contexto.RequestAborted);
}));

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseRateLimiter();
app.UseAuthorization();
app.MapControllers();

app.Run();

/// <summary>Nombres de las politicas de limitacion de solicitudes.</summary>
public static class PoliticasLimite
{
    public const string Consultas = "consultas";
}

// Necesario para que las pruebas de integracion puedan arrancar la aplicacion (WebApplicationFactory).
public partial class Program;
