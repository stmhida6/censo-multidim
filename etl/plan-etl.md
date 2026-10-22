# Plan de ETL — Censo 2018

> Basado en la revisión de los microdatos oficiales `.sav` (`datos/microdatos`, fuera del control de versiones) con R, y en `etl/jsonl/diccionario_variables_censo2018.jsonl`. Ver `docs/estado-proyecto.md` para el estado general del proyecto y `docs/convenciones.md` para las convenciones de nombres.

## Fuentes

| Archivo | Tema | Filas | Columnas |
|---|---|---|---|
| `VIVIENDA_BDP.sav` | Viviendas | 3,943,431 | 15 |
| `HOGAR_BDP.sav` | Hogares | 3,275,931 | 42 |
| `PERSONA - BDP.sav` | Personas | 14,901,286 | 85 |
| `MIGRACION_BDP.sav` | Emigración | 242,203 | 11 |

## Jerarquía y grano (validado con `etl/r/01-validacion-integridad.R`)

- **Vivienda** — grano: una fila por vivienda. Llave natural: `DEPARTAMENTO + MUNICIPIO + LUGAR_POBLADO + NUM_VIVIENDA`. 3,943,431 filas, **100% únicas**.
- **Hogar** — grano: un hogar dentro de una vivienda. Llave: llave de vivienda + `NUM_HOGAR`. 3,275,931 filas, **100% únicas**, **100% con vivienda válida** (`hogar_sin_vivienda = 0`).
- **Persona** — grano: una persona dentro de un hogar (o de una vivienda colectiva/sin vivienda). Llave: llave de hogar + `PCP1`. 14,901,286 filas, **100% únicas**.
  - 43,752 personas (0.29%) no tienen hogar asociado. **Totalmente explicado, no es un problema de datos**: sus viviendas (1,389 en total) tienen `PCV1 = 10` ("Vivienda colectiva", 42,536 personas: cuarteles, hospitales, cárceles, conventos) o `PCV1 = 11` ("Sin vivienda", 1,216 personas). El INE no organiza estos casos en hogares por diseño metodológico.
  - **Implicación de diseño:** en `Hechos.CensoPoblacion`, el FK hacia `Hechos.CensoHogar` debe ser **NULLABLE**; el vínculo confiable para toda persona es hacia `Hechos.CensoVivienda` (o directamente hacia `Dim` de territorio), no hacia hogar.
- **Migración** — grano: un evento de emigración reportado por un hogar. Llave: `DEPARTAMENTO + MUNICIPIO + NUM_VIVIENDA + NUM_HOGAR + ID_EMIGRACION`. 242,203 filas, **100% únicas**, **100% con hogar válido** (no requiere `LUGAR_POBLADO` en el cruce, lo que confirma que `NUM_VIVIENDA` ya es efectivamente único dentro de `DEPARTAMENTO + MUNICIPIO`).
- **Vivienda sin hogar**: 763,836 (19.4% del total). Explicado por completo: 762,447 viviendas no ocupadas (`PCV4` = 2 desocupada de uso temporal, 3 desocupada o 4 moradores ausentes o rechazo total, verificado con `etl/r/04-verificacion-nulos.R`) más 1,389 viviendas colectivas o "sin vivienda". No implica una tabla de hechos separada, solo que `Hechos.CensoHogar` no cubre el 100% de `Hechos.CensoVivienda`.

## Jerarquía territorial (validado con `etl/r/02-conteo-territorio.R`)

- 22 departamentos, 340 municipios, **20,254 lugares poblados**, todos con código único a nivel nacional (no hace falta componer `DEPARTAMENTO+MUNICIPIO+LUGAR_POBLADO` para identificarlos: el conteo de combinaciones distintas coincide exactamente con el conteo de `LUGAR_POBLADO` únicos).

## Propuesta preliminar de esquema en estrella

### Dimensiones de territorio
- `Dim.Departamento` (22 filas)
- `Dim.Municipio` (362 filas: 340 municipios más 22 miembros "*Departamento* municipio no declarado", códigos 199, 299, …, 2299, que aparecen en los catálogos de lugar de nacimiento, residencia 2013, estudio y trabajo; FK `DepartamentoId`)
- `Dim.LugarPoblado` (20,254 filas, FK `MunicipioId`, atributos `NombreLugarPoblado` y `Zona`) — tabla propia por volumen y porque Power BI la usará para desagregar. `AREA` (urbano/rural) **no** va aquí: 100 lugares poblados tienen viviendas urbanas y rurales, así que `EsUrbano` se guarda en `Hechos.CensoVivienda`.

