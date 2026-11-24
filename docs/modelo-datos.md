# Modelo de datos del tablero

El tablero comparte una base SQLite local con aprendizaje y simulador.
[El esquema](../godot/logica/datos/esquema.gd) crea las siete tablas en una
transacción. [La capa de acceso](../godot/logica/datos/acceso_sqlite.gd)
abre una conexión por consulta, activa las claves foráneas y admite parámetros
enlazados mediante `?`.

| Tabla | Campos y restricciones |
|---|---|
| `tecnico` | `id` entero, clave primaria. `alias` texto único y no vacío. `demo` entero booleano (`0` o `1`, por defecto `0`). `creado` texto con fecha y hora UTC, por defecto al insertar. |
| `intento` | `id` entero, clave primaria. `tecnico` entero, clave foránea. `competencia`, `item`, `formato`, `dificultad`, `respuesta`, `resultado`, `tipo_error`, `fuente_entrada`, `momento`, `reloj_sim` y `version_contenido` son texto. `tipo_error` admite `NULL`. `valor` es real de 0 a 100, `peso` es real positivo y `tiempo_ms` es entero no negativo. `momento` admite `pre`, `post`, `retest` o `practica`. |
| `evento` | `id` entero, clave primaria. `tecnico` entero, clave foránea. `escenario`, `accion`, `estado_antes`, `estado_despues`, `criticidad`, `fuente_entrada` y `reloj_sim` son texto. |
| `brecha` | `id` entero, clave primaria. `tecnico` entero, clave foránea. `competencia`, `caso`, `causa_marcada`, `accion_ejecutada` y `reloj_sim` son texto. |
| `leitner` | `tecnico` entero, clave foránea. `item` texto. La clave primaria combina `tecnico` e `item`. `caja` es entero de 1 a 3 y `proxima_fecha_sim` es texto. |
| `progreso` | `tecnico` entero, clave primaria y foránea. `paso_actual` texto. `ruta` texto con JSON válido, por defecto `[]`. `microlecciones_hechas` entero no negativo, por defecto `0`. |
| `reloj` | `tecnico` entero, clave primaria y foránea. `desplazamiento_dias` entero no negativo, por defecto `0`. |

Cada `tecnico` referencia a `tecnico.id` con borrado en cascada. Los
identificadores de competencia, ítem y caso remiten al contenido JSON.
Los intentos conservan su versión de contenido. El dominio, el nivel y
los errores recurrentes se calculan al consultar el historial de `intento`.
La identificación de los técnicos se limita al alias o ID.

## Creación y respaldo

- `crear(ruta)` abre la base o la crea si falta. Las tablas existentes y sus filas se conservan al volver a ejecutar el esquema.
- `respaldar(base, respaldo)` crea una instantánea SQLite. El flujo debe llamarla al cerrar cada paso, después de guardar sus cambios.
- `restaurar(base, respaldo)` repone la base desde la instantánea y conserva el archivo de respaldo.

En la aplicación, usa rutas escribibles en `user://` y mantén el destino
cerrado durante el respaldo o la restauración. La copia se construye en un
archivo temporal junto al destino y se publica al terminar. Los tres métodos
devuelven `true` al completar la operación y `false` si falla.

[La prueba del esquema](../godot/tests/test_esquema.gd) crea una base
vacía, comprueba las siete tablas y restaura una copia después de modificar
la base original.
