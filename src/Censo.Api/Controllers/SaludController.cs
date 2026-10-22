using Censo.Dominio.Consultas;
using Censo.Dominio.Contratos;
using Microsoft.AspNetCore.Mvc;

namespace Censo.Api.Controllers;

/// <summary>Comprobacion de que la API responde y llega a la base de datos.</summary>
[ApiController]
[Route("salud")]
public class SaludController : ControllerBase
{
    private static readonly ConsultaSql Sonda = new("SELECT 1 AS ok", new Dictionary<string, object?>());

    private readonly IRepositorioConsultas _repositorio;

    public SaludController(IRepositorioConsultas repositorio) => _repositorio = repositorio;

    [HttpGet]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status503ServiceUnavailable)]
    public async Task<IActionResult> Obtener(CancellationToken cancelacion)
    {
        try
        {
            await _repositorio.EjecutarAsync(Sonda, cancelacion);
            return Ok(new { estado = "ok" });
        }
        catch (ConsultaFallidaException)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new { estado = "sin conexion a la base de datos" });
        }
    }
}
