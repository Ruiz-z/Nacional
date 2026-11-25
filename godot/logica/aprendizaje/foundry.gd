extends Node

# Cliente mínimo de chat completions de Azure AI Foundry.
# Configuración (nunca en git): variables NACIONAL_FOUNDRY_ENDPOINT, _CLAVE, _MODELO y _AUTH
# o el archivo user://foundry.cfg con la sección [foundry].
const CONFIG := "user://foundry.cfg"
const ESPERA_S := 8.0

var config := {}


func _init() -> void:
	cargar()


func cargar() -> void:
	config = {}
	var archivo := ConfigFile.new()
	var hay_archivo := archivo.load(CONFIG) == OK
	for campo in ["endpoint", "clave", "modelo", "auth"]:
		var valor := OS.get_environment("NACIONAL_FOUNDRY_" + campo.to_upper())
		if valor.is_empty() and hay_archivo:
			valor = str(archivo.get_value("foundry", campo, ""))
		if not valor.is_empty():
			config[campo] = valor


func disponible() -> bool:
	return str(config.get("endpoint", "")).begins_with("https://") and not str(config.get("clave", "")).is_empty()


func cuerpo(instruccion: String, contexto: Dictionary, esquema: Dictionary) -> Dictionary:
	var datos := {"messages": [
		{"role": "system", "content": instruccion},
		{"role": "user", "content": JSON.stringify(contexto)}],
		"response_format": {"type": "json_schema", "json_schema": esquema},
		"temperature": 0.2}
	if config.has("modelo"):
		datos["model"] = config.modelo
	return datos


func encabezados() -> PackedStringArray:
	var autorizacion: String = "api-key: " + str(config.clave)
	if config.get("auth", "api-key") == "bearer":
		autorizacion = "Authorization: Bearer " + config.clave
	return PackedStringArray(["Content-Type: application/json", autorizacion])


# Devuelve el JSON de la respuesta del modelo o {} si falla, tarda más de 8 s o no es JSON.
func generar(instruccion: String, contexto: Dictionary, esquema: Dictionary) -> Dictionary:
	if not disponible() or not is_inside_tree():
		return {}
	var peticion := HTTPRequest.new()
	peticion.timeout = ESPERA_S
	add_child(peticion)
	if peticion.request(config.endpoint, encabezados(), HTTPClient.METHOD_POST,
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
	var opciones: Variant = externo.data.get("choices")
	if not opciones is Array or opciones.is_empty() or not opciones[0] is Dictionary:
		return {}
	var mensaje: Variant = opciones[0].get("message")
	if not mensaje is Dictionary or not mensaje.get("content") is String:
		return {}
	var interno := JSON.new()
	if interno.parse(mensaje.content) != OK or not interno.data is Dictionary:
		return {}
	return interno.data
