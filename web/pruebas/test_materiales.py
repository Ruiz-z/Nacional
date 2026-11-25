"""Pruebas de SPEC-materiales. Correr desde la raíz: python -m unittest discover web/pruebas"""

import json
import os
import sys
import tempfile
import threading
import unittest
import urllib.error
import urllib.request
from pathlib import Path

os.environ["NACIONAL_SIN_NUBE"] = "1"  # Nunca llamar a Foundry en las pruebas.
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from logica import formatos  # noqa: E402
from logica.almacen import Almacen, NoEncontrado  # noqa: E402
from logica.catalogo import Catalogo, ErrorSeleccion  # noqa: E402
from logica.foundry import ClienteFoundry, ErrorFoundry, cargar_config, extraer  # noqa: E402
from logica.generador import ErrorGeneracion, Generador, fuentes_validas, requiere_doble_revision  # noqa: E402
import servidor  # noqa: E402

PDF = "Fact-sheet-Electric-Safety-EN-VolvoBuses-2024-Es-Mx.pdf"

EJEMPLOS = {
    "tarjetas": {"tarjetas": [{"frente": f"Término {i}", "reverso": f"Respuesta {i}"} for i in range(4)]},
    "presentacion": {"diapositivas": [{"titulo": f"D{i}", "puntos": ["Uno", "Dos"], "nota": ""} for i in range(3)]},
    "infografia": {"idea_central": "Idea", "aviso_seguridad": "",
                   "bloques": [{"titulo": f"B{i}", "dato": "600 V", "explicacion": "Texto"} for i in range(3)]},
    "quiz": {"preguntas": [{"pregunta": f"¿P{i}?", "opciones": ["A", "B", "C"], "correcta": 1, "explicacion": "Porque B"}
                           for i in range(3)]},
    "pareo": {"pares": [{"termino": f"T{i}", "definicion": f"Definición {i}"} for i in range(4)]},
    "secuencia": {"procedimiento": "LOTO", "pasos": ["Apagar", "Bloquear", "Verificar"], "explicacion": "Así"},
}


class ClienteFalso:
    """Simula al agente: devuelve una respuesta fija y los PDF que 'encontró' la búsqueda."""

    def __init__(self, respuesta, devueltas=(PDF,), error=None):
        self.respuesta, self.devueltas, self.error = respuesta, list(devueltas), error
        self.llamadas = []

    def disponible(self):
        return True

    def generar(self, instruccion, contexto, esquema):
        self.llamadas.append((instruccion, contexto, esquema))
        if self.error:
            raise self.error
        return json.loads(json.dumps(self.respuesta)), self.devueltas


def respuesta_ia(formato="tarjetas", fuentes=(PDF,), titulo="LOTO básico"):
    return {"titulo": titulo, "contenido": EJEMPLOS[formato], "fuentes": list(fuentes)}


class Base(unittest.TestCase):
    def setUp(self):
        self.temporal = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporal.cleanup)
        self.catalogo = Catalogo()
        self.almacen = Almacen(Path(self.temporal.name))

    def generador(self, cliente=None):
        return Generador(self.catalogo, self.almacen, cliente)


class PruebaFormatos(unittest.TestCase):
    def test_ejemplos_validos(self):
        for formato, contenido in EJEMPLOS.items():
            with self.subTest(formato=formato):
                limpio, errores = formatos.validar(formato, contenido)
                self.assertEqual(errores, [])
                self.assertEqual(limpio, contenido)

    def test_cuenta_y_longitud(self):
        _, errores = formatos.validar("tarjetas", {"tarjetas": EJEMPLOS["tarjetas"]["tarjetas"][:2]})
        self.assertTrue(any("de 4 a 12" in e for e in errores))
        largo = {"tarjetas": [{"frente": "x" * 121, "reverso": "y"}] + EJEMPLOS["tarjetas"]["tarjetas"][1:]}
        self.assertTrue(any("120" in e for e in formatos.validar("tarjetas", largo)[1]))

    def test_quiz_correcta_fuera_de_rango_y_booleana(self):
        for correcta in (3, -1, True, "1"):
            preguntas = json.loads(json.dumps(EJEMPLOS["quiz"]))
            preguntas["preguntas"][0]["correcta"] = correcta
            self.assertTrue(formatos.validar("quiz", preguntas)[1], correcta)

    def test_repetidos_y_campos_faltantes(self):
        pares = {"pares": [{"termino": "A", "definicion": f"d{i}"} for i in range(4)]}
        self.assertTrue(any("repetido" in e for e in formatos.validar("pareo", pares)[1]))
        self.assertTrue(any("procedimiento" in e for e in formatos.validar("secuencia", {"pasos": ["a", "b", "c"]})[1]))
        self.assertTrue(any("faltan" in e for e in formatos.validar("pareo", {"pares": [{"termino": "a"}] * 4})[1]))

    def test_formato_inexistente_y_espacios(self):
        self.assertTrue(formatos.validar("video", {})[1])
        limpio, _ = formatos.validar("secuencia", {**EJEMPLOS["secuencia"], "procedimiento": "  LOTO \n seguro "})
        self.assertEqual(limpio["procedimiento"], "LOTO seguro")

    def test_esquema_por_formato(self):
        for formato in formatos.FORMATOS:
            self.assertEqual(formatos.esquema(formato)["required"], ["titulo", "contenido", "fuentes"])


