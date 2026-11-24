# Arquitectura

## Módulos y conexiones
```
 contenido/ (JSON) ──► competencias ──► aprendizaje ──┐
                         │                            ├──► datos (SQLite) ──► tablero ──► flujo (menú)
 escenarios (JSON) ──► simulador ─────────────────────┘
                         ▲
 teclado · ratón · Pro Controller · panel físico/virtual ──► entrada
```
- **competencias:** carga y valida el banco JSON; rechaza ítems sin fuente permitida.
- **aprendizaje:** dominio, diagnóstico, ruta, repetición espaciada (Leitner), reloj simulado, pre/post/retest.
- **simulador:** motor de estado guiado por datos (acciones, eventos, recuperaciones, puntaje, brecha).
- **entrada/panel:** vocabulario único de acciones; el panel envía una línea JSON por evento (`docs/protocolo-panel.md`).
- **tablero:** indicadores, vistas, exportación CSV/JSON y asistente opcional.
- **flujo:** alias, menú principal, guardado y modo demo.
- **datos:** esquema SQLite único (`docs/modelo-datos.md`).

La lógica vive en `godot/logica/` sin nodos; las escenas en `godot/escenas/` solo la llaman.

## Cómo ejecutar
Ver `README.md`. Pruebas: `godot --headless --path godot -s tests/run.gd`.

## Cómo agregar contenido
1. Edita `contenido/banco.json`: cada ítem necesita `id`, `competencia`, `formato`, `dificultad` (`facil`/`media`/`dificil`), `criticidad`, `fuente`, `muestra` y `version`.
2. Un valor técnico sin fuente pública usa la fuente `[MUESTRA] valor de ejemplo, sin fuente oficial` con `muestra=true`; nunca un ítem de seguridad.
3. Valida: `godot --headless -s tools/validar_contenido.gd`. Debe imprimir `OK`.

## Cómo agregar un escenario
1. Copia `contenido/escenarios/aislamiento.json` y cambia `estado`, `acciones`, `eventos`, `recuperaciones` y `terminacion`.
2. Cada acción lleva competencia, tipo de error, criticidad y fuente.
3. El validador del simulador reporta archivo y campo si algo falla; no se carga un escenario inválido.
4. No hace falta programar.
