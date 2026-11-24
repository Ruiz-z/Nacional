# Spec 004 — tablero

## Contexto y objetivo
Muestra el avance, dominio, errores y retención de cada técnico, con trazabilidad de resultados. Es el módulo de visualización: no calcula dominio ni ruta, los toma de `aprendizaje` y `simulador`. Guarda los datos en SQLite local y ofrece un asistente LLM con RAG como extra opcional.

## Usuarios / actores
- Técnico: ve su avance y qué practicar.
- Instructor: revisa a todos los técnicos y su detalle.
- Módulos: `aprendizaje` (indicadores), `simulador` (eventos), `competencias` (fuentes).

## Historias de usuario
- H1: Como técnico quiero ver mi dominio y mis errores repetidos para saber qué practicar.
- H2: Como instructor quiero comparar técnicos y ver ganancia y retención para saber si el entrenamiento funciona.
- H3: Como jurado quiero ver la fórmula y la fuente de cada indicador para confiar en los números.
- H4: Como técnico quiero preguntarle a un asistente por qué fallé, con respuestas respaldadas por fuentes.

## Vistas
- Técnico: dominio y nivel por competencia, ruta pendiente, última sesión, errores que repite, intento actual frente al anterior.
- Instructor: lista de técnicos con dominio por competencia, ganancia, retención, errores recurrentes y brechas; detalle con línea de tiempo.
- Cambio de vista desde un menú; sin contraseña en la demo.
- Datos de demostración: un técnico ficticio con historial, marcado `[DEMO]`.

## Indicadores (lista cerrada)
1. Dominio y nivel por competencia.
2. Confianza por competencia (baja o alta).
3. Ganancia = post − pre.
4. Retención = retest ÷ post × 100 (marcada como simulada).
5. Errores recurrentes: mismo tipo de error 3 o más veces en una competencia.
6. Brechas diagnóstico-vs-acción: conteo por competencia y evolución pre/post/retest.
7. Faltas críticas: conteo y fecha de la última.
8. Tiempo promedio por acción por escenario.
9. Avance de la ruta: micro-lecciones completadas frente a pendientes.

## Requisitos funcionales (EARS)
- RF-1: EL SISTEMA define el esquema único de la base SQLite local (en `docs/modelo-datos.md`) y guarda en ella técnico (alias), competencia, ítem, respuesta, tiempo, resultado, tipo de error, evento, fuente y versión de contenido; `aprendizaje` y `simulador` escriben mediante ese esquema.
- RF-2: CUANDO `aprendizaje` o `simulador` entregan resultados, EL SISTEMA los guarda sin recalcular dominio ni ruta.
- RF-3: EL SISTEMA ofrece la vista del técnico y la vista del instructor con cambio desde un menú.
- RF-4: EL SISTEMA muestra los 9 indicadores de la lista según la vista.
- RF-5: CUANDO el usuario pide ayuda de un indicador, EL SISTEMA muestra su fórmula.
- RF-6: EL SISTEMA muestra el dominio por competencia con barras horizontales y el nivel marcado.
- RF-7: EL SISTEMA muestra pre, post y retest agrupados por competencia, con el retest etiquetado "simulado".
- RF-8: EL SISTEMA muestra ganancia y retención con valor y flecha de tendencia.
- RF-9: EL SISTEMA muestra errores recurrentes y brechas en una lista con tipo de error y caso.
- RF-10: EL SISTEMA muestra una línea de tiempo de dominio por sesión y competencia.
- RF-11: EL SISTEMA usa color solo para estado (rojo, ámbar, verde) y siempre acompañado de texto o icono.
- RF-12: CUANDO se abre un técnico en la vista del instructor, EL SISTEMA muestra su historial con evento, ítem, fuente y versión.
- RF-13: EL SISTEMA exporta los resultados de un técnico o de todos a CSV y JSON con fecha y versión del contenido.
- RF-14: CUANDO el usuario elige borrar un técnico, EL SISTEMA elimina sus datos tras confirmación.
- RF-15: EL SISTEMA marca los datos de demostración con `[DEMO]` y los distingue de los reales.
- RF-16: EL SISTEMA precarga un técnico ficticio con historial al iniciar en modo demo.
- RF-17: EL SISTEMA funciona sin conexión a internet.
- RF-18: DONDE exista un modelo LLM disponible, EL SISTEMA ofrece un asistente que explica errores, resume progreso, sugiere qué practicar y responde dudas de procedimiento.
- RF-19: CUANDO el asistente responde, EL SISTEMA se basa solo en las fuentes permitidas y en el historial del técnico, y cita la fuente.
- RF-20: SI el asistente no encuentra respaldo, ENTONCES EL SISTEMA responde "no tengo esa información".
- RF-21: EL SISTEMA no permite que el asistente cree ítems, cambie dominio o ruta, ni dé valores técnicos fuera de las fuentes.
- RF-22: SI no hay conexión o modelo, ENTONCES EL SISTEMA desactiva el asistente con el aviso "Asistente no disponible" y el resto del tablero sigue funcionando.
- RF-23: EL SISTEMA envía al asistente solo datos con alias, nunca nombres.

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
- [NECESITA ACLARACIÓN] Si la vista del instructor necesitará protección más adelante.