class PruebaCatalogo(unittest.TestCase):
    def test_catalogo_coherente(self):
        c = Catalogo()
        self.assertIn("general", c.modelos)
        self.assertEqual(c.basicos(), ["novato", "basico"])
        self.assertEqual(set(c.formatos), set(formatos.FORMATOS))
        self.assertEqual(len(c.competencias), 4)
        for nivel in c.niveles.values():
            self.assertTrue(set(nivel["dificultad_banco"]) <= {"facil", "media", "dificil"})
        with self.assertRaises(ErrorSeleccion):
            c.comprobar("tarjetas", "camion", "basico", "diagnostico-fallas")


class PruebaFoundry(unittest.TestCase):
    def test_sin_nube_y_endpoint(self):
        self.assertEqual(cargar_config({"NACIONAL_SIN_NUBE": "1", "NACIONAL_FOUNDRY_ENDPOINT": "https://x"}), {})
        self.assertEqual(cargar_config({"NACIONAL_FOUNDRY_ENDPOINT": "http://x"}, archivo_env="no-existe"), {})
        config = cargar_config({"NACIONAL_FOUNDRY_ENDPOINT": "https://x/api/projects/p",
                                "NACIONAL_FOUNDRY_AGENTE": "Faro",
                                "NACIONAL_FOUNDRY_AGENTE_MATERIALES": "materiales"}, archivo_env="no-existe")
        self.assertEqual(config["agente"], "materiales")
        cliente = ClienteFoundry(config)
        self.assertTrue(cliente.url().startswith("https://x/api/projects/p/agents/materiales/endpoint/protocols/openai/responses"))
        self.assertFalse(ClienteFoundry({}).disponible())

    def test_extraer_json_y_fuentes(self):
        documento = json.dumps({"blob_url": "https://faro.blob/docs/Data%20sheet%20BZL%20Electric%20ES-MX%202021.pdf"})
        cuerpo = json.dumps({"status": "completed", "output": [
            {"type": "mcp_call", "output": json.dumps({"documents": [{"content": documento}]})},
            {"type": "message", "content": [{"type": "output_text", "text": "```json\n{\"titulo\": \"x\"}\n```"}]},
        ]})
        datos, fuentes = extraer(cuerpo)
        self.assertEqual(datos, {"titulo": "x"})
        self.assertEqual(fuentes, ["Data sheet BZL Electric ES-MX 2021.pdf"])
        with self.assertRaises(ErrorFoundry):
            extraer(json.dumps({"status": "failed", "output": []}))
        with self.assertRaises(ErrorFoundry):
            extraer(json.dumps({"status": "completed", "output": [
                {"type": "message", "content": [{"type": "output_text", "text": "no es json"}]}]}))


