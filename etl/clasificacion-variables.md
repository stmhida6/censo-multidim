# Clasificación de variables del Censo 2018

> Base del DDL de `db/02-dimensiones` y de la carga de `etl/sql` (decisiones ratificadas el 2026-09-24 y revisadas con los hallazgos de la carga). Fuentes: `etl/jsonl/diccionario_variables_censo2018.jsonl` (153 variables, 4 archivos), `docs/doc censo18/BOLETA CENSAL.md` (estructura y saltos del cuestionario), `docs/doc censo18/GLOSARIO DE DEFINICIONES.md` (definiciones oficiales) y las verificaciones de `etl/r/03-verificaciones-clasificacion.R`. Contexto general en `etl/plan-etl.md`.

## 1. Criterios de clasificación

Cada variable recibe una de estas clases:

| Clase | Significado | Destino |
|---|---|---|
| **DIM** | Variable categórica con catálogo propio (códigos y etiquetas) | Tabla `Dim.*`; la tabla de hechos guarda solo el `XId` |
| **ATR** | Valor numérico o de rango amplio sin catálogo | Columna en la tabla de hechos |
| **BIN** | Pregunta Sí/No (códigos 1 y 2) | Columna `BIT` con prefijo `Es`/`Tiene` (convención de `docs/convenciones.md`) |
| **DER** | Variable derivada por el INE (no está en la boleta) | Se conserva como atributo; su regla se documenta |
| **LLAVE** | Identificador de la jerarquía Vivienda → Hogar → Persona | Columna degenerada en el hecho; permite trazabilidad |
| **RED** | Redundante: se obtiene de otra columna o de una dimensión | No se carga a `hechos`; se conserva en `stage` |

Reglas transversales:

1. **"No aplica" y "No declarado" son cosas distintas.** "No aplica" es un salto del cuestionario (por edad, sexo o respuesta previa) y se guarda como `NULL`. "No declarado" es una respuesta que el INE codificó (`9`, `99`, `9999`) y se guarda como un miembro más de la dimensión (o `NULL` con su significado documentado en las columnas numéricas). Así los porcentajes de nulos del diccionario se interpretan como saltos y no como datos perdidos (sección 5).
2. **Una dimensión por concepto, compartida cuando el catálogo es idéntico** (role-playing). Por ejemplo `Dim.Idioma` sirve a `PCP15`, `PCP23_A/B/C` y `PCP25_A/B/C`; `Dim.Pais` a las cuatro columnas de país; `Dim.Departamento` y `Dim.Municipio` a los lugares de nacimiento, residencia, estudio y trabajo.
3. **Los códigos del INE se conservan tal cual** en la columna `Codigo*` de cada dimensión (convención de `docs/convenciones.md`); la llave sustituta `XId` es interna.
4. **Las etiquetas se limpian en la carga** (`TRIM`): el diccionario trae etiquetas con espacio inicial (por ejemplo `" Cobán"`, `" Jalapa"`).

## 2. Dimensiones propuestas (38)

| Grupo | Dimensiones |
|---|---|
| Territorio (3) | `Dim.Departamento` (22), `Dim.Municipio` (362: 340 municipios más 22 miembros "municipio no declarado"), `Dim.LugarPoblado` (20,254) |
| Transversales (7) | `Dim.Sexo`, `Dim.Edad`, `Dim.RespuestaSiNo`, `Dim.Pais` (60), `Dim.Idioma` (29), `Dim.TipoLugar`, `Dim.SexoResponsable` |
| Vivienda (5) | `Dim.TipoVivienda`, `Dim.MaterialPared`, `Dim.MaterialTecho`, `Dim.CondicionVivienda`, `Dim.MaterialPiso` |
| Hogar (8) | `Dim.TenenciaVivienda`, `Dim.FuenteAgua`, `Dim.TipoServicioSanitario`, `Dim.UsoServicioSanitario`, `Dim.DesagueAguasGrises`, `Dim.TipoAlumbrado`, `Dim.EliminacionBasura`, `Dim.CombustibleCocina` |
| Persona (15) | `Dim.CondicionActividad`, `Dim.Parentesco`, `Dim.TipoResidencia2013`, `Dim.Pueblo`, `Dim.ComunidadLinguistica`, `Dim.GradoDificultad`, `Dim.NivelGrado`, `Dim.TipoEstablecimiento`, `Dim.CausaNoAsistencia`, `Dim.ActividadSemana`, `Dim.ActividadNoTrabajo`, `Dim.Ocupacion`, `Dim.RamaActividad`, `Dim.CategoriaOcupacional`, `Dim.EstadoConyugal` |

