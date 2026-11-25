"""Cliente del agente de Azure AI Foundry para la página de materiales.

Es el mismo protocolo que usa el juego (godot/logica/aprendizaje/foundry.gd): API Responses del
agente con búsqueda en los manuales, token de Microsoft Entra de la CLI de Azure y el esquema en el
mensaje. Configuración (nunca en git): variables de entorno o el archivo .env de la raíz.
"""

import json
import os
import shutil
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
API = "v1"
RECURSO_TOKEN = "https://ai.azure.com"
VIGENCIA_TOKEN_S = 3000
MAX_FUENTES = 6
# Si la terminal se abrió antes de instalar la CLI, su PATH aún no la incluye.
RUTAS_AZ = tuple(Path(base) / "Microsoft SDKs" / "Azure" / "CLI2" / "wbin" / "az.cmd"
                 for base in (os.environ.get("ProgramFiles", r"C:\Program Files"),
                              os.environ.get("ProgramFiles(x86)", r"C:\Program Files (x86)")))


class ErrorFoundry(Exception):
    """Fallo de configuración, red o respuesta; el mensaje se puede mostrar al autor."""


def leer_env(ruta):
    datos = {}
    try:
        lineas = Path(ruta).read_text(encoding="utf-8").splitlines()
    except OSError:
        return datos
    for linea in lineas:
        texto = linea.strip()
        if texto.startswith("#") or "=" not in texto:
            continue
        clave, valor = texto.split("=", 1)
        datos[clave.strip()] = valor.strip().strip('"')
    return datos


ARCHIVOS_ENV = (RAIZ / ".env", RAIZ / "godot" / ".env")


def cargar_config(env=None, archivo_env=None):
    """endpoint, agente y token opcional. NACIONAL_SIN_NUBE=1 apaga la nube (pruebas).

    Lee el .env de la raíz y, si falta una clave, el de godot/ (la raíz tiene prioridad).
    """
    entorno = os.environ if env is None else env
    if entorno.get("NACIONAL_SIN_NUBE") == "1":
        return {}
    dotenv = {}
    for ruta in ((archivo_env,) if archivo_env else reversed(ARCHIVOS_ENV)):
        dotenv.update(leer_env(ruta))

    def valor(clave):
        return entorno.get(clave) or dotenv.get(clave) or ""

    config = {
        "endpoint": valor("NACIONAL_FOUNDRY_ENDPOINT"),
        # Agente propio para materiales; si no existe, el mismo de la ruta (Faro).
        "agente": valor("NACIONAL_FOUNDRY_AGENTE_MATERIALES") or valor("NACIONAL_FOUNDRY_AGENTE") or "Faro",
        "token": valor("NACIONAL_FOUNDRY_TOKEN"),
        # Tenant de Entra donde está el recurso de Foundry (si la cuenta tiene varios).
        "tenant": valor("NACIONAL_FOUNDRY_TENANT"),
        "espera": float(valor("NACIONAL_FOUNDRY_ESPERA_S") or 90),
    }
    return config if config["endpoint"].startswith("https://") else {}


def limpiar_json(texto):
    limpio = texto.strip()
    if limpio.startswith("```"):
        limpio = limpio[limpio.find("\n") + 1:]
        if limpio.rstrip().endswith("```"):
            limpio = limpio.rstrip()[:-3]
    return limpio.strip()


def fuentes_de(salida_mcp):
    """Nombres de PDF de los documentos que devolvió la base de conocimiento."""
    nombres = []
    try:
        datos = json.loads(salida_mcp)
    except (TypeError, ValueError):
        return nombres
    documentos = datos.get("documents") if isinstance(datos, dict) else None
    for documento in documentos if isinstance(documentos, list) else []:
        contenido = documento.get("content") if isinstance(documento, dict) else None
        try:
            interno = json.loads(contenido) if isinstance(contenido, str) else None
        except ValueError:
            continue
        if not isinstance(interno, dict):
            continue
        origen = str(interno.get("blob_url", ""))
        nombre = urllib.parse.unquote(origen.rsplit("/", 1)[-1])
        if nombre.lower().endswith(".pdf") and nombre not in nombres:
            nombres.append(nombre)
    return nombres


