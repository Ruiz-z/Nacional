# Firmware del panel

Maqueta de bajo voltaje alimentada por USB. Usa el pin GND de la placa como tierra común.

## Cableado

| Componente | ESP32 Dev Module (ESP32 clásico) | Arduino Uno R3 | Conexión |
| --- | --- | --- | --- |
| Interruptor de bloqueo | GPIO 18 | D2 | Entre pin y GND |
| Interruptor de etiquetado | GPIO 19 | D3 | Entre pin y GND |
| Botón confirmar | GPIO 21 | D4 | Entre pin y GND |
| Botón cancelar | GPIO 22 | D5 | Entre pin y GND |
| Perilla de torque | GPIO 34 | A0 | Terminal central al pin, extremos a GND y a 3,3 V en ESP32 o 5 V en Uno |
| LED energizado | GPIO 25 | D6 | Pin → resistencia de 330 Ω → ánodo. Cátodo a GND |
| LED bloqueado | GPIO 26 | D7 | Pin → resistencia de 330 Ω → ánodo. Cátodo a GND |
| LED falla | GPIO 27 | D8 | Pin → resistencia de 330 Ω → ánodo. Cátodo a GND |

Los interruptores y botones usan las resistencias pull-up internas. Cerrarlos a GND equivale a `1`. Para otra placa, revisa el bloque de pines y la resolución del ADC en `panel/panel.ino`. Para T-05 basta con montar el botón confirmar y el LED falla. Conecta temporalmente la entrada de torque a GND si la perilla aún no está montada.

## Carga

- **Arduino IDE.** Abre `firmware/panel/panel.ino`. En el gestor de placas usa el core correspondiente (Arduino AVR Boards para Uno R3 o esp32 de Espressif para ESP32). Selecciona la placa y el puerto USB en **Herramientas** y pulsa **Subir**.
- **arduino-cli.** Con el core correspondiente disponible, ejecuta desde la raíz y sustituye el puerto por el que muestra `arduino-cli board list`. Para ESP32 Dev Module cambia el FQBN a `esp32:esp32:esp32`.

```sh
arduino-cli board list
placa=arduino:avr:uno
puerto=/dev/ttyACM0
arduino-cli compile --fqbn "$placa" firmware/panel
arduino-cli upload --fqbn "$placa" --port "$puerto" firmware/panel
```

El puerto usa 115200 baudios. Al arrancar se publican los estados de ambos interruptores y el torque. Los botones emiten solo al pulsar y los LEDs arrancan apagados. La perilla se muestrea cada 10 ms con un promedio móvil de ocho muestras. Cuando cambia el valor redondeado, los eventos de torque se separan al menos 50 ms.

## Prueba de humo de T-05 (30 minutos)

1. **Min 0–5.** Monta el botón confirmar y el LED falla, carga el firmware y localiza el puerto. Cierra el monitor serial para dejar libre el puerto. Desde la raíz ejecuta `godot --headless --no-header -s tools/emisor_eventos.gd`. Guarda una línea de `confirmar` como referencia para comparar sus campos con el evento físico.
2. **Min 5–10.** Abre una sesión física con el plugin serial del simulador, si está disponible. Haz que la recepción de `confirmar` con `valor:1` envíe el estado del LED falla por el mismo puerto. Para probar el camino alternativo con la referencia del emisor, usa el comando de Linux de abajo. Cada pulsación alterna el LED. Comprueba el latido cada segundo y verifica que la primera pulsación encienda el LED. Compara los campos con la línea del emisor. El orden de claves puede variar y cada emisor asigna su propio `n` y `t`.
3. **Min 10–20.** Pulsa varias veces, deja el botón presionado y después suéltalo. Comprueba que cada pulsación genere un solo evento, que el LED cambie una sola vez y que los latidos continúen. Verifica que `n` aumente entre eventos de control y que `t` esté en milisegundos.
4. **Min 20–25.** Desconecta el USB durante más de tres segundos. Si estás usando el simulador, comprueba la pausa, el aviso y el paso al panel virtual. Vuelve a conectar, abre una sesión física nueva y repite la prueba de botón y LED. Con el comando de abajo, vuelve a ejecutarlo tras reconectar.
5. **Min 25–30.** Registra en `SPEC-panel.md` la placa, el transporte probado, si respondió el LED, si hubo duplicados y qué pasó al reconectar. Registra la decisión de conservar el plugin serial o usar el puente Python hacia UDP local. El comando de abajo comprueba el enlace USB en ambos sentidos; la integración con Godot se verifica desde el simulador.

### Host de prueba en Linux

Ejecuta en una terminal con el puerto de tu placa. Usa Python 3 con su biblioteca estándar. Detén con Ctrl+C.

```sh
python3 - /dev/ttyACM0 <<'PY'
import json
import os
import subprocess
import sys

puerto = sys.argv[1]
subprocess.run(["stty", "-F", puerto, "115200", "raw", "-echo", "-ixon", "-ixoff"],
               check=True)
led = 0
with open(puerto, "r+b", buffering=0) as serial:
    pendientes = b""
    while True:
        bloque = os.read(serial.fileno(), 256)
        if not bloque:
            break
        *lineas, pendientes = (pendientes + bloque).split(b"\n")
        for linea in lineas:
            try:
                evento = json.loads(linea)
            except (ValueError, UnicodeError):
                continue
            print(evento, flush=True)
            if (evento.get("v"), evento.get("ctrl"), evento.get("valor")) == (1, "confirmar", 1):
                led = 1 - led
                orden = {"v": 1, "led": "falla", "valor": led}
                serial.write((json.dumps(orden) + "\n").encode("ascii"))
PY
```

## Verificación de escritorio y maqueta

Ejecuta `firmware/pruebas/correr.sh` con g++. Compara las líneas de eventos y el latido con el protocolo y comprueba las tres órdenes LED documentadas.

Para T-56, etiqueta cada componente y verifica en la maqueta ambos estados de los interruptores, el recorrido de torque de 0 a 100, una pulsación por cada botón y el encendido y apagado de cada LED desde el host.
