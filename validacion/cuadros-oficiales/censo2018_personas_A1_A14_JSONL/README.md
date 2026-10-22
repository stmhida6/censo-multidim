# Censo 2018 Guatemala — Personas A1–A14 en JSONL

## Contenido

- `A1_personas_censo2018.jsonl` ... `A14_personas_censo2018.jsonl`: un registro por unidad geográfica y cuadro.
- `censo2018_personas_A1_A14.jsonl`: consolidado de los 14 cuadros.
- `catalogo_A1_A14.json`: metadatos, universos, dimensiones, categorías, notas y conteos.
- `validaciones_geograficas_A1_A14.jsonl`: comprobaciones de agregación municipio → departamento → país.

## Estructura

Cada línea de datos es un objeto JSON autocontenido con:

- identificación del censo y del cuadro;
- título original del cuadro;
- universo estadístico;
- nivel geográfico;
- códigos y nombres de departamento/municipio;
- `datos`, con la estructura específica de cada cuadro;
- notas cuando aplican.

Hay 363 registros por cuadro:
- 1 total nacional;
- 22 departamentos;
- 340 municipios.

Total: 5082 registros.

## Guiones en los cuadros

Cuando el Excel original contiene `-` en una celda de conteo, el JSONL conserva la ruta de esa celda en
`valores_originales_con_guion` y normaliza el valor numérico a `0` para poder realizar las sumas de validación.

## Notas al pie

Las notas vinculadas a superíndices se conservan como metadatos. En A12 se preserva la nota 1:
`Se excluyen los casos con respuesta no declarada.`

## Validación geográfica

Se comprobaron las columnas/indicadores de los 14 cuadros con la regla:

1. suma de municipios = valor oficial del departamento;
2. suma de departamentos = valor oficial del país.

Resultado: todos los cuadros A1–A14 tienen 0 diferencias en las comprobaciones geográficas realizadas.

## Uso recomendado en RAG

Para recuperación semántica, conviene fragmentar por línea JSONL. Cada línea representa un cuadro y una geografía completa,
por lo que mantiene juntas todas las categorías del indicador para un municipio, departamento o el total nacional.