def extraer(cuerpo):
    """Del cuerpo de la API Responses: (json_del_modelo, pdf_devueltos). Lanza ErrorFoundry si no sirve."""
    try:
        externo = json.loads(cuerpo)
    except ValueError as error:
        raise ErrorFoundry("La respuesta de Foundry no es JSON.") from error
    salida = externo.get("output") if isinstance(externo, dict) else None
    if externo.get("status") != "completed" or not isinstance(salida, list):
        raise ErrorFoundry("Foundry no completó la respuesta.")
    texto = ""
    fuentes = []
    for elemento in salida:
        if not isinstance(elemento, dict):
            continue
        if elemento.get("type") == "message" and isinstance(elemento.get("content"), list):
            for parte in elemento["content"]:
                if isinstance(parte, dict) and parte.get("type") == "output_text" and isinstance(parte.get("text"), str):
                    texto = parte["text"]
        elif elemento.get("type") == "mcp_call" and isinstance(elemento.get("output"), str):
            for nombre in fuentes_de(elemento["output"]):
                if nombre not in fuentes and len(fuentes) < MAX_FUENTES:
                    fuentes.append(nombre)
    try:
        datos = json.loads(limpiar_json(texto))
    except ValueError as error:
        raise ErrorFoundry("El agente no devolvió un JSON válido.") from error
    if not isinstance(datos, dict):
        raise ErrorFoundry("El agente no devolvió un objeto JSON.")
    return datos, fuentes


class ClienteFoundry:
    def __init__(self, config=None):
        self.config = cargar_config() if config is None else config
        self._token = ""
        self._token_hasta = 0.0

    def disponible(self):
        return bool(self.config.get("endpoint", "").startswith("https://"))

    def url(self):
        base = self.config["endpoint"].rstrip("/")
        agente = urllib.parse.quote(self.config.get("agente", "Faro"), safe="")
        return f"{base}/agents/{agente}/endpoint/protocols/openai/responses?api-version={API}"

    def token(self):
        if self.config.get("token"):
            return self.config["token"]
        if self._token and time.time() < self._token_hasta:
            return self._token
        az = shutil.which("az") or next((str(r) for r in RUTAS_AZ if r.exists()), None)
        if not az:
            raise ErrorFoundry("No se encontró la CLI de Azure (az). Instálala y haz «az login».")
        comando = [az, "account", "get-access-token", "--resource", RECURSO_TOKEN, "--query", "accessToken", "-o", "tsv"]
        if self.config.get("tenant"):
            comando += ["--tenant", self.config["tenant"]]
        try:
            salida = subprocess.run(
                comando,
                capture_output=True, text=True, timeout=60, check=False)
        except (OSError, subprocess.TimeoutExpired) as error:
            raise ErrorFoundry("No se pudo pedir el token a la CLI de Azure.") from error
        if salida.returncode != 0 or not salida.stdout.strip():
            raise ErrorFoundry("La CLI de Azure no dio un token. Haz «az login».")
        self._token = salida.stdout.strip()
        self._token_hasta = time.time() + VIGENCIA_TOKEN_S
        return self._token

    def generar(self, instruccion, contexto, esquema):
        """Envía la instrucción y el esquema; devuelve (json_del_modelo, pdf_devueltos)."""
        if not self.disponible():
            raise ErrorFoundry("Foundry no está configurado.")
        texto = (f"{instruccion}\nConsulta los manuales y responde solo con un JSON que cumpla este esquema:\n"
                 f"{json.dumps(esquema, ensure_ascii=False)}\nContexto:\n{json.dumps(contexto, ensure_ascii=False)}")
        peticion = urllib.request.Request(
            self.url(), method="POST",
            data=json.dumps({"input": texto, "store": False}).encode("utf-8"),
            headers={"Content-Type": "application/json", "Authorization": "Bearer " + self.token()})
        try:
            with urllib.request.urlopen(peticion, timeout=self.config.get("espera", 90)) as respuesta:
                cuerpo = respuesta.read().decode("utf-8")
        except urllib.error.HTTPError as error:
            raise ErrorFoundry(f"Foundry respondió con el código {error.code}.") from error
        except (urllib.error.URLError, TimeoutError, OSError) as error:
            raise ErrorFoundry("No hubo conexión con Foundry o tardó demasiado.") from error
        return extraer(cuerpo)
