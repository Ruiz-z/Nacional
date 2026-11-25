"""Materiales asignados a un técnico según su ruta de aprendizaje.

La app de Godot calcula la ruta (competencias de la más débil a la más fuerte) y el dominio de cada una,
y los entrega al abrir la página con la forma «competencia~dominio.competencia~dominio».
"""

NIVELES = ("novato", "basico", "competente", "experto")
MAX_PASOS = 8


def nivel_de(dominio):
    """Mismos cortes que Dominio.nivel en la app: 40, 70 y 90."""
    if dominio < 40:
        return "novato"
    if dominio < 70:
        return "basico"
    return "competente" if dominio < 90 else "experto"


def leer_ruta(texto, competencias):
    """Devuelve [(competencia, dominio)] en el orden recibido; ignora lo que no se reconoce."""
    ruta = []
    for par in str(texto or "").split(".")[:MAX_PASOS]:
        competencia, _, dominio = par.partition("~")
        try:
            valor = float(dominio)
        except ValueError:
            continue
        if competencia in competencias and 0 <= valor <= 100 and competencia not in [c for c, _ in ruta]:
            ruta.append((competencia, valor))
    return ruta


def asignar(materiales, ruta):
    """Un paso por competencia de la ruta, con los materiales publicados de su nivel y del siguiente."""
    pasos = []
    for indice, (competencia, dominio) in enumerate(ruta, start=1):
        propio = nivel_de(dominio)
        posicion = NIVELES.index(propio)
        permitidos = set(NIVELES[posicion:posicion + 2])
        lista = [m for m in materiales
                 if m.get("estado") == "revisado" and m.get("competencia") == competencia
                 and m.get("nivel") in permitidos]
        lista.sort(key=lambda m: (NIVELES.index(m["nivel"]), m.get("titulo", "")))
        pasos.append({"paso": indice, "competencia": competencia, "dominio": round(dominio),
                      "nivel": propio, "materiales": lista})
    return pasos
