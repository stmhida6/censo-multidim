#!/usr/bin/env bash
# Prueba de carga por escalones con k6 en contenedor (tesis, objetivo especifico 4).
#
# Uso (desde la raiz del repositorio, con Docker en marcha y la base cargada):
#   bash pruebas/carga/ejecutar-carga.sh                       # escalones 1 5 10 25 50, 60 s cada uno, contra la API local
#   ESCALONES="1 10 50 100" DURACION=120s bash pruebas/carga/ejecutar-carga.sh
#   K6_BASE_URL=https://<api-en-azure> ETIQUETA=azure bash pruebas/carga/ejecutar-carga.sh   # otro despliegue
#
# Resultados en pruebas/carga/resultados/<ETIQUETA>/: un JSON por escalon (usuarios-NNN.json) y, en local, el uso de
# CPU y memoria de los contenedores muestreado cada 5 s (recursos.csv).

set -euo pipefail
cd "$(dirname "$0")/../.."

ESCALONES="${ESCALONES:-1 5 10 25 50}"
DURACION="${DURACION:-60s}"
PAUSA="${PAUSA:-1}"
ETIQUETA="${ETIQUETA:-local-$(date +%Y-%m-%d)}"
DESCANSO="${DESCANSO:-20}"            # segundos entre escalones para que la base se estabilice
LOCAL=0; [ -z "${K6_BASE_URL:-}" ] && LOCAL=1

SALIDA="pruebas/carga/resultados/$ETIQUETA"
mkdir -p "$SALIDA" pruebas/carga/resultados/calentamiento

k6() {  # ejecuta k6 en su contenedor; un escalon que no cumple los umbrales no detiene la serie
  docker compose --profile pruebas run --rm -e USUARIOS="$1" -e DURACION="$2" -e PAUSA="$PAUSA" -e ETIQUETA="$3" \
    ${K6_BASE_URL:+-e BASE_URL="$K6_BASE_URL"} k6 run --quiet consultas-censo.js || echo "  (el escalon de $1 usuarios no cumplio algun umbral)"
}

if [ "$LOCAL" = 1 ]; then
  echo "== API local con el limitador en 1,000,000 solicitudes por minuto (se restaura al terminar)"
  API_LIMITE_POR_MINUTO=1000000 docker compose up -d api >/dev/null
  trap 'echo "== Restaurando el limite normal de la API"; docker compose up -d api >/dev/null' EXIT
  until curl -sf http://localhost:"${API_HTTP_PORT:-5000}"/salud >/dev/null; do sleep 2; done

  echo "tiempo,contenedor,cpu,memoria" > "$SALIDA/recursos.csv"
  ( while true; do
      docker stats --no-stream --format "{{.Name}},{{.CPUPerc}},{{.MemUsage}}" censo-api censo-sqlserver 2>/dev/null \
        | sed "s/^/$(date +%H:%M:%S),/" >> "$SALIDA/recursos.csv"
      sleep 5
    done ) &
  MUESTREO=$!
  trap 'kill $MUESTREO 2>/dev/null; echo "== Restaurando el limite normal de la API"; docker compose up -d api >/dev/null' EXIT
fi

echo "== Calentamiento (1 usuario, 20 s; no se registra en los resultados)"
k6 1 20s calentamiento

for u in $ESCALONES; do
  echo "== Escalon: $u usuarios simultaneos durante $DURACION ($(date +%H:%M:%S))"
  echo "$(date +%H:%M:%S),escalon,$u usuarios," >> "$SALIDA/recursos.csv" 2>/dev/null || true
  k6 "$u" "$DURACION" "$ETIQUETA"
  sleep "$DESCANSO"
done

echo "== Resultados en $SALIDA"
