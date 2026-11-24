# Tareas

Cada tarea dura menos de 30 min, sigue el orden del plan y empieza por su prueba. Formato: `[ ] T-n — qué (RF) — Hecho cuando`. Responsable: S = sistemas, E = electrónica.

## 0. Cimientos
- [x] T-01 S — Crear proyecto Godot 4.7.2, carpetas del plan y `tests/run.gd` que ejecuta todos los `test_*.gd` y devuelve código de salida — Hecho cuando: `godot --headless --path godot -s tests/run.gd` sale con 0 y una prueba de ejemplo.
- [x] T-02 S — Probar plugin SQLite en 4.7.2 (abrir, crear tabla, leer) — Hecho cuando: una prueba lo demuestra o se documenta el fallo y la alternativa.
- [x] T-03 S — Escribir `datos/esquema` con las 7 tablas, creación y copia de respaldo (tablero RF-1) — Hecho cuando: prueba crea la BD vacía y restaura el respaldo.
- [x] T-04 S — Redactar `docs/modelo-datos.md` desde el esquema — Hecho cuando: lista tablas y campos como el plan.
- [ ] T-05 S+E — Prueba de humo serial de 30 min (plugin o puente Python) — Hecho cuando: un botón enciende un LED y se registra la decisión en `panel`. — código listo, falta prueba en hardware

## 1. competencias
- [x] T-06 S — Definir formato JSON del banco y 4 competencias con id (RF-1, 2) — Hecho cuando: archivo de ejemplo con campos comunes.
- [x] T-07 S — Cargador y validador: competencia, formato, fuente, versión, id duplicado, JSON corrupto (RF-3, 4) — Hecho cuando: pruebas rechazan cada caso con id y archivo.
- [x] T-08 S — Lista de fuentes permitidas y fuente `[MUESTRA]` (RF-4, 5) — Hecho cuando: prueba acepta `[MUESTRA]` solo en ítems no de seguridad.
- [x] T-09 S — Validador de `caso-diagnostico` (ruta ideal, tipos de error) y `accion-panel` (RF-10, 11) — Hecho cuando: un caso sin ruta ideal se rechaza.
- [x] T-10 S — Consulta por competencia y dificultad (RF-12, 13) — Hecho cuando: solo devuelve ítems válidos y expone la fuente.
- [x] T-11 S — `tools/validar_contenido` desde la terminal (RF-14) — Hecho cuando: imprime errores o "OK".
- [x] T-12 S+E — Redactar 8 ítems de `seguridad-alto-voltaje` con fuente — Hecho cuando: pasan el validador.
- [x] T-13 S+E — Redactar 8 ítems de `sistema-electrico-bateria` — Hecho cuando: pasan el validador.
- [x] T-14 S+E — Redactar 8 ítems de `diagnostico-fallas` — Hecho cuando: pasan el validador.
- [x] T-15 S+E — Redactar 8 ítems de `electronica-conectividad` — Hecho cuando: pasan el validador.
- [x] T-16 S+E — Redactar 2 `caso-diagnostico` y 3 `accion-panel` — Hecho cuando: pasan el validador.
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
- [ ] T-52 S — Panel virtual en pantalla con los mismos eventos y LEDs (RF-9) — Hecho cuando: demo manual de un escenario con ratón. — falta verificación manual
- [x] T-53 S — Redactar `docs/protocolo-panel.md` (RF-15) — Hecho cuando: campos, versión y ejemplos.
- [ ] T-54 E — Firmware: leer controles, filtrar rebotes, enviar JSON, latido (RF-16) — Hecho cuando: el emisor y el firmware producen líneas iguales. — código listo, falta prueba en hardware
- [ ] T-55 E — Firmware: recibir estado de LEDs — Hecho cuando: los 3 LEDs responden al simulador. — código listo, falta prueba en hardware
- [ ] T-56 E — Montar la maqueta y etiquetas — Hecho cuando: checklist manual de cada control.

## 5. simulador (escena)
- [ ] T-57 S — Escena esquemática del bus y componentes inspeccionables (RF-10, 11) — Hecho cuando: se camina y se inspecciona con el control. — falta verificación manual
- [ ] T-58 S — Menú de acciones del componente y selección de causa (RF-3, 16) — Hecho cuando: se juega el escenario con teclado y ratón (RF-12). — falta verificación manual
- [ ] T-59 S — Indicador de estado del panel y pausa por desconexión (RF-14, 15) — Hecho cuando: demo manual con cable desconectado. — falta verificación manual
- [ ] T-60 S — Pantalla de resumen y reintento — Hecho cuando: demo manual con error, recuperación y reintento. — falta verificación manual

