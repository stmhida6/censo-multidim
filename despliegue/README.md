# Despliegue en producción (Azure)

Scripts para publicar el sistema en Azure SQL Database y Azure App Service a partir de una instalación local ya cargada y verificada. La guía completa, con requisitos, dimensionamiento, costos y solución de problemas, está en la sección 8 del [manual técnico](../docs/manual-tecnico.md#8-puesta-en-producción-en-azure).

Requisitos: Azure CLI con sesión iniciada (`az login --use-device-code`), SqlPackage, .NET SDK 8, Python 3 y el contenedor local `censo-sqlserver` en marcha (los scripts usan su `sqlcmd`). Las variables `AZURE_*` se configuran en `.env`; los scripts generan y guardan ahí el nombre del servidor, la aplicación y las claves.

| Paso | Script | Qué hace |
|---|---|---|
| 1 | `01-presupuesto.sh <correo>` | Alerta de presupuesto mensual (USD 30) |
| 2 | `02-crear-servidor.sh` | Grupo de recursos, servidor SQL y firewall |
| 3 | `03-crear-base.sh` | Base con la oferta gratuita (serverless 2 vCore, 10 GB) |
| 4 | `04-exportar-bacpac.sh` | Exporta la base local a `datos/CensoGT2018.bacpac` |
| 5 | `05-importar-datos.sh` | Importa el BACPAC en Azure (unos 55 min) |
| 6 | `06-crear-usuario-api.sh` | Usuario contenido `CensoApi` de solo lectura |
| 7 | `07-validar-datos.sh` | Conteos, exactitud, permisos y suite de la base contra Azure |
| 8 | `08-publicar-api.sh [F1\|B1\|B2]` | Plan de App Service, aplicación y publicación de la API |

| Operación | Script |
|---|---|
| Estado, cupo gratuito y costo | `estado.sh` |
| Poner en servicio / dejar sin consumo | `reanudar.sh` / `pausar-todo.sh` |
| Cambiar el plan de la API | `escalar-api.sh F1\|B1\|B2` |
| Despertar la base antes de usarla | `despertar-base.sh` |
| CPU de la base y de la API tras una prueba de carga | `recursos-carga.sh <etiqueta>` |
| Comparar el despliegue con la API local | `python pruebas-consumo.py <url-api> [url-local]` |
| Eliminar todo | `eliminar-todo.sh --confirmar` |
