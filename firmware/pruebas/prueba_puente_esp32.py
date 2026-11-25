import json
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "..", "tools"))
from puente_esp32 import Traductor


def lineas(traductor, datagrama, t=0):
    return [json.loads(l) for l in traductor.traducir(datagrama, t)]


t = Traductor()
inicial = lineas(t, b'{"tp1":1,"tp2":0}')
assert [(m["ctrl"], m["valor"]) for m in inicial] == [("nodo_p", 1), ("nodo_q", 0)], inicial
assert all(m["v"] == 1 for m in inicial)
assert [m["n"] for m in inicial] == [1, 2]
assert lineas(t, b'{"tp1":1,"tp2":0}') == []
cambio = lineas(t, b'{"tp1":1,"tp2":1}', 500)
assert [(m["ctrl"], m["valor"], m["n"], m["t"]) for m in cambio] == [("nodo_q", 1, 3, 500)], cambio
assert lineas(t, b"basura") == []
assert lineas(t, b'{"tp1":true,"tp2":7}') == []
assert json.loads(t.latido()) == {"v": 1, "ctrl": "hb"}
print("OK: puente_esp32")
