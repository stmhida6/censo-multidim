# Convenciones y decisiones de diseño

Reglas que sigue el código y que las pruebas de esquema (`pruebas/Censo.Pruebas.BaseDatos`, categoría `Esquema`) hacen cumplir: si se agrega una tabla, columna o restricción que no las siga, las pruebas fallan.

## Stack

| Capa | Tecnología | Decisión |
|---|---|---|
| Base de datos | SQL Server 2022 en Docker (`mcr.microsoft.com/mssql/server:2022-latest`); Azure SQL Database en la nube | Esquema en estrella para análisis multidimensional |
| API | ASP.NET Core 8 (Web API), C# | Controladores tradicionales en `Controllers/` |
| Acceso a datos | Dapper | Control explícito sobre el SQL parametrizado que genera el motor de consultas; no se usa Entity Framework Core |
| ETL | R (solo para leer los `.sav` y exportar a CSV) y T-SQL (`BULK INSERT` y transformación dentro de SQL Server) | R no forma parte del entorno de producción |
| Visualización | Power BI Desktop, consumiendo la API | Los indicadores no se recalculan en DAX: solo se re-agregan con el numerador y el denominador que devuelve la API |
| Orquestación local | Docker Compose | SQL Server, la API y k6 (perfil `pruebas`) |

## Idioma

Todo el esquema de base de datos y el código C# (proyectos, clases, métodos, propiedades y espacios de nombres) se escriben en **español sin tildes**, en PascalCase. Los métodos de prueba son frases descriptivas con guiones bajos (`Toda_tabla_tiene_clave_primaria`).

## Esquemas de SQL Server

| Esquema | Contenido |
|---|---|
| `dim` | Tablas de dimensión |
| `hechos` | Tablas de hechos |
| `stage` | Datos crudos del ETL; conserva los nombres de las variables del INE (`LUGAR_POBLADO`, `PCP7`) para rastrear cada columna hasta el `.sav`. Se recrea en cada carga |
| `seg` | Seguridad y auditoría |

## Nombres

| Elemento | Regla | Ejemplo |
|---|---|---|
| Dimensión | `Dim` + nombre en singular | `Dim.Departamento`, `Dim.GrupoEtnico` |
| Hecho | `Hechos` + proceso en singular | `Hechos.CensoPoblacion` |
| Llave sustituta | `<Tabla>Id` | `DepartamentoId` |
| Llave de negocio (código del INE) | Sufijo `Codigo` | `CodigoDepartamento` |
| Llave foránea | Mismo nombre que la PK de la dimensión; si una dimensión se usa varias veces, un nombre de rol | `MunicipioId`, `MunicipioNacimientoId` |
| Medida | Nombre descriptivo, sin abreviaturas ambiguas | `TotalPersonas` |
| Booleano | Prefijo `Es` o `Tiene` | `EsUrbano`, `TieneEnergiaElectrica` |
| Auditoría (todas las tablas) | `FechaCreacion`, `FechaModificacion`, `UsuarioCreacion` | |
| Vistas, procedimientos y funciones | Prefijos `Vw`, `Sp` + verbo en infinitivo, `Fn` | `Sp.CargarDimensionMunicipio` |
| Restricciones e índices (incluyen el esquema) | `PK_<Tabla>`, `FK_<Origen>_<Destino>[_<Columna>]`, `UQ_<Tabla>_<Columna>`, `IX_<Tabla>_<Columnas>` | `PK_Dim_Departamento`, `FK_Hechos_CensoHogar_Dim_FuenteAgua` |

## Decisiones de implementación

- **Llaves:** `SMALLINT IDENTITY` en las dimensiones e `INT` en los hechos. `Dim.Edad` usa la edad en años como llave (`TINYINT`, sin `IDENTITY`).
- **Hechos:** la PK es `NONCLUSTERED` para permitir un índice columnstore agrupado.
- **Valores nulos:** `NULL` significa "no aplica" (salto del cuestionario); "No declarado" es un miembro de la dimensión; los códigos centinela (`99`, `9999`) se guardan como `NULL`.
- **Orden de los scripts:** las PK se crean con la tabla (`db/02-dimensiones`); las FK, las restricciones únicas y los índices van en `db/03-indices`. Las tablas de dimensión y de hechos conviven en `02-dimensiones` y se distinguen por el prefijo.
- **Clasificaciones del INE que no están en los microdatos** se derivan en el ETL como dimensiones propias (`Dim.CondicionActividad`, `Dim.TipoHogar`, `Dim.CondicionDificultad`) o, si solo reagrupan códigos, como niveles del catálogo de la API.
- **Codificación en la carga:** en SQL Server para Linux, `BULK INSERT` no admite `CODEPAGE` y lee los archivos de caracteres con la página OEM 437. Por eso los CSV con texto se escriben en UTF-16LE con BOM y se cargan con `DATAFILETYPE = 'widechar'`.
- **Confidencialidad estadística:** no se aplican restricciones por conteo mínimo de celda; se asume que los microdatos ya están anonimizados por el INE.

## API

- El **catálogo** (`src/Censo.Aplicacion/Catalogo/`) es la única fuente de lo que se puede consultar. Cada solicitud se valida contra él y el SQL se construye solo con sus fragmentos; los valores de los filtros van siempre como parámetros.
- Los **indicadores** son razón de agregados (numerador / denominador), calculados en C#; nunca un promedio de tasas.
- La API se conecta con el usuario **`CensoApi`**, de solo lectura (`SELECT` sobre `dim` y `hechos`), nunca con `sa`.
- Al agregar una dimensión, medida o indicador hay que actualizar `docs/catalogo.md` (se genera desde `GET /api/catalogo/*`) y las pruebas; la prueba de exactitud contra los 25 cuadros oficiales debe seguir en 0 diferencias.
- Al cambiar el modelo hay que actualizar también `pruebas/Censo.Pruebas.BaseDatos/ValoresEsperados.cs` y los diagramas de `docs/diagramas/` (Mermaid).
