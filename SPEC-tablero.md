# Spec 004 — tablero

## Contexto y objetivo
Muestra el avance, dominio, errores y retención de cada técnico, con trazabilidad de resultados. Es el módulo de visualización: no calcula dominio ni ruta, los toma de `aprendizaje` y `simulador`. Guarda los datos en SQLite local y ofrece un asistente LLM con RAG como extra opcional.

## Usuarios / actores
- Técnico: ve su avance y qué practicar.
- Jefe directo: revisa la evidencia de cada técnico y decide su avance.
- Módulos: `aprendizaje` (indicadores), `simulador` (eventos), `competencias` (fuentes).

## Historias de usuario
- H1: Como técnico quiero ver mi dominio y mis errores repetidos para saber qué practicar.
- H2: Como jefe directo quiero priorizar a los técnicos que necesitan apoyo y revisar su evidencia antes de decidir el avance.
- H3: Como jurado quiero ver la fórmula y la fuente de cada indicador para confiar en los números.
- H4: Como técnico quiero preguntarle a un asistente por qué fallé, con respuestas respaldadas por fuentes.

## Vistas
- Técnico: dominio y nivel por competencia, ruta pendiente, última sesión, errores que repite, intento actual frente al anterior.
- Jefe directo: lista de técnicos ordenada por atención y fichas con recomendación, respaldo y detalle del historial.
- Cambio de vista desde un menú; sin contraseña en la demo.
- Datos de demostración: un técnico ficticio con historial, marcado `[DEMO]`.

## Indicadores
1. Dominio y nivel por competencia.
2. Confianza por competencia (baja o alta).
3. Ganancia = post − pre.
4. Retención = retest ÷ post × 100 (marcada como simulada).
5. Errores recurrentes: mismo tipo de error 3 o más veces en una competencia.
6. Brechas diagnóstico-vs-acción: conteo por competencia y evolución pre/post/retest.
7. Faltas críticas: conteo y fecha de la última.
8. Tiempo promedio por acción por escenario.
9. Avance de la ruta: microlecciones completadas frente a pendientes.
10. Evidencia por competencia: teoría, prácticas virtuales, casos con banco, errores por oportunidad e intentos sin ayuda.

## Requisitos funcionales (EARS)
- RF-1: EL SISTEMA define el esquema único de la base SQLite local (en `docs/modelo-datos.md`) y guarda en ella técnico (usuario, guardado en alias), competencia, ítem, respuesta, tiempo, resultado, tipo de error, evento, fuente y versión de contenido; `aprendizaje` y `simulador` escriben mediante ese esquema.
- RF-2: CUANDO `aprendizaje` o `simulador` entregan resultados, EL SISTEMA los guarda sin recalcular dominio ni ruta.
- RF-3: EL SISTEMA abre la vista personal para el técnico, la de equipo para el jefe directo y la operativa para el administrador. El técnico solo ve sus datos. El administrador consulta también las dos vistas de progreso en modo lectura. La vista operativa muestra cuentas por rol, heredadas, actividad de técnicos, revisión por Volvo, respaldo y configuración de IA.
- RF-4: EL SISTEMA muestra los indicadores de la lista según la vista.
- RF-5: CUANDO el usuario pide ayuda de un indicador, EL SISTEMA muestra su fórmula.
- RF-6: EL SISTEMA muestra el dominio por competencia con barras horizontales y el nivel marcado.
- RF-7: EL SISTEMA muestra pre, post y retest agrupados por competencia, con el retest etiquetado "simulado".
- RF-8: EL SISTEMA muestra ganancia y retención con valor y flecha de tendencia.
- RF-9: EL SISTEMA muestra errores recurrentes y brechas en una lista con tipo de error y caso.
- RF-10: EL SISTEMA muestra una línea de tiempo de dominio por sesión y competencia.
- RF-11: EL SISTEMA usa rojo, ámbar y verde para estados con texto o marca. Las gráficas usan tonos de una misma familia para magnitud y colores fijos para identificar series con leyenda y etiquetas.
- RF-12: CUANDO se abre un técnico en la vista «Jefe directo», EL SISTEMA muestra su historial con evento, ítem, fuente y versión.
- RF-13: EL SISTEMA exporta los resultados de un técnico o de todos a CSV y JSON con fecha y versión del contenido.
- RF-14: CUANDO el administrador confirma el borrado de una cuenta en Administración, EL SISTEMA elimina la cuenta y sus datos asociados. Protege la cuenta propia y la última cuenta de administración activa.
- RF-15: EL SISTEMA marca los datos de demostración con `[DEMO]` y los distingue de los reales.
- RF-16: EL SISTEMA precarga un técnico ficticio con historial al iniciar en modo demo.
- RF-17: EL SISTEMA funciona sin conexión a internet.
- RF-18: DONDE exista un modelo LLM disponible, EL SISTEMA ofrece un asistente que explica errores, resume progreso, sugiere qué practicar y responde dudas de procedimiento.
- RF-19: CUANDO el asistente responde, EL SISTEMA se basa solo en las fuentes permitidas y en el historial del técnico, y cita la fuente.
- RF-20: SI el asistente no encuentra respaldo, ENTONCES EL SISTEMA responde "no tengo esa información".
- RF-21: EL SISTEMA no permite que el asistente cree ítems, cambie dominio, ni dé valores técnicos fuera de las fuentes; la ruta solo puede proponerla dentro del catálogo y validada (SPEC-aprendizaje RF-23).
- RF-22: SI no hay conexión o modelo, ENTONCES EL SISTEMA desactiva el asistente con el aviso "Asistente no disponible" y el resto del tablero sigue funcionando.
- RF-23: EL SISTEMA envía al asistente solo datos con alias, nunca nombres.
- RF-24: CUANDO se abre una ficha de «Jefe directo», EL SISTEMA resume la evidencia guardada por competencia. Una oportunidad es una respuesta o intento de práctica registrado. Los detalles de una práctica y las brechas se consultan aparte. Cuenta los intentos incorrectos sobre las oportunidades y los intentos con `ayudas = 0`. Identifica las prácticas virtuales y los casos con banco mediante la fuente de entrada. También reconoce el banco cuando un evento de medición se puede asociar con una sola sesión del caso y fecha. El panel físico por sí solo no acredita banco de arnés. Si falta evidencia, los conteos se quedan en cero. Los tiempos usan el promedio de las acciones registradas con duración y competencia identificables.
- RF-25: CUANDO se abre una ficha, EL SISTEMA muestra una recomendación con la evidencia que la respalda y el pie «Es una recomendación. La decisión de avance es del jefe directo.». Prioriza una falta crítica pendiente, luego una competencia por debajo de 70 % con un error que se repite al menos tres veces. Para recomendar práctica supervisada, las cuatro competencias deben estar aprobadas según SPEC-aprendizaje. Con resultados faltantes o alertas restantes, señala qué falta completar o revisar. La vista «Técnico» conserva su lenguaje.
- RF-26: CUANDO se abre «Jefe directo», EL SISTEMA muestra una fila por alias con estado textual y color, cuatro barras de nivel y fecha de última actividad. Ordena por estado en este orden: «Con falta crítica», «Con alertas», «Sin completar», «Sin alertas». CUANDO se abre una ficha, muestra la recomendación con respaldo debajo de las gráficas, luego evidencia por competencia, faltas críticas con fecha, ganancia, retención con el retest marcado como simulado, ruta pendiente e historial. «Volver a la lista» queda visible al desplazar la ficha. El jefe directo conserva acceso a «Exportar». La exportación de la ficha usa el alias abierto y permite elegir CSV o JSON.

