# Spec 008 — arnés de diagnóstico

## Contexto y objetivo
Añade una práctica de diagnóstico eléctrico con medición: un **banco de arnés** (virtual y, si hay tiempo, físico) donde dos fallas distintas producen el mismo aviso en pantalla y el técnico debe medir con un multímetro, elegir el punto de prueba e interpretar la lectura. Aporta una habilidad que el panel de bloqueo, etiquetado y torque no mide, y separa dos errores que piden capacitación distinta: **medir en el lugar equivocado** y **medir bien pero interpretar mal**.

La versión virtual es obligatoria (respaldo, constitución principio 6). El banco físico es opcional y emite los mismos eventos.

Fuente de la propuesta: conversación de hardware del equipo (`HackaTec_conversacion.md`, sección 6 en adelante). Los valores del banco (5 V, 10 kΩ, 1 kΩ) son **didácticos y de la maqueta**, no valores de un autobús.

## Usuarios / actores
- Técnico: observa el síntoma, mide, registra lecturas, diagnostica y repara.
- Instructor: prepara la falla (físicamente con S1 y S2, o eligiendo la variante en la orden).
- Módulos: `simulador` (escenario y zona), `panel` (protocolo y firmware), `aprendizaje` (errores y brecha), `tablero` (indicadores), `competencias` (fuente y competencia).

## Historias de usuario
- H1: Como técnico quiero medir con un multímetro dos puntos de prueba y decidir cuál conductor falló, para no cambiar piezas por adivinar.
- H2: Como instructor quiero saber si el técnico midió mal o interpretó mal, para recomendar la práctica correcta.
- H3: Como equipo quiero que todo funcione sin el banco físico, para no depender del hardware en la demo.

## Banco (modelo eléctrico didáctico)
- Origen J1 (controlador) y destino J2 (módulo auxiliar), tres conductores: alimentación (5 V), señal de prueba (5 V) y tierra.
- Interruptores ocultos **S1** (abre la alimentación) y **S2** (abre la señal). Nodos **P** (alimentación recibida) y **Q** (señal recibida), con 10 kΩ a tierra cada uno.
- Puntos de prueba **TP0** (tierra), **TP1** (nodo P) y **TP2** (nodo Q), con 1 kΩ en serie.

| Estado | S1 | S2 | TP1 | TP2 | Aviso en pantalla |
|---|---|---|---:|---:|---|
| Sano | cerrado | cerrado | ≈5 V | ≈5 V | Módulo disponible |
| Falla de alimentación | abierto | cerrado | ≈0 V | ≈5 V | Módulo sin respuesta |
| Falla de señal | cerrado | abierto | ≈5 V | ≈0 V | Módulo sin respuesta |

Los puntos de prueba van del lado de J2, después de los interruptores.

## Requisitos funcionales (EARS)
- RF-1: EL SISTEMA incluye una zona `banco` en el taller con una mesa, un arnés J1 a J2, los puntos de prueba TP0, TP1 y TP2 rotulados y un multímetro.
- RF-2: EL SISTEMA calcula la tensión de TP1 y TP2 con una función pura del estado de S1 y S2, con los valores de la tabla.
- RF-3: CUANDO el técnico apunta con las puntas del multímetro virtual a TP0 y a un punto de prueba, EL SISTEMA muestra en la pantalla del multímetro la tensión correspondiente con una tolerancia de ±0,2 V.
- RF-4: SI las puntas no están en TP0 y un punto de prueba, ENTONCES EL SISTEMA muestra "—" y no registra una medición.
- RF-5: EL SISTEMA produce el mismo aviso ("Módulo sin respuesta") para la falla de alimentación y la de señal, y no muestra las tensiones al técnico salvo mediante el multímetro.
- RF-6: EL SISTEMA determina la falla activa de una de estas fuentes: la variante elegida en la orden de servicio (virtual) o el estado de S1 y S2 recibido del banco físico.
- RF-7: CUANDO el técnico mide un punto de prueba, EL SISTEMA registra qué punto midió y la lectura que mostró el multímetro.
- RF-8: EL SISTEMA permite al técnico registrar la lectura que cree haber visto en cada punto, eligiendo entre "≈0 V", "≈5 V" u "otra", y la guarda como `lectura-reportada`.
- RF-9: CUANDO el técnico confirma un diagnóstico, EL SISTEMA compara las lecturas reportadas con las reales del estado y su causa elegida con la falla activa.
- RF-10: SI el técnico no midió el punto que distingue la falla antes de reparar, ENTONCES EL SISTEMA registra el error `punto-de-medicion-incorrecto`.
- RF-11: SI las lecturas reportadas son correctas pero la causa elegida no corresponde, ENTONCES EL SISTEMA registra el error `lectura-mal-interpretada`.
- RF-12: SI el técnico repara sin haber medido, ENTONCES EL SISTEMA registra `paso-omitido`.
- RF-13: CUANDO el técnico elige la reparación correcta, EL SISTEMA la ejecuta con confirmación del panel (virtual o físico) y cierra la falla.
- RF-14: DONDE exista el banco físico, EL SISTEMA detecta el cierre de S1 o S2 por el protocolo y lo toma como verificación de la reparación.
- RF-15: EL SISTEMA muestra en el resumen y entrega a `aprendizaje` y `tablero` por separado los errores de medición y los de interpretación.
- RF-16: EL SISTEMA incluye el escenario `modulo_auxiliar.json` con la competencia `electronica-conectividad`, dos variantes (una por falla), `titulo` en cada acción y fuente `[MUESTRA]` para los valores del banco.
- RF-17: EL SISTEMA asigna al técnico la variante que no resolvió antes cuando reintenta.
- RF-18: EL SISTEMA funciona sin el banco físico usando el multímetro virtual, e indica en pantalla cuál de las dos fuentes de falla está activa.
- RF-19: EL SISTEMA opera el banco físico a 5 V por USB (Arduino Uno) o a 3.3 V con ESP32 por Wi-Fi, rotulado como maqueta didáctica, sin conexión a sistemas reales.
- RF-20: EL SISTEMA funciona sin conexión a internet.
- RF-21: EL SISTEMA admite un banco con ESP32 por Wi-Fi mediante un adaptador local (`tools/puente_esp32.py`) que traduce `{"tp1","tp2"}` a eventos `nodo_p` y `nodo_q`, y admite una tensión de nivel alto configurable (`nominal_alto` en la orden o `--nominal-alto=3.3`), de modo que las opciones, los textos y la calificación usan 3.3 V o 5 V según el banco.

