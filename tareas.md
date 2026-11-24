# Tareas

Cada tarea dura menos de 30 min, sigue el orden del plan y empieza por su prueba. Formato: `[ ] T-n — qué (RF) — Hecho cuando`. Responsable: S = sistemas, E = electrónica.

## 0. Cimientos
- [x] T-01 S — Crear proyecto Godot 4.7.2, carpetas del plan y `tests/run.gd` que ejecuta todos los `test_*.gd` y devuelve código de salida — Hecho cuando: `godot --headless --path godot -s tests/run.gd` sale con 0 y una prueba de ejemplo.
- [ ] T-02 (BLOQUEADA: sin red, ver docs/bloqueos.md) S — Probar plugin SQLite en 4.7.2 (abrir, crear tabla, leer) — Hecho cuando: una prueba lo demuestra o se documenta el fallo y la alternativa.
- [x] T-03 S — Escribir `datos/esquema` con las 7 tablas, creación y copia de respaldo (tablero RF-1) — Hecho cuando: prueba crea la BD vacía y restaura el respaldo.
- [x] T-04 S — Redactar `docs/modelo-datos.md` desde el esquema — Hecho cuando: lista tablas y campos como el plan.
- [ ] T-05 S+E — Prueba de humo serial de 30 min (plugin o puente Python) — Hecho cuando: un botón enciende un LED y se registra la decisión en `panel`.

## 1. competencias
- [x] T-06 S — Definir formato JSON del banco y 4 competencias con id (RF-1, 2) — Hecho cuando: archivo de ejemplo con campos comunes.
- [x] T-07 S — Cargador y validador: competencia, formato, fuente, versión, id duplicado, JSON corrupto (RF-3, 4) — Hecho cuando: pruebas rechazan cada caso con id y archivo.
- [x] T-08 S — Lista de fuentes permitidas y fuente `[MUESTRA]` (RF-4, 5) — Hecho cuando: prueba acepta `[MUESTRA]` solo en ítems no de seguridad.
- [x] T-09 S — Validador de `caso-diagnostico` (ruta ideal, tipos de error) y `accion-panel` (RF-10, 11) — Hecho cuando: un caso sin ruta ideal se rechaza.
- [x] T-10 S — Consulta por competencia y dificultad (RF-12, 13) — Hecho cuando: solo devuelve ítems válidos y expone la fuente.
- [x] T-11 S — `tools/validar_contenido` desde la terminal (RF-14) — Hecho cuando: imprime errores o "OK".
- [ ] T-12 S+E — Redactar 8 ítems de `seguridad-alto-voltaje` con fuente — Hecho cuando: pasan el validador.
- [ ] T-13 S+E — Redactar 8 ítems de `sistema-electrico-bateria` — Hecho cuando: pasan el validador.
- [ ] T-14 S+E — Redactar 8 ítems de `diagnostico-fallas` — Hecho cuando: pasan el validador.
- [ ] T-15 S+E — Redactar 8 ítems de `electronica-conectividad` — Hecho cuando: pasan el validador.
- [ ] T-16 S+E — Redactar 2 `caso-diagnostico` y 3 `accion-panel` — Hecho cuando: pasan el validador.
- [ ] T-17 S+E — Verificación cruzada de los ítems de seguridad contra su fuente — Hecho cuando: marca de revisión en cada ítem.

## 2. aprendizaje
- [x] T-18 S — Dominio: valor, peso por dificultad, práctica ×2, ventana de 10, tope 0–100 (RF-1, 3) — Hecho cuando: pruebas con valores calculados a mano.
- [x] T-19 S — Niveles y umbrales (RF-2) — Hecho cuando: 39, 40, 69, 70, 89, 90 caen en su nivel.
- [x] T-20 S — Falta crítica y brecha como intentos de valor 0 (peso 3 y 1) — Hecho cuando: prueba muestra el efecto sobre el dominio.
- [x] T-21 S — Diagnóstico: 8 preguntas, 2 prácticas y reemplazo por fácil (RF-4, 5) — Hecho cuando: prueba cubre acierto y fallo de la media.
- [x] T-22 S — Resultado del diagnóstico: dominio, nivel y confianza (RF-6) — Hecho cuando: confianza `baja` en competencias sin práctica.
- [x] T-23 S — Ruta: orden por (100−dominio)×peso, prioridad crítica, 2 brechas y desempate (RF-8, 11, 18) — Hecho cuando: pruebas de cada regla.
- [x] T-24 S — Sesión de 3 micro-lecciones y recálculo (RF-9, 10) — Hecho cuando: prueba de sesión completa.
- [x] T-25 S — Leitner de 3 cajas (1, 3 y 7 días) (RF-12) — Hecho cuando: pruebas de subida, bajada y vencimiento.
- [x] T-26 S — Reloj simulado: adelantar, persistir, no ir atrás, restablecer (RF-13) — Hecho cuando: prueba rechaza retroceso.
- [x] T-27 S — Variante de ítem repetido (RF-14) — Hecho cuando: prueba entrega variante si existe.
- [x] T-28 S — Pre, post y retest sin repetir ítems entre pre y post (RF-7, 15) — Hecho cuando: prueba de no solapamiento y aviso si faltan ítems.
- [x] T-29 S — Ganancia y retención con tope y "no calculable" (RF-16) — Hecho cuando: pruebas con post = 0 y retención > 100.
- [x] T-30 S — Registro de eventos con todos los campos (RF-19) — Hecho cuando: fila en `intento` con los campos del plan.
- [x] T-31 S — Indicadores hacia `tablero` (RF-20) — Hecho cuando: errores recurrentes con regla de 3 o más.

