extends RefCounted

const Base = preload("res://tests/base_tablero.gd")
const RutaIA = preload("res://logica/aprendizaje/ruta_ia.gd")
const Foundry = preload("res://logica/aprendizaje/foundry.gd")
const Pantallas = preload("res://tests/pantallas_aprendizaje.gd")
const Recorrido = preload("res://logica/flujo/recorrido.gd")
const Ordenes = preload("res://logica/simulador/ordenes.gd")

const ORDEN := ["seguridad-alto-voltaje", "diagnostico-fallas", "electronica-conectividad", "sistema-electrico-bateria"]
const IDS := ["aislamiento", "modulo_auxiliar", "faros"]


static func paso(competencia: String, ordenes := ["aislamiento"]) -> Dictionary:
	return {"competencia": competencia, "motivo": "Tu dominio es bajo.", "practica": "Practica la referencia.",
		"ordenes": ordenes}


static func respuesta(orden: Array) -> Dictionary:
	return {"pasos": orden.map(func(id: String) -> Dictionary: return paso(id))}


static func ejecutar() -> bool:
	return contexto_privado() and validacion() and cliente() and Base.con_base(cache) \
		and Base.con_base(integracion)


static func integracion(base: String) -> bool:
	var menu := Pantallas.abrir(base)
	var ahora := int(Time.get_unix_time_from_system())
	Recorrido.cerrar_paso(base, base + ".respaldo.sqlite", menu.perfil.id, "diagnostico", [], 0, ahora)
	menu.actualizar()
	menu.botones.ruta.pressed.emit()
	var pantalla: Node = menu.pantalla
	var actividad = pantalla.actividad
	var original: Array = actividad.ruta.duplicate()
	var nueva := original.duplicate()
	nueva.reverse()
	var ids: Array = Ordenes.listar().ordenes.map(func(orden: Dictionary) -> String: return orden.id)
	var validada := RutaIA.validar(respuesta(nueva), original, actividad.historial, ids)
	var correcto: bool = actividad.origen_ruta == "reglas" and actividad.aplicar_ruta_ia(validada) \
		and actividad.ruta == validada.orden and actividad.origen_ruta == "ia" \
		and actividad.plan.lecciones[0].competencia == validada.orden[0] \
		and actividad.motivos_ruta()[0].motivo == "Tu dominio es bajo."
	menu.free()
	return correcto


static func contexto_privado() -> bool:
	var historial := [{"competencia": "diagnostico-fallas", "tipo_error": "paso-omitido"}]
	var c := RutaIA.contexto("Ana Perez", ORDEN, {"diagnostico-fallas": 40.0}, historial,
		[{"id": "aislamiento", "titulo": "Aislamiento", "dificultad": "facil",
			"competencia": "Seguridad de alto voltaje"}])
	var texto := JSON.stringify(c)
	return not texto.contains("Ana") and c.tecnico == RutaIA.pseudonimo("Ana Perez") \
		and c.competencias[1].errores == {"paso-omitido": 1} and c.ordenes[0].competencia == "seguridad-alto-voltaje" \
		and RutaIA.clave(c) == RutaIA.clave(c.duplicate(true))


static func validacion() -> bool:
	var valida := RutaIA.validar(respuesta(ORDEN), ORDEN, [], IDS)
	var invertida := ORDEN.duplicate()
	invertida.reverse()
	# Una falta crítica pendiente obliga a poner esa competencia primero, aunque la IA la ponga al final.
	var critica := [{"competencia": "sistema-electrico-bateria", "tipo_error": "falta-critica"}]
	var corregida := RutaIA.validar(respuesta(invertida), ORDEN, critica, IDS)
	var repetida := respuesta(ORDEN)
	repetida.pasos[1] = paso(ORDEN[0])
	var id_inventado := respuesta(ORDEN)
	id_inventado.pasos[0] = paso(ORDEN[0], ["no_existe"])
	var largo := respuesta(ORDEN)
	largo.pasos[0].motivo = "x".repeat(RutaIA.MAX_TEXTO + 1)
	var con_fuentes := respuesta(ORDEN)
	con_fuentes["fuentes"] = ["Manual.pdf", "../secreto.txt", 5, "Manual.pdf"]
	var con_temas := respuesta(ORDEN)
	con_temas["fuentes"] = ["Manual.pdf"]
	con_temas.pasos[0]["temas"] = [
		{"titulo": "Bloqueo y etiquetado", "fuente": "Manual.pdf"},
		{"titulo": "Tema sin fuente de la base", "fuente": "Otro.pdf"},
		{"titulo": "Otro tema", "fuente": "MANUAL.PDF"},
		{"titulo": "x".repeat(RutaIA.MAX_TITULO + 1), "fuente": "Manual.pdf"},
		{"titulo": "Bloqueo y etiquetado", "fuente": "Manual.pdf"}]
	var temas: Array = RutaIA.validar(con_temas, ORDEN, [], IDS).detalle[ORDEN[0]].temas
	return temas == [{"titulo": "Bloqueo y etiquetado", "fuente": "Manual.pdf"},
			{"titulo": "Otro tema", "fuente": "Manual.pdf"}] \
		and RutaIA.validar(valida_sin_temas(), ORDEN, [], IDS).detalle[ORDEN[0]].temas == [] \
		and RutaIA.validar(con_fuentes, ORDEN, [], IDS).fuentes == ["Manual.pdf"] \
		and valida.orden == ORDEN and corregida.orden[0] == "sistema-electrico-bateria" \
		and RutaIA.validar(repetida, ORDEN, [], IDS).is_empty() \
		and RutaIA.validar(id_inventado, ORDEN, [], IDS).detalle[ORDEN[0]].ordenes == [] \
		and RutaIA.validar(largo, ORDEN, [], IDS).is_empty() \
		and RutaIA.validar({"pasos": []}, ORDEN, [], IDS).is_empty() \
		and RutaIA.validar("texto", ORDEN, [], IDS).is_empty()


