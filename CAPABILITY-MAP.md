# Capability Map: Sistema Inteligente de Entrenamiento para Autobuses (HackaTec 2026, Reto 1 Volvo)

Estado: **aprobado para avanzar** (constitución en `docs/constitution.md`). Aún no hay specs de módulo.

## Módulos

| Id | Responsabilidad | Depende de |
|---|---|---|
| competencias | Mapa de habilidades, banco de preguntas y casos con fuente, criticidad de seguridad | — |
| aprendizaje | Diagnóstico inicial, ruta adaptativa, repetición espaciada, evaluación antes/después/diferida, métrica de brecha | competencias |
| simulador | Escena 3D del bus en Godot, árbol de fallas, reglas de seguridad y puntuación | competencias |
| panel | Firmware ESP32/Arduino, protocolo JSON serial, puente a Godot, maqueta física | simulador |
| entrada | Vocabulario único de acciones: teclado y ratón, sticks del Pro Controller, panel | simulador, panel |
| tablero | Avance, dominio, errores recurrentes, curva de retención, trazabilidad | aprendizaje, simulador |
| entrega | Documentación técnica, escalabilidad e integración, guion de demo | todos |

Orden de construcción: competencias → aprendizaje y simulador (paralelo) → panel → entrada y tablero → entrega.

Cada módulo tendrá `SPEC-<id>.md` en la raíz, basado en `samples/spec.md` (RF en EARS).

## Trazabilidad con los 6 entregables del reto

| Entregable del reto | Módulo(s) |
|---|---|
| 1. Diagnóstico inicial de competencias | competencias, aprendizaje |
| 2. Ruta de aprendizaje adaptativa | aprendizaje |
| 3. Módulo práctico (bus eléctrico o diésel) | simulador, panel, entrada |
| 4. Evaluación antes, inmediata y diferida simulada | aprendizaje |
| 5. Tablero de avance, dominio, errores y retención | tablero |
| 6. Escalabilidad e integración + documentación | entrega |

Requisitos transversales: operación offline, trazabilidad de resultados, contenido confiable (fuente citada), protección de datos.

## Decisiones tomadas

- Stack: Godot 4.7.2. Sin giroscopio; solo sticks del Pro Controller, teclado y ratón, y panel de botones.
- Idea central: la **brecha** entre lo que el técnico diagnostica en pantalla y lo que ejecuta en el panel alimenta la ruta adaptativa.
- Escenario eléctrico primero; diésel solo si sobra tiempo.
- Datos locales, contenido `[MUESTRA]` hasta recibir material de Volvo, retención diferida simulada y declarada.

## Decisiones abiertas

- Equipo: tamaño y horas reales.
- Panel: microcontrolador (ESP32 sin probar) y cuántos botones, interruptores, perillas y LEDs.
- Rúbrica real de evaluación y material técnico de Volvo (preguntar a los organizadores).
- Plugin serial de Godot vs. puente Python (prueba de 30 min).

## Actualización
- Módulo `flujo` (Spec 007): depende de aprendizaje, simulador, tablero. `entrada` está dentro de `panel`. Orden: competencias → aprendizaje+simulador → panel → tablero → flujo → entrega.

## Actualización — arnés
- Módulo `arnes` (Spec 008): práctica de diagnóstico con medición. Depende de `simulador`, `panel`, `aprendizaje`, `tablero`. Banco físico opcional; el multímetro virtual es obligatorio.