## 6. tablero
- [x] T-61 S — Consultas de los 9 indicadores (RF-4) — Hecho cuando: pruebas con el técnico `[DEMO]`.
- [x] T-62 S — Datos `[DEMO]` precargados (RF-15, 16) — Hecho cuando: historial con pre, post y retest.
- [ ] T-63 S — Vista del técnico (RF-3, 6, 8) — Hecho cuando: demo manual. — falta verificación manual
- [ ] T-64 S — Vista del instructor y detalle con línea de tiempo (RF-7, 9, 10, 12) — Hecho cuando: demo manual. — falta verificación manual
- [ ] T-65 S — Fórmulas en ayuda, color solo con texto (RF-5, 11) — Hecho cuando: checklist manual. — falta verificación manual
- [x] T-66 S — Exportar CSV y JSON; borrar técnico con confirmación (RF-13, 14) — Hecho cuando: pruebas de contenido y de borrado.
- [x] T-67 S — Estados vacíos y "pendiente" — Hecho cuando: técnico sin sesiones sin errores.
- [x] T-68 S — Asistente: búsqueda por palabras clave en fuentes locales, prompt y respuesta con cita, "no tengo esa información" (RF-18 a 21, 23) — Hecho cuando: prueba con pregunta con y sin respaldo.
- [x] T-69 S — Asistente desactivado sin modelo (RF-22) — Hecho cuando: aviso y el resto funciona.

## 7. flujo
- [x] T-70 S — Alias único y sin nombres reales (RF-1) — Hecho cuando: prueba de alias repetido.
- [x] T-71 S — Siguiente paso recomendado y diagnóstico obligatorio (RF-2, 3) — Hecho cuando: pruebas por estado.
- [x] T-72 S — Guardado por paso y reanudación (RF-4, 5) — Hecho cuando: prueba cierra y reabre a mitad de un paso.
- [ ] T-73 S — Menú principal navegable con teclado, control y ratón — Hecho cuando: checklist manual. — falta verificación manual
- [ ] T-74 S — Modo demo: base separada, adelantar reloj, restablecer (RF-6, 7, 8) — Lógica y pantalla probadas headless, incluido el estado de entrada del menú. — falta verificación manual

## 8. entrega
- [x] T-75 S — README con instalación en 3 pasos y estructura (RF-5) — Hecho cuando: otra persona lo sigue sin ayuda.
- [x] T-76 S — Documentación técnica y arquitectura (RF-1) — Hecho cuando: incluye cómo agregar contenido y escenarios.
- [x] T-77 S — Propuesta de escalabilidad con diagrama actual y objetivo (RF-2) — Hecho cuando: tres fases y riesgos.
- [x] T-78 S — Nota de privacidad y contenido (RF-3) — Hecho cuando: declara alias, datos locales, fuentes y marcas.
- [x] T-79 S — Guion de demo con plan B (RF-4) — Hecho cuando: 5 minutos medidos.
- [x] T-80 (Linux verificado desde otro directorio, Windows exportado y sin probar) S — Exportar ejecutables Windows y Linux (RF-6) — Hecho cuando: corre en Linux; Windows probado o declarado no probado.
- [x] T-81 S — Lista de dependencias y versiones (RF-8) — Hecho cuando: incluida en el paquete.
- [ ] T-82 S+E — Prueba de usabilidad con 2 ajenos y correcciones (RF-10, 11) — Hecho cuando: hallazgos con severidad y corregidos.
- [ ] T-83 S+E — Checklist de los 6 entregables (RF-12) — Hecho cuando: sin pendientes.
- [ ] T-84 S+E — Dos ensayos completos con plan B y USB de respaldo (RF-9, 13) — Hecho cuando: ambos registrados.

## Marcha paralela
Electrónica: T-05, T-54 a T-56 desde el primer día. Contenido: T-12 a T-17 en paralelo a T-18 en adelante. Sistemas: el resto en orden.

