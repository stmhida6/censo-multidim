# Guía del tablero en Power BI

El tablero es la capa de visualización del sistema (tesis 2.7 y objetivo específico 3). Sigue lo que establece la sección 2.7.1: **el tablero presenta las opciones, envía las solicitudes y representa los resultados; las reglas de cálculo y la generación de consultas se quedan en la API.** Por eso Power BI se conecta a la API (`POST /api/consultas`) y no directamente a las tablas de SQL Server: si lo hiciera, tendría que repetir en DAX la definición de cada indicador, y dos herramientas podrían dar resultados distintos.

> **¿Primera vez con Power BI?** Sigue `guia-paso-a-paso.md`: explica cada clic y los valores que deben aparecer en cada página.

El archivo `.pbix` no se versiona (`.gitignore`). Lo que sí se versiona es la lógica de conexión, en texto:

| Archivo | Contenido |
|---|---|
| `consultas/00-UrlApi.pq` | Parámetro con la dirección de la API |
| `consultas/01-ConsultarCenso.pq` | Función que envía una solicitud a la API y devuelve la tabla con sus tipos; la usan todas las consultas |
| `consultas/02-Catalogo.pq` | Catálogo de indicadores, medidas y niveles (`GET /api/catalogo/*`) |
| `consultas/10-Paginas.pq` | Consultas de las páginas fijas del tablero |
| `consultas/20-ConsultaLibre.pq` | Página de consulta libre: la combinación de variables se elige al momento |
| `medidas.dax` | Medidas DAX (re-agregación de indicadores y presentación) |

## Paso 0. Requisitos

1. **Power BI Desktop**, gratuito (Microsoft Store o microsoft.com/power-bi). No se necesita licencia para crear el informe.
2. **La API en marcha:** `docker compose up -d` y comprobar que `http://localhost:5000/salud` responde `{"estado":"ok"}`.

## Paso 1. Parámetro y función de conexión

1. Abrir Power BI Desktop, **Inicio > Transformar datos** (abre Power Query).
2. **Inicio > Administrar parámetros > Nuevo parámetro:** nombre `UrlApi`, tipo *Texto*, valor actual `http://localhost:5000/`.
3. **Inicio > Nueva fuente > Consulta en blanco**, luego **Editor avanzado**: pegar `consultas/01-ConsultarCenso.pq` y nombrar la consulta `ConsultarCenso`.
4. **Configuración de privacidad** (evita el error del *firewall* de fórmulas al combinar consultas): **Archivo > Opciones y configuración > Opciones > Archivo actual > Privacidad**, elegir *Ignorar los niveles de privacidad*. En **Configuración de origen de datos**, dejar `http://localhost:5000/` con autenticación *Anónima*.

Prueba rápida: una consulta en blanco con `= ConsultarCenso([medidas = {"personas"}])` debe devolver 14,901,286.

## Paso 2. Consultas del catálogo y de las páginas

Crear una consulta en blanco por cada bloque de `02-Catalogo.pq` y `10-Paginas.pq`, con el nombre indicado en el comentario de cada bloque:

| Consulta | Qué trae | Filas |
|---|---|---:|
| `CatalogoIndicadores`, `CatalogoMedidas`, `CatalogoNiveles` | Lo que se puede consultar, con nombres, fórmulas y fuentes | 13, 20, 108 |
| `ListaNiveles`, `ListaValores` | Listas para los parámetros de la consulta libre | |
| `Totales` | Personas, hogares, viviendas y emigrantes | 4 |
| `IndicadoresNacionales` | 10 indicadores nacionales (clave, valor) | 10 |
| `IndicadoresPorMunicipio` | 4 indicadores por municipio, con numerador y denominador | 340 |
| `Piramide` | Personas por departamento, grupo quinquenal y sexo | 924 |
| `PoblacionPorPueblo` | Personas por departamento y pueblo | 132 |
| `HogaresPorFuenteAgua` | Hogares por departamento, área y fuente de agua | 412 |
| `IndicadoresHogarPorDepartamento` | Tamaño del hogar, internet y remesas | 22 |

Desactivar la carga de `ConsultarCenso`, `ListaNiveles` y `ListaValores` (clic derecho > *Habilitar carga*), porque no son tablas del modelo. **Cerrar y aplicar.**

## Paso 3. Modelo

1. **Relación:** `IndicadoresNacionales[clave]` con `CatalogoIndicadores[clave]` (varios a uno). Así cada valor tiene nombre, fórmula y fuente.
2. **Ordenar por columna:** `Piramide[grupoQuinquenal]` por `Piramide[OrdenGrupo]`; los nombres de departamento por su columna `departamento_codigo`.
3. **Resumen predeterminado:** en las columnas de indicadores (por ejemplo `IndicadoresPorMunicipio[tasaAlfabetismo]`), elegir *No resumir*. Un indicador nunca se suma ni se promedia.
4. **Medidas:** crear las de `medidas.dax`. Cuando una visualización junta varias filas (una tarjeta con el total de un departamento), el indicador se re-agrega con el numerador y el denominador que devuelve la API: razón de sumas, no promedio de tasas (tesis 2.2.7).
5. **Categoría de datos:** `IndicadoresPorMunicipio[Ubicacion]` como *Lugar* (para el mapa).

## Paso 4. Páginas del tablero

Propuesta de cinco páginas más una del catálogo. Microsoft recomienda elegir la visualización según la relación que se quiere mostrar (tesis 2.7.1): tablas para valores exactos y gráficas para comparar territorios o grupos.

