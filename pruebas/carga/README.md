# Prueba de carga con k6

Mide los tiempos de respuesta de la API ante diferentes cantidades de solicitudes simultáneas (tesis, objetivo específico 4). Usa [k6](https://k6.io) (Grafana Labs, código abierto, licencia AGPL-3.0) en su imagen oficial de Docker (`grafana/k6:2.3.0`): no hay que instalar nada, solo Docker.

k6 prueba la API **desde fuera**, como cualquier cliente (Power BI u otra aplicación), sin conocer su código: es una prueba de caja negra sobre `POST /api/consultas`.

## Archivos

| Archivo | Contenido |
|---|---|
| `consultas-censo.js` | Escenario de k6: mezcla de consultas, usuarios simultáneos, umbrales de aceptación y resumen por escalón |
| `ejecutar-carga.sh` | Ejecuta la serie de escalones (calentamiento y luego 1, 5, 10, 25 y 50 usuarios) y guarda los resultados |
| `resultados/<etiqueta>/usuarios-NNN.json` | Resumen de cada escalón: solicitudes, solicitudes por segundo, errores y tiempos (mediana, p90, p95, p99), en total y por tipo de consulta |
| `resultados/<etiqueta>/recursos.csv` | Uso de CPU y memoria de `censo-api` y `censo-sqlserver` cada 5 s (solo en local) |

## Diseño de la prueba

- **Usuarios virtuales (VU):** cada uno repite en bucle: elige una consulta de la mezcla, la envía, comprueba la respuesta y espera 1 s (tiempo de reflexión). Con 1 s de pausa, N usuarios virtuales se comportan como N analistas consultando sin parar.
- **Escalones:** cada cantidad de usuarios se mantiene constante durante 60 s (ejecutor `constant-vus`), con 20 s de descanso entre escalones. Antes hay un calentamiento de 20 s que no se registra.
- **Mezcla de consultas** (por peso): 30 % ligeras (un total o pocos grupos), 50 % medianas (por departamento, con filtros o indicadores) y 20 % pesadas (por municipio cruzado con otra dimensión, recorriendo los 14.9 millones de personas). El detalle está en `consultas-censo.js`.
- **Comprobaciones:** cada respuesta debe ser 200, traer filas y no estar truncada.
- **Umbrales de aceptación** (declarados antes de medir): menos de 1 % de errores, p95 del tiempo de respuesta menor a 5 s y más de 99 % de comprobaciones correctas.
- **Limitador de la API:** durante la prueba local, el script levanta la API con 1,000,000 solicitudes por minuto (variable `API_LIMITE_POR_MINUTO`) para medir el sistema y no el limitador, y al terminar la restaura con el valor normal (120).

## Ejecución local

Con Docker en marcha, la base cargada y el `.env` completo:

```bash
bash pruebas/carga/ejecutar-carga.sh
```

Variables opcionales: `ESCALONES="1 5 10 25 50"`, `DURACION=60s`, `PAUSA=1`, `DESCANSO=20`, `ETIQUETA=local-AAAA-MM-DD`.

## Ejecución contra otro despliegue (por ejemplo Azure)

El mismo escenario sirve para cualquier URL:

```bash
K6_BASE_URL=https://<api-desplegada> ETIQUETA=azure-AAAA-MM-DD bash pruebas/carga/ejecutar-carga.sh
```

Consideraciones para que los resultados sean comparables:

1. **Limitador:** el despliegue debe tener `LimiteSolicitudes__PorMinuto` alto durante la prueba (todas las solicitudes de k6 salen de una misma IP y compartirían el límite de 120 por minuto).
2. **Desde dónde se lanza k6:** desde la laptop, los tiempos incluyen la latencia de internet hasta Azure; para medir solo el sistema, lanzar k6 desde una máquina en la misma región (por ejemplo, Azure Container Instances con la misma imagen `grafana/k6`). Documentar cuál se usó.
3. **Recursos:** anotar el nivel de servicio de Azure SQL (DTU o vCores) y del App Service o contenedor de la API; los tiempos dependen de ellos.
4. **Misma mezcla y escalones:** no modificar `consultas-censo.js` entre la corrida local y la de Azure, para comparar lo mismo.

## Interpretación

- **Mediana y p95:** la mediana es la experiencia típica; el p95, la del 5 % más lento. Los umbrales se fijan sobre el p95.
- **Solicitudes por segundo:** si deja de crecer al agregar usuarios, el sistema llegó a su capacidad (saturación) y el tiempo extra es espera en cola.
- **`recursos.csv`:** muestra qué se satura (CPU de SQL Server, de la API o memoria).
- En local, la API, SQL Server (limitado a 2 CPU y 4 GB) y k6 comparten la misma laptop: los tiempos describen ese entorno y no un servidor dedicado.

Los resultados de cada corrida quedan en `pruebas/carga/resultados/<etiqueta>/` (no se versionan). Resultados de referencia: `docs/pruebas.md`.
