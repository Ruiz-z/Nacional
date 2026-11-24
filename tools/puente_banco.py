"""Reenvía líneas del banco desde el puerto serial de Linux a Godot por UDP local."""

import socket
import subprocess
import sys


def reenviar(lineas):
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as salida:
        for linea in lineas:
            salida.sendto(linea, ("127.0.0.1", 11521))


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("Uso: python3 tools/puente_banco.py /dev/ttyACM0")
    puerto = sys.argv[1]
    try:
        if puerto == "-":
            reenviar(sys.stdin.buffer)
        else:
            subprocess.run(
                ["stty", "-F", puerto, "115200", "raw", "-echo", "-ixon", "-ixoff"],
                check=True,
            )
            with open(puerto, "rb") as serial:
                reenviar(serial)
    except KeyboardInterrupt:
        pass
    except (OSError, subprocess.CalledProcessError) as error:
        sys.exit(f"Se cerró el enlace del banco: {error}")
