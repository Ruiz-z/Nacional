extends RefCounted

const Asistente = preload("res://logica/tablero/asistente.gd")

class ModeloFalso:
	extends RefCounted
	var llamadas := 0
	var inventar := false

	func generar(peticion: Dictionary) -> Dictionary:
		llamadas += 1
		if peticion.fuentes.size() != 1 or peticion.historial.has("nombre"):
			return {}
		return {"fuente": 0, "fragmento": "Valor inventado." if inventar else "El indicador muestra la carga simulada."}


static func ejecutar() -> bool:
	var asistente := Asistente.new()
	var archivo := "user://fuente_asistente_%d.txt" % Time.get_ticks_usec()
	var fuente := FileAccess.open(archivo, FileAccess.WRITE)
	if fuente == null or not fuente.store_string("contexto ".repeat(500) + "El indicador muestra la carga simulada."):
		return false
	fuente.close()
	var indexado := asistente.indexar([{"ruta": archivo, "cita": "[MUESTRA] Indicadores, p. 1"}])
	DirAccess.remove_absolute(archivo)
	if not indexado:
		return false
	var modelo := ModeloFalso.new()
	var respuesta: Dictionary = asistente.responder("¿CÁRGA?", modelo.generar,
		{"alias": "T-01", "nombre": "dato ajeno"})
	if respuesta.texto != "El indicador muestra la carga simulada." or respuesta.cita != "[MUESTRA] Indicadores, p. 1":
		return false
	respuesta = asistente.responder("¿Qué descarga? NEAR *", modelo.generar)
	if respuesta.texto != "no tengo esa información" or modelo.llamadas != 1:
		return false
	modelo.inventar = true
	respuesta = asistente.responder("carga", modelo.generar)
	return respuesta.texto == "no tengo esa información" and respuesta.cita.is_empty()
