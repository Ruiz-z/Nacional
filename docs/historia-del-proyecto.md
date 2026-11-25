# Historia del proyecto: qué hicimos y por qué

Reto 1 de Volvo en HackaTec 2026 (TecNM): *Técnicos del Mañana, sistema inteligente de entrenamiento para autobuses*. Este documento resume lo construido y la razón de cada decisión.

## 1. El problema y la idea central
- **Problema que confirmó Volvo:** los técnicos fallan en la **lógica del procedimiento de diagnóstico**, aunque tengan manuales, diagnóstico guiado, códigos de falla y soporte. Además, el seguimiento de su capacitación es **manual**.
- **Idea:** un simulador de entrenamiento adaptativo que enseñe **cómo diagnosticar**, no solo cuál es la falla, y que dé evidencia al jefe directo (que es quien decide el avance de nivel).
- **Por qué un juego en primera persona:** el técnico aprende haciendo en un taller virtual, con herramientas, piezas y errores reales, sin riesgo para un autobús.

## 2. Cómo trabajamos
- **Desarrollo guiado por especificaciones** (SPEC-*.md, constitución, plan, tareas). *Por qué:* dos subequipos (electrónica y sistemas) necesitan un acuerdo escrito para no pisarse, y el jurado puede rastrear cada decisión.
- **Ritmo:** una persona orquesta, Codex implementa en segundo plano, se verifica con la suite de pruebas sin pantalla y con capturas, y se sube a `dev`.
- **Por qué pruebas automáticas (102 hoy):** cada cambio de interfaz rompía algo; la suite lo detecta antes de que lo vea el usuario.
- **Sin internet y local:** el prototipo funciona sin conexión (SQLite local, JSON de contenido). *Por qué:* un taller real no siempre tiene red, y la demo no debe depender de ella.

## 3. Tecnología
- **Godot 4.7.2** (GDScript, renderer de compatibilidad): ligero, gratuito, exporta a escritorio y web.
- **SQLite (godot-sqlite)** para intentos, progreso y reloj simulado.
- **Contenido en JSON** (banco de preguntas y escenarios). *Por qué:* sustituir el contenido de muestra por el oficial de Volvo sin tocar código.
- **Panel físico opcional** (ESP32/Arduino) con protocolo JSON v1 y panel virtual de respaldo. *Por qué:* el reto valora lo físico, pero la demo no puede quedar bloqueada si falla el hardware.

## 4. Lo que se construyó

### Simulador de taller
- Zonas del autobús (gabinete de baterías, faros, motor, cabina, bajos) con piezas interactuables y menú por pieza.
- **Elevador** con consola, calzas y soportes; trabajar bajo el autobús sin seguridad es falta crítica. *Por qué:* el procedimiento seguro es parte de la competencia.
- **Taller con inventario:** mesa, caja roja de herramientas con cajones (de uno en uno), estantería de repuestos, carrito. Cinturón de 4 espacios más 4 del carrito, y los objetos ocupan distinto espacio. *Por qué:* elegir y llevar la herramienta correcta es un error real de los técnicos.
- **Herramienta en la mano** obligatoria para cada acción; si es otra, tarjeta de "herramienta equivocada".
- **Guía azul automática** (contorno, flecha, baliza) y subpasos de la misión con la ubicación exacta ("caja roja de herramientas, cajón de abajo"). *Por qué:* un usuario nuevo no sabe cuál mueble es cuál.
- **Rótulos** en los muebles y leyenda "Dónde está todo" en la tarjeta de orden.
- **Avisos como tarjetas con OK** en vez de mensajes que duran segundos. *Por qué:* no daba tiempo de leerlos.
- **Aviso de problema por reparar:** si una pieza se daña, el HUD lo dice y qué hacer primero.

### Órdenes de servicio (10)
Aislamiento, comunicación, faros, módulo auxiliar, motor, neumático pinchado, tuercas flojas, fuga de suspensión neumática, amortiguador dañado y freno desgastado, agrupadas por función (FG) de Volvo y ordenadas por dificultad. Cada una tiene **tarjeta de orden** (síntoma, objetivo, cómo) y **preguntas de diagnóstico al final** con causa real y explicación. *Por qué:* evaluar el proceso y la causa, no solo el resultado.

### Banco de arnés (hardware)
Maqueta con interruptores S1/S2 y puntos de prueba TP0, TP1 y TP2: dos averías distintas con el mismo síntoma. El técnico mide con **un solo multímetro**, ve qué punta usa, anota lecturas en una **hoja de diagnóstico** y elige la causa. *Por qué:* distinguir alimentación de señal con dos mediciones es una habilidad observable y demostrable ante el jurado. Los errores se separan en **de medición** y **de interpretación**, porque requieren prácticas distintas.
- **Adaptador del ESP32** (UDP por Wi-Fi hacia el protocolo del simulador) y **nivel alto configurable** (3.3 V o 5 V). *Por qué:* el ESP32 del equipo hablaba otro formato y otro voltaje que el simulador.

