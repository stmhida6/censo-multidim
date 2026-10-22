using System.Text;
using Censo.Dominio.Catalogo;
using Censo.Dominio.Consultas;
using Censo.Dominio.Contratos;

namespace Censo.Aplicacion.Consultas;

/// <summary>Columna del SELECT generado y su papel en el resultado.</summary>
/// <param name="Rol">dimension, dimensionCodigo o medida.</param>
public sealed record ColumnaSql(string Alias, string Rol, string Nombre, string Tipo);

/// <summary>SQL parametrizado junto con la descripcion de sus columnas.</summary>
public sealed record ConsultaConstruida(ConsultaSql Sql, IReadOnlyList<ColumnaSql> Columnas);

/// <summary>
/// Etapa de construccion de una consulta dinamica (tesis 2.4.5). Solo recibe un <see cref="PlanConsulta"/> validado y arma
/// el SQL exclusivamente con identificadores y expresiones del catalogo, que son constantes del programa; los valores de
/// los filtros nunca se concatenan: viajan como parametros (@p0, @p1, ...).
/// </summary>
public sealed class ConstructorConsultaSql
{
    private readonly ICatalogo _catalogo;

    public ConstructorConsultaSql(ICatalogo catalogo) => _catalogo = catalogo;

    public ConsultaConstruida Construir(PlanConsulta plan)
    {
        var contexto = new Contexto(plan.Hecho.Clave);
        var seleccion = new List<string>();
        var columnas = new List<ColumnaSql>();
        var agrupar = new List<string>();
        var ordenar = new List<string>();

        foreach (var (dimension, nivel) in plan.Agrupaciones)
        {
            var alias = contexto.AliasNivel(dimension, nivel);
            var etiqueta = Render(nivel.ExpresionEtiqueta, alias);
            var codigo = nivel.ExpresionCodigo is null ? null : Render(nivel.ExpresionCodigo, alias);

            seleccion.Add($"ISNULL(CAST({etiqueta} AS NVARCHAR(200)), N'No aplica') AS [{nivel.Clave}]");
            columnas.Add(new ColumnaSql(nivel.Clave, "dimension", nivel.Nombre, "texto"));
            AgregarUnico(agrupar, etiqueta);

            if (codigo is not null)
            {
                seleccion.Add($"{codigo} AS [{nivel.Clave}_codigo]");
                columnas.Add(new ColumnaSql($"{nivel.Clave}_codigo", "dimensionCodigo", $"{nivel.Nombre} (codigo)", "entero"));
                AgregarUnico(agrupar, codigo);
            }

            var orden = nivel.ExpresionOrden is null ? codigo ?? etiqueta : Render(nivel.ExpresionOrden, alias);
            AgregarUnico(agrupar, orden);
            ordenar.Add(orden);
        }

        foreach (var medida in plan.MedidasConsultadas)
        {
            seleccion.Add($"{Agregado(medida, contexto)} AS [{medida.Clave}]");
            columnas.Add(new ColumnaSql(medida.Clave, "medida", medida.Nombre, "entero"));
        }

        var condiciones = plan.Filtros.Select(f => Predicado(f.Dimension, f.Nivel, f.Operador, f.Valores, contexto)).ToList();

        var sql = new StringBuilder();
        sql.Append("SELECT TOP (@limite)\n    ").Append(string.Join(",\n    ", seleccion));
        sql.Append("\nFROM ").Append(plan.Hecho.Tabla).Append(" AS f");
        foreach (var (alias, paso, previo) in contexto.Uniones)
        {
            var on = paso.Condicion.Replace("{f}", "f").Replace("{p}", previo).Replace("{a}", alias);
            sql.Append("\nLEFT JOIN ").Append(paso.Tabla).Append(" AS ").Append(alias).Append(" ON ").Append(on);
        }

        if (condiciones.Count > 0)
            sql.Append("\nWHERE ").Append(string.Join("\n  AND ", condiciones));
        if (agrupar.Count > 0)
            sql.Append("\nGROUP BY ").Append(string.Join(", ", agrupar));
        if (ordenar.Count > 0)
            sql.Append("\nORDER BY ").Append(string.Join(", ", ordenar));

        // Se pide una fila mas que el limite para saber si el resultado se trunco.
        contexto.Parametros["limite"] = (long)plan.Limite + 1;
        return new ConsultaConstruida(new ConsultaSql(sql.ToString(), contexto.Parametros), columnas);
    }

