namespace Censo.Api.Modelos;

/// <summary>Descripcion publica de un hecho consultable.</summary>
public sealed record HechoDto(string Clave, string Nombre, string Descripcion, string Grano);

/// <summary>Nivel por el que se puede agrupar o filtrar; no expone nada del SQL interno.</summary>
public sealed record NivelDto(string Clave, string Nombre, bool TieneCodigo, string TipoValor);

public sealed record DimensionDto(string Clave, string Nombre, string Descripcion, IReadOnlyList<NivelDto> Niveles, IReadOnlyList<string> Hechos);

public sealed record MedidaDto(string Clave, string Nombre, string Descripcion, string Hecho, string Unidad);

public sealed record IndicadorDto(
    string Clave, string Nombre, string Descripcion, string Hecho, string Formula, string Fuente,
    string Unidad, decimal Multiplicador, string Numerador, string Denominador);

public sealed record OperadorDto(string Nombre, string Descripcion, string Valores, IReadOnlyList<string> TiposValor);
