# Pruebas de consumo de la API publicada en Azure, comparadas con la API local.
#   1. Catalogo: los 5 servicios GET responden 200 con el mismo contenido que en local.
#   2. Resultados: los cuadros de ejemplo del manual de usuario dan las mismas filas en Azure y en local.
#   3. Validacion y seguridad: solicitudes invalidas, inyeccion, cuerpo de mas de 64 KB y Swagger desactivado.
#   4. Latencia: tiempo de respuesta por tipo de consulta (ligera, mediana, pesada) con 1 usuario, local frente a Azure.
#   5. Limite de solicitudes: 130 solicitudes seguidas; con el limite de 120 por minuto, las sobrantes reciben 429.
#      Bloquea al equipo durante un minuto (el limite es por IP): no ejecutar mientras Power BI actualiza.
# Uso: python despliegue/scripts/pruebas-consumo.py <url-azure> [url-local] [--solo-limite]
# Escribe un resumen JSON en datos/logs/consumo-azure-<fecha>.json y muestra el detalle en la consola.
import json
import statistics
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime

from concurrent.futures import ThreadPoolExecutor

ARGS = [a for a in sys.argv[1:] if not a.startswith("--")]
SOLO_LIMITE = "--solo-limite" in sys.argv
if not ARGS:
    sys.exit("Indique la URL de la API publicada, por ejemplo https://<aplicacion>.azurewebsites.net")
AZURE = ARGS[0].rstrip("/")
LOCAL = (ARGS[1] if len(ARGS) > 1 else "http://localhost:5000").rstrip("/")


def pedir(base, ruta, cuerpo=None, crudo=None):
    datos = crudo if crudo is not None else (json.dumps(cuerpo).encode() if cuerpo is not None else None)
    solicitud = urllib.request.Request(base + ruta, data=datos, headers={"Content-Type": "application/json"} if datos else {})
    inicio = time.perf_counter()
    try:
        with urllib.request.urlopen(solicitud, timeout=120) as r:
            texto = r.read()
            codigo = r.status
    except urllib.error.HTTPError as e:
        texto, codigo = e.read(), e.code
    except Exception as e:  # conexion cerrada (por ejemplo, al rechazar un cuerpo grande)
        return 0, str(e), (time.perf_counter() - inicio) * 1000
    segundos = (time.perf_counter() - inicio) * 1000
    try:
        return codigo, json.loads(texto), segundos
    except ValueError:
        return codigo, texto.decode(errors="replace")[:200], segundos


resumen = {"fecha": datetime.now().isoformat(timespec="seconds"), "azure": AZURE, "local": LOCAL}
correctas = total = 0


def verificar(nombre, ok, detalle=""):
    global correctas, total
    total += 1
    correctas += ok
    print(f"  [{'OK' if ok else 'FALLA'}] {nombre}{(' - ' + detalle) if detalle else ''}")
    return ok


print(f"== Pruebas de consumo de la API en Azure ({resumen['fecha']})\n   Azure: {AZURE}\n   Local: {LOCAL}")

