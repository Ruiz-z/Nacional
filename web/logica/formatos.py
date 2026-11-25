"""Formatos de material de estudio: esquema que viaja a la IA y validación de lo que regresa.

Cada validador recibe el `contenido` propuesto y devuelve (contenido_limpio, errores).
Si hay errores, el material no se guarda (SPEC-materiales RF-5 y RF-9).
"""

import re
import unicodedata

MAX_TITULO = 90
MAX_AFIRMACION = 420
MAX_EXPLICACION_VF = 520
HUECO = r"(?<!_)____(?!_)"
FORMATOS = ("tarjetas", "presentacion", "infografia", "quiz", "pareo", "secuencia", "ahorcado",
            "verdadero_falso", "completar", "clasificar", "caso")
MAX_PALABRA = 24
MARCA_ENE = "\x00"  # Protege la Ñ mientras se quitan los acentos.


class Errores(list):
    def agregar(self, ruta, mensaje):
        self.append(f"{ruta}: {mensaje}")


def _texto(valor, ruta, maximo, errores, vacio=False):
    if not isinstance(valor, str):
        errores.agregar(ruta, "debe ser texto")
        return ""
    limpio = " ".join(valor.split())
    if not limpio and not vacio:
        errores.agregar(ruta, "está vacío")
    if len(limpio) > maximo:
        errores.agregar(ruta, f"pasa de {maximo} caracteres")
    return limpio


def _lista(valor, ruta, minimo, maximo, errores):
    if not isinstance(valor, list):
        errores.agregar(ruta, "debe ser una lista")
        return []
    if not minimo <= len(valor) <= maximo:
        errores.agregar(ruta, f"debe tener de {minimo} a {maximo} elementos (tiene {len(valor)})")
    return valor


def _objeto(valor, ruta, campos, errores):
    if not isinstance(valor, dict):
        errores.agregar(ruta, "debe ser un objeto")
        return {}
    faltan = [c for c in campos if c not in valor]
    if faltan:
        errores.agregar(ruta, "faltan " + ", ".join(faltan))
    return valor


def _sin_repetir(textos, ruta, errores):
    vistos = set()
    for texto in textos:
        clave = texto.lower()
        if clave in vistos:
            errores.agregar(ruta, f"«{texto}» está repetido")
        vistos.add(clave)


def _tarjetas(c, e):
    tarjetas = []
    for i, t in enumerate(_lista(c.get("tarjetas"), "tarjetas", 4, 12, e)):
        t = _objeto(t, f"tarjetas[{i}]", ("frente", "reverso"), e)
        tarjetas.append({
            "frente": _texto(t.get("frente"), f"tarjetas[{i}].frente", 120, e),
            "reverso": _texto(t.get("reverso"), f"tarjetas[{i}].reverso", 240, e),
        })
    _sin_repetir([t["frente"] for t in tarjetas], "tarjetas", e)
    return {"tarjetas": tarjetas}


def _presentacion(c, e):
    diapositivas = []
    for i, d in enumerate(_lista(c.get("diapositivas"), "diapositivas", 3, 8, e)):
        d = _objeto(d, f"diapositivas[{i}]", ("titulo", "puntos"), e)
        puntos = [_texto(p, f"diapositivas[{i}].puntos[{j}]", 160, e)
                  for j, p in enumerate(_lista(d.get("puntos"), f"diapositivas[{i}].puntos", 1, 5, e))]
        diapositivas.append({
            "titulo": _texto(d.get("titulo"), f"diapositivas[{i}].titulo", 80, e),
            "puntos": puntos,
            "nota": _texto(d.get("nota", ""), f"diapositivas[{i}].nota", 240, e, vacio=True),
        })
    return {"diapositivas": diapositivas}


def _infografia(c, e):
    bloques = []
    for i, b in enumerate(_lista(c.get("bloques"), "bloques", 3, 6, e)):
        b = _objeto(b, f"bloques[{i}]", ("titulo", "dato", "explicacion"), e)
        bloques.append({
            "titulo": _texto(b.get("titulo"), f"bloques[{i}].titulo", 60, e),
            "dato": _texto(b.get("dato"), f"bloques[{i}].dato", 60, e),
            "explicacion": _texto(b.get("explicacion"), f"bloques[{i}].explicacion", 200, e),
        })
    return {
        "idea_central": _texto(c.get("idea_central"), "idea_central", 200, e),
        "bloques": bloques,
        "aviso_seguridad": _texto(c.get("aviso_seguridad", ""), "aviso_seguridad", 200, e, vacio=True),
    }