| Página | Visualizaciones | Datos |
|---|---|---|
| **1. Panorama nacional** | 4 tarjetas (personas, hogares, viviendas, emigrantes); tabla de indicadores con nombre, valor, fórmula y fuente | `Totales`, `IndicadoresNacionales` + `CatalogoIndicadores` |
| **2. Territorio** | Segmentación por departamento; tarjetas con las 4 medidas de `medidas.dax`; barras horizontales de un indicador por municipio; mapa de burbujas por `Ubicacion`; tabla con valores exactos | `IndicadoresPorMunicipio` |
| **3. Población** | Pirámide de edad (barras horizontales apiladas: eje `grupoQuinquenal`, leyenda `sexo`, valor `Personas piramide`) con segmentación por departamento; barras de pueblo de pertenencia | `Piramide`, `PoblacionPorPueblo` |
| **4. Hogar y vivienda** | Barras 100 % apiladas de fuente de agua por departamento con segmentación urbano/rural; tabla de tamaño del hogar, internet y remesas | `HogaresPorFuenteAgua`, `IndicadoresHogarPorDepartamento` |
| **5. Consulta libre** | Tabla y gráfica de barras sobre `Categoria 1` (leyenda `Categoria 2`, valor `Valor agregado`); tarjeta con la columna `Solicitud` (el JSON enviado a la API) | `ConsultaLibre` |
| **Catálogo** | Tablas con los indicadores (fórmula, fuente), las medidas y los niveles disponibles | `Catalogo*` |

Sugerencias de presentación: un título por página que diga qué muestra; la fuente al pie ("INE, Censo 2018; sistema de consulta multidimensional"); formato de miles en los conteos y dos decimales en los indicadores.

## Paso 5. Consulta libre: la combinación se elige al momento

Es la página que permite elegir la combinación de variables al momento de consultar. Aquí se elige qué consultar y el tablero envía una solicitud nueva a la API, sin modificar el informe.

1. En Power Query crear los parámetros de `20-ConsultaLibre.pq` (`Valor`, `EsIndicador`, `Dimension1`, `Dimension2`, `FiltroNivel`, `FiltroValor`). En `Valor` y `Dimension1`, en *Valores sugeridos* elegir *Consulta* y seleccionar `ListaValores` o `ListaNiveles`: el diálogo mostrará una lista desplegable con las claves del catálogo.
2. Crear la consulta `ConsultaLibre` con `20-ConsultaLibre.pq`.
3. Para cambiar la consulta: **Inicio > Transformar datos > Editar parámetros**, elegir los valores y **Aplicar cambios**. Ejemplos:

| Pregunta | Valor | EsIndicador | Dimension1 | Dimension2 | FiltroNivel | FiltroValor |
|---|---|---|---|---|---|---|
| Alfabetismo por pueblo y sexo en Quiché | `tasaAlfabetismo` | true | `pueblo` | `sexo` | `departamento` | `14` |
| Hogares por tipología y área | `hogares` | false | `tipoHogar` | `esUrbano` | | |
| Personas por nivel educativo del INE y sexo | `personas` | false | `nivelEducativoCensal` | `sexo` | | |
| Desempleo abierto por grupo quinquenal | `tasaDesempleoAbierto` | true | `grupoQuinquenal` | | | |

Si una clave no existe en el catálogo, Power BI muestra el error que devolvió la API (400 con la lista de problemas): la validación también ocurre en el servidor.

Qué esperar al leer los resultados (comprobado simulando la consulta libre contra la API):

- Los niveles booleanos (`esUrbano`, `tieneInternet`, ...) llegan como "Si" y "No": en `esUrbano`, "Si" es urbana.
- Aparece un grupo "No aplica" cuando la pregunta no se hizo a esa persona (por ejemplo, el nivel educativo de los 1,334,389 menores de 4 años). Es un miembro legítimo del resultado, no un error.
- Un indicador sale vacío en los grupos donde no aplica (la tasa de desempleo para 0-14 años tiene denominador 0); la medida `Valor agregado` usa `DIVIDE`, que devuelve vacío en lugar de error.

Limitación conocida: Power BI no permite que una segmentación del informe cambie una solicitud web en modo importación (los parámetros dinámicos enlazados a segmentaciones solo funcionan con DirectQuery). Por eso la consulta libre se cambia desde *Editar parámetros*. Otra aplicación cliente (una página web, por ejemplo) podría ofrecer la misma libertad de forma interactiva, porque la lógica está en la API.

## Paso 6. Comprobación

- Guardar el `.pbix` fuera del repositorio.
- Comprobación cruzada: un valor del tablero (por ejemplo, la tasa de alfabetismo nacional, 81.53 %) debe coincidir con la API y con los cuadros oficiales (la API se valida contra los 25 cuadros con la prueba de exactitud: `docs/manual-tecnico.md`).

## Paso 7. Cuando se despliegue en Azure

- Cambiar el parámetro `UrlApi` por la dirección de la API en Azure (HTTPS) y actualizar.
- Para publicar en el servicio de Power BI y programar actualizaciones: como `ConsultarCenso` usa una URL base fija con `RelativePath`, el servicio puede actualizar el origen web sin puerta de enlace si la API es pública. La publicación y el uso compartido requieren una licencia (Pro o Premium por usuario), que conviene evaluar según el escenario (tesis 2.7.2).
- La actualización del informe envía unas 12 solicitudes seguidas: quedan dentro del límite de 120 solicitudes por minuto de la API.
