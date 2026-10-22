# Censo 2018 Guatemala — Cuadros de vivienda C1–C3 en JSONL

## Propósito

Este paquete transforma los cuadros oficiales C1–C3 del XII Censo Nacional de Población y VII de Vivienda 2018 del INE de Guatemala a JSONL para facilitar su uso en RAG, prompts, búsquedas semánticas y validación de resultados oficiales.

## Archivos

- `C1.jsonl`: tipo de vivienda censada y condición de ocupación.
- `C2.jsonl`: material predominante en paredes exteriores y techo.
- `C3.jsonl`: material predominante en el piso.
- `censo2018_viviendas_C1_C3.jsonl`: consolidado.
- `catalogo_cuadros.json`: metadatos, universos, columnas y notas.
- `validaciones.jsonl`: validaciones geográficas e internas.

Cada archivo individual inicia con un registro `metadata` y continúa con registros `dato`.

## Cobertura geográfica

Cada cuadro contiene:
- 1 registro nacional (Guatemala)
- 22 departamentos
- 340 municipios

Cada cuadro contiene 363 registros de datos.

## Notas al pie

Se conservaron las notas que modifican la interpretación de columnas:

- **C1, nota 1:** Incluye viviendas particulares y colectivas. En el Excel original aparece como “Inclyue viviendas particulares y colectivas”.
- **C3, nota 1:** Viviendas particulares ocupadas. Por ello el universo de C3 se registró como `Viviendas particulares ocupadas`.

La referencia de nota queda asociada a la columna correspondiente en `catalogo_cuadros.json`.

## Guiones

Cuando el Excel contiene `-`, JSONL utiliza `0` para permitir agregaciones y validaciones. El registro conserva `celdas_originalmente_guion` con las claves que originalmente contenían guion.

## Validaciones

Se comprobó para cada indicador numérico:

1. Suma de municipios = valor oficial del departamento.
2. Suma de 22 departamentos = valor oficial nacional.

También se verificaron relaciones internas cuando son aditivas:

- C1: tipos de vivienda particular; vivienda particular + colectiva; condición de ocupación.
- C2: materiales de paredes y materiales de techo.
- C3: materiales de piso.

Resultado:
- Validaciones OK: **3167**
- Validaciones para revisar: **0**

## Recomendación para RAG

Indexe principalmente los registros `dato` del consolidado y mantenga `catalogo_cuadros.json` como contexto metodológico. Para recuperar cifras oficiales conviene filtrar por:

- `cuadro`
- `nivel_geografico`
- `codigo_departamento`
- `codigo_municipio`
- `universo`
- indicador y categoría

Los Excel originales del INE siguen siendo la fuente oficial; estos JSONL son una representación estructurada para consulta y validación.