def _quiz(c, e):
    preguntas = []
    for i, p in enumerate(_lista(c.get("preguntas"), "preguntas", 3, 10, e)):
        p = _objeto(p, f"preguntas[{i}]", ("pregunta", "opciones", "correcta", "explicacion"), e)
        opciones = [_texto(o, f"preguntas[{i}].opciones[{j}]", 140, e)
                    for j, o in enumerate(_lista(p.get("opciones"), f"preguntas[{i}].opciones", 3, 4, e))]
        _sin_repetir(opciones, f"preguntas[{i}].opciones", e)
        correcta = p.get("correcta")
        if isinstance(correcta, bool) or not isinstance(correcta, int) or not 0 <= correcta < len(opciones):
            e.agregar(f"preguntas[{i}].correcta", "debe ser el índice de una opción")
            correcta = 0
        preguntas.append({
            "pregunta": _texto(p.get("pregunta"), f"preguntas[{i}].pregunta", 200, e),
            "opciones": opciones,
            "correcta": correcta,
            "explicacion": _texto(p.get("explicacion"), f"preguntas[{i}].explicacion", 240, e),
        })
    return {"preguntas": preguntas}


def _pareo(c, e):
    pares = []
    for i, p in enumerate(_lista(c.get("pares"), "pares", 4, 8, e)):
        p = _objeto(p, f"pares[{i}]", ("termino", "definicion"), e)
        pares.append({
            "termino": _texto(p.get("termino"), f"pares[{i}].termino", 60, e),
            "definicion": _texto(p.get("definicion"), f"pares[{i}].definicion", 160, e),
        })
    _sin_repetir([p["termino"] for p in pares], "pares", e)
    _sin_repetir([p["definicion"] for p in pares], "pares", e)
    return {"pares": pares}


def _secuencia(c, e):
    pasos = [_texto(p, f"pasos[{i}]", 140, e) for i, p in enumerate(_lista(c.get("pasos"), "pasos", 3, 8, e))]
    _sin_repetir(pasos, "pasos", e)
    return {
        "procedimiento": _texto(c.get("procedimiento"), "procedimiento", 120, e),
        "pasos": pasos,
        "explicacion": _texto(c.get("explicacion"), "explicacion", 240, e),
    }


def letras_ahorcado(palabra):
    """Mayúsculas sin acentos (la Ñ se conserva): así se compara cada letra en el juego."""
    texto = palabra.upper().replace("Ñ", MARCA_ENE)
    plano = unicodedata.normalize("NFKD", texto).encode("ascii", "ignore").decode("ascii")
    return plano.replace(MARCA_ENE, "Ñ")


def _ahorcado(c, e):
    palabras = []
    for i, p in enumerate(_lista(c.get("palabras"), "palabras", 4, 10, e)):
        p = _objeto(p, f"palabras[{i}]", ("palabra", "pista", "explicacion"), e)
        palabra = _texto(p.get("palabra"), f"palabras[{i}].palabra", MAX_PALABRA, e)
        letras = letras_ahorcado(palabra)
        if palabra and not re.fullmatch(r"[A-ZÑ]+(?:[ -][A-ZÑ]+){0,2}", letras):
            e.agregar(f"palabras[{i}].palabra", "solo letras, de 1 a 3 palabras, sin números ni signos")
        elif palabra and len(re.sub(r"[ -]", "", letras)) < 3:
            e.agregar(f"palabras[{i}].palabra", "debe tener al menos 3 letras")
        palabras.append({
            "palabra": palabra,
            "pista": _texto(p.get("pista"), f"palabras[{i}].pista", 160, e),
            "explicacion": _texto(p.get("explicacion"), f"palabras[{i}].explicacion", 200, e),
        })
    _sin_repetir([letras_ahorcado(p["palabra"]) for p in palabras], "palabras", e)
    return {"palabras": palabras}
def _verdadero_falso(c, e):
    afirmaciones = []
    for i, a in enumerate(_lista(c.get("afirmaciones"), "afirmaciones", 6, 12, e)):
        ruta = f"afirmaciones[{i}]"
        a = _objeto(a, ruta, ("afirmacion", "verdadero", "explicacion"), e)
        verdadero = a.get("verdadero")
        if not isinstance(verdadero, bool):
            e.agregar(f"{ruta}.verdadero", "debe ser true o false")
        afirmaciones.append({
            "afirmacion": _texto(a.get("afirmacion"), f"{ruta}.afirmacion", MAX_AFIRMACION, e),
            "verdadero": verdadero,
            "explicacion": _texto(a.get("explicacion"), f"{ruta}.explicacion", MAX_EXPLICACION_VF, e),
        })
    _sin_repetir([a["afirmacion"] for a in afirmaciones], "afirmaciones", e)
    return {"afirmaciones": afirmaciones}


