using Censo.Dominio.Catalogo;

namespace Censo.Aplicacion.Catalogo;

/// <summary>Claves de los hechos del catalogo.</summary>
public static class ClavesHecho
{
    public const string Poblacion = "poblacion";
    public const string Hogar = "hogar";
    public const string Vivienda = "vivienda";
    public const string Migracion = "migracion";
}

/// <summary>Definicion de las dimensiones: los niveles por los que se puede agrupar o filtrar y como llega cada hecho a ellos.</summary>
internal static class DimensionesCatalogo
{
    private const string P = ClavesHecho.Poblacion;
    private const string H = ClavesHecho.Hogar;
    private const string V = ClavesHecho.Vivienda;
    private const string M = ClavesHecho.Migracion;

    private static readonly PasoUnion HogarDeHecho = new("hogar", "hechos.CensoHogar", "{a}.HogarId = {f}.HogarId");
    private static readonly PasoUnion ViviendaDeHecho = new("vivienda", "hechos.CensoVivienda", "{a}.ViviendaId = {f}.ViviendaId");
    private static readonly PasoUnion ViviendaViaHogar = new("vivienda_via_hogar", "hechos.CensoVivienda", "{a}.ViviendaId = {p}.ViviendaId");

    /// <summary>Forma de llegar desde un hecho a la tabla que contiene el dato.</summary>
    private enum Via
    {
        Directo,
        ViaHogar,
        ViaVivienda,
    }

    private sealed record Vin(string Hecho, string? Fk = null, Via Via = Via.Directo);

