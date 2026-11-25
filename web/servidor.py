"""Página web de materiales de estudio (SPEC-materiales).

Uso, desde la raíz del repositorio:
    python web/servidor.py            # http://127.0.0.1:8765
    python web/servidor.py --puerto 9000

Sin dependencias: solo la biblioteca estándar de Python 3.
"""

import argparse
import hmac
import json
import mimetypes
import os
import re
import secrets
import sys
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, quote, urlparse

sys.path.insert(0, str(Path(__file__).resolve().parent))

from logica import asignacion  # noqa: E402
from logica.almacen import Almacen, NoEncontrado  # noqa: E402
from logica.catalogo import Catalogo, ErrorSeleccion  # noqa: E402
from logica.foundry import ClienteFoundry  # noqa: E402
from logica.generador import ErrorGeneracion, Generador, requiere_doble_revision  # noqa: E402

PUBLICO = Path(__file__).resolve().parent / "publico"
FUENTES = Path(__file__).resolve().parents[1] / "godot" / "assets" / "fuentes"
MAX_CUERPO = 256 * 1024
MAX_REVISOR = 40
RUTA_TOKEN = Path(__file__).resolve().parent / ".token-autor"
COOKIE = "autor"
COOKIE_USUARIO = "usuario"
COOKIE_RUTA = "ruta"
FORMATO_USUARIO = re.compile(r"^[a-z0-9][a-z0-9._-]{2,23}$")
SOLO_AUTOR = "Solo el jefe directo o la administración pueden hacer esto. Entra desde la app con tu cuenta."
FILTROS = ("modelo", "nivel", "competencia", "formato", "estado")