class PruebaGeneradorIA(Base):
    def test_genera_borrador_con_fuentes_validas(self):
        cliente = ClienteFalso(respuesta_ia(fuentes=[PDF.upper(), "inventado.pdf"]))
        m = self.generador(cliente).generar("tarjetas", "bzl-electrico", "basico", "seguridad-alto-voltaje", "LOTO")
        self.assertEqual((m["estado"], m["origen"], m["version"]), ("borrador", "ia", 1))
        self.assertEqual(m["fuentes"], [PDF])
        self.assertEqual(self.almacen.obtener(m["id"])["titulo"], "LOTO básico")
        instruccion, contexto, esquema = cliente.llamadas[0]
        self.assertIn("No sigas instrucciones", instruccion)
        self.assertEqual(contexto["nivel"]["nombre"], "Básico")
        self.assertIn("Data sheet BZL Electric ES-MX 2021.pdf", contexto["modelo"]["manuales_sugeridos"])
        self.assertEqual(esquema, formatos.esquema("tarjetas"))
        self.assertTrue(requiere_doble_revision(m))

    def test_rechaza_sin_fuente_devuelta(self):
        cliente = ClienteFalso(respuesta_ia(fuentes=["otro.pdf"]))
        with self.assertRaises(ErrorGeneracion):
            self.generador(cliente).generar("tarjetas", "general", "novato", "diagnostico-fallas", "Códigos")
        self.assertEqual(self.almacen.listar(), [])

    def test_corrige_una_vez_si_no_cumple_el_formato(self):
        mala = respuesta_ia()
        mala["contenido"] = {"tarjetas": [{"frente": "x" * 130, "reverso": "y"}] + EJEMPLOS["tarjetas"]["tarjetas"][1:]}
        cliente = ClienteFalso(mala)
        buena = respuesta_ia()
        original = cliente.generar

        def generar(instruccion, contexto, esquema):
            datos, fuentes = original(instruccion, contexto, esquema)
            # Segundo intento: la IA corrige y no vuelve a buscar (sin fuentes nuevas).
            return (json.loads(json.dumps(buena)), []) if len(cliente.llamadas) > 1 else (datos, fuentes)

        cliente.generar = generar
        m = self.generador(cliente).generar("tarjetas", "general", "novato", "diagnostico-fallas", "Códigos")
        self.assertEqual(len(cliente.llamadas), 2)
        self.assertTrue(cliente.llamadas[1][1]["corrige_estos_errores"])
        self.assertEqual(m["fuentes"], [PDF])

    def test_rechaza_formato_invalido_y_error_de_red(self):
        mala = respuesta_ia()
        mala["contenido"] = {"tarjetas": []}
        for cliente in (ClienteFalso(mala), ClienteFalso({}, error=ErrorFoundry("sin red"))):
            with self.assertRaises(ErrorGeneracion):
                self.generador(cliente).generar("tarjetas", "general", "novato", "diagnostico-fallas", "Códigos")
        self.assertEqual(self.almacen.listar(), [])

    def test_rechaza_seleccion_y_tema(self):
        g = self.generador(ClienteFalso(respuesta_ia()))
        with self.assertRaises(ErrorSeleccion):
            g.generar("tarjetas", "general", "maestro", "diagnostico-fallas", "x")
        with self.assertRaises(ErrorGeneracion):
            g.generar("tarjetas", "general", "novato", "diagnostico-fallas", "  ")

    def test_actualizar_conserva_id_y_guarda_historial(self):
        cliente = ClienteFalso(respuesta_ia())
        g = self.generador(cliente)
        m = g.generar("tarjetas", "general", "novato", "diagnostico-fallas", "Códigos")
        self.almacen.revisar(m["id"], "instructor-1")
        cliente.respuesta = respuesta_ia(titulo="LOTO más sencillo")
        nuevo = g.actualizar(m["id"], "Más sencillo")
        self.assertEqual((nuevo["id"], nuevo["version"], nuevo["estado"]), (m["id"], 2, "borrador"))
        self.assertEqual(nuevo["titulo"], "LOTO más sencillo")
        self.assertEqual(nuevo["historial"][0]["version"], 1)
        self.assertEqual(nuevo["historial"][0]["revisado_por"], "instructor-1")
        self.assertIn("Más sencillo", nuevo["historial"][0]["motivo_cambio"])
        self.assertEqual(cliente.llamadas[-1][1]["indicacion_del_autor"], "Más sencillo")
        self.assertEqual(cliente.llamadas[-1][1]["material_actual"]["titulo"], "LOTO básico")

    def test_editar_a_mano(self):
        g = self.generador(ClienteFalso(respuesta_ia()))
        m = g.generar("tarjetas", "general", "novato", "diagnostico-fallas", "Códigos")
        contenido = json.loads(json.dumps(m["contenido"]))
        contenido["tarjetas"][0]["reverso"] = "Corregido"
        editado = g.editar(m["id"], "Nuevo título", contenido)
        self.assertEqual((editado["version"], editado["origen"]), (2, "manual"))
        with self.assertRaises(ErrorGeneracion):
            g.editar(m["id"], "x", {"tarjetas": []})
        self.assertEqual(self.almacen.obtener(m["id"])["version"], 2)

    def test_fuentes_validas(self):
        self.assertEqual(fuentes_validas(["a.pdf", "A.PDF", "b.pdf"], ["A.pdf"]), ["A.pdf"])
        self.assertEqual(fuentes_validas("a.pdf", ["a.pdf"]), [])


