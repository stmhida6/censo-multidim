// Prueba de carga de la API de consultas del Censo 2018 (tesis, objetivo especifico 4).
//
// Cada usuario virtual (VU) repite: elegir una consulta de la mezcla, enviarla a POST /api/consultas, comprobar la
// respuesta y esperar un tiempo de reflexion. Los usuarios simultaneos y la duracion se pasan por variables de entorno,
// de modo que el mismo script sirve para cualquier escalon y para cualquier despliegue (local o Azure):
//
//   BASE_URL   URL de la API (por defecto http://api:8080, el contenedor de docker-compose)
//   USUARIOS   usuarios virtuales simultaneos (por defecto 1)
//   DURACION   duracion del escalon (por defecto 60s)
//   PAUSA      tiempo de reflexion entre consultas de un usuario, en segundos (por defecto 1)
//   ETIQUETA   carpeta de resultados dentro de resultados/ (por defecto "local")
//
// Ejecucion: bash pruebas/carga/ejecutar-carga.sh (ver README.md).

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Trend } from 'k6/metrics';

const BASE_URL = __ENV.BASE_URL || 'http://api:8080';
const USUARIOS = parseInt(__ENV.USUARIOS || '1', 10);
const DURACION = __ENV.DURACION || '60s';
const PAUSA = parseFloat(__ENV.PAUSA || '1');
const ETIQUETA = __ENV.ETIQUETA || 'local';

// ---------------------------------------------------------------- mezcla de consultas
// Tres tipos, con el peso con que aparecen en la mezcla. Son consultas que haria un analista o un tablero:
//  - ligera: un total o pocos grupos (decenas de filas)
//  - mediana: por departamento con filtros o indicadores (cientos de filas)
//  - pesada: por municipio cruzado con otra dimension (miles de filas, 14.9 millones de personas recorridas)
const CONSULTAS = [
  { tipo: 'ligera', peso: 15, nombre: 'Poblacion total', cuerpo: { medidas: ['personas'] } },
  { tipo: 'ligera', peso: 10, nombre: 'Viviendas por condicion', cuerpo: { medidas: ['viviendas'], dimensiones: ['condicionVivienda'] } },
  { tipo: 'ligera', peso: 5, nombre: 'Hogares por tipologia', cuerpo: { medidas: ['hogares'], dimensiones: ['tipoHogar'] } },

  { tipo: 'mediana', peso: 15, nombre: 'Personas por departamento y sexo', cuerpo: { medidas: ['personas'], dimensiones: ['departamento', 'sexo'] } },
  { tipo: 'mediana', peso: 15, nombre: 'Tasa de participacion de mujeres por departamento', cuerpo: {
    indicadores: ['tasaGlobalParticipacion'], dimensiones: ['departamento'],
    filtros: [{ nivel: 'sexo', operador: 'Igual', valores: [2] }] } },
  { tipo: 'mediana', peso: 10, nombre: 'Hogares por fuente de agua y area', cuerpo: { medidas: ['hogares'], dimensiones: ['departamento', 'fuenteAgua', 'esUrbano'] } },
  { tipo: 'mediana', peso: 10, nombre: 'Nivel educativo de 4 anios o mas en un departamento', cuerpo: {
    medidas: ['personas'], dimensiones: ['municipio', 'nivelEducativoCensal'],
    filtros: [{ nivel: 'departamento', operador: 'Igual', valores: [14] }, { nivel: 'edad', operador: 'MayorOIgual', valores: [4] }] } },

  { tipo: 'pesada', peso: 10, nombre: 'Personas por municipio y grupo quinquenal', cuerpo: { medidas: ['personas'], dimensiones: ['municipio', 'grupoQuinquenal'] } },
  { tipo: 'pesada', peso: 5, nombre: 'Pueblo de pertenencia por municipio', cuerpo: { medidas: ['personas', 'hombres', 'mujeres'], dimensiones: ['municipio', 'pueblo'] } },
  { tipo: 'pesada', peso: 5, nombre: 'Indicadores laborales por municipio', cuerpo: {
    indicadores: ['tasaGlobalParticipacion', 'tasaDesempleoAbierto'], dimensiones: ['municipio'] } },
];

const PESO_TOTAL = CONSULTAS.reduce((suma, c) => suma + c.peso, 0);

function elegirConsulta() {
  let r = Math.random() * PESO_TOTAL;
  for (const c of CONSULTAS) {
    r -= c.peso;
    if (r < 0) return c;
  }
  return CONSULTAS[CONSULTAS.length - 1];
}

