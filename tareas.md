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
- [ ] T-64 S — Vista «Jefe directo» y detalle con línea de tiempo (RF-7, 9, 10, 12) — Hecho cuando: demo manual. — falta verificación manual
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
- [x] T-141 S — Pasada de textos limpios en todo lo que ve el jugador (avisos, tarjetas, menús, HUD, escenarios, ayudas, preguntas y explicaciones), sin la marca `[MUESTRA]` pegada al texto — Hecho cuando: ningún texto de pantalla contiene `[MUESTRA]` ni frases rígidas; la marca se muestra como etiqueta "Ejemplo didáctico"; las pruebas siguen en verde.
- [x] T-142 S — Resultados de éxito con siguiente paso en tarjeta con OK (chip verde "Bien hecho") y avisos breves con fondo oscuro legible de al menos 3 s (simulador RF-34) — Hecho cuando: ningún mensaje de más de tres palabras desaparece solo; prueba y captura del caso de la caja de fusibles.
- [x] T-143 S — Resumen de la orden con botones Guardar, Omitir, Reintentar y Volver al menú, aviso cuando falta la reflexión, texto claro y contenido completo con desplazamiento (simulador RF-35) — Hecho cuando: prueba de guardar con campo vacío, guardar con texto, omitir y volver al menú con clic y con teclado.
- [x] T-144 S — La consola del elevador señalada con la tecla G, "Cerrar la orden" como paso final visible, etiqueta "Ejemplo didáctico" una sola vez como chip y resumen sin puntos sobrantes ni milisegundos — Hecho cuando: la guía apunta a la consola en los pasos de elevador y el resumen se ve limpio.
- [x] T-145 S — Rediseño del resumen de la orden como tablero de tarjetas con indicadores, línea de tiempo con colores, tarjeta de diagnóstico y comparación con el intento anterior (simulador RF-36) — Hecho cuando: captura del resumen revisada a 1280x720 y 1920x1080 y pruebas de pluralización, formato de tiempo y agrupación de pasos repetidos.
- [x] T-146 S — HUD por misiones: una misión en grande con subpasos, progreso en puntos y transición de misión cumplida, en lugar de la lista completa de pasos (simulador RF-37) — Hecho cuando: capturas de las cinco órdenes mecánicas y de motor revisadas, subpasos que se marcan solos y pruebas de transición.
- [x] T-147 S — Catálogo de órdenes ordenado por dificultad (Fácil, Media, Difícil) con FG como etiqueta y filtro por FG, y tarjetas limpias con chips de dificultad y de ejemplo didáctico (taller RF-16) — Hecho cuando: captura del catálogo con tres secciones por dificultad y prueba del orden.
- [x] T-148 S — Multímetro único sobre la mesa del banco (ubicación inicial por orden), lectura en el de la mano y puntas negra y roja visibles con indicador y avisos de apuntado (arnés, ajustes) — Hecho cuando: recorrido por la UI real y captura con las pinzas en los bornes.
- [x] T-149 S — Hoja de diagnóstico sobre la mesa con formulario de lecturas y causa que usa las acciones existentes (arnés, ajustes) — Hecho cuando: prueba de la hoja con las dos variantes y con el banco físico.
- [x] T-150 S — Banco de arnés en cuatro misiones con misión compuesta por claves (arnés, ajustes) — Hecho cuando: HUD con cuatro misiones y subpasos automáticos y el resumen intacto.
- [x] T-151 S — Tarjeta "Orden de trabajo" al iniciar y al reintentar las diez órdenes, con tecla O (simulador RF-38) — Hecho cuando: prueba en las diez órdenes y captura de la tarjeta.
- [x] T-152 S — Texto de apuntado de las puntas coherente con el estado (si la roja ya está en el borne, decirlo) y "Ejemplo didáctico" como chip en la tarjeta de orden — Hecho cuando: prueba del texto de apuntado en cada estado de las puntas y captura de la tarjeta.
- [x] T-153 S — Guía azul automática: el objeto que toca tomar se marca en azul con contorno y flecha en pantalla sin pulsar G, y la herramienta que toca tener en la mano se resalta en azul en el inventario (taller RF-28) — Hecho cuando: prueba de qué objeto se marca en cada subpaso y capturas del contorno, la flecha y el inventario.
- [x] T-154 S — Quitar la causa de la hoja de diagnóstico, pasar el banco a tres misiones y registrar el error de interpretación al cierre de la orden (arnés, cambio posterior) — Hecho cuando: la hoja solo pide las dos lecturas, reparar no exige diagnóstico previo y el cierre registra `lectura-mal-interpretada` cuando corresponde.
- [x] T-155 S — Inventario legible: mostrar el espacio usado (3 de 4), el tamaño de cada objeto y avisos con la cuenta exacta y qué soltar (taller, RF-3 y RF-4) — Hecho cuando: la pantalla muestra el espacio ocupado, el aviso dice cuánto ocupa el objeto y cuánto queda, y una prueba de flujo real de tomar, soltar en mesa y carrito y volver a tomar.
- [x] T-156 S — Instrucciones específicas con ubicación: subpasos que dicen dónde está cada herramienta, pieza y punto de trabajo, rótulos visibles en la caja de herramientas y la mesa, nombre del mueble en la flecha y leyenda "Dónde está todo" en la tarjeta de orden (taller RF-29) — Hecho cuando: ningún subpaso de "Toma" o "Coloca" sin ubicación, rótulos en las capturas y prueba de los textos.
- [x] T-157 S — Cajones de la caja roja de uno en uno: cada cajón es una pieza, se abre con animación, solo uno abierto a la vez y solo sus herramientas se pueden tomar (taller RF-30) — Hecho cuando: prueba de abrir, cambiar de cajón, cerrar y tomar por la UI real, y captura con un solo cajón abierto.
- [x] T-158 S — Diagnóstico y ruta: introducción, retroalimentación de la respuesta anterior y resultados con barras (aprendizaje RF-21) — Hecho cuando: capturas revisadas y suite en verde.
- [ ] T-159 S — Ruta: motivo de cada tema, botón "Practicar en el taller" y estado en las tarjetas del menú.
- [ ] T-160 S — Alinear con Volvo: el tablero muestra "recomendación para el jefe directo" y no una decisión de avance; el resumen de cada orden evalúa el procedimiento (orden, pasos omitidos e innecesarios) además del resultado (docs/respuestas-volvo.md) — Hecho cuando: textos revisados y prueba.
- [x] T-161 S — Adaptador del ESP32 (UDP 4210 → eventos del simulador con latido) y prueba (arnés RF nuevo) — Hecho cuando: prueba de lógica y recorrido de punta a punta con una placa simulada.
- [x] T-162 S — Nivel alto configurable (3.3 V o 5 V) en banco, opciones, textos y calificación — Hecho cuando: prueba con 3.3 V y suite en verde.
- [x] T-163 S — Identidad de sesión en los intentos (`sesion_id`, caso, variante, número de intento, ayudas) y agrupación por sesión en el tablero.
- [x] T-164 S — Error concreto → práctica de refuerzo con motivo visible en la ruta.
- [x] T-165 S — Evidencia y errores/oportunidades junto al dominio en el tablero. Cubierto por T-180.
- [ ] T-166 H — Prueba en mesa con el ESP32 real: sano, alimentación abierta, señal abierta y desconexión a mitad de un intento; comparar multímetro, monitor serial y Godot.
- [x] T-167 S — Ruta de aprendizaje como roadmap: camino numerado por competencia según el diagnóstico, con "Hoy" o "Después", barra de dominio, motivo y práctica sugerida (aprendizaje RF-21).
- [x] T-168 S — Foundry: contexto, esquema y validación de la ruta (`ruta_ia.gd`) y spec/privacidad (aprendizaje RF-23, RF-24).
- [x] T-169 S — Cliente Foundry con `HTTPRequest`, configuración local y tiempo de espera de 8 s.
- [x] T-170 S — Caché de la ruta generada en SQLite.
- [x] T-171 S — Pantalla de ruta: "Armando tu ruta…", ruta con IA y respaldo "Ruta calculada sin IA".
- [ ] T-172 H — Revisión humana: correr un diagnóstico en la app con `az login` y revisar que la ruta tenga sentido (corrida real hecha: válida, con fuentes).
- [x] T-173 — Cliente del agente Faro (API Responses con token de `az`, `.env` fuera de git), extracción de JSON y de fuentes citadas, y "Basada en: …" en la ruta. Pruebas sin nube.
- [ ] T-174 S — Mostrar el mapa del diagnóstico con camino central y ramas de error y práctica (aprendizaje RF-25). Modelo, texto y desplazamiento verificados a 1280 × 720 y 1920 × 1080. Queda pendiente la revisión de las capturas en un entorno gráfico.
- [x] T-175 — Faro genera los temas de cada paso del mapa (con fuente de los manuales), la app los valida contra las fuentes devueltas y tolera ids de órdenes inválidos; caché con versión.
- [x] T-176 — Ampliar el banco a 57 ítems con 20 preguntas de opción múltiple (competencias RF-2 y RF-3). Nuevas por competencia: 4 de seguridad de alto voltaje, 6 de sistema eléctrico y batería, 4 de diagnóstico de fallas y 6 de electrónica y conectividad. PDF usados: `Fact-sheet-Electric-Safety-EN-VolvoBuses-2024-Es-Mx.pdf`, `Data sheet BZL Electric ES-MX 2021.pdf`, `volvo_9700_manual_en_3.pdf`, `h3_operator_manual_en_0.pdf` y `PA1583-2 Literature.pdf`. [Páginas y reparto por dificultad](docs/fuentes-volvo.md#preguntas-nuevas-del-banco-t-176). Revisión por Volvo pendiente.
- [x] T-177 — Abrir el detalle de cada nodo del mapa de aprendizaje, enlazar al taller y verificar el panel con pruebas y una vista de captura (aprendizaje RF-26).
- [x] T-178 — La ruta se muestra solo como mapa, sin preguntas; «Continuar» cierra el paso (RF-27). Se quita la práctica de seis preguntas de la ruta.
- [x] T-179 — Rediseñar el mapa de aprendizaje y su panel de detalle (RF-25 y RF-26). Camino numerado, cuatro estados con color, fichas compactas con acceso al detalle y pie fijo. Suite y geometría verificadas a 1280 × 720 y 1920 × 1080. Revisión de PNG pendiente por falta de acceso a una sesión gráfica.

- [x] T-180 S — Tablero para el jefe directo (tablero RF-3, RF-24 a RF-26). Lista por prioridad, ficha con evidencia y recomendación, y exportación por alias. Suite y geometría verificadas a 1280 × 720 y 1920 × 1080. Los PNG requieren una sesión gráfica.


- [x] T-183 S — Sustituir el ingreso por alias con usuario y contraseña, creación del primer administrador, cambio obligatorio, bloqueo y cierre de sesión (flujo RF-1, RF-10 a RF-15).
- [x] T-184 S — Aplicar roles al menú y a las vistas personal, de equipo y operativa (flujo RF-12 y tablero RF-3).
- [x] T-185 S — Gestionar cuentas, mostrar la contraseña temporal una vez y confirmar el borrado con protecciones (flujo RF-13 y tablero RF-14).
- [x] T-186 S — Probar las pantallas de cuenta e incorporar las seis vistas a la herramienta de captura.
- [x] T-187 — Página de materiales (materiales RF-1 a RF-3, RF-11, RF-13): servidor con la biblioteca estándar, catálogo por modelo de autobús, nivel y competencia que abre en los básicos, vistas de técnico y autor y visores de tarjetas, presentación, infografía, quiz, pareo y ordenar pasos. Recorrido en navegador sin errores.
- [x] T-188 — Generar y actualizar con el agente de Foundry (materiales RF-4 a RF-10, RF-14, RF-15): esquema por formato, guía por nivel, PDF sugeridos por modelo, validación de fuentes contra las devueltas, borrador, historial de versiones y edición manual validada. Pruebas con agente simulado.
- [x] T-189 — Respaldo sin IA desde el banco (materiales RF-12) y materiales de inicio de nivel básico en borrador (7 del banco y a mano, 6 generados con Faro).
- [ ] T-190 H — Crear el agente `materiales` en el portal con la base de conocimiento de Faro y revisar y publicar los materiales de inicio. Hecho: generación real de los seis formatos con Faro, fuentes verificadas (25/11/2026).

- [x] T-191 S — Preparar datos de gráficas a partir de las consultas existentes y probar estados vacíos, límites, orden y máximo de series (tablero RF-27 a RF-29).
- [x] T-192 S — Integrar las gráficas de técnico, equipo, ficha y administración con acceso por rol, foco, tooltips y tablas equivalentes (tablero RF-27 a RF-30).
- [x] T-193 S — Añadir las cuatro vistas de captura con datos temporales y verificar geometría a 1280 × 720 y 1920 × 1080.
- [ ] T-194 H — Revisar los PNG de las cuatro vistas en una sesión gráfica.

- [x] T-195 — Banco de competencias (RF-2 y RF-3). Retirar 14 preguntas repetitivas o poco útiles, incorporar 14 preguntas respaldadas por los PDF y agrupar las 52 preguntas por tema. Ajustar distractores y repartir la posición de las respuestas correctas. [Fuentes y cobertura por dificultad](docs/fuentes-volvo.md#fuentes-vigentes-del-banco-t-185).
- [x] T-196 — Juego de ahorcado en materiales: formato validado (solo letras, sin distinguir acentos), teclado en pantalla y físico, dibujo por errores y explicación al terminar cada término; uno generado con Faro.

- [x] T-200 — Incorporar los esquemas, la validación, el catálogo y las instrucciones de Foundry para Verdadero o falso, Completa la frase, Clasifica y Caso de falla (materiales RF-16 a RF-20).
- [x] T-201 — Generar Verdadero o falso con el banco cuando no hay IA e incorporar un borrador con fuentes por juego nuevo.
- [x] T-202 — Implementar los cuatro visores con botones, foco visible y retroalimentación anunciada.
- [ ] T-203 — Verificar los visores con capturas de Chromium a 1280 × 800 y 390 px de ancho. Las interacciones se comprobaron en el DOM. El entorno de ejecución bloqueó el inicio de Chromium y los sockets de localhost.
- [x] T-204 — EPP como primer paso de cada orden: catálogo y requisitos por tarea (`epp.gd`), vestidor con señuelos, bloqueo de pasos en el motor y registro del intento (SPEC-simulador RF-39).
- [x] T-205 — Casillero de EPP en el taller 3D, selección en primera persona y retroalimentación del equipo puesto (SPEC-simulador RF-39). Queda pendiente la validación con Volvo de los requisitos por tarea.
- [x] T-206 — La práctica en el taller se bloquea hasta terminar el diagnóstico y las órdenes se abren por nivel según el dominio de cada competencia (Media desde 50, Difícil desde 75; `niveles.gd`).
- [x] T-207 — Sonido sintetizado en código (clics, pasos, éxito, error, falta crítica, EPP, elevador, victoria). La tecla M lo silencia y la preferencia se guarda; sin archivos de audio externos.
- [x] T-208 — Materiales: botón Publicar y Retirar en cada tarjeta y en el visor; el técnico recibe primero los publicados que le tocan según su ruta de aprendizaje y su nivel (`asignacion.py`, sección «Para ti»).
