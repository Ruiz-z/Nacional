# Plan técnico — HackaTec 2026, Reto 1 Volvo

Parte de los specs 001–007 y la constitución. Cada módulo se construye en el orden de la sección "Orden y puntos de control".

## Estructura del repositorio
```
godot/            proyecto Godot 4.7.2
  logica/         GDScript puro, sin nodos (se prueba sin escena)
    competencias/ cargador y validador del banco
    aprendizaje/  dominio, diagnóstico, ruta, Leitner, reloj
    simulador/    motor de estado de escenarios
    entrada/      vocabulario de acciones y mapeo
    datos/        acceso a SQLite y esquema
  escenas/        UI, escena 3D, tablero, panel virtual, menú
  config/         mapeo de entrada (JSON)
  tests/          scripts de prueba y run.gd
contenido/        banco JSON y escenarios JSON
firmware/         código del ESP32 o Arduino
tools/            emisor de eventos de prueba, validador de contenido
docs/             constitution.md, protocolo-panel.md, modelo-datos.md, arquitectura, escalabilidad, privacidad, demo
```
Regla: toda la lógica de los RF vive en `logica/` y las escenas solo la llaman. Así las pruebas no dependen de la escena.

## Módulos y dependencias
`competencias` → `aprendizaje`, `simulador` → `panel` (entrada) → `tablero` → `flujo` → `entrega`.
`datos/` es de `tablero` (esquema único); `aprendizaje` y `simulador` escriben mediante él.

## Modelo de datos (SQLite, `docs/modelo-datos.md`)
| Tabla | Campos clave |
|---|---|
| `tecnico` | id, alias (único), demo (bool), creado |
| `intento` | id, tecnico, competencia, item, formato, dificultad, respuesta, valor 0–100, peso, resultado, tipo_error, tiempo_ms, fuente_entrada, momento (`pre`/`post`/`retest`/`practica`), reloj_sim, version_contenido |
| `evento` | id, tecnico, escenario, accion, estado_antes, estado_despues, criticidad, fuente_entrada, reloj_sim |
| `brecha` | id, tecnico, competencia, caso, causa_marcada, accion_ejecutada, reloj_sim |
| `leitner` | tecnico, item, caja 1–3, proxima_fecha_sim |
| `progreso` | tecnico, paso_actual, ruta (JSON), microlecciones_hechas |
| `reloj` | tecnico, desplazamiento_dias |
Dominio, nivel y errores recurrentes se calculan al consultar a partir de `intento`; no se guardan derivados. Copia de respaldo automática del archivo al cerrar cada paso.

## Decisiones técnicas
| Decisión | Elegido | Alternativa descartada y por qué |
|---|---|---|
| Lógica fuera de las escenas | GDScript puro en `logica/` | Lógica en nodos: no se puede probar sin abrir el editor. |
| Pruebas | Scripts con `godot --headless --path godot -s tests/run.gd` | GUT: es una dependencia más y la constitución pide preguntar. Se puede cambiar si el equipo lo prefiere. |
| Almacenamiento | SQLite mediante plugin aprobado | JSON por técnico: consultas y exportación más difíciles; sin la fuente única que pide `tablero`. |
| Contenido y escenarios | JSON validado al cargar | Recursos de Godot (`.tres`): los autores no pueden editarlos sin el editor. |
| Escenarios | Máquina de estados guiada por datos | Árbol de pasos fijo: no permite consecuencias ni recuperaciones. |
| Entrada | Una acción única (`entrada`) con mapeo en JSON | Leer teclas en cada escena: duplica reglas y rompe la intercambiabilidad panel/teclado. |
| Panel físico | Plugin serial de Godot si pasa la prueba de 30 min | Puente Python por UDP: otro proceso que arrancar; se usa solo si el plugin falla. |
| Panel virtual | Escena que emite los mismos JSON por el mismo bus de eventos | Eventos internos distintos: no probaría el protocolo. |
| Asistente LLM | Ollama local opcional, RAG con FTS5 de SQLite | Embeddings y base vectorial: más dependencias y peso para una demo offline. |
| Reloj | Desplazamiento guardado en días, solo hacia adelante | Reloj del sistema operativo: no se puede demostrar la retención. |
| Exportación | Windows y Linux con plantillas de Godot | Solo Linux: no cumple `entrega` RF-6; Windows queda declarado como no probado si no hay máquina. |