## Protocolo y firmware (si hay banco físico)
- Se añaden al contrato dos controles de entrada, `nodo_p` y `nodo_q` (valor 0 o 1, de las entradas A1 y A2 con umbral de 2,5 V y antirrebote de 50 ms). Se envían al cambiar y con el latido. **Cambiar el contrato exige actualizar `SPEC-panel.md` y `docs/protocolo-panel.md` antes del firmware** (constitución, principio 7).
- La perilla de torque conserva A0; el arnés usa A1 y A2.
- Si se usa un Uno dedicado al banco, los controles del panel no cambian.

## Requisitos no funcionales
- Español; escena ligera (menos de 90 000 triángulos en total).
- El multímetro virtual se maneja con ratón, teclado y control; el respaldo cubre todo lo que haría el banco físico.
- Los valores se declaran didácticos; no se presentan como valores de Volvo.

## Casos límite
- Puntas invertidas (rojo en TP0 y negro en un punto): lectura "—" con aviso de polaridad.
- Medición de TP0 contra TP0: 0 V sin registrar falla.
- Banco físico desconectado a mitad de la práctica: pausa y paso al virtual, como el panel (`simulador` RF-14).
- Ambas líneas abiertas (S1 y S2): solo para prueba del instructor; el escenario no la ofrece.
- Lectura reportada "otra": se registra como error de medición sin penalizar la interpretación.

## Fuera de alcance
- Red CAN real o diagnóstico de buses de comunicación.
- Verificar con el Arduino dónde pone las puntas el técnico.
- Motorización de la puerta o piezas móviles del banco.
- Entrada libre de valores numéricos; se usan opciones.
- Alto voltaje y cualquier conexión a un vehículo real.

## Criterios de finalización
- Todos los RF con prueba (automática para el modelo eléctrico, las lecturas, los errores y el escenario; checklist manual para la escena, el multímetro y el banco físico) en verde.
- Demo manual: aviso en la cabina, medir TP1 y TP2 en el banco, registrar lecturas, diagnosticar, reparar y ver en el resumen si el error fue de medición o de interpretación, con las dos variantes.
- Si hay banco físico: las tres filas de la tabla se comprueban con un multímetro real antes de conectar el simulador.

## Ajustes tras la prueba con el equipo (24/11/2026)
- Hay un solo multímetro, el de mano, que nace sobre la mesa del banco; al tomarlo, el de la mesa queda apagado y la lectura se ve en el de la mano.
- Anota las dos lecturas y la causa en la **hoja de diagnóstico** de la mesa. Pulsa **Guardar hoja** para registrar las tres respuestas. Usa la misma hoja con el banco físico.
- Las puntas son visibles: cables y pinzas negra y roja, un indicador "Punta negra / Punta roja" y avisos de apuntado por punta.
- La orden tiene cuatro misiones: medir TP1 y TP2, anotar las lecturas, identificar la causa y reparar. Elige **Reconectar conductor** en el conductor del banco y confirma con el panel virtual o con el interruptor del banco físico.

- (Cambio posterior) La causa de la falla ya no se anota en la hoja: se responde en la pregunta de cierre de la orden. La hoja solo guarda las lecturas de TP1 y TP2, y el banco tiene tres misiones: medir, anotar las lecturas y reparar. El error `lectura-mal-interpretada` se registra al cierre cuando las lecturas son correctas y la causa elegida no.

## Decisiones
- Se construyen el banco **virtual y el físico**; el virtual es el respaldo.
- El banco físico usa un **Arduino Uno R3 aparte**, sin tocar el panel de torque.
- En la demo el técnico usa un **multímetro real**: lo que mide se registra como `lectura-reportada` y el multímetro virtual queda de respaldo.

## Dudas abiertas
- [NECESITA ACLARACIÓN] Fecha en que estará armado el banco físico.
