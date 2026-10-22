using Censo.Api.Modelos;
using Censo.Dominio.Catalogo;
using Censo.Dominio.Contratos;
using Microsoft.AspNetCore.Mvc;

namespace Censo.Api.Controllers;

/// <summary>
/// Descubrimiento del catalogo: que hechos, dimensiones, medidas e indicadores se pueden consultar. Un cliente (por
/// ejemplo Power BI) usa estas listas para armar solicitudes; el catalogo es la unica fuente de lo que se puede pedir.
/// </summary>
[ApiController]
[Route("api/catalogo")]
[Produces("application/json")]
public class CatalogoController : ControllerBase
{
    private readonly ICatalogo _catalogo;

    public CatalogoController(ICatalogo catalogo) => _catalogo = catalogo;

    /// <summary>Hechos sobre los que se consulta: personas, hogares, viviendas y emigrantes.</summary>
    [HttpGet("hechos")]
    public IEnumerable<HechoDto> Hechos() =>
        _catalogo.Hechos.Select(h => new HechoDto(h.Clave, h.Nombre, h.Descripcion, h.Grano));

    /// <summary>Dimensiones con sus niveles de agrupacion; con <c>hecho</c> solo las disponibles para ese hecho.</summary>
    [HttpGet("dimensiones")]
    public IEnumerable<DimensionDto> Dimensiones([FromQuery] string? hecho = null) =>
        _catalogo.Dimensiones
            .Where(d => hecho is null || d.VinculoCon(hecho) is not null)
            .Select(d => new DimensionDto(
                d.Clave, d.Nombre, d.Descripcion,
                d.Niveles.Select(n => new NivelDto(n.Clave, n.Nombre, n.ExpresionCodigo is not null, n.TipoValor.ToString())).ToList(),
                d.Vinculos.Select(v => v.HechoClave).ToList()));

    /// <summary>Medidas (conteos y sumas); con <c>hecho</c> solo las de ese hecho.</summary>
    [HttpGet("medidas")]
    public IEnumerable<MedidaDto> Medidas([FromQuery] string? hecho = null) =>
        _catalogo.Medidas
            .Where(m => hecho is null || m.HechoClave == hecho)
            .Select(m => new MedidaDto(m.Clave, m.Nombre, m.Descripcion, m.HechoClave, m.Unidad));

    /// <summary>Indicadores con su formula oficial; con <c>hecho</c> solo los de ese hecho.</summary>
    [HttpGet("indicadores")]
    public IEnumerable<IndicadorDto> Indicadores([FromQuery] string? hecho = null) =>
        _catalogo.Indicadores
            .Where(i => hecho is null || i.HechoClave == hecho)
            .Select(i => new IndicadorDto(i.Clave, i.Nombre, i.Descripcion, i.HechoClave, i.Formula, i.Fuente, i.Unidad, i.Multiplicador, i.NumeradorClave, i.DenominadorClave));

    /// <summary>Operadores admitidos en los filtros y el tipo de valor que aceptan.</summary>
    [HttpGet("operadores")]
    public IEnumerable<OperadorDto> Operadores() => new[]
    {
        new OperadorDto(nameof(OperadorFiltro.Igual), "Igual a un valor.", "1 valor", new[] { "Entero", "Texto" }),
        new OperadorDto(nameof(OperadorFiltro.Distinto), "Distinto de un valor.", "1 valor", new[] { "Entero", "Texto" }),
        new OperadorDto(nameof(OperadorFiltro.En), "Igual a alguno de varios valores.", $"1 a {Censo.Aplicacion.Consultas.ValidadorSolicitud.MaxValoresPorFiltro} valores", new[] { "Entero", "Texto" }),
        new OperadorDto(nameof(OperadorFiltro.NoEn), "Distinto de todos los valores.", $"1 a {Censo.Aplicacion.Consultas.ValidadorSolicitud.MaxValoresPorFiltro} valores", new[] { "Entero", "Texto" }),
        new OperadorDto(nameof(OperadorFiltro.Entre), "Entre dos valores, inclusive.", "2 valores", new[] { "Entero" }),
        new OperadorDto(nameof(OperadorFiltro.MayorOIgual), "Mayor o igual que un valor.", "1 valor", new[] { "Entero" }),
        new OperadorDto(nameof(OperadorFiltro.MenorOIgual), "Menor o igual que un valor.", "1 valor", new[] { "Entero" }),
    };
}