    private string Agregado(Medida medida, Contexto contexto)
    {
        var valor = medida.ExpresionValor is null ? "CAST(1 AS BIGINT)" : $"CAST({Render(medida.ExpresionValor, "f")} AS BIGINT)";
        if (medida.Condiciones.Count == 0)
            return medida.ExpresionValor is null ? "COUNT_BIG(*)" : $"SUM({valor})";

        var predicados = medida.Condiciones.Select(c =>
        {
            var (dimension, nivel) = _catalogo.BuscarNivel(c.NivelClave)
                ?? throw new InvalidOperationException($"La medida '{medida.Clave}' usa el nivel '{c.NivelClave}', que no existe en el catalogo.");
            var valores = c.Valores.Select(v => nivel.TipoValor == TipoValor.Entero ? (object)Convert.ToInt64(v) : Convert.ToString(v)!).ToList();
            return Predicado(dimension, nivel, c.Operador, valores, contexto);
        });
        return $"SUM(CASE WHEN {string.Join(" AND ", predicados)} THEN {valor} ELSE CAST(0 AS BIGINT) END)";
    }

    private static string Predicado(Dimension dimension, NivelDimension nivel, OperadorFiltro operador, IReadOnlyList<object> valores, Contexto contexto)
    {
        var alias = contexto.AliasNivel(dimension, nivel);
        var expresion = Render(nivel.ExpresionCodigo ?? nivel.ExpresionEtiqueta, alias);
        var parametros = valores.Select(contexto.AgregarParametro).ToList();

        return operador switch
        {
            OperadorFiltro.Igual => $"{expresion} = {parametros[0]}",
            OperadorFiltro.Distinto => $"{expresion} <> {parametros[0]}",
            OperadorFiltro.En => $"{expresion} IN ({string.Join(", ", parametros)})",
            OperadorFiltro.NoEn => $"{expresion} NOT IN ({string.Join(", ", parametros)})",
            OperadorFiltro.Entre => $"{expresion} BETWEEN {parametros[0]} AND {parametros[1]}",
            OperadorFiltro.MayorOIgual => $"{expresion} >= {parametros[0]}",
            OperadorFiltro.MenorOIgual => $"{expresion} <= {parametros[0]}",
            _ => throw new ArgumentOutOfRangeException(nameof(operador)),
        };
    }

    private static string Render(string plantilla, string alias) => plantilla.Replace("{a}", alias).Replace("{f}", "f");

    private static void AgregarUnico(List<string> lista, string elemento)
    {
        if (!lista.Contains(elemento))
            lista.Add(elemento);
    }

    /// <summary>Estado de la construccion de una consulta: alias de las uniones y parametros.</summary>
    private sealed class Contexto
    {
        private readonly string _hechoClave;
        private readonly Dictionary<string, string> _aliasPorPaso = new();

        public Contexto(string hechoClave) => _hechoClave = hechoClave;

        public List<(string Alias, PasoUnion Paso, string Previo)> Uniones { get; } = new();

        public Dictionary<string, object?> Parametros { get; } = new();

        public string AgregarParametro(object valor)
        {
            var nombre = $"p{Parametros.Count}";
            Parametros[nombre] = valor;
            return "@" + nombre;
        }

        /// <summary>Alias de la tabla que contiene el nivel; registra las uniones necesarias para llegar a ella.</summary>
        public string AliasNivel(Dimension dimension, NivelDimension nivel)
        {
            var vinculo = dimension.VinculoCon(_hechoClave)
                ?? throw new InvalidOperationException($"La dimension '{dimension.Clave}' no esta vinculada al hecho '{_hechoClave}'.");
            var pasos = vinculo.Pasos.Concat(dimension.PasosJerarquia).ToList();
            var indice = vinculo.Pasos.Count - 1 + nivel.Paso;
            if (indice < 0)
                return "f";
            if (indice >= pasos.Count)
                throw new InvalidOperationException($"El nivel '{nivel.Clave}' pide un paso que la dimension '{dimension.Clave}' no tiene.");

            var previo = "f";
            for (var i = 0; i <= indice; i++)
            {
                var paso = pasos[i];
                if (!_aliasPorPaso.TryGetValue(paso.Id, out var alias))
                {
                    alias = $"j{_aliasPorPaso.Count}";
                    _aliasPorPaso[paso.Id] = alias;
                    Uniones.Add((alias, paso, previo));
                }

                previo = alias;
            }

            return previo;
        }
    }
}