if not SOLO_LIMITE:
    print("\n== 1. Catalogo: mismo contenido que en local")
    for ruta in ["/api/catalogo/hechos", "/api/catalogo/dimensiones", "/api/catalogo/medidas",
                 "/api/catalogo/indicadores", "/api/catalogo/operadores"]:
        ca, da, _ = pedir(AZURE, ruta)
        cl, dl, _ = pedir(LOCAL, ruta)
        verificar(f"GET {ruta}", ca == 200 and da == dl, f"HTTP {ca}, {len(da) if isinstance(da, list) else '?'} elementos")

    print("\n== 2. Resultados: mismas filas en Azure y en local")
    CUADROS = {
        "Poblacion por departamento y sexo": {"medidas": ["personas"], "dimensiones": ["departamento", "sexo"]},
        "Piramide de Coban": {"medidas": ["personas"], "dimensiones": ["grupoQuinquenal", "sexo"],
                              "filtros": [{"nivel": "municipio", "operador": "Igual", "valores": [1601]}]},
        "Alfabetismo por pueblo y sexo en Quiche": {"indicadores": ["tasaAlfabetismo"], "dimensiones": ["pueblo", "sexo"],
                                                    "filtros": [{"nivel": "departamento", "operador": "Igual", "valores": [14]}]},
        "Indicadores laborales de mujeres por departamento": {
            "indicadores": ["tasaGlobalParticipacion", "tasaDesempleoAbierto"], "dimensiones": ["departamento"],
            "filtros": [{"nivel": "sexo", "operador": "Igual", "valores": [2]}]},
        "Internet, remesas y tamanio del hogar por area": {
            "indicadores": ["porcentajeHogaresConInternet", "porcentajeHogaresConRemesas", "tamanioPromedioHogar"],
            "dimensiones": ["esUrbano"]},
        "Paredes de las viviendas en Alta Verapaz": {"medidas": ["viviendas"], "dimensiones": ["materialPared"],
                                                     "filtros": [{"nivel": "departamento", "operador": "Igual", "valores": [16]}]},
        "Emigrantes por grupo de edad y sexo": {"medidas": ["emigrantes"], "dimensiones": ["grupoAmplio", "sexo"]},
        "Uso de internet de 15 a 29 anios": {"medidas": ["personas"], "dimensiones": ["usoInternet"],
                                             "filtros": [{"nivel": "edad", "operador": "Entre", "valores": [15, 29]}]},
        "Indicadores nacionales": {"indicadores": ["indiceMasculinidad", "relacionDependencia", "tasaAlfabetismo"]},
    }
    resumen["cuadros"] = []
    for nombre, cuerpo in CUADROS.items():
        ca, da, ta = pedir(AZURE, "/api/consultas", cuerpo)
        cl, dl, tl = pedir(LOCAL, "/api/consultas", cuerpo)
        iguales = ca == 200 and cl == 200 and da["filas"] == dl["filas"]
        filas = len(da["filas"]) if ca == 200 else 0
        verificar(nombre, iguales, f"{filas} filas; Azure {ta:,.0f} ms, local {tl:,.0f} ms")
        resumen["cuadros"].append({"cuadro": nombre, "filas": filas, "iguales": iguales,
                                   "msAzure": round(ta), "msLocal": round(tl)})

    print("\n== 3. Validacion y seguridad en Azure")
    CASOS = [
        ("Indicador inexistente", {"indicadores": ["indicadorInventado"]}, 400, "no existe en el catalogo"),
        ("Medidas de hechos distintos", {"medidas": ["personas", "hogares"]}, 400, "mismo hecho"),
        ("Nivel no disponible para el hecho", {"medidas": ["hogares"], "dimensiones": ["pueblo"]}, 400, "no esta disponible"),
        ("Operador invalido", {"medidas": ["personas"], "filtros": [{"nivel": "sexo", "operador": "Parecido", "valores": [1]}]}, 400, "no es valido"),
        ("Limite fuera de rango", {"medidas": ["personas"], "limite": 0}, 400, "limite"),
        ("Inyeccion en el nombre de un nivel", {"medidas": ["personas"], "dimensiones": ["sexo]; DROP TABLE dim.Sexo; --"]}, 400, "no existe"),
    ]
    for nombre, cuerpo, esperado, texto in CASOS:
        c, d, _ = pedir(AZURE, "/api/consultas", cuerpo)
        mensaje = json.dumps(d, ensure_ascii=False)
        verificar(nombre, c == esperado and texto in mensaje, f"HTTP {c}")
    c, d, _ = pedir(AZURE, "/api/consultas", {"medidas": ["personas"], "filtros": [
        {"nivel": "grupoAmplio", "operador": "Igual", "valores": ["0-14' OR '1'='1"]}]})
    personas = d["filas"][0].get("personas") if c == 200 and d["filas"] else None
    verificar("Inyeccion como valor de filtro (se trata como dato)", c == 200 and not personas, f"HTTP {c}, personas = {personas}")
    c, d, _ = pedir(AZURE, "/api/consultas", crudo=json.dumps({"medidas": ["personas"], "x": "a" * 70_000}).encode())
    verificar("Cuerpo de 70 KB rechazado sin procesar", c in (413, 502, 0), f"HTTP {c}")
    c, d, _ = pedir(AZURE, "/swagger/index.html")
    verificar("Swagger desactivado en produccion", c == 404, f"HTTP {c}")
    c, d, _ = pedir(AZURE, "/api/consultas", crudo=b"{esto no es json")
    verificar("JSON mal formado", c == 400, f"HTTP {c}")

    print("\n== 4. Latencia con 1 usuario (5 repeticiones, mediana)")
    TIPOS = {
        "ligera": {"medidas": ["personas"]},
        "mediana": {"medidas": ["personas"], "dimensiones": ["departamento", "sexo"]},
        "pesada": {"medidas": ["personas"], "dimensiones": ["municipio", "grupoQuinquenal"]},
    }
    resumen["latencia"] = {}
    for tipo, cuerpo in TIPOS.items():
        fila = {}
        for entorno, base in (("local", LOCAL), ("azure", AZURE)):
            totales, servidor = [], []
            for _ in range(5):
                c, d, t = pedir(base, "/api/consultas", cuerpo)
                if c == 200:
                    totales.append(t)
                    servidor.append(d["duracionMs"])
            fila[entorno] = {"totalMs": round(statistics.median(totales)), "servidorMs": round(statistics.median(servidor))}
        fila["redMs"] = fila["azure"]["totalMs"] - fila["azure"]["servidorMs"]
        resumen["latencia"][tipo] = fila
        print(f"  {tipo:8} local {fila['local']['totalMs']:>6,} ms (servidor {fila['local']['servidorMs']:>6,})"
              f" | Azure {fila['azure']['totalMs']:>6,} ms (servidor {fila['azure']['servidorMs']:>6,}; red y HTTPS {fila['redMs']:,} ms)")