def _decisiones(c, e, lista, campo, minimo, maximo, max_opciones):
    decisiones = []
    for i, d in enumerate(_lista(c.get(lista), lista, minimo, maximo, e)):
        ruta = f"{lista}[{i}]"
        d = _objeto(d, ruta, (campo, "opciones", "correcta", "explicacion"), e)
        texto = _texto(d.get(campo), f"{ruta}.{campo}", 200, e)
        if campo == "frase" and (len(re.findall(HUECO, texto)) != 1 or texto.count("____") != 1):
            e.agregar(f"{ruta}.frase", "debe contener el marcador «____» exactamente una vez")
        opciones = [_texto(o, f"{ruta}.opciones[{j}]", 140, e)
                    for j, o in enumerate(_lista(d.get("opciones"), f"{ruta}.opciones", 3, max_opciones, e))]
        _sin_repetir(opciones, f"{ruta}.opciones", e)
        correcta = d.get("correcta")
        if type(correcta) is not int or not 0 <= correcta < len(opciones):
            e.agregar(f"{ruta}.correcta", "debe ser el índice de una opción")
            correcta = 0
        decisiones.append({campo: texto, "opciones": opciones, "correcta": correcta,
                            "explicacion": _texto(d.get("explicacion"), f"{ruta}.explicacion", 240, e)})
    _sin_repetir([d[campo] for d in decisiones], lista, e)
    return decisiones


def _completar(c, e):
    return {"frases": _decisiones(c, e, "frases", "frase", 5, 10, 4)}


def _clasificar(c, e):
    categorias = []
    for i, categoria in enumerate(_lista(c.get("categorias"), "categorias", 2, 3, e)):
        ruta = f"categorias[{i}]"
        categoria = _objeto(categoria, ruta, ("id", "nombre"), e)
        categorias.append({"id": _texto(categoria.get("id"), f"{ruta}.id", 40, e),
                           "nombre": _texto(categoria.get("nombre"), f"{ruta}.nombre", 70, e)})
    ids = [categoria["id"] for categoria in categorias]
    _sin_repetir(ids, "categorias.id", e)
    _sin_repetir([categoria["nombre"] for categoria in categorias], "categorias.nombre", e)
    elementos = []
    for i, elemento in enumerate(_lista(c.get("elementos"), "elementos", 6, 12, e)):
        ruta = f"elementos[{i}]"
        elemento = _objeto(elemento, ruta, ("texto", "categoria"), e)
        categoria = _texto(elemento.get("categoria"), f"{ruta}.categoria", 40, e)
        if categoria and categoria not in ids:
            e.agregar(f"{ruta}.categoria", f"la categoría «{categoria}» no existe")
        elementos.append({"texto": _texto(elemento.get("texto"), f"{ruta}.texto", 160, e), "categoria": categoria})
    _sin_repetir([elemento["texto"] for elemento in elementos], "elementos", e)
    return {"categorias": categorias, "elementos": elementos}


def _caso(c, e):
    return {"situacion": _texto(c.get("situacion"), "situacion", 420, e),
            "pasos": _decisiones(c, e, "pasos", "pregunta", 3, 6, 3)}


VALIDADORES = {
    "tarjetas": _tarjetas,
    "presentacion": _presentacion,
    "infografia": _infografia,
    "quiz": _quiz,
    "pareo": _pareo,
    "secuencia": _secuencia,
    "ahorcado": _ahorcado,
    "verdadero_falso": _verdadero_falso,
    "completar": _completar,
    "clasificar": _clasificar,
    "caso": _caso,
}


def validar(formato, contenido):
    """Devuelve (contenido_limpio, errores). errores vacío = válido."""
    errores = Errores()
    if formato not in VALIDADORES:
        errores.agregar("formato", f"«{formato}» no existe")
        return {}, list(errores)
    if not isinstance(contenido, dict):
        errores.agregar("contenido", "debe ser un objeto")
        return {}, list(errores)
    return VALIDADORES[formato](contenido, errores), list(errores)


def validar_titulo(titulo):
    errores = Errores()
    limpio = _texto(titulo, "titulo", MAX_TITULO, errores)
    return limpio, list(errores)


# --- Esquemas que viajan en el mensaje al agente (el agente fijo no acepta formato de salida) ---

def _s(tipo="string"):
    return {"type": tipo}


def _arr(items, minimo, maximo):
    return {"type": "array", "items": items, "minItems": minimo, "maxItems": maximo}


