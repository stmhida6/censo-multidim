# Guía paso a paso: tablero de Power BI con la API local

> Para quien empieza con Power BI. Explica cada clic y qué valores deben aparecer para comprobar que el tablero está bien conectado. Complementa `powerbi/README.md`, que tiene el diseño completo. Los menús están en español; entre paréntesis, el nombre en inglés por si tu Power BI está en ese idioma.
>
> Tiempo estimado: 2 a 3 horas la primera vez. Todo funciona **en tu equipo** (API local), sin Azure y sin costo.

## 0. Antes de empezar

1. **Abre Docker Desktop** y espera a que diga *Engine running*.
2. En una terminal, desde la carpeta del proyecto, levanta la base y la API **con un límite de solicitudes más alto**. Mientras editas, Power BI hace muchas consultas seguidas y podría chocar con el límite normal de 120 por minuto:
   ```bash
   API_LIMITE_POR_MINUTO=2000 docker compose up -d sqlserver api
   ```
3. Abre en el navegador `http://localhost:5000/salud`. Debe mostrar `{"estado":"ok"}`. Si no, la API no está lista; espera un minuto y repite.
4. Elige una carpeta **fuera del repositorio** para el archivo de Power BI (por ejemplo `Documentos\TableroCenso2018.pbix`): el `.pbix` no se versiona.
5. Al terminar el día, vuelve la API a su límite normal: `docker compose up -d api`.

## 1. Las 4 zonas de Power BI que vas a usar

| Zona | Dónde está | Para qué |
|---|---|---|
| **Editor de Power Query** | *Inicio > Transformar datos* (*Home > Transform data*) | Traer los datos de la API |
| **Vista de informe** | Primer icono de la barra izquierda (un gráfico) | Armar las páginas con gráficas |
| **Vista de modelo** | Tercer icono de la barra izquierda (tres cuadros unidos) | Relacionar tablas |
| **Paneles de la derecha** | *Visualizaciones* (*Visualizations*) y *Datos* (*Data*) | Elegir el tipo de gráfica y arrastrar los campos |

En el panel *Visualizaciones*, debajo de los iconos de gráficas, hay **casillas** (*Eje Y*, *Eje X*, *Leyenda*, *Valores*...). Armar una gráfica es arrastrar campos desde el panel *Datos* a esas casillas.

## 2. Conectar Power BI con la API (Power Query)

### 2.1 Parámetro con la dirección de la API

1. Abre Power BI Desktop: *Archivo > Nuevo* (*File > New*).
2. *Inicio > Transformar datos* (*Home > Transform data*). Se abre el Editor de Power Query.
3. *Inicio > Administrar parámetros > Nuevo parámetro* (*Manage Parameters > New Parameter*).
   - Nombre: `UrlApi`
   - Tipo: *Texto* (*Text*)
   - Valor actual: `http://localhost:5000/` (con la barra al final)
   - *Aceptar*.

### 2.2 La función que habla con la API

1. *Inicio > Nuevo origen > Consulta en blanco* (*New Source > Blank Query*).
2. *Inicio > Editor avanzado* (*Advanced Editor*). Borra todo lo que aparece.
3. Abre `powerbi/consultas/01-ConsultarCenso.pq` en el Bloc de notas, copia **todo** y pégalo. *Listo* (*Done*).
4. En el panel derecho *Configuración de la consulta*, en *Nombre*, escribe `ConsultarCenso`.

### 2.3 Privacidad (evita el error más común)

*Archivo > Opciones y configuración > Opciones* (*File > Options and settings > Options*). En la parte de abajo, sección **ARCHIVO ACTUAL > Privacidad** (*CURRENT FILE > Privacy*): elige **Omitir los niveles de privacidad** (*Ignore the Privacy Levels*). *Aceptar*.

### 2.4 Prueba de conexión

1. Nueva consulta en blanco, y en la barra de fórmulas (arriba, junto a *fx*) escribe:
   ```
   = ConsultarCenso([medidas = {"personas"}])
   ```
2. Si aparece un aviso amarillo de credenciales, pulsa *Editar credenciales* y elige **Anónimo** (*Anonymous*) > *Conectar*.
3. Debe aparecer una tabla con **14901286**. Si es así, la conexión funciona. Puedes borrar esta consulta de prueba (clic derecho > *Eliminar*).


### 2.5 Crear las consultas del tablero

Cada consulta se crea igual: *Nuevo origen > Consulta en blanco > Editor avanzado*, pegar el bloque y ponerle el nombre indicado.

Los archivos `02-Catalogo.pq` y `10-Paginas.pq` tienen **varias consultas**. Cada bloque empieza con una línea como `// ------------ NombreDeLaConsulta` y va desde `let` hasta el nombre que aparece después de `in`. Copia solo ese bloque, sin la línea de comentario.

