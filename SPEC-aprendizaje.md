# Spec 002 — aprendizaje

## Contexto y objetivo
Calcula el dominio por competencia, aplica el diagnóstico inicial, arma la ruta adaptativa, programa la repetición espaciada, evalúa antes/después/diferida y mide la brecha entre diagnóstico y ejecución. Consume el banco de `competencias` y entrega indicadores a `tablero`.

## Usuarios / actores
- Técnico: hace el diagnóstico, sigue la ruta y las evaluaciones.
- Instructor: revisa resultados en `tablero`.
- Módulos: `competencias` (ítems), `simulador` y `panel` (resultados de práctica), `tablero` (indicadores).

## Historias de usuario
- H1: Como técnico quiero un diagnóstico que mida lo que sé y lo que hago para saber dónde estoy.
- H2: Como técnico quiero una ruta que priorice mis brechas para practicar lo más importante primero.
- H3: Como instructor quiero ver ganancia, retención y recurrencia de errores para saber si el entrenamiento funciona.

## Modelo de dominio
- Valor de un intento: pregunta = 100 si es correcta y 0 si no; escenario o caso = su puntaje 0–100 (`simulador` RF-17).
- Peso de un intento: fácil 1, media 2, difícil 3; las tareas prácticas multiplican por 2.
- Dominio 0–100 por competencia = promedio ponderado de los últimos 10 intentos; limitado a 0–100.
- Pre, post y retest son instantáneas: el dominio de cada uno se calcula solo con los ítems de esa evaluación. La ganancia es indicativa porque el diagnóstico tiene pocos ítems por competencia, y se declara.
- Falta crítica: se registra como un intento de valor 0 y peso 3. Brecha diagnóstico-vs-acción: intento de valor 0 y peso 1. Ambos entran a la ventana de 10 intentos.
- Niveles: Novato (<40), Básico (40–69), Competente (70–89), Experto (≥90).
- Competencia aprobada: nivel Competente o superior y sin falta crítica reciente.
- Confianza por competencia: `baja` (solo teoría) o `alta` (teoría y práctica).