Jerarquías previstas (tesis 2.2.7): `Departamento → Municipio → LugarPoblado`; `Edad → GrupoQuinquenal → GrupoAmplio` (0-14, 15-64, 65 y más, base de la relación de dependencia del glosario); `Ocupacion` y `RamaActividad` de 1 dígito → 2 dígitos; `NivelGrado` → nivel educativo.

## 3. Clasificación por archivo

`% nulo` es el porcentaje de perdidos del diccionario; la causa se explica en la sección 5.

### 3.1 VIVIENDA_BDP.sav → `Hechos.CensoVivienda`

| Variable | Descripción | Cat. | % nulo | Clase | Destino |
|---|---|---|---|---|---|
| `DEPARTAMENTO`, `MUNICIPIO` | Ubicación | 22 / 340 | 0 | LLAVE | Vía `LugarPoblado` (el lugar poblado ya identifica municipio y departamento) |
| `COD_MUNICIPIO` | Código del municipio dentro del departamento | – | 0 | RED (V1) | Último par de dígitos de `MUNICIPIO` |
| `LUGAR_POBLADO` | Código del lugar poblado | 20,254 | 0 | LLAVE | `LugarPobladoId` → `Dim.LugarPoblado` |
| `NOMBRE_LUGAR_POBLADO` | Nombre | texto | 0 | ATR | Atributo de `Dim.LugarPoblado` |
| `NUM_VIVIENDA` | Número de vivienda | – | 0 | LLAVE | `NumeroVivienda` (degenerada) |
| `ZONA` | Zona (municipio de Guatemala) o código de municipio | – | 0 | ATR (V2) | Atributo de `Dim.LugarPoblado` (constante por lugar poblado) |
| `AREA` | Urbano / Rural | 2 | 0 | BIN (V2) | `EsUrbano` en `Hechos.CensoVivienda`; **no** es constante por lugar poblado, por eso no va en la dimensión |
| `PCV1` | Tipo de vivienda | 9 | 0 | DIM | `Dim.TipoVivienda` |
| `PCV2` | Material de paredes | 11 | 0.01 | DIM | `Dim.MaterialPared` |
| `PCV3` | Material del techo | 8 | 0.01 | DIM | `Dim.MaterialTecho` |
| `PCV4` | Condición de la vivienda | 4 | 0.04 | DIM | `Dim.CondicionVivienda` |
| `PCV5` | Material del piso | 8 | 19.34 | DIM | `Dim.MaterialPiso` |
| `Long`, `Lat` | Coordenadas | – | 1.33 | ATR | `Longitud`, `Latitud` (V3) |

### 3.2 HOGAR_BDP.sav → `Hechos.CensoHogar`

