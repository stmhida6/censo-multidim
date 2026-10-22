# Catálogo de dimensiones, medidas e indicadores

> Generado a partir de `GET /api/catalogo/*` de la API (fuente única: `src/Censo.Aplicacion/Catalogo/`). Actualizar cuando cambie el catálogo.

El catálogo define **una sola vez** qué se puede consultar: 4 hechos, 93 dimensiones con 108 niveles, 20 medidas y 13 indicadores. Una solicitud solo puede referirse a estas claves (tesis 2.4.5): lo que no está en el catálogo se rechaza con 400 antes de llegar a la base de datos.

Los niveles marcados como *clasificación de los cuadros del INE* (`nivelEducativoCensal`, `lugarNacimiento`, `lugarResidencia2013`, `lugarEstudio`, `lugarTrabajo`), las dimensiones `fecundidad`, `cuartosHogar`, `tipoHogar` y `condicionDificultad` reproducen las agrupaciones de los cuadros oficiales; con ellas el sistema reproduce los 25 cuadros sin diferencias (prueba de exactitud: `docs/pruebas.md`).

## Hechos

| Clave | Nombre | Grano |
|---|---|---|
| `poblacion` | Poblacion | una persona |
| `hogar` | Hogares | un hogar |
| `vivienda` | Viviendas | una vivienda |
| `migracion` | Emigracion internacional | un emigrante |

## Medidas

Conteos (o sumas) de un hecho; se pueden combinar en una consulta si son del mismo hecho.

| Clave | Nombre | Hecho | Descripción |
|---|---|---|---|
| `personas` | Personas | poblacion | Total de personas censadas. |
| `hombres` | Hombres | poblacion | Personas de sexo masculino. |
| `mujeres` | Mujeres | poblacion | Personas de sexo femenino. |
| `poblacion15a64` | Poblacion de 15 a 64 anios | poblacion | Poblacion en edades teoricamente activas (denominador de la relacion de dependencia). |
| `poblacionDependiente` | Poblacion dependiente | poblacion | Poblacion de 0 a 14 anios y de 65 anios o mas (numerador de la relacion de dependencia). |
| `pet` | Poblacion en edad de trabajar (PET) | poblacion | Personas de 15 anios o mas. |
| `pea` | Poblacion economicamente activa (PEA) | poblacion | Personas de 15 anios o mas ocupadas o desocupadas (aspirantes y cesantes). |
| `ocupados` | Poblacion ocupada (PO) | poblacion | Personas de 15 anios o mas ocupadas. |
| `desocupadosAbiertos` | Poblacion en desempleo abierto (PDA) | poblacion | Personas de 15 anios o mas desocupadas: aspirantes y cesantes. |
| `personas7oMas` | Personas de 7 anios o mas | poblacion | Poblacion a la que se pregunta si sabe leer y escribir. |
| `alfabetas` | Personas alfabetas de 7 anios o mas | poblacion | Personas de 7 anios o mas que saben leer y escribir en al menos un idioma. |
| `migrantesVida` | Migrantes de toda la vida | poblacion | Personas que residen en un municipio, departamento o pais distinto del de nacimiento. |
| `hogares` | Hogares | hogar | Total de hogares censados. |
| `personasEnHogares` | Personas en hogares | hogar | Suma de las personas de cada hogar. |
| `hogaresConInternet` | Hogares con internet | hogar | Hogares con servicio de internet. |
| `hogaresConRemesas` | Hogares que reciben remesas | hogar | Hogares que reciben remesas con regularidad. |
| `viviendas` | Viviendas | vivienda | Total de viviendas censadas. |
| `viviendasOcupadas` | Viviendas ocupadas | vivienda | Viviendas cuya condicion es ocupada. |
| `emigrantes` | Emigrantes internacionales | migracion | Personas que se fueron a vivir a otro pais desde 2002. |
| `emigrantesMujeres` | Emigrantes mujeres | migracion | Emigrantes de sexo femenino. |

## Indicadores

Se calculan como razón de dos medidas **agregadas** (numerador / denominador × multiplicador), por lo que son correctos a cualquier nivel de agregación: nunca se promedian tasas de los grupos (tesis 2.2.7). La respuesta incluye numerador y denominador para poder re-agregar.