- RF-27: CUANDO se abre la vista personal, EL SISTEMA muestra cuatro fichas compactas y gráficas de dominio por competencia con mínimo de 70 %, comparación de Pre, Post y Retest simulado, dominio por sesión y errores por tipo. El técnico solo recibe su propio historial. La ficha del jefe directo usa las mismas gráficas para el alias seleccionado.
- RF-28: CUANDO se abre la vista de equipo, EL SISTEMA muestra conteos por estado, un mapa de calor ordenado por la prioridad de RF-26, una barra apilada de estados y errores del equipo por tipo. La lista y las acciones de la ficha permanecen disponibles debajo.
- RF-29: CUANDO se abre «Estado del taller», EL SISTEMA muestra intentos y última actividad por técnico, distribución de cuentas por rol y un medidor de revisión de preguntas. Muestra los estados de respaldo e IA con texto.
- RF-30: CADA gráfica identifica qué se está midiendo y ofrece un valor al señalar una marca. Tab enfoca la gráfica y las flechas recorren sus marcas. «Ver como tabla» alterna al mismo conjunto de datos con encabezados. Si faltan datos, EL SISTEMA muestra cómo obtenerlos en el lugar de la gráfica.

## Requisitos no funcionales
- SQLite como almacenamiento; CSV y JSON solo para exportar.
- Texto grande y lenguaje de taller; pantalla de laptop.
- Español.
- El asistente es opcional: la demo no depende de él.

## Casos límite
- Técnico sin sesiones: vistas vacías con mensaje claro, sin errores.
- Base de datos ausente: se crea una nueva y se avisa. Corrupta: se restaura la copia de respaldo automática; si no hay, se aísla el registro dañado y se avisa. Nunca se borran los datos de los demás técnicos.
- Indicador sin datos (por ejemplo, retest pendiente): se muestra "pendiente", no cero.
- Dos técnicos con el mismo alias: se rechaza.
- Exportación con muchos datos: no bloquea la interfaz.

## Fuera de alcance
- Cálculo de dominio, ruta y repetición espaciada (`aprendizaje`).
- Contenido y fuentes de los ítems (`competencias`).
- Escena 3D y escenarios (`simulador`).
- Servidor, nube, cuentas con contraseña real y sincronización entre dispositivos.
- Que el LLM genere ítems o cambie dominio o ruta.
- Otros idiomas.

## Criterios de finalización
- Todos los RF con prueba (automática para consultas, fórmulas y exportación; checklist manual para vistas y asistente) en verde.
- Demo manual: cambiar de vista, abrir el técnico ficticio, ver la fórmula de un indicador, exportar y, si hay modelo, hacer una pregunta con fuente.

## Dudas abiertas
- [NECESITA ACLARACIÓN] Qué modelo LLM local se usará y si la laptop de la demo puede ejecutarlo.
- [NECESITA ACLARACIÓN] Cómo se indexan las fuentes para el RAG (formato y volumen de los documentos).
- [NECESITA ACLARACIÓN] Si la vista «Jefe directo» necesitará protección más adelante.