## 9. Pantallas faltantes (detectadas al integrar el flujo)
- [x] T-85 S — Pantalla de diagnóstico: 8 preguntas y 2 tareas prácticas, con reemplazo por fácil (aprendizaje RF-4, 5, 6) — Hecho cuando: prueba de humo recorre el diagnóstico y guarda los intentos. — falta verificación manual
- [x] T-86 S — Pantalla de ruta y micro-lecciones: sesión de 3, fuente visible y recálculo (aprendizaje RF-8 a 10) — Hecho cuando: prueba de humo completa una sesión. — falta verificación manual
- [x] T-87 S — Pantalla de evaluación post-test y retest, con aviso si falta adelantar el reloj (aprendizaje RF-15; flujo RF-2, 3) — Hecho cuando: prueba de humo recorre post-test y retest con reloj adelantado. — falta verificación manual
- [x] T-88 S — Que el ejecutable exportado encuentre `contenido/` (junto al ejecutable o dentro del paquete) en vez de depender de la carpeta de trabajo — Hecho cuando: el binario de `build/linux/` ejecutado desde otra carpeta carga el banco y un escenario.

## 10. Práctica en primera persona (plan aprobado)
- [x] T-89 S — Campo `componente` en acciones del escenario y validación (simulador RF-27) — Hecho cuando: prueba rechaza un componente inexistente y los dos escenarios validan.
- [x] T-90 S — Función pura de movimiento y límites del taller (RF-25) — Hecho cuando: pruebas de velocidad, diagonal y colisión con límites.
- [ ] T-91 S — Jugador en primera persona con WASD, ratón, sticks y Tab (RF-25) — Hecho cuando: prueba de humo y captura desde la posición inicial. — falta verificación manual
- [ ] T-92 S — Gabinete de servicio con puerta animada y piezas (RF-28) — Hecho cuando: captura con la puerta cerrada y abierta. — falta verificación manual
- [x] T-93 S — Raycast, resaltado y menú contextual por pieza (RF-26) — Hecho cuando: prueba que cada pieza lista solo sus acciones. — falta verificación manual
- [ ] T-94 S — HUD en franja colapsable y reflejo del estado en la escena (RF-28) — Hecho cuando: captura con tornillo roto y LED en rojo. — falta verificación manual
- [ ] T-95 S — Recorrido completo y actualizar README y checklist — Hecho cuando: ejecutable exportado recorre inspeccionar, fallo, recuperación, resumen y reintento. — falta verificación manual

## 11. Menú contextual, órdenes de servicio y zonas (plan aprobado)
- [x] T-96 S — Menú contextual en pantalla junto a la mira, con lógica pura `menu_pieza.gd` (RF-29, 30, 31) — Hecho cuando: pruebas de la lógica y captura con el menú abierto sobre el gabinete.
- [x] T-97 S — Campo `requiere_panel`, ejecución inmediata de diagnóstico y aviso central (RF-30, 31) — Hecho cuando: prueba de que inspeccionar abre la puerta sin confirmar y reponer espera el panel.
- [x] T-98 S — Pantalla de órdenes de servicio y campo `zona` (RF-32) — Hecho cuando: prueba lista los escenarios válidos y la escena arranca el elegido.
- [x] T-99 S — Zona de faros y escenario `faros.json` (RF-33) — Hecho cuando: ruta ideal pasa en prueba y captura de la zona.
- [x] T-100 S — Zona del motor eléctrico y escenario `motor.json` con falta crítica sin bloqueo (RF-33) — Hecho cuando: ruta ideal y falta crítica pasan en prueba y captura.
- [x] T-101 S — Interior y cabina con entrada por la puerta de pasajeros (RF-33) — Hecho cuando: prueba de entrada y salida y captura de la cabina.
- [ ] T-102 S — Recorrido manual de las cuatro órdenes, README y checklist — Hecho cuando: ejecutable exportado completa cada orden.
- [x] T-103 S — Prueba de flujo real de las tapas (clic, Inspeccionar, animación) y corrección de por qué no abren en faros y motor (RF-31) — Hecho cuando: la prueba pasa en faros, motor y aislamiento.
- [x] T-104 S — Rehacer el aspecto de faros y motor: tapas integradas, interior iluminado y rótulos limpios (RF-33) — Hecho cuando: capturas a 1280x720 cerradas, abiertas y a mitad de animación revisadas.

