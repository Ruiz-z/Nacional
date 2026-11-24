# Firmware del banco de arnés

**Maqueta didáctica de 5 V por USB.** Usa un Arduino Uno R3 dedicado y etiqueta la maqueta. Conecta únicamente los elementos de la tabla. Mantén el banco separado del autobús y de cualquier instalación real.

## Cableado

| Pin o punto | Componente y conexión |
| --- | --- |
| USB | Alimentación de 5 V y datos hacia la computadora |
| 5V | Alimenta un terminal de S1 y un terminal de S2, en el lado J1 |
| P / A1 | Otro terminal de S1, R1 de 10 kΩ hacia GND y R3 de 1 kΩ hacia TP1 |
| Q / A2 | Otro terminal de S2, R2 de 10 kΩ hacia GND y R4 de 1 kΩ hacia TP2 |
| GND / TP0 | Tierra común de J1 y J2 y retorno de R1 y R2 |

Coloca P, Q y los bornes del lado de J2, después de los interruptores.

## Carga y comprobación

1. Abre `firmware/banco/banco.ino` en Arduino IDE. Selecciona **Arduino Uno** del paquete **Arduino AVR Boards**, selecciona el puerto USB y pulsa **Subir**.
2. Abre el monitor serial a 115200 baudios. Comprueba que se envía un latido y el estado de ambos nodos cada segundo. Cambia S1 o S2 y comprueba que se emite el estado tras 50 ms estables. Cierra el monitor antes de usar el simulador.
3. Pon el multímetro en voltaje continuo. Deja la punta negra en TP0 y mueve la roja entre TP1 y TP2.

| S1 | S2 | TP1 | TP2 | `nodo_p` | `nodo_q` |
| --- | --- | ---: | ---: | ---: | ---: |
| Cerrado | Cerrado | ≈5 V | ≈5 V | 1 | 1 |
| Abierto | Cerrado | ≈0 V | ≈5 V | 0 | 1 |
| Cerrado | Abierto | ≈5 V | ≈0 V | 1 | 0 |

Ejecuta `firmware/pruebas/correr.sh` desde la raíz para comprobar la lógica y comparar los mensajes con los ejemplos del protocolo.