    public static IReadOnlyList<Dimension> Crear()
    {
        var d = new List<Dimension>();

        // ---------- Territorio y edad ----------
        d.Add(Territorio());
        d.Add(Edad());

        // ---------- Personas ----------
        d.Add(Simple("sexo", "Sexo", "Sexo", "Sexo de la persona; en migracion, del emigrante.", new Vin(P, "SexoId"), new Vin(M, "SexoId")));
        d.Add(Simple("parentesco", "Parentesco con la jefatura", "Parentesco", "Relacion de la persona con la jefa o el jefe del hogar.", new Vin(P, "ParentescoId")));
        d.Add(Simple("estadoConyugal", "Estado conyugal", "EstadoConyugal", "Estado conyugal de las personas de 10 anios o mas.", new Vin(P, "EstadoConyugalId")));
        d.Add(Simple("pueblo", "Pueblo de pertenencia", "Pueblo", "Pueblo con el que se autoidentifica la persona.", new Vin(P, "PuebloId")));
        d.Add(Simple("comunidadLinguistica", "Comunidad linguistica", "ComunidadLinguistica", "Comunidad linguistica maya de quienes se identifican como mayas.", new Vin(P, "ComunidadLinguisticaId")));
        d.Add(Simple("condicionActividad", "Condicion de actividad", "CondicionActividad", "Ocupada, desocupada aspirante, desocupada cesante, inactiva o no declarada (personas de 7 anios o mas).", new Vin(P, "CondicionActividadId")));
        d.Add(Simple("categoriaOcupacional", "Categoria ocupacional", "CategoriaOcupacional", "Relacion de la persona ocupada con su trabajo.", new Vin(P, "CategoriaOcupacionalId")));
        d.Add(Simple("actividadSemana", "Actividad de la semana pasada", "ActividadSemana", "Que hizo la persona la semana anterior al censo.", new Vin(P, "ActividadSemanaId")));
        d.Add(Simple("actividadNoTrabajo", "Actividad de quien no trabajo", "ActividadNoTrabajo", "Que hizo la semana pasada quien no trabajo.", new Vin(P, "ActividadNoTrabajoId")));
        d.Add(Simple("tipoEstablecimiento", "Tipo de establecimiento educativo", "TipoEstablecimiento", "Publico, privado, municipal o cooperativa.", new Vin(P, "TipoEstablecimientoId")));
        d.Add(Simple("causaNoAsistencia", "Causa por la que no asiste a estudiar", "CausaNoAsistencia", "Causa principal de no asistir a un establecimiento educativo.", new Vin(P, "CausaNoAsistenciaId")));
        d.Add(ConClasificacion("tipoResidencia2013", "Residencia en abril de 2013", "TipoResidencia2013", "Donde residia la persona en abril de 2013.",
            new Vin(P, "TipoResidencia2013Id"),
            LugarCensal("lugarResidencia2013", "Lugar de residencia en abril de 2013 (clasificacion de los cuadros del INE)", "TipoResidencia2013", 3, "PaisResidencia2013Id",
                (1, "No habia nacido"), (2, "En el mismo municipio"), (3, "En otro municipio"), (4, "En otro pais"), (9, "No declarado"))));

        d.Add(Simple("idiomaMaterno", "Idioma en que aprendio a hablar", "Idioma", "Idioma materno de la persona.", new Vin(P, "IdiomaMaternoId")));
        for (var i = 1; i <= 3; i++)
        {
            d.Add(Simple($"idiomaLecturaEscritura{i}", $"Idioma en que sabe leer y escribir ({i})", "Idioma", $"Idioma {i} en que la persona sabe leer y escribir.", new Vin(P, $"IdiomaLecturaEscritura{i}Id")));
            d.Add(Simple($"otroIdioma{i}", $"Otro idioma que habla ({i})", "Idioma", $"Idioma {i}, ademas del materno, que la persona sabe hablar.", new Vin(P, $"OtroIdioma{i}Id")));
        }

        foreach (var (clave, nombre, fk) in new[]
        {
            ("dificultadVer", "Dificultad para ver", "DificultadVerId"),
            ("dificultadOir", "Dificultad para oir", "DificultadOirId"),
            ("dificultadCaminar", "Dificultad para caminar o subir escaleras", "DificultadCaminarId"),
            ("dificultadRecordar", "Dificultad para recordar o concentrarse", "DificultadRecordarId"),
            ("dificultadCuidadoPersonal", "Dificultad para el cuidado personal", "DificultadCuidadoPersonalId"),
            ("dificultadComunicarse", "Dificultad para comunicarse", "DificultadComunicarseId"),
        })
        {
            d.Add(Simple(clave, nombre, "GradoDificultad", nombre + " (grado).", new Vin(P, fk)));
        }

        d.Add(Simple("condicionDificultad", "Condicion de dificultad", "CondicionDificultad",
            "Sin dificultad, con al menos una dificultad o no declarado, segun las 6 preguntas de dificultad (personas de 4 anios o mas; cuadro A8).",
            new Vin(P, "CondicionDificultadId")));

        foreach (var (clave, nombre, fk) in new[]
        {
            ("inscripcionRenap", "Inscripcion en el RENAP", "InscripcionRenapId"),
            ("usoTrajeTradicional", "Uso de traje tradicional", "UsoTrajeTradicionalId"),
            ("usoCelular", "Uso de celular", "UsoCelularId"),
            ("usoComputadora", "Uso de computadora", "UsoComputadoraId"),
            ("usoInternet", "Uso de internet", "UsoInternetId"),
        })
        {
            d.Add(Simple(clave, nombre, "RespuestaSiNo", nombre + " (Si, No o No declarado).", new Vin(P, fk)));
        }

        d.Add(NivelEducativo());
        d.Add(Ocupacion());
        d.Add(RamaActividad());

        // Lugar de nacimiento, residencia en 2013, estudio y trabajo
        foreach (var (sufijo, etiqueta, tipoFk, depFk, munFk, paisFk) in new[]
        {
            ("Nacimiento", "de nacimiento", "TipoLugarNacimientoId", "DepartamentoNacimientoId", "MunicipioNacimientoId", "PaisNacimientoId"),
            ("Residencia2013", "de residencia en 2013", null, "DepartamentoResidencia2013Id", "MunicipioResidencia2013Id", "PaisResidencia2013Id"),
            ("Estudio", "donde estudia", "TipoLugarEstudioId", "DepartamentoEstudioId", "MunicipioEstudioId", "PaisEstudioId"),
            ("Trabajo", "donde trabaja", "TipoLugarTrabajoId", "DepartamentoTrabajoId", "MunicipioTrabajoId", "PaisTrabajoId"),
        })
        {
            if (tipoFk is not null)
            {
                d.Add(ConClasificacion($"tipoLugar{sufijo}", $"Tipo de lugar {etiqueta}", "TipoLugar", $"Si el lugar {etiqueta} es el mismo municipio u otro.",
                    new Vin(P, tipoFk),
                    LugarCensal($"lugar{sufijo}", $"Lugar {etiqueta} (clasificacion de los cuadros del INE)", "TipoLugar", 2, paisFk,
                        (1, "En el mismo municipio"), (2, "En otro municipio"), (3, "En otro pais"), (9, "No declarado"))));
            }

            d.Add(Simple($"departamento{sufijo}", $"Departamento {etiqueta}", "Departamento", $"Departamento {etiqueta}.", new Vin(P, depFk)));
            d.Add(Simple($"municipio{sufijo}", $"Municipio {etiqueta}", "Municipio", $"Municipio {etiqueta}.", new Vin(P, munFk)));
            d.Add(Simple($"pais{sufijo}", $"Pais {etiqueta}", "Pais", $"Pais {etiqueta}.", new Vin(P, paisFk)));
        }

        foreach (var (clave, nombre, columna) in new[]
        {
            ("esAlfabeta", "Alfabetismo", "EsAlfabeta"),
            ("esEstudiante", "Asiste a un establecimiento educativo", "EsEstudiante"),
            ("tieneOtroIdioma", "Habla otro idioma", "TieneOtroIdioma"),
            ("esTrabajadorSemanaPasada", "Trabajo la semana pasada", "EsTrabajadorSemanaPasada"),
            ("esVivoUltimoHijo", "Su ultimo hijo esta vivo", "EsVivoUltimoHijo"),
            ("esMigranteVida", "Migrante de toda la vida", "EsMigranteVida"),
            ("esMigranteReciente", "Migrante reciente", "EsMigranteReciente"),
        })
        {
            d.Add(Booleana(clave, nombre, nombre + " (Si o No).", columna, new Vin(P)));
        }

        d.Add(Fecundidad());

        // ---------- Hogar (accesibles desde la persona y el emigrante a traves del hogar) ----------
        d.Add(Simple("tipoHogar", "Tipologia del hogar", "TipoHogar",
            "Unipersonal, nuclear, extendido, compuesto o co-residentes, segun el parentesco de los miembros (cuadro B8).",
            new Vin(H, "TipoHogarId"), new Vin(P, "TipoHogarId", Via.ViaHogar), new Vin(M, "TipoHogarId", Via.ViaHogar)));
        d.Add(CuartosHogar());

        foreach (var (clave, nombre, tabla, fk) in new[]
        {
            ("tenenciaVivienda", "Tenencia de la vivienda", "TenenciaVivienda", "TenenciaViviendaId"),
            ("fuenteAgua", "Fuente de agua", "FuenteAgua", "FuenteAguaId"),
            ("tipoServicioSanitario", "Tipo de servicio sanitario", "TipoServicioSanitario", "TipoServicioSanitarioId"),
            ("usoServicioSanitario", "Uso del servicio sanitario", "UsoServicioSanitario", "UsoServicioSanitarioId"),
            ("desagueAguasGrises", "Desague de aguas grises", "DesagueAguasGrises", "DesagueAguasGrisesId"),
            ("tipoAlumbrado", "Tipo de alumbrado", "TipoAlumbrado", "TipoAlumbradoId"),
            ("eliminacionBasura", "Eliminacion de basura", "EliminacionBasura", "EliminacionBasuraId"),
            ("combustibleCocina", "Combustible para cocinar", "CombustibleCocina", "CombustibleCocinaId"),
            ("sexoPropietario", "Sexo de la persona propietaria", "SexoResponsable", "SexoPropietarioId"),
            ("sexoDecisiones", "Sexo de quien toma las decisiones", "SexoResponsable", "SexoDecisionesId"),
        })
        {
            d.Add(Simple(clave, nombre, tabla, nombre + " del hogar.", new Vin(H, fk), new Vin(P, fk, Via.ViaHogar), new Vin(M, fk, Via.ViaHogar)));
        }

        foreach (var (clave, nombre, columna) in new[]
        {
            ("tieneRadio", "Tiene radio", "TieneRadio"),
            ("tieneEstufa", "Tiene estufa", "TieneEstufa"),
            ("tieneTelevisor", "Tiene televisor", "TieneTelevisor"),
            ("tieneCable", "Tiene servicio de cable", "TieneCable"),
            ("tieneRefrigeradora", "Tiene refrigeradora", "TieneRefrigeradora"),
            ("tieneTanqueAgua", "Tiene tanque o deposito de agua", "TieneTanqueAgua"),
            ("tieneLavadora", "Tiene lavadora de ropa", "TieneLavadora"),
            ("tieneComputadora", "Tiene computadora", "TieneComputadora"),
            ("tieneInternet", "Tiene servicio de internet", "TieneInternet"),
            ("tieneTemazcal", "Tiene temazcal o tuj", "TieneTemazcal"),
            ("tieneAguaCaliente", "Tiene sistema de agua caliente", "TieneAguaCaliente"),
            ("tieneMoto", "Tiene moto", "TieneMoto"),
            ("tieneCarro", "Tiene carro", "TieneCarro"),
            ("tieneCuartoCocina", "Tiene cuarto exclusivo para cocinar", "TieneCuartoCocina"),
            ("tieneRemesas", "Recibe remesas", "TieneRemesas"),
            ("tieneEmigrantes", "Tiene emigrantes", "TieneEmigrantes"),
        })
        {
            d.Add(Booleana(clave, nombre, nombre + " (Si o No), del hogar.", columna, new Vin(H), new Vin(P, null, Via.ViaHogar), new Vin(M, null, Via.ViaHogar)));
        }

        // ---------- Vivienda (accesibles desde el hogar, la persona y el emigrante) ----------
        foreach (var (clave, nombre, tabla, fk) in new[]
        {
            ("tipoVivienda", "Tipo de vivienda", "TipoVivienda", "TipoViviendaId"),
            ("materialPared", "Material de las paredes", "MaterialPared", "MaterialParedId"),
            ("materialTecho", "Material del techo", "MaterialTecho", "MaterialTechoId"),
            ("materialPiso", "Material del piso", "MaterialPiso", "MaterialPisoId"),
            ("condicionVivienda", "Condicion de la vivienda", "CondicionVivienda", "CondicionViviendaId"),
        })
        {
            d.Add(Simple(clave, nombre, tabla, nombre + " de la vivienda.", new Vin(V, fk), new Vin(H, fk, Via.ViaVivienda), new Vin(P, fk, Via.ViaVivienda), new Vin(M, fk, Via.ViaVivienda)));
        }

        d.Add(Booleana("esUrbano", "Area urbana", "Area urbana (Si) o rural (No) de la vivienda.", "EsUrbano",
            new Vin(V), new Vin(H, null, Via.ViaVivienda), new Vin(P, null, Via.ViaVivienda), new Vin(M, null, Via.ViaVivienda)));

        return d;
    }