## 3. simulador (motor)
- [x] T-32 S — Formato JSON de escenario y validador con archivo y campo (RF-1, 2) — Hecho cuando: pruebas de campos faltantes y estado imposible.
- [x] T-33 S — Detección de eventos circulares al validar — Hecho cuando: un ciclo se rechaza.
- [x] T-34 S — Motor: condiciones previas, efectos y rechazo con motivo (RF-3, 4) — Hecho cuando: pruebas de acción permitida y rechazada.
- [x] T-35 S — Eventos por estado y menú de recuperación (RF-5, 6, 7) — Hecho cuando: `tornillo_roto` ofrece opciones con costo, tiempo y riesgo.
- [x] T-36 S — Faltas críticas y leves (RF-8, 9) — Hecho cuando: crítica detiene y registra; leve resta y sigue.
- [x] T-37 S — Puntaje 0–100 con crédito por recuperación (RF-17) — Hecho cuando: pruebas con valores calculados.
- [x] T-38 S — Brecha causa marcada vs acción (RF-16, 24) — Hecho cuando: prueba envía la brecha y la fuente de entrada.
- [x] T-39 S — Reintento desde punto seguro y variante (RF-19) — Hecho cuando: prueba tras falta crítica.
- [x] T-40 S — Resumen: línea de tiempo, ruta ideal, comparación con intento anterior, "¿qué harías distinto?" (RF-18, 20, 21) — Hecho cuando: pruebas de la estructura devuelta.
- [x] T-41 S — Entrega de resultados a `aprendizaje` y `tablero` (RF-22) — Hecho cuando: prueba verifica los campos.
- [x] T-42 S — Escenario `[MUESTRA]` de aislamiento con 3 o 4 fallas y recuperaciones — Hecho cuando: valida y se completa en una prueba por la ruta ideal.
- [x] T-43 S — Caso corto de falla de comunicación — Hecho cuando: valida.

## 4. entrada y panel
- [x] T-44 S — Vocabulario de acciones y archivo de mapeo (entrada RF-1, 2) — Hecho cuando: prueba traduce tecla y botón a la misma acción.
- [x] T-45 S — Registro de fuente y regla de la última fuente (RF-3) — Hecho cuando: prueba con dos fuentes.
- [x] T-46 S — Parser de líneas JSON con `v`, `n`, `t`; ignora y registra errores (RF-4, 5) — Hecho cuando: pruebas de malformado, versión, control inexistente y `n` repetido.
- [x] T-47 S — Filtro de 50 ms (RF-6) — Hecho cuando: prueba con ráfaga.
- [x] T-48 S — Comparación de secuencias: `orden-incorrecto`, `paso-innecesario`, `accion-insegura` (RF-10, 11, 12) — Hecho cuando: una prueba por tipo.
- [x] T-49 S — Rango de perilla (RF-13) — Hecho cuando: prueba dentro y fuera de rango.
- [x] T-50 S — `tools/emisor_eventos` (RF-14) — Hecho cuando: reproduce una secuencia contra el simulador.
- [x] T-51 S — Latido y detección de desconexión a 3 s (RF-8) — Hecho cuando: prueba pausa y cambia a virtual.
- [ ] T-52 S — Panel virtual en pantalla con los mismos eventos y LEDs (RF-9) — Hecho cuando: demo manual de un escenario con ratón.
- [x] T-53 S — Redactar `docs/protocolo-panel.md` (RF-15) — Hecho cuando: campos, versión y ejemplos.
- [ ] T-54 E — Firmware: leer controles, filtrar rebotes, enviar JSON, latido (RF-16) — Hecho cuando: el emisor y el firmware producen líneas iguales.
- [ ] T-55 E — Firmware: recibir estado de LEDs — Hecho cuando: los 3 LEDs responden al simulador.
- [ ] T-56 E — Montar la maqueta y etiquetas — Hecho cuando: checklist manual de cada control.

