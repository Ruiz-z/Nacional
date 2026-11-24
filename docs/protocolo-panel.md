# Protocolo del panel, versión 1

El panel físico y el virtual usan una línea JSON UTF-8 por mensaje, terminada en salto de línea. La conexión física prevista es USB serial a 115200 baudios. Si la prueba de humo descarta el plugin serial, el puente Python reenviará las líneas por UDP local. Cualquier cambio al contrato requiere actualizar primero `SPEC-panel.md`.

## Panel → simulador

| Campo | Tipo y significado |
|---|---|
| `v` | Número de versión, actualmente `1`. |
| `ctrl` | Control accionado. Puede ser `bloqueo`, `etiquetado`, `torque`, `confirmar` o `cancelar`. |
| `valor` | Para los interruptores, estado absoluto `0` (inactivo) o `1` (activo). Para los botones, `1` indica pulsación y `0` indica liberación si se reporta. La acción de confirmar o cancelar se ejecuta con la pulsación. La perilla envía un valor numérico absoluto de `0` a `100`, inclusive. |
| `n` | Entero no negativo que identifica el evento. El emisor lo incrementa por cada evento de control. Las secuencias del panel físico y virtual son independientes. |
| `t` | Milisegundos enteros no negativos en el reloj del emisor. El filtro usa este reloj dentro de la misma sesión. |

```json
{"v":1,"ctrl":"bloqueo","valor":1,"n":0,"t":0}
{"v":1,"ctrl":"etiquetado","valor":1,"n":1,"t":60}
{"v":1,"ctrl":"torque","valor":42,"n":2,"t":120}
{"v":1,"ctrl":"confirmar","valor":1,"n":3,"t":180}
{"v":1,"ctrl":"cancelar","valor":1,"n":4,"t":240}
```

El receptor registra y descarta mensajes inválidos y números de secuencia repetidos. Suprime eventos del mismo control recibidos a menos de 50 ms del último aceptado de ese control y esa fuente. Los eventos de distintos controles conservan su orden de llegada. Si varias fuentes emiten la misma acción en un lote simultáneo, se aplican los eventos de la última fuente de esa acción y se registran todas las entradas reconocidas.

## Latido

El panel físico envía este mensaje cada segundo. El latido usa solo `v` y `ctrl`.

```json
{"v":1,"ctrl":"hb"}
```

El simulador mide el plazo con su reloj monotónico desde el inicio de la sesión física o desde el último latido válido. Al cumplirse 3 s, pausa la práctica, avisa y selecciona el panel virtual. La práctica se puede reanudar explícitamente. Una nueva conexión física inicia otra sesión y reinicia el seguimiento de secuencia y rebote del panel físico.

## Simulador → panel

El mensaje lleva la versión `v`, el identificador `led` y el estado absoluto `valor`, con `0` para apagar o `1` para encender.

```json
{"v":1,"led":"energizado","valor":1}
{"v":1,"led":"bloqueado","valor":1}
{"v":1,"led":"falla","valor":1}
```

## Emisor de prueba

Desde la raíz, `godot --headless --no-header -s tools/emisor_eventos.gd` imprime una secuencia de controles en la salida estándar. `test_entrada_50.gd` reproduce esas líneas a través del parser y la capa de entrada, y usa las confirmaciones para ejecutar los pasos del escenario de aislamiento.