## Estrategia de pruebas
- **Automáticas** (`tests/`): validación de contenido y escenarios, fórmulas de dominio, ganancia y retención, selección de diagnóstico, ruta y Leitner, motor de estado del simulador, parser y filtro del protocolo (con `tools/emisor_eventos`), esquema SQLite y exportación.
- **Manuales** (checklist en `docs/checklists.md`): escena 3D, controles, panel físico, vistas del tablero, asistente LLM, demo completa.
- **Datos de prueba**: banco mínimo y escenario `[MUESTRA]` en `contenido/`.
- Un RF se marca hecho cuando su prueba está en verde (constitución 10).

## Cobertura de RF
| Spec | RF | Cómo se prueba |
|---|---|---|
| 001 competencias | 1–14 | Validador (RF-2 a 4, 9, 10, 12–14), prueba de esquema, revisión manual de fuentes de seguridad |
| 002 aprendizaje | 1–21 | Pruebas de fórmula y ruta (RF-1 a 11, 15, 16, 18, 20); Leitner y reloj (12–14); registro (17, 19); manual del flujo (21) |
| 003 simulador | 1–24 | Motor de estado (1–9, 16–19, 22); manual de escena y controles (10–15, 24) |
| 004 tablero | 1–23 | Consultas y exportación automáticas (1, 2, 4, 5, 13–16); manual de vistas y asistente (3, 6–12, 17–23) |
| 005 panel | 1–18 | Emisor de eventos (1–7, 10–12, 14–15); manual con panel físico (8, 9, 13, 16–18) |
| 006 entrega | 1–13 | Checklist de entregables y ensayos de demo |
| 007 flujo | 1–9 | Guardado y reanudación automáticos (4, 5); manual de pantallas |

## Orden y puntos de control
1. **Cimientos:** proyecto Godot, `datos/` con esquema, `run.gd`. *Control:* prueba vacía en verde.
2. **competencias:** cargador, validador, banco `[MUESTRA]` (32 ítems, 2 casos, 3 acciones-panel). *Control:* validador sin errores.
3. **aprendizaje:** dominio, diagnóstico, ruta, Leitner, reloj, pre/post/retest. *Control:* flujo completo en pruebas con datos simulados.
4. **simulador (motor):** escenario JSON de aislamiento, recuperaciones, puntaje, brecha. *Control:* escenario con tornillo roto resuelto en prueba.
5. **entrada y panel virtual:** acciones, mapeo, protocolo, emisor. En paralelo con electrónica: prueba de 30 min y firmware. *Control:* escenario jugable con teclado y panel virtual.
6. **simulador (escena 3D) :** inspección, menú de acciones, resumen y reintento. *Control:* demo manual del escenario.
7. **tablero:** consultas, vistas, exportación; luego asistente. *Control:* técnico `[DEMO]` visible.
8. **flujo:** alias, menú, guardado y modo demo. *Control:* recorrido completo.
9. **entrega:** documentos, exportación, usabilidad y ensayos. *Control:* checklist de 6 entregables.

Prioridad si falta tiempo: puntos 1–5 y 7–8 sin LLM; la escena 3D puede ser esquemática; el asistente y el escenario de comunicación son lo primero que se recorta.

## Riesgos
| Riesgo | Mitigación |
|---|---|
| Plugin SQLite o serial no compatible con 4.7.2 | Prueba de 30 min el primer día; respaldo: puente Python para el panel y JSON solo para la demo. |
| Sin material oficial de Volvo | Todo `[MUESTRA]` con fuentes públicas; sustitución solo por JSON. |
| Panel físico tarde | Panel virtual desde el punto 5; el firmware no bloquea la demo. |
| Autoría de 32 ítems y variantes consume tiempo | Repartir la redacción entre electrónica y sistemas; verificación cruzada. |
| LLM no corre en la laptop de la demo | Asistente opcional; la demo no lo usa. |

## Dudas que afectan el plan
Tamaño y horas del equipo, componentes del panel, plugin serial y fecha límite. Hay que fijarlos antes de dividir tareas.