| Clave | Fórmula | Numerador | Denominador | Fuente |
|---|---|---|---|---|
| `indiceMasculinidad` | (total de hombres / total de mujeres) * 100 | `hombres` | `mujeres` | Glosario de definiciones del Censo 2018 (INE) |
| `relacionDependencia` | ((poblacion de 0 a 14 + poblacion de 65 y mas) / poblacion de 15 a 64) * 100 | `poblacionDependiente` | `poblacion15a64` | Glosario de definiciones del Censo 2018 (INE) |
| `tasaGlobalParticipacion` | (PEA / PET) * 100 | `pea` | `pet` | Glosario de definiciones del Censo 2018 (INE) |
| `tasaBrutaOcupacion` | (PO / PET) * 100 | `ocupados` | `pet` | Glosario de definiciones del Censo 2018 (INE) |
| `tasaEspecificaOcupacion` | (PO / PEA) * 100 | `ocupados` | `pea` | Glosario de definiciones del Censo 2018 (INE) |
| `tasaDesempleoAbierto` | (PDA / PEA) * 100 | `desocupadosAbiertos` | `pea` | Glosario de definiciones del Censo 2018 (INE) |
| `tasaAlfabetismo` | (alfabetas de 7 anios o mas / personas de 7 anios o mas) * 100 | `alfabetas` | `personas7oMas` | Glosario de definiciones del Censo 2018 (INE) |
| `porcentajeMigrantesVida` | (migrantes de toda la vida / total de personas) * 100 | `migrantesVida` | `personas` | Glosario de definiciones del Censo 2018 (INE) |
| `tamanioPromedioHogar` | personas en hogares / hogares | `personasEnHogares` | `hogares` | Glosario de definiciones del Censo 2018 (INE) |
| `porcentajeHogaresConInternet` | (hogares con internet / hogares) * 100 | `hogaresConInternet` | `hogares` | Glosario de definiciones del Censo 2018 (INE) |
| `porcentajeHogaresConRemesas` | (hogares que reciben remesas / hogares) * 100 | `hogaresConRemesas` | `hogares` | Glosario de definiciones del Censo 2018 (INE) |
| `porcentajeViviendasOcupadas` | (viviendas ocupadas / viviendas) * 100 | `viviendasOcupadas` | `viviendas` | Glosario de definiciones del Censo 2018 (INE) |
| `porcentajeEmigrantesMujeres` | (emigrantes mujeres / emigrantes) * 100 | `emigrantesMujeres` | `emigrantes` | Glosario de definiciones del Censo 2018 (INE) |

## Dimensiones y niveles

Los niveles son las claves que se usan en `dimensiones` (agrupar) y en `filtros`. La columna Hechos indica en cuáles se puede usar.

