# Spec 005 — panel (incluye `entrada`)

## Contexto y objetivo
Define el panel físico (maqueta con controles y LEDs), su protocolo JSON y el vocabulario único de acciones (`entrada`) que unifica teclado y ratón, Pro Controller y panel. El simulador no distingue la fuente: solo recibe acciones. Hasta que exista el panel físico, un panel virtual en pantalla emite los mismos eventos.

## Usuarios / actores
- Técnico: opera el panel (físico o virtual), el control o el teclado.
- Equipo de electrónica: construye maqueta y firmware.
- Módulos: `simulador` (consume acciones y manda estado de LEDs), `aprendizaje` (registra fuente de entrada y brecha).

## Historias de usuario
- H1: Como técnico quiero ejecutar acciones en un panel con botones y perillas para practicar con las manos.
- H2: Como equipo quiero un contrato JSON fijo para desarrollar simulador y firmware en paralelo.
- H3: Como técnico quiero que todo funcione con teclado o control si no hay panel.

## Controles del panel (punto de partida, revisable)
- 2 interruptores: bloqueo y etiquetado.
- 1 perilla (potenciómetro): torque.
- 2 botones: confirmar y cancelar.
- 3 LEDs: energizado, bloqueado, falla.
- Hardware: ESP32 o Arduino, resistencias, cableado, base de cartón o madera con etiquetas. Si los componentes cambian, se actualiza esta spec antes de tocar el firmware.

## Vocabulario de acciones (`entrada`)
`mover`, `mirar`, `inspeccionar`, `elegir-accion`, `bloqueo`, `etiquetado`, `torque`, `confirmar`, `cancelar`.

| Acción | Teclado y ratón | Pro Controller | Panel |
|---|---|---|---|
| mover | WASD | Stick izquierdo | — |
| mirar | Ratón | Stick derecho | — |
| inspeccionar | Clic | A | — |
| elegir-accion | Teclas numéricas | D-pad | — |
| bloqueo, etiquetado | Teclas | Botones laterales | Interruptores |
| torque | Rueda del ratón | Gatillos | Perilla |
| confirmar | Tecla | X | Botón |
| cancelar | Tecla | B | Botón |

El mapeo vive en un archivo de configuración, no en el código.

Semántica: el torque es un valor absoluto 0–100; la rueda y los gatillos ajustan un valor virtual en pasos de 1. Los interruptores son estado; en teclado y control, la tecla o botón alterna el estado.

## Protocolo JSON (`docs/protocolo-panel.md`)
- Una línea JSON por evento, versionada: `{"v":1,"ctrl":"torque","valor":42,"t":12345}`.
- Panel → simulador: eventos de controles. Simulador → panel: estado de LEDs.
- USB serial a 115200 baudios. Alternativa si falla el plugin serial de Godot: puente en Python que reenvía por UDP local.
- Cambiar el contrato exige actualizar esta spec primero.
- Cada evento lleva número de secuencia `n`; `t` son milisegundos del microcontrolador. Perilla: `valor` de 0 a 100.
- LEDs: `{"v":1,"led":"falla","valor":1}`.
- Latido: `{"v":1,"ctrl":"hb"}` cada 1 s; sin latido por 3 s, el panel se considera desconectado.
- **Banco de arnés (dispositivo opcional, `SPEC-arnes.md`):** es un segundo Arduino con su propio puerto serial y la misma versión `v` del contrato. Envía `{"v":1,"ctrl":"nodo_p","valor":1,"n":0,"t":0}` y `nodo_q` (valor `0` o `1`, estado de los nodos P y Q con umbral de 2,5 V y antirrebote de 50 ms), al cambiar y con el latido. Tiene su propia secuencia `n`, su propio latido de 3 s y la fuente `banco`. `nodo_p` y `nodo_q` son estado de sensor, no acciones del vocabulario: el simulador los toma como el estado de S1 y S2 del banco.