    // ---------------------------------------------------------------- dimensiones con jerarquia

    private static Dimension Territorio()
    {
        var niveles = new[]
        {
            new NivelDimension("lugarPoblado", "Lugar poblado", 0, "{a}.CodigoLugarPoblado", "{a}.NombreLugarPoblado", TipoValor.Entero),
            new NivelDimension("municipio", "Municipio", 1, "{a}.CodigoMunicipio", "{a}.NombreMunicipio", TipoValor.Entero),
            new NivelDimension("departamento", "Departamento", 2, "{a}.CodigoDepartamento", "{a}.NombreDepartamento", TipoValor.Entero),
        };
        var jerarquia = new[]
        {
            new PasoUnion("territorio.municipio", "dim.Municipio", "{a}.MunicipioId = {p}.MunicipioId"),
            new PasoUnion("territorio.departamento", "dim.Departamento", "{a}.DepartamentoId = {p}.DepartamentoId"),
        };
        var vinculos = new[] { P, H, V, M }
            .Select(h => new VinculoDimension(h, new[] { new PasoUnion($"territorio.base.{h}", "dim.LugarPoblado", "{a}.LugarPobladoId = {f}.LugarPobladoId") }))
            .ToArray();

        return new Dimension("territorio", "Territorio", "Departamento, municipio y lugar poblado donde esta la vivienda.", niveles, jerarquia, vinculos);
    }

