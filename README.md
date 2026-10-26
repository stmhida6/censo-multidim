# Sistema de consulta multidimensional del Censo 2018 de Guatemala

Consulta dinámica de indicadores del XII Censo Nacional de Población y VII de Vivienda 2018 de Guatemala. Las combinaciones de variables (territorio, sexo, edad, pueblo, vivienda, hogar y más) se eligen al momento de consultar, y los resultados coinciden con los cuadros oficiales del Instituto Nacional de Estadística (INE).

- **Almacén de datos** en SQL Server 2022 con modelo en estrella: 4 hechos, 40 dimensiones y 22.4 millones de registros.
- **ETL** reproducible desde los microdatos del INE (R y T-SQL), con 59 controles de calidad.
- **API REST** en ASP.NET Core 8 con un catálogo de 13 indicadores, 20 medidas y 108 niveles; SQL parametrizado y usuario de solo lectura.
- **Tablero de Power BI** que consume la API.
- **Exactitud verificada:** 124,509 celdas de 25 cuadros oficiales del INE, sin diferencias.
- **Despliegue en Azure** con scripts reproducibles.

![Arquitectura](docs/imagenes/fig-01-arquitectura-final.png)

## Requisitos

Git (Git Bash en Windows), Docker Desktop, R 4.5 con `haven`, `data.table`, `dplyr` y `jsonlite`, y .NET SDK 8. Para producción, además: Azure CLI, SqlPackage y Python 3. Equipo con 16 GB de RAM y 20 GB libres.

Los **microdatos del Censo 2018** no se incluyen en el repositorio. Se descargan del sitio oficial del censo del INE, en [censo2018.ine.gob.gt/descarga](https://censo2018.ine.gob.gt/descarga), en formato SPSS: `VIVIENDA_BDP.sav`, `HOGAR_BDP.sav`, `PERSONA - BDP.sav` y `MIGRACION_BDP.sav`.

## Inicio rápido

```bash
git clone https://github.com/stmhida6/censo-multidim.git
cd censo-multidim
cp .env.example .env                       # 1. definir MSSQL_SA_PASSWORD y CLAVE_API
# 2. copiar los cuatro .sav del INE a datos/microdatos/
docker compose up -d sqlserver             # 3. SQL Server (esperar "healthy")
bash db/crear-esquema.sh                   # 4. base y modelo en estrella vacío
bash db/crear-usuario-api.sh               # 5. usuario de solo lectura de la API
bash etl/ejecutar-etl.sh                   # 6. carga completa, unos 31 minutos (59 de 59 controles)
docker compose up -d api                   # 7. API en http://localhost:5000
```

Verificación:

```bash
curl http://localhost:5000/salud           # {"estado":"ok"}
curl -s -H "Content-Type: application/json" -d '{"medidas":["personas"]}' http://localhost:5000/api/consultas   # 14,901,286
dotnet test pruebas/Censo.Pruebas.Integracion --filter "Categoria=Exactitud"   # 124,509 celdas, 0 diferencias
```

Documentación interactiva de la API: `http://localhost:5000/swagger`.

## Documentación

| Documento | Contenido |
|---|---|
| [Manual técnico](docs/manual-tecnico.md) | Requisitos, instalación, verificación, puesta en producción en Azure, operación, mantenimiento y solución de problemas |
| [Manual de usuario](docs/manual-usuario.md) | Uso del tablero de Power BI y de la API, con ejemplos de cuadros |
| [Pruebas y resultados de referencia](docs/pruebas.md) | Pruebas automáticas, exactitud, conteos esperados y rendimiento |
| [Catálogo](docs/catalogo.md) | Hechos, dimensiones, medidas, indicadores y operadores consultables |
| [Convenciones](docs/convenciones.md) | Stack, nombres del esquema y decisiones de diseño |
| [Diagramas](docs/diagramas/) | Arquitectura, modelo de datos y flujo del ETL (Mermaid) |
| [Power BI](powerbi/README.md) | Diseño del tablero y guía paso a paso |
| [Prueba de carga](pruebas/carga/README.md) | Escenario de k6 y ejecución |

## Estructura

```
src/          API (ASP.NET Core 8): Censo.Api, Censo.Aplicacion, Censo.Dominio, Censo.Infraestructura
db/           Esquema de la base de datos y scripts de creación
etl/          Exportación con R y carga en T-SQL
pruebas/      Pruebas automáticas (xUnit) y prueba de carga (k6)
validacion/   Cuadros oficiales del INE para la prueba de exactitud
powerbi/      Consultas de Power Query y medidas DAX
despliegue/   Scripts de producción en Azure
docs/         Manuales y documentación técnica
```

## Origen

Desarrollado por **Mynor Hidalgo Letona** como proyecto de graduación de la Licenciatura en Ingeniería en Sistemas y Tecnologías de la Información y la Comunicación de la Universidad Panamericana de Guatemala (2026).

## Licencia

El código se distribuye bajo la [licencia MIT](LICENSE). Los microdatos y los cuadros estadísticos del Censo 2018 son del Instituto Nacional de Estadística (INE) de Guatemala; los cuadros incluidos en `validacion/` se usan únicamente como referencia de verificación. Los resultados del sistema no son una publicación oficial del INE.
