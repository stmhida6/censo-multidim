#!/usr/bin/env bash
# Valida la base en Azure: conteos de los 4 hechos, prueba de exactitud contra los 25 cuadros oficiales (con el usuario
# de solo lectura, como la API), pruebas de permisos y la suite de la base de datos (sin la linea base de rendimiento,
# que se midio en local). Las pruebas leen la conexion de variables de entorno: no se cambia codigo.
source "$(dirname "$0")/configuracion.sh"

ETIQUETA="azure-$(date +%Y-%m-%d)"
# Una prueba fallida no debe detener las siguientes: se registran todas y se revisan al final.
set +e +o pipefail
mkdir -p datos/logs

paso "Conteos en Azure (esperado: 3943431 / 3275931 / 14901286 / 242203)"
sql_azure "$BD" -Q "SET NOCOUNT ON; SELECT
  (SELECT COUNT_BIG(*) FROM hechos.CensoVivienda) AS viviendas,
  (SELECT COUNT_BIG(*) FROM hechos.CensoHogar) AS hogares,
  (SELECT COUNT_BIG(*) FROM hechos.CensoPoblacion) AS personas,
  (SELECT COUNT_BIG(*) FROM hechos.CensoMigracion) AS emigrantes,
  (SELECT COUNT(*) FROM sys.tables WHERE SCHEMA_NAME(schema_id) = 'dim') AS dimensiones,
  (SELECT COUNT(*) FROM sys.foreign_keys) AS llaves_foraneas"

export CENSO_PRUEBAS_CONEXION="$CONEXION_ADMIN"
export CENSO_PRUEBAS_CONEXION_API="$CONEXION_API"
export CENSO_EXACTITUD_SALIDA="$RAIZ/datos/logs/exactitud-$ETIQUETA"

paso "Exactitud contra los 25 cuadros oficiales (usuario CensoApi)"
dotnet test pruebas/Censo.Pruebas.Integracion --filter "Categoria=Exactitud" 2>&1 | grep -E "Correctas!|Con error!|\[FAIL\]|difieren" | tee "datos/logs/pruebas-exactitud-$ETIQUETA.log"

paso "Permisos del usuario CensoApi"
dotnet test pruebas/Censo.Pruebas.Integracion --filter "Categoria=Seguridad" 2>&1 | grep -E "Correctas!|Con error!|\[FAIL\]|Assert|Mensaje" | tee "datos/logs/pruebas-seguridad-$ETIQUETA.log"

paso "Suite de la base de datos (sin Rendimiento)"
dotnet test pruebas/Censo.Pruebas.BaseDatos --filter "Categoria!=Rendimiento" 2>&1 | grep -E "Correctas!|Con error!|\[FAIL\]|Assert|Mensaje" | tee "datos/logs/pruebas-basedatos-$ETIQUETA.log"