### Dimensiones de catálogo (PCV*/PCH*/PCP*)
Clasificadas en [`clasificacion-variables.md`](clasificacion-variables.md): 38 dimensiones en total (3 de territorio, 7 transversales, 5 de vivienda, 8 de hogar y 15 de persona); después se agregaron 2 clasificaciones derivadas para reproducir los cuadros oficiales (`Dim.TipoHogar` y `Dim.CondicionDificultad`), 40 en total, con columnas `BIT` para las preguntas Sí/No y columnas numéricas para conteos y años. Ese documento incluye las decisiones de diseño pendientes de ratificar (sección 4) y la explicación de los nulos (sección 5).

### Tablas de hechos
| Tabla | Grano | Filas | FK obligatorios | FK opcionales |
|---|---|---|---|---|
| `Hechos.CensoVivienda` | 1 vivienda | 3,943,431 | Territorio | — |
| `Hechos.CensoHogar` | 1 hogar | 3,275,931 | Territorio, Vivienda | — |
| `Hechos.CensoPoblacion` | 1 persona | 14,901,286 | Territorio, Vivienda | **Hogar (nullable)** |
| `Hechos.CensoMigracion` | 1 evento de emigración | 242,203 | Territorio, Hogar | — |

## Hallazgos de las verificaciones adicionales (`etl/r/03-verificaciones-clasificacion.R`)

- `TOTAL_PERS` de Hogar coincide exactamente con el conteo de personas de cada hogar (3,275,931 hogares, 0 diferencias); sirve como control de carga.
- Las coordenadas de Hogar repiten las de su Vivienda (0 diferencias); se guardan solo en Vivienda.
- `COD_MUNICIPIO` y `VIVEHABGEO` son redundantes con `MUNICIPIO` (0 diferencias); no se cargan a las tablas de hechos.
- `NIVGRADO` determina el nivel educativo (`PCP17_A`) pero no el grado (`PCP17_B`), que se conserva como columna.
- La edad máxima registrada es 124 años; `Dim.Edad` cubre 0 a 124.

## Esquema implementado (`db/02-dimensiones`)

Los scripts crean en `CensoGT2018` las 40 dimensiones (`dim`) y las 4 tablas de hechos (`hechos`), verificados contra el contenedor (42 tablas, ejecución idempotente):

| Tabla | Columnas propias | Notas |
|---|---|---|
| `hechos.CensoVivienda` | 11 | Incluye `EsUrbano` y las coordenadas |
| `hechos.CensoHogar` | 35 | 13 columnas `Tiene*` para los bienes del hogar; `LugarPobladoId` copiado de la vivienda |
| `hechos.CensoPoblacion` | 74 | `HogarId` nullable; `LugarPobladoId` copiado de la vivienda; columnas de rol para lugar de nacimiento, residencia 2013, estudio y trabajo; `InscripcionRenapId` y `UsoTrajeTradicionalId` referencian `Dim.RespuestaSiNo` porque traen el código 9 (no declarado) |
| `hechos.CensoMigracion` | 7 | Enlaza al hogar; `AnioSalida` nulo si era 9999 |

`db/03-indices` agrega 78 llaves foráneas (todas de confianza), 42 restricciones únicas (el código del INE en cada dimensión y la llave natural de vivienda, hogar y emigrante) y un columnstore agrupado en `CensoVivienda`, `CensoHogar` y `CensoPoblacion`; `CensoMigracion` queda como rowstore por tener solo 242,203 filas. Se comprobó con una transacción revertida que las restricciones rechazan referencias inexistentes y códigos duplicados. Diagramas del esquema en `docs/diagramas/modelo-datos.md`.

Cada tabla lleva además las tres columnas de auditoría de `docs/convenciones.md`. Una columna es `NOT NULL` solo cuando el diccionario registra cero valores perdidos en el origen; las demás admiten `NULL` (saltos del cuestionario, sección 5 de `clasificacion-variables.md`).