static func valida_sin_temas() -> Dictionary:
	return respuesta(ORDEN)


static func cliente() -> bool:
	var f := Foundry.new()
	f.config = {}
	var sin_configuracion := not f.disponible()
	f.config = {"endpoint": "http://inseguro"}
	var sin_https := not f.disponible()
	f.config = {"endpoint": "https://ejemplo.invalid/api/projects/p/", "agente": "Faro", "token": "t"}
	var cuerpo := f.cuerpo("sistema", {"a": 1}, RutaIA.esquema(ORDEN))
	var interno := JSON.stringify({"pasos": []})
	var documento := JSON.stringify({"documents": [{"content": JSON.stringify({
		"blob_url": "https://x.blob.core.windows.net/doc/Manual%20Uno.pdf"})}]})
	var externo := JSON.stringify({"status": "completed", "output": [
		{"type": "mcp_call", "output": documento},
		{"type": "message", "content": [{"type": "output_text", "text": "```json\n" + interno + "\n```"}]}]}).to_utf8_buffer()
	var leido := Foundry.extraer(HTTPRequest.RESULT_SUCCESS, 200, externo)
	var correcto: bool = f.disponible() and f.url() == "https://ejemplo.invalid/api/projects/p/agents/Faro/endpoint/protocols/openai/responses?api-version=v1" \
		and cuerpo.store == false and str(cuerpo.input).contains("sistema") and str(cuerpo.input).contains("ruta_aprendizaje") == false \
		and f.encabezados("t")[1] == "Authorization: Bearer t" and f.token() == "t" \
		and leido.pasos == [] and leido.fuentes == ["Manual Uno.pdf"] \
		and Foundry.extraer(HTTPRequest.RESULT_TIMEOUT, 0, externo).is_empty() \
		and Foundry.extraer(HTTPRequest.RESULT_SUCCESS, 500, externo).is_empty() \
		and Foundry.extraer(HTTPRequest.RESULT_SUCCESS, 200, "no json".to_utf8_buffer()).is_empty() \
		and Foundry.extraer(HTTPRequest.RESULT_SUCCESS, 200, JSON.stringify({"status": "failed", "output": []}).to_utf8_buffer()).is_empty()
	var env := Foundry.leer_env("res://tests/no_existe.env")
	f.free()
	return sin_configuracion and sin_https and correcto and env.is_empty()


static func cache(base: String) -> bool:
	Base.consultar(base, "INSERT INTO tecnico (alias) VALUES ('T-IA');")
	var id: int = Base.consultar(base, "SELECT id FROM tecnico;")[0].id
	var validada := RutaIA.validar(respuesta(ORDEN), ORDEN, [], IDS)
	if not RutaIA.leer_cache(base, id, "k1", Base.consultar).is_empty():
		return false
	if not RutaIA.guardar_cache(base, id, "k1", validada, Base.consultar):
		return false
	var leida := RutaIA.leer_cache(base, id, "k1", Base.consultar)
	return leida.orden == ORDEN and leida.detalle[ORDEN[0]].motivo == "Tu dominio es bajo." \
		and RutaIA.leer_cache(base, id, "otra", Base.consultar).is_empty()
