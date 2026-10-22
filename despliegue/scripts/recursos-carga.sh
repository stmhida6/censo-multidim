#!/usr/bin/env bash
# Guarda el uso de recursos de Azure durante la prueba de carga; es el equivalente de docker stats en local.
# Ejecutar INMEDIATAMENTE despues de la serie de k6: sys.dm_db_resource_stats conserva solo la ultima hora.
#   - recursos-sql.csv: CPU, memoria y E/S de la base cada 15 s (porcentaje del limite de 2 vCore)
#   - recursos-api.csv: CPU y memoria del plan de App Service por minuto (metricas de Azure Monitor)
# Uso: bash despliegue/scripts/recursos-carga.sh <etiqueta> [solo-api]   (la misma ETIQUETA de ejecutar-carga.sh)
#      solo-api: no consulta la base (por ejemplo, si el firewall ya se cerro); las metricas de Azure Monitor duran 93 dias
source "$(dirname "$0")/configuracion.sh"

ETIQUETA="${1:?Indique la etiqueta de la prueba, por ejemplo azure-2vcore-2026-10-14}"
SALIDA="pruebas/carga/resultados/$ETIQUETA"
mkdir -p "$SALIDA"

if [ "${2:-}" != "solo-api" ]; then
paso "Recursos de la base (sys.dm_db_resource_stats, cada 15 s, hora UTC)"
sql_azure "$BD" -s "," -h -1 -Q "SET NOCOUNT ON;
  SELECT CONVERT(varchar(19), end_time, 120), avg_cpu_percent, avg_memory_usage_percent, avg_data_io_percent, avg_log_write_percent
  FROM sys.dm_db_resource_stats ORDER BY end_time;" \
  | tr -d '\r' | sed '/^$/d' > "$SALIDA/recursos-sql.tmp"
{ echo "fin_utc,cpu,memoria,io_datos,escritura_log"; cat "$SALIDA/recursos-sql.tmp"; } > "$SALIDA/recursos-sql.csv"
rm -f "$SALIDA/recursos-sql.tmp"
echo "$(( $(wc -l < "$SALIDA/recursos-sql.csv") - 1 )) muestras en $SALIDA/recursos-sql.csv"
fi

paso "CPU y memoria del plan de App Service (por minuto, ultima hora, hora UTC)"
ID_PLAN="$(az appservice plan show -g "$RG" -n "$PLAN" --query id -o tsv | tr -d '\r')"
INICIO="$(date -u -d '-70 minutes' +%Y-%m-%dT%H:%M:%SZ)"   # sin --end-time, Azure toma solo 1 hora desde el inicio
MSYS_NO_PATHCONV=1 az monitor metrics list --resource "$ID_PLAN" --metric CpuPercentage MemoryPercentage \
  --interval PT1M --start-time "$INICIO" --end-time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --aggregation Average Maximum \
  --query "value[].{m:name.value, d:timeseries[0].data[].[timeStamp, average, maximum]}" -o json > "$SALIDA/recursos-api.json"
python - "$SALIDA/recursos-api.json" "$SALIDA/recursos-api.csv" <<'EOF'
import json, sys
datos = json.load(open(sys.argv[1]))
filas = {}
for serie in datos:
    for t, prom, maxi in serie["d"]:
        filas.setdefault(t[:19].replace("T", " "), {})[serie["m"]] = (prom, maxi)
with open(sys.argv[2], "w") as f:
    f.write("minuto_utc,cpu_promedio,cpu_maximo,memoria_promedio\n")
    for t in sorted(filas):
        cpu = filas[t].get("CpuPercentage", (None, None)); mem = filas[t].get("MemoryPercentage", (None, None))
        if cpu[0] is None:
            continue
        f.write(f"{t},{cpu[0]:.1f},{cpu[1]:.1f},{'' if mem[0] is None else round(mem[0], 1)}\n")
EOF
rm -f "$SALIDA/recursos-api.json"
echo "$(( $(wc -l < "$SALIDA/recursos-api.csv") - 1 )) minutos en $SALIDA/recursos-api.csv"