class PruebaSinIA(Base):
    def test_tarjetas_y_quiz_desde_banco(self):
        g = self.generador(None)
        for formato in ("tarjetas", "quiz"):
            m = g.generar(formato, "bzl-electrico", "novato", "sistema-electrico-bateria", "Repaso")
            self.assertEqual(m["origen"], "banco")
            self.assertTrue(m["fuentes"])
            self.assertEqual(formatos.validar(formato, m["contenido"])[1], [])
        quiz = m["contenido"]["preguntas"]
        # Novato pide fácil: los primeros ítems son fáciles y del manual del BZL si hay.
        banco = {i["pregunta"]: i for i in self.catalogo.banco["items"] if i["formato"] == "opcion-multiple"}
        self.assertEqual(banco[quiz[0]["pregunta"]]["dificultad"], "facil")
        self.assertIn("BZL", banco[quiz[0]["pregunta"]]["fuente"].get("referencia", ""))

    def test_tema_prioriza_preguntas_que_lo_mencionan(self):
        m = self.generador(None).generar("quiz", "general", "basico", "seguridad-alto-voltaje", "Etiqueta LOTO")
        self.assertIn("etiqueta", m["contenido"]["preguntas"][0]["pregunta"].lower())

    def test_secuencia_desde_caso_y_formatos_que_piden_ia(self):
        g = self.generador(None)
        m = g.generar("secuencia", "general", "basico", "diagnostico-fallas", "Red")
        self.assertGreaterEqual(len(m["contenido"]["pasos"]), 3)
        with self.assertRaises(ErrorGeneracion):
            g.generar("secuencia", "general", "basico", "seguridad-alto-voltaje", "LOTO")
        with self.assertRaises(ErrorGeneracion):
            g.generar("presentacion", "general", "basico", "seguridad-alto-voltaje", "LOTO")
        with self.assertRaises(ErrorGeneracion):
            g.actualizar(m["id"], "algo")


class PruebaAlmacen(Base):
    def test_ids_seguros(self):
        for malo in ("../banco", "A", "", "x/y"):
            with self.assertRaises(NoEncontrado):
                self.almacen.obtener(malo)
        m = self.almacen.crear(formato="quiz", modelo="general", nivel="novato", competencia="diagnostico-fallas",
                               tema="Códigos de falla ¿qué son?", titulo="t", contenido={}, fuentes=[], origen="banco")
        self.assertRegex(m["id"], r"^quiz-codigos-de-falla-que-son-[0-9a-f]{6}$")
        self.almacen.eliminar(m["id"])
        self.assertEqual(self.almacen.listar(), [])