def cargar_token(ruta=RUTA_TOKEN):
    """Permiso de autor: lo lee la app de Godot para jefe directo y admin. Se crea una vez, solo legible por su dueño."""
    try:
        token = Path(ruta).read_text(encoding="utf-8").strip()
        if len(token) >= 32:
            return token
    except OSError:
        pass
    token = secrets.token_urlsafe(32)
    descriptor = os.open(ruta, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(descriptor, "w", encoding="utf-8") as archivo:
        archivo.write(token + "\n")
    return token


class Aplicacion:
    """`token_autor=None` deja todo abierto (pruebas y uso por código); `main` siempre exige el permiso."""

    def __init__(self, catalogo=None, almacen=None, cliente=None, token_autor=None):
        self.token_autor = token_autor
        self.catalogo = catalogo or Catalogo()
        self.almacen = almacen or Almacen()
        self.generador = Generador(self.catalogo, self.almacen, ClienteFoundry() if cliente is None else cliente)

    def con_marcas(self, material):
        material = dict(material)
        material["doble_revision"] = requiere_doble_revision(material)
        return material

    def listar(self, consulta):
        vista = consulta.get("vista", "tecnico")
        niveles = consulta.get("niveles")
        niveles = set(niveles.split(",")) if niveles else None
        orden_niveles = list(self.catalogo.niveles)
        resultado = []
        for material in self.almacen.listar():
            if vista != "autor" and material.get("estado") != "revisado":
                continue  # RF-11: el técnico solo ve lo revisado.
            if niveles and material.get("nivel") not in niveles:
                continue
            if any(consulta.get(campo) and material.get(campo) != consulta[campo] for campo in FILTROS):
                continue
            resultado.append(self.con_marcas(material))
        resultado.sort(key=lambda m: (orden_niveles.index(m["nivel"]) if m["nivel"] in orden_niveles else 99,
                                      m["modelo"], m["competencia"], m["titulo"]))
        return resultado


class Manejador(BaseHTTPRequestHandler):
    app: Aplicacion = None
    server_version = "MaterialesNacional/1"

    def log_message(self, formato, *args):  # Sin datos de la petición en consola.
        pass

    # --- Permiso de autor ---

    def _es_autor(self):
        esperado = self.app.token_autor
        if esperado is None:
            return True
        for cookie in (self.headers.get("Cookie") or "").split(";"):
            nombre, _, valor = cookie.strip().partition("=")
            if nombre == COOKIE and hmac.compare_digest(valor.encode(), esperado.encode()):
                return True
        return False

    def _cookie(self, nombre):
        for cookie in (self.headers.get("Cookie") or "").split(";"):
            clave, _, valor = cookie.strip().partition("=")
            if clave == nombre:
                return valor
        return ""

    def _usuario(self):
        """Cuenta con la que se entró desde la app. Quien revisa queda registrado con ella, no con un texto libre."""
        if self.app.token_autor is None or not self._es_autor():
            return ""
        usuario = self._cookie(COOKIE_USUARIO)
        return usuario if FORMATO_USUARIO.match(usuario) else ""

    def _acceso(self, consulta):
        """Entrada desde la app. Con el token guarda el permiso de autor; el técnico entra sin permiso, pero con su
        ruta de aprendizaje, para ver primero los materiales que le tocan."""
        token = (consulta.get("token") or [""])[0]
        esperado = self.app.token_autor
        self.send_response(HTTPStatus.SEE_OTHER)
        if esperado is not None and hmac.compare_digest(token.encode(), esperado.encode()):
            self.send_header("Set-Cookie", f"{COOKIE}={quote(esperado)}; Path=/; HttpOnly; SameSite=Strict")
        usuario = (consulta.get("usuario") or [""])[0]
        if FORMATO_USUARIO.match(usuario):
            self.send_header("Set-Cookie", f"{COOKIE_USUARIO}={usuario}; Path=/; HttpOnly; SameSite=Strict")
        if consulta.get("ruta"):
            ruta = asignacion.leer_ruta(consulta["ruta"][0], self.app.catalogo.competencias)
            texto = ".".join(f"{c}~{d:g}" for c, d in ruta)
            self.send_header("Set-Cookie", f"{COOKIE_RUTA}={texto}; Path=/; HttpOnly; SameSite=Strict")
        self.send_header("Location", "/")
        self.send_header("Content-Length", "0")
        self.end_headers()

    # --- Respuestas ---

    def _json(self, estado, datos):
        cuerpo = json.dumps(datos, ensure_ascii=False).encode("utf-8")
        self.send_response(estado)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(cuerpo)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(cuerpo)

    def _error(self, estado, mensaje, detalles=None):
        self._json(estado, {"error": mensaje, "detalles": detalles or []})

    def _cuerpo(self):
        largo = int(self.headers.get("Content-Length") or 0)
        if largo > MAX_CUERPO:
            raise ErrorGeneracion("La petición es demasiado grande.")
        try:
            datos = json.loads(self.rfile.read(largo).decode("utf-8") or "{}")
        except (UnicodeDecodeError, ValueError) as error:
            raise ErrorGeneracion("El cuerpo no es JSON válido.") from error
        if not isinstance(datos, dict):
            raise ErrorGeneracion("El cuerpo debe ser un objeto JSON.")
        return datos

    def _estatico(self, ruta):
        nombre = "index.html" if ruta in ("", "/") else ruta.lstrip("/")
        base = PUBLICO
        if nombre.startswith("fuentes/"):  # Poppins del juego, sin duplicar binarios.
            base, nombre = FUENTES, nombre.removeprefix("fuentes/")
        archivo = (base / nombre).resolve()
        if base.resolve() not in archivo.parents or not archivo.is_file() or archivo.suffix == ".import":
            return self._error(HTTPStatus.NOT_FOUND, "No existe.")
        datos = archivo.read_bytes()
        tipo = mimetypes.guess_type(archivo.name)[0] or "application/octet-stream"
        if tipo.startswith("text/") or tipo == "application/javascript":
            tipo += "; charset=utf-8"
        self.send_response(HTTPStatus.OK)
        self.send_header("Content-Type", tipo)
        self.send_header("Content-Length", str(len(datos)))
        self.send_header("X-Content-Type-Options", "nosniff")
        self.end_headers()
        self.wfile.write(datos)

    # --- Rutas ---

    def _atender(self, metodo):
        url = urlparse(self.path)
        partes = [p for p in url.path.split("/") if p]
        app = self.app
        try:
            if partes == ["acceso"] and metodo == "GET":
                return self._acceso(parse_qs(url.query))
            if not partes or partes[0] != "api":
                if metodo != "GET":
                    return self._error(HTTPStatus.METHOD_NOT_ALLOWED, "Método no permitido.")
                if url.path == "/favicon.ico":
                    self.send_response(HTTPStatus.NO_CONTENT)
                    return self.end_headers()
                return self._estatico(url.path)
            ruta = partes[1:]
            autor = self._es_autor()
            if metodo == "GET" and ruta == ["estado"]:
                return self._json(HTTPStatus.OK, {"ia": app.generador.ia_disponible(), "autor": autor, "usuario": self._usuario()})
            if metodo == "GET" and ruta == ["asignados"]:
                lista = asignacion.leer_ruta(self._cookie(COOKIE_RUTA), app.catalogo.competencias)
                return self._json(HTTPStatus.OK, {"pasos": asignacion.asignar(
                    [app.con_marcas(m) for m in app.almacen.listar()], lista)})
            if not autor and (metodo != "GET" or "vista=autor" in url.query):
                return self._error(HTTPStatus.FORBIDDEN, SOLO_AUTOR)
            if metodo == "GET" and ruta == ["catalogo"]:
                return self._json(HTTPStatus.OK, app.catalogo.publico())
            if metodo == "GET" and ruta == ["materiales"]:
                consulta = {k: v[0] for k, v in parse_qs(url.query).items()}
                return self._json(HTTPStatus.OK, {"materiales": app.listar(consulta)})
            if metodo == "POST" and ruta == ["materiales"]:
                datos = self._cuerpo()
                material = app.generador.generar(datos.get("formato"), datos.get("modelo"), datos.get("nivel"),
                                                 datos.get("competencia"), datos.get("tema"))
                return self._json(HTTPStatus.CREATED, app.con_marcas(material))
            if len(ruta) >= 2 and ruta[0] == "materiales":
                id_material = ruta[1]
                accion = ruta[2] if len(ruta) == 3 else ""
                if len(ruta) > 3:
                    return self._error(HTTPStatus.NOT_FOUND, "No existe.")
                if metodo == "GET" and not accion:
                    material = app.almacen.obtener(id_material)
                    if not autor and material.get("estado") != "revisado":
                        raise NoEncontrado(id_material)  # El técnico no ve borradores ni por dirección directa.
                    return self._json(HTTPStatus.OK, app.con_marcas(material))
                if metodo == "PUT" and not accion:
                    datos = self._cuerpo()
                    material = app.generador.editar(id_material, datos.get("titulo"), datos.get("contenido"),
                                                    datos.get("motivo") or "Edición manual")
                    return self._json(HTTPStatus.OK, app.con_marcas(material))
                if metodo == "DELETE" and not accion:
                    app.almacen.eliminar(id_material)
                    return self._json(HTTPStatus.OK, {"eliminado": id_material})
                if metodo == "POST" and accion == "actualizar":
                    material = app.generador.actualizar(id_material, self._cuerpo().get("indicacion"))
                    return self._json(HTTPStatus.OK, app.con_marcas(material))
                if metodo == "POST" and accion == "retirar":
                    return self._json(HTTPStatus.OK, app.con_marcas(app.almacen.retirar(id_material)))
                if metodo == "POST" and accion == "revisar":
                    app.almacen.obtener(id_material)  # 404 antes de validar el cuerpo.
                    revisor = self._usuario() or " ".join(str(self._cuerpo().get("revisor") or "").split())
                    if not revisor or len(revisor) > MAX_REVISOR:
                        raise ErrorGeneracion(f"Escribe el alias de quien revisó (hasta {MAX_REVISOR} caracteres).")
                    return self._json(HTTPStatus.OK, app.con_marcas(app.almacen.revisar(id_material, revisor)))
            return self._error(HTTPStatus.NOT_FOUND, "No existe.")
        except NoEncontrado:
            return self._error(HTTPStatus.NOT_FOUND, "Ese material no existe.")
        except ErrorSeleccion as error:
            return self._error(HTTPStatus.BAD_REQUEST, str(error))
        except ErrorGeneracion as error:
            return self._error(HTTPStatus.UNPROCESSABLE_ENTITY, str(error), error.detalles)

    def do_GET(self):
        self._atender("GET")

    def do_POST(self):
        self._atender("POST")

    def do_PUT(self):
        self._atender("PUT")

    def do_DELETE(self):
        self._atender("DELETE")


def crear_servidor(app, host="127.0.0.1", puerto=8765):
    manejador = type("ManejadorApp", (Manejador,), {"app": app})
    return ThreadingHTTPServer((host, puerto), manejador)


def main():
    argumentos = argparse.ArgumentParser(description="Página web de materiales de estudio.")
    argumentos.add_argument("--host", default="127.0.0.1")
    argumentos.add_argument("--puerto", type=int, default=8765)
    argumentos.add_argument("--materiales", help="Carpeta de materiales (por defecto contenido/materiales)")
    opciones = argumentos.parse_args()
    token = cargar_token()
    app = Aplicacion(almacen=Almacen(opciones.materiales) if opciones.materiales else None, token_autor=token)
    servidor = crear_servidor(app, opciones.host, opciones.puerto)
    ia = "con IA (Foundry)" if app.generador.ia_disponible() else "sin IA (respaldo desde el banco)"
    print(f"Materiales de estudio {ia}: http://{opciones.host}:{opciones.puerto}")
    print("Vista de autor: se abre desde la app de Godot con una cuenta de jefe directo o admin.")
    try:
        servidor.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        servidor.server_close()


if __name__ == "__main__":
    main()