| Dimensión | Niveles (clave) | Hechos |
|---|---|---|
| Territorio (`territorio`) | `lugarPoblado`, `municipio`, `departamento` | poblacion, hogar, vivienda, migracion |
| Edad (`edad`) | `edad`, `grupoQuinquenal`, `grupoAmplio` | poblacion, migracion |
| Sexo (`sexo`) | `sexo` | poblacion, migracion |
| Parentesco con la jefatura (`parentesco`) | `parentesco` | poblacion |
| Estado conyugal (`estadoConyugal`) | `estadoConyugal` | poblacion |
| Pueblo de pertenencia (`pueblo`) | `pueblo` | poblacion |
| Comunidad linguistica (`comunidadLinguistica`) | `comunidadLinguistica` | poblacion |
| Condicion de actividad (`condicionActividad`) | `condicionActividad` | poblacion |
| Categoria ocupacional (`categoriaOcupacional`) | `categoriaOcupacional` | poblacion |
| Actividad de la semana pasada (`actividadSemana`) | `actividadSemana` | poblacion |
| Actividad de quien no trabajo (`actividadNoTrabajo`) | `actividadNoTrabajo` | poblacion |
| Tipo de establecimiento educativo (`tipoEstablecimiento`) | `tipoEstablecimiento` | poblacion |
| Causa por la que no asiste a estudiar (`causaNoAsistencia`) | `causaNoAsistencia` | poblacion |
| Residencia en abril de 2013 (`tipoResidencia2013`) | `tipoResidencia2013`, `lugarResidencia2013` | poblacion |
| Idioma en que aprendio a hablar (`idiomaMaterno`) | `idiomaMaterno` | poblacion |
| Idioma en que sabe leer y escribir (1) (`idiomaLecturaEscritura1`) | `idiomaLecturaEscritura1` | poblacion |
| Otro idioma que habla (1) (`otroIdioma1`) | `otroIdioma1` | poblacion |
| Idioma en que sabe leer y escribir (2) (`idiomaLecturaEscritura2`) | `idiomaLecturaEscritura2` | poblacion |
| Otro idioma que habla (2) (`otroIdioma2`) | `otroIdioma2` | poblacion |
| Idioma en que sabe leer y escribir (3) (`idiomaLecturaEscritura3`) | `idiomaLecturaEscritura3` | poblacion |
| Otro idioma que habla (3) (`otroIdioma3`) | `otroIdioma3` | poblacion |
| Dificultad para ver (`dificultadVer`) | `dificultadVer` | poblacion |
| Dificultad para oir (`dificultadOir`) | `dificultadOir` | poblacion |
| Dificultad para caminar o subir escaleras (`dificultadCaminar`) | `dificultadCaminar` | poblacion |
| Dificultad para recordar o concentrarse (`dificultadRecordar`) | `dificultadRecordar` | poblacion |
| Dificultad para el cuidado personal (`dificultadCuidadoPersonal`) | `dificultadCuidadoPersonal` | poblacion |
| Dificultad para comunicarse (`dificultadComunicarse`) | `dificultadComunicarse` | poblacion |
| Condicion de dificultad (`condicionDificultad`) | `condicionDificultad` | poblacion |
| Inscripcion en el RENAP (`inscripcionRenap`) | `inscripcionRenap` | poblacion |
| Uso de traje tradicional (`usoTrajeTradicional`) | `usoTrajeTradicional` | poblacion |
| Uso de celular (`usoCelular`) | `usoCelular` | poblacion |
| Uso de computadora (`usoComputadora`) | `usoComputadora` | poblacion |
| Uso de internet (`usoInternet`) | `usoInternet` | poblacion |
| Nivel educativo (`nivelEducativo`) | `nivelEducativo`, `nivelGrado`, `nivelEducativoCensal` | poblacion |
| Ocupacion (`ocupacion`) | `grupoOcupacion`, `ocupacion` | poblacion |
| Rama de actividad economica (`ramaActividad`) | `grupoRamaActividad`, `ramaActividad` | poblacion |
| Tipo de lugar de nacimiento (`tipoLugarNacimiento`) | `tipoLugarNacimiento`, `lugarNacimiento` | poblacion |
| Departamento de nacimiento (`departamentoNacimiento`) | `departamentoNacimiento` | poblacion |
| Municipio de nacimiento (`municipioNacimiento`) | `municipioNacimiento` | poblacion |
| Pais de nacimiento (`paisNacimiento`) | `paisNacimiento` | poblacion |
| Departamento de residencia en 2013 (`departamentoResidencia2013`) | `departamentoResidencia2013` | poblacion |
| Municipio de residencia en 2013 (`municipioResidencia2013`) | `municipioResidencia2013` | poblacion |
| Pais de residencia en 2013 (`paisResidencia2013`) | `paisResidencia2013` | poblacion |
| Tipo de lugar donde estudia (`tipoLugarEstudio`) | `tipoLugarEstudio`, `lugarEstudio` | poblacion |
| Departamento donde estudia (`departamentoEstudio`) | `departamentoEstudio` | poblacion |
| Municipio donde estudia (`municipioEstudio`) | `municipioEstudio` | poblacion |
| Pais donde estudia (`paisEstudio`) | `paisEstudio` | poblacion |
| Tipo de lugar donde trabaja (`tipoLugarTrabajo`) | `tipoLugarTrabajo`, `lugarTrabajo` | poblacion |
| Departamento donde trabaja (`departamentoTrabajo`) | `departamentoTrabajo` | poblacion |
| Municipio donde trabaja (`municipioTrabajo`) | `municipioTrabajo` | poblacion |
| Pais donde trabaja (`paisTrabajo`) | `paisTrabajo` | poblacion |
| Alfabetismo (`esAlfabeta`) | `esAlfabeta` | poblacion |
| Asiste a un establecimiento educativo (`esEstudiante`) | `esEstudiante` | poblacion |
| Habla otro idioma (`tieneOtroIdioma`) | `tieneOtroIdioma` | poblacion |
| Trabajo la semana pasada (`esTrabajadorSemanaPasada`) | `esTrabajadorSemanaPasada` | poblacion |
| Su ultimo hijo esta vivo (`esVivoUltimoHijo`) | `esVivoUltimoHijo` | poblacion |
| Migrante de toda la vida (`esMigranteVida`) | `esMigranteVida` | poblacion |
| Migrante reciente (`esMigranteReciente`) | `esMigranteReciente` | poblacion |
| Fecundidad (`fecundidad`) | `hijosNacidosVivos`, `hijosSobrevivientes`, `edadPrimerHijo` | poblacion |
| Tipologia del hogar (`tipoHogar`) | `tipoHogar` | hogar, poblacion, migracion |
| Cuartos del hogar (`cuartosHogar`) | `numeroCuartos`, `numeroDormitorios` | hogar, poblacion, migracion |
| Tenencia de la vivienda (`tenenciaVivienda`) | `tenenciaVivienda` | hogar, poblacion, migracion |
| Fuente de agua (`fuenteAgua`) | `fuenteAgua` | hogar, poblacion, migracion |
| Tipo de servicio sanitario (`tipoServicioSanitario`) | `tipoServicioSanitario` | hogar, poblacion, migracion |
| Uso del servicio sanitario (`usoServicioSanitario`) | `usoServicioSanitario` | hogar, poblacion, migracion |
| Desague de aguas grises (`desagueAguasGrises`) | `desagueAguasGrises` | hogar, poblacion, migracion |
| Tipo de alumbrado (`tipoAlumbrado`) | `tipoAlumbrado` | hogar, poblacion, migracion |
| Eliminacion de basura (`eliminacionBasura`) | `eliminacionBasura` | hogar, poblacion, migracion |
| Combustible para cocinar (`combustibleCocina`) | `combustibleCocina` | hogar, poblacion, migracion |
| Sexo de la persona propietaria (`sexoPropietario`) | `sexoPropietario` | hogar, poblacion, migracion |
| Sexo de quien toma las decisiones (`sexoDecisiones`) | `sexoDecisiones` | hogar, poblacion, migracion |
| Tiene radio (`tieneRadio`) | `tieneRadio` | hogar, poblacion, migracion |
| Tiene estufa (`tieneEstufa`) | `tieneEstufa` | hogar, poblacion, migracion |
| Tiene televisor (`tieneTelevisor`) | `tieneTelevisor` | hogar, poblacion, migracion |
| Tiene servicio de cable (`tieneCable`) | `tieneCable` | hogar, poblacion, migracion |
| Tiene refrigeradora (`tieneRefrigeradora`) | `tieneRefrigeradora` | hogar, poblacion, migracion |
| Tiene tanque o deposito de agua (`tieneTanqueAgua`) | `tieneTanqueAgua` | hogar, poblacion, migracion |
| Tiene lavadora de ropa (`tieneLavadora`) | `tieneLavadora` | hogar, poblacion, migracion |
| Tiene computadora (`tieneComputadora`) | `tieneComputadora` | hogar, poblacion, migracion |
| Tiene servicio de internet (`tieneInternet`) | `tieneInternet` | hogar, poblacion, migracion |
| Tiene temazcal o tuj (`tieneTemazcal`) | `tieneTemazcal` | hogar, poblacion, migracion |
| Tiene sistema de agua caliente (`tieneAguaCaliente`) | `tieneAguaCaliente` | hogar, poblacion, migracion |
| Tiene moto (`tieneMoto`) | `tieneMoto` | hogar, poblacion, migracion |
| Tiene carro (`tieneCarro`) | `tieneCarro` | hogar, poblacion, migracion |
| Tiene cuarto exclusivo para cocinar (`tieneCuartoCocina`) | `tieneCuartoCocina` | hogar, poblacion, migracion |
| Recibe remesas (`tieneRemesas`) | `tieneRemesas` | hogar, poblacion, migracion |
| Tiene emigrantes (`tieneEmigrantes`) | `tieneEmigrantes` | hogar, poblacion, migracion |
| Tipo de vivienda (`tipoVivienda`) | `tipoVivienda` | vivienda, hogar, poblacion, migracion |
| Material de las paredes (`materialPared`) | `materialPared` | vivienda, hogar, poblacion, migracion |
| Material del techo (`materialTecho`) | `materialTecho` | vivienda, hogar, poblacion, migracion |
| Material del piso (`materialPiso`) | `materialPiso` | vivienda, hogar, poblacion, migracion |
| Condicion de la vivienda (`condicionVivienda`) | `condicionVivienda` | vivienda, hogar, poblacion, migracion |
| Area urbana (`esUrbano`) | `esUrbano` | vivienda, hogar, poblacion, migracion |

## Operadores de filtro

| Operador | Descripción | Valores |
|---|---|---|
| `Igual` | Igual a un valor. | 1 valor |
| `Distinto` | Distinto de un valor. | 1 valor |
| `En` | Igual a alguno de varios valores. | 1 a 500 valores |
| `NoEn` | Distinto de todos los valores. | 1 a 500 valores |
| `Entre` | Entre dos valores, inclusive. | 2 valores |
| `MayorOIgual` | Mayor o igual que un valor. | 1 valor |
| `MenorOIgual` | Menor o igual que un valor. | 1 valor |

## Ejemplo de solicitud

```json
POST /api/consultas
{
  "indicadores": ["tasaGlobalParticipacion"],
  "medidas": [],
  "dimensiones": ["departamento"],
  "filtros": [{ "nivel": "sexo", "operador": "Igual", "valores": [2] }],
  "limite": 100
}
```

Cada fila de la respuesta trae el nombre y el código del nivel agrupado, el valor del indicador y, con `incluirComponentes` (por defecto sí), su numerador y denominador.
