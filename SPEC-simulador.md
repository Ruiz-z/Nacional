# Spec 003 — simulador

## Contexto y objetivo
Escena en Godot de un bus eléctrico donde el técnico inspecciona, diagnostica y actúa. Cada acción cambia el estado del bus y puede provocar problemas nuevos que el técnico debe resolver. Los escenarios son datos (JSON), no código. Entrega resultados a `aprendizaje` y `tablero`.

## Usuarios / actores
- Técnico: juega el escenario.
- Autor de contenido: define escenarios en JSON.
- Módulos: `competencias` (casos y fuentes), `aprendizaje`, `panel`/`entrada` (eventos), `tablero`.

## Historias de usuario
- H1: Como técnico quiero ver las consecuencias de mis acciones (por ejemplo, romper un tornillo por exceso de torque) para aprender de ellas.
- H2: Como técnico quiero opciones de recuperación cuando algo sale mal, para practicar la resolución de problemas.
- H3: Como técnico quiero revisar y reintentar mis decisiones para aprender de mis propios errores.
- H4: Como autor quiero añadir escenarios editando un JSON, sin programar.

## Escenarios
- 1 escenario completo: pérdida de aislamiento en alto voltaje (datos de muestra con fuente), con 3 o 4 acciones que pueden salir mal y sus recuperaciones.
- 1 caso corto de diagnóstico por síntomas (falla de comunicación en la red del vehículo).
- Más escenarios si hay tiempo, solo como datos.

## Modelo de escenario (JSON)
- `estado`: variables simples (`energizado`, `bloqueo_puesto`, `torque_borne`, `tornillo_roto`, `aislamiento_ok`...).
- `acciones`: condiciones previas, efectos sobre el estado, competencia, tipo de error, criticidad, fuente.
- Una acción o recuperación puede declarar `seguridad_panel` y `explicacion_seguridad`. El motor evalúa los interruptores activos de bloqueo y etiquetado al ejecutar. Con `previa`, rechaza la acción si falta un interruptor. Con `critica`, registra `accion-insegura` y termina en `falta-critica` si falta uno o ambos. Con los dos activos se aplican las condiciones previas y los efectos habituales. El reintento conserva el progreso seguro anterior a la primera acción dependiente del panel.
- `eventos`: condición sobre el estado que activa un problema o el fin del escenario.
- `recuperaciones`: opciones con costo, tiempo y riesgo que modifican el estado.
- `terminacion`: falla resuelta, falta crítica o límite de intentos.

## Interacción
- Pro Controller (sticks): caminar, mirar, apuntar e inspeccionar componentes.
- Menú en pantalla: acciones disponibles del componente (medir, apretar, reemplazar, consultar procedimiento, escalar).
- Panel (físico o virtual): bloqueo y etiquetado, perilla de torque, confirmar acción, LEDs de estado.
- Teclado y ratón: respaldo completo; toda acción del panel tiene tecla equivalente.
- La causa que el técnico cree que es se marca en pantalla; la acción correctiva se confirma en el panel.