| Variable | Descripción | Cat. | % nulo | Clase | Destino |
|---|---|---|---|---|---|
| Llaves y territorio | `DEPARTAMENTO`, `MUNICIPIO`, `LUGAR_POBLADO`, `NUM_VIVIENDA`, `NUM_HOGAR` | – | 0 | LLAVE | `ViviendaId`, `NumeroHogar` y `LugarPobladoId` (copiado de la vivienda para consultar territorio sin unir) |
| `COD_MUNICIPIO`, `NOMBRE_LUGAR_POBLADO`, `ZONA`, `AREA` | Repiten a Vivienda | – | 0 | RED | Se obtienen por `ViviendaId` |
| `PCH1` | Tenencia de la vivienda | 6 | 0 | DIM | `Dim.TenenciaVivienda` |
| `PCH2` | Sexo de la persona propietaria | 4 | 19.8 | DIM | `Dim.SexoResponsable` |
| `PCH3` | Sexo de quien toma las decisiones | 4 | 0 | DIM | `Dim.SexoResponsable` (segunda FK) |
| `PCH4` | Fuente de agua | 10 | 0 | DIM | `Dim.FuenteAgua` |
| `PCH5` | Tipo de servicio sanitario | 5 | 0 | DIM | `Dim.TipoServicioSanitario` |
| `PCH6` | Uso del servicio sanitario | 2 | 4.79 | DIM | `Dim.UsoServicioSanitario` |
| `PCH7` | Desagüe de aguas grises | 2 | 0 | DIM | `Dim.DesagueAguasGrises` |
| `PCH8` | Tipo de alumbrado | 5 | 0 | DIM | `Dim.TipoAlumbrado` |
| `PCH9_A` … `PCH9_M` | 13 bienes del hogar: radio, estufa, televisor, cable, refrigeradora, tanque de agua, lavadora, computadora, internet, temazcal, agua caliente, moto, carro | 2 c/u | 0 | BIN | `TieneRadio`, `TieneEstufa`, `TieneTelevisor`, `TieneCable`, `TieneRefrigeradora`, `TieneTanqueAgua`, `TieneLavadora`, `TieneComputadora`, `TieneInternet`, `TieneTemazcal`, `TieneAguaCaliente`, `TieneMoto`, `TieneCarro` |
| `PCH10` | Eliminación de basura | 8 | 0 | DIM | `Dim.EliminacionBasura` |
| `PCH11`, `PCH12` | Cuartos y dormitorios | – | 0 | ATR | `TotalCuartos`, `TotalDormitorios` |
| `PCH13` | Cuarto exclusivo para cocinar | 2 | 0 | BIN | `TieneCuartoCocina` |
| `PCH14` | Combustible para cocinar | 7 | 0 | DIM | `Dim.CombustibleCocina` |
| `PCH15` | Recibe remesas | 2 | 0 | BIN | `TieneRemesas` |
| `PEI1` | Algún miembro emigró desde 2002 | 2 | 0 | BIN | `TieneEmigrantes` |
| `PEI2` | Total de emigrantes | – | 94.05 | ATR | `TotalEmigrantes` |
| `PEI2_E` | Emigrantes con sexo, edad y año reportados | – | 94.05 | DER | `TotalEmigrantesConDetalle` |
| `TOTAL_PERS` | Conteo de personas del hogar | – | 0 | DER (V4) | `TotalPersonas` (medida) |
| `Long`, `Lat` | Coordenadas | – | 0.88 | RED (V3) | Se obtienen de la vivienda |

### 3.3 MIGRACION_BDP.sav → `Hechos.CensoMigracion`

| Variable | Descripción | Cat. | % nulo | Clase | Destino |
|---|---|---|---|---|---|
| `DEPARTAMENTO`, `MUNICIPIO`, `NUM_VIVIENDA`, `NUM_HOGAR` | Enlace al hogar | – | 0 | LLAVE | `HogarId` y `LugarPobladoId` (copiado del hogar) |
| `ID_EMIGRACION` | Número del emigrante | – | 0 | LLAVE | `NumeroEmigrante` (degenerada) |
| `COD_MUNICIPIO`, `ZONA`, `AREA` | Territorio | – | 0 | RED | Se obtienen por `HogarId` |
| `PEI3` | Sexo del emigrante | 2 | 0 | DIM | `Dim.Sexo` |
| `PEI4` | Edad al irse | – | 0 | DIM | `Dim.Edad` |
| `PEI5` | Año de salida | – | 0 | ATR | `AnioSalida` |

### 3.4 PERSONA - BDP.sav → `Hechos.CensoPoblacion`