## Carga implementada (`etl/sql`, `etl/ejecutar-etl.sh`)

```
.sav ──R──> CSV (datos/csv) ──BULK INSERT──> stage.* ──T-SQL──> dim.* ──T-SQL──> hechos.* ──> 05-validaciones
```

| Paso | Script | Qué hace |
|---|---|---|
| Exportar | `etl/r/10-exportar-catalogos.R`, `11-exportar-microdatos.R` | Etiquetas de valor (4,290) y microdatos a CSV; Persona por bloques de 2 millones de filas; omite las columnas redundantes documentadas |
| 0 | `etl/sql/00-vaciar-modelo.sql` | Vacía dimensiones y hechos para repetir la carga (opción `--recargar`) |
| 1 | `01-stage-tablas.sql` | Recrea `stage` (7 tablas; columnstore en las tres grandes) |
| 2 | `02-cargar-stage.sql` | `BULK INSERT` de los CSV; los de texto en UTF-16 (`widechar`) |
| 3 | `03-cargar-dimensiones.sql` | 40 dimensiones: catálogos del `.sav`, jerarquías, y por regla `Dim.Edad`, `Dim.CondicionActividad`, `Dim.TipoHogar` y `Dim.CondicionDificultad` |
| 4 | `04-cargar-hechos.sql` | 4 hechos en el orden vivienda, hogar, migración y población (22 lotes por departamento), con llaves foráneas desactivadas y revalidadas al final |
| 5 | `05-validaciones.sql` | 59 controles contra cifras independientes (incluye las cifras nacionales de los cuadros B8 y A8); termina con error si alguno falla |

Cada script es una sola instrucción de trabajo con controles propios: `03` y `04` se niegan a cargar sobre tablas con datos; `04` verifica antes de insertar que todo código de `stage` exista en su dimensión y compara después las filas insertadas con las de `stage`.

**Resultado:** las 4 tablas de hechos y las 38 dimensiones cargadas, con **50 de 50 controles correctos**: conteos por tabla, integridad referencial (76 llaves de confianza, 43,752 personas sin hogar, 763,836 viviendas sin hogar), 14 cifras del diccionario de variables (por ejemplo 2,213,460 viviendas urbanas y 6,207,503 personas mayas), la condición de actividad derivada (4,968,542 ocupados) y la conversión de valores centinela y de texto.

### Problemas encontrados durante la carga y su solución

| Problema | Causa | Solución |
|---|---|---|
| `BULK INSERT` rechaza `CODEPAGE` | En SQL Server para Linux no está soportado | Los CSV con texto se escriben en UTF-16LE con BOM y se cargan con `DATAFILETYPE = 'widechar'` |
| Acentos convertidos en símbolos (`Sacatepéquez` → `SacatepΘquez`) | Sin `CODEPAGE`, los archivos de caracteres se leen con la página OEM 437, que no tiene `Á Í Ó Ú` | Igual que el anterior; se comprobó que la `é` queda como `U+00E9` |
| Error de conversión en `NUM_VIVIENDA` | `fwrite` escribía números redondos como `1e+05` | `options(scipen = 999)` en `etl/r/utilidades-exportacion.R` |
| Terminador de fila duplicado (`CR CR LF`) | `write.csv` abre el archivo en modo texto en Windows | Sustituido por el helper UTF-16 basado en `fwrite` |
| Cursor sobre `stage.Persona` rechazado | T-SQL no permite cursores sobre tablas con columnstore agrupado | Los departamentos se leen de `dim.Departamento` |
| Códigos de 2 dígitos con más de un grupo de 1 dígito | Origen no estrictamente jerárquico: 2 códigos de ocupación (2 personas) y 5 de rama de actividad (9 personas) | Se asigna el grupo más frecuente y las excepciones se reportan en la carga |
| Rama de actividad 54, sin etiqueta | Una persona con un código que no existe en la clasificación y no está en el catálogo del `.sav` | El control previo de códigos huérfanos detuvo la carga; se agregó el miembro "Codigo 54 sin etiqueta en el origen" para no perder ni reasignar el registro |
| `PCP9` (241,578) y `PCP14` (371,419) con código 9 | El diccionario solo etiquetaba 1 y 2, pero los datos traen "no declarado" | Pasan de `BIT` a `Dim.RespuestaSiNo`, según la regla de que "No declarado" es un miembro de la dimensión |
| 6 columnas booleanas sin el prefijo `Es` o `Tiene` de la convención de nombres | Nombres elegidos sin contrastarlos con `docs/convenciones.md`; lo detectó la primera corrida de las pruebas de esquema (`pruebas/Censo.Pruebas.BaseDatos`) | Renombradas: `TieneRemesas`, `EsEstudiante`, `EsAlfabeta`, `TieneOtroIdioma`, `EsTrabajadorSemanaPasada` y `EsVivoUltimoHijo`; en la base viva con `sp_rename`, sin recargar |
| 4 nombres de lugares poblados con defectos de codificación | Ya vienen así en el `.sav` (3 con el carácter de control U+0081, 1 con un `?` literal), verificado en `etl/r/07-verificacion-nombres-lugares.R` | Se conservan como en el origen y el control de validación los cuenta (4) |