## 12. Arnés de diagnóstico con multímetro (SPEC-arnes.md, pendiente de aprobación)
- [ ] T-105 E — Armar el banco en protoboard y comprobar con un multímetro las tres filas de la tabla (S1 y S2 cerrados, S1 abierto, S2 abierto) — Hecho cuando: TP1 y TP2 marcan ≈5 V, ≈0 V y ≈5 V, y ≈5 V y ≈0 V según el caso.
- [x] T-106 S — Modelo eléctrico del banco como función pura y su prueba (arnés RF-2, 5) — Hecho cuando: la prueba cubre las tres filas y la tolerancia de ±0,2 V.
- [x] T-107 S — Escenario `modulo_auxiliar.json` con dos variantes, acciones con `titulo` y tipos de error nuevos en el validador (RF-10 a 12, 16) — Hecho cuando: la ruta ideal de cada variante pasa por `motor.gd`.
- [x] T-108 S — Lógica de mediciones y lecturas reportadas: punto medido, lectura, comparación y errores (RF-7 a 12) — Hecho cuando: pruebas de `punto-de-medicion-incorrecto`, `lectura-mal-interpretada` y `paso-omitido`.
- [x] T-109 S — Zona `banco` en el taller con mesa, arnés, puntos de prueba y multímetro virtual con puntas (RF-1, 3, 4) — Hecho cuando: captura frente al banco y prueba de humo.
- [x] T-110 S — Menú para registrar lecturas y diagnosticar, y reparación con confirmación del panel (RF-8, 13) — Hecho cuando: prueba de flujo real (clic, medir, registrar, reparar).
- [x] T-111 S — Orden de servicio y cabina enlazadas con el banco, y variante alterna al reintentar (RF-5, 17) — Hecho cuando: la orden aparece en el catálogo y el aviso es idéntico en ambas fallas.
- [x] T-112 S — Resumen y entrega a `aprendizaje` y `tablero` con errores de medición separados de los de interpretación (RF-15) — Hecho cuando: indicador visible en el tablero con datos `[DEMO]`.
- [x] T-113 S+E — Actualizar `SPEC-panel.md` y `docs/protocolo-panel.md` con los controles `nodo_p` y `nodo_q` (RF-14, protocolo) — Hecho cuando: contrato versionado y aprobado antes de tocar el firmware.
- [ ] T-114 E — Firmware de A1 y A2 con umbral y antirrebote, y su prueba de PC (RF-14) — Hecho cuando: las líneas generadas coinciden con los ejemplos del protocolo.
- [x] T-115 S — Detección del cierre de S1 o S2 como verificación de la reparación y paso al virtual si se desconecta (RF-14, 18) — Hecho cuando: prueba con el emisor de eventos.
- [x] T-116 S+E — `docs/banco-arnes.md` con diagrama, materiales y prueba de aceptación, y recorrido manual con las dos variantes (RF-19, criterios) — Hecho cuando: el recorrido completo pasa con el banco virtual y, si existe, con el físico.
- [x] T-117 S — Acción de navegación "Cerrar/Abrir" en la tapa o puerta de cada zona (gabinete, faros, motor), sin registrar puntos (RF-29) — Hecho cuando: prueba de que se puede cerrar y volver a abrir sin que el estado del motor lo reabra.
- [x] T-118 S — HUD con todos los pasos de la orden (campo `indicios` en el JSON) y aviso que nombra los pasos que faltan al rechazar una acción (RF-31) — Hecho cuando: prueba del recorrido real de faros por el panel con pausas humanas y del aviso de pasos faltantes.
- [x] T-119 S — Ayuda de siguiente paso en el HUD y tras cada acción, y prueba del clic real sobre Confirmar (RF-31) — Hecho cuando: en el banco, tras registrar el diagnóstico, el aviso y el HUD indican reparar con Reconectar conductor y confirmar en el panel; la prueba hace clic real en el botón Confirmar en faros y banco.

