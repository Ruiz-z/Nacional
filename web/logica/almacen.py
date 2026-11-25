"""Almacén de materiales: un archivo JSON por material en contenido/materiales/.

Los materiales viven en git como el resto del contenido, así el historial y la revisión quedan trazables.
"""

import json
import os
import re
import secrets
import tempfile
import unicodedata
from datetime import datetime
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
CARPETA = RAIZ / "contenido" / "materiales"
PATRON_ID = re.compile(r"^[a-z0-9-]{1,80}$")
MAX_HISTORIAL = 10


class NoEncontrado(KeyError):
    pass


def ahora():
    return datetime.now().astimezone().isoformat(timespec="seconds")


def slug(texto, maximo=40):
    plano = unicodedata.normalize("NFKD", texto).encode("ascii", "ignore").decode("ascii").lower()
    return re.sub(r"[^a-z0-9]+", "-", plano).strip("-")[:maximo].strip("-") or "material"


def id_valido(id_material):
    return isinstance(id_material, str) and bool(PATRON_ID.match(id_material))


class Almacen:
    def __init__(self, carpeta=CARPETA):
        self.carpeta = Path(carpeta)
        self.carpeta.mkdir(parents=True, exist_ok=True)

    def _ruta(self, id_material):
        if not id_valido(id_material):
            raise NoEncontrado(id_material)
        return self.carpeta / f"{id_material}.json"

    def nuevo_id(self, formato, tema):
        while True:
            candidato = f"{slug(formato)}-{slug(tema)}-{secrets.token_hex(3)}"
            if not self._ruta(candidato).exists():
                return candidato

    def obtener(self, id_material):
        ruta = self._ruta(id_material)
        try:
            return json.loads(ruta.read_text(encoding="utf-8"))
        except FileNotFoundError as error:
            raise NoEncontrado(id_material) from error

    def listar(self):
        materiales = []
        for ruta in sorted(self.carpeta.glob("*.json")):
            try:
                materiales.append(json.loads(ruta.read_text(encoding="utf-8")))
            except (OSError, ValueError):
                continue  # Un archivo dañado no tumba el catálogo; el validador lo reporta.
        return materiales

    def guardar(self, material):
        ruta = self._ruta(material["id"])
        texto = json.dumps(material, ensure_ascii=False, indent=2) + "\n"
        descriptor, temporal = tempfile.mkstemp(dir=self.carpeta, suffix=".tmp")
        try:
            with os.fdopen(descriptor, "w", encoding="utf-8", newline="\n") as archivo:
                archivo.write(texto)
            os.replace(temporal, ruta)
        except BaseException:
            Path(temporal).unlink(missing_ok=True)
            raise
        return material

    def crear(self, *, formato, modelo, nivel, competencia, tema, titulo, contenido, fuentes, origen, muestra=False):
        fecha = ahora()
        material = {
            "id": self.nuevo_id(formato, tema),
            "formato": formato,
            "titulo": titulo,
            "modelo": modelo,
            "nivel": nivel,
            "competencia": competencia,
            "tema": tema,
            "contenido": contenido,
            "fuentes": fuentes,
            "origen": origen,
            "muestra": muestra,
            "estado": "borrador",
            "revisado_por": "",
            "revisado_en": "",
            "version": 1,
            "creado": fecha,
            "actualizado": fecha,
            "historial": [],
        }
        return self.guardar(material)

    def nueva_version(self, id_material, *, titulo, contenido, fuentes, origen, motivo):
        """Guarda la versión actual en el historial, sube la versión y regresa a borrador."""
        material = self.obtener(id_material)
        anterior = {clave: material[clave] for clave in
                    ("version", "actualizado", "titulo", "contenido", "fuentes", "origen", "estado", "revisado_por")}
        anterior["motivo_cambio"] = motivo
        material["historial"] = ([anterior] + material.get("historial", []))[:MAX_HISTORIAL]
        material.update(titulo=titulo, contenido=contenido, fuentes=fuentes, origen=origen,
                        estado="borrador", revisado_por="", revisado_en="",
                        version=int(material.get("version", 1)) + 1, actualizado=ahora())
        return self.guardar(material)

    def revisar(self, id_material, revisor):
        material = self.obtener(id_material)
        material.update(estado="revisado", revisado_por=revisor, revisado_en=ahora())
        return self.guardar(material)

    def eliminar(self, id_material):
        ruta = self._ruta(id_material)
        if not ruta.exists():
            raise NoEncontrado(id_material)
        ruta.unlink()
