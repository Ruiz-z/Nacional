# Historia del proyecto: qué hicimos y por qué

Reto 1 de Volvo en HackaTec 2026 (TecNM): *Técnicos del Mañana, sistema inteligente de entrenamiento para autobuses*. Este documento resume lo construido y la razón de cada decisión.

## 1. El problema y la idea central
- **Problema que confirmó Volvo:** los técnicos fallan en la **lógica del procedimiento de diagnóstico**, aunque tengan manuales, diagnóstico guiado, códigos de falla y soporte. Además, el seguimiento de su capacitación es **manual**.
- **Idea:** un simulador de entrenamiento adaptativo que enseñe **cómo diagnosticar**, no solo cuál es la falla, y que dé evidencia al jefe directo (que es quien decide el avance de nivel).
- **Por qué un juego en primera persona:** el técnico aprende haciendo en un taller virtual, con herramientas, piezas y errores reales, sin riesgo para un autobús.

## 2. Cómo trabajamos
- **Desarrollo guiado por especificaciones** (SPEC-*.md, constitución, plan, tareas). *Por qué:* dos subequipos (electrónica y sistemas) necesitan un acuerdo escrito para no pisarse, y el jurado puede rastrear cada decisión.
- **Ritmo:** una persona orquesta, Codex implementa en segundo plano, se verifica con la suite de pruebas sin pantalla y con capturas, y se sube a `dev`.
- **Por qué pruebas automáticas (166 hoy: 126 en Godot y 40 en Python):** cada cambio de interfaz rompía algo; la suite lo detecta antes de que lo vea el usuario.
- **Local primero:** el prototipo funciona sin conexión (SQLite local, JSON de contenido). *Por qué:* un taller real no siempre tiene red, y la demo no debe depender de ella. Solo Faro, el agente de IA, necesita internet, y sin él la app usa un respaldo (ver la sección 4).

## 3. Tecnología
- **Godot 4.7.2** (GDScript, renderer de compatibilidad): ligero, gratuito, exporta a escritorio y web.
- **SQLite (godot-sqlite)** para intentos, progreso y reloj simulado.
- **Contenido en JSON** (banco de preguntas y escenarios). *Por qué:* sustituir el contenido de muestra por el oficial de Volvo sin tocar código.
- **Microsoft Foundry:** el agente **Faro** y una base de conocimiento con los 8 manuales de Volvo en PDF (Azure AI Search sobre un contenedor privado). *Por qué:* la ruta y los materiales deben apoyarse en documentos reales y citarlos.
- **Python estándar** (sin dependencias) para la página de materiales de estudio.
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

### Faro: la IA con control
- **Faro** es un agente de Foundry con acceso a los manuales de Volvo. Propone el orden de la ruta, explica cada tema y cita el PDF de donde sale.
- **La app decide si acepta la respuesta:** valida el formato, descarta fuentes que no vinieron en la misma respuesta y ordenes que no existen. A Faro solo llega un seudónimo del técnico, nunca su nombre ni su contraseña.
- **Sin internet o sin IA** la ruta sale como "Ruta calculada sin IA", con el orden que calcula la propia app, y se reutiliza la última ruta generada. *Por qué:* la IA ayuda, pero la demo y el taller no dependen de ella.
- **Ruta como mapa** (roadmap) con estados Primero, Hoy, Después y Hecho, y un panel de detalle con el motivo de cada tema.
- **Banco de 57 ítems** depurado, sin repetidos ni preguntas sin sentido, con un subconjunto distinto por técnico para que no se copien ni repitan.

### Cuentas y roles
- **Ingreso con usuario y contraseña** y tres roles: técnico, jefe directo y administración. *Por qué:* el tablero y los materiales deben mostrar cosas distintas según quién entra.
- Contraseñas con PBKDF2-HMAC-SHA256, espera tras 5 fallos y mensaje genérico. Solo la administración crea cuentas y la contraseña inicial es temporal.
- **Los permisos se aplican en la lógica**, no solo escondiendo botones: un técnico no puede listar a otros ni exportar, y la exportación nunca incluye las columnas de contraseña.
- **Botones "Entrar con"** para cuentas de demostración, solo si el `.env` local lo habilita.

### Secuencia de entrenamiento
- **Antes del diagnóstico** solo está abierto el diagnóstico. Después se abren la ruta, la práctica y los materiales.
- **Niveles por dominio:** las órdenes se abren por competencia. Fácil siempre, Media desde 50 de dominio y Difícil desde 75. Cada orden bien resuelta sube el dominio. *Por qué:* un técnico con poca base no debe saltar a un caso difícil, y avanzar tiene que sentirse como un logro.

### EPP: el primer paso de cada tarea
El técnico camina a un casillero del taller, escoge y se pone el equipo de protección antes de tocar el autobús. El equipo exigido cambia con la tarea (alto voltaje, trabajo bajo el autobús, faros, banco) y se mezcla con piezas que no hacen falta. Sin el EPP completo el motor rechaza cualquier paso, y el intento queda registrado para el tablero. *Por qué:* la seguridad es el primer paso del procedimiento, no un trámite. Los modelos son formas simples hechas en código; los requisitos son criterio didáctico hasta que Volvo los valide.