Tiempos de la carga completa desde los `.sav` (corrida del 2026-09-26, 31 min 24 s en total): exportación 3 min 47 s, vaciado del modelo 2 min 56 s, `stage` 7 min 16 s (Persona 6 min), dimensiones 1 s, hechos 17 min 20 s (Población 10 min y unos 5 min de revalidación de llaves, compresión del columnstore y estadísticas) y validaciones 4 s. Resultados de referencia en `docs/pruebas.md`.

## Pendiente

- Optimización según la fase de pruebas: índices no agrupados sobre las llaves foráneas, columnstore ordenado por `LugarPobladoId` y estadísticas, solo si los planes de ejecución lo justifican.
- Obtener la categoría del lugar poblado (`PLG14` de la boleta: ciudad, aldea, caserío, etc.), que no está en los `.sav`; sin otra fuente del INE, `Dim.LugarPoblado` no la incluirá.
- Confidencialidad estadística / restricciones de desagregación: **fuera de alcance** (decisión tomada — microdatos ya anonimizados por el INE).
- Validación de exactitud contra los 25 cuadros oficiales del INE: pendiente, no es prioridad en esta fase (se retoma en capítulo III / fase de pruebas).

## Scripts de análisis (R)

Ubicados en `etl/r/`, no forman parte del stack de producción (ver `docs/convenciones.md`) — son herramientas de desarrollo para entender los microdatos y para exportarlos a CSV.

- `01-validacion-integridad.R` — lee las llaves de los 4 archivos (más `PCV1` de Vivienda) y valida unicidad + integridad referencial; explica los huérfanos de `Persona -> Hogar` por tipo de vivienda (`PCV1`). Genera `etl/r/salidas/validacion_integridad.json` y cachea las llaves en `etl/r/salidas/llaves_censo2018.rds` (ignorado por git).
- `02-conteo-territorio.R` — cuenta departamentos/municipios/lugares poblados distintos, reutilizando el caché.
- `03-verificaciones-clasificacion.R` — comprueba las hipótesis de la clasificación de variables (redundancias, constancia de `AREA`/`ZONA` por lugar poblado, `TOTAL_PERS`, catálogos de 362 categorías). Genera `etl/r/salidas/verificaciones_clasificacion.json`.
- `04-verificacion-nulos.R` — cruza los nulos de las variables con la pregunta que los origina y con la edad, para explicar los porcentajes del diccionario. Genera `etl/r/salidas/verificacion_nulos.json`.
- `05-etiquetas-codigos-extra.R` — imprime las etiquetas oficiales de los códigos geográficos 199, 299, …, 2299.
- `06-verificacion-migracion-actividad.R` — determina que en `MIGRA_VIDA` y `MIGRA_REC` el código 2 es migrante, y cuenta las combinaciones de las banderas de actividad. Genera `etl/r/salidas/verificacion_migracion_actividad.json`.
- `07-verificacion-nombres-lugares.R` — comprueba en el `.sav` que 4 nombres de lugares poblados ya traen defectos de codificación.
- `10-exportar-catalogos.R` y `11-exportar-microdatos.R` — exportan a CSV las etiquetas y los microdatos para la carga (con `utilidades-exportacion.R`). No son de análisis: forman parte de la carga (ver arriba).

Las salidas `.json` se versionan como evidencia para la tesis; los `.rds` de caché y los logs de ejecución no.