| Variable | Descripción | Cat. | % nulo | Clase | Destino |
|---|---|---|---|---|---|
| Llaves y territorio | `DEPARTAMENTO`, `MUNICIPIO`, `LUGAR_POBLADO`, `NUM_VIVIENDA`, `NUM_HOGAR` | – | 0 | LLAVE | `ViviendaId`, `HogarId` (nullable), `LugarPobladoId` (copiado de la vivienda) |
| `COD_MUNICIPIO`, `NOMBRE_LUGAR_POBLADO`, `AREA` | Repiten a Vivienda | – | 0 | RED | Se obtienen por `ViviendaId` |
| `PCP1` | Número de persona | – | 0 | LLAVE | `NumeroPersona` (degenerada) |
| `PCP5` | Parentesco con la jefatura | 15 | 0 | DIM | `Dim.Parentesco` |
| `PCP6` | Sexo | 2 | 0 | DIM | `Dim.Sexo` |
| `PCP7` | Edad en años cumplidos | – | 0 | DIM | `Dim.Edad` |
| `PCP9` | Fe de edad / inscrito en RENAP | 2 + código 9 | 0 | DIM (V10) | `InscripcionRenapId` → `Dim.RespuestaSiNo` (241,578 personas con código 9, no declarado) |
| `PCP10` | Lugar de nacimiento (aquí / otro / no declarado) | 3 | 0 | DIM | `Dim.TipoLugar` |
| `PCP10_B` | Departamento de nacimiento | 22 | 2.1 | DIM | `Dim.Departamento` |
| `LUGNACGEO` | Municipio de nacimiento | 362 | 2.1 | DIM (V5) | `Dim.Municipio` |
| `PCP10_C`, `PCP10_D` | País de nacimiento, año de llegada | 60 / 1 | 99.45 | DIM / ATR | `Dim.Pais`; `AnioLlegada` (`9999` = no declarado) |
| `PCP11` | Residencia en abril de 2013 | 4 | 0 | DIM | `Dim.TipoResidencia2013` |
| `PCP11_B`, `RESCINGEO`, `PCP11_C` | Departamento, municipio y país de residencia 2013 | 22 / 362 / 60 | 12.32 / 12.32 / 99.82 | DIM (V5) | `Dim.Departamento`, `Dim.Municipio`, `Dim.Pais` |
| `PCP12` | Pueblo de pertenencia | 6 | 0 | DIM | `Dim.Pueblo` |
| `PCP13` | Comunidad lingüística | 22 | 58.34 | DIM | `Dim.ComunidadLinguistica` |
| `PCP14` | Usa traje tradicional | 2 + código 9 | 56.25 | DIM (V10) | `UsoTrajeTradicionalId` → `Dim.RespuestaSiNo` (371,419 personas con código 9, no declarado) |
| `PCP15` | Idioma en que aprendió a hablar | 29 | 8.95 | DIM | `Dim.Idioma` |
| `PCP16_A` … `PCP16_F` | Dificultad para ver, oír, caminar, recordar, cuidado personal, comunicarse | 5 c/u | 8.95 | DIM | `Dim.GradoDificultad` (6 FK) |
| `PCP17_A` | Nivel de estudios más alto | 7 | 8.95 | RED (V6) | Atributo `NivelEducativo` de `Dim.NivelGrado` |
| `PCP17_B` | Grado más alto aprobado | – | 31.8 | ATR (V6) | `GradoMasAltoAprobado` (`NIVGRADO` agrupa grados y no lo reemplaza) |
| `NIVGRADO` | Nivel y grado (derivada) | 23 | 8.95 | DER → DIM | `Dim.NivelGrado` |
| `ANEDUCA` | Años de estudio (derivada) | 22 | 8.95 | DER → ATR | `AniosEstudio` |
| `PCP18` | Asiste a un establecimiento en 2018 | 2 | 8.95 | BIN | `EsEstudiante` |
| `PCP19` | Tipo de establecimiento | 4 | 72.74 | DIM | `Dim.TipoEstablecimiento` |
| `PCP20`, `PCP20_B`, `ESTUDIAGEO`, `PCP20_C` | Dónde estudia (tipo, departamento, municipio, país) | 3 / 22 / 362 / 60 | 72.74 – 99.98 | DIM (V5) | `Dim.TipoLugar`, `Dim.Departamento`, `Dim.Municipio`, `Dim.Pais` |
| `PCP21` | Causa por la que no asiste | 18 | 72.25 | DIM | `Dim.CausaNoAsistencia` |
| `PCP22` | Sabe leer y escribir | 2 | 15.92 | BIN | `EsAlfabeta` |
| `PCP23_A/B/C` | Idiomas en que sabe leer y escribir | 28 c/u | 31.45 – 99.78 | DIM | `Dim.Idioma` (3 FK) |
| `PCP24` | Sabe hablar otro idioma | 2 | 15.92 | BIN | `TieneOtroIdioma` |
| `PCP25_A/B/C` | Otros idiomas que habla | 28 c/u | 79.89 – 99.97 | DIM | `Dim.Idioma` (3 FK) |
| `PCP26_A/B/C` | Uso de celular, computadora, internet | 3 c/u | 15.92 | DIM | `Dim.RespuestaSiNo` (3 FK; incluye "No declarado") |
| `PCP27` | Trabajó la semana pasada | 2 | 15.92 | BIN | `EsTrabajadorSemanaPasada` |
| `PCP28` | Qué hizo la semana pasada | 7 | 48.63 | DIM | `Dim.ActividadSemana` |
| `PCP29` | Si no trabajó, qué hizo | 9 | 49.26 | DIM | `Dim.ActividadNoTrabajo` |
| `PCP30_1D`, `PCP30_2D` | Ocupación (1 y 2 dígitos) | 11 / 44 | 66.07 | DIM | `Dim.Ocupacion` (jerarquía) |
| `PCP31_D` | Categoría ocupacional | 8 | 66.07 | DIM | `Dim.CategoriaOcupacional` |
| `PCP32_1D`, `PCP32_2D` | Rama de actividad (1 y 2 dígitos) | 22 / 89 | 66.07 | DIM | `Dim.RamaActividad` (jerarquía) |
| `PCP33`, `PCP33_B`, `TRABAJAGEO`, `PCP33_C` | Dónde trabaja (tipo, departamento, municipio, país) | 3 / 22 / 362 / 60 | 66.07 – 99.9 | DIM (V5) | `Dim.TipoLugar`, `Dim.Departamento`, `Dim.Municipio`, `Dim.Pais` |
| `PCP34` | Estado conyugal | 7 | 22.54 | DIM | `Dim.EstadoConyugal` |
| `PCP35_A/B/C` | Hijos nacidos vivos (total, mujeres, hombres) | – | 59.62 | ATR | `HijosNacidosVivos*` (`99` = no declarado) |
| `PCP36_A/B/C` | Hijos sobrevivientes (total, mujeres, hombres) | – | 75.83 | ATR | `HijosSobrevivientes*` |
| `PCP37` | Edad al tener el primer hijo | – | 75.83 | ATR | `EdadPrimerHijo` (`99` = no declarado) |
| `PCP38_A/B/C` | Día, mes y año de nacimiento del último hijo | – | 75.83 | ATR | `DiaUltimoHijo`, `MesUltimoHijo`, `AnioUltimoHijo` |
| `PCP39` | Último hijo sigue vivo | 2 | 75.83 | BIN | `EsVivoUltimoHijo` |
| `VIVEHABGEO` | Municipio de residencia habitual | 340 | 0 | RED (V7) | Igual a `MUNICIPIO` |
| `PEA`, `POCUPA`, `PDESOC`, `PEI` | Banderas de condición de actividad (`PEA` y `POCUPA` valen 1 o nulo; `PDESOC`: 1 aspirante, 2 cesante; `PEI`: inactiva) | 1 / 1 / 2 / – | 65.71 / 66.66 / 99.05 / 51.35 | DER → DIM | Se combinan en `Dim.CondicionActividad` (sección 4) |
| `MIGRA_VIDA` | Migración de toda la vida | – | 1.55 | DER (V9) | `EsMigranteVida` (el código **2** es migrante) |
| `MIGRA_REC` | Migración reciente | – | 0.86 | DER (V9) | `EsMigranteReciente` (el código **2** es migrante) |