## Requisitos funcionales (EARS)
- RF-1: EL SISTEMA carga cada escenario desde un archivo JSON local y valida estado, acciones, eventos, recuperaciones y fuentes.
- RF-2: SI un escenario es inválido, ENTONCES EL SISTEMA reporta el error con archivo y campo, y no lo carga.
- RF-3: CUANDO el técnico ejecuta una acción cuyas condiciones previas se cumplen, EL SISTEMA aplica sus efectos al estado y los refleja en la escena.
- RF-4: SI una acción tiene condiciones previas no cumplidas, ENTONCES EL SISTEMA la rechaza y explica por qué.
- RF-5: CUANDO el estado cumple la condición de un evento, EL SISTEMA activa el problema asociado (por ejemplo, `tornillo_roto` abre el menú de recuperación).
- RF-6: CUANDO se activa un problema, EL SISTEMA ofrece opciones de recuperación con costo, tiempo y riesgo.
- RF-7: CUANDO el técnico elige una recuperación, EL SISTEMA aplica sus efectos, que pueden resolver el problema o abrir otro.
- RF-8: CUANDO el técnico ejecuta una acción de criticidad `critica`, EL SISTEMA detiene el escenario, muestra la explicación con su fuente y registra la falta.
- RF-9: CUANDO el técnico ejecuta una acción `leve`, EL SISTEMA resta puntos, avisa y continúa.
- RF-10: EL SISTEMA permite caminar y mirar con los sticks del Pro Controller e inspeccionar componentes con A.
- RF-11: CUANDO el técnico inspecciona un componente, EL SISTEMA muestra su estado, lecturas y acciones disponibles.
- RF-12: EL SISTEMA permite completar cualquier escenario solo con teclado y ratón.
- RF-13: MIENTRAS no haya panel físico conectado, EL SISTEMA usa un panel virtual en pantalla que emite los mismos eventos que el real.
- RF-14: SI el panel físico se desconecta durante un escenario, ENTONCES EL SISTEMA pausa, avisa y permite continuar con el panel virtual.
- RF-15: EL SISTEMA muestra el estado del panel (físico, virtual, desconectado) en pantalla.
- RF-16: CUANDO el técnico marca una causa en pantalla y ejecuta una acción en el panel, EL SISTEMA compara ambas y envía a `aprendizaje` la brecha `diagnostico-vs-accion` si no coinciden.
- RF-17: EL SISTEMA puntúa cada escenario de 0 a 100: parte de 100 y resta por tipo de error; una recuperación correcta devuelve parte de los puntos.
- RF-18: AL terminar, EL SISTEMA muestra un resumen con línea de tiempo de decisiones, aciertos y errores, ruta ideal con fuente y brechas.
- RF-19: EL SISTEMA permite reintentar desde el punto donde falló y, al reintentar, presenta una variante del escenario (misma falla con ubicación o valores distintos; una variante por escenario).
- RF-20: ANTES de mostrar la solución, EL SISTEMA pregunta "¿qué harías distinto?" y registra la elección.
- RF-21: EL SISTEMA muestra la comparación entre el intento anterior y el actual (errores, tiempo, puntos).
- RF-22: EL SISTEMA entrega a `aprendizaje` y `tablero` por escenario: resultados por competencia, errores, faltas, brechas, tiempo por acción, fuente de entrada (`panel`, `virtual`, `teclado` o `control`) y versión del contenido.
- RF-23: EL SISTEMA funciona sin conexión a internet.
- RF-24: CUANDO no hay panel físico, EL SISTEMA calcula la brecha con el panel virtual y registra la fuente de entrada.
- RF-25: EL SISTEMA presenta la práctica en primera persona: el técnico camina por el taller y mira con teclado y ratón o con los sticks, y puede liberar el cursor con Tab para usar los paneles.
- RF-26: CUANDO el técnico apunta a una pieza a menos de 2,5 m, EL SISTEMA la resalta y muestra su nombre; AL pulsar inspeccionar con clic izquierdo o A, muestra las acciones de esa pieza y las recuperaciones habilitadas. La decisión se ejecuta al confirmar la acción seleccionada.
- RF-27: CADA acción o recuperación de un escenario puede declarar un `componente` (`compuerta`, `monitor`, `cables`, `terminal`, `bateria`); SI el valor no existe, ENTONCES el validador rechaza el escenario con archivo y campo. Si se omite el campo, la acción o recuperación aparece en la batería.
- RF-28: CUANDO cambia el estado del motor, EL SISTEMA refleja en la escena la compuerta abierta o cerrada, el LED del monitor y la pieza dañada.
- RF-29: CUANDO el técnico pulsa sobre una pieza, EL SISTEMA muestra al instante un menú en pantalla junto a la mira con las acciones de esa pieza, su costo, tiempo y riesgo, navegable con clic, teclas numéricas o control.
- RF-30: EL SISTEMA ejecuta de inmediato las acciones de diagnóstico y, en las acciones con `requiere_panel`, espera la confirmación del panel físico o virtual antes de ejecutarlas.
- RF-31: CUANDO se ejecuta una acción, EL SISTEMA muestra un aviso central con su resultado y anima la escena en ese momento.
- RF-32: EL SISTEMA ofrece órdenes de servicio, una por escenario con su `zona`, y activa solo la falla de la orden elegida; las demás piezas se pueden inspeccionar sin falla.
- RF-33: EL SISTEMA incluye las zonas gabinete lateral, faros, motor eléctrico de tracción y cabina interior, accesibles caminando; la cabina se alcanza por la puerta de pasajeros.
- RF-34: CUANDO ocurre un error, un rechazo o un aviso importante (falta una herramienta o pieza, acción no aplicada, error del técnico, falta crítica), EL SISTEMA lo muestra en una tarjeta modal con título, explicación y botón **OK** que no se cierra sola; mientras está abierta, la práctica queda en pausa y al cerrarla se recupera el control. Los resultados de éxito que incluyen explicación o el siguiente paso también se muestran en tarjeta con **OK**, con chip verde "Bien hecho". Solo las confirmaciones de una o dos palabras ("Compuerta abierta") son temporales, con fondo oscuro legible y al menos 3 segundos de duración.
- RF-35: AL terminar una orden, EL SISTEMA muestra un resumen con botones visibles **Guardar y ver ruta ideal**, **Omitir**, **Reintentar** y **Volver al menú**; SI el campo de reflexión está vacío al guardar, ENTONCES avisa en la pantalla "Escribe tu respuesta o pulsa Omitir" y no se queda sin responder; el resumen usa texto claro ("Orden resuelta", sin palabras internas) y su contenido se puede leer completo con desplazamiento.
- RF-36: EL SISTEMA presenta el resumen de la orden como un tablero de tarjetas: cabecera con el resultado y la orden; cuatro indicadores (puntos con barra, errores, tiempo en minutos y segundos, resultado del diagnóstico); línea de tiempo de los pasos con color por resultado y la explicación junto a cada error; tarjeta de diagnóstico con la respuesta del técnico, la causa real, la explicación y la fuente; y comparación con el intento anterior cuando exista; los pasos repetidos se agrupan.
- RF-37: EL SISTEMA presenta el avance de la orden por **misiones**: muestra una sola misión a la vez, en grande y con verbo ("Inspecciona la tapa del motor"), con un indicador "Misión 3 de 6", una fila de puntos de progreso y, debajo, los subpasos de esa misión con casilla (tomar la herramienta, tenerla en la mano, activar lo que pida el panel, elegir la acción en la pieza, confirmar en el panel); AL cumplir la misión, el sistema la marca con una animación breve de "Misión cumplida" y pasa a la siguiente; las misiones cumplidas quedan en la fila de puntos y el jugador puede ocultar el detalle con la tecla H.
- RF-38: AL empezar y al reintentar una orden, EL SISTEMA muestra una tarjeta con OK titulada "Orden de trabajo" con el síntoma, el objetivo y cómo empezar en bloques de texto breve. La práctica queda en pausa hasta cerrar la tarjeta. Pulsa O o Start para verla de nuevo.
- RF-39: AL abrir una orden desde el menú, DESPUÉS de la tarjeta "Orden de trabajo" y ANTES de cualquier paso, EL SISTEMA abre el vestidor de EPP con el equipo que pide la tarea (según la zona o el campo `epp.requeridos` del escenario) más tres señuelos fijos por orden; MIENTRAS falte equipo exigido, EL SISTEMA rechaza todos los pasos, resta puntos por paso omitido y muestra qué falta y por qué. El equipo de más resta como paso innecesario. Los intentos se guardan como competencia `seguridad-alto-voltaje`. Los requisitos son criterio didáctico `[MUESTRA]` hasta que Volvo los valide.

