# Técnicos del Mañana — HackaTec 2026, Reto 1 Volvo

Juego de escritorio que entrena a técnicos de autobuses eléctricos con escenarios de falla, consecuencias y un panel físico opcional. Mide la **brecha** entre lo que el técnico marca como diagnóstico en pantalla y lo que ejecuta en el panel. Todo es simulado, funciona sin internet y los técnicos se identifican con alias.

## Instalación en 3 pasos
1. Instala **Godot 4.7.2** (versión estándar, sin .NET).
2. Clona el repositorio: `git clone git@github.com-personal:Ruiz-z/Nacional.git && cd Nacional && git checkout dev`.
3. Abre la carpeta `godot/` desde Godot (Importar) y pulsa Ejecutar. El plugin `godot-sqlite` ya viene en `godot/addons/`.

## Comandos
| Acción | Comando |
|---|---|
| Pruebas | `godot --headless --path godot -s tests/run.gd` |
| Validar el banco de contenido | `godot --headless --path godot -s ../tools/validar_contenido.gd` |
| Emitir eventos de prueba del panel | ver `docs/protocolo-panel.md` |

Si Godot no puede escribir sus logs, antepón `XDG_DATA_HOME=/tmp/nacional-godot`.

## Estructura
```
godot/       proyecto Godot: logica/ (sin nodos, con pruebas), escenas/, config/, tests/, addons/
contenido/   banco de preguntas y escenarios en JSON, con su fuente
firmware/    código del ESP32 o Arduino (a cargo de electrónica)
tools/       validador de contenido y emisor de eventos
docs/        constitución, arquitectura, protocolo del panel, modelo de datos, escalabilidad, privacidad, demo
SPEC-*.md    especificaciones por módulo; plan.md y tareas.md
```

## Más información
- Arquitectura y cómo agregar contenido: `docs/arquitectura.md`
- Escalabilidad e integración: `docs/escalabilidad.md`
- Privacidad y contenido: `docs/privacidad.md`
- Guion de la demo: `docs/demo.md`
- Dependencias y versiones: `docs/dependencias.md`

El contenido no oficial está marcado `[MUESTRA]` y los datos de demostración `[DEMO]`.