## 4. Decisiones de diseño (ratificadas el 2026-09-24)

1. **Una dimensión por concepto (38) frente a un catálogo genérico único** (`Variable, Codigo, Etiqueta`). Se propone lo primero: respeta el esquema en estrella de la tesis (2.6.5), da a Power BI relaciones claras y permite que el catálogo de la API describa cada dimensión con sus jerarquías. El costo es más objetos de base de datos, pero se generan con una plantilla.
2. **Vivienda y Hogar como tablas de hechos referenciadas desde Persona.** Las características de la vivienda o el hogar (fuente de agua, tipo de vivienda) se cruzan con personas mediante la cadena `Persona → Hogar → Vivienda`. Es el diseño de `etl/plan-etl.md`. La alternativa, copiar esas columnas en Persona, duplicaría cerca de 30 columnas en 14.9 millones de filas.
3. **`Dim.Edad` con la edad en años como llave natural**, para que los grupos quinquenales y amplios sean atributos de la dimensión y no columnas calculadas en cada consulta.
4. **Columnas Sí/No como `BIT`**, excepto `PCP9`, `PCP14` y `PCP26_*`, que traen "No declarado" y usan `Dim.RespuestaSiNo`. *Revisada el 2026-09-26:* `PCP9` y `PCP14` estaban previstas como `BIT`, pero la carga reveló que el 1.6% y el 5.7% de sus respuestas son el código 9, que el diccionario no etiquetaba; convertirlas a `BIT` las habría dejado en `NULL`, que significa "no aplica".
5. **Valores centinela numéricos** (`99`, `9999`) se convierten a `NULL` en las columnas `ATR`, para no distorsionar sumas y promedios; el hecho de que fueran "no declarado" queda documentado aquí y en `stage`, donde se conserva el valor original.

