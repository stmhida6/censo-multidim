# Diagramas de arquitectura

> Actualizado: 2026-09-26. Los diagramas usan [Mermaid](https://mermaid.js.org/) y se visualizan en GitHub, en la vista previa de Markdown de VS Code (con la extensión *Markdown Preview Mermaid Support*) y en Visual Studio. Fundamento teórico: capítulo II de la tesis, secciones 2.4 a 2.8.

## 1. Visión general del sistema

Los nodos verdes ya existen (la base de datos está cargada con los datos del censo); los grises con borde punteado están pendientes.

```mermaid
flowchart LR
    subgraph Fuentes["Fuentes del INE (fuera del repositorio)"]
        SAV["Microdatos .sav de SPSS<br/>4 archivos, 14.9 millones de personas"]
        DOC["Boleta censal<br/>y glosario"]
    end

    subgraph Analisis["Análisis y diseño (etl/)"]
        R["Scripts de R con haven<br/>etl/r"]
        DIC["Diccionario de variables<br/>etl/jsonl"]
        PLAN["plan-etl.md<br/>clasificacion-variables.md"]
    end

    subgraph Datos["SQL Server 2022 en Docker"]
        STAGE[("stage<br/>datos crudos")]
        DIM[("dim<br/>40 dimensiones")]
        HECHOS[("hechos<br/>4 tablas de hechos")]
    end

    subgraph Backend["ASP.NET Core 8"]
        INFRA["Censo.Infraestructura<br/>Dapper"]
        APP["Censo.Aplicacion<br/>catálogo y motor de consultas"]
        API["Censo.Api<br/>REST y JSON"]
    end

    PBI["Power BI"]

    SAV --> R
    DOC --> PLAN
    R --> DIC
    R --> PLAN
    PLAN --> DIM
    PLAN --> HECHOS
    SAV -- "R y BULK INSERT" --> STAGE
    STAGE --> DIM
    STAGE --> HECHOS
    DIM --- HECHOS
    HECHOS -.-> INFRA
    INFRA -.-> APP
    APP -.-> API
    API -.-> PBI
    HECHOS -. "conexión directa" .-> PBI

    classDef listo fill:#d9f2d9,stroke:#2e7d32,color:#111
    classDef pendiente fill:#eeeeee,stroke:#777,stroke-dasharray: 4 3,color:#333
    class SAV,DOC,R,DIC,PLAN,STAGE,DIM,HECHOS listo
    class INFRA,APP,API,PBI pendiente
```

## 2. Capas de la solución .NET

Las dependencias apuntan hacia el núcleo (`Censo.Dominio`), que no depende de ninguna otra capa (arquitectura por capas con inversión de dependencias, tesis 2.4.1 y 2.4.6).

```mermaid
flowchart TD
    API["Censo.Api<br/>Controllers, Swagger, configuración"]
    APP["Censo.Aplicacion<br/>catálogo de dimensiones y medidas,<br/>motor de consultas multidimensionales"]
    INF["Censo.Infraestructura<br/>acceso a datos con Dapper"]
    DOM["Censo.Dominio<br/>entidades y contratos"]

    API --> APP
    API --> INF
    APP --> DOM
    INF --> DOM

    classDef nucleo fill:#fff3cd,stroke:#b8860b,color:#111
    class DOM nucleo
```

Estado: implementadas. `Censo.Dominio` define los registros del catálogo, los modelos de consulta y los contratos (`ICatalogo`, `IRepositorioConsultas`); `Censo.Aplicacion` contiene el catálogo (`CatalogoCenso`), el validador, el constructor de SQL y el servicio de consultas; `Censo.Infraestructura` implementa el repositorio con Dapper; `Censo.Api` expone los controladores y compone las dependencias.

## 3. Despliegue local con Docker Compose

```mermaid
flowchart LR
    DEV["Equipo de desarrollo<br/>Windows 11, 16 GB"]

    subgraph Compose["docker compose, red censo-net"]
        SQL["censo-sqlserver<br/>SQL Server 2022 Developer<br/>límite 4 GB, volumen censo_sqlserver_data<br/>datos/ montada como /datos (solo lectura)"]
        APIC["censo-api<br/>ASP.NET Core 8<br/>usuario no root"]
        K6["k6 (perfil pruebas)<br/>grafana/k6, prueba de carga"]
    end

    DEV -- "puerto 1433" --> SQL
    DEV -- "puerto 5000" --> APIC
    APIC -- "espera a que SQL esté healthy" --> SQL
    K6 -. "POST /api/consultas" .-> APIC
```

El servicio `k6` solo arranca con `docker compose --profile pruebas` (lo hace `pruebas/carga/ejecutar-carga.sh`); con `K6_BASE_URL` apunta a otro despliegue, por ejemplo Azure.

El destino previsto en la nube es Azure App Service para la API y Azure SQL Database para los datos (tesis 2.8.5).

## 4. Flujo de una consulta dinámica

Cuatro etapas de la tesis (2.4.5): recibir la solicitud, validarla contra el catálogo, construir la instrucción solo con elementos reconocidos y ejecutarla con parámetros. Implementado en `ServicioConsultas` (validación y construcción) y `RepositorioConsultasSql` (ejecución); los errores de la base de datos devuelven 500 o 504 con un mensaje genérico, sin detalles internos.

```mermaid
sequenceDiagram
    participant C as Cliente (Power BI u otro)
    participant A as Censo.Api
    participant P as Censo.Aplicacion
    participant I as Censo.Infraestructura
    participant B as SQL Server

    C->>A: solicitud con indicador, dimensiones y filtros
    A->>P: solicitud con estructura válida
    P->>P: comprobar cada elemento contra el catálogo
    alt algún elemento no está en el catálogo
        P-->>A: error de validación
        A-->>C: 400 sin detalles internos
    else todos los elementos son reconocidos
        P->>P: construir el SQL solo con elementos del catálogo, filtros como parámetros
        P->>I: consulta y parámetros
        I->>B: SQL parametrizado con Dapper
        B-->>I: resultados agregados
        I-->>P: filas
        P-->>A: resultado
        A-->>C: 200 con JSON
    end
```