## Requisitos no funcionales
- Godot 4.7.2; modo escritorio; español.
- Gráficos esquemáticos pero reconocibles; sin física realista.
- Todo valor técnico (torque, piezas, pasos) viene de una fuente confiable y se marca `[MUESTRA]`; si no hay fuente, se deja genérico y no se inventan cifras.
- Los escenarios nuevos se agregan solo con JSON.

## Casos límite
- Control no conectado: teclado y ratón.
- Acción repetida en el mismo estado: respuesta coherente sin romper el estado.
- Estado imposible o evento circular: se detecta al validar el JSON.
- Panel que envía eventos duplicados o con número de secuencia repetido o perdido: se ignoran y se registran. El orden incorrecto de acciones del técnico sí se evalúa (`panel` RF-10/11).
- Reintento tras falta crítica: reinicia desde el punto seguro.

## Fuera de alcance
- Firmware, protocolo serial y maqueta física (`panel`).
- Dominio, ruta y repetición espaciada (`aprendizaje`).
- Contenido y fuentes de los ítems (`competencias`).
- Gráficas del tablero (`tablero`).
- Gráficos realistas, animaciones detalladas y física realista.
- VR, giroscopio, escenario diésel, multijugador y red.

## Criterios de finalización
- Todos los RF con prueba (automática para el motor de estado y validación; checklist manual para controles y escena) en verde.
- Demo manual: escenario completo con un error provocado (tornillo roto), recuperación, resumen y reintento.
- Un integrante verificó los valores técnicos contra su fuente.

## Dudas abiertas
- [NECESITA ACLARACIÓN] Valores reales de torque y pasos de recuperación: dependen de fuentes confiables o del material de Volvo.
- [NECESITA ACLARACIÓN] Cuántas acciones que salen mal caben en el tiempo del equipo (3 o 4 propuestas).
- [NECESITA ACLARACIÓN] Cuándo estará disponible el panel físico y con qué controles.