6. **`Dim.CondicionActividad`** se deriva en el ETL combinando `PEA`, `POCUPA`, `PDESOC` y `PEI`, porque cada bandera solo trae el valor 1. Las banderas son mutuamente excluyentes (V9) y sus miembros son: 1 Ocupada, 2 Desocupada aspirante, 3 Desocupada cesante, 4 Inactiva y 5 No declarada (personas de 7 años o más sin ninguna bandera, 169,442, que coinciden con `PCP29` = "No declarado"). Los menores de 7 años quedan en `NULL` (no aplica). Así los indicadores de participación, ocupación y desempleo del glosario se calculan con una sola dimensión y un filtro de edad explícito.

## 5. Origen de los nulos (comprobado con `etl/r/04-verificacion-nulos.R`)

Cada fila indica la pregunta que activa la variable y el resultado del cruce con los microdatos. "Sin excepciones" significa que todas las personas u hogares a los que aplica tienen valor y ninguno de los demás lo tiene.

| Variable | % nulo | Causa comprobada |
|---|---|---|
| `PCV4` | 0.04 | Nula en las 1,389 viviendas colectivas y "sin vivienda" (no aplica). Trae además el código 4 (moradores ausentes o rechazo total, 58,226 viviendas), que la boleta no lista |
| `PCV5` | 19.34 | Nula en las 762,447 viviendas con `PCV4` = 2, 3 o 4 (no ocupadas) y en las 346 "sin vivienda"; con valor en las 3,179,595 ocupadas. Sin excepciones |
| `PCH2` | 19.8 | Con valor solo si `PCH1` = 1 o 2 (vivienda propia): 2,627,179 hogares. Sin excepciones |
| `PCH6` | 4.79 | Con valor solo si `PCH5` = 1 a 4 (tiene servicio sanitario): 3,119,004 hogares. Sin excepciones |
| `PEI2`, `PEI2_E` | 94.05 | Con valor solo si `PEI1` = 1: 194,979 hogares con emigrantes. Sin excepciones |
| `PCP10_C/D`, `PCP11_C`, `PCP20_C`, `PCP33_C` | 99.45 – 99.98 | Solo aplican a quien nació, residía, estudia o trabaja en otro país |
| `PCP13` | 58.34 | Solo si `PCP12` = 1 (maya): 6,207,503 personas. Sin excepciones |
| `PCP14` | 56.25 | Solo si `PCP12` = 1 a 4 (maya, garífuna, xinka o afrodescendiente): 6,518,846 personas. Sin excepciones |
| `PCP15`, `PCP16_*`, `PCP17_*`, `PCP18`, `NIVGRADO`, `ANEDUCA` | 8.95 | Personas menores de 4 años (1,334,389); la edad mínima con valor es 4 en todas ellas, incluidas las de idioma y dificultades funcionales, que la boleta no restringe por edad |
| `PCP22`, `PCP24`, `PCP26_*`, `PCP27` | 15.92 | Menores de 7 años (2,372,349). `PCP22` tiene valor en las 12,528,937 personas de 7 años o más |
| `PCP19`, `PCP20*` | 72.74 – 73.82 | Solo quienes asisten (`PCP18` = 1): 4,062,290 personas |
| `PCP21` | 72.25 | Solo quienes no asisten (`PCP18` = 2) **y** tienen entre 4 y aproximadamente 29 años: tiene valor en el 100% de los que no asisten de 4 a 24 años, en una parte de los de 25 a 34 y en ninguno de 35 o más (4,135,046 de 9,504,607). La edad exacta de corte se fijará en el ETL |
| `PCP28` | 48.63 | Solo quienes no trabajaron (`PCP27` = 2): 7,654,072 personas; nula para quienes sí trabajaron y para los menores de 7 años |
| `PCP29` | 49.26 | Solo si `PCP28` = 7 (no trabajó): 7,560,395 personas. Sin excepciones |
| `PCP30_*`, `PCP31_D`, `PCP32_*`, `PCP33*` | 66 – 69 | Con valor en los 4,968,542 ocupados y además en 87,952 cesantes (buscaron trabajo y habían trabajado antes, `PCP29` = 1) |
| `PCP34` | 22.54 | Personas de 10 años o más: 11,542,635. Sin excepciones |
| `PCP35_*` | 59.62 | Mujeres de 10 años o más: 6,017,041 (476,501 con código 99, "no declarado"). Sin excepciones |
| `PCP36_*`, `PCP37`, `PCP38_*`, `PCP39` | 75.83 | Mujeres de 10 años o más con hijos nacidos vivos: 3,601,758 |
| `PEA`, `POCUPA`, `PDESOC`, `PEI` | 51 – 99 | Son banderas con un solo valor (1): el nulo significa "no pertenece a esa categoría", no "salto del cuestionario". Ver `Dim.CondicionActividad` en la sección 4 |