## 5. simulador (escena)
- [ ] T-57 S — Escena esquemática del bus y componentes inspeccionables (RF-10, 11) — Hecho cuando: se camina y se inspecciona con el control.
- [ ] T-58 S — Menú de acciones del componente y selección de causa (RF-3, 16) — Hecho cuando: se juega el escenario con teclado y ratón (RF-12).
- [ ] T-59 S — Indicador de estado del panel y pausa por desconexión (RF-14, 15) — Hecho cuando: demo manual con cable desconectado.
- [ ] T-60 S — Pantalla de resumen y reintento — Hecho cuando: demo manual con error, recuperación y reintento.

## 6. tablero
- [x] T-61 S — Consultas de los 9 indicadores (RF-4) — Hecho cuando: pruebas con el técnico `[DEMO]`.
- [x] T-62 S — Datos `[DEMO]` precargados (RF-15, 16) — Hecho cuando: historial con pre, post y retest.
- [ ] T-63 S — Vista del técnico (RF-3, 6, 8) — Hecho cuando: demo manual.
- [ ] T-64 S — Vista del instructor y detalle con línea de tiempo (RF-7, 9, 10, 12) — Hecho cuando: demo manual.
- [ ] T-65 S — Fórmulas en ayuda, color solo con texto (RF-5, 11) — Hecho cuando: checklist manual.
- [x] T-66 S — Exportar CSV y JSON; borrar técnico con confirmación (RF-13, 14) — Hecho cuando: pruebas de contenido y de borrado.
- [x] T-67 S — Estados vacíos y "pendiente" — Hecho cuando: técnico sin sesiones sin errores.
- [x] T-68 S — Asistente: FTS5 de las fuentes, prompt y respuesta con cita, "no tengo esa información" (RF-18 a 21, 23) — Hecho cuando: prueba con pregunta con y sin respaldo.
- [x] T-69 S — Asistente desactivado sin modelo (RF-22) — Hecho cuando: aviso y el resto funciona.

## 7. flujo
- [x] T-70 S — Alias único y sin nombres reales (RF-1) — Hecho cuando: prueba de alias repetido.
- [x] T-71 S — Siguiente paso recomendado y diagnóstico obligatorio (RF-2, 3) — Hecho cuando: pruebas por estado.
- [x] T-72 S — Guardado por paso y reanudación (RF-4, 5) — Hecho cuando: prueba cierra y reabre a mitad de un paso.
- [ ] T-73 S — Menú principal navegable con teclado, control y ratón — Hecho cuando: checklist manual.
- [ ] T-74 S — Modo demo: base separada, adelantar reloj, restablecer (RF-6, 7, 8) — Lógica probada. Falta la pantalla con los controles, mostrar el estado de entrada en el menú (RF-8) y verificar la demo manual.

## 8. entrega
- [ ] T-75 S — README con instalación en 3 pasos y estructura (RF-5) — Hecho cuando: otra persona lo sigue sin ayuda.
- [ ] T-76 S — Documentación técnica y arquitectura (RF-1) — Hecho cuando: incluye cómo agregar contenido y escenarios.
- [ ] T-77 S — Propuesta de escalabilidad con diagrama actual y objetivo (RF-2) — Hecho cuando: tres fases y riesgos.
- [ ] T-78 S — Nota de privacidad y contenido (RF-3) — Hecho cuando: declara alias, datos locales, fuentes y marcas.
- [ ] T-79 S — Guion de demo con plan B (RF-4) — Hecho cuando: 5 minutos medidos.
- [ ] T-80 S — Exportar ejecutables Windows y Linux (RF-6) — Hecho cuando: corre en Linux; Windows probado o declarado no probado.
- [ ] T-81 S — Lista de dependencias y versiones (RF-8) — Hecho cuando: incluida en el paquete.
- [ ] T-82 S+E — Prueba de usabilidad con 2 ajenos y correcciones (RF-10, 11) — Hecho cuando: hallazgos con severidad y corregidos.
- [ ] T-83 S+E — Checklist de los 6 entregables (RF-12) — Hecho cuando: sin pendientes.
- [ ] T-84 S+E — Dos ensayos completos con plan B y USB de respaldo (RF-9, 13) — Hecho cuando: ambos registrados.

## Marcha paralela
Electrónica: T-05, T-54 a T-56 desde el primer día. Contenido: T-12 a T-17 en paralelo a T-18 en adelante. Sistemas: el resto en orden.