### Aprendizaje adaptativo
- **Diagnóstico** inicial (10 reactivos) con adaptación a fácil si falla la pregunta media.
- **Ruta** ordenada por falta crítica, brechas y dominio, con peso extra a seguridad; ahora como **roadmap visual** con motivo y práctica por tema.
- **Retroalimentación**, introducción y resultados con barras de color.
- **Post-test y retest diferido** (reloj simulado a 7 días, declarado como tal). *Por qué:* medir ganancia y retención sin esperar una semana real en la demo.
- **Repetición espaciada (Leitner)** y dominio ponderado de los últimos intentos.
- **Identidad de sesión** en cada intento y migración de la base. *Por qué:* la curva de aprendizaje necesita saber qué intentos pertenecen a una misma práctica.
- **Refuerzo por error concreto:** cada tipo de error recomienda su práctica.

### Tablero y resumen
Tablero con dominio, ganancia, retención, errores recurrentes y brechas, y exportación CSV/JSON. Resumen de cada orden con paso a paso, tiempo y reflexión. Línea de aprobación de 91, tomada de los cursos de Volvo. *Por qué:* reemplaza el seguimiento manual y da evidencia al jefe directo.

### Menú y experiencia
Menú con tarjetas, paleta y tipografía propias, alias de técnico, modo demo con datos precargados, y recorrido Diagnóstico → Ruta → Escenario → Post → Retest. Exportación web y recorrido automático con Playwright.

## 5. Problemas encontrados y cómo se resolvieron
| Problema | Causa | Solución |
|---|---|---|
| El ratón no giraba la cámara | Su movimiento pasaba por un filtro de rebote de 50 ms | Se guarda el mapeo y se evita el filtro en el movimiento |
| Las compuertas no abrían | El clic usaba un rayo viejo | Se consulta el rayo en el instante del clic |
| "No tengo espacio" con espacio libre | La bolsa de aire ocupa 2 espacios y el HUD no lo mostraba | Inventario legible "Cinturón 3/4" y mensaje con la cuenta exacta |
| El resumen "no guardaba ni salía" | Guardar fallaba sin avisar con la reflexión vacía | Botones fijos y avisos claros |
| El banco confundía (dos multímetros) | Había uno en la mesa y otro en la caja | Un solo multímetro y hoja aparte |
| Un commit incluyó binarios de más de 100 MB | Se versionó la carpeta de exportación | Se quitó de git y se corrigió `.gitignore` |
| ESP32 incompatible con Godot | Distinto puerto, formato y voltaje | Adaptador y nominal configurable |
| Una prueba de cajones fallaba | Esperaba una animación que ya no ocurría | Se ajustó la prueba al flujo real |

## 6. Lo que dijo Volvo y qué cambió
Ver `docs/respuestas-volvo.md`. Se mantienen tres niveles simplificados, el circuito de aislamiento, el arnés y el aprendizaje adaptativo. Cambia el enfoque: evaluar el **procedimiento** y mostrar el avance como **recomendación**, porque lo decide el jefe directo. Cobertura actual: tres de las cinco categorías de falla que Volvo mencionó (directa en electrónica y arneses, parcial en batería).

## 7. Pendiente
- **T-165:** evidencia y errores por oportunidad en el tablero.
- **T-160:** el resumen evalúa el orden de los pasos y los omitidos, no solo el resultado.
- **T-129, T-130, T-131, T-133, T-134:** más órdenes eléctricas, catálogo, recorrido web del taller, línea de aprobación en el tablero y extras de Tech Tool.
- **Humanas:** T-166 (prueba en mesa con el ESP32 real), validar escenarios con Volvo y confirmar si su documentación técnica es confidencial antes de subirla a GitHub.
- **Ideas aparte:** paso de predicción antes de medir, diferido con variante práctica, rúbrica de cuatro criterios, mentor de voz local, y actualizar el ejecutable de Windows.

## 8. Qué mostrar al jurado
Una sola sesión completa: qué sabía el técnico al entrar, en qué paso se equivocó, qué práctica recibió y si después resolvió otra falla por su cuenta. La pregunta guía: *cuando el módulo deja de responder, ¿el técnico puede demostrar con dos mediciones dónde está la falla?*

## 9. Limitaciones que declaramos
- Los valores técnicos y las preguntas son de **muestra** hasta recibir material oficial de Volvo.
- La retención se **simula** adelantando el reloj; la real exige tiempo real.
- El prototipo no está integrado con Tech Tool ni con otros sistemas de Volvo.
- Un puntaje del simulador no equivale a una certificación Volvo.