def _obj(**propiedades):
    return {"type": "object", "additionalProperties": False,
            "required": list(propiedades), "properties": propiedades}


CONTENIDO = {
    "tarjetas": _obj(tarjetas=_arr(_obj(frente=_s(), reverso=_s()), 4, 12)),
    "presentacion": _obj(diapositivas=_arr(_obj(titulo=_s(), puntos=_arr(_s(), 1, 5), nota=_s()), 3, 8)),
    "infografia": _obj(idea_central=_s(), bloques=_arr(_obj(titulo=_s(), dato=_s(), explicacion=_s()), 3, 6),
                       aviso_seguridad=_s()),
    "quiz": _obj(preguntas=_arr(_obj(pregunta=_s(), opciones=_arr(_s(), 3, 4), correcta=_s("integer"),
                                     explicacion=_s()), 3, 10)),
    "pareo": _obj(pares=_arr(_obj(termino=_s(), definicion=_s()), 4, 8)),
    "secuencia": _obj(procedimiento=_s(), pasos=_arr(_s(), 3, 8), explicacion=_s()),
    "ahorcado": _obj(palabras=_arr(_obj(palabra=_s(), pista=_s(), explicacion=_s()), 4, 10)),
    "verdadero_falso": _obj(afirmaciones=_arr(_obj(afirmacion=_s(), verdadero=_s("boolean"), explicacion=_s()), 6, 12)),
    "completar": _obj(frases=_arr(_obj(frase=_s(), opciones=_arr(_s(), 3, 4), correcta=_s("integer"),
                                       explicacion=_s()), 5, 10)),
    "clasificar": _obj(categorias=_arr(_obj(id=_s(), nombre=_s()), 2, 3),
                       elementos=_arr(_obj(texto=_s(), categoria=_s()), 6, 12)),
    "caso": _obj(situacion=_s(), pasos=_arr(_obj(pregunta=_s(), opciones=_arr(_s(), 3, 3), correcta=_s("integer"),
                                              explicacion=_s()), 3, 6)),
}

LIMITES = {
    "tarjetas": "frente hasta 120 caracteres, reverso hasta 240.",
    "presentacion": "título de diapositiva hasta 80, cada punto hasta 160, nota hasta 240 o vacía.",
    "infografia": "idea_central hasta 200; en cada bloque, título hasta 60, dato hasta 60: una cifra con su unidad o de 2 a 5 palabras, nunca una oración, explicación hasta 200; aviso_seguridad hasta 200 o vacío.",
    "quiz": "pregunta hasta 200, opciones hasta 140, «correcta» es el índice (desde 0) de la opción correcta, explicación hasta 240. Las opciones incorrectas deben ser creíbles.",
    "pareo": "término hasta 60, definición hasta 160; sin términos ni definiciones repetidos.",
    "ahorcado": "cada «palabra» es un término técnico del manual de 1 a 3 palabras y hasta 24 caracteres, solo letras (sin números, siglas con números ni signos); «pista» hasta 160 describe el término sin nombrarlo; «explicacion» hasta 200 dice para qué sirve o por qué importa.",
    "secuencia": "«pasos» va en el orden correcto (la app los revuelve), cada paso hasta 140; explicación hasta 240 dice por qué ese orden.",
    "verdadero_falso": f"Mezcla afirmaciones verdaderas y falsas sin repetir. Afirmación hasta {MAX_AFIRMACION}, "
                       f"explicación hasta {MAX_EXPLICACION_VF}. Explica por qué y corrige las falsas.",
    "completar": "Frase hasta 200 con «____» exactamente una vez, opciones hasta 140 y explicación hasta 240. "
                 "Usa vocabulario, valores o condiciones del procedimiento. Una sola opción encaja. "
                 "«correcta» es el índice desde 0. Evita frases y opciones repetidas.",
    "clasificar": "Usa categorías claras con id hasta 40 y nombre hasta 70, ambos únicos. "
                  "Cada elemento tiene texto hasta 160 y el id exacto de su categoría. "
                  "Incluye ejemplos de cada categoría y evita elementos repetidos o ambiguos.",
    "caso": "Situación hasta 420. Presenta un caso de taller y revela lo que encuentras paso a paso. "
            "Pregunta hasta 200, tres opciones distintas de hasta 140, «correcta» es el índice desde 0 "
            "y explicación hasta 240. Evita preguntas repetidas.",
}


def esquema(formato):
    return _obj(titulo=_s(), contenido=CONTENIDO[formato], fuentes=_arr(_s(), 1, 5))