    private static Dimension Edad()
    {
        var niveles = new[]
        {
            new NivelDimension("edad", "Edad en anios cumplidos", 0, "{a}.EdadId", "CAST({a}.EdadId AS NVARCHAR(3))", TipoValor.Entero),
            new NivelDimension("grupoQuinquenal", "Grupo quinquenal de edad", 0, null, "{a}.GrupoQuinquenal", TipoValor.Texto, "{a}.OrdenGrupoQuinquenal"),
            new NivelDimension("grupoAmplio", "Grupo amplio de edad", 0, null, "{a}.GrupoAmplio", TipoValor.Texto,
                "CASE {a}.GrupoAmplio WHEN N'0-14' THEN 1 WHEN N'15-64' THEN 2 ELSE 3 END"),
        };
        var vinculos = new[] { P, M }
            .Select(h => new VinculoDimension(h, new[] { new PasoUnion($"edad.base.{h}", "dim.Edad", "{a}.EdadId = {f}.EdadId") }))
            .ToArray();

        return new Dimension("edad", "Edad", "Edad en anios, grupos quinquenales (0-4, 5-9, ...) y grupos amplios (0-14, 15-64, 65 y mas); en migracion, la edad al irse.", niveles, Array.Empty<PasoUnion>(), vinculos);
    }