Dos diferencias respecto de la boleta y del glosario, relevantes para el catálogo de indicadores:

- **Las preguntas de empleo se registran desde los 7 años**, no desde los 10 que indica el encabezado de la boleta del repositorio (el glosario también habla de 7 años para la búsqueda de trabajo). La edad mínima con valor es 7 en `PCP27` a `PCP30`.
- **`PEA` tiene 89,462 personas menores de 15 años**, aunque el glosario define la población económicamente activa desde los 15. Los indicadores oficiales de participación y desempleo deben aplicar el filtro de edad explícitamente.

## 6. Verificaciones contra los datos (`etl/r/03-verificaciones-clasificacion.R`)

Las hipótesis marcadas `(V#)` en las tablas se comprobaron con los microdatos:

| Id | Hipótesis | Resultado |
|---|---|---|
| V1 | `COD_MUNICIPIO` es el último par de dígitos de `MUNICIPIO` | **Confirmada**: 0 diferencias en 3,943,431 viviendas |
| V2 | `AREA` y `ZONA` son constantes dentro de cada lugar poblado | **`ZONA` sí** (0 excepciones; fuera del departamento de Guatemala coincide con `COD_MUNICIPIO`). **`AREA` no**: 100 de 20,254 lugares poblados tienen viviendas urbanas y rurales; por eso `EsUrbano` va en el hecho. `AREA` de Hogar coincide con la de su Vivienda en todos los casos |
| V3 | Las coordenadas de Hogar repiten las de su Vivienda | **Confirmada**: 0 diferencias. Rangos plausibles para Guatemala (longitud −92.21 a −88.29, latitud 13.74 a 17.81) |
| V4 | `TOTAL_PERS` coincide con el conteo de personas del hogar | **Confirmada**: 0 diferencias en 3,275,931 hogares, y ningún hogar carece de personas. Sirve además como control de carga |
| V5 | Los catálogos de 362 categorías contienen los 340 municipios más otros códigos | **Confirmada**: los 22 códigos extra (199, 299, …, 2299) son "*Departamento* municipio no declarado". Aplica a `LUGNACGEO`, `RESCINGEO`, `ESTUDIAGEO` y `TRABAJAGEO` |
| V6 | `NIVGRADO` determina `PCP17_A` y `PCP17_B` | **Parcial**: determina `PCP17_A` (0 excepciones) pero no `PCP17_B` (27 combinaciones nivel-grado frente a 23 categorías de `NIVGRADO`, porque agrupa grados) |
| V7 | `VIVEHABGEO` es igual a `MUNICIPIO` | **Confirmada**: 0 diferencias en 14,901,286 personas |
| V8 | Los nulos de cada variable corresponden a los saltos de la boleta | **Confirmada casi en su totalidad** (sección 5). Diferencias: las preguntas de empleo empiezan a los 7 años y no a los 10; `PCP21` solo se registra hasta cerca de los 29 años; `PEA` incluye 89,462 menores de 15 años |
| V9 | Significado de `MIGRA_VIDA`, `MIGRA_REC` y combinaciones de `PEA`/`POCUPA`/`PDESOC`/`PEI` (`etl/r/06-verificacion-migracion-actividad.R`) | **Confirmada**: en ambas migraciones el código **1 es no migrante** y el **2 es migrante** (`MIGRA_VIDA` = 2 coincide con `PCP10` = 2; `MIGRA_REC` = 2 con `PCP11` = 3; `PCP11` = 1 "no había nacido" cuenta como no migrante); nulas cuando la pregunta es "No declarado". Las banderas de actividad son excluyentes: 4,884,838 + 83,704 ocupados, 135,710 + 5,758 desocupados, 7,249,485 inactivos y 169,442 sin bandera entre los de 7 años o más |
| V10 | Las preguntas Sí/No solo traen los códigos 1 y 2 | **Parcial**: de las 23 preguntas Sí/No (13 bienes del hogar y 10 de otros temas), solo `PCP9` (241,578) y `PCP14` (371,419) traen el código 9. Detectado por la carga (`etl/sql/04-cargar-hechos.sql`) y consultado en `stage` |

## 7. Observaciones sobre la fuente

- La boleta del repositorio lista 11 bienes en `PCH9`; los datos traen 13 (`A` a `M`), con `estufa` y `tanque o depósito de agua` además de los de la boleta. Se usan los 13 de los datos, porque las etiquetas del `.sav` los nombran.
- Varios catálogos del `.sav` traen códigos que no están en la boleta: `PCV1` = 9, 10, 11 (no especificada, vivienda colectiva, sin vivienda) y `PCV4` = 4 (moradores ausentes o rechazo total).
- `PLG14` (categoría del lugar poblado: ciudad, aldea, caserío, etc.) está en la boleta pero **no** en los `.sav`; `Dim.LugarPoblado` no puede incluirla salvo que se obtenga de otra fuente del INE.
- Las columnas de nulos altos no son errores de calidad: ver sección 5.