class PruebaServidor(Base):
    def setUp(self):
        super().setUp()
        self.cliente = ClienteFalso(respuesta_ia("quiz"))
        app = servidor.Aplicacion(self.catalogo, self.almacen, self.cliente)
        self.http = servidor.crear_servidor(app, puerto=0)
        threading.Thread(target=self.http.serve_forever, daemon=True).start()
        self.addCleanup(self.http.server_close)
        self.addCleanup(self.http.shutdown)
        self.base = f"http://127.0.0.1:{self.http.server_address[1]}"

    def pedir(self, metodo, ruta, cuerpo=None):
        datos = json.dumps(cuerpo).encode() if cuerpo is not None else None
        peticion = urllib.request.Request(self.base + ruta, data=datos, method=metodo,
                                          headers={"Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(peticion, timeout=10) as r:
                return r.status, r.read()
        except urllib.error.HTTPError as error:
            return error.code, error.read()

    def json(self, metodo, ruta, cuerpo=None):
        estado, datos = self.pedir(metodo, ruta, cuerpo)
        return estado, json.loads(datos)

    def test_flujo_completo(self):
        self.assertEqual(self.json("GET", "/api/estado"), (200, {"ia": True, "autor": True}))
        estado, catalogo = self.json("GET", "/api/catalogo")
        self.assertEqual(catalogo["enfoque_por_defecto"], "basicos")
        estado, m = self.json("POST", "/api/materiales", {"formato": "quiz", "modelo": "general", "nivel": "novato",
                                                          "competencia": "seguridad-alto-voltaje", "tema": "EPP"})
        self.assertEqual(estado, 201)
        self.assertTrue(m["doble_revision"])
        # El técnico no ve borradores; el autor sí.
        self.assertEqual(self.json("GET", "/api/materiales")[1]["materiales"], [])
        self.assertEqual(len(self.json("GET", "/api/materiales?vista=autor")[1]["materiales"]), 1)
        self.assertEqual(self.json("POST", f"/api/materiales/{m['id']}/revisar", {"revisor": " "})[0], 422)
        estado, revisado = self.json("POST", f"/api/materiales/{m['id']}/revisar", {"revisor": "instructor-1"})
        self.assertEqual((revisado["estado"], revisado["doble_revision"]), ("revisado", False))
        lista = self.json("GET", "/api/materiales?niveles=novato,basico&modelo=general")[1]["materiales"]
        self.assertEqual([x["id"] for x in lista], [m["id"]])
        self.assertEqual(self.json("GET", "/api/materiales?niveles=experto")[1]["materiales"], [])
        estado, actualizado = self.json("POST", f"/api/materiales/{m['id']}/actualizar", {"indicacion": "Más corto"})
        self.assertEqual((estado, actualizado["version"], actualizado["estado"]), (200, 2, "borrador"))
        estado, error = self.json("PUT", f"/api/materiales/{m['id']}", {"titulo": "x", "contenido": {"preguntas": []}})
        self.assertEqual(estado, 422)
        self.assertTrue(error["detalles"])
        self.assertEqual(self.json("DELETE", f"/api/materiales/{m['id']}")[0], 200)
        self.assertEqual(self.json("GET", f"/api/materiales/{m['id']}")[0], 404)

    def test_errores_de_entrada(self):
        self.assertEqual(self.json("POST", "/api/materiales", {"formato": "video", "modelo": "general",
                                                               "nivel": "novato", "competencia": "x", "tema": "t"})[0], 400)
        self.assertEqual(self.pedir("POST", "/api/materiales", None)[0], 400)
        estado, _ = self.pedir("POST", "/api/materiales/x-1/revisar", None)
        self.assertEqual(estado, 404)
        self.assertEqual(self.json("GET", "/api/materiales/..%2F..%2Fbanco")[0], 404)
        self.assertEqual(self.json("GET", "/api/nada")[0], 404)

    def test_estaticos_y_recorrido(self):
        estado, html = self.pedir("GET", "/")
        self.assertEqual(estado, 200)
        self.assertIn(b"Materiales de estudio", html)
        for archivo in ("/app.js", "/formatos.js", "/estilos.css", "/fuentes/Poppins-Regular.ttf"):
            self.assertEqual(self.pedir("GET", archivo)[0], 200, archivo)
        for malo in ("/../servidor.py", "/%2e%2e/servidor.py", "/fuentes/../../project.godot",
                     "/fuentes/Poppins-Regular.ttf.import"):
            self.assertEqual(self.pedir("GET", malo)[0], 404, malo)


class PruebaPermisoDeAutor(Base):
    """Con permiso configurado, solo quien entra desde la app (cookie) hace acciones de autor."""

    TOKEN = "t" * 43

    def setUp(self):
        super().setUp()
        app = servidor.Aplicacion(self.catalogo, self.almacen, ClienteFalso(respuesta_ia("quiz")), token_autor=self.TOKEN)
        self.http = servidor.crear_servidor(app, puerto=0)
        threading.Thread(target=self.http.serve_forever, daemon=True).start()
        self.addCleanup(self.http.server_close)
        self.addCleanup(self.http.shutdown)
        self.base = f"http://127.0.0.1:{self.http.server_address[1]}"

    def pedir(self, metodo, ruta, cuerpo=None, cookie=None):
        datos = json.dumps(cuerpo).encode() if cuerpo is not None else None
        cabeceras = {"Content-Type": "application/json"}
        if cookie:
            cabeceras["Cookie"] = cookie
        peticion = urllib.request.Request(self.base + ruta, data=datos, method=metodo, headers=cabeceras)
        try:
            with urllib.request.urlopen(peticion, timeout=10) as r:
                return r.status, r.read()
        except urllib.error.HTTPError as error:
            return error.code, error.read()

    def test_sin_permiso_solo_hay_vista_de_tecnico(self):
        estado, datos = self.pedir("GET", "/api/estado")
        self.assertEqual((estado, json.loads(datos)["autor"]), (200, False))
        self.assertEqual(self.pedir("GET", "/api/materiales")[0], 200)
        self.assertEqual(self.pedir("GET", "/api/materiales?vista=autor")[0], 403)
        for metodo, ruta, cuerpo in [
                ("POST", "/api/materiales", {"formato": "quiz", "modelo": "general", "nivel": "novato",
                                              "competencia": "seguridad-alto-voltaje", "tema": "EPP"}),
                ("PUT", "/api/materiales/x-1", {"titulo": "x", "contenido": {}}),
                ("DELETE", "/api/materiales/x-1", None),
                ("POST", "/api/materiales/x-1/revisar", {"revisor": "yo"}),
                ("POST", "/api/materiales/x-1/actualizar", {"indicacion": "x"})]:
            self.assertEqual(self.pedir(metodo, ruta, cuerpo)[0], 403, f"{metodo} {ruta}")
        # Una cookie equivocada no sirve.
        self.assertEqual(self.pedir("GET", "/api/materiales?vista=autor", cookie="autor=otro")[0], 403)

    def test_acceso_con_token_da_la_cookie_y_el_permiso(self):
        class SinSeguir(urllib.request.HTTPRedirectHandler):
            def redirect_request(self, *args, **kwargs):
                return None
        abridor = urllib.request.build_opener(SinSeguir)
        for token, debe_dar_cookie in [(self.TOKEN, True), ("incorrecto", False)]:
            try:
                abridor.open(f"{self.base}/acceso?token={token}", timeout=10)
                self.fail("debía redirigir")
            except urllib.error.HTTPError as respuesta:
                self.assertEqual((respuesta.code, respuesta.headers["Location"]), (303, "/"))
                cookie = respuesta.headers.get("Set-Cookie")
                self.assertEqual(cookie is not None, debe_dar_cookie)
                if cookie:
                    self.assertIn("HttpOnly", cookie)
                    self.assertIn("SameSite=Strict", cookie)
        cookie = f"autor={self.TOKEN}"
        self.assertEqual(json.loads(self.pedir("GET", "/api/estado", cookie=cookie)[1])["autor"], True)
        self.assertEqual(self.pedir("GET", "/api/materiales?vista=autor", cookie=cookie)[0], 200)

    def test_el_tecnico_no_ve_un_borrador_ni_por_su_direccion(self):
        estado, creado = self.pedir("POST", "/api/materiales", {"formato": "quiz", "modelo": "general", "nivel": "novato",
                                    "competencia": "seguridad-alto-voltaje", "tema": "EPP"}, cookie=f"autor={self.TOKEN}")
        self.assertEqual(estado, 201)
        identificador = json.loads(creado)["id"]
        self.assertEqual(self.pedir("GET", f"/api/materiales/{identificador}")[0], 404)
        self.assertEqual(self.pedir("GET", f"/api/materiales/{identificador}", cookie=f"autor={self.TOKEN}")[0], 200)
        self.pedir("POST", f"/api/materiales/{identificador}/revisar", {"revisor": "jefe-1"}, cookie=f"autor={self.TOKEN}")
        self.assertEqual(self.pedir("GET", f"/api/materiales/{identificador}")[0], 200)

    def test_el_token_se_crea_una_vez_y_con_permisos_cerrados(self):
        with tempfile.TemporaryDirectory() as carpeta:
            ruta = Path(carpeta) / ".token"
            primero = servidor.cargar_token(ruta)
            self.assertGreaterEqual(len(primero), 32)
            self.assertEqual(servidor.cargar_token(ruta), primero)
            if os.name == "posix":
                self.assertEqual(ruta.stat().st_mode & 0o077, 0)


class PruebaAgente(unittest.TestCase):
    def test_yaml_coincide_con_la_instruccion(self):
        yaml = (Path(__file__).resolve().parents[2] / "foundry" / "agente-materiales.yaml").read_text(encoding="utf-8")
        bloque = yaml.split("instructions: |-\n", 1)[1].split("\ntools:", 1)[0]
        texto = "\n".join(linea[2:] for linea in bloque.splitlines())
        from logica.generador import INSTRUCCION
        self.assertEqual(texto, INSTRUCCION)


class PruebaContenidoGuardado(unittest.TestCase):
    """Todo material en contenido/materiales/ cumple su formato y el catálogo."""

    def test_materiales_del_repositorio(self):
        catalogo = Catalogo()
        for material in Almacen().listar():
            with self.subTest(id=material["id"]):
                catalogo.comprobar(material["formato"], material["modelo"], material["nivel"], material["competencia"])
                self.assertEqual(formatos.validar(material["formato"], material["contenido"])[1], [])
                self.assertTrue(material["fuentes"])
                self.assertIn(material["estado"], ("borrador", "revisado"))


if __name__ == "__main__":
    unittest.main()
