extends RefCounted


static func item() -> Dictionary:
	return {"id": "bateria-01", "competencia": "sistema-electrico-bateria",
		"formato": "opcion-multiple", "dificultad": "media", "criticidad": "normal",
		"fuente": "[MUESTRA] valor de ejemplo, sin fuente oficial", "muestra": true,
		"version": "1", "pregunta": "¿Qué indica el instrumento simulado?",
		"opciones": ["Carga media", "Carga completa"], "correcta": 0}


static func ejecutar() -> bool:
	var ruta_banco := "res://logica/competencias/banco.gd"
	if not FileAccess.file_exists(ruta_banco):
		return false
	var banco := load(ruta_banco) as GDScript
	var ruta := OS.get_temp_dir().path_join("banco-" + Crypto.new().generate_random_bytes(8).hex_encode() + ".json")
	var correcto := comprobar(banco, ruta)
	DirAccess.remove_absolute(ruta)
	return correcto


static func escribir(ruta: String, contenido: String) -> bool:
	var archivo := FileAccess.open(ruta, FileAccess.WRITE)
	if archivo == null:
		return false
	archivo.store_string(contenido)
	return true


static func comprobar(banco: GDScript, ruta: String) -> bool:
	if not escribir(ruta, JSON.stringify({"items": [item()]})):
		return false
	var resultado: Dictionary = banco.cargar(ruta)
	if resultado.items.size() != 1 or not resultado.errores.is_empty():
		return false
	var invalidos := {"competencia": "diesel", "formato": "texto", "fuente": "",
		"version": "", "dificultad": "fácil", "criticidad": "alta", "muestra": "true"}
	for campo in invalidos:
		var invalido := item()
		invalido[campo] = invalidos[campo]
		resultado = banco.validar_texto(JSON.stringify({"items": [invalido]}), ruta)
		if not rechaza(resultado, ruta, campo):
			return false
	resultado = banco.validar_texto(JSON.stringify({"items": [item(), item()]}), ruta)
	if not rechaza(resultado, ruta, "duplicado"):
		return false
	if not escribir(ruta, "{\n\"items\": [}"):
		return false
	resultado = banco.cargar(ruta)
	return resultado.items.is_empty() and resultado.errores.size() == 1 \
		and ruta in resultado.errores[0] and "línea 2" in resultado.errores[0]


static func rechaza(resultado: Dictionary, ruta: String, motivo: String) -> bool:
	return resultado.items.is_empty() and resultado.errores.size() == 1 \
		and ruta in resultado.errores[0] and "bateria-01" in resultado.errores[0] \
		and motivo in resultado.errores[0]