    private static Dimension NivelEducativo()
    {
        var niveles = new[]
        {
            new NivelDimension("nivelEducativo", "Nivel educativo", 0, "{a}.CodigoNivelEducativo", "{a}.NombreNivelEducativo", TipoValor.Entero),
            new NivelDimension("nivelGrado", "Nivel y grado de estudios", 0, "{a}.CodigoNivelGrado", "{a}.NombreNivelGrado", TipoValor.Entero),
            Clasificacion("nivelEducativoCensal", "Nivel educativo (clasificacion de los cuadros del INE)",
                "CASE WHEN {a}.CodigoNivelGrado = 10 THEN 1 WHEN {a}.CodigoNivelGrado = 20 THEN 2 WHEN {a}.CodigoNivelGrado BETWEEN 31 AND 33 THEN 3 " +
                "WHEN {a}.CodigoNivelGrado BETWEEN 34 AND 35 THEN 4 WHEN {a}.CodigoNivelGrado = 36 THEN 5 WHEN {a}.CodigoNivelGrado BETWEEN 41 AND 43 THEN 6 " +
                "WHEN {a}.CodigoNivelGrado BETWEEN 44 AND 46 THEN 7 WHEN {a}.CodigoNivelGrado BETWEEN 51 AND 55 THEN 8 WHEN {a}.CodigoNivelGrado BETWEEN 61 AND 72 THEN 9 END",
                (1, "Ninguno"), (2, "Preprimaria"), (3, "Primaria 1-3"), (4, "Primaria 4-5"), (5, "Primaria 6"), (6, "Basico"),
                (7, "Diversificado"), (8, "Licenciatura"), (9, "Maestria o doctorado")),
        };
        return new Dimension("nivelEducativo", "Nivel educativo", "Nivel de estudios mas alto aprobado y su grado.", niveles, Array.Empty<PasoUnion>(),
            new[] { Directo("nivelEducativo", "NivelGrado", new Vin(P, "NivelGradoId")) });
    }

    private static Dimension Ocupacion()
    {
        var niveles = new[]
        {
            new NivelDimension("grupoOcupacion", "Grupo de ocupacion (1 digito)", 0, "{a}.CodigoGrupoOcupacion", "{a}.NombreGrupoOcupacion", TipoValor.Entero),
            new NivelDimension("ocupacion", "Ocupacion (2 digitos)", 0, "{a}.CodigoOcupacion", "{a}.NombreOcupacion", TipoValor.Entero),
        };
        return new Dimension("ocupacion", "Ocupacion", "Ocupacion principal a 1 y 2 digitos.", niveles, Array.Empty<PasoUnion>(),
            new[] { Directo("ocupacion", "Ocupacion", new Vin(P, "OcupacionId")) });
    }

