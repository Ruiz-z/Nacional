# Clarificación (revisión tipo QA) — specs 001 a 006

Solo detección: nada se resolvió ni se editó en los specs. Cada hallazgo indica specs y RF implicados.
Gravedad: **A** bloquea el plan, **M** se resuelve antes de implementar ese módulo, **B** menor.

## Contradicciones

| # | Gravedad | Hallazgo |
|---|---|---|
| C1 | A | **Fuente "genérica" vs fuente obligatoria.** `simulador` (no funcionales) dice que sin fuente el valor se deja genérico, y `panel` RF-13 acepta rangos `[MUESTRA]` sin fuente oficial. `competencias` RF-4 rechaza todo ítem sin fuente de la lista permitida. Un valor genérico no tiene fuente y sería rechazado. |
| C2 | M | **Fuente de entrada.** `panel` RF-3 define 4 valores (`panel`, `virtual`, `teclado`, `control`). `simulador` RF-22 y RF-24 solo 3 (falta `control`). |
| C3 | M | **Eventos fuera de orden.** `panel` RF-5 los ignora; `panel` RF-10/11 los evalúa y registra `orden-incorrecto`; `simulador` casos límite los ignora. No se puede distinguir un evento fuera de orden por fallo de transporte de uno por error del técnico. |
| C4 | M | **Registro corrupto.** `aprendizaje`: error claro sin perder a los demás técnicos. `tablero`: BD corrupta, se crea una nueva y se avisa (se pierden todos). |
| C5 | M | **"El tablero no calcula" frente a sus indicadores.** `tablero` RF-2 dice que no recalcula. Pero los indicadores 5 (errores recurrentes ≥3), 7 (faltas críticas), 8 (tiempo promedio) y 9 (avance de ruta) no figuran en lo que entrega `aprendizaje` RF-20. Nadie los calcula. |
| C6 | M | **Quién detecta la brecha.** `simulador` RF-16 compara y envía la brecha. `aprendizaje` RF-17 repite la condición ("marca una causa y ejecuta otra"). Dos módulos describen la misma regla. |
| C7 | M | **Penalización al dominio vs promedio de intentos.** `aprendizaje` define dominio como promedio ponderado de los últimos 10 intentos y a la vez resta −15 y −5 "directo". No se sabe si la resta es permanente, se aplica sobre el promedio o es un intento más. |
| C8 | B | **Pro Controller.** La constitución (6) y `simulador` RF-10 hablan de "sticks"; `panel` usa también A, X, B, D-pad, gatillos y botones laterales. Hay que alinear el texto. |

## Huecos

| # | Gravedad | Hallazgo |
|---|---|---|
| H1 | A | **Nadie define el flujo de la aplicación.** Alta y selección de técnico (alias), menú principal, orden diagnóstico → ruta → escenario → post → retest, guardar/reanudar a mitad de sesión, modo demo. Ningún módulo lo posee. Falta un módulo (p. ej. `app` o `flujo`) o asignarlo a uno. |
| H2 | A | **Valor de un intento.** No se dice qué número entra al promedio: ¿0/100 en preguntas?, ¿el puntaje 0-100 del escenario? `simulador` RF-17 puntúa escenarios; `aprendizaje` no dice cómo lo convierte. |
| H3 | A | **Pesos sin cifras.** `aprendizaje` RF-1 "peso creciente según dificultad" sin valores. Los niveles de `dificultad` (fácil, media, difícil) tampoco están definidos en `competencias`, pero RF-4/RF-5 los usan. El no funcional pide "fórmulas tal cual escritas". |
| H4 | A | **Ganancia contaminada.** Dominio pre/post: ¿instantánea del diagnóstico y del post-test, o ventana de 10 intentos que incluye la práctica? Con 2 ítems teóricos por competencia (duda abierta de `aprendizaje`) la ganancia sería ruido. |
| H5 | M | **Suficiencia del banco.** 8 ítems por competencia (`competencias` RF-9) cubren pre (2) + post (2) + práctica de ruta (2 por micro-lección, 3 por sesión) con muy pocas sesiones antes de repetir. Retest reutiliza "ítems ya vistos" sin decir de cuál conjunto (pre o post). Los 3 `accion-panel` y 2 `caso-diagnostico` alcanzan justo para pre + post. |
| H6 | M | **Retención.** Retest ÷ post con post = 0 divide entre cero; puede pasar de 100. Sin regla. |
| H7 | M | **Prioridad de ruta.** `aprendizaje` RF-8, RF-11 y RF-18 mandan "al primer lugar" por motivos distintos. Si coinciden dos competencias no hay desempate. "Hasta que se repita correctamente" y "falta crítica reciente" no están definidos. |
| H8 | M | **Variantes.** `simulador` RF-19 y `aprendizaje` RF-14 piden variantes sin decir qué varía (estado inicial, ubicación de la falla, valores) ni cuántas se escriben. Con un solo escenario completo el costo de autoría no está estimado. |
| H9 | M | **Dueño del modelo de datos.** `aprendizaje` RF-19 registra eventos y `tablero` RF-1 los guarda en SQLite con otros campos. Falta un único esquema y su responsable (entrega lo exige en `docs`). |
| H10 | M | **Protocolo incompleto.** Sin definir: unidades y rango de `valor`, formato del mensaje de LEDs, origen de `t`, número de secuencia para detectar duplicados/pérdidas, saludo de versión. Sin latido, el simulador no sabe que el panel se desconectó (`simulador` RF-14 lo presupone). |
| H11 | M | **Semántica de controles.** Perilla da valor absoluto; rueda del ratón y gatillos son relativos. Interruptores guardan estado; teclas y botones son pulsos. `entrada` no define la conversión. |
| H12 | M | **Reloj simulado.** Dónde está el botón, cómo se combina con el reloj real, si persiste entre ejecuciones, cómo se reinicia para la demo. |
| H13 | M | **Variable de "modo demo".** `tablero` RF-16 y `entrega` RF-7 precargan datos; no se dice cómo se activa ni cómo se separan de datos reales. |
| H14 | B | **Tipos de error.** Los cinco de `competencias` RF-11 no cubren "torque fuera de rango" ni "tornillo roto" del ejemplo central. |
| H15 | B | **Faltas leves.** `simulador` RF-9 resta puntos del escenario; `competencias` RF-8 también. No se relaciona con la resta al dominio de `aprendizaje`. |