// ---------------------------------------------------------------- metricas propias por tipo de consulta
const duracionPorTipo = {
  ligera: new Trend('duracion_ligera', true),
  mediana: new Trend('duracion_mediana', true),
  pesada: new Trend('duracion_pesada', true),
};
const duracionMotor = new Trend('duracion_motor_ms', true); // duracionMs que informa la propia API (tiempo en el servidor)
const respuestasPorEstado = new Counter('respuestas_por_estado');

export const options = {
  scenarios: {
    carga: { executor: 'constant-vus', vus: USUARIOS, duration: DURACION, gracefulStop: '120s' },
  },
  summaryTrendStats: ['avg', 'min', 'med', 'p(90)', 'p(95)', 'p(99)', 'max'],
  // Umbrales de aceptacion declarados antes de medir; un escalon que no los cumple queda marcado como fallido.
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<5000'],
    checks: ['rate>0.99'],
  },
};

export default function () {
  const consulta = elegirConsulta();
  const respuesta = http.post(`${BASE_URL}/api/consultas`, JSON.stringify(consulta.cuerpo), {
    headers: { 'Content-Type': 'application/json' },
    tags: { tipo: consulta.tipo, consulta: consulta.nombre },
    timeout: '120s',
  });

  respuestasPorEstado.add(1, { estado: String(respuesta.status) });
  duracionPorTipo[consulta.tipo].add(respuesta.timings.duration);

  const correcta = check(respuesta, {
    'estado 200': (r) => r.status === 200,
    'resultado con filas y sin truncar': (r) => {
      if (r.status !== 200) return false;
      const cuerpo = r.json();
      if (typeof cuerpo.duracionMs === 'number') duracionMotor.add(cuerpo.duracionMs);
      return Array.isArray(cuerpo.filas) && cuerpo.filas.length > 0 && cuerpo.truncado === false;
    },
  });
  if (!correcta && respuesta.status !== 200) {
    console.warn(`${consulta.nombre}: HTTP ${respuesta.status}`);
  }

  sleep(PAUSA);
}

// ---------------------------------------------------------------- resumen del escalon
export function handleSummary(datos) {
  const m = datos.metrics;
  const valor = (metrica, stat) => (m[metrica] && m[metrica].values[stat] !== undefined ? m[metrica].values[stat] : null);
  const tendencia = (metrica) => m[metrica] ? {
    promedio: valor(metrica, 'avg'), mediana: valor(metrica, 'med'), p90: valor(metrica, 'p(90)'),
    p95: valor(metrica, 'p(95)'), p99: valor(metrica, 'p(99)'), maximo: valor(metrica, 'max'), n: null,
  } : null;

  const resumen = {
    fecha: new Date().toISOString(),
    baseUrl: BASE_URL,
    usuarios: USUARIOS,
    duracion: DURACION,
    pausaSegundos: PAUSA,
    solicitudes: valor('http_reqs', 'count'),
    solicitudesPorSegundo: valor('http_reqs', 'rate'),
    tasaErrores: valor('http_req_failed', 'rate'),
    tasaChecks: valor('checks', 'rate'),
    tiempoRespuestaMs: tendencia('http_req_duration'),
    tiempoRespuestaPorTipoMs: {
      ligera: tendencia('duracion_ligera'), mediana: tendencia('duracion_mediana'), pesada: tendencia('duracion_pesada'),
    },
    tiempoMotorMs: tendencia('duracion_motor_ms'),
    umbralesCumplidos: Object.fromEntries(Object.entries(m)
      .filter(([, v]) => v.thresholds)
      .map(([k, v]) => [k, Object.values(v.thresholds).every((t) => t.ok)])),
  };

  const texto = `Escalon ${USUARIOS} usuarios (${DURACION}): ${resumen.solicitudes} solicitudes, ` +
    `${resumen.solicitudesPorSegundo.toFixed(2)}/s, mediana ${resumen.tiempoRespuestaMs.mediana.toFixed(0)} ms, ` +
    `p95 ${resumen.tiempoRespuestaMs.p95.toFixed(0)} ms, errores ${(resumen.tasaErrores * 100).toFixed(2)} %\n`;

  return {
    stdout: texto,
    [`resultados/${ETIQUETA}/usuarios-${String(USUARIOS).padStart(3, '0')}.json`]: JSON.stringify(resumen, null, 2),
  };
}