print("\n== 5. Limite de solicitudes (120 por minuto por cliente)")
print("   Espera de 65 s para empezar con la ventana de un minuto vacia...")
time.sleep(65)
# En paralelo (13 a la vez) para que las 130 lleguen dentro de la misma ventana de un minuto: una tras otra tardan
# mas de 60 s por la latencia de red y la ventana se reinicia a mitad de la prueba.
inicio = time.perf_counter()
with ThreadPoolExecutor(max_workers=13) as hilos:
    codigos = list(hilos.map(lambda _: pedir(AZURE, "/api/consultas", {"medidas": ["personas"]})[0], range(130)))
duracion = time.perf_counter() - inicio
aceptadas, rechazadas = codigos.count(200), codigos.count(429)
resumen["limite"] = {"enviadas": 130, "aceptadas": aceptadas, "rechazadas429": rechazadas,
                     "otras": 130 - aceptadas - rechazadas, "segundos": round(duracion, 1)}
verificar("130 solicitudes en un minuto", aceptadas == 120 and rechazadas == 10,
          f"{aceptadas} aceptadas, {rechazadas} con 429, en {duracion:.0f} s")

resumen["verificaciones"] = {"correctas": correctas, "total": total}
print(f"\n== Resultado: {correctas} de {total} verificaciones correctas")
salida = f"datos/logs/consumo-azure-{datetime.now():%Y-%m-%d}{'-limite' if SOLO_LIMITE else ''}.json"
with open(salida, "w", encoding="utf-8") as f:
    json.dump(resumen, f, ensure_ascii=False, indent=1)
print(f"   Resumen: {salida}")