### Materiales de estudio
Página local (Python) con 11 formatos: tarjetas, presentación, infografía y ocho juegos (quiz, pareo, ordena los pasos, ahorcado, verdadero o falso, completa la frase, clasifica y caso de falla). Faro los genera con los manuales y quedan como **borrador** hasta que un jefe directo o la administración los **publica**. El técnico solo ve lo publicado y recibe primero lo que le toca según su ruta y su nivel. Hay 18 borradores listos para revisar. *Por qué:* contenido de alto voltaje generado con IA no debe llegar al técnico sin una revisión humana.

### Sonido
Efectos sintetizados en código (clics, aciertos, errores, falta crítica, EPP, elevador). La tecla M los silencia. *Por qué:* sin archivos de audio no hay licencias que atribuir.

### Tablero y resumen
Tablero **por rol**: el técnico ve su propio avance, el jefe directo ve al equipo con una recomendación y la evidencia por técnico, y la administración ve el estado del sistema y del contenido. Incluye gráficas tipo dashboard (dominio por competencia, pre, post y retest, línea por sesión, errores por tipo y comparación del equipo), ganancia, retención, errores recurrentes y brechas, y exportación CSV/JSON solo para quien tiene permiso. Resumen de cada orden con paso a paso, tiempo y reflexión. Línea de aprobación de 91, tomada de los cursos de Volvo. *Por qué:* reemplaza el seguimiento manual y da evidencia al jefe directo.

### Menú y experiencia
Pantalla de ingreso sobre la foto del taller, menú con tarjetas, paleta y tipografía propias y recorrido Diagnóstico → Ruta → Práctica → Post → Retest, con los materiales justo después de la práctica. El modo demo se quitó del menú. Exportación web y recorrido automático con Playwright.

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
| Al añadir el ingreso se rehízo todo el diseño del menú | Una tarea grande sin límite de alcance | Se restauró el diseño original y se insertó el ingreso con cambios mínimos |
| La exportación habría filtrado las contraseñas | La consulta leía todas las columnas de la cuenta | Columnas explícitas y una prueba que lo vigila |
| El subconjunto de preguntas por técnico no cambiaba el orden | El hash simple conservaba el orden | Se pasó a SHA-256 con el id del técnico |
| El técnico no veía los juegos nuevos en la página de materiales | El servidor seguía corriendo con el código anterior | Se reinició el servidor |

## 6. Lo que dijo Volvo y qué cambió
Ver `docs/respuestas-volvo.md`. Se mantienen tres niveles simplificados, el circuito de aislamiento, el arnés y el aprendizaje adaptativo. Cambia el enfoque: evaluar el **procedimiento** y mostrar el avance como **recomendación**, porque lo decide el jefe directo. Cobertura actual: tres de las cinco categorías de falla que Volvo mencionó (directa en electrónica y arneses, parcial en batería).

## 7. Pendiente
- **T-165:** evidencia y errores por oportunidad en el tablero.
- **T-160:** el resumen evalúa el orden de los pasos y los omitidos, no solo el resultado.
- **Plan de la reunión sin hacer:** modos Guiado, Normal y Experto con tiempo, diagramas de flujo, cámara en tercera persona, servicios básicos de posventa, conectividad (VPN y perfiles de documentación) y reporte en PDF.
- **EPP:** casillero con modelos más detallados (hoy son formas simples) y validar con Volvo qué equipo exige cada tarea.
- **Materiales:** que jefe directo o administración revisen y publiquen los 18 borradores; hasta entonces el técnico no recibe nada asignado.
- **T-129, T-130, T-131, T-133, T-134:** más órdenes eléctricas, catálogo, recorrido web del taller, línea de aprobación en el tablero y extras de Tech Tool.
- **Humanas:** T-166 (prueba en mesa con el ESP32 real), validar escenarios con Volvo y confirmar si su documentación técnica es confidencial antes de subirla a GitHub o a Azure.
- **Ideas aparte:** paso de predicción antes de medir, diferido con variante práctica, rúbrica de cuatro criterios, mentor de voz local, y actualizar el ejecutable de Windows.

## 8. Qué mostrar al jurado
Una sola sesión completa: qué sabía el técnico al entrar, en qué paso se equivocó, qué práctica recibió y si después resolvió otra falla por su cuenta. La pregunta guía: *cuando el módulo deja de responder, ¿el técnico puede demostrar con dos mediciones dónde está la falla?*

## 9. Limitaciones que declaramos
- Los valores técnicos y las preguntas son de **muestra** hasta recibir material oficial de Volvo.
- La retención se **simula** adelantando el reloj; la real exige tiempo real.
- El prototipo no está integrado con Tech Tool ni con otros sistemas de Volvo.
- Un puntaje del simulador no equivale a una certificación Volvo.
- **Faro necesita internet.** Sin conexión, la ruta usa el respaldo sin IA y los formatos de material que exigen IA no se generan.
- **Los usuarios y las contraseñas son locales.** La base SQLite no está cifrada: el hash protege contra el uso casual, no contra quien edite el archivo. El control real llega con un servidor central y VPN.
- Los umbrales de niveles (50 y 75) y el EPP por tarea son propuestas del equipo, pendientes de validar con Volvo.
- Los botones "Entrar con" existen solo en equipos de demostración con el `.env` habilitado.