## Requisitos funcionales (EARS)
- RF-1: EL SISTEMA define un vocabulario único de acciones que consume el simulador sin conocer la fuente.
- RF-2: EL SISTEMA mapea teclado y ratón, Pro Controller y panel a ese vocabulario según un archivo de configuración.
- RF-3: CUANDO llegan acciones de dos fuentes a la vez, EL SISTEMA usa la última y registra la fuente de cada evento (`panel`, `virtual`, `teclado`, `control`).
- RF-4: EL SISTEMA recibe eventos del panel como líneas JSON versionadas.
- RF-5: SI llega JSON malformado, versión desconocida, control inexistente o evento con número de secuencia `n` repetido, ENTONCES EL SISTEMA lo ignora y lo registra sin detener el escenario.
- RF-6: EL SISTEMA filtra eventos repetidos del mismo control en menos de 50 ms.
- RF-7: EL SISTEMA envía al panel el estado de los LEDs (energizado, bloqueado, falla) por el mismo canal.
- RF-8: MIENTRAS no lleguen eventos del puerto serial, EL SISTEMA usa el panel virtual y lo indica en pantalla.
- RF-9: EL SISTEMA muestra un panel virtual con los mismos controles y LEDs que emite los mismos eventos JSON.
- RF-10: CUANDO se evalúa una `accion-panel`, EL SISTEMA compara la secuencia de eventos recibida con la esperada, en orden.
- RF-11: SI la secuencia llega en orden incorrecto o con eventos extra, ENTONCES EL SISTEMA registra `orden-incorrecto` o `paso-innecesario`.
- RF-12: SI el técnico actúa sobre un componente sin el bloqueo activo, ENTONCES EL SISTEMA registra `accion-insegura` con la criticidad definida en el escenario.
- RF-13: EL SISTEMA lee la perilla como valor numérico y lo compara con el rango del escenario (`[MUESTRA]` si no hay fuente oficial).
- RF-14: EL SISTEMA incluye un script que emite eventos JSON de prueba para probar el simulador sin panel.
- RF-15: EL SISTEMA documenta en `docs/protocolo-panel.md` campos, versión y ejemplos.
- RF-16: EL FIRMWARE lee los controles, filtra rebotes y envía un JSON por evento a 115200 baudios, y recibe el estado de los LEDs.
- RF-17: EL SISTEMA funciona sin conexión a internet y sin Wi-Fi ni Bluetooth.
- RF-18: EL SISTEMA opera el panel solo a bajo voltaje por USB, sin conexión a sistemas reales del bus.
- RF-19: DONDE exista el banco de arnés, EL SISTEMA recibe `nodo_p` y `nodo_q` de ese dispositivo con secuencia, latido y rebote propios, y registra `banco` como fuente.
- RF-20: SI el banco se desconecta, ENTONCES EL SISTEMA pasa a la falla virtual de la variante sin detener el escenario y lo indica en pantalla.

## Requisitos no funcionales
- Latencia del evento al efecto en pantalla perceptible como inmediata.
- Español en etiquetas y mensajes.
- Panel virtual y físico intercambiables sin cambios en el simulador.

## Casos límite
- Panel desconectado a mitad del escenario: pausa, aviso y panel virtual (RF-14 de `simulador`).
- Dos controles accionados a la vez: se procesan en orden de llegada.
- Perilla con ruido: se promedia o se filtra antes de enviar.
- Puerto serial ocupado o inexistente: aviso claro y panel virtual.
- Control reasignado en el archivo de configuración: se aplica al reiniciar.

## Fuera de alcance
- Escena 3D, escenarios y puntuación (`simulador`).
- Dominio, ruta y repetición espaciada (`aprendizaje`).
- Vistas y asistente LLM (`tablero`).
- Giroscopio, Joy-Con, VR, cámara y reconocimiento de imagen.
- Wi-Fi, Bluetooth y comunicación inalámbrica del panel.
- Conexión a cualquier sistema real del bus o alto voltaje.
- Carcasa de producción.

## Criterios de finalización
- Todos los RF con prueba (script de eventos simulados para el protocolo y la validación; checklist manual para el panel físico y los controles) en verde.
- Prueba de humo de 30 minutos con un botón y un LED entre firmware y simulador.
- Demo manual del escenario completo con panel virtual y, si existe, con el físico.

## Dudas abiertas
- [NECESITA ACLARACIÓN] Plugin serial de Godot frente a puente Python: se decide con la prueba de 30 minutos.
- [NECESITA ACLARACIÓN] Microcontrolador definitivo (ESP32 o Arduino) y componentes disponibles.
- [NECESITA ACLARACIÓN] Fecha en que estará el panel físico.