    private static Dimension RamaActividad()
    {
        var niveles = new[]
        {
            new NivelDimension("grupoRamaActividad", "Grupo de rama de actividad (1 digito)", 0, "{a}.CodigoGrupoRamaActividad", "{a}.NombreGrupoRamaActividad", TipoValor.Entero),
            new NivelDimension("ramaActividad", "Rama de actividad (2 digitos)", 0, "{a}.CodigoRamaActividad", "{a}.NombreRamaActividad", TipoValor.Entero),
        };
        return new Dimension("ramaActividad", "Rama de actividad economica", "Rama de actividad economica a 1 y 2 digitos.", niveles, Array.Empty<PasoUnion>(),
            new[] { Directo("ramaActividad", "RamaActividad", new Vin(P, "RamaActividadId")) });
    }

    /// <summary>Hijos e hijas de las mujeres de 15 anios o mas: columnas del propio hecho agrupadas como en el cuadro A14.</summary>
    private static Dimension Fecundidad()
    {
        var niveles = new[]
        {
            Conteo("hijosNacidosVivos", "Hijos nacidos vivos", "HijosNacidosVivos", 5),
            Conteo("hijosSobrevivientes", "Hijos vivos actualmente", "HijosSobrevivientes", 5),
            Clasificacion("edadPrimerHijo", "Edad de la madre al nacer su primer hijo",
                "CASE WHEN {a}.EdadPrimerHijo < 15 THEN 1 WHEN {a}.EdadPrimerHijo <= 17 THEN 2 WHEN {a}.EdadPrimerHijo <= 19 THEN 3 " +
                "WHEN {a}.EdadPrimerHijo <= 24 THEN 4 WHEN {a}.EdadPrimerHijo <= 29 THEN 5 WHEN {a}.EdadPrimerHijo >= 30 THEN 6 END",
                (1, "Antes de 15"), (2, "15-17 anios"), (3, "18-19 anios"), (4, "20-24 anios"), (5, "25-29 anios"), (6, "30 anios o mas")),
        };
        return new Dimension("fecundidad", "Fecundidad", "Hijos nacidos vivos, hijos vivos y edad al primer hijo de las mujeres de 15 anios o mas (sin dato: no aplica o no declarado).",
            niveles, Array.Empty<PasoUnion>(), new[] { new VinculoDimension(P, Array.Empty<PasoUnion>()) });
    }

    /// <summary>Numero de cuartos y de dormitorios del hogar, agrupados como en el cuadro B7.</summary>
    private static Dimension CuartosHogar()
    {
        var niveles = new[]
        {
            Conteo("numeroCuartos", "Numero de cuartos", "TotalCuartos", 7),
            Conteo("numeroDormitorios", "Numero de dormitorios", "TotalDormitorios", 7),
        };
        return new Dimension("cuartosHogar", "Cuartos del hogar", "Numero de cuartos y de dormitorios que usa el hogar (7 o mas agrupados).", niveles, Array.Empty<PasoUnion>(),
            new[] { new Vin(H), new Vin(P, null, Via.ViaHogar), new Vin(M, null, Via.ViaHogar) }
                .Select(v => new VinculoDimension(v.Hecho, PasosHasta(v.Via, v.Hecho))).ToArray());
    }

    // ---------------------------------------------------------------- constructores

    /// <summary>Nivel cuyos miembros se calculan con una expresion de codigo y reciben la etiqueta de una lista fija.</summary>
    private static NivelDimension Clasificacion(string clave, string nombre, string expresionCodigo, params (int Codigo, string Etiqueta)[] miembros)
    {
        var etiqueta = "CASE " + expresionCodigo + " " + string.Join(" ", miembros.Select(m => $"WHEN {m.Codigo} THEN N'{m.Etiqueta}'")) + " END";
        return new NivelDimension(clave, nombre, 0, expresionCodigo, etiqueta, TipoValor.Entero);
    }

    /// <summary>Conteo de una columna numerica del hecho con los valores altos agrupados (por ejemplo "5 o mas").</summary>
    private static NivelDimension Conteo(string clave, string nombre, string columna, int tope) =>
        new(clave, nombre, 0, $"CASE WHEN {{a}}.{columna} >= {tope} THEN {tope} ELSE {{a}}.{columna} END",
            $"CASE WHEN {{a}}.{columna} >= {tope} THEN N'{tope} o mas' ELSE CAST({{a}}.{columna} AS NVARCHAR(3)) END", TipoValor.Entero);

