"""Adaptador del banco con ESP32: traduce su UDP por Wi-Fi al protocolo del simulador.

La placa crea una red Wi-Fi y espera "INICIO" en UDP 4210. Después reporta
{"tp1":0,"tp2":1} cada 250 ms. El simulador espera eventos "nodo_p" y "nodo_q"
(protocolo v1) en 127.0.0.1:11521, además de un latido.

Uso: python3 tools/puente_esp32.py [ip_de_la_placa]   (por defecto 192.168.4.1)
"""

import json
import socket
import sys
import time

PUERTO_PLACA = 4210
DESTINO = ("127.0.0.1", 11521)
LATIDO_S = 1.0
REINTENTO_INICIO_S = 2.0


class Traductor:
    """Convierte lecturas {"tp1","tp2"} en líneas del protocolo del simulador."""

    def __init__(self):
        self.n = 0
        self.ultimo = {}

    def _linea(self, ctrl, valor, t_ms):
        self.n += 1
        mensaje = {"v": 1, "ctrl": ctrl, "valor": valor, "n": self.n, "t": t_ms}
        return (json.dumps(mensaje, separators=(",", ":")) + "\n").encode()

    def latido(self):
        return b'{"v":1,"ctrl":"hb"}\n'

    def traducir(self, datagrama, t_ms):
        """Devuelve las líneas nuevas: todas al inicio y solo los cambios después."""
        try:
            datos = json.loads(datagrama)
        except (ValueError, UnicodeDecodeError):
            return []
        if not isinstance(datos, dict):
            return []
        lineas = []
        for clave, ctrl in (("tp1", "nodo_p"), ("tp2", "nodo_q")):
            valor = datos.get(clave)
            if valor not in (0, 1) or isinstance(valor, bool):
                continue
            if self.ultimo.get(ctrl) != valor:
                self.ultimo[ctrl] = valor
                lineas.append(self._linea(ctrl, valor, t_ms))
        return lineas


def ejecutar(ip_placa):
    traductor = Traductor()
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as entrada, \
            socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as salida:
        entrada.settimeout(0.25)
        inicio = time.monotonic()
        ultimo_latido = 0.0
        ultimo_inicio = 0.0
        recibio = False
        ultimo_dato = 0.0
        while True:
            ahora = time.monotonic()
            if not recibio and ahora - ultimo_inicio >= REINTENTO_INICIO_S:
                entrada.sendto(b"INICIO", (ip_placa, PUERTO_PLACA))
                ultimo_inicio = ahora
            try:
                datagrama, _ = entrada.recvfrom(256)
                recibio = True
                ultimo_dato = ahora
                for linea in traductor.traducir(datagrama, int((ahora - inicio) * 1000)):
                    salida.sendto(linea, DESTINO)
            except socket.timeout:
                pass
            # El latido solo sale mientras la placa responde; sin él, Godot pasa a virtual.
            if recibio and ahora - ultimo_dato > 3 * LATIDO_S:
                recibio = False  # la placa calló: vuelve a pedir INICIO y deja de enviar latido
            if recibio and ahora - ultimo_latido >= LATIDO_S:
                salida.sendto(traductor.latido(), DESTINO)
                ultimo_latido = ahora


if __name__ == "__main__":
    placa = sys.argv[1] if len(sys.argv) > 1 else "192.168.4.1"
    try:
        ejecutar(placa)
    except KeyboardInterrupt:
        pass
    except OSError as error:
        sys.exit(f"Se cerró el enlace con el ESP32: {error}")