## 13. Taller, inventario y elevador (SPEC-taller.md)
- [x] T-120 S — Inventario como lógica pura: capacidad 4+4, tomar, dejar y consumir (taller RF-2, 3, 6, 9) — Hecho cuando: pruebas de capacidad, duplicados, consumo y reinicio.
- [x] T-121 S — Campo `requiere` en las acciones de los escenarios, validación y rechazo que nombra lo que falta (RF-5) — Hecho cuando: prueba de rechazo y de consumo de piezas.
- [x] T-122 S — Mesa de trabajo, caja roja funcional con cajones, estantería de piezas y carrito en el taller (RF-1) — Hecho cuando: capturas de los muebles y prueba de que cada pieza es apuntable.
- [x] T-123 S — Tomar y dejar por el menú de pieza y HUD de inventario con selección de la mano (RF-2, 4) — Hecho cuando: prueba de flujo real y captura del HUD.
- [x] T-124 S — Guía: ubicación en el aviso, baliza visible, indicador en pantalla y tecla de guía (RF-7, 8) — Hecho cuando: captura con la baliza y prueba de que la guía apunta al mueble correcto.
- [x] T-125 S — Requisitos en los escenarios existentes: foco y fusible en faros, llave en motor y aislamiento, multímetro en el banco (RF-5) — Hecho cuando: las rutas ideales siguen pasando tomando lo requerido.
- [x] T-126 S — Elevador: consola, animación, calzas, trabas y falta crítica bajo el autobús (RF-10 a 12) — Hecho cuando: pruebas del procedimiento y captura con el autobús elevado.
- [x] T-127 S — Zona de bajos: ruedas con tuercas, suspensión neumática, amortiguador y frenos, con colisiones bajo el autobús (RF-13) — Hecho cuando: capturas desde abajo y prueba de movimiento.
- [x] T-128 S — Órdenes mecánicas: neumático pinchado, tuercas flojas con perilla de torque, fuga de suspensión, amortiguador y freno (RF-14, 15) — Hecho cuando: ruta ideal de cada una pasa por `motor.gd`.
- [ ] T-129 S — Órdenes eléctricas nuevas: carga CCS que no inicia, puerta de pasajeros que no cierra y luces interiores apagadas (RF-15) — Hecho cuando: ruta ideal de cada una pasa y la fuente citada es la de Volvo cuando aplique.
- [ ] T-130 S — Catálogo de órdenes agrupado y desplazable con teclado, ratón y control (RF-16) — Hecho cuando: captura del catálogo con 13 órdenes.
- [ ] T-131 S — Documentación, checklist y recorrido e2e con Playwright del taller (RF-18) — Hecho cuando: el recorrido toma una pieza, la guía la señala y se resuelve una orden.
- [x] T-132 S — Campo `grupo_funcion` en los escenarios, validación y catálogo agrupado por FG (taller RF-20) — Hecho cuando: el catálogo muestra grupos FG con sus órdenes.
- [ ] T-133 S — Línea de aprobación de 91 en el tablero como referencia, sin cambiar el cálculo de dominio (decisión de aprobación) — Hecho cuando: barras del tablero muestran la línea y la prueba la verifica.
- [ ] T-134 S — Herramienta de diagnóstico tipo Tech Tool con códigos de falla genéricos y órdenes de suspensión electrónica, frenos, puerta y aire acondicionado (RF-21, 22) — Hecho cuando: ruta ideal de cada orden pasa y el Tech Tool muestra su código.
- [x] T-135 S — Tarjetas modales con botón OK para errores, rechazos y avisos importantes, en lugar del aviso temporal (simulador RF-34) — Hecho cuando: prueba de que la tarjeta no se cierra sola, bloquea la práctica hasta pulsar OK y se maneja con teclado, clic y control; captura de cada tipo.
- [x] T-136 S — Dejar en la mesa y el carrito, guardar en la caja roja, y que carrito y mesa no sean tomables (taller RF-23) — Hecho cuando: prueba de flujo real de tomar, dejar y guardar en cada mueble.
- [x] T-137 S — Selección por números 1 a 8, HUD de ocho espacios numerados y objeto en la mano resaltado (RF-24) — Hecho cuando: prueba de las teclas y captura del HUD.
- [x] T-138 S — Herramienta requerida en la mano para todas las acciones, tarjeta "Herramienta equivocada" y error leve `herramienta-equivocada` en validadores, aprendizaje y tablero (RF-25) — Hecho cuando: todas las rutas ideales pasan tomando y empuñando la herramienta correcta y la prueba de herramienta equivocada.
- [x] T-139 S — Preguntas de diagnóstico al final de la orden con retroalimentación correcto o incorrecto, explicación y fuente (RF-26) — Hecho cuando: prueba de las cinco órdenes y captura de la pantalla final.
- [x] T-140 S — Título completo y en varias líneas en el HUD (RF-27) — Hecho cuando: captura con una orden de título largo.
- [ ] T-141 S — Pasada de textos limpios en todo lo que ve el jugador (avisos, tarjetas, menús, HUD, escenarios, ayudas, preguntas y explicaciones), sin la marca `[MUESTRA]` pegada al texto — Hecho cuando: ningún texto de pantalla contiene `[MUESTRA]` ni frases rígidas; la marca se muestra como etiqueta "Ejemplo didáctico"; las pruebas siguen en verde.
- [ ] T-142 S — Resultados de éxito con siguiente paso en tarjeta con OK (chip verde "Bien hecho") y avisos breves con fondo oscuro legible de al menos 3 s (simulador RF-34) — Hecho cuando: ningún mensaje de más de tres palabras desaparece solo; prueba y captura del caso de la caja de fusibles.
