"""Catálogo de modelos de autobús, niveles, formatos y competencias (estas últimas del banco)."""

import json
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
CATALOGO = RAIZ / "contenido" / "catalogo-materiales.json"
BANCO = RAIZ / "contenido" / "banco.json"


class ErrorSeleccion(ValueError):
    """Un modelo, nivel, competencia o formato que no existe."""


class Catalogo:
    def __init__(self, ruta_catalogo=CATALOGO, ruta_banco=BANCO):
        self.datos = json.loads(Path(ruta_catalogo).read_text(encoding="utf-8"))
        self.banco = json.loads(Path(ruta_banco).read_text(encoding="utf-8"))
        self.modelos = {m["id"]: m for m in self.datos["modelos"]}
        self.niveles = {n["id"]: n for n in self.datos["niveles"]}
        self.formatos = {f["id"]: f for f in self.datos["formatos"]}
        self.competencias = {c["id"]: c for c in self.banco["competencias"]}

    def basicos(self):
        return list(self.datos["enfoques"]["basicos"])

    def publico(self):
        return {
            "modelos": self.datos["modelos"],
            "niveles": self.datos["niveles"],
            "formatos": self.datos["formatos"],
            "competencias": self.banco["competencias"],
            "enfoques": self.datos["enfoques"],
            "enfoque_por_defecto": self.datos["enfoque_por_defecto"],
        }

    def comprobar(self, formato, modelo, nivel, competencia):
        for campo, valor, opciones in (("formato", formato, self.formatos), ("modelo", modelo, self.modelos),
                                       ("nivel", nivel, self.niveles), ("competencia", competencia, self.competencias)):
            if valor not in opciones:
                raise ErrorSeleccion(f"{campo}: «{valor}» no está en el catálogo")
