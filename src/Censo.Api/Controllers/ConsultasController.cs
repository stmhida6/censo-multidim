using Censo.Aplicacion.Consultas;
using Censo.Dominio.Consultas;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace Censo.Api.Controllers;

/// <summary>Consultas multidimensionales sobre el Censo 2018.</summary>
[ApiController]
[Route("api/consultas")]
[Produces("application/json")]
[EnableRateLimiting(PoliticasLimite.Consultas)]
public class ConsultasController : ControllerBase
{
    private readonly IServicioConsultas _servicio;
    private readonly ILogger<ConsultasController> _registro;

    public ConsultasController(IServicioConsultas servicio, ILogger<ConsultasController> registro)
    {
        _servicio = servicio;
        _registro = registro;
    }

    /// <summary>
    /// Agrega medidas e indicadores del censo por los niveles de dimension y con los filtros pedidos. Todo se refiere a
    /// claves del catalogo (<c>GET api/catalogo/...</c>); una clave desconocida devuelve 400 con la lista de problemas.
    /// </summary>
    /// <param name="solicitud">Medidas, indicadores, niveles de agrupacion, filtros y limite de filas.</param>
    [HttpPost]
    [RequestSizeLimit(65_536)]
    [ProducesResponseType(typeof(ResultadoConsulta), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status400BadRequest)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status429TooManyRequests)]
    [ProducesResponseType(typeof(ProblemDetails), StatusCodes.Status504GatewayTimeout)]
    public async Task<IActionResult> Consultar([FromBody] SolicitudConsulta solicitud, CancellationToken cancelacion)
    {
        try
        {
            return Ok(await _servicio.ConsultarAsync(solicitud, cancelacion));
        }
        catch (SolicitudInvalidaException ex)
        {
            var problema = new ProblemDetails
            {
                Status = StatusCodes.Status400BadRequest,
                Title = "La solicitud no es valida.",
                Detail = "Corrija los errores indicados y vuelva a enviarla.",
            };
            problema.Extensions["errores"] = ex.Errores;
            return BadRequest(problema);
        }
        catch (ConsultaFallidaException ex) when (ex.TiempoAgotado)
        {
            _registro.LogWarning(ex, "Una consulta supero el tiempo de espera.");
            return Problema(StatusCodes.Status504GatewayTimeout, "La consulta tardo mas de lo permitido.",
                "Reduzca los niveles de agrupacion o agregue filtros para acotar el resultado.");
        }
        catch (ConsultaFallidaException ex)
        {
            _registro.LogError(ex, "La base de datos no pudo ejecutar una consulta valida.");
            return Problema(StatusCodes.Status500InternalServerError, "No se pudo procesar la consulta.",
                "Intente de nuevo mas tarde.");
        }
    }

    private ObjectResult Problema(int estado, string titulo, string detalle) =>
        new(new ProblemDetails { Status = estado, Title = titulo, Detail = detalle }) { StatusCode = estado };
}