| Nombre de la consulta | De qué archivo | Debe mostrar |
|---|---|---|
| `CatalogoIndicadores` | `02-Catalogo.pq` | 13 filas |
| `CatalogoMedidas` | `02-Catalogo.pq` | 20 filas |
| `CatalogoNiveles` | `02-Catalogo.pq` | 108 filas |
| `ListaNiveles` | `02-Catalogo.pq` (línea `= CatalogoNiveles[nivel]`) | Una lista |
| `ListaValores` | `02-Catalogo.pq` (línea `= List.Combine(...)`) | Una lista |
| `Totales` | `10-Paginas.pq` | 4 filas: Personas 14,901,286; Hogares 3,275,931; Viviendas 3,943,085; Emigrantes 242,203 |
| `IndicadoresNacionales` | `10-Paginas.pq` | 10 filas |
| `IndicadoresPorMunicipio` | `10-Paginas.pq` | 340 filas |
| `Piramide` | `10-Paginas.pq` | 924 filas |
| `PoblacionPorPueblo` | `10-Paginas.pq` | 132 filas |
| `HogaresPorFuenteAgua` | `10-Paginas.pq` | 412 filas |
| `IndicadoresHogarPorDepartamento` | `10-Paginas.pq` | 22 filas |

Las listas `ListaNiveles` y `ListaValores` se crean como consulta en blanco, escribiendo esa línea en la barra de fórmulas.

Para ver cuántas filas tiene una consulta, mira la esquina inferior izquierda del editor ("N COLUMNAS, M FILAS").

### 2.6 Las que no son tablas

Clic derecho sobre `ConsultarCenso`, `ListaNiveles` y `ListaValores` > desmarca **Habilitar carga** (*Enable load*). El nombre se verá en cursiva.

Por último: *Inicio > Cerrar y aplicar* (*Close & Apply*). Power BI carga los datos; tarda unos segundos.


## 3. Preparar el modelo