    /// <summary>Clasificacion de lugar de los cuadros del INE: separa "otro municipio" de "otro pais" segun si hay pais registrado.</summary>
    private static NivelDimension LugarCensal(string clave, string nombre, string tabla, int codigoOtroLugar, string paisFk, params (int Codigo, string Etiqueta)[] miembros)
    {
        var codigoPais = miembros.Single(m => m.Etiqueta == "En otro pais").Codigo;
        return Clasificacion(clave, nombre,
            $"CASE WHEN {{a}}.Codigo{tabla} = {codigoOtroLugar} AND {{f}}.{paisFk} IS NOT NULL THEN {codigoPais} ELSE {{a}}.Codigo{tabla} END", miembros);
    }

    /// <summary>Dimension simple con un segundo nivel que reclasifica sus miembros.</summary>
    private static Dimension ConClasificacion(string clave, string nombre, string tabla, string descripcion, Vin vinculo, NivelDimension clasificacion)
    {
        var nivel = new NivelDimension(clave, nombre, 0, $"{{a}}.Codigo{tabla}", $"{{a}}.Nombre{tabla}", TipoValor.Entero);
        return new Dimension(clave, nombre, descripcion, new[] { nivel, clasificacion }, Array.Empty<PasoUnion>(), new[] { Directo(clave, tabla, vinculo) });
    }

    /// <summary>Dimension de un solo nivel con la forma habitual: tabla dim.X con XId, CodigoX y NombreX.</summary>
    private static Dimension Simple(string clave, string nombre, string tabla, string descripcion, params Vin[] vinculos)
    {
        var nivel = new NivelDimension(clave, nombre, 0, $"{{a}}.Codigo{tabla}", $"{{a}}.Nombre{tabla}", TipoValor.Entero);
        return new Dimension(clave, nombre, descripcion, new[] { nivel }, Array.Empty<PasoUnion>(),
            vinculos.Select(v => Directo(clave, tabla, v)).ToArray());
    }

    /// <summary>Dimension booleana: una columna BIT del hecho (o de su hogar o vivienda) presentada como Si o No.</summary>
    private static Dimension Booleana(string clave, string nombre, string descripcion, string columna, params Vin[] vinculos)
    {
        var nivel = new NivelDimension(clave, nombre, 0, $"CAST({{a}}.{columna} AS INT)", $"CASE {{a}}.{columna} WHEN 1 THEN N'Si' WHEN 0 THEN N'No' END", TipoValor.Entero);
        return new Dimension(clave, nombre, descripcion, new[] { nivel }, Array.Empty<PasoUnion>(),
            vinculos.Select(v => new VinculoDimension(v.Hecho, PasosHasta(v.Via, v.Hecho))).ToArray());
    }

    private static VinculoDimension Directo(string clave, string tabla, Vin v)
    {
        var baseId = $"{clave}.base.{v.Hecho}.{v.Via}.{v.Fk}";
        var pasos = PasosHasta(v.Via, v.Hecho).ToList();
        var origen = pasos.Count == 0 ? "{f}" : "{p}";
        pasos.Add(new PasoUnion(baseId, $"dim.{tabla}", $"{{a}}.{tabla}Id = {origen}.{v.Fk}"));
        return new VinculoDimension(v.Hecho, pasos);
    }

    /// <summary>Pasos previos que llevan del hecho a la tabla que contiene el dato (hogar o vivienda); vacio si esta en el propio hecho.</summary>
    private static IReadOnlyList<PasoUnion> PasosHasta(Via via, string hecho) => via switch
    {
        Via.Directo => Array.Empty<PasoUnion>(),
        Via.ViaHogar => new[] { HogarDeHecho },
        Via.ViaVivienda when hecho == M => new[] { HogarDeHecho, ViviendaViaHogar },
        Via.ViaVivienda => new[] { ViviendaDeHecho },
        _ => throw new ArgumentOutOfRangeException(nameof(via)),
    };
}
