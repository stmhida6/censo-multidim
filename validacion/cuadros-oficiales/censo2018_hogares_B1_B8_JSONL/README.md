# Censo 2018 Guatemala — Cuadros de hogares B1–B8 en JSONL

## Propósito

Este paquete transforma los cuadros oficiales B1–B8 del XII Censo Nacional de Población y VII de Vivienda 2018 del INE de Guatemala a JSONL para facilitar su uso en RAG, prompts, búsquedas semánticas y validación de resultados.

## Estructura

- `B1.jsonl` … `B8.jsonl`: un archivo por cuadro.
- `censo2018_hogares_B1_B8.jsonl`: consolidado de los ocho cuadros.
- `catalogo_cuadros.json`: metadatos, títulos, columnas, grupos y notas al pie.
- `validaciones.jsonl`: comprobaciones municipio → departamento y departamento → país.

Cada archivo individual inicia con un registro `metadata` y continúa con registros `dato`.

## Unidad geográfica

Cada cuadro contiene:

- 1 registro de país: Guatemala.
- 22 registros departamentales.
- 340 registros municipales.

Por tanto, cada cuadro contiene 363 registros de datos.

## Estructura de un registro

```json
{
  "tipo_registro": "dato",
  "cuadro": "B2",
  "tema": "hogares",
  "nivel_geografico": "municipio",
  "codigo_departamento": "02",
  "departamento": "El Progreso",
  "codigo_municipio": "0201",
  "municipio": "Guastatoya",
  "universo": "Hogares censados",
  "unidad": "hogares",
  "indicadores": {
    "total_de_hogares_censados": 6619,
    "fuente_principal_de_agua_para_consumo": {
      "tuberia_en_la_vivienda": 5000
    }
  }
}
```

Los indicadores se conservan agrupados según los encabezados originales del Excel. Esto evita confundir categorías con el mismo nombre que pertenecen a temas diferentes.

## Guiones en los cuadros

Cuando una celda original contiene `-`, el JSONL usa el valor numérico `0` para que las sumas puedan validarse. El registro conserva además la propiedad `celdas_originalmente_guion` con las claves afectadas.

## Notas al pie y superíndices

Las notas encontradas al final de los cuadros se conservan en el registro `metadata`, dentro de `notas`.

Las columnas conservan:
- etiqueta original;
- grupo original;
- categoría original;
- referencias de nota detectadas.

En B8 las notas de la tipología de hogar se vinculan semánticamente con:
1. Unipersonal
2. Nuclear
3. Extendido/Extensa
4. Compuesto/Compuesta
5. Co-residentes

Esto permite que un RAG recupere no solo la cifra, sino también la definición asociada.

## Validaciones realizadas

Para cada indicador numérico de los cuadros B1–B8 se comprobó:

1. La suma de los municipios de cada departamento coincide con el valor oficial departamental.
2. La suma de los 22 departamentos coincide con el valor oficial nacional.

Resultado: **0 diferencias en los ocho cuadros**.

Estas comprobaciones son geográficas. No se presupone que todos los grupos internos deban sumar el total del cuadro, porque algunos indicadores representan subconjuntos o conceptos distintos.

## Recomendación para RAG

Para recuperación semántica conviene indexar los registros `dato` y conservar `catalogo_cuadros.json` como contexto metodológico. Una consulta debería filtrar, cuando sea posible, por:

- `cuadro`
- `nivel_geografico`
- `codigo_departamento`
- `codigo_municipio`
- `universo`
- nombre del indicador

La fuente original debe seguir considerándose el Excel oficial del INE; estos JSONL son una representación estructurada para consulta.