## Requisitos funcionales (EARS)
- RF-1: EL SISTEMA calcula el dominio de cada competencia como promedio ponderado de los últimos 10 intentos, con peso creciente según dificultad.
- RF-2: EL SISTEMA asigna nivel (Novato, Básico, Competente, Experto) según los umbrales del modelo.
- RF-3: CUANDO el técnico completa una tarea práctica, EL SISTEMA le da el doble de peso que a una pregunta teórica.
- RF-4: CUANDO un técnico nuevo inicia, EL SISTEMA aplica un diagnóstico de 8 preguntas de opción múltiple (2 por competencia, una media y una difícil) y 2 tareas prácticas (1 `accion-panel` de seguridad y 1 `caso-diagnostico`).
- RF-5: MIENTRAS el diagnóstico está en curso, SI el técnico falla la pregunta media de una competencia, ENTONCES EL SISTEMA reemplaza la difícil por una fácil.
- RF-6: AL terminar el diagnóstico, EL SISTEMA entrega dominio, nivel y confianza por competencia.
- RF-7: EL SISTEMA no reutiliza en el post-test ítems del diagnóstico.
- RF-8: CUANDO se arma la ruta, EL SISTEMA ordena las competencias por (100 − dominio) × peso de seguridad (2 para `seguridad-alto-voltaje`, 1 para las demás).
- RF-9: EL SISTEMA ofrece sesiones de 3 micro-lecciones (3 a 5 min) sobre las dos competencias de mayor prioridad, cada una con una explicación corta con fuente y 2 ítems de práctica.
- RF-10: AL terminar una sesión, EL SISTEMA recalcula dominio y ruta.
- RF-11: CUANDO ocurre una falta crítica, EL SISTEMA coloca esa competencia en primer lugar de la ruta hasta que el técnico acierte un ítem de esa competencia; "falta crítica reciente" son las últimas 3 sesiones. Prioridad: falta crítica, luego dos brechas (RF-18), luego la fórmula del RF-8; el empate lo gana el menor dominio.
- RF-12: EL SISTEMA aplica repetición espaciada Leitner de 3 cajas: el ítem fallado entra a la caja 1; acertar sube de caja; fallar vuelve a la 1; intervalos 1, 3 y 7 días.
- RF-13: CUANDO se pulsa "adelantar reloj", EL SISTEMA avanza el tiempo simulado y muestra que es simulado. El botón está en el menú de demo, el reloj se guarda entre ejecuciones y "Restablecer demo" lo reinicia.
- RF-14: DONDE el banco lo permita, EL SISTEMA presenta una variante del ítem repetido.
- RF-15: EL SISTEMA aplica pre-test (diagnóstico), post-test (8 teóricas + 2 prácticas con ítems distintos) y retest diferido simulado a 7 días (mismo formato, con los ítems del post-test). La práctica de la ruta puede repetir ítems por Leitner; pre y post no.
- RF-16: EL SISTEMA calcula ganancia = dominio post − dominio pre, y retención = dominio retest ÷ dominio post × 100, por competencia, con tope de 100. SI el dominio post es 0, ENTONCES la retención es "no calculable".
- RF-17: CUANDO `simulador` envía una brecha `diagnostico-vs-accion`, EL SISTEMA la registra con competencia y caso, y la cuenta como un intento de valor 0 y peso 1.
- RF-21: ANTES de la primera pregunta del diagnóstico y de la ruta, EL SISTEMA explica qué mide la actividad, cuántas preguntas tiene y cuánto dura; DESPUÉS de cada pregunta de opción múltiple muestra si la respuesta anterior fue correcta y, si no, cuál era; AL terminar muestra el dominio de cada competencia con una barra de color, el nivel, la confianza en palabras y "Empieza por" la competencia más baja.
- RF-22: CADA intento guarda `sesion`, `caso`, `variante`, `numero_intento` y `ayudas`; EL SISTEMA agrupa los puntos de la curva por sesión y competencia, y las bases anteriores se migran sin perder intentos.
- RF-23: DONDE exista un servicio Foundry configurado y haya conexión, EL SISTEMA pide a la IA que ordene la ruta y explique cada tema según el diagnóstico, enviando solo un identificador seudónimo, dominios, errores y el catálogo permitido de órdenes; la respuesta usa un esquema fijo, EL SISTEMA la valida (ids del catálogo, cuatro competencias, seguridad o falta crítica primero, textos cortos) y la guarda para reproducirla sin conexión.
- RF-24: SI no hay configuración, conexión o respuesta válida en 8 s, ENTONCES EL SISTEMA usa la ruta calculada por reglas y lo indica con "Ruta calculada sin IA". La IA nunca crea preguntas, valores técnicos ni dominio.
- RF-25: AL abrir la ruta, EL SISTEMA muestra «Tu ruta», la competencia por la que se empieza, el origen y una leyenda de estados. Las competencias siguen el orden de RF-11 en un camino numerado con flechas. Cada nodo muestra su porcentaje y barra de dominio, y usa el relleno de su estado. «Primero» señala una falta crítica pendiente, «Hecho» indica que la competencia está aprobada, «Hoy» indica que está en el plan de hoy y «Después» cubre los demás casos. Cada rama muestra hasta tres fichas de contenido. A la izquierda aparecen los errores con su conteo. A la derecha aparecen los temas sugeridos y luego las órdenes del taller. Si quedan elementos, «+N más» abre el detalle de la competencia. Las citas, el refuerzo y las marcas didácticas se consultan en el panel. Las cuatro competencias caben a 1920 × 1080. A 1280 × 720 se admite desplazamiento vertical. «Continuar» y el indicador de paso permanecen visibles en el pie fijo.
- RF-26: AL activar un nodo o una ficha con clic, Enter o Espacio, EL SISTEMA abre o actualiza el panel a la derecha. Los nodos muestran foco blanco visible, resaltado al pasar el ratón y cursor de mano. El panel tiene un borde izquierdo del color del estado de la competencia. «Cerrar» o Escape cierran el panel y devuelven el foco a la tarjeta activada. El panel muestra el detalle de la competencia, del error, del tema o de la orden. Para los errores muestra qué pasó, cómo evitarlo y los datos de los intentos disponibles en el historial y el banco. Desde una competencia se abre el catálogo filtrado y desde una orden se puede abrir su práctica. Al volver del taller se retoma la ruta.
- RF-27: LA ruta se presenta solo como mapa, sin preguntas. EL SISTEMA no pide las seis preguntas de práctica en la ruta: el botón «Continuar» cierra el paso y habilita el escenario. La práctica ocurre en las órdenes del taller que abre cada nodo (RF-26). Esto sustituye la práctica de seis preguntas de RF-15 y el recálculo por sesión de RF-10 en este paso; el pre-test, el post-test y el retest no cambian.
- RF-18: SI hay dos brechas en la misma competencia en una sesión, ENTONCES EL SISTEMA la sube al primer lugar de la ruta.
- RF-19: EL SISTEMA registra por cada evento: alias del técnico, competencia, ítem, respuesta, tiempo, resultado, tipo de error y versión del contenido.
- RF-20: EL SISTEMA entrega a `tablero` dominio, nivel, confianza, ganancia, retención, conteo de brechas, errores recurrentes (mismo tipo 3 o más veces), faltas críticas con fecha, tiempo promedio por acción y avance de la ruta por competencia.
- RF-21: EL SISTEMA funciona sin conexión a internet.

## Requisitos no funcionales
- Datos locales, con alias en lugar de datos personales.
- Fórmulas implementadas tal cual están escritas aquí, para poder explicarlas al jurado.
- Español.

## Casos límite
- Técnico sin intentos previos: dominio inicial viene del diagnóstico.
- Competencia sin práctica disponible (2 y 4): confianza `baja`.
- Banco sin ítems suficientes para post-test o retest: se avisa y se permite reutilizar ítems marcando que no son equivalentes.
- Reloj adelantado hacia atrás: no permitido.
- Registro corrupto: error claro, se aísla el registro dañado y se restaura la copia de respaldo; no se pierden los demás técnicos.

## Fuera de alcance
- Contenido de ítems y fuentes (`competencias`).
- Escena 3D, árbol interactivo y panel físico (`simulador`, `panel`).
- Gráficas y vistas (`tablero`).
- IA generativa, Elo/IRT, otros idiomas y competencia diésel.

## Criterios de finalización
- Todos los RF con prueba (automática para fórmulas y ruta; checklist manual para el flujo con panel) en verde.
- Demo manual del flujo completo: diagnóstico, ruta, adelantar reloj, post-test, retest y tablero con datos.

## Dudas abiertas
- [NECESITA ACLARACIÓN] Dominio inicial exacto cuando el diagnóstico solo tiene 2 ítems teóricos por competencia (¿es suficiente confianza?).
- [NECESITA ACLARACIÓN] Cantidad real de ítems disponibles para evitar repetirlos entre diagnóstico, post y retest (depende de `competencias`).
