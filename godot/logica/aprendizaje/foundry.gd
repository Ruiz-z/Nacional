extends Node

# Cliente del agente de Azure AI Foundry (API Responses del agente, con RAG sobre los manuales).
# Configuración (nunca en git): variables NACIONAL_FOUNDRY_ENDPOINT, _AGENTE y _TOKEN, el archivo .env
# de la raíz del repositorio o user://foundry.cfg con la sección [foundry].
# Sin _TOKEN, el token de Microsoft Entra se pide a la CLI de Azure (`az login` previo) y se reutiliza.
const CONFIG := "user://foundry.cfg"
const ENV := "res://../.env"
const CAMPOS := ["endpoint", "agente", "token"]
const API := "v1"
const RECURSO_TOKEN := "https://ai.azure.com"
const ESPERA_S := 30.0
const VIGENCIA_TOKEN_S := 3000
const MAX_FUENTES := 3

var config := {}
var token_cache := ""
var token_hasta := 0


func _init() -> void:
	cargar()


func cargar() -> void:
	config = {}
	# La suite de pruebas apaga la nube: nunca llama a Foundry aunque haya un .env.
	if OS.get_environment("NACIONAL_SIN_NUBE") == "1":
		return
	var archivo := ConfigFile.new()
	var hay_archivo := archivo.load(CONFIG) == OK
	var env := leer_env(ENV)
	for campo in CAMPOS:
		var clave: String = "NACIONAL_FOUNDRY_" + campo.to_upper()
		var valor: String = OS.get_environment(clave)
		if valor.is_empty():
			valor = str(env.get(clave, ""))
		if valor.is_empty() and hay_archivo:
			valor = str(archivo.get_value("foundry", campo, ""))
		if not valor.is_empty():
			config[campo] = valor


# Lee líneas CLAVE=valor de un .env; ignora comentarios y líneas vacías.
static func leer_env(ruta: String) -> Dictionary:
	var datos := {}
	var archivo := FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		return datos
	for linea in archivo.get_as_text().split("\n"):
		var texto := linea.strip_edges()
		var corte := texto.find("=")
		if texto.begins_with("#") or corte <= 0:
			continue
		datos[texto.substr(0, corte).strip_edges()] = texto.substr(corte + 1).strip_edges().trim_prefix("\"").trim_suffix("\"")
	return datos


func disponible() -> bool:
	return str(config.get("endpoint", "")).begins_with("https://")


func url() -> String:
	var base: String = str(config.get("endpoint", "")).trim_suffix("/")
	return "%s/agents/%s/endpoint/protocols/openai/responses?api-version=%s" % [
		base, str(config.get("agente", "Faro")), API]


# El agente fija el formato de salida, así que el esquema viaja en el mensaje y la app lo valida.
func cuerpo(instruccion: String, contexto: Dictionary, esquema: Dictionary) -> Dictionary:
	var texto := "%s\nConsulta los manuales y responde solo con un JSON que cumpla este esquema:\n%s\nContexto:\n%s" % [
		instruccion, JSON.stringify(esquema.get("schema", esquema)), JSON.stringify(contexto)]
	return {"input": texto, "store": false}


func encabezados(token: String) -> PackedStringArray:
	return PackedStringArray(["Content-Type: application/json", "Authorization: Bearer " + token])


# Token de Entra: el de la configuración o el de `az`, guardado en memoria unos 50 minutos.
func token() -> String:
	if config.has("token"):
		return str(config.token)
	var ahora := int(Time.get_unix_time_from_system())
	if not token_cache.is_empty() and ahora < token_hasta:
		return token_cache
	var salida: Array = []
	var codigo := OS.execute("az", ["account", "get-access-token", "--resource", RECURSO_TOKEN,
		"--query", "accessToken", "-o", "tsv"], salida, false)
	token_cache = str(salida[0]).strip_edges() if codigo == 0 and not salida.is_empty() else ""
	token_hasta = ahora + VIGENCIA_TOKEN_S
	return token_cache


# Devuelve el JSON del modelo más "fuentes" (nombres de PDF), o {} si falla, tarda o no es JSON.
func generar(instruccion: String, contexto: Dictionary, esquema: Dictionary) -> Dictionary:
	if not disponible() or not is_inside_tree():
		return {}
	var acceso := token()
	if acceso.is_empty():
		return {}
	var peticion := HTTPRequest.new()
	peticion.timeout = ESPERA_S
	add_child(peticion)
	if peticion.request(url(), encabezados(acceso), HTTPClient.METHOD_POST,
			JSON.stringify(cuerpo(instruccion, contexto, esquema))) != OK:
		peticion.queue_free()
		return {}
	var respuesta: Array = await peticion.request_completed
	peticion.queue_free()
	return extraer(respuesta[0], respuesta[1], respuesta[3])


static func extraer(resultado: int, codigo: int, cuerpo_bytes: PackedByteArray) -> Dictionary:
	if resultado != HTTPRequest.RESULT_SUCCESS or codigo < 200 or codigo >= 300:
		return {}
	var externo := JSON.new()
	if externo.parse(cuerpo_bytes.get_string_from_utf8()) != OK or not externo.data is Dictionary:
		return {}
	var salida: Variant = externo.data.get("output")
	if externo.data.get("status") != "completed" or not salida is Array:
		return {}
	var texto := ""
	var fuentes := []
	for elemento in salida:
		if not elemento is Dictionary:
			continue
		if elemento.get("type") == "message" and elemento.get("content") is Array:
			for parte in elemento.content:
				if parte is Dictionary and parte.get("type") == "output_text" and parte.get("text") is String:
					texto = parte.text
		elif elemento.get("type") == "mcp_call" and elemento.get("output") is String:
			for nombre in fuentes_de(elemento.output):
				if nombre not in fuentes and fuentes.size() < MAX_FUENTES:
					fuentes.append(nombre)
	var interno := JSON.new()
	if interno.parse(limpiar_json(texto)) != OK or not interno.data is Dictionary:
		return {}
	var datos: Dictionary = interno.data
	datos["fuentes"] = fuentes
	return datos


# Quita las vallas ```json que el modelo a veces agrega.
static func limpiar_json(texto: String) -> String:
	var limpio := texto.strip_edges()
	if limpio.begins_with("```"):
		limpio = limpio.substr(limpio.find("\n") + 1).trim_suffix("```").strip_edges()
	return limpio


# Nombres de PDF de los documentos que devolvió la base de conocimiento.
static func fuentes_de(salida_mcp: String) -> Array:
	var nombres := []
	var json := JSON.new()
	if json.parse(salida_mcp) != OK or not json.data is Dictionary or not json.data.get("documents") is Array:
		return nombres
	for documento in json.data.documents:
		if not documento is Dictionary or not documento.get("content") is String:
			continue
		var interno := JSON.new()
		if interno.parse(documento.content) != OK or not interno.data is Dictionary:
			continue
		var origen := str(interno.data.get("blob_url", ""))
		var nombre := origen.get_file().uri_decode()
		if nombre.to_lower().ends_with(".pdf") and nombre not in nombres:
			nombres.append(nombre)
	return nombres
