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
- Dominio 0–100 por competencia = promedio ponderado de los últimos 10 intentos; el peso sube con la dificultad.
- Falta crítica: −15 directo. Brecha diagnóstico-vs-acción: −5.
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
- RF-11: CUANDO ocurre una falta crítica, EL SISTEMA coloca esa competencia en primer lugar de la ruta hasta que se repita correctamente.
- RF-12: EL SISTEMA aplica repetición espaciada Leitner de 3 cajas: el ítem fallado entra a la caja 1; acertar sube de caja; fallar vuelve a la 1; intervalos 1, 3 y 7 días.
- RF-13: CUANDO se pulsa "adelantar reloj", EL SISTEMA avanza el tiempo simulado y muestra que es simulado.
- RF-14: DONDE el banco lo permita, EL SISTEMA presenta una variante del ítem repetido.
- RF-15: EL SISTEMA aplica pre-test (diagnóstico), post-test (8 teóricas + 2 prácticas con ítems distintos) y retest diferido simulado a 7 días (mismo formato, ítems ya vistos).
- RF-16: EL SISTEMA calcula ganancia = dominio post − dominio pre, y retención = dominio retest ÷ dominio post × 100, por competencia.
- RF-17: CUANDO el técnico marca una causa o acción en pantalla y ejecuta otra en el panel, EL SISTEMA registra una brecha `diagnostico-vs-accion` con competencia y caso, y resta 5 puntos al dominio.
- RF-18: SI hay dos brechas en la misma competencia en una sesión, ENTONCES EL SISTEMA la sube al primer lugar de la ruta.
- RF-19: EL SISTEMA registra por cada evento: alias del técnico, competencia, ítem, respuesta, tiempo, resultado, tipo de error y versión del contenido.
- RF-20: EL SISTEMA entrega a `tablero` dominio, nivel, confianza, ganancia, retención, conteo de brechas y errores recurrentes por competencia.
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
- Registro corrupto: error claro, sin pérdida de los demás técnicos.

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
