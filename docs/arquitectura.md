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

## Cómo agregar un escenario (orden de servicio)
1. Copia `contenido/escenarios/faros.json` y cambia `id`, `titulo`, `descripcion`, `estado`, `acciones`, `eventos`, `recuperaciones`, `terminacion` y `ruta_ideal`.
2. Declara la `zona` donde ocurre (`gabinete`, `faros`, `motor` o `cabina`). Aparece sola en el catálogo de **Escenario**.
3. Cada acción lleva `titulo` (verbo corto, por ejemplo "Medir continuidad"), `descripcion`, `componente` (la pieza donde se ofrece), `competencia`, `tipo_error`, `criticidad` y `fuente`.
4. `requiere_panel: true` hace que la acción espere la confirmación del panel (físico o virtual); sin él se ejecuta al pulsar.
5. Valores técnicos sin fuente pública usan `[MUESTRA] valor de ejemplo, sin fuente oficial`. Los datos de Volvo citables están en `docs/fuentes-volvo.md`.
6. Las pruebas recorren la `ruta_ideal` de cada escenario; si falla, el validador indica archivo y campo.
7. No hace falta programar, salvo que se agregue una zona nueva (una escena que herede de `zona_base.gd`).