## Ambigüedades y requisitos no verificables

| # | Gravedad | Hallazgo |
|---|---|---|
| A1 | M | "Percibida como inmediata" (`panel`), "no bloquea la interfaz" (`tablero`), "texto grande", "gráficos reconocibles" no tienen número ni prueba. |
| A2 | M | `entrega` guion: diagnóstico de 10 ítems en 60 s y flujo escenario + brecha en 120 s no caben en vivo. No se aclara si el diagnóstico va precargado. El retest simulado del paso 5 no tiene paso previo (post-test y reloj). |
| A3 | B | "Competencia aprobada" (`aprendizaje`) se define pero ningún RF ni indicador la usa. |
| A4 | B | `entrega` RF-11 depende de la persona de prueba y no es verificable por sí mismo. |
| A5 | B | `entrega` RF-6 exportar Windows y Linux: no hay plantilla de exportación ni máquina Windows para probar. |

## Conflictos con la constitución

| # | Gravedad | Hallazgo |
|---|---|---|
| K1 | A | Principio 12 (no añadir dependencias sin preguntar). Los specs asumen sin aprobar: plugin SQLite para Godot, plugin serial o puente Python, runtime LLM local, modelo y embeddings para RAG. Hay que aprobar o rechazar cada una. |
| K2 | M | La constitución (1 y 2) no menciona SQLite ni el LLM opcional; los specs los exigen. Hay que añadirlos como decisiones. |
| K3 | B | El principio 4 dice que las reglas de seguridad se escriben a mano. La nota de `tablero` sobre el asistente lo respeta; conviene reflejarlo en RF-21 con la misma palabra. |

## Documentos desalineados
- `CAPABILITY-MAP.md` lista `entrada` como módulo aparte; está dentro de `panel`. Falta registrar el módulo de H1 si se acepta.
- No existen `docs/protocolo-panel.md` ni `AGENTS.md`.

## Dudas abiertas heredadas (sin resolver)
Equipo y horas; componentes y fecha del panel; material y rúbrica de Volvo; plugin serial vs puente; modelo LLM y RAG; formato y fecha de entrega; tiempo de presentación; quién escribe cada documento.

## Decisiones de clarificación (por aplicar a los specs)
- C1: se permite fuente "[MUESTRA] valor de ejemplo, sin fuente oficial" con muestra=true solo para valores técnicos (torque, rangos), nunca para ítems de seguridad; se sustituye con material de Volvo. Afecta competencias RF-4/RF-5, simulador, panel RF-13.
- H1: módulo nuevo `flujo` (Spec 007): alias, menú principal (Diagnóstico, Ruta, Escenario, Evaluación, Tablero, Modo demo), orden guiado, guardado automático por paso. Depende de aprendizaje, simulador, tablero. Falta redactar SPEC-flujo.md y actualizar CAPABILITY-MAP.md.
- H2/H3/H4 aplicados en SPEC-aprendizaje.md y SPEC-competencias.md: intento 100/0 o puntaje del escenario; pesos 1/2/3, práctica x2; pre/post/retest son instantáneas.
- K1 aplicado en docs/constitution.md (12): SQLite, LLM local opcional y FTS5 aprobados; serial por prueba.
- Pendiente: C3-C7, H5-H15, A y K2-K3 (importantes y menores); redactar SPEC-flujo.md.
- Aplicado: C2-C8, H5-H15, A1-A3, K2 en los specs; creado SPEC-flujo.md (RF-1..9). No aplicado: A4, A5 (declarar exportación Windows sin probar), K3.
