# Empaqueta la API publicada en un .zip con rutas de estilo Linux ("/").
# Compress-Archive de Windows PowerShell 5.1 guarda las rutas con "\", que App Service (Linux) no reconoce como carpetas.
# Uso: python empaquetar.py <carpeta_publicada> <archivo.zip>
import os
import sys
import zipfile

origen, destino = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(destino, "w", zipfile.ZIP_DEFLATED) as zip_:
    for raiz, _, archivos in os.walk(origen):
        for archivo in archivos:
            ruta = os.path.join(raiz, archivo)
            zip_.write(ruta, os.path.relpath(ruta, origen).replace(os.sep, "/"))
print(f"{destino}: {len(zip_.namelist())} archivos")
