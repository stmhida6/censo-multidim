using Censo.Dominio.Catalogo;

namespace Censo.Aplicacion.Consultas;

/// <summary>Nivel de dimension por el que se agrupa.</summary>
public sealed record AgrupacionPlan(Dimension Dimension, NivelDimension Nivel);

/// <summary>Filtro ya validado: los valores estan normalizados a long o string segun el tipo del nivel.</summary>
public sealed record FiltroPlan(Dimension Dimension, NivelDimension Nivel, OperadorFiltro Operador, IReadOnlyList<object> Valores);

/// <summary>
/// Solicitud que ya paso la validacion contra el catalogo: solo contiene elementos del catalogo y valores normalizados.
/// Es lo unico que el constructor de SQL acepta.
/// </summary>
/// <param name="MedidasSolicitadas">Medidas pedidas explicitamente; se devuelven en el resultado.</param>
/// <param name="MedidasConsultadas">Las solicitadas mas las que necesitan los indicadores; todas se calculan.</param>
public sealed record PlanConsulta(
    Hecho Hecho,
    IReadOnlyList<AgrupacionPlan> Agrupaciones,
    IReadOnlyList<Medida> MedidasSolicitadas,
    IReadOnlyList<Medida> MedidasConsultadas,
    IReadOnlyList<Indicador> Indicadores,
    IReadOnlyList<FiltroPlan> Filtros,
    int Limite,
    bool IncluirComponentes);