1. **Relación:** ve a la *Vista de modelo*. Arrastra el campo `clave` de la tabla `IndicadoresNacionales` hasta el campo `clave` de `CatalogoIndicadores`. Aparece una línea entre las dos tablas.
2. **Ordenar la pirámide por edad:** en la *Vista de tabla* (segundo icono de la izquierda), elige la tabla `Piramide` y selecciona la columna `grupoQuinquenal`. En la cinta: *Herramientas de columnas > Ordenar por columna* (*Column tools > Sort by column*) > `OrdenGrupo`.
3. **Que los indicadores no se sumen:** en el panel *Datos*, selecciona cada columna de indicador (por ejemplo `IndicadoresPorMunicipio > tasaAlfabetismo`). En *Herramientas de columnas*, pon *Resumen* (*Summarization*) en **No resumir** (*Don't summarize*). Haz lo mismo con `IndicadoresNacionales > valor` y con las columnas de `IndicadoresHogarPorDepartamento`.
4. **Medidas:** abre `powerbi/medidas.dax`. Para cada medida: en el panel *Datos*, clic derecho sobre la tabla indicada > *Nueva medida* (*New measure*). Pega **solo esa medida**, desde su nombre hasta el final de la fórmula, y presiona Enter. Son 7: 4 en `IndicadoresPorMunicipio`, 1 en `Piramide`, 1 en `HogaresPorFuenteAgua` y 1 en `ConsultaLibre`. La de `ConsultaLibre` créala hasta la sección 5.

## 4. Las páginas del tablero

Cada página nueva se crea con el `+` de abajo. Para renombrarla: doble clic sobre su pestaña.

### Página 1: "Panorama nacional"

1. **4 tarjetas:**
   - En *Visualizaciones*, elige *Tarjeta* (*Card*) y arrastra `Totales > Valor` a *Campos*.
   - En el panel *Filtros* (*Filters*), en *Filtros en este objeto visual*, arrastra `Concepto` y marca solo `Personas`.
   - Repite para Hogares, Viviendas y Emigrantes. Puedes copiar la tarjeta con `Ctrl + C`, `Ctrl + V` y cambiar el filtro.
2. **Tabla de indicadores:** elige *Tabla* (*Table*) y arrastra, en este orden, `CatalogoIndicadores > nombre`, `IndicadoresNacionales > valor`, `CatalogoIndicadores > formula` y `CatalogoIndicadores > fuente`.
3. Título: *Insertar > Cuadro de texto* (*Insert > Text box*): "Panorama nacional del Censo 2018".

**Comprueba:**

| Elemento | Valor esperado |
|---|---|
| Personas | 14,901,286 |
| Hogares | 3,275,931 |
| Viviendas | 3,943,085 |
| Emigrantes | 242,203 |
| Índice de masculinidad | 94.07 |
| Relación de dependencia | 63.91 |
| Tasa global de participación | 50.57 |
| Tasa de desempleo abierto | 2.70 |
| Tasa de alfabetismo | 81.53 |
| Porcentaje de migrantes de toda la vida | 17.44 |
| Tamaño promedio del hogar | 4.54 |
| Porcentaje de hogares con internet | 17.26 |
| Porcentaje de hogares con remesas | 8.49 |
| Porcentaje de viviendas ocupadas | 80.64 |


### Página 2: "Territorio"

1. **Segmentación por departamento:** elige *Segmentación de datos* (*Slicer*) y arrastra `IndicadoresPorMunicipio > departamento`.
2. **4 tarjetas** con las medidas `Tasa global de participacion`, `Tasa de desempleo abierto`, `Tasa de alfabetismo` e `Indice de masculinidad`. Arrastra cada medida a una *Tarjeta*.
3. **Barras por municipio:** elige *Gráfico de barras agrupadas* (*Clustered bar chart*). En *Eje Y*, `municipio`; en *Eje X*, la medida `Tasa de alfabetismo`. Ordénalo de menor a mayor: clic en `...` de la gráfica > *Ordenar eje*.
4. **Tabla:** `municipio`, `tasaAlfabetismo`, `tasaGlobalParticipacion`.

**Comprueba** (es la prueba más importante del tablero): elige **Quiché** en la segmentación. Las tarjetas suman los 21 municipios de Quiché y deben dar **exactamente** las cifras que la API calcula para el departamento:

| Tarjeta | Valor esperado para Quiché |
|---|---|
| Tasa global de participación | 45.38 |
| Tasa de desempleo abierto | 1.56 |
| Tasa de alfabetismo | 67.36 |
| Índice de masculinidad | 92.19 |

El municipio con menor alfabetismo de Quiché es **San Andrés Sajcabajá (54.23 %)**. Sin selección, deben verse los 340 municipios.


(Opcional) **Mapa:** elige *Mapa* (*Map*) y arrastra `Ubicacion` a *Ubicación*. Si el mapa aparece deshabilitado, actívalo en *Archivo > Opciones > Seguridad > Usar objetos visuales de mapa y mapa coroplético*.

### Página 3: "Población"

1. **Pirámide:**
   - Elige *Gráfico de barras apiladas* (*Stacked bar chart*).
   - En *Eje Y*, `Piramide > grupoQuinquenal`; en *Leyenda*, `sexo`; en *Eje X*, la medida `Personas piramide`.
   - Si las edades salen al revés, usa `...` > *Ordenar eje* > `grupoQuinquenal`.
2. **Formato de los números (que los hombres no se vean negativos):** selecciona la medida `Personas piramide` en el panel *Datos*. En *Herramientas de medición > Formato*, escribe `#,0;#,0`.
3. **Segmentación:** `Piramide > departamento`.
4. **Pueblos:** *Gráfico de barras agrupadas* con `PoblacionPorPueblo > pueblo` en *Eje Y* y `personas` en *Eje X*.

**Comprueba:**

| Elemento | Valor esperado |
|---|---|
| Grupo 0-4, todo el país | Hombres 850,065; mujeres 831,825 |
| Grupo 0-4, Quiché | Hombres 62,826; mujeres 61,472 |
| Pueblo maya, todo el país | 6,207,503 |


### Página 4: "Hogar y vivienda"

1. **Fuente de agua:** elige *Gráfico de barras 100 % apiladas* (*100% stacked bar chart*). En *Eje Y*, `HogaresPorFuenteAgua > departamento`; en *Leyenda*, `fuenteAgua`; en *Eje X*, `hogares`.
2. **Segmentación** con `HogaresPorFuenteAgua > Area` (Urbana o Rural).
3. **Tabla** con `IndicadoresHogarPorDepartamento`: `departamento`, `tamanioPromedioHogar`, `porcentajeHogaresConInternet` y `porcentajeHogaresConRemesas`.

**Comprueba:** departamento de Guatemala: tamaño promedio del hogar **3.98** y hogares con internet **41.56 %**. En todo el país, los hogares con tubería dentro de la vivienda son **1,931,149**.


### Página 5: "Consulta libre" (la más importante)

Demuestra que la combinación de variables no está fijada: se elige y el tablero pide un resultado nuevo a la API.

1. En Power Query, crea **6 parámetros** (*Administrar parámetros > Nuevo parámetro*):

   | Nombre | Tipo | Requerido | Valores sugeridos | Valor inicial |
   |---|---|---|---|---|
   | `Valor` | Texto | Sí | *Consulta*: `ListaValores` | `tasaAlfabetismo` |
   | `EsIndicador` | Verdadero/Falso (*True/False*) | Sí | — | `true` |
   | `Dimension1` | Texto | Sí | *Consulta*: `ListaNiveles` | `pueblo` |
   | `Dimension2` | Texto | No | *Consulta*: `ListaNiveles` | `sexo` |
   | `FiltroNivel` | Texto | No | — | `departamento` |
   | `FiltroValor` | Texto | No | — | `14` |

2. Crea la consulta `ConsultaLibre` con `powerbi/consultas/20-ConsultaLibre.pq`, sin la cabecera de comentarios. *Cerrar y aplicar*.
3. Crea la medida `Valor agregado` en la tabla `ConsultaLibre` (último bloque de `medidas.dax`).
4. **Visualizaciones:**
   - *Tabla* con `Categoria 1`, `Categoria 2` y la medida `Valor agregado`.
   - *Gráfico de barras agrupadas*: `Categoria 1` en *Eje Y*, `Categoria 2` en *Leyenda* y `Valor agregado` en *Eje X*.
   - *Tarjeta* con `Solicitud`. Si muestra "Recuento", cámbialo a *Primero* con la flechita del campo. Así se ve el JSON que se envió a la API.

**Primera combinación** (los valores iniciales): alfabetismo por pueblo y sexo en Quiché. **Comprueba:** Maya hombres **71.94**, Maya mujeres **59.13**.


**Segunda combinación:** *Inicio > Transformar datos > Editar parámetros* (*Edit parameters*). Cambia a `Valor` = `hogares`, `EsIndicador` = `false`, `Dimension1` = `tipoHogar`, `Dimension2` = `esUrbano`, y deja `FiltroNivel` y `FiltroValor` **vacíos**. *Aceptar* > *Aplicar cambios*. **Comprueba:** Unipersonal "No" (rural) **67,993** y "Sí" (urbano) **131,207**; Nuclear "No" **870,774** y "Sí" **1,155,646**.


**Tercera, la validación del servidor:** pon `Valor` = `indicadorInventado` y aplica. Power BI debe mostrar un error con el mensaje de la API: *"El indicador 'indicadorInventado' no existe en el catalogo"*. Así se demuestra que la API valida cada solicitud.


### Página 6: "Catálogo" (opcional)

Tres *Tablas*: `CatalogoIndicadores` (nombre, fórmula, fuente), `CatalogoMedidas` (nombre, descripción) y `CatalogoNiveles` (nombreDimension, nombreNivel, hechos).


## 5. Comprobación API frente a Power BI (evidencia P-16)

La guía de figuras pide demostrar que Power BI muestra lo mismo que la API. Para cada fila, anota el valor que ves en Power BI. El de la API ya está consultado:

| Consulta | Valor de la API | Valor en Power BI | ¿Igual? |
|---|---:|---:|:---:|
| Personas (total nacional) | 14,901,286 | | |
| Tasa de alfabetismo nacional | 81.53 | | |
| Tasa global de participación de Quiché (sumando sus municipios) | 45.38 | | |
| Alfabetismo de hombres mayas en Quiché (consulta libre) | 71.94 | | |
| Hogares unipersonales urbanos (consulta libre) | 131,207 | | |

Si quieres consultar tú mismo el valor de la API: abre `http://localhost:5000/swagger`, *POST /api/consultas > Try it out*, pega la solicitud (la tarjeta `Solicitud` de la página 5 te la da) y pulsa *Execute*.


## 6. Guardar

*Archivo > Guardar como* > la carpeta elegida en el paso 0 (por ejemplo `TableroCenso2018.pbix`). No lo guardes dentro del repositorio: el `.pbix` no se versiona.

## 7. Si algo falla

| Mensaje o síntoma | Causa | Solución |
|---|---|---|
| `Formula.Firewall` o "...hace referencia a otras consultas..." | Niveles de privacidad | Paso 2.3 |
| `DataSource.Error: No se puede conectar` | La API no está encendida | Paso 0: Docker abierto y `docker compose up -d sqlserver api` |
| Pide credenciales | Primera conexión al sitio | Elegir **Anónimo** |
| `La API rechazo la consulta (HTTP 429)` | Muchas consultas seguidas | Esperar un minuto o subir el límite (paso 0) |
| `La API rechazo la consulta (HTTP 400)` | Una clave mal escrita | Revisar la ortografía con `docs/catalogo.md` (mayúsculas incluidas) |
| `Expression.Error: No se encontró la columna...` | El bloque se copió incompleto | Copiar de nuevo el bloque completo desde `let` |
| Un indicador muestra un número enorme | Se está sumando | Paso 3.3: *No resumir*, o usar la medida |
| La segmentación no filtra otra gráfica | Son de tablas distintas | Usar en la segmentación un campo de la misma tabla que la gráfica |
| Acentos raros (`SacatepÃ©quez`) | Los CSV se exportaron con otra codificación | Volver a cargar con `bash etl/ejecutar-etl.sh --exportar --recargar` (manual técnico, solución de problemas) |


Para otros problemas, consulte la sección de solución de problemas de `docs/manual-tecnico.md`.
